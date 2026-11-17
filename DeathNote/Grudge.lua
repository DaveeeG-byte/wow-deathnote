-- DeathNote - Grudge.lua (1.4.0 grudge)
-- Attacked without dying: who attacked me goes into a small notice (GrudgeCard.lua) with a tick and a cross per
-- attacker; a tick writes an attack into the book (role "attack", Store.AddAttack). Nothing is written without a tick.
--
-- There is no combat log on Forever. An enemy player counts as an attacker of the running episode when
--   a) he has me targeted, is in combat, and I take a hit (UNIT_COMBAT / UNIT_HEALTH on me) within HIT_WINDOW
--      seconds, or he casts a spell while he has me targeted;
--   b) my death names him (death recap through Attribution.lua: the killing blow is marked, the others took part);
--   c) the damage meter names him after the fight (only while it is readable, never secret; it only adds to an
--      episode that a) or b) opened: an older session must not start one).
-- Enemy = a player, attackable, not me, not in my group, not my duel partner, not the opponent of a duel to the death.
-- An episode starts with the first attacker, gathers the others (groups: all of them) and ends with the end of the
-- fight or my death. Who was answered (or let go) in the last ASKED_WINDOW seconds is not asked again.
-- Places: the open world (grudge.enabled); battlegrounds and arenas only with grudge.battlegrounds (off by default);
-- dungeons, raids and scenarios never.
-- No OnUpdate: events, and C_Timer for the short waits. Every value from the client goes through the guards of
-- Core.lua (IsSecret first, then compare). Unmeasured in the game: what of this the client delivers (probe.grudge).

local ADDON, ns = ...
local Util = ns.Util
local Call, IsSecret, Str, Num, True = Util.Call, Util.IsSecret, Util.Str, Util.Num, Util.True
local L, Fmt = ns.L, ns.F

local Grudge = {}
ns.Grudge = Grudge

Grudge.HIT_WINDOW = 2        -- seconds between a hit on me and the enemy that has me targeted (proof a)
Grudge.SCAN_EVERY = 0.25     -- seconds between two looks at the visible units after hits
Grudge.ASKED_WINDOW = 300    -- seconds: answered (or let go) is not asked again
Grudge.MAX_ROWS = 40         -- attackers kept per episode (the notice shows 8 and "+n")
Grudge.DEATH_WAIT = 6        -- seconds to wait for the evaluation of my death (Attribution reads at 0.5, 2 and 4 s)
Grudge.SECONDS = { 10, 20, 30, 60 }
Grudge.CASES = 5             -- episodes kept in probe.grudge.cases while /dn debug is on

local ep                     -- the episode of the notice, or nil
local nextId = 0
local asked = {}             -- key -> GetTime of the answer
local lastHit                -- GetTime of the last hit on me
local lastHP                 -- my last plain health (UNIT_HEALTH)
local lastScan, scanQueued = -1, false
local plates = {}            -- active nameplate tokens (own set: works where the tracker rests, battlegrounds)
local dueling                -- GetTime of a duel request or start, nil after the duel
local inCombat = false
local allowed = false        -- the place and the switches allow the notice right now
local unitFrame              -- own frame for the unit events of the player and the casts
local counts = { episodes = 0, rows = 0, a = 0, b = 0, c = 0, cast = 0, hits = 0, hitsCombat = 0, hitsHealth = 0,
  shown = 0, yes = 0, no = 0, expired = 0, meterOk = 0, meterSecret = 0, meterNone = 0, meterOnly = 0,
  combatUnknown = 0, dropped = 0 }
local meterLast              -- why the last meter read gave nothing ("secret", "keine Daten", ...) or "ok"
local events = {}            -- event -> registered (true/false), for the probe

local function now() return GetTime() end

---------------------------------------------------------------------------
-- Places and switches
---------------------------------------------------------------------------
-- "world" (open world), "pvp" (battleground, arena), "instance" (dungeon, raid, scenario) or "unknown" (secret)
function Grudge.Where()
  local inInstance, kind = Call(_G.IsInInstance)
  if IsSecret(inInstance) or IsSecret(kind) then return "unknown" end
  if inInstance ~= true and (type(kind) ~= "string" or kind == "none") then return "world" end
  if kind == "pvp" or kind == "arena" then return "pvp" end
  return "instance"
end

