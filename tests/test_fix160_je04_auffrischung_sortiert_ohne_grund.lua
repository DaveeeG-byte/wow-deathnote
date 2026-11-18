-- Copy of the efficiency hunter's test (fixer 2 1.6.0), red on b55addb; helpers tests/_je.lua, tests/_je_gross.lua.
-- Jagd 2 Effizienz 04 (niedrig): Auffrischungen des offenen Buchs sortieren neu, obwohl sich die Reihenfolge nicht aendert.
-- a) Eine eigene Sichtung (Store.Seen -> ENEMY_UPDATED "seen") bei offenem Reiter "Gesucht", Sortierung Rang: die
--    gebuendelte Auffrischung sortiert die 3.000 Eintraege neu. 1.5.0 mit demselben Buch: 0 Vergleiche, 0,9 ms.
-- b) Der Reiter "Zu klaeren" sortiert bei jeder Auffrischung ohne jede Aenderung (alt; 1.5.0: 43.000 Vergleiche).
-- Gemessen (Attrappe, luajit -joff): a) 4,0 bis 4,1 ms, 53 Sortierlaeufe, 16.800 Vergleiche je Auffrischung (hoechstens
-- 2 je Sekunde); b) 4,7 ms, 20.000 Vergleiche je Auffrischung.
-- Erwartet: eine Auffrischung ohne Aenderung der Reihenfolge bleibt unter 2.000 Vergleichen.
-- Lauf: cd ~/Projects/wow-deathnote-jagd && luajit <diese Datei> .   (Exit 1 = Fund belegt). Die Attrappe ist nicht der Client.
local DIR = ((arg and arg[1]) or "."):gsub("/+$", "")
local HERE = debug.getinfo(1, "S").source:match("^@(.*)/[^/]+$") or "."
package.path = HERE .. "/?.lua;" .. package.path
local J = require("_je")
local X = require("_je_gross")

local db = X.build(J, DIR)
local W = J.world(DIR, { db = db, guild = X.GUILD })
local ns, AM = W.ns, W.AM
W.tick(60)
W.open()
ns.UI.SetFilter("wanted"); W.tick(2)
ns.UI.Refresh()
local base = J.measure(function() ns.UI.Refresh() end)
print(("  Auffrischung Gesucht ohne Aenderung: %.2f ms, %d Sortierlaeufe, %d Vergleiche"):format(base.ms, base.sorts, base.cmps))
AM.AddEnemy("target", { name = "Feind3", surname = "Ling", guid = "Player-93-FFeind3" })
local s0 = ns.Store.rankedSorts or 0
AM.FireEvent("PLAYER_TARGET_CHANGED")
local r = J.measure(function() W.tick(1) end)
print(("  eigene Sichtung, danach die Auffrischung: %.2f ms, %.0f KB, %d Sortierlaeufe, %d Vergleiche; Store.rankedSorts +%d")
  :format(r.ms, r.kb, r.sorts, r.cmps, (ns.Store.rankedSorts or 0) - s0))
J.check("a) Auffrischung nach einer eigenen Sichtung: unter 2.000 Vergleiche", r.cmps < 2000, r.cmps)
ns.UI.SetFilter("open"); W.tick(2)
ns.UI.Refresh()
local o = J.measure(function() ns.UI.Refresh() end)
print(("  Auffrischung Zu klaeren ohne Aenderung: %.2f ms, %.0f KB, %d Sortierlaeufe, %d Vergleiche"):format(o.ms, o.kb, o.sorts, o.cmps))
J.check("b) Auffrischung Zu klaeren ohne Aenderung: unter 2.000 Vergleiche", o.cmps < 2000, o.cmps)
J.check("keine Fehler der Attrappe", #AM.errors == 0, AM.errors[1])
J.done()
