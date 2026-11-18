-- Jagd Logik 160/01: Ein Hilferuf (Praefix DeathNoteSOS, WHISPER) wird angenommen, sobald der Vorname des Absenders
-- auf der Freundesliste steht (Call.OnAddon: nur Friends.FriendOf + Muted). Die Pruefung des Buchs auf den gebundenen
-- Freund (Friends.lua identity: vorlaeufige Bindung, GUID-Beweis, Namensvetter) wird uebergangen. Ein Fremder mit dem
-- Vornamen eines Freundes loest so lauten Alarm, Zettel und Kartennadel mit erfundenem Ort aus, obwohl das Buch
-- dieselbe Person auf Praefix DeathNote als Fremden verwirft.
-- Lauf: cd ~/Projects/wow-deathnote-jagd && luajit <diese Datei> .   (Exit 1 = Fund belegt)
local DIR = ((arg and arg[1]) or "."):gsub("/+$", "")

package.path = DIR .. "/tests/?.lua;" .. package.path
local H = require("beleg_helfer")
local SOS = "DeathNoteSOS"

local function rufe(c, ns, from)
  local text = ns.Call.Encode({ mapID = 1434, x = 50, y = 50, t = time(), display = "Lockvogel" })
  c.fire("CHAT_MSG_ADDON", SOS, text, "WHISPER", from)
end

H.lauf("Freund ohne Nachnamen auf der Liste, gebunden an Berta Senf; Berta Falsch ruft", function()
  local W = H.welt({ "HELP_CALL", "GUILD_UPDATED" })
  local a = W.client("Anton", "Wurst", nil, { friends = { "Berta" } })
  a.login(); W.run(40)
  local P = a.ns.Guild.Proto
  -- die echte Berta bindet den Namen (erster gueltiger Kontakt)
  H.fluestern(a, P.EncodeHunt({ key = "Echt-Lamm", t = time(), by = "Berta Senf", why = "echt" }), "Berta Senf-Forever")
  H.erwartet("Vorbedingung: Berta Senf gebunden", a.ns.Guild.Hunt("Echt-Lamm", "friends") ~= nil)
  -- das Buch verwirft den Namensvetter
  H.fluestern(a, P.EncodeHunt({ key = "Falsch-Lamm", t = time(), by = "Berta Falsch", why = "x" }), "Berta Falsch-Forever")
  H.erwartet("Vorbedingung: Buch verwirft Berta Falsch", a.ns.Guild.Hunt("Falsch-Lamm", "friends") == nil)
  rufe(a, a.ns, "Berta Falsch-Forever")
  H.erwartet("Hilferuf des Namensvetters wird verworfen", H.zaehle(a, "HELP_CALL") == 0,
    H.zaehle(a, "HELP_CALL") .. " Alarm(e) von Berta Falsch")
end)

H.lauf("Freundesliste gibt die GUID; ein unbewiesener Absender gleichen Vornamens ruft", function()
  local W = H.welt({ "HELP_CALL" })
  W.guids = true
  local a = W.client("Anton", "Wurst", nil, { friends = { "Berta" } })
  local b = W.client("Berta", "Senf", nil, { friends = { "Anton" } })
  a.login(); W.run(40)   -- Berta ist nicht eingeloggt: es gab nie ein Hallo mit ihrer GUID
  rufe(a, a.ns, "Berta Falsch-Forever")
  H.erwartet("ohne GUID-Beweis kein Alarm", H.zaehle(a, "HELP_CALL") == 0, H.zaehle(a, "HELP_CALL") .. " Alarm(e)")
end)

H.fertig()
