-- (fix-2) Belegtest der finalen Jagd, in die Suite uebernommen (Aufruf aus der Projektwurzel: luajit <datei> .)
-- Zusammenspiel in der Oberflaeche:
-- (1) Erster Start: kein Sprachwahl-Dialog mehr (seit Nachtrag 3), der Alarm steht frei.
-- (2) Sprachwechsel ohne /reload bei offenem Buch: Automatisch und alle 21 Sprachen durchschalten, Buch weiter bedienen.
-- (3) Sprache per Befehl gewaehlt und zurueck auf Automatisch.
local DIR = (arg[1] or "."):gsub("/+$", "")
package.path = DIR .. "/tests/ui/?.lua;" .. DIR .. "/tests/?.lua;" .. package.path
arg[0] = DIR .. "/tests/ui/beleg.lua"
local ADDON = DIR .. "/DeathNote"
local AM, BM, G
local pass, fail, lines = 0, 0, {}
local function erwartet(name, cond, detail)
  if cond then pass = pass + 1 else fail = fail + 1; lines[#lines + 1] = "  ROT: " .. name .. (detail ~= nil and ("  -> " .. tostring(detail)) or "") end
end
local function world(opts)
  package.loaded.mock_wow, package.loaded.mock = nil, nil
  AM = require("mock_wow"); BM = require("mock")
  BM.mediaDir = ADDON .. "/Media"; G = BM.G
  AM.locale = opts.locale or "deDE"
  AM.client = opts.client
  local ns = AM.Load({ noLogin = true, lang = opts.lang, db = opts.db })
  for _, f in ipairs({ "Alert.lua", "UI.lua", "Extras.lua" }) do BM.Load(ADDON .. "/" .. f, ns) end
  AM.FireEvent("PLAYER_LOGIN"); AM.FireEvent("PLAYER_ENTERING_WORLD")
  return ns
end
local function tick(s) AM.Advance(s or 0.1); BM.Advance(s or 0.1) end
local function sauber(name)
  erwartet(name .. ": keine Fehler, keine Verstoesse", #AM.errors == 0 and #BM.violations == 0, AM.errors[1] or BM.violations[1])
end

-- (1) frischer Account mit einem Gesuchten im Buch (Update von 1.1.0): kein Sprachwahl-Dialog, der Alarm steht frei.
-- Bei 1366 x 768 und der Groesse des Mocks.
for _, size in ipairs({ { 1366, 768 }, false }) do
  local db = { version = 3, settings = { welcomed = true }, enemies = {}, deaths = {} }
  local ns = world({ lang = false, client = "deDE", db = db })
  if size then G.UIParent._w, G.UIParent._h = size[1], size[2] end
  ns.Store.AddManual("Grimm", "Bart")
  tick(6)
  erwartet("kein Sprachwahl-Dialog (UIParent " .. G.UIParent._w .. " x " .. G.UIParent._h .. ")", rawget(G, "DeathNoteLangDialog") == nil)
  AM.AddEnemy("mouseover", { name = "Grimm", surname = "Bart", guid = "Player-1-GB", level = 40 })
  AM.FireEvent("UPDATE_MOUSEOVER_UNIT"); tick()
  local popup = rawget(G, "DeathNoteAlert")
  erwartet("Alarm kommt", popup and popup:IsShown())
  erwartet("Sprache: die des Clients", ns.Locale.code == "deDE", ns.Locale.code)
  sauber("Alarm ohne Dialog")
end

-- (2) Sprachwechsel bei offenem Buch
do
  local ns = world({ lang = "deDE" })
  local key = ns.Store.AddManual("Grimm", "Bart")
  ns:Fire("TOGGLE_UI"); tick()
  ns.UI.OpenPanel("settings"); tick()
  local seen = {}
  for i = 1, 22 do
    ns.UI.StepLang = nil
    -- der Pfeil der Hausordnung
    local S
    for _, f in ipairs(BM.frames) do if f.code and f.label and f.plus then S = f end end
    if S then S.plus._scripts.OnClick(S.plus, "LeftButton") else AM.ns.HandleSlash("lang " .. ns.Locale.CODES[i]) end
    tick()
    seen[tostring(ns.Store.Setting("lang"))] = true
    ns.UI.ClosePanel(); tick()
    ns.UI.ShowEnemy(key); tick()
    for _, id in ipairs({ "open", "journal", "guild", "wanted" }) do
      for _, f in ipairs(BM.frames) do if f.id == id and f._scripts and f._scripts.OnClick then f._scripts.OnClick(f, "LeftButton"); break end end
      tick()
    end
    ns:Fire("TEST_ALERT"); tick()
    ns.UI.OpenPanel("settings"); tick()
  end
  local n = 0
  for _ in pairs(seen) do n = n + 1 end
  erwartet("Automatisch und alle 21 Sprachen durchgeschaltet", n == 22, n)
  erwartet("aktive Sprache bleibt bis zum Neuladen Deutsch", ns.Locale.code == "deDE" and ns.L.TAB_WANTED ~= nil)
  erwartet("keine fehlenden Schluessel durch das Umschalten", next(ns.Locale.missing) == nil, next(ns.Locale.missing))
  sauber("Sprachwechsel bei offenem Buch")
end

-- (3) Sprache per Befehl gewaehlt und wieder auf Automatisch
do
  local ns = world({ lang = false, client = "deDE" })
  tick(6)
  ns.HandleSlash("lang en"); tick()
  erwartet("Wahl Englisch gespeichert", ns.Store.Setting("lang") == "enUS", ns.Store.Setting("lang"))
  ns.HandleSlash("lang auto"); tick()
  erwartet("Automatisch: Wahl geloescht, Deutsch bleibt aktiv", ns.Store.Setting("lang") == nil and ns.Locale.code == "deDE")
  sauber("Befehl und Automatisch")
end

io.write(("beleg_f11_dialog_alarm_sprachwechsel %3d gruen, %d rot\n"):format(pass, fail))
for _, l in ipairs(lines) do io.write(l .. "\n") end
os.exit(fail == 0 and 0 or 1)
