-- Rap sheet (1.3.0): differential run against 1.2.2 (commit 374cf7f, read with git). The same random events go
-- through 1.2.2 and through these files, one after the other in this Lua state (same string hashing, the events are
-- drawn before either runs). Checked every 5 steps:
--   the book (enemies without the new field revengeForeign) and the journal are the same as in 1.2.2;
--   the bounty of every book entry is never higher than in 1.2.2 (kills before he was listed may lower it);
--   counted per GUID in this version: "me" of a book entry is never above the own killing blows booked on that GUID
--   plus the revenge recognised without a killing blow plus revenge by hand; never a book entry and a victim of two
--   GUIDs under one key; never one GUID under two keys (book here, rap sheet there).
-- One narrow exception, counted: namesakes known by first name only. 1.3.0 lets the GUID beat the first name where
-- 1.2.2 took a surnameless player for the one listed under "Name-Realm" (alarm, last seen, a deed credited to the
-- wrong entry). From the first step in which a player of first name N with GUID g meets a book entry (or a tracker
-- record, for a surnameless unit) under "N-<realm>" that carries another GUID, the entries of first name N and the
-- journal rows naming N are left out of the comparison with 1.2.2 for that seed (the GUID checks above still hold
-- for them). Everything else must stay the same.
-- Events: sightings (namesakes, with and without surname), own, pet's and others' PARTY_KILL, honour lines, revenge
-- without a killing blow, deaths, revenge by hand and back, status, removal, duels (normal), instances, group, export
-- and import, relogs, time jumps. Usage: luajit tests/test_ledger_diff.lua [seeds] [steps] [first seed]
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

local REALM = "Forever"   -- the mock's realm: placeholders are "Name-Forever"

-- Which first names meet the precondition of the exception in this step (see the head)? Read on this version
-- before the step, as narrow as the code paths that differ:
--   a surnameless unit in sight (a plate, the target; a death re-reads them all) whose "Name-<realm>" is listed or
--   buffered with another GUID;
--   a death by, or my PARTY_KILL on, a player the tracker knows by first name only (or not at all) and the book not
--   by his GUID, while "Name-<realm>" is listed with another GUID;
--   an honour line naming a first name only while my target is such a surnameless namesake;
--   two surnameless units of one first name with two GUIDs in sight at once.
local function plainOf(name) return name .. "-" .. REALM end
local function otherListed(ns, name, guid)
  local e = ns.Store.Get(plainOf(name))
  return e ~= nil and type(e.guid) == "string" and e.guid ~= guid and not ns.Store.ByGUID(guid)
end
local function namesakeUnit(ns, u)
  if not (u and u.exists and u.isPlayer and u.name and u.guid) or u.surname then return nil end
  local e = ns.Store.Get(plainOf(u.name))
  if e and type(e.guid) == "string" and e.guid ~= u.guid then return u.name end
  local r = ns.Tracker.Get(plainOf(u.name))
  if r and r.guid and r.guid ~= u.guid then return u.name end
  return nil
end
-- two surnameless units of one first name with two GUIDs in sight at once (1.2.2 shares one tracker record between
-- them and the reading order decides: the fault of the report of fixer C)
local function twoInSight(taint)
  local seen = {}
  for k, u in pairs(M.units) do
    if (k:find("^nameplate") or k == "target" or k == "focus" or k == "mouseover") and u.exists and u.isPlayer
      and u.name and u.guid and not u.surname then
      if seen[u.name] and seen[u.name] ~= u.guid then taint[u.name] = true end
      seen[u.name] = u.guid
    end
  end
end

local function namesakeStep(ns, x, att, name, guid, tok, withSur, taint)
  local function mark(n) if n and not taint[n] then taint[n] = true end end
  if x <= 60 then twoInSight(taint) end
  if x <= 22 then
    -- the plate this step adds
    mark(namesakeUnit(ns, { exists = true, isPlayer = true, name = name, guid = guid, surname = withSur or nil }))
  elseif x <= 34 then
    if att <= 4 then
      local r = ns.Tracker.ByGUID(guid)
      if (not r or not r.surname) and otherListed(ns, name, guid) then mark(name) end
    end
  elseif x <= 40 then
    local t = M.units.target
    if namesakeUnit(ns, t) == name then mark(name) end
  elseif x <= 45 then
    mark(namesakeUnit(ns, M.units[tok]))
    for k, u in pairs(M.units) do if k:find("^nameplate") then mark(namesakeUnit(ns, u)) end end
  elseif x <= 60 then
    local r = ns.Tracker.ByGUID(guid)
    if (not r or not r.surname) and otherListed(ns, name, guid) then mark(name) end
    for k, u in pairs(M.units) do
      if k:find("^nameplate") or k == "target" or k == "focus" or k == "mouseover" then mark(namesakeUnit(ns, u)) end
    end
  end
