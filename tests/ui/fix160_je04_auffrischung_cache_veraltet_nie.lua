-- Fixer 2 1.6.0 (je04): refreshes of the open book sort only when the order can change. A sighting keeps the sorts
-- "rank" and "recent" and the evaluation "which guilds kill you" (only that guild's "last seen" is made again); the list
-- "Unsolved" keeps its order while the same items with the same times come. Never stale: after every kind of change
-- (a sighting in the same guild, one that brings a new guild, one of an entry without a guild that gets one, a new
-- suspect, a new deed of a suspect, a removal, a new kill) the cached lists equal a fresh build.
-- Use: luajit tests/ui/fix160_je04_auffrischung_cache_veraltet_nie.lua [<worktree>]. Names made up.
local WT = ((arg and arg[1]) or "."):gsub("/+$", "")
local X = dofile(WT .. "/tests/ui/_fe160.lua")
local J = X.J

local W = X.world(WT, "deDE")
local ns = W.ns
local S, Fe = ns.Store, ns.Feud
local now = time()
for i = 1, 12 do W.kill("Feind" .. i, "Ling", "Rote Hand " .. (i % 3), now - 1000 - i) end
for i = 1, 6 do
  S.AddAttack({ name = "Verdacht" .. i, surname = "Ling", guid = "Player-93-V" .. i, guild = i % 2 == 0 and "Rote Hand 1" or nil,
    class = "MAGE", level = 40 }, { t = now - 500 - i, zone = "Brachland" })
end
W.open()
W.tab("open"); W.settle()
local UX = W.kit().UX

local function guildsSig()
  local out = {}
  for _, g in ipairs(Fe.Guilds()) do
    local m = {}
    for _, e in ipairs(g.members) do m[#m + 1] = e.key end
    out[#out + 1] = table.concat({ g.name, g.deaths, g.rev, g.n, tostring(g.seen), tostring(g.feud), table.concat(m, ",") }, "|")
  end
  return table.concat(out, "\n")
end
local function openSig(list)
  local out = {}
  for i, x in ipairs(list) do out[i] = tostring(x.key or x.t) end
  return table.concat(out, ",")
end
local function rankedSig(sort)
  local out = {}
  for i, e in ipairs(S.Ranked("all", sort)) do out[i] = e.key end
  return table.concat(out, ",")
end
-- the sorts of Store.lua (SORTS, rankLess), written out: a fresh sort of every entry
local function rankLess(a, b)
  if (a.kills or 0) ~= (b.kills or 0) then return (a.kills or 0) > (b.kills or 0) end
  if (a.assists or 0) ~= (b.assists or 0) then return (a.assists or 0) > (b.assists or 0) end
  if (a.lastKill or 0) ~= (b.lastKill or 0) then return (a.lastKill or 0) > (b.lastKill or 0) end
  return (a.key or "") < (b.key or "")
end
local SORTS = {
  rank = rankLess,
  recent = function(a, b)
    local ta = math.max(a.lastKill or 0, a.deaths[1] and a.deaths[1].t or 0)
    local tb = math.max(b.lastKill or 0, b.deaths[1] and b.deaths[1].t or 0)
    if ta ~= tb then return ta > tb end
    return rankLess(a, b)
  end,
  name = function(a, b)
    local na, nb = ns.Util.Display(a):lower(), ns.Util.Display(b):lower()
    if na ~= nb then return na < nb end
    return (a.key or "") < (b.key or "")
  end,
  seen = function(a, b)
    local ta, tb = a.lastSeen and a.lastSeen.t or 0, b.lastSeen and b.lastSeen.t or 0
    if ta ~= tb then return ta > tb end
    return rankLess(a, b)
  end,
}
local function freshRanked(sort)
  local list = {}
  for _, e in pairs(S.All()) do list[#list + 1] = e end
  table.sort(list, SORTS[sort])
  local out = {}
  for i, e in ipairs(list) do out[i] = e.key end
  return table.concat(out, ",")
end
local function freshOpen()
  local copy = {}
  for i, x in ipairs(UX.OpenData()) do copy[i] = x end
  -- the same items sorted afresh with the rule of the list (newest first, then key)
  table.sort(copy, function(a, b)
    local function t(x)
      if x.status == nil and x.kind ~= nil then return tonumber(x.t) or 0 end
      local d = ns.Look.LastDeed(x)
      return d and tonumber(d.t) or 0
    end
    local ta, tb = t(a), t(b)
    if ta ~= tb then return ta > tb end
    return tostring(a.key or a.t) < tostring(b.key or b.t)
  end)
  return copy
end

local steps = {
  { "Sichtung, Gilde gleich", function() S.Seen("Feind1-Ling", { guild = "Rote Hand 1" }, { t = time(), zone = "Z" }, true) end },
  { "Sichtung, neue Gilde", function() S.Seen("Feind2-Ling", { guild = "Neue Gilde" }, { t = time(), zone = "Z" }, true) end },
  { "Sichtung eines Verdachts ohne Gilde, jetzt mit", function()
    S.Seen("Verdacht1-Ling", { guild = "Rote Hand 2" }, { t = time(), zone = "Z" }, true) end },
  { "Sichtung, älterer Zeitpunkt", function() S.Seen("Feind4-Ling", {}, { t = time() - 99999, zone = "Z" }, false) end },
  { "neuer Verdacht", function()
    S.AddAttack({ name = "Verdacht9", surname = "Ling", guid = "Player-93-V9", class = "MAGE", level = 40 }, { t = time(), zone = "Z" }) end },
  { "neue Tat eines Verdachts", function()
    S.AddAttack({ name = "Verdacht3", surname = "Ling", guid = "Player-93-V3", class = "MAGE", level = 40 }, { t = time() + 5, zone = "Z" }) end },
  { "Eintrag entfernt", function() S.Remove("Verdacht2-Ling") end },
  { "neue Tötung", function() W.kill("Feind20", "Ling", "Rote Hand 1", time()) end },
}
for i, st in ipairs(steps) do
  -- warm: the cached lists exist before the change
  Fe.Guilds(); UX.OpenData(); S.Ranked("all", "rank"); S.Ranked("all", "recent"); S.Ranked("all", "seen"); S.Ranked("all", "name")
  st[2]()
  W.tick(1); W.settle()
  local cached = { guildsSig(), openSig(UX.OpenData()), rankedSig("rank"), rankedSig("recent"), rankedSig("seen"), rankedSig("name") }
  local fo = openSig(freshOpen())
  Fe.Touched()
  local fresh = { guildsSig(), fo, freshRanked("rank"), freshRanked("recent"), freshRanked("seen"), freshRanked("name") }
  for k, what in ipairs({ "Gilden", "Zu klären", "Rang", "Neueste", "Gesehen", "Name" }) do
    J.check(("Schritt %d (%s): %s wie frisch"):format(i, st[1], what), cached[k] == fresh[k], cached[k] .. "\n  vs\n" .. fresh[k])
  end
end
-- a sighting in the same guild: no new evaluation, no sort of the rank
local b0, r0 = Fe.builds, S.rankedSorts
Fe.Guilds(); S.Ranked("wanted", "rank")
b0, r0 = Fe.builds, S.rankedSorts
S.Seen("Feind5-Ling", {}, { t = time(), zone = "Z" }, true)
Fe.Guilds(); S.Ranked("wanted", "rank")
J.check("Sichtung: Gilden ohne Neubau", Fe.builds == b0, Fe.builds - b0)
J.check("Sichtung: Rang ohne Sortierung", S.rankedSorts == r0, S.rankedSorts - r0)
local ok, err = W.errors()
J.check("keine Fehler", ok, err)
J.done("fix160 je04 Auffrischung")
