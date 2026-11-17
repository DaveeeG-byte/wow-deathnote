-- Jagd Logik 03: ein echter Angriff, waehrend die Probe-Meldung (/dn rachsucht test) noch steht, landet in der
-- Probe-Episode (ep.test). Der Haken traegt dann nichts ein (Grudge.Answer prueft `not e.test`), und wer nicht
-- beantwortet wird, ist 5 Minuten lang still (asked).
-- Erwartet: ein echter Angreifer beginnt eine echte Episode (die Probe-Meldung weicht), und sein Haken traegt ein.
package.path = "./tests/?.lua;" .. package.path
local M = require("mock_wow")
local test, eq, ok = M.test, M.eq, M.ok

local function load()
  local ns = M.Load()
  _G.UnitAffectingCombat = function(u) local x = M.units[u]; if not x then return false end
    if x.combat == nil then return true end; return x.combat end
  M.hp = 1000
  _G.UnitHealth = function(u) if u == "player" then return M.hp end end
  _G.UnitInParty = function(u) local x = M.units[u]; return x and x.party or false end
  _G.UnitInRaid = function() return nil end
  return ns
end

test("JL03: echter Angriff waehrend der Probe-Meldung wird eingetragen, wenn man den Haken setzt", function()
  local ns = load()
  ns.Grudge.Test()
  M.Advance(3)
  M.inCombat = true; M.FireEvent("PLAYER_REGEN_DISABLED")
  M.AddEnemy("nameplate1", { name = "Grimm", surname = "Bart", guid = "Player-93-Grimm", target = "player" })
  M.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate1")
  M.FireEvent("UNIT_COMBAT", "player", "WOUND", "", 120, 1)
  local ep = ns.Grudge.Current()
  ok(ep and ep.rows["Grimm-Bart"], "Vorbedingung: Angreifer erkannt")
  ok(not ep.test, "der echte Angreifer steht in einer echten Episode, nicht in der Probe")
  ns.Grudge.Answer("Grimm-Bart", true)
  ok(ns.Store.Get("Grimm-Bart"), "Haken traegt ein")
end)

M.done("jl03 probe schluckt")
