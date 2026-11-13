-- Rap sheet (1.3.0): random run. RUNS runs (default 1000) of STEPS random steps: own kills (player, pet, group
-- member, honour line, secrets, never seen victims), namesakes (one first name, two surnames, two GUIDs), his kills,
-- revenge by hand and back, revenge without an own killing blow (PLAYER_PVP_KILLS_CHANGED with him in the target),
-- pardon, removal from book and rap sheet, export and import (own text and a foreign one), duels to the death (GUID,
-- full name, first name), group, instances, time jumps forward and back, relogs, a small cap, broken data.
-- After every step:
--   accounts, own kills and the reported tier never sink; #log <= 60; victims <= the cap;
--   per victim: n = own kills booked (OWN_KILL) while he stood in the rap sheet; the start books nothing;
--   points: sum of the accounts = points of all booked kills;
--   the bounty's "me" (Ledger.Mine) >= the book's revenge and >= n + by hand (never higher than 1.2.x);
--   the standing: me = max(n, recognised - imported + pre) + by hand, him = his kills;
--   a reload changes no standing, no account, no own kill;
--   no REPUTE_RANK with path = nil above tier 2; no error, no secret in the data.
-- 1.3.1: the group member is in the group (party1 with his GUID) half of the time, so his PARTY_KILL with
-- PLAYER_PVP_KILLS_CHANGED or an honour line (also the plain one) books a group kill; the checks above stay as they
-- are (a group kill is an OWN_KILL like any other).
-- Usage: luajit tests/test_ledger_random.lua [runs] [steps] [seed]
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local M = require("mock_wow")

local RUNS = tonumber(arg[1]) or 1000
local STEPS = tonumber(arg[2]) or 60
local SEED = tonumber(arg[3]) or 1300
local ME = "Player-93-0000AAAA"
local NAMES = { "Grimm", "Anna", "Bernd", "Carla", "Dora", "Edda", "Fritz", "Gerd", "Hanna", "Ida", "Jan", "Kai",
  "Geist", "Schemen" }
local SURS = { "Zufall", "Zweit" }   -- every first name stands for two players (namesakes)

local fails, firstFail = 0, nil
local steps, kills, groupKills = 0, 0, 0
local function fail(run, step, what)
  fails = fails + 1
  if not firstFail then firstFail = ("run %d (seed %d), step %d: %s"):format(run, SEED + run, step, what) end
end

local ns
local onKill, onRank   -- the handlers of the running run (one bus handler per load)
local function guidOf(i, j) return "Player-93-R" .. i .. "x" .. j end
local function enemy(i, j, level, noSurname)
  return M.AddEnemy("nameplate" .. (i * 2 + j), { name = NAMES[i], surname = (not noSurname) and SURS[j] or nil,
    guid = guidOf(i, j), level = level, faction = "Alliance" })
end
local function foreignText(i, j, revenge)
  return "DEATHNOTE:1\n" .. table.concat({ "E", NAMES[i] .. "-" .. SURS[j], "wanted", "0", tostring(math.random(0, 4)),
    "0", tostring(revenge), "1700000000", "1700000000", "1700000000", "1", "ROGUE", "", "40", "", "", SURS[j], "", "",
    "0" }, "|")
end

