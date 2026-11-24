-- jb03 (niedrig, im Bau-Bericht als Entscheidung 2 genannt): Steht beim Start des Modus ein echter Alarm und wartet
-- ein zweiter in der Warteschlange, endet der Modus 0,4 s nach dem Start von selbst (Finish stellt ShowNext, dessen
-- Show beendet den Modus). Im PvP-Gebiet (der Fall des Kommentars) kommt der Spieler so nicht zum Ziehen.
-- Erwartet: der Modus bleibt, bis der Spieler ihn beendet; der wartende Alarm kommt danach.
-- Der Zielknopf ist in jedem Schritt weg oder deckungsgleich (das ist in Ordnung und wird mitgeprueft).
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_jb.lua")
local W = J.world("deDE", { db = J.db() })
local k1 = W.ns.Store.AddManual("Velka Thornheart")
local k2 = W.ns.Store.AddManual("Borin Ashfall")
W.ns.Alert.Spotted(k1, nil, "test"); W.tick(0.3)
W.ns.Alert.Spotted(k2, nil, "test"); W.tick(0.3)
J.check("Vorbedingung: Alarm steht, einer wartet", W.shown("DeathNoteAlert") and W.ns.Alert.Shows(k2))
W.slash("move")
J.check("Modus an, Knopf weg", W.ns.Place.Active() and not W.shown("DeathNoteAlertButton"))
W.tick(1)
J.check("eine Sekunde spaeter: Modus laeuft noch", W.ns.Place.Active() and #W.samples() == 4, "Muster: " .. #W.samples())
local ok, why = W.buttonOk()
J.check("Zielknopf weg oder deckungsgleich", ok, why)
J.done("jb03")
