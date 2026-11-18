-- Copy of the bug hunter's test (fixer 2 1.6.0), red on b55addb.
-- (the duel partner renamed against the leak check; otherwise unchanged)
-- Jagd 2 Fehler 01: Der Fixer-Zweig in Attribution.Decide (Todesstoss einer Kreatur nach Spielerschaden in derselben
-- Stufe -> "pvp" unsicher, Taeter = Spieler mit dem meisten Schaden) prueft weder das Alter des Spielerschadens noch
-- Duell oder Fraktion. Der Recap haelt die letzten Schadenszeilen ohne Zeitgrenze (nur die NEUESTE Zeile wird gegen
-- STALE_RECAP geprueft). Folge: Duell (endet bei 1 HP), danach erschlaegt mich ein Wolf -> der Duellpartner der
-- eigenen Fraktion steht mit Rolle "assist" (Quelle recap) als GESUCHT im Buch und loest kuenftig Alarm aus.
-- 1.5.0 und 5cb6d88: "pve", kein Eintrag.
-- Lauf: cd ~/Projects/wow-deathnote-jagd && luajit <diese Datei> .   (Exit 1 = Fund belegt)
local DIR = ((arg and arg[1]) or "."):gsub("/+$", "")
arg[0] = DIR .. "/tests/jagd2_bug_01.lua"
package.path = DIR .. "/tests/?.lua;" .. package.path
local M = require("mock_wow")
local test, eq, ok = M.test, M.eq, M.ok

local function ev(o)
  return { sourceGUID = o.guid, sourceName = o.name, amount = o.amount or 100, overkill = o.overkill or 0,
    timestamp = time() - (o.ago or 1), spellName = o.spell, hideCaster = false, event = o.event or "SPELL_DAMAGE" }
end
local WOLF = "Creature-0-93-0-1-1131-0000A1"

local function entries(ns)
  local n, first = 0, nil
  for k, e in pairs(ns.Store.All()) do n = n + 1; first = first or e end
  return n, first
end

test("JB01a: Duell vorbei (20 s), dann toetet ein Wolf: Duellpartner der eigenen Fraktion", function()
  local ns = M.Load()
  M.AddEnemy("nameplate1", { name = "Rimbo", surname = "Kumpel", guid = "Player-93-0000D0E1", faction = "Horde",
    enemy = false, canAttack = false })
  M.FireEvent("DUEL_REQUESTED", "Rimbo")
  M.Advance(40)
  M.FireEvent("DUEL_FINISHED")
  M.Advance(20)
  M.recap = { id = 501, events = {
    ev({ guid = "Player-93-0000D0E1", name = "Rimbo Kumpel", amount = 800, ago = 21, spell = "Heldenhafter Stoss" }),
    ev({ guid = "Player-93-0000D0E1", name = "Rimbo Kumpel", amount = 700, ago = 22, spell = "Heldenhafter Stoss" }),
    ev({ guid = WOLF, name = "Waldwolf", amount = 60, overkill = 12, ago = 1, event = "SWING_DAMAGE" }),
  } }
  M.FireEvent("PLAYER_DEAD")
  M.Advance(6)
  local n, e = entries(ns)
  ok(n == 0, "kein Bucheintrag fuer den Duellpartner (Eintraege: " .. n .. ", Stand: " .. tostring(e and e.status)
    .. ", assists: " .. tostring(e and e.assists) .. ", Rolle: " .. tostring(e and e.deaths[1] and e.deaths[1].role) .. ")")
  local f = ns.Fates and ns.Fates.Rows() or {}
  ok(#f == 1 and f[1].art == "creature", "der Wolf steht als Ursache (Zeilen: " .. #f .. ")")
end)

test("JB01b: fremder Spieler traf mich vor 10 Minuten, jetzt toetet ein Wolf", function()
  local ns = M.Load()
  M.recap = { id = 502, events = {
    ev({ guid = "Player-93-0000BEEF", name = "Grimm Bart", amount = 300, ago = 600, spell = "Feuerschlag" }),
    ev({ guid = WOLF, name = "Waldwolf", amount = 400, ago = 3, event = "SWING_DAMAGE" }),
    ev({ guid = WOLF, name = "Waldwolf", amount = 400, overkill = 50, ago = 1, event = "SWING_DAMAGE" }),
  } }
  M.FireEvent("PLAYER_DEAD")
  M.Advance(6)
  local n, e = entries(ns)
  ok(n == 0 or (e and e.status ~= "wanted"), "10 Minuten alter Treffer macht niemanden GESUCHT (Eintraege: " .. n
    .. ", Stand: " .. tostring(e and e.status) .. ", assists: " .. tostring(e and e.assists) .. ")")
  local j = ns.Store.Journal()
  ok(not (j[1] and j[1].kind == "pvp"), "kein Spielertod im Journal (Art: " .. tostring(j[1] and j[1].kind) .. ")")
end)

test("JB01c Gegenprobe: nur der Wolf -> pve, Ursache Kreatur", function()
  local ns = M.Load()
  M.recap = { id = 503, events = {
    ev({ guid = WOLF, name = "Waldwolf", amount = 400, overkill = 50, ago = 1, event = "SWING_DAMAGE" }),
  } }
  M.FireEvent("PLAYER_DEAD")
  M.Advance(6)
  eq(entries(ns), 0, "kein Eintrag")
  eq(#ns.Store.Journal(), 0, "keine Journalzeile")
  eq(#ns.Fates.Rows(), 1, "eine Ursache")
end)

test("JB01d: Treffer eines Spielers vor 10 Minuten, jetzt Sturz in den Tod: zaehlt als Sturz", function()
  local ns = M.Load()
  M.recap = { id = 504, events = {
    ev({ guid = "Player-93-0000BEEF", name = "Grimm Bart", amount = 300, ago = 600, spell = "Feuerschlag" }),
    { amount = 900, overkill = 80, timestamp = time() - 1, event = "ENVIRONMENTAL_DAMAGE", environmentalType = "Falling",
      hideCaster = false },
  } }
  M.FireEvent("PLAYER_DEAD")
  M.Advance(6)
  local f = ns.Fates.Rows()
  ok(#f == 1 and f[1].art == "env", "der Sturz steht unter den Ursachen (Zeilen: " .. #f .. ", Journal: "
    .. tostring(ns.Store.Journal()[1] and ns.Store.Journal()[1].kind) .. " mit "
    .. tostring(ns.Store.Journal()[1] and #ns.Store.Journal()[1].candidates) .. " Kandidaten)")
end)

M.done("jb01 duell dann kreatur")
