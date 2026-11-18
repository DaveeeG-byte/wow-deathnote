-- Copy of the bug hunter's test (fixer 2 1.6.0), red on b55addb.
-- Jagd 2 Fehler 03: Regel der Runde: "Ein Fehler in neuem Code darf nie das Buch, den Alarm oder die Todes-Erkennung
-- brechen." Drei Stellen rufen neuen Code (Feud.lua, Fates.lua) ohne pcall aus dem Kern:
--  a) Store.ApplyKill / AddAttack / Seen -> Feud.Touch. Wirft es, bricht finalize ab; attempt() hat `pending` schon
--     geloest, also greift auch das Netz in runAttempt nicht: der Tod steht weder im Journal noch am Feind.
--  b) Store.Init -> sanitizeEntry -> Feud.SanitizeEntry (Feud.OnInit daneben steht unter pcall, dies nicht). Wirft es,
--     bricht PLAYER_LOGIN ab: kein READY, das Buch bleibt die ganze Sitzung tot.
--  c) Attribution.ReadRecap -> Fates.EnvOf. Wirft es, kostet es die Stufe Recap: aus dem sicheren Moerder wird ein
--     unklarer Tod.
-- Simuliert wird der Fehler, indem die eine Funktion wirft (ein realer Ausloeser wurde nicht gefunden).
-- Lauf: cd ~/Projects/wow-deathnote-jagd && luajit <diese Datei> .   (Exit 1 = Fund belegt)
local DIR = ((arg and arg[1]) or "."):gsub("/+$", "")
arg[0] = DIR .. "/tests/jagd2_bug_03.lua"
package.path = DIR .. "/tests/?.lua;" .. package.path
local M = require("mock_wow")
local results = { pass = 0, fail = 0 }
local function check(name, cond, info)
  if cond then results.pass = results.pass + 1; print("ok    " .. name)
  else results.fail = results.fail + 1; print("ROT   " .. name .. (info and ("  -> " .. tostring(info)) or "")) end
end
local function ev(o)
  return { sourceGUID = o.guid, sourceName = o.name, amount = o.amount or 100, overkill = o.overkill or 0,
    timestamp = time() - 1, spellName = o.spell, hideCaster = false, event = o.event or "SPELL_DAMAGE",
    environmentalType = o.env }
end
local KILL = { guid = "Player-93-0000BEEF", name = "Grimm Bart", amount = 900, overkill = 10, spell = "Meucheln" }

do -- a
  local ns = M.Load()
  ns.Feud.Touch = function() error("jb boom Touch") end
  M.recap = { id = 1, events = { ev(KILL) } }
  M.FireEvent("PLAYER_DEAD"); M.Advance(8)
  local e = ns.Store.Get("Grimm-Bart")
  check("a) Feud.Touch wirft: der Tod steht im Journal", #ns.Store.Journal() == 1, "Journalzeilen " .. #ns.Store.Journal())
  check("a) Feud.Touch wirft: der Moerder hat seine Toetung", e and e.kills == 1, "Eintrag " .. tostring(e ~= nil) .. ", kills " .. tostring(e and e.kills))
end
do -- b
  local db = { version = 5, settings = {}, deaths = {}, enemies = { ["Grimm-Bart"] = { name = "Grimm", surname = "Bart",
    kills = 1, deaths = { { t = 1700000000, role = "kill", sure = true } }, status = "wanted" } } }
  local ns = M.Load({ db = db, noLogin = true })
  ns.Feud.SanitizeEntry = function() error("jb boom SanitizeEntry") end
  M.FireEvent("PLAYER_LOGIN"); M.FireEvent("PLAYER_ENTERING_WORLD"); M.Advance(8)
  check("b) Feud.SanitizeEntry wirft: das Buch startet (READY)", ns.ready == true, "ns.ready " .. tostring(ns.ready))
end
do -- c
  local ns = M.Load()
  ns.Fates.EnvOf = function() error("jb boom EnvOf") end
  M.recap = { id = 3, events = { ev({ event = "ENVIRONMENTAL_DAMAGE", env = "Falling", amount = 50 }), ev(KILL) } }
  M.FireEvent("PLAYER_DEAD"); M.Advance(8)
  local j = ns.Store.Journal()[1]
  check("c) Fates.EnvOf wirft: der Todesstoss des Spielers bleibt sicher", j and j.kind == "pvp" and j.sure == true,
    "Art " .. tostring(j and j.kind) .. ", sicher " .. tostring(j and j.sure) .. ", Quelle " .. tostring(j and j.source))
end
print(("jb03 fehler in neuem code  %d ok, %d rot"):format(results.pass, results.fail))
os.exit(results.fail > 0 and 1 or 0)
