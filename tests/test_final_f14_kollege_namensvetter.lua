-- Gegenprobe Fund 7 ("Kollege ist, wer im Roster steht bzw. in den letzten 5 Minuten auf GUILD zu hoeren war").
-- (1) Freundin "Berta" steht ohne Nachnamen auf der Freundesliste und ist NICHT in meiner Gilde. In der Gilde gibt es
--     eine andere Berta. Der Roster nennt (wie im Mock) nur Vornamen: die Freundin gilt dauerhaft als Kollegin,
--     bekommt kein Hallo und keine Daten, ihr Fluestern wird als "Kollegin" verworfen.
-- (2) Dasselbe mit vollem Namen auf der Liste: gesperrt, solange die andere Berta in den letzten 5 Minuten auf GUILD
--     zu hoeren war (sie kann das mit einem Hallo alle paar Minuten dauerhaft halten).
-- (fix-2) Belegtest der finalen Jagd, in die Suite uebernommen; Kopf: tests/beleg_helfer.lua
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local H = require("beleg_helfer")
local M = H.M
local G = "Die Testgilde"

local function lauf(listenname, absenderVoll)
  local W = H.welt()
  local f = W.client("Berta", "Senf", nil, { friends = { "Anton Wurst" }, fullSender = absenderVoll })   -- die Freundin, ohne Gilde
  local a = W.client("Anton", "Wurst", G, { friends = { listenname } })
  local o = W.client("Berta", "Anders", G)                                                              -- andere Berta, Gilde
  a.login(); f.login(); o.login(); W.run(90)
  local key = H.tod(f, "Grimm", "Bart")
  for _ = 1, 4 do
    W.run(200)
    o.ns.Guild.SyncNow()      -- die andere Berta ist alle paar Minuten auf GUILD zu hoeren
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
