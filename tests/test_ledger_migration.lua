-- Rap sheet (1.3.0): DB version 3 -> 4, the check at every start (idempotent), and up, back, up again with
-- 1.2.0 (tests/fixtures/addon-1.2.0), 1.2.1 (the tag v1.2.1, read with git) and 1.2.2 (these files without the
-- rap sheet, DB version 3). Fixtures are loaded, never quoted. All names are invented.
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local M = require("mock_wow")
local test, eq, ok, no = M.test, M.eq, M.ok, M.no
local ROOT = (arg[0]:match("^(.*)/tests/") or ".")

local function copy(t, seen)
  if type(t) ~= "table" then return t end
  seen = seen or {}
  if seen[t] then return seen[t] end
  local c = {}
  seen[t] = c
  for k, v in pairs(t) do c[copy(k, seen)] = copy(v, seen) end
  return c
end
local function same(a, b, path)
  path = path or "ledger"
  if type(a) ~= type(b) then return path end
  if type(a) ~= "table" then return a ~= b and path or nil end
  for k, v in pairs(a) do local x = same(v, b[k], path .. "." .. tostring(k)) if x then return x end end
  for k in pairs(b) do if a[k] == nil then return path .. "." .. tostring(k) end end
  return nil
end

-- a book of version 3 as 1.2.1 writes it
local function v3book()
  local t0 = 1700000000
  local function entry(name, surname, kills, revenge, hand, extra)
    local e = { name = name, surname = surname, display = name .. " " .. surname, realm = surname, kills = kills,
      assists = 0, suspected = 0, revenge = revenge, status = "wanted", manual = false, note = "", sightings = 1,
      deaths = {}, guid = "Player-93-" .. name, level = 40, class = "ROGUE", lastRevenge = t0 + 50 }
    if hand and hand > 0 then e.revengeHand = hand; e.revengeHandAt = {}; for i = 1, hand do e.revengeHandAt[i] = t0 + i end end
    for k, v in pairs(extra or {}) do e[k] = v end
    return e
  end
  return { version = 3, settings = {}, deaths = {}, enemies = {
    ["Grimm-Bart"] = entry("Grimm", "Bart", 3, 3, 1, { revengeAutoAt = t0 + 40 }),   -- 2 recognised, 1 by hand
    ["Viel-Rache"] = entry("Viel", "Rache", 14, 12, 0),                               -- 12 recognised, 10 score
    ["Nur-Hand"] = entry("Nur", "Hand", 1, 1, 1),                                     -- only by hand
    ["Kein-Mal"] = entry("Kein", "Mal", 2, 0, 0),
  } }
end

-- the bounty of 1.2.x: the same function with the rap sheet switched off (it then reads revenge)
local function oldBounty(ns, e)
  ns.Store.Setting("ledger.enabled", false)
  local x = ns.Store.Bounty(e)
  ns.Store.Setting("ledger.enabled", true)
  return x
end

