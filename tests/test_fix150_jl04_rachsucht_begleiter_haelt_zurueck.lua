-- Jagd Logik 150/04: Die Gegenprobe "Kreatur" (mobOnMe) nimmt jede angreifbare Nicht-Spieler-Einheit, die mich im Ziel
-- hat oder auf ihrer Bedrohungsliste fuehrt. Das ist auch der Begleiter des Angreifers selbst (Jaegertier,
-- Wichtel/Leerwandler, Wasserelementar): ein Jaeger, der mit Tier und Autoschuss angreift, ist dann "a allein + Kreatur"
-- = zurueckgehalten, die Meldung zeigt niemanden. Das Signal r ist mit Kreatur unmoeglich, j nur beim Einstieg; ohne
-- erkannten Zauber (s) bleibt er unsichtbar. In 1.4.0 erschien er (a). Erwartet: der Begleiter eines Spielers zaehlt
-- nicht als Kreatur (UnitPlayerControlled / Besitzer), der Angreifer erscheint mindestens als "wahrscheinlich".
local DIR = ((arg and arg[1]) or "."):gsub("/+$", "")
arg[0] = DIR .. "/tests/jagd150.lua"
package.path = DIR .. "/tests/?.lua;" .. package.path
local M = require("mock_wow")
local test, eq, ok = M.test, M.eq, M.ok

local function load()
  local ns = M.Load()
  _G.UnitAffectingCombat = function(u)
    local x = M.units[u]
    if not x then return false end
    if x.combat == nil then return true end
    return x.combat
  end
  M.hp = 1000
  _G.UnitHealth = function(u) if u == "player" then return M.hp end end
  _G.UnitInParty = function(u) local x = M.units[u]; return x and x.party or false end
  _G.UnitInRaid = function() return nil end
  _G.UnitThreatSituation = function(_, u) local x = M.units[u]; return x and x.threat end
  _G.UnitPlayerControlled = function(u) local x = M.units[u]; return x and (x.isPlayer or x.controlled) or false end
  return ns
end

test("JL150-04: Jaeger mit Tier greift an: er steht auf der Meldung", function()
  local ns = load()
  local G = ns.Grudge
  M.inCombat = true; M.FireEvent("PLAYER_REGEN_DISABLED")
  -- der Jaeger hat mich im Ziel und ist im Kampf
  M.AddEnemy("nameplate1", { name = "Jaeg", surname = "Ling", guid = "Player-93-Jaeg", class = "HUNTER", target = "player" })
  M.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate1")
  -- sein Tier (Begleiter, von einem Spieler gesteuert) beisst mich
  M.AddEnemy("nameplate2", { isPlayer = false, controlled = true, name = "Wolf", guid = "Pet-0-1-2-3-4", target = "player", threat = 3 })
  M.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate2")
  for i = 1, 4 do
    M.FireEvent("UNIT_COMBAT", "player", "WOUND", "", 120, 1)
    M.Advance(1.2)
  end
  local ep = G.Current()
  ok(ep, "eine Episode laeuft")
  local row = ep and ep.rows["Jaeg-Ling"]
  ok(row, "der Jaeger ist erkannt")
  ok(row and row.conf ~= "held", "Sicherheit des Jaegers: " .. tostring(row and row.conf))
  ok(#G.Rows() >= 1, "die Meldung zeigt ihn")
end)

M.done("jl150-04 begleiter")
