-- Jagd Logik 150/06: Die Taste "Ziel ins Buch" (Grip.AddTarget) prueft nur "feindlich oder angreifbar". Ein
-- Duellpartner ist waehrend des Duells angreifbar, aber von der eigenen Fraktion (oft Gildenkollege oder Freund):
-- er landet als Hand-Eintrag "gesucht" im Buch (Alarm, Plakette, Zeigen). Die Rachsucht schliesst Duellpartner
-- ausdruecklich aus (Grudge duelFoe); die Taste nicht. Erwartet: eigene Fraktion ohne "UnitIsEnemy" = kein Feind,
-- klare Zeile, nichts eingetragen (wie beim Freund ohne Duell).
local DIR = ((arg and arg[1]) or "."):gsub("/+$", "")
arg[0] = DIR .. "/tests/jagd150.lua"
package.path = DIR .. "/tests/?.lua;" .. package.path
local M = require("mock_wow")
local test, eq, ok = M.test, M.eq, M.ok

test("JL150-06: Duellpartner der eigenen Fraktion kommt per Taste nicht ins Buch", function()
  local files = {}
  for _, f in ipairs(M.Files()) do files[#files + 1] = f end
  files[#files + 1] = "Grip.lua"
  local ns = M.Load({ files = files })
  _G.UnitInParty = function() return false end
  _G.UnitInRaid = function() return nil end
  _G.UIErrorsFrame = { AddMessage = function() end }
  M.FireEvent("DUEL_REQUESTED", "Duell")
  -- im Duell: angreifbar, aber kein Feind (UnitIsEnemy false), Fraktion wie ich
  M.AddEnemy("target", { name = "Duell", surname = "Partner", enemy = false, canAttack = true, faction = M.units.player.faction })
  M.FireEvent("PLAYER_TARGET_CHANGED")
  _G.DeathNote_Binding("ADD")
  local n = 0
  for _ in pairs(ns.Store.All()) do n = n + 1 end
  eq(n, 0, "Eintraege im Buch nach der Taste (letzte Zeile: " .. tostring(M.chat[#M.chat]) .. ")")
end)

M.done("jl150-06 duell")
