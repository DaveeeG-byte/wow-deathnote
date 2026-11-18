-- Jagd Logik 150/07: Ein Tod ohne sicheren Todesstoss (Journal sure = false: der Verdaechtige ist nur der, der mich
-- zuletzt im Ziel hatte, Attribution "suspect") bekommt auf der Karte die Kopfzeile "Hier hat <Name> dich getoetet",
-- genau wie ein sicherer Todesstoss. Scene.All nimmt killerKey ohne j.sure zu pruefen, Scene.Head kennt nur "Name da"
-- oder "unklar". Das Buch nennt so einen Tod Verdacht; die Karte behauptet die Tat. Erwartet: ohne sure die unklare
-- Kopfzeile (oder eine eigene "vermutlich"-Zeile), nie "hat dich getoetet".
local DIR = ((arg and arg[1]) or "."):gsub("/+$", "")
arg[0] = DIR .. "/tests/jagd150.lua"
package.path = DIR .. "/tests/?.lua;" .. package.path
local M = require("mock_wow")
local test, eq, ok, no = M.test, M.eq, M.ok, M.no

test("JL150-07: Verdacht ist auf der Karte kein Toeter", function()
  local ns = M.Load()
  local S, Sc, L = ns.Store, ns.Scene, ns.L
  local t = time() - 300
  local key = S.ApplyKill({ name = "Ver", surname = "Dacht", class = "ROGUE" }, { t = t, zone = "Z", mapID = 1434, x = 40, y = 30,
    source = "suspect" }, false)
  S.RecordDeath({ t = t, zone = "Z", mapID = 1434, x = 40, y = 30, kind = "pvp", sure = false, counted = true, source = "suspect",
    killerKey = key, killerName = "Ver Dacht", candidates = { key } })
  eq(S.Get(key).status, "suspect", "im Buch nur Verdacht")
  local pins = Sc.Pins(1434, time())
  eq(#pins, 1)
  local head = Sc.Head(pins[1].lead)
  local claim = ns.F(L.SCENE_TIP_DEATH, { killer = "" })
  no(head:find(claim:sub(1, 8), 1, true) and head:find("Ver Dacht", 1, true), "Kopfzeile: " .. head)
end)

M.done("jl150-07 verdacht")
