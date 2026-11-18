-- Fixer 1.6.0 (jl01, counter-check): the help call by whisper still comes from the bound friend himself, with the
-- bound full name (provisional binding) and with the GUID proven by his hello. Names made up.
local DIR = ((arg and arg[1]) or "."):gsub("/+$", "")

package.path = DIR .. "/tests/?.lua;" .. package.path
local H = require("beleg_helfer")
local SOS = "DeathNoteSOS"

local function rufe(c, ns, from)
  local text = ns.Call.Encode({ mapID = 1434, x = 50, y = 50, t = time(), display = "Lockvogel" })
  c.fire("CHAT_MSG_ADDON", SOS, text, "WHISPER", from)
end

H.lauf("gebundene Berta Senf ruft per Fluestern: kommt an", function()
  local W = H.welt({ "HELP_CALL", "GUILD_UPDATED" })
  local a = W.client("Anton", "Wurst", nil, { friends = { "Berta" } })
  a.login(); W.run(40)
  local P = a.ns.Guild.Proto
  H.fluestern(a, P.EncodeHunt({ key = "Echt-Lamm", t = time(), by = "Berta Senf", why = "echt" }), "Berta Senf-Forever")
  H.erwartet("Vorbedingung: Berta Senf gebunden", a.ns.Guild.Hunt("Echt-Lamm", "friends") ~= nil)
  rufe(a, a.ns, "Berta Senf-Forever")
  H.erwartet("Ruf der gebundenen Freundin kommt an", H.zaehle(a, "HELP_CALL") == 1, H.zaehle(a, "HELP_CALL"))
end)

H.lauf("Freund ohne Bindung (noch kein Kontakt) ruft mit vollem Namen: still verworfen", function()
  local W = H.welt({ "HELP_CALL" })
  local a = W.client("Anton", "Wurst", nil, { friends = { "Berta" } })
  a.login(); W.run(40)
  rufe(a, a.ns, "Berta Senf-Forever")
  H.erwartet("ohne Bindung kein Ruf", H.zaehle(a, "HELP_CALL") == 0, H.zaehle(a, "HELP_CALL"))
end)

H.fertig()
