-- Fixer 2 1.6.0 (je01, je02): the chronicle's caches never go stale. A sighting or a call goes into the built lists and
-- the counts of the dot and the ribbon in place (no build), the dot is counted by a scan without a build. After every
-- kind of change (K, R, V, B, J, E, a sighting, a merged sighting, a call, the ring overflowing, a setting) the cached
-- lists (all, guild, friends), the counts (Unseen seenTab and seenFeed, NewSince) equal a fresh build. Names made up.
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local M = require("mock_wow")
local test, eq, ok = M.test, M.eq, M.ok

local GUILD = "Die Wurstbrüder"
local FILES = {}
for _, f in ipairs(M.FILES) do FILES[#FILES + 1] = f end
FILES[#FILES + 1] = "Share.lua"

local function from(x, sender, text) x.fire("CHAT_MSG_ADDON", "DeathNote", text, "GUILD", sender .. "-Forever") end

local function sig(e)
  local vs = {}
  for _, v in ipairs(e.victims or {}) do vs[#vs + 1] = v end
  return table.concat({ e.k, tostring(e.t), tostring(e.key), tostring(e.name), tostring(e.by), tostring(e.victim),
    tostring(e.zone), tostring(e.src), tostring(e.mine), tostring(e.n), tostring(e.quiet), tostring(e.g),
    e.place and (tostring(e.place.mapID) .. "/" .. tostring(e.place.x) .. "/" .. tostring(e.place.y)) or "-",
    table.concat(vs, ",") }, "|")
end
local function snapshot(GL, since)
  local out = {}
  -- the counts first (without a current list they come from the scan or the patched counts)
  out.tab, out.feed = GL.Unseen("seenTab"), GL.Unseen("seenFeed")
  out.since = GL.NewSince(since, "all")
  for _, src in ipairs({ "all", "guild", "friends" }) do
    local list, s, sorted = GL.All(src), {}, true
    for i, e in ipairs(list) do
      s[#s + 1] = sig(e)
      if i > 1 and list[i - 1].t < e.t then sorted = false end
    end
    table.sort(s)
    out[src] = table.concat(s, "\n")
    out[src .. ".sorted"] = sorted
  end
  return out
end
-- a fresh build: a setting of the guild makes every cache stale
local function fresh(a) a.ns:Fire("SETTINGS_CHANGED", "guild.test") end

test("Chronik-Cache veraltet nie: jede Art von Änderung gegen einen frischen Bau", function()
  M.Reset()
  local W = M.NewWorld()
  local a = W.client("Anton", "Wurst", GUILD, { version = "1.6.0", files = FILES })
  a.login()
  W.run(30)
  local GL, P = a.ns.GuildLog, a.ns.Guild.Proto
  GL.RING_MAX = 12          -- the ring overflows within the run
  local t0 = time()
  local g = GL.DB()
  g.seenTab, g.seenFeed = t0 - 5000, t0 - 200
  local n = 0
  local function kill(i, kind, dt)
    from(a, "Berta", P.EncodeKill({ key = "Grimm" .. i .. "-Bart", display = "Grimm" .. i .. " Bart", class = "ROGUE", level = 40,
      zone = "Eschental", t = time() - (dt or 0), victim = "Berta Senf" }, kind or "K"))
  end
  local function sight(i, by)
    return GL.OnSighting({ key = "Grimm" .. i .. "-Bart", name = "Grimm" .. i .. " Bart", by = by or "Berta Senf", zone = "Brachland",
      src = "guild", t = time(), mapID = 1413, x = 40 + i, y = 50 })
  end
  local function call(i, by)
    return GL.OnHelpCall({ from = "guild", t = time(), key = "Grimm" .. i .. "-Bart", display = "Grimm" .. i .. " Bart",
      by = by or "Cäsar Kraut", zone = "Eschental", mapID = 1440, x = 10, y = 20 })
  end
  local ops = {
    function() kill(1) end,
    function() kill(2, "R", 3000) end,
    function() sight(1) end,
    function() sight(1, "Dora Dill") end,                 -- merged into the line of the first
    function() call(2) end,
    function() call(3, "Anton Wurst") end,                -- the own call: not counted for the dot
    function() from(a, "Cäsar", P.EncodeAvenged("Grimm1-Bart", "Cäsar Kraut", time() - 10, "0")) end,
    function() from(a, "Cäsar", P.EncodeBounty("Grimm2-Bart", "Cäsar Kraut", 50, time() - 20)) end,
    function() from(a, "Berta", P.EncodeHunt({ key = "Ork-Hau", display = "Ork Hau", t = time() - 30, by = "Berta Senf" })) end,
    function() from(a, "Cäsar", P.EncodeBagged("Ork-Hau", "Cäsar Kraut", time() - 5)) end,
    function() for i = 4, 20 do if i % 2 == 0 then sight(i) else call(i) end end end,   -- the ring overflows
    function() GL.MarkSeen("seenTab") end,
    function() call(30) end,
    function() a.ns:Fire("SETTINGS_CHANGED", "guild.share") end,
  }
  for round = 1, 2 do
    for i, op in ipairs(ops) do
      -- round 1: lists and counts built before the change (the patch); round 2: only the counts (the scan)
      if round == 1 then GL.All("all"); GL.All("guild"); GL.All("friends") else fresh(a) end
      GL.Unseen("seenTab"); GL.Unseen("seenFeed")
      op()
      W.run(1)
      local since = t0 - 100
      local cached = snapshot(GL, since)
      fresh(a)
      local new = snapshot(GL, since)
      for _, k in ipairs({ "all", "guild", "friends", "tab", "feed", "since" }) do
        eq(cached[k], new[k], ("Runde %d, Schritt %d: %s wie frisch gebaut"):format(round, i, k))
        n = n + 1
      end
      for _, src in ipairs({ "all", "guild", "friends" }) do ok(cached[src .. ".sorted"], "neueste zuerst: " .. src) end
      W.run(2)
    end
  end
  ok(GL.stat.patches > 0, "der Patch lief")
  ok(GL.stat.scans > 0, "der Scan lief")
  ok(n >= 150, "Vergleiche: " .. n)
  eq(#M.errors, 0, tostring(M.errors[1]))
end)

test("Punkt am Reiter ohne Bau: Unseen baut die Chronik nicht", function()
  M.Reset()
  local W = M.NewWorld()
  local a = W.client("Anton", "Wurst", GUILD, { version = "1.6.0", files = FILES })
  a.login()
  W.run(30)
  local GL, P = a.ns.GuildLog, a.ns.Guild.Proto
  GL.DB().seenTab = time() - 60
  from(a, "Berta", P.EncodeKill({ key = "Grimm-Bart", display = "Grimm Bart", class = "ROGUE", level = 40,
    zone = "Eschental", t = time(), victim = "Berta Senf" }, "K"))
  W.run(1)
  local b0 = GL.stat.builds
  eq(GL.Unseen("seenTab"), 1, "die neue Tat zählt")
  eq(GL.stat.builds, b0, "kein Bau der Chronik für den Punkt")
  GL.MarkSeen("seenTab")
  eq(GL.Unseen("seenTab"), 0)
  eq(GL.stat.builds, b0, "auch MarkSeen baut nicht")
end)

M.done("fix160 je01/je02 Chronik-Cache")
