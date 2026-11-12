-- DeathNote - Tracker.lua
-- Hostile players in sight (nameplates, target, mouseover, focus, group targets).
-- Small buffer of recent sightings for the killer search; updates listed enemies.

local ADDON, ns = ...
local Util = ns.Util
local Call, IsSecret, Str, True = Util.Call, Util.IsSecret, Util.Str, Util.True

local Tracker = {}
ns.Tracker = Tracker

Tracker.TTL = 60            -- seconds a sighting stays in the buffer
Tracker.MAX = 40            -- hard cap of the buffer
Tracker.WRITE_EVERY = 5     -- seconds between lastSeen writes per listed enemy
Tracker.ENCOUNTER_GAP = 60  -- seconds without sighting that start a new "sighting"
Tracker.INFO_REFRESH = 10   -- seconds before identity fields of a record are read again

local buffer, count = {}, 0   -- key -> record
local byGUID = {}             -- guid -> key (buffer only)
local plates = {}             -- active nameplate tokens
local lastWrite = {}          -- key -> GetTime of last Store write
local lastFire = {}           -- key -> GetTime of last ENEMY_SPOTTED (same-frame dedupe)
local lastPrune = 0
Tracker.active = true

local function now() return GetTime() end

local function remove(key)
  local r = buffer[key]
  if not r then return end
  if r.guid and byGUID[r.guid] == key then byGUID[r.guid] = nil end
  buffer[key] = nil
  count = count - 1
end

function Tracker.Prune(force)
  local t = now()
  if not force and t - lastPrune < 10 and count < Tracker.MAX then return end
  lastPrune = t
  for key, r in pairs(buffer) do
    if t - r.t > Tracker.TTL then remove(key) end
  end
  while count >= Tracker.MAX do
    local oldestKey, oldest
    for key, r in pairs(buffer) do
      if not oldest or r.t < oldest then oldestKey, oldest = key, r.t end
    end
    if not oldestKey then break end
    remove(oldestKey)
  end
end

function Tracker.Reset()
  buffer, count, byGUID, plates, lastWrite, lastFire, lastPrune = {}, 0, {}, {}, {}, {}, 0
end

function Tracker.Count() return count end

---------------------------------------------------------------------------
-- Reading units
---------------------------------------------------------------------------
-- true = hostile, false = friendly, nil = unknown (secret).
-- `attack` = UnitCanAttack result when the caller has it already.
local function hostility(unit, attack)
  local enemy = Call(UnitIsEnemy, "player", unit)
  if True(enemy) then return true end
  if attack == nil then attack = Call(UnitCanAttack, "player", unit) end
  if True(attack) then return true end
  local mine, theirs = Str(Call(UnitFactionGroup, "player")), Str(Call(UnitFactionGroup, unit))
  if mine and theirs and theirs ~= "Neutral" then return theirs ~= mine end
  if Util.False(enemy) then return false end
  return nil
end

local function isPlayerUnit(unit)
  return True(Call(UnitExists, unit)) and True(Call(UnitIsPlayer, unit))
end

-- Name part of identity() (the unit is known to be a player).
local function nameOf(unit)
  if True(Call(UnitIsUnit, unit, "player")) then return nil end
  local name, second = Call(UnitName, unit)
  if IsSecret(name) or IsSecret(second) then return nil end
  name = Str(name)
  if not name then return nil end
  second = Str(second)
  local key = Util.KeyFor(name, second)
  if not key then return nil end
  return key, name, second
end

-- Identity of a player unit: key, name, surname or nil (secret/not a player/me).
local function identity(unit)
  if not isPlayerUnit(unit) then return nil end
  return nameOf(unit)
end
Tracker.Identity = identity

-- Fills the identity fields of a record (only plain values).
local function readInfo(unit, r)
  local guid = Str(Call(UnitGUID, unit))
  if guid then r.guid = guid end
  local classLoc, class = Call(UnitClass, unit)
  r.classLoc, r.class = Str(classLoc) or r.classLoc, Str(class) or r.class
  local raceLoc, race = Call(UnitRace, unit)
  r.raceLoc, r.race = Str(raceLoc) or r.raceLoc, Str(race) or r.race
  local level = Util.Num(Call(UnitLevel, unit))
  if level and level > 0 then r.level = level end
  local sex = Util.Num(Call(UnitSex, unit))
  if sex then r.sex = sex end
  local guild = Str(Call(GetGuildInfo, unit))
  if guild then r.guild = guild end
  local faction = Str(Call(UnitFactionGroup, unit))
  if faction then r.faction = faction end
  r.infoAt = now()
