-- DeathNote - Claim.lua (1.7.0 claim)
-- Cashing in a bounty. Only a bounty posted on purpose (DeathNoteDB.bounty of the poster, received as B) can be
-- claimed; the book's own value never. Data, wire and rules only: no visible text here, the screen listens to the
-- events (EARNED_NEW, EARNED_CHANGED, CLAIM_SETTLED, and CLAIM_NEW, CLAIMS_CHANGED of Feud.lua).
--
-- The killer (own killing blow, Guild.OnPartyKill, sure key by the GUID: tracker or own book, never a first name alone):
-- one record per poster of a bounty of others on the victim, state "sent". The kill goes out as V as before. The claim
-- goes as C first in the answer to the poster's hello and on its own when the book hears any message of the poster
-- (a new record waits 90 s for the receipt of its V); the throttle lives on the record (10 minutes apart, 4 hours once
-- the kill is a day old, at most 6 a day). Guild: only the named poster takes it; friends: whisper. The poster answers
-- every valid V or C, every change and a repeated C (throttled) with the receipt Q: 0 open, 1 paid, 2 declined, 3 no
-- bounty (did not stand at the kill, or paid to somebody else).
-- The poster (E4 as changed after the hunt): one bounty (target, own char, first posting t0), one PAID claim. Every kill
-- made while the bounty stood is a claim, also when its C comes after the bounty ended (tombstones); claims stand open
-- side by side, "paid" for one declines the others (receipt 3) and takes exactly that bounty back (the logged-in
-- char's with sending, another own char's quietly, sent by that char at its next login); "declined" changes nothing
-- for the others.
--
-- Data, account-wide, additive (no DB version; 1.6.x keeps the unknown table and field untouched):
--   DeathNoteDB.earned   { { key, name, owner, char, t, g, via, state, at, c, cn, cd } } newest first, at most MAX,
--                        older than DAYS days go; owner = the poster's char, char = the own char that killed, t = kill
--                        time, g = gold, via = "guild" | "friends", state = "sent" | "open" | "paid" | "declined" |
--                        "gone", at = time of the last change; c, cn, cd = the throttle of its C (last time, count on
--                        day cd)
--   DeathNoteDB.claims   (Feud.lua) plus b = the bounty's identity: the time it was first posted (t0)
--   DeathNoteDB.bountyEnded  { { key, char, t0, g, e, paid } } own bounties that ended (taken back, expired, paid;
--                        e = end, paid = a claim on it is paid):
--                        a kill while one stood is still valid when its C comes later; newest first, at most ENDED_MAX,
--                        CLAIM_AGE; only judge reads them, never sent, never in "Back up book"
--   DeathNoteDB.bountyBack   { [own char] = { [key] = time } } (1.7.0 fix JL-10) bounties of another own char that
--                        "paid" took back quietly: that char sends B with gold 0 at its next login
--   DeathNoteDB.probe.claim   counters: sent and received per kind, dropped per reason, send results
-- Never in "Back up book", never in another message of the book.

local ADDON, ns = ...
local Util = ns.Util
local Guild = ns.Guild
if type(Guild) ~= "table" or type(Guild.Bridge) ~= "table" then return end

local B, P, C = Guild.Bridge, Guild.Proto, Guild.C
local IsSecret = Util.IsSecret

local Claim = {}
ns.Claim = Claim
local Ext = {}
Guild.ClaimExt = Ext

