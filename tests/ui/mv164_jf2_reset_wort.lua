-- Jagd 1.6.4, Jaeger A, Fund 2. Aufruf: luajit jf2_reset_wort.lua <projekt>   (rot = Exit 1)
-- Erwartet: Wer im deutschen Client das Wort tippt, das auf dem Knopf der Leiste steht ("Plaetze zuruecksetzen" mit
-- Umlaut), also "/dn verschieben zurücksetzen", setzt zurueck. Und ein Wort, das der Befehl nicht kennt
-- ("/dn move off"), schaltet den Modus nicht EIN.
-- Auf 4f30098 rot: beides startet den Platzier-Modus (Place.Slash: alles ausser reset/zuruecksetzen schaltet um).
local WT = arg[1] or "."
local J = dofile(WT .. "/tests/ui/_mv164.lua")
local db = { version = 5, settings = { welcomed = true, firstRun = "done", news164 = true, news160 = true, news150 = true,
  news140 = true, lang = "deDE", alert = { point = { "CENTER", "CENTER", 200, 100, 1 } } }, enemies = {}, deaths = {} }
local W = J.world("deDE", { db = db })
W.slash("verschieben zurücksetzen")
J.check("zurücksetzen (Umlaut): startet den Modus nicht", not W.ns.Place.Active())
J.check("zurücksetzen (Umlaut): Lage des Alarms zurueckgesetzt", W.ns.Store.Setting("alert.point") == nil)
J.check("zurücksetzen (Umlaut): Zeile MOVE_RESET_DONE", W.said(W.ns.L.MOVE_RESET_DONE) == 1)
if W.ns.Place.Active() then W.ns.Place.Stop("cmd") end
W.slash("move off")
J.check("/dn move off bei ausgeschaltetem Modus: schaltet nicht ein", not W.ns.Place.Active())
J.done("jf2_reset_wort")
