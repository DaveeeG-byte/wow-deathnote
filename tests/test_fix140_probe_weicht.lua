-- 1.4.0 fixer (hunt logic 3): the test notice (/dn rachsucht test) gives way at once to a real attack or a real death;
-- the real attackers get a real episode (a tick writes), and the made-up names of the test are not "asked lately".
package.path = "./tests/?.lua;" .. package.path
local M = require("mock_wow")
local test, eq, ok, no = M.test, M.eq, M.ok, M.no

local function load()
  local ns = M.Load()
  _G.UnitAffectingCombat = function() return true end
  _G.UnitHealth = function() return 1000 end
  _G.UnitInParty = function() return false end
  _G.UnitInRaid = function() return nil end
  return ns
end

test("Tod waehrend der Probe-Meldung: die Probe weicht, die Todes-Episode ist echt", function()
  local ns = load()
  local t = ns.Grudge.Test()
  M.recap = { id = 7, events = {
    { sourceGUID = "Player-93-Fies", sourceName = "Fies Ling", amount = 900, overkill = 50, timestamp = time() - 1, spellName = "Hieb" },
    { sourceGUID = "Player-93-Grimm", sourceName = "Grimm Bart", amount = 300, overkill = -1, timestamp = time() - 2, spellName = "Hieb" } } }
  local seen
  ns:On("GRUDGE_UPDATE", function(e) if e and not e.test then seen = e end end)
  M.FireEvent("PLAYER_DEAD")
  eq(t.closed, true, "Probe geschlossen")
  M.Advance(5)
  ok(seen, "echte Episode")
  ok(seen and seen.rows["Fies-Ling"] and not seen.test)
end)

test("Probe weicht: ihre erfundenen Namen gelten nicht als beantwortet", function()
  local ns = load()
  ns.Grudge.Test()
  M.inCombat = true; M.FireEvent("PLAYER_REGEN_DISABLED")
  M.AddEnemy("nameplate1", { name = "Dornfels", surname = "Probe", guid = "Player-93-Dorn", target = "player" })
  M.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate1")
  M.FireEvent("UNIT_COMBAT", "player", "WOUND", "", 120, 1)
  local ep = ns.Grudge.Current()
  ok(ep and not ep.test and ns.Grudge.Open(ep.rows["Dornfels-Probe"]), "gefragt")
  eq(ns.Grudge.ProbeSnapshot().counts.expired, 0)
end)

M.done("fix140 probe weicht")
