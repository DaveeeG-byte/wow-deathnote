-- Counter-check finding 7 ("a guildmate is whoever is in the roster or was heard on GUILD in the last 5 minutes").
-- (1) Friend "Berta" is on the friend list without surname and NOT in my guild. There is another Berta
--     in the guild. The roster gives (as in the mock) first names only: the friend counts as a guildmate for good,
--     gets no hello and no data, her whisper is dropped as "guildmate".
-- (2) The same with the full name on the list: blocked while the other Berta was heard on GUILD in the last
--     5 minutes (she can keep that up for good with a hello every few minutes).
-- (fix-2) Proof test of the final hunt, taken into the suite; head: tests/beleg_helfer.lua
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local H = require("beleg_helfer")
local M = H.M
local G = "Die Testgilde"

local function lauf(listenname, absenderVoll)
  local W = H.welt()
  local f = W.client("Berta", "Senf", nil, { friends = { "Anton Wurst" }, fullSender = absenderVoll })   -- the friend, without guild
  local a = W.client("Anton", "Wurst", G, { friends = { listenname } })
  local o = W.client("Berta", "Anders", G)                                                              -- another Berta, guild
  a.login(); f.login(); o.login(); W.run(90)
  local key = H.tod(f, "Grimm", "Bart")
  for _ = 1, 4 do
    W.run(200)
    o.ns.Guild.SyncNow()      -- the other Berta can be heard on GUILD every few minutes
    f.ns.Friends.SyncNow(); a.ns.Friends.SyncNow()
  end
  W.run(60)
  return a.ns.Guild.Get(key, "friends") ~= nil, a.whispers or 0, a.ns.Friends.stats.mates
end

H.lauf("(1) Liste ohne Nachnamen, Namensvetterin in der Gilde", function()
  local got, whispers, mates = lauf("Berta", false)
  H.erwartet("die Freundin bekommt ein Hallo per Fluestern", whispers > 0, "kein einziges Fluestern in 15 Minuten")
  H.erwartet("die Tat der Freundin kommt an", got, "fehlt; als Kollegin verworfen: " .. tostring(mates))
end)
H.lauf("(2) Liste mit vollem Namen, Namensvetterin meldet sich alle paar Minuten auf GUILD", function()
  local got, whispers, mates = lauf("Berta Senf", true)
  H.erwartet("die Tat der Freundin kommt an", got, "fehlt; Fluestern gesendet " .. whispers .. ", als Kollegin verworfen: " .. tostring(mates))
end)

H.fertig()
