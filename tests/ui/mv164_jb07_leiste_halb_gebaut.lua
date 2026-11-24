-- jb07 (niedrig): Fehler mitten im Aufbau der Leiste. BuildBar weist "bar" in der ersten Zeile zu; bricht der Aufbau
-- danach ab (hier: Look.Text wirft einmal), bleibt eine halbe Leiste fuer die ganze Sitzung: "if not bar" ist beim
-- naechsten Start falsch, es wird nie neu gebaut. Folge: Leiste ohne Text und Knoepfe, kein OnHide, kein Eintrag in
-- UISpecialFrames, also beendet Esc den Modus nicht mehr (die Leiste verschwindet, die Muster bleiben).
-- Erwartet: der naechste Start baut die Leiste neu (Knopf "Fertig" da), und Esc beendet den Modus.
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_jb.lua")
local W = J.world("deDE", { db = J.db() })
-- die vier Stuecke vorab bauen lassen, damit der Fehler die Leiste trifft und nicht ein Muster
W.ns.Store.AddManual("Velka Thornheart")
W.ns:Fire("TEST_ALERT"); W.ns.CallUI.Show({ by = "Liora", zone = "Ashenvale", same = true }); W.ns.Extras.Notice("RANG", "Grimwald", "Zeile")
W.ns.Grudge.Test(); W.tick(0.6); W.settle(); if W.ns.Grudge.Current() then W.ns.Grudge.Close("click") end; W.tick(1)
local Look = W.ns.Look
local real, n = Look.Text, 0
Look.Text = function(...) n = n + 1; if n == 1 then error("einmaliger Fehler im Aufbau") end return real(...) end
W.slash("move")
Look.Text = real
J.check("Vorbedingung: der Fehler traf die Leiste, der Modus laeuft mit vier Mustern", n >= 1 and W.ns.Place.Active() and #W.samples() == 4, #W.samples())
W.slash("move")
J.check("Modus laesst sich beenden", not W.ns.Place.Active() and #W.samples() == 0)
W.slash("move")                                   -- zweiter Start, jetzt ohne Fehler
local bar = W.frame("DeathNoteMove")
J.check("zweiter Start: Leiste vollstaendig (Knopf Fertig)", bar ~= nil and bar.done ~= nil and bar.reset ~= nil)
W.esc()
J.check("zweiter Start: Esc beendet den Modus", not W.ns.Place.Active() and #W.samples() == 0, "Muster: " .. #W.samples())
J.done("jb07")
