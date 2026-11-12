-- 1.1.0: roles of deeds (kill/assist/suspect), migration of real 1.0.1 data, rank with assists,
-- Weight, open cases, Count() fourth value, export with roles.
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local M = require("mock_wow")
local test, eq, ok, no = M.test, M.eq, M.ok, M.no

local DIR = arg[0]:match("^(.*)/") or "."

-- Autor's real SavedVariables of 1.0.1 (DB version 2), fresh copy on every call
local function autorDB()
  local chunk = assert(loadfile(DIR .. "/fixtures/sv_1.0.1_autor.lua"))
  local env = {}
  setfenv(chunk, env)
  chunk()
  return env.DeathNoteDB
end
local AUTOR_NOW = 1794357000   -- shortly after the last death in the file

local function loadAutor(db)
  return M.Load({ db = db or autorDB(), before = function() M.epoch = AUTOR_NOW - 1000 end })
end

local function roles(e)
  local out = {}
  for i = 1, #e.deaths do out[#out + 1] = e.deaths[i].role end
  return table.concat(out, ",")
end

local function ev(o)
  return { sourceGUID = o.guid, sourceName = o.name, amount = o.amount or 100, overkill = o.overkill or -1,
    timestamp = o.ts or (time() - 1), spellName = o.spell or "Hieb" }
end
local function die() M.FireEvent("PLAYER_DEAD"); M.Advance(5) end

