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

M.done("ledger_fixes_e")
