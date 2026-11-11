-- DeathNote - Core.lua
-- Namespace, event frame, internal bus, utilities, secret guards, slash commands.

local ADDON, ns = ...
_G.DeathNote = ns

ns.name = ADDON
ns.Util = {}
local Util = ns.Util

---------------------------------------------------------------------------
-- Secret guards
---------------------------------------------------------------------------
local issecretvalue, issecrettable = _G.issecretvalue, _G.issecrettable

-- true when the client hands us an opaque value (secret value or secret table).
-- Rule for every guard in this addon: ask IsSecret FIRST, only then compare, take the
-- length, concatenate or index (the client raises on all of these for secrets).
-- type(v) is allowed on secrets (it returns the real type).
function Util.IsSecret(v)
  if type(v) == "nil" then return false end     -- type() is no comparison; issecretvalue(nil) unverified
  if issecretvalue and issecretvalue(v) then return true end
  if issecrettable and type(v) == "table" and issecrettable(v) then return true end
  return false
end
local IsSecret = Util.IsSecret

-- The value itself, or `alt` when it is nil or secret.
function Util.Safe(v, alt)
  if IsSecret(v) or v == nil then return alt end
  return v
end
local Safe = Util.Safe

-- Plain string (non-empty) or nil.
-- type() is allowed on secrets (it is no comparison of the value): it filters first, cheaply.
function Util.Str(v)
  if type(v) ~= "string" or IsSecret(v) then return nil end
  if v ~= "" then return v end
  return nil
end
local Str = Util.Str

-- Plain number or nil.
function Util.Num(v)
  if type(v) ~= "number" or IsSecret(v) then return nil end
  if v == v then return v end
  return nil
end

-- Plain boolean true only (secret or anything else -> false).
function Util.True(v)
  if type(v) ~= "boolean" or IsSecret(v) then return false end
  return v == true
end

-- Plain boolean false only (secret or anything else -> false).
function Util.False(v)
  if type(v) ~= "boolean" or IsSecret(v) then return false end
  return v == false
end

-- pcall wrapper: returns the function's results, or nothing when it errors or is missing.
-- No table per call (hot path: several calls per nameplate).
local function callTail(ok, ...)
  if ok then return ... end
end
function Util.Call(fn, ...)
  if type(fn) ~= "function" then return end
  return callTail(pcall(fn, ...))
end
local Call = Util.Call

---------------------------------------------------------------------------
-- Bus
---------------------------------------------------------------------------
local handlers = {}

local function report(err)
  local eh = _G.geterrorhandler and _G.geterrorhandler()
  if eh then pcall(eh, err) end
end
ns.ReportError = report

