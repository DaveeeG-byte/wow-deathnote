-- Rap sheet (1.3.0): fixes after the second look at the rap sheet (one player, one key: the GUID beats the first
-- name; the duel to the death; shared tables; keys of namesakes; gaps in the tests; the tracker with namesakes).
-- One block per finding; every test was red before its fix. All names are invented.
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local M = require("mock_wow")
local test, eq, ok, no = M.test, M.eq, M.ok, M.no

local ME = "Player-93-0000AAAA"

local ns, plate = nil, 0
local function fresh(level)
  _G.DeathNoteDB = nil
  ns = M.Load(); plate = 0
  M.units.player.level = level or 40
  return ns
end
local function reload(level)
  ns = M.Load({ db = _G.DeathNoteDB }); plate = 0
  M.units.player.level = level or 40
  return ns
end
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
local function dieBy(guid, name)
  M.recap = { id = math.random(1, 1e6), events = { { sourceGUID = guid, sourceName = name, amount = 900, overkill = 120,
    timestamp = time() - 1, spellName = "Hieb" } } }
  M.FireEvent("PLAYER_DEAD"); M.Advance(5)
end
local function standing(key)
  local m, h, s = ns.Ledger.Standing(key)
  return tostring(m) .. ":" .. tostring(h) .. " " .. tostring(s)
end
-- GetPlayerInfoByGUID knows the first name only (as on Forever)
local function firstNameOnly(name, guids)
  _G.GetPlayerInfoByGUID = function(g)
    if guids[g] then return "Schurke", "ROGUE", "Mensch", "Human", 2, name, "" end
  end
end

---------------------------------------------------------------------------
-- Keys of namesakes (finding 5)
---------------------------------------------------------------------------
test("Three namesakes with three GUIDs on two realm numbers are three victims", function()
  fresh()
  local gs = { "Player-93-0000A1", "Player-93-0000B2", "Player-94-0000B2" }
  firstNameOnly("Gerd", { [gs[1]] = true, [gs[2]] = true, [gs[3]] = true })
  for _, g in ipairs(gs) do kill(g); M.Advance(60) end
  _G.GetPlayerInfoByGUID = nil
  eq(ns.Ledger.VictimCount(), 3)
  local guids = {}
  for _, v in ipairs(ns.Ledger.Victims()) do guids[v.guid] = v.key end
  eq(guids[gs[2]], "Gerd-Forever#93-0000B2")
  eq(guids[gs[3]], "Gerd-Forever#94-0000B2")
end)

test("A namesake key shows as the name: NameParts and DisplayName, also after a reload", function()
  fresh()
  firstNameOnly("Gerd", { ["Player-93-0000A1"] = true, ["Player-93-0000B2"] = true })
  kill("Player-93-0000A1"); M.Advance(60); kill("Player-93-0000B2")
  _G.GetPlayerInfoByGUID = nil
  local key = "Gerd-Forever#93-0000B2"
  ok(ns.Ledger.Victim(key), "victim under the namesake key")
  local n, sn, realm = ns.Ledger.NameParts(key)
  eq(n, "Gerd"); eq(sn, nil); eq(realm, "Forever")
  eq(ns.Ledger.DisplayName(key), "Gerd")
  eq(ns.Ledger.AsEntry(key).realm, "Forever")
  -- a saved victim without realm field is repaired from its key without the "#..." part
  _G.DeathNoteDB.ledger.victims[key].realm = nil
  reload()
  eq(ns.Ledger.Victim(key).realm, "Forever")
  eq(ns.Ledger.DisplayName("Gerd-Groll"), "Gerd")   -- a key nobody holds: the first part only
  local a = seen("Anna", "Ast", 40); kill(a)
  local n2, s2, r2 = ns.Ledger.NameParts("Anna-Ast")
  eq(n2 .. "/" .. s2 .. "/" .. tostring(r2), "Anna/Ast/nil", "a full key has no realm")
  eq(ns.Ledger.DisplayName("Anna-Ast"), "Anna Ast")
  eq(ns.Store.Get(key), nil, "never in the book")
end)

