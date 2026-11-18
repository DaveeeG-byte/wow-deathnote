-- Jagd Logik 150/08: Die Kreatur-Marke einer Zeile (row.mob) ist klebrig und senkt die Sicherheit auch NACHTRAEGLICH.
-- Ein Spieler greift mich an (Treffer, Ziel auf mir, im Kampf: "wahrscheinlich", steht auf der Meldung). Danach zieht
-- eine Kreatur Aggro und beim naechsten Treffer wird die schon gezeigte Zeile "zurueckgehalten": sie verschwindet von
-- der Meldung, die Episode fragt nichts mehr und schliesst nach dem Kampf mit "none". In 1.4.0 blieb er stehen.
-- Erwartet: was einmal gezeigt wurde, faellt nicht mehr unter "wahrscheinlich" (die Kreatur kann nur einen neuen
-- Beleg entwerten, nicht einen schon gezeigten).
local DIR = ((arg and arg[1]) or "."):gsub("/+$", "")
arg[0] = DIR .. "/tests/jagd150.lua"
package.path = DIR .. "/tests/?.lua;" .. package.path
local M = require("mock_wow")
local test, eq, ok = M.test, M.eq, M.ok

test("JL150-08: eine gezeigte Zeile verschwindet nicht, weil spaeter ein Wolf dazukommt", function()
  local ns = M.Load()
  _G.UnitAffectingCombat = function(u) local x = M.units[u]; if not x then return false end; if x.combat == nil then return true end; return x.combat end
  M.hp = 1000
  _G.UnitHealth = function(u) if u == "player" then return M.hp end end
  _G.UnitInParty = function() return false end
  _G.UnitInRaid = function() return nil end
  _G.UnitThreatSituation = function(_, u) local x = M.units[u]; return x and x.threat end
  local G = ns.Grudge
  M.inCombat = true; M.FireEvent("PLAYER_REGEN_DISABLED")
  M.AddEnemy("nameplate1", { name = "Grimm", surname = "Bart", guid = "Player-93-Grimm", target = "player" })
  M.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate1")
  M.FireEvent("UNIT_COMBAT", "player", "WOUND", "", 120, 1)
  M.Advance(0.5)
  eq(#G.Rows(), 1, "nach dem ersten Treffer gezeigt")
  local before = G.Rows()[1].conf
  -- ein Wolf zieht Aggro
  M.AddEnemy("nameplate2", { isPlayer = false, name = "Wolf", guid = "Creature-0-1-2-3-9", target = "player", threat = 3 })
  M.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate2")
  M.Advance(0.6)
  M.FireEvent("UNIT_COMBAT", "player", "WOUND", "", 80, 1)
  M.Advance(0.5)
  eq(#G.Rows(), 1, "nach dem zweiten Treffer noch gezeigt (vorher " .. tostring(before) .. ", jetzt "
    .. tostring(G.Current() and G.Current().rows["Grimm-Bart"] and G.Current().rows["Grimm-Bart"].conf) .. ")")
end)

M.done("jl150-08 herabgestuft")
