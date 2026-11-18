-- Fixer 2 1.6.0 (jb07): a remembered last play day in the future (one login with the clock far ahead) is set back to
-- today without counting; the play days count on from the next day. The same day twice still counts once; a clock
-- that goes back and forth by one day counts nothing twice (one day ahead is let be). Names made up.
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local M = require("mock_wow")
local test, eq = M.test, M.eq

test("Tag in der Zukunft: auf heute, dann zählt jeder Tag", function()
  local ns = M.Load()
  local S, d = ns.Store, ns.Store.DB()
  local d0 = d.days
  M.epoch = M.epoch + 400 * 86400; S.Init()
  eq(d.days, d0 + 1, "der Sprung zählt einmal")
  M.epoch = M.epoch - 400 * 86400; S.Init()
  eq(d.days, d0 + 1, "zurückgestellt: kein Tag")
  eq(d.dayAt, math.floor(time() / 86400), "der gemerkte Tag ist heute")
  S.Init()
  eq(d.days, d0 + 1, "derselbe Tag nochmal: nichts")
  M.epoch = M.epoch + 86400; S.Init()
  eq(d.days, d0 + 2, "der nächste Tag zählt")
  eq(d.friends and d.friends.days, d.days, "das Freundesbuch liest denselben Zähler")
  -- back and forth by one day: no day twice
  local d1 = d.days
  M.epoch = M.epoch - 86400; S.Init()
  M.epoch = M.epoch + 86400; S.Init()
  eq(d.days, d1, "ein Tag hin und her: nichts doppelt")
end)
M.done("fix160 jb07 Tag in der Zukunft")
