-- DeathNote - Bounty.lua (1.2.1)
-- Own bounties shared with guild and friends, and "avenged": a killer of others taken down by one of us.
-- Messages (protocol in Sync.lua): B (a bounty or taking it back), Y (end of an answer: these were all bounties of a
-- char), V (a char killed a killer of others). 1.2.0 and 1.1.0 drop all three as "type" and keep their data as it is.
--
-- Data, all additive and language-neutral (no DB version):
--   DeathNoteDB.bounty   = { [key] = { [own char] = { g = whole gold, t = time set, b = book id } } }
--   <guild list>.bounty  = { [key] = { [char] = { g, t, b, via } } }   bounties others set in that guild
--   DeathNoteDB.friends.bounty                                          the same from friends
--   DeathNoteDB.avenged  = { [key] = { by = { [char] = n }, log = { { by, t } }, t = last } }
-- Everybody sends only his own bounties, nobody passes them on; the sender must be the char (Sync.lua checks it, and
-- Friends.lua the GUID of a friend). The addon pays nothing and checks nothing: a bounty is a promise between players.

local ADDON, ns = ...
local Util = ns.Util
local Guild = ns.Guild
if type(Guild) ~= "table" or type(Guild.Bridge) ~= "table" then return end

local B, P, C = Guild.Bridge, Guild.Proto, Guild.C
local IsSecret, Str, Call = Util.IsSecret, Util.Str, Util.Call

local X = {}
ns.Bounty = X
local Ext = {}
Guild.Ext = Ext

local EMPTY = {}
local VDELAY = 3          -- seconds an "avenged" notice waits: a "taken down" notice of the same kill wins
local AV_CHARS = 20       -- avengers remembered per target

local function now() return time() end
local function plainName(s)
  return type(s) == "string" and s ~= "" and #s <= C.MAX_FIELD and not s:find("[%c|]")
end
local function goldOK(g)
  return type(g) == "number" and g == math.floor(g) and g >= 1 and g <= C.BOUNTY_GOLD_MAX
end
local function db() return ns.Store and ns.Store.DB and ns.Store.DB() or nil end
local function fctx() local F = ns.Friends; return F and F.ctx or nil end
local function ownTable()
  local d = db()
  if not d then return nil end
  if type(d.bounty) ~= "table" then d.bounty = {} end
  return d.bounty
end

local function newest(x)
  local t = 0
  for _, r in pairs(x) do if r.t > t then t = r.t end end
  return t
end

-- the target whose newest bounty is the oldest (the one that leaves a full table), not `keep`
local function oldestKey(tbl, keep)
  local k0, t0
  for k, x in pairs(tbl) do
    if k ~= keep then
      local t = newest(x)
      if not t0 or t < t0 or (t == t0 and k < k0) then k0, t0 = k, t end
    end
  end
  return k0
end

-- Repairs a bounty table in place: broken records out, expired ones out (maxAge), at most BOUNTY_MAX targets.
-- own = true: an own bounty "from the future" (the clock was set back) is set to now, else dropped.
function X.Sanitize(tbl, t, maxAge, own)
  if type(tbl) ~= "table" then return 0 end
  local keys = 0
  for key, x in pairs(tbl) do
    local keep = type(key) == "string" and P.ValidKey(key) ~= nil and type(x) == "table"
    if keep then
      for c, r in pairs(x) do
        if not plainName(c) or type(r) ~= "table" or not goldOK(r.g) or not P.Finite(r.t)
          or (maxAge and r.t < t - maxAge) or (r.t > t + C.FUTURE and not own) then
          x[c] = nil
        else
          if r.t > t + C.FUTURE then r.t = t end
          if r.b ~= nil and not P.ValidBook(r.b) then r.b = nil end
          if r.via ~= nil and not plainName(r.via) then r.via = nil end
        end
      end
      keep = next(x) ~= nil
    end
    if keep then keys = keys + 1 else tbl[key] = nil end
  end
  while keys > C.BOUNTY_MAX do
    local k = oldestKey(tbl)
    if not k then break end
    tbl[k] = nil
    keys = keys - 1
  end
  return keys
end

