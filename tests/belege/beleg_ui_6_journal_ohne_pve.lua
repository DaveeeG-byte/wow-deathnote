-- Todesjournal nur mit Toden durch Spieler (1.2.0, Nachtrag 4): Tode der Art "pve" (Monster, Umwelt) stehen nicht
-- im Journal, zaehlen nicht am Reiter und nicht in der Suche; "unknown" bleibt. Neue pve-Tode bekommen keine Zeile
-- (nur den Zaehler db.tally), alte pve-Zeilen bleiben in der Datei. Export und Einlesen unveraendert, die Fixture
-- (1.0.1) verliert beim Hochladen nichts.
-- Aufruf: luajit tests/belege/beleg_ui_6_journal_ohne_pve.lua <Projektkopie>. Alle Namen sind erfunden.
package.path = (arg[0]:match("^(.*)/[^/]+$") or ".") .. "/?.lua;" .. package.path
local K = require("_kopf_ui")

local function searchBox(W)
  return W.frameWith(function(f) return f._kind == "EditBox" and f.ph and f._scripts and f._scripts.OnTextChanged end)
end
local function search(W, text)
  local b = searchBox(W)
  b:SetText(text); b._scripts.OnTextChanged(b); W.tick()
end
local function zonesShown(W)
  local out = {}
  for _, r in ipairs(W.rows()) do if type(r.item) == "table" and r.item.zone then out[#out + 1] = r.item.zone end end
  return out
end
local function has(list, x) for _, v in ipairs(list) do if v == x then return true end end return false end

-- gemischtes Buch: eine alte pve-Zeile aus 1.1.0 in der Datei, dazu ein PvP-Tod, ein pve-Tod, ein unklarer Tod
local W = K.world("deDE")
local ns = W.ns
local db = ns.Store.DB()
local t = _G.time()
table.insert(db.deaths, 1, { t = t - 500, zone = "Altwald", kind = "pve", counted = true, me = "Ich Selbst", candidates = {} })
ns.Store.TouchJournal()
ns.Store.ApplyKill({ name = "Grimm", surname = "Bart", class = "MAGE", level = 40 }, { t = t - 300, zone = "Kampfplatz" }, true)
ns.Store.RecordDeath({ t = t - 300, zone = "Kampfplatz", kind = "pvp", sure = true, counted = true, killerKey = "Grimm-Bart",
  killerName = "Grimm Bart", me = "Ich Selbst", candidates = {} })
ns.Store.RecordDeath({ t = t - 200, zone = "Monsterwald", kind = "pve", counted = true, me = "Ich Selbst", candidates = {} })
ns.Store.RecordDeath({ t = t - 100, zone = "Nebel", kind = "unknown", counted = true, me = "Ich Selbst", candidates = {} })
K.check("Datei: der neue pve-Tod bekommt keine Zeile, die alte bleibt", #db.deaths == 3 and has({ db.deaths[3].zone }, "Altwald"),
  #db.deaths)
K.check("Zaehler: alle vier Tode", db.tally and db.tally.n == 4, db.tally and db.tally.n)

ns:Fire("TOGGLE_UI"); W.tick(); W.settle()
W.tab("journal"); W.settle()
local z = zonesShown(W)
K.info("Journal zeigt: " .. table.concat(z, ", "))
K.check("Journal zeigt PvP und unklar", has(z, "Kampfplatz") and has(z, "Nebel"))
K.check("Journal zeigt keine pve-Zeile (alt und neu)", not has(z, "Altwald") and not has(z, "Monsterwald"))
local tab = W.frameWith(function(f) return f.id == "journal" and f.text end)
local label = tab and tab.text._text or ""
K.check("Zahl am Reiter: 2", label:find("  2", 1, true) ~= nil and not label:find("  3", 1, true), label)
search(W, "Altwald")
K.check("Suche findet keine pve-Zeile", #W.rows() == 0, #W.rows())
search(W, "Nebel")
K.check("Suche findet den unklaren Tod", #W.rows() == 1 and W.rows()[1].item.zone == "Nebel", #W.rows())
search(W, "")

-- Export und Einlesen: unveraendert (das Journal gehoert nicht zum Export; die Taten reisen wie bisher)
local text = ns.Store.Export()
local old = table.remove(db.deaths, 3)
ns.Store.TouchJournal()
K.check("Export haengt nicht an pve-Zeilen", ns.Store.Export() == text)
table.insert(db.deaths, old); ns.Store.TouchJournal()
local W2 = K.world("deDE")
local okI = W2.ns.Store.Import(text)
local g2 = W2.ns.Store.Get("Grimm-Bart")
K.check("Einlesen: der Taeter mit seiner Tat ist da", okI and g2 and g2.kills == ns.Store.Get("Grimm-Bart").kills, g2 and g2.kills)
local n, e = W.errs()
K.check("keine Fehler", n == 0, e)

-- Fixture 1.0.1: nichts geht verloren, pve-Zeilen bleiben in der Datei
local f = assert(loadfile(K.DIR .. "/tests/fixtures/sv_1.0.1_autor.lua"))
local env = {}
setfenv(f, env); f()
local before = #(env.DeathNoteDB.deaths or {})
local pve = 0
for _, d in ipairs(env.DeathNoteDB.deaths or {}) do if d.kind == "pve" then pve = pve + 1 end end
local W3 = K.world("deDE", { db = env.DeathNoteDB })
W3.tick(10)
local db3 = W3.ns.Store.DB()
K.info(("Fixture: %d Zeilen, davon %d pve"):format(before, pve))
K.check("Fixture: keine Zeile verloren", #db3.deaths == before, #db3.deaths)
K.check("Fixture: Journal ohne pve", #W3.ns.Store.Journal() == before - pve, #W3.ns.Store.Journal())
n, e = W3.errs()
K.check("Fixture: keine Fehler", n == 0, e)

K.done("beleg_ui_6 Journal ohne pve")