local function setting(path)
  local S = ns.Store
  if not (S and S.DB and S.DB()) then return nil end
  return S.Setting(path)
end

-- does the notice come here? where = Grudge.Where() (read when absent)
function Grudge.Allowed(where)
  if setting("grudge.enabled") == false or not (ns.Store and ns.Store.DB and ns.Store.DB()) then return false end
  where = where or Grudge.Where()
  if where == "world" then return true end
  if where == "pvp" then return setting("grudge.battlegrounds") == true end
  return false
end

-- seconds the notice stays after the fight (one of Grudge.SECONDS)
function Grudge.Seconds()
  local v = tonumber(setting("grudge.seconds"))
  for i = 1, #Grudge.SECONDS do if v == Grudge.SECONDS[i] then return v end end
  return 20
end

---------------------------------------------------------------------------
-- Reading a unit (every value guarded)
---------------------------------------------------------------------------
local INFO_STR = { "classLoc", "class", "raceLoc", "race" }
local function readInfo(unit, name, surname)
  local info = { name = name, surname = surname }
  info.guid = Str(Call(_G.UnitGUID, unit))
  local classLoc, class = Call(_G.UnitClass, unit)
  info.classLoc, info.class = Str(classLoc), Str(class)
  local raceLoc, race = Call(_G.UnitRace, unit)
  info.raceLoc, info.race = Str(raceLoc), Str(race)
  local level = Num(Call(_G.UnitLevel, unit))
  if level and level > 0 then info.level = level elseif level and level < 0 then info.skull = true end
  info.guild = Str(Call(_G.GetGuildInfo, unit))
  info.faction = Str(Call(_G.UnitFactionGroup, unit))
  info.sex = Num(Call(_G.UnitSex, unit))
  for i = 1, #INFO_STR do if info[INFO_STR[i]] == nil then info[INFO_STR[i]] = nil end end
  return info
end

local function myFaction() return Str(Call(_G.UnitFactionGroup, "player")) end

-- in combat? true, false, or nil when the client does not say (missing API, secret)
local function unitInCombat(unit)
  local fn = _G.UnitAffectingCombat
  if type(fn) ~= "function" then return nil end
  local v = Call(fn, unit)
  if IsSecret(v) or type(v) ~= "boolean" then return nil end
  return v
end

local function inMyGroup(unit)
  if True(Call(_G.UnitInParty, unit)) then return true end
  local r = Call(_G.UnitInRaid, unit)
  if not IsSecret(r) and type(r) == "number" then return true end
  return false
end

-- the opponent of a duel (to the death or not): never an attacker
local function duelFoe(unit, info)
  local A = ns.Attribution
  local full = info.surname and (info.name .. " " .. info.surname) or info.name
  if A and A.DuelFoe and A.DuelFoe(info.guid, full) then return true end
  if dueling and now() - dueling < 60 then
    -- a duel partner is of my own faction (a duel across factions does not exist)
    local mine = myFaction()
    if mine and info.faction == mine then return true end
  end
  return false
end

-- an enemy player behind the unit token: key, info (nil for everybody else). needTarget: he must have me targeted
local function enemyOf(unit, needTarget)
  if IsSecret(unit) or type(unit) ~= "string" then return nil end
  local T = ns.Tracker
  local key, name, surname
  if T and T.Identity then key, name, surname = T.Identity(unit) end
  if not key then return nil end
  if not True(Call(_G.UnitCanAttack, "player", unit)) then return nil end
  if inMyGroup(unit) then return nil end
  if needTarget and not True(Call(_G.UnitIsUnit, unit .. "target", "player")) then return nil end
  local info = readInfo(unit, name, surname)
  -- the GUID beats the first name: somebody known by first name only is not the book's entry of another GUID
  if not surname and info.guid and ns.Store then
    local e = ns.Store.Get(key)
    local eg = e and Str(e.guid)
    if eg and eg ~= info.guid and not ns.Store.ByGUID(info.guid) then return nil end
  end
  if duelFoe(unit, info) then return nil end
  return key, info
end
Grudge.EnemyOf = enemyOf

---------------------------------------------------------------------------
-- Episode
---------------------------------------------------------------------------
local function fire() ns:Fire("GRUDGE_UPDATE", ep) end

