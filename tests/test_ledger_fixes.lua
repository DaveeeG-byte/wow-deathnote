-- Rap sheet (1.3.0): fixes after the bug hunt on the rap sheet (rule "me", import, detection, duel, keys, caps,
-- clock, ranks). One block per finding; every test was red before its fix. All names are invented.
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local M = require("mock_wow")
local test, eq, ok, no = M.test, M.eq, M.ok, M.no

local ME = "Player-93-0000AAAA"
local LINE = " stirbt (Ehrenhafter Sieg: Rang 3). Ihr erhaltet 12 Ehre."

local ns, plate = nil, 0
local function fresh(level, opts)
  _G.DeathNoteDB = nil
  ns = M.Load(opts); plate = 0
  M.units.player.level = level or 40
  return ns
end
local function load(db, level)
  ns = M.Load({ db = db }); plate = 0
  M.units.player.level = level or 40
  return ns
end
local function reload(level) return load(_G.DeathNoteDB, level) end
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
-- a book entry of version 3 as 1.2.x writes it
local function entry(name, surname, kills, revenge, extra)
  local e = { name = name, surname = surname, display = surname and (name .. " " .. surname) or nil, kills = kills,
    assists = 0, suspected = 0, revenge = revenge, status = "wanted", manual = false, note = "", sightings = 1,
    deaths = {}, lastRevenge = 1700000000 }
  for k, v in pairs(extra or {}) do e[k] = v end
  return e
end
-- the bounty of 1.2.x: the same function with the rap sheet switched off (it then reads revenge)
local function oldBounty(e)
  local Lg = ns.Ledger
  ns.Ledger = nil
  local x = ns.Store.Bounty(e)
  ns.Ledger = Lg
  return x
end
local function standing(key)
  local m, h, s = ns.Ledger.Standing(key)
  return tostring(m) .. ":" .. tostring(h) .. " " .. tostring(s)
end

---------------------------------------------------------------------------
-- "me" = max(own kills, recognised revenge + kills before he was listed) + by hand (findings 2, 7, 8, 9, E11)
---------------------------------------------------------------------------
test("Revenge without an own killing blow (pvpkills): standing and bounty at once, nothing jumps at a reload", function()
  fresh()
  local g = seen("Grimm", "Bart", 40)
  ns.Store.ApplyKill({ name = "Grimm", surname = "Bart", guid = g }, { t = time() - 100 }, true)
  M.units.target = M.units.nameplate1; M.FireEvent("PLAYER_TARGET_CHANGED")
  kill(g, "Player-93-Kollege")                     -- a guildmate has the killing blow
  M.FireEvent("PLAYER_PVP_KILLS_CHANGED")
  local e = ns.Store.Get("Grimm-Bart")
  eq(e.revenge, 1, "the book counts it as before"); eq(ns.Attribution.lastRevengeHow, "pvpkills")
  eq(standing("Grimm-Bart"), "1:1 even", "the book's revenge counts for the standing")
  eq(ns.Store.Bounty(e), oldBounty(e), "bounty as in 1.2.x")
  eq(ns.Ledger.Victim("Grimm-Bart"), nil, "no own kill booked")
  reload()
  eq(standing("Grimm-Bart"), "1:1 even", "the same after a reload")
  eq(ns.Ledger.Repute().total, 0, "no repute for a kill that was not mine")
  eq(ns.Ledger.Repute().n, 0)
end)

test("Up, back, up: the book entry moved under 1.2.x; the victim follows by GUID, nothing is booked twice", function()
  fresh()
  M.units.x1 = { exists = false, guid = "Player-93-G1", name = "Grimm", class = "ROGUE", classLoc = "Schurke" }
  ns.Store.ApplyKill({ name = "Grimm", guid = "Player-93-G1" }, { t = time() - 100 }, true)
  kill("Player-93-G1"); M.Advance(700); kill("Player-93-G1")
  local key = next(ns.Store.All())
  eq((ns.Ledger.Standing(key)), 2)
  local before = ns.Ledger.Repute().total
  -- what 1.2.x writes when it moves the entry (Store.Promote there): new key, surname, nothing else
  local db = _G.DeathNoteDB
  local e = db.enemies[key]; db.enemies[key] = nil
  e.surname, e.display = "Bart", "Grimm Bart"; db.enemies["Grimm-Bart"] = e
  reload()
  eq((ns.Ledger.Standing("Grimm-Bart")), 2, "own kills after up, back, up")
  eq(ns.Ledger.Repute().total, before, "accounts unchanged")
  eq(ns.Ledger.Repute().n, 2)
  local v = ns.Ledger.Victim("Grimm-Bart")
  ok(v, "the victim moved to the book's key"); eq(v and v.n, 2); eq(ns.Ledger.Victim(key), nil)
  local snap = ns.Ledger.Repute().total
  for _ = 1, 5 do ns.Store.Init() end
  eq(ns.Ledger.Repute().total, snap)
end)

test("Up, back, up: revenge 1.2.x recognised on top of kills before he was listed reaches the standing", function()
  fresh()
  local a = seen("Anna", "Ast", 40)
  kill(a); M.Advance(700); seen("Anna", "Ast", 40, { guid = a }); kill(a)
  for i = 1, 3 do ns.Store.ApplyKill({ name = "Anna", surname = "Ast", guid = a }, { t = time() + i }, true) end
  eq(standing("Anna-Ast"), "2:3 open")
  local e = _G.DeathNoteDB.enemies["Anna-Ast"]   -- 1.2.x recognises one revenge
  e.revenge = e.revenge + 1; e.revengeAutoAt = time(); e.lastRevenge = time()
  reload()
  eq(standing("Anna-Ast"), "3:3 even")
end)

test("Striking a victim from the rap sheet never raises the bounty of a listed enemy", function()
  fresh()
  local a = seen("Anna", "Ast", 40)
  ns.Store.ApplyKill({ name = "Anna", surname = "Ast", guid = a }, { t = time() - 50 }, true)
  kill(a)
  local e = ns.Store.Get("Anna-Ast")
  eq(e.revenge, 1)
  local b = oldBounty(e)
  eq(ns.Store.Bounty(e), b)
  ok(ns.Ledger.RemoveVictim("Anna-Ast"))
  eq(ns.Store.Bounty(e), b, "after striking")
  eq(standing("Anna-Ast"), "1:1 even")
end)

test("The book's revenge never turns into repute at the start (30 enemies with 4 revenges: rank 1)", function()
  local db = { version = 3, settings = {}, deaths = {}, enemies = {} }
  for i = 1, 30 do
    local n = "R" .. string.char(97 + math.floor(i / 26)) .. string.char(97 + i % 26)
    db.enemies[n .. "-Alt"] = entry(n, "Alt", 5, 4, { guid = "Player-93-" .. n })
  end
  load(db)
  local r = ns.Ledger.Repute()
  eq(r.total, 0); eq(r.tier, 1); eq(r.n, 0); eq(ns.Ledger.VictimCount(), 0)
  eq((ns.Ledger.Standing("Rab-Alt")), 4, "me = the book's revenge")
  local e = _G.DeathNoteDB.enemies["Rab-Alt"]; e.revenge = 7         -- 1.2.x recognises three more
  reload()
  eq(ns.Ledger.Repute().total, 0); eq((ns.Ledger.Standing("Rab-Alt")), 7, "me = the book's revenge")
end)

M.done("ledger_fixes")
