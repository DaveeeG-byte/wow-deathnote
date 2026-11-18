-- ju05: Buendel-Radius in Prozent der Karte (2,5 %), Nadel fest 28 px auf dem Bildschirm. Bei Leinwandskala 1
-- passt das; auf der kleinen Karte (Fenstermodus, Leinwandskala unter 1) liegen zwei Tatorte knapp ausserhalb des
-- Radius als zwei Nadeln uebereinander. Bild: dev/berichte/150/bilder/ju-karte-40-klein-deDE.png (Szene
-- ju-karte-40-klein). Erwartet: Radius in Bildschirm-Pixeln (Nadelbreite / Leinwandskala), Nadeln decken sich nie.
local WT = arg[1] or "."
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_jukarte.lua")
local W = J.map(WT, { canvasScale = 0.6 })
W.death("Grimm", 40, 40, 600)
W.death("Velka", 42.6, 40, 900)    -- 2,6 % daneben: knapp ausserhalb des Radius
W.show()
local pins = W.pins()
-- Fixer copy (decision of the orchestrator: bundle by pixels of the shown map): at canvas scale 0.6 the two spots
-- 15 px apart on the screen are one bundle with the count 2; two pins would have to be a full pin apart
J.check("ein Buendel (2) oder zwei Nadeln", (#pins == 1 and pins[1].data.count == 2) or #pins == 2, #pins)
local size = W.ns.SceneMap.PIN / 0.6          -- Nadel in Leinwand-Einheiten
if #pins == 2 then
  local a, b = pins[1].data, pins[2].data
  local dx = math.abs(a.x - b.x) / 100 * 1002
  local dy = math.abs(a.y - b.y) / 100 * 668
  J.check("Nadeln decken sich nicht (Abstand >= Nadelbreite)", dx >= size or dy >= size,
    ("Abstand %.1f, Nadel %.1f Leinwand-Einheiten"):format(dx, size))
end
J.done()
