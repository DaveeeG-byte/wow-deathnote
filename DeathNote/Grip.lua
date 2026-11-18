local ADDON, ns = ...

-- 1.5.0 grip: the key bindings (Bindings.xml; the game loads that file by itself, it is not in the TOC). No default
-- keys. Each binding calls DeathNote_Binding(what); nothing here is a protected action, so all of it works in combat:
--   TOGGLE  open or close the book (as /dn)
--   ADD     the current target into the book (as /dn add) with class, level, guild and GUID read from the target
--   HUNT    the current target on the hit list (as /dn hunt) with a standard reason (the poster's hit list sheet
--           changes it later: releasing again with another reason replaces it)
--   ALARM   alarm off / on (as /dn quiet)
--   HELP    1.6.0 call: a help call with my place to guild, group and friends (Call.lua)
-- Feedback: one chat line and the same words as a small line in the middle of the screen (UIErrorsFrame).
-- The texts of the key binding window: BINDING_HEADER_DEATHNOTE (the addon's title from the TOC, so a new display
-- name follows by itself) and BINDING_NAME_DEATHNOTE_* (from the language table).

local Util = ns.Util
local Call, IsSecret, Str, Num, True = Util.Call, Util.IsSecret, Util.Str, Util.Num, Util.True
local L, Fmt = ns.L, ns.F

local Grip = {}
ns.Grip = Grip

Grip.BINDINGS = { "TOGGLE", "ADD", "HUNT", "ALARM", "HELP" }
Grip.NAME_KEYS = { TOGGLE = "BIND_TOGGLE", ADD = "BIND_ADD", HUNT = "BIND_HUNT", ALARM = "BIND_ALARM", HELP = "BIND_HELP" }

-- the small line in the middle of the screen (when the client has it) and the chat line
local function say(text)
  if type(text) ~= "string" or text == "" then return end
  Util.Print(text)
  local ef = rawget(_G, "UIErrorsFrame")
  if type(ef) == "table" and type(ef.AddMessage) == "function" then pcall(ef.AddMessage, ef, text, 1, 0.82, 0.3, 1) end
end
Grip.Say = say

-- the hostile player behind a unit token: key, info { name, surname, guid, class, classLoc, race, raceLoc, level,
-- guild, faction, sex }, or nil with why ("none" no target, "notplayer", "friendly", "me", "group", "secret")
function Grip.EnemyOf(unit)
  unit = unit or "target"
  local exists = Call(_G.UnitExists, unit)
  if IsSecret(exists) then return nil, "secret" end
  if exists ~= true then return nil, "none" end
  local isP = Call(_G.UnitIsPlayer, unit)
  if IsSecret(isP) then return nil, "secret" end
  if isP ~= true then return nil, "notplayer" end
  if True(Call(_G.UnitIsUnit, unit, "player")) then return nil, "me" end
  local T = ns.Tracker
  local key, name, surname
  if T and T.Identity then key, name, surname = T.Identity(unit) end
  if not key then return nil, "secret" end
  -- hostile: enemy, or attackable and not of my faction, or of the other faction (a city: not attackable, still the
  -- enemy). 1.5.0 fixer: a duel partner of my own faction is attackable for the duel, but no enemy (as for the grudge)
  local mine, theirs = Str(Call(_G.UnitFactionGroup, "player")), Str(Call(_G.UnitFactionGroup, unit))
  local same = mine ~= nil and theirs ~= nil and theirs == mine
  local hostile = True(Call(_G.UnitIsEnemy, "player", unit)) or (not same and True(Call(_G.UnitCanAttack, "player", unit)))
  if not hostile then
    hostile = mine ~= nil and theirs ~= nil and theirs ~= "Neutral" and theirs ~= mine
  end
  if not hostile then return nil, "friendly" end
  if True(Call(_G.UnitInParty, unit)) then return nil, "group" end
  local raid = Call(_G.UnitInRaid, unit)
  if not IsSecret(raid) and type(raid) == "number" then return nil, "group" end
  local info = { name = name, surname = surname }
  info.guid = Str(Call(_G.UnitGUID, unit))
  local classLoc, class = Call(_G.UnitClass, unit)
  info.classLoc, info.class = Str(classLoc), Str(class)
  local raceLoc, race = Call(_G.UnitRace, unit)
  info.raceLoc, info.race = Str(raceLoc), Str(race)
  local level = Num(Call(_G.UnitLevel, unit))
  if level and level > 0 then info.level = level end
  info.guild = Str(Call(_G.GetGuildInfo, unit))
  info.faction = Str(Call(_G.UnitFactionGroup, unit))
  info.sex = Num(Call(_G.UnitSex, unit))
  return key, info
end

local function whyLine(why)
  if why == "notplayer" or why == "friendly" or why == "me" or why == "group" then return L.GRIP_NOT_ENEMY end
  return L.GRIP_NO_TARGET
end

