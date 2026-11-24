-- Jagd 1.6.4, Jaeger A, Fund 5. Aufruf: luajit jf5_wartender_alarm.lua <projekt>   (rot = Exit 1)
-- Erwartet (Regeln, Entscheidung 1: die Muster stehen "so lange, bis der Spieler fertig ist"): Startet der Spieler
-- den Platzier-Modus, waehrend ein Alarm steht und ein zweiter wartet ("+1 more"), bleibt der Modus stehen; ein
-- Alarm, der schon vor dem Start bekannt war, beendet ihn nicht eine halbe Sekunde spaeter. Mindestens sagt eine
-- Chatzeile, warum der Modus weg ist.
-- Auf 4f30098 rot: Alert.ShowSample ruft Finish(), das nach 0,4 s den wartenden Alarm zeigt; dessen Show beendet
-- den Modus, ohne ein Wort im Chat. (Im Bau-Bericht als Entscheidung 2 fuer den Besitzer genannt, ohne Test.)
local WT = arg[1] or "."
local J = dofile(WT .. "/tests/ui/_mv164.lua")
local db = { version = 5, settings = { welcomed = true, firstRun = "done", news164 = true, news160 = true, news150 = true,
  news140 = true, lang = "enUS" }, enemies = {}, deaths = {} }
local W = J.world("enUS", { db = db })
local k1 = W.ns.Store.AddManual("Velka Thornheart")
local k2 = W.ns.Store.AddManual("Torvik Greyhammer")
W.ns.Alert.Spotted(k1, nil, "x"); W.tick(0.2)
W.ns.Alert.Spotted(k2, nil, "x"); W.tick(0.2)
local a = W.frame("DeathNoteAlert")
J.check("Voraussetzung: ein Alarm steht, einer wartet", a and a:IsShown() and a.more:GetText() ~= "" and a.more:GetText() ~= nil, a and a.more:GetText())
local n = #W.chat()
W.slash("move")
J.check("Voraussetzung: Modus an, vier Muster", W.ns.Place.Active() and #W.samples() == 4)
W.tick(0.5)
local still = W.ns.Place.Active() and #W.samples() == 4
J.check("0,5 s spaeter: Modus steht noch", still)
J.check("oder: eine Chatzeile sagt, warum er endete", still or #W.chat() > n, ("%d neue Zeilen"):format(#W.chat() - n))
J.done("jf5_wartender_alarm")
