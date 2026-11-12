-- W1 (expiry can be set, default Never) against its purpose: calls nobody can take back any more.
-- (1) I set "30 days": my own call silently disappears for me after 30 days (no call-off goes
--     out). All others (default Never) keep it forever, and I can no longer call it off.
-- (2) I call off while a guildmate is away for more than 30 days (call-offs are remembered for 30 days):
--     with "Never" my call stays with him forever, although I NO longer name it in any answer.
-- (3) The caller leaves the guild: his calls stay with everyone forever and keep alerting.
-- (fix-2) Proof test of the final hunt, taken into the suite; head: tests/beleg_helfer.lua
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
  -- the witness leaves for 40 days; on the first day Anton calls off
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
