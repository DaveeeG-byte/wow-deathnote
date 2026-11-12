package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local M = require("mock_wow")
local test, eq, ok, no = M.test, M.eq, M.ok, M.no

local function ev(o)
  return { sourceGUID = o.guid, sourceName = o.name, amount = o.amount or 100, overkill = o.overkill or -1,
    timestamp = o.ts or (time() - 1), spellName = o.spell or "Hieb", hideCaster = o.hide }
end

local function die()
  M.FireEvent("PLAYER_DEAD")
  M.Advance(5)
end

local function lastJournal(ns) return ns.Store.Deaths()[1] end

local function noSecretsInDB()
  no(M.ContainsSecret(_G.DeathNoteDB), "Secret in DeathNoteDB")
end

---------------------------------------------------------------------------
-- Pure decision
---------------------------------------------------------------------------
local ns0 = M.Load()
local A0 = ns0.Attribution
local ctx0 = { myGUID = "Player-93-ME", myKey = "Varorak-Narenmar",
  lookupGUID = function() return nil end, lookupName = function() return nil end }

test("Classify: Spieler-GUID, Kreatur, Pet, Name ohne Beleg, ich selbst", function()
  local c = A0.Classify({ guid = "Player-93-1", name = "Grimm Bart", amount = 5 }, ctx0)
  eq(c.isPlayer, true); eq(c.key, "Grimm-Bart")
  c = A0.Classify({ guid = "Creature-0-1-2-3-4", name = "Raptor" }, ctx0)
  eq(c.isPlayer, false); no(c.key)
  c = A0.Classify({ guid = "Pet-0-1", name = "Wolf" }, ctx0)
  eq(c.isPlayer, false); eq(c.isPet, true)
  c = A0.Classify({ name = "Grimm Bart" }, ctx0)
  eq(c.isPlayer, nil, "Name allein reicht nicht")
  c = A0.Classify({ name = "Grimm", class = "ROGUE", isMob = false }, ctx0)
  eq(c.isPlayer, true, "Meter: Klasse + kein Mob")
  no(A0.Classify({ guid = "Player-93-ME", name = "Varorak" }, ctx0))
  c = A0.Classify({ guid = "Player-93-1" }, ctx0)
  eq(c.isPlayer, nil, "Spieler-GUID ohne Namen: nicht verwertbar")
end)

local function src(key, o)
  local n, s = key:match("^(.-)%-(.+)$")
  local r = { key = key, info = { name = n, surname = s }, isPlayer = true, amount = o and o.amount or 10, kb = o and o.kb }
  if o then for k, v in pairs(o) do r[k] = v end end
  return r
end

