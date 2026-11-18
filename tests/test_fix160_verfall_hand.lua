-- Fixer 1.6.0 (jl06, counter-check): only what the player did by hand keeps a suspicion from expiring. A note of blanks
-- is no note; the automatic standings (a suspicion, an attack making him wanted) never count as by hand; a broken mark
-- is repaired at loading. Names made up.
local DIR = ((arg and arg[1]) or "."):gsub("/+$", "")
arg[0] = DIR .. "/tests/fix160_verfall_hand.lua"
package.path = DIR .. "/tests/?.lua;" .. package.path
local M = require("mock_wow")
local test, ok, eq = M.test, M.ok, M.eq

local function suspect(S, name)
  return S.ApplyKill({ name = name, surname = "Ling", guid = "Player-93-" .. name }, { t = time() - 50, zone = "Z" }, false)
end

test("Notiz nur aus Leerzeichen haelt nichts", function()
  local ns = M.Load()
  local S = ns.Store
  suspect(S, "Leer")
  S.SetNote("Leer-Ling", "   ")
  for _ = 1, 31 do M.epoch = M.epoch + 86400; S.Init() end
  ok(S.Get("Leer-Ling") == nil, "abgelegt")
end)

test("automatischer Stand setzt keine Hand-Marke", function()
  local ns = M.Load()
  local S = ns.Store
  suspect(S, "Auto")
  local e = S.Get("Auto-Ling")
  eq(e.status, "suspect")
  ok(e.statusHand == nil, "keine Marke nach dem Verdacht")
  ok(ns.Feud.MayKeep(e), "darf verfallen")
  S.SetStatus("Auto-Ling", "pardoned")
  ok(e.statusHand == true, "Marke nach dem Stand von Hand")
  ok(not ns.Feud.MayKeep(e), "verfaellt nicht mehr")
end)

test("kaputte Marke wird beim Laden repariert", function()
  local ns = M.Load()
  local e = { statusHand = "ja" }
  ns.Feud.SanitizeEntry(e)
  ok(e.statusHand == nil, "weg")
  e.statusHand = true
  ns.Feud.SanitizeEntry(e)
  ok(e.statusHand == true, "bleibt")
end)

M.done("fix160 verfall hand")
