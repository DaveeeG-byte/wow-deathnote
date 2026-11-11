-- DeathNote - Sync.lua
-- Guild death list: invisible addon messages in the GUILD channel.
-- Every client sends only its OWN sure open-world kills (deaths of this account),
-- never data heard from others. Received data lives apart in DeathNoteDB.guild.
--
-- Wire format (one addon message, at most 255 bytes, fields separated by TAB,
-- each field percent-escaped for '%', '|' and control bytes):
--   1 K key display class level zone t victim   a kill, just happened
--   1 R key display class level zone t victim   a kill, sent as answer to H
--   1 H since version                           hello after login: "send me your kills newer than since"
--   1 S key zone t                              a listed guild enemy was seen (only when sightings are on)
--   1 M key display class level t char          on my list by hand (1.1.0), live and in answers to H
--   1 X key char                                taken off my list again (deleted or pardoned, 1.1.0)
-- The first field is the protocol version; unknown versions and types are dropped silently.

local ADDON, ns = ...
local Util = ns.Util

local Guild = {}
ns.Guild = Guild

---------------------------------------------------------------------------
-- Constants
---------------------------------------------------------------------------
local PREFIX = "DeathNote"
local PROTO = "1"
local C = {
  MAX_MSG = 255,
  MAX_FIELD = 64,           -- bytes per string field (decoded)
  MAX_ENEMIES = 400,
  MAX_DEEDS = 20,
  MAX_AGE = 180 * 86400,    -- deeds older than this are dropped
  FUTURE = 300,             -- tolerated clock skew into the future
  FRESH = 120,              -- a K this young fires GUILD_KILL
  MAX_LEVEL = 100,
  MAX_MEMBERS = 200,
  SEND_GAP = 0.3,           -- seconds between two sent messages
  BACKOFF = 1.5,            -- seconds after a throttled or failed send
  REPLY_MAX = 30,           -- R messages per answer to a hello
  QUEUE_MAX = 120,
  QUEUE_TTL = 600,          -- a queued message older than this is dropped
  TRIES = 5,                -- send attempts per message
  HOLD_RETRY = 30,          -- fallback timer while sending is held back
  HOLD_MAX = 20,            -- fallback timer rounds before the queue is dropped
  HELLO_MIN = 8, HELLO_MAX = 20,
  REPLY_MIN = 2, REPLY_MAX_DELAY = 8,
  SYNC_COOLDOWN = 60,       -- own /dn sync: one hello per minute
  REPLY_GAP = 10,           -- seconds between two answers (hellos meanwhile are merged)
  HELLO_PER_SENDER = 300,   -- a hello of the same member is answered at most every 5 min
  MAX_PER_SENDER = 40,      -- guild enemies one member may bring in
  ANNOUNCE_MAX = 3,         -- fresh kills per member and minute that fire GUILD_KILL
  MAX_LISTS = 5,            -- guild lists kept (one per guild of the account's characters)
  MEMBER_MAX_AGE = 60 * 86400,
  SINCE_OVERLAP = 600,
  LOOKBACK = 3 * 86400,     -- a hello always asks for at least the last 3 days
  FLOOD_WINDOW = 60, FLOOD_MAX = 150,
  UPDATE_THROTTLE = 0.5,
  SEEN_WRITE = 5,           -- seconds between lastSeen writes per guild enemy
  SIGHT_SEND = 120,         -- seconds between S messages per enemy
  -- names listed by hand (M/X, 1.1.0)
  LISTED_MAX = 20,          -- listed names per member (they count into MAX_PER_SENDER and MAX_ENEMIES)
  LISTED_REPLY = 20,        -- M messages per answer to a hello
  UNLISTED_REPLY = 10,      -- X messages per answer (removals a member may have missed)
  LISTED_MAX_AGE = 5 * 365 * 86400,   -- a listing older than this is not accepted
  TOMB_MAX = 30, TOMB_AGE = 30 * 86400,   -- remembered removals (resent in answers)
}
Guild.PREFIX, Guild.C = PREFIX, C

---------------------------------------------------------------------------
-- Pure protocol functions (no WoW calls; `now` is always passed in)
---------------------------------------------------------------------------
local P = {}
Guild.Proto = P

local function escByte(c) return ("%%%02X"):format(c:byte()) end
function P.Escape(v)
  if v == nil then return "" end
  return (tostring(v):gsub("[%c%%|]", escByte))
end

local function hexByte(h) return string.char(tonumber(h, 16)) end
-- Decoded field or nil when the escaping is broken or the result is not plain text.
function P.Unescape(s)
  if s:find("%", 1, true) then
    if s:gsub("%%%x%x", ""):find("%", 1, true) then return nil end
    s = s:gsub("%%(%x%x)", hexByte)
  end
  if #s > C.MAX_FIELD or s:find("[%c|]") then return nil end
  return s
end

-- Cuts a string to at most n bytes without splitting a UTF-8 character.
function P.CutUTF8(s, n)
  if #s <= n then return s end
  if n <= 0 then return "" end
  s = s:sub(1, n)
  local i = #s
  local b = s:byte(i)
  if b >= 0x80 then
    -- walk back to the lead byte of the last character
    local j = i
    while j > 1 and s:byte(j) >= 0x80 and s:byte(j) < 0xC0 do j = j - 1 end
    local lead = s:byte(j)
    local need = lead >= 0xF0 and 4 or lead >= 0xE0 and 3 or lead >= 0xC0 and 2 or 1
    if i - j + 1 < need then s = s:sub(1, j - 1) end
  end
  return s
end

local function plain(s, max)
  if type(s) ~= "string" then return "" end
  s = s:gsub("[%c|]", "")
  return P.CutUTF8(s, max or C.MAX_FIELD)
end

-- Kill/answer message. k = { key, display, class, level, zone, t, victim }, kind "K" or "R".
-- Returns the text (<= 255 bytes) or nil when it cannot be made valid.
function P.EncodeKill(k, kind)
  if type(k) ~= "table" or type(k.key) ~= "string" or type(k.t) ~= "number" then return nil end
  local key = plain(k.key)
  if key ~= k.key then return nil end
  local display = plain(k.display)
  if display == key then display = "" end
  local class = type(k.class) == "string" and k.class:match("^%u+$") and #k.class <= 16 and k.class or ""
  local level = type(k.level) == "number" and math.floor(k.level) or 0
  if level < 0 or level > C.MAX_LEVEL then level = 0 end
  local zone = plain(k.zone)
  local victim = plain(k.victim)
  if victim == "" then return nil end
  local head = table.concat({ PROTO, kind == "R" and "R" or "K", P.Escape(key) }, "\t")
  local tail = table.concat({ class, tostring(level) }, "\t")
  local tt = tostring(math.floor(k.t))
  local function build()
    return head .. "\t" .. P.Escape(display) .. "\t" .. tail .. "\t" .. P.Escape(zone) .. "\t" .. tt .. "\t" .. P.Escape(victim)
  end
  local msg = build()
  -- too long: shorten the zone, then drop the display name (it can be derived from the key)
  while #msg > C.MAX_MSG and zone ~= "" do
    zone = P.CutUTF8(zone, #zone - math.max(1, math.ceil((#msg - C.MAX_MSG) / 3)))
    msg = build()
  end
  if #msg > C.MAX_MSG then display = ""; msg = build() end
  if #msg > C.MAX_MSG then return nil end
  return msg
end

function P.EncodeHello(since, version)
  local v = type(version) == "string" and version:match("^%d+%.%d+[%.%d]*$") and #version <= 16 and version or "0"
  return table.concat({ PROTO, "H", tostring(math.floor(tonumber(since) or 0)), v }, "\t")
end

function P.EncodeSight(key, zone, t)
  if type(key) ~= "string" or plain(key) ~= key or type(t) ~= "number" then return nil end
  local msg = table.concat({ PROTO, "S", P.Escape(key), P.Escape(plain(zone)), tostring(math.floor(t)) }, "\t")
  if #msg > C.MAX_MSG then return nil end
  return msg
end

-- Listed by hand. l = { key, display, class, level, t, by }; by = "Name Surname" of the char.
function P.EncodeListed(l)
  if type(l) ~= "table" or type(l.key) ~= "string" or type(l.t) ~= "number" then return nil end
  local key = plain(l.key)
  if key ~= l.key then return nil end
  local by = plain(l.by)
  if by == "" or by ~= l.by then return nil end
  local display = plain(l.display)
  if display == key then display = "" end
  local class = type(l.class) == "string" and l.class:match("^%u+$") and #l.class <= 16 and l.class or ""
  local level = type(l.level) == "number" and math.floor(l.level) or 0
  if level < 0 or level > C.MAX_LEVEL then level = 0 end
  local tt = tostring(math.floor(l.t))
  local msg = table.concat({ PROTO, "M", P.Escape(key), P.Escape(display), class, tostring(level), tt, P.Escape(by) }, "\t")
  if #msg > C.MAX_MSG then
    msg = table.concat({ PROTO, "M", P.Escape(key), "", class, tostring(level), tt, P.Escape(by) }, "\t")
  end
  if #msg > C.MAX_MSG then return nil end
  return msg
end

function P.EncodeUnlisted(key, by)
  if type(key) ~= "string" or plain(key) ~= key or type(by) ~= "string" or by == "" or plain(by) ~= by then return nil end
  local msg = table.concat({ PROTO, "X", P.Escape(key), P.Escape(by) }, "\t")
  if #msg > C.MAX_MSG then return nil end
  return msg
end

-- Canonical key check: "Name-Surname" exactly as Util.KeyFor would build it.
function P.ValidKey(key)
  if type(key) ~= "string" or #key < 3 or #key > C.MAX_FIELD then return nil end
  local n, s = key:match("^([^%-%s]+)%-(.+)$")
  if not n then return nil end
  local k, kn, ks = Util.KeyFor(n, s)
  if k ~= key then return nil end
  return kn, ks
end

local F = {}   -- reusable field buffer
local function split(text, maxFields)
  local n, pos = 0, 1
  while true do
    local s = text:find("\t", pos, true)
    n = n + 1
    if n > maxFields then return nil end
    if not s then F[n] = text:sub(pos); break end
    F[n] = text:sub(pos, s - 1)
    pos = s + 1
  end
  for i = n + 1, #F do F[i] = nil end
  return n
end

local function int(s, lo, hi)
  if type(s) ~= "string" or not s:match("^%d+$") or #s > 12 then return nil end
  local v = tonumber(s)
  if not v or v < lo or v > hi then return nil end
  return v
end

local FIELDS = { K = 9, R = 9, H = 4, S = 5, M = 8, X = 4 }

-- Parses an incoming text into `out` (a reused table). Returns out or nil, reason.
-- Never raises for any input.
function P.Decode(text, now, out)
  if type(text) ~= "string" or #text == 0 or #text > C.MAX_MSG then return nil, "size" end
  local n = split(text, 9)
  if not n then return nil, "fields" end
  if F[1] ~= PROTO then return nil, "version" end
  local kind = F[2]
  local want = FIELDS[kind]
  if not want then return nil, "type" end
  if n ~= want then return nil, "fields" end
  out = out or {}
  for k in pairs(out) do out[k] = nil end
  out.kind = kind
  if kind == "H" then
    out.since = int(F[3], 0, now + C.FUTURE)
    if not out.since then return nil, "since" end
    local v = F[4]
    out.version = (#v <= 16 and v:match("^%d+%.%d+[%.%d]*$")) and v or nil
    return out
  end
  local key = P.Unescape(F[3])
  if not key then return nil, "key" end
  local name, surname = P.ValidKey(key)
  if not name then return nil, "key" end
  out.key, out.name, out.surname = key, name, surname
  if kind == "S" then
    out.zone = P.Unescape(F[4])
    out.t = int(F[5], now - C.MAX_AGE, now + C.FUTURE)
    if not out.zone or not out.t then return nil, "fields" end
    return out
  end
  if kind == "X" then
    out.by = P.Unescape(F[4])
    if not out.by or out.by == "" then return nil, "by" end
    return out
  end
  local display = P.Unescape(F[4])
  if not display then return nil, "display" end
  -- the display name may only be "Name Surname" or "Name"
  if display ~= name and display ~= name .. " " .. surname then display = name .. " " .. surname end
  out.display = display
  local class = F[5]
  if class ~= "" and not (class:match("^%u+$") and #class <= 16) then return nil, "class" end
  out.class = class ~= "" and class or nil
  out.level = int(F[6], 0, C.MAX_LEVEL)
  if not out.level then return nil, "level" end
  if out.level == 0 then out.level = nil end
  if kind == "M" then
    out.t = int(F[7], now - C.LISTED_MAX_AGE, now + C.FUTURE)
    if not out.t then return nil, "time" end
    out.by = P.Unescape(F[8])
    if not out.by or out.by == "" then return nil, "by" end
    return out
  end
  out.zone = P.Unescape(F[7])
  if not out.zone then return nil, "zone" end
  if out.zone == "" then out.zone = nil end
  out.t = int(F[8], now - C.MAX_AGE, now + C.FUTURE)
  if not out.t then return nil, "time" end
  out.victim = P.Unescape(F[9])
  if not out.victim or out.victim == "" then return nil, "victim" end
  return out
end

-- Derived fields of a guild entry (kills, victims, last*). deeds are newest first.
function P.Recompute(e)
  local deeds = e.deeds
  e.kills = #deeds
  local victims, vc = {}, 0
  for i = 1, #deeds do
    local v = deeds[i].victim
    if v then
      if not victims[v] then vc = vc + 1 end
      victims[v] = (victims[v] or 0) + 1
    end
  end
  e.victims, e.victimCount = victims, vc
  local d = deeds[1]
  e.lastKill = d and d.t or nil
  e.lastZone = d and d.zone or nil
  e.lastVictim = d and d.victim or nil
  -- listed by hand (1.1.0): listedBy = { [char] = time listed }
  local lc, last = 0, nil
  if e.listedBy then
    for _, t in pairs(e.listedBy) do
      lc = lc + 1
      if not last or t > last then last = t end
    end
    if lc == 0 then e.listedBy = nil end
  end
  e.listedCount, e.lastListed = lc, last
  e.listedOnly = e.kills == 0
end

-- lower-case first word of a char name: the key of the per-member listing count
local function memberKey(char)
  local w = type(char) == "string" and char:match("^([^%s%-]+)")
  return w and w:lower() or nil
end
P.MemberKey = memberKey

local function countBy(store, by, d)
  local bs = store.bySender
  if not bs then bs = {}; store.bySender = bs end
  local n = (bs[by] or 0) + d
  bs[by] = n > 0 and n or nil
end

local function countListed(store, char, d)
  local mk = memberKey(char)
  if not mk then return end
  local ls = store.listedBySender
  if not ls then ls = {}; store.listedBySender = ls end
  local n = (ls[mk] or 0) + d
  ls[mk] = n > 0 and n or nil
end

-- Which entry leaves when the list is full. Entries listed by hand only (no kills) go
-- first, those of the member who brought in the most entries before the others; then the
-- oldest entry of that member (one member cannot push out everybody else); `protect` = own name.
local function evict(store, keepKey, protect)
  local enemies = store.enemies
  local top, topN
  for by, n in pairs(store.bySender or {}) do
    if by ~= protect and (not topN or n > topN or (n == topN and by < top)) then top, topN = by, n end
  end
  for pass = 1, 4 do
    local oldKey, oldT
    local onlyListed, onlyTop = pass <= 2, pass == 1 or pass == 3
    for k, x in pairs(enemies) do
      if k ~= keepKey and (not onlyTop or x.by == top) and (not onlyListed or (x.kills or 0) == 0) then
        local t = (x.kills or 0) == 0 and (x.lastListed or 0) or (x.lastKill or 0)
        if not oldT or t < oldT then oldKey, oldT = k, t end
      end
    end
    if oldKey then return oldKey end
  end
  return nil
end

local function drop(store, key)
  local x = store.enemies[key]
  if not x then return end
  countBy(store, x.by or "?", -1)
  if x.listedBy then for char in pairs(x.listedBy) do countListed(store, char, -1) end end
  store.enemies[key] = nil
  store.count = store.count - 1
end
P.Drop = drop

-- Store = { enemies = {}, count = n, bySender = { name -> entries brought in } }. Adds one deed.
-- m = decoded kill (or own kill), by = reporter name, opts = { maxPerSender, protect } (optional).
-- Returns "new", entry, deed | "dup" | "old" | "cap" | nil.
function P.Merge(store, m, by, opts)
  local enemies = store.enemies
  local e = enemies[m.key]
  if e then
    local deeds = e.deeds
    for i = 1, #deeds do
      local d = deeds[i]
      if d.t == m.t and d.victim == m.victim then return "dup" end
    end
    if #deeds >= C.MAX_DEEDS and deeds[#deeds].t >= m.t then return "old" end
  else
    local max = opts and opts.maxPerSender
    if max and store.bySender and (store.bySender[by] or 0) >= max then return "cap" end
    e = { key = m.key, name = m.name, surname = m.surname, display = m.display, deeds = {}, by = by }
    enemies[m.key] = e
    store.count = (store.count or 0) + 1
    countBy(store, by, 1)
  end
  if m.class then e.class = m.class end
  if m.level and (not e.lastKill or m.t >= e.lastKill) then e.level = m.level end
  if m.display and (not e.display or #m.display > #e.display) then e.display = m.display end
  e.display = e.display or m.name
  local deed = { t = m.t, zone = m.zone, victim = m.victim, level = m.level, by = by }
  local deeds = e.deeds
  local pos = #deeds + 1
  for i = 1, #deeds do if deeds[i].t < m.t then pos = i; break end end
  table.insert(deeds, pos, deed)
  while #deeds > C.MAX_DEEDS do table.remove(deeds) end
  P.Recompute(e)
  -- total cap: one entry leaves (never the one just added), see evict()
  if store.count > C.MAX_ENEMIES then
    local oldKey = evict(store, m.key, opts and opts.protect)
    if oldKey then drop(store, oldKey) end
  end
  return "new", e, deed
end

-- Adds "listed by hand by m.by" (decoded M or own entry). by = reporter short name.
-- opts = { maxPerSender, maxListed, protect } (optional).
-- Returns "new" (entry created), "add" (listing added), "upd" (time changed), "dup", "cap" | nil, entry.
function P.MergeListed(store, m, by, opts)
  local enemies = store.enemies
  local e = enemies[m.key]
  local char = m.by
  local had = e and e.listedBy and e.listedBy[char]
  if had then
    if had == m.t then return "dup", e end
    e.listedBy[char] = m.t
    P.Recompute(e)
    return "upd", e
  end
  local maxListed = opts and opts.maxListed
  local mk = memberKey(char)
  if not mk then return nil end
  if maxListed and store.listedBySender and (store.listedBySender[mk] or 0) >= maxListed then return "cap" end
  local res = "add"
  if not e then
    local max = opts and opts.maxPerSender
    if max and store.bySender and (store.bySender[by] or 0) >= max then return "cap" end
    e = { key = m.key, name = m.name, surname = m.surname, display = m.display, deeds = {}, by = by }
    enemies[m.key] = e
    store.count = (store.count or 0) + 1
    countBy(store, by, 1)
    res = "new"
  end
  if m.class and not e.class then e.class = m.class end
  if m.level and not e.lastKill then e.level = m.level end
  if m.display and (not e.display or #m.display > #e.display) then e.display = m.display end
  e.display = e.display or m.name
  e.listedBy = e.listedBy or {}
  e.listedBy[char] = m.t
  countListed(store, char, 1)
  P.Recompute(e)
  if store.count > C.MAX_ENEMIES then
    local oldKey = evict(store, m.key, opts and opts.protect)
    if oldKey then drop(store, oldKey) end
  end
  return res, e
end

-- Removes the listing of `char`; the entry leaves when it has neither kills nor listings.
-- Returns "gone" (entry removed), "removed", or nil (nothing to remove).
function P.Unlist(store, key, char)
  local e = store.enemies[key]
  if not e or not e.listedBy or not e.listedBy[char] then return nil end
  e.listedBy[char] = nil
  countListed(store, char, -1)
  P.Recompute(e)
  if e.kills == 0 and not e.listedBy then
    countBy(store, e.by or "?", -1)
    store.enemies[key] = nil
    store.count = store.count - 1
    return "gone"
  end
  return "removed"
end

-- Recounts the per-sender counters (entries brought in, listings per member).
function P.Recount(store)
  store.count, store.bySender, store.listedBySender = 0, {}, {}
  for _, e in pairs(store.enemies) do
    store.count = store.count + 1
    countBy(store, e.by or "?", 1)
    if e.listedBy then for char in pairs(e.listedBy) do countListed(store, char, 1) end end
  end
end

-- Repairs/prunes a stored guild list in place (old deeds out, broken entries out). Returns count.
function P.Sanitize(store, now)
  if type(store.enemies) ~= "table" then store.enemies = {} end
  local count = 0
  for key, e in pairs(store.enemies) do
    local keep = type(e) == "table" and P.ValidKey(key) and type(e.deeds) == "table"
    if keep then
      local deeds = e.deeds
      for i = #deeds, 1, -1 do
        local d = deeds[i]
        if type(d) ~= "table" or type(d.t) ~= "number" or d.t < now - C.MAX_AGE or type(d.victim) ~= "string" then
          table.remove(deeds, i)
        end
      end
      table.sort(deeds, function(a, b) return a.t > b.t end)
      while #deeds > C.MAX_DEEDS do table.remove(deeds) end
      -- listed by hand (1.1.0): plain char names, plain times
      local lb = e.listedBy
      if lb ~= nil and type(lb) ~= "table" then lb = nil; e.listedBy = nil end
      if lb then
        for char, t in pairs(lb) do
          if type(char) ~= "string" or char == "" or #char > C.MAX_FIELD or char:find("[%c|]")
            or type(t) ~= "number" or t ~= t or t < now - C.LISTED_MAX_AGE or t > now + C.FUTURE then
            lb[char] = nil
          end
        end
        if next(lb) == nil then e.listedBy = nil end
      end
      keep = #deeds > 0 or e.listedBy ~= nil
      if keep then
        e.key = key
        local n, s = P.ValidKey(key)
        e.name, e.surname = n, s
        if type(e.display) ~= "string" then e.display = n .. " " .. s end
        if e.lastSeen ~= nil and type(e.lastSeen) ~= "table" then e.lastSeen = nil end
        e.mine = nil
        -- who brought it in (older data: the reporter of the oldest deed)
        if type(e.by) ~= "string" then
          local d = deeds[#deeds]
          if d then
            e.by = type(d.by) == "string" and d.by or "?"
          else
            local w = next(e.listedBy):match("^([^%s%-]+)")
            e.by = w or "?"
          end
        end
        P.Recompute(e)
      end
    end
    if keep then count = count + 1 else store.enemies[key] = nil end
  end
  while count > C.MAX_ENEMIES do
    local oldKey, oldT
    for k, x in pairs(store.enemies) do
      if not oldT or (x.lastKill or 0) < oldT then oldKey, oldT = k, x.lastKill or 0 end
    end
    store.enemies[oldKey] = nil
    count = count - 1
  end
  P.Recount(store)
  return store.count
end

-- Entries listed by hand only (kills == 0) sort after all entries with kills, newest listing first.
local function rankLess(a, b)
  if (a.kills or 0) ~= (b.kills or 0) then return (a.kills or 0) > (b.kills or 0) end
  if (a.lastKill or 0) ~= (b.lastKill or 0) then return (a.lastKill or 0) > (b.lastKill or 0) end
  if (a.kills or 0) == 0 and (a.lastListed or 0) ~= (b.lastListed or 0) then
    return (a.lastListed or 0) > (b.lastListed or 0)
  end
  return a.key < b.key
end
P.SORTS = {
  rank = rankLess,
  recent = function(a, b)
    if (a.lastKill or 0) ~= (b.lastKill or 0) then return (a.lastKill or 0) > (b.lastKill or 0) end
    return a.key < b.key
  end,
  name = function(a, b)
    local na, nb = (a.display or a.key):lower(), (b.display or b.key):lower()
    if na ~= nb then return na < nb end
    return a.key < b.key
  end,
}

-- only: nil = all, "kills" = entries with kills, "listed" = entries listed by hand only
function P.Sorted(enemies, sort, only)
  local out = {}
  for _, e in pairs(enemies) do
    if not only or (only == "kills") == ((e.kills or 0) > 0) then out[#out + 1] = e end
  end
  table.sort(out, P.SORTS[sort] or rankLess)
  return out
end

-- Flood guard: returns false when `who` sent more than FLOOD_MAX messages in FLOOD_WINDOW.
function P.Flood(state, who, now)
  local f = state[who]
  if not f then f = { at = now, n = 0 }; state[who] = f end
  if now - f.at > C.FLOOD_WINDOW then f.at, f.n = now, 0 end
  f.n = f.n + 1
  return f.n <= C.FLOOD_MAX
end

---------------------------------------------------------------------------
-- Client glue (WoW calls only below)
---------------------------------------------------------------------------
local Call, IsSecret, Str = Util.Call, Util.IsSecret, Util.Str

local gdb                -- DeathNoteDB.guild = { name, lists = { [guild] = { enemies, members, lastOnline, used } } }
local list               -- gdb.lists[gdb.name]: the list of the bound guild, or nil
local store = { enemies = {}, count = 0, bySender = {}, listedBySender = {} }
local listCache = {}     -- sort (.. variant) -> array
local rankCache
local memberCache        -- ByMember() result, nil when dirty
local membersVersion = 0 -- bumped when a member is heard (lastHeard in the cached view)
local flood = {}
local queue, queued = {}, {}   -- outgoing messages; queued[text] = true
local pumping, holdTimer, holdRounds = false, false, 0
local lastHello, helloPlanned = nil, false
local reply                    -- { since } pending answer to a hello
local lastReplyAt
local helloFrom, announced = {}, {}   -- per sender: last answered hello, GUILD_KILL window
local sanitized = {}           -- lists checked in this session
local updatePending = false
local seenWrite, sightSent, spotFrame = {}, {}, {}
local prefixOK = nil
local backfilled = false     -- own kills merged into the guild list in this session
Guild.stats = { sent = 0, received = 0, dropped = 0, lastResult = nil, lastReason = nil, lastSender = nil,
  -- 1.1.0: listed by hand (M) and taken off (X)
  listSent = 0, listReceived = 0, listDropped = 0, unlistSent = 0, unlistReceived = 0, unlistDropped = 0,
  byMemberBuilds = 0 }
local stats = Guild.stats

local function now() return time() end

local DEFAULTS = { share = true, receive = true, alert = true, announce = true, sightings = false, minKills = 1,
  shareManual = true, alertListed = false }
-- settings.guild.<name> without Store.Setting's path parsing (read on every message)
local function setting(name)
  local db = ns.Store and ns.Store.DB()
  local g = db and type(db.settings) == "table" and db.settings.guild
  local v
  if type(g) == "table" then v = g[name] end
  if v == nil then return DEFAULTS[name] end
  return v
end
Guild.Setting = setting

local function invalidate()
  for k in pairs(listCache) do listCache[k] = nil end
  rankCache = nil
  memberCache = nil
end

local function updated()
  invalidate()
  if updatePending then return end
  updatePending = true
  local After = _G.C_Timer and _G.C_Timer.After
  if After then
    After(C.UPDATE_THROTTLE, function()
      updatePending = false
      ns:Fire("GUILD_UPDATED")
    end)
  else
    updatePending = false
    ns:Fire("GUILD_UPDATED")
  end
end

-- pcall without the table of Util.Call (hot path: one call per addon message)
local function call1(fn, a, b)
  if type(fn) ~= "function" then return nil end
  local ok, v = pcall(fn, a, b)
  if ok then return v end
  return nil
end

local me, meFull
local function myName()
  if me then return me end
  local n = Str(call1(_G.UnitName, "player"))
  if n then me = n end
  return n
end

-- "Name Surname" of the current character, as Attribution writes it into death.me.
local function myFullName()
  if meFull then return meFull end
  local n, sn = Call(_G.UnitName, "player")
  n, sn = Str(n), Str(sn)
  if n then meFull = sn and (n .. " " .. sn) or n end
  return meFull
end

local function firstWord(s)
  return type(s) == "string" and s:match("^([^%s%-]+)") or nil
end

-- Short name of a sender ("Name-Realm" -> "Name"), nil when unusable.
local function senderName(sender)
  if IsSecret(sender) or type(sender) ~= "string" or sender == "" or #sender > 80 then return nil end
  local full = sender
  if _G.Ambiguate then
    local a = call1(_G.Ambiguate, sender, "none")
    if not IsSecret(a) and type(a) == "string" and a ~= "" then full = a end
  end
  local short = full:match("^([^%-]+)") or full
  if short:find("[%c|]") then return nil end
  return short, full
end
Guild.SenderName = senderName

local function inGuild()
  return Util.True(call1(_G.IsInGuild))
end

local function guildNameNow()
  return Str(call1(_G.GetGuildInfo, "player"))
end

function Guild.Name()
  if not inGuild() then return nil end
  return guildNameNow() or (gdb and gdb.name) or nil
end

-- Additive: names of the guilds whose lists are kept (this account's characters).
function Guild.Lists()
  local out = {}
  if gdb then for name in pairs(gdb.lists) do out[#out + 1] = name end end
  table.sort(out)
  return out
end

function Guild.Enabled()
  return inGuild() and setting("share") == true
end

---------------------------------------------------------------------------
-- Guild binding
---------------------------------------------------------------------------
local function ownKills(since, limit)
  -- own sure kills from the personal list (never imported data), newest first.
  -- Only deeds with role "kill" (1.1.0): assists and suspicions never leave the book.
  local Store = ns.Store
  local out = {}
  if not Store then return out end
  local t0 = now()
  -- only deaths of the character that is logged in: its guild is the one listening
  local mine = myFullName()
  if not mine then return out end
  for key, e in pairs(Store.All()) do
    for i = 1, #(e.deaths or {}) do
      local d = e.deaths[i]
      if d.role == "kill" and d.sure == true and not d.imported and type(d.t) == "number" and d.t > since and d.t >= t0 - C.MAX_AGE
        and d.t <= t0 + C.FUTURE and d.me == mine then
        out[#out + 1] = { key = key, display = Util.Display(e), class = e.class,
          level = type(d.theirLevel) == "number" and d.theirLevel or (type(e.level) == "number" and e.level or nil),
          zone = d.zone, t = d.t, victim = d.me }
      end
    end
  end
  table.sort(out, function(a, b) return a.t > b.t end)
  if limit then while #out > limit do table.remove(out) end end
  return out
end
Guild.OwnKills = ownKills

local function addOwn(k)
  local key = k.key
  local n, s = P.ValidKey(key)
  if not n then return nil end
  local m = { key = key, name = n, surname = s, display = k.display, class = k.class, level = k.level,
    zone = k.zone, t = k.t, victim = k.victim }
  return P.Merge(store, m, myName() or "?")
end

-- Personal entry that may go to the guild as "listed by hand": manual, wanted, not taken
-- over from the guild, not imported, plain names. Old entries without `by` are claimed
-- by the character that sends them first (claim = true).
local function listable(key, e)
  if type(e) ~= "table" or e.manual ~= true or e.status ~= "wanted" or e.fromGuild or e.imported then return false end
  if not P.ValidKey(key) or plain(key) ~= key then return false end
  if type(e.name) ~= "string" or e.name:find("[%c|]") then return false end
  if e.surname ~= nil and (type(e.surname) ~= "string" or e.surname:find("[%c|]")) then return false end
  local deaths = e.deaths
  for i = 1, #(deaths or {}) do
    if deaths[i].imported then return false end   -- older import without the entry mark
  end
  return true
end
Guild.Listable = listable

local function listedMsg(key, e)
  return { key = key, display = Util.Display(e), class = e.class,
    level = type(e.level) == "number" and e.level or nil, t = e.listedAt, by = e.by }
end

-- Own listable entries of the logged-in char, newest listing first (claims unowned ones).
local function ownListed(limit, claim)
  local Store = ns.Store
  local out = {}
  local mine = myFullName()
  if not Store or not mine then return out end
  local t0 = now()
  for key, e in pairs(Store.All()) do
    if listable(key, e) then
      if e.by == nil and claim then e.by = mine end
      if e.by == mine then
        if type(e.listedAt) ~= "number" or e.listedAt > t0 + C.FUTURE then e.listedAt = t0 end
        if e.listedAt >= t0 - C.LISTED_MAX_AGE then out[#out + 1] = listedMsg(key, e) end
      end
    end
  end
  table.sort(out, function(a, b) if a.t ~= b.t then return a.t > b.t end return a.key < b.key end)
  if limit then while #out > limit do table.remove(out) end end
  return out
end
Guild.OwnListed = ownListed

local function addOwnListed(l)
  local n, s = P.ValidKey(l.key)
  if not n then return nil end
  local m = { key = l.key, name = n, surname = s, display = l.display, class = l.class, level = l.level,
    t = l.t, by = l.by }
  return P.MergeListed(store, m, myName() or "?")
end

local function backfill()
  local added = 0
  for _, k in ipairs(ownKills(0)) do
    if addOwn(k) == "new" then added = added + 1 end
  end
  if setting("shareManual") == true then
    -- no claim here: an old entry without `by` belongs to the char that sends it first
    for _, l in ipairs(ownListed(nil, false)) do
      local res = addOwnListed(l)
      if res == "new" or res == "add" or res == "upd" then added = added + 1 end
    end
  end
  return added
end

-- Makes `name`'s list the active one (created when new; at most MAX_LISTS are kept,
-- the one unused longest leaves). Runtime aliases gdb.enemies/members point at it.
local function useList(name)
  local L = gdb.lists[name]
  if not L then
    L = { enemies = {}, members = {} }
    gdb.lists[name] = L
    local n = 0
    for _ in pairs(gdb.lists) do n = n + 1 end
    while n > C.MAX_LISTS do
      local oldName, oldT
      for gname, x in pairs(gdb.lists) do
        if gname ~= name and (not oldT or (x.used or 0) < oldT) then oldName, oldT = gname, x.used or 0 end
      end
      gdb.lists[oldName] = nil
      n = n - 1
    end
  end
  L.used = now()
  list = L
  gdb.name = name
  gdb.enemies, gdb.members = L.enemies, L.members
  store.enemies = L.enemies
  if not sanitized[L] then
    sanitized[L] = true
    P.Sanitize(store, now())
  else
    P.Recount(store)
  end
  return L
end

-- Binds the list to the current guild; each guild of the account keeps its own list.
local function bind()
  if not gdb or not inGuild() then return false end
  local name = guildNameNow()
  if not name then return false end
  local changed = false
  if gdb.name ~= name or not list then
    changed = true
    local had = gdb.name ~= nil and gdb.name ~= name
    useList(name)
    seenWrite, sightSent = {}, {}
    if had then stats.lastReason = "guild changed" end
  end
  -- own kills (also those confirmed or assigned later by hand) join the list once per
  -- login and after a guild change; duplicates are skipped by the deed id
  if changed or not backfilled then
    backfilled = true
    if backfill() > 0 then changed = true end
  end
  if changed then updated() end
  return true
end
Guild.Bind = bind

local function setHook()
  if ns.Tracker then
    ns.Tracker.guildHook = (store.count > 0) and Guild.OnUnit or nil
  end
end

---------------------------------------------------------------------------
-- Sending
---------------------------------------------------------------------------
local function enum(name, fallback)
  local E = _G.Enum and _G.Enum.SendAddonMessageResult
  local v = E and E[name]
  if type(v) == "number" then return v end
  return fallback
end

-- "ok" | "throttle" | "retry" | "drop" for the results of pcall(SendAddonMessage, ...).
-- Old clients return nothing or a boolean, newer ones Enum.SendAddonMessageResult.
function P.SendOutcome(ok, res, success, throttle1, throttle2, general, lockdown)
  if not ok then return "retry" end
  if res == nil or res == true then return "ok" end
  if res == false then return "retry" end
  if type(res) == "number" then
    if res == success then return "ok" end
    if res == throttle1 or res == throttle2 then return "throttle" end
    if lockdown ~= nil and res == lockdown then return "retry" end
    if res == general then return "retry" end
    return "drop"   -- invalid prefix/message/channel, not in guild: retrying will not help
  end
  return "ok"
end

-- Why sending must wait right now, or nil.
local function holdReason()
  local inInst = call1(_G.IsInInstance)
  if Util.True(inInst) then return "instance" end
  local combat = call1(_G.InCombatLockdown)
  if Util.True(combat) then return "combat" end
  local CI = _G.C_ChatInfo
  if CI then
    local l = call1(CI.InChatMessagingLockdown)
    if Util.True(l) then return "lockdown" end
    -- AreOutgoingAddonChatMessagesRestricted() is true for the whole realm on Forever PvP realms
    -- (seen live 11.11.2026). It must not hold the queue: other addons send to GUILD regardless,
    -- and the send result tells us what really happened. Only remembered for /dn probe.
    local r = call1(CI.AreOutgoingAddonChatMessagesRestricted)
    stats.realmRestricted = Util.True(r) or nil
  end
  return nil
end
Guild.HoldReason = holdReason

local pump
local function scheduleHold()
  if holdTimer then return end
  holdRounds = holdRounds + 1
  if holdRounds > C.HOLD_MAX then
    -- never endless: give up on what is waiting
    stats.dropped = stats.dropped + #queue
    queue, queued, holdRounds = {}, {}, 0
    return
  end
  local After = _G.C_Timer and _G.C_Timer.After
  if not After then return end
  holdTimer = true
  After(C.HOLD_RETRY, function() holdTimer = false; pump() end)
end

function pump()
  if pumping then return end
  local CI = _G.C_ChatInfo
  if #queue == 0 then holdRounds = 0; return end
  if not (CI and CI.SendAddonMessage) or not Guild.Enabled() then
    stats.dropped = stats.dropped + #queue
    queue, queued = {}, {}
    return
  end
  local t = now()
  while queue[1] and t - queue[1].at > C.QUEUE_TTL do
    queued[queue[1].text] = nil
    table.remove(queue, 1)
    stats.dropped = stats.dropped + 1
  end
  local m = queue[1]
  if not m then return end
  local why = holdReason()
  if why then stats.lastReason = why; scheduleHold(); return end
  local ok, res = pcall(CI.SendAddonMessage, PREFIX, m.text, "GUILD")
  if IsSecret(res) then res = nil end
  stats.lastResult = ok and (res == nil and "nil" or tostring(res)) or "error"
  local outcome = P.SendOutcome(ok, res, enum("Success", 0), enum("AddonMessageThrottle", 3),
    enum("ChannelThrottle", 8), enum("GeneralError", 9), enum("AddOnMessageLockdown", 11))
  if outcome == "ok" then
    stats.failStreak, stats.hardFail = 0, nil
    m.throttled = nil
  elseif outcome == "throttle" then
    m.throttled = (m.throttled or 0) + 1
  else
    stats.failStreak = (stats.failStreak or 0) + 1
    stats.lastFail = stats.lastResult
    if outcome == "drop" then stats.hardFail = stats.lastResult end   -- a definite refusal, not a hiccup
  end
  if outcome == "ok" then
    stats.sent = stats.sent + 1
    if m.kind == "M" then stats.listSent = stats.listSent + 1
    elseif m.kind == "X" then stats.unlistSent = stats.unlistSent + 1 end
  elseif outcome ~= "throttle" then   -- throttled messages wait (bounded by QUEUE_TTL)
    m.tries = m.tries + 1
  end
  if outcome == "ok" or outcome == "drop" or m.tries >= C.TRIES then
    if outcome ~= "ok" then stats.dropped = stats.dropped + 1 end
    table.remove(queue, 1)
    queued[m.text] = nil
  end
  if #queue > 0 then
    local After = _G.C_Timer and _G.C_Timer.After
    if After then
      pumping = true
      local gap = outcome == "ok" and C.SEND_GAP or C.BACKOFF
      -- a throttled message waits longer each time (1.5, 3, 6 ... 30 s) instead of knocking every 1.5 s
      if outcome == "throttle" and queue[1] == m then
        gap = math.min(30, C.BACKOFF * 2 ^ math.min((m.throttled or 1) - 1, 6))
      end
      After(gap, function() pumping = false; pump() end)
    end
  else
    holdRounds = 0
  end
end
Guild.Pump = pump

local function enqueue(text, kind)
  if not text or queued[text] then return false end
  if #queue >= C.QUEUE_MAX then stats.dropped = stats.dropped + 1; return false end
  queue[#queue + 1] = { text = text, at = now(), tries = 0, kind = kind }
  queued[text] = true
  pump()
  return true
end

function Guild.QueueSize() return #queue end

local function canSend()
  return Guild.Enabled() and _G.C_ChatInfo and _G.C_ChatInfo.SendAddonMessage and true or false
end

-- "send me your kills newer than this": last logout minus an overlap, but always at least
-- LOOKBACK seconds back (kills of members who were offline at my last login), never older than MAX_AGE.
function P.Since(t, lastOnline, empty)
  local floor = t - C.MAX_AGE
  if empty or not lastOnline then return floor end
  return math.max(floor, math.min(lastOnline - C.SINCE_OVERLAP, t - C.LOOKBACK))
end

local function since()
  return P.Since(now(), list and list.lastOnline, store.count == 0)
end
Guild.Since = since

local function addonVersion()
  local md = (_G.C_AddOns and _G.C_AddOns.GetAddOnMetadata) or _G.GetAddOnMetadata
  local v = md and Call(md, ADDON, "Version")
  return Str(v) or "0"
end

local function sendHello()
  if not canSend() or setting("receive") ~= true then return false end
  lastHello = GetTime()
  return enqueue(P.EncodeHello(since(), addonVersion()))
end

function Guild.SyncNow()
  if not canSend() then return false, "aus" end
  bind()
  local t = GetTime()
  if lastHello and t - lastHello < C.SYNC_COOLDOWN then
    return false, math.ceil(C.SYNC_COOLDOWN - (t - lastHello))
  end
  return sendHello() and true or false, "gesendet"
end

local function sendReply()
  local r = reply
  reply = nil
  if not r or not canSend() then return end
  lastReplyAt = GetTime()
  local list = ownKills(r.since, C.REPLY_MAX)
  for i = 1, #list do enqueue(P.EncodeKill(list[i], "R")) end
  if setting("shareManual") ~= true then return end
  -- names listed by hand (all of them, not only newer than since: there are few)
  local listed = ownListed(C.LISTED_REPLY, true)
  local changed = false
  for i = 1, #listed do
    enqueue(P.EncodeListed(listed[i]), "M")
    local res = addOwnListed(listed[i])       -- maybe claimed just now: into the own guild list too
    if res == "new" or res == "add" or res == "upd" then changed = true end
  end
  if changed then setHook(); updated() end
  -- removals a member may have missed while offline
  local tombs = gdb and gdb.unlisted
  local mine = myFullName()
  if tombs and mine then
    local keys = {}
    for key, x in pairs(tombs) do if x.by == mine then keys[#keys + 1] = key end end
    table.sort(keys, function(a, b) return tombs[a].t > tombs[b].t end)
    for i = 1, math.min(#keys, C.UNLISTED_REPLY) do enqueue(P.EncodeUnlisted(keys[i], mine), "X") end
  end
end

---------------------------------------------------------------------------
-- Receiving
---------------------------------------------------------------------------
local scratch = {}

local function noteMember(short, full, version)
  if not list then return end
  local members = list.members
  local m = members[full]
  if not m then
    local n = 0
    for _ in pairs(members) do n = n + 1 end
    if n >= C.MAX_MEMBERS then return end
    m = { name = short }
    members[full] = m
  end
  m.lastHeard = now()
  membersVersion = membersVersion + 1
  if version then m.version = version end
end

-- Own echo. The sender may arrive as "Name", "Name-Realm", "Name-Surname" or with the surname
-- after a space ("Name Surname[-Realm]"): the first word must be mine, and a second word, if
-- there is one, must be my surname.
local function isMe(short)
  local me = myName()
  if me == nil or type(short) ~= "string" then return false end
  if short == me then return true end
  local first, rest = short:match("^(%S+)%s+(.+)$")
  if first ~= me then return false end
  local full = myFullName()
  return full == nil or full == me or short == full
end
Guild.IsMe = isMe

-- true while `who` may still fire GUILD_KILL in this minute
local function mayAnnounce(who, t)
  local a = announced[who]
  if not a or t - a.at > 60 then a = { at = t, n = 0 }; announced[who] = a end
  a.n = a.n + 1
  return a.n <= C.ANNOUNCE_MAX
end

function Guild.OnAddonMessage(_, prefix, text, channel, sender)
  if IsSecret(prefix) or prefix ~= PREFIX then return end
  if IsSecret(channel) or IsSecret(text) or channel ~= "GUILD" or type(text) ~= "string" then return end
  local short, full = senderName(sender)
  if not short or isMe(short) or not gdb then return end   -- own echo
  local t = now()
  if not P.Flood(flood, full, t) then stats.dropped = stats.dropped + 1; return end
  local m, why = P.Decode(text, t, scratch)
  if not m then
    stats.dropped = stats.dropped + 1; stats.lastReason = why
    local k = text:match("^1\t([MX])\t")
    if k == "M" then stats.listDropped = stats.listDropped + 1
    elseif k == "X" then stats.unlistDropped = stats.unlistDropped + 1 end
    return
  end
  stats.received = stats.received + 1
  stats.lastSender = full
  if not inGuild() then return end
  if not list then bind() end
  noteMember(short, full, m.version)
  local kind = m.kind
  if kind == "H" then
    if setting("share") ~= true then return end
    local gt = GetTime()
    -- the same member is answered at most every few minutes; members logging in one after
    -- another all get an answer (they did not hear the earlier ones)
    local last = helloFrom[full]
    if last and gt - last < C.HELLO_PER_SENDER then return end
    helloFrom[full] = gt
    if reply then
      if m.since < reply.since then reply.since = m.since end
      return
    end
    reply = { since = m.since }
    local After = _G.C_Timer and _G.C_Timer.After
    local delay = C.REPLY_MIN + math.random() * (C.REPLY_MAX_DELAY - C.REPLY_MIN)
    if lastReplyAt and lastReplyAt + C.REPLY_GAP - gt > delay then delay = lastReplyAt + C.REPLY_GAP - gt end
    if After then After(delay, sendReply) else sendReply() end
    return
  end
  -- data only into a list bound to a known guild name (else a later bind would mix guilds)
  if setting("receive") ~= true or not list then return end
  if kind == "K" or kind == "R" then
    -- everyone sends only own deaths: the victim must be the sender
    local vf, sf = firstWord(m.victim), firstWord(short)
    if not vf or not sf or vf:lower() ~= sf:lower() then
      stats.dropped = stats.dropped + 1; stats.lastReason = "victim"
      return
    end
    local res, e, deed = P.Merge(store, m, short, { maxPerSender = C.MAX_PER_SENDER, protect = myName() })
    if res ~= "new" then
      if res == "cap" then stats.dropped = stats.dropped + 1; stats.lastReason = "cap" end
      return
    end
    setHook()
    updated()
    if kind == "K" and t - m.t <= C.FRESH and setting("announce") == true and mayAnnounce(full, t) then
      ns:Fire("GUILD_KILL", deed, e.key)
    end
  elseif kind == "M" or kind == "X" then
    local isM = kind == "M"
    if isM then stats.listReceived = stats.listReceived + 1 else stats.unlistReceived = stats.unlistReceived + 1 end
    -- everyone sends only own listings: the char must be the sender
    local cf, sf = firstWord(m.by), firstWord(short)
    if not cf or not sf or cf:lower() ~= sf:lower() then
      stats.dropped = stats.dropped + 1; stats.lastReason = "by"
      if isM then stats.listDropped = stats.listDropped + 1 else stats.unlistDropped = stats.unlistDropped + 1 end
      return
    end
    local res
    if isM then
      res = P.MergeListed(store, m, short,
        { maxPerSender = C.MAX_PER_SENDER, maxListed = C.LISTED_MAX, protect = myName() })
      if res == "cap" then
        stats.dropped = stats.dropped + 1; stats.listDropped = stats.listDropped + 1; stats.lastReason = "cap"
      end
      if res ~= "new" and res ~= "add" and res ~= "upd" then return end
    else
      res = P.Unlist(store, m.key, m.by)
      if not res then return end
    end
    setHook()
    updated()
  elseif kind == "S" then
    if setting("sightings") ~= true then return end
    local e = store.enemies[m.key]
    if not e then return end
    if e.lastSeen and (e.lastSeen.t or 0) >= m.t then return end
    e.lastSeen = { t = m.t, zone = m.zone, by = short }
    updated()
    ns:Fire("GUILD_SIGHTING", m.key, m.zone, short)
  end
end

---------------------------------------------------------------------------
-- Own deaths and sightings
---------------------------------------------------------------------------
function Guild.OnDeath(journal, key)
  if type(journal) ~= "table" or not key or journal.sure ~= true or journal.counted == false then return end
  if journal.kind ~= "pvp" or not gdb then return end
  local Store = ns.Store
  local e = Store and Store.Get(key)
  if not e or type(journal.t) ~= "number" or type(journal.me) ~= "string" then return end
  local lvl
  for i = 1, #e.deaths do
    if e.deaths[i].t == journal.t then lvl = e.deaths[i].theirLevel; break end
  end
  local k = { key = key, display = Util.Display(e), class = e.class, level = lvl or e.level,
    zone = journal.zone, t = journal.t, victim = journal.me }
  if inGuild() then
    bind()
    if addOwn(k) == "new" then setHook(); updated() end
    if canSend() then enqueue(P.EncodeKill(k, "K")) end
  end
end

-- Tracker hook (set only while the guild list has entries): a hostile player is in sight.
function Guild.OnUnit(key, unit, how, listed)
  local e = store.enemies[key]
  if not e then return end
  local gt = GetTime()
  if not seenWrite[key] or gt - seenWrite[key] >= C.SEEN_WRITE then
    seenWrite[key] = gt
    local zone = Util.Zone()
    e.lastSeen = { t = now(), zone = zone, by = myName() }
    updated()
    if setting("sightings") == true and canSend() and (not sightSent[key] or gt - sightSent[key] >= C.SIGHT_SEND) then
      sightSent[key] = gt
      enqueue(P.EncodeSight(key, zone, now()))
    end
  end
  if listed or setting("alert") ~= true then return end
  if (e.kills or 0) == 0 then
    -- listed by hand only: an alarm only when switched on, no kill threshold
    if setting("alertListed") ~= true then return end
  elseif (e.kills or 0) < (tonumber(setting("minKills")) or 1) then
    return
  end
  if spotFrame[key] == gt then return end
  spotFrame[key] = gt
  ns:Fire("GUILD_ENEMY_SPOTTED", key, unit, how)
end

-- Own entry `key` now listed by hand (added, pardon lifted, rekeyed): into the own guild
-- list and, when sharing is on, an M to the guild at once.
function Guild.OnListed(key)
  local Store = ns.Store
  if not gdb or not Store or setting("shareManual") ~= true then return end
  local e = Store.Get(key)
  if not listable(key, e) then return end
  local mine = myFullName()
  if not mine or not inGuild() then return end
  if e.by == nil then e.by = mine end
  if e.by ~= mine then return end
  if type(e.listedAt) ~= "number" then e.listedAt = now() end
  if gdb.unlisted then gdb.unlisted[key] = nil end
  bind()
  local l = listedMsg(key, e)
  local res = addOwnListed(l)
  if res == "new" or res == "add" or res == "upd" then setHook(); updated() end
  if canSend() then enqueue(P.EncodeListed(l), "M") end
end

-- Own entry `key` (table e, maybe already removed) is no longer listed: out of the own guild
-- list, remembered for later answers and, when sharing is on, an X to the guild at once.
function Guild.OnUnlisted(key, e)
  if not gdb or type(e) ~= "table" or e.manual ~= true or e.fromGuild or e.imported then return end
  local by = e.by
  if type(by) ~= "string" then return end     -- never sent: nothing to take back
  if store.enemies[key] and P.Unlist(store, key, by) then setHook(); updated() end
  local tombs = gdb.unlisted
  if type(tombs) ~= "table" then tombs = {}; gdb.unlisted = tombs end
  tombs[key] = { t = now(), by = by }
  local n, oldKey, oldT = 0, nil, nil
  for k, x in pairs(tombs) do
    n = n + 1
    if not oldT or x.t < oldT then oldKey, oldT = k, x.t end
  end
  if n > C.TOMB_MAX then tombs[oldKey] = nil end
  if setting("shareManual") == true and by == myFullName() and inGuild() and canSend() then
    enqueue(P.EncodeUnlisted(key, by), "X")
  end
end

---------------------------------------------------------------------------
-- Public reading API
---------------------------------------------------------------------------
local function markMine(list)
  local Store = ns.Store
  for i = 1, #list do
    local e = list[i]
    e.mine = (Store and Store.Get(e.key)) and true or false
  end
end

-- true when a character other than `mine` is part of the entry: as victim of a deed or in
-- listedBy (1.1.0). Without a known own name every entry counts as foreign.
function P.Foreign(e, mine)
  local deeds = e.deeds
  for i = 1, #deeds do
    if deeds[i].victim ~= mine then return true end
  end
  if e.listedBy then
    for char in pairs(e.listedBy) do
      if char ~= mine then return true end
    end
  end
  return false
end

-- opts (additive): { only = "kills" } entries with kills, { only = "listed" } entries listed
-- by hand only; { foreign = true } (1.1.0) only entries in which another character than the
-- logged-in one takes part (see P.Foreign). Without opts: all entries, those listed by hand
-- only at the end of "rank".
function Guild.List(sort, opts)
  sort = P.SORTS[sort] and sort or "rank"
  local only = type(opts) == "table" and (opts.only == "kills" or opts.only == "listed") and opts.only or nil
  local foreign = type(opts) == "table" and opts.foreign == true
  local ck = only and (sort .. "/" .. only) or sort
  if foreign then ck = ck .. "/f" end
  local list = listCache[ck]
  if not list then
    list = P.Sorted(store.enemies, sort, only)
    if foreign then
      local mine = myFullName()
      local out = {}
      for i = 1, #list do if P.Foreign(list[i], mine) then out[#out + 1] = list[i] end end
      list = out
    end
    markMine(list)
    listCache[ck] = list
  end
  return list
end

function Guild.Get(key)
  if type(key) ~= "string" then return nil end
  local e = store.enemies[key]
  if e then e.mine = (ns.Store and ns.Store.Get(key)) and true or false end
  return e
end

function Guild.Rank(key)
  if type(key) ~= "string" or not store.enemies[key] then return nil end
  if not rankCache then
    rankCache = {}
    local list = Guild.List("rank")
    for i = 1, #list do rankCache[list[i].key] = i end
  end
  return rankCache[key]
end

-- enemies, deeds, entries listed by hand only (no kills), foreign entries (1.1.0: another
-- character than the logged-in one takes part, as victim or in listedBy; see P.Foreign)
function Guild.Count()
  local deeds, listed, foreign = 0, 0, 0
  local mine = myFullName()
  for _, e in pairs(store.enemies) do
    deeds = deeds + #e.deeds
    if #e.deeds == 0 then listed = listed + 1 end
    if P.Foreign(e, mine) then foreign = foreign + 1 end
  end
  return store.count, deeds, listed, foreign
end

local function rowLess(a, b)
  if a.kills ~= b.kills then return a.kills > b.kills end
  if (a.lastKill or 0) ~= (b.lastKill or 0) then return (a.lastKill or 0) > (b.lastKill or 0) end
  if (a.listedAt or 0) ~= (b.listedAt or 0) then return (a.listedAt or 0) > (b.listedAt or 0) end
  return a.key < b.key
end

local function memberLess(a, b)
  if a.me ~= b.me then return a.me end
  if a.deaths ~= b.deaths then return a.deaths > b.deaths end
  return a.name < b.name
end

-- lastHeard/hasAddon of every section from the members table (cheap, no rebuild)
local function fillHeard(out)
  local heard = {}
  if list then
    for _, m in pairs(list.members) do
      local k = memberKey(m.name)
      if k and (not heard[k] or m.lastHeard > heard[k]) then heard[k] = m.lastHeard end
    end
  end
  for i = 1, #out do
    local g = out[i]
    g.lastHeard = heard[memberKey(g.name) or ""]
    g.hasAddon = g.me or g.lastHeard ~= nil
  end
end

-- Guild list grouped by the member who died / listed (1.1.0). Cached; rebuilt only after
-- a change of the guild list. Sections and rows must not be changed by the caller.
function Guild.ByMember()
  if memberCache then
    if memberCache.mv ~= membersVersion then
      fillHeard(memberCache.list)
      memberCache.mv = membersVersion
    end
    return memberCache.list
  end
  stats.byMemberBuilds = stats.byMemberBuilds + 1
  local groups, out = {}, {}
  local rowOf = {}          -- member char -> row of the entry being walked (cleared per entry)
  local function group(char)
    local g = groups[char]
    if not g then
      g = { name = char, deaths = 0, killers = 0, listed = 0, lastDeath = nil, rows = {}, me = false }
      groups[char] = g
      out[#out + 1] = g
    end
    return g
  end
  local mine = myFullName()
  if mine then group(mine).me = true end
  for key, e in pairs(store.enemies) do
    local deeds = e.deeds
    for i = 1, #deeds do                 -- newest first: the first deed per member is his last
      local d = deeds[i]
      local v = d.victim
      if v then
        local g = group(v)
        local r = rowOf[v]
        if not r then
          r = { key = key, entry = e, kills = 0, lastKill = d.t, lastZone = d.zone, listed = false }
          rowOf[v] = r
          g.rows[#g.rows + 1] = r
          g.killers = g.killers + 1
        end
        r.kills = r.kills + 1
        g.deaths = g.deaths + 1
        if not g.lastDeath or d.t > g.lastDeath then g.lastDeath = d.t end
      end
    end
    if e.listedBy then
      for char, t in pairs(e.listedBy) do
        local g = group(char)
        local r = rowOf[char]
        if not r then
          r = { key = key, entry = e, kills = 0, listed = false }
          rowOf[char] = r
          g.rows[#g.rows + 1] = r
        end
        r.listed, r.listedAt = true, t
        g.listed = g.listed + 1
      end
    end
    for k in pairs(rowOf) do rowOf[k] = nil end
  end
  for i = 1, #out do table.sort(out[i].rows, rowLess) end
  table.sort(out, memberLess)
  fillHeard(out)
  local Store = ns.Store
  for _, e in pairs(store.enemies) do e.mine = (Store and Store.Get(e.key)) and true or false end
  memberCache = { list = out, mv = membersVersion }
  return out
end

function Guild.Members()
  local out = {}
  if not list then return out end
  for full, m in pairs(list.members) do
    out[#out + 1] = { name = m.name, full = full, version = m.version, lastHeard = m.lastHeard }
  end
  table.sort(out, function(a, b) return (a.lastHeard or 0) > (b.lastHeard or 0) end)
  return out
end

function Guild.Clear()
  if not gdb then return end
  local fresh = {}
  if list then list.enemies = fresh end
  gdb.enemies = fresh
  store.enemies, store.count, store.bySender, store.listedBySender = fresh, 0, {}, {}
  seenWrite, sightSent = {}, {}
  setHook()
  updated()
end

-- Takes a guild enemy over into the personal list as a manual entry. Returns the key.
function Guild.Adopt(key)
  local e = store.enemies[key]
  local Store = ns.Store
  if not e or not Store then return nil end
  -- a display without surname means the second key part is only a realm fallback
  -- fromGuild: never sent back to the guild as "listed by hand" (no echo loop)
  local k = Store.AddManual(e.name, e.display ~= e.name and e.surname or nil, { fromGuild = true })
  if not k then return nil end
  Store.Upsert({ name = e.name, surname = e.display ~= e.name and e.surname or nil, class = e.class,
    level = e.level }, false)
  local own = Store.Get(k)
  if own and own.note == "" then
    Store.SetNote(k, ("Aus dem Gildenbuch übernommen (%d× getötet in der Gilde)."):format(e.kills or 0))
  end
  invalidate()
  return k
end

---------------------------------------------------------------------------
-- Startup and events
---------------------------------------------------------------------------
-- Repairs one stored guild list; false when it is beyond repair.
local function sanitizeList(L, t)
  if type(L) ~= "table" then return false end
  if type(L.enemies) ~= "table" then L.enemies = {} end
  if type(L.members) ~= "table" then L.members = {} end
  if L.lastOnline ~= nil and type(L.lastOnline) ~= "number" then L.lastOnline = nil end
  if L.used ~= nil and type(L.used) ~= "number" then L.used = nil end
  for full, m in pairs(L.members) do
    -- broken entries out, members not heard of for 60 days out (the list is capped)
    if type(full) ~= "string" or type(m) ~= "table" or type(m.name) ~= "string"
      or type(m.lastHeard) ~= "number" or m.lastHeard < t - C.MEMBER_MAX_AGE then
      L.members[full] = nil
    end
  end
  return true
end

function Guild.Init()
  local db = ns.Store and ns.Store.DB()
  if not db then return end
  if type(db.guild) ~= "table" then db.guild = {} end
  gdb = db.guild
  if gdb.name ~= nil and type(gdb.name) ~= "string" then gdb.name = nil end
  local t = now()
  if type(gdb.lists) ~= "table" then
    -- first DB form: one list next to the guild name
    gdb.lists = {}
    if gdb.name and type(gdb.enemies) == "table" then
      gdb.lists[gdb.name] = { enemies = gdb.enemies, members = gdb.members, lastOnline = gdb.lastOnline, used = t }
    end
  end
  -- runtime aliases (and the old fields) are rebuilt from the lists
  gdb.enemies, gdb.members, gdb.lastOnline = nil, nil, nil
  for name, L in pairs(gdb.lists) do
    if type(name) ~= "string" or not sanitizeList(L, t) then gdb.lists[name] = nil end
  end
  -- removals of own listings, resent in answers: { [key] = { t, by } }
  if type(gdb.unlisted) ~= "table" then gdb.unlisted = {} end
  local tn = 0
  for key, x in pairs(gdb.unlisted) do
    if type(key) ~= "string" or type(x) ~= "table" or type(x.t) ~= "number" or type(x.by) ~= "string"
      or x.t < t - C.TOMB_AGE then
      gdb.unlisted[key] = nil
    else
      tn = tn + 1
    end
  end
  if tn > C.TOMB_MAX then gdb.unlisted = {} end
  list, sanitized = nil, {}
  store.enemies, store.count, store.bySender, store.listedBySender = {}, 0, {}, {}
  if gdb.name and gdb.lists[gdb.name] then useList(gdb.name) end
  flood, queue, queued, reply, backfilled = {}, {}, {}, nil, false
  seenWrite, sightSent, spotFrame = {}, {}, {}
  helloFrom, announced, lastReplyAt, meFull = {}, {}, nil, nil
  invalidate()
  local CI = _G.C_ChatInfo
  if CI and CI.RegisterAddonMessagePrefix then
    local ok, res = pcall(CI.RegisterAddonMessagePrefix, PREFIX)
    if IsSecret(res) then res = nil end
    -- old clients: nothing/boolean; newer: a result enum (0 = success, 1 = already registered)
    prefixOK = ok and (res == nil or res == true or res == 0 or res == 1)
    stats.prefixResult = ok and tostring(res) or "error"
  else
    prefixOK = false
    stats.prefixResult = "fehlt"
  end
  bind()
  setHook()
end

function Guild.DB() return gdb end
function Guild.PrefixOK() return prefixOK end

-- Additive: is sharing actually working?
-- -> { ok = bool, reason = key, text = short German sentence for players (<= 60 chars, no
--      technical words), short = button label (<= 24 chars), detail = technical note or nil }
-- reason: "noguild" | "off" | "prefix" | "blocked" | "failing" | "hold" | "quiet" | "ok"
local HOLD_TEXT = { instance = "bis du die Instanz verlässt", combat = "bis du aus dem Kampf bist",
  lockdown = "bis der Chat wieder frei ist" }
local HOLD_SHORT = { instance = "Wartet: Instanz", combat = "Wartet: im Kampf", lockdown = "Wartet: Chat zu" }
function Guild.Health()
  local h = {}
  if not inGuild() then
    h.ok, h.reason, h.short = false, "noguild", "Keine Gilde"
    h.text = "Du bist in keiner Gilde, es wird nichts geteilt."
  elseif setting("share") ~= true then
    h.ok, h.reason, h.short = false, "off", "Teilen ist aus"
    h.text = "Teilen ist ausgeschaltet (Hausordnung, Blatt Gilde)."
  elseif prefixOK == false then
    h.ok, h.reason, h.short = false, "prefix", "Empfang geht nicht"
    h.text = "Das Spiel lässt keinen Empfang zu. Neu einloggen hilft."
    h.detail = "RegisterAddonMessagePrefix: " .. tostring(stats.prefixResult)
  elseif stats.hardFail and stats.sent == 0 or (stats.failStreak or 0) >= 3 and stats.sent == 0 then
    h.ok, h.reason, h.short = false, "blocked", "Realm blockt Senden"
    h.text = "Der Realm blockt das Senden. Weitergeben mit Buch sichern."
    h.detail = "SendAddonMessage: " .. tostring(stats.lastFail)
  elseif stats.hardFail or (stats.failStreak or 0) >= 3 then
    h.ok, h.reason, h.short = false, "failing", "Senden hakt"
    h.text = "Senden klappt gerade nicht, es wird erneut versucht."
    h.detail = "SendAddonMessage: " .. tostring(stats.lastFail)
  else
    local why = holdReason()
    if why and #queue > 0 then
      h.ok, h.reason, h.short = true, "hold", HOLD_SHORT[why] or "Wartet"
      h.text = "Senden wartet, " .. (HOLD_TEXT[why] or "bis es wieder geht") .. "."
    elseif stats.sent > 0 and stats.received == 0 then
      h.ok, h.reason, h.short = true, "quiet", "Angefragt"
      h.text = "Gesendet, aber noch kein Kollege mit DeathNote gehört."
    else
      h.ok, h.reason, h.short = true, "ok", "Angefragt"
      local n = list and #Guild.Members() or 0
      if n == 0 then
        h.text = "Bereit. Noch kein Kollege mit DeathNote gehört."
      elseif n == 1 then
        h.text = "Läuft: 1 Kollege mit DeathNote."
      else
        h.text = ("Läuft: %d Kollegen mit DeathNote."):format(n)
      end
    end
  end
  return h
end

local function planHello()
  if helloPlanned then return end
  helloPlanned = true
  local After = _G.C_Timer and _G.C_Timer.After
  if not After then return end
  After(C.HELLO_MIN + math.random() * (C.HELLO_MAX - C.HELLO_MIN), function()
    if not guildNameNow() and inGuild() then
      -- guild info not there yet: one more try later
      After(15, function() bind(); sendHello() end)
      return
    end
    bind()
    sendHello()
  end)
end

ns:On("READY", function()
  Guild.Init()
  planHello()
end)
ns:On("DEATH_RECORDED", Guild.OnDeath)
-- a change in the personal list only flips the "mine" mark of that one guild entry;
-- the sort orders do not depend on it, so the caches stay
ns:On("ENEMY_UPDATED", function(key)
  local e = type(key) == "string" and store.enemies[key]
  if e then e.mine = (ns.Store and ns.Store.Get(key)) and true or false end
end)
ns:On("SETTINGS_CHANGED", function(path)
  if type(path) ~= "string" or not path:find("^guild") then return end
  invalidate()
  -- sharing of hand entries switched on: own listings into the list and out to the guild
  if path == "guild.shareManual" and setting("shareManual") == true and gdb and inGuild() then
    bind()
    local listed = ownListed(C.LISTED_REPLY, true)
    local changed = false
    for i = 1, #listed do
      local res = addOwnListed(listed[i])
      if res == "new" or res == "add" or res == "upd" then changed = true end
      if canSend() then enqueue(P.EncodeListed(listed[i]), "M") end
    end
    if changed then setHook(); updated() end
  end
end)
-- hand entries of the personal list (1.1.0)
ns:On("MANUAL_ADDED", function(key) Guild.OnListed(key) end)
ns:On("ENEMY_REMOVED", function(key, e) Guild.OnUnlisted(key, e) end)
ns:On("ENEMY_STATUS", function(key, old, new)
  local e = ns.Store and ns.Store.Get(key)
  if not e then return end
  if old == "wanted" and new ~= "wanted" then Guild.OnUnlisted(key, e)
  elseif new == "wanted" and old ~= "wanted" then Guild.OnListed(key) end
end)
ns:On("ENEMY_REKEYED", function(oldKey, newKey)
  local e = ns.Store and ns.Store.Get(newKey)
  if not e or not listable(newKey, e) or type(e.by) ~= "string" then return end
  Guild.OnUnlisted(oldKey, e)
  Guild.OnListed(newKey)
end)

ns:RegisterEvent("CHAT_MSG_ADDON", Guild.OnAddonMessage)
ns:RegisterEvent("PLAYER_GUILD_UPDATE", function()
  if gdb and bind() then setHook() end
end)
ns:RegisterEvent("PLAYER_REGEN_ENABLED", function() if #queue > 0 then pump() end end)
ns:RegisterEvent("PLAYER_ENTERING_WORLD", function() if #queue > 0 then pump() end end)
ns:RegisterEvent("ADDON_RESTRICTION_STATE_CHANGED", function() if #queue > 0 then pump() end end)
ns:RegisterEvent("PLAYER_LOGOUT", function()
  if not gdb then return end
  if list and inGuild() then list.lastOnline = now(); list.used = now() end
  -- the aliases would be saved as copies
  gdb.enemies, gdb.members, gdb.lastOnline = nil, nil, nil
end)