end

local function targetsMe(unit)
  return True(Call(UnitIsUnit, unit .. "target", "player"))
end

---------------------------------------------------------------------------
-- Sightings
---------------------------------------------------------------------------
local function spotted(key, unit, how, r)
  local t = now()
  local Store = ns.Store
  local e = Store and Store.Get(key)
  if not e then return end
  -- lastSeen at most every WRITE_EVERY seconds
  if not lastWrite[key] or t - lastWrite[key] >= Tracker.WRITE_EVERY then
    lastWrite[key] = t
    local zone, sub, mapID, x, y = Util.Zone()
    local at = time()
    local newEncounter = not (e.lastSeen and e.lastSeen.t) or (at - e.lastSeen.t) > Tracker.ENCOUNTER_GAP
    Store.Seen(key, r, { t = at, zone = zone, subzone = sub, mapID = mapID, x = x, y = y }, newEncounter)
  end
  if lastFire[key] == t then return end
  lastFire[key] = t
  ns:Fire("ENEMY_SPOTTED", key, unit, how)
end

-- Looks at one unit token. Returns the record for hostile players (or listed ones).
function Tracker.OnUnit(unit, how)
  if not Tracker.active or IsSecret(unit) or type(unit) ~= "string" then return nil end
  if not isPlayerUnit(unit) then return nil end
  -- friendly players (cities: the common case) leave before name and key are built
  local attack = Call(UnitCanAttack, "player", unit)
  if not True(attack) and True(Call(UnitIsFriend, "player", unit)) then return nil end
  local key, name, second = nameOf(unit)
  if not key then return nil end
  local hostile = hostility(unit, attack)
  if hostile == false then return nil end
  local Store = ns.Store
  local listed = Store and Store.Get(key)
  if not listed and second and Store and Store.HasPlaceholders and Store.HasPlaceholders() then
    -- entered by hand or known by GUID with the first name only: take the full name now
    -- (the GUID is read only while such placeholder entries exist)
    local k2 = Store.Promote(name, second, Str(Call(UnitGUID, unit)))
    if k2 then key = k2; listed = Store.Get(k2) end
  end
  -- additive: guild list (Sync.lua sets the hook only while that list has entries)
  local guildHook = Tracker.guildHook
  if guildHook and (hostile or listed) then guildHook(key, unit, how or "other", listed) end
  if hostile == nil and not listed then return nil end
  local t = now()
  local r = buffer[key]
  if not r then
    Tracker.Prune()
    r = { key = key, name = name, surname = second }
    buffer[key] = r
    count = count + 1
  end
  r.t, r.at, r.unit = t, time(), unit
  if not r.infoAt or t - r.infoAt > Tracker.INFO_REFRESH then
    readInfo(unit, r)
    if r.guid then byGUID[r.guid] = key end
  end
  if targetsMe(unit) then r.targetedMe = t end
  if unit == "target" then r.iTargeted = t end
  if listed then spotted(key, unit, how or "other", r) end
  return r
end

-- Re-checks every visible token (called right at death: who had me targeted).
function Tracker.ScanAll()
  for unit in pairs(plates) do Tracker.OnUnit(unit, "nameplate") end
  Tracker.OnUnit("target", "target")
  Tracker.OnUnit("focus", "other")
  Tracker.OnUnit("mouseover", "mouseover")
end

---------------------------------------------------------------------------
-- Queries (used by Attribution / UI)
---------------------------------------------------------------------------
function Tracker.Get(key)
  local r = buffer[key]
  if r and now() - r.t <= Tracker.TTL then return r end
  return nil
end

function Tracker.ByGUID(guid)
  if IsSecret(guid) or type(guid) ~= "string" then return nil end
  local key = byGUID[guid]
  return key and Tracker.Get(key) or nil
end