for run = 1, RUNS do
  math.randomseed(SEED + run)
  if run % 50 == 1 then
    ns = M.Load()
    ns:On("OWN_KILL", function(...) if onKill then onKill(...) end end)
    ns:On("REPUTE_RANK", function(...) if onRank then onRank(...) end end)
  end
  M.errors = {}
  _G.DeathNoteDB = (math.random(4) == 1) and { version = 3, settings = {}, deaths = {}, enemies = {
    ["Grimm-Zufall"] = { name = "Grimm", surname = "Zufall", kills = 3, revenge = math.random(0, 14), revengeHand = 1,
      status = "wanted", deaths = {}, guid = guidOf(1, 1) } } } or {}
  local L, S = ns.Ledger, ns.Store
  L.VICTIMS_MAX = (math.random(3) == 1) and math.random(2, 6) or 200
  S.Init()
  L.ResetRuntime()
  L.HONOR_FALLBACK = math.random(2) == 1   -- off by default; both ways are run
  M.units.player.level = math.random(1, 70)
  local booked = {}                     -- per GUID (or key): own kills booked while he stood in the rap sheet
  local present = {}                    -- ids of the victims at the start of the step
  local bookedPts = 0
  local stepFail
  local prev = { r = 0, e = 0, j = 0, s = 0, n = L.DB().n, tier = L.DB().tier }
  for k in pairs(prev) do if L.DB().acc[k] then prev[k] = L.DB().acc[k] end end
  local function idOf(k, v) return v.guid or k end
  onKill = function(key, row)
    local v = L.Victim(key)
    local id = v and idOf(key, v) or key
    if not present[id] or (v and v.n == 1) then booked[id] = 0; present[id] = true end   -- new, or back after the cap
    -- a victim known by first name only (honour line, no GUID) learned his GUID with this kill
    if v and v.guid and present[key] and booked[key] then booked[id] = booked[id] + booked[key]; booked[key] = nil end
    booked[id] = (booked[id] or 0) + 1
    bookedPts = bookedPts + row.r + row.e + row.j + row.s
    kills = kills + 1
    if row.f:find("o", 1, true) then groupKills = groupKills + 1 end
  end
  onRank = function(tier, path)
    if tier >= 3 and path == nil then stepFail = "REPUTE_RANK(" .. tier .. ") without a path" end
  end
  local function standings()
    local t = {}
    for k in pairs(S.All()) do
      local m, h, st = L.Standing(k)
      t[k] = tostring(m) .. ":" .. tostring(h) .. ":" .. tostring(st)
    end
    return t
  end
  local unsure = false                   -- broken data was written: the books are re-read from scratch
  for step = 1, STEPS do
    steps = steps + 1
    present = {}
    for k, v in pairs(L.DB().victims) do present[idOf(k, v)] = true end
    local i, j = math.random(#NAMES), math.random(2)
    local key = NAMES[i] .. "-" .. SURS[j]
    local guid = guidOf(i, j)
    local x = math.random(100)
    -- the last two first names are never seen and never in the book: two namesakes known only by GUID and first
    -- name (a first name alone that matches a book entry is the book's guess, as in Attribution, and not modelled)
    local ghost = i > #NAMES - 2
    if ghost and x > 26 then x = 70 end
    local ok, err = pcall(function()
      if x <= 26 then
        local lv = ({ math.random(1, 70), -1, nil, M.units.player.level })[math.random(4)]
        local r = math.random(6)
        if ghost then r = 1 elseif r == 1 then r = 2 end
        if r > 1 then
          -- one plate in four without surname: the GUID tells the namesakes apart (the tracker gives the second one
          -- a namesake key of its own); the ghosts cover players never seen
          enemy(i, j, lv, math.random(4) == 1)
          if math.random(3) > 1 then M.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate" .. (i * 2 + j)) end
        else
          -- never seen: the client knows the first name only
          M.units["x" .. i .. j] = { exists = false, guid = guid, name = NAMES[i], class = "ROGUE" }
        end
        local att = ({ ME, ME, ME, "Pet-0-1", "Player-93-Kollege", "Creature-0-1" })[math.random(6)]
        M.units.pet = { exists = true, guid = "Pet-0-1" }
        M.FireEvent("PARTY_KILL", att, guid)
        -- 1.3.1: the proof of a kill I took part in (now and then none, or late)
        if math.random(3) > 1 then
          M.Advance(({ 0.4, 1, 2.5, 4 })[math.random(4)])
          if math.random(2) == 1 then M.FireEvent("PLAYER_PVP_KILLS_CHANGED")
          else M.FireEvent("CHAT_MSG_COMBAT_HONOR_GAIN", "Ihr habt 198 Ehrenpunkte erhalten.") end
        end
        M.units["x" .. i .. j] = nil
      elseif x <= 31 then
        enemy(i, j, math.random(1, 70))
        M.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate" .. (i * 2 + j))
        M.FireEvent("CHAT_MSG_COMBAT_HONOR_GAIN", NAMES[i] .. (math.random(2) == 1 and (" " .. SURS[j]) or "")
          .. " stirbt (Ehrenhafter Sieg: Rang 2). Ihr erhaltet 7 Ehre.")
      elseif x <= 34 then
        -- revenge without an own killing blow: he is my target, someone else kills him, my kill count rises
        enemy(i, j, 40)
        M.units.target = M.units["nameplate" .. (i * 2 + j)]
        M.FireEvent("PLAYER_TARGET_CHANGED")
        M.FireEvent("PARTY_KILL", "Player-93-Kollege", guid)
        M.FireEvent("PLAYER_PVP_KILLS_CHANGED")
      elseif x <= 46 then
        S.ApplyKill({ name = NAMES[i], surname = SURS[j], guid = guid }, { t = time() }, true)
      elseif x <= 50 then
        S.AddRevenge(key, true)
      elseif x <= 52 then
        S.UndoRevenge(key)
      elseif x <= 54 then
        S.SetStatus(key, ({ "wanted", "pardoned", "suspect" })[math.random(3)])
      elseif x <= 56 then
        S.Remove(key)
      elseif x <= 58 then
        local v = L.Victim(key)
        if v and L.RemoveVictim(key) then booked[idOf(key, v)] = 0 end
      elseif x <= 60 then
        if math.random(2) == 1 then S.Import(S.Export(false)) else S.Import(foreignText(i, j, math.random(0, 12))) end
      elseif x <= 63 then
        local how = math.random(3)
        if how == 1 then _G.GetDuelerInfo = function() return guid end end
        M.FireEvent("DUEL_TO_THE_DEATH_REQUESTED", how == 2 and (NAMES[i] .. " " .. SURS[j]) or NAMES[i])
        _G.GetDuelerInfo = nil
      elseif x <= 64 then
        M.FireEvent(({ "DUEL_FINISHED", "DUEL_INBOUNDS", "ZONE_CHANGED_NEW_AREA" })[math.random(3)])
      elseif x <= 66 then
        M.units.party1 = (math.random(2) == 1) and { exists = true, isPlayer = true, name = "Kollege",
          guid = (math.random(4) > 1) and "Player-93-Kollege" or nil } or nil
        M.FireEvent("GROUP_ROSTER_UPDATE")
      elseif x <= 67 then
        M.instance = (math.random(3) == 1) and { true, "pvp" } or { false, "none" }
      elseif x <= 80 then
        M.Advance(({ 1, 5, 11, 60, 700, 3000, 90000 })[math.random(7)])
      elseif x <= 82 then
        M.epoch = M.epoch - ({ 30, 700, 100000 })[math.random(3)]   -- the clock set back
      elseif x <= 87 then
        local d = L.DB()
        local before, n0, st0 = d.acc.r + d.acc.e + d.acc.j + d.acc.s, d.n, standings()
        S.Init()
        d = L.DB()
        if d.acc.r + d.acc.e + d.acc.j + d.acc.s ~= before then stepFail = "the start changed the accounts" end
        if d.n ~= n0 then stepFail = "the start changed the own kills" end
        if S.Setting("ledger.enabled") ~= false then
          for k, v in pairs(standings()) do
            if st0[k] ~= v then stepFail = "standing of " .. k .. " jumped at the start: " .. tostring(st0[k]) .. " -> " .. v end
          end
        end
      elseif x <= 89 then
        -- broken data, then a relog
        local d = _G.DeathNoteDB.ledger
        local junk = ({ "x", -1, 0 / 0, {}, 1 / 0, false })[math.random(6)]
        local field = ({ "victims", "log", "acc", "mood", "n", "best", "awards", "tier", "path", "cur" })[math.random(10)]
        if math.random(2) == 1 then d[field] = junk
        else local v = next(d.victims) if v then d.victims[v][({ "n", "last", "dt", "pts", "name", "pre" })[math.random(6)]] = junk end end
        S.Init()
        unsure = true
      elseif x <= 92 then
        M.FireEvent("PARTY_KILL", M.Secret("a"), ({ guid, M.Secret("t") })[math.random(2)])
        M.FireEvent("CHAT_MSG_COMBAT_HONOR_GAIN", M.Secret("text"))
      elseif x <= 95 then
        S.Setting("ledger.enabled", math.random(3) > 1)
      else
        S.Setting("debug", math.random(2) == 1)
        if math.random(3) == 1 then ns.Probe.Run(false) end
      end
    end)
    if not ok then fail(run, step, "error: " .. tostring(err)) end
    if stepFail then fail(run, step, stepFail); stepFail = nil end
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
      if sum ~= bookedPts then fail(run, step, ("points %d ~= booked %d"):format(sum, bookedPts)) end
      for k, v in pairs(d.victims) do
        local id = idOf(k, v)
        -- a victim known without GUID (honour line) that met his GUID: both counts are his now
        if id ~= k and booked[k] then booked[id] = (booked[id] or 0) + booked[k]; booked[k] = nil end
        if v.n ~= (booked[id] or 0) then fail(run, step, ("%s: n %d, booked %d"):format(k, v.n, booked[id] or 0)) end
      end
      -- counts of victims that left (moved, struck, capped) go with them
      local live = {}
      for k, v in pairs(d.victims) do live[idOf(k, v)] = true end
      for id in pairs(booked) do if not live[id] then booked[id] = nil end end
    else
      prev = { r = d.acc.r, e = d.acc.e, j = d.acc.j, s = d.acc.s, n = d.n, tier = d.tier }
    end
    if #d.log > 60 then fail(run, step, "log over 60") end
    if L.VictimCount() > L.VICTIMS_MAX then fail(run, step, "victims over the cap") end
    if S.Setting("ledger.enabled") ~= false then
      for k, e in pairs(S.All()) do
        local mine, his = L.Standing(k)
        local v = d.victims[k]
        local n, hand = v and v.n or 0, S.HandRevenge(e)
        local rec = math.max(0, (e.revenge or 0) - hand - (e.revengeForeign or 0))
        local want = math.min(math.max(n, rec + (v and v.pre or 0)) + hand, 9999)
        if mine ~= want or his ~= (e.kills or 0) then
          fail(run, step, ("standing of %s: %s:%s, want %d:%d"):format(k, tostring(mine), tostring(his), want, e.kills or 0))
        end
        local bm = L.Mine(k, e)
        if bm < (e.revenge or 0) then fail(run, step, "bounty's me below the book's revenge: " .. k) end
        if bm < n + hand then fail(run, step, "bounty's me below own kills + by hand: " .. k) end
      end
    end
    if M.ContainsSecret(_G.DeathNoteDB) then fail(run, step, "secret in the data") end
  end
  onKill, onRank = nil, nil
  L.VICTIMS_MAX = 200
  M.instance = { false, "none" }; M.units.party1 = nil; M.units.target = nil
end

io.write(("%-18s %d runs, %d steps, %d kills booked (%d group kills), %s\n"):format("ledger_random", RUNS, steps, kills,
  groupKills,
  fails == 0 and "0 rot" or (fails .. " rot")))
if firstFail then io.write("  ROT: " .. firstFail .. "\n") end
os.exit(fails == 0 and 0 or 1)