-- "avenged" table: plain counters, plain log, at most AVENGED_MAX targets
function X.SanitizeAvenged(av)
  if type(av) ~= "table" then return 0 end
  local n = 0
  for key, a in pairs(av) do
    local keep = type(key) == "string" and P.ValidKey(key) ~= nil and type(a) == "table" and type(a.by) == "table"
    if keep then
      local chars = 0
      for c, k in pairs(a.by) do
        if not plainName(c) or not P.Finite(k) or k < 1 or chars >= AV_CHARS then a.by[c] = nil
        else a.by[c] = math.min(C.BAGGED_MAX, math.floor(k)); chars = chars + 1 end
      end
      if type(a.log) ~= "table" then a.log = {} end
      for i = #a.log, 1, -1 do
        local l = a.log[i]
        if type(l) ~= "table" or not plainName(l.by) or not P.Finite(l.t) then table.remove(a.log, i) end
      end
      while #a.log > C.BAGS_MAX do table.remove(a.log) end
      if not P.Finite(a.t) then a.t = 0 end
      keep = next(a.by) ~= nil
    end
    if keep then n = n + 1 else av[key] = nil end
  end
  while n > C.AVENGED_MAX do
    local k0, t0
    for k, a in pairs(av) do if not t0 or a.t < t0 then k0, t0 = k, a.t end end
    av[k0] = nil
    n = n - 1
  end
  return n
end

---------------------------------------------------------------------------
-- Own bounties
---------------------------------------------------------------------------
local function ownCount(char)
  local n = 0
  for _, x in pairs(ownTable() or EMPTY) do if x[char] then n = n + 1 end end
  return n
end

-- one own bounty out to the guild and the friends (gold 0: taken back)
local function share(key, char, g, t)
  local text = P.EncodeBounty(key, char, g, t, B.book())
  if not text then return end
  if B.canSendGuild() and B.guildList() then B.enqueue(text, "B") end
  local F = ns.Friends
  if F and F.Broadcast then F.Broadcast(text, "B") end
end

-- Sets the own bounty of the logged-in char on `key` (whole gold 1..BOUNTY_GOLD_MAX); nil or 0 takes it back.
-- Returns true | nil, reason ("key" | "me" | "gold" | "ours" | "cap" | "none").
function X.Set(key, gold)
  if IsSecret(key) or IsSecret(gold) or type(key) ~= "string" then return nil, "key" end
  local n, s = P.ValidKey(key)
  if not n then return nil, "key" end
  local mine = B.myFullName()
  local own = ownTable()
  if not mine or not own then return nil, "me" end
  if gold ~= nil and type(gold) ~= "number" then return nil, "gold" end
  gold = gold or 0
  if gold ~= 0 and not goldOK(gold) then return nil, "gold" end
  local x = own[key]
  local r = x and x[mine]
  local t = now()
  if gold == 0 then
    if not r then return nil, "none" end
    x[mine] = nil
    if next(x) == nil then own[key] = nil end
    share(key, mine, 0, t)
  else
    -- the own chars and guildmates or friends with DeathNote: no bounty (as with the hit list)
    if Guild.WhoIs and Guild.WhoIs(n, s) then return nil, "ours" end
    if not r and ownCount(mine) >= C.BOUNTY_PER_SENDER then return nil, "cap" end
    if r and r.g == gold then return true end
    if not x then x = {}; own[key] = x end
    x[mine] = { g = gold, t = t, b = B.book() }
    share(key, mine, gold, t)
  end
  B.updated()
  return true
end

-- whole gold of the own bounty of the logged-in char on key, or nil
function X.Own(key)
  if IsSecret(key) then return nil end
  local mine = B.myFullName()
  local x = type(key) == "string" and (ownTable() or EMPTY)[key]
  local r = x and mine and x[mine]
  return r and r.g or nil
end

