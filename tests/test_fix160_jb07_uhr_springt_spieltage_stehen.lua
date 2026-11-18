-- Copy of the bug hunter's test (fixer 2 1.6.0), red on b55addb.
-- Jagd 2 Fehler 07: Feud.CountDay zaehlt einen Spieltag nur, wenn der Kalendertag groesser ist als der gemerkte
-- (d.dayAt). Steht die Uhr des Rechners bei EINEM Login in der Zukunft (leere BIOS-Batterie, falsches Jahr, Zeitzone),
-- merkt sich das Buch diesen Tag; nach der Korrektur der Uhr zaehlt kein Login mehr, bis die echte Zeit den falschen
-- Tag ueberholt. So lange steht der Verfall (und alles, was Spieltage liest: Freunde "seit", Tage-Marken) still.
-- Hier: Uhr einmal 400 Tage voraus, dann 60 echte Spieltage: der Zaehler bleibt stehen, ein alter Verdacht verfaellt
-- nicht. Lauf: cd ~/Projects/wow-deathnote-jagd && luajit <diese Datei> .   (Exit 1 = Fund belegt)
local DIR = ((arg and arg[1]) or "."):gsub("/+$", "")
arg[0] = DIR .. "/tests/jagd2_bug_07.lua"
package.path = DIR .. "/tests/?.lua;" .. package.path
local M = require("mock_wow")
local test, ok, eq = M.test, M.ok, M.eq

test("JB07: ein Login mit der Uhr 400 Tage voraus, danach 60 Spieltage", function()
  local ns = M.Load()
  local S = ns.Store
  S.ApplyKill({ name = "Alt", surname = "Ling", guid = "Player-93-Alt" }, { t = time() - 50, zone = "Z" }, false)
  local d0 = S.DB().days
  M.epoch = M.epoch + 400 * 86400; S.Init()          -- die Uhr geht falsch
  M.epoch = M.epoch - 400 * 86400                    -- und wird gestellt
  local d1 = S.DB().days
  for _ = 1, 60 do M.epoch = M.epoch + 86400; S.Init() end
  local d2 = S.DB().days
  ok(d2 - d1 >= 59, "60 echte Spieltage zaehlen (Zaehler vorher " .. tostring(d0) .. ", nach dem Sprung " .. tostring(d1)
    .. ", nach 60 Tagen " .. tostring(d2) .. ")")
  ok(S.Get("Alt-Ling") == nil, "der alte Verdacht ist nach 60 Spieltagen abgelegt")
end)
M.done("jb07 uhr springt")