local function newEpisode()
  nextId = nextId + 1
  local zone, sub, mapID, x, y = Util.Zone()
  ep = { id = nextId, t = time(), gt = now(), lastNew = now(), running = true, rows = {}, order = {},
    zone = zone, subzone = sub, mapID = mapID, x = x, y = y, me = Util.PlayerFullName(),
    myLevel = Num(Call(_G.UnitLevel, "player")), proofs = {} }
  counts.episodes = counts.episodes + 1
  if Grudge.Watch then Grudge.Watch() end
  return ep
end

local function askedLately(key)
  local t = asked[key]
  return t ~= nil and now() - t < Grudge.ASKED_WINDOW
end

-- adds or updates an attacker. proof = "a" | "b" | "c"; opts: { kb = true, inBook = true }. Returns the row or nil.
local function addRow(key, info, proof, opts)
  if type(key) ~= "string" or type(info) ~= "table" then return nil end
  opts = opts or {}
  local row = ep and ep.rows[key]
  if not row then
    -- answered lately: not asked again (unless my death put him into the book anyway: the notice says so)
    if askedLately(key) and not opts.inBook then return nil end
    if not ep or ep.closed then
      if proof == "c" then counts.meterOnly = counts.meterOnly + 1; return nil end
      newEpisode()
    end
    if #ep.order >= Grudge.MAX_ROWS then counts.dropped = counts.dropped + 1; return nil end
    row = { key = key, at = now(), proofs = {} }
    ep.rows[key] = row
    ep.order[#ep.order + 1] = key
    ep.lastNew = now()
    counts.rows = counts.rows + 1
  end
  for k, v in pairs(info) do
    if not IsSecret(v) and (type(v) == "string" or type(v) == "number" or type(v) == "boolean") then
      if row[k] == nil or k == "level" or k == "skull" then row[k] = v end
    end
  end
  if not row.proofs[proof] then
    row.proofs[proof] = true
    counts[proof] = counts[proof] + 1
    ep.proofs[proof] = true
  end
  if opts.kb then row.kb = true end
  if opts.inBook then row.inBook = true end
  return row
end

-- the attackers in the order of the notice: the killing blow first, then in the order they came
function Grudge.Rows(e)
  e = e or ep
  if not e then return {} end
  local out = {}
  for i = 1, #e.order do out[#out + 1] = e.rows[e.order[i]] end
  table.sort(out, function(a, b)
    if (a.kb or false) ~= (b.kb or false) then return a.kb == true end
    return a.at < b.at
  end)
  return out
end

-- a row that waits for an answer (not in the book by my death, not answered yet)
function Grudge.Open(row) return type(row) == "table" and not row.inBook and row.state == nil end

-- does the episode ask anything? (only then the notice shows)
function Grudge.Asks(e)
  e = e or ep
  if not e or e.closed then return false end
  for _, key in ipairs(e.order) do if Grudge.Open(e.rows[key]) then return true end end
  return false
end

function Grudge.Current() return ep end

-- the notice counts what it shows (probe.grudge)
function Grudge.Count(what) if counts[what] then counts[what] = counts[what] + 1 end end

-- the player's answer for one attacker of the current episode: yes = tick (into the book), no = cross
function Grudge.Answer(key, yes)
  local e = ep
  local row = e and e.rows[key]
  if not Grudge.Open(row) then return false end
  row.state = yes and "yes" or "no"
  asked[key] = now()
  if yes then
    counts.yes = counts.yes + 1
    if not e.test and ns.Store and ns.Store.AddAttack then
      local info = {}
      for _, f in ipairs({ "name", "surname", "guid", "class", "classLoc", "race", "raceLoc", "level", "guild",
        "faction", "sex" }) do info[f] = row[f] end
      local rec = { t = e.t, zone = e.zone, subzone = e.subzone, mapID = e.mapID, x = e.x, y = e.y, me = e.me,
        myLevel = e.myLevel, theirLevel = row.level }
      row.bookKey = ns.Store.AddAttack(info, rec)
    end
  else
    counts.no = counts.no + 1
  end
  fire()
  return true
end

-- the notice went away (time out, right click): whoever was not answered is not entered, and not asked again for a
-- while either (the notice must not come back for the same player after every fight)
function Grudge.Close(why)
  local e = ep
  if not e then return end
  for _, key in ipairs(e.order) do
    local row = e.rows[key]
    if Grudge.Open(row) then
      row.state = "gone"
      asked[key] = now()
      counts.expired = counts.expired + 1
    end
  end
  e.closed, e.closedBy = true, why or "time"
  if not e.test and setting("debug") and ns.Store and ns.Store.DB() then
    local db = ns.Store.DB()
    if type(db.probe) ~= "table" then db.probe = {} end
    if type(db.probe.grudge) ~= "table" then db.probe.grudge = {} end
    local g = db.probe.grudge
    if type(g.cases) ~= "table" then g.cases = {} end
    local c = { t = e.t, rows = #e.order, death = e.death or false, by = e.closedBy, proofs = {}, yes = 0, no = 0, gone = 0 }
    for k in pairs(e.proofs) do c.proofs[#c.proofs + 1] = k end
    table.sort(c.proofs)
    c.proofs = table.concat(c.proofs, "")
    for _, key in ipairs(e.order) do
      local st = e.rows[key].state
      if st == "yes" then c.yes = c.yes + 1 elseif st == "no" then c.no = c.no + 1 elseif st == "gone" then c.gone = c.gone + 1 end
    end
    table.insert(g.cases, 1, c)
    while #g.cases > Grudge.CASES do table.remove(g.cases) end
  end
  ep = nil
  ns:Fire("GRUDGE_CLOSED", e)
  Grudge.UpdateEvents()
end

-- the end of the fight (or of the death's evaluation): the notice counts down from here
local endEpisode
-- safety net while an episode runs: should the end of the fight never be announced (PLAYER_REGEN_ENABLED), a look
-- every WATCH seconds ends it once I am out of combat (C_Timer, only while an episode runs)
Grudge.WATCH = 5
local watching = false
local function watch()
  watching = false
  if not ep or ep.closed or not ep.running or ep.deathPending or Grudge.pendingDeath then return end
  local fight = Call(_G.InCombatLockdown)
  if IsSecret(fight) or fight == true then
    local After = _G.C_Timer and _G.C_Timer.After
    if After then watching = true; After(Grudge.WATCH, watch) end
    return
  end
  inCombat = false
  endEpisode()
  Grudge.UpdateEvents()
end
function Grudge.Watch()
  if watching then return end
  local After = _G.C_Timer and _G.C_Timer.After
  if After then watching = true; After(Grudge.WATCH, watch) end
end

function endEpisode()
  if not ep or ep.closed then return end
  ep.running = false
  ep.endGT = now()
  fire()
end

---------------------------------------------------------------------------
-- Proof a: hits on me, enemies that have me targeted, casts
---------------------------------------------------------------------------
local FIXED = { "target", "focus", "mouseover", "party1target", "party2target", "party3target", "party4target" }

local function consider(unit, proof)
  local key, info = enemyOf(unit, true)
  if not key then return nil end
  local c = unitInCombat(unit)
  if c == false then return nil end
  if c == nil then counts.combatUnknown = counts.combatUnknown + 1 end
  local row = addRow(key, info, proof or "a")
  if row then
    -- a new attacker after the end of the fight: the episode runs again (the notice waits for its end)
    if ep.endGT and not ep.running then ep.running = true; ep.endGT = nil; Grudge.Watch() end
    fire()
  end
  return row
end
Grudge.Consider = consider

local function scan()
  scanQueued = false
  if not allowed then return end
  lastScan = now()
  for i = 1, #FIXED do consider(FIXED[i]) end
  for unit in pairs(plates) do consider(unit) end
end

local function scanSoon()
  local t = now()
  if t - lastScan >= Grudge.SCAN_EVERY then scan(); return end
  if scanQueued then return end
  scanQueued = true
  local After = _G.C_Timer and _G.C_Timer.After
  if After then After(Grudge.SCAN_EVERY - (t - lastScan), scan) else scan() end
end

-- a hit on me (any attack that is no heal); the enemies that have me targeted right now are looked at
function Grudge.OnHit(how)
  if not allowed then return end
  lastHit = now()
  counts.hits = counts.hits + 1
  if how == "health" then counts.hitsHealth = counts.hitsHealth + 1 else counts.hitsCombat = counts.hitsCombat + 1 end
  scanSoon()
end

-- a unit turned up or changed its target shortly after a hit (the hit came first, ±HIT_WINDOW)
local function onUnitSeen(unit)
  if not allowed or not lastHit or now() - lastHit > Grudge.HIT_WINDOW then return end
  consider(unit)
end

local NO_HIT = { HEAL = true, ENERGIZE = true }
local function onUnitCombat(unit, action)
  if unit ~= "player" then return end
  -- a secret or unknown action counts as a hit (rather too many: the notice is the filter)
  local a = Str(action)
  if a and NO_HIT[a] then return end
  Grudge.OnHit("combat")
end

local function onUnitHealth(unit)
  if unit ~= "player" then return end
  local hp = Num(Call(_G.UnitHealth, "player"))
  if not hp then return end
  local before = lastHP
  lastHP = hp
  if before and hp < before then Grudge.OnHit("health") end
end

local function onCast(unit)
  if not allowed or IsSecret(unit) or type(unit) ~= "string" then return end
  if not (plates[unit] or unit == "target" or unit == "focus" or unit == "mouseover") then return end
  local row = consider(unit)
  if row and not row.cast then row.cast = true; counts.cast = counts.cast + 1 end
end

local CAST_EVENTS = { "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_CHANNEL_START", "UNIT_SPELLCAST_SUCCEEDED" }
local castsOn = false

local function onUnitEvent(_, event, unit, a1)
  if event == "UNIT_COMBAT" then onUnitCombat(unit, a1)
  elseif event == "UNIT_HEALTH" then onUnitHealth(unit)
  else onCast(unit) end
end

local function ensureFrame()
  if unitFrame or type(_G.CreateFrame) ~= "function" then return unitFrame end
  local ok, f = pcall(_G.CreateFrame, "Frame")
  if not ok or not f then return nil end
  unitFrame = f
  f:SetScript("OnEvent", function(...)
    local okc, err = pcall(onUnitEvent, ...)
    if not okc then ns.ReportError(err) end
  end)
  return f
end

-- an event of the player only (RegisterUnitEvent where the client has it, else the plain event, filtered above)
local function registerPlayerEvent(f, ev)
  if f.RegisterUnitEvent and pcall(f.RegisterUnitEvent, f, ev, "player") then return true end
  return pcall(f.RegisterEvent, f, ev)
end

-- unit events only while the notice may come; the casts only in a fight or while an episode is open
function Grudge.UpdateEvents()
  local f = ensureFrame()
  if not f then return end
  local want = allowed
  for _, ev in ipairs({ "UNIT_COMBAT", "UNIT_HEALTH" }) do
    if want and not events[ev] then
      events[ev] = registerPlayerEvent(f, ev) and true or false
    elseif not want and events[ev] then
      pcall(f.UnregisterEvent, f, ev)
      events[ev] = nil
    end
  end
  if want then lastHP = Num(Call(_G.UnitHealth, "player")) end
  local casts = want and (inCombat or (ep ~= nil and not ep.closed))
  if casts ~= castsOn then
    castsOn = casts
    for _, ev in ipairs(CAST_EVENTS) do
      if casts then events[ev] = pcall(f.RegisterEvent, f, ev) and true or false
      else pcall(f.UnregisterEvent, f, ev) end
    end
  end
end

function Grudge.UpdateAllowed()
  local was = allowed
  allowed = Grudge.Allowed()
  if was and not allowed and ep and not ep.test then Grudge.Close("place") end
  Grudge.UpdateEvents()
  return allowed
end

---------------------------------------------------------------------------
-- Proof c: the damage meter after the fight (only plain values; it adds to an open episode only)
---------------------------------------------------------------------------
function Grudge.ReadMeter()
  local A = ns.Attribution
  if not (A and A.ReadMeter and A.Classify and A.Context) then meterLast = "no api"; return 0 end
  local ok, ev = pcall(A.ReadMeter)
  if not ok or type(ev) ~= "table" then meterLast = "error"; counts.meterNone = counts.meterNone + 1; return 0 end
  if not ev.ok then
    meterLast = ev.why or "empty"
    if ev.why == "secret" then counts.meterSecret = counts.meterSecret + 1 else counts.meterNone = counts.meterNone + 1 end
    return 0
  end
  meterLast = "ok"
  counts.meterOk = counts.meterOk + 1
  local ctx, n = A.Context(), 0
  for _, s in ipairs(ev.sources or {}) do
    local okc, c = pcall(A.Classify, s, ctx)
    if okc and type(c) == "table" and c.isPlayer and c.key and type(c.info) == "table" then
      local info = {}
      for k, v in pairs(c.info) do info[k] = v end
      if not duelFoe(nil, info) and addRow((c.key:gsub("#.*$", "")), info, "c") then n = n + 1 end
    end
  end
  if n > 0 then fire() end
  return n
end

---------------------------------------------------------------------------
-- Proof b: my death (Attribution.lua has evaluated it: DEATH_RECORDED)
---------------------------------------------------------------------------
local deathToken = 0

local function finishDeath()
  if not ep then return end
  ep.deathPending = nil
  endEpisode()
end

function Grudge.OnPlayerDead()
  if not allowed then return end
  deathToken = deathToken + 1
  local token = deathToken
  if ep and not ep.closed then
    ep.deathPending = token
    ep.running = true
  else
    -- no episode yet: the death may open one (deathPending marks the wait)
    ep = nil
  end
  Grudge.pendingDeath = token
  local After = _G.C_Timer and _G.C_Timer.After
  if After then
    After(Grudge.DEATH_WAIT, function()
      if Grudge.pendingDeath == token then
        Grudge.pendingDeath = nil
        if ep and ep.deathPending == token then finishDeath() end
      end
    end)
  end
end

-- journal = the death's journal row, fired = the key booked as killer (Attribution.lua: finalize)
function Grudge.OnDeathRecorded(journal, fired)
  if not Grudge.pendingDeath then return end
  Grudge.pendingDeath = nil
  if not allowed or type(journal) ~= "table" then
    if ep then finishDeath() end
    return
  end
  local A = ns.Attribution
  local last = A and A.last
  local res = type(last) == "table" and last.journal == journal and last.result or nil
  local counted = journal.counted == true
  if type(res) == "table" and res.kind == "pvp" then
    local infos = type(res.othersInfo) == "table" and res.othersInfo or {}
    local function add(key, info, kb, booked)
      if type(key) ~= "string" or type(info) ~= "table" then return end
      key = key:gsub("#.*$", "")
      local i2 = {}
      for k, v in pairs(info) do i2[k] = v end
      if duelFoe(nil, i2) then return end
      -- in the book by the death: the killer the journal names, the others when the death counted
      local row = addRow(key, i2, "b", { kb = kb, inBook = booked })
      if row and not ep.death then ep.death = true end
    end
    if res.killerKey and type(res.killerInfo) == "table" then
      local booked = counted and journal.killerKey ~= nil
      add(journal.killerKey or res.killerKey, res.killerInfo, res.sure == true, booked)
    end
    for _, k in ipairs(res.others or {}) do add(k, infos[k], false, counted) end
    -- candidates of an unclear death (several had me targeted): nobody is in the book, the notice asks
    for _, k in ipairs(res.candidates or {}) do
      if not (ep and ep.rows[(k:gsub("#.*$", ""))]) then add(k, infos[k], false, false) end
    end
  end
  if ep then
    ep.death = true
    finishDeath()
  end
end

---------------------------------------------------------------------------
-- Test (/dn rachsucht test): a notice with made-up names that writes nothing
---------------------------------------------------------------------------
Grudge.SAMPLE = {
  { name = "Grimmzahn", surname = "Probe", class = "ROGUE", level = 38, kb = true, inBook = true },
  { name = "Dornfels", surname = "Probe", class = "WARRIOR", level = 40 },
  { name = "Rabenruf", surname = "Probe", class = "MAGE", level = 39 },
}
function Grudge.Test(n)
  if ep and not ep.test then Grudge.Close("test") end
  ep = nil
  newEpisode()
  counts.episodes = counts.episodes - 1
  ep.test = true
  n = tonumber(n) or #Grudge.SAMPLE
  for i = 1, n do
    local s = Grudge.SAMPLE[(i - 1) % #Grudge.SAMPLE + 1]
    local info = { name = s.name, surname = i > #Grudge.SAMPLE and (s.surname .. i) or s.surname, class = s.class,
      level = s.level }
    local key = Util.KeyFor(info.name, info.surname)
    local row = { key = key, at = now() + i * 0.001, proofs = { a = true }, kb = s.kb and i == 1 or nil,
      inBook = s.inBook and i == 1 or nil }
    for k, v in pairs(info) do row[k] = v end
    ep.rows[key] = row
    ep.order[#ep.order + 1] = key
  end
  ep.death = n > 0 and Grudge.SAMPLE[1].kb or nil
  ep.running = false
  ep.endGT = now()
  fire()
  return ep
end

---------------------------------------------------------------------------
-- /dn rachsucht, /dn grudge: on/off; "test": the test notice
---------------------------------------------------------------------------
function Grudge.Slash(rest)
  L, Fmt = ns.L, ns.F
  rest = type(rest) == "string" and rest:lower() or ""
  local S = ns.Store
  if rest == "test" or rest == "probe" then
    Grudge.Test()
    Util.Print(L.CHAT_GRUDGE_TEST)
    return
  end
  if not (S and S.DB and S.DB()) then return end
  local on = S.Setting("grudge.enabled") == false
  S.Setting("grudge.enabled", on)
  Util.Print(on and L.CHAT_GRUDGE_ON or L.CHAT_GRUDGE_OFF)
end

---------------------------------------------------------------------------
-- Probe (/dn probe: probe.grudge)
---------------------------------------------------------------------------
function Grudge.ProbeSnapshot()
  local c = {}
  for k, v in pairs(counts) do c[k] = v end
  local ev = {}
  for k, v in pairs(events) do ev[k] = v end
  return { counts = c, meter = meterLast, events = ev, where = Grudge.Where(), allowed = allowed,
    enabled = setting("grudge.enabled") ~= false, battlegrounds = setting("grudge.battlegrounds") == true,
    combatApi = type(_G.UnitAffectingCombat) == "function", healthApi = type(_G.UnitHealth) == "function",
    open = ep ~= nil and not ep.closed }
end

-- tests: back to the state after loading
function Grudge.Reset()
  ep, asked, lastHit, lastHP, lastScan, scanQueued, plates, dueling = nil, {}, nil, nil, -1, false, {}, nil
  inCombat = false
  Grudge.pendingDeath = nil
  for k in pairs(counts) do counts[k] = 0 end
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------
ns:On("READY", function() Grudge.UpdateAllowed() end)
ns:On("SETTINGS_CHANGED", function(path)
  if type(path) == "string" and path:find("^grudge%.") then Grudge.UpdateAllowed() end
end)
ns:RegisterEvent("PLAYER_ENTERING_WORLD", function()
  plates = {}
  Grudge.UpdateAllowed()
end)
ns:RegisterEvent("ZONE_CHANGED_NEW_AREA", function() Grudge.UpdateAllowed() end)
ns:RegisterEvent("NAME_PLATE_UNIT_ADDED", function(_, unit)
  if IsSecret(unit) or type(unit) ~= "string" then return end
  plates[unit] = true
  onUnitSeen(unit)
end)
ns:RegisterEvent("NAME_PLATE_UNIT_REMOVED", function(_, unit)
  if not IsSecret(unit) and type(unit) == "string" then plates[unit] = nil end
end)
ns:RegisterEvent("UNIT_TARGET", function(_, unit)
  if IsSecret(unit) or type(unit) ~= "string" then return end
  if plates[unit] or unit == "target" or unit == "focus" or unit == "mouseover" then onUnitSeen(unit) end
end)
ns:RegisterEvent("PLAYER_TARGET_CHANGED", function() onUnitSeen("target") end)
ns:RegisterEvent("UPDATE_MOUSEOVER_UNIT", function() onUnitSeen("mouseover") end)
ns:RegisterEvent("PLAYER_REGEN_DISABLED", function()
  inCombat = true
  Grudge.UpdateEvents()
end)
ns:RegisterEvent("PLAYER_REGEN_ENABLED", function()
  inCombat = false
  local open = ep ~= nil and not ep.closed and not ep.test
  -- the meter after a fight with hits on me (also without an episode: the probe counts what it alone would name)
  if allowed and (open or (lastHit and now() - lastHit < 120)) then Grudge.ReadMeter() end
  if allowed and open and ep and not ep.deathPending and not Grudge.pendingDeath then endEpisode() end
  Grudge.UpdateEvents()
end)
ns:RegisterEvent("PLAYER_DEAD", function() Grudge.OnPlayerDead() end)
ns:On("DEATH_RECORDED", function(journal, fired) Grudge.OnDeathRecorded(journal, fired) end)
ns:RegisterEvent("DUEL_REQUESTED", function() dueling = now() end)
ns:RegisterEvent("DUEL_INBOUNDS", function() dueling = now() end)
ns:RegisterEvent("DUEL_FINISHED", function()
  local After = _G.C_Timer and _G.C_Timer.After
  if After then After(1, function() dueling = nil end) else dueling = nil end
end)
