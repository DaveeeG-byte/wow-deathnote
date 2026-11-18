-- Fixer 2 1.6.0 (jb03): the core calls Feud.Touch, Feud.SanitizeEntry, Feud.RevengeGuild, Feud.GuildRead and
-- Fates.EnvOf through pcall; an error there is reported (once per function), not swallowed, and death, deed, sighting
-- and start stay whole. And the evaluation's net: an error inside the booking after the evaluation still leaves the
-- death in the journal (unclear). Names made up.
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local M = require("mock_wow")
local test, ok, eq = M.test, M.ok, M.eq
local function ev(o)
  return { sourceGUID = o.guid, sourceName = o.name, amount = o.amount or 100, overkill = o.overkill or 0,
    timestamp = time() - 1, spellName = o.spell, hideCaster = false, event = o.event or "SPELL_DAMAGE" }
end
local KILL = { guid = "Player-93-0000BEEF", name = "Grimm Bart", amount = 900, overkill = 10, spell = "Meucheln" }

test("Feud.Touch wirft bei jedem Aufruf: Tod, Sichtung gebucht, Fehler einmal gemeldet", function()
  local ns = M.Load()
  local reported = {}
  ns.ReportError = function(e) reported[#reported + 1] = tostring(e) end
  ns.Feud.Touch = function() error("boom Touch") end
  M.recap = { id = 1, events = { ev(KILL) } }
  M.FireEvent("PLAYER_DEAD"); M.Advance(8)
  eq(#ns.Store.Journal(), 1, "Journal")
  eq(ns.Store.Get("Grimm-Bart").kills, 1, "Tötung")
  ok(ns.Store.Seen("Grimm-Bart", {}, { t = time(), zone = "Z" }, true), "Sichtung geschrieben")
  eq(#reported, 1, "einmal gemeldet")
  ok(reported[1] and reported[1]:find("boom Touch", 1, true), reported[1])
end)

test("Feud.RevengeGuild wirft: die Rache zählt trotzdem", function()
  local ns = M.Load()
  ns.ReportError = function() end
  M.recap = { id = 2, events = { ev(KILL) } }
  M.FireEvent("PLAYER_DEAD"); M.Advance(8)
  ns.Feud.RevengeGuild = function() error("boom Rev") end
  local before = ns.Store.Get("Grimm-Bart").revenge or 0
  ns.Store.AddRevenge("Grimm-Bart")
  eq(ns.Store.Get("Grimm-Bart").revenge or 0, before + 1, "Rache gezählt")
end)

test("Netz der Auswertung: ein Fehler in der Buchung nach der Auswertung lässt den Tod im Journal", function()
  local ns = M.Load()
  ns.ReportError = function() end
  local apply = ns.Store.ApplyKill
  ns.Store.ApplyKill = function() error("boom ApplyKill") end
  M.recap = { id = 3, events = { ev(KILL) } }
  M.FireEvent("PLAYER_DEAD"); M.Advance(8)
  ns.Store.ApplyKill = apply
  local j = ns.Store.Journal()
  eq(#j, 1, "eine Journalzeile")
  eq(j[1] and j[1].kind, "unknown", "unklar")
end)

M.done("fix160 jb03 Fehler gemeldet")
