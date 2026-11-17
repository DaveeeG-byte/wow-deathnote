-- 1.4.0 fixer (hunt logic 7): probe.grudge counts the open questions of the build on their own: UNIT_COMBAT on me
-- arrived, my health readable or secret, "in combat" of an enemy readable or secret, "has me targeted" plain or secret,
-- the enemy's name secret. Without them "proofs a 0" cannot tell "nobody had me targeted" from "the target was secret".
package.path = "./tests/?.lua;" .. package.path
local M = require("mock_wow")
local test, eq, ok = M.test, M.eq, M.ok

local function load()
  local ns = M.Load()
  _G.UnitInParty = function() return false end
  _G.UnitInRaid = function() return nil end
  M.inCombat = true; M.FireEvent("PLAYER_REGEN_DISABLED")
  return ns
end
local function c(ns) return ns.Grudge.ProbeSnapshot().counts end

test("Sonde: lesbare Werte", function()
  local ns = load()
  _G.UnitAffectingCombat = function() return true end
  local hp = 1000
  _G.UnitHealth = function() return hp end
  M.AddEnemy("nameplate1", { name = "Grimm", surname = "Bart", guid = "Player-93-Grimm", target = "player" })
  M.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate1")
  M.FireEvent("UNIT_COMBAT", "player", "WOUND", "", 120, 1)
  hp = 900; M.FireEvent("UNIT_HEALTH", "player")
  local n = c(ns)
  ok(n.unitCombat >= 1, "UNIT_COMBAT kam"); ok(n.healthOk >= 1, "Leben lesbar"); eq(n.healthSecret, 0)
  ok(n.combatOk >= 1, "im Kampf lesbar"); eq(n.combatSecret, 0)
  ok(n.targetMe >= 1, "hat mich im Ziel"); eq(n.targetSecret, 0); eq(n.nameSecret, 0)
end)

test("Sonde: secret Werte", function()
  local ns = load()
  _G.UnitAffectingCombat = function() return M.Secret("UnitAffectingCombat", "boolean") end
  _G.UnitHealth = function() return M.Secret("UnitHealth", "number") end
  M.AddEnemy("nameplate1", { name = "Grimm", surname = "Bart", guid = "Player-93-Grimm", target = "player" })
  M.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate1")
  M.FireEvent("UNIT_HEALTH", "player")
  M.FireEvent("UNIT_COMBAT", "player", "WOUND", "", 120, 1)
  local n = c(ns)
  ok(n.healthSecret >= 1, "Leben secret"); ok(n.combatSecret >= 1, "im Kampf secret")
  M.AddEnemy("nameplate2", { name = "Dorn", surname = "Fels", guid = "Player-93-Dorn", target = "player", targetsMeSecret = true })
  M.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate2")
  M.Advance(1)
  M.FireEvent("UNIT_COMBAT", "player", "WOUND", "", 120, 1)
  ok(c(ns).targetSecret >= 1, "Ziel secret")
  local old = _G.UnitName
  _G.UnitName = function(u) if u == "nameplate1" then return M.Secret("UnitName") end return old(u) end
  M.Advance(1)
  M.FireEvent("UNIT_COMBAT", "player", "WOUND", "", 120, 1)
  ok(c(ns).nameSecret >= 1, "Name secret")
  _G.UnitName = old
end)

M.done("fix140 sonde")
