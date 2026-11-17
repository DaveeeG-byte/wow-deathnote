-- Jagd Logik 07: die Sonde probe.grudge sagt nicht, ob "hat mich im Ziel" (UnitIsUnit(<einheit>target, "player"))
-- im Spiel secret ist. Der Baubericht nennt genau das als offene Messfrage ("sonst findet a niemanden"), die Regel
-- verlangt "alles Ungemessene in die Sonde". Heute faellt ein secret Ziel still durch (True(secret) = false), die
-- Sonde zeigt dann nur "hits n, proofs a 0" und man kann "keiner hatte mich im Ziel" nicht von "Ziel secret"
-- unterscheiden.
-- Erwartet: nach einem Treffer mit einem Feind, dessen Ziel secret ist, steht in Grudge.ProbeSnapshot().counts ein
-- Zaehler > 0 fuer secret Ziel (Name des Zaehlers frei; der Test sucht einen Schluessel mit "secret" oder "Secret"
-- ausser meterSecret).
package.path = "./tests/?.lua;" .. package.path
local M = require("mock_wow")
local test, ok = M.test, M.ok

test("JL07: secret Ziel wird in probe.grudge gezaehlt", function()
  local ns = M.Load()
  _G.UnitAffectingCombat = function() return true end
  _G.UnitHealth = function() return 1000 end
  _G.UnitInParty = function() return false end
  _G.UnitInRaid = function() return nil end
  M.inCombat = true; M.FireEvent("PLAYER_REGEN_DISABLED")
  M.AddEnemy("nameplate1", { name = "Grimm", surname = "Bart", guid = "Player-93-Grimm", target = "player", targetsMeSecret = true })
  M.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate1")
  M.FireEvent("UNIT_COMBAT", "player", "WOUND", "", 120, 1)
  local c = ns.Grudge.ProbeSnapshot().counts
  local n = 0
  for k, v in pairs(c) do if k ~= "meterSecret" and k:lower():find("secret") and v > 0 then n = n + 1 end end
  ok(n > 0, "ein Zaehler fuer secret Ziel")
end)

M.done("jl07 sonde")