function ns:On(event, fn)
  if type(fn) ~= "function" then return end
  local list = handlers[event]
  if not list then list = {}; handlers[event] = list end
  list[#list + 1] = fn
end

function ns:Fire(event, ...)
  local list = handlers[event]
  if not list then return end
  for i = 1, #list do
    local ok, err = pcall(list[i], ...)
    if not ok then report(err) end
  end
end

---------------------------------------------------------------------------
-- WoW events (one shared frame)
---------------------------------------------------------------------------
local frame = CreateFrame("Frame")
ns.eventFrame = frame
local wowHandlers = {}

-- Returns true when the event could be registered (pcall: unknown/closed events fail softly).
function ns:RegisterEvent(event, fn)
  local list = wowHandlers[event]
  if not list then
    local ok = pcall(frame.RegisterEvent, frame, event)
    if not ok then return false end
    list = {}
    wowHandlers[event] = list
  end
  list[#list + 1] = fn
  return true
end

function ns:UnregisterEvent(event)
  if wowHandlers[event] then
    pcall(frame.UnregisterEvent, frame, event)
    wowHandlers[event] = nil
  end
end

frame:SetScript("OnEvent", function(_, event, ...)
  local list = wowHandlers[event]
  if not list then return end
  for i = 1, #list do
    local ok, err = pcall(list[i], event, ...)
    if not ok then report(err) end
  end
end)

---------------------------------------------------------------------------
-- Names and keys
-- WoW Forever is realmless: every character has a first name and a surname
-- (UnitName(unit) returns name, surname). The key is "Name-Surname"; the
-- second part sits in the contract field `realm` (and `surname`). When no
-- surname is known, the own (normalized) realm fills the slot as the contract says.
---------------------------------------------------------------------------

-- Upper-case the first character, UTF-8 aware for Latin-1 letters (ä -> Ä).
local function capFirst(s)
  local b1, b2 = s:byte(1, 2)
  if not b1 then return s end
  if b1 >= 97 and b1 <= 122 then
    return string.char(b1 - 32) .. s:sub(2)
  end
  -- UTF-8 0xC3 0xA0..0xBE (à..þ, not ÷ 0xB7) -> 0xC3 0x80..0x9E
  if b1 == 0xC3 and b2 and b2 >= 0xA0 and b2 <= 0xBE and b2 ~= 0xB7 then
    return string.char(0xC3, b2 - 0x20) .. s:sub(3)
  end
  return s
end
Util.CapFirst = capFirst

local function trim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end

-- Name parts never carry control bytes, "|" (UI escape codes) or "/" and "\\" (the name goes
-- into a /targetexact macro, a slash there ends the name). Central: KeyFor and every surname
-- write in Store go through it.
function Util.CleanName(s)
  if type(s) ~= "string" or IsSecret(s) then return nil end
  -- find first: the normal name needs no new string
  if s:find("[%c|/\\]") then s = s:gsub("[%c|/\\]", "") end
  if s:byte(1) == 32 or s:byte(-1) == 32 then s = trim(s) end   -- other whitespace is %c
  if s == "" then return nil end
  return s
end

local ownRealm
function Util.OwnRealm()
  if ownRealm then return ownRealm end
  local r = Str(Call(_G.GetNormalizedRealmName))
  if not r then
    r = Str(Call(_G.GetRealmName))
    r = r and r:gsub("[%s%-']", "") or nil
  end
  if r and r ~= "" then ownRealm = r end
  return r or ""
end

-- Splits "Name Surname", "Name-Surname" or "Name" into name, second.
function Util.SplitFull(full)
  if IsSecret(full) or type(full) ~= "string" then return nil end
  full = trim(full)
  if full == "" then return nil end
  local a, b = full:match("^([^%s%-]+)[%s%-]+(.+)$")
  if a then return a, trim(b) end
  return full, nil
end

-- KeyFor(name[, realmOrSurname]) -> key, name, second, hadSecond
-- Accepts "Name", "Name Surname", "Name-Surname"; returns nil for invalid/secret input.
function Util.KeyFor(name, second)
  name = Util.CleanName(name)
  if not name then return nil end
  second = Util.CleanName(second)
  local n, s = Util.SplitFull(name)
  if not n then return nil end
  if second and trim(second) ~= "" then s = trim(second) end
  if n == "" or n == _G.UNKNOWNOBJECT or n == "Unknown" then return nil end
  n = capFirst(n)
  local had = s ~= nil and s ~= ""
  if had then
    s = capFirst((s:gsub("%s+", " ")))
  else
    s = Util.OwnRealm()
    if s == "" then s = "?" end
  end
  return n .. "-" .. s, n, s, had
end

function Util.SplitKey(key)
  if type(key) ~= "string" then return nil end
  local n, s = key:match("^([^%-]+)%-(.+)$")
  if n then return n, s end
  return key, nil
end

-- Key of a unit token, nil when not a player or when the name is secret.
function Util.KeyOfUnit(unit)
  if IsSecret(unit) or type(unit) ~= "string" then return nil end
  if not Util.True(Call(_G.UnitIsPlayer, unit)) then return nil end
  local name, second = Call(_G.UnitName, unit)
  if IsSecret(name) or IsSecret(second) then return nil end
  return (Util.KeyFor(name, second))
end

-- How the player is called in the game ("Name Surname").
function Util.Display(entry)
  if type(entry) ~= "table" then return "?" end
  if entry.display then return entry.display end
  if entry.surname then return entry.name .. " " .. entry.surname end
  return entry.name or entry.key or "?"
end

-- "Name Surname" (or "Name") of the logged-in character, nil when unknown or secret.
-- The same form Attribution writes into death.me.
function Util.PlayerFullName()
  local n, sn = Call(_G.UnitName, "player")
  n, sn = Str(n), Str(sn)
  if not n then return nil end
  return sn and (n .. " " .. sn) or n
end

-- Name for /targetexact. Assumption (unverified in game): the full "Name Surname".
function Util.TargetName(entry)
  if type(entry) ~= "table" then return nil end
  if entry.surname then return entry.name .. " " .. entry.surname end
  return entry.name
end

---------------------------------------------------------------------------
-- Display helpers
---------------------------------------------------------------------------
function Util.ClassColor(token)
  if type(token) == "string" then
    local c = (_G.C_ClassColor and Call(_G.C_ClassColor.GetClassColor, token))
      or (_G.RAID_CLASS_COLORS and _G.RAID_CLASS_COLORS[token])
    if c and c.r then return c.r, c.g, c.b end
  end
  return 0.75, 0.75, 0.75
end

-- The two time forms of the addon (1.1.0, one place for all of them):
--   Util.Ago(t)  relative, for lists and sub lines: "gerade eben", "vor 23 Min.", "vor 3 Std.",
--                "vor 2 Tagen"; from 7 days on the day "11.11." (with year "11.11.25" when not this year)
--   Util.When(t) absolute, for files, deeds and tooltips: "11.11. 01:01" ("11.11.2025 01:01" when not this year)
-- `date` is the client's os.date (used e.g. by DBM-Core/localization.de.lua:10).
local dateFn = _G.date or (os and os.date)

local function sameYear(t)
  if not dateFn then return true end
  local ok1, a = pcall(dateFn, "%Y", t)
  local ok2, b = pcall(dateFn, "%Y", time())
  return not (ok1 and ok2) or a == b
end

local function fmtDate(fmt, t)
  if not dateFn then return "?" end
  local ok, s = pcall(dateFn, fmt, t)
  if ok and type(s) == "string" then return s end
  return "?"
end

function Util.When(t)
  if type(t) ~= "number" or t ~= t then return "?" end
  return fmtDate(sameYear(t) and "%d.%m. %H:%M" or "%d.%m.%Y %H:%M", t)
end

function Util.Ago(t)
  if type(t) ~= "number" or t ~= t then return "nie" end
  local d = time() - t
  if d < 0 then d = 0 end
  if d < 60 then return "gerade eben" end
  if d < 3600 then return ("vor %d Min."):format(math.floor(d / 60)) end
  if d < 86400 then
    local h = math.floor(d / 3600)
    return h == 1 and "vor 1 Std." or ("vor %d Std."):format(h)
  end
  local days = math.floor(d / 86400)
  if days == 1 then return "vor 1 Tag" end
  if days < 7 then return ("vor %d Tagen"):format(days) end
  return fmtDate(sameYear(t) and "%d.%m." or "%d.%m.%y", t)
end

function Util.Money(copper)
  copper = math.floor(tonumber(copper) or 0)
  local g = math.floor(copper / 10000)
  local s = math.floor((copper % 10000) / 100)
  local c = copper % 100
  local parts = {}
  if g > 0 then parts[#parts + 1] = g .. "g" end
  if s > 0 then parts[#parts + 1] = s .. "s" end
  if c > 0 or #parts == 0 then parts[#parts + 1] = c .. "k" end
  return table.concat(parts, " ")
end

-- zone, subzone, mapID, x, y (x/y in percent with one decimal, or nil)
function Util.Zone()
  local zone = Str(Call(_G.GetRealZoneText)) or Str(Call(_G.GetZoneText))
  local sub = Str(Call(_G.GetSubZoneText))
  local mapID, x, y
  local C_Map = _G.C_Map
  if C_Map then
    mapID = Util.Num(Call(C_Map.GetBestMapForUnit, "player"))
    if mapID then
      local pos = Call(C_Map.GetPlayerMapPosition, mapID, "player")
      if not IsSecret(pos) and type(pos) == "table" and pos.GetXY then
        local px, py = Call(pos.GetXY, pos)
        px, py = Util.Num(px), Util.Num(py)
        if px and py and (px > 0 or py > 0) then
          x = math.floor(px * 1000 + 0.5) / 10
          y = math.floor(py * 1000 + 0.5) / 10
        end
      end
    end
  end
  return zone, sub, mapID, x, y
end

-- Open world = not in an instance (dungeon/raid/bg/arena/scenario). Duels are tracked by Attribution.
function Util.IsOpenWorld()
  local inInstance, kind = Call(_G.IsInInstance)
  if IsSecret(inInstance) or IsSecret(kind) then return false end
  if inInstance == true then return false end
  if type(kind) == "string" and kind ~= "none" then return false end
  return true
end

-- Enemy nameplates switched on? (CVar nameplateShowEnemies, as used by ElvUI). Read only.
function Util.NameplatesOn()
  local C_CVar = _G.C_CVar
  local v
  if C_CVar and C_CVar.GetCVarBool then
    v = Call(C_CVar.GetCVarBool, "nameplateShowEnemies")
  elseif _G.GetCVarBool then
    v = Call(_G.GetCVarBool, "nameplateShowEnemies")
  end
  if IsSecret(v) then return nil end
  return v == true
end

local PREFIX = "|cffc41e3aDeathNote|r: "
function Util.Print(...)
  local parts = {}
  for i = 1, select("#", ...) do parts[#parts + 1] = tostring((select(i, ...))) end
  local msg = PREFIX .. table.concat(parts, "")
  local cf = _G.DEFAULT_CHAT_FRAME
  if cf and cf.AddMessage then cf:AddMessage(msg) else print(msg) end
end

---------------------------------------------------------------------------
-- Slash commands
---------------------------------------------------------------------------
-- Words (1.1.0, one word each): "Buch" (own), "Gildenbuch" (shared), "Täter" (the person),
-- "Kollege" (a member of the own guild), "streichen" (remove).
local HELP = {
  "/dn  Buch auf/zu",
  "/dn add <Name [Nachname]>  Täter von Hand ins Buch eintragen",
  "/dn del <Name [Nachname]>  Täter aus dem Buch streichen",
  "/dn still  Alarm aus/an",
  "/dn test  Probe-Alarm zeigen",
  "/dn gilde  Gildenbuch: Stand und welche Kollegen DeathNote haben",
  "/dn sync  Gildenbuch jetzt abgleichen",
  "/dn probe  Fehlersuche: was das Spiel dem Buch verrät",
  "/dn probe combatlog  Fehlersuche, dazu das Kampflog prüfen",
  "/dn debug  Fehlersuche: jeden Tod genau mitschreiben (an/aus)",
  "/dn hilfe  diese Hilfe",
  "In Dungeons, Schlachtfeldern und Arenen schweigt das Buch von selbst.",
}
ns.HELP = HELP

local function onOff(v) return v and "an" or "aus" end

function ns.HandleSlash(msg)
  msg = type(msg) == "string" and trim(msg) or ""
  local cmd, rest = msg:match("^(%S*)%s*(.-)$")
  cmd = (cmd or ""):lower()
  local Store = ns.Store
  if cmd == "" then
    ns:Fire("TOGGLE_UI")
  elseif cmd == "add" then
    if rest == "" then Util.Print("Wen denn? /dn add <Name>"); return end
    local key = Store and Store.AddManual(rest)
    if key then
      Util.Print(Util.Display(Store.Get(key)), " steht jetzt im Buch.")
    else
      Util.Print("Ungültiger Name.")
    end
  elseif cmd == "del" or cmd == "rm" or cmd == "delete" then
    if rest == "" then Util.Print("Wen denn? /dn del <Name>"); return end
    local key = Store and Store.Find(rest)
    if key then
      local disp = Util.Display(Store.Get(key))
      Store.Remove(key)
      Util.Print(disp, " ist aus dem Buch gestrichen.")
    else
      Util.Print("Nicht im Buch: ", rest)
    end
  elseif cmd == "still" or cmd == "ruhe" or cmd == "mute" then
    if not Store then return end
    local on = Store.Setting("alert.enabled") == false
    Store.Setting("alert.enabled", on)
    Util.Print(on and "Alarm an." or "Alarm aus.")
  elseif cmd == "probe" then
    -- "/dn probe combatlog" also tries to register the (closed) combat log; plain "/dn probe" never does
    if ns.Probe then ns.Probe.Run(true, { combatlog = rest:lower() == "combatlog" }) end
  elseif cmd == "debug" then
    local on = not (Store and Store.Setting("debug"))
    if Store then Store.Setting("debug", on) end
    Util.Print("Mitschnitt für die Fehlersuche ", onOff(on), ".")
  elseif cmd == "test" then
    ns:Fire("TEST_ALERT")
  elseif cmd == "gilde" or cmd == "guild" then
    local G = ns.Guild
    if not G then Util.Print("Das Gildenbuch ist nicht geladen."); return end
    local name = G.Name()
    if not name then
      Util.Print("Du bist in keiner Gilde (oder das Spiel kennt sie noch nicht).")
    else
      Util.Print("Gilde ", name, ": Teilen ", onOff(G.Setting("share")), ", Empfangen ", onOff(G.Setting("receive")), ".")
    end
    local enemies, deeds, listed, foreign = G.Count()
    Util.Print("Gildenbuch: ", enemies, " Täter (", listed or 0, " nur von Hand eingetragen), ", deeds,
      deeds == 1 and " Tat, " or " Taten, ", foreign or 0, " mit Kollegen. Einträge von Hand teilen: ", onOff(G.Setting("shareManual")), ".")
    if G.Health then
      local h = G.Health()
      if h and h.text then Util.Print(h.ok and "Stand: " or "Achtung: ", h.text) end
    end
    local members = G.Members()
    if #members == 0 then
      Util.Print("Noch kein Kollege mit DeathNote gehört.")
    else
      local names = {}
      for i = 1, math.min(#members, 15) do
        local m = members[i]
        names[#names + 1] = m.name .. (m.version and (" " .. m.version) or "")
      end
      Util.Print("DeathNote haben: ", table.concat(names, ", "), #members > 15 and (" und " .. (#members - 15) .. " weitere") or "")
    end
  elseif cmd == "sync" then
    local G = ns.Guild
    if not G then return end
    local ok, why = G.SyncNow()
    if ok then
      Util.Print("Abgleich angefragt. Antworten kommen in den nächsten Sekunden.")
    elseif type(why) == "number" then
      Util.Print("Gerade erst abgeglichen. Nochmal in ", why, " Sek.")
    else
      local h = G.Health and G.Health()
      Util.Print("Abgleich geht nicht: ", (h and not h.ok and h.text) or "keine Gilde oder Teilen ist aus.")
    end
  elseif cmd == "hilfe" or cmd == "help" or cmd == "?" then
    for i = 1, #HELP do Util.Print(HELP[i]) end
  else
    Util.Print("Unbekannter Befehl. Hilfe: /dn hilfe")
  end
end

_G.SLASH_DEATHNOTE1 = "/dn"
_G.SLASH_DEATHNOTE2 = "/deathnote"
_G.SLASH_DEATHNOTE3 = "/todesliste"
_G.SLASH_DEATHNOTE4 = "/deathlist"
if _G.SlashCmdList then _G.SlashCmdList.DEATHNOTE = ns.HandleSlash end

---------------------------------------------------------------------------
-- Startup
---------------------------------------------------------------------------
ns:RegisterEvent("PLAYER_LOGIN", function()
  if ns.Store then ns.Store.Init() end
  ns.ready = true
  ns:Fire("READY")
end)

---------------------------------------------------------------------------
-- First contact (1.1.0): one chat line, once per account, 5 s after login, never in combat
---------------------------------------------------------------------------
ns.WELCOME = "Das Buch liegt bereit. Wer dich in der offenen Welt tötet, steht danach drin. "
  .. "Aufschlagen mit /dn oder am Minimap-Knopf."
ns.WELCOME_PLATES = "Feindliche Namensplaketten sind aus. Ohne sie sieht der Alarm nur dein Ziel."
ns.WELCOME_DELAY = 5

local welcomeWaiting = false   -- true while the line waits for the end of a fight

local function inCombat() return Util.True(Call(_G.InCombatLockdown)) end

-- Prints the greeting when it is due. Returns true when it was printed.
function ns.Welcome()
  local Store = ns.Store
  if not (Store and Store.DB()) or Store.Setting("welcomed") ~= false then
    welcomeWaiting = false
    return false
  end
  if inCombat() then welcomeWaiting = true; return false end
  welcomeWaiting = false
  Util.Print(ns.WELCOME)
  if Util.NameplatesOn() == false then Util.Print(ns.WELCOME_PLATES) end
  Store.Setting("welcomed", true)
  return true
end

ns:On("READY", function()
  local Store = ns.Store
  if not Store or Store.Setting("welcomed") ~= false then return end
  local After = _G.C_Timer and _G.C_Timer.After
  if After then After(ns.WELCOME_DELAY, ns.Welcome) else ns.Welcome() end
end)

-- cheap: one boolean test per end of combat
ns:RegisterEvent("PLAYER_REGEN_ENABLED", function()
  if welcomeWaiting then ns.Welcome() end
end)
