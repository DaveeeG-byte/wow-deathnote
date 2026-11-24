-- jb01 (niedrig): "A changed alarm size keeps the alarm's kept place" (CHANGELOG 1.6.4) gilt nicht, solange der Alarm
-- in der Sitzung noch nicht gebaut ist und die Lage aus 1.6.3 stammt (vier Felder, ohne Skala).
-- Erwartet: Lage aus 1.6.3 (linke untere Ecke 300/400 bei Groesse 100 %), nach dem Update wird in der Hausordnung
-- die Alarmgroesse auf 130 % gestellt, BEVOR der erste Alarm der Sitzung kam: die Ecke bleibt bei 300/400.
-- Ist auf 4f30098: 390/520 (wie 1.6.3), weil Alert.ApplyScale ohne popup sofort zurueckkehrt und nichts stempelt.
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_jb.lua")
local W = J.world("deDE", { db = J.db({ alert = { point = { "BOTTOMLEFT", "BOTTOMLEFT", 300, 400 } } }) })
W.ns.Store.AddManual("Velka Thornheart")
W.ns.Store.Setting("alert.scale", 1.3); W.tick(0.1)          -- Hausordnung, Blatt Alarm, vor dem ersten Alarm
W.ns:Fire("TEST_ALERT"); W.tick(0.5)
local l, b = W.rect(W.frame("DeathNoteAlert"))
J.check("Groesse vor dem ersten Alarm: Ecke bleibt bei 300/400", math.abs(l - 300) < 1 and math.abs(b - 400) < 1, ("%.0f/%.0f"):format(l, b))
-- Gegenprobe (gruen): dieselbe Aenderung NACH dem ersten Alarm haelt die Ecke
local W2 = J.world("deDE", { db = J.db({ alert = { point = { "BOTTOMLEFT", "BOTTOMLEFT", 300, 400 } } }) })
W2.ns.Store.AddManual("Velka Thornheart")
W2.ns:Fire("TEST_ALERT"); W2.tick(0.5)
W2.ns.Store.Setting("alert.scale", 1.3); W2.tick(0.1)
local l2, b2 = W2.rect(W2.frame("DeathNoteAlert"))
J.check("Gegenprobe: Groesse nach dem ersten Alarm haelt die Ecke", math.abs(l2 - 300) < 1 and math.abs(b2 - 400) < 1, ("%.0f/%.0f"):format(l2, b2))
J.done("jb01")