end

local function run(seed, dir, files, checks)
  local ev = events(seed)
  _G.DeathNoteDB = nil
  M.Reset()
  local opts = { dir = dir, files = files }
  local ns = M.Load(opts)
  local out = {}
  local tainted = {}
  -- per GUID (this version only): own killing blows booked, revenge recognised without a killing blow in that step
  local K, RN, stepKill, stepRev = {}, {}, {}, {}
  local function hook()
    if not checks then return end
    ns:On("OWN_KILL", function(key)
      local v = ns.Ledger.Victim(key)
      local g = v and v.guid
      if g then K[g] = (K[g] or 0) + 1; stepKill[g] = true end
    end)
    ns:On("REVENGE", function(key)
      local en = ns.Store.Get(key)
      local g = en and en.guid
      if type(g) == "string" then stepRev[g] = (stepRev[g] or 0) + 1 end
    end)
  end
  hook()
  for step = 1, STEPS do
    local e = ev[step]
    local name, sur = NAMES[e.i], SUR[e.j]
    local guid = "Player-93-D" .. e.i .. e.j
    local withSur = e.withSur
    local tok = "nameplate" .. (e.i * 2 + e.j)
    local x = e.x
    if checks then namesakeStep(ns, x, e.att, name, guid, tok, withSur, tainted) end
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
        -- the recap names the source in full (seen live), a player without surname by his first name
        M.recap = { id = e.id, events = { { sourceGUID = guid, sourceName = withSur and (name .. " " .. sur) or name,
          amount = 900, overkill = 120,
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
        ns = M.Load(opts); hook()
      else M.Advance(({ 1, 5, 11, 20, 60, 700, 90000 })[e.adv]) end
    end)
    for g, n in pairs(stepRev) do if not stepKill[g] then RN[g] = (RN[g] or 0) + n end end
    stepKill, stepRev = {}, {}
    if step % 5 == 0 or step == STEPS then
      local db = _G.DeathNoteDB
      local b, book, journal = {}, {}, {}
      for k, en in pairs(ns.Store.All()) do b[k] = ns.Store.Bounty(en); book[k] = ser(en) end
      for i = 1, #db.deaths do journal[i] = ser(db.deaths[i]) end
      local taint = {}
      for n in pairs(tainted) do taint[n] = true end
      out[#out + 1] = { book = book, journal = journal, bounty = b, errors = #M.errors, taint = taint }
      if checks then
        for k, en in pairs(ns.Store.All()) do
          local g = type(en.guid) == "string" and en.guid or nil
          local v = ns.Ledger.Victim(k)
          checks.join = checks.join + 1
          if g and v and v.guid and v.guid ~= g then
            checks.mixed = checks.mixed + 1
            checks.firstMixed = checks.firstMixed or ("seed %d, step %d, %s"):format(seed, step, k)
          end
          local mine = ns.Ledger.Standing(k)
          if g and mine then
            checks.obs = checks.obs + 1
            local bound = (K[g] or 0) + (RN[g] or 0) + ns.Store.HandRevenge(en)
            if mine > bound then
              checks.over = checks.over + 1
              checks.firstOver = checks.firstOver or ("seed %d, step %d, %s: me %d, booked %d, revenge without a kill %d, hand %d"):format(
                seed, step, k, mine, K[g] or 0, RN[g] or 0, ns.Store.HandRevenge(en))
            end
          end
        end
        for vk, v in pairs(db.ledger.victims) do
          local bk = v.guid and ns.Store.ByGUID(v.guid)
          if bk and bk ~= vk then
            checks.split = checks.split + 1
            checks.firstSplit = checks.firstSplit or ("seed %d, step %d, rap sheet %s, book %s"):format(seed, step, vk, bk)
          end
        end
      end
    end
  end
  return out, tainted
end

-- first name of a key ("Name-..."), and whether a journal row names a tainted first name
local function firstOfKey(k) return k:match("^([^%-#]+)") end
local function rowTainted(row, taint)
  for n in pairs(taint) do
    if row:find("[=,{]" .. n .. "[%- ]") then return true end
  end
  return false
end

local checks, books, entries, lower, higher, bookDiff, errors = 0, 0, 0, 0, 0, 0, 0
local firstHigher, firstBook
local G = { join = 0, mixed = 0, obs = 0, over = 0, split = 0 }
local exSeeds, exEntries, allEntries, exRows, allRows, exDiffer = 0, 0, 0, 0, 0, 0
for seed = FIRST, FIRST + SEEDS - 1 do
  local a = run(seed, OLD, OLDFILES)
  local b, tainted = run(seed, nil, nil, G)
  if next(tainted) then exSeeds = exSeeds + 1 end
  for k = 1, #a do
    checks = checks + 1
    local taint = b[k].taint
    local same, where = true, nil
    local keys = {}
    for key in pairs(a[k].book) do keys[key] = true end
    for key in pairs(b[k].book) do keys[key] = true end
    for key in pairs(keys) do
      allEntries = allEntries + 1
      if taint[firstOfKey(key)] then
        exEntries = exEntries + 1
        if a[k].book[key] ~= b[k].book[key] then exDiffer = exDiffer + 1 end
      elseif a[k].book[key] ~= b[k].book[key] then
        same, where = false, where or key
        if os.getenv("DN_DIFF_SHOW") then print(seed, k, key, "\n  1.2.2: " .. tostring(a[k].book[key]), "\n  now:   " .. tostring(b[k].book[key])) end
      end
    end
    local ra, rb = {}, {}
    for _, row in ipairs(a[k].journal) do allRows = allRows + 1; if rowTainted(row, taint) then exRows = exRows + 1 else ra[#ra + 1] = row end end
    for _, row in ipairs(b[k].journal) do if not rowTainted(row, taint) then rb[#rb + 1] = row end end
    if table.concat(ra, "\n") ~= table.concat(rb, "\n") then same, where = false, where or "journal" end
    if same then books = books + 1 else
      bookDiff = bookDiff + 1
      firstBook = firstBook or ("seed " .. seed .. ", checkpoint " .. k .. " (" .. where .. ")")
    end
    errors = errors + b[k].errors
    for key, old in pairs(a[k].bounty) do
      local new = b[k].bounty[key]
      if new and not taint[firstOfKey(key)] then
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

local guidRed = G.mixed > 0 or G.over > 0 or G.split > 0
local red = higher > 0 or bookDiff > 0 or errors > 0 or guidRed
io.write(("%-18s %d seeds x %d steps, %d checkpoints (book same: %d), %d bounties: higher %d, lower %d, %s\n"):format(
  "ledger_diff", SEEDS, STEPS, checks, books, entries, higher, lower, red and "ROT" or "0 rot"))
io.write(("  per GUID: %d book entries checked, %d standings: me above booked + revenge + hand %d, two GUIDs under one key %d, "
  .. "one GUID under two keys %d\n"):format(G.join, G.obs, G.over, G.mixed, G.split))
io.write(("  exception namesakes without surname: %d of %d seeds, %d of %d entry comparisons left out (%d of them differ), "
  .. "%d of %d journal rows\n"):format(exSeeds, SEEDS, exEntries, allEntries, exDiffer, exRows, allRows))
if firstHigher then io.write("  ROT: bounty higher than 1.2.2: " .. firstHigher .. "\n") end
if firstBook then io.write("  ROT: book differs from 1.2.2: " .. firstBook .. "\n") end
if G.firstOver then io.write("  ROT: me above the count per GUID: " .. G.firstOver .. "\n") end
if G.firstMixed then io.write("  ROT: book entry and victim of two GUIDs under one key: " .. G.firstMixed .. "\n") end
if G.firstSplit then io.write("  ROT: one GUID under two keys: " .. G.firstSplit .. "\n") end
if errors > 0 then io.write("  ROT: " .. errors .. " addon errors\n") end
os.exit(red and 1 or 0)
