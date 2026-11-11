-- Fund 9: /dn FACHKRAFT und /dn Fachkr(ae)fte gehen, /dn FACHKR(AE)FTE mit grossem Umlaut ist "unbekannter Befehl":
-- string.lower wandelt nur ASCII, der Tabellenschluessel hat den kleinen Umlaut.
local here = arg[0]:match("^(.*)/[^/]+$") or "."
package.path = here .. "/?.lua;" .. package.path
local H = require("_kopf_hu")
local ns = H.welt("deDE")
local function antwortet(cmd)
  H.AM.chat = {}; ns.Humor.said = nil
  ns.HandleSlash(cmd)
  return ns.Humor.said ~= nil
end
local klein, gross = "fachkr\195\164fte", "FACHKR\195\132FTE"
H.check("Vorbedingung: der Befehl mit kleinem Umlaut steht in der Tabelle", ns.Humor.COMMANDS[klein] ~= nil)
H.check("Vorbedingung: klein geschrieben antwortet er", antwortet(klein))
H.check("Vorbedingung: ASCII-Befehl in Grossbuchstaben antwortet", antwortet("FACHKRAFT"))
H.check("in Grossbuchstaben mit Umlaut antwortet er auch", antwortet(gross), "unbekannter Befehl")
H.ende("beleg_hu_9_umlaut")
