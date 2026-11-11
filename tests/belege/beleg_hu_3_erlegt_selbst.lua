-- Fund 3: Mitglied der Gilde erlegt selbst ein Ziel der Abschussliste, das nicht im eigenen Buch steht (keine
-- Rache-Meldung). Die Erlegt-Meldung kommt sofort; Humor.OnBagged haelt sie fuer "die Rache-Meldung steht schon"
-- (Extras.BannerShows(key) ist wahr, weil Extras vor Humor dran war) und laesst Stempel und Spruch weg.
-- Kommt dieselbe Meldung aus der Warteschlange oder von einem Kollegen, sind beide da.
local here = arg[0]:match("^(.*)/[^/]+$") or "."
package.path = here .. "/?.lua;" .. package.path
local H = require("_kopf_hu")
local function lauf(src, warten)
  local ns = H.welt("deDE", { guild = H.SRC.deDE and "Die Fachkr\195\164fte" })
  local T = H.SRC.deDE
  if warten then H.kill(ns, "Anderer", "Mann") end      -- eine Meldung steht, Erlegt wartet
  ns:Fire("HUNT_BAGGED", "Ziel-Eins", "Hans", _G.time(), src); H.settle()
  if warten then H.away() end
  local b = H.banner()
  local istErlegt = b and b:IsShown() and b.key == "Ziel-Eins"
  return ns.Humor.IsMember(), istErlegt, H.stampText() == T.STAMP.pro, H.quip() ~= nil
end
local m, da, stempel, spruch = lauf("guild", false)
H.check("Vorbedingung: Mitglied, Erlegt-Meldung eines Kollegen sofort: Stempel und Spruch", m and da and stempel and spruch)
m, da, stempel, spruch = lauf("self", true)
H.check("Vorbedingung: eigener Abschuss aus der Warteschlange: Stempel und Spruch", da and stempel and spruch)
m, da, stempel, spruch = lauf("self", false)
H.check("Vorbedingung: eigener Abschuss, Erlegt-Meldung steht sofort", da)
H.check("eigener Abschuss, Meldung sofort: Mitglieder-Stempel", stempel)
H.check("eigener Abschuss, Meldung sofort: Spruch (Wahrscheinlichkeit 1)", spruch)
H.ende("beleg_hu_3_erlegt_selbst")
