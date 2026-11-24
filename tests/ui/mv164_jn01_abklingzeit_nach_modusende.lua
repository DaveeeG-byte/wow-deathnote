-- Nachjagd 1.6.4, Fund N1. Aufruf: luajit jn01_abklingzeit_nach_modusende.lua <projekt>   (rot = Exit 1)
-- Erwartet: Ein Alarm, der gezeigt wurde, setzt die Abklingzeit seines Spielers (alert.cooldown, 90 s), auch wenn
-- genau dieser Alarm den Platzier-Modus beendet hat.
-- Ablauf: Alarm fuer A steht, Spieler startet den Modus (A wird "geschluckt"), bleibt laenger als 90 s im Modus,
-- A kommt wieder in Sicht: echter Alarm, Modus endet (so entschieden). Der Alarm laeuft ab, A ist weiter in Sicht.
-- Ist auf e9c9b36: A klingelt sofort noch einmal. Alert.Spotted ruft Mark(key) und dann Show(); Show beendet den
-- Modus, Alert.EndSample gibt die Abklingzeit aller geschluckten Schluessel zurueck und loescht damit die eben
-- gesetzte Marke von A (Alert.lua, EndSample: lastAlert[k] = nil). Dasselbe gilt fuer lastVictim beim Opfer-Alarm.
local WT = arg[1] or "."
local J = dofile(WT .. "/tests/ui/_mv164.lua")
local db = { version = 5, settings = { welcomed = true, firstRun = "done", news164 = true, news160 = true, news150 = true,
  news140 = true, lang = "enUS" }, enemies = {}, deaths = {} }
local W = J.world("enUS", { db = db })
local k1 = W.ns.Store.AddManual("Velka Thornheart")
W.ns.Alert.Spotted(k1, nil, "x"); W.tick(0.2)
local a = W.frame("DeathNoteAlert")
J.check("Voraussetzung: Alarm fuer A steht", a and a:IsShown() and not a.sample)
W.slash("move")
J.check("Voraussetzung: Modus an", W.ns.Place.Active())
W.ns.Alert.Spotted(k1, nil, "x"); W.tick(0.2)
J.check("A in Sicht waehrend seiner Abklingzeit beendet den Modus nicht", W.ns.Place.Active())
W.tick(95)
W.ns.Alert.Spotted(k1, nil, "x"); W.tick(0.2)
J.check("nach 95 s im Modus: echter Alarm fuer A, Modus aus", not W.ns.Place.Active() and a:IsShown() and not a.sample)
W.settle()
J.check("Voraussetzung: der Alarm ist abgelaufen (rund 15 s spaeter)", not a:IsShown())
W.ns.Alert.Spotted(k1, nil, "x"); W.tick(0.2)
J.check("A klingelt 15 s nach seinem Alarm nicht noch einmal (Abklingzeit 90 s)", not a:IsShown())
-- Gegenprobe ohne Modus (gruen): derselbe Ablauf, die Abklingzeit haelt
local W2 = J.world("enUS", { db = { version = 5, settings = db.settings, enemies = {}, deaths = {} } })
local k2 = W2.ns.Store.AddManual("Velka Thornheart")
W2.ns.Alert.Spotted(k2, nil, "x"); W2.tick(0.2)
local a2 = W2.frame("DeathNoteAlert")
W2.settle()
W2.ns.Alert.Spotted(k2, nil, "x"); W2.tick(0.2)
J.check("Gegenprobe ohne Modus: kein zweiter Alarm in der Abklingzeit", not a2:IsShown())
J.done("jn01")
