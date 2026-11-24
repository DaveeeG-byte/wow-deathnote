-- jb04 (niedrig): "/dn verschieben zurücksetzen" (das deutsche Wort mit Umlaut, wie es ein Spieler tippt) und jedes
-- andere unbekannte Wort nach "/dn move" setzen nichts zurueck, sondern schalten den Modus um (Place.Slash: alles,
-- was nicht "reset" oder "zuruecksetzen" ist, ist Toggle).
-- Erwartet: das Wort mit Umlaut setzt zurueck; ein unbekanntes Wort startet den Modus nicht stillschweigend.
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_jb.lua")
local function fresh() return J.world("deDE", { db = J.db({ alert = { point = { "BOTTOMLEFT", "BOTTOMLEFT", 300, 400, 1 } } }) }) end
local W = fresh()
W.slash("verschieben zur\195\188cksetzen")
J.check("Umlaut-Wort setzt zurueck", W.ns.Store.Setting("alert.point") == nil and not W.ns.Place.Active(),
  "Modus " .. tostring(W.ns.Place.Active()))
W = fresh()
W.slash("move resett")
J.check("Tippfehler startet den Modus nicht", not W.ns.Place.Active())
J.done("jb04")