---------------------------------------------------------------------------
-- Migration with the real data
---------------------------------------------------------------------------
test("Migration an Autors echten Daten: Mittäter werden Beteiligte und Gesuchte", function()
  local raw = autorDB()
  eq(raw.version, 2)
  eq(raw.enemies["Brenendan-Forever"].status, "suspect", "vorher: Brenendan verdächtig")
  eq(raw.enemies["Yoron-Pvp"].suspected, 2, "vorher: Yoron 2 Verdachtsfälle")
  local ns = loadAutor(raw)
  local S = ns.Store
  eq(_G.DeathNoteDB.version, 4)  -- 1.3.0: version 4 (rap sheet)
  local x = S.Get("Yoron-Pvp")
  eq(x.kills, 1); eq(x.assists, 2); eq(x.suspected, 0); eq(x.status, "wanted")
  eq(roles(x), "kill,assist,assist")
  local y = S.Get("Brenensil-Mage")
  eq(y.kills, 2); eq(y.assists, 1); eq(y.suspected, 0); eq(y.status, "wanted")
  eq(roles(y), "assist,kill,kill")
  local k = S.Get("Brenendan-Forever")
  eq(k.kills, 0); ok(k.assists >= 1, "Brenendan beteiligt"); eq(k.assists, 1); eq(k.suspected, 0)
  eq(k.status, "wanted", "Brenendan ist nicht mehr verdächtig")
  local g = S.Get("Wenil-Star")
  eq(g.kills, 1); eq(g.assists, 0); eq(g.status, "wanted"); eq(g.revenge, 1)
  -- sure follows the role everywhere
  for _, e in pairs(S.All()) do
    for _, d in ipairs(e.deaths) do eq(d.sure, d.role == "kill", e.key .. " sure passt zur Rolle") end
  end
  -- nothing lost
  eq(#x.deaths, 3); eq(#S.Deaths(), 4); eq(S.Get("Yoron-Pvp").revenge, 2); eq(x.lastSeen.t, 1794355634)
  eq(S.Setting("ui.point")[1], "CENTER", "Fensterposition bleibt")
  eq(S.Setting("welcomed"), false, "auch Autor bekommt die Begrüßung einmal")
  local w, s, p, open = S.Count()
  eq(w, 4); eq(s, 0); eq(p, 0); eq(open, 0)
  -- rank: Brenensil 2 kills, then Yoron (1 kill, 2 assists) before Wenil (1 kill), then Brenendan
  local r = S.Ranked("wanted", "rank")
  eq(r[1].key, "Brenensil-Mage"); eq(r[2].key, "Yoron-Pvp"); eq(r[3].key, "Wenil-Star"); eq(r[4].key, "Brenendan-Forever")
  eq(S.Weight(x), 3); eq(S.Weight(k), 1)
  -- the guild list of the file is still there
  ok(ns.Guild.Get("Yoron-Pvp"), "Gildenliste übernommen")
  no(M.ContainsSecret(_G.DeathNoteDB))
end)

test("Migration ist idempotent (Init doppelt, Neuladen, MigrateRoles doppelt)", function()
  local ns = loadAutor()
  local S = ns.Store
  local function snap()
    local out = {}
    for key, e in pairs(S.All()) do
      out[#out + 1] = key .. ":" .. e.kills .. "/" .. e.assists .. "/" .. e.suspected .. "/" .. e.status .. "/" .. roles(e)
    end
    table.sort(out)
    return table.concat(out, ";")
  end
  local first = snap()
  S.Init()
  eq(snap(), first, "zweites Init")
  local db = _G.DeathNoteDB
  db.version = 2      -- even a wrongly lowered version must not count twice
  S.Init()
  eq(snap(), first, "Version erneut 2")
  eq(S.MigrateRoles(S.Get("Yoron-Pvp"), db.deaths), 0, "nichts mehr umzustellen")
  ns = M.Load({ db = db, keepWorld = true })
  eq(ns.Store.Get("Yoron-Pvp").assists, 2, "nach /reload")
end)

test("Migration: Tat ohne Rolle in einer DB Version 3 bekommt nur die Rolle", function()
  local db = { version = 3, settings = {}, deaths = { { t = 12, kind = "pvp", source = "recap", killerKey = "Alt-B" } },
    enemies = {
    ["Ohne-Quelle"] = { kills = 0, suspected = 1, status = "suspect", deaths = { { t = 12, sure = false } } },
    ["Neu-A"] = { kills = 0, assists = 0, suspected = 1, status = "suspect",
      deaths = { { t = 10, sure = false, source = "recap" } } },
    ["Alt-B"] = { kills = 1, assists = 0, suspected = 1, status = "wanted",
      deaths = { { t = 11, sure = false, source = "suspect" }, { t = 9, sure = true, source = "recap" } } },
  } }
  local ns = M.Load({ db = db })
  local a, b = ns.Store.Get("Neu-A"), ns.Store.Get("Alt-B")
  eq(a.deaths[1].role, "assist"); eq(a.assists, 1); eq(a.suspected, 0); eq(a.status, "wanted")
  eq(roles(b), "suspect,kill"); eq(b.suspected, 1); eq(b.assists, 0)
  local q = ns.Store.Get("Ohne-Quelle")
  eq(q.deaths[1].source, "recap", "fehlende Quelle aus dem Todesjournal (gleiche Zeit)")
  eq(q.deaths[1].role, "assist"); eq(q.status, "wanted")
end)

---------------------------------------------------------------------------
-- Roles of new deaths
---------------------------------------------------------------------------
test("Neuer Tod: Recap-Todesstoß = kill, Recap-Mittäter = assist, Heuristik = suspect", function()
  local ns = M.Load()
  M.recap = { id = 3, events = {
    ev({ guid = "Player-93-B", name = "Helfer Typ", amount = 300 }),
    ev({ guid = "Player-93-A", name = "Moerder Typ", amount = 900, overkill = 10 }),
  } }
  die()
  local S = ns.Store
  eq(S.Get("Moerder-Typ").deaths[1].role, "kill")
  local h = S.Get("Helfer-Typ")
  eq(h.deaths[1].role, "assist"); eq(h.assists, 1); eq(h.status, "wanted")
  -- heuristic: exactly one targeter, no recap
  M.recap = nil
  M.Advance(30)
  M.AddEnemy("nameplate1", { name = "Ziel", surname = "Er", target = "player" })
  M.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate1")
  M.Advance(1)
  die()
  local z = S.Get("Ziel-Er")
  eq(z.deaths[1].role, "suspect"); eq(z.suspected, 1); eq(z.assists, 0); eq(z.status, "suspect")
end)

test("Meter ohne Todesstoß: oberster Spieler nur Verdacht (Meter kann ältere Kämpfe enthalten)", function()
  local ns = M.Load()
  M.meter = { combatSpells = {
    { spellID = 1, totalAmount = 500, overkillAmount = 0, combatSpellDetails = { unitName = "Meter Mann", unitClassFilename = "MAGE", isMob = false, isPet = false, amount = 500 } },
  } }
  die()
  local e = ns.Store.Get("Meter-Mann")
  eq(e.deaths[1].role, "suspect"); eq(e.status, "suspect")
end)

test("ApplyKill: Rolle direkt angegeben gewinnt, sure folgt der Rolle", function()
  local ns = M.Load(); local S = ns.Store
  local k = S.ApplyKill({ name = "Direkt", surname = "A" }, { t = 5, source = "manual", role = "assist" }, true)
  local e = S.Get(k)
  eq(e.deaths[1].role, "assist"); eq(e.deaths[1].sure, false); eq(e.kills, 0); eq(e.assists, 1)
  eq(S.RoleOf(true, "suspect"), "kill"); eq(S.RoleOf(false, "recap"), "assist"); eq(S.RoleOf(false, "meter"), "suspect")
  eq(S.RoleOf(false, nil), "suspect")
end)

---------------------------------------------------------------------------
-- Status transitions, confirm, dismiss, assign
---------------------------------------------------------------------------
local function deed(S, name, t, role)
  return S.ApplyKill({ name = name, surname = "X" }, { t = t, zone = "Z", source = role == "suspect" and "suspect" or "recap" },
    role == "kill")
end

test("Status-Übergänge mit Beteiligung", function()
  local ns = M.Load(); local S = ns.Store
  local k = deed(S, "Wech", 10, "suspect")
  eq(S.Get(k).status, "suspect")
  deed(S, "Wech", 20, "assist")
  eq(S.Get(k).status, "wanted", "Beteiligung macht aus Verdacht einen Gesuchten")
  S.SetStatus(k, "pardoned")
  deed(S, "Wech", 30, "assist")
  eq(S.Get(k).status, "pardoned", "begnadigt bleibt begnadigt"); eq(S.Get(k).assists, 2)
  -- assist only, fresh entry
  local a = deed(S, "Nurbei", 40, "assist")
  eq(S.Get(a).status, "wanted"); eq(S.Get(a).kills, 0)
end)

test("Bestätigen macht aus suspect oder assist einen kill; Verwerfen entfernt nur Verdacht", function()
  local ns = M.Load(); local S = ns.Store
  S.RecordDeath({ t = 100, kind = "pvp", candidates = { "Mix-X" } })
  local k = deed(S, "Mix", 100, "assist")
  deed(S, "Mix", 200, "suspect")
  local e = S.Get(k)
  eq(roles(e), "suspect,assist")
  ok(S.ConfirmSuspect(k, 2), "Beteiligung bestätigen")
  eq(e.kills, 1); eq(e.assists, 0); eq(e.suspected, 1); eq(roles(e), "suspect,kill"); eq(e.deaths[2].sure, true)
  eq(S.Deaths()[1].killerKey, k, "Journal nachgezogen")
  no(S.ConfirmSuspect(k, 2), "schon ein kill")
  ok(S.ConfirmSuspect(k), "ohne Index: der jüngste Nicht-kill")
  eq(e.kills, 2); eq(e.suspected, 0); eq(roles(e), "kill,kill")
  -- dismiss keeps assists
  local b = deed(S, "Bleibt", 300, "assist")
  deed(S, "Bleibt", 310, "suspect")
  ok(S.DismissSuspect(b))
  local be = S.Get(b)
  ok(be, "Beteiligter wird nicht gelöscht"); eq(roles(be), "assist"); eq(be.assists, 1); eq(be.suspected, 0)
  eq(be.status, "wanted")
  -- a pure suspicion still goes away
  local w = deed(S, "Weg", 400, "suspect")
  ok(S.DismissSuspect(w)); no(S.Get(w))
end)

test("AssignDeath: Beteiligung an genau diesem Tod wird zum kill", function()
  local ns = M.Load(); local S = ns.Store
  S.RecordDeath({ t = 500, kind = "pvp", candidates = { "Hand-X", "Neben-X" }, counted = true })
  local k = deed(S, "Hand", 500, "assist")
  deed(S, "Hand", 400, "assist")
  eq(S.OpenCases(), 1)
  ok(S.AssignDeath(1, k))
  local e = S.Get(k)
  eq(e.kills, 1); eq(e.assists, 1); eq(roles(e), "kill,assist"); eq(e.deaths[1].source, "manual")
  eq(S.OpenCases(), 0, "Fall geschlossen")
  -- reassign to someone else: the old kill goes, the new one is a kill
  ok(S.AssignDeath(1, "Neben-X"))
  eq(e.kills, 0); eq(roles(e), "assist"); eq(S.Get("Neben-X").deaths[1].role, "kill")
end)

---------------------------------------------------------------------------
-- Rank, Weight, Bounty
---------------------------------------------------------------------------
test("Rang: kills, dann assists, dann letzter Kill, dann Name", function()
  local ns = M.Load(); local S = ns.Store
  deed(S, "Neu", 900, "kill")                       -- 1 kill, newest
  deed(S, "Mit", 100, "kill"); deed(S, "Mit", 110, "assist"); deed(S, "Mit", 120, "assist")
  deed(S, "Nur", 130, "assist"); deed(S, "Nur", 140, "assist"); deed(S, "Nur", 150, "assist")
  deed(S, "Zwei", 50, "kill"); deed(S, "Zwei", 60, "kill")
  deed(S, "Bb", 70, "assist"); deed(S, "Aa", 70, "assist")
  local r = S.Ranked("wanted", "rank")
  local keys = {}
  for i = 1, #r do keys[i] = r[i].key end
  eq(table.concat(keys, " "), "Zwei-X Mit-X Neu-X Nur-X Aa-X Bb-X")
  eq(S.Rank("Zwei-X"), 1); eq(S.Rank("Mit-X"), 2); eq(S.Rank("Nur-X"), 4)
  deed(S, "Neu", 950, "assist"); deed(S, "Neu", 960, "assist"); deed(S, "Neu", 970, "assist")
  eq(S.Rank("Neu-X"), 2, "Rang-Cache nach Änderung neu")
end)

test("Weight = kills + assists, Bounty rechnet assists moderat und deterministisch ein", function()
  local ns = M.Load(); local S = ns.Store
  eq(S.Weight({ kills = 2, assists = 3 }), 5); eq(S.Weight({ kills = 1 }), 1); eq(S.Weight(nil), 0)
  eq(S.Weight({ kills = 0, assists = 0, suspected = 4 }), 0, "Verdacht wiegt nichts")
  local a = { kills = 1, assists = 0, suspected = 0, revenge = 0, level = 40 }
  local b = { kills = 1, assists = 2, suspected = 0, revenge = 0, level = 40 }
  local c = { kills = 2, assists = 0, suspected = 0, revenge = 0, level = 40 }
  ok(S.Bounty(b) > S.Bounty(a), "Beteiligung erhöht"); ok(S.Bounty(c) > S.Bounty(b), "ein Kill mehr wiegt mehr als zwei Beteiligungen")
  eq(S.Bounty(b), S.Bounty(b)); ok(S.Bounty({ kills = 0, assists = 1 }) >= 10000, "Mindestwert für Beteiligte")
end)

---------------------------------------------------------------------------
-- Open cases and Count()
---------------------------------------------------------------------------
test("OpenCases: eine Zählregel, neueste zuerst, gecacht, Count() vierter Wert", function()
  local ns = M.Load(); local S = ns.Store
  S.RecordDeath({ t = 1, kind = "pvp", candidates = { "A-X" } })                          -- open
  S.RecordDeath({ t = 2, kind = "pvp", candidates = {} })                                  -- no candidate
  S.RecordDeath({ t = 3, kind = "pvp", candidates = { "A-X" }, killerKey = "A-X" })        -- solved
  S.RecordDeath({ t = 4, kind = "pvp", candidates = { "A-X" }, counted = false })          -- not counted
  S.RecordDeath({ t = 5, kind = "pve", candidates = { "A-X" } })                           -- no PvP
  S.RecordDeath({ t = 6, kind = "pvp", candidates = { "B-X", "C-X" }, counted = true })    -- open
  local n, list = S.OpenCases()
  eq(n, 2); eq(list[1].t, 6, "neueste zuerst"); eq(list[2].t, 1)
  local n2, list2 = S.OpenCases()
  ok(list2 == list, "gecacht: dieselbe Liste ohne Änderung")
  eq(select(4, S.Count()), 2)
  S.RecordDeath({ t = 7, kind = "pvp", candidates = { "D-X" } })
  local n3, list3 = S.OpenCases()
  eq(n3, 3); ok(list3 ~= list, "nach Journal-Änderung neu")
  ok(S.AssignDeath(1, "D-X"))
  eq((S.OpenCases()), 2, "Zuweisung schließt den Fall")
  -- journal written from outside: noticed by length / first entry
  table.insert(S.Deaths(), 1, { t = 8, kind = "pvp", candidates = { "E-X" } })
  eq((S.OpenCases()), 3)
  S.Deaths()[1].killerKey = "E-X"; S.TouchJournal()
  eq((S.OpenCases()), 2, "TouchJournal leert den Cache")
  local w, s, p, open = S.Count()
  eq(open, 2); ok(w >= 1)
end)

test("Echter Tod ohne Täter mit Kandidaten ist ein offener Fall", function()
  local ns = M.Load()
  M.AddEnemy("nameplate1", { name = "Eins", surname = "A", target = "player" })
  M.AddEnemy("nameplate2", { name = "Zwei", surname = "B", target = "player" })
  M.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate1"); M.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate2")
  M.Advance(1)
  die()
  local n, list = ns.Store.OpenCases()
  eq(n, 1); eq(list[1], ns.Store.Deaths()[1])
end)

---------------------------------------------------------------------------
-- Export / Import with roles
---------------------------------------------------------------------------
test("Export/Import trägt Rolle und assists; alter Text ohne Rolle wird abgeleitet", function()
  local ns = loadAutor(); local S = ns.Store
  local text = S.Export()
  ok(text:find("|kill\n", 1, true) or text:find("|kill$"), "Rolle in D-Zeilen")
  local ns2 = M.Load({ before = function() M.epoch = AUTOR_NOW - 1000 end }); local S2 = ns2.Store
  ok(S2.Import(text))
  local x = S2.Get("Yoron-Pvp")
  eq(x.kills, 1); eq(x.assists, 2); eq(roles(x), "kill,assist,assist")
  eq(S2.Get("Brenendan-Forever").status, "wanted")
  -- a 1.0.x text: no role, no assists field
  local old = "DEATHNOTE:1\nE|Alt-Text|suspect|0|0|1|0||||0||||||||\nD|Alt-Text|500|0|recap|Z||||||||"
  ok(S2.Import(old))
  local a = S2.Get("Alt-Text")
  eq(a.deaths[1].role, "assist"); eq(a.deaths[1].sure, false); eq(a.assists, 1); eq(a.status, "wanted")
end)

M.done("test_rollen")
