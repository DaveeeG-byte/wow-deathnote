-- 1.4.0 fixer (hunt logic 4): an attack never pushes out a kill or an assist deed; old attacks go first, also when a
-- kill comes to a full list and when a text brings attacks (at most 5 attack deeds). All names are made up.
package.path = "./tests/?.lua;" .. package.path
local M = require("mock_wow")
local test, eq = M.test, M.eq

local function count(e, role) local n = 0; for _, d in ipairs(e.deaths) do if d.role == role then n = n + 1 end end; return n end
local G = { name = "Grimm", surname = "Bart", guid = "Player-93-Grimm" }

test("Kill auf voller Liste mit Angriffen: ein alter Angriff weicht, kein Kill", function()
  local ns = M.Load()
  local S = ns.Store
  local t0 = time() - 100000
  for i = 1, 3 do S.AddAttack(G, { t = t0 - 5000 + i, zone = "Z", me = "Ich Selbst" }) end
  for i = 1, 27 do S.ApplyKill(G, { t = t0 + i * 100, zone = "Z", source = "recap" }, true) end
  local e = S.Get("Grimm-Bart")
  eq(#e.deaths, 30); eq(count(e, "attack"), 3)
  S.ApplyKill(G, { t = time(), zone = "Z", source = "recap" }, true)
  eq(#e.deaths, 30); eq(count(e, "kill"), 28); eq(count(e, "attack"), 2)
  S.ApplyKill({ name = "Grimm", surname = "Bart", guid = "Player-93-Grimm" }, { t = time() + 1, zone = "Z", source = "recap", role = "assist" }, false)
  eq(count(e, "kill"), 28, "ein Beteiligt verdraengt keinen Kill, solange Angriffe da sind"); eq(count(e, "attack"), 1)
  eq(e.attacks, 3, "die Zahl der Angriffe zaehlt weiter")
end)

test("Einlesen: hoechstens 5 Angriffs-Taten, Kills bleiben", function()
  local ns = M.Load()
  local S = ns.Store
  local t0 = time() - 100000
  for i = 1, 28 do S.ApplyKill(G, { t = t0 + i * 100, zone = "Z", source = "recap" }, true) end
  local lines = { "DEATHNOTE:1" }
  lines[#lines + 1] = table.concat({ "E", "Grimm-Bart", "wanted", "0", "28", "0", "0", "", "", "", "0", "ROGUE", "", "40", "", "",
    "Bart", "Player-93-Grimm", "", "0", "8" }, "|")
  for i = 1, 8 do
    -- D|key|t|sure|source|zone|subzone|mapID|x|y|me|myLevel|spell|role
    lines[#lines + 1] = table.concat({ "D", "Grimm-Bart", tostring(t0 + 50000 + i), "0", "grudge", "Z", "", "", "", "", "Ich Selbst", "40", "", "attack" }, "|")
  end
  local ok = S.Import(table.concat(lines, "\n"))
  eq(ok, true)
  local e = S.Get("Grimm-Bart")
  eq(count(e, "kill"), 28); eq(count(e, "attack"), 2, "nur Platz bis 30, alte Angriffe zuerst raus")
  eq(e.attacks, 8)
end)

test("Einlesen: 8 Angriffs-Taten bei kurzer Liste werden 5", function()
  local ns = M.Load()
  local S = ns.Store
  local t0 = time() - 100000
  local lines = { "DEATHNOTE:1", table.concat({ "E", "Grimm-Bart", "wanted", "0", "0", "0", "0", "", "", "", "0", "ROGUE", "", "40",
    "", "", "Bart", "Player-93-Grimm", "", "0", "8" }, "|") }
  for i = 1, 8 do
    lines[#lines + 1] = table.concat({ "D", "Grimm-Bart", tostring(t0 + i), "0", "grudge", "Z", "", "", "", "", "Ich Selbst", "40", "", "attack" }, "|")
  end
  S.Import(table.concat(lines, "\n"))
  local e = S.Get("Grimm-Bart")
  eq(count(e, "attack"), 5); eq(e.attacks, 8)
  eq(e.deaths[5].t, t0 + 4, "die neuesten bleiben")
end)

M.done("fix140 deckel")
