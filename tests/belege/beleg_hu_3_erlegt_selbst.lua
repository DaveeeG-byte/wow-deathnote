-- Finding 3: a guild member takes down a hit list target himself that is not in his own book (no
-- revenge message). The taken-down message comes at once; Humor.OnBagged takes it for "the revenge message is already up"
-- (Extras.BannerShows(key) is true because Extras ran before Humor) and leaves out stamp and line.
-- If the same message comes from the queue or from a guildmate, both are there.
local here = arg[0]:match("^(.*)/[^/]+$") or "."
package.path = here .. "/?.lua;" .. package.path
local H = require("_kopf_hu")
local function lauf(src, warten)
  local ns = H.welt("deDE", { guild = H.SRC.deDE and "Die Fachkr\195\164fte" })
  local T = H.SRC.deDE
  if warten then H.kill(ns, "Anderer", "Mann") end      -- one message is up, taken down waits
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
