-- ju01: Im Einband "trade" (Kundenbuch) geht das Themenwort des Plakatkopfes in die oeffentliche Chatzeile
-- ("[Revenge Book: Grimm Bart] KUNDE · Stand ..."); die Leser kennen das Wort nicht. Ebenso VERGELTUNG/Abschussliste
-- im Einband harbor. Erwartet: Chatzeilen nehmen die Woerter der Sprache, nicht des Einbands. Namen erfunden.
local WT = arg[1] or "."
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_ju.lua")
for _, th in ipairs({ "trade", "harbor" }) do
  local W = J.world(WT, "deDE", { ui = { theme = th } })
  local ns = W.ns
  local key = ns.Store.ApplyKill({ name = "Grimm", surname = "Bart", class = "ROGUE", level = 40 },
    { t = time() - 60, zone = "Schlingendorntal", source = "recap" }, true)
  local e = ns.Store.Get(key)
  local line = ns.Share.LineFor(e) or ""
  local rev = ns.Share.RevengeLine(e) or ""
  J.check(th .. ": Theme aktiv", ns.Theme and ns.Theme.id == th, ns.Theme and ns.Theme.id)
  J.check(th .. ": Steckbrief-Zeile traegt WANTED, kein Themenwort", line:find("] WANTED", 1, true) ~= nil, line)
  J.check(th .. ": Rache-Zeile traegt VERGELTUNG, kein Themenwort", rev:find("] VERGELTUNG", 1, true) ~= nil, rev)
end
J.done()
