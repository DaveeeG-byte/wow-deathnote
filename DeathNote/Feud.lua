-- DeathNote - Feud.lua (1.6.0 feud)
-- The guilds behind the killers, a guild as a feud, the claim on a bounty, the expiry of old suspicions and the hard
-- cap of the own book. Data and rules only; the book shows it through FeudUI.lua. Nothing of this goes over the wire
-- except the "avenged" message V of Bounty.lua (its sending rule is wider now, the message itself is unchanged).
--
-- Data, account-wide, additive and language-neutral (no DB version):
--   DeathNoteDB.days, .dayAt   own play days (a calendar day with a login counts once), lifted from the friends' book
--                              (DeathNoteDB.friends.days stays as a copy for 1.5.0 after a downgrade)
--   deed.guild                 the guild the enemy wore at this deed (death, attack); e.guild stays "last seen"
--   e.revGuild                 { [guild] = n } the guilds of his revenges (at most REV_GUILDS); the rest of e.revenge
--                              belongs to e.guild (books before 1.6.0)
--   e.day                      play day of his last deed or sighting (expiry); e.keep = true: never expires
--   DeathNoteDB.feuds          { [guild name] = { t, by, seen } }, at most MAX_FEUDS; seen = last time one of them
--                              was in sight (the only thing a feud stores: never who, never where)
--   DeathNoteDB.claims         { { key, name, by, t, g, char, state, at, b } } newest first, at most MAX_CLAIMS, older than
--                              CLAIM_DAYS days go; state "open" | "paid" | "declined"; b (1.7.0, optional) = the time
--                              the bounty was set that the claim is for (one bounty, one open or paid claim; Claim.lua)
--   DeathNoteDB.expired        { [key] = entry with expiredAt } at most MAX_EXPIRED, the oldest go
--   DeathNoteDB.probe.feud     counters (guild of an enemy readable, empty, secret; expired; feud alarms; start time)

local ADDON, ns = ...
local Util = ns.Util
local IsSecret = Util.IsSecret

local Feud = {}
ns.Feud = Feud

Feud.MAX_FEUDS = 50
Feud.FEUD_GAP = 300          -- seconds: one quiet alarm per feud guild at most
Feud.MAX_CLAIMS = 50
Feud.CLAIM_DAYS = 30
Feud.EXPIRE_DAYS = 30        -- play days without a deed and without a sighting
Feud.MAX_EXPIRED = 200
Feud.BOOK_MAX = 3000         -- own book and archive together
Feud.REV_GUILDS = 5
Feud.NAME_MAX = 64

local function now() return time() end
local function finite(v) return type(v) == "number" and v == v and v > -math.huge and v < math.huge end
local function plainName(s)
  return not IsSecret(s) and type(s) == "string" and s ~= "" and #s <= Feud.NAME_MAX and not s:find("[%c|]")
end
Feud.PlainName = plainName
local function db() return ns.Store and ns.Store.DB and ns.Store.DB() or nil end

---------------------------------------------------------------------------
-- Probe (probe.feud): counters of this session, added to DeathNoteDB.probe.feud at logout and by /dn probe
---------------------------------------------------------------------------
local counts, initMs = {}, nil
function Feud.Count(name, n) counts[name] = (counts[name] or 0) + (n or 1) end
function Feud.InitTime(ms)
  if finite(ms) then initMs = math.floor(ms * 10 + 0.5) / 10 end
end
-- Tracker.lua: one read of GetGuildInfo on an enemy (raw value before Util.Str)
function Feud.GuildRead(raw)
  if IsSecret(raw) then Feud.Count("guildSecret")
  elseif type(raw) == "string" and raw ~= "" then Feud.Count("guildOk")
  else Feud.Count("guildEmpty") end
end
-- the stored counters plus this session's (the session's are moved over); the table, or nil without SavedVariables
function Feud.Flush()
  local d = db()
  if not d then return nil end
  if type(d.probe) ~= "table" then d.probe = {} end
  local p = d.probe.feud
  if type(p) ~= "table" then p = {}; d.probe.feud = p end
  for k, v in pairs(counts) do p[k] = (finite(p[k]) and p[k] or 0) + v end
  counts = {}
  if initMs then
    p.initMs = initMs
    if not finite(p.initMaxMs) or initMs > p.initMaxMs then p.initMaxMs = initMs end
  end
  return p