test("Migration 3 -> 4: only the empty structure; no victim, no point, me = the book's revenge", function()
  local ns = M.Load({ db = v3book() })
  local db = _G.DeathNoteDB
  eq(db.version, 4)
  local L = ns.Ledger
  eq(L.VictimCount(), 0, "no victim from the book's revenge")
  local rp = L.Repute()
  eq(rp.total, 0); eq(rp.n, 0); eq(rp.counted, 0); eq(rp.tier, 1); eq(rp.path, nil)
  eq(db.ledger.tier, 1); eq(db.ledger.path, nil)
  local function st(key) local m, h, s = L.Standing(key) return m .. ":" .. h .. " " .. s end
  eq(st("Grimm-Bart"), "3:3 even", "2 recognised + 1 by hand")
  eq(st("Viel-Rache"), "12:14 open"); eq(st("Nur-Hand"), "1:1 even"); eq(st("Kein-Mal"), "0:2 open")
  for key, e in pairs(ns.Store.All()) do eq(ns.Store.Bounty(e), oldBounty(ns, e), "bounty as in 1.2.x: " .. key) end
  eq(#M.Fired("REPUTE_RANK"), 0)
end)

test("The start is idempotent and books nothing (Store.Init 21 times)", function()
  local ns = M.Load({ db = v3book() })
  local first = copy(_G.DeathNoteDB.ledger)
  for _ = 1, 21 do ns.Store.Init() end
  eq(same(first, _G.DeathNoteDB.ledger), nil, "unchanged")
  eq(_G.DeathNoteDB.version, 4)
  eq(ns.Ledger.Repute().total, 0)
end)

test("Fixture 1.0.1 -> 4: no victim, no point; standing and bounty read the book's revenge", function()
  local fx = {}
  local f = assert(loadfile(ROOT .. "/tests/fixtures/sv_1.0.1_autor.lua")); setfenv(f, fx); f()
  local ns = M.Load({ db = copy(fx.DeathNoteDB) })
  local L = ns.Ledger
  local nRev = 0
  for key, e in pairs(ns.Store.All()) do
    if (e.revenge or 0) > 0 then nRev = nRev + 1 end
    eq((L.Standing(key)), e.revenge or 0, key)
    eq(ns.Store.Bounty(e), oldBounty(ns, e), "bounty " .. key)
  end
  ok(nRev > 0, "the fixture has revenge")
  eq(L.VictimCount(), 0); eq(L.Repute().n, 0); eq(L.Repute().total, 0)
  local snap = copy(_G.DeathNoteDB.ledger)
  ns.Store.Init()
  eq(same(snap, _G.DeathNoteDB.ledger), nil)
end)

test("The start does nothing while the rap sheet is switched off", function()
  local b = v3book()
  b.settings = { ledger = { enabled = false } }
  b.version = 4
  b.ledger = { victims = { ["Alt-Er"] = { name = "Alt", guid = "Player-93-Grimm", n = 2 } } }
  local ns = M.Load({ db = b })
  ok(ns.Ledger.Victim("Alt-Er"), "no move while off")
  eq(ns.Ledger.Victim("Grimm-Bart"), nil)
end)

test("Broken ledger data is repaired, never an error", function()
  local b = v3book()
  b.version = 4
  b.ledger = { v = "x", victims = { ["Gut-Er"] = { name = "Gut", surname = "Er", n = 2, pts = 1 / 0, last = 0 / 0 },
    ["Bad"] = "x", [5] = { n = 1 }, ["Null-Er"] = { n = 0 }, ["Neg-Er"] = { n = -3 } },
    log = { { t = 5, key = "Gut-Er", band = "lila", r = -1, e = "x", f = "zz" }, "x", { key = 1 } },
    acc = { r = -5, e = 0 / 0, j = "x" }, mood = "x", n = -1, tier = 99, path = "q", bands = { grau = -1, lila = 4 },
    best = { gap = -1, streak = 1 / 0 }, cur = "x", awards = { first_entry = "x", nope = 1, david = 5 }, gone = { 5 } }
  b.ledger.victims["Gut-Er"].old = 2
  local ns = M.Load({ db = b })
  local d = _G.DeathNoteDB.ledger
  eq(d.victims["Gut-Er"].n, 2); eq(d.victims["Gut-Er"].pts, 0); eq(d.victims["Gut-Er"].last, nil)
  eq(d.victims.Bad, nil); eq(d.victims[5], nil); eq(d.victims["Null-Er"], nil); eq(d.victims["Neg-Er"], nil)
  eq(#d.log, 1); eq(d.log[1].band, "unbekannt"); eq(d.log[1].r, 0); eq(d.log[1].f, "")
  eq(d.acc.r, 0); eq(d.tier >= 1 and d.tier <= 10, true); eq(d.path ~= "q", true)
  eq(d.awards.first_entry, nil); eq(d.awards.nope, nil); eq(d.awards.david, 5)
  eq(d.gone, nil, "marks of the 1.3.0 test builds go"); eq(d.victims["Gut-Er"].old, nil)
  eq(#M.errors, 0, M.errors[1])
  ok(ns.Ledger.OnPartyKill ~= nil)
end)

---------------------------------------------------------------------------
-- Up, back, up again
---------------------------------------------------------------------------
local LOGIC = { "Locale.lua", "Locales/enUS.lua", "Locales/deDE.lua", "Core.lua", "Store.lua", "Tracker.lua",
  "Attribution.lua", "Probe.lua", "Sync.lua", "Friends.lua", "Bounty.lua" }

-- the logic files of the tag v1.2.1, read with git into a temporary folder
local function tag121()
  local dir = os.tmpname()
  os.remove(dir)
  assert(os.execute('mkdir -p "' .. dir .. '/Locales"') == 0 or true)
  for _, f in ipairs(LOGIC) do
    local p = io.popen('git -C "' .. ROOT .. '" show v1.2.1:DeathNote/' .. f .. ' 2>/dev/null')
    local src = p:read("*a"); p:close()
    assert(src and #src > 100, "git show v1.2.1:" .. f .. " (needs the repository with its tags)")
    local h = assert(io.open(dir .. "/" .. f, "wb")); h:write(src); h:close()
  end
  return dir .. "/"
end

local V120 = ROOT .. "/tests/fixtures/addon-1.2.0/"
local FILES120 = { "Locale.lua", "Locales/enUS.lua", "Locales/deDE.lua", "Core.lua", "Store.lua", "Tracker.lua",
  "Attribution.lua", "Probe.lua", "Sync.lua", "Friends.lua" }
-- 1.2.2 = these files without Ranks.lua and Ledger.lua and with DB version 3 (Store calls the rap sheet only when
-- it is there)
local FILES122 = {}
for _, f in ipairs(M.FILES) do if f ~= "Ranks.lua" and f ~= "Ledger.lua" then FILES122[#FILES122 + 1] = f end end
local function patch122(f, src)
  if f == "Store.lua" then return (src:gsub("local DB_VERSION = 4", "local DB_VERSION = 3")) end
  return src
end

local function run(W, name, db, opts)
  opts = opts or {}
  local c = W.client("Anton", "Wurst", nil, { db = db, dir = opts.dir, files = opts.files, patch = opts.patch,
    version = opts.version })
  c.login(); W.run(2)
  return c
end
local function out(W, c)
  c.fire("PLAYER_LOGOUT")
  local db = copy(c.env.DeathNoteDB)
  c.loggedIn = false
  for i = #W.clients, 1, -1 do if W.clients[i] == c then table.remove(W.clients, i) end end
  return db
end
local function partyKill(W, c, guid) c.fire("PARTY_KILL", W.guidOf(c), guid) end

for _, old in ipairs({ { "1.2.0", V120, FILES120 }, { "1.2.1", "tag", nil }, { "1.2.2", nil, FILES122, patch122 } }) do
  test("Up to 1.3.0, back to " .. old[1] .. ", up again: no error, nothing lost, nothing booked, standing as before",
    function()
    M.Reset()
    local W = M.NewWorld()
    local dir = old[2] == "tag" and tag121() or old[2]
    local files = old[3] or LOGIC
    -- 1.3.0: a converted book and two own kills
    local c = run(W, "1.3.0", v3book())
    M.AddEnemy("nameplate1", { name = "Grimm", surname = "Bart", guid = "Player-93-Grimm", level = 40 })
    M.AddEnemy("nameplate2", { name = "Neu", surname = "Ling", guid = "Player-93-Neu", level = 40 })
    c.fire("NAME_PLATE_UNIT_ADDED", "nameplate1"); c.fire("NAME_PLATE_UNIT_ADDED", "nameplate2")
    partyKill(W, c, "Player-93-Grimm"); W.run(11); partyKill(W, c, "Player-93-Neu"); W.run(11)
    eq(c.ns.Ledger.Victim("Grimm-Bart").n, 1); eq(c.ns.Ledger.Victim("Neu-Ling").n, 1)
    local total = c.ns.Ledger.Repute().total
    local db = out(W, c)
    local ledger = copy(db.ledger)
    eq(db.version, 4)
    -- back: the old version plays, recognises one more revenge, leaves the rap sheet alone
    c = run(W, old[1], db, { dir = dir, files = files, patch = old[4], version = old[1] })
    eq(#M.errors, 0, M.errors[1])
    c.fire("NAME_PLATE_UNIT_ADDED", "nameplate1")
    W.run(20)
    partyKill(W, c, "Player-93-Grimm"); W.run(11)
    eq(c.env.DeathNoteDB.enemies["Grimm-Bart"].revenge, 5, old[1] .. " counts revenge")
    db = out(W, c)
    eq(db.version, 4, "the old version keeps version 4")
    eq(same(ledger, db.ledger), nil, old[1] .. " leaves the rap sheet as it was")
    -- up again: the revenge of the old version counts in the standing through the book, nothing is booked
    c = run(W, "1.3.0", db)
    eq(same(ledger, c.env.DeathNoteDB.ledger), nil, "the start books nothing")
    local v = c.ns.Ledger.Victim("Grimm-Bart")
    eq(v.n, 1, "own kills stay"); eq(v.old, nil)
    eq(c.ns.Ledger.Repute().total, total, "no point for the old version's revenge")
    local mine, his = c.ns.Ledger.Standing("Grimm-Bart")
    eq(mine .. ":" .. his, "5:3", "me = 4 recognised + 1 by hand")
    eq(c.ns.Ledger.Victim("Neu-Ling").n, 1, "a victim outside the book survives the way back")
    local snap = copy(c.env.DeathNoteDB.ledger)
    c.ns.Store.Init()
    eq(same(snap, c.env.DeathNoteDB.ledger), nil, "idempotent after the way back")
    eq(#M.errors, 0, M.errors[1])
  end)
end

M.done("ledger_migration")
