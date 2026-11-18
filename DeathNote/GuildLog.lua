-- DeathNote - GuildLog.lua (1.6.0 guildlog)
-- The guild's chronicle as data: what happened to the guild (deaths, revenge, bounties, releases for the hunt), who in
-- the guild has the book, the avengers and the most wanted of the week, the week's card as a chat line and a Discord
-- block, the line "recommend to the guild". Everything comes from what the guild and friends already share (K, R, L, V,
-- E, B, J and H in Sync.lua); nothing new goes over the wire. The window is GuildLogUI.lua.
--
-- Data (additive, language-neutral; older versions leave the table untouched):
--   DeathNoteDB.glog = {
--     holders = { [full name] = { n = short name, g = guild, v = version, t = last heard } }   at most HOLDERS_MAX,
--               dropped after HOLDER_AGE without a message (who has the book: only who sent something himself)
--     ring    = { { k = kind, t, key, name, by, victim, zone, g, src } }   events the books do not keep (a target of
--               the hit list taken down stays only while the target is listed; kinds of other packages via Add)
--     seenTab, seenFeed = time the guild tab / the chronicle was last looked at (the dot on the tab, the ribbon's count)
--     recAt   = time of the last "recommend to the guild" (at most one per RECOMMEND_GAP)
--     counts  = { [what] = n }   probe counters over all sessions
--   }
-- Privacy: a death is only in the chronicle when its victim shared it (others: their K never came); the own deaths
-- (every char of the account) only while "Share deaths with the guild" (or with friends) is on. "Who has the book"
-- lists only who sent a message on GUILD himself; there is no list of those without it.
-- An error here never reaches the book, the alarm or the death detection: every entry from outside (Sync's hook, the
-- UI) goes through pcall at its caller.

local ADDON, ns = ...
local L, Fmt = ns.L, ns.F
local Util = ns.Util
local IsSecret = Util.IsSecret

local GL = {}
ns.GuildLog = GL

GL.RING_MAX = 200           -- events kept in the ring
GL.HOLDERS_MAX = 500        -- book holders remembered (all guilds of the account together)
GL.HOLDER_AGE = 30 * 86400  -- a holder not heard this long is forgotten
GL.WEEK = 7 * 86400
GL.FEED_MAX = 300           -- events in the chronicle (the newest)
GL.RECOMMEND_GAP = 1800     -- seconds between two "recommend to the guild"
GL.ROSTER_TTL = 30          -- the guild roster is read at most this often (only while the list is looked at)
GL.ROSTER_MAX = 1000
GL.FIELD_MAX = 64
GL.SAME = 120               -- one kill reported as V and as E counts once (Sync's BAG_DEDUPE)
GL.VICTIMS_SHOWN = 1        -- names of avenged victims in a sentence, the rest is "and n more"
GL.SIGHT_MERGE = 600        -- sightings of the same enemy within this many seconds of the line's first are one line
GL.SIGHT_COUNT_MAX = 999

local function G(n) return _G[n] end   -- (the client's globals; a test client's environment reads through)
local function num(v) return type(v) == "number" and not IsSecret(v) and v == v and v > -math.huge and v < math.huge end
local function plain(s, max)
  return type(s) == "string" and not IsSecret(s) and s ~= "" and #s <= (max or GL.FIELD_MAX) and not s:find("[%c|]")
end
local function now() return time() end
local function first(s)
  if type(s) ~= "string" then return "?" end
  return s:match("^([^%s%-]+)") or s
end

---------------------------------------------------------------------------
-- Stored data
---------------------------------------------------------------------------
local function rawDB() return ns.Store and ns.Store.DB and ns.Store.DB() or nil end

local function db()
  local d = rawDB()
  if type(d) ~= "table" then return nil end
  local g = d.glog
  if type(g) ~= "table" then g = {}; d.glog = g end
  if type(g.holders) ~= "table" then g.holders = {} end
  if type(g.ring) ~= "table" then g.ring = {} end
  if type(g.counts) ~= "table" then g.counts = {} end
  return g
end
GL.DB = db

local ver = 0               -- bumped by every change the chronicle may show
-- fixer 2 1.6.0 (je01, je02): the built lists (cache) and the counts of the dot and the ribbon (marks) carry the version
-- they were made at. A change of the books bumps the version (everything is stale, built again when looked at); an
-- event of the ring (call, sighting) is put into the current lists and counts instead (patch in GL.Add).
local cache = {}            -- [src] = { ver, list, names, rowOf = { [ring event] = row }, seen = { [id] = row }, dup }
local marks = {}            -- [seenTab | seenFeed] = { ver, since, n }
local function bump() ver = ver + 1 end
function GL.Version() return ver end
GL.stat = { builds = 0, scans = 0, patches = 0 }   -- for tests and the probe
local sortedRing            -- the ring table known to be sorted newest first (GL.Sanitize, GL.Add keep it so)

function GL.Count(what)
  local g = db()
  if not g or type(what) ~= "string" then return end
  g.counts[what] = (tonumber(g.counts[what]) or 0) + 1
end

-- the oldest holder (by last heard), not `keep`
local function oldestHolder(h, keep)
  local k0, t0
  for k, x in pairs(h) do
    if k ~= keep and (not t0 or x.t < t0 or (x.t == t0 and k < k0)) then k0, t0 = k, x.t end
  end
  return k0
end

-- Repairs the table in place: broken records out, holders older than HOLDER_AGE out, caps.
function GL.Sanitize(g, t)
  if type(g) ~= "table" then return end
  t = t or now()
  local n = 0
  if type(g.holders) ~= "table" then g.holders = {} end
  for full, x in pairs(g.holders) do
    if not plain(full, 80) or type(x) ~= "table" or not num(x.t) or x.t < t - GL.HOLDER_AGE or x.t > t + 300 then
      g.holders[full] = nil
    else
      if x.v ~= nil and not plain(x.v, 16) then x.v = nil end
      if x.g ~= nil and not plain(x.g) then x.g = nil end
      if not plain(x.n) then x.n = first(full) end
      n = n + 1
    end
  end
  while n > GL.HOLDERS_MAX do
    local k = oldestHolder(g.holders)
    if not k then break end
    g.holders[k] = nil
    n = n - 1
  end
  if type(g.ring) ~= "table" then g.ring = {} end
  local ring = {}
  for _, e in ipairs(g.ring) do
    if type(e) == "table" and plain(e.k, 16) and num(e.t) and e.t <= t + 300 then
      -- the place and the count of a merged line (1.6.0 call, sightings): broken fields out
      if e.m ~= nil and not (num(e.m) and num(e.x) and num(e.y)) then e.m, e.x, e.y = nil, nil, nil end
      if e.m == nil then e.x, e.y = nil, nil end
      if e.n ~= nil and not (num(e.n) and e.n >= 1) then e.n = nil end
      if e.t0 ~= nil and not num(e.t0) then e.t0 = nil end
      if e.gn ~= nil and not plain(e.gn) then e.gn = nil end
      ring[#ring + 1] = e
    end
  end
  table.sort(ring, function(a, b) return a.t > b.t end)
  while #ring > GL.RING_MAX do table.remove(ring) end
  g.ring = ring
  sortedRing = ring
  for _, k in ipairs({ "seenTab", "seenFeed", "recAt" }) do
    if g[k] ~= nil and not num(g[k]) then g[k] = nil end
  end
  if type(g.counts) ~= "table" then g.counts = {} end
end

---------------------------------------------------------------------------
-- Who has the book
---------------------------------------------------------------------------
local function guildName()
  local Gd = ns.Guild
  -- fixer 2 1.6.0 (jb04): only while this char is in a guild (the stored name may be another char's guild)
  local Bg = Gd and Gd.Bridge
  if Bg and Bg.inGuild and not Bg.inGuild() then return nil end
  local d = Gd and Gd.DB and Gd.DB()
  local name = type(d) == "table" and d.name or nil
  return plain(name) and name or nil
end

local function myFull()
  local B = ns.Guild and ns.Guild.Bridge
  return B and B.myFullName and B.myFullName() or nil
end
local function isMine(char)
  if type(char) ~= "string" then return false end
  if char == myFull() then return true end
  local own = ns.Guild and ns.Guild.IsOwnChar
  if type(own) ~= "function" then return false end
  local ok, v = pcall(own, char)
  return ok and v == true
end
local function myVersion()
  local B = ns.Guild and ns.Guild.Bridge
  local v = B and B.addonVersion and B.addonVersion()
  return plain(v, 16) and v or nil
end

-- Sync.lua's hook: a member sent something on GUILD (short and full name of the sender, version from his hello)
function GL.Heard(short, full, version)
  if not plain(full, 80) then return end
  local g = db()
  if not g then return end
  local t = now()
  local h = g.holders[full]
  if not h then
    local n = 0
    for _ in pairs(g.holders) do n = n + 1 end
    if n >= GL.HOLDERS_MAX then
      local k = oldestHolder(g.holders)
      if k then g.holders[k] = nil end
    end
    h = { n = plain(short) and short or first(full), t = t }
    g.holders[full] = h
  end
  h.t = t
  h.g = guildName() or h.g
  if plain(version, 16) then h.v = version end
end

-- "1.5.0" < "1.6.0"; nil when either is no version
function GL.Older(v, than)
  if type(v) ~= "string" or type(than) ~= "string" then return nil end
  local a, b = {}, {}
  for x in v:gmatch("%d+") do a[#a + 1] = tonumber(x) end
  for x in than:gmatch("%d+") do b[#b + 1] = tonumber(x) end
  if #a == 0 or #b == 0 then return nil end
  for i = 1, math.max(#a, #b) do
    local x, y = a[i] or 0, b[i] or 0
    if x ~= y then return x < y end
  end
  return false
end

-- The guild roster: total, online, a set of online names (lower case, without realm). On demand, at most every
-- ROSTER_TTL seconds; every call of the client API behind an existence check and pcall.
local roster = {}
function GL.Roster(force)
  local gt = G("GetTime")
  local t = type(gt) == "function" and gt() or 0
  if not force and roster.at and t - roster.at < GL.ROSTER_TTL then return roster end
  roster = { at = t, ok = false }
  local inG = G("IsInGuild")
  local okG, isIn = pcall(type(inG) == "function" and inG or function() return false end)
  if not okG or IsSecret(isIn) or not isIn then roster.why = "noguild"; return roster end
  local fnN, fnI = G("GetNumGuildMembers"), G("GetGuildRosterInfo")
  if type(fnN) ~= "function" or type(fnI) ~= "function" then roster.why = "noapi"; return roster end
  local ok, total, online = pcall(fnN)
  if not ok or not num(total) then roster.why = "error"; return roster end
  local names, on = {}, 0
  for i = 1, math.min(math.floor(total), GL.ROSTER_MAX) do
    local ok2, name, _, _, _, _, _, _, _, isOnline = pcall(fnI, i)
    if ok2 and isOnline == true and not IsSecret(name) and type(name) == "string" and name ~= "" then
      on = on + 1
      names[(name:match("^([^%-]+)") or name):lower()] = true
    end
  end
  if on == 0 and num(online) and online > 0 then on = math.floor(online) end
  roster.ok, roster.total, roster.online, roster.names = true, math.floor(total), on, names
  return roster
end

local function onlineIn(r, full)
  if not (r and r.ok and r.names) or type(full) ~= "string" then return false end
  local f = full:match("^([^%-]+)") or full
  return r.names[f:lower()] == true or r.names[first(full):lower()] == true
end

-- Book holders of the current guild, the own char first, then by last heard: rows { name, full, v, t, old, me,
-- online }. Second value: the header numbers { holders, online = online holders or nil, total online or nil }.
function GL.Holders()
  local g = db()
  local out = {}
  local t = now()
  local cur = guildName()
  local mine, mv = myFull(), myVersion()
  local r = GL.Roster()
  local seenMe = false
  if g and cur then
    for full, h in pairs(g.holders) do
      if type(h) == "table" and h.g == cur and num(h.t) and t - h.t <= GL.HOLDER_AGE then
        local me = full == mine
        if me then seenMe = true end
        out[#out + 1] = { name = h.n or first(full), full = full, v = h.v, t = h.t, me = me,
          old = GL.Older(h.v, mv) == true, online = me or onlineIn(r, full) }
      end
    end
  end
  if mine and cur and not seenMe then
    out[#out + 1] = { name = first(mine), full = mine, v = mv, t = t, me = true, old = false, online = true }
  end
  table.sort(out, function(a, b)
    if a.me ~= b.me then return a.me end
    if a.t ~= b.t then return a.t > b.t end
    return a.full < b.full
  end)
  local head = { holders = #out }
  if r.ok then
    local n = 0
    for i = 1, #out do if out[i].online then n = n + 1 end end
    head.online, head.total = n, math.max(r.online or 0, n)
  end
  return out, head
end

-- "12 of 48 online have the book" / "12 have the book"
function GL.HolderLine()
  local _, h = GL.Holders()
  if h.total then return Fmt(L.GLOG_HAVE_ONLINE, { count = h.online, total = h.total }), h end
  return Fmt(L.GLOG_HAVE, { count = h.holders }), h
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------
-- An event of another package (1.6.0 call: sightings, calls for help) or of this one: kind is a short word, data
-- { t, key, name, by, victim, zone, src, mapID, x, y, merge }. Kept in the ring (RING_MAX, the oldest go). true when
-- taken. mapID, x, y (percent) make the place a link to the map. merge = seconds: an event of the same kind and key
-- within that many seconds of the first of an earlier line makes that line newer and counts it (n) instead.
-- fixer 2 1.6.0 (je01): the ring stays sorted newest first by insertion (no sort per event); an older ring (data of an
-- earlier version) is sorted once.
local function ringPos(ring, t)
  local lo, hi = 1, #ring + 1
  while lo < hi do
    local mid = math.floor((lo + hi) / 2)
    if ring[mid].t >= t then lo = mid + 1 else hi = mid end
  end
  return lo
end
local function ringInsert(ring, e)
  if sortedRing ~= ring then
    table.sort(ring, function(a, b) return a.t > b.t end)
    sortedRing = ring
  end
  table.insert(ring, ringPos(ring, e.t), e)
end

local patchRing       -- (below the build)

function GL.Add(kind, data)
  if not plain(kind, 16) or type(data) ~= "table" then return false end
  local g = db()
  if not g then return false end
  local t = num(data.t) and math.floor(data.t) or now()
  local e = { k = kind, t = t }
  for _, f in ipairs({ "key", "name", "by", "victim", "zone" }) do
    if plain(data[f]) then e[f] = data[f] end
  end
  if num(data.g) then e.g = math.floor(data.g) end
  if data.src == "friends" or data.src == "guild" then e.src = data.src end
  -- fixer 2 1.6.0 (jb04): an event of the guild belongs to the guild of the char that heard it (gn); another char in
  -- another guild or without one does not see it. Friends' events stay the account's (the friends' book is).
  if e.src ~= "friends" then e.gn = guildName() end
  if num(data.mapID) and num(data.x) and num(data.y) then e.m, e.x, e.y = math.floor(data.mapID), data.x, data.y end
  local ring = g.ring
  if num(data.merge) and e.key then
    for i = 1, #ring do
      local x = ring[i]
      local first = num(x.t0) and x.t0 or x.t
      if x.k == e.k and x.key == e.key and x.src == e.src and x.gn == e.gn and t >= first and t - first < data.merge then
        if t >= x.t then
          x.t, x.by, x.zone, x.m, x.x, x.y = t, e.by, e.zone, e.m, e.x, e.y
          if e.name then x.name = e.name end
        end
        x.t0 = first
        x.n = math.min(GL.SIGHT_COUNT_MAX, (num(x.n) and x.n or 1) + 1)
        table.remove(ring, i)
        ringInsert(ring, x)
        patchRing(x, x)
        ns:Fire("GUILDLOG_UPDATED", kind)
        return true
      end
    end
  end
  for i = 1, #ring do
    local x = ring[i]
    if x.k == e.k and x.key == e.key and x.by == e.by and x.victim == e.victim and x.gn == e.gn and math.abs(x.t - t) < GL.SAME then
      return false
    end
  end
  ringInsert(ring, e)
  local gone
  while #ring > GL.RING_MAX do
    local x = table.remove(ring)
    if x == e then e = nil else gone = gone or {}; gone[#gone + 1] = x end
  end
  patchRing(e, nil, gone)
  ns:Fire("GUILDLOG_UPDATED", kind)
  return true
end

local function displayOf(e, key)
  if type(e) == "table" then
    local ok, d = pcall(Util.Display, e)
    if ok and plain(d, 80) then return d end
    if plain(e.display, 80) then return e.display end
  end
  if type(key) == "string" then
    local n, s = key:match("^([^%-]+)%-(.+)$")
    if n then return s:find("^#") and n or (n .. " " .. s) end
    return key
  end
  return "?"
end

-- the stores the chronicle reads: { { ctx, tag } } (guild while in one, friends when sharing with them)
local function sources(src)
  local out = {}
  local Gd = ns.Guild
  local B = Gd and Gd.Bridge
  if src ~= "friends" and B and B.gctx and B.inGuild and B.inGuild() and B.guildList and B.guildList() then
    out[#out + 1] = { ctx = B.gctx, tag = "guild", share = B.setting and B.setting("share") == true }
  end
  local F = ns.Friends
  if src ~= "guild" and F and type(F.ctx) == "table" and F.Enabled and F.Enabled() then
    out[#out + 1] = { ctx = F.ctx, tag = "friends", share = B and B.setting and B.setting("friends") == true }
  end
  return out
end

-- Every event of the books, newest first, plus the ring. Rows { k, t, key, name, by, victim, zone, place, g, victims,
-- src, mine }. Built only when looked at, cached until something changes (bump).
-- fixer 2 1.6.0 (je02): with `since`, a scan instead: only the events newer than since - SAME become rows (the rest is
-- a comparison), no names, no victims, no sort; what the dot and the ribbon count is the same as in the full list.
-- fixer 2 1.6.0 (jb04): an event of the ring is shown to a char of its guild (friends' events to every char)
local function ringVisible(e, gn)
  if e.src == "friends" then return true end
  return gn ~= nil and e.gn == gn
end
-- events of the guild from before the stamp: the guild of the first char in a guild that loads them
local function stampRing(g, gn)
  if not (g and gn) then return false end
  local n = 0
  for _, e in ipairs(g.ring) do
    if e.src ~= "friends" and e.gn == nil then e.gn = gn; n = n + 1 end
  end
  return n > 0
end
GL.StampRing = stampRing

local function ringRow(e, names)
  return { k = e.k, t = e.t, key = e.key, name = e.name or (e.key and (names[e.key] or displayOf(nil, e.key))),
    by = e.by, victim = e.victim, zone = e.zone, g = e.g, src = e.src or "guild", ring = true,
    mine = isMine(e.by or e.victim), n = e.n, quiet = GL.QUIET[e.k],
    place = num(e.m) and { mapID = e.m, x = e.x, y = e.y } or nil }
end
local function rowId(e) return e.k .. "\t" .. tostring(e.key) .. "\t" .. tostring(e.by or e.victim) .. "\t" .. tostring(e.t) end
local function before(a, b)
  if a.t ~= b.t then return a.t > b.t end
  if a.k ~= b.k then return a.k < b.k end
  return tostring(a.key) < tostring(b.key)
end

local function build(src, since)
  local scan = since ~= nil
  local lim = scan and since - GL.SAME or nil
  local out, seen, dup, rowOf = {}, {}, {}, {}
  local victimsOf, names, inBook = {}, {}, {}
  local function add(e)
    local id = rowId(e)
    if seen[id] then dup[id] = true; return false end
    seen[id] = e
    out[#out + 1] = e
    return true
  end
  local function fresh(t) return num(t) and (not lim or t > lim) end
  local list = sources(src)
  for _, s in ipairs(list) do
    local st = s.ctx.store
    for key, e in pairs(type(st) == "table" and type(st.enemies) == "table" and st.enemies or {}) do
      local name
      if not scan then
        name = names[key] or displayOf(e, key)
        names[key] = name
      end
      inBook[key] = true
      local deeds = type(e) == "table" and e.deeds
      if type(deeds) == "table" then
        for _, d in ipairs(deeds) do
          local v = type(d) == "table" and d.victim
          if fresh(d.t) and plain(v) then
            -- own deaths only while they are shared (the guild got them; else they stay in the own book)
            local mine = isMine(v)
            if s.share or not mine then
              add({ k = "death", t = d.t, key = key, name = name, victim = v, zone = plain(d.zone, 80) and d.zone or nil,
                place = (num(d.mapID) and d) or nil, src = s.tag, mine = mine })
              if not scan then
                local vl = victimsOf[key]
                if not vl then vl = {}; victimsOf[key] = vl end
                vl[#vl + 1] = { v = v, t = d.t }
              end
            end
          end
        end
      end
    end
    for key, h in pairs(type(s.ctx.hunts) == "table" and s.ctx.hunts or {}) do
      if type(h) == "table" then
        local name
        if not scan then
          name = names[key] or displayOf(h, key)
          names[key] = name
        end
        for char, x in pairs(type(h.by) == "table" and h.by or {}) do
          if plain(char) and type(x) == "table" and fresh(x.t) then
            add({ k = "release", t = x.t, key = key, name = name, by = char, src = s.tag, mine = isMine(char) })
          end
        end
        for _, b in ipairs(type(h.bags) == "table" and h.bags or {}) do
          if type(b) == "table" and plain(b.by) and fresh(b.t) then
            add({ k = "bag", t = b.t, key = key, name = name, by = b.by, src = s.tag, mine = isMine(b.by) })
          end
        end
      end
    end
    for key, x in pairs(type(s.ctx.bounty) == "table" and s.ctx.bounty or {}) do
      if type(x) == "table" then
        for char, r in pairs(x) do
          if plain(char) and type(r) == "table" and fresh(r.t) and num(r.g) then
            add({ k = "bounty", t = r.t, key = key, name = not scan and (names[key] or displayOf(nil, key)) or nil, by = char,
              g = r.g, src = s.tag, mine = isMine(char) })
          end
        end
      end
    end
  end
  local d = rawDB()
  if #list > 0 and type(d) == "table" then
    -- own bounties on killers of the guild or friends (they went out with B)
    for key, x in pairs(type(d.bounty) == "table" and d.bounty or {}) do
      if inBook[key] and type(x) == "table" then
        for char, r in pairs(x) do
          if plain(char) and type(r) == "table" and fresh(r.t) and num(r.g) then
            add({ k = "bounty", t = r.t, key = key, name = names[key], by = char, g = r.g, src = list[1].tag, mine = true })
          end
        end
      end
    end
    -- revenge: who took a killer of the guild or friends down (V, own and heard)
    for key, a in pairs(type(d.avenged) == "table" and d.avenged or {}) do
      if inBook[key] and type(a) == "table" then
        for _, l in ipairs(type(a.log) == "table" and a.log or {}) do
          if type(l) == "table" and plain(l.by) and fresh(l.t) then
            add({ k = "avenged", t = l.t, key = key, name = names[key], by = l.by, src = list[1].tag, mine = isMine(l.by) })
          end
        end
      end
    end
  end
  -- the ring: what the books no longer keep, and other packages' events
  local g = db()
  local gn = guildName()
  for _, e in ipairs(g and g.ring or {}) do
    -- the ring is sorted newest first (GL.Sanitize, GL.Add): a scan stops at the first old one
    if lim and sortedRing == g.ring and not (num(e.t) and e.t > lim) then break end
    if (src == "all" or (e.src or "guild") == src) and ringVisible(e, gn) then
      local x = ringRow(e, names)
      if x.k ~= "death" or not x.mine or (list[1] and list[1].share) then
        if add(x) then rowOf[e] = x end
      end
    end
  end
  -- one kill that came as V and as E: one event, the revenge (it names the avenged)
  local av = {}
  for _, e in ipairs(out) do
    if e.k == "avenged" then
      local k2 = tostring(e.key) .. "\t" .. tostring(e.by)
      av[k2] = av[k2] or {}
      table.insert(av[k2], e.t)
    end
  end
  local keep = {}
  for _, e in ipairs(out) do
    local drop = false
    if e.k == "bag" then
      for _, t in ipairs(av[tostring(e.key) .. "\t" .. tostring(e.by)] or {}) do
        if math.abs(t - e.t) < GL.SAME then drop = true; break end
      end
    end
    if not drop then keep[#keep + 1] = e end
  end
  out = keep
  if scan then GL.stat.scans = GL.stat.scans + 1; return out end
  -- whom a revenge avenged: the victims of that killer before it (newest first, each once)
  for _, e in ipairs(out) do
    if e.k == "avenged" or e.k == "bag" then
      local vl, vs, have = victimsOf[e.key], {}, {}
      if vl then
        table.sort(vl, function(a, b) return a.t > b.t end)
        for _, x in ipairs(vl) do
          -- the avenger himself is not "avenged" by his own kill
          if x.t <= e.t + GL.SAME and not have[x.v] and x.v ~= e.by then have[x.v] = true; vs[#vs + 1] = x.v end
        end
      end
      e.victims = vs
    end
  end
  table.sort(out, before)
  GL.stat.builds = GL.stat.builds + 1
  return out, { names = names, seen = seen, dup = dup, rowOf = rowOf }
end

local function counts(row, since) return row.t > since and not row.mine and not row.quiet end

-- fixer 2 1.6.0 (je01): a call or a sighting (the ring) changes the current lists and counts in place: the row goes in
-- at its place (binary search), a row of a merged line moves, a row that left the ring goes. Anything the patch cannot
-- be sure of (an id twice, a kind other than call and sight) makes everything stale as before.
local PATCH = { call = true, sight = true }
local function bsearch(list, row)
  local lo, hi = 1, #list + 1
  while lo < hi do
    local mid = math.floor((lo + hi) / 2)
    if before(list[mid], row) then lo = mid + 1 else hi = mid end
  end
  return lo
end
local function dropRow(c, row)
  for i = bsearch(c.list, row), #c.list do
    if c.list[i] == row then table.remove(c.list, i); return true end
  end
  for i = 1, #c.list do if c.list[i] == row then table.remove(c.list, i); return true end end
  return false
end
patchRing = function(e, moved, gone)
  local old = ver
  ver = ver + 1
  local ok = (not e or PATCH[e.k]) and true or false
  for _, x in ipairs(gone or {}) do if not PATCH[x.k] then ok = false end end
  if not ok then return end
  local allBad = false
  local okAll = pcall(function()
    for src, c in pairs(cache) do
      if c.ver == old and c.list then
        local good = true
        local function out(x)
          local row = c.rowOf[x]
          if not row then return end
          local id = rowId(row)
          if c.dup[id] or not dropRow(c, row) then good = false; return end
          c.seen[id], c.rowOf[x] = nil, nil
        end
        local function into(x)
          if not (src == "all" or (x.src or "guild") == src) or not ringVisible(x, guildName()) then return end
          local row = ringRow(x, c.names)
          local id = rowId(row)
          if c.seen[id] or c.dup[id] then good = false; return end
          table.insert(c.list, bsearch(c.list, row), row)
          c.seen[id], c.rowOf[x] = row, row
        end
        for _, x in ipairs(gone or {}) do out(x) end
        if moved then out(moved) end
        if good and e then into(e) end
        if good then c.ver = ver else cache[src] = nil; if src == "all" then allBad = true end end
      end
    end
  end)
  if not okAll then cache = {}; return end
  -- the counts of the dot and the ribbon: a quiet row (a sighting) changes nothing, a new row of another counts on, a
  -- row that left the ring counts off
  local sure = not allBad and not (moved and not GL.QUIET[moved.k])
  if sure then
    for w, m in pairs(marks) do
      if m.ver == old then
        local d = 0
        local gn = guildName()
        for _, x in ipairs(gone or {}) do if ringVisible(x, gn) and counts(ringRow(x, {}), m.since) then d = d - 1 end end
        if e and not moved and ringVisible(e, gn) and counts(ringRow(e, {}), m.since) then d = d + 1 end
        m.n, m.ver = m.n + d, ver
      end
    end
  end
  GL.stat.patches = GL.stat.patches + 1
end

-- all events of the source ("all" default, "guild", "friends"), newest first (not to be changed by callers)
function GL.All(src)
  src = (src == "guild" or src == "friends") and src or "all"
  local c = cache[src]
  if c and c.ver == ver then return c.list end
  local ok, list, meta = pcall(build, src)
  if not ok then
    if ns.ReportError then ns.ReportError(list) end
    list, meta = {}, nil
  end
  c = meta or { names = {}, seen = {}, dup = {}, rowOf = {} }
  c.ver, c.list = ver, list
  if not meta then c.dup = setmetatable({}, { __index = function() return true end }) end   -- never patched
  cache[src] = c
  return list
end

-- the chronicle: the newest FEED_MAX events
function GL.Feed(src)
  local all = GL.All(src)
  if #all <= GL.FEED_MAX then return all end
  local out = {}
  for i = 1, GL.FEED_MAX do out[i] = all[i] end
  return out
end

-- events of others newer than `since` (the dot on the tab, the count on the ribbon), and the newest time of all events
-- newer than since. From the built list when it is current, else from a scan (fixer 2 1.6.0, je02: the dot needs no
-- build of the chronicle).
local function since2(since, src)
  src = (src == "guild" or src == "friends") and src or "all"
  local n, top = 0, nil
  local c = cache[src]
  if c and c.ver == ver then
    for _, e in ipairs(c.list) do
      if e.t <= since then break end
      top = top or e.t
      if not e.mine and not e.quiet then n = n + 1 end
    end
    return n, top
  end
  local ok, rows = pcall(build, src, since)
  if not ok then
    if ns.ReportError then ns.ReportError(rows) end
    return 0, nil
  end
  for _, e in ipairs(rows) do
    if e.t > since then
      if not top or e.t > top then top = e.t end
      if not e.mine and not e.quiet then n = n + 1 end
    end
  end
  return n, top
end

function GL.NewSince(since, src)
  if not num(since) then return 0 end
  return (since2(since, src))
end

function GL.MarkSeen(which)
  local g = db()
  if not g or (which ~= "seenTab" and which ~= "seenFeed") then return end
  -- 1.6.0 fix: a time a little ahead (a clock that runs early, Sync takes up to 300 s) is seen as well
  local t = now()
  local _, top = since2(t, "all")
  if top and num(top) and top > t then t = math.min(top, t + 300) end
  g[which] = t
end
function GL.Unseen(which)
  local g = db()
  if not g then return 0 end
  local since = g[which]
  if not num(since) then return 0 end
  local m = marks[which]
  if m and m.ver == ver and m.since == since then return m.n end
  local n = since2(since, "all")
  marks[which] = { ver = ver, since = since, n = n }
  return n
end

---------------------------------------------------------------------------
-- Sentences
---------------------------------------------------------------------------
local function victimsText(vs)
  if type(vs) ~= "table" or #vs == 0 then return nil end
  local mine = myFull()
  local function nm(v) return v == mine and L.GLOG_VICTIM_YOU or first(v) end
  if #vs == 1 then return nm(vs[1]) end
  return Fmt(L.GLOG_VICTIMS_MORE, { name = nm(vs[1]), count = #vs - 1 })
end

-- 1.6.0 call: kinds whose sentence names the zone itself, and kinds that light no dot on the tab (quiet)
GL.ZONE_IN_SENTENCE = { call = true, sight = true }
GL.QUIET = { sight = true }

-- the sentence of one event (without time and place)
function GL.Sentence(e)
  if type(e) ~= "table" then return "" end
  local name = e.name or "?"
  local by = first(e.by)
  local me = e.mine
  if e.k == "death" then
    return me and Fmt(L.GLOG_EV_DEATH_ME, { name = name }) or Fmt(L.GLOG_EV_DEATH, { victim = first(e.victim), name = name })
  elseif e.k == "avenged" or e.k == "bag" then
    local vt = victimsText(e.victims)
    if vt then
      return me and Fmt(L.GLOG_EV_AVENGED_ME, { name = name, victims = vt })
        or Fmt(L.GLOG_EV_AVENGED, { by = by, name = name, victims = vt })
    end
    if e.k == "avenged" then
      return me and Fmt(L.GLOG_EV_TOOK_ME, { name = name }) or Fmt(L.GLOG_EV_TOOK, { by = by, name = name })
    end
    return me and Fmt(L.GLOG_EV_BAG_ME, { name = name }) or Fmt(L.GLOG_EV_BAG, { by = by, name = name })
  elseif e.k == "bounty" then
    local gold = Fmt(L.MONEY_GOLD, { count = e.g or 0 })
    return me and Fmt(L.GLOG_EV_BOUNTY_ME, { name = name, gold = gold })
      or Fmt(L.GLOG_EV_BOUNTY, { by = by, name = name, gold = gold })
  elseif e.k == "release" then
    return me and Fmt(L.GLOG_EV_RELEASE_ME, { name = name }) or Fmt(L.GLOG_EV_RELEASE, { by = by, name = name })
  elseif e.k == "call" then
    -- 1.6.0: a call for help (the zone stands in the sentence, the attacker when the caller had one)
    local zone = e.zone or L.CALL_SOMEWHERE
    if e.name then return Fmt(L.GLOG_EV_CALL_BY, { by = by, zone = zone, name = name }) end
    return Fmt(L.GLOG_EV_CALL, { by = by, zone = zone })
  elseif e.k == "sight" then
    -- 1.6.0: a sighting of a killer; sightings of him within SIGHT_MERGE are one line with the count
    local zone = e.zone or L.CALL_SOMEWHERE
    if num(e.n) and e.n > 1 then return Fmt(L.GLOG_EV_SIGHT_N, { by = by, name = name, zone = zone, count = e.n }) end
    return Fmt(L.GLOG_EV_SIGHT, { by = by, name = name, zone = zone })
  end
  -- a kind of another package without words of its own here
  return Fmt(L.GLOG_EV_OTHER, { by = e.by and by or "?", name = name })
end

-- "Anna was killed by Grimm, Ashenvale, 3 min ago"
function GL.Line(e)
  local s = GL.Sentence(e)
  local ago = Util.Ago and Util.Ago(e.t) or ""
  if e.zone and not GL.ZONE_IN_SENTENCE[e.k] then return Fmt(L.GLOG_LINE_PLACE, { text = s, place = e.zone, time = ago }) end
  return Fmt(L.GLOG_LINE, { text = s, time = ago })
end

-- the day word of a time: "Today", "Yesterday", else the date
function GL.DayWord(t, ref)
  ref = ref or now()
  local d = G("date") or (os and os.date)
  if type(d) ~= "function" or not num(t) then return "?" end
  local ok, a, b, c = pcall(function() return d("%Y-%m-%d", t), d("%Y-%m-%d", ref), d("%Y-%m-%d", ref - 86400) end)
  if ok then
    if a == b then return L.GLOG_TODAY end
    if a == c then return L.GLOG_YESTERDAY end
  end
  if ns.Chronicle and ns.Chronicle.Day then return ns.Chronicle.Day(t) end
  return "?"
end

-- the chronicle as rows for the page: { head = day word } and { event = e, text = line }
function GL.Rows(src)
  local out, last = {}, nil
  local t0 = now()
  for _, e in ipairs(GL.Feed(src)) do
    local day = GL.DayWord(e.t, t0)
    if day ~= last then out[#out + 1] = { head = day }; last = day end
    out[#out + 1] = { event = e, text = GL.Line(e) }
  end
  return out
end

---------------------------------------------------------------------------
-- The week
---------------------------------------------------------------------------
-- The last 7 days of the guild: deaths, revenge, the avengers (who took killers of the guild down, from V and E) and
-- the most wanted (who killed the most guildmates). { deaths, avenged, avengers = { { char, n, me } },
-- wanted = { { key, name, n } }, from, to, guild }
function GL.Week(t, src)
  t = t or now()
  src = src or "guild"
  local since = t - GL.WEEK
  local deaths, avenged = 0, 0
  local byChar, byKey, rows, krows = {}, {}, {}, {}
  for _, e in ipairs(GL.All(src)) do
    if e.t < since then break end
    if e.t <= t + 300 then
      if e.k == "death" then
        deaths = deaths + 1
        local r = byKey[e.key]
        if not r then r = { key = e.key, name = e.name, n = 0, last = e.t }; byKey[e.key] = r; krows[#krows + 1] = r end
        r.n = r.n + 1
      elseif e.k == "avenged" or e.k == "bag" then
        avenged = avenged + 1
        local r = byChar[e.by]
        if not r then r = { char = e.by, n = 0, me = e.mine, last = e.t }; byChar[e.by] = r; rows[#rows + 1] = r end
        r.n = r.n + 1
      end
    end
  end
  table.sort(rows, function(a, b)
    if a.n ~= b.n then return a.n > b.n end
    if a.last ~= b.last then return a.last > b.last end
    return a.char < b.char
  end)
  table.sort(krows, function(a, b)
    if a.n ~= b.n then return a.n > b.n end
    if a.last ~= b.last then return a.last > b.last end
    return tostring(a.key) < tostring(b.key)
  end)
  return { deaths = deaths, avenged = avenged, avengers = rows, wanted = krows, from = since, to = t, guild = guildName() }
end

-- the own rank title next to the own name (Ranks.lua, only while the rap sheet is on)
function GL.OwnRank()
  local Lg, R = ns.Ledger, ns.Ranks
  if not (Lg and Lg.Enabled and Lg.Repute and R and R.Title) then return nil end
  local ok, on = pcall(Lg.Enabled)
  if not ok or not on then return nil end
  local ok2, r = pcall(Lg.Repute)
  if not ok2 or type(r) ~= "table" then return nil end
  local ok3, title = pcall(R.Title, r.tier, r.path)
  return ok3 and type(title) == "string" and title or nil
end

local function day(t) return ns.Chronicle and ns.Chronicle.Day and ns.Chronicle.Day(t) or "?" end

-- the card's numbers as texts of the active language (the window and the lines share them)
function GL.CardTexts(w)
  w = w or GL.Week()
  local top, av = w.wanted[1], w.avengers[1]
  return {
    guild = w.guild and Fmt(L.GLOG_CARD_GUILD, { guild = w.guild }) or L.GLOG_CARD_NOGUILD,
    -- fixer 1.6.0: seven calendar days on the card ("04.11. to 10.11."), the count stays the rolling 7 x 24 hours
    week = Fmt(L.GLOG_CARD_WEEK, { from = day(w.to - GL.WEEK + 86400), to = day(w.to) }),
    deaths = Fmt(L.GLOG_CARD_DEATHS, { count = w.deaths }),
    avenged = Fmt(L.GLOG_CARD_AVENGED, { count = w.avenged }),
    wanted = top and Fmt(L.GLOG_CARD_WANTED, { name = top.name or "?", count = top.n }) or L.GLOG_CARD_WANTED_NONE,
    avenger = av and Fmt(L.GLOG_CARD_AVENGER, { name = first(av.char), count = av.n }) or L.GLOG_CARD_AVENGER_NONE,
    top = top, av = av, w = w,
  }
end

-- the chat line of the card (GUILD only): "[Revenge Book: Grimm] Guild X, week of … · 41 deaths · 12 avenged · …"
-- The most wanted stands in the bracket (a reader with the addon gets him as a link), the rest as segments.
function GL.WeekLine(t)
  local Sh = ns.Share
  if not Sh then return nil end
  local w = GL.Week(t)
  local c = GL.CardTexts(w)
  -- fixer 1.6.0: a count of 0 is no segment ("0 avenged" is not posted)
  local segs = { c.guild, c.week, w.deaths > 0 and c.deaths or nil, w.avenged > 0 and c.avenged or nil,
    c.top and Fmt(L.GLOG_LINE_WANTED, { count = c.top.n }) or nil, c.av and c.avenger or nil }
  local list = {}
  for i = 1, 6 do if segs[i] then list[#list + 1] = segs[i] end end
  return Sh.Build(c.top and c.top.name or nil, list), w
end

local function md(s) return (tostring(s):gsub("([%*_~`\\>|])", "\\%1")) end

-- the block for Discord (a few lines, the guild and the most wanted bold)
function GL.WeekDiscord(t)
  local w = GL.Week(t)
  local c = GL.CardTexts(w)
  local sep = (ns.Share and ns.Share.SEP) or " · "
  local lines = {
    "**" .. md(c.guild) .. "**" .. sep .. md(c.week),
    md(c.deaths) .. sep .. md(c.avenged),
    c.top and Fmt(md(L.GLOG_CARD_WANTED), { name = "**" .. md(c.top.name or "?") .. "**", count = c.top.n }) or md(c.wanted),
    md(c.avenger),
    "*" .. ((ns.Share and ns.Share.BRAND) or "Revenge Book") .. "*",
  }
  return table.concat(lines, "\n")
end

---------------------------------------------------------------------------
-- Sending: one line on the player's click, GUILD only (Share.Send: never in combat or a chat lockdown)
---------------------------------------------------------------------------
function GL.RecommendWait(t)
  local g = db()
  local at = g and g.recAt
  if not num(at) then return 0 end
  local w = GL.RECOMMEND_GAP - ((t or now()) - at)
  return w > 0 and math.ceil(w) or 0
end

-- the line of "recommend to the guild": plain text in the sender's language, no link, no brackets
function GL.RecommendLine()
  local s = L.GLOG_RECOMMEND_LINE
  if type(s) ~= "string" then return nil end
  return (s:gsub("[%c|%[%]]", ""))
end

-- true | false, reason ("wait", "noguild", and Share.Send's reasons)
function GL.Recommend()
  if GL.RecommendWait() > 0 then return false, "wait" end
  local Sh = ns.Share
  if not Sh then return false, "noapi" end
  local okc = false
  for _, ch in ipairs(Sh.Channels()) do if ch == "GUILD" then okc = true end end
  if not okc then return false, "noguild" end
  local ok, why = Sh.Send(GL.RecommendLine(), "GUILD")
  if not ok then return false, why end
  local g = db()
  if g then g.recAt = now() end
  GL.Count("recommend")
  return true
end

function GL.QuietWeek(w)
  w = w or GL.Week()
  return (w.deaths or 0) == 0 and (w.avenged or 0) == 0
end

function GL.PostWeek()
  local Sh = ns.Share
  if not Sh then return false, "noapi" end
  local okc = false
  for _, ch in ipairs(Sh.Channels()) do if ch == "GUILD" then okc = true end end
  if not okc then return false, "noguild" end
  -- fixer 1.6.0: a quiet week (no death, nothing avenged) is not posted
  if GL.QuietWeek() then return false, "empty" end
  local line = GL.WeekLine()
  local ok, why = Sh.Send(line, "GUILD")
  if ok then GL.Count("weekPosted") end
  return ok, why
end

---------------------------------------------------------------------------
-- Probe (probe.glog): book holders heard, events per kind, the roster, the counters
---------------------------------------------------------------------------
function GL.ProbeSnapshot()
  local g = db()
  local kinds = {}
  for _, e in ipairs(GL.All("all")) do kinds[e.k] = (kinds[e.k] or 0) + 1 end
  local stored = 0
  for _ in pairs(g and g.holders or {}) do stored = stored + 1 end
  local hl = GL.Holders()
  local r = GL.Roster(true)
  local counts = {}
  for k, v in pairs(g and g.counts or {}) do counts[k] = v end
  return { holders = #hl, holdersStored = stored, events = kinds, ring = g and #g.ring or 0,
    roster = r.ok and "ok" or (r.why or "?"), rosterTotal = r.total, rosterOnline = r.online, counts = counts }
end

---------------------------------------------------------------------------
-- Bus
---------------------------------------------------------------------------
ns:On("READY", function()
  local g = db()
  if not g then return end
  GL.Sanitize(g, now())
  stampRing(g, guildName())
  -- a first start sees no dot for the whole past
  if not g.seenTab then g.seenTab = now() end
  if not g.seenFeed then g.seenFeed = now() end
  bump()
end)
-- 1.6.0 fix: a mere sighting (lastSeen, Sync.lua's reason "seen") is nothing the chronicle shows: the cache stays
ns:On("GUILD_UPDATED", function(reason)
  if reason ~= "seen" then
    stampRing(db(), guildName())   -- the guild's name came later than READY
    bump()
  end
end)
ns:On("AVENGED", bump)
-- a target of the hit list taken down: kept in the ring (the hit list forgets it with the call-off)
ns:On("HUNT_BAGGED", function(key, char, t, src)
  if type(key) ~= "string" then return end
  local Gd = ns.Guild
  local h = Gd and Gd.Hunt and Gd.Hunt(key, src)
  GL.Add("bag", { key = key, by = char, t = t, src = src == "friends" and "friends" or "guild",
    name = h and displayOf(h, key) or nil })
end)
-- 1.6.0 call: a call for help and a sighting of a killer go into the chronicle (only from guild and friends; a call of
-- the group only when the caller is a guildmate). Sightings of the same enemy within SIGHT_MERGE are one line.
function GL.OnHelpCall(rec)
  if type(rec) ~= "table" then return false end
  local src = rec.from == "guild" and "guild" or rec.from == "friend" and "friends" or nil
  if rec.from == "group" then
    local Gd = ns.Guild
    local ok, mate = pcall(function() return Gd and Gd.IsGuildmate and Gd.IsGuildmate(rec.by) end)
    if ok and mate == true then src = "guild" end
  end
  if not src then return false end
  return GL.Add("call", { t = rec.t, key = rec.key, name = rec.display, by = rec.by, zone = rec.zone, src = src,
    mapID = rec.mapID, x = rec.x, y = rec.y })
end
function GL.OnSighting(rec)
  if type(rec) ~= "table" or type(rec.key) ~= "string" then return false end
  local src = rec.src == "friends" and "friends" or rec.src == "guild" and "guild" or nil
  if not src then return false end
  return GL.Add("sight", { t = rec.t, key = rec.key, name = rec.name, by = rec.by, zone = rec.zone, src = src,
    mapID = rec.mapID, x = rec.x, y = rec.y, merge = GL.SIGHT_MERGE })
end
ns:On("HELP_CALL", function(rec) GL.OnHelpCall(rec) end)
ns:On("SIGHTING", function(rec) GL.OnSighting(rec) end)

ns:On("SETTINGS_CHANGED", function(path)
  if type(path) == "string" and (path:find("^guild%.") or path == "ledger.enabled") then bump() end
end)
