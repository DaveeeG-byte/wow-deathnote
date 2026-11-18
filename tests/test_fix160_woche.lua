-- Fixer 1.6.0 (UI hunt, low findings 9 and 10): the week's card names seven calendar days; a quiet week (no death,
-- nothing avenged) is not posted; a count of 0 is no segment of the chat line. Names made up.
local DIR = ((arg and arg[1]) or "."):gsub("/+$", "")
arg[0] = DIR .. "/tests/fix160_woche.lua"
package.path = DIR .. "/tests/?.lua;" .. package.path
local M = require("mock_wow")
local test, ok, eq = M.test, M.ok, M.eq

test("Woche: sieben Kalendertage, ruhige Woche geht nicht hinaus, keine 0-Segmente", function()
  local files = {}
  for _, f in ipairs(M.Files()) do files[#files + 1] = f end
  files[#files + 1] = "Share.lua"   -- the way of a visible line (not in the logic mock's default list)
  local ns = M.Load({ files = files })
  M.units.player.guild = "Die Testgilde"
  local GL = ns.GuildLog
  local w = GL.Week()
  local c = GL.CardTexts(w)
  local D = ns.Chronicle.Day
  eq(c.week, ns.F(ns.L.GLOG_CARD_WEEK, { from = D(w.to - 6 * 86400), to = D(w.to) }), "sieben Tage")
  ok(GL.QuietWeek(w), "ruhige Woche")
  local sent = 0
  _G.SendChatMessage = function() sent = sent + 1 end
  local okp, why = GL.PostWeek()
  ok(not okp and why == "empty", tostring(why))
  eq(sent, 0, "nichts gesendet")
  local line = GL.WeekLine() or ""
  ok(not line:find(ns.F(ns.L.GLOG_CARD_AVENGED, { count = 0 }), 1, true), "kein 0 geraecht: " .. line)
  ok(not line:find(ns.F(ns.L.GLOG_CARD_DEATHS, { count = 0 }), 1, true), "keine 0 Tode: " .. line)
end)

M.done("fix160 woche")
