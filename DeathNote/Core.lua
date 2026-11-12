-- DeathNote - Core.lua
-- Namespace, event frame, internal bus, utilities, secret guards, slash commands.

local ADDON, ns = ...
_G.DeathNote = ns

ns.name = ADDON
ns.Util = {}
local Util = ns.Util
-- Texte (1.2.0): ns.L ist ab ADDON_LOADED gefuellt (Locale.lua); L.KEY nur in Funktionen lesen
local L, Fmt = ns.L, ns.F

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

-- The two time forms of the addon (1.1.0, one place for all of them; 1.2.0: words and date formats
-- from the language table, TIME_*):
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

-- 1.2.0: a date format of a translation reaches date() only with the signs every C library knows
-- (%d %m %y %Y %H %M and %%); anything else falls back to the English format (strftime on Windows may abort
-- on unknown signs instead of raising a Lua error)
local DATE_EN = { TIME_FMT_WHEN = "%m/%d %H:%M", TIME_FMT_WHEN_YEAR = "%m/%d/%Y %H:%M", TIME_FMT_DAY = "%m/%d",
  TIME_FMT_DAY_YEAR = "%m/%d/%y" }
local function fmtDate(key, t)
  if not dateFn then return "?" end
  local fmt = L[key]
  if type(fmt) ~= "string" or #fmt > 40 or fmt:gsub("%%[dmyYHM%%]", ""):find("%", 1, true) then fmt = DATE_EN[key] end
  local ok, s = pcall(dateFn, fmt, t)
  if ok and type(s) == "string" then return s end
  return "?"
end
Util.FmtDate = fmtDate

function Util.When(t)
  if type(t) ~= "number" or t ~= t then return "?" end
  return fmtDate(sameYear(t) and "TIME_FMT_WHEN" or "TIME_FMT_WHEN_YEAR", t)
end

function Util.Ago(t)
  if type(t) ~= "number" or t ~= t then return L.TIME_NEVER end
  local d = time() - t
  if d < 0 then d = 0 end
  if d < 60 then return L.TIME_JUST end
  if d < 3600 then return Fmt(L.TIME_MINUTES, { count = math.floor(d / 60) }) end
  if d < 86400 then return Fmt(L.TIME_HOURS, { count = math.floor(d / 3600) }) end
  local days = math.floor(d / 86400)
  if days < 7 then return Fmt(L.TIME_DAYS, { count = days }) end
  return fmtDate(sameYear(t) and "TIME_FMT_DAY" or "TIME_FMT_DAY_YEAR", t)
end