---------------------------------------------------------------------------
-- One player, one key: the book's key for his GUID leads (finding 1)
---------------------------------------------------------------------------
-- seen with surname, plate gone, the buffer pruned; the recall keeps him for 15 min
local function gone()
  M.units["nameplate" .. plate] = nil
  M.Advance(120); ns.Tracker.Prune(true)
end
local function unseenRevenge()
  fresh()
  local g = seen("Gerd", "Groll", 40); gone()
  ok(ns.Tracker.Recall(g), "only in the recall")
  dieBy(g, "Gerd")                                     -- he kills me unseen: the book lists his first name and GUID
  ok(ns.Store.Get("Gerd-Forever"), "book entry under the first name")
  M.Advance(30); kill(g)                               -- my killing blow without a new sighting (DoT, pet)
  return g
end

test("A kill on a listed enemy the book knows by first name and GUID is revenge, booked under the book's key", function()
  local g = unseenRevenge()
  local row = ns.Ledger.Log()[1]
  eq(row.key, "Gerd-Forever")
  ok(row.f:find("v"), "flag v, f = '" .. row.f .. "'")
  local v = ns.Ledger.Victim("Gerd-Forever")
  eq(v.pre, nil, "no kill before he was listed")
  eq(v.guid, g)
  eq(ns.Ledger.Victim("Gerd-Groll"), nil, "no second key for the same GUID")
  eq(standing("Gerd-Forever"), "1:1 even")
end)

test("The book moves to the full name at the sighting: the one kill counts once, also after a reload", function()
  local g = unseenRevenge()
  M.Advance(60); seen("Gerd", "Groll", 40, { guid = g })
  eq(ns.Store.ByGUID(g), "Gerd-Groll")
  eq(standing("Gerd-Groll"), "1:1 even")
  eq(ns.Ledger.VictimCount(), 1)
  reload()
  eq(standing("Gerd-Groll"), "1:1 even")
end)

test("A victim known with surname follows a later book entry of the same GUID under the first name", function()
  fresh()
  local g = seen("Anna", "Ast", 40)
  kill(g); gone(); M.Advance(1000)                     -- killed before she was listed, the recall ran out
  dieBy(g, "Anna")                                     -- she kills me unseen: the book lists "Anna-<realm>"
  local bk = ns.Store.ByGUID(g)
  eq(bk, "Anna-Forever")
  eq(standing(bk), "1:1 even")
  local v = ns.Ledger.Victim(bk)
  eq(v and v.surname, "Ast", "the victim keeps the surname it knew")
  eq(v and v.pre, 1, "killed before she was listed")
  eq(ns.Ledger.VictimCount(), 1)
  M.Advance(60); seen("Anna", "Ast", 40, { guid = g })  -- the book moves to the full name, the victim along
  eq(ns.Store.ByGUID(g), "Anna-Ast"); eq(standing("Anna-Ast"), "1:1 even"); eq(ns.Ledger.VictimCount(), 1)
end)

---------------------------------------------------------------------------
-- Namesakes are joined by GUID, never by the shared first-name key (finding 2)
---------------------------------------------------------------------------
local A, B = "Player-93-0000A1", "Player-93-0000B2"

test("A kill on A is no 'me' against the namesake B who kills me; A's victim steps aside", function()
  fresh(); firstNameOnly("Gerd", { [A] = true, [B] = true })
  kill(A)                                              -- A never seen: victim Gerd-<realm> with GUID A
  M.Advance(60); dieBy(B, "Gerd")                      -- B kills me unseen: the book lists Gerd-<realm> with GUID B
  local e = ns.Store.Get("Gerd-Forever")
  eq(e and e.guid, B)
  eq(standing("Gerd-Forever"), "0:1 open")
  local with = ns.Store.Bounty(e)
  ns.Store.Setting("ledger.enabled", false)
  eq(with, ns.Store.Bounty(e), "bounty on B as in 1.2.x")
  ns.Store.Setting("ledger.enabled", true)
  local v = ns.Ledger.Victim("Gerd-Forever#93-0000A1")
  eq(v and v.guid, A, "A under a namesake key of his own")
  eq(ns.Ledger.VictimCount(), 1)
  _G.GetPlayerInfoByGUID = nil
end)

