-- (fix-2) Belegtest der finalen Jagd, in die Suite uebernommen (Aufruf aus der Projektwurzel: luajit <datei> .)
-- Ladefehler rund um die Sprachdateien, mit Oberflaeche (Gegenprobe, erwartet gruen):
-- (1) die gewaehlte Sprachdatei fehlt (nicht geladen), (2) ihr Aufbau wirft mittendrin einen Fehler,
-- (3) sie liefert Unsinn (Zahlen, Tabellen, leere Texte, fremde Schluessel), (4) ADDON_LOADED anderer Addons zuerst,
-- auch mit Secret als Name, (5) ADDON_LOADED fuer DeathNote kommt nie (nur PLAYER_LOGIN), (6) Englisch fehlt ganz.
local DIR = (arg[1] or "."):gsub("/+$", "")
package.path = DIR .. "/tests/ui/?.lua;" .. DIR .. "/tests/?.lua;" .. package.path
arg[0] = DIR .. "/tests/ui/beleg.lua"
local ADDON = DIR .. "/DeathNote"
local AM, BM, G
local pass, fail, lines = 0, 0, {}
local function erwartet(name, cond, detail)
  if cond then pass = pass + 1 else fail = fail + 1; lines[#lines + 1] = "  ROT: " .. name .. (detail ~= nil and ("  -> " .. tostring(detail)) or "") end
end
local LOGIC = { "Core.lua", "Store.lua", "Tracker.lua", "Attribution.lua", "Probe.lua", "Sync.lua", "Friends.lua" }
-- opts: locales = Liste der Sprachdateien, die "in der TOC" geladen werden; inject = function(ns) nach Locale.lua;
-- events = function() vor dem Login; noAddonLoaded
local function world(db, opts)
  package.loaded.mock_wow, package.loaded.mock = nil, nil
  AM = require("mock_wow"); BM = require("mock")
  BM.mediaDir = ADDON .. "/Media"; G = BM.G
  AM.Reset()
  _G.DeathNoteDB = db
  AM.units.player.guild = "Die Testgilde"
  local ns = {}
  assert(loadfile(ADDON .. "/Locale.lua"))("DeathNote", ns)
  for _, c in ipairs(opts.locales or { "enUS", "deDE" }) do assert(loadfile(ADDON .. "/Locales/" .. c .. ".lua"))("DeathNote", ns) end
  if opts.inject then opts.inject(ns) end
  for _, f in ipairs(LOGIC) do assert(loadfile(ADDON .. "/" .. f))("DeathNote", ns) end
  for _, f in ipairs({ "Alert.lua", "UI.lua", "Extras.lua" }) do BM.Load(ADDON .. "/" .. f, ns) end
  AM.ns = ns
  if opts.events then opts.events() end
  if not opts.noAddonLoaded then AM.FireEvent("ADDON_LOADED", "DeathNote") end
  AM.FireEvent("PLAYER_LOGIN"); AM.FireEvent("PLAYER_ENTERING_WORLD")
  return ns
end
local function tick(s) AM.Advance(s or 0.1); BM.Advance(s or 0.1) end
local function drive(ns)
  tick(8)
  ns:Fire("TOGGLE_UI"); tick()
  for _, id in ipairs({ "wanted", "open", "journal", "guild", "wanted" }) do
    for _, f in ipairs(BM.frames) do if f.id == id and f._scripts and f._scripts.OnClick then f._scripts.OnClick(f, "LeftButton"); break end end
    tick()
  end
  ns.UI.OpenPanel("settings"); tick(); ns.UI.OpenPanel("help"); tick(); ns.UI.ClosePanel(); tick()
  ns:Fire("TEST_ALERT"); tick()
  ns.HandleSlash("hilfe"); ns.HandleSlash("lang"); ns.HandleSlash("gilde")
  tick(5)
end
local function db(lang) return { version = 3, settings = { lang = lang, welcomed = true, langAsked = true }, enemies = {}, deaths = {} } end

do -- (1)
  local ns = world(db("fiFI"), { locales = { "enUS", "deDE" } })
  drive(ns)
  erwartet("Datei der gewaehlten Sprache fehlt: Englisch aktiv, keine Fehler", ns.Locale.code == "enUS" and #AM.errors == 0 and #BM.violations == 0,
    tostring(ns.Locale.code) .. " " .. tostring(AM.errors[1] or BM.violations[1]))
  erwartet("die Wahl bleibt gespeichert (kommt die Datei wieder, gilt sie)", ns.Store.Setting("lang") == "fiFI", ns.Store.Setting("lang"))
end
do -- (2)
  local reported = 0
  local ns = world(db("fiFI"), { locales = { "enUS", "deDE" }, inject = function(ns)
    ns.Locale.Register("fiFI", function(L) L.TAB_WANTED = "Etsityt"; error("kaputt") end)
  end })
  for _, e in ipairs(AM.errors) do if tostring(e):find("kaputt", 1, true) then reported = reported + 1 end end
  AM.errors = {}
  drive(ns)
  erwartet("Aufbau der Sprache wirft: Fehler einmal gemeldet, Buch laeuft englisch weiter", reported == 1 and #AM.errors == 0 and #BM.violations == 0
    and ns.L.TAB_WANTED == "Wanted", ("gemeldet %d, %s, TAB_WANTED=%s"):format(reported, tostring(AM.errors[1]), tostring(ns.L.TAB_WANTED)))
end
do -- (3)
  local ns = world(db("fiFI"), { locales = { "enUS", "deDE" }, inject = function(ns)
    ns.Locale.Register("fiFI", function(L)
      L.TAB_WANTED = 5; L.TAB_OPEN = {}; L.TAB_JOURNAL = ""; L.FREMD = "x"; L.TIME_MINUTES = true; L[7] = "x"; L.SHEET_BOOK = false
    end)
  end })
  drive(ns)
  erwartet("Sprachdatei liefert Unsinn: englische Texte bleiben, keine Fehler", #AM.errors == 0 and #BM.violations == 0
    and ns.L.TAB_WANTED == "Wanted" and type(ns.L.TIME_MINUTES) == "string" and next(ns.Locale.missing) == nil,
    tostring(AM.errors[1] or BM.violations[1] or next(ns.Locale.missing)))
end
do -- (4)
  local ns = world(db("deDE"), { events = function()
    AM.FireEvent("ADDON_LOADED", "Blizzard_Irgendwas"); AM.FireEvent("ADDON_LOADED", AM.Secret("name", "string")); AM.FireEvent("ADDON_LOADED")
  end })
  drive(ns)
  erwartet("ADDON_LOADED anderer Addons zuerst (auch Secret): Deutsch aktiv, keine Fehler", ns.Locale.code == "deDE" and #AM.errors == 0,
    tostring(ns.Locale.code) .. " " .. tostring(AM.errors[1]))
end
do -- (5)
  local ns = world(db("deDE"), { noAddonLoaded = true })
  drive(ns)
  erwartet("ohne ADDON_LOADED: beim Login aktiviert, Deutsch, keine Fehler", ns.Locale.code == "deDE" and #AM.errors == 0 and next(ns.Locale.early) == nil,
    tostring(ns.Locale.code) .. " " .. tostring(AM.errors[1] or next(ns.Locale.early)))
end
do -- (6)
  local ok, err = pcall(function()
    local ns = world(db("deDE"), { locales = { "deDE" } })
    drive(ns)
    erwartet("Englisch fehlt: Deutsch laeuft trotzdem (alle Schluessel aus der gewaehlten Sprache)", ns.L.TAB_WANTED ~= "TAB_WANTED" and #AM.errors == 0,
      "TAB_WANTED zeigt: " .. tostring(ns.L.TAB_WANTED) .. " | " .. tostring(AM.errors[1]))
  end)
  if not ok then erwartet("Englisch fehlt: kein Abbruch", false, err) end
end

io.write(("beleg_f15_sprachdatei_fehlt_kaputt %3d gruen, %d rot\n"):format(pass, fail))
for _, l in ipairs(lines) do io.write(l .. "\n") end
os.exit(fail == 0 and 0 or 1)
