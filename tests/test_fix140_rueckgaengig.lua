-- 1.4.0 fixer (hunt logic 2): "Undo" after "Import book" never costs own data. What came after the import (a kill,
-- a death, an attack, a note, a pardon) stays; only what the import added is taken back, and an entry that cannot be
-- taken back cleanly stays as it is and is counted as kept. All names are made up.
package.path = "./tests/?.lua;" .. package.path
local M = require("mock_wow")
local test, eq, ok, no = M.test, M.eq, M.ok, M.no

local function E(key, kills, surname, guid, status)
  return table.concat({ "E", key, status or "wanted", "0", tostring(kills), "0", "0", "", "", "", "0", "ROGUE", "", "40", "",
    "", surname, guid, "", "0", "0" }, "|")
end
local function text(...) return "DEATHNOTE:1\n" .. table.concat({ ... }, "\n") end

test("Einlesen: Notiz, Begnadigung, Angriff an neuen Eintraegen bleiben; Unberuehrtes geht", function()
  local ns = M.Load()
  local S = ns.Store
  local okI, a = S.Import(text(E("Grimm-Bart", 2, "Bart", "Player-93-G"), E("Fies-Ling", 1, "Ling", "Player-93-F"),
    E("Dorn-Fels", 1, "Fels", "Player-93-D"), E("Rabe-Ruf", 1, "Ruf", "Player-93-R")))
  ok(okI); eq(a, 4)
  M.Advance(30)
  S.SetNote("Grimm-Bart", "der mit dem Hut")
  S.SetStatus("Fies-Ling", "pardoned")
  S.AddAttack({ name = "Dorn", surname = "Fels", guid = "Player-93-D" }, { t = time(), zone = "Z", me = "Ich Selbst" })
  local n, kept = S.UndoImport()
  eq(n, 1, "nur Rabe zurueckgenommen"); eq(kept, 3)
  no(S.Get("Rabe-Ruf"))
  eq(S.Get("Grimm-Bart").note, "der mit dem Hut")
  eq(S.Get("Fies-Ling").status, "pardoned")
  eq(S.Attacks(S.Get("Dorn-Fels")), 1)
end)

test("Einlesen: zusammengefuehrt + danach Notiz bleibt wie er ist; unberuehrt Zusammengefuehrtes kommt zurueck", function()
  local ns = M.Load()
  local S = ns.Store
  S.ApplyKill({ name = "Grimm", surname = "Bart", guid = "Player-93-G" }, { t = time() - 900, zone = "Z", source = "recap" }, true)
  S.ApplyKill({ name = "Fies", surname = "Ling", guid = "Player-93-F" }, { t = time() - 800, zone = "Z", source = "recap" }, true)
  local okI, a, m = S.Import(text(E("Grimm-Bart", 5, "Bart", "Player-93-G"), E("Fies-Ling", 4, "Ling", "Player-93-F")))
  ok(okI); eq(m, 2)
  S.SetNote("Grimm-Bart", "Notiz nach dem Einlesen")
  local n, kept = S.UndoImport()
  eq(n, 1); eq(kept, 1)
  eq(S.Get("Fies-Ling").kills, 1, "Fies wie vorher")
  eq(S.Get("Grimm-Bart").note, "Notiz nach dem Einlesen", "Notiz bleibt")
  eq(S.Get("Grimm-Bart").kills, 5, "Grimm bleibt wie er ist (nicht sauber zuruecknehmbar)")
end)

test("Einlesen: von Hand gestrichen seitdem zaehlt weder zurueck noch geblieben", function()
  local ns = M.Load()
  local S = ns.Store
  S.Import(text(E("Grimm-Bart", 2, "Bart", "Player-93-G")))
  S.Remove("Grimm-Bart")
  local n, kept = S.UndoImport()
  eq(n, 0); eq(kept, 0)
end)

M.done("fix140 rueckgaengig")