test("A's victim does not take B's surname when the book moves to B's full name", function()
  fresh(); firstNameOnly("Gerd", { [A] = true, [B] = true })
  kill(A); M.Advance(60); dieBy(B, "Gerd")
  M.Advance(60); seen("Gerd", "Bolz", 40, { guid = B })
  _G.GetPlayerInfoByGUID = nil
  eq(ns.Store.ByGUID(B), "Gerd-Bolz")
  eq(ns.Ledger.Victim("Gerd-Bolz"), nil)
  eq(standing("Gerd-Bolz"), "0:1 open")
  local v = ns.Ledger.Victim("Gerd-Forever#93-0000A1")
  eq(v and v.surname, nil); eq(v and v.n, 1)
end)

test("Two namesakes in the rap sheet stay two when one of them comes into the book", function()
  fresh(); firstNameOnly("Gerd", { [A] = true, [B] = true })
  kill(A); M.Advance(60); kill(B)
  eq(ns.Ledger.VictimCount(), 2)
  M.Advance(60); dieBy(B, "Gerd")
  _G.GetPlayerInfoByGUID = nil
  eq(ns.Ledger.VictimCount(), 2)
  local v = ns.Ledger.Victim("Gerd-Forever")
  eq(v and v.guid, B); eq(v and v.n, 1)
  eq(standing("Gerd-Forever"), "1:1 even")
  eq(ns.Ledger.Victim("Gerd-Forever#93-0000A1").n, 1)
end)

test("A move never merges two GUIDs; the check at start lets a victim of another GUID step aside", function()
  fresh(); firstNameOnly("Gerd", { [A] = true, [B] = true })
  kill(A); M.Advance(60); kill(B)
  _G.GetPlayerInfoByGUID = nil
  ns.Ledger.MoveVictim("Gerd-Forever#93-0000B2", "Gerd-Forever")
  eq(ns.Ledger.VictimCount(), 2, "two victims after a move onto a namesake")
  eq(ns.Ledger.Victim("Gerd-Forever").guid, B)
  eq(ns.Ledger.Victim("Gerd-Forever#93-0000A1").guid, A)
  -- a saved state where the book lists another GUID under a victim's key (written by an older build)
  local db = _G.DeathNoteDB
  db.enemies["Gerd-Forever"] = { name = "Gerd", realm = "Forever", guid = A, kills = 1, assists = 0, suspected = 0,
    revenge = 0, status = "wanted", manual = false, note = "", sightings = 0, deaths = {} }
  reload()
  eq(ns.Ledger.Victim("Gerd-Forever").guid, A, "A follows the book's key")
  eq(ns.Ledger.Victim("Gerd-Forever#93-0000B2").guid, B, "B steps aside")
  eq(standing("Gerd-Forever"), "1:1 even")
end)

---------------------------------------------------------------------------
-- Duel to the death: my own challenge, a zone change (finding 3)
---------------------------------------------------------------------------
test("My own challenge to the death: held until DUEL_FINISHED (30 s grace), at most 15 min", function()
  fresh()
  local g = seen("Grimm", "Bart", 40)
  M.units.target = M.units["nameplate" .. plate]
  ns.Attribution.OnStartDuel("target", nil, true)
  M.Advance(70); ok(ns.Attribution.DuelFoe(g), "70 s after my challenge: still the opponent")
  kill(g)
  eq(ns.Ledger.Victim("Grimm-Bart"), nil, "his death in the duel is no rap sheet kill")
  -- declined (or over): DUEL_FINISHED ends it
  M.Advance(60)
  ns.Attribution.OnStartDuel("target", nil, true)
  M.FireEvent("DUEL_FINISHED")
  M.Advance(29); ok(ns.Attribution.DuelFoe(g), "grace")
  M.Advance(2); no(ns.Attribution.DuelFoe(g), "over")
  -- nothing ever ends it: let go after 15 min
  ns.Attribution.OnStartDuel("target", nil, true)
  M.Advance(899); ok(ns.Attribution.DuelFoe(g), "held up to 15 min")
  M.Advance(2); no(ns.Attribution.DuelFoe(g), "let go after 15 min")
end)