-- Unique record by first name (optionally surname); nil when none or ambiguous.
function Tracker.ByName(name, surname)
  if IsSecret(name) or type(name) ~= "string" then return nil end
  if IsSecret(surname) then surname = nil end
  local ln, ls = name:lower(), type(surname) == "string" and surname:lower() or nil
  local found, t = nil, now()
  for _, r in pairs(buffer) do
    if t - r.t <= Tracker.TTL and r.name and r.name:lower() == ln and (not ls or (r.surname and r.surname:lower() == ls)) then
      if found then return nil end
      found = r
    end
  end
  return found
end

-- Records seen within `window` seconds (newest first).
function Tracker.Recent(window)
  local t, out = now(), {}
  for _, r in pairs(buffer) do
    if t - r.t <= (window or Tracker.TTL) then out[#out + 1] = r end
  end
  table.sort(out, function(a, b) return a.t > b.t end)
  return out
end

-- Records that had me targeted within `window` seconds of `at` (GetTime value, default now).
function Tracker.Targeters(window, at)
  at = at or now()
  local out = {}
  for _, r in pairs(buffer) do
    if r.targetedMe and at - r.targetedMe <= window and at - r.targetedMe >= -1 then out[#out + 1] = r end
  end
  table.sort(out, function(a, b) return a.targetedMe > b.targetedMe end)
  return out
end

-- Additive: a unit token showing this listed player right now, or nil.
local FIXED_UNITS = { "target", "focus", "mouseover" }
function Tracker.UnitFor(key)
  for i = 1, #FIXED_UNITS do
    local u = FIXED_UNITS[i]
    if identity(u) == key then return u end
  end
  for u in pairs(plates) do
    if identity(u) == key then return u end
  end
  return nil
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------
local GROUP_UNIT = { party1 = true, party2 = true, party3 = true, party4 = true }

local function updateActive()
  local was = Tracker.active
  Tracker.active = Util.IsOpenWorld()
  if was and not Tracker.active then
    -- enemy names are hidden in instances: nothing to do there
    for k in pairs(buffer) do remove(k) end
  end
end
Tracker.UpdateActive = updateActive

ns:RegisterEvent("PLAYER_ENTERING_WORLD", function()
  plates = {}
  updateActive()
end)
ns:RegisterEvent("ZONE_CHANGED_NEW_AREA", updateActive)

ns:RegisterEvent("NAME_PLATE_UNIT_ADDED", function(_, unit)
  if IsSecret(unit) or type(unit) ~= "string" then return end
  plates[unit] = true
  -- 1.2.2: a plate appeared while the enemy plates count as off (or unknown): read the CVar once more.
  -- Hot path: one compare when they are on. (Friendly plates fire this too, hence no blind "on".)
  if Util.platesOn ~= true then
    local was = Util.platesOn
    Util.CheckPlates("NAME_PLATE_UNIT_ADDED")
    if Util.platesOn ~= was then Util.LogPlateEvent("NAME_PLATE_UNIT_ADDED").switched = true end
  end
  if Tracker.active then Tracker.OnUnit(unit, "nameplate") end
end)
ns:RegisterEvent("NAME_PLATE_UNIT_REMOVED", function(_, unit)
  if not IsSecret(unit) and type(unit) == "string" then plates[unit] = nil end
end)
ns:RegisterEvent("PLAYER_TARGET_CHANGED", function()
  if Tracker.active then Tracker.OnUnit("target", "target") end
end)
ns:RegisterEvent("UPDATE_MOUSEOVER_UNIT", function()
  if Tracker.active then Tracker.OnUnit("mouseover", "mouseover") end
end)
ns:RegisterEvent("PLAYER_FOCUS_CHANGED", function()
  if Tracker.active then Tracker.OnUnit("focus", "other") end
end)
-- A unit changed its target: note who targets me; a group member's target is a sighting too.
ns:RegisterEvent("UNIT_TARGET", function(_, unit)
  if not Tracker.active or IsSecret(unit) or type(unit) ~= "string" then return end
  if plates[unit] or unit == "target" or unit == "focus" then
    if targetsMe(unit) then Tracker.OnUnit(unit, "combat") end
  elseif GROUP_UNIT[unit] or unit:find("^raid%d+$") then
    Tracker.OnUnit(unit .. "target", "other")
  end
end)
