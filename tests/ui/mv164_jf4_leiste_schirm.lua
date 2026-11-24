-- Jagd 1.6.4, Jaeger A, Fund 4. Aufruf: luajit jf4_leiste_schirm.lua <projekt>   (rot = Exit 1)
-- Erwartet: Die Leiste des Platzier-Modus ("Plaetze zuruecksetzen", "Fertig") bleibt auf dem Schirm und weicht nur,
-- wenn sie wirklich ein Muster trifft.
-- Auf 4f30098 rot: Place.PlaceBar nimmt als "getroffen" die ganze Spanne vom untersten bis zum obersten Muster in
-- ihrer Spalte. (a) Meldung unten abgelegt, ohne die Leiste zu beruehren: die Leiste springt ueber den Alarm.
-- (b) Steht dazu der Alarm am oberen Rand, landet sie oberhalb des Schirms (Attrappe); im Client klemmt
-- SetClampedToScreen sie dann an den Rand, also auf den Alarm.
local WT = arg[1] or "."
local J = dofile(WT .. "/tests/ui/_mv164.lua")
local db = { version = 5, settings = { welcomed = true, firstRun = "done", news164 = true, news160 = true, news150 = true,
  news140 = true, lang = "deDE" }, enemies = {}, deaths = {} }
local W = J.world("deDE", { db = db, ui = 2560 / 1366 })
local UH = W.G.UIParent:GetHeight()
W.slash("move")
local a, b, bar = W.frame("DeathNoteAlert"), W.frame("DeathNoteBanner"), W.frame("DeathNoteMove")
local _, b0, _, t0 = W.rect(bar)
local l2 = W.rect(b)
W.dragTo(b, l2, 30)          -- Meldung 30..94, die Leiste steht 160..258: keine Beruehrung
local _, nb, _, nt = W.rect(b)
local _, b1, _, t1 = W.rect(bar)
J.check("(a) Voraussetzung: Meldung liegt klar unter der Leiste", nt + 10 <= b0, ("Meldung %.0f..%.0f, Leiste %.0f..%.0f"):format(nb, nt, b0, t0))
J.check("(a) Leiste bleibt, wo sie war (nichts getroffen)", math.abs(b1 - b0) < 0.5, ("Leiste jetzt %.0f..%.0f"):format(b1, t1))
local l, ab, _, at = W.rect(a)
W.dragTo(a, l, UH - (at - ab))   -- Alarm an den oberen Rand
local _, b2, _, t2 = W.rect(bar)
J.check("(b) Leiste auf dem Schirm", b2 >= 0 and t2 <= UH + 0.5, ("Leiste %.0f..%.0f, Schirm %.0f"):format(b2, t2, UH))
J.done("jf4_leiste_schirm")