function Util.Money(copper)
  copper = math.floor(tonumber(copper) or 0)
  local g = math.floor(copper / 10000)
  local s = math.floor((copper % 10000) / 100)
  local c = copper % 100
  local parts = {}
  if g > 0 then parts[#parts + 1] = Fmt(L.MONEY_GOLD, { count = g }) end
  if s > 0 then parts[#parts + 1] = Fmt(L.MONEY_SILVER, { count = s }) end
  if c > 0 or #parts == 0 then parts[#parts + 1] = Fmt(L.MONEY_COPPER, { count = c }) end
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
  -- Known gap: nil (CVar unknown to the client) counts as "off" here, unlike a secret. The CVar exists on the
  -- clients we support, so this is left as it is; treating nil as unknown would need a decision first.
  return v == true
end

-- 1.2.2: the last known state of the enemy plates (nil = not read yet or unreadable). Every hint that they may
-- have changed (CVAR_UPDATE, a nameplate appearing, the book's poll while it is open) calls Util.CheckPlates;
-- only a real change fires PLATES_CHANGED, so the book's status line follows at once.
-- Util.platesSource names what noticed the last change; Util.plateLog keeps the last CVAR_UPDATE arguments
-- for /dn probe (which event the client really sends when the plates are switched).
Util.platesOn = nil
Util.platesSource = nil
Util.plateLog = {}
local PLATE_LOG_MAX = 6
function Util.CheckPlates(source)
  local on = Util.NameplatesOn()
  if on == nil or on == Util.platesOn then return on end
  Util.platesOn = on
  Util.platesSource = source
  ns:Fire("PLATES_CHANGED", on, source)
  return on
end

-- one marker per CVAR_UPDATE argument: plain strings/numbers/booleans as they are, secrets as "<secret>"
local function plateArg(v)
  if IsSecret(v) then return "<secret>" end
  if v == nil then return "nil" end
  local t = type(v)
  if t == "string" then return #v > 40 and v:sub(1, 40) or v end
  if t == "number" or t == "boolean" then return tostring(v) end
  return "<" .. t .. ">"
end
function Util.LogPlateEvent(event, a1, a2)
  local log = Util.plateLog
  local e = { t = _G.GetTime and Util.Num(Call(_G.GetTime)) or 0, event = event, a1 = plateArg(a1), a2 = plateArg(a2) }
  table.insert(log, 1, e)
  while #log > PLATE_LOG_MAX do table.remove(log) end
  return e
end

local PREFIX = "|cffc41e3aDeathNote|r: "
-- Note of an own entry as shown (1.2.0): the stored free text; an entry taken over from the guild
-- book keeps only a mark (fromGuild, fromGuildKills) and gets its sentence in the active language here.
function Util.NoteOf(e)
  if type(e) ~= "table" then return "" end
  if type(e.note) == "string" and e.note ~= "" then return e.note end
  if e.fromGuild == true and type(e.fromGuildKills) == "number" and ns.L and ns.F then
    return ns.F(ns.L.NOTE_FROM_GUILD, { kills = e.fromGuildKills })
  end
  return ""
end

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
-- 1.2.0: the lines come from the language table (HELP_*), in the active language; ns.HELP is built
-- at activation. The German subcommands stay valid forever, the English ones work in every language.
local HELP_KEYS = { "HELP_TOGGLE", "HELP_ADD", "HELP_DEL", "HELP_QUIET", "HELP_TEST", "HELP_GUILD", "HELP_FRIENDS",
  "HELP_SYNC", "HELP_HUNT", "HELP_CALLOFF", "HELP_BOUNTY", "HELP_LANG", "HELP_PROBE", "HELP_PROBE_COMBATLOG", "HELP_DEBUG",
  "HELP_HELP", "HELP_SILENT_ZONES" }
ns.HELP_KEYS = HELP_KEYS
local HELP = {}
ns.HELP = HELP
local function buildHelp()
  for i = #HELP, 1, -1 do HELP[i] = nil end
  for i = 1, #HELP_KEYS do HELP[i] = L[HELP_KEYS[i]] end
end

local function onOff(v) return v and L.WORD_ON or L.WORD_OFF end

-- "Anna, Bert" or "Anna, Bert and 3 more" (chat: up to 15 names with version)
local function haveList(members)
  local names = {}
  for i = 1, math.min(#members, 15) do
    local m = members[i]
    names[#names + 1] = m.name .. (m.version and (" " .. m.version) or "")
  end
  local list = table.concat(names, ", ")
  if #members > 15 then return Fmt(L.CHAT_HAVE_DN_MORE, { names = list, count = #members - 15 }) end
  return Fmt(L.CHAT_HAVE_DN, { names = list })
end

-- 1.2.1: one chat line for setting or taking back an own bounty (slash command and the poster)
-- disp = the target as shown, gold = whole gold (0 = taken back), ok/why = Guild.SetBounty's answer
function Util.BountyReport(disp, gold, ok, why)
  disp = Str(disp) or "?"
  if ok then
    if gold and gold > 0 then
      -- 1.2.1 fix: "Gilde und Freunde sehen es" only when there is somebody to see it
      local G, F = ns.Guild, ns.Friends
      local fdb = F and F.DB and F.DB()
      local shared = (G and G.HuntTargets and G.HuntTargets()) or (type(fdb) == "table" and type(fdb.members) == "table"
        and next(fdb.members) ~= nil)
      Util.Print(Fmt(shared and L.CHAT_BOUNTY_SET or L.CHAT_BOUNTY_SET_ALONE, { name = disp, gold = gold }))
    else
      Util.Print(Fmt(L.CHAT_BOUNTY_OFF, { name = disp }))
    end
  elseif why == "none" then Util.Print(Fmt(L.CHAT_BOUNTY_NONE, { name = disp }))
  elseif why == "cap" then Util.Print(Fmt(L.CHAT_BOUNTY_CAP, { count = ns.Guild and ns.Guild.C and ns.Guild.C.BOUNTY_PER_SENDER or 20 }))
  elseif why == "ours" then Util.Print(L.CHAT_BOUNTY_OURS)
  elseif why == "gold" then Util.Print(L.CHAT_BOUNTY_BAD)
  else Util.Print(Fmt(L.CHAT_HUNT_UNKNOWN, { name = disp })) end
end

-- /dn kopfgeld <Name [Surname]> [gold]: the last word is the amount when it is a number; none or 0 takes it back
-- 1.2.1 fix: without anything it lists the own bounties of this char; only names from a book get one (a typo no
-- longer posts a bounty nobody can see); an amount with a unit ("50g", "50 Gold", "1e3") gets the rule line.
local function slashBounty(rest)
  local G = ns.Guild
  if not (G and G.SetBounty) then Util.Print(L.CHAT_HUNT_NOT_LOADED); return end
  local Store = ns.Store
  local function shown(key)
    local x = (Store and Store.Get(key)) or G.Get(key, "all") or G.Hunt(key, "all")
    return type(x) == "table" and Util.Display(x) or (key:gsub("%-", " "))
  end
  if rest == "" then
    local own = ns.Bounty and ns.Bounty.OwnList and ns.Bounty.OwnList() or {}
    if #own == 0 then Util.Print(L.CHAT_BOUNTY_LIST_NONE); Util.Print(L.CHAT_WHO_BOUNTY); return end
    local parts = {}
    for i = 1, #own do parts[i] = shown(own[i].key) .. " " .. Fmt(L.MONEY_GOLD, { count = own[i].g }) end
    Util.Print(Fmt(L.CHAT_BOUNTY_LIST, { count = #own, max = G.C and G.C.BOUNTY_PER_SENDER or 20,
      list = table.concat(parts, ", ") }))
    return
  end
  local name, amount = rest:match("^(.-)%s+(%S+)$")
  local gold = 0
  if amount and amount:match("^%d+$") then
    gold = tonumber(amount)
    if #amount > 6 or gold > (G.C and G.C.BOUNTY_GOLD_MAX or 99999) then Util.Print(L.CHAT_BOUNTY_BAD); return end
  elseif amount and amount:match("^[%d%.,%-%+]+$") then
    Util.Print(L.CHAT_BOUNTY_BAD); return
  else
    name = rest
  end
  -- names carry no digits: a digit in the name part is a wrongly written amount
  if name and name:find("%d") then Util.Print(L.CHAT_BOUNTY_BAD); return end
  local key = G.FindTarget(name)
  if not key then Util.Print(Fmt(L.CHAT_HUNT_UNKNOWN, { name = name })); return end
  local inBook = (Store and Store.Get(key)) or G.Get(key, "all") or G.Hunt(key, "all")
  -- a name from no book: refused (taking back an own one still works)
  if not inBook and not (gold == 0 and G.OwnBounty and G.OwnBounty(key)) then
    Util.Print(Fmt(L.CHAT_BOUNTY_UNKNOWN, { name = name })); return
  end
  local ok, why = G.SetBounty(key, gold)
  Util.BountyReport(shown(key), gold, ok, why)
end

-- /dn lang [code]: shows or stores the language (works after /reload)
local function slashLang(rest)
  local Lc = ns.Locale
  if not Lc then return end
  local function nameOf(c)
    if c == Lc.AUTO then
      local r = Lc.Resolve(nil)
      return L.SET_LANG_AUTO .. ": " .. (Lc.NATIVE[r] or r) .. " (" .. Lc.AUTO .. ")"
    end
    return (Lc.NATIVE[c] or c) .. " (" .. c .. ")"
  end
  local codes = table.concat(Lc.CODES, ", ")
  if rest == "" then
    Util.Print(Fmt(L.CHAT_LANG_CURRENT, { lang = nameOf(Lc.StoredChoice() or Lc.AUTO) }))
    Util.Print(Fmt(L.CHAT_LANG_LIST, { codes = Lc.AUTO .. ", " .. codes }))
    return
  end
  local c, pending = Lc.SetChoice(rest)
  if not c then
    Util.Print(Fmt(L.CHAT_LANG_BAD, { code = rest }))
    Util.Print(Fmt(L.CHAT_LANG_LIST, { codes = Lc.AUTO .. ", " .. codes }))
    return
  end
  Util.Print(Fmt(pending and L.CHAT_LANG_RELOAD or L.CHAT_LANG_SET, { lang = nameOf(c) }))
end

function ns.HandleSlash(msg)
  msg = type(msg) == "string" and trim(msg) or ""
  local cmd, rest = msg:match("^(%S*)%s*(.-)$")
  cmd = (cmd or ""):lower()
  local Store = ns.Store
  if cmd == "" then
    ns:Fire("TOGGLE_UI")
  elseif cmd == "add" then
    if rest == "" then Util.Print(L.CHAT_WHO_ADD); return end
    local key = Store and Store.AddManual(rest)
    if key then
      Util.Print(Fmt(L.CHAT_ADDED, { name = Util.Display(Store.Get(key)) }))
    else
      Util.Print(L.CHAT_BAD_NAME)
    end
  elseif cmd == "del" or cmd == "rm" or cmd == "delete" then
    if rest == "" then Util.Print(L.CHAT_WHO_DEL); return end
    local key = Store and Store.Find(rest)
    if key then
      local disp = Util.Display(Store.Get(key))
      Store.Remove(key)
      Util.Print(Fmt(L.CHAT_REMOVED, { name = disp }))
    else
      Util.Print(Fmt(L.CHAT_NOT_IN_BOOK, { name = rest }))
    end
  elseif cmd == "still" or cmd == "ruhe" or cmd == "mute" or cmd == "quiet" then
    if not Store then return end
    local on = Store.Setting("alert.enabled") == false
    Store.Setting("alert.enabled", on)
    Util.Print(on and L.CHAT_ALARM_ON or L.CHAT_ALARM_OFF)
  elseif cmd == "probe" then
    -- "/dn probe combatlog" also tries to register the (closed) combat log; plain "/dn probe" never does
    if ns.Probe then ns.Probe.Run(true, { combatlog = rest:lower() == "combatlog" }) end
  elseif cmd == "debug" then
    local on = not (Store and Store.Setting("debug"))
    if Store then Store.Setting("debug", on) end
    Util.Print(Fmt(L.CHAT_DEBUG, { state = onOff(on) }))
  elseif cmd == "test" then
    ns:Fire("TEST_ALERT")
  elseif cmd == "gilde" or cmd == "guild" then
    local G = ns.Guild
    if not G then Util.Print(L.CHAT_GUILD_NOT_LOADED); return end
    local name = G.Name()
    if not name then
      Util.Print(L.CHAT_NO_GUILD)
    else
      Util.Print(Fmt(L.CHAT_GUILD_STATE, { guild = name, share = onOff(G.Setting("share")),
        receive = onOff(G.Setting("receive")) }))
    end
    local enemies, deeds, listed, foreign = G.Count()
    Util.Print(Fmt(L.CHAT_GUILD_BOOK, { enemies = enemies, listed = listed or 0, deeds = deeds, foreign = foreign or 0,
      manual = onOff(G.Setting("shareManual")) }))
    if G.Health then
      local h = G.Health()
      if h and h.text then Util.Print(Fmt(h.ok and L.CHAT_STATE_OK or L.CHAT_STATE_WARN, { text = h.text })) end
    end
    local members = G.Members()
    if #members == 0 then
      Util.Print(L.CHAT_NO_MATES)
    else
      Util.Print(haveList(members))
    end
  elseif cmd == "sync" then
    local G = ns.Guild
    if not G then return end
    local ok, why = G.SyncNow()
    local Fr = ns.Friends
    local fok, fwhy = false, nil
    if Fr and Fr.SyncNow then fok, fwhy = Fr.SyncNow() end
    if ok or fok then
      Util.Print(L.CHAT_SYNC_ASKED)
    elseif type(why) == "number" or type(fwhy) == "number" then
      Util.Print(Fmt(L.CHAT_SYNC_WAIT, { seconds = tonumber(why) or tonumber(fwhy) }))
    else
      local h = G.Health and G.Health("all")
      Util.Print(Fmt(L.CHAT_SYNC_FAIL, { reason = (h and not h.ok and h.text) or L.CHAT_SYNC_FAIL_DEFAULT }))
    end
  elseif cmd == "freunde" or cmd == "friends" then
    local Fr = ns.Friends
    if not Fr then Util.Print(L.CHAT_FRIENDS_NOT_LOADED); return end
    local G = ns.Guild
    local online, total = Fr.OnlineCount()
    Util.Print(Fmt(L.CHAT_FRIENDS_STATE, { share = onOff(Fr.Enabled()), online = online, total = total }))
    local enemies, deeds, listed = G.Count("friends")
    Util.Print(Fmt(L.CHAT_FRIENDS_BOOK, { enemies = enemies, listed = listed or 0, deeds = deeds }))
    local h = Fr.Health()
    if h and h.text then Util.Print(Fmt(h.ok and L.CHAT_STATE_OK or L.CHAT_STATE_WARN, { text = h.text })) end
    local members = Fr.MemberList()
    if #members == 0 then
      Util.Print(L.CHAT_NO_FRIENDS)
    else
      Util.Print(haveList(members))
    end
    -- 1.2.0: friends listed without surname and the full name each is linked to (* = not proven yet)
    local bound = Fr.Bound and Fr.Bound() or {}
    if #bound > 0 then
      local parts = {}
      for i = 1, math.min(#bound, 20) do
        local b = bound[i]
        parts[#parts + 1] = (b.list:match("^([^%-]+)") or b.list) .. " = " .. b.full .. (b.sure and "" or "*")
          .. (b.rival and (" / " .. b.rival .. "*") or "")
      end
      Util.Print(Fmt(L.CHAT_FRIENDS_TIES, { list = table.concat(parts, ", ") }))
    end
  elseif cmd == "jagd" or cmd == "hunt" then
    local G = ns.Guild
    if not (G and G.Release) then Util.Print(L.CHAT_HUNT_NOT_LOADED); return end
    if rest == "" then
      if ns.UI and ns.UI.ShowHunts then ns.UI.ShowHunts() else ns:Fire("TOGGLE_UI") end
      return
    end
    local key = G.FindTarget(rest)
    if not key then
      Util.Print(Fmt(L.CHAT_HUNT_UNKNOWN, { name = rest }))
      return
    end
    local g, f = G.Release(key)
    local disp = (G.Hunt(key, "all") or {}).display or key
    if g == nil then
      if f == "cap" then Util.Print(Fmt(L.CHAT_HUNT_CAP, { own = 10, targets = 100 }))
      elseif f == "self" then Util.Print(L.REL_SELF)
      elseif f == "mate" then Util.Print(L.REL_MATE)
      else Util.Print(L.CHAT_HUNT_NOWHERE) end
    elseif g and f then Util.Print(Fmt(L.CHAT_HUNT_BOTH, { name = disp }))
    elseif g then Util.Print(Fmt(L.CHAT_HUNT_GUILD, { name = disp }))
    else Util.Print(Fmt(L.CHAT_HUNT_FRIENDS, { name = disp })) end
  elseif cmd == "abblasen" or cmd == "calloff" then
    local G = ns.Guild
    if not (G and G.CallOff) then return end
    if rest == "" then Util.Print(L.CHAT_WHO_CALLOFF); return end
    local key = G.FindTarget(rest)
    local disp = key and (G.Hunt(key, "all") or {}).display or key
    if key and G.CallOff(key) then
      Util.Print(Fmt(L.CHAT_CALLED_OFF, { name = disp }))
    else
      Util.Print(Fmt(L.CHAT_NO_OWN_CALL, { name = rest }))
    end
  elseif cmd == "kopfgeld" or cmd == "bounty" then
    slashBounty(rest)
  elseif cmd == "lang" or cmd == "sprache" or cmd == "language" then
    slashLang(rest)
  elseif cmd == "hilfe" or cmd == "help" or cmd == "?" then
    if #HELP == 0 then buildHelp() end
    for i = 1, #HELP do Util.Print(HELP[i]) end
  elseif ns.Humor and select(2, pcall(ns.Humor.Slash, cmd)) == true then -- Humor: versteckte Befehle (nur de/en, nur sonst unbekannte Woerter)
  else
    Util.Print(L.CHAT_UNKNOWN_CMD)
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
  -- safety net: the language is built at ADDON_LOADED (Locale.lua); should that have been missed
  if ns.Locale and not ns.Locale.code then ns.Locale.Activate() end
  if ns.Store then ns.Store.Init() end
  ns.ready = true
  ns:Fire("READY")
end)

---------------------------------------------------------------------------
-- First contact (1.1.0): one chat line, once per account, 5 s after login, never in combat
---------------------------------------------------------------------------
-- 1.2.0: the three lines come from the language table (WELCOME, WELCOME_PLATES, WELCOME_SHARE: what is
-- shared with guild and friends and what never); set at activation, before PLAYER_LOGIN
ns.WELCOME_DELAY = 5
if ns.Locale and ns.Locale.OnActivate then
  ns.Locale.OnActivate(function()
    ns.WELCOME, ns.WELCOME_PLATES, ns.WELCOME_SHARE = L.WELCOME, L.WELCOME_PLATES, L.WELCOME_SHARE
    buildHelp()
  end)
end

local welcomeWaiting = false   -- true while the greeting waits for the end of a fight

local function inCombat() return Util.True(Call(_G.InCombatLockdown)) end

-- the language as the chat names it: its own name and code; "automatic" with the language it gives
local function langName(c)
  local Lc = ns.Locale
  if not Lc then return tostring(c) end
  return (Lc.NATIVE[c] or c) .. " (" .. c .. ")"
end

local function printWelcome()
  Util.Print(ns.WELCOME)
  if Util.NameplatesOn() == false then Util.Print(ns.WELCOME_PLATES) end
  Util.Print(ns.WELCOME_SHARE)
  -- where the language is changed (the book speaks the client's language unless the player chose one)
  if ns.Locale and ns.Locale.code then Util.Print(Fmt(L.CHAT_LANG_CURRENT, { lang = langName(ns.Locale.code) })) end
end

-- The one-time greeting, as in 1.1.0 a few seconds after the login (never in a fight). Returns true when shown.
function ns.Welcome()
  local Store = ns.Store
  if not (Store and Store.DB()) then welcomeWaiting = false; return false end
  if Store.Setting("welcomed") ~= false then welcomeWaiting = false; return false end
  if inCombat() then welcomeWaiting = true; return false end
  welcomeWaiting = false
  printWelcome()
  Store.Setting("welcomed", true)
  return true
end

-- 1.2.2: the delay starts at the first PLAYER_ENTERING_WORLD after READY, not at PLAYER_LOGIN: the line about
-- the enemy plates reads their CVar, and the world (with the character's CVars) is surely there by then.
local welcomeArmed = false
local function startWelcome()
  welcomeArmed = false
  local Store = ns.Store
  if not Store or Store.Setting("welcomed") ~= false then return end
  local After = _G.C_Timer and _G.C_Timer.After
  if After then After(ns.WELCOME_DELAY, ns.Welcome) else ns.Welcome() end
end
ns:On("READY", function() welcomeArmed = true end)
ns:RegisterEvent("PLAYER_ENTERING_WORLD", function()
  if welcomeArmed then startWelcome() end
  Util.CheckPlates("login")
end)

-- 1.2.2: enemy plates switched on or off. The event's first argument is the CVar name on some clients and a
-- glue name on others, so the name is not trusted: every CVAR_UPDATE compares the value (one CVar read; the
-- event is rare outside the login). Arguments that look like a nameplate CVar are kept for /dn probe.
ns:RegisterEvent("CVAR_UPDATE", function(_, a1, a2)
  local was = Util.platesOn
  Util.CheckPlates("CVAR_UPDATE")
  -- the first read after loading (unknown -> known) is no switch
  local changed = was ~= nil and was ~= Util.platesOn
  local named = not IsSecret(a1) and type(a1) == "string" and a1:lower():find("plate", 1, true) ~= nil
  if changed or named then
    local e = Util.LogPlateEvent("CVAR_UPDATE", a1, a2)
    e.switched = changed or nil
  end
end)

-- cheap: one boolean test per end of combat
ns:RegisterEvent("PLAYER_REGEN_ENABLED", function()
  if welcomeWaiting then ns.Welcome() end
end)