test("A zone change ends a request that has not started, never a duel under way", function()
  fresh()
  local g = seen("Grimm", "Bart", 40)
  local function challenge()
    _G.GetDuelerInfo = function() return g end
    M.FireEvent("DUEL_TO_THE_DEATH_REQUESTED", "Grimm")
    _G.GetDuelerInfo = nil
  end
  challenge(); M.FireEvent("DUEL_INBOUNDS")
  M.Advance(20); M.FireEvent("ZONE_CHANGED_NEW_AREA")
  M.Advance(31); ok(ns.Attribution.DuelFoe(g), "under way across the zone border")
  kill(g)
  eq(ns.Ledger.Victim("Grimm-Bart"), nil, "his death in the duel is no rap sheet kill")
  M.Advance(31)
  M.units.target = M.units["nameplate" .. plate]
  ns.Attribution.OnStartDuel("target", nil, true)
  M.Advance(20); M.FireEvent("ZONE_CHANGED_NEW_AREA")
  M.Advance(31); ok(ns.Attribution.DuelFoe(g), "my own challenge counts as under way")
  M.FireEvent("PLAYER_ENTERING_WORLD"); M.Advance(31)
  no(ns.Attribution.DuelFoe(g), "a loading screen ends it")
  challenge()
  M.Advance(20); M.FireEvent("ZONE_CHANGED_NEW_AREA")
  M.Advance(31); no(ns.Attribution.DuelFoe(g), "a request to me that never started ends at the zone change")
end)

