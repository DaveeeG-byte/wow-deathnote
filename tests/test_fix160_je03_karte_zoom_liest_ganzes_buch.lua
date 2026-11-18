-- Copy of the efficiency hunter's test (fixer 2 1.6.0), red on b55addb; helpers tests/_je.lua, tests/_je_gross.lua.
-- Jagd 2 Effizienz 03 (mittel): Jede Aenderung des Kartenmassstabs (Haken auf WorldMapFrame.OnCanvasScaleChanged,
-- SceneMap.lua rescale -> SceneMap.Refresh -> Scene.Pins -> Scene.All) liest das ganze Buch neu: alle Eintraege, alle
-- Gilden- und Freundeslisten, ohne Cache und ohne Buendelung. Ebenso jeder Kartenwechsel (OnMapChanged).
-- Gemessen (Attrappe, luajit -joff, volles Buch): je Aufruf 6,6 bis 7,5 ms und 4,5 MB Muell; 30 Aufrufe (ein Zoom, wenn
-- der Client den Haken je Bild ruft): rund 200 ms und 135 MB. Alt seit 1.5.0 (dort gleich: 6,6 ms, 4,5 MB), aber erst der
-- Deckel 3.000 und die fuenf Listen von 1.6.0 machen so grosse Buecher zum erlaubten Fall.
-- Wie oft Forever OnCanvasScaleChanged je Zoom ruft, ist im Client ungemessen (Retail: je Bild der Zoom-Animation).
-- Erwartet: ohne Aenderung am Buch liest ein Massstabswechsel das Buch nicht neu (30 Wechsel unter 20 MB Muell).
-- Lauf: cd ~/Projects/wow-deathnote-jagd && luajit <diese Datei> .   (Exit 1 = Fund belegt). Die Attrappe ist nicht der Client.
local DIR = ((arg and arg[1]) or "."):gsub("/+$", "")
local HERE = debug.getinfo(1, "S").source:match("^@(.*)/[^/]+$") or "."
package.path = HERE .. "/?.lua;" .. package.path
local J = require("_je")
local X = require("_je_gross")

local SM = dofile(DIR .. "/tests/ui/scene_map.lua")
local wm
local db = X.build(J, DIR)
local W = J.world(DIR, { db = db, guild = X.GUILD, before = function(AM, BM) wm = SM.Install(BM, { mapID = 1434 }); wm:Hide() end })
local ns, AM = W.ns, W.AM
W.tick(60)
J.check("Vorbedingung: Karte angebunden", ns.SceneMap.Map() == wm)
wm:Show(); W.tick(1)
local pins = #ns.SceneMap.Shown()
J.check("Vorbedingung: Nadeln auf der Karte", pins > 0, pins)
-- zaehlen, wie oft das Buch gelesen wird
local calls, all = 0, ns.Scene.All
ns.Scene.All = function(...) calls = calls + 1; return all(...) end
local one = J.measure(function() wm:OnCanvasScaleChanged() end)
print(("  ein Massstabswechsel: %.2f ms, %.1f MB Muell, Scene.All %d mal"):format(one.ms, one.kb / 1024, calls))
calls = 0
local z = J.measure(function() for i = 1, 30 do wm._canvasScale = 1 + i * 0.02; wm:OnCanvasScaleChanged(); W.tick(0.02) end end)
print(("  30 Massstabswechsel in 0,6 s (ein Zoom): %.0f ms, %.0f MB Muell, Scene.All %d mal"):format(z.ms, z.kb / 1024, calls))
J.check("ein Zoom liest das Buch hoechstens zweimal", calls <= 2, calls)
J.check("ein Zoom erzeugt unter 20 MB Muell", z.kb < 20 * 1024, ("%.0f MB"):format(z.kb / 1024))
J.check("keine Fehler der Attrappe", #AM.errors == 0, AM.errors[1])
J.done()
