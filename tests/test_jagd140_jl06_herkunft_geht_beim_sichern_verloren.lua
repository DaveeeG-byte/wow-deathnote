-- Jagd Logik 06: "Buch sichern" (Store.Export) schreibt die Herkunft eines uebernommenen Eintrags nicht mit
-- (fromGuild, adoptFrom, adoptSrc, fromGuildKills). Nach "Buch einlesen" des eigenen Textes (Wiederherstellen) steht
-- der Eintrag als "von Hand" (manual=1) und "eingelesen" da; Notiz und Zeile sagen nicht mehr "uebernommen von Wendell".
-- CHANGELOG 1.4.0: "Taken-over entries keep where they came from and from whom".
-- Erwartet: nach Sichern und Wiederherstellen in ein leeres Buch nennt der Eintrag weiter seine Herkunft (adoptFrom).
package.path = "./tests/?.lua;" .. package.path
local M = require("mock_wow")
local test, eq, ok = M.test, M.eq, M.ok

test("JL06: Herkunft eines uebernommenen Eintrags uebersteht Sichern und Einlesen", function()
  local ns = M.Load()
  ns.Store.AddManual("Grimm", "Bart", { fromGuild = true, adopt = { from = "Wendell Probe", src = "friends", kills = 2 } })
  local text = ns.Store.Export()
  local ns2 = M.Load()
  local okI = ns2.Store.Import(text)
  ok(okI)
  local e = ns2.Store.Get("Grimm-Bart")
  ok(e, "Eintrag da")
  eq(e.adoptFrom, "Wendell Probe", "Herkunft nach dem Wiederherstellen")
end)

M.done("jl06 herkunft")
