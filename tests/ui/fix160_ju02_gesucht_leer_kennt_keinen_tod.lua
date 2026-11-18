-- ju02: Abnahme neuer Spieler (die Zielgruppe von 1.6.0). Er stirbt an einem Wolf und oeffnet das Buch: es schlaegt
-- "Gesucht" auf, leer, mit "Noch kein Name eingetragen ... Wer dich in der offenen Welt toetet, steht danach hier."
-- Kein Wort, dass sein Tod im Todesjournal steht. Das Buch wirkt wie ein reines PvP-Werkzeug ohne Inhalt.
-- Erwartet: die leere Seite "Gesucht" nennt das Todesjournal (Reitername), sobald dort ein Tod steht, oder das Buch
-- schlaegt beim ersten Oeffnen das Todesjournal auf. Namen erfunden.
local WT = arg[1] or "."
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_ju160.lua")
for _, code in ipairs({ "deDE", "enUS" }) do
  local W = J.world(WT, code)
  W.creature("Grauer Wolf", 299, "Biss")
  W.open()
  local L = W.ns.L
  local onWanted = W.visible(L.EMPTY_WANTED_HEAD) ~= nil
  local mentions = false
  for _, t in ipairs(W.texts()) do
    if t:find(L.TAB_DEATHLOG, 1, true) and not t:match("^" .. L.TAB_DEATHLOG .. "%s*%d*$") then mentions = true end
  end
  J.check(code .. ": erstes Oeffnen nach einem Tod durch einen Wolf zeigt ihn oder verweist auf " .. L.TAB_DEATHLOG,
    (not onWanted) or mentions, onWanted and "Gesucht leer, kein Verweis" or "")
end
J.done()
