package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local M = require("mock_wow")
local test, eq, ok, no = M.test, M.eq, M.ok, M.no

local function kill(Store, name, surname, t, sure)
  -- 1.1.0: an unsure deed from the recap is an assist; a suspicion comes from the heuristic
  return Store.ApplyKill({ name = name, surname = surname },
    { t = t or time(), zone = "Z", source = sure == false and "suspect" or "recap" }, sure ~= false)
end

test("Leere DB: Defaults, READY gefeuert", function()
  local ns = M.Load()
  local db = _G.DeathNoteDB
  eq(db.version, 3)
  eq(db.settings.alert.cooldown, 90)
  eq(db.settings.alert.minKills, 1)
  eq(db.settings.ui.minimap.angle, 215)
  eq(db.settings.deathMessage, true)
  eq(db.settings.attribution.recap, true)
  eq(type(db.enemies), "table"); eq(type(db.deaths), "table")
  eq(#M.Fired("READY"), 1)
end)

test("Alte/kaputte DB wird repariert, Werte bleiben", function()
  local deaths = {}
  for i = 1, 120 do deaths[i] = { t = i } end
  deaths[5] = "kaputt"
  local ns = M.Load({ db = {
    settings = { alert = { cooldown = 30 }, debug = true, ui = "falsch" },
    enemies = {
      ["Alt-Narenmar"] = { kills = 3 },
      ["Leer-X"] = { },
      kaputt = 5,
    },
    deaths = deaths,
    probe = "x",
  } })
  local db = _G.DeathNoteDB
  eq(db.version, 3)
  eq(db.settings.alert.cooldown, 30, "Nutzerwert bleibt")
  eq(db.settings.alert.sound, true, "fehlender Default ergänzt")
  eq(type(db.settings.ui), "table")
  eq(db.settings.debug, true)
  local e = ns.Store.Get("Alt-Narenmar")
  eq(e.kills, 3); eq(e.status, "wanted"); eq(e.name, "Alt"); eq(e.realm, "Narenmar"); eq(#e.deaths, 0)
  eq(ns.Store.Get("Leer-X").status, "wanted")
  no(db.enemies.kaputt)
  eq(#db.deaths, 100)
  no(db.probe)
end)

test("Status-Regeln: sicher -> wanted, Verdacht -> suspect, begnadigt bleibt", function()
  local ns = M.Load(); local S = ns.Store
  local k = kill(S, "Verd", "A", nil, false)
  local e = S.Get(k)
  eq(e.status, "suspect"); eq(e.kills, 0); eq(e.suspected, 1)
  kill(S, "Verd", "A", nil, true)
  eq(e.status, "wanted"); eq(e.kills, 1)
  S.SetStatus(k, "pardoned")
  kill(S, "Verd", "A", nil, true)
  eq(e.status, "pardoned"); eq(e.kills, 2)
  -- suspicion on a wanted enemy keeps "wanted"
  local k2 = kill(S, "Boss", "B")
  kill(S, "Boss", "B", nil, false)
  eq(S.Get(k2).status, "wanted"); eq(S.Get(k2).suspected, 1)
  no(S.SetStatus(k2, "quatsch"))
end)

test("Rangliste und Rang", function()
  local ns = M.Load(); local S = ns.Store
  kill(S, "Eins", "A", 100); kill(S, "Eins", "A", 200); kill(S, "Eins", "A", 300)
  kill(S, "Zwei", "B", 500); kill(S, "Zwei", "B", 600)
  kill(S, "Drei", "C", 900); kill(S, "Drei", "C", 950)
  kill(S, "Vier", "D", nil, false)
  local r = S.Ranked("wanted", "rank")
  eq(#r, 3)
  eq(r[1].key, "Eins-A"); eq(r[2].key, "Drei-C", "gleiche Kills: jüngerer lastKill zuerst"); eq(r[3].key, "Zwei-B")
  eq(S.Rank("Eins-A"), 1); eq(S.Rank("Zwei-B"), 3); no(S.Rank("Vier-D"))
  eq(#S.Ranked("suspect"), 1); eq(#S.Ranked("all"), 4)
  local w, s, p = S.Count(); eq(w, 3); eq(s, 1); eq(p, 0)
  -- rank cache is invalidated on change
  kill(S, "Zwei", "B", 1000); kill(S, "Zwei", "B", 1001)
  eq(S.Rank("Zwei-B"), 1)
  local byName = S.Ranked("all", "name")
  eq(byName[1].key, "Drei-C")
end)

test("Deckelung: 30 Taten je Feind, 100 Tode im Journal", function()
  local ns = M.Load(); local S = ns.Store
  for i = 1, 35 do kill(S, "Viel", "X", i) end
  local e = S.Get("Viel-X")
  eq(#e.deaths, 30); eq(e.kills, 35); eq(e.deaths[1].t, 35, "neueste zuerst")
  for i = 1, 105 do S.RecordDeath({ t = i, kind = "unknown" }) end
  eq(#S.Deaths(), 100); eq(S.Deaths()[1].t, 105)
end)

-- 1.2.0: Tode durch Monster und Umwelt (pve) bekommen keine Journalzeile, zaehlen aber in db.tally;
-- alte pve-Zeilen bleiben in der Datei und fehlen nur in der Ansicht (Store.Journal)
test("pve: keine Journalzeile, Zaehler laeuft, alte Zeilen bleiben in der Datei", function()
  local ns = M.Load(); local S = ns.Store
  local db = S.DB()
  db.deaths[1] = { t = 5, kind = "pve", counted = true }      -- alte Zeile aus 1.1.0
  S.TouchJournal()
  S.RecordDeath({ t = 10, kind = "pvp", counted = true, candidates = {} })
  S.RecordDeath({ t = 11, kind = "pve", counted = true })
  S.RecordDeath({ t = 12, kind = "unknown", counted = true, candidates = {} })
  eq(#S.Deaths(), 3, "Datei: alte pve-Zeile plus pvp und unknown")
  eq(#S.Journal(), 2, "Ansicht: nur pvp und unknown")
  for _, j in ipairs(S.Journal()) do ok(j.kind ~= "pve", "keine pve-Zeile in der Ansicht") end
  eq(db.tally.n, 4, "Zaehler: alle vier Tode")
  eq(db.tally.last, 12, "letzter Tod")
end)

test("Setting lesen/schreiben feuert SETTINGS_CHANGED, nil schreibbar", function()
  local ns = M.Load(); local S = ns.Store
  eq(S.Setting("alert.cooldown"), 90)
  M.ClearFired()
  S.Setting("alert.cooldown", 30)
  eq(S.Setting("alert.cooldown"), 30)
  eq(M.Fired("SETTINGS_CHANGED")[1][2], "alert.cooldown")
  S.Setting("alert.point", { "TOP", "TOP", 0, -100 })
  eq(S.Setting("alert.point")[1], "TOP")
  S.Setting("alert.point", nil)
  no(S.Setting("alert.point"))
  no(S.Setting("gibt.es.nicht"))
end)

test("AddManual / Find / Remove / ENEMY_UPDATED", function()
  local ns = M.Load(); local S = ns.Store
  M.ClearFired()
  local k = S.AddManual("grimmbart eisenfaust")
  eq(k, "Grimmbart-Eisenfaust")
  local e = S.Get(k)
  ok(e.manual); eq(e.status, "wanted"); eq(e.surname, "Eisenfaust"); eq(e.display, "Grimmbart Eisenfaust")
  eq(M.Fired("ENEMY_UPDATED")[1][2], k)
  eq(S.AddManual("Grimmbart Eisenfaust"), k, "kein Duplikat")
  eq(S.Find("grimmbart"), k, "eindeutiger Vorname")
  eq(S.Find("GRIMMBART", "eisenfaust"), k)
  S.AddManual("Grimmbart", "Zwilling")
  no(S.Find("Grimmbart"), "Vorname mehrdeutig")
  ok(S.Remove(k))
  no(S.Get(k))
  no(S.Remove(k))
  no(S.AddManual(""))
end)

test("Verdacht bestätigen / verwerfen", function()
  local ns = M.Load(); local S = ns.Store
  S.RecordDeath({ t = 500, kind = "pvp", candidates = { "Sus-A" } })
  local k = S.ApplyKill({ name = "Sus", surname = "A" }, { t = 500, source = "suspect" }, false)
  ok(S.ConfirmSuspect(k))
  local e = S.Get(k)
  eq(e.kills, 1); eq(e.suspected, 0); eq(e.status, "wanted"); eq(e.deaths[1].sure, true); eq(e.lastKill, 500)
  eq(S.Deaths()[1].killerKey, k, "Journal nachgezogen")
  no(S.ConfirmSuspect(k, 1), "schon sicher")
  -- dismiss: pure suspect disappears
  local k2 = S.ApplyKill({ name = "Weg", surname = "B" }, { t = 600, source = "suspect" }, false)
  ok(S.DismissSuspect(k2)); no(S.Get(k2))
  -- dismiss on a wanted one keeps the entry, drops unsure deaths
  S.ApplyKill({ name = "Sus", surname = "A" }, { t = 700, source = "suspect" }, false)
  ok(S.DismissSuspect(k))
  eq(S.Get(k).suspected, 0); eq(#S.Get(k).deaths, 1)
end)

test("AddRevenge feuert REVENGE", function()
  local ns = M.Load(); local S = ns.Store
  local k = S.AddManual("Opfer")
  M.ClearFired()
  ok(S.AddRevenge(k))
  eq(S.Get(k).revenge, 1); ok(S.Get(k).lastRevenge)
  eq(M.Fired("REVENGE")[1][2], k)
  no(S.AddRevenge("gibts-nicht"))
end)

test("AssignDeath: Journal-Eintrag wird sicherer Kill, Umhängen korrigiert den alten", function()
  local ns = M.Load(); local S = ns.Store
  S.RecordDeath({ t = 800, kind = "pvp", candidates = { "Aa-X", "Bb-Y" }, zone = "Z", me = "Ich" })
  ok(S.AssignDeath(1, "Aa-X"))
  local a = S.Get("Aa-X")
  eq(a.kills, 1); eq(a.deaths[1].source, "manual"); eq(a.deaths[1].sure, true)
  local j = S.Deaths()[1]
  eq(j.killerKey, "Aa-X"); eq(j.sure, true); eq(j.source, "manual")
  ok(S.AssignDeath(1, "Bb-Y"))
  -- 1.1.0 (Abschlussjagd): wem nach dem Umhängen nichts bleibt, der steht nicht mehr als Gesuchter mit 0 im Buch
  no(S.Get("Aa-X"), "alter Kill zurückgenommen, leerer Eintrag gestrichen")
  eq(S.Get("Bb-Y").kills, 1)
  no(S.AssignDeath(99, "Bb-Y"))
end)

test("Bounty ist deterministisch und wächst mit Kills", function()
  local ns = M.Load(); local S = ns.Store
  local a = { kills = 1, suspected = 0, revenge = 0, level = 40 }
  local b = { kills = 3, suspected = 0, revenge = 0, level = 40 }
  eq(S.Bounty(a), S.Bounty(a))
  ok(S.Bounty(b) > S.Bounty(a))
  ok(S.Bounty({ kills = 3, revenge = 2, level = 40 }) < S.Bounty(b), "Rache zahlt aus")
  eq(S.Bounty(nil), 0)
end)

test("Upsert: gleiche GUID mit Nachnamen zieht den Eintrag um", function()
  local ns = M.Load(); local S = ns.Store
  local k = S.ApplyKill({ name = "Nur", guid = "Player-93-1" }, { t = 1 }, true)
  eq(k, "Nur-Forever")
  local k2 = S.ApplyKill({ name = "Nur", surname = "Vorname", guid = "Player-93-1" }, { t = 2 }, true)
  eq(k2, "Nur-Vorname")
  no(S.Get("Nur-Forever"))
  eq(S.Get(k2).kills, 2)
  eq(S.ByGUID("Player-93-1"), k2)
end)

test("Export/Import: Rundreise, Zusammenführen ohne Überschreiben", function()
  local ns = M.Load(); local S = ns.Store
  local k = kill(S, "Exp", "Ort|mit%Zeichen", 100)
  kill(S, "Exp", "Ort|mit%Zeichen", 200)
  S.SetNote(k, "Zeile1\nZeile2 | Pipe")
  kill(S, "Ärger", "Öde", 300, false)
  local text = S.Export()
  ok(text:find("^DEATHNOTE:1\n"))
  -- fresh DB: import everything
  local ns2 = M.Load(); local S2 = ns2.Store
  local good, added, merged = S2.Import(text)
  ok(good); eq(added, 2); eq(merged, 0)
  local e = S2.Get(k)
  eq(e.kills, 2); eq(#e.deaths, 2); eq(e.deaths[1].t, 200); eq(e.note, "Zeile1\nZeile2 | Pipe")
  eq(S2.Get("Ärger-Öde").status, "suspect")
  -- merge: own note and higher counters stay
  S2.SetNote(k, "eigene Notiz"); e.kills = 7
  local good2, added2, merged2 = S2.Import(text)
  ok(good2); eq(added2, 0); eq(merged2, 2)
  eq(e.note, "eigene Notiz"); eq(e.kills, 7); eq(#e.deaths, 2, "keine doppelten Taten")
end)

test("Import: kaputter Text -> false + Meldung, nichts geändert", function()
  local ns = M.Load(); local S = ns.Store
  local r, msg = S.Import("Hallo Welt")
  eq(r, false); ok(type(msg) == "string")
  r, msg = S.Import("DEATHNOTE:1\nE|nur|zwei")
  eq(r, false); ok(msg:find("Zeile 2"))
  r = S.Import("DEATHNOTE:1\nD|A-B|keineZahl|1|recap|||||||||")
  eq(r, false)
  eq(S.Import(nil), false)
  eq(next(S.All()), nil, "nichts angelegt")
  ok(S.Import("DEATHNOTE:1\n"), "leerer Export ist gültig")
end)

M.done("test_store")
