-- 1.6.4 move: the placing mode's counters (DeathNoteDB.probe.move, written by Place.lua: how often it ran, how it
-- ended, which piece was dragged) survive /dn probe, which builds DeathNoteDB.probe anew; numbers only, no names.
package.path = "./tests/?.lua;" .. package.path
local M = require("mock_wow")
local test, eq, ok = M.test, M.eq, M.ok

test("/dn probe behaelt probe.move", function()
  local ns = M.Load()
  local db = ns.Store.DB()
  db.probe = db.probe or {}
  db.probe.move = { counts = { start = 3, stop_esc = 1, drag_alert = 2 } }
  ns.Probe.Run(false)
  local p = ns.Store.DB().probe.move
  ok(type(p) == "table" and type(p.counts) == "table", "nach dem Sondenlauf da")
  eq(p.counts.start, 3); eq(p.counts.stop_esc, 1); eq(p.counts.drag_alert, 2)
  ns.Probe.Run(false)
  eq(ns.Store.DB().probe.move.counts.start, 3, "nicht doppelt, nicht verloren")
end)

test("ohne probe.move: der Sondenlauf legt keins an", function()
  local ns = M.Load()
  ns.Probe.Run(false)
  eq(ns.Store.DB().probe.move, nil)
end)

M.done("mv164_sonde")
