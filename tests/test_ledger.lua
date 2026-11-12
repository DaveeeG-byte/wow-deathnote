-- Rap sheet (1.3.0): detection of own kills, the standing, events, awards, caps, hooks, probe.
-- All names are invented.
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local M = require("mock_wow")
local test, eq, ok, no = M.test, M.eq, M.ok, M.no

local ME = "Player-93-0000AAAA"
local HONOR = "%s stirbt (Ehrenhafter Sieg: %s). Ihr erhaltet %d Ehre."

local ns, got
local function load(level, opts)
  ns = M.Load(opts)
  M.units.player.level = level or 40
  got = {}
  for _, ev in ipairs({ "OWN_KILL", "STANDING_CHANGED", "REPUTE_RANK", "AWARD", "VICTIM_SPOTTED" }) do
    ns:On(ev, function(...) got[#got + 1] = { ev, ... } end)
  end
  return ns
end
local function fired(ev)
  local out = {}
  for _, x in ipairs(got) do if x[1] == ev then out[#out + 1] = x end end
  return out
end

local plate = 0
-- an enemy seen on a nameplate; returns its GUID
local function seen(name, surname, level, o)
  plate = plate + 1
  o = o or {}
  o.name, o.surname, o.level = name, surname, level or 40
  o.guid = o.guid or ("Player-93-" .. name .. (surname or ""))
  M.AddEnemy("nameplate" .. plate, o)
  M.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate" .. plate)
  return o.guid
end
local function kill(guid, attacker) M.FireEvent("PARTY_KILL", attacker or ME, guid) end
local function L() return ns.Ledger end
local function noSecrets() no(M.ContainsSecret(_G.DeathNoteDB), "secret in DeathNoteDB") end

local function ev(o)
  return { sourceGUID = o.guid, sourceName = o.name, amount = 900, overkill = 120, timestamp = time() - 1,
    spellName = "Hieb" }
end
local function dieBy(guid, name)
  M.recap = { id = math.random(1, 1e6), events = { ev({ guid = guid, name = name }) } }
  M.FireEvent("PLAYER_DEAD")
  M.Advance(5)
end

---------------------------------------------------------------------------
-- Detection
---------------------------------------------------------------------------
test("Own killing blow: victim, log row with scene, events OWN_KILL and STANDING_CHANGED", function()
  load(40)
  local g = seen("Grimm", "Bart", 41)
  kill(g)
  local v = L().Victim("Grimm-Bart")
  ok(v, "victim"); eq(v.n, 1); eq(v.level, 41); eq(v.guid, g)
  local row = L().Log()[1]
  eq(row.key, "Grimm-Bart"); eq(row.band, "gelb"); eq(row.e, 3); eq(row.vl, 41); eq(row.ml, 40)
  eq(row.zone, "Schlingendorntal"); eq(row.mapID, 1434); eq(row.x, 41.2); eq(row.y, 56.8)
  eq(row.me, "Varorak Narenmar"); eq(row.state, "victim"); eq(row.f, "")
  local k = fired("OWN_KILL")
  eq(#k, 1); eq(k[1][2], "Grimm-Bart"); eq(k[1][3], row); eq(k[1][3].state, "victim")
  eq(#fired("STANDING_CHANGED"), 1)
  local mine, his, state = L().Standing("Grimm-Bart")
  eq(mine, 1); eq(his, 0); eq(state, "victim")
  eq(L().Repute().n, 1); eq(L().Repute().acc.e, 3)
  noSecrets()
end)

test("Pet's killing blow counts (flag p); a group member's, an NPC's and a creature victim do not", function()
  load(40)
  M.units.pet = { exists = true, guid = "Pet-0-77" }
  local a, b, c = seen("Anna", "Ast", 40), seen("Bernd", "Bolz", 40), seen("Carla", "Klee", 40)
  kill(a, "Pet-0-77")
  eq(L().Victim("Anna-Ast").n, 1); ok(L().Log()[1].f:find("p"), "flag p")
  kill(b, "Player-93-Kollege")
  eq(L().Victim("Bernd-Bolz"), nil, "group member's kill")
  kill(c, "Creature-0-1-Totem")
  eq(L().Victim("Carla-Klee"), nil, "totem or guardian: not mine (probe notes it)")
  kill("Creature-0-5-Raptor")
  eq(L().Repute().n, 1)
  local okk, why = L().OnPartyKill(ME, "Creature-0-5-Raptor")
  no(okk); eq(why, "notplayer")
  no(L().OnPartyKill(ME, ME), "myself")
end)

test("Dropped: own faction, instance, rap sheet switched off", function()
  load(40)
  local g = seen("Hordi", "Gleich", 40, { faction = "Horde", enemy = false, canAttack = true })
  local okk, why = L().OnPartyKill(ME, g)
  no(okk); eq(why, "faction")
  local h = seen("Ali", "Anz", 40)
  M.instance = { true, "pvp" }
  okk, why = L().OnPartyKill(ME, h)
  no(okk); eq(why, "instance")
  M.instance = { false, "none" }
  ns.Store.Setting("ledger.enabled", false)
  okk, why = L().OnPartyKill(ME, h)
  no(okk); eq(why, "off"); eq(L().Standing("Ali-Anz"), nil, "no standing while off")
  ns.Store.Setting("ledger.enabled", true)
  ok(L().OnPartyKill(ME, h))
end)

test("The same kill twice within 10 s counts once; later it is kicking (infamy 2, no honour)", function()
  load(40)
  local g = seen("Grimm", "Bart", 40)
  kill(g); M.Advance(3); kill(g)
  eq(L().Victim("Grimm-Bart").n, 1, "dedupe")
  M.Advance(60); seen("Grimm", "Bart", 40, { guid = g }); kill(g)
  local v = L().Victim("Grimm-Bart")
  eq(v.n, 2); eq(v.dn, 2)
  local row = L().Log()[1]
  ok(row.f:find("n"), "kick flag"); eq(row.r, 2); eq(row.e, 0)
end)

test("Duel to the death: the opponent's kill is no rap sheet kill, no revenge; a third player counts", function()
  load(40)
  local g = seen("Grimm", "Bart", 40)
  local o = seen("Olm", "Reet", 40)
  -- he is in the book (he killed me before)
  ns.Store.ApplyKill({ name = "Grimm", surname = "Bart", guid = g }, { t = time() - 100 }, true)
  M.FireEvent("DUEL_TO_THE_DEATH_REQUESTED", "Grimm")
  M.Advance(20)
  kill(g)
  eq(L().Victim("Grimm-Bart"), nil, "no rap sheet kill")
  eq(ns.Store.Get("Grimm-Bart").revenge, 0, "no revenge")
  kill(o)
  eq(L().Victim("Olm-Reet").n, 1, "a third player still counts")
  M.FireEvent("DUEL_FINISHED"); M.Advance(31)
  seen("Grimm", "Bart", 40, { guid = g }); kill(g)
  eq(L().Victim("Grimm-Bart").n, 1, "31 s after the duel his death counts again")
  eq(ns.Store.Get("Grimm-Bart").revenge, 1)
end)

test("Duel to the death: my death by the opponent is no deed; by a third player it is", function()
  load(40)
  local g = seen("Grimm", "Bart", 40)
  M.FireEvent("DUEL_TO_THE_DEATH_REQUESTED", "Grimm")
  M.Advance(10)
  dieBy(g, "Grimm Bart")
  eq(ns.Store.Get("Grimm-Bart"), nil, "no book entry from the duel's death")
  eq(ns.Store.Deaths()[1].counted, false)
  M.Advance(10)
  local x = seen("Xaver", "Fremd", 40)
  dieBy(x, "Xaver Fremd")
  eq(ns.Store.Get("Xaver-Fremd").kills, 1, "a third player's kill counts")
end)

test("Duel to the death: the opponent on the hit list is not 'taken down' (Sync.lua)", function()
  M.Reset()
  local W = M.NewWorld({ "HUNT_BAGGED" })
  local a = W.client("Anton", "Wurst", "Die Testgilde")
  local b = W.client("Berta", "Senf", "Die Testgilde")
  a.login(); b.login(); W.run(90)
  b.ns.Store.AddManual("Grimm Bart")
  ok(b.ns.Guild.Release("Grimm-Bart"), "released")
  W.run(5)
  ok(a.ns.Guild.Hunt("Grimm-Bart", "guild"), "A hunts him")
  M.units.grimm = { exists = true, isPlayer = true, name = "Grimm", surname = "Bart", guid = "Player-1-GRIMM",
    class = "MAGE", level = 40, enemy = true, canAttack = true, faction = "Alliance" }
  a.ns.Tracker.OnUnit("grimm", "target")
  a.fire("DUEL_TO_THE_DEATH_REQUESTED", "Grimm")
  W.run(5)
  a.fire("PARTY_KILL", W.guidOf(a), "Player-1-GRIMM")
  W.run(5)
  local n = 0
  for _, e in ipairs(a.events) do if e[1] == "HUNT_BAGGED" then n = n + 1 end end
  eq(n, 0, "no take-down from the duel")
  eq(a.ns.Ledger.Victim("Grimm-Bart"), nil)
  a.fire("DUEL_FINISHED"); W.run(31)
  a.ns.Tracker.OnUnit("grimm", "target")
  a.fire("PARTY_KILL", W.guidOf(a), "Player-1-GRIMM")
  W.run(5)
  n = 0
  for _, e in ipairs(a.events) do if e[1] == "HUNT_BAGGED" then n = n + 1 end end
  eq(n, 1, "after the duel: taken down")
  ok(a.ns.Ledger.Log()[1].f:find("h"), "hit list flag")
  eq(#M.errors, 0, M.errors[1])
end)

test("Duel to the death by my own StartDuel(target, _, true), opponent by GUID", function()
  load(40)
  local g = seen("Grimm", "Bart", 40)
  M.units.target = M.units["nameplate" .. plate]
  ns.Attribution.OnStartDuel("target", nil, true)
  ok(ns.Attribution.DuelFoe(g), "opponent by GUID")
  no(ns.Attribution.DuelFoe("Player-93-Other", "Other"), "nobody else")
  ns.Attribution.OnStartDuel("target", nil, false)
  ok(ns.Attribution.DuelFoe(g), "a normal challenge changes nothing")
end)

test("Honour line as fallback: books after 2 s with flag m, pattern from the client's text", function()
  load(40)
  L().HONOR_FALLBACK = true   -- off by default until the probe has measured it
  eq(_G.COMBATLOG_HONORGAIN, HONOR, "mock carries the Forever text")
  seen("Grimm", "Bart", 42)
  M.FireEvent("CHAT_MSG_COMBAT_HONOR_GAIN", "Grimm Bart stirbt (Ehrenhafter Sieg: Rang 3). Ihr erhaltet 12 Ehre.")
  eq(L().Victim("Grimm-Bart"), nil, "waits for its PARTY_KILL")
  M.Advance(3)
  local v = L().Victim("Grimm-Bart")
  ok(v, "booked"); eq(v.n, 1)
  ok(L().Log()[1].f:find("m"), "flag m"); eq(L().Log()[1].band, "gelb")
  L().HONOR_FALLBACK = false
end)

test("Honour line and PARTY_KILL of one kill count once, in either order", function()
  load(40)
  local g = seen("Grimm", "Bart", 40)
  M.FireEvent("CHAT_MSG_COMBAT_HONOR_GAIN", "Grimm Bart stirbt (Ehrenhafter Sieg: Rang 3). Ihr erhaltet 12 Ehre.")
  M.Advance(1); kill(g); M.Advance(5)
  eq(L().Victim("Grimm-Bart").n, 1, "line first")
  no(L().Log()[1].f:find("m"), "booked from PARTY_KILL")
  local h = seen("Hanna", "Hut", 40)
  M.Advance(30)
  kill(h); M.Advance(1)
  M.FireEvent("CHAT_MSG_COMBAT_HONOR_GAIN", "Hanna stirbt (Ehrenhafter Sieg: Rang 1). Ihr erhaltet 9 Ehre.")
  M.Advance(5)
  eq(L().Victim("Hanna-Hut").n, 1, "kill first, line with first name only")
  eq(L().Repute().n, 2)
end)

test("Honour line after a group member's PARTY_KILL on that victim books nothing", function()
  load(40)
  local g = seen("Grimm", "Bart", 40)
  kill(g, "Player-93-Kollege")
  M.FireEvent("CHAT_MSG_COMBAT_HONOR_GAIN", "Grimm Bart stirbt (Ehrenhafter Sieg: Rang 3). Ihr erhaltet 12 Ehre.")
  M.Advance(5)
  eq(L().Victim("Grimm-Bart"), nil)
end)

test("Honour line without a victim, from an English client, never seen victim", function()
  load(40)
  L().HONOR_FALLBACK = true   -- off by default until the probe has measured it
  M.FireEvent("CHAT_MSG_COMBAT_HONOR_GAIN", "Ihr habt 12 Ehre erhalten.")
  M.Advance(5)
  eq(L().Repute().n, 0, "no name, nothing")
  _G.COMBATLOG_HONORGAIN = "%s dies, honorable kill Rank: %s (Estimated Honor Points: %d)"
  M.FireEvent("CHAT_MSG_COMBAT_HONOR_GAIN", "Vik dies, honorable kill Rank: Scout (Estimated Honor Points: 5)")
  M.Advance(5)
  local v = L().Victim("Vik-Forever")
  ok(v, "placeholder victim"); eq(v.surname, nil); eq(L().Log()[1].band, "unbekannt")
  L().HONOR_FALLBACK = false
end)

test("Victim never seen: first name from GetPlayerInfoByGUID, level unknown; seen later with surname: moved", function()
  load(40)
  M.units.ghost = { exists = false, isPlayer = true, name = "Vik", guid = "Player-93-VIK", class = "MAGE",
    classLoc = "Magier", level = 33, faction = "Alliance" }
  kill("Player-93-VIK")
  local v = L().Victim("Vik-Forever")
  ok(v, "placeholder"); eq(v.class, "MAGE"); eq(v.level, nil); eq(L().Log()[1].band, "unbekannt")
  ok(L().Log()[1].f:find("u"), "flag u")
  M.units.ghost = nil
  seen("Vik", "Sohn", 33, { guid = "Player-93-VIK" })
  eq(L().Victim("Vik-Forever"), nil, "moved")
  eq(L().Victim("Vik-Sohn").n, 1); eq(L().Log()[1].key, "Vik-Sohn")
  eq(ns.Tracker.ledgerHook, nil, "hook gone: no placeholder left")
end)

-- found by the random run: two victims for one GUID
test("Placeholder merges when a later kill names him in full (hook was off meanwhile)", function()
  load(40)
  M.units.ghost = { exists = false, isPlayer = true, name = "Vik", guid = "Player-93-VIK", faction = "Alliance" }
  kill("Player-93-VIK")
  ok(L().Victim("Vik-Forever"))
  M.units.ghost = nil
  ns.Store.Setting("ledger.enabled", false)
  seen("Vik", "Sohn", 30, { guid = "Player-93-VIK" })
  ok(L().Victim("Vik-Forever"), "not moved while switched off")
  ns.Store.Setting("ledger.enabled", true)
  M.Advance(20)
  kill("Player-93-VIK")
  eq(L().Victim("Vik-Forever"), nil); eq(L().Victim("Vik-Sohn").n, 2); eq(L().VictimCount(), 1)
end)

test("Placeholder merges when the full name learns his GUID (book entry by GUID)", function()
  load(40)
  M.units.ghost = { exists = false, isPlayer = true, name = "Dora", guid = "Player-93-DORA", faction = "Alliance" }
  kill("Player-93-DORA")
  ok(L().Victim("Dora-Forever"))
  M.units.ghost = nil
  ns.Store.ApplyKill({ name = "Dora", surname = "Dick", guid = "Player-93-DORA" }, { t = time() }, true)
  M.Advance(20)
  kill("Player-93-DORA")
  eq(L().Victim("Dora-Forever"), nil); eq(L().Victim("Dora-Dick").n, 2); eq(L().VictimCount(), 1)
  local mine, his = L().Standing("Dora-Dick")
  eq(mine .. ":" .. his, "2:1")
end)

test("GUID recall: level known 10 min after the sighting, unknown after 15 min", function()
  load(40)
  local g = seen("Grimm", "Bart", 44)
  M.units["nameplate" .. plate] = nil
  M.Advance(600); ns.Tracker.Prune(true)
  eq(ns.Tracker.ByGUID(g), nil, "out of the buffer")
  ok(ns.Tracker.Recall(g), "in the recall")
  kill(g)
  eq(L().Log()[1].band, "orange", "level from the recall")
  local h = seen("Hanna", "Hut", 44)
  M.units["nameplate" .. plate] = nil
  M.Advance(70); ns.Tracker.Prune(true); M.Advance(900)
  local okk, why = L().OnPartyKill(ME, h)
  no(okk); eq(why, "name", "no name known at all: nothing to book")
  M.units.ghost = { exists = false, isPlayer = true, name = "Hanna", guid = h, faction = "Alliance" }
  kill(h)
  eq(L().Log()[1].key, "Hanna-Forever"); eq(L().Log()[1].band, "unbekannt", "15 min later: level unknown")
end)

test("GUID recall: cap of 50, oldest first", function()
  load(40)
  local first
  for i = 1, 60 do
    local g = seen("Feind" .. i, "Nr", 40)
    first = first or g
    M.units["nameplate" .. plate] = nil
    M.Advance(1)
  end
  M.Advance(61); ns.Tracker.Prune(true)
  eq(ns.Tracker.Recall(first), nil, "the oldest left")
  ok(ns.Tracker.Recall("Player-93-Feind60Nr"), "the newest stays")
  local n = 0
  for i = 1, 60 do if ns.Tracker.Recall("Player-93-Feind" .. i .. "Nr") then n = n + 1 end end
  eq(n, 50)
end)

test("Skull: UnitLevel -1 marks the record, band skull; my target's live level wins", function()
  load(40)
  local g = seen("Riese", "Groß", -1)
  ok(ns.Tracker.ByGUID(g).skull, "skull marker")
  kill(g)
  eq(L().Log()[1].band, "schaedel"); eq(L().Log()[1].j, 10)
  local h = seen("Hanna", "Hut", 40)
  M.units.target = { exists = true, isPlayer = true, guid = h, level = 46, name = "Hanna", surname = "Hut" }
  kill(h)
  eq(L().Log()[1].band, "rot", "level of the target at the kill")
end)

---------------------------------------------------------------------------
-- Standing, revenge, events
---------------------------------------------------------------------------
local function theirKill(key, name, surname, guid)
  ns.Store.ApplyKill({ name = name, surname = surname, guid = guid }, { t = time() }, true)
end

test("Standing: open 1:2, even 2:2 (award receipt), ahead 3:2; revenge flag and +2 honour", function()
  load(40)
  local g = seen("Grimm", "Bart", 40)
  theirKill("Grimm-Bart", "Grimm", "Bart", g); M.Advance(30); theirKill("Grimm-Bart", "Grimm", "Bart", g)
  local mine, his, state = L().Standing("Grimm-Bart")
  eq(mine, 0); eq(his, 2); eq(state, "open")
  got = {}
  kill(g)
  eq(select(3, L().Standing("Grimm-Bart")), "open")
  ok(L().Log()[1].f:find("v"), "revenge flag"); eq(L().Log()[1].e, 5)
  M.Advance(700); seen("Grimm", "Bart", 40, { guid = g }); kill(g)
  mine, his, state = L().Standing("Grimm-Bart")
  eq(mine .. ":" .. his, "2:2"); eq(state, "even")
  ok(L().DB().awards.receipt, "award receipt")
  M.Advance(700); seen("Grimm", "Bart", 40, { guid = g }); kill(g)
  eq(select(3, L().Standing("Grimm-Bart")), "ahead")
  no(L().Log()[1].f:find("v"), "no revenge when he does not lead")
  eq(ns.Store.Get("Grimm-Bart").revenge, 3, "Attribution counts revenge as before")
end)

test("Standing: kills before he was in the book count; his kill makes it even (STANDING_CHANGED)", function()
  load(40)
  local g = seen("Grimm", "Bart", 40)
  kill(g)
  eq(select(3, L().Standing("Grimm-Bart")), "victim")
  got = {}
  theirKill("Grimm-Bart", "Grimm", "Bart", g)
  local mine, his, state = L().Standing("Grimm-Bart")
  eq(mine .. ":" .. his, "1:1"); eq(state, "even", "kill first, then he: even (the author's case 1)")
  eq(#fired("STANDING_CHANGED"), 1)
  got = {}
  ns.Store.Seen("Grimm-Bart", {}, { t = time() }, false)
  eq(#fired("STANDING_CHANGED"), 0, "a sighting changes nothing")
end)

test("Standing: hand revenge counts for me, never for the repute; undo; pardoned; suspect", function()
  load(40)
  local g = seen("Grimm", "Bart", 40)
  theirKill("Grimm-Bart", "Grimm", "Bart", g)
  got = {}
  ns.Store.AddRevenge("Grimm-Bart", true)
  eq(select(3, L().Standing("Grimm-Bart")), "even")
  eq(#fired("STANDING_CHANGED"), 1)
  eq(L().Repute().total, 0, "no points from a hand revenge")
  ns.Store.UndoRevenge("Grimm-Bart")
  eq(select(3, L().Standing("Grimm-Bart")), "open")
  ns.Store.SetStatus("Grimm-Bart", "pardoned")
  eq(select(3, L().Standing("Grimm-Bart")), "pardoned")
  kill(g)
  no(L().Log()[1].f:find("v"), "a pardoned one is no revenge")
end)

test("Book entry removed: the victim stays; book entry moved to a fuller key: the victim follows", function()
  load(40)
  local g = seen("Grimm", "Bart", 40)
  theirKill("Grimm-Bart", "Grimm", "Bart", g)
  kill(g)
  ns.Store.Remove("Grimm-Bart")
  eq(L().Victim("Grimm-Bart").n, 1)
  eq(select(3, L().Standing("Grimm-Bart")), "victim")
  -- a placeholder in the book (by hand), killed, then the book learns the surname
  M.units.ghost = { exists = false, isPlayer = true, name = "Edda", guid = "Player-93-EDDA", faction = "Alliance" }
  ns.Store.AddManual("Edda")
  kill("Player-93-EDDA")
  ok(L().Victim("Edda-Forever"), "victim under the book's placeholder key")
  M.units.ghost = nil
  seen("Edda", "Kahl", 30, { guid = "Player-93-EDDA" })
  ok(ns.Store.Get("Edda-Kahl"), "book moved")
  eq(L().Victim("Edda-Forever"), nil); eq(L().Victim("Edda-Kahl").n, 1)
end)

test("Awards: first entry, David (red, alone), same day, patience; arch-enemy at 5 : 5", function()
  load(40)
  local g = seen("Grimm", "Bart", 46)
  kill(g)
  local a = L().DB().awards
  ok(a.first_entry); ok(a.david); no(a.same_day)
  local ids = {}
  for _, x in ipairs(fired("AWARD")) do ids[#ids + 1] = x[2] end
  eq(table.concat(ids, ","), "first_entry,david")
  -- ten times killed by the same, then avenged within a day
  local h = seen("Hanna", "Hut", 40)
  for _ = 1, 10 do theirKill("Hanna-Hut", "Hanna", "Hut", h); M.Advance(30) end
  kill(h)
  ok(a.patience, "patience"); ok(a.same_day, "same day")
  -- arch-enemy: 5 : 5
  load(40)
  local x = seen("Erz", "Feind", 40)
  for i = 1, 5 do
    theirKill("Erz-Feind", "Erz", "Feind", x); M.Advance(700)
    seen("Erz", "Feind", 40, { guid = x }); kill(x); M.Advance(700)
    if i < 5 then no(L().DB().awards.arch_enemy, "not before 5 : 5") end
  end
  ok(L().DB().awards.arch_enemy, "arch-enemy")
  -- David not in a group
  load(40)
  M.units.party1 = { exists = true, isPlayer = true, name = "Kollege", guid = "Player-93-K" }
  kill(seen("Rot", "Ling", 46))
  no(L().DB().awards.david, "in a group")
  ok(L().Log()[1].f:find("g"), "group flag"); eq(L().Log()[1].j, 3, "hunt halved")
end)

test("REPUTE_RANK fires once per change of tier or path", function()
  load(40)
  for i = 1, 4 do kill(seen("Opfer" .. i, "Gelb", 40)); M.Advance(20) end
  eq(#fired("REPUTE_RANK"), 1, "12 points: tier 2")
  local r = fired("REPUTE_RANK")[1]
  eq(r[2], 2); eq(r[3], nil); eq(r[4], 1); eq(r[5], nil)
  for i = 5, 10 do kill(seen("Opfer" .. i, "Gelb", 40)); M.Advance(20) end
  local rr = fired("REPUTE_RANK")
  eq(#rr, 3, "tier 3 at 30 points, then the path at the 10th kill")
  eq(rr[3][3], "e"); eq(L().Repute().path, "e"); eq(L().Repute().tier, 3)
  eq(L().DB().tier, 3); eq(L().DB().path, "e")
end)

test("Protection, hit list, foreign bounty from the guild book and the bounties", function()
  load(40)
  local g = seen("Grimm", "Bart", 40)
  ns.Guild.Get = function(key) if key == "Grimm-Bart" then return { deeds = { { victim = "Kollegin Klar" } } } end end
  ns.Guild.Hunt = function(key) if key == "Grimm-Bart" then return { key = key } end end
  ns.Bounty.Has = function() return true end
  ns.Bounty.Rows = function() return { { char = "Kollegin Klar", g = 50, own = false } } end
  kill(g)
  local row = L().Log()[1]
  eq(row.f, "shb"); eq(row.s, 4); eq(row.j, 8); eq(row.e, 3)
end)

---------------------------------------------------------------------------
-- Caps, removal, hooks, settings
---------------------------------------------------------------------------
test("Caps: 200 victims (book entries stay), 60 log rows", function()
  load(40)
  local keep = seen("Buch", "Mann", 40)
  theirKill("Buch-Mann", "Buch", "Mann", keep)
  kill(keep)
  M.Advance(20)
  for i = 1, 205 do
    kill(seen("V" .. i, "Opfer", 40)); M.Advance(11)
  end
  eq(L().VictimCount(), 200)
  ok(L().Victim("Buch-Mann"), "the oldest, but in the book")
  eq(L().Victim("V1-Opfer"), nil, "oldest outside the book left")
  ok(L().Victim("V205-Opfer"))
  eq(#L().Log(), 60)
  eq(L().Repute().n, 206)
end)

test("RemoveVictim: name and count go, points stay, the book's revenge stays in the standing and the bounty", function()
  load(40)
  local g = seen("Grimm", "Bart", 40)
  theirKill("Grimm-Bart", "Grimm", "Bart", g)
  kill(g)
  local e = ns.Store.Get("Grimm-Bart")
  local bounty = ns.Store.Bounty(e)
  local before = L().Repute().total
  ok(L().RemoveVictim("Grimm-Bart"))
  eq(L().Victim("Grimm-Bart"), nil); eq(L().Repute().total, before)
  eq(e.revenge, 1)
  eq(select(3, L().Standing("Grimm-Bart")), "even", "the recognised revenge of the book still counts")
  eq(ns.Store.Bounty(e), bounty, "the bounty does not rise")
  no(L().RemoveVictim("Grimm-Bart"))
  ns.Store.Init()
  eq(L().Victim("Grimm-Bart"), nil, "not back from the book's revenge")
  eq(L().Repute().total, before, "no points at the start")
end)

test("Victim alarm hook: only while switched on and victims exist; VICTIM_SPOTTED", function()
  load(40)
  eq(ns.Tracker.victimHook, nil, "default off")
  local g = seen("Grimm", "Bart", 40)
  kill(g)
  eq(ns.Tracker.victimHook, nil, "still off")
  ns.Store.Setting("alert.victims", true)
  ok(ns.Tracker.victimHook, "on")
  M.Advance(1)
  seen("Grimm", "Bart", 40, { guid = g })
  local v = fired("VICTIM_SPOTTED")
  eq(#v, 1); eq(v[1][2], "Grimm-Bart"); eq(v[1][4], "nameplate")
  seen("Other", "One", 40)
  eq(#fired("VICTIM_SPOTTED"), 1, "no event for others")
  ns.Store.Setting("alert.victims", false)
  eq(ns.Tracker.victimHook, nil)
end)

test("Settings: defaults and repair", function()
  load(40)
  eq(ns.Store.Setting("ledger.enabled"), true); eq(ns.Store.Setting("ledger.chat"), true)
  eq(ns.Store.Setting("alert.settled"), "always"); eq(ns.Store.Setting("alert.victims"), false)
  _G.DeathNoteDB.settings.alert.settled = "loud"
  ns.Store.Init()
  eq(ns.Store.Setting("alert.settled"), "always")
end)

test("Store: debt order and the book's bounty read 'me'", function()
  load(40)
  local a, b, c = seen("Anna", "Ast", 40), seen("Bernd", "Bolz", 40), seen("Carla", "Klee", 40)
  for _ = 1, 3 do theirKill("Anna-Ast", "Anna", "Ast", a); M.Advance(5) end
  for _ = 1, 2 do theirKill("Bernd-Bolz", "Bernd", "Bolz", b); M.Advance(5) end
  theirKill("Carla-Klee", "Carla", "Klee", c)
  for _ = 1, 3 do kill(a); M.Advance(11) end      -- Anna 3 : 3, even
  local list = ns.Store.Ranked("wanted", "debt")
  eq(list[1].key, "Bernd-Bolz", "debt 2"); eq(list[2].key, "Carla-Klee", "debt 1"); eq(list[3].key, "Anna-Ast", "even last")
  eq(ns.Store.Ranked("wanted", "rank")[1].key, "Anna-Ast", "the old order stays the default")
  eq(ns.Store.Debt(ns.Store.Get("Bernd-Bolz")), 2)
  local e = ns.Store.Get("Anna-Ast")
  local withMine = ns.Store.Bounty(e)
  ns.Store.Setting("ledger.enabled", false)
  eq(ns.Store.Bounty(e), withMine, "same as revenge: 3 kills = 3 revenges")
  ns.Store.Setting("ledger.enabled", true)
  kill(seen("Dora", "Dick", 40)); M.Advance(11)
  theirKill("Dora-Dick", "Dora", "Dick", "Player-93-DoraDick")
  local d = ns.Store.Get("Dora-Dick")
  ok(ns.Store.Bounty(d) < (function() ns.Store.Setting("ledger.enabled", false); local x = ns.Store.Bounty(d)
    ns.Store.Setting("ledger.enabled", true); return x end)(), "a kill before he was listed lowers his bounty")
end)

test("Streak: own kills until an own death by a player; best marks", function()
  load(40)
  for i = 1, 3 do kill(seen("S" .. i, "Erie", 45)); M.Advance(11) end
  eq(L().DB().cur.streak, 3); eq(L().DB().best.streak, 3); eq(L().DB().best.gap, 5)
  dieBy(seen("Killer", "Typ", 40), "Killer Typ")
  eq(L().DB().cur.streak, 0); eq(L().DB().best.streak, 3)
  M.Advance(30)
  kill(seen("Killer", "Typ", 40, { guid = "Player-93-KillerTyp" }))
  ok(L().DB().best.quick and L().DB().best.quick <= 40, "quickest revenge in seconds")
end)

---------------------------------------------------------------------------
-- Secrets and the probe
---------------------------------------------------------------------------
test("Secrets: PARTY_KILL arguments, honour text, levels, GUIDs secret in every position", function()
  load(40)
  M.ClearFired()
  local g = seen("Grimm", "Bart", 40)
  for _, args in ipairs({ { M.Secret("a"), g }, { ME, M.Secret("t") }, { M.Secret("a"), M.Secret("t") } }) do
    M.FireEvent("PARTY_KILL", args[1], args[2])
  end
  M.FireEvent("CHAT_MSG_COMBAT_HONOR_GAIN", M.Secret("text"))
  M.units.pet = { exists = true, guid = M.Secret("pet") }
  M.FireEvent("PARTY_KILL", ME, g)
  M.units.pet = nil
  local h = seen("Hanna", "Hut", M.Secret("lvl", "number"))
  kill(h)
  eq(L().Log()[1].band, "unbekannt")
  M.units.player.faction = M.Secret("fac")
  kill(seen("Ida", "Igel", 40))
  M.units.player.faction = "Horde"
  M.units.ghost = { exists = false, isPlayer = true, name = M.Secret("nm"), guid = "Player-93-SEC" }
  kill("Player-93-SEC")
  eq(#M.errors, 0, M.errors[1])
  noSecrets()
end)

test("Probe (/dn debug): cases without names, counters, kept by /dn probe, feign-death check", function()
  load(40)
  ns.Store.Setting("debug", true)
  M.units.pet = { exists = true, guid = "Pet-0-77" }
  local g = seen("Grimm", "Bart", 41)
  kill(g)
  M.Advance(1)
  M.FireEvent("CHAT_MSG_COMBAT_HONOR_GAIN", "Grimm Bart stirbt (Ehrenhafter Sieg: Rang 3). Ihr erhaltet 12 Ehre.")
  M.FireEvent("PLAYER_PVP_KILLS_CHANGED")
  M.FireEvent("UNIT_DIED", g)
  kill(g)                                          -- dup
  kill(seen("Anna", "Ast", 40), "Player-93-Kollege")
  kill(seen("Bernd", "Bolz", 40), "Creature-0-9-Totem")
  M.Advance(11)
  local k = _G.DeathNoteDB.probe.kills
  ok(k and #k.cases >= 4, "cases")
  local c = k.cases[#k.cases]
  eq(c.src, "partykill"); eq(c.att, "me"); eq(c.tgt, "Player"); eq(c.result, "booked"); eq(c.band, "gelb")
  eq(c.args.a, "Player"); eq(c.info.form, "full"); eq(c.info.via, "buffer"); eq(c.myLevel, 40); eq(c.vicLevel, 41)
  ok(c.honor and c.honor.name == "full" and c.honor.rank == "Rang 3" and c.honor.honor == 12, "honour line on the case")
  ok(c.honor.dt and c.honor.dt >= 1, "seconds to the line"); ok(c.kc ~= nil, "kills changed"); ok(c.died, "UNIT_DIED")
  eq(c.alive, "unseen", "not seen again after the kill")
  eq(k.cases[1].att, "npc"); eq(k.cases[2].att, "foreign")
  eq(k.counts.dup, 1); eq(k.counts.booked, 1); eq(k.counts.own, 2)
  -- no name anywhere in the cases
  local function scan(t)
    for kk, v in pairs(t) do
      if type(v) == "string" and (v:find("Grimm") or v:find("Bart") or v:find("Anna") or v:find("Bernd")) then return kk end
      if type(v) == "table" then local x = scan(v) if x then return x end end
    end
  end
  eq(scan(k), nil, "names in the probe")
  ns.Probe.Run(false)
  local k2 = _G.DeathNoteDB.probe.kills
  eq(#k2.cases, #k.cases, "cases kept"); eq(k2.pattern, ns.Ledger.HonorPattern()); eq(k2.maxLevel, 60)
  eq(k2.deathDuelEvent, true)
  -- debug off: no new cases
  ns.Store.Setting("debug", false)
  local n = #k2.cases
  kill(seen("Carla", "Klee", 40))
  eq(#_G.DeathNoteDB.probe.kills.cases, n)
end)

test("Probe: feign death, the victim stands again within 10 s", function()
  load(40)
  ns.Store.Setting("debug", true)
  local g = seen("Jaeger", "Tot", 40)
  local u = M.units["nameplate" .. plate]
  _G.UnitIsDeadOrGhost = function(t) return false end
  kill(g)
  M.Advance(5); ns.Tracker.OnUnit("nameplate" .. plate, "nameplate")
  M.Advance(6)
  eq(_G.DeathNoteDB.probe.kills.cases[1].alive, true)
  _G.UnitIsDeadOrGhost = nil
  ok(u)
end)

---------------------------------------------------------------------------
-- The ganker of concept 6.6 through the real booking path (PARTY_KILL, tracker levels, kicking and wear)
---------------------------------------------------------------------------
test("Concept 6.6 ganker end to end: 157 points, tier 5, infamy, needle -79", function()
  load(60)
  local seq = "grau grau grau+kick+n2 grau gruen grau grau+n3 gruen grau gelb grau gruen grau grau+kick+n2 grau gruen grau grau grau+kick+n2 gruen gelb grau grau grau+n3 grau+n3 grau grau grau+kick+n2 gelb grau gruen grau grau+kick+n2 grau grau+n3 gruen grau grau grau+kick+n2 gelb gruen gruen grau grau grau grau grau+n3 gruen gelb grau+n3"
  local LV = { grau = 40, gruen = 54, gelb = 59 }
  local id, open, kicked = 0, {}, {}   -- open: grey victims killed once (for a later kick), kicked: waiting for n3
  local function victim(level) id = id + 1; return seen("G" .. id, "Opfer", level) end
  local t = 0
  for tok in seq:gmatch("%S+") do
    local band = tok:match("^(%a+)")
    if tok:find("kick") then
      local x = table.remove(open, 1)            -- the oldest single grey: within 10 min (kills 25 s apart)
      seen(x.name, "Opfer", 40, { guid = x.g }); kill(x.g); kicked[#kicked + 1] = x
    elseif tok:find("n3") then
      local x = table.remove(kicked, 1)
      seen(x.name, "Opfer", 40, { guid = x.g }); kill(x.g)
    else
      local g = victim(LV[band])
      kill(g)
      if band == "grau" then open[#open + 1] = { g = g, name = "G" .. id } end
    end
    M.Advance(25); t = t + 25
    -- the kicked ones come back after more than 10 minutes: no kicking for the third kill
  end
  local rp = L().Repute()
  eq(table.concat({ rp.acc.r, rp.acc.e, rp.acc.j, rp.acc.s, rp.total, rp.tier, tostring(rp.path), rp.needle }, " "),
    "142 15 0 0 157 5 r -79")
  eq(rp.n, 50); eq(rp.bands.grau, 35); eq(rp.bands.gruen, 10); eq(rp.bands.gelb, 5)
end)

M.done("ledger")
