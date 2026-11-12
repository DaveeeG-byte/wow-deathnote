-- Rap sheet (1.3.0): random run. RUNS runs (default 1000) of STEPS random steps: own kills (player, pet, group
-- member, honour line, secrets), his kills, revenge by hand and back, pardon, removal from book and rap sheet, duels
-- to the death, group, instances, time jumps, relogs, broken data. After every step:
--   accounts, own kills and the reported tier never sink; #log <= 60; victims <= 200;
--   per victim: n = own kills booked (OWN_KILL) + old cases from the check at start;
--   points: sum of the accounts = points of all booked kills + points of the old cases;
--   the standing is me = n + revenge by hand, him = his kills; no error, no secret in the data.
-- Usage: luajit tests/test_ledger_random.lua [runs] [steps] [seed]
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local M = require("mock_wow")

local RUNS = tonumber(arg[1]) or 1000
local STEPS = tonumber(arg[2]) or 60
local SEED = tonumber(arg[3]) or 1300
local ME = "Player-93-0000AAAA"
local NAMES = { "Grimm", "Anna", "Bernd", "Carla", "Dora", "Edda", "Fritz", "Gerd", "Hanna", "Ida", "Jan", "Kai" }

local fails, firstFail = 0, nil
local steps, kills = 0, 0
local function fail(run, step, what)
  fails = fails + 1
  if not firstFail then firstFail = ("run %d (seed %d), step %d: %s"):format(run, SEED + run, step, what) end
end

local ns
local onKill   -- the handler of the running run (one bus handler per load)
local function enemy(i, level)
  local name = NAMES[i]
  local u = M.AddEnemy("nameplate" .. i, { name = name, surname = "Zufall", guid = "Player-93-R" .. i, level = level,
    faction = "Alliance" })
  return u
end

