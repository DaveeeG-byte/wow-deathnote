-- Jagd Logik 160/04: Ein Spieler schlaegt mich fast tot (Recap: 900 Schaden), den Todesstoss gibt die Umwelt (Sturz
-- nach Rueckstoss, Lava, Ertrinken). 1.5.0: Umweltzeile ohne GUID -> isPlayer nil -> Art "unknown", Journalzeile mit
-- dem Spieler als Kandidat (Zu klaeren). 1.6.0: Attribution.Classify macht jede Umweltzeile zu isPlayer = false,
-- Decide bucht "pve", Store.RecordDeath legt fuer "pve" KEINE Journalzeile an. Der Tod verschwindet aus dem Buch der
-- Fehde (nur noch eine Zeile "Sturz" in den anderen Toden), der Spieler steht nirgends als Kandidat.
-- Lauf: cd ~/Projects/wow-deathnote-jagd && luajit <diese Datei> .   (Exit 1 = Fund belegt)
local DIR = ((arg and arg[1]) or "."):gsub("/+$", "")
arg[0] = DIR .. "/tests/jagd160_04.lua"
package.path = DIR .. "/tests/?.lua;" .. package.path
local M = require("mock_wow")
local test, eq, ok = M.test, M.eq, M.ok

local function ev(o)
  return { sourceGUID = o.guid, sourceName = o.name, amount = o.amount or 100, overkill = o.overkill or 0,
    timestamp = time() - 1, spellName = o.spell, hideCaster = false, event = o.event or "SPELL_DAMAGE",
    environmentalType = o.env }
end

for _, env in ipairs({ "Falling", "Lava", "Drowning" }) do
  test("JL160-04: Spieler 900 Schaden, Todesstoss " .. env, function()
    local ns = M.Load()
    M.recap = { id = 4711, events = {
      ev({ guid = "Player-93-0000BEEF", name = "Grimm Bart", amount = 900, overkill = 0, spell = "Donnerknall" }),
      ev({ event = "ENVIRONMENTAL_DAMAGE", env = env, amount = 150, overkill = 40 }),
    } }
    M.FireEvent("PLAYER_DEAD")
    M.Advance(6)
    local j = ns.Store.Journal()
    ok(#j == 1, "Journalzeile fuer den Tod mit Spielerschaden (gefunden: " .. #j .. ", Art im Buch der anderen Tode: "
      .. tostring(ns.Fates and ns.Fates.Rows()[1] and ns.Fates.Rows()[1].art) .. ")")
    local cand = j[1] and j[1].candidates or {}
    ok(#cand >= 1, "Grimm Bart steht als Kandidat")
  end)
end

M.done("jl160-04 sturz nach spielerschaden")