-- ADD: returns the key or nil
function Grip.AddTarget(unit)
  L, Fmt = ns.L, ns.F
  local S = ns.Store
  if not (S and S.DB and S.DB() and S.AddManual) then return nil end
  local key, info = Grip.EnemyOf(unit)
  if not key then say(whyLine(info)); return nil end
  local had = S.Find and S.Find(info.name, info.surname)
  local k = S.AddManual(info.name, info.surname)
  if not k then say(L.CHAT_BAD_NAME); return nil end
  -- class, level, guild, GUID of the target onto the entry (Upsert fills identity fields only, it never counts)
  if S.Upsert then
    local k2 = S.Upsert(info, false)
    if type(k2) == "string" then k = k2 end
  end
  ns:Fire("ENEMY_UPDATED", k)
  local e = S.Get(k)
  local disp = e and Util.Display(e) or info.name
  local parts = {}
  if info.level then parts[#parts + 1] = Fmt(L.POSTER_LEVEL, { level = info.level }) end
  if info.classLoc then parts[#parts + 1] = info.classLoc end
  if info.guild then parts[#parts + 1] = "<" .. info.guild .. ">" end
  local who = table.concat(parts, ", ")
  local line = had and Fmt(L.GRIP_ALREADY, { name = disp }) or Fmt(L.CHAT_ADDED, { name = disp })
  if who ~= "" then line = line .. " (" .. who .. ")" end
  say(line)
  return k
end

-- HUNT: returns guildDone, friendsDone (as Guild.Release) or nil
function Grip.HuntTarget(unit)
  L, Fmt = ns.L, ns.F
  local G = ns.Guild
  if not (G and G.Release) then say(L.CHAT_HUNT_NOT_LOADED); return nil end
  local key, info = Grip.EnemyOf(unit)
  if not key then say(whyLine(info)); return nil end
  if not info.surname and G.FindTarget then
    -- first name only: the book or a list may know the full name
    key = G.FindTarget(info.name) or key
  end
  local g, f = G.Release(key, { to = "all", why = L.GRIP_HUNT_WHY })
  local disp = (G.Hunt and (G.Hunt(key, "all") or {}).display) or (info.surname and (info.name .. " " .. info.surname))
    or info.name
  if g == nil then
    if f == "cap" then say(Fmt(L.CHAT_HUNT_CAP, { own = 10, targets = 100 }))
    elseif f == "self" then say(L.REL_SELF)
    elseif f == "mate" then say(L.REL_MATE)
    elseif f == "key" then say(L.CHAT_BAD_NAME)
    else say(L.CHAT_HUNT_NOWHERE) end
    return nil
  end
  if g and f then say(Fmt(L.CHAT_HUNT_BOTH, { name = disp }))
  elseif g then say(Fmt(L.CHAT_HUNT_GUILD, { name = disp }))
  else say(Fmt(L.CHAT_HUNT_FRIENDS, { name = disp })) end
  say(Fmt(L.GRIP_HUNT_CHANGE, { why = L.GRIP_HUNT_WHY, action = L.ACT_RELEASE }))
  return g, f
end

-- ALARM: as /dn quiet (one line)
function Grip.ToggleAlarm()
  L = ns.L
  local S = ns.Store
  if not (S and S.DB and S.DB()) then return end
  local on = S.Setting("alert.enabled") == false
  S.Setting("alert.enabled", on)
  say(on and L.CHAT_ALARM_ON or L.CHAT_ALARM_OFF)
end

function Grip.Run(what)
  if what == "TOGGLE" then ns:Fire("TOGGLE_UI")
  elseif what == "ADD" then Grip.AddTarget("target")
  elseif what == "HUNT" then Grip.HuntTarget("target")
  elseif what == "ALARM" then Grip.ToggleAlarm()
  elseif what == "HELP" and ns.Call and ns.Call.Trigger then ns.Call.Trigger() end
end

-- the one global the bindings call (Bindings.xml); an error is reported, never raised into the key handler
function _G.DeathNote_Binding(what)
  local ok, err = pcall(Grip.Run, what)
  if not ok and ns.ReportError then ns.ReportError(err) end
end

-- the words of the key binding window
local function title()
  local CA = rawget(_G, "C_AddOns")
  local fn = type(CA) == "table" and CA.GetAddOnMetadata or rawget(_G, "GetAddOnMetadata")
  local t = type(fn) == "function" and Call(fn, ADDON, "Title") or nil
  t = Str(t)
  if not t or t == "" or t:find("|", 1, true) then t = ADDON end
  return t
end
function Grip.SetNames()
  L = ns.L
  _G.BINDING_HEADER_DEATHNOTE = title()
  for _, w in ipairs(Grip.BINDINGS) do
    local text = L[Grip.NAME_KEYS[w]]
    if type(text) == "string" then _G["BINDING_NAME_DEATHNOTE_" .. w] = text end
  end
end
if ns.Locale and ns.Locale.OnActivate then ns.Locale.OnActivate(function() Grip.SetNames() end) end

-- 1.5.0 fixer: where the keys are set (a line of the nameplate stepper's tooltip and of the hint below)
function Grip.KeysWhere()
  L = ns.L
  return Fmt(L.GRIP_KEYS_WHERE, { title = title() })
end
-- the key of a binding as the game writes it, or nil (none set, no API, secret)
function Grip.KeyOf(what)
  local key = Str(Call(rawget(_G, "GetBindingKey"), "DEATHNOTE_" .. tostring(what)))
  if not key or key == "" then return nil end
  local text = Str(Call(rawget(_G, "GetBindingText"), key, "KEY_"))
  return (text and text ~= "") and text or key
end
-- 1.5.0 fixer: after "/dn add" was typed, once per account: the key "Target into the book" exists (and which it is,
-- or where to set it). Returns true when the line was said.
function Grip.KeyHint()
  L = ns.L
  local S = ns.Store
  if not (S and S.Setting and S.DB and S.DB()) or S.Setting("grip.keyHint") == true then return false end
  S.Setting("grip.keyHint", true)
  local key = Grip.KeyOf("ADD")
  Util.Print(key and Fmt(L.GRIP_KEY_HAVE, { key = key }) or Fmt(L.GRIP_KEY_HINT, { title = title() }))
  return true
end
