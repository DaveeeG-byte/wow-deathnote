-- Rap sheet (1.3.0): differential run against 1.2.2 (commit 374cf7f, read with git). The same random events go
-- through 1.2.2 and through these files, one after the other in this Lua state (same string hashing, the events are
-- drawn before either runs). Checked every 5 steps:
--   the book (enemies without the new field revengeForeign) and the journal are the same as in 1.2.2;
--   the bounty of every book entry is never higher than in 1.2.2 (kills before he was listed may lower it).
-- Events: sightings (namesakes), own, pet's and others' PARTY_KILL, honour lines, revenge without a killing blow,
-- deaths, revenge by hand and back, status, removal, duels (normal), instances, group, export and import, relogs,
-- time jumps. Usage: luajit tests/test_ledger_diff.lua [seeds] [steps] [first seed]
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local M = require("mock_wow")
local ROOT = (arg[0]:match("^(.*)/tests/") or ".")

local SEEDS = tonumber(arg[1]) or 40
local STEPS = tonumber(arg[2]) or 200
local FIRST = tonumber(arg[3]) or 1
local BASE = "374cf7f"

-- 1.2.2 into a temporary folder
local OLD = os.tmpname()
os.remove(OLD)
assert(os.execute('mkdir -p "' .. OLD .. '" && git -C "' .. ROOT .. '" archive ' .. BASE .. ' DeathNote | tar -x -C "' .. OLD
  .. '" 2>/dev/null') == 0 or true)