---------------------------------------------------------------------------
-- No shared tables: Victims and Repute give the caller its own (finding 4)
---------------------------------------------------------------------------
test("A caller who filters or sorts its victim list changes nobody else's", function()
  fresh()
  for i = 1, 3 do kill(seen("Opfer" .. i, "Nach", 40)); M.Advance(20) end
  local mine = ns.Ledger.Victims("recent")
  table.remove(mine, 1)
  table.sort(mine, function(a, b) return a.key > b.key end)
  eq(#ns.Ledger.Victims("recent"), 3)
  eq(ns.Ledger.Victims("recent")[1].key, "Opfer3-Nach")
end)

test("A caller who changes Repute() changes no account, mark or award, also after a reload", function()
  fresh()
  kill(seen("Opfer", "Nach", 40))
  local before = ns.Ledger.Repute()
  local r = ns.Ledger.Repute()
  r.acc.e = r.acc.e + 100; r.mood.e = 1e6; r.share.e = 7; r.best.streak = 99; r.awards.david = 1; r.bands.gelb = 50
  r.tier = 10
  local again = ns.Ledger.Repute()
  eq(again.total, before.total); eq(again.tier, before.tier); eq(again.acc.e, before.acc.e)
  eq(again.mood.e, before.mood.e); eq(again.share.e, before.share.e); eq(again.best.streak, before.best.streak)
  eq(again.awards.david, nil); eq(again.bands.gelb, before.bands.gelb)
  reload()
  eq(ns.Ledger.Repute().total, before.total)
end)

---------------------------------------------------------------------------
-- The tracker with namesakes known by first name only: the GUID beats the first name (finding 7, also in 1.2.2)
---------------------------------------------------------------------------
local G1, G2 = "Player-93-G1", "Player-93-G2"
-- G1 kills me while seen without surname: the book lists "Gerd-<realm>" with GUID G1; then he is out of sight
local function listedG1()
  fresh()
  M.AddEnemy("nameplate1", { name = "Gerd", level = 34, guid = G1 })
  M.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate1")
  dieBy(G1, "Gerd")
  M.units.nameplate1 = nil
  M.Advance(600); ns.Tracker.Prune(true)
  local key = next(ns.Store.All())
  eq(key, "Gerd-Forever")
  return key, ns.Store.Get(key)
end
local function plateG2(n)
  M.AddEnemy("nameplate" .. (n or 2), { name = "Gerd", level = 58, guid = G2 })
  M.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate" .. (n or 2))
end

test("A namesake without surname raises no alarm and is no sighting of the listed one", function()
  local key, e = listedG1()
  local spotted, seen0, n0 = 0, e.lastSeen and e.lastSeen.t, e.sightings
  ns:On("ENEMY_SPOTTED", function(k) if k == key then spotted = spotted + 1 end end)
  plateG2()
  eq(spotted, 0, "ENEMY_SPOTTED")
  eq(e.lastSeen and e.lastSeen.t, seen0, "last seen"); eq(e.sightings, n0, "sightings")
  eq(e.level, 34); eq(e.guid, G1)
  local r = ns.Tracker.ByGUID(G2)
  eq(r and r.key, "Gerd-Forever#93-G2", "the namesake's own buffer key")
  eq(ns.Tracker.UnitFor(key), nil, "his plate is no unit of the listed one")
end)

test("A death by the namesake is no second kill of the listed one; the journal keeps his name", function()
  local key, e = listedG1()
  plateG2()
  dieBy(G2, "Gerd")
  eq(e.kills, 1, "kills of the listed one")
  eq(ns.Store.Count(), 1, "no entry under another key")
  local j = ns.Store.Deaths()[1]
  eq(j.killerKey, nil); eq(j.killerName, "Gerd")
end)

test("The listed one seen again takes the plain buffer key back; reading order changes nothing", function()
  local res = {}
  for _, order in ipairs({ { 1, 2 }, { 2, 1 } }) do
    local key, e = listedG1()
    M.AddEnemy("nameplate1", { name = "Gerd", level = 34, guid = G1 })
    M.AddEnemy("nameplate2", { name = "Gerd", level = 58, guid = G2 })
    for _, n in ipairs(order) do ns.Tracker.OnUnit("nameplate" .. n, "nameplate") end
    res[#res + 1] = ("%s/%s/%s/%s"):format(tostring(e.level), tostring(e.guid), ns.Tracker.ByGUID(G1).key,
      ns.Tracker.ByGUID(G2).key)
  end
  eq(res[1], "34/Player-93-G1/Gerd-Forever/Gerd-Forever#93-G2")
  eq(res[2], res[1], "order 1,2 and 2,1")
  -- unlisted namesakes: the first one seen keeps the plain key, the other one gets his own
  fresh()
  M.AddEnemy("nameplate1", { name = "Gerd", level = 34, guid = G1 })
  M.AddEnemy("nameplate2", { name = "Gerd", level = 58, guid = G2 })
  ns.Tracker.OnUnit("nameplate1", "nameplate"); ns.Tracker.OnUnit("nameplate2", "nameplate")
  eq(ns.Tracker.ByGUID(G1).level, 34); eq(ns.Tracker.ByGUID(G2).level, 58)
  eq(ns.Tracker.Count(), 2)
end)

test("My kill on the namesake (or his honour line with my target on him) is no revenge on the listed one", function()
  local key, e = listedG1()
  plateG2()
  M.Advance(30); kill(G2)
  eq(e.revenge, 0, "PARTY_KILL on the namesake")
  M.units.target = M.units.nameplate2
  M.FireEvent("PLAYER_TARGET_CHANGED")
  M.Advance(30)
  ns.Attribution.OnHonorGain("Gerd stirbt (Ehrenhafter Sieg: Rang 3). Ihr erhaltet 12 Ehre.")
  eq(e.revenge, 0, "honour line with the namesake in the target")
  M.units.target = nil
end)

test("Store: info of another GUID never lands on an entry with a GUID, unless both name the player in full", function()
  local key, e = listedG1()
  ns.Store.Seen(key, { name = "Gerd", guid = G2, level = 58, class = "MAGE" }, { t = time() }, false)
  eq(e.level, 34); eq(e.guid, G1); eq(e.class, "ROGUE")
  ns.Store.Seen(key, { name = "Gerd", guid = G1, level = 35 }, { t = time() }, false)
  eq(e.level, 35, "his own GUID")
  local g = seen("Hans", "Hart", 40)
  local f = ns.Store.Get(select(1, ns.Store.Upsert({ name = "Hans", surname = "Hart", guid = g }, true)))
  ns.Store.Seen("Hans-Hart", { name = "Hans", surname = "Hart", guid = "Player-93-NEU", level = 41 }, { t = time() }, false)
  eq(f.guid, "Player-93-NEU", "a full name with a new GUID is still taken (as in 1.2.x)")
end)

---------------------------------------------------------------------------
-- Gaps of the mutation run (finding 6): REPUTE_RANK only on a tier change, the surname of another GUID, pre on a
-- merge
---------------------------------------------------------------------------
test("A path change without a tier change fires REPUTE_PATH, never REPUTE_RANK", function()
  fresh(20)
  local same, pathOnly, tierBefore = 0, 0, nil
  ns:On("REPUTE_RANK", function(tier, _, oldTier) if tier == oldTier then same = same + 1 end end)
  ns:On("REPUTE_PATH", function(_, _, tier) if tier == tierBefore then pathOnly = pathOnly + 1 end end)
  for i = 1, 3 do tierBefore = ns.Ledger.Repute().tier; kill(seen("Hoch" .. i, "Nach", 35)); M.Advance(20) end
  M.units.player.level = 60
  for i = 1, 12 do tierBefore = ns.Ledger.Repute().tier; kill(seen("Grau" .. i, "Nach", 20)); M.Advance(20) end
  ok(pathOnly >= 1, "a path change without a tier change came (" .. pathOnly .. ")")
  eq(same, 0, "REPUTE_RANK with tier == oldTier")
end)

test("A full name that belongs to another GUID's victim is no key for this GUID (seen with that full name)", function()
  fresh()
  local a = seen("Gerd", "Groll", 40, { guid = "Player-93-A" })
  kill(a); M.Advance(60)
  -- another GUID shows the same full name (a name taken again): never booked onto A's victim
  local b = seen("Gerd", "Groll", 40, { guid = "Player-93-B" })
  kill(b)
  eq(ns.Ledger.VictimCount(), 2)
  local v = ns.Ledger.Victim("Gerd-Groll")
  eq(v.guid, a); eq(v.n, 1)
end)

test("A first name never lands on a victim of another GUID under a book entry without GUID", function()
  fresh()
  local a = seen("Gerd", "Groll", 40, { guid = "Player-93-A" })
  kill(a); M.Advance(60)
  ns.Store.AddManual("Gerd", "Groll")                    -- the book lists him by hand, without GUID
  firstNameOnly("Gerd", { ["Player-93-C"] = true })
  kill("Player-93-C")                                    -- another Gerd, never seen: the first name only
  _G.GetPlayerInfoByGUID = nil
  eq(ns.Ledger.Victim("Gerd-Groll").n, 1, "A's victim")
  eq(ns.Ledger.VictimCount(), 2)
end)

test("Two victims of one player merge with their kills before he was listed (pre adds up)", function()
  fresh()
  local g = "Player-93-0000C3"
  local db = _G.DeathNoteDB
  db.enemies["Gerd-Forever"] = { name = "Gerd", realm = "Forever", guid = g, kills = 1, assists = 0, suspected = 0,
    revenge = 1, revengeAutoAt = time() - 5000, status = "wanted", manual = false, note = "", sightings = 0, deaths = {} }
  local L = db.ledger
  L.victims["Gerd-Forever"] = { key = "Gerd-Forever", name = "Gerd", realm = "Forever", n = 1, pre = 1, pts = 3, dn = 1 }
  L.victims["Gerd-Groll"] = { key = "Gerd-Groll", name = "Gerd", surname = "Groll", guid = g, n = 1, pre = 1, pts = 3,
    dn = 1 }
  reload()
  eq(ns.Ledger.VictimCount(), 1)
  local v = ns.Ledger.Victim("Gerd-Forever")
  eq(v.n, 2); eq(v.pre, 2); eq(v.guid, g); eq(v.surname, "Groll")
  eq(standing("Gerd-Forever"), "3:1 ahead", "max(2 kills, 1 revenge + 2 before he was listed)")
end)

---------------------------------------------------------------------------
-- More gaps found by the mutation run of these fixes
---------------------------------------------------------------------------
test("A full name the book lists with another GUID is no key for a GUID the tracker saw with it", function()
  fresh()
  -- B seen as "Gerd Groll" while nobody is listed; then A, never seen, kills me and the recap names him in full
  local b = seen("Gerd", "Groll", 40, { guid = "Player-93-B" })
  M.units.x1 = { exists = false, guid = "Player-93-A", name = "Gerd", class = "ROGUE" }
  dieBy("Player-93-A", "Gerd Groll")
  M.units.x1 = nil
  eq(ns.Store.Get("Gerd-Groll").guid, "Player-93-A", "the book lists Gerd Groll with GUID A")
  M.Advance(10); kill(b)                                 -- my kill on B, whom the tracker knows as Gerd Groll
  eq(ns.Ledger.Victim("Gerd-Groll"), nil, "no victim of B under A's book key")
  eq(standing("Gerd-Groll"), "0:1 open")
end)

test("A hand entry of a first name taken by a namesake's full name: the other GUID's victim stays", function()
  fresh()
  firstNameOnly("Gerd", { [A] = true })
  ns.Store.AddManual("Gerd")                             -- by hand, first name only, no GUID
  kill(A)                                                -- A never seen: joined with the hand entry by name
  _G.GetPlayerInfoByGUID = nil
  eq(ns.Ledger.Victim("Gerd-Forever").guid, A)
  M.Advance(60); seen("Gerd", "Bolz", 40, { guid = B })   -- B takes the hand entry with his full name and GUID
  eq(ns.Store.ByGUID(B), "Gerd-Bolz")
  eq(ns.Ledger.Victim("Gerd-Bolz"), nil, "A's victim does not follow B's entry")
  eq(ns.Ledger.Victim("Gerd-Forever").guid, A)
end)

test("The check at start: a victim under a key the book lists with another GUID steps aside", function()
  fresh()
  firstNameOnly("Gerd", { [B] = true })
  kill(B)
  _G.GetPlayerInfoByGUID = nil
  local db = _G.DeathNoteDB
  db.enemies["Gerd-Forever"] = { name = "Gerd", realm = "Forever", guid = A, kills = 1, assists = 0, suspected = 0,
    revenge = 0, status = "wanted", manual = false, note = "", sightings = 0, deaths = {} }
  reload()
  eq(ns.Ledger.Victim("Gerd-Forever"), nil)
  eq(ns.Ledger.Victim("Gerd-Forever#93-0000B2").guid, B)
end)

-- G2 seen without surname before anybody is listed; then G1, never seen, kills me: the book lists G1 under the
-- plain key the tracker gave G2
local function namesakeFirst()
  fresh()
  M.AddEnemy("nameplate2", { name = "Gerd", level = 58, guid = G2 })
  M.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate2")
  eq(ns.Tracker.ByGUID(G2).key, "Gerd-Forever")
  M.units.x1 = { exists = false, guid = G1, name = "Gerd", class = "ROGUE" }
  dieBy(G1, "Gerd")
  M.units.x1 = nil
  eq(ns.Store.Get("Gerd-Forever").guid, G1)
end

test("The listed one seen later takes the tracker's plain key from the namesake", function()
  namesakeFirst()
  M.Advance(2)
  M.AddEnemy("nameplate1", { name = "Gerd", level = 34, guid = G1 })
  M.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate1")
  eq(ns.Tracker.ByGUID(G1) and ns.Tracker.ByGUID(G1).key, "Gerd-Forever")
  eq(ns.Tracker.ByGUID(G2) and ns.Tracker.ByGUID(G2).key, "Gerd-Forever#93-G2")
end)

test("My kill on a namesake the tracker holds under the listed one's plain key is no revenge", function()
  namesakeFirst()
  M.Advance(2); kill(G2)
  eq(ns.Store.Get("Gerd-Forever").revenge, 0)
end)

test("A namesake who targeted me stands in the journal under the plain key, never the tracker's own key", function()
  local key, e = listedG1()
  M.AddEnemy("nameplate2", { name = "Gerd", level = 58, guid = G2, target = "player" })
  M.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate2")
  M.recap = nil
  M.FireEvent("PLAYER_DEAD"); M.Advance(5)
  local j = ns.Store.Deaths()[1]
  local text = table.concat(j.candidates or {}, " ")
  no(text:find("#", 1, true), "candidates: " .. text)
  eq(e.kills, 1, "no kill of the listed one")
end)

M.done("ledger_fixes_e")
