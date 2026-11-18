-- Jagd Logik 150/09: Der Zauber-Merker castAt haengt am Einheiten-Token ("target", "focus", "mouseover"), nicht am
-- Spieler. Wechselt das Ziel, erbt der neue Spieler den Zauber des vorigen: castAt["target"] bleibt stehen
-- (geloescht wird nur bei NAME_PLATE_UNIT_REMOVED). Ein Spieler, der nie gezaubert hat, bekommt so das Signal s
-- und gilt als "sicher". Erwartet: castAt beim Zielwechsel (PLAYER_TARGET_CHANGED, UPDATE_MOUSEOVER_UNIT,
-- PLAYER_FOCUS_CHANGED) verwerfen oder nach GUID/Schluessel merken.
local DIR = ((arg and arg[1]) or "."):gsub("/+$", "")
arg[0] = DIR .. "/tests/jagd150.lua"
package.path = DIR .. "/tests/?.lua;" .. package.path
local M = require("mock_wow")
local test, eq, ok = M.test, M.eq, M.ok

test("JL150-09: kein Signal s aus dem Zauber des vorigen Ziels", function()
  local ns = M.Load()
  _G.UnitAffectingCombat = function(u) local x = M.units[u]; if not x then return false end; if x.combat == nil then return true end; return x.combat end
  _G.UnitInParty = function() return false end
  _G.UnitInRaid = function() return nil end
  _G.UnitThreatSituation = function() return nil end
  local G = ns.Grudge
  M.inCombat = true; M.FireEvent("PLAYER_REGEN_DISABLED")
  -- Ziel 1 zaubert (hat mich nicht im Ziel)
  M.AddEnemy("target", { name = "Magier", surname = "Eins", guid = "Player-93-M1", target = nil })
  M.FireEvent("PLAYER_TARGET_CHANGED")
  M.FireEvent("UNIT_SPELLCAST_START", "target")
  M.Advance(0.3)
  -- ich wechsle das Ziel auf einen Krieger, der mich schlaegt (zaubert nicht)
  M.AddEnemy("target", { name = "Krieger", surname = "Zwei", guid = "Player-93-K2", target = "player" })
  M.FireEvent("PLAYER_TARGET_CHANGED")
  M.FireEvent("UNIT_COMBAT", "player", "WOUND", "", 120, 1)
  M.Advance(0.5)
  local ep = G.Current()
  local row = ep and ep.rows["Krieger-Zwei"]
  ok(row, "Krieger erkannt")
  ok(row and not row.proofs.s, "Signal s ohne eigenen Zauber (Belege: " .. (function()
    local t = {}; for k in pairs(row and row.proofs or {}) do t[#t + 1] = k end; table.sort(t); return table.concat(t) end)() .. ")")
end)

M.done("jl150-09 fremder zauber")