-- the bounties on one target: own ones (all chars of the account), the guild's (while in it) and the friends', one
-- row per char (the newest). Rows { char, g, t, own, mine }, biggest first; second value: the sum in gold.
function X.Rows(key)
  -- (1.2.1 fix: without any bounty no tables are built: the poster asks on every refresh)
  if not X.Has(key) then return EMPTY, 0 end
  local out, seen, sum = {}, {}, 0
  local mine = B.myFullName()
  local age = Guild.ExpireAge and Guild.ExpireAge()
  local t0 = now()
  local function add(x, own)
    if type(x) ~= "table" then return end
    for c, r in pairs(x) do
      if not (age and r.t < t0 - age) then
        local have = seen[c]
        if not have then
          have = { char = c, g = r.g, t = r.t, own = own, mine = c == mine }
          seen[c] = have
          out[#out + 1] = have
        elseif not have.own and r.t > have.t then
          have.g, have.t = r.g, r.t
        end
      end
    end
  end
  add((ownTable() or EMPTY)[key], true)
  local gb = B.inGuild() and B.gctx.bounty
  if gb then add(gb[key], false) end
  local fc = fctx()
  if fc and fc.bounty then add(fc.bounty[key], false) end
  table.sort(out, function(a, b) if a.g ~= b.g then return a.g > b.g end return a.char < b.char end)
  for i = 1, #out do sum = sum + out[i].g end
  return out, sum
end

-- one record of x not older than t0 (t0 nil: no expiry)
local function live(x, t0)
  if not x then return false end
  if not t0 then return true end
  for _, r in pairs(x) do if r.t >= t0 then return true end end
  return false
end

-- is there any bounty on key? (cheap: one look per table, read for every row of a list; 1.2.1 fix: an expired one
-- does not count, the same rule as X.Rows)
function X.Has(key)
  if IsSecret(key) or type(key) ~= "string" then return false end
  local age = Guild.ExpireAge and Guild.ExpireAge()
  local t0 = age and now() - age or nil
  local own = ownTable()
  if own and live(own[key], t0) then return true end
  local gb = B.inGuild() and B.gctx.bounty
  if gb and live(gb[key], t0) then return true end
  local fc = fctx()
  return fc ~= nil and fc.bounty ~= nil and live(fc.bounty[key], t0)
end

Guild.SetBounty, Guild.Bounties, Guild.HasBounty, Guild.OwnBounty = X.Set, X.Rows, X.Has, X.Own

-- the own bounties of the logged-in char, newest first: { { key, g, t } } (/dn kopfgeld without anything)
function X.OwnList()
  local out, mine = {}, B.myFullName()
  if not mine then return out end
  for key, x in pairs(ownTable() or EMPTY) do
    local r = x[mine]
    if r then out[#out + 1] = { key = key, g = r.g, t = r.t } end
  end
  table.sort(out, function(a, b) if a.t ~= b.t then return a.t > b.t end return a.key < b.key end)
  return out
end

---------------------------------------------------------------------------
-- Receiving (Sync.lua apply: the sender is checked already)
---------------------------------------------------------------------------
local function fresh(ctx, who, t)
  local s = ctx.fresh[who]
  if not s then s = { at = t or now(), n = 0, w = 0 }; ctx.fresh[who] = s end
  return s
end

-- the answer window after the OWN hello on this channel, kept open for a sender while his answer comes (Sync.lua)
local function window(ctx, who)
  return Guild.AnswerWindow(ctx, who)
end

-- new bounties per sender: in the own answer window at most BOUNTY_REPLY, else HUNT_LIVE_MAX in HUNT_LIVE_WINDOW
local function mayTake(ctx, who, t)
  local s = fresh(ctx, who, t)
  local ha = window(ctx, who)
  if ha then
    if s.bwin ~= ha then s.bwin, s.bw = ha, 0 end
    if s.bw >= C.BOUNTY_REPLY then return false end
    s.bw = s.bw + 1
    return true
  end
  if not s.bat or t - s.bat > C.HUNT_LIVE_WINDOW then s.bat, s.bn = t, 0 end
  if s.bn >= C.HUNT_LIVE_MAX then return false end
  s.bn = s.bn + 1
  return true
end

-- the B of one sender in the own answer window are noted; his Y says how many his answer had (like Z)
local function noteB(ctx, who, key)
  local ha = window(ctx, who)
  if not ha then return end
  local s = fresh(ctx, who)
  if s.ywin ~= ha then s.ywin, s.ykeys, s.yn = ha, {}, 0 end
  if not s.ykeys[key] then s.ykeys[key] = true; s.yn = s.yn + 1 end
end

-- Y: the numbers agree, so every other bounty of this char from the same book is taken back (1.2.1 fix: on GUILD
-- the copy in the friends' book too, as with a taking back with gold 0)
local function applySnap(ctx, tb, m, who)
  local ha = window(ctx, who)
  if not ha or not m.b then return false end
  local s = ctx.fresh[who]
  local keys = s and s.ywin == ha and s.ykeys or EMPTY
  local got = s and s.ywin == ha and s.yn or 0
  if got ~= m.n then return false end
  local n = 0
  local fc = ctx == B.gctx and fctx() or nil
  local other = fc and fc.bounty ~= tb and fc.bounty or nil
  for pass = 1, other and 2 or 1 do
    local tt = pass == 1 and tb or other
    for key, x in pairs(tt) do
      if not keys[key] then
        local r = x[m.by]
        if r and r.b == m.b then x[m.by] = nil; n = n + 1 end
        if next(x) == nil then tt[key] = nil end
      end
    end
  end
  if s then s.ywin, s.ykeys, s.yn = nil, nil, nil end
  return n > 0
end

local function takeBack(tb, key, char, t)
  local x = tb and tb[key]
  local r = x and x[char]
  if not r or r.t > t then return false end
  x[char] = nil
  if next(x) == nil then tb[key] = nil end
  return true
end

local function ownerBounties(tb, owner)
  local n = 0
  for _, x in pairs(tb) do for c, r in pairs(x) do if P.OwnerOf(c, r) == owner then n = n + 1 end end end
  return n
end

local function drop(st, why) st.dropped = st.dropped + 1; st.lastReason = why end

local function applyB(ctx, m, short, full, t)
  local st, tb = ctx.stats, ctx.bounty
  if not tb then return end
  st.bountyReceived = (st.bountyReceived or 0) + 1
  if m.g == 0 then
    -- taken back: only his own (the sender is the char), not a newer one; on GUILD the copy in the friends'
    -- book goes too (a friend who became a guildmate hears no whispers any more)
    local hit = takeBack(tb, m.key, m.by, m.t)
    local fc = ctx == B.gctx and fctx() or nil
    if fc and fc.bounty and fc.bounty ~= tb and takeBack(fc.bounty, m.key, m.by, m.t) then hit = true end
    if hit then B.updated() end
    return
  end
  noteB(ctx, full, m.key)
  local age = Guild.ExpireAge and Guild.ExpireAge()
  if age and m.t < t - age then drop(st, "old"); return end
  local x = tb[m.key]
  local have = x and x[m.by]
  -- the same or an older one changes nothing (the usual repeat in every answer): out before the costly check below
  if have and (m.t < have.t or (have.g == m.g and have.t == m.t)) then return end
  -- 1.2.1 fix: never on an own char or on guildmates or friends with DeathNote (the same rule as X.Set)
  if Guild.WhoIs and Guild.WhoIs(P.ValidKey(m.key)) then drop(st, "ours"); return end
  local owner = short:lower()
  local via = owner ~= m.by:lower() and short or nil
  if have then
    have.g, have.t, have.via = m.g, m.t, via
    if m.b then have.b = m.b end
    B.updated()
    return
  end
  -- the same owner under another spelling of his char: replaced, does not count twice
  local replace
  if x then for c, r in pairs(x) do if P.OwnerOf(c, r) == owner then replace = c end end end
  if not replace then
    if not mayTake(ctx, full, t) then drop(st, "later"); return end
    if ownerBounties(tb, owner) >= C.BOUNTY_PER_SENDER then drop(st, "cap"); return end
  end
  if not x then
    local n = 0
    for _ in pairs(tb) do n = n + 1 end
    if n >= C.BOUNTY_MAX then
      local k = oldestKey(tb, m.key)
      if not k then drop(st, "cap"); return end
      tb[k] = nil
    end
    x = {}
    tb[m.key] = x
  end
  if replace then x[replace] = nil end
  x[m.by] = { g = m.g, t = m.t, b = m.b, via = via }
  B.updated()
end

---------------------------------------------------------------------------
-- Avenged (V)
---------------------------------------------------------------------------
local function avTable()
  local d = db()
  if not d then return nil end
  if type(d.avenged) ~= "table" then d.avenged = {} end
  return d.avenged
end

-- One kill (by, t) of key counts once: the last BAGS_MAX are remembered per target; false when known or too old.
function X.Record(key, by, t)
  local av = avTable()
  if not av or IsSecret(key) or IsSecret(by) or IsSecret(t) then return false end
  if type(key) ~= "string" or not plainName(by) or not P.Finite(t) then return false end
  t = math.floor(t)
  local a = av[key]
  if not a then
    local n, k0, t0 = 0, nil, nil
    for k, y in pairs(av) do
      n = n + 1
      if not t0 or y.t < t0 then k0, t0 = k, y.t end
    end
    if n >= C.AVENGED_MAX and k0 then av[k0] = nil end
    a = { by = {}, log = {}, t = t }
    av[key] = a
  end
  local log, oldest = a.log, nil
  for i = 1, #log do
    local l = log[i]
    if l.by == by and math.abs(l.t - t) < C.BAG_DEDUPE then return false end
    if not oldest or l.t < oldest then oldest = l.t end
  end
  if #log >= C.BAGS_MAX and oldest and t <= oldest then return false end
  if not a.by[by] then
    local chars = 0
    for _ in pairs(a.by) do chars = chars + 1 end
    if chars >= AV_CHARS then return false end
  end
  log[#log + 1] = { by = by, t = t }
  table.sort(log, function(p, q) return p.t > q.t end)
  while #log > C.BAGS_MAX do table.remove(log) end
  a.by[by] = math.min(C.BAGGED_MAX, (a.by[by] or 0) + 1)
  if t > (a.t or 0) then a.t = t end
  return true
end

-- who took key down for the others: rows { char, n } (most first), total (1.2.1 fix: nothing known, no new table)
function X.Avenged(key)
  local a = type(key) == "string" and not IsSecret(key) and (avTable() or EMPTY)[key]
  if not a then return EMPTY, 0 end
  local out, total = {}, 0
  for c, n in pairs(a.by) do out[#out + 1] = { char = c, n = n }; total = total + n end
  table.sort(out, function(p, q) if p.n ~= q.n then return p.n > q.n end return p.char < q.char end)
  return out, total
end
Guild.Avenged = X.Avenged

-- only the total (a row of the guild list asks for it on every refresh: no table)
function X.AvengedTotal(key)
  local a = type(key) == "string" and not IsSecret(key) and (avTable() or EMPTY)[key]
  if not a then return 0 end
  local total = 0
  for _, n in pairs(a.by) do total = total + n end
  return total
end
Guild.AvengedTotal = X.AvengedTotal

local function mayAv(ctx, who, t)
  local s = fresh(ctx, who, t)
  if not s.avAt or t - s.avAt > C.BAG_WINDOW then s.avAt, s.av = t, 0 end
  return s.av < C.AVENGE_PER_SENDER
end

local function applyV(ctx, m, short, full, t)
  local st = ctx.stats
  -- live only, like E: older than 10 minutes or from the future is dropped
  if t - m.t > C.BAG_FRESH or m.t - t > C.FUTURE then drop(st, "time"); return end
  local e = ctx.store and ctx.store.enemies[m.key]
  local S = ns.Store
  local own = S and S.Get and S.Get(m.key)
  local mineHit = type(own) == "table" and ((tonumber(own.kills) or 0) > 0 or (tonumber(own.assists) or 0) > 0)
  -- a target nobody here knows as a killer: not kept (no poster would show it)
  if not ((e and #e.deeds > 0) or mineHit) then return end
  if not mayAv(ctx, full, t) then drop(st, "flood"); return end
  if not X.Record(m.key, m.by, m.t) then return end
  local s = ctx.fresh[full]
  s.av = s.av + 1
  st.avengedReceived = (st.avengedReceived or 0) + 1
  B.updated()
  -- "for you" only to whom the killer killed or with whom he took part; one notice per kill: when the same
  -- kill comes as "taken down" (target of the hit list), that message is the one
  -- (1.2.1 fix: also with e = 1 the notice waits and asks; when that E never came, "avenged" is the one notice)
  if not mineHit or B.setting("announceHunt") == false then return end
  local key, by, when = m.key, m.by, m.t
  local function fire()
    if B.setting("announceHunt") == false then return end
    if Guild.BagSeen and Guild.BagSeen(key, by, when) then return end
    ns:Fire("AVENGED", key, by, when)
  end
  local After = _G.C_Timer and _G.C_Timer.After
  if After then After(VDELAY, fire) else fire() end
end

function Ext.apply(ctx, m, short, full, t)
  local kind = m.kind
  if kind == "V" then return applyV(ctx, m, short, full, t) end
  if not ctx.bounty then return end
  if kind == "Y" then
    if applySnap(ctx, ctx.bounty, m, full) then B.updated() end
    return
  end
  return applyB(ctx, m, short, full, t)
end

---------------------------------------------------------------------------
-- Answer to a hello: every own bounty of the logged-in char, then Y (after the Z of the releases)
---------------------------------------------------------------------------
function Ext.answer(ctx, send, mine, book)
  local own = ownTable()
  if not mine or not own then return end
  local list = {}
  for key, x in pairs(own) do
    local r = x[mine]
    if r then list[#list + 1] = { key = key, r = r } end
  end
  table.sort(list, function(a, b) if a.r.t ~= b.r.t then return a.r.t > b.r.t end return a.key < b.key end)
  local sent = 0
  for i = 1, math.min(#list, C.BOUNTY_REPLY) do
    local r = list[i].r
    local ok, why = send(P.EncodeBounty(list[i].key, mine, r.g, r.t, r.b or book), "B")
    if ok or why == "dup" then sent = sent + 1 end
  end
  if #list <= C.BOUNTY_REPLY and sent == #list then send(P.EncodeBountySnapshot(mine, sent, book), "Y") end
end

---------------------------------------------------------------------------
-- Own killing blow (Sync.lua Guild.OnPartyKill): V to the guild and to the friends whose death it answers
---------------------------------------------------------------------------
-- anything to look for at all (cheap, every own killing blow)
function Ext.wants()
  local g = B.gctx.store
  if g and (g.count or 0) > 0 then return true end
  local fc = fctx()
  return fc ~= nil and (fc.store.count or 0) > 0
end

local function inBooks(k)
  if type(k) ~= "string" then return nil end
  local fc = fctx()
  if B.gctx.store.enemies[k] or (fc and fc.store.enemies[k]) then return k end
  return nil
end

-- key of the killed player in the guild or friends' book: tracker, own book, else a unique first name there
local function keyFor(guid)
  local k, sure = Guild.KeyOfGUID(guid, inBooks)
  if k or sure then return k end
  local _, _, _, _, _, name = Call(_G.GetPlayerInfoByGUID, guid)
  name = Str(name)
  if not name then return nil end
  local first = (name:match("^([^%s%-]+)") or name):lower()
  local found
  local fc = fctx()
  for pass = 1, 2 do
    local st = pass == 1 and B.gctx.store or (fc and fc.store)
    if st then
      for key, e in pairs(st.enemies) do
        if type(e.name) == "string" and e.name:lower() == first then
          if found and found ~= key then return nil end
          found = key
        end
      end
    end
  end
  return found
end

-- killed somebody who is not one of my own chars?
local function othersKilled(e, mine)
  for i = 1, #e.deeds do
    local v = e.deeds[i].victim
    if type(v) == "string" and v ~= mine and not Guild.IsOwnChar(v) then return true end
  end
  return false
end

function Ext.partyKill(guid, t, mine, bagG, bagF)
  local key = keyFor(guid)
  if not key then return end
  local g = B.gctx.store.enemies[key]
  local fc = fctx()
  local fe = fc and fc.store.enemies[key]
  local toGuild = g ~= nil and B.inGuild() and B.guildList() ~= nil and othersKilled(g, mine)
  -- friends: only those whose death the killed one answers for (never everybody: the addon does not report every kill)
  local F = ns.Friends
  local names
  if fe and F and F.FriendOf then
    for i = 1, #fe.deeds do
      local v = fe.deeds[i].victim
      if type(v) == "string" and v ~= mine and not Guild.IsOwnChar(v) then
        local x = F.FriendOf(v)
        if x then names = names or {}; names[x.name] = true end
      end
    end
  end
  if not toGuild and not names then return end
  X.Record(key, mine, t)
  if toGuild and B.canSendGuild() then B.enqueue(P.EncodeAvenged(key, mine, t, bagG), "V") end
  if names then
    local text = P.EncodeAvenged(key, mine, t, bagF)
    for name in pairs(names) do F.SendTo(name, text, "V") end
  end
  B.updated()
end

---------------------------------------------------------------------------
-- Lists, clean-up, expiry
---------------------------------------------------------------------------
function Ext.useList(L, gctx)
  if type(L.bounty) ~= "table" then L.bounty = {} end
  X.Sanitize(L.bounty, now(), Guild.ExpireAge and Guild.ExpireAge())
  gctx.bounty = L.bounty
end

-- "Empty guild book": the bounties others set in this guild go
function Ext.clear(L)
  if type(L.bounty) == "table" then for k in pairs(L.bounty) do L.bounty[k] = nil end end
end

-- bounties of chars `keep` refuses (a friend removed or unbound); returns the number dropped
function X.Purge(ctx, keep)
  local tb = ctx and ctx.bounty
  if type(tb) ~= "table" then return 0 end
  local n = 0
  for key, x in pairs(tb) do
    for c in pairs(x) do if not keep(c) then x[c] = nil; n = n + 1 end end
    if next(x) == nil then tb[key] = nil end
  end
  return n
end

-- releases expire after the days of "Calls last" (guild.huntExpire); bounties too. An expired own bounty of the
-- logged-in char is taken back (sent); one of another own char goes quietly (its next answer says it with Y).
local function expire()
  local age = Guild.ExpireAge and Guild.ExpireAge()
  if not age then return end
  local t, mine = now(), B.myFullName()
  local own = ownTable()
  for key, x in pairs(own or EMPTY) do
    for c, r in pairs(x) do
      if type(r) == "table" and P.Finite(r.t) and r.t < t - age then
        x[c] = nil
        if c == mine then share(key, c, 0, t) end
      end
    end
    if next(x) == nil then own[key] = nil end
  end
  if B.gctx.bounty then X.Sanitize(B.gctx.bounty, t, age) end
  local fc = fctx()
  if fc and fc.bounty then X.Sanitize(fc.bounty, t, age) end
end

ns:On("READY", function()
  local d = db()
  if not d then return end
  local t = now()
  if d.bounty ~= nil and type(d.bounty) ~= "table" then d.bounty = nil end
  if d.bounty then
    X.Sanitize(d.bounty, t, nil, true)
    -- at most BOUNTY_PER_SENDER own bounties per char (the newest stay)
    local per = {}
    for key, x in pairs(d.bounty) do for c, r in pairs(x) do per[c] = per[c] or {}; table.insert(per[c], { key, r.t }) end end
    for c, l in pairs(per) do
      if #l > C.BOUNTY_PER_SENDER then
        table.sort(l, function(a, b) return a[2] > b[2] end)
        for i = C.BOUNTY_PER_SENDER + 1, #l do
          local x = d.bounty[l[i][1]]
          x[c] = nil
          if next(x) == nil then d.bounty[l[i][1]] = nil end
        end
      end
    end
  end
  if d.avenged ~= nil and type(d.avenged) ~= "table" then d.avenged = nil end
  if d.avenged then X.SanitizeAvenged(d.avenged) end
  local fc, F = fctx(), ns.Friends
  local fdb = F and F.DB and F.DB()
  if fc and fdb then
    if type(fdb.bounty) ~= "table" then fdb.bounty = {} end
    X.Sanitize(fdb.bounty, t, Guild.ExpireAge and Guild.ExpireAge())
    fc.bounty = fdb.bounty
  end
  expire()
end)

-- 1.2.1 fix: a target struck from the own book keeps no own bounty of this char when no other book or the hit list
-- shows him any more (no poster: nobody could see or take it back)
ns:On("ENEMY_REMOVED", function(key)
  if type(key) ~= "string" or not X.Own(key) then return end
  local G = Guild
  if (G.Get and G.Get(key, "all")) or (G.Hunt and G.Hunt(key, "all")) then return end
  if X.Set(key, 0) and ns.Util and ns.Util.Print and ns.L and ns.F then
    ns.Util.Print(ns.F(ns.L.CHAT_BOUNTY_OFF, { name = (key:gsub("%-", " ")) }))
  end
end)

ns:On("SETTINGS_CHANGED", function(path)
  if path == "guild.huntExpire" then expire(); B.updated() end
end)
