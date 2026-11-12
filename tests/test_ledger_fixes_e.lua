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

M.done("ledger_fixes_e")