end
Feud.ProbeSnapshot = Feud.Flush
function Feud.Session() return counts, initMs end
ns:RegisterEvent("PLAYER_LOGOUT", function() pcall(Feud.Flush) end)

---------------------------------------------------------------------------
-- Play days (the friends' book reads the same counter)
---------------------------------------------------------------------------
function Feud.CountDay(d)
  d = d or db()
  if type(d) ~= "table" then return end
  local day = math.floor(now() / 86400)
  -- only a later calendar day counts (a clock set back and forth again counts nothing twice)
  if not finite(d.dayAt) or day > d.dayAt then d.dayAt = day; d.days = (finite(d.days) and d.days or 0) + 1
  -- fixer 2 1.6.0 (jb07): a remembered day in the future (one login with a clock far ahead) is set back to today without
  -- counting; every later day counts again. One day ahead is let be: a clock that goes back and forth over midnight
  -- must not count a day twice (beleg_a04)
  elseif day < d.dayAt - 1 then d.dayAt = day end
  -- 1.5.0 reads its own copy in the friends' book (a downgrade keeps counting from here)
  local f = d.friends
  if type(f) == "table" then f.days, f.dayAt = d.days, d.dayAt end
end
function Feud.Days()
  local d = db()
  return d and finite(d.days) and d.days or 0
end

-- the play day of an entry's last deed or sighting
function Feud.Touch(e)
  if type(e) == "table" then e.day = Feud.Days() end
end

---------------------------------------------------------------------------
-- The guild of a deed and of a revenge
---------------------------------------------------------------------------
function Feud.SanitizeEntry(e)
  local deeds = e.deaths
  if type(deeds) == "table" then
    for i = 1, #deeds do
      local d = deeds[i]
      if type(d) == "table" and d.guild ~= nil and not plainName(d.guild) then d.guild = nil end
    end
  end
  if e.revGuild ~= nil then
    local r, n, sum = e.revGuild, 0, 0
    if type(r) ~= "table" then e.revGuild = nil else
      for g, k in pairs(r) do
        if not plainName(g) or not finite(k) or k < 1 or n >= Feud.REV_GUILDS then r[g] = nil
        else r[g] = math.floor(k); n = n + 1; sum = sum + r[g] end
      end
      local rev = tonumber(e.revenge) or 0
      if sum > rev then
        -- more than the revenge (a revenge taken back by an older client): start over from "last seen"
        e.revGuild = nil
      elseif n == 0 then e.revGuild = nil end
    end
  end
  if e.day ~= nil and not (finite(e.day) and e.day >= 0) then e.day = nil end
  if e.keep ~= nil and e.keep ~= true then e.keep = nil end
  if e.statusHand ~= nil and e.statusHand ~= true then e.statusHand = nil end
end

-- Store.AddRevenge (+1) and Store.UndoRevenge (-1): the guild he wears now carries the revenge
function Feud.RevengeGuild(e, delta)
  local g = plainName(e.guild) and e.guild or nil
  if not g then return end
  local r = type(e.revGuild) == "table" and e.revGuild or nil
  if delta > 0 then
    if not r then r = {}; e.revGuild = r end
    if not r[g] then
      local n = 0
      for _ in pairs(r) do n = n + 1 end
      if n >= Feud.REV_GUILDS then return end
    end
    r[g] = (r[g] or 0) + 1
  elseif r and r[g] then
    r[g] = r[g] - 1
    if r[g] <= 0 then r[g] = nil end
    if next(r) == nil then e.revGuild = nil end
  end
end

---------------------------------------------------------------------------
-- "Which guilds kill you": evaluation only, cached until the book changes
---------------------------------------------------------------------------
local cache, dirty = nil, true
Feud.builds = 0              -- tests: how often the evaluation really ran
local function touch() dirty = true end
for _, ev in ipairs({ "ENEMY_REMOVED", "ENEMY_REKEYED", "REVENGE", "REVENGE_UNDONE", "FEUDS_CHANGED",
  "DEATH_RECORDED" }) do
  ns:On(ev, touch)
end
-- fixer 2 1.6.0 (je04): a sighting (Store.Seen, "seen") of an entry whose guild stayed the same changes only that
-- guild's "last seen" (no order depends on it): that one value is made again, the evaluation stays
local memberOf = setmetatable({}, { __mode = "k" })   -- entry -> the guild it was counted in at the last build
local seenOf                                           -- (below)
ns:On("ENEMY_UPDATED", function(key, why)
  if why ~= "seen" or dirty or not cache then dirty = true; return end
  local S = ns.Store
  local e = S and S.Get and type(key) == "string" and S.Get(key)
  local eg = type(e) == "table" and plainName(e.guild) and e.guild or nil
  if not e or memberOf[e] ~= eg then dirty = true; return end
  if not eg then return end
  for i = 1, #cache do
    if cache[i].name == eg then seenOf(cache[i]); Feud.seenOnly = (Feud.seenOnly or 0) + 1; return end
  end
  dirty = true
end)
function Feud.Touched() dirty = true end

local function memberLess(a, b)
  if (a.kills or 0) ~= (b.kills or 0) then return (a.kills or 0) > (b.kills or 0) end
  if (a.assists or 0) ~= (b.assists or 0) then return (a.assists or 0) > (b.assists or 0) end
  return tostring(a.key) < tostring(b.key)
end
local function guildLess(a, b)
  if a.deaths ~= b.deaths then return a.deaths > b.deaths end
  if a.feud ~= b.feud then return a.feud end
  if a.n ~= b.n then return a.n > b.n end
  if a.rev ~= b.rev then return a.rev > b.rev end
  return a.name < b.name
end

-- list of { name, deaths, rev, n, members = { entries }, seen, feud } (the list and its rows must not be changed)
function Feud.Guilds()
  if cache and not dirty then return cache end
  Feud.builds = Feud.builds + 1
  dirty = false
  local S = ns.Store
  local all = S and S.All and S.All() or {}
  local d = db()
  local feuds = d and type(d.feuds) == "table" and d.feuds or {}
  local list, by = {}, {}
  local function G(name)
    local g = by[name]
    if not g then
      g = { name = name, deaths = 0, rev = 0, n = 0, members = {}, times = {}, feud = feuds[name] ~= nil }
      by[name] = g
      list[#list + 1] = g
    end
    return g
  end
  for k in pairs(memberOf) do memberOf[k] = nil end
  for _, e in pairs(all) do
    local eg = plainName(e.guild) and e.guild or nil
    memberOf[e] = eg
    if eg then
      local g = G(eg)
      g.n = g.n + 1
      g.members[#g.members + 1] = e
      local ls = type(e.lastSeen) == "table" and tonumber(e.lastSeen.t) or nil
      if ls and ls > (g.seen or 0) then g.seen = ls end
    end
    -- own deaths by this guild: one per death (two of them in the same death count once), from the deeds' guild
    local deeds, inDeeds = e.deaths, 0
    if type(deeds) == "table" then
      for i = 1, #deeds do
        local x = deeds[i]
        if x.role == "kill" or x.role == "assist" then
          inDeeds = inDeeds + 1
          local dg = plainName(x.guild) and x.guild or eg
          if dg then
            local g = G(dg)
            local t = tonumber(x.t) or i
            if not g.times[t] then g.times[t] = true; g.deaths = g.deaths + 1 end
          end
        end
      end
    end
    -- kills and assists whose deeds left the entry (cap of 30 deeds): the guild he wears now
    local rest = (tonumber(e.kills) or 0) + (tonumber(e.assists) or 0) - inDeeds
    if rest > 0 and eg then local g = G(eg); g.deaths = g.deaths + rest end
    local rev = tonumber(e.revenge) or 0
    if rev > 0 then
      local counted = 0
      if type(e.revGuild) == "table" then
        for rg, k in pairs(e.revGuild) do
          if plainName(rg) and finite(k) and k > 0 then G(rg).rev = G(rg).rev + k; counted = counted + k end
        end
      end
      if rev > counted and eg then G(eg).rev = G(eg).rev + rev - counted end
    end
  end
  for name, f in pairs(feuds) do
    local g = G(name)
    local fs = type(f) == "table" and tonumber(f.seen) or nil
    if fs and fs > (g.seen or 0) then g.seen = fs end
  end
  for i = #list, 1, -1 do
    local g = list[i]
    g.times = nil
    if g.n == 0 and g.deaths == 0 and g.rev == 0 and not g.feud then table.remove(list, i) end
  end
  for i = 1, #list do table.sort(list[i].members, memberLess) end
  table.sort(list, guildLess)
  cache = list
  return list
end

-- a guild's "last seen": its members' and the feud's (as in the build)
seenOf = function(g)
  local s
  for _, e in ipairs(g.members) do
    local ls = type(e.lastSeen) == "table" and tonumber(e.lastSeen.t) or nil
    if ls and ls > (s or 0) then s = ls end
  end
  local d = db()
  local f = d and type(d.feuds) == "table" and d.feuds[g.name]
  local fs = type(f) == "table" and tonumber(f.seen) or nil
  if fs and fs > (s or 0) then s = fs end
  g.seen = s
end

-- the evaluation of one guild, or nil
function Feud.Guild(name)
  if not plainName(name) then return nil end
  local list = Feud.Guilds()
  for i = 1, #list do if list[i].name == name then return list[i] end end
  return nil
end

---------------------------------------------------------------------------
-- A guild as a feud
---------------------------------------------------------------------------
local function feudTable()
  local d = db()
  if not d then return nil end
  if type(d.feuds) ~= "table" then d.feuds = {} end
  return d.feuds
end
local function feudCount()
  local n = 0
  for _ in pairs(feudTable() or {}) do n = n + 1 end
  return n
end
Feud.FeudCount = feudCount

function Feud.Is(name)
  local d = db()
  return plainName(name) and d and type(d.feuds) == "table" and d.feuds[name] ~= nil or false
end

local updateHook
-- true | nil, reason ("name" | "cap")
function Feud.Declare(name)
  if not plainName(name) then return nil, "name" end
  local t = feudTable()
  if not t then return nil, "name" end
  if t[name] then return true end
  if feudCount() >= Feud.MAX_FEUDS then return nil, "cap" end
  t[name] = { t = now(), by = Util.PlayerFullName and Util.PlayerFullName() or nil }
  updateHook()
  ns:Fire("FEUDS_CHANGED", name, true)
  return true
end
function Feud.End(name)
  local t = feudTable()
  if not t or not plainName(name) or not t[name] then return false end
  t[name] = nil
  updateHook()
  ns:Fire("FEUDS_CHANGED", name, false)
  return true
end

local function sanitizeFeuds(d)
  if d.feuds ~= nil and type(d.feuds) ~= "table" then d.feuds = nil end
  local t = d.feuds
  if not t then return end
  local n, list = 0, {}
  for name, f in pairs(t) do
    if not plainName(name) or type(f) ~= "table" then t[name] = nil else
      if not finite(f.t) then f.t = 0 end
      if f.seen ~= nil and not finite(f.seen) then f.seen = nil end
      if f.by ~= nil and not plainName(f.by) then f.by = nil end
      n = n + 1
      list[#list + 1] = name
    end
  end
  if n > Feud.MAX_FEUDS then
    table.sort(list, function(a, b) return t[a].t > t[b].t end)
    for i = Feud.MAX_FEUDS + 1, #list do t[list[i]] = nil end
  end
end

-- The quiet alarm (Tracker.lua, only while there is a feud): a hostile player in sight who is not in the own book, the
-- guild's or friends' book or on the hit list, of a feud guild; in the open world only; once per guild per FEUD_GAP.
local lastAlarm = {}
function Feud.OnUnit(r, unit, how)
  if type(r) ~= "table" then return end
  local g = r.guild
  if not plainName(g) then return end
  local d = db()
  local f = d and type(d.feuds) == "table" and d.feuds[g]
  if type(f) ~= "table" then return end
  if not (Util.IsOpenWorld and Util.IsOpenWorld()) then return end
  local t = now()
  f.seen = t
  dirty = true
  local G = ns.Guild
  if G and G.Get then
    local ok, x = pcall(G.Get, r.key, "all")
    if ok and x then return end
  end
  if G and G.Hunt then
    local ok, x = pcall(G.Hunt, r.key, "all")
    if ok and x then return end
  end
  local gt = GetTime and GetTime() or t
  if lastAlarm[g] and gt - lastAlarm[g] < Feud.FEUD_GAP and gt >= lastAlarm[g] then return end
  lastAlarm[g] = gt
  Feud.Count("alarms")
  ns:Fire("FEUD_SPOTTED", g, r.key, unit, how)
end
function Feud.ResetAlarms() lastAlarm = {} end

updateHook = function()
  local T = ns.Tracker
  if not T then return end
  local d = db()
  local on = d and type(d.feuds) == "table" and next(d.feuds) ~= nil
  T.feudHook = on and Feud.OnUnit or nil
end
Feud.UpdateHook = function() updateHook() end

---------------------------------------------------------------------------
-- Claims on an own bounty (Bounty.lua: a V from someone else on a target with an own bounty)
---------------------------------------------------------------------------
local CLAIM_STATES = { open = true, paid = true, declined = true }
local function claimTable()
  local d = db()
  if not d then return nil end
  if type(d.claims) ~= "table" then d.claims = {} end
  return d.claims
end
local function sanitizeClaims(d)
  if d.claims ~= nil and type(d.claims) ~= "table" then d.claims = nil end
  local c = d.claims
  if not c then return end
  local t0 = now() - Feud.CLAIM_DAYS * 86400
  for k in pairs(c) do if type(k) ~= "number" or k < 1 or k > #c or k ~= math.floor(k) then c[k] = nil end end
  for i = #c, 1, -1 do
    local x = c[i]
    local ok = type(x) == "table" and plainName(x.key) and plainName(x.by) and finite(x.t) and x.t >= t0
      and finite(x.g) and x.g >= 0 and CLAIM_STATES[x.state]
    if ok then
      if x.char ~= nil and not plainName(x.char) then x.char = nil end
      if x.name ~= nil and not plainName(x.name) then x.name = nil end
      if x.at ~= nil and not finite(x.at) then x.at = nil end
      if x.b ~= nil and not finite(x.b) then x.b = nil end
    else
      table.remove(c, i)
    end
  end
  table.sort(c, function(a, b) return a.t > b.t end)
  -- 1.7.0 fix (JL-9, JN-2): over the cap the oldest declined claim goes first, then the oldest open one, a paid one
  -- last (it holds its bounty: one bounty, one paid claim)
  while #c > Feud.MAX_CLAIMS do
    local drop
    for _, st in ipairs({ "declined", "open" }) do
      for i = #c, 1, -1 do if c[i].state == st then drop = i; break end end
      if drop then break end
    end
    table.remove(c, drop or #c)
  end
end
Feud.SanitizeClaims = function() local d = db(); if d then sanitizeClaims(d) end end

-- one claim: key of the target, his shown name, who took him down (char), when, gold of the own bounty, own char
-- that posted it, (1.7.0) the time that bounty was set. The same kill once (1.7.0: per own char). Fires
-- CLAIM_NEW(claim). Returns the claim or nil.
function Feud.AddClaim(key, name, by, t, g, char, b)
  if not plainName(key) or not plainName(by) or not finite(t) or not finite(g) then return nil end
  local c = claimTable()
  if not c then return nil end
  char = plainName(char) and char or nil
  for i = 1, #c do
    local y = c[i]
    if y.key == key and y.by == by and math.abs(y.t - t) < 60 and (y.char == char or y.char == nil or char == nil) then
      return nil
    end
  end
  local x = { key = key, name = plainName(name) and name or nil, by = by, t = math.floor(t), g = math.floor(g),
    char = char, state = "open", b = finite(b) and math.floor(b) or nil }
  table.insert(c, 1, x)
  sanitizeClaims(db())
  -- 1.7.0 fix (JL-9): a claim the cap pushed out at once is no claim (no notice, no receipt "open")
  local kept = false
  for i = 1, #c do if c[i] == x then kept = true; break end end
  if not kept then return nil end
  Feud.Count("claims")
  ns:Fire("CLAIM_NEW", x)
  return x
end

function Feud.Claims()
  local c = claimTable() or {}
  return c
end
function Feud.OpenClaims()
  local n = 0
  for _, x in ipairs(Feud.Claims()) do if x.state == "open" then n = n + 1 end end
  return n
end
-- 1.7.0 fix (new E4): one bounty, one PAID claim. Two claims are on the same bounty when target and own char agree and
-- their bounty (b = first posting) is the same; a claim of 1.6.x without b is on the bounty when its kill came after
-- the bounty's first posting (JL-11)
local function skew() local G = ns.Guild; return G and G.C and G.C.CLAIM_SKEW or 300 end
local function sameBounty(y, x)
  if y == x or type(y) ~= "table" or y.key ~= x.key or y.char ~= x.char then return false end
  if x.b ~= nil and y.b ~= nil then return y.b == x.b end
  if x.b ~= nil then return finite(y.t) and y.t >= x.b - skew() end
  if y.b ~= nil then return finite(x.t) and x.t >= y.b - skew() end
  return false
end
Feud.SameBounty = sameBounty
-- the other claim PAID on the same bounty, or nil
function Feud.Rival(x)
  if type(x) ~= "table" then return nil end
  for _, y in ipairs(Feud.Claims()) do
    if y.state == "paid" and sameBounty(y, x) then return y end
  end
  return nil
end
-- the other claims OPEN on the same bounty (a new table, never nil)
function Feud.Rivals(x)
  local out = {}
  if type(x) ~= "table" then return out end
  for _, y in ipairs(Feud.Claims()) do
    if y.state == "open" and sameBounty(y, x) then out[#out + 1] = y end
  end
  return out
end

-- "paid" | "declined" | "open" (back); fires CLAIMS_CHANGED. 1.7.0: "paid" and "open" are false while another claim is
-- paid on the same bounty (Feud.Rival); after the change Feud.ClaimHook(claim, state, old) runs (Claim.lua: after
-- "paid" the other open claims on the bounty are declined and the bounty is taken back; the receipt to the killer)
function Feud.SetClaim(x, state)
  if type(x) ~= "table" or not CLAIM_STATES[state] then return false end
  local found = false
  for _, y in ipairs(Feud.Claims()) do if y == x then found = true; break end end
  if not found or x.state == state then return false end
  if (state == "open" or state == "paid") and Feud.Rival(x) then return false end
  local old = x.state
  x.state, x.at = state, now()
  ns:Fire("CLAIMS_CHANGED", x)
  local hook = Feud.ClaimHook
  if hook then
    local ok, err = pcall(hook, x, state, old)
    if not ok and ns.ReportError then ns.ReportError(err) end
  end
  return true
end

---------------------------------------------------------------------------
-- Expiry of old suspicions, the archive and the hard cap of the book (Store.Init, once per login)
---------------------------------------------------------------------------
-- only suspicions or only attacks, not by hand, nothing more (no kill, assist or revenge). 1.6.0 fix: an own note or
-- a standing set by hand (wanted, pardoned: e.statusHand) counts as by hand too
function Feud.MayKeep(e)
  if type(e) ~= "table" or e.manual == true or e.statusHand == true then return false end
  if type(e.note) == "string" and e.note:find("%S") then return false end
  if (tonumber(e.kills) or 0) > 0 or (tonumber(e.assists) or 0) > 0 or (tonumber(e.revenge) or 0) > 0 then return false end
  return (tonumber(e.suspected) or 0) > 0 or (tonumber(e.attacks) or 0) > 0
end

-- protected by the raw data (Sync.lua and Bounty.lua may not be up yet at the start): hit lists, bounties, feud guild
local function protected(d, key, e)
  if e.keep == true then return true end
  local feuds = type(d.feuds) == "table" and d.feuds or nil
  if feuds and plainName(e.guild) and feuds[e.guild] then return true end
  if type(d.bounty) == "table" and d.bounty[key] then return true end
  local f = type(d.friends) == "table" and d.friends or nil
  if f and ((type(f.hunts) == "table" and f.hunts[key]) or (type(f.bounty) == "table" and f.bounty[key])) then return true end
  local gl = type(d.guild) == "table" and type(d.guild.lists) == "table" and d.guild.lists or nil
  if gl then
    for _, L in pairs(gl) do
      if type(L) == "table" and ((type(L.hunts) == "table" and L.hunts[key]) or (type(L.bounty) == "table" and L.bounty[key])) then
        return true
      end
    end
  end
  return false
end
Feud.Protected = function(key, e) local d = db(); return d ~= nil and protected(d, key, e) end

function Feud.ExpireOn()
  local d = db()
  local b = d and type(d.settings) == "table" and d.settings.book
  return not (type(b) == "table" and b.expire == false)
end

local function sanitizeExpired(d)
  if d.expired ~= nil and type(d.expired) ~= "table" then d.expired = nil end
  local x = d.expired
  if not x then return 0 end
  local n = 0
  for key, e in pairs(x) do
    if not plainName(key) or type(e) ~= "table" or not finite(e.expiredAt) then x[key] = nil else n = n + 1 end
  end
  return n
end

local function oldestExpired(x)
  local k0, t0
  for k, e in pairs(x) do if not t0 or e.expiredAt < t0 or (e.expiredAt == t0 and k < k0) then k0, t0 = k, e.expiredAt end end
  return k0
end

local function lastActive(e)
  local t = 0
  for _, d in ipairs(type(e.deaths) == "table" and e.deaths or {}) do if (tonumber(d.t) or 0) > t then t = d.t end end
  local ls = type(e.lastSeen) == "table" and tonumber(e.lastSeen.t) or 0
  if ls > t then t = ls end
  return t
end

Feud.lastExpired, Feud.lastCapped = 0, 0
function Feud.OnInit(d, enemies)
  Feud.lastExpired, Feud.lastCapped = 0, 0
  -- fixer 2 1.6.0 (jb02): the book's own play days are new in 1.6.0: without them this is the first start with it
  local first160 = type(d.days) ~= "number"
  if type(d.days) ~= "number" then
    local f = type(d.friends) == "table" and d.friends or nil
    if f and finite(f.days) and f.days >= 0 then d.days = math.floor(f.days); if finite(f.dayAt) then d.dayAt = f.dayAt end end
  end
  if d.days ~= nil and not (finite(d.days) and d.days >= 0) then d.days = nil end
  if d.dayAt ~= nil and not finite(d.dayAt) then d.dayAt = nil end
  Feud.CountDay(d)
  local today = finite(d.days) and d.days or 0
  sanitizeFeuds(d)
  sanitizeClaims(d)
  local nx = sanitizeExpired(d)
  -- 1.6.0: the probe's death records only while /dn debug is on (they were the biggest block of the file)
  local st = type(d.settings) == "table" and d.settings or {}
  if st.debug ~= true and type(d.probe) == "table" and type(d.probe.deaths) == "table" and #d.probe.deaths > 0 then
    d.probe.deaths = {}
  end
  local b = type(st.book) == "table" and st.book or nil
  local on = not (b and b.expire == false)
  -- fixer 2 1.6.0 (jb02): at the first start with 1.6.0 a book of an older version knows no statusHand. What may have
  -- been set by hand there counts as set by hand and never expires: pardoned, or wanted with only suspicions or
  -- attacks; an entry made by hand; an entry with a note. Once: at the start that brings the play days.
  if first160 then
    for _, e in pairs(enemies) do
      if type(e) == "table" then
        local only = (tonumber(e.kills) or 0) == 0 and (tonumber(e.assists) or 0) == 0
        local noted = type(e.note) == "string" and e.note:find("%S") ~= nil
        if e.status == "pardoned" or (e.status == "wanted" and only) or e.manual == true or noted then e.statusHand = true end
      end
    end
  end
  local n = 0
  if on and type(d.expired) ~= "table" then d.expired = {} end
  local x = d.expired
  local t = now()
  for key, e in pairs(enemies) do
    n = n + 1
    if not finite(e.day) then e.day = today end
    if on and Feud.MayKeep(e) and today - e.day >= Feud.EXPIRE_DAYS and not protected(d, key, e) then
      enemies[key] = nil
      n = n - 1
      e.expiredAt = t
      if x[key] == nil then nx = nx + 1 end
      x[key] = e
      Feud.lastExpired = Feud.lastExpired + 1
    end
  end
  if x then
    while nx > Feud.MAX_EXPIRED do x[oldestExpired(x)] = nil; nx = nx - 1 end
  end
  -- hard cap: book and archive together; first the archive goes, then the oldest suspicions and attacks; deaths never
  if n + nx > Feud.BOOK_MAX then
    while x and nx > 0 and n + nx > Feud.BOOK_MAX do x[oldestExpired(x)] = nil; nx = nx - 1; Feud.lastCapped = Feud.lastCapped + 1 end
    if n > Feud.BOOK_MAX then
      local weak = {}
      for key, e in pairs(enemies) do
        if Feud.MayKeep(e) and not protected(d, key, e) then weak[#weak + 1] = { key, lastActive(e) } end
      end
      table.sort(weak, function(a, c) if a[2] ~= c[2] then return a[2] < c[2] end return a[1] < c[1] end)
      for i = 1, #weak do
        if n <= Feud.BOOK_MAX then break end
        enemies[weak[i][1]] = nil
        n = n - 1
        Feud.lastCapped = Feud.lastCapped + 1
      end
    end
  end
  if Feud.lastExpired > 0 then Feud.Count("expired", Feud.lastExpired) end
  if Feud.lastCapped > 0 then Feud.Count("capped", Feud.lastCapped) end
  dirty = true
end

-- the archive, newest first: { { key, e } } (the entries must not be changed)
function Feud.Expired()
  local d = db()
  local out = {}
  local x = d and type(d.expired) == "table" and d.expired or nil
  if not x then return out end
  for k, e in pairs(x) do out[#out + 1] = { key = k, e = e } end
  table.sort(out, function(a, b) if a.e.expiredAt ~= b.e.expiredAt then return a.e.expiredAt > b.e.expiredAt end return a.key < b.key end)
  return out
end
function Feud.ExpiredCount()
  local d = db()
  local n = 0
  for _ in pairs(d and type(d.expired) == "table" and d.expired or {}) do n = n + 1 end
  return n
end

-- back into the book, marked "keep" (it would leave again at the next login otherwise); false when the key is taken
function Feud.Restore(key)
  local d = db()
  local x = d and type(d.expired) == "table" and d.expired or nil
  local e = x and x[key]
  if not e or not ns.Store or not ns.Store.PutBack then return false end
  if ns.Store.Get(key) then x[key] = nil; ns:Fire("EXPIRED_CHANGED"); return false end
  e.expiredAt = nil
  e.keep = true
  Feud.Touch(e)
  x[key] = nil
  local ok = ns.Store.PutBack(key, e)
  ns:Fire("EXPIRED_CHANGED")
  return ok
end

-- "keep" on an entry (the poster's right-click menu): it never expires
function Feud.SetKeep(key, on)
  local S = ns.Store
  local e = S and S.Get(key)
  if not e then return false end
  e.keep = on and true or nil
  ns:Fire("ENEMY_UPDATED", key)
  return true
end

ns:On("READY", function()
  updateHook()
  local n = Feud.lastExpired or 0
  if n > 0 then
    local function say()
      if ns.Util and ns.Util.Print and ns.L and ns.F and ns.L.FEUD_EXPIRED_CHAT then
        ns.Util.Print(ns.F(ns.L.FEUD_EXPIRED_CHAT, { count = n }))
      end
    end
    local A = _G.C_Timer and _G.C_Timer.After
    if A then A(6, say) else say() end
  end
end)
