-- 1.5.0 name: players read "Revenge Book" (TOC title, book title, chat prefix, minimap tooltip, every sentence of the
-- 21 languages that names the addon), and everything that other versions, saved books or other addons rely on stays
-- (folder, DeathNoteDB, the message prefix, frame names, the broker object, the export header, the old commands).
-- New: /rb and /revengebook. Stand-alone part (TOC and language files) plus the mock (chat prefix, commands).
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local M = require("mock_wow")
local test, eq, ok, no = M.test, M.eq, M.ok, M.no
local ROOT = (arg[0]:match("^(.*)/tests/") or ".")
local DIR = ROOT .. "/DeathNote/"
local NAME = "Revenge Book"

local function read(p)
  local f = assert(io.open(p, "rb")); local s = f:read("*a"); f:close(); return s
end
local TOC = read(DIR .. "DeathNote.toc")
local function meta(key) return TOC:match("\n## " .. key:gsub("%-", "%%-") .. ": ([^\r\n]*)") end

-- every language file, built stand-alone (as tests/test_fix140_texte.lua)
local LANG = (function()
  local saved = { GetLocale = _G.GetLocale, CreateFrame = _G.CreateFrame }
  _G.GetLocale = function() return "deDE" end
  _G.CreateFrame = _G.CreateFrame or function() return { RegisterEvent = function() end, SetScript = function() end } end
  local ns = {}
  assert(loadfile(DIR .. "Locale.lua"))("DeathNote", ns)
  local out = {}
  for _, c in ipairs(ns.Locale.CODES) do assert(loadfile(DIR .. "Locales/" .. c .. ".lua"))("DeathNote", ns) end
  for _, c in ipairs(ns.Locale.CODES) do out[c] = ns.Locale.Raw(c) end
  _G.GetLocale, _G.CreateFrame = saved.GetLocale, saved.CreateFrame
  return out
end)()
local CODES = {}
for c in pairs(LANG) do CODES[#CODES + 1] = c end
table.sort(CODES)

test("21 Sprachen geladen", function() eq(#CODES, 21) end)

---------------------------------------------------------------------------
-- What players read
---------------------------------------------------------------------------
test("TOC: Titel Revenge Book, Notes nennen das Rachebuch", function()
  eq(meta("Title"), NAME)
  ok((meta("Notes") or ""):find("^World PvP revenge book: "), meta("Notes"))
  ok((meta("Notes-deDE") or ""):find("^Rachebuch"), meta("Notes-deDE"))
  for line in TOC:gmatch("## Notes[^\n]*") do no(line:find("[Dd]eath ?list"), line) end
end)

test("Buchtitel in allen 21 Sprachen: Revenge Book (englisch)", function()
  for _, c in ipairs(CODES) do eq(LANG[c].BOOK_TITLE, NAME, c) end
end)

-- a visible sentence must not name the old name; the only ones that may: the variable name (PROBE_SAVED) and the
-- one line after the update, which says that DeathNote is Revenge Book now
local MAY_NAME_OLD = { CHAT_NEWS_150 = true }
test("kein Satz in 21 Sprachen nennt noch DeathNote (ausser DeathNoteDB und der Zeile nach dem Update)", function()
  for _, c in ipairs(CODES) do
    for k, v in pairs(LANG[c]) do
      if type(v) == "string" and not MAY_NAME_OLD[k] then
        no((v:gsub("DeathNoteDB", "")):find("DeathNote", 1, true), c .. " " .. k .. ": " .. v)
      end
    end
  end
end)

test("die Saetze, die das Addon nennen, nennen Revenge Book (Stichproben je Sprache)", function()
  for _, c in ipairs(CODES) do
    local T = LANG[c]
    for _, k in ipairs({ "TIP_MATES_WITH", "SYNC_READY", "CHAT_NO_FRIENDS", "IMPORT_NOT_EXPORT", "MANUAL_GUILD" }) do
      ok(T[k]:find("Revenge[ %-]Book"), c .. " " .. k .. ": " .. tostring(T[k]))   -- deDE: Revenge-Book-Export
    end
  end
end)

test("Zeile nach dem Update in 21 Sprachen: alter Name, neuer Name, /dn, 1.5.0", function()
  for _, c in ipairs(CODES) do
    local s = LANG[c].CHAT_NEWS_150
    ok(type(s) == "string" and s:find("DeathNote", 1, true) and s:find(NAME, 1, true) and s:find("/dn", 1, true)
      and s:find("1.5.0", 1, true), c .. ": " .. tostring(s))
    no(s:find("{", 1, true), c .. " ohne Platzhalter")
  end
end)

test("Hilfezeile der neuen Befehle in 21 Sprachen", function()
  for _, c in ipairs(CODES) do
    local s = LANG[c].HELP_ALIASES
    ok(type(s) == "string" and s:find("^/rb, /revengebook  ") and s:find("/dn", 1, true), c .. ": " .. tostring(s))
  end
end)

---------------------------------------------------------------------------
-- What never changes
---------------------------------------------------------------------------
test("nie aendern: Ordner, SavedVariables, Projekt-ID, Einstiege des Addon-Fachs", function()
  local f = io.open(ROOT .. "/DeathNote/DeathNote.toc", "rb")
  ok(f, "Ordner DeathNote mit DeathNote.toc"); if f then f:close() end
  eq(meta("SavedVariables"), "DeathNoteDB")
  eq(meta("X-Curse-Project-ID"), "1797508")
  eq(meta("IconTexture"), "Interface\\AddOns\\DeathNote\\Media\\icon.tga")
  eq(meta("AddonCompartmentFunc"), "DeathNote_OnCompartmentClick")
end)

test("nie aendern: Nachrichten-Praefix, Kopfzeile des Textformats, Broker-Name, Frame-Namen", function()
  ok(read(DIR .. "Sync.lua"):find('\nlocal PREFIX = "DeathNote"\n', 1, true), "Sync PREFIX")
  ok(read(DIR .. "Store.lua"):find('\nlocal EXPORT_HEADER = "DEATHNOTE:1"\n', 1, true), "EXPORT_HEADER")
  local ui = read(DIR .. "UI.lua")
  -- LibDBIcon names its button LibDBIcon10_<object name>: the object name keeps the saved position of collectors
  ok(ui:find('\nlocal LDB_NAME = "DeathNote"\n', 1, true), "LDB_NAME")
  for _, n in ipairs({ "DeathNoteFrame", "DeathNoteMinimapButton", "DeathNoteMenu", "DeathNoteSearch" }) do
    ok(ui:find('"' .. n .. '"', 1, true), n)
  end
  ok(read(DIR .. "Alert.lua"):find('"DeathNoteAlert"', 1, true), "DeathNoteAlert")
  ok(read(DIR .. "Start.lua"):find('"DeathNoteStart"', 1, true), "DeathNoteStart")
end)

test("nie aendern: der Satz mit DeathNoteDB in 21 Sprachen", function()
  for _, c in ipairs(CODES) do ok(LANG[c].PROBE_SAVED:find("DeathNoteDB.probe", 1, true), c) end
end)

test("nie aendern: alte Befehle; neu: /rb und /revengebook, alle auf denselben Griff", function()
  M.Load()
  eq(_G.SLASH_DEATHNOTE1, "/dn"); eq(_G.SLASH_DEATHNOTE2, "/deathnote")
  eq(_G.SLASH_DEATHNOTE3, "/todesliste"); eq(_G.SLASH_DEATHNOTE4, "/deathlist")
  eq(_G.SLASH_DEATHNOTE5, "/rb"); eq(_G.SLASH_DEATHNOTE6, "/revengebook")
  eq(_G.SLASH_DEATHNOTE7, nil)
  ok(type(_G.SlashCmdList.DEATHNOTE) == "function")
end)

test("Export: Kopfzeile bleibt DEATHNOTE:1, ein 1.4.0-Text wird gelesen", function()
  local ns = M.Load()
  ns.Store.AddManual("Grimm", "Bart")
  local text = ns.Store.Export()
  eq(text:match("^[^\n]+"), "DEATHNOTE:1")
  local ns2 = M.Load()
  local okI, n = ns2.Store.Import(text)
  ok(okI, tostring(n)); eq(n, 1)
end)

---------------------------------------------------------------------------
-- Chat and help
---------------------------------------------------------------------------
local function plain(s) return (s:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")) end

test("Chat-Vorsatz Revenge Book, Marke des Musters gleich", function()
  local ns = M.Load()
  eq(ns.TITLE, NAME)
  ns.Util.Print("x")
  eq(plain(M.chat[#M.chat]), NAME .. ": x")
  ok(M.chat[#M.chat]:find("^|cffc41e3a" .. NAME .. "|r: "), "rot wie vorher")
end)

test("/dn help nennt /rb und /revengebook", function()
  M.Load(); M.chat = {}
  _G.SlashCmdList.DEATHNOTE("help")
  local found
  for _, l in ipairs(M.chat) do if plain(l):find("/rb, /revengebook", 1, true) then found = true end end
  ok(found, "Hilfezeile")
end)

M.done("name 1.5.0")