Claim.MAX = 50
Claim.DAYS = 30
Claim.NAME_MAX = 64
Claim.RESEND_MAX = 12         -- C per record and session at most (besides RESEND gap and the answer's cap)
Claim.DAY_MAX = 6             -- C per record and calendar day at most, over reloads (fix JN-3; the one after 90 s counts)
Claim.RESEND_LONG = 4 * 3600  -- gap between two C of a record whose kill is older than a day (fix JN-3)
Claim.FRESH_WAIT = 90         -- seconds a new record waits for the receipt of its V before its C goes (fix JL-1/2)
Claim.HEARD_GAP = 30          -- seconds between two looks at the records of the same poster on his messages
Claim.ENDED_MAX = 50          -- tombstones of own bounties
Claim.END_SKEW = 60           -- seconds after the end of an ended own bounty a kill still counts (fix JN-5)

local STATES = { sent = true, open = true, paid = true, declined = true, gone = true }
local OPEN = { sent = true, open = true }
local CODE_STATE = { [0] = "open", [1] = "paid", [2] = "declined", [3] = "gone" }
local STATE_CODE = { open = 0, paid = 1, declined = 2 }
local EMPTY = {}

local function now() return time() end
local function finite(v) return type(v) == "number" and v == v and v > -math.huge and v < math.huge end
local function plainName(s)
  return not IsSecret(s) and type(s) == "string" and s ~= "" and #s <= Claim.NAME_MAX and not s:find("[%c|]")
end
local function db() return ns.Store and ns.Store.DB and ns.Store.DB() or nil end
local function fctx() local F = ns.Friends; return F and F.ctx or nil end

---------------------------------------------------------------------------
-- Probe (probe.claim): counters of this session, added to DeathNoteDB.probe.claim at logout and by /dn probe
---------------------------------------------------------------------------
local resent = setmetatable({}, { __mode = "k" })   -- record -> { at = GetTime, n } (C sent this session)
local confirmed = setmetatable({}, { __mode = "k" }) -- record -> true: a receipt reached it this session
local sessionAt                                      -- time() of this login (READY)
local counts = {}
function Claim.Count(name, n)
  if type(name) ~= "string" then return end
  counts[name] = (counts[name] or 0) + (n or 1)
end
function Claim.Flush()
  local d = db()
  if not d then return nil end
  if type(d.probe) ~= "table" then d.probe = {} end
  local p = d.probe.claim
  if type(p) ~= "table" then p = {}; d.probe.claim = p end
  for k, v in pairs(counts) do p[k] = (finite(p[k]) and p[k] or 0) + v end
  counts = {}
  return p
end
Claim.ProbeSnapshot = Claim.Flush
function Claim.Session() return counts end
ns:RegisterEvent("PLAYER_LOGOUT", function() pcall(Claim.Flush) end)
Ext.count = Claim.Count
-- the queue's result of one C or Q (Sync.lua pump)
function Ext.noteSend(kind, outcome, channel)
  Claim.Count("code." .. tostring(kind) .. "." .. tostring(outcome) .. "." .. (channel == "GUILD" and "guild" or "friends"))
end

---------------------------------------------------------------------------
-- The killer's records (DeathNoteDB.earned)
---------------------------------------------------------------------------
-- repairs the list in place: broken records out, older than DAYS out, newest first, at most MAX
local function sanitize(list, t)
  local keep = {}
  for k, x in pairs(list) do
    if type(k) == "number" and k >= 1 and k == math.floor(k) then keep[#keep + 1] = { k, x } end
  end
  table.sort(keep, function(a, b) return a[1] < b[1] end)
  for k in pairs(list) do list[k] = nil end
  local t0 = t - Claim.DAYS * 86400
  for i = 1, #keep do
    local x = keep[i][2]
    local ok = type(x) == "table" and type(x.key) == "string" and not IsSecret(x.key) and P.ValidKey(x.key) ~= nil
      and plainName(x.owner) and plainName(x.char) and finite(x.t) and x.t >= t0 and finite(x.g) and x.g >= 0
      and STATES[x.state] == true
    if ok then
      x.t, x.g = math.floor(x.t), math.floor(x.g)
      if x.name ~= nil and not plainName(x.name) then x.name = nil end
      if x.via ~= "guild" and x.via ~= "friends" then x.via = nil end
      if x.at ~= nil and not finite(x.at) then x.at = nil end
      -- (fix JN-3) the throttle of the C
      if x.c ~= nil and not (finite(x.c) and x.c <= t + C.FUTURE) then x.c = nil end
      if x.cd ~= nil and not finite(x.cd) then x.cd = nil end
      if x.cn ~= nil and not (finite(x.cn) and x.cn >= 0) then x.cn = nil end
      list[#list + 1] = x
    end
  end
  table.sort(list, function(a, b) if a.t ~= b.t then return a.t > b.t end return a.owner < b.owner end)
  while #list > Claim.MAX do table.remove(list) end
end
Claim.Sanitize = sanitize

local function earnedTable()
  local d = db()
  if not d then return nil end
  if type(d.earned) ~= "table" then d.earned = {} end
  return d.earned
end

-- the killer's list (E7), newest first; never nil
function Claim.Earned()
  return earnedTable() or {}
end

-- records still waiting: "sent" or "open"
function Claim.OpenEarned()
  local n = 0
  for _, x in ipairs(Claim.Earned()) do if type(x) == "table" and OPEN[x.state] then n = n + 1 end end
  return n
end

local rewait   -- (below)
-- takes one own record out of the list (true when it was there)
function Claim.Dismiss(x)
  local list = earnedTable()
  if type(x) ~= "table" or not list then return false end
  for i = 1, #list do
    if list[i] == x then
      table.remove(list, i)
      Claim.Count("dismissed")
      rewait()
      return true
    end
  end
  return false
end

-- 1.7.0 fix JL-1/2: the posters for whom records of the logged-in char wait (sent, open), as lower first names in
-- Guild.claimWait (nil when none: then a received message costs one table look). Made anew on every change of the list.
local function firstOf(s) local f = type(s) == "string" and s:match("^([^%s%-]+)"); return f and f:lower() or nil end
rewait = function()
  local d = db()
  local list = d and type(d.earned) == "table" and d.earned or EMPTY
  local mine = B.myFullName()
  local t0 = now() - C.CLAIM_AGE
  local w
  for i = 1, #list do
    local x = list[i]
    if type(x) == "table" and OPEN[x.state] and x.char == mine and finite(x.t) and x.t >= t0 and plainName(x.owner) then
      local f = firstOf(x.owner)
      if f then w = w or {}; w[f] = true end
    end
  end
  Guild.claimWait = w
  return w
end
Claim.Rewait = rewait

-- may this record's C go now? 1.7.0 fix JN-3: the throttle lives on the record (x.c = time of the last C, x.cn = C on
-- the day x.cd) and holds over reloads and logins: CLAIM_RESEND apart (RESEND_LONG once the kill is a day old), at most
-- DAY_MAX a day; in the session at most RESEND_MAX as before
local function dayOf(t) return math.floor(t / 86400) end
local function dayFull(x, t) return x.cd == dayOf(t) and (tonumber(x.cn) or 0) >= Claim.DAY_MAX end
local function mayResend(x, gt)
  local t = now()
  local gap = (finite(x.t) and t - x.t > 86400) and Claim.RESEND_LONG or C.CLAIM_RESEND
  if finite(x.c) and t - x.c < gap and t >= x.c then return false end
  if dayFull(x, t) then return false end
  local r = resent[x]
  return not r or r.n < Claim.RESEND_MAX
end
local function countDay(x, t)
  local day = dayOf(t)
  if x.cd ~= day then x.cd, x.cn = day, 0 end
  x.cn = (tonumber(x.cn) or 0) + 1
end
local function noteResent(x, gt)
  local r = resent[x]
  resent[x] = { at = gt, n = (r and r.n or 0) + 1 }
  local t = now()
  x.c = t
  countDay(x, t)
  Claim.Count("sent.C")
end

-- one C of record x: on GUILD, or as a whisper to the friend `fname`; once = true: not booked against the throttle (the
-- poster may be offline: his next message or hello must still bring the C)
local function sendC(x, fname, once)
  local text = P.EncodeClaim(x.key, x.char, x.t, x.owner, math.max(1, x.g))
  if not text then return false end
  local ok, why
  if not fname then
    if not (B.canSendGuild() and B.guildList()) then return false end
    ok, why = B.enqueue(text, "C")
  else
    local F = ns.Friends
    ok = F and F.SendTo and F.SendTo(fname, text, "C")
  end
  if ok or why == "dup" then
    if once then countDay(x, now()); Claim.Count("sent.C") else noteResent(x, GetTime()) end
    return true
  end
  Claim.Count("unsent.C." .. tostring(why or "friend"))
  return false
end

-- A message of somebody for whom own records may wait (Sync.lua Guild.ClaimHeard, Friends.lua): his waiting records go
-- out as C on the way the message came. A new record waits FRESH_WAIT for its V's receipt; an open one goes once per
-- session (to learn a later change), one with a receipt this session not at all.
local heardAt = {}
function Ext.heard(ctx, short, full, known)
  local w = Guild.claimWait
  local f = firstOf(short)
  if not w or not f or not w[f] then return end
  local gt = GetTime()
  local last = heardAt[full]
  if last and gt - last < Claim.HEARD_GAP and gt >= last then return end
  heardAt[full] = gt
  local fname
  if ctx ~= B.gctx then
    local F = ns.Friends
    local fx = F and F.FriendOf and F.FriendOf(short)
    if not fx then return end
    fname = fx.name
  end
  local d = db()
  local list = d and type(d.earned) == "table" and d.earned or EMPTY
  local mine = B.myFullName()
  local t, t0 = now(), now() - C.CLAIM_AGE
  local n = 0
  for i = 1, #list do
    if n >= C.CLAIM_REPLY then break end
    local x = list[i]
    if type(x) == "table" and OPEN[x.state] and x.char == mine and finite(x.t) and x.t >= t0 and plainName(x.owner)
      and P.Owns(x.owner, short, known) and not confirmed[x]
      and not (x.state == "sent" and t - (tonumber(x.at) or 0) < Claim.FRESH_WAIT)
      and not (x.state == "open" and resent[x]) and mayResend(x, gt) then
      if sendC(x, fname) then n = n + 1; Claim.Count("heard.C") end
    end
  end
end

-- FRESH_WAIT after a kill: its records still "sent" go to their posters when they were heard in this session (guild:
-- a message since the login; friends: answered in this session, Friends.SendTo checks it)
local function pushFresh(made)
  local d = db()
  local list = d and type(d.earned) == "table" and d.earned or EMPTY
  local mine = B.myFullName()
  local gt = GetTime()
  for i = 1, #made do
    local x = made[i]
    local inList = false
    for j = 1, #list do if list[j] == x then inList = true; break end end
    if inList and x.state == "sent" and x.char == mine and not confirmed[x] and not dayFull(x, now()) then
      local sent = false
      if B.inGuild() and Guild.HeardSince and sessionAt and Guild.HeardSince(x.owner, sessionAt) then sent = sendC(x, nil, true) end
      if not sent then
        local F = ns.Friends
        local fx = F and F.FriendOf and F.FriendOf(x.owner)
        if fx then sent = sendC(x, fx.name, true) end
      end
      if sent then Claim.Count("fresh.C") end
    end
  end
end

-- the shown name of a target: own book, the guild's or friends' book (nil: the screen shows the key)
local function nameOf(key)
  local S = ns.Store
  local e = S and S.Get and S.Get(key)
  if type(e) == "table" then
    local ok, d = pcall(Util.Display, e)
    if ok and plainName(d) and d ~= "?" then return d end
  end
  local fc = fctx()
  for pass = 1, 2 do
    local st = pass == 1 and B.gctx.store or (fc and fc.store)
    local g = st and type(st.enemies) == "table" and st.enemies[key]
    if type(g) == "table" and plainName(g.display) then return g.display end
  end
  return nil
end
Claim.NameOf = nameOf

-- start of the bounties still alive (huntExpire), or nil
local function aliveFrom()
  local age = Guild.ExpireAge and Guild.ExpireAge()
  return age and now() - age or nil
end

-- has the killer a record for this poster on key that covers the kill t of a bounty last set at bt? The same kill (two
-- events), or an earlier kill of his (sent, open, paid) on the bounty as he knows it: its last change bt came before
-- that kill. (Round 2: a waiting record no longer covers a bounty posted anew after it; the killer cannot tell that
-- from a new amount, which then gives a second record: the poster holds both open, "paid" declines the other.)
local function covered(list, key, owner, t, bt)
  for i = 1, #list do
    local x = list[i]
    if x.key == key and x.owner == owner then
      if math.abs(x.t - t) < C.BAG_DEDUPE then return true end
      if (OPEN[x.state] or x.state == "paid") and x.t >= bt - C.CLAIM_SKEW then return true end
    end
  end
  return false
end

-- Own killing blow (Bounty.lua Ext.partyKill): one record "sent" per poster of a bounty of others on key. sure = the key
-- came from the GUID (tracker or own book); without it nothing (E3). Returns the number of new records.
function Claim.OnKill(key, sure, t, mine)
  if IsSecret(key) or type(key) ~= "string" or not plainName(mine) or not finite(t) then return 0 end
  local gb = B.inGuild() and B.gctx.bounty
  local fc = fctx()
  local gx = gb and gb[key]
  local fx = fc and fc.bounty and fc.bounty[key]
  if type(gx) ~= "table" and type(fx) ~= "table" then return 0 end
  if not sure then Claim.Count("unsure"); return 0 end
  local list = earnedTable()
  if not list then return 0 end
  t = math.floor(t)
  local t0 = aliveFrom()
  local made, seen = {}, {}
  for pass = 1, 2 do
    local x
    if pass == 1 then x = gx else x = fx end
    if type(x) == "table" then
      for c, r in pairs(x) do
        if not seen[c] and plainName(c) and c ~= mine and not Guild.IsOwnChar(c) and type(r) == "table"
          and finite(r.g) and r.g >= 1 and finite(r.t) and not (t0 and r.t < t0) then
          seen[c] = true
          if r.t > t + C.CLAIM_SKEW then
            Claim.Count("early")
          elseif covered(list, key, c, t, r.t) then
            Claim.Count("covered")
          else
            local y = { key = key, name = nameOf(key), owner = c, char = mine, t = t, g = math.floor(r.g),
              via = pass == 1 and "guild" or "friends", state = "sent", at = now() }
            table.insert(list, 1, y)
            made[#made + 1] = y
          end
        end
      end
    end
  end
  if #made == 0 then return 0 end
  sanitize(list, now())
  local n = 0
  for i = 1, #made do
    local y = made[i]
    for j = 1, #list do
      if list[j] == y then
        n = n + 1
        Claim.Count("earned")
        ns:Fire("EARNED_NEW", y)
        break
      end
    end
  end
  rewait()
  local A = _G.C_Timer and _G.C_Timer.After
  if A and n > 0 then
    A(Claim.FRESH_WAIT + 1, function()
      local ok, err = pcall(pushFresh, made)
      if not ok and ns.ReportError then ns.ReportError(err) end
    end)
  end
  return n
end

---------------------------------------------------------------------------
-- Receiving (Sync.lua apply: the sender is checked already: C from the killer, Q from the poster)
---------------------------------------------------------------------------
-- per sender: C at most CLAIM_IN, Q at most RECEIPT_IN in CLAIM_IN_WINDOW seconds
local function mayTake(ctx, who, t, kind)
  local f = ctx.fresh
  if type(f) ~= "table" or type(who) ~= "string" then return false end
  local s = f[who]
  if not s then s = { at = t, n = 0, w = 0 }; f[who] = s end
  local cap = kind == "C" and C.CLAIM_IN or C.RECEIPT_IN
  local ak, nk = kind == "C" and "clAt" or "rcAt", kind == "C" and "clN" or "rcN"
  if not s[ak] or t - s[ak] > C.CLAIM_IN_WINDOW or t < s[ak] then s[ak], s[nk] = t, 0 end
  if s[nk] >= cap then return false end
  s[nk] = s[nk] + 1
  return true
end

local function drop(ctx, why)
  Claim.Count("drop." .. why)
  local st = ctx and ctx.stats
  if type(st) == "table" then st.dropped = (st.dropped or 0) + 1; st.lastReason = "claim " .. why end
end

-- the way a claim came in this session (the receipt of a later change goes the same way): claim -> { ctx, short }
local route = setmetatable({}, { __mode = "k" })

-- one receipt to the killer on the way of ctx (GUILD, or a whisper to the friend `short`)
local function receipt(ctx, short, key, by, t, owner, s, g)
  local text = P.EncodeReceipt(key, by, t, owner, s, g)
  if not text then return false end
  local ok
  if ctx == B.gctx then
    if not (B.canSendGuild() and B.guildList()) then return false end
    ok = B.enqueue(text, "Q")
  else
    local F = ns.Friends
    local x = F and F.FriendOf and F.FriendOf(short)
    if not x then return false end
    ok = F.SendTo(x.name, text, "Q")
  end
  if ok then Claim.Count("sent.Q") end
  return ok and true or false
end

-- a receipt for a repeated C at most every RECEIPT_GAP seconds per kill
local lastReceipt, receiptN = {}, 0
local function mayReceipt(key, by, t)
  local id = key .. "\t" .. by .. "\t" .. tostring(t)
  local gt = GetTime()
  local last = lastReceipt[id]
  if last and gt - last < C.RECEIPT_GAP and gt >= last then return false end
  if not last then
    receiptN = receiptN + 1
    if receiptN > 200 then lastReceipt, receiptN = {}, 1 end
  end
  lastReceipt[id] = gt
  return true
end

-- the own bounties on key (all chars of the account), or nil
local function ownBounty(key)
  local d = db()
  local own = d and type(d.bounty) == "table" and d.bounty[key]
  return type(own) == "table" and own or nil
end

-- 1.7.0 fix JL-3/4/5: a bounty is (target, own char, first posting t0). The own bounties of key, live and ended
-- (tombstones): { { char, b = t0, g, to = end or nil } }; owner = only this own char
local function bid(r) return math.floor(r.t0 or r.t) end
local function endedTable()
  local d = db()
  if not d then return nil end
  if type(d.bountyEnded) ~= "table" then d.bountyEnded = {} end
  return d.bountyEnded
end
local function instances(key, owner)
  local out = {}
  local own = ownBounty(key)
  local age = Guild.ExpireAge and Guild.ExpireAge()
  if own then
    for c, r in pairs(own) do
      if (owner == nil or c == owner) and type(r) == "table" and finite(r.t) and finite(r.g) then
        out[#out + 1] = { char = c, b = bid(r), g = math.floor(r.g), to = age and r.t + age or nil, live = true }
      end
    end
  end
  local d = db()
  local list = d and type(d.bountyEnded) == "table" and d.bountyEnded or EMPTY
  for i = 1, #list do
    local e = list[i]
    if type(e) == "table" and e.key == key and (owner == nil or e.char == owner) then
      local dup = false
      for j = 1, #out do if out[j].char == e.char and out[j].b == e.t0 then dup = true; break end end
      if not dup then out[#out + 1] = { char = e.char, b = e.t0, g = e.g, to = e.e, paid = e.paid == true } end
    end
  end
  -- (fix JN-1) per char the live bounty first, then the tombstones, the latest first posting first; never by gold
  local mine = B.myFullName()
  table.sort(out, function(a, b)
    if a.char ~= b.char then
      if (a.char == mine) ~= (b.char == mine) then return a.char == mine end
      return a.char < b.char
    end
    if (a.live == true) ~= (b.live == true) then return a.live == true end
    return a.b > b.b
  end)
  return out
end
Claim.Instances = instances

-- did the bounty stand at the kill kt? From its first posting (CLAIM_SKEW before it: two clocks) to its end; after the
-- end of an ended one (taken back, expired, paid: the end was heard by all at once) only END_SKEW (fix JN-5)
local function stood(a, kt)
  if kt < a.b - C.CLAIM_SKEW then return false end
  if a.to == nil then return true end
  return kt <= a.to + (a.live and C.CLAIM_SKEW or Claim.END_SKEW)
end

-- 1.7.0 fix JN-1: of the bounties of each own char the one that stood at the kill: the live one when it stood, else
-- the tombstone whose time holds the kill (the latest first posting); cands sorted as instances() gives them.
-- Returns the picks in that order (logged-in char first) and the first candidate with the reason when none stood.
local function picks(cands, kt)
  local out, seen = {}, {}
  local first, why
  for i = 1, #cands do
    local a = cands[i]
    first = first or a
    if not seen[a.char] then
      if stood(a, kt) then seen[a.char] = true; out[#out + 1] = a
      else why = why or (kt < a.b - C.CLAIM_SKEW and "early" or "ended") end
    end
  end
  return out, first, why
end

-- 1.7.0 fix (new E4): a claim PAID on the bounty (key, char, first posted at bt); a claim of 1.6.x without b counts
-- when its kill came after the first posting (JL-11). Open claims may stand side by side: the poster chooses.
local function taken(claims, key, char, bt)
  for i = 1, #claims do
    local y = claims[i]
    if y.key == key and y.char == char and y.state == "paid"
      and (y.b == bt or (y.b == nil and finite(y.t) and y.t >= bt - C.CLAIM_SKEW)) then
      return true
    end
  end
  return false
end

-- an own bounty ended (Bounty.lua: taken back, expired, paid; e = its end): one tombstone per bounty
function Claim.BountyEnded(key, char, r, e)
  if IsSecret(key) or type(key) ~= "string" or not plainName(char) or type(r) ~= "table" or not finite(r.t)
    or not finite(e) then return end
  local list = endedTable()
  if not list then return end
  local t0 = bid(r)
  local paid
  for i = #list, 1, -1 do
    local y = list[i]
    if type(y) ~= "table" or (y.key == key and y.char == char and y.t0 == t0) then
      if type(y) == "table" and y.paid == true then paid = true end
      table.remove(list, i)
    end
  end
  local g = finite(r.g) and math.max(0, math.min(C.BOUNTY_GOLD_MAX, math.floor(r.g))) or 0
  table.insert(list, 1, { key = key, char = char, t0 = t0, g = g, e = math.floor(math.min(e, now() + C.FUTURE)),
    paid = paid })
  local old = now() - C.CLAIM_AGE
  for i = #list, 1, -1 do if not finite(list[i].e) or list[i].e < old then table.remove(list, i) end end
  while #list > Claim.ENDED_MAX do table.remove(list) end
end

-- a tombstone of an own bounty on key (Bounty.lua applyV: a V for a target whose bounty ended may still be a claim)
function Claim.EndedOn(key, by)
  if IsSecret(key) or IsSecret(by) or type(key) ~= "string" or type(by) ~= "string" or Guild.IsOwnChar(by) then return nil end
  local d = db()
  local list = d and type(d.bountyEnded) == "table" and d.bountyEnded or EMPTY
  for i = 1, #list do
    local e = list[i]
    if type(e) == "table" and e.key == key then return { g = e.g, char = e.char } end
  end
  return nil
end

local function sanitizeEnded(d, t)
  if d.bountyEnded ~= nil and type(d.bountyEnded) ~= "table" then d.bountyEnded = nil end
  local list = d.bountyEnded
  if not list then return end
  local keep = {}
  for k, e in pairs(list) do
    if type(k) == "number" and type(e) == "table" and type(e.key) == "string" and not IsSecret(e.key)
      and P.ValidKey(e.key) ~= nil and plainName(e.char) and finite(e.t0) and finite(e.g) and finite(e.e)
      and e.e >= t - C.CLAIM_AGE
      -- (fix JN-8) bounds as for the other tables: whole gold 0..BOUNTY_GOLD_MAX, the end not ahead, posted before it
      and e.g >= 0 and e.g <= C.BOUNTY_GOLD_MAX and e.g == math.floor(e.g) and e.e <= t + C.FUTURE and e.t0 <= e.e then
      if e.paid ~= nil and e.paid ~= true then e.paid = nil end
      keep[#keep + 1] = e
    end
  end
  table.sort(keep, function(a, b) if a.e ~= b.e then return a.e > b.e end return a.key < b.key end)
  for k in pairs(list) do list[k] = nil end
  for i = 1, math.min(#keep, Claim.ENDED_MAX) do list[i] = keep[i] end
end

-- The rule for C (and the first candidate of a V): is the kill (by, kt) of key a claim on an own bounty that stood at the
-- kill and is not paid to somebody else? owner = the own char the C names (nil: the logged-in char's bounty first).
-- Returns "new", { g, char, b } | "repeat", claim | "gone", { g, char, b } or nil, reason | nil (an own char killed).
local function judge(key, by, kt, owner)
  if Guild.IsOwnChar(by) then return nil end
  local Fe = ns.Feud
  local claims = Fe and Fe.Claims and Fe.Claims() or EMPTY
  for i = 1, #claims do
    local y = claims[i]
    if y.key == key and y.by == by and math.abs(y.t - kt) < 60 and (owner == nil or y.char == nil or y.char == owner) then
      return "repeat", y
    end
  end
  -- 1.7.0 fix JL-3/4/5: the bounties that stood at the kill (live or ended), judged by their first posting
  local cands = instances(key, owner)
  if #cands == 0 then return "gone", nil, "none" end
  local chosen, first, why = picks(cands, kt)
  for i = 1, #chosen do
    local a = chosen[i]
    first = a
    if a.paid or taken(claims, key, a.char, a.b) then why = "taken"
    else return "new", a end
  end
  return "gone", first, why or "none"
end
Claim.Judge = judge

-- V of someone else on a target with an own bounty (Bounty.lua applyV, after its own checks: fresh, not flooded, the
-- kill counted once). 1.7.0 fix JL-6/7 (new E4): one claim on EVERY own bounty that stood at the kill and is not paid,
-- on whichever own char; the receipt for the logged-in char's bounty (0 when a claim is new, 3 when its bounty did not
-- stand or is paid, nothing for a repeat)
function Claim.OnAvenged(ctx, m, short, name)
  Claim.Count("recv.V")
  if Guild.IsOwnChar(m.by) then return end
  local Fe = ns.Feud
  if not (Fe and Fe.AddClaim and Fe.Claims) then return end
  local claims = Fe.Claims()
  local mine = B.myFullName()
  local all = instances(m.key, nil)
  local cands = picks(all, m.t)
  local done, mineAny, mineQ, mineG = {}, false, nil, 0
  for i = 1, #all do if all[i].char == mine then mineAny = true; mineG = mineG > 0 and mineG or all[i].g end end
  for i = 1, #cands do
    local a = cands[i]
    if a.char == mine then mineG = a.g end
    if not done[a.char] then
      local rep = false
      for j = 1, #claims do
        local y = claims[j]
        if y.key == m.key and y.by == m.by and math.abs(y.t - m.t) < 60 and (y.char == a.char or y.char == nil) then
          rep = true; break
        end
      end
      if rep then
        done[a.char] = true
        if a.char == mine then mineQ = mineQ or false end
      elseif a.paid or taken(claims, m.key, a.char, a.b) then
        Claim.Count("claim.gone.taken")
      else
        local c = Fe.AddClaim(m.key, name, m.by, m.t, a.g, a.char, a.b)
        if c then
          done[a.char] = true
          route[c] = { ctx, short }
          Claim.Count("claim.new")
          if a.char == mine then mineQ = 0; mineG = c.g end
        end
      end
    end
  end
  if not mine then return end
  if mineQ == 0 then receipt(ctx, short, m.key, m.by, m.t, mine, 0, mineG)
  elseif mineQ == nil and mineAny then
    Claim.Count("claim.gone.mine")
    receipt(ctx, short, m.key, m.by, m.t, mine, 3, mineG)
  end
end

local function applyC(ctx, m, short, full, t)
  local mine = B.myFullName()
  -- for another poster (the guild hears every C): not counted as dropped
  if not mine or m.owner ~= mine then Claim.Count("other.C"); return end
  if Guild.IsOwnChar(m.by) then drop(ctx, "own"); return end
  if t - m.t > C.CLAIM_AGE then drop(ctx, "old"); return end
  if not mayTake(ctx, full, t, "C") then drop(ctx, "flood"); return end
  Claim.Count("recv.C")
  local verdict, a, why = judge(m.key, m.by, m.t, mine)
  if verdict == "new" then
    local Fe = ns.Feud
    local c = Fe and Fe.AddClaim and Fe.AddClaim(m.key, nameOf(m.key), m.by, m.t, a.g, a.char, a.b)
    if not c then return end
    route[c] = { ctx, short }
    Claim.Count("claim.new")
    mayReceipt(m.key, m.by, m.t)
    receipt(ctx, short, m.key, m.by, m.t, mine, 0, c.g)
  elseif verdict == "repeat" then
    route[a] = { ctx, short }
    Claim.Count("claim.repeat")
    local code = STATE_CODE[a.state]
    if code and mayReceipt(m.key, m.by, m.t) then receipt(ctx, short, m.key, m.by, m.t, mine, code, a.g) end
  elseif verdict == "gone" then
    Claim.Count("claim.gone." .. tostring(why))
    if mayReceipt(m.key, m.by, m.t) then receipt(ctx, short, m.key, m.by, m.t, mine, 3, a and a.g or 0) end
  end
end

local function applyQ(ctx, m, short, full, t)
  local mine = B.myFullName()
  -- for another killer (the guild hears every Q): not counted as dropped
  if not (m.by == mine or Guild.IsOwnChar(m.by)) then Claim.Count("other.Q"); return end
  if not mayTake(ctx, full, t, "Q") then drop(ctx, "flood"); return end
  Claim.Count("recv.Q")
  local list = earnedTable()
  local x
  for i = 1, list and #list or 0 do
    local y = list[i]
    if y.key == m.key and y.owner == m.owner and y.char == m.by and y.t == m.t then x = y; break end
  end
  -- 1.7.0 fix JL-12: the poster's claim may carry another time of the same kill (two kills under 60 s are one): when
  -- exactly one record is that close, it is the one
  if not x and list then
    local n, y1 = 0, nil
    for i = 1, #list do
      local y = list[i]
      if y.key == m.key and y.owner == m.owner and y.char == m.by and math.abs(y.t - m.t) < 60 then n = n + 1; y1 = y end
    end
    if n == 1 then x = y1 end
  end
  if not x then drop(ctx, "unknown"); return end
  local new = CODE_STATE[m.s]
  if not new then drop(ctx, "state"); return end
  confirmed[x] = true
  if m.g >= 1 then x.g = m.g end
  if x.state == new then return end
  local old = x.state
  x.state, x.at = new, now()
  Claim.Count("state." .. new)
  rewait()
  ns:Fire("EARNED_CHANGED", x, old)
end

function Ext.apply(ctx, m, short, full, t)
  if m.kind == "C" then return applyC(ctx, m, short, full, t) end
  if m.kind == "Q" then return applyQ(ctx, m, short, full, t) end
end

---------------------------------------------------------------------------
-- The killer's answer to a hello: C for the records of the logged-in char on bounties of those who asked
---------------------------------------------------------------------------
function Ext.answer(ctx, send, asked)
  local d = db()
  local list = d and type(d.earned) == "table" and d.earned or nil
  if not list or #list == 0 then return end
  local mine = B.myFullName()
  if not mine then return end
  local t0 = now() - C.CLAIM_AGE
  local gt = GetTime()
  local n = 0
  for i = 1, #list do
    if n >= C.CLAIM_REPLY then break end
    local x = list[i]
    if type(x) == "table" and OPEN[x.state] and x.char == mine and finite(x.t) and x.t >= t0 and plainName(x.owner)
      and asked(x.owner) then
      if mayResend(x, gt) then
        local text = P.EncodeClaim(x.key, x.char, x.t, x.owner, math.max(1, x.g))
        local ok, why = send(text, "C")
        if ok or why == "dup" then
          n = n + 1
          noteResent(x, gt)
        else
          Claim.Count("unsent.C." .. tostring(why))
        end
      end
    end
  end
end

---------------------------------------------------------------------------
-- The poster changes a claim (Feud.SetClaim, the only way of the screen): "paid" takes the bounty back (E5), every
-- change goes to the killer as a receipt
---------------------------------------------------------------------------
-- exactly the bounty of the claim (the same time it was set; a claim of 1.6.x without it: a bounty that was there at
-- the kill); the logged-in char's with sending (B with gold 0), another own char's quietly
-- the bounty table of the target and the record "paid" would take back, or nil (nothing is changed)
local function bountyOf(x)
  local d = db()
  local own = d and type(x) == "table" and type(d.bounty) == "table" and d.bounty[x.key]
  local char = x.char
  local r = type(own) == "table" and char and own[char]
  if type(r) ~= "table" or not finite(r.t) then return nil end
  -- 1.7.0 fix JL-4: the bounty is its first posting (a new amount keeps it)
  if x.b ~= nil then
    if bid(r) ~= x.b then return nil end
  elseif not finite(x.t) or bid(r) > x.t + C.CLAIM_SKEW then
    return nil
  end
  return own, d
end
-- would "paid" take a bounty back for this claim? (the sheet says so before the click only when it is true). Second
-- value (1.7.0 fix JL-10): the own char whose bounty it is when that is not the logged-in one: guild and friends hear of
-- it at that char's next login
function Claim.WouldTake(x)
  local ok, own = pcall(bountyOf, x)
  if not (ok and own ~= nil) then return false, nil end
  local mine = B.myFullName()
  return true, (x.char ~= mine and x.char or nil)
end

local function settle(x)
  local own, d = bountyOf(x)
  if not own then return false end
  local char = x.char
  if char == B.myFullName() then
    local X = ns.Bounty
    return X ~= nil and X.Set ~= nil and X.Set(x.key, 0) == true
  end
  Claim.BountyEnded(x.key, char, own[char], now())
  own[char] = nil
  if next(own) == nil then d.bounty[x.key] = nil end
  -- 1.7.0 fix JL-10: only that char may send its taking back (the sender must be the char): noted for its next login
  if type(d.bountyBack) ~= "table" then d.bountyBack = {} end
  local pend = d.bountyBack[char]
  if type(pend) ~= "table" then pend = {}; d.bountyBack[char] = pend end
  pend[x.key] = now()
  B.updated()
  return true, char
end
Claim.Settle = settle

-- the receipt of a change: the way the claim came in this session, else the guild (a mate with the book) or the friend
local function tell(x, code)
  local mine = B.myFullName()
  if not mine or x.char ~= mine or not plainName(x.by) then return false end
  local w = route[x]
  local sent = false
  if w then sent = receipt(w[1], w[2], x.key, x.by, x.t, mine, code, x.g) end
  if not w and B.inGuild() and (Guild.IsGuildmate(x.by) or Guild.HasAddon(x.by)) then
    sent = receipt(B.gctx, nil, x.key, x.by, x.t, mine, code, x.g)
  end
  -- (fixer 1.7.0: a killer who left the guild after the kill hears no GUILD any more; a friend gets the receipt by
  -- whisper too, Friends.SendTo never whispers to a guildmate, a double receipt changes nothing)
  local F = ns.Friends
  local f = F and F.FriendOf and F.FriendOf(x.by)
  if f and fctx() and not (w and w[1] == fctx()) then
    if receipt(fctx(), f.name, x.key, x.by, x.t, mine, code, x.g) then sent = true end
  end
  return sent
end

-- 1.7.0 fix JN-2: the tombstone of the claim's bounty knows that it is paid (the paid claim may age or leave the list
-- before the tombstone: the bounty stays paid); on = false when the claim leaves "paid" again
local function markPaid(x, on)
  local list = endedTable()
  if not list or type(x) ~= "table" then return end
  for i = 1, #list do
    local e = list[i]
    if type(e) == "table" and e.key == x.key and e.char == x.char and (e.t0 == x.b or (x.b == nil and finite(x.t)
      and e.t0 <= x.t + C.CLAIM_SKEW and e.e >= x.t - Claim.END_SKEW)) then
      e.paid = on and true or nil
      Claim.Count(on and "tomb.paid" or "tomb.unpaid")
      return
    end
  end
end
Claim.MarkPaid = markPaid

local function onSet(x, state, old)
  if old == "paid" and state ~= "paid" then markPaid(x, false) end
  if state == "paid" then
    -- 1.7.0 fix (new E4): the other open claims on this bounty are declined (receipt 3: no bounty for them)
    local Fe = ns.Feud
    local others = Fe and Fe.Rivals and Fe.Rivals(x) or EMPTY
    for i = 1, #others do
      local r = others[i]
      r.state, r.at = "declined", now()
      Claim.Count("declined.auto")
      ns:Fire("CLAIMS_CHANGED", r)
      tell(r, 3)
    end
    local ok, took, later = pcall(settle, x)
    took = ok and took == true
    later = took and type(later) == "string" and later or nil
    Claim.Count(took and (later and "settled.later" or "settled.taken") or "settled.kept")
    markPaid(x, true)
    ns:Fire("CLAIM_SETTLED", x, took, later)
  end
  local code = STATE_CODE[state]
  if code then tell(x, code) end
end
if ns.Feud then ns.Feud.ClaimHook = onSet end

---------------------------------------------------------------------------
-- Start
---------------------------------------------------------------------------
ns:On("READY", function()
  local d = db()
  if not d then return end
  if d.earned ~= nil and type(d.earned) ~= "table" then d.earned = nil end
  if d.earned then sanitize(d.earned, now()) end
  sanitizeEnded(d, now())
  sessionAt = now()
  rewait()
  -- 1.7.0 fix JL-10: the takings back noted for this char go out once the guild is bound (and again for the friends,
  -- who answer later); older than CLAIM_AGE they are forgotten
  if d.bountyBack ~= nil and type(d.bountyBack) ~= "table" then d.bountyBack = nil end
  local bb = d.bountyBack
  if not bb then return end
  local t = now()
  for c, pend in pairs(bb) do
    if not plainName(c) or type(pend) ~= "table" then bb[c] = nil else
      for k, at in pairs(pend) do
        -- (fix JN-8) not from the future, and not when the char posted on the target again after it
        local own = type(d.bounty) == "table" and type(k) == "string" and d.bounty[k]
        local live = type(own) == "table" and type(own[c]) == "table" and own[c] or nil
        if type(k) ~= "string" or IsSecret(k) or P.ValidKey(k) == nil or not finite(at) or at < t - C.CLAIM_AGE
          or at > t + C.FUTURE or (live and finite(live.t) and live.t >= at) then
          pend[k] = nil
        end
      end
      if next(pend) == nil then bb[c] = nil end
    end
  end
  local mine = B.myFullName()
  if not mine or type(bb[mine]) ~= "table" then return end
  local A = _G.C_Timer and _G.C_Timer.After
  if not A then return end
  local tries = 0
  local send
  local function safe(last)
    local ok, err = pcall(send, last)
    if not ok and ns.ReportError then ns.ReportError(err) end
  end
  send = function(last)
    local d2 = db()
    local pend = d2 and type(d2.bountyBack) == "table" and d2.bountyBack[mine]
    local X = ns.Bounty
    if type(pend) ~= "table" or not (X and X.SendBack) then return end
    if B.inGuild() and not B.guildList() and tries < 10 then tries = tries + 1; A(30, function() safe(last) end); return end
    -- (fix JN-8) with the time of the taking back: only a bounty set before it goes at the others
    for k, at in pairs(pend) do X.SendBack(k, mine, at); Claim.Count("sentBack") end
    if last then d2.bountyBack[mine] = nil else A(60, function() safe(true) end) end
  end
  A(25, function() safe(false) end)
end)
