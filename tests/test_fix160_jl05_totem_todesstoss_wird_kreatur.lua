-- Jagd Logik 160/05: Ein Schamane schlaegt mich fast tot (900), sein Totem (GUID "Creature-...", der Recap kennt keinen
-- Besitzer) gibt den Todesstoss. Decide bucht "pve" (Todesstoss einer Kreatur), keine Journalzeile, kein Kandidat.
-- Das Verhalten ist alt (1.5.0 genauso), 1.6.0 macht daraus aber zusaetzlich eine Kreatur "Totem der Verbrennung" als
-- Ursache samt Erzfeind-Rang und Auszeichnungen; der Schamane fehlt im Buch der Fehde. Erwartet: hat in derselben
-- Stufe ein Spieler Schaden gemacht, wird der Tod nicht still zur Kreatur.
-- Lauf: cd ~/Projects/wow-deathnote-jagd && luajit <diese Datei> .   (Exit 1 = Fund belegt)
local DIR = ((arg and arg[1]) or "."):gsub("/+$", "")
arg[0] = DIR .. "/tests/jagd160_05.lua"
package.path = DIR .. "/tests/?.lua;" .. package.path
local M = require("mock_wow")
local test, ok = M.test, M.ok

local function ev(o)
  return { sourceGUID = o.guid, sourceName = o.name, amount = o.amount or 100, overkill = o.overkill or 0,
    timestamp = time() - 1, spellName = o.spell, hideCaster = false, event = "SPELL_DAMAGE" }
end

test("JL160-05: Schamane 900, Totem gibt den Todesstoss", function()
  local ns = M.Load()
  M.recap = { id = 4712, events = {
    ev({ guid = "Player-93-0000BEEF", name = "Grimm Bart", amount = 900, spell = "Blitzschlag" }),
    ev({ guid = "Creature-0-3110-0-49-2523-0000AB0001", name = "Totem der Verbrennung", amount = 60, overkill = 20,
      spell = "Verbrennen" }),
  } }
  M.FireEvent("PLAYER_DEAD")
  M.Advance(6)
  local j = ns.Store.Journal()
  ok(#j == 1 and #(j[1].candidates or {}) >= 1, "Journalzeile mit Grimm Bart als Kandidat (Journal: " .. #j .. ")")
end)

M.done("jl160-05 totem")
