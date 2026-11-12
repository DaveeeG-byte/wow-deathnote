-- 1.2.2: enemy plates state (CVAR_UPDATE, NAME_PLATE_UNIT_ADDED, /dn probe), greeting timing, embedded libraries.
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local M = require("mock_wow")
local test, eq, ok, no = M.test, M.eq, M.ok, M.no
local DIR = M.ADDON_DIR

local function readFile(p)
  local f = io.open(p, "rb")
  if not f then return nil end
  local s = f:read("*a"); f:close()
  return s
end
local function plain(msg) return (msg:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")) end
local function chatHas(s)
  for _, l in ipairs(M.chat) do if plain(l):find(s, 1, true) then return true end end
  return false
end

---------------------------------------------------------------------------
-- Plates state
---------------------------------------------------------------------------
test("CheckPlates: CVAR_UPDATE compares the value, whatever the first argument", function()
  local ns = M.Load()
  local U = ns.Util
  eq(U.platesOn, true, "known after the login")
  local seen = {}
  ns:On("PLATES_CHANGED", function(on, by) seen[#seen + 1] = { on, by } end)
  M.cvars.nameplateShowEnemies = false
  M.FireEvent("CVAR_UPDATE", "NAMEPLATES_SHOW_ENEMIES", "0")
  eq(#seen, 1); eq(seen[1][1], false); eq(seen[1][2], "CVAR_UPDATE")
  M.FireEvent("CVAR_UPDATE", "SomethingElse", "1")
  eq(#seen, 1, "no change, no event")
  M.cvars.nameplateShowEnemies = true
  M.FireEvent("CVAR_UPDATE", nil, nil)
  eq(#seen, 2); eq(seen[2][1], true)
end)

test("CheckPlates: a nameplate while off reads the CVar; while on it reads nothing", function()
  local ns = M.Load()
  local U = ns.Util
  M.cvars.nameplateShowEnemies = false
  M.FireEvent("CVAR_UPDATE", "x", "0")
  eq(U.platesOn, false)
  M.cvars.nameplateShowEnemies = true
  M.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate1")
  eq(U.platesOn, true); eq(U.platesSource, "NAME_PLATE_UNIT_ADDED")
  eq(U.plateLog[1].event, "NAME_PLATE_UNIT_ADDED"); eq(U.plateLog[1].switched, true)
  local reads, orig = 0, U.NameplatesOn
  U.NameplatesOn = function(...) reads = reads + 1; return orig(...) end
  for i = 1, 40 do M.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate" .. i) end
  U.NameplatesOn = orig
  eq(reads, 0, "hot path")
end)

test("CheckPlates: secret CVar and secret event arguments change nothing", function()
  local ns = M.Load()
  local U = ns.Util
  M.cvars.nameplateShowEnemies = M.Secret("bool", "boolean")
  M.FireEvent("CVAR_UPDATE", M.Secret("name"), M.Secret("value"))
  eq(U.platesOn, true, "last plain state stays")
  eq(#M.errors, 0, tostring(M.errors[1]))
end)

test("/dn probe names the event that switched the plates and the CVAR_UPDATE arguments", function()
  local ns = M.Load()
  M.cvars.nameplateShowEnemies = false
  M.FireEvent("CVAR_UPDATE", "NAMEPLATES_SHOW_ENEMIES", "0")
  M.cvars.nameplateShowEnemies = true
  M.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate3")
  M.FireEvent("CVAR_UPDATE", M.Secret("n"), "1")      -- no switch, no plate name: not logged
  M.chat = {}
  _G.SlashCmdList.DEATHNOTE("probe")
  ok(chatHas("nameplateShowEnemies: true (NAME_PLATE_UNIT_ADDED)"), "state and source")
  ok(chatHas("NAME_PLATE_UNIT_ADDED*"), "plate event marked as the switch")
  ok(chatHas("CVAR_UPDATE(NAMEPLATES_SHOW_ENEMIES, 0)*"), "raw CVAR_UPDATE arguments")
  local p = _G.DeathNoteDB.probe.plates
  eq(p.known, true); eq(p.by, "NAME_PLATE_UNIT_ADDED"); eq(#p.events, 2)
  eq(_G.DeathNoteDB.probe.events.CVAR_UPDATE, true, "CVAR_UPDATE registrable")
  eq(#M.errors, 0, tostring(M.errors[1]))
end)

---------------------------------------------------------------------------
-- Greeting: the delay starts at PLAYER_ENTERING_WORLD
---------------------------------------------------------------------------
local WELCOME = "DeathNote: Das Buch liegt bereit."
local PLATES = "DeathNote: Feindliche Namensplaketten sind aus."
local function count(s) local n = 0 for _, l in ipairs(M.chat) do if plain(l):find(s, 1, true) == 1 then n = n + 1 end end return n end

test("Greeting: 5 s after the first PLAYER_ENTERING_WORLD, not after PLAYER_LOGIN", function()
  M.Load({ noLogin = true })
  M.FireEvent("PLAYER_LOGIN")
  M.Advance(10)
  eq(count(WELCOME), 0, "login alone (a long loading screen) does not start it")
  M.FireEvent("PLAYER_ENTERING_WORLD")
  M.Advance(4.9)
  eq(count(WELCOME), 0)
  M.Advance(0.2)
  eq(count(WELCOME), 1)
  M.FireEvent("PLAYER_ENTERING_WORLD"); M.Advance(10)
  eq(count(WELCOME), 1, "later zone changes: never again")
end)

test("Greeting: the plates line reads the CVar when it prints", function()
  M.Load({ noLogin = true, before = function() M.cvars.nameplateShowEnemies = false end })
  M.FireEvent("PLAYER_LOGIN")
  M.FireEvent("PLAYER_ENTERING_WORLD")
  M.cvars.nameplateShowEnemies = true            -- the character's CVars arrive late
  M.Advance(6)
  eq(count(WELCOME), 1); eq(count(PLATES), 0)
end)

---------------------------------------------------------------------------
-- Embedded libraries
---------------------------------------------------------------------------
local LIBS = { "LibStub\\LibStub.lua", "CallbackHandler-1.0\\CallbackHandler-1.0.lua",
  "LibDataBroker-1.1\\LibDataBroker-1.1.lua", "LibDBIcon-1.0\\LibDBIcon-1.0.lua" }

test("TOC loads Libs\\embeds.xml before the language files and Core.lua", function()
  local toc = assert(readFile(DIR .. "DeathNote.toc"))
  local pos, i = {}, 0
  for line in toc:gmatch("[^\r\n]+") do
    if not line:match("^#") and line:match("%S") then i = i + 1; pos[line:gsub("/", "\\")] = i end
  end
  ok(pos["Libs\\embeds.xml"], "embeds.xml listed")
  ok(pos["Libs\\embeds.xml"] < pos["Locale.lua"] and pos["Libs\\embeds.xml"] < pos["Core.lua"], "before Locale/Core")
end)

test("embeds.xml: LibStub, CallbackHandler, LibDataBroker, LibDBIcon in this order; files there and compile", function()
  local xml = assert(readFile(DIR .. "Libs/embeds.xml"))
  local got = {}
  for f in xml:gmatch('<Script file="([^"]+)"') do got[#got + 1] = f end
  eq(#got, #LIBS)
  for k, f in ipairs(LIBS) do
    eq(got[k], f)
    local path = DIR .. "Libs/" .. f:gsub("\\", "/")
    ok(readFile(path), "missing " .. path)
    ok(loadfile(path), "does not compile: " .. path)
  end
  ok(readFile(DIR .. "Libs/CallbackHandler-1.0/LICENSE.txt"), "CallbackHandler license")
  ok(readFile(DIR .. "Libs/LibDBIcon-1.0/LICENSE.txt"), "LibDBIcon license")
end)

test("LibDBIcon is minor 57 and has every function UI.lua calls", function()
  local src = assert(readFile(DIR .. "Libs/LibDBIcon-1.0/LibDBIcon-1.0.lua"))
  ok(src:find("DBICON10_MINOR = 57", 1, true), "minor 57 (the copy that runs on Forever in DBM-Core and BugSack)")
  for _, fn in ipairs({ "Register", "GetMinimapButton", "Hide", "Show", "Refresh" }) do
    ok(src:find("function lib:" .. fn .. "(", 1, true), "lib:" .. fn)
  end
  ok(src:find('CreateFrame("Button", "LibDBIcon10_"..name, Minimap)', 1, true), "standard button name")
end)

test("The real LibStub, CallbackHandler and LibDataBroker give our launcher back", function()
  local env = setmetatable({}, { __index = _G })
  env._G = env
  env.strmatch = string.match   -- WoW alias used by LibStub
  for k = 1, 3 do
    local chunk = assert(loadfile(DIR .. "Libs/" .. LIBS[k]:gsub("\\", "/")))
    setfenv(chunk, env)
    chunk()
  end
  local ldb = env.LibStub("LibDataBroker-1.1", true)
  ok(ldb, "LDB through LibStub")
  local obj = ldb:NewDataObject("DeathNote", { type = "launcher", icon = "x", OnClick = function() end })
  ok(obj); eq(ldb:GetDataObjectByName("DeathNote"), obj); eq(obj.type, "launcher")
  no(ldb:NewDataObject("DeathNote", {}), "second object of the same name refused")
  eq(env.LibStub("LibDBIcon-1.0", true), nil, "silent lookup of a missing library")
end)

M.done("plates/libs")
