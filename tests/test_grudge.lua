-- 1.4.0 grudge: attacked without dying. The book side (role "attack", Store.AddAttack, never shared, export and
-- import, older clients and an older book), the detection (proofs a, b, c), the episode, the places (open world on,
-- battlegrounds and arenas only with their switch, dungeons never), the five minutes, the answers, the test notice,
-- the probe. All names are made up.
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local M = require("mock_wow")
local test, eq, ok, no = M.test, M.eq, M.ok, M.no
local ROOT = (arg[0]:match("^(.*)/tests/") or ".")
local GitBase = dofile(ROOT .. "/tests/git_base.lua")
local GUILD = "Die Wurstbrueder"

local function noErrors() eq(#M.errors, 0, tostring(M.errors[1])) end

-- a world with the client APIs the notice reads (the base mock has no combat state and no health)
local function load(opts)
  local ns = M.Load(opts)
  _G.UnitAffectingCombat = function(u)
    local x = M.units[u]
    if not x then return false end
    if x.combat == nil then return true end
    return x.combat
  end
  M.hp = 1000
  _G.UnitHealth = function(u) if u == "player" then return M.hp end end
  _G.UnitInParty = function(u) local x = M.units[u]; return x and x.party or false end
  _G.UnitInRaid = function() return nil end
  return ns
end

local function enemy(token, name, surname, o)
  o = o or {}
  o.name, o.surname = name, surname
  o.guid = o.guid or ("Player-93-" .. name)
  if o.target == nil then o.target = "player" end
  if o.target == false then o.target = nil end
  local u = M.AddEnemy(token, o)
  if token:find("^nameplate") then M.FireEvent("NAME_PLATE_UNIT_ADDED", token) end
  return u
end

local function hit(action) M.FireEvent("UNIT_COMBAT", "player", action or "WOUND", "", 120, 1) end
local function fightStart() M.inCombat = true; M.FireEvent("PLAYER_REGEN_DISABLED") end
local function fightEnd() M.inCombat = false; M.FireEvent("PLAYER_REGEN_ENABLED") end
local function keys(ep)
  local out = {}
  for _, r in ipairs(ep and ep.order or {}) do out[#out + 1] = r end
  table.sort(out)
  return table.concat(out, ",")
end

local function attack(ns, name, surname, t, o)
  local info = { name = name, surname = surname, guid = "Player-93-" .. name, class = "ROGUE", level = 40 }
  for k, v in pairs(o or {}) do info[k] = v end
  return ns.Store.AddAttack(info, { t = t or time(), zone = "Schlingendorntal", subzone = "Grom'gol", me = "Varorak Narenmar",
    myLevel = 40 })
end

---------------------------------------------------------------------------
-- Book
---------------------------------------------------------------------------
test("Buch: ein Angriff traegt ein (Gesucht, nicht von Hand, Rolle attack, Quelle grudge, kein Kill)", function()
  local ns = load()
  local key = attack(ns, "Grimm", "Bart")
  eq(key, "Grimm-Bart")
  local e = ns.Store.Get(key)
  eq(e.status, "wanted"); eq(e.manual, false); eq(e.kills, 0); eq(e.assists, 0); eq(e.suspected, 0)
  eq(e.attacks, 1); eq(ns.Store.Attacks(e), 1); eq(ns.Store.OnlyAttacks(e), true)
  eq(#e.deaths, 1); eq(e.deaths[1].role, "attack"); eq(e.deaths[1].source, "grudge"); eq(e.deaths[1].sure, false)
  eq(e.class, "ROGUE"); eq(e.guid, "Player-93-Grimm")
  -- the same fight twice: one deed; another fight: the count goes on
  attack(ns, "Grimm", "Bart", e.deaths[1].t)
  eq(e.attacks, 1); eq(#e.deaths, 1)
  attack(ns, "Grimm", "Bart", time() + 1)
  eq(e.attacks, 2); eq(#e.deaths, 2)
  -- under Wanted (the list of the book)
  local found = false
  for _, x in ipairs(ns.Store.Ranked("wanted")) do if x.key == key then found = true end end
  ok(found, "unter Gesucht")
  noErrors()
end)

test("Buch: Angriffe verdraengen keine Kills (hoechstens 5 Angriffs-Taten, die Zahl zaehlt weiter)", function()
  local ns = load()
  local t0 = time() - 1000
  ns.Store.ApplyKill({ name = "Grimm", surname = "Bart", guid = "Player-93-Grimm" }, { t = t0, zone = "Z", source = "recap" }, true)
  for i = 1, 8 do attack(ns, "Grimm", "Bart", t0 + i * 10) end
  local e = ns.Store.Get("Grimm-Bart")
  local nA, nK = 0, 0
  for _, d in ipairs(e.deaths) do if d.role == "attack" then nA = nA + 1 elseif d.role == "kill" then nK = nK + 1 end end
  eq(nA, 5); eq(nK, 1); eq(e.attacks, 8); eq(e.kills, 1)
  eq(ns.Store.OnlyAttacks(e), false)
  -- newest first
  eq(e.deaths[1].t, t0 + 80)
end)

test("Buch: Verdaechtiger wird mit Angriff gesucht, Begnadigter bleibt begnadigt", function()
  local ns = load()
  ns.Store.ApplyKill({ name = "Fies", surname = "Ling" }, { t = time() - 50, zone = "Z", source = "suspect" }, false)
  eq(ns.Store.Get("Fies-Ling").status, "suspect")
  attack(ns, "Fies", "Ling")
  eq(ns.Store.Get("Fies-Ling").status, "wanted")
  attack(ns, "Ruhig", "Blut")
  ns.Store.SetStatus("Ruhig-Blut", "pardoned")
  attack(ns, "Ruhig", "Blut", time() + 5)
  eq(ns.Store.Get("Ruhig-Blut").status, "pardoned")
end)

test("Buch: ein Angriff wird nie zum Kill (Bestaetigen, Zuordnen), Verdacht verwerfen loescht ihn nicht", function()
  local ns = load()
  local key = attack(ns, "Grimm", "Bart")
  eq(ns.Store.ConfirmSuspect(key), false, "kein Kill aus einem Angriff")
  eq(ns.Store.ConfirmSuspect(key, 1), false)
  local e = ns.Store.Get(key)
  eq(e.kills, 0); eq(e.deaths[1].role, "attack")
  ns.Store.DismissSuspect(key)
  ok(ns.Store.Get(key), "Eintrag bleibt"); eq(ns.Store.Get(key).attacks, 1)
  -- a death of the same second assigned to him: the attack stays, a kill comes on top
  local t = e.deaths[1].t
  ns.Store.RecordDeath({ t = t, kind = "pvp", candidates = { key }, counted = true, me = "Varorak Narenmar" })
  ok(ns.Store.AssignDeath(1, key))
  local nA, nK = 0, 0
  for _, d in ipairs(e.deaths) do if d.role == "attack" then nA = nA + 1 elseif d.role == "kill" then nK = nK + 1 end end
  eq(nA, 1); eq(nK, 1); eq(e.kills, 1); eq(e.attacks, 1)
end)

test("Rache zaehlt: Todesstoss an einem, der nur angegriffen hat", function()
  local ns = load()
  local key = attack(ns, "Grimm", "Bart")
  M.AddEnemy("target", { name = "Grimm", surname = "Bart", guid = "Player-93-Grimm" })
  M.FireEvent("PLAYER_TARGET_CHANGED")
  M.FireEvent("PARTY_KILL", M.units.player.guid, "Player-93-Grimm")
  eq(ns.Store.Get(key).revenge, 1)
  local mine, his, state = ns.Ledger.Standing(key)
  eq(mine, 1); eq(his, 0); eq(state, "ahead")
end)

---------------------------------------------------------------------------
-- Never shared
---------------------------------------------------------------------------
test("Nie geteilt: ein Angriff geht weder an die Gilde noch an Freunde (ein Kill schon)", function()
  M.Reset()
  local W = M.NewWorld()
  local a = W.client("Anton", "Wurst", GUILD, { friends = { "Berta" } })
  local b = W.client("Berta", "Senf", GUILD, { friends = { "Anton" } })
  local c = W.client("Carla", "Kraut", nil, { friends = { "Anton" } })
  a.login(); b.login(); c.login(); W.run(60)
  local t = time()
  a.ns.Store.AddAttack({ name = "Grimm", surname = "Bart", guid = "Player-93-Grimm", class = "ROGUE", level = 40 },
    { t = t, zone = "Schlingendorntal", me = "Anton Wurst", myLevel = 40 })
  -- control: a kill of the same moment goes out
  local me = "Anton Wurst"
  local kk = a.ns.Store.ApplyKill({ name = "Fies", surname = "Ling", class = "MAGE", level = 36 },
    { t = t, zone = "Schlingendorntal", me = me, myLevel = 34, source = "recap", others = {} }, true)
  a.ns:Fire("DEATH_RECORDED", { t = t, zone = "Schlingendorntal", me = me, kind = "pvp", sure = true, counted = true,
    killerKey = kk, source = "recap" }, kk)
  W.run(5)
  a.ns.Guild.SyncNow(); if a.ns.Friends and a.ns.Friends.SyncNow then a.ns.Friends.SyncNow() end
  W.run(120)
  ok(b.ns.Guild.Get(kk), "Kontrolle: Kill in der Gilde")
  no(b.ns.Guild.Get("Grimm-Bart", "all"), "Angriff nicht bei der Gilde")
  no(c.ns.Guild.Get("Grimm-Bart", "all"), "Angriff nicht beim Freund")
  for _, m in ipairs(W.sent) do no(tostring(m.text):find("Grimm", 1, true), "nichts auf der Leitung: " .. tostring(m.text)) end
  eq(#a.ns.Guild.OwnListed(50, false), 0, "nicht als von Hand gelistet")
  eq(#M.errors, 0, tostring(M.errors[1]))
end)

---------------------------------------------------------------------------
-- Export / import, older clients, older books
---------------------------------------------------------------------------
test("Export/Import: Rolle und Zahl der Angriffe reisen mit; alte Texte ohne Feld lesen sich", function()
  local ns = load()
  attack(ns, "Grimm", "Bart", time() - 100)
  attack(ns, "Grimm", "Bart", time() - 50)
  local text = ns.Store.Export()
  ok(text:find("|grudge|", 1, true), "Quelle im Text")
  ok(text:find("|attack\n", 1, true) or text:find("|attack$"), "Rolle im Text")
  local eline = text:match("\nE|Grimm%-Bart|[^\n]*")
  ok(eline and eline:match("|2$"), "Zahl der Angriffe am Ende der E-Zeile: " .. tostring(eline))
  local ns2 = load()
  local okI, added = ns2.Store.Import(text)
  ok(okI); eq(added, 1)
  local e = ns2.Store.Get("Grimm-Bart")
  eq(e.attacks, 2); eq(e.status, "wanted"); eq(e.manual, false); eq(e.imported, true)
  eq(#e.deaths, 2); eq(e.deaths[1].role, "attack"); eq(e.deaths[1].source, "grudge")
  -- a text whose E line has no attacks field (cut / older): the deeds count
  local cut = text:gsub("(\nE|Grimm%-Bart|[^\n]*)|2", "%1")
  local ns3 = load()
  ok(ns3.Store.Import(cut))
  eq(ns3.Store.Get("Grimm-Bart").attacks, 2)
  -- an attack that an older client wrote back as a suspicion (role suspect, source grudge) is an attack again
  local old = text:gsub("|attack", "|suspect")
  local ns4 = load()
  ok(ns4.Store.Import(old))
  local e4 = ns4.Store.Get("Grimm-Bart")
  eq(e4.deaths[1].role, "attack"); eq(e4.suspected, 0); eq(e4.attacks, 2)
end)

test("Alte Daten: Buch von 1.0.1 (Fixture) wird Version 5, nichts geht verloren, kein Angriff entsteht", function()
  local fx = assert(loadfile(ROOT .. "/tests/fixtures/sv_1.0.1_autor.lua"))
  local env = {}
  setfenv(fx, env); fx()
  local raw = env.DeathNoteDB
  local n0 = 0
  for _ in pairs(raw.enemies) do n0 = n0 + 1 end
  local ns = load({ db = raw })
  local db = _G.DeathNoteDB
  eq(db.version, 5)
  local n1, att = 0, 0
  for _, e in pairs(db.enemies) do
    n1 = n1 + 1
    att = att + ns.Store.Attacks(e)
    for _, d in ipairs(e.deaths) do no(d.role == "attack", "keine Angriffs-Tat aus alten Daten") end
  end
  eq(n1, n0); eq(att, 0)
  eq(db.settings.grudge.enabled, true); eq(db.settings.grudge.battlegrounds, false); eq(db.settings.grudge.seconds, 20)
  noErrors()
end)

test("Version 5: ein Buch von 1.3.x (Version 4) ohne gewaehlten Ton behaelt den Vorschlag des Einbands", function()
  load({ db = { version = 4, settings = { welcomed = true, alert = { volume = 3 } }, enemies = {}, deaths = {} } })
  eq(_G.DeathNoteDB.version, 5)
  eq(_G.DeathNoteDB.settings.alert.soundKey, nil, "kein Ton erzwungen (nur Buecher vor Version 4 bekommen \"warnung\")")
  load({ db = { version = 3, settings = { welcomed = true }, enemies = {}, deaths = {} } })
  eq(_G.DeathNoteDB.settings.alert.soundKey, "warnung", "Version 3 wie bisher")
end)

test("Mit 1.3.1 hin und zurueck: der alte Client liest Angriffe ohne Fehler, danach sind sie wieder Angriffe", function()
  local dir, why = GitBase.Archive(ROOT, "v1.3.1")
  if not dir then GitBase.Skip("grudge", "up and back with 1.3.1 (" .. tostring(why) .. ")"); return end
  M.Reset()
  local W = M.NewWorld()
  local function out(c)
    c.fire("PLAYER_LOGOUT")
    local db = c.env.DeathNoteDB
    c.loggedIn = false
    for i = #W.clients, 1, -1 do if W.clients[i] == c then table.remove(W.clients, i) end end
    return db
  end
  local c = W.client("Anton", "Wurst", nil, {})
  c.login(); W.run(2)
  local t = time()
  c.ns.Store.AddAttack({ name = "Grimm", surname = "Bart", guid = "Player-93-Grimm", class = "ROGUE", level = 40 },
    { t = t - 30, zone = "Z", me = "Anton Wurst" })
  c.ns.Store.AddAttack({ name = "Grimm", surname = "Bart", guid = "Player-93-Grimm" }, { t = t - 10, zone = "Z", me = "Anton Wurst" })
  local text = c.ns.Store.Export()
  local db = out(c)
  eq(db.version, 5)
  -- the old client (files of the tag, without Grudge.lua)
  local oldFiles = {}
  for _, f in ipairs(M.FILES) do if f ~= "Grudge.lua" then oldFiles[#oldFiles + 1] = f end end
  local o = W.client("Anton", "Wurst", nil, { db = db, dir = dir, files = oldFiles, version = "1.3.1" })
  o.login(); W.run(2)
  eq(#M.errors, 0, tostring(M.errors[1]))
  local oe = o.ns.Store.Get("Grimm-Bart")
  ok(oe, "der alte Client kennt den Eintrag"); eq(oe.kills, 0); eq(oe.suspected, 0, "keine Verdachtsfaelle dazugezaehlt")
  eq(oe.status, "wanted")
  -- the old client reads the new text too
  local o2 = W.client("Otto", "Alt", nil, { dir = dir, files = oldFiles, version = "1.3.1" })
  o2.login(); W.run(2)
  local okI = o2.ns.Store.Import(text)
  ok(okI, "alter Import liest den neuen Text")
  db = out(o)
  out(o2)
  eq(db.version, 5, "der alte Client senkt die Version nicht")
  -- back up again
  local n = W.client("Anton", "Wurst", nil, { db = db })
  n.login(); W.run(2)
  local e = n.ns.Store.Get("Grimm-Bart")
  eq(e.attacks, 2); eq(e.suspected, 0); eq(e.kills, 0); eq(e.status, "wanted")
  for _, d in ipairs(e.deaths) do eq(d.role, "attack"); eq(d.source, "grudge") end
  eq(#M.errors, 0, tostring(M.errors[1]))
  GitBase.Clean()
end)

---------------------------------------------------------------------------
-- Detection: proof a
---------------------------------------------------------------------------
local G = function(ns) return ns.Grudge end

test("Beleg a: hat mich im Ziel, im Kampf, ich werde getroffen -> Angreifer der Episode", function()
  local ns = load()
  M.ClearFired()
  enemy("nameplate1", "Grimm", "Bart", { level = 38, class = "ROGUE" })
  no(G(ns).Current(), "ohne Treffer keine Episode")
  fightStart(); hit()
  local ep = G(ns).Current()
  ok(ep, "Episode"); eq(keys(ep), "Grimm-Bart")
  local r = ep.rows["Grimm-Bart"]
  eq(r.level, 38); eq(r.class, "ROGUE"); eq(r.proofs.a, true); eq(r.kb, nil); eq(r.inBook, nil)
  eq(ep.running, true)
  ok(G(ns).Asks(ep))
  no(ns.Store.Get("Grimm-Bart"), "nichts im Buch ohne Haken")
  noErrors()
end)

test("Beleg a: nicht ohne Treffer, nicht ohne Ziel auf mir, nicht ausser Kampf, nicht Gruppe, nicht freundlich", function()
  local ns = load()
  fightStart()
  enemy("nameplate1", "Ohne", "Ziel", { target = false })
  enemy("nameplate2", "Ohne", "Kampf", { combat = false })
  enemy("nameplate3", "In", "Gruppe", { party = true })
  enemy("nameplate4", "Ganz", "Lieb", { canAttack = false, enemy = false, friend = true })
  hit()
  no(G(ns).Current(), "keiner davon ist ein Angreifer")
  -- a heal is no hit
  M.Advance(3)
  enemy("nameplate5", "Grimm", "Bart")
  M.Advance(1)
  M.FireEvent("UNIT_COMBAT", "player", "HEAL", "", 50, 1)
  no(G(ns).Current(), "Heilung ist kein Treffer")
  M.Advance(1); hit()
  eq(keys(G(ns).Current()), "Grimm-Bart")
end)

test("Beleg a: Lebenspunkte sinken (UNIT_HEALTH) zaehlen als Treffer; steigen nicht", function()
  local ns = load()
  fightStart()
  enemy("nameplate1", "Grimm", "Bart")
  M.FireEvent("UNIT_HEALTH", "player")       -- first read
  M.hp = 1100; M.FireEvent("UNIT_HEALTH", "player")
  no(G(ns).Current(), "mehr Leben ist kein Treffer")
  M.hp = 900; M.FireEvent("UNIT_HEALTH", "player")
  eq(keys(G(ns).Current()), "Grimm-Bart")
end)

test("Beleg a: Treffer zuerst, Angreifer taucht bis 2 s spaeter auf; nach 3 s nicht mehr", function()
  local ns = load()
  fightStart(); hit()
  M.Advance(1.5)
  enemy("nameplate1", "Grimm", "Bart")
  eq(keys(G(ns).Current()), "Grimm-Bart")
  M.Advance(3)
  enemy("nameplate2", "Spaet", "Dran")
  eq(keys(G(ns).Current()), "Grimm-Bart", "zu spaet")
end)

-- 1.5.0 grip: before, a cast alone (he has me targeted) was proof a; now it is signal s and only beside a hit
test("Beleg s: ein Zauber allein oeffnet nichts; mit Treffer im Fenster ist er Beleg s neben a; Gruppen: alle", function()
  local ns = load()
  fightStart()
  enemy("nameplate1", "Grimm", "Bart")
  enemy("nameplate2", "Fies", "Ling")
  enemy("nameplate3", "Dritter", "Mann")
  M.FireEvent("UNIT_SPELLCAST_START", "nameplate2", "cast-1", 118)
  no(G(ns).Current(), "ein Zauber ohne Treffer ist kein Beleg (Selbst-Buff, Reiten)")
  eq(G(ns).ProbeSnapshot().counts.castAlone, 1)
  M.Advance(1); hit()
  local ep = G(ns).Current()
  eq(keys(ep), "Dritter-Mann,Fies-Ling,Grimm-Bart", "alle Angreifer der Gruppe")
  eq(ep.rows["Fies-Ling"].proofs.s, true, "Zauber 1 s vor dem Treffer: s")
  eq(ep.rows["Fies-Ling"].proofs.a, true)
  eq(ep.rows["Grimm-Bart"].proofs.s, nil)
  -- a cast right after a hit: s at once
  M.Advance(0.5)
  M.FireEvent("UNIT_SPELLCAST_SUCCEEDED", "nameplate1", "cast-2", 118)
  eq(ep.rows["Grimm-Bart"].proofs.s, true)
  eq(ep.rows["Grimm-Bart"].cast, true)
end)

test("Secrets: Name, Ziel, Aktion secret -> kein Fehler, nichts Falsches", function()
  local ns = load()
  fightStart()
  enemy("nameplate1", "Grimm", "Bart", { targetsMeSecret = true })
  local u = enemy("nameplate2", "Fies", "Ling")
  u.name = M.Secret("name")
  M.FireEvent("UNIT_COMBAT", "player", M.Secret("action"), "", M.Secret("amount", "number"), 1)
  no(G(ns).Current(), "secret Ziel und secret Name zaehlen nicht")
  enemy("nameplate3", "Klar", "Sicht")
  M.Advance(1)
  M.FireEvent("UNIT_COMBAT", "player", M.Secret("action"), "", 1, 1)
  eq(keys(G(ns).Current()), "Klar-Sicht", "eine secret Aktion zaehlt als Treffer")
  no(M.ContainsSecret(_G.DeathNoteDB), "kein Secret in der DB")
  noErrors()
end)

---------------------------------------------------------------------------
-- Places
---------------------------------------------------------------------------
test("Orte: offene Welt an; Schlachtfeld und Arena nur mit Schalter (Standard aus); Dungeon nie", function()
  local ns = load()
  eq(ns.Store.Setting("grudge.battlegrounds"), false, "Standard aus")
  local function try(kind, label)
    G(ns).Reset()
    M.instance = kind and { true, kind } or { false, "none" }
    M.FireEvent("ZONE_CHANGED_NEW_AREA")
    fightStart()
    enemy("nameplate1", "Grimm", "Bart")
    M.Advance(1); hit()
    local got = G(ns).Current() ~= nil
    fightEnd()
    if G(ns).Current() then G(ns).Close("test") end
    return got
  end
  eq(try(nil), true, "offene Welt")
  eq(try("pvp"), false, "Schlachtfeld, Schalter aus")
  eq(try("arena"), false, "Arena, Schalter aus")
  ns.Store.Setting("grudge.battlegrounds", true)
  eq(try("pvp"), true, "Schlachtfeld, Schalter an")
  eq(try("arena"), true, "Arena, Schalter an")
  eq(try("party"), false, "Dungeon nie")
  eq(try("raid"), false, "Schlachtzug nie")
  ns.Store.Setting("grudge.enabled", false)
  eq(try(nil), false, "ganz aus")
  -- switched off while an episode is open: it closes, nothing entered
  ns.Store.Setting("grudge.enabled", true)
  G(ns).Reset(); M.instance = { false, "none" }; M.FireEvent("ZONE_CHANGED_NEW_AREA")
  fightStart(); enemy("nameplate1", "Grimm", "Bart"); M.Advance(1); hit()
  ok(G(ns).Current())
  M.instance = { true, "party" }; M.FireEvent("ZONE_CHANGED_NEW_AREA")
  no(G(ns).Current(), "im Dungeon geschlossen")
  no(ns.Store.Get("Grimm-Bart"))
end)

test("Duell: der Duellpartner (eigene Fraktion) ist kein Angreifer; ein Fremder schon", function()
  local ns = load()
  fightStart()
  M.FireEvent("DUEL_REQUESTED")
  enemy("nameplate1", "Duell", "Partner", { faction = "Horde" })
  enemy("nameplate2", "Grimm", "Bart", { faction = "Alliance" })
  hit()
  eq(keys(G(ns).Current()), "Grimm-Bart")
end)

---------------------------------------------------------------------------
-- Episode, answers, five minutes
---------------------------------------------------------------------------
test("Episode: endet mit dem Kampf; ein neuer Angreifer danach laesst sie weiterlaufen", function()
  local ns = load()
  fightStart(); enemy("nameplate1", "Grimm", "Bart"); hit()
  local ep = G(ns).Current()
  fightEnd()
  eq(ep.running, false); ok(ep.endGT)
  M.Advance(3)
  fightStart(); enemy("nameplate2", "Fies", "Ling"); M.Advance(1); hit()
  eq(G(ns).Current(), ep, "dieselbe Meldung"); eq(ep.running, true)
  eq(keys(ep), "Fies-Ling,Grimm-Bart")
  -- the end of the fight is never announced: the safety net ends the episode
  M.inCombat = false
  M.Advance(6)
  eq(ep.running, false)
end)

test("Antworten: Haken traegt ein, Kreuz nicht; beide nicht erneut gefragt fuer 5 Minuten", function()
  local ns = load()
  fightStart(); enemy("nameplate1", "Grimm", "Bart"); enemy("nameplate2", "Fies", "Ling"); hit(); fightEnd()
  eq(G(ns).Answer("Grimm-Bart", true), true)
  eq(G(ns).Answer("Grimm-Bart", true), false, "zweiter Klick zaehlt nicht")
  eq(G(ns).Answer("Fies-Ling", false), true)
  local e = ns.Store.Get("Grimm-Bart")
  ok(e); eq(e.attacks, 1); eq(e.deaths[1].zone, "Schlingendorntal"); eq(e.deaths[1].me, "Varorak Narenmar")
  no(ns.Store.Get("Fies-Ling"), "Kreuz traegt nichts ein")
  no(G(ns).Asks(), "alles beantwortet")
  G(ns).Close("done")
  no(G(ns).Current())
  -- 4 minutes later: no new question for either
  M.Advance(240)
  fightStart(); M.Advance(1); hit()
  no(G(ns).Current(), "innerhalb von 5 Minuten nicht erneut")
  fightEnd()
  M.Advance(70)
  fightStart(); hit()
  eq(keys(G(ns).Current()), "Fies-Ling,Grimm-Bart", "nach 5 Minuten wieder")
end)

test("Ablauf: weg = nicht eingetragen und 5 Minuten Ruhe", function()
  local ns = load()
  fightStart(); enemy("nameplate1", "Grimm", "Bart"); hit(); fightEnd()
  G(ns).Close("time")
  no(ns.Store.Get("Grimm-Bart"))
  M.Advance(10); fightStart(); hit()
  no(G(ns).Current(), "nicht sofort wieder")
end)

---------------------------------------------------------------------------
-- Proof b: death; proof c: meter
---------------------------------------------------------------------------
local function recapEv(o)
  return { sourceGUID = o.guid, sourceName = o.name, amount = o.amount or 100, overkill = o.overkill or -1,
    timestamp = time() - 1, spellName = "Hieb" }
end

test("Beleg b, offene Welt: Todesstoss markiert, wer durch den Tod im Buch steht ohne Frage, Gesehene ohne Recap fragen", function()
  local ns = load()
  fightStart()
  enemy("nameplate1", "Grimm", "Bart")
  enemy("nameplate3", "Nur", "Gesehen")
  hit()
  M.recap = { id = 3, events = {
    recapEv({ guid = "Player-93-Fies", name = "Fies Ling", amount = 900, overkill = 50 }),
    recapEv({ guid = "Player-93-Grimm", name = "Grimm Bart", amount = 300 }),
  } }
  M.FireEvent("PLAYER_DEAD"); M.inCombat = false; M.FireEvent("PLAYER_REGEN_ENABLED")
  ok(G(ns).Current().running, "wartet auf die Auswertung des Todes")
  M.Advance(5)
  local ep = G(ns).Current()
  eq(keys(ep), "Fies-Ling,Grimm-Bart,Nur-Gesehen")
  local kb, gb, ng = ep.rows["Fies-Ling"], ep.rows["Grimm-Bart"], ep.rows["Nur-Gesehen"]
  eq(kb.kb, true); eq(kb.inBook, true); eq(kb.proofs.b, true)
  eq(gb.inBook, true); eq(gb.kb, nil)
  eq(ng.inBook, nil); ok(G(ns).Open(ng))
  eq(ep.death, true); eq(ep.running, false)
  eq(G(ns).Rows(ep)[1].key, "Fies-Ling", "Todesstoss zuerst")
  -- only the killer and the helper in the book by the death; the one only seen waits for the tick
  eq(ns.Store.Get("Fies-Ling").kills, 1); eq(ns.Store.Get("Grimm-Bart").assists, 1); no(ns.Store.Get("Nur-Gesehen"))
  eq(G(ns).Answer("Fies-Ling", true), false, "im Buch: keine Frage")
  noErrors()
end)

test("Beleg b, offene Welt, alle durch den Tod im Buch: keine Frage (die Todes-Meldung reicht)", function()
  local ns = load()
  local ep
  ns:On("GRUDGE_UPDATE", function(e) ep = ep or e end)
  M.recap = { id = 4, events = { recapEv({ guid = "Player-93-Fies", name = "Fies Ling", amount = 900, overkill = 50 }) } }
  M.FireEvent("PLAYER_DEAD"); M.Advance(5)
  ok(ep); eq(keys(ep), "Fies-Ling"); no(G(ns).Asks(ep))
  -- 1.4.0 fixer: nothing to ask, so the episode is over at once (it used to stay open until /reload)
  eq(ep.closed, true); eq(ep.closedBy, "none"); eq(G(ns).Current(), nil)
end)

test("Beleg b, Schlachtfeld mit Schalter: niemand kommt von selbst ins Buch, alle werden gefragt, Todesstoss markiert", function()
  local ns = load()
  ns.Store.Setting("grudge.battlegrounds", true)
  M.instance = { true, "pvp" }; M.FireEvent("ZONE_CHANGED_NEW_AREA")
  M.recap = { id = 5, events = {
    recapEv({ guid = "Player-93-Fies", name = "Fies Ling", amount = 900, overkill = 50 }),
    recapEv({ guid = "Player-93-Grimm", name = "Grimm Bart", amount = 300 }),
  } }
  M.FireEvent("PLAYER_DEAD"); M.Advance(5)
  local ep = G(ns).Current()
  eq(keys(ep), "Fies-Ling,Grimm-Bart")
  eq(ep.rows["Fies-Ling"].kb, true); eq(ep.rows["Fies-Ling"].inBook, nil)
  ok(G(ns).Asks(ep))
  no(ns.Store.Get("Fies-Ling"), "Schlachtfeld: kein Eintrag durch den Tod")
  G(ns).Answer("Fies-Ling", true)
  eq(ns.Store.Get("Fies-Ling").attacks, 1); eq(ns.Store.Get("Fies-Ling").kills, 0)
end)

test("Beleg b: Schlachtfeld ohne Schalter: keine Episode beim Tod", function()
  local ns = load()
  M.instance = { true, "pvp" }; M.FireEvent("ZONE_CHANGED_NEW_AREA")
  M.recap = { id = 6, events = { recapEv({ guid = "Player-93-Fies", name = "Fies Ling", amount = 900, overkill = 50 }) } }
  M.FireEvent("PLAYER_DEAD"); M.Advance(5)
  no(G(ns).Current())
end)

test("Beleg c: Schadensanzeige nach dem Kampf ergaenzt eine offene Episode, startet keine; secret = nichts", function()
  local ns = load()
  M.meter = { combatSpells = { { totalAmount = 400, spellID = 1, combatSpellDetails = {
    { unitName = "Unsicht Bar", unitClassFilename = "ROGUE", isMob = false, amount = 400 } } } } }
  fightStart(); hit(); fightEnd()
  no(G(ns).Current(), "die Anzeige allein startet keine Episode")
  eq(G(ns).ProbeSnapshot().counts.meterOnly, 1)
  fightStart(); enemy("nameplate1", "Grimm", "Bart"); hit(); fightEnd()
  local ep = G(ns).Current()
  eq(keys(ep), "Grimm-Bart,Unsicht-Bar")
  eq(ep.rows["Unsicht-Bar"].proofs.c, true)
  G(ns).Close("time")
  M.meter = M.SecretTable()
  M.Advance(400)
  fightStart(); hit(); fightEnd()
  eq(keys(G(ns).Current()), "Grimm-Bart", "secret: nur der Gesehene")
  eq(G(ns).ProbeSnapshot().meter, "secret")
  noErrors()
end)

---------------------------------------------------------------------------
-- Test notice, slash, probe
---------------------------------------------------------------------------
test("/dn rachsucht an/aus, /dn grudge test: Probe-Meldung traegt nichts ein", function()
  local ns = load()
  ns.HandleSlash("rachsucht")
  eq(ns.Store.Setting("grudge.enabled"), false)
  ok(M.chat[#M.chat]:find("Rachsucht aus", 1, true), M.chat[#M.chat])
  ns.HandleSlash("grudge")
  eq(ns.Store.Setting("grudge.enabled"), true)
  ns.HandleSlash("grudge test")
  local ep = G(ns).Current()
  ok(ep and ep.test); eq(#ep.order, 3)
  for _, k in ipairs(ep.order) do G(ns).Answer(k, true) end
  for _, k in ipairs(ep.order) do no(ns.Store.Get(k), "Probe: nichts im Buch") end
  local n = 0
  for _ in pairs(ns.Store.All()) do n = n + 1 end
  eq(n, 0)
end)

test("Sonde: probe.grudge mit Belegen, Episoden, Antworten, Anzeige lesbar", function()
  local ns = load()
  fightStart(); enemy("nameplate1", "Grimm", "Bart"); hit(); fightEnd()
  G(ns).Answer("Grimm-Bart", false)
  ns.Store.Setting("debug", true)
  G(ns).Close("done")
  ns.Probe.Run(false)
  local p = _G.DeathNoteDB.probe.grudge
  ok(p); eq(p.counts.episodes, 1); eq(p.counts.a, 1); eq(p.counts.no, 1); eq(p.allowed, true); eq(p.where, "world")
  eq(p.events.UNIT_COMBAT, true)
  eq(#p.cases, 1); eq(p.cases[1].proofs, "a"); eq(p.cases[1].no, 1)
  eq(_G.DeathNoteDB.probe.events.UNIT_COMBAT, true)
  -- the cases stay at the next probe
  ns.Probe.Run(false)
  eq(#_G.DeathNoteDB.probe.grudge.cases, 1)
  no(M.ContainsSecret(_G.DeathNoteDB))
end)

M.done("test_grudge")
