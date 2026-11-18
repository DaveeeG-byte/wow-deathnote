-- Jagd Logik 150/01: Die Chronik zaehlt die Wendepunkte ("Jetzt quitt", "Jetzt vorn") aus den gespeicherten Taten nach.
-- Ein Feind behaelt aber hoechstens 30 Taten (aeltere fallen weg), seine Toetungen (e.kills) zaehlen weiter. In einer
-- langen Fehde meldet die Chronik darum "Jetzt quitt: 30 : 30", waehrend der echte Stand (Schlusszeile) 30 : 35 ist.
-- Erwartet: kein Wendepunkt, den der echte Stand nie hatte (oder die Wendepunkte ab einer gekappten Fehde weglassen).
local DIR = ((arg and arg[1]) or "."):gsub("/+$", "")
arg[0] = DIR .. "/tests/jagd150.lua"
package.path = DIR .. "/tests/?.lua;" .. package.path
local M = require("mock_wow")
local test, eq, ok, no = M.test, M.eq, M.ok, M.no

test("JL150-01: Chronik behauptet einen Gleichstand, den es nie gab", function()
  local ns = M.Load({ before = function() M.units.player.guild = "Die Wurstbrüder" end })
  local S, C = ns.Store, ns.Chronicle
  local t0 = time() - 40 * 86400
  local key
  for i = 1, 35 do
    key = S.ApplyKill({ name = "Viel", surname = "Taeter", class = "ROGUE" }, { t = t0 + i * 3600, zone = "Ort", source = "recap" }, true)
  end
  eq(S.Get(key).kills, 35)
  -- danach erlege ich ihn 30 Mal (Strafregister-Protokoll und Opferzaehler)
  local log = ns.Ledger.Log()
  local db = ns.Ledger.DB()
  for i = 1, 30 do
    table.insert(log, 1, { t = t0 + 10 * 86400 + i * 3600, key = key, name = "Viel Taeter", f = "v", zone = "Ort" })
  end
  db.victims[key] = db.victims[key] or {}
  db.victims[key].n = 30
  local m, h = ns.Ledger.Standing(key)
  eq(m, 30, "mein Stand"); eq(h, 35, "sein Stand")
  local ch = C.Build(key)
  local all = {}
  for _, l in ipairs(ch.lines) do all[#all + 1] = l.text end
  local txt = table.concat(all, "\n")
  ok(ch.lines[#ch.lines].text:find("30 : 35", 1, true), "Schlusszeile: " .. ch.lines[#ch.lines].text)
  no(txt:find("quitt: 30 : 30", 1, true) or txt:find("30 : 30", 1, true), "Wendepunkt ohne Grundlage:\n" .. txt)
end)

M.done("jl150-01 chronik")
