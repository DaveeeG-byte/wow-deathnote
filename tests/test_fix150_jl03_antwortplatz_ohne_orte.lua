-- Jagd Logik 150/03: Die Antwort auf ein Hallo bringt seit 1.5.0 bis zu 10 Nachrichten L mehr (C.PLACE_REPLY, direkt
-- nach den R). Die Freundes-Antwort wartet aber nur auf Platz fuer die alte Groesse (Friends.C.REPLY_ROOM = R + M + X +
-- J + A + B + 3, ohne L). Ist die Schlange gerade so voll, dass genau REPLY_ROOM frei ist, laufen die letzten Nachrichten
-- der Antwort (B-Kopfgelder, Y, Z) als "full" ins Leere. Erwartet: REPLY_ROOM rechnet PLACE_REPLY mit.
local DIR = ((arg and arg[1]) or "."):gsub("/+$", "")
arg[0] = DIR .. "/tests/jagd150.lua"
package.path = DIR .. "/tests/?.lua;" .. package.path
local M = require("mock_wow")
local test, eq, ok = M.test, M.eq, M.ok

test("JL150-03: Platz fuer eine ganze Antwort schliesst die Orte ein", function()
  local ns = M.Load()
  local C, FC = ns.Guild.C, ns.Friends.C
  ok(C.PLACE_REPLY and C.PLACE_REPLY > 0, "Antwort bringt Orte")
  local whole = C.REPLY_MAX + C.PLACE_REPLY + C.LISTED_REPLY + C.UNLISTED_REPLY + C.HUNT_REPLY + C.HUNTOFF_REPLY
    + C.BOUNTY_REPLY + 3
  ok(FC.REPLY_ROOM >= whole, ("REPLY_ROOM %d, groesste Antwort %d"):format(FC.REPLY_ROOM, whole))
end)

-- dieselbe Antwort wirklich gezaehlt: 30 eigene Tode mit Ort in den letzten Tagen -> 30 R und 10 L
test("JL150-03b: eine Antwort mit 30 Toden bringt 40 Nachrichten fuer die Tode", function()
  local ns = M.Load()
  local S = ns.Store
  local me = ns.Util.PlayerFullName()
  for i = 1, 30 do
    S.ApplyKill({ name = "Taeter", surname = "Nr" .. i, class = "MAGE" }, { t = time() - i * 600, zone = "Z", mapID = 1434,
      x = 40, y = 60, me = me, source = "recap" }, true)
  end
  local kinds = {}
  ns.Guild.Bridge.answer(ns.Guild.Bridge.gctx, 0, function(text, kind) kinds[kind] = (kinds[kind] or 0) + 1; return true end)
  eq(kinds.R, 30); eq(kinds.L, 10)
  local FC, C = ns.Friends.C, ns.Guild.C
  ok(FC.REPLY_ROOM - (C.LISTED_REPLY + C.UNLISTED_REPLY + C.HUNT_REPLY + C.HUNTOFF_REPLY + C.BOUNTY_REPLY + 3) >= kinds.R + kinds.L,
    "Platz fuer die Tode: " .. (FC.REPLY_ROOM - (C.LISTED_REPLY + C.UNLISTED_REPLY + C.HUNT_REPLY + C.HUNTOFF_REPLY + C.BOUNTY_REPLY + 3)))
end)

M.done("jl150-03 antwortplatz")
