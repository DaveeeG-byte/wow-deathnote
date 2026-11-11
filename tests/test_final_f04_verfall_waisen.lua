-- W1 (Verfall einstellbar, Voreinstellung Nie) gegen den Zweck: Freigaben, die niemand mehr zuruecknehmen kann.
-- (1) Ich stelle "30 Tage" ein: meine eigene Freigabe faellt bei mir nach 30 Tagen still weg (kein Abblasen geht
--     raus). Alle anderen (Voreinstellung Nie) behalten sie fuer immer, und ich kann sie nicht mehr abblasen.
-- (2) Ich blase ab, waehrend ein Kollege laenger als 30 Tage weg ist (das Merken der Abblasen haelt 30 Tage):
--     bei ihm bleibt meine Freigabe bei "Nie" fuer immer, obwohl ich sie in jeder Antwort NICHT mehr nenne.
-- (3) Der Freigebende verlaesst die Gilde: seine Freigaben bleiben bei allen fuer immer und alarmieren weiter.
-- (fix-2) Belegtest der finalen Jagd, in die Suite uebernommen; Kopf: tests/beleg_helfer.lua
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local H = require("beleg_helfer")
local M = H.M
local G = "Die Testgilde"

H.lauf("(1) eigener Verfall 30 Tage: Freigabe bleibt bei den anderen, Abblasen geht nicht mehr", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", G)
  local z = W.client("Zeuge", "Still", G)
  a.login(); z.login(); W.run(40)
  a.ns.Store.Setting("guild.huntExpire", 30)
  a.ns.Guild.Release("Opfer-Lamm", { to = "guild", why = "Grund" })
  W.run(10)
  H.erwartet("Vorbedingung: Zeuge hat die Freigabe", z.ns.Guild.Hunt("Opfer-Lamm", "guild") ~= nil)
  H.tage(31)
  local a2 = H.relog(W, a); local z2 = H.relog(W, z)
  a2.login(); z2.login(); W.run(90)
  H.erwartet("Vorbedingung: bei mir ist sie verfallen", a2.ns.Guild.Hunt("Opfer-Lamm", "guild") == nil)
  local beimZeugen = z2.ns.Guild.Hunt("Opfer-Lamm", "guild") ~= nil
  local ok = a2.ns.Guild.CallOff("Opfer-Lamm")
  W.run(10)
  H.erwartet("was bei mir verfaellt, steht bei den anderen nicht ewig weiter (oder laesst sich von mir noch abblasen)",
    not beimZeugen or z2.ns.Guild.Hunt("Opfer-Lamm", "guild") == nil,
    "Zeuge behaelt die Freigabe, CallOff liefert " .. tostring(ok))
end)

H.lauf("(2) Abblasen verpasst, Merkfrist 30 Tage vorbei", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", G)
  local z = W.client("Zeuge", "Still", G)
  a.login(); z.login(); W.run(40)
  a.ns.Guild.Release("Opfer-Lamm", { to = "guild", why = "Grund" })
  W.run(10)
  H.erwartet("Vorbedingung: Zeuge hat die Freigabe", z.ns.Guild.Hunt("Opfer-Lamm", "guild") ~= nil)
  -- Zeuge geht fuer 40 Tage; am ersten Tag blaest Anton ab
  z.fire("PLAYER_LOGOUT"); local zdb = H.tiefe_kopie(z.env.DeathNoteDB)
  z.loggedIn = false
  for i = #W.clients, 1, -1 do if W.clients[i] == z then table.remove(W.clients, i) end end
  a.ns.Guild.CallOff("Opfer-Lamm"); W.run(10)
  H.tage(40)
  local a2 = H.relog(W, a)
  local z2 = W.client("Zeuge", "Still", G, { db = zdb })
  a2.login(); z2.login(); W.run(120)
  z2.ns.Guild.SyncNow(); W.run(120)
  H.erwartet("nach dem Abgleich steht die abgeblasene Freigabe beim Rueckkehrer nicht mehr",
    z2.ns.Guild.Hunt("Opfer-Lamm", "guild") == nil, "steht weiter, Freigebender kann sie nicht mehr zuruecknehmen")
end)

H.lauf("(3) Freigebender verlaesst die Gilde", function()
  local W = H.welt({ "GUILD_ENEMY_SPOTTED" })
  local a = W.client("Anton", "Wurst", G)
  local z = W.client("Zeuge", "Still", G)
  a.login(); z.login(); W.run(40)
  a.ns.Guild.Release("Opfer-Lamm", { to = "guild", why = "Grund" })
  W.run(10)
  a.guild = nil; a.fire("PLAYER_GUILD_UPDATE"); z.fire("GUILD_ROSTER_UPDATE"); W.run(10)
  H.tage(200)
  local z2 = H.relog(W, z); z2.login(); W.run(90)
  z2.fire("GUILD_ROSTER_UPDATE"); W.run(40)
  local h = z2.ns.Guild.Hunt("Opfer-Lamm", "guild")
  H.erwartet("200 Tage nach dem Austritt des Freigebenden steht seine Freigabe nicht mehr auf der Liste der Gilde",
    h == nil, h and ("steht noch, von " .. tostring(h.names[1])))
end)

H.fertig()
