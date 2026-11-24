-- jb08 (niedrig, Entscheidung): Der Modus endet bei Kampf, Tod, Buch, echtem Ereignis, aber nicht bei einem
-- Ladebildschirm. Wer mit offenem Modus in eine Instanz, ein Schlachtfeld oder eine Arena portet, hat die vier Muster
-- und die Leiste dort weiter auf dem Schirm (DIALOG/HIGH, mit Maus), bis der Kampf beginnt oder er selbst beendet.
-- Erwartet: PLAYER_ENTERING_WORLD waehrend des Modus beendet ihn sauber.
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_jb.lua")
local W = J.world("deDE", { db = J.db() })
W.slash("move")
J.check("Vorbedingung: Modus an", W.ns.Place.Active() and #W.samples() == 4)
W.AM.FireEvent("PLAYER_ENTERING_WORLD", false, false); W.tick(1)
J.check("nach dem Ladebildschirm: Modus aus, keine Muster, keine Leiste", not W.ns.Place.Active() and #W.samples() == 0 and not W.shown("DeathNoteMove"),
  "Muster: " .. #W.samples())
J.done("jb08")
