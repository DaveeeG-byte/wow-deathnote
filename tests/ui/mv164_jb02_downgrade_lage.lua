-- jb02 (niedrig): Downgrade auf 1.6.3. Nach einer Groessenaenderung in 1.6.4 bleibt alert.point in den Einheiten der
-- ALTEN Groesse gespeichert (Feld 5 traegt sie). 1.6.3 liest nur die Felder 1 bis 4 und setzt sie in der aktuellen
-- Groesse: der Alarm steht nach einem Downgrade woanders (und nach erneutem Update wieder richtig).
-- Erwartet: die gespeicherte Lage, nach der Regel von 1.6.3 gelesen (SetPoint(p, UIParent, rp, x, y) in der
-- aktuellen Alarmgroesse, also Schirmversatz = x * alert.scale), ergibt dieselbe Stelle, an der 1.6.4 den Alarm zeigt.
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_jb.lua")
local W = J.world("deDE", { db = J.db({ alert = { scale = 1.3 } }) })
W.ns.Store.AddManual("Velka Thornheart")
W.slash("move")
W.dragTo(W.frame("DeathNoteAlert"), 600, 500)
W.slash("move")
W.ns.Store.Setting("alert.scale", 0.8); W.tick(0.1)
W.ns:Fire("TEST_ALERT"); W.tick(0.5)
local l, b = W.rect(W.frame("DeathNoteAlert"))
J.check("1.6.4 haelt die Ecke bei 600/500", math.abs(l - 600) < 1 and math.abs(b - 500) < 1, ("%.0f/%.0f"):format(l, b))
local pt = W.ns.Store.Setting("alert.point")
local s = W.ns.Store.Setting("alert.scale")
J.check("Regel von 1.6.3 auf die gespeicherte Lage: dieselbe Ecke", pt[1] == "BOTTOMLEFT" and math.abs(pt[3] * s - l) < 1 and math.abs(pt[4] * s - b) < 1,
  ("1.6.3 zeigte %.0f/%.0f, 1.6.4 zeigt %.0f/%.0f"):format(pt[3] * s, pt[4] * s, l, b))
J.done("jb02")
