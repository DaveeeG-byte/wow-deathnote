-- Jagd Logik 04: Store.AddAttack schneidet nach dem Einfuegen auf MAX_ENEMY_DEATHS (30) Taten und wirft dabei die
-- aelteste Tat weg, auch einen Kill. Kommentar (Store.lua "kills keep their room") und Baubericht ("Schutz fuer
-- Kills ueber die Obergrenze von 5 Angriffs-Taten") versprechen, dass Angriffe keine Kills verdraengen.
-- Erwartet: ein Eintrag mit 30 Kill-Taten behaelt nach einem Angriff alle 30 Kill-Taten (der Angriff weicht oder
-- wird nicht als Tat gespeichert, die Zahl e.attacks zaehlt trotzdem).
package.path = "./tests/?.lua;" .. package.path
local M = require("mock_wow")
local test, eq, ok = M.test, M.eq, M.ok

test("JL04: ein Angriff verdraengt keine Kill-Tat", function()
  local ns = M.Load()
  local S = ns.Store
  local t0 = time() - 100000
  for i = 1, 30 do
    S.ApplyKill({ name = "Grimm", surname = "Bart", guid = "Player-93-Grimm" }, { t = t0 + i * 100, zone = "Z", source = "recap" }, true)
  end
  local e = S.Get("Grimm-Bart")
  local function kills() local n = 0; for _, d in ipairs(e.deaths) do if d.role == "kill" then n = n + 1 end end; return n end
  eq(kills(), 30, "Vorbedingung")
  S.AddAttack({ name = "Grimm", surname = "Bart", guid = "Player-93-Grimm" }, { t = time(), zone = "Z", me = "Ich Selbst" })
  eq(e.attacks, 1)
  eq(kills(), 30, "Kill-Taten nach einem Angriff")
end)

M.done("jl04 kill-tat")