OLD = OLD .. "/DeathNote/"
assert(io.open(OLD .. "Store.lua"), "git archive " .. BASE .. " (needs the repository)")
local OLDFILES = {}
-- only the files 1.2.2 has (it knows neither the rap sheet nor the theme core)
for _, f in ipairs(M.FILES) do
  local h = io.open(OLD .. f)
  if h then h:close(); OLDFILES[#OLDFILES + 1] = f end
end

local ME = "Player-93-0000AAAA"
local NAMES = { "Grimm", "Anna", "Bernd", "Carla", "Dora", "Edda", "Fritz", "Gerd" }
local SUR = { "Eins", "Zwei" }

local function events(seed)
  math.randomseed(seed)
  local list = {}
  for step = 1, STEPS do
    list[step] = { i = math.random(#NAMES), j = math.random(2), x = math.random(100), lv = math.random(20, 60),
      withSur = math.random(4) > 1, att = math.random(6), adv = math.random(7), misc = math.random(3),
      id = math.random(1, 1e6) }
  end
  return list
end

local function ser(v)
  if type(v) ~= "table" then return tostring(v) end
  local keys = {}
  for k in pairs(v) do if k ~= "revengeForeign" then keys[#keys + 1] = k end end
  table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
  local out = {}
  for _, k in ipairs(keys) do out[#out + 1] = tostring(k) .. "=" .. ser(v[k]) end
  return "{" .. table.concat(out, ",") .. "}"
end

local function run(seed, dir, files)
  local ev = events(seed)
  _G.DeathNoteDB = nil
  M.Reset()
  local opts = { dir = dir, files = files }
  local ns = M.Load(opts)
  local out = {}
  for step = 1, STEPS do
    local e = ev[step]
    local name, sur = NAMES[e.i], SUR[e.j]
    local guid = "Player-93-D" .. e.i .. e.j
    -- only the first of two namesakes is ever seen without surname: two surnameless plates of one first name share
    -- one tracker record and their order decides (a fault of 1.2.2 itself, see the report of fixer C)
    local withSur = e.withSur or e.j == 2
    local tok = "nameplate" .. (e.i * 2 + e.j)
    local x = e.x
    pcall(function()
      if x <= 22 then
        M.AddEnemy(tok, { name = name, surname = withSur and sur or nil, guid = guid, level = e.lv })
        M.FireEvent("NAME_PLATE_UNIT_ADDED", tok)
      elseif x <= 34 then
        M.units.pet = { exists = true, guid = "Pet-0-1" }
        M.FireEvent("PARTY_KILL", ({ ME, ME, ME, "Pet-0-1", "Player-93-Kollege", "Creature-0-1" })[e.att], guid)
      elseif x <= 40 then
        M.FireEvent("CHAT_MSG_COMBAT_HONOR_GAIN", name .. (withSur and (" " .. sur) or "")
          .. " stirbt (Ehrenhafter Sieg: Rang 2). Ihr erhaltet 7 Ehre.")
      elseif x <= 45 then
        M.units.target = M.units[tok]; M.FireEvent("PLAYER_TARGET_CHANGED"); M.FireEvent("PLAYER_PVP_KILLS_CHANGED")
      elseif x <= 60 then
        M.recap = { id = e.id, events = { { sourceGUID = guid, sourceName = name, amount = 900, overkill = 120,
          timestamp = time() - 1, spellName = "Hieb" } } }
        M.FireEvent("PLAYER_DEAD"); M.Advance(6)
      elseif x <= 64 then ns.Store.AddRevenge(name .. "-" .. sur, true)
      elseif x <= 67 then ns.Store.UndoRevenge(name .. "-" .. sur)
      elseif x <= 70 then ns.Store.SetStatus(name .. "-" .. sur, ({ "wanted", "pardoned", "suspect" })[e.misc])
      elseif x <= 72 then ns.Store.Remove(name .. "-" .. sur)
      elseif x <= 75 then M.FireEvent(({ "DUEL_REQUESTED", "DUEL_INBOUNDS", "DUEL_FINISHED" })[e.misc])
      elseif x <= 77 then M.instance = (e.misc == 1) and { true, "pvp" } or { false, "none" }
      elseif x <= 79 then M.units.party1 = (e.misc == 1) and { exists = true, isPlayer = true, name = "Kollege" } or nil
      elseif x <= 81 then ns.Store.Import(ns.Store.Export(e.misc == 1))
      elseif x <= 84 then
        local db = _G.DeathNoteDB
        opts.db, opts.keepWorld = db, true
        ns = M.Load(opts)
      else M.Advance(({ 1, 5, 11, 20, 60, 700, 90000 })[e.adv]) end
    end)
    if step % 5 == 0 or step == STEPS then
      local db = _G.DeathNoteDB
      local b = {}
      for k, en in pairs(ns.Store.All()) do b[k] = ns.Store.Bounty(en) end
      out[#out + 1] = { book = ser(db.enemies), journal = ser(db.deaths), bounty = b, errors = #M.errors }
    end
  end
  return out
end

local checks, books, entries, lower, higher, bookDiff, errors = 0, 0, 0, 0, 0, 0, 0
local firstHigher, firstBook
for seed = FIRST, FIRST + SEEDS - 1 do
  local a = run(seed, OLD, OLDFILES)
  local b = run(seed, nil, nil)
  for k = 1, #a do
    checks = checks + 1
    if a[k].book ~= b[k].book or a[k].journal ~= b[k].journal then
      bookDiff = bookDiff + 1
      firstBook = firstBook or ("seed " .. seed .. ", checkpoint " .. k)
    else
      books = books + 1
    end
    errors = errors + b[k].errors
    for key, old in pairs(a[k].bounty) do
      local new = b[k].bounty[key]
      if new then
        entries = entries + 1
        if new > old then
          higher = higher + 1
          firstHigher = firstHigher or ("seed %d, checkpoint %d, %s: %d > %d"):format(seed, k, key, new, old)
        elseif new < old then lower = lower + 1 end
      end
    end
  end
end
os.execute('rm -rf "' .. OLD:gsub("/DeathNote/$", "") .. '"')

local red = higher > 0 or bookDiff > 0 or errors > 0
io.write(("%-18s %d seeds x %d steps, %d checkpoints (book same: %d), %d bounties: higher %d, lower %d, %s\n"):format(
  "ledger_diff", SEEDS, STEPS, checks, books, entries, higher, lower, red and "ROT" or "0 rot"))
if firstHigher then io.write("  ROT: bounty higher than 1.2.2: " .. firstHigher .. "\n") end
if firstBook then io.write("  ROT: book differs from 1.2.2: " .. firstBook .. "\n") end
if errors > 0 then io.write("  ROT: " .. errors .. " addon errors\n") end
os.exit(red and 1 or 0)