test("Decide: Todesstoß Spieler -> sicher, Mittäter in others", function()
  local r = A0.Decide({ { stage = "recap", ok = true, sources = {
    src("A-X", { amount = 50 }), src("B-Y", { amount = 500, kb = true }), src("A-X", { amount = 60 }),
    { isPlayer = false, amount = 999 } } } }, nil)
  eq(r.kind, "pvp"); eq(r.killerKey, "B-Y"); eq(r.sure, true); eq(r.source, "recap")
  eq(#r.others, 1); eq(r.others[1], "A-X"); ok(r.othersInfo["A-X"])
end)

test("Decide: Todesstoß Mob -> pve, Spieler nur Kandidaten", function()
  local r = A0.Decide({ { stage = "recap", ok = true, sources = {
    { isPlayer = false, kb = true, amount = 1 }, src("A-X") } } })
  eq(r.kind, "pve"); no(r.killerKey); eq(r.candidates[1], "A-X")
end)

test("Decide: Todesstoß Pet ohne Besitzer -> Verdacht auf stärksten Spieler", function()
  local r = A0.Decide({ { stage = "recap", ok = true, sources = {
    { isPlayer = false, isPet = true, kb = true }, src("A-X", { amount = 5 }), src("B-Y", { amount = 50 }) } } })
  eq(r.kind, "pvp"); eq(r.killerKey, "B-Y"); eq(r.sure, false)
end)

test("Decide: Pet mit bekanntem Besitzer -> Besitzer sicher", function()
  local r = A0.Decide({ { stage = "recap", ok = true, sources = {
    { isPlayer = false, isPet = true, kb = true, ownerKey = "Jae-Ger", ownerInfo = { name = "Jae", surname = "Ger" } } } } })
  eq(r.killerKey, "Jae-Ger"); eq(r.sure, true)
end)

test("Decide: Meter ohne Spieler/Todesstoß entscheidet nicht, Heuristik greift", function()
  local r = A0.Decide({ { stage = "recap", ok = false }, { stage = "meter", ok = true, sources = { { isPlayer = false, amount = 3 } } } },
    { targeters = { { key = "Einer-X", info = { name = "Einer", surname = "X" } } }, recent = {} })
  eq(r.source, "suspect"); eq(r.killerKey, "Einer-X"); eq(r.sure, false); eq(r.kind, "pvp")
end)

test("Decide: zwei im Ziel -> kein Täter, beide Kandidaten", function()
  local r = A0.Decide({}, { targeters = { { key = "A-X", info = {} }, { key = "B-Y", info = {} } }, recent = {} })
  eq(r.kind, "pvp"); no(r.killerKey); eq(#r.candidates, 2)
end)

test("Decide: niemand -> unknown; Heuristik abschaltbar", function()
  eq(A0.Decide({}, { targeters = {}, recent = {} }).kind, "unknown")
  local r = A0.Decide({}, { targeters = { { key = "A-X", info = {} } } }, { suspect = false })
  no(r.killerKey)
end)

test("FormatToPattern", function()
  local p = A0.FormatToPattern("Ihr habt %s getötet!")
  eq(("Ihr habt Grimm Bart getötet!"):match(p), "Grimm Bart")
  p = A0.FormatToPattern("%s stirbt.")
  eq(("Grimm stirbt."):match(p), "Grimm")
  p = A0.FormatToPattern("%1$s hat %2$d Punkte (100%%)")
  local a, b = ("X hat 5 Punkte (100%)"):match(p)
  eq(a, "X"); eq(b, "5")
end)

---------------------------------------------------------------------------
-- Full flow with the mock
---------------------------------------------------------------------------
test("Recap: Spieler-Todesstoß (overkill) -> sicherer Kill, Mittäter beteiligt (1.1.0)", function()
  local ns = M.Load()
  M.recap = { id = 7, events = {
    ev({ guid = "Player-93-B", name = "Helfer Typ", amount = 300 }),
    ev({ guid = "Player-93-A", name = "Moerder Typ", amount = 900, overkill = 120 }),
    ev({ guid = "Creature-0-1", name = "Raptor", amount = 20 }),
  } }
  M.ClearFired()
  die()
  local d = M.Fired("DEATH_RECORDED")
  eq(#d, 1)
  eq(d[1][3], "Moerder-Typ")
  local j = lastJournal(ns)
  eq(j.kind, "pvp"); eq(j.killerKey, "Moerder-Typ"); eq(j.sure, true); eq(j.source, "recap"); eq(j.zone, "Schlingendorntal")
  local e = ns.Store.Get("Moerder-Typ")
  eq(e.kills, 1); eq(e.status, "wanted"); eq(e.guid, "Player-93-A"); eq(e.deaths[1].others[1], "Helfer-Typ")
  local h = ns.Store.Get("Helfer-Typ")
  eq(h.kills, 0); eq(h.assists, 1); eq(h.suspected, 0); eq(h.status, "wanted", "Mittäter ist gesucht")
  eq(h.deaths[1].role, "assist"); eq(h.deaths[1].sure, false); eq(e.deaths[1].role, "kill")
  noSecretsInDB()
end)

test("Recap ohne overkill: jüngster Zeitstempel ist der Todesstoß", function()
  local ns = M.Load()
  M.recap = { id = 3, events = {
    ev({ guid = "Player-93-A", name = "Frueh", ts = time() - 5 }),
    ev({ guid = "Player-93-B", name = "Spaet", ts = time() - 1 }),
  } }
  die()
  eq(lastJournal(ns).killerKey, "Spaet-Forever")
end)

test("Recap: Kreatur tötet -> pve, kein Eintrag", function()
  local ns = M.Load()
  M.recap = { id = 4, events = { ev({ guid = "Creature-0-1", name = "Raptor", overkill = 5 }) } }
  M.ClearFired()
  die()
  -- 1.2.0: the death goes out as pve (DEATH_RECORDED) but gets no journal line
  local j = M.Fired("DEATH_RECORDED")[1][2]
  eq(j.kind, "pve"); no(j.killerKey); eq(next(ns.Store.All()), nil)
  eq(lastJournal(ns), nil, "keine Journalzeile fuer pve")
  eq(M.Fired("DEATH_RECORDED")[1][3], nil)
end)

test("Veraltetes Recap (schon beim Login da) wird nicht dem nächsten Tod angelastet", function()
  local ns = M.Load({ before = function()
    M.recap = { id = 9, events = { ev({ guid = "Player-93-A", name = "Alter Feind", overkill = 5 }) } }
  end })
  -- PvE death, recap API still shows the old one
  die()
  local j = lastJournal(ns)
  no(j.killerKey); eq(j.kind, "unknown")
  no(ns.Store.Get("Alter-Feind"))
end)

test("Veraltetes Recap: zweimal derselbe Inhalt zählt nur einmal", function()
  local ns = M.Load()
  M.recap = { id = 11, events = { ev({ guid = "Player-93-A", name = "Einmal", overkill = 5 }) } }
  die()
  eq(ns.Store.Get("Einmal-Forever").kills, 1)
  M.Advance(30)
  M.recap.events[1].timestamp = time() - 1   -- even with a fresh-looking time stamp: same id
  die()
  eq(ns.Store.Get("Einmal-Forever").kills, 1)
end)

test("Veraltetes Recap: Zeitstempel älter als 60 s", function()
  local ns = M.Load()
  M.recap = { events = { ev({ guid = "Player-93-A", name = "Uralt", overkill = 5, ts = time() - 600 }) } }
  die()
  no(ns.Store.Get("Uralt-Forever"))
  eq(ns.Attribution.last.evidence[1].why, "Zeitstempel zu alt")
end)

test("Recap kommt verspätet: zweiter Versuch findet ihn", function()
  local ns = M.Load()
  M.FireEvent("PLAYER_DEAD")
  M.Advance(1)
  M.recap = { id = 20, events = { ev({ guid = "Player-93-A", name = "Spaet Dran", overkill = 5 }) } }
  M.Advance(5)
  eq(lastJournal(ns).killerKey, "Spaet-Dran")
end)

test("Secret-Recap (Tabelle) -> Heuristik, kein Fehler, keine Secrets in der DB", function()
  local ns = M.Load()
  M.recap = M.SecretTable()
  M.AddEnemy("nameplate1", { name = "Einziger", surname = "Jaeger", target = "player" })
  M.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate1")
  M.Advance(2)
  die()
  local j = lastJournal(ns)
  eq(j.killerKey, "Einziger-Jaeger"); eq(j.sure, false); eq(j.source, "suspect")
  eq(ns.Store.Get("Einziger-Jaeger").status, "suspect")
  noSecretsInDB()
end)

test("Secret-Felder in Recap-Ereignissen werden übersprungen", function()
  local ns = M.Load()
  M.recap = { id = 30, events = {
    { sourceGUID = M.Secret("g"), sourceName = M.Secret("n"), amount = M.Secret("a"), overkill = M.Secret("o"),
      timestamp = M.Secret("t"), spellName = M.Secret("s"), hideCaster = M.Secret("h") },
    M.SecretTable(),
  } }
  die()
  local j = lastJournal(ns)
  no(j.killerKey)
  noSecretsInDB()
end)

test("Heuristik: zwei hatten mich im Ziel -> kein Täter, beide Kandidaten", function()
  local ns = M.Load()
  M.AddEnemy("nameplate1", { name = "Eins", target = "player" })
  M.AddEnemy("nameplate2", { name = "Zwei", target = "player" })
  M.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate1")
  M.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate2")
  die()
  local j = lastJournal(ns)
  eq(j.kind, "pvp"); no(j.killerKey); eq(#j.candidates, 2)
  eq(next(ns.Store.All()), nil, "nicht raten")
  ok(ns.Store.AssignDeath(1, j.candidates[1]))
  eq(ns.Store.Get(j.candidates[1]).kills, 1)
end)

test("Heuristik: nur wer in den letzten 6 s zielte", function()
  local ns = M.Load()
  M.AddEnemy("nameplate1", { name = "Frueher", target = "player" })
  M.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate1")
  M.units.nameplate1.target = nil
  M.Advance(10)
  die()
  local j = lastJournal(ns)
  no(j.killerKey); eq(j.kind, "unknown"); eq(j.candidates[1], "Frueher-Forever", "als Kandidat (20 s)")
end)

test("Heuristik: secret UnitIsUnit zählt nicht", function()
  local ns = M.Load()
  M.AddEnemy("nameplate1", { name = "Geheim", target = "player", targetsMeSecret = true })
  M.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate1")
  die()
  no(lastJournal(ns).killerKey)
end)

test("Instanz/Schlachtfeld: nur Journal, keine Feinde", function()
  local ns = M.Load()
  M.instance = { true, "pvp" }
  M.recap = { id = 40, events = { ev({ guid = "Player-93-A", name = "Bg Typ", overkill = 5 }) } }
  M.ClearFired()
  die()
  local j = lastJournal(ns)
  eq(j.counted, false); eq(next(ns.Store.All()), nil)
  eq(M.Fired("DEATH_RECORDED")[1][3], nil)
end)

test("Duell: Tod zählt nicht", function()
  local ns = M.Load()
  M.FireEvent("DUEL_REQUESTED")
  M.recap = { id = 41, events = { ev({ guid = "Player-93-A", name = "Duell Typ", overkill = 5 }) } }
  die()
  eq(next(ns.Store.All()), nil)
end)

test("Stufe Recap abgeschaltet -> Heuristik", function()
  local ns = M.Load()
  ns.Store.Setting("attribution.recap", false)
  M.recap = { id = 42, events = { ev({ guid = "Player-93-A", name = "Ignoriert", overkill = 5 }) } }
  die()
  no(ns.Store.Get("Ignoriert-Forever"))
end)

test("Keine APIs (C_DeathRecap/C_DamageMeter fehlen) -> kein Fehler", function()
  local ns = M.Load()
  _G.C_DeathRecap = nil; _G.C_DamageMeter = nil; _G.Enum = nil; _G.C_Map = nil
  die()
  eq(lastJournal(ns).kind, "unknown")
end)

test("Meter-Stufe: Spieler mit overkill im Schaden-erlitten", function()
  local ns = M.Load()
  M.meter = { combatSpells = {
    { spellID = 1, totalAmount = 500, overkillAmount = 50, combatSpellDetails = { unitName = "Meter Mann", unitClassFilename = "MAGE", isMob = false, isPet = false, amount = 500 } },
    { spellID = 2, totalAmount = 30, overkillAmount = 0, combatSpellDetails = { unitName = "Wolf", isMob = true, amount = 30 } },
  } }
  die()
  local j = lastJournal(ns)
  eq(j.killerKey, "Meter-Mann"); eq(j.source, "meter"); eq(j.sure, true)
end)

test("Meter-Stufe: secret Sitzung -> übersprungen", function()
  local ns = M.Load()
  M.meter = M.SecretTable()
  die()
  eq(lastJournal(ns).kind, "unknown")
  noSecretsInDB()
end)

test("Combat-Log geschlossen: Registrierung scheitert leise", function()
  local ns = M.Load()
  _G.CombatLogGetCurrentEventInfo = function() return nil end
  ns.Attribution.Setup()
  no(ns.Attribution.state.clogOn)
  die()
  eq(#M.errors, 0)
end)

test("Combat-Log ohne Inhalt schaltet sich selbst ab", function()
  M.Reset()
  M.closedEvents = {}
  local ns = M.Load({ keepWorld = true })
  _G.CombatLogGetCurrentEventInfo = function() return nil end
  ns.Attribution.Setup()
  no(ns.Attribution.state.clogOn, "Standard: Kampflog-Stufe aus, keine Registrierung")
  ns.Store.Setting("attribution.combatlog", true)
  ns.Attribution.Setup()
  ok(ns.Attribution.state.clogOn)
  for _ = 1, 6 do M.FireEvent("COMBAT_LOG_EVENT_UNFILTERED") end
  ok(ns.Attribution.state.clogDead)
end)

test("Combat-Log mit Inhalt liefert den Täter", function()
  M.Reset()
  M.closedEvents = {}
  local ns = M.Load({ keepWorld = true })
  local payload
  _G.CombatLogGetCurrentEventInfo = function() return unpack(payload, 1, 17) end
  ns.Store.Setting("attribution.combatlog", true)
  ns.Attribution.Setup()
  payload = { time(), "SPELL_DAMAGE", false, "Player-93-L", "Log Typ", 0, 0, "Player-93-0000AAAA", "Varorak", 0, 0,
    133, "Feuerball", 4, 900, 77 }
  M.FireEvent("COMBAT_LOG_EVENT_UNFILTERED")
  die()
  local j = lastJournal(ns)
  eq(j.killerKey, "Log-Typ"); eq(j.source, "combatlog")
end)

---------------------------------------------------------------------------
-- Revenge
---------------------------------------------------------------------------
test("Rache über PARTY_KILL (ich oder mein Pet)", function()
  local ns = M.Load()
  local k = ns.Store.ApplyKill({ name = "Ziel", surname = "Scheibe", guid = "Player-93-Z" }, { t = 1 }, true)
  M.ClearFired()
  M.FireEvent("PARTY_KILL", "Player-93-0000AAAA", "Player-93-Z")
  eq(ns.Store.Get(k).revenge, 1)
  eq(M.Fired("REVENGE")[1][2], k)
  M.FireEvent("PARTY_KILL", "Player-93-0000AAAA", "Player-93-Z")
  eq(ns.Store.Get(k).revenge, 1, "doppelt gemeldet")
  M.Advance(20)
  M.FireEvent("PARTY_KILL", "Player-93-ANDERER", "Player-93-Z")
  eq(ns.Store.Get(k).revenge, 1, "nicht ich")
  M.FireEvent("PARTY_KILL", M.Secret("a"), M.Secret("b"))
  eq(ns.Store.Get(k).revenge, 1)
end)

test("Rache über Chat 'Ihr habt X getötet!'", function()
  local ns = M.Load()
  local k = ns.Store.AddManual("Chat", "Opfer")
  M.FireEvent("CHAT_MSG_COMBAT_HOSTILE_DEATH", "Ihr habt Chat Opfer getötet!")
  eq(ns.Store.Get(k).revenge, 1)
  M.FireEvent("CHAT_MSG_COMBAT_HOSTILE_DEATH", M.Secret("text"))
end)

test("Rache über 'X stirbt.' nur wenn ich ihn im Ziel hatte", function()
  local ns = M.Load()
  local k = ns.Store.AddManual("Stirbt", "Typ")
  M.FireEvent("CHAT_MSG_COMBAT_HOSTILE_DEATH", "Stirbt Typ stirbt.")
  eq(ns.Store.Get(k).revenge, 0)
  M.AddEnemy("target", { name = "Stirbt", surname = "Typ" })
  M.FireEvent("PLAYER_TARGET_CHANGED")
  M.FireEvent("CHAT_MSG_COMBAT_HOSTILE_DEATH", "Stirbt Typ stirbt.")
  eq(ns.Store.Get(k).revenge, 1)
end)

test("Rache über PLAYER_PVP_KILLS_CHANGED nur bei genau einem Gegner im Kampf", function()
  local ns = M.Load()
  local k = ns.Store.AddManual("Pvp", "Eins")
  ns.Store.AddManual("Pvp", "Zwei")
  M.AddEnemy("target", { name = "Pvp", surname = "Eins" })
  M.FireEvent("PLAYER_TARGET_CHANGED")
  M.FireEvent("PLAYER_PVP_KILLS_CHANGED")
  eq(ns.Store.Get(k).revenge, 1)
  M.Advance(20)
  M.AddEnemy("nameplate1", { name = "Pvp", surname = "Zwei", target = "player" })
  M.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate1")
  M.FireEvent("PLAYER_TARGET_CHANGED")
  M.FireEvent("PLAYER_PVP_KILLS_CHANGED")
  eq(ns.Store.Get(k).revenge, 1, "zwei möglich: nicht raten")
end)

test("Debug: Ringpuffer der letzten 5 Tode, ohne Secrets", function()
  local ns = M.Load()
  ns.Store.Setting("debug", true)
  for i = 1, 7 do
    M.recap = { id = 100 + i, events = { ev({ guid = M.Secret("g"), name = "X" .. i, overkill = 1 }),
      ev({ guid = "Player-93-" .. i, name = "Dbg" .. i, overkill = 5 }) } }
    die()
    M.Advance(10)
  end
  local list = _G.DeathNoteDB.probe.deaths
  eq(#list, 5)
  eq(list[1].result.killer, "Dbg7-Forever")
  eq(list[1].stages[1].raw[1].sourceGUID, "<secret>")
  noSecretsInDB()
end)

M.done("test_attribution")
