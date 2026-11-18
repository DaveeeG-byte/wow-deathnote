-- 1.5.0 grip: the key bindings (Bindings.xml, Grip.lua). Book open/close, target into the book (class, level, guild,
-- GUID from the target), target on the hit list (standard reason, a second release with another reason replaces it),
-- alarm off/on; no target or no enemy player: a clear line, nothing written; in combat as out of it; the texts of
-- the key binding window. All names are made up.
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local M = require("mock_wow")
local test, eq, ok, no = M.test, M.eq, M.ok, M.no
local ROOT = (arg[0]:match("^(.*)/tests/") or ".")

local function noErrors() eq(#M.errors, 0, tostring(M.errors[1])) end

local function load(opts)
  opts = opts or {}
  local files = {}
  for _, f in ipairs(M.Files()) do files[#files + 1] = f end
  files[#files + 1] = "Grip.lua"
  opts.files = files
  local ns = M.Load(opts)
  _G.UnitInParty = function(u) local x = M.units[u]; return x and x.party or false end
  _G.UnitInRaid = function() return nil end
  M.screen = {}
  _G.UIErrorsFrame = { AddMessage = function(_, text) M.screen[#M.screen + 1] = text end }
  return ns
end

local function last() return M.chat[#M.chat] or "" end
local function target(o)
  o = o or {}
  M.AddEnemy("target", o)
  M.FireEvent("PLAYER_TARGET_CHANGED")
end

test("Bindings.xml: fünf Tasten (1.6.0: Hilferuf), eigene Abteilung, keine Standardbelegung, jede ruft DeathNote_Binding", function()
  local f = assert(io.open(ROOT .. "/DeathNote/Bindings.xml", "r"))
  local x = f:read("*a"); f:close()
  local names = {}
  for name, cat, body in x:gmatch('<Binding name="([%w_]+)" category="([%w_]+)">(.-)</Binding>') do
    names[#names + 1] = name
    eq(cat, "BINDING_HEADER_DEATHNOTE")
    local what = body:match('^DeathNote_Binding%("(%u+)"%)$')
    ok(what and name == "DEATHNOTE_" .. what, body)
  end
  eq(table.concat(names, ","), "DEATHNOTE_TOGGLE,DEATHNOTE_ADD,DEATHNOTE_HUNT,DEATHNOTE_ALARM,DEATHNOTE_HELP")
  local code = x:gsub("<!%-%-.-%-%->", "")
  no(code:find("[Kk]ey[12]?%s*=") or code:find("default", 1, true), "keine Standardbelegung")
  -- the game loads the file by itself: it is not in the TOC (an XML file of the TOC would be read as a UI file)
  local t = assert(io.open(ROOT .. "/DeathNote/DeathNote.toc", "r"))
  local toc = t:read("*a"); t:close()
  no(toc:find("\nBindings.xml", 1, true), "nicht in der TOC")
  ok(toc:find("\nGrip.lua", 1, true) and toc:find("\nPlate.lua", 1, true), "Grip.lua und Plate.lua in der TOC")
end)

test("Texte des Tastenfensters: Kopf = Titel aus der TOC, Namen aus der Sprachtabelle", function()
  local ns = load()
  eq(_G.BINDING_HEADER_DEATHNOTE, "DeathNote", "ohne Titel in den Metadaten: der Ordnername")
  _G.C_AddOns.GetAddOnMetadata = function(_, field) if field == "Title" then return "Revenge Book" end end
  ns.Grip.SetNames()
  eq(_G.BINDING_HEADER_DEATHNOTE, "Revenge Book", "folgt dem Anzeigenamen")
  eq(_G.BINDING_NAME_DEATHNOTE_ADD, ns.L.BIND_ADD)
  eq(_G.BINDING_NAME_DEATHNOTE_ADD, "Ziel ins Buch")
  for _, w in ipairs({ "TOGGLE", "HUNT", "ALARM" }) do ok(type(_G["BINDING_NAME_DEATHNOTE_" .. w]) == "string", w) end
  -- without metadata: the folder name
  _G.C_AddOns.GetAddOnMetadata = function() return nil end
  ns.Grip.SetNames()
  eq(_G.BINDING_HEADER_DEATHNOTE, "DeathNote")
  _G.C_AddOns.GetAddOnMetadata = function(_, field) if field == "Version" then return "1.0.0" end end
end)

test("Buch auf/zu: wie /dn", function()
  local ns = load()
  local n = 0
  ns:On("TOGGLE_UI", function() n = n + 1 end)
  _G.DeathNote_Binding("TOGGLE")
  M.inCombat = true
  _G.DeathNote_Binding("TOGGLE")
  eq(n, 2, "auch im Kampf")
end)

test("Ziel ins Buch: von Hand eingetragen mit Klasse, Stufe, Gilde und GUID vom Ziel; kleine Meldung", function()
  local ns = load()
  M.inCombat = true
  target({ name = "Grimm", surname = "Bart", guid = "Player-93-Grimm", class = "ROGUE", classLoc = "Schurke", level = 38,
    guild = "Die Dornen" })
  _G.DeathNote_Binding("ADD")
  local e = ns.Store.Get("Grimm-Bart")
  ok(e, "eingetragen")
  eq(e.manual, true); eq(e.status, "wanted"); eq(e.kills, 0)
  eq(e.class, "ROGUE"); eq(e.level, 38); eq(e.guild, "Die Dornen"); eq(e.guid, "Player-93-Grimm")
  ok(last():find("Grimm Bart steht jetzt im Buch", 1, true), last())
  ok(last():find("Stufe 38", 1, true) and last():find("<Die Dornen>", 1, true), last())
  eq(#M.screen, 1); ok(M.screen[1]:find("Grimm Bart", 1, true))
  -- twice: no second entry, the line says so
  target({ name = "Grimm", surname = "Bart", guid = "Player-93-Grimm", class = "ROGUE", level = 39 })
  _G.DeathNote_Binding("ADD")
  ok(last():find("steht schon im Buch", 1, true), last())
  eq(ns.Store.Get("Grimm-Bart").level, 39, "die neue Stufe")
  local n = 0
  for _ in pairs(ns.Store.All()) do n = n + 1 end
  eq(n, 1)
  noErrors()
end)

test("Ziel ins Buch: kein Ziel, eine Kreatur, ein Freund, die eigene Gruppe, ich selbst: klare Zeile, nichts eingetragen", function()
  local ns = load()
  _G.DeathNote_Binding("ADD")
  ok(last():find("Kein Ziel", 1, true), last())
  target({ isPlayer = false, name = "Wolf", guid = "Creature-0-1" })
  _G.DeathNote_Binding("ADD")
  ok(last():find("kein feindlicher Spieler", 1, true), last())
  target({ name = "Lieb", surname = "Freund", enemy = false, canAttack = false, faction = "Horde" })
  _G.DeathNote_Binding("ADD")
  ok(last():find("kein feindlicher Spieler", 1, true), last())
  target({ name = "Grimm", surname = "Bart", party = true })
  _G.DeathNote_Binding("ADD")
  ok(last():find("kein feindlicher Spieler", 1, true), last())
  M.units.target = M.units.player
  _G.DeathNote_Binding("ADD")
  ok(last():find("kein feindlicher Spieler", 1, true), last())
  -- a secret name (an instance): no entry, the line "no target"
  target({ name = M.Secret("name"), surname = "Bart" })
  _G.DeathNote_Binding("ADD")
  ok(last():find("Kein Ziel", 1, true), last())
  local n = 0
  for _ in pairs(ns.Store.All()) do n = n + 1 end
  eq(n, 0)
  no(M.ContainsSecret(_G.DeathNoteDB))
  noErrors()
end)

test("Feind in der Stadt (nicht angreifbar, andere Fraktion) ist ein feindlicher Spieler", function()
  local ns = load()
  target({ name = "Stadt", surname = "Wache", enemy = false, canAttack = false, faction = "Alliance" })
  _G.DeathNote_Binding("ADD")
  ok(ns.Store.Get("Stadt-Wache"))
end)

test("Ziel auf die Abschussliste: Standardgrund, im Kampf, ohne Rueckfrage; ein zweites Freigeben mit Grund ersetzt ihn", function()
  local ns = load()
  local G = ns.Guild
  local canG, canF = true, false
  G.HuntTargets = function() return canG, canF end
  local calls = {}
  local real = G.Release
  G.Release = function(key, o) calls[#calls + 1] = { key = key, why = o and o.why, to = o and o.to }; return true, false end
  M.inCombat = true
  target({ name = "Grimm", surname = "Bart", guid = "Player-93-Grimm" })
  _G.DeathNote_Binding("HUNT")
  eq(#calls, 1); eq(calls[1].key, "Grimm-Bart"); eq(calls[1].why, "Im Kampf markiert"); eq(calls[1].to, "all")
  ok(M.chat[#M.chat - 1]:find("zur Jagd freigegeben, für die Gilde", 1, true), M.chat[#M.chat - 1])
  ok(last():find("Im Kampf markiert", 1, true) and last():find("Zur Jagd freigeben", 1, true), last())
  no(ns.Store.Get("Grimm-Bart"), "die Abschussliste traegt nicht ins Buch ein")
  G.Release = real
  -- no target: nothing released
  M.units.target = nil
  local before = #calls
  _G.DeathNote_Binding("HUNT")
  eq(#calls, before); ok(last():find("Kein Ziel", 1, true), last())
  noErrors()
end)

test("Abschussliste mit echter Logik: Grund steht in der Freigabe, neues Freigeben mit anderem Grund ersetzt ihn", function()
  local ns = load()
  local G = ns.Guild
  M.units.player.guild = "Die Wurstbrueder"
  M.FireEvent("PLAYER_GUILD_UPDATE")
  local canG = G.HuntTargets()
  if not canG then
    -- no guild in this world: the friends' list is the other way; without both nothing is released
    target({ name = "Grimm", surname = "Bart", guid = "Player-93-Grimm" })
    _G.DeathNote_Binding("HUNT")
    ok(last():find("geht gerade nicht", 1, true) or last():find("Freigeben", 1, true), last())
    return
  end
  target({ name = "Grimm", surname = "Bart", guid = "Player-93-Grimm" })
  _G.DeathNote_Binding("HUNT")
  local h = G.Hunt("Grimm-Bart", "all")
  ok(h, "auf der Liste")
  eq(h.why, "Im Kampf markiert")
  ok(G.Release("Grimm-Bart", { to = "all", why = "Gankt am Flugpunkt" }))
  eq(G.Hunt("Grimm-Bart", "all").why, "Gankt am Flugpunkt", "am Plakat geaendert")
  noErrors()
end)

test("Alarm stumm/laut: wie /dn still, auch im Kampf", function()
  local ns = load()
  M.inCombat = true
  _G.DeathNote_Binding("ALARM")
  eq(ns.Store.Setting("alert.enabled"), false); ok(last():find("Alarm aus", 1, true), last())
  _G.DeathNote_Binding("ALARM")
  eq(ns.Store.Setting("alert.enabled"), true); ok(last():find("Alarm an", 1, true), last())
end)

test("Ein Fehler in der Taste bricht nichts: gemeldet, nicht geworfen", function()
  local ns = load()
  local real = ns.Grip.AddTarget
  ns.Grip.AddTarget = function() error("kaputt") end
  local okc = pcall(_G.DeathNote_Binding, "ADD")
  ok(okc, "kein Fehler in den Tastenhandler")
  ns.Grip.AddTarget = real
  ok(#M.errors >= 1 and tostring(M.errors[1]):find("kaputt", 1, true), tostring(M.errors[1]))
  M.errors = {}
end)

M.done("test_grip_tasten")
