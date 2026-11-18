-- 1.6.0 feud: load. A book of 3000 entries, five full guild lists (400 enemies with 20 deeds each) and a full friends'
-- book: Store.Init and a refresh of the list stay under generous limits; the sorted lists are cached per filter and
-- sort (counted), the merged view of guild and friends is not copied again after a change, the guild tab's number is
-- counted once per change. Measured under luajit with the mock (secret-aware type()); the game is faster. Names made up.
package.path = "./tests/?.lua;" .. package.path
local M = require("mock_wow")
local test, eq, ok = M.test, M.eq, M.ok

local INIT_LIMIT_MS = tonumber(os.getenv("FE_INIT_LIMIT")) or 1500   -- generous: measured see the report
local REFRESH_LIMIT_MS = tonumber(os.getenv("FE_REFRESH_LIMIT")) or 400
local T0 = 1700000000 + 1000

local function bigBook()
  local enemies = {}
  for i = 1, 3000 do
    local kill = i % 3 == 0
    local e = { kills = kill and 1 or 0, suspected = kill and 0 or 1, status = kill and "wanted" or "suspect", deaths = {},
      guild = "Gilde " .. (i % 40), class = "ROGUE", level = 40, day = 0 }
    for d = 1, 2 do
      e.deaths[d] = { t = T0 - i * 60 - d, zone = "Schlingendorntal", role = kill and d == 1 and "kill" or "suspect",
        sure = kill and d == 1, source = "recap", guild = "Gilde " .. (i % 40) }
    end
    enemies[("Feind%d-Ling"):format(i)] = e
  end
  local function list(prefix)
    local en = {}
    for i = 1, 400 do
      local deeds = {}
      for d = 1, 20 do deeds[d] = { t = T0 - i * 100 - d, victim = "Kollege Nr" .. (d % 5), by = "Kollege Nr" .. (d % 5), zone = "Z" } end
      en[("%s%d-Ling"):format(prefix, i)] = { deeds = deeds }
    end
    return { enemies = en, members = {}, used = T0 }
  end
  local lists = {}
  for g = 1, 5 do lists["Gilde Nr " .. g] = list("G" .. g .. "x") end
  -- the bound guild shares 100 enemies with the friends' book (they are joined in "all")
  local fen = list("F").enemies
  for i = 1, 100 do fen[("G1x%d-Ling"):format(i)] = lists["Gilde Nr 1"].enemies[("G1x%d-Ling"):format(i)] end
  return { enemies = enemies, guild = { name = "Gilde Nr 1", lists = lists }, friends = { enemies = fen, days = 3, dayAt = 0 } }
end

local function ms(fn)
  local c = os.clock()
  fn()
  return (os.clock() - c) * 1000
end

local db = bigBook()
local ns, initMs
test("Store.Init mit 3000 Eintraegen, 5 vollen Gildenlisten, vollem Freundesbuch", function()
  ns = M.Load({ db = db, before = function()
    M.units.player.guild = "Gilde Nr 1"
  end })
  local _, measured = ns.Feud.Session()
  initMs = measured
  ok(initMs ~= nil, "Startzeit gemessen")
  local n = 0
  for _ in pairs(ns.Store.All()) do n = n + 1 end
  eq(n, 3000)
  io.write(("  Store.Init: %.1f ms (Grenze %d)\n"):format(initMs, INIT_LIMIT_MS))
  ok(initMs < INIT_LIMIT_MS, "Store.Init " .. initMs .. " ms")
end)

local S
local function refresh()
  local list = S.Ranked("wanted", S.RankOrder())
  S.Ranked("pardoned", "rank")
  S.Ranked("suspect", "recent")
  local G = ns.Guild
  if G and G.List then G.List("rank", { foreign = true, source = "all" }); G.Count("all"); G.Count("guild") end
  ns.Feud.Guilds()
  return list
end

test("Auffrischung der Liste: erste unter der Grenze, die naechsten ohne Sortieren", function()
  S = ns.Store
  local first = ms(refresh)
  local sorts = S.rankedSorts
  local second = ms(refresh)
  io.write(("  Auffrischung: erste %.1f ms, zweite %.1f ms (Grenze %d), Sortierlaeufe in der zweiten: %d\n")
    :format(first, second, REFRESH_LIMIT_MS, S.rankedSorts - sorts))
  ok(first < REFRESH_LIMIT_MS, "erste " .. first .. " ms")
  eq(S.rankedSorts - sorts, 0, "die zweite sortiert nicht")
  ok(second < first, "die zweite ist billiger")
  -- a change sorts again, once per filter and sort
  S.ApplyKill({ name = "Neu", surname = "Ling" }, { t = time(), zone = "Z", source = "recap" }, true)
  sorts = S.rankedSorts
  refresh(); refresh()
  eq(S.rankedSorts - sorts, 3, "nach der Aenderung je Liste einmal")
end)

test("Gilde und Freunde: nach einer Aenderung keine neue Kopie, Zahl einmal je Aenderung", function()
  local G = ns.Guild
  ok(G and G.stats, "Sync geladen")
  local st = G.stats
  G.Get("G1x1-Ling", "all")
  G.Count("all")
  local builds, put, runs = st.viewBuilds or 0, st.viewPut or 0, st.countRuns or 0
  for _ = 1, 10 do G.Count("all"); G.Count("guild") end
  eq((st.countRuns or 0) - runs, 0, "zehn Abfragen ohne Aenderung: nicht neu gezaehlt")
  -- a change elsewhere: the view is filled again in place, nothing of one list alone is put again, an entry of both lists
  -- that did not change keeps its joined table (before 1.6.0: both books copied and every joined entry built anew)
  local both = G.Get("G1x1-Ling", "all")
  ok(both and both.both, "Eintrag aus beiden Listen")
  local joinedBefore = st.viewJoined or 0
  for _ = 1, 5 do
    G.Bridge.updated()
    G.Count("all")
  end
  ok((st.viewBuilds or 0) - builds >= 5, "fuenfmal neu aufgebaut")
  eq((st.viewPut or 0) - put, 0, "kein Eintrag neu hineinkopiert")
  eq((st.viewJoined or 0) - joinedBefore, 0, "kein Eintrag beider Listen neu verbunden")
  ok(G.Get("G1x1-Ling", "all") == both, "derselbe verbundene Eintrag")
  eq((st.countRuns or 0) - runs, 5, "je Aenderung einmal gezaehlt")
  local _, n = G.Count("all")
  ok(n > 0, "Taten gezaehlt")
  -- a new deed on one side: that entry is joined again, with the deed
  local ge = ns.Store.DB().guild.lists["Gilde Nr 1"].enemies["G1x1-Ling"]
  table.insert(ge.deeds, 1, { t = time(), victim = "Kollege Nr9", by = "Kollege Nr9", zone = "Z" })
  G.Bridge.updated()
  G.Count("all")
  local again = G.Get("G1x1-Ling", "all")
  ok(again ~= both and again.deeds[1].victim == "Kollege Nr9", "neu verbunden mit der neuen Tat")
  eq((st.viewJoined or 0) - joinedBefore, 1, "genau einer")
end)

M.done("fe160_last")
