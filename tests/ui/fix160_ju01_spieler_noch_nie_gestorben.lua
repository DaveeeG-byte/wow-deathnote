-- ju01: Neuer Spieler, einmal an einem Wolf gestorben. Todesjournal, Ansicht "Spieler": die leere Seite sagt
-- "Noch nie gestorben. Respekt. Oder Luege." (enUS entsprechend), obwohl das Buch einen Tod kennt und der Reiter ihn
-- in "Alles" zaehlt. Erwartet: ein Leer-Text, der zur Ansicht passt ("Kein Spieler hat dich getoetet" o. ae.) und
-- auf "Alles" zeigt. Namen erfunden.
local WT = arg[1] or "."
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_ju160.lua")
for _, code in ipairs({ "deDE", "enUS" }) do
  local W = J.world(WT, code)
  W.creature("Grauer Wolf", 299, "Biss")
  W.open(); W.tab("journal")
  W.click(W.find(function(x) return x.fateView and x.view == "players" end))
  W.settle()
  local head = W.ns.L.EMPTY_JOURNAL_HEAD
  J.check(code .. ": Ansicht Spieler nach einem Tod durch Kreatur behauptet nicht \"" .. head .. "\"",
    not W.visible(head), head)
end
J.done()