for run = 1, RUNS do
  math.randomseed(SEED + run)
  if run % 50 == 1 then
    ns = M.Load()
    ns:On("OWN_KILL", function(...) if onKill then onKill(...) end end)
  end
  M.errors = {}
  _G.DeathNoteDB = (math.random(4) == 1) and { version = 3, settings = {}, deaths = {}, enemies = {
    ["Grimm-Zufall"] = { name = "Grimm", surname = "Zufall", kills = 3, revenge = math.random(0, 14), revengeHand = 1,
      status = "wanted", deaths = {}, guid = "Player-93-R1" } } } or {}
  ns.Store.Init()
  ns.Ledger.ResetRuntime()
  M.units.player.level = math.random(1, 70)
  local L, S = ns.Ledger, ns.Store
  local booked, oldPts = {}, 0          -- per key: own kills booked; points of old cases
  local bookedPts = 0
  local function absorbStart(before)
    -- what the check at start added: old cases (n) and their points
    local d = L.DB()
    for k, v in pairs(d.victims) do
      local id = v.guid or k
      if v.n > (booked[id] or 0) then booked[id] = v.n end
    end
    oldPts = oldPts + (d.acc.r + d.acc.e + d.acc.j + d.acc.s) - before
  end
  absorbStart(0)
  local unsure = false                   -- broken data was written: the books are re-read from scratch
  local prev = { r = 0, e = 0, j = 0, s = 0, n = L.DB().n, tier = L.DB().tier }
  for k in pairs(prev) do if L.DB().acc[k] then prev[k] = L.DB().acc[k] end end
  onKill = function(key, row)
    -- by GUID: a victim known by first name only moves to his full name when he is seen (Ledger.Promote)
    local v = L.Victim(key)
    local id = v and v.guid or key
    booked[id] = (booked[id] or 0) + 1
    bookedPts = bookedPts + row.r + row.e + row.j + row.s
    kills = kills + 1
  end
  for step = 1, STEPS do
    steps = steps + 1
    local i = math.random(#NAMES)
    local key = NAMES[i] .. "-Zufall"
    local guid = "Player-93-R" .. i
    local x = math.random(100)
    local ok, err = pcall(function()
      if x <= 30 then
        local lv = ({ math.random(1, 70), -1, nil, M.units.player.level })[math.random(4)]
        enemy(i, lv)
        if math.random(3) > 1 then M.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate" .. i) end
        local att = ({ ME, ME, ME, "Pet-0-1", "Player-93-Kollege", "Creature-0-1" })[math.random(6)]
        M.units.pet = { exists = true, guid = "Pet-0-1" }
        M.FireEvent("PARTY_KILL", att, guid)
      elseif x <= 36 then
        enemy(i, math.random(1, 70))
        M.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate" .. i)
        M.FireEvent("CHAT_MSG_COMBAT_HONOR_GAIN", NAMES[i] .. (math.random(2) == 1 and " Zufall" or "")
          .. " stirbt (Ehrenhafter Sieg: Rang 2). Ihr erhaltet 7 Ehre.")
      elseif x <= 50 then
        S.ApplyKill({ name = NAMES[i], surname = "Zufall", guid = guid }, { t = time() }, true)
      elseif x <= 55 then
        S.AddRevenge(key, true)
      elseif x <= 58 then
        S.UndoRevenge(key)
      elseif x <= 60 then
        S.SetStatus(key, ({ "wanted", "pardoned", "suspect" })[math.random(3)])
      elseif x <= 62 then
        S.Remove(key)
      elseif x <= 64 then
        local v = L.Victim(key)
        if v and L.RemoveVictim(key) then booked[v.guid or key] = 0 end
      elseif x <= 66 then
        M.FireEvent("DUEL_TO_THE_DEATH_REQUESTED", NAMES[i])
      elseif x <= 67 then
        M.FireEvent("DUEL_FINISHED")
      elseif x <= 70 then
        M.units.party1 = (math.random(2) == 1) and { exists = true, isPlayer = true, name = "Kollege" } or nil
      elseif x <= 72 then
        M.instance = (math.random(3) == 1) and { true, "pvp" } or { false, "none" }
      elseif x <= 85 then
        M.Advance(({ 1, 5, 11, 60, 700, 3000, 90000 })[math.random(7)])
      elseif x <= 89 then
        local before = L.DB().acc.r + L.DB().acc.e + L.DB().acc.j + L.DB().acc.s
        S.Init()
        absorbStart(before)
      elseif x <= 91 then
        -- broken data, then a relog
        local d = _G.DeathNoteDB.ledger
        local junk = ({ "x", -1, 0 / 0, {}, 1 / 0, false })[math.random(6)]
        local field = ({ "victims", "log", "acc", "mood", "n", "best", "awards", "tier", "path", "cur" })[math.random(10)]
        if math.random(2) == 1 then d[field] = junk
        else local v = next(d.victims) if v then d.victims[v][({ "n", "last", "dt", "pts", "name" })[math.random(5)]] = junk end end
        S.Init()
        unsure = true
      elseif x <= 94 then
        M.FireEvent("PARTY_KILL", M.Secret("a"), ({ guid, M.Secret("t") })[math.random(2)])
        M.FireEvent("CHAT_MSG_COMBAT_HONOR_GAIN", M.Secret("text"))
      elseif x <= 96 then
        S.Setting("ledger.enabled", math.random(3) > 1)
      else
        S.Setting("debug", math.random(2) == 1)
        if math.random(3) == 1 then ns.Probe.Run(false) end
      end
    end)
    if not ok then fail(run, step, "error: " .. tostring(err)) end
    if #M.errors > 0 then fail(run, step, "addon error: " .. tostring(M.errors[1])); M.errors = {} end
    local d = L.DB()
    if not unsure then
      for _, p in ipairs({ "r", "e", "j", "s" }) do
        if d.acc[p] < prev[p] then fail(run, step, "account " .. p .. " sank") end
        prev[p] = d.acc[p]
      end
      if d.n < prev.n then fail(run, step, "own kills sank") end
      if d.tier < prev.tier then fail(run, step, "tier sank") end
      prev.n, prev.tier = d.n, d.tier
      local sum = d.acc.r + d.acc.e + d.acc.j + d.acc.s
      if sum ~= bookedPts + oldPts then fail(run, step, ("points %d ~= booked %d + old %d"):format(sum, bookedPts, oldPts)) end
      for k, v in pairs(d.victims) do
        local id = v.guid or k
        if v.n ~= (booked[id] or 0) then fail(run, step, ("%s: n %d, booked %d"):format(k, v.n, booked[id] or 0)) end
      end
    else
      prev = { r = d.acc.r, e = d.acc.e, j = d.acc.j, s = d.acc.s, n = d.n, tier = d.tier }
    end
    if #d.log > 60 then fail(run, step, "log over 60") end
    if L.VictimCount() > 200 then fail(run, step, "victims over 200") end
    if S.Setting("ledger.enabled") ~= false then
      for k, e in pairs(S.All()) do
        local mine, his = L.Standing(k)
        local v = d.victims[k]
        if mine ~= (v and v.n or 0) + S.HandRevenge(e) or his ~= (e.kills or 0) then
          fail(run, step, "standing of " .. k)
        end
      end
    end
    if M.ContainsSecret(_G.DeathNoteDB) then fail(run, step, "secret in the data") end
  end
  onKill = nil
  M.instance = { false, "none" }; M.units.party1 = nil
end

io.write(("%-18s %d runs, %d steps, %d kills booked, %s\n"):format("ledger_random", RUNS, steps, kills,
  fails == 0 and "0 rot" or (fails .. " rot")))
if firstFail then io.write("  ROT: " .. firstFail .. "\n") end
os.exit(fails == 0 and 0 or 1)
