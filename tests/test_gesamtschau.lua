-- 1.1.0 (Gesamtschau): greeting once, /dn still, one time format, guild Count/foreign,
-- Health text/short for every reason, sharing never sends assists or suspicions.
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local M = require("mock_wow")
local test, eq, ok, no = M.test, M.eq, M.ok, M.no

local GUILD = "Die Fachkräfte"
local WELCOME = "DeathNote: Das Buch liegt bereit. Wer dich in der offenen Welt tötet, steht danach drin. "
  .. "Aufschlagen mit /dn oder am Minimap-Knopf."
local PLATES = "DeathNote: Feindliche Namensplaketten sind aus. Ohne sie sieht der Alarm nur dein Ziel."

local function plain(msg) return (msg:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")) end
local function count(lines, text)
  local n = 0
  for _, l in ipairs(lines) do if plain(l) == text then n = n + 1 end end
  return n
end
local function slash(msg) _G.SlashCmdList.DEATHNOTE(msg) end
-- characters, not bytes (umlauts are two bytes)
local function chars(s) return #(s:gsub("[\128-\191]", "")) end

---------------------------------------------------------------------------
-- First contact
---------------------------------------------------------------------------
test("Begrüßung: einmal, 5 s nach dem Login, Wortlaut aus dem Bericht", function()
  M.Load()
  eq(_G.DeathNoteDB.settings.welcomed, false, "Standard")
  M.Advance(4.9)
  eq(count(M.chat, WELCOME), 0, "noch nicht nach 4,9 s")
  M.Advance(0.2)
  eq(count(M.chat, WELCOME), 1, "nach 5 s")
  eq(count(M.chat, PLATES), 0, "Namensplaketten sind an: keine zweite Zeile")
  eq(_G.DeathNoteDB.settings.welcomed, true)
  M.Advance(60)
  eq(count(M.chat, WELCOME), 1, "kein zweites Mal")
  -- /reload with the same DB
  local db = _G.DeathNoteDB
  M.Load({ db = db, keepWorld = true }); M.Advance(30)
  eq(count(M.chat, WELCOME), 1, "auch nach Neuladen nicht")
end)

test("Begrüßung nicht im Kampf: kommt erst nach dem Kampf, dann genau einmal", function()
  M.Load({ before = function() M.inCombat = true end })
  M.Advance(10)
  eq(count(M.chat, WELCOME), 0, "im Kampf still")
  eq(_G.DeathNoteDB.settings.welcomed, false)
  M.FireEvent("PLAYER_REGEN_ENABLED")      -- still in combat (flag): nothing
  eq(count(M.chat, WELCOME), 0)
  M.inCombat = false
  M.FireEvent("PLAYER_REGEN_ENABLED")
  eq(count(M.chat, WELCOME), 1, "nach dem Kampf")
  M.FireEvent("PLAYER_REGEN_ENABLED")
  eq(count(M.chat, WELCOME), 1, "nur einmal")
end)

test("Begrüßung: zweite Zeile, wenn feindliche Namensplaketten aus sind", function()
  M.Load({ before = function() M.cvars.nameplateShowEnemies = false end })
  M.Advance(6)
  eq(count(M.chat, WELCOME), 1); eq(count(M.chat, PLATES), 1)
  local iw, ip
  for i, l in ipairs(M.chat) do
    if plain(l) == WELCOME then iw = i elseif plain(l) == PLATES then ip = i end
  end
  eq(ip, iw + 1, "direkt danach")
end)

test("Begrüßung auch für eine bestehende 1.0.1-DB mit Einträgen", function()
  M.Load({ db = { version = 2, settings = { alert = { enabled = true } }, enemies = { ["Alt-A"] = { kills = 2 } } } })
  M.Advance(6)
  eq(count(M.chat, WELCOME), 1)
end)

---------------------------------------------------------------------------
-- /dn still
---------------------------------------------------------------------------
test("/dn still schaltet den Alarm um, meldet es und feuert SETTINGS_CHANGED", function()
  local ns = M.Load()
  M.ClearFired()
  slash("still")
  eq(ns.Store.Setting("alert.enabled"), false); eq(plain(M.chat[#M.chat]), "DeathNote: Alarm aus.")
  eq(M.Fired("SETTINGS_CHANGED")[1][2], "alert.enabled")
  slash("STILL")
  eq(ns.Store.Setting("alert.enabled"), true); eq(plain(M.chat[#M.chat]), "DeathNote: Alarm an.")
  local n = #M.chat
  slash("hilfe")
  local help = table.concat(M.chat, "\n", n + 1)
  ok(help:find("/dn still", 1, true), "in der Hilfe")
  ok(help:find("schweigt das Buch", 1, true), "Hinweis auf Ruhe in Instanzen")
end)

test("Wortwahl: Chat-Ausgaben ohne alte Wörter", function()
  M.Load({ before = function() M.units.player.guild = GUILD end })
  slash("add Grimm Bart"); slash("del Grimm"); slash("del Niemand"); slash("hilfe"); slash("gilde"); slash("sync")
  slash("debug"); slash("quatsch")
  local all = plain(table.concat(M.chat, "\n"))
  for _, w in ipairs({ "Fahndungsliste", "Notizbuch", "Gilden-Todesliste", "Gildenliste", "Feinde", "Mitglied",
    "Addon-Nachricht", "Präfix", "Rückgabe", "von der Liste", "löschen" }) do
    no(all:find(w, 1, true), "altes Wort: " .. w)
  end
  ok(all:find("Grimm Bart steht jetzt im Buch.", 1, true)); ok(all:find("Grimm Bart ist aus dem Buch gestrichen.", 1, true))
  ok(all:find("Gildenbuch:", 1, true))
end)

---------------------------------------------------------------------------
-- Time format
---------------------------------------------------------------------------
test("Zeitformat: When absolut kurz, Ago relativ, ab 7 Tagen Datum", function()
  local ns = M.Load(); local U = ns.Util
  local now = time()
  eq(U.When(now - 3600), os.date("%d.%m. %H:%M", now - 3600))
  local lastYear = now - 400 * 86400
  eq(U.When(lastYear), os.date("%d.%m.%Y %H:%M", lastYear), "Jahr nur, wenn nicht das laufende")
  eq(U.When(nil), "?"); eq(U.When(0 / 0), "?")
  eq(U.Ago(now - 6 * 86400), "vor 6 Tagen")
  local week = now - 8 * 86400
  local exp = os.date("%Y", week) == os.date("%Y", now) and os.date("%d.%m.", week) or os.date("%d.%m.%y", week)
  eq(U.Ago(week), exp, "ab 7 Tagen das Datum")
  eq(U.Ago(lastYear), os.date("%d.%m.%y", lastYear))
  eq(U.Ago(now - 1380), "vor 23 Min.")
end)

---------------------------------------------------------------------------
-- Guild: Count fourth value, List foreign
---------------------------------------------------------------------------
local function loadGuild()
  return M.Load({ before = function() M.units.player.guild = GUILD end })
end
local function hear(text, sender)
  M.FireEvent("CHAT_MSG_ADDON", "DeathNote", text, "GUILD", sender or "Kollege-Forever")
end

test("Guild.Count: vierter Wert zählt nur Einträge mit einem anderen Char; List foreign", function()
  local ns = loadGuild()
  local G = ns.Guild
  -- own sure kill: in the guild list, but not foreign
  local key = ns.Store.ApplyKill({ name = "Eigen", surname = "Feind" },
    { t = time() - 50, zone = "Z", me = "Varorak Narenmar", source = "recap", others = {} }, true)
  ns:Fire("DEATH_RECORDED", { t = time() - 50, zone = "Z", me = "Varorak Narenmar", kind = "pvp", sure = true,
    counted = true, killerKey = key, source = "recap" }, key)
  local e, d, l, f = G.Count()
  eq(e, 1); eq(d, 1); eq(l, 0); eq(f, 0, "nur man selbst: kein Fremdeintrag")
  eq(#G.List("rank", { foreign = true }), 0)
  -- a member's kill and a member's listing
  hear(G.Proto.EncodeKill({ key = "Grimm-Bart", display = "Grimm Bart", class = "ROGUE", level = 40, zone = "Z",
    t = time() - 30, victim = "Kollege Wurst" }, "K"))
  hear(G.Proto.EncodeListed({ key = "Hand-Gelistet", display = "Hand Gelistet", t = time() - 20, by = "Kollege Wurst" }))
  e, d, l, f = G.Count()
  eq(e, 3); eq(d, 2); eq(l, 1); eq(f, 2)
  local fl = G.List("rank", { foreign = true })
  eq(#fl, 2); eq(fl[1].key, "Grimm-Bart", "Kills vor reinen Hand-Einträgen")
  eq(#G.List("rank"), 3, "ohne foreign alles")
  eq(#G.List("rank", { foreign = true, only = "kills" }), 1)
  -- the same enemy also killed the colleague: the own entry becomes foreign
  hear(G.Proto.EncodeKill({ key = key, display = "Eigen Feind", level = 40, zone = "Z", t = time() - 10,
    victim = "Kollege Wurst" }, "K"))
  eq(select(4, G.Count()), 3)
end)

---------------------------------------------------------------------------
-- Health: a short sentence for players and a button label for every reason
---------------------------------------------------------------------------
local TECH = { "Präfix", "Prefix", "Addon", "Nachricht", "Rückgabe", "API", "Kanal", "Schlange", "Enum", "nil" }

local function checkWords(h)
  ok(type(h.text) == "string" and h.text ~= "", "Satz da")
  ok(chars(h.text) <= 60, h.reason .. " Satz zu lang (" .. chars(h.text) .. "): " .. h.text)
  ok(type(h.short) == "string" and h.short ~= "", "Knopftext da")
  ok(chars(h.short) <= 24, h.reason .. " Knopftext zu lang: " .. h.short)
  for _, w in ipairs(TECH) do no(h.text:find(w, 1, true), h.reason .. ": Technikwort " .. w) end
  no(h.text:find("%d%d"), h.reason .. ": keine Rückgabecodes im Satz")
end

local function world()
  M.Reset()
  return M.NewWorld()
end

test("Guild.Health: jeder Grund hat text (<= 60, ohne Technik) und short (<= 24)", function()
  local seen = {}
  local function take(h, reason, short)
    eq(h.reason, reason)
    checkWords(h)
    if short then eq(h.short, short) end
    seen[reason] = true
  end
  -- noguild
  local W = world(); local a = W.client("Varorak", "Narenmar", nil); a.login(); W.run(30)
  take(a.ns.Guild.Health(), "noguild", "Keine Gilde")
  -- off
  W = world(); a = W.client("Varorak", "Narenmar", GUILD); a.login(); W.run(30)
  a.ns.Store.Setting("guild.share", false)
  take(a.ns.Guild.Health(), "off", "Teilen ist aus")
  -- prefix refused
  W = world(); a = W.client("Varorak", "Narenmar", GUILD)
  a.env.C_ChatInfo.RegisterAddonMessagePrefix = function() return 2 end
  a.login(); W.run(30)
  local h = a.ns.Guild.Health()
  take(h, "prefix"); eq(h.ok, false); ok(h.detail:find("2", 1, true), "Technik nur im Detail")
  -- blocked: nothing ever went out
  W = world(); a = W.client("Varorak", "Narenmar", GUILD); a.sendResult = 11; a.login(); W.run(60)
  take(a.ns.Guild.Health(), "blocked", "Realm blockt Senden")
  -- failing: worked before, refused now
  W = world(); a = W.client("Varorak", "Narenmar", GUILD); a.login(); W.run(30)
  ok(a.ns.Guild.stats.sent > 0)
  a.sendResult = 10
  a.ns.Store.AddManual("Neu", "Feind"); W.run(5)
  take(a.ns.Guild.Health(), "failing")
  -- hold: in combat with something waiting
  W = world(); a = W.client("Varorak", "Narenmar", GUILD); a.combat = true; a.login(); W.run(30)
  ok(a.ns.Guild.QueueSize() > 0, "wartet")
  take(a.ns.Guild.Health(), "hold", "Wartet: im Kampf")
  -- quiet: sent, nobody answered
  W = world(); a = W.client("Varorak", "Narenmar", GUILD); a.login(); W.run(60)
  take(a.ns.Guild.Health(), "quiet", "Angefragt")
  -- ok: two clients talking
  W = world(); a = W.client("Varorak", "Narenmar", GUILD); local b = W.client("Moppel", "Mogsen", GUILD)
  a.login(); b.login(); W.run(60)
  h = a.ns.Guild.Health()
  take(h, "ok", "Angefragt"); ok(h.text:find("1 Kollege", 1, true), h.text)
  for _, r in ipairs({ "noguild", "off", "prefix", "blocked", "failing", "hold", "quiet", "ok" }) do
    ok(seen[r], "Grund geprüft: " .. r)
  end
  eq(#M.errors, 0, tostring(M.errors[1]))
end)

---------------------------------------------------------------------------
-- Sharing: kills only
---------------------------------------------------------------------------
test("Gilden-Sync teilt nur kill-Taten, nie assists oder suspects (live, Antwort, Nachtrag)", function()
  local W = world()
  local a = W.client("Varorak", "Narenmar", GUILD)
  local b = W.client("Moppel", "Mogsen", GUILD)
  a.login(); W.run(30)
  local me = "Varorak Narenmar"
  local S = a.ns.Store
  local t = time()
  -- one death: killer + recap co-attacker; another: heuristic only
  local k = S.ApplyKill({ name = "Yoron", surname = "Pvp" }, { t = t - 100, zone = "Z", me = me, source = "recap",
    others = { "Brenendan-Forever" } }, true)
  S.ApplyKill({ name = "Brenendan", surname = "Forever" }, { t = t - 100, zone = "Z", me = me, source = "recap",
    others = { k } }, false)
  S.ApplyKill({ name = "Brenensil", surname = "Mage" }, { t = t - 200, zone = "Z", me = me, source = "suspect" }, false)
  eq(S.Get("Brenendan-Forever").deaths[1].role, "assist")
  eq(S.Get("Brenendan-Forever").status, "wanted", "beteiligt = gesucht, aber kein Hand-Eintrag")
  local own = a.ns.Guild.OwnKills(0)
  eq(#own, 1); eq(own[1].key, k)
  -- b logs in later: hello -> answer from a
  b.login(); W.run(40)
  ok(b.ns.Guild.Get(k), "Kill geteilt")
  no(b.ns.Guild.Get("Brenendan-Forever"), "Beteiligung nie gesendet")
  no(b.ns.Guild.Get("Brenensil-Mage"), "Verdacht nie gesendet")
  no(a.ns.Guild.Get("Brenendan-Forever"), "auch nicht in der eigenen Gildenliste")
  for _, m in ipairs(W.sent) do
    no(m.text:find("Brenendan", 1, true), "keine Nachricht nennt den Beteiligten: " .. m.text)
    no(m.text:find("Brenensil", 1, true), "keine Nachricht nennt den Verdächtigen")
  end
  -- confirming the assist makes it a kill: now it may be shared (next login backfill)
  ok(S.ConfirmSuspect("Brenendan-Forever"))
  eq(#a.ns.Guild.OwnKills(0), 2)
  eq(#M.errors, 0, tostring(M.errors[1]))
end)

M.done("test_gesamtschau")
