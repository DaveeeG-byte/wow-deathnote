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
--   1 J key display class level t char reason [book]   released for the hunt (Abschussliste, 1.2.0)
--   1 A key char                                hunt called off by its own releaser (1.2.0)
--   1 E key char t                              a target of the hunt list killed by char (1.2.0)
--   1 Z char n [book]                           end of an answer: these n J were ALL releases of char (1.2.0);
--                                               only sent when the answer was not capped
-- book (optional last field of J and Z, 1.2.0): the book id of the SavedVariables the release was made in;
-- a Z only takes back releases of that char with the same book id (another device or a lost file never does).
-- A hello to a friend (WHISPER/Battle.net, never GUILD) may carry a fifth field: the sender's GUID (1.2.0).
-- The first field is the protocol version; unknown versions and types are dropped silently
-- (1.1.0 and older drop J/A/E as "type").
-- 1.2.0: the same messages also go to friends as WHISPER (Friends.lua: who, when, trust);
-- the send queue below carries channel and target per message.

local ADDON, ns = ...
-- Texte (1.2.0): L.KEY nur in Funktionen lesen; gespeichert und gesendet wird nie Uebersetztes
local L, Fmt = ns.L, ns.F
local Util = ns.Util
local IsSecret = Util.IsSecret

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
  REPLY_TRIES = 6, REPLY_RETRY = 10,   -- an answer waits this often this long for the guild name after login
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
  -- hunt list (J/A/E, 1.2.0), per store (one guild list, the friends' list)
  HUNT_MAX = 100,           -- targets per store
  HUNT_PER_SENDER = 10,     -- releases one char may have in a store
  HUNT_REPLY = 10,          -- J messages per answer to a hello
  HUNTOFF_REPLY = 10,       -- A messages per answer (call-offs a member may have missed)
  REASON_CHARS = 60, REASON_BYTES = 120,   -- the only free text that is ever shared
  BAG_DEDUPE = 120,         -- one kill reported twice (two channels, two events) counts once
  BAGGED_MAX = 99,          -- small cap: the counter is a hint, not a score
  BAG_FRESH = 600,          -- an E older than 10 minutes is dropped (E is never part of an answer)
  BAGS_MAX = 20,            -- remembered kills (char, t) per target: every kill counts once
  BAG_PER_SENDER = 3, BAG_WINDOW = 600,     -- E accepted per sender in 10 minutes
  CLEARED_MAX = 200,        -- releases "cleared" by the player, remembered against the next answer (1.2.0)
  HUNT_LIVE_MAX = 5, HUNT_LIVE_WINDOW = 600, -- new releases per sender taken live in 10 minutes
  ANSWER_WINDOW = 60,       -- after the OWN hello: J messages are answers (own cap, collective notice)
  NEW_NOTICE_DELAY = 8,     -- new releases of others are announced together after this
  HIDDEN_MAX = 200,         -- targets hidden "for me"
  MATE_RECENT = 300,        -- without the guild roster API: a member heard this recently is a guildmate
  ROSTER_TTL = 30,
  ROSTER_MIN = 5,           -- a roster event within this many seconds and with the same number of members: no new read          -- the guild roster is read again after this (on demand, never per message)
  MATE_GONE = 14 * 86400,   -- not in the roster and not heard on GUILD this long: left the guild (1.2.0)
  EXPIRE_DAYS = { 0, 30, 90, 180 },   -- releases expire after (0 = never, the default)
}
Guild.PREFIX, Guild.C = PREFIX, C

---------------------------------------------------------------------------
-- Pure protocol functions (no WoW calls; `now` is always passed in)
---------------------------------------------------------------------------
local P = {}
Guild.Proto = P

function P.Finite(v) return type(v) == "number" and v == v and v < math.huge and v > -math.huge end

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

-- At most n characters (UTF-8 lead bytes counted).
local function cutChars(s, n)
  local count, i, len = 0, 1, #s
  while i <= len do
    count = count + 1
    if count > n then return s:sub(1, i - 1) end
    local b = s:byte(i)
    i = i + (b >= 0xF0 and 4 or b >= 0xE0 and 3 or b >= 0xC0 and 2 or 1)
  end
  return s
end

-- Only valid UTF-8 is kept (broken lead or continuation bytes, overlong forms and surrogates are
-- dropped). Invisible direction and zero-width marks go, no-break spaces become plain spaces.
local function cleanUTF8(s)
  if not s:find("[\128-\255]") then return s end
  local out, i, n = {}, 1, #s
  while i <= n do
    local b = s:byte(i)
    local need = b < 0x80 and 0 or (b >= 0xC2 and b <= 0xDF) and 1 or (b >= 0xE0 and b <= 0xEF) and 2
      or (b >= 0xF0 and b <= 0xF4) and 3 or -1
    local ok = need >= 0 and i + need <= n
    if ok then
      for k = 1, need do
        local c = s:byte(i + k)
        if c < 0x80 or c > 0xBF then ok = false; break end
      end
    end
    if ok and need >= 2 then
      local c1 = s:byte(i + 1)
      if (b == 0xE0 and c1 < 0xA0) or (b == 0xED and c1 > 0x9F) or (b == 0xF0 and c1 < 0x90) or (b == 0xF4 and c1 > 0x8F) then
        ok = false
      end
    end
    if ok then
      local c1, c2 = s:byte(i + 1), s:byte(i + 2)
      if need == 1 and b == 0xC2 and c1 == 0xA0 then
        out[#out + 1] = " "                                   -- U+00A0
      elseif need == 2 and b == 0xE2 and c1 == 0x80 and ((c2 >= 0x8B and c2 <= 0x8F) or (c2 >= 0xAA and c2 <= 0xAE)) then
        -- U+200B..U+200F, U+202A..U+202E: dropped
      elseif need == 2 and b == 0xE2 and c1 == 0x81 and (c2 == 0xA0 or (c2 >= 0xA6 and c2 <= 0xA9)) then
        -- U+2060, U+2066..U+2069: dropped
      elseif need == 2 and b == 0xEF and c1 == 0xBB and c2 == 0xBF then
        -- U+FEFF: dropped
      elseif need == 2 and b == 0xE2 and c1 == 0x80 and (c2 == 0xA8 or c2 == 0xA9 or c2 == 0xAF) then
        out[#out + 1] = " "                                   -- U+2028, U+2029, U+202F
      else
        out[#out + 1] = s:sub(i, i + need)
      end
      i = i + need + 1
    else
      i = i + 1
    end
  end
  return table.concat(out)
end
P.CleanUTF8 = cleanUTF8

-- Reason of a hunt release (1.2.0): one plain line, no UI codes, at most REASON_CHARS characters
-- and REASON_BYTES bytes, valid UTF-8 only. Used before sending and after receiving.
function P.CleanReason(s)
  if type(s) ~= "string" or s == "" then return "" end
  s = cleanUTF8(s)
  if s:find("|", 1, true) then
    s = s:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|T.-|t", ""):gsub("|A.-|a", "")
    s = s:gsub("|H.-|h", ""):gsub("|h", ""):gsub("|", "")
  end
  s = s:gsub("%c", " "):gsub("%s+", " "):gsub("^ ", ""):gsub(" $", "")
  s = P.CutUTF8(cutChars(s, C.REASON_CHARS), C.REASON_BYTES)
  return (s:gsub(" $", ""))
end

-- Decoded reason field: broken escaping drops the message, odd content is cleaned, not refused.
local function unescapeReason(s)
  if #s > C.REASON_BYTES * 3 then return nil end
  if s:find("%", 1, true) then
    if s:gsub("%%%x%x", ""):find("%", 1, true) then return nil end
    s = s:gsub("%%(%x%x)", hexByte)
  end
  return P.CleanReason(s)
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

-- guid (optional, 1.2.0): only in hellos to friends; the guild hello keeps the four fields of 1.1.0
function P.ValidGUID(g)
  if IsSecret(g) then return false end
  return type(g) == "string" and #g <= 40 and g:match("^Player%-%d+%-%x+$") ~= nil
end
function P.EncodeHello(since, version, guid)
  if IsSecret(since) or IsSecret(version) then return nil end
  local v = type(version) == "string" and version:match("^%d+%.%d+[%.%d]*$") and #version <= 16 and version or "0"
  local out = table.concat({ PROTO, "H", tostring(math.floor(tonumber(since) or 0)), v }, "\t")
  if P.ValidGUID(guid) then out = out .. "\t" .. guid end
  return out
end

-- book id (1.2.0): a short random mark of the SavedVariables a release was made in (one per account and
-- device). It travels as an optional last field of J and Z; a Z only touches releases of its own book.
function P.ValidBook(b)
  return not IsSecret(b) and type(b) == "string" and #b >= 4 and #b <= 12 and b:match("^%w+$") ~= nil
end
function P.NewBook()
  local A = "0123456789abcdefghijklmnopqrstuvwxyz"
  local seed = math.floor((tonumber(time and time()) or 0) + (tonumber(GetTime and GetTime()) or 0) * 1000)
  local out = {}
  for i = 1, 8 do
    local k = (math.random(0, 35) + seed) % 36 + 1
    seed = math.floor(seed / 7)
    out[i] = A:sub(k, k)
  end
  return table.concat(out)
end

-- end of an answer (1.2.0): n = number of J that went out for char, all of his releases; b = book id
function P.EncodeSnapshot(by, n, b)
  if IsSecret(by) or IsSecret(n) then return nil end
  if type(by) ~= "string" or by == "" or plain(by) ~= by or type(n) ~= "number" then return nil end
  local msg = table.concat({ PROTO, "Z", P.Escape(by), tostring(math.floor(n)) }, "\t")
  if P.ValidBook(b) then msg = msg .. "\t" .. b end
  if #msg > C.MAX_MSG then return nil end
  return msg
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

-- Released for the hunt (1.2.0). h = { key, display, class, level, t, by, why }.
-- Too long: the display name goes first, then the reason is cut.
function P.EncodeHunt(h)
  if type(h) ~= "table" or type(h.key) ~= "string" or type(h.t) ~= "number" then return nil end
  local key = plain(h.key)
  if key ~= h.key then return nil end
  local by = plain(h.by)
  if by == "" or by ~= h.by then return nil end
  local display = plain(h.display)
  if display == key then display = "" end
  local class = type(h.class) == "string" and h.class:match("^%u+$") and #h.class <= 16 and h.class or ""
  local level = type(h.level) == "number" and math.floor(h.level) or 0
  if level < 0 or level > C.MAX_LEVEL then level = 0 end
  local why = P.CleanReason(h.why)
  local head = PROTO .. "\tJ\t" .. P.Escape(key) .. "\t"
  local mid = "\t" .. class .. "\t" .. tostring(level) .. "\t" .. tostring(math.floor(h.t)) .. "\t" .. P.Escape(by) .. "\t"
  local tail = P.ValidBook(h.b) and ("\t" .. h.b) or ""
  local msg = head .. P.Escape(display) .. mid .. P.Escape(why) .. tail
  if #msg > C.MAX_MSG then msg = head .. mid .. P.Escape(why) .. tail end
  while #msg > C.MAX_MSG and why ~= "" do
    why = P.CutUTF8(why, #why - math.max(1, math.ceil((#msg - C.MAX_MSG) / 3)))
    msg = head .. mid .. P.Escape(why) .. tail
  end
  if #msg > C.MAX_MSG then return nil end
  return msg
end

function P.EncodeCallOff(key, by)
  if type(key) ~= "string" or plain(key) ~= key or type(by) ~= "string" or by == "" or plain(by) ~= by then return nil end
  local msg = table.concat({ PROTO, "A", P.Escape(key), P.Escape(by) }, "\t")
  if #msg > C.MAX_MSG then return nil end
  return msg
end

function P.EncodeBagged(key, by, t)
  if type(key) ~= "string" or plain(key) ~= key or type(by) ~= "string" or by == "" or plain(by) ~= by
    or type(t) ~= "number" then return nil end
  local msg = table.concat({ PROTO, "E", P.Escape(key), P.Escape(by), tostring(math.floor(t)) }, "\t")
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

local FIELDS = { K = 9, R = 9, H = 4, S = 5, J = 9, A = 4, E = 5, Z = 4, M = 8, X = 4 }

-- Parses an incoming text into `out` (a reused table). Returns out or nil, reason.
-- Never raises for any input.
function P.Decode(text, now, out)
  if type(text) ~= "string" or #text == 0 or #text > C.MAX_MSG then return nil, "size" end
  local n = split(text, 10)
  if not n then return nil, "fields" end
  if F[1] ~= PROTO then return nil, "version" end
  local kind = F[2]
  local want = FIELDS[kind]
  if not want then return nil, "type" end
  -- optional last fields (1.2.0): the GUID of a hello, the book id of J and Z
  if n ~= want and not ((kind == "H" or kind == "Z") and n == want + 1) and not (kind == "J" and n == want + 1) then
    return nil, "fields"
  end
  out = out or {}
  for k in pairs(out) do out[k] = nil end
  out.kind = kind
  if kind == "H" then
    out.since = int(F[3], 0, now + C.FUTURE)
    if not out.since then return nil, "since" end
    local v = F[4]
    out.version = (#v <= 16 and v:match("^%d+%.%d+[%.%d]*$")) and v or nil
    -- 1.2.0: GUID of a friend's hello (a broken one is ignored, not the hello)
    if n == 5 and P.ValidGUID(F[5]) then out.guid = F[5] end
    return out
  end
  if kind == "Z" then
    out.by = P.Unescape(F[3])
    if not out.by or out.by == "" then return nil, "by" end
    out.n = int(F[4], 0, C.HUNT_REPLY)
    if not out.n then return nil, "fields" end
    if n == 5 and P.ValidBook(F[5]) then out.b = F[5] end
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
  if kind == "X" or kind == "A" then
    out.by = P.Unescape(F[4])
    if not out.by or out.by == "" then return nil, "by" end
    return out
  end
  if kind == "E" then
    out.by = P.Unescape(F[4])
    if not out.by or out.by == "" then return nil, "by" end
    out.t = int(F[5], now - C.MAX_AGE, now + C.FUTURE)
    if not out.t then return nil, "time" end
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
  if kind == "J" then
    -- how long a release stays is the receiver's setting (apply); here only plain bounds
    out.t = int(F[7], now - C.LISTED_MAX_AGE, now + C.FUTURE)
    if not out.t then return nil, "time" end
    out.by = P.Unescape(F[8])
    if not out.by or out.by == "" then return nil, "by" end
    out.why = unescapeReason(F[9])
    if not out.why then return nil, "reason" end
    if n == 10 and P.ValidBook(F[10]) then out.b = F[10] end
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
    -- opts.noGrow (backfill of own kills at login): a full list takes no new entry, so nothing is pushed out
    if opts and opts.noGrow and (store.count or 0) >= C.MAX_ENEMIES then return "cap" end
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
        -- sightings (1.2.0): a finite number as time, plain texts or nothing (else every received
        -- sighting would raise in apply)
        local ls = e.lastSeen
        if ls ~= nil then
          if type(ls) ~= "table" or not P.Finite(ls.t) then
            e.lastSeen = nil
          else
            if ls.zone ~= nil and (type(ls.zone) ~= "string" or #ls.zone > C.MAX_FIELD) then ls.zone = nil end
            if ls.by ~= nil and not (type(ls.by) == "string" and ls.by ~= "" and #ls.by <= C.MAX_FIELD
              and not ls.by:find("[%c|]")) then ls.by = nil end
          end
        end
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
-- Hunt list (Abschussliste, 1.2.0): hunts = { [key] = H }, H = { key, name, surname, display,
-- class, level, by = { [char] = { t = released, why = reason or nil } }, bagged = n,
-- lastBagged = { by, t }, lastSeen = { t, zone, by } }. A target stays while one release is left.
---------------------------------------------------------------------------
-- Who stands behind a release: the sender as the client named him (r.via, 1.2.0 fix) or the char.
-- A sender with a surname can only release as himself, so via is then the char; a sender known by
-- the first name only is one owner, whatever char names he writes into the field.
local function ownerOf(char, r)
  local v = type(r) == "table" and r.via or nil
  return (type(v) == "string" and v or char):lower()
end
P.OwnerOf = ownerOf

-- releases of one owner (see ownerOf) in a hunt table
function P.HuntReleases(hunts, owner)
  if type(owner) ~= "string" or owner == "" then return 0 end
  local o = owner:lower()
  local n = 0
  for _, h in pairs(hunts) do
    for c, r in pairs(h.by) do if ownerOf(c, r) == o then n = n + 1 end end
  end
  return n
end

-- newest release time of a target
local function huntNewest(h)
  local t = 0
  for _, r in pairs(h.by) do if type(r.t) == "number" and r.t > t then t = r.t end end
  return t
end

-- the target that leaves when a table is full: no release of an own char (protect), oldest first
local function huntVictim(hunts, protect)
  local oldKey, oldT
  for k, h in pairs(hunts) do
    local own = false
    if protect then for c in pairs(h.by) do if protect(c) then own = true; break end end end
    if not own then
      local t = huntNewest(h)
      if not oldT or t < oldT or (t == oldT and k < oldKey) then oldKey, oldT = k, t end
    end
  end
  return oldKey
end

-- m = decoded J (or own release): { key, name, surname, display, class, level, t, by, why }.
-- opts = { maxPerSender, maxTotal, via (sender as the client named him; default m.by),
-- protect = function(char) -> true for own chars }. One release per owner and target: a later J
-- of the same owner replaces the earlier one (other spelling of the char). A full table makes the
-- oldest target without an own release leave, never an own one.
-- Returns "new" | "add" | "upd" | "dup" | "cap" | nil, H.
function P.MergeHunt(hunts, m, opts)
  local char = m.by
  if not memberKey(char) then return nil end
  local via = opts and type(opts.via) == "string" and opts.via or char
  local owner = via:lower()
  local why = (type(m.why) == "string" and m.why ~= "") and m.why or nil
  local b = P.ValidBook(m.b) and m.b or nil
  local h = hunts[m.key]
  local had = h and h.by[char]
  if had then
    local v = owner ~= char:lower() and via or nil
    if had.t == m.t and had.why == why and had.via == v and (b == nil or had.b == b) then return "dup", h end
    had.t, had.why, had.via = m.t, why, v
    if b then had.b = b end
    return "upd", h
  end
  -- the same owner under another spelling on this target: replaced, does not count twice
  local replace
  if h then
    for c, r in pairs(h.by) do
      if ownerOf(c, r) == owner then replace = replace or {}; replace[#replace + 1] = c end
    end
  end
  if opts and opts.maxPerSender and P.HuntReleases(hunts, via) - (replace and #replace or 0) >= opts.maxPerSender then
    return "cap"
  end
  local res = "add"
  if not h then
    if opts and opts.maxTotal then
      local n = 0
      for _ in pairs(hunts) do n = n + 1 end
      if n >= opts.maxTotal then
        local victim = huntVictim(hunts, opts.protect)
        if not victim then return "cap" end
        hunts[victim] = nil
      end
    end
    h = { key = m.key, name = m.name, surname = m.surname, display = m.display or m.name, by = {} }
    hunts[m.key] = h
    res = "new"
  end
  if replace then for i = 1, #replace do h.by[replace[i]] = nil end end
  if m.class then h.class = m.class end
  if m.level then h.level = m.level end
  if m.display and (not h.display or #m.display > #h.display) then h.display = m.display end
  h.by[char] = { t = m.t, why = why, via = owner ~= char:lower() and via or nil, b = b }
  return res, h
end

-- Takes back the release of `char`. Returns "gone" (target left the list), "removed" or nil.
function P.CallOffHunt(hunts, key, char)
  local h = hunts[key]
  if not h or not h.by[char] then return nil end
  h.by[char] = nil
  if next(h.by) == nil then hunts[key] = nil; return "gone" end
  return "removed"
end

-- A kill of a target by `char` at time t. false when unknown or the same kill again. Every kill
-- (char, t) counts once: the last BAGS_MAX are remembered per target (h.bags), a kill older than
-- all of them while the memory is full is not taken (it could be one that was forgotten).
function P.BagHunt(hunts, key, char, t)
  local h = hunts[key]
  if not h or type(char) ~= "string" or type(t) ~= "number" then return false end
  t = math.floor(t)
  local lb = h.lastBagged
  if lb and lb.by == char and math.abs((lb.t or 0) - t) < C.BAG_DEDUPE then return false end
  local bags = h.bags
  if type(bags) ~= "table" then bags = {}; h.bags = bags end
  local oldest
  for i = 1, #bags do
    local b = bags[i]
    if b.by == char and math.abs(b.t - t) < C.BAG_DEDUPE then return false end
    if not oldest or b.t < oldest then oldest = b.t end
  end
  if #bags >= C.BAGS_MAX and oldest and t <= oldest then return false end
  bags[#bags + 1] = { by = char, t = t }
  table.sort(bags, function(a, b) return a.t > b.t end)
  while #bags > C.BAGS_MAX do table.remove(bags) end
  h.bagged = math.min(C.BAGGED_MAX, (h.bagged or 0) + 1)
  if not lb or t >= (lb.t or 0) then h.lastBagged = { by = char, t = t } end
  return true
end

local finite = P.Finite
local function plainName(s)
  return type(s) == "string" and s ~= "" and #s <= C.MAX_FIELD and not s:find("[%c|]")
end

-- Repairs a stored hunt table in place (broken entries out). opts (all optional):
-- { maxAge = seconds (nil = releases never expire), mine = function(char) -> true for own chars,
--   self = the logged-in char, expired = array (1.2.0) }.
-- An own release "from the future" (the own clock was set back) is set to now instead of dropped,
-- so it can still be called off; a foreign one is dropped.
-- Expiry of own releases (1.2.0): an expired release of the logged-in char is not dropped here but
-- listed in opts.expired ({ key, char }); the caller calls it off properly (call-off sent, remembered for the
-- answers). An own release of another own char stays until that char logs in (only he can call it off).
function P.SanitizeHunts(hunts, now, opts)
  if type(opts) ~= "table" then opts = nil end
  local maxAge = opts and opts.maxAge
  local mine = opts and opts.mine
  local selfChar, expired = opts and opts.self, opts and opts.expired
  local n = 0
  for key, h in pairs(hunts) do
    local keep = type(h) == "table" and P.ValidKey(key) and type(h.by) == "table"
    if keep then
      for char, r in pairs(h.by) do
        local old = maxAge and type(r) == "table" and finite(r.t) and r.t < now - maxAge
        if old and plainName(char) and mine and mine(char) then
          if char == selfChar and type(expired) == "table" then expired[#expired + 1] = { key = key, char = char } end
        elseif not plainName(char) or type(r) ~= "table" or not finite(r.t) or old then
          h.by[char] = nil
        elseif r.t > now + C.FUTURE then
          if mine and mine(char) then r.t = now else h.by[char] = nil end
        end
        if h.by[char] then
          if r.why ~= nil then
            r.why = type(r.why) == "string" and P.CleanReason(r.why) or nil
            if r.why == "" then r.why = nil end
          end
          if r.via ~= nil and not plainName(r.via) then r.via = nil end
          if r.b ~= nil and not P.ValidBook(r.b) then r.b = nil end
        end
      end
      keep = next(h.by) ~= nil
    end
    if keep then
      local nm, s = P.ValidKey(key)
      h.key, h.name, h.surname = key, nm, s
      if type(h.display) ~= "string" then h.display = nm .. " " .. s end
      if h.class ~= nil and not (type(h.class) == "string" and h.class:match("^%u+$")) then h.class = nil end
      if h.level ~= nil and (not finite(h.level) or h.level < 1 or h.level > C.MAX_LEVEL) then h.level = nil end
      if not finite(h.bagged) or h.bagged < 0 then h.bagged = nil
      else h.bagged = math.min(C.BAGGED_MAX, math.floor(h.bagged)) end
      local lb = h.lastBagged
      if lb ~= nil and (type(lb) ~= "table" or not plainName(lb.by) or not finite(lb.t)) then h.lastBagged = nil end
      -- sightings: a number as time, plain texts or nothing (else every sort and sighting would raise)
      local ls = h.lastSeen
      if ls ~= nil then
        if type(ls) ~= "table" or not finite(ls.t) then
          h.lastSeen = nil
        else
          if ls.zone ~= nil and (type(ls.zone) ~= "string" or #ls.zone > C.MAX_FIELD) then ls.zone = nil end
          if ls.by ~= nil and not plainName(ls.by) then ls.by = nil end
        end
      end
      local bags = h.bags
      if bags ~= nil then
        if type(bags) ~= "table" then
          h.bags = nil
        else
          for i = #bags, 1, -1 do
            local b = bags[i]
            if type(b) ~= "table" or not plainName(b.by) or not finite(b.t) then table.remove(bags, i) end
          end
          while #bags > C.BAGS_MAX do table.remove(bags) end
        end
      end
      n = n + 1
    else
      hunts[key] = nil
    end
  end
  while n > C.HUNT_MAX do
    local oldKey = huntVictim(hunts, mine) or huntVictim(hunts, nil)
    hunts[oldKey] = nil
    n = n - 1
  end
  return n
end

-- Drops everything of chars that `keep(char)` refuses (a friend removed from the friend list):
-- deeds by victim, listings and hunt releases by char. Returns the number of changes.
function P.PurgeChars(store, hunts, keep)
  local changed = 0
  for key, e in pairs(store.enemies) do
    local deeds = e.deeds
    local hit = false
    for i = #deeds, 1, -1 do
      if not keep(deeds[i].victim) then table.remove(deeds, i); hit = true end
    end
    if e.listedBy then
      for char in pairs(e.listedBy) do if not keep(char) then e.listedBy[char] = nil; hit = true end end
    end
    if hit then
      changed = changed + 1
      P.Recompute(e)
      if #deeds == 0 and not e.listedBy then store.enemies[key] = nil end
    end
  end
  if hunts then
    for key, h in pairs(hunts) do
      for char in pairs(h.by) do if not keep(char) then h.by[char] = nil; changed = changed + 1 end end
      if next(h.by) == nil then hunts[key] = nil end
    end
  end
  if changed > 0 then P.Recount(store) end
  return changed
end

---------------------------------------------------------------------------
-- Client glue (WoW calls only below)
---------------------------------------------------------------------------
local Call, Str = Util.Call, Util.Str

local gdb                -- DeathNoteDB.guild = { name, lists = { [guild] = { enemies, members, lastOnline, used } } }
local list               -- gdb.lists[gdb.name]: the list of the bound guild, or nil
local book               -- gdb.book: the book id of these SavedVariables (1.2.0)
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
-- 1.2.0: Friends.lua attaches itself (Guild.AttachFriends): { store, stats, hunts(), members(), ... }
local friends
-- the channel a received message belongs to: store, hunt table, counters (the friends' one in Friends.lua)
-- fresh: per sender the live cap of new releases and kills (J/E); helloAt: GetTime() of the last
-- hello on this channel (J in the minute after are answers)
local GCTX = { src = "guild", store = store, stats = stats, hunts = nil, fresh = {}, helloAt = nil }
local views = {}          -- source -> merged/plain store (see view())
local huntCache = {}      -- source -> sorted hunt rows
local huntIndex = {}      -- source -> key -> row of huntCache[source]
-- the hunt list of the guild while it counts (in that guild, list bound); nil otherwise (1.2.0 fix:
-- after leaving the guild its hunt list neither alarms nor shows)
local GH

local function now() return time() end

local DEFAULTS = { share = true, receive = true, alert = true, announce = true, sightings = false, minKills = 1,
  shareManual = true, alertListed = false, friends = true, alertHunt = true,
  -- announceHunt: the notice "taken down" / "new targets" (fix: the window had no switch);
  -- huntExpire: days after which releases expire, 0 = never
  announceHunt = true, huntExpire = 0 }
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

-- how long releases stay, in seconds; nil = never
local function expireAge()
  local d = tonumber(setting("huntExpire")) or 0
  if d ~= d or d <= 0 then return nil end
  return math.floor(d) * 86400
end
Guild.ExpireAge = expireAge

local function invalidate()
  for k in pairs(listCache) do listCache[k] = nil end
  rankCache = nil
  memberCache = nil
  for k in pairs(views) do views[k] = nil end
  for k in pairs(huntCache) do huntCache[k] = nil; huntIndex[k] = nil end
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

-- "Name Surname" -> "Name", "Surname"; "Name" / "Name-Realm" -> "Name", nil
local function splitName(s)
  local f, sur = s:match("^(%S+)%s+(.+)$")
  if f then return f, (sur:match("^([^%-]+)") or sur) end
  return (s:match("^([^%s%-]+)") or s), nil
end
P.SplitName = splitName

-- first names equal, surnames too when both have one
local function sameName(n, s, other)
  if type(other) ~= "string" or type(n) ~= "string" then return false end
  local f, s2 = splitName(other)
  if f:lower() ~= n:lower() then return false end
  return not (s and s2 and s:lower() ~= s2:lower())
end

-- Does the char named in a message (victim, lister, releaser, hunter) belong to the sender?
-- short = sender as the client gives it ("Name" or "Name Surname"); known = the sender's surname
-- known otherwise (friend list, the bound full name, the guild roster) or nil.
-- A sender with a surname must name exactly himself; else the first names must match and a known
-- surname must match too. Without any surname only the first name binds (the client gave no more).
function P.Owns(char, short, known)
  if type(char) ~= "string" or type(short) ~= "string" then return false end
  local cf, cs = splitName(char)
  local sf, ss = splitName(short)
  if cf:lower() ~= sf:lower() then return false end
  ss = ss or known
  if ss then return cs ~= nil and cs:lower() == ss:lower() end
  return true
end
local owns = P.Owns

---------------------------------------------------------------------------
-- Guild roster (1.2.0 fix): who is in the guild right now, and with which surname. Read on demand
-- (at most every ROSTER_TTL seconds) and on GUILD_ROSTER_UPDATE, never per message.
-- API as OpenMap/Map/Friends.lua ScanGuild uses it: GetNumGuildMembers, GetGuildRosterInfo.
---------------------------------------------------------------------------
-- roster: lower first name -> { [lower surname or ""] = { name = surname or false, n = count } }; nil = no
-- API. The own char is taken out once (a guildmate with the same first name stays in).
local roster, rosterAt, rosterN
local function readRoster()
  rosterAt = GetTime()
  if not (_G.GetNumGuildMembers and _G.GetGuildRosterInfo) or not inGuild() then roster = nil; return end
  local n = Util.Num(call1(_G.GetNumGuildMembers)) or 0
  rosterN = n
  local r = {}
  for i = 1, math.min(n, 1000) do
    local name = Str((Call(_G.GetGuildRosterInfo, i)))
    if name and #name <= 80 and not name:find("[%c|]") then
      local f, s = splitName(name)
      local k = f:lower()
      local x = r[k]
      if not x then x = {}; r[k] = x end
      local sk = s and s:lower() or ""
      local y = x[sk]
      if not y then y = { name = s or false, n = 0 }; x[sk] = y end
      y.n = y.n + 1
    end
  end
  -- the own char: by full name, else by the first name alone
  local mf, ms = splitName(myFullName() or myName() or "")
  local x = r[mf:lower()]
  if x then
    local sk = ms and x[ms:lower()] and ms:lower() or ""
    local y = x[sk]
    if y then
      y.n = y.n - 1
      if y.n <= 0 then x[sk] = nil end
      if next(x) == nil then r[mf:lower()] = nil end
    end
  end
  roster = n > 0 and r or nil
end
local function rosterNow()
  if not rosterAt or GetTime() - rosterAt >= C.ROSTER_TTL then readRoster() end
  return roster
end
Guild.ReadRoster = readRoster

-- the surname the guild roster gives a first name, when it is the only one with that first name
local function rosterSurname(first)
  local r = rosterNow()
  local x = r and r[first:lower()]
  if not x then return nil end
  local only
  for _, y in pairs(x) do
    if only ~= nil or y.n > 1 then return nil end
    only = y
  end
  return only and only.name or nil
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

local NO_GROW = { noGrow = true }
-- fill = true (backfill at login): a list at its cap is not grown; the own kills of years would each push
-- out an entry and be pushed out by the next one (8000 kills against a full list: half a second per login)
local function addOwn(k, st, fill)
  local key = k.key
  local n, s = P.ValidKey(key)
  if not n then return nil end
  local m = { key = key, name = n, surname = s, display = k.display, class = k.class, level = k.level,
    zone = k.zone, t = k.t, victim = k.victim }
  return P.Merge(st or store, m, myName() or "?", fill and NO_GROW or nil)
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

local function addOwnListed(l, st)
  local n, s = P.ValidKey(l.key)
  if not n then return nil end
  local m = { key = l.key, name = n, surname = s, display = l.display, class = l.class, level = l.level,
    t = l.t, by = l.by }
  return P.MergeListed(st or store, m, myName() or "?")
end

local function backfill()
  local added = 0
  for _, k in ipairs(ownKills(0)) do
    if addOwn(k, nil, true) == "new" then added = added + 1 end
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

-- Own chars of this account: the logged-in one and those the friends' book remembers (fdb.mine).
local function isOwnChar(char)
  if type(char) ~= "string" then return false end
  if char == myFullName() then return true end
  local db = ns.Store and ns.Store.DB and ns.Store.DB()
  local mine = db and type(db.friends) == "table" and db.friends.mine
  return type(mine) == "table" and mine[char] == true
end
Guild.IsOwnChar = isOwnChar

-- options for P.SanitizeHunts / P.MergeHunt: expiry and the own chars
function Guild.HuntOpts() return { maxAge = expireAge(), mine = isOwnChar } end

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
  -- hunt list of this guild (1.2.0, additive: 1.1.0 keeps the unknown fields untouched)
  if type(L.hunts) ~= "table" then L.hunts = {} end
  if type(L.huntOff) ~= "table" then L.huntOff = {} end
  GCTX.hunts, GCTX.huntOff = L.hunts, L.huntOff
  -- releases cleared by the player (1.2.0; additive)
  if L.huntCleared ~= nil and type(L.huntCleared) ~= "table" then L.huntCleared = nil end
  if L.huntCleared then P.SanitizeCleared(L.huntCleared) end
  GCTX.cleared = L.huntCleared
  GH = inGuild() and L.hunts or nil
  if not sanitized[L] then
    sanitized[L] = true
    P.Sanitize(store, now())
    Guild.ExpireHunts(L.hunts, L.huntOff, "guild")
  else
    P.Recount(store)
  end
  return L
end

-- Binds the list to the current guild; each guild of the account keeps its own list.
local function bind()
  if not gdb then return false end
  if not inGuild() then
    if GH then GH = nil; invalidate() end
    return false
  end
  if list then GH = list.hunts end
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

local function fhunts() return friends and friends.hunts() or nil end

local function anyHunt()
  local fh = fhunts()
  return (GH ~= nil and next(GH) ~= nil) or (fh ~= nil and next(fh) ~= nil)
end

-- Tracker hook only while there is something to look for (guild list, friends' list, hunt list)
local function setHook()
  if ns.Tracker then
    -- the friends' list counts with entries of others only (own kills there are in the own book)
    local fs = friends and friends.store
    local fn = fs and ((fs.count or 0) - ((fs.bySender and fs.bySender[myName() or ""]) or 0)) or 0
    local on = store.count > 0 or fn > 0 or anyHunt()
    ns.Tracker.guildHook = on and Guild.OnUnit or nil
  end
end

-- 1.2.0: releases of a char who left the guild and is no friend leave the guild's hunt list at the
-- next roster read: not in the roster (a roster with first names only cannot tell: kept), not heard on GUILD
-- for MATE_GONE (a roster without offline members must not cost a member his releases), not an own char.
-- His next answer would bring them back if he were still there.
local function inRoster(r, char)
  local f, s = splitName(char)
  local x = r[f:lower()]
  if not x then return false end
  if x[""] or not s then return true end
  return x[s:lower()] ~= nil
end
function Guild.PurgeLeavers()
  local r = roster
  if not r or not GH or not list then return 0 end
  local t, n = now(), 0
  for key, h in pairs(GH) do
    for c in pairs(h.by) do
      if not isOwnChar(c) and not inRoster(r, c) and not (friends and friends.FriendOf(c)) then
        local f, s = splitName(c)
        local heard = false
        for _, m in pairs(list.members) do
          if type(m.lastHeard) == "number" and t - m.lastHeard < C.MATE_GONE and sameName(f, s, m.name) then heard = true; break end
        end
        if not heard then h.by[c] = nil; n = n + 1 end
      end
    end
    if next(h.by) == nil then GH[key] = nil end
  end
  if n > 0 then setHook(); updated() end
  return n
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
local lastSendAt          -- GetTime() of the last send attempt (spacing, also after an empty queue)
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

-- May this queued message still go out? GUILD: sharing on and in a guild; WHISPER: Friends.lua decides
-- (sharing with friends on, the realm did not refuse whispers, the friend is still online).
local function allowed(m)
  if m.channel ~= "GUILD" then return friends ~= nil and friends.MaySend(m.target, m.channel) == true end
  -- (1.2.0) a message waits for the guild it was meant for: after a guild
  -- change it would land in the wrong guild's list
  if m.guild and m.guild ~= guildNameNow() then return false end
  return Guild.Enabled()
end

local function statsOf(m)
  if m.channel ~= "GUILD" and friends then return friends.stats end
  return stats
end

-- one message out: GUILD/WHISPER as addon message, "BN" as game data to a Battle.net friend
-- (BNSendGameData returns nothing usable: a call without error counts as sent)
local function send(CI, m)
  if m.channel == "BN" then
    local id = friends and friends.BNTarget(m.target)
    local fn = _G.BNSendGameData or (_G.C_BattleNet and _G.C_BattleNet.SendGameData)
    if type(id) ~= "number" or type(fn) ~= "function" then return true, 10 end
    return pcall(fn, id, PREFIX, m.text)
  end
  return pcall(CI.SendAddonMessage, PREFIX, m.text, m.channel, m.target)
end

function pump()
  if pumping then return end
  local CI = _G.C_ChatInfo
  if #queue == 0 then holdRounds = 0; return end
  if not (CI and CI.SendAddonMessage) then
    stats.dropped = stats.dropped + #queue
    queue, queued = {}, {}
    return
  end
  local t = now()
  while queue[1] and (t - queue[1].at > C.QUEUE_TTL or not allowed(queue[1])) do
    local x = table.remove(queue, 1)
    queued[x.id] = nil
    local st = statsOf(x)
    st.dropped = st.dropped + 1
  end
  local m = queue[1]
  if not m then holdRounds = 0; return end
  local why = holdReason()
  if why then stats.lastReason = why; scheduleHold(); return end
  -- 1.2.0 fix: two sends never closer than SEND_GAP, also when the queue was empty before (a burst such
  -- as "call off all" goes out spaced, not at once)
  local gt = GetTime()
  if lastSendAt and gt - lastSendAt < C.SEND_GAP - 0.01 and gt >= lastSendAt then
    local After = _G.C_Timer and _G.C_Timer.After
    if After then
      pumping = true
      After(C.SEND_GAP - (gt - lastSendAt), function() pumping = false; pump() end)
      return
    end
  end
  lastSendAt = gt
  local st = statsOf(m)
  -- a whisper to someone who just went offline must not raise: pcall, result evaluated like GUILD
  local ok, res = send(CI, m)
  if IsSecret(res) then res = nil end
  st.lastResult = ok and (res == nil and "nil" or tostring(res)) or "error"
  local outcome = P.SendOutcome(ok, res, enum("Success", 0), enum("AddonMessageThrottle", 3),
    enum("ChannelThrottle", 8), enum("GeneralError", 9), enum("AddOnMessageLockdown", 11))
  if outcome == "ok" then
    st.failStreak, st.hardFail = 0, nil
    m.throttled = nil
  elseif outcome == "throttle" then
    m.throttled = (m.throttled or 0) + 1
  else
    st.failStreak = (st.failStreak or 0) + 1
    st.lastFail = st.lastResult
    if outcome == "drop" then st.hardFail = st.lastResult end   -- a definite refusal, not a hiccup
  end
  if outcome == "ok" then
    st.sent = st.sent + 1
    if m.kind == "M" then st.listSent = (st.listSent or 0) + 1
    elseif m.kind == "X" then st.unlistSent = (st.unlistSent or 0) + 1 end
  elseif outcome ~= "throttle" then   -- throttled messages wait (bounded by QUEUE_TTL)
    m.tries = m.tries + 1
  end
  -- whispers: fewer tries (a refusing realm should not fill the queue, Friends.lua gives up early)
  local maxTries = m.channel ~= "GUILD" and 2 or C.TRIES
  if outcome == "ok" or outcome == "drop" or m.tries >= maxTries then
    if outcome ~= "ok" then st.dropped = st.dropped + 1 end
    table.remove(queue, 1)
    queued[m.id] = nil
  end
  if m.channel ~= "GUILD" and friends and friends.OnSent then friends.OnSent(m.target, outcome, m.channel) end
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

-- channel "GUILD" (default) or "WHISPER" with target = the name as the friend list gives it.
-- One queue for both: the same gap, throttle backoff and send result evaluation.
-- Release and call-off (J/A) as well as listing and removal (M/X) of the same key take each other
-- back while they wait: only the last word goes out (1.2.0 fix: release, call off, release, call
-- off in a waiting queue lost the second call-off).
local SUPERSEDE = { J = { J = true, A = true }, A = { J = true, A = true }, M = { M = true, X = true }, X = { M = true, X = true } }
local function supersede(kind, text, channel, target)
  local takes = SUPERSEDE[kind]
  if not takes then return end
  local key = text:match("^%d+\t%u\t([^\t]*)")
  if not key then return end
  for i = #queue, 1, -1 do
    local q = queue[i]
    if q.channel == channel and q.target == target and takes[q.kind] and q.text:match("^%d+\t%u\t([^\t]*)") == key then
      table.remove(queue, i)
      queued[q.id] = nil
    end
  end
end

-- Returns true when queued, else false and "dup" (the same message waits already) or "full".
local function enqueue(text, kind, channel, target)
  if not text then return false end
  channel = channel or "GUILD"
  local id = channel ~= "GUILD" and (tostring(target) .. "\t" .. text) or text
  if queued[id] then return false, "dup" end
  supersede(kind, text, channel, target)
  if #queue >= C.QUEUE_MAX then
    local st = channel ~= "GUILD" and friends and friends.stats or stats
    st.dropped = st.dropped + 1
    return false, "full"
  end
  queue[#queue + 1] = { text = text, at = now(), tries = 0, kind = kind, channel = channel, target = target, id = id,
    guild = channel == "GUILD" and guildNameNow() or nil }
  queued[id] = true
  pump()
  return true
end

function Guild.QueueSize() return #queue end
-- free places in the queue (friends' answers wait while it is nearly full)
function Guild.QueueRoom() return C.QUEUE_MAX - #queue end

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
  GCTX.helloAt = lastHello
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

-- Own releases of the logged-in char in a hunt table, newest first (1.2.0).
local function ownHunts(hunts, limit)
  local out = {}
  local mine = myFullName()
  if not hunts or not mine then return out end
  for key, h in pairs(hunts) do
    local r = h.by[mine]
    if r then
      -- a release from before the book id (1.2.0 development) belongs to this book
      out[#out + 1] = { key = key, display = h.display, class = h.class, level = h.level, t = r.t, by = mine, why = r.why,
        b = r.b or book }
    end
  end
  table.sort(out, function(a, b) if a.t ~= b.t then return a.t > b.t end return a.key < b.key end)
  if limit then while #out > limit do table.remove(out) end end
  return out
end
Guild.OwnHunts = ownHunts

-- keys of remembered tombs { [key] = { t, by } } of the logged-in char, newest first
local function ownTombs(tombs, limit)
  local mine = myFullName()
  local keys = {}
  if type(tombs) ~= "table" or not mine then return keys end
  for key, x in pairs(tombs) do if x.by == mine then keys[#keys + 1] = key end end
  table.sort(keys, function(a, b) return tombs[a].t > tombs[b].t end)
  while #keys > limit do table.remove(keys) end
  return keys
end

-- Answer to a hello on one channel: own sure kills since `since`, own hand entries, missed
-- removals, own hunt releases and missed call-offs. send(text, kind) puts one message on the way.
-- ctx = GCTX or the friends' context (own hand entries also join its store).
local function answer(ctx, since, send)
  local list = ownKills(since, C.REPLY_MAX)
  for i = 1, #list do send(P.EncodeKill(list[i], "R"), "R") end
  local mine = myFullName()
  if setting("shareManual") == true then
    -- names listed by hand (all of them, not only newer than since: there are few)
    local listed = ownListed(C.LISTED_REPLY, true)
    local changed = false
    for i = 1, #listed do
      send(P.EncodeListed(listed[i]), "M")
      local res = addOwnListed(listed[i], ctx.store)   -- maybe claimed just now: into the own list too
      if res == "new" or res == "add" or res == "upd" then changed = true end
    end
    if changed then setHook(); updated() end
    -- removals a member may have missed while offline
    local tombs = gdb and gdb.unlisted
    local keys = ownTombs(tombs, C.UNLISTED_REPLY)
    for i = 1, #keys do send(P.EncodeUnlisted(keys[i], mine), "X") end
  end
  -- hunt list: own releases and call-offs (no switch: releasing is an explicit act)
  local hunts = ownHunts(ctx.hunts)
  local all = #hunts <= C.HUNT_REPLY
  local sent = 0
  for i = 1, math.min(#hunts, C.HUNT_REPLY) do
    local ok, why = send(P.EncodeHunt(hunts[i]), "J")
    if ok or why == "dup" then sent = sent + 1 end
  end
  local offs = ownTombs(ctx.huntOff, C.HUNTOFF_REPLY)
  for i = 1, #offs do send(P.EncodeCallOff(offs[i], mine), "A") end
  -- 1.2.0: the answer names all own releases: Z says so, with their number (a capped answer or
  -- one with a lost J is no snapshot; the receiver compares the number)
  if all and mine and sent == #hunts then send(P.EncodeSnapshot(mine, sent, book), "Z") end
end

local function sendGuild(text, kind) return enqueue(text, kind) end

local function sendReply()
  local r = reply
  reply = nil
  if not r or not canSend() then return end
  -- no answer (and so no Z) while the guild name is not known yet after the login: the bound list could be
  -- the one of another guild of this account. Tried again a little later.
  if not bind() then
    r.tries = (r.tries or 0) + 1
    local After = _G.C_Timer and _G.C_Timer.After
    if After and r.tries <= C.REPLY_TRIES then reply = r; After(C.REPLY_RETRY, sendReply) end
    return
  end
  lastReplyAt = GetTime()
  GCTX.huntOff = list and list.huntOff or nil
  answer(GCTX, r.since, sendGuild)
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

-- one kill of the hunt list reported once (two channels or own kill plus echo): key -> { by, t }
local bagSeen = {}
local function fireBagged(key, char, t, src)
  local b = bagSeen[key]
  if b and b.by == char and math.abs(b.t - t) < C.BAG_DEDUPE then return end
  bagSeen[key] = { by = char, t = t }
  ns:Fire("HUNT_BAGGED", key, char, t, src)
end

-- Targets hidden "for me" (1.2.0 fix): no alarm, pale at the end of the list, undone at the poster.
-- gdb.huntHidden = { [key] = time hidden } (account-wide, additive)
local function hiddenOf(key)
  local hh = gdb and gdb.huntHidden
  return hh ~= nil and hh[key] ~= nil
end

-- the answer window of a channel: open for ANSWER_WINDOW seconds after the OWN hello on it (1.2.0:
-- the hello of somebody else no longer opens it); returns the window's id (GetTime of the hello) or nil
local EMPTY_KEYS = {}
local function answerWindow(ctx)
  local ha = ctx.helloAt
  if ha and GetTime() - ha <= C.ANSWER_WINDOW then return ha end
  return nil
end

-- Cap per sender (1.2.0): new releases (J) and kills (E). In the answer window after the own
-- hello a J is an answer: at most HUNT_REPLY per sender and window (what the protocol puts into one answer);
-- above that it waits for the next answer. Outside the window at most HUNT_LIVE_MAX new releases per
-- HUNT_LIVE_WINDOW are taken live. Both caps always hold. Returns false (drop) or "answer" / "live".
local function mayTakeRelease(ctx, who, t)
  local f = ctx.fresh
  local s = f[who]
  if not s then s = { at = t, n = 0, w = 0 }; f[who] = s end
  local ha = answerWindow(ctx)
  if ha then
    if s.win ~= ha then s.win, s.w = ha, 0 end
    if s.w >= C.HUNT_REPLY then return false end
    s.w = s.w + 1
    return "answer"
  end
  if t - s.at > C.HUNT_LIVE_WINDOW then s.at, s.n = t, 0 end
  if s.n >= C.HUNT_LIVE_MAX then return false end
  s.n = s.n + 1
  return "live"
end

-- Snapshot of an answer (1.2.0): the J of one owner in the own answer window are noted; his Z then
-- says how many J his answer had. When the numbers agree the answer was complete and every other release of
-- this owner in the table is called off (he no longer names it). A capped or broken answer is no snapshot.
local function noteAnswered(ctx, who, key)
  local ha = answerWindow(ctx)
  if not ha then return end
  local s = ctx.fresh[who]
  if not s then s = { at = now(), n = 0, w = 0 }; ctx.fresh[who] = s end
  if s.zwin ~= ha then s.zwin, s.zkeys, s.zn = ha, {}, 0 end
  if not s.zkeys[key] then s.zkeys[key] = true; s.zn = s.zn + 1 end
end

local function applySnapshot(ctx, m, short, full)
  local hunts = ctx.hunts
  local ha = answerWindow(ctx)
  if not hunts or not ha then return false end
  local s = ctx.fresh[full]
  local keys = s and s.zwin == ha and s.zkeys or EMPTY_KEYS
  local got = s and s.zwin == ha and s.zn or 0
  if got ~= m.n then return false end
  -- only releases of exactly this char made in the same book (another device, a lost file or a namesake
  -- never takes back anything); releases without a book id stay until call-off, expiry or leaving
  local b = m.b
  if not b then return false end
  local n = 0
  for key, h in pairs(hunts) do
    if not keys[key] then
      local r = h.by[m.by]
      if r and r.b == b then h.by[m.by] = nil; n = n + 1 end
      if next(h.by) == nil then hunts[key] = nil end
    end
  end
  if s then s.zwin, s.zkeys, s.zn = nil, nil, nil end
  return n > 0
end

-- E: may `who` still report a kill in this window? (counted with countBag once it really counted)
local function mayTakeBag(ctx, who, t)
  local s = ctx.fresh[who]
  if not s then s = { at = t, n = 0, w = 0 }; ctx.fresh[who] = s end
  if not s.bagAt or t - s.bagAt > C.BAG_WINDOW then s.bagAt, s.bags = t, 0 end
  return s.bags < C.BAG_PER_SENDER
end
local function countBag(ctx, who) local s = ctx.fresh[who]; if s then s.bags = (s.bags or 0) + 1 end end

-- New releases of others are announced together (one notice for several, 1.2.0 fix)
local newRel, newPlanned = {}, false
local function noticeNew(key, char, src)
  if hiddenOf(key) then return end
  newRel[#newRel + 1] = { key = key, by = char, src = src }
  if newPlanned then return end
  newPlanned = true
  local After = _G.C_Timer and _G.C_Timer.After
  local function fire()
    newPlanned = false
    local list = newRel
    newRel = {}
    -- only targets still on the list
    local keep, seen = {}, {}
    for i = 1, #list do
      local x = list[i]
      local h = (x.src == "friends" and fhunts() or GCTX.hunts or {})[x.key]
      if h and not seen[x.key] then seen[x.key] = true; keep[#keep + 1] = x end
    end
    -- 1.2.0: one releaser for all: the notice names him (full name)
    local one = true
    for i = 2, #keep do if keep[i].by ~= keep[1].by then one = false; break end end
    -- the sixth argument lists every new target ({ key, by, src }): one in sight gets its own alarm
    if #keep > 0 then ns:Fire("HUNT_NEW", #keep, keep[1].key, keep[1].by, keep[1].src, one, keep) end
  end
  if After then After(C.NEW_NOTICE_DELAY, fire) else fire() end
end

-- Data messages of one channel (ctx = GCTX or the friends' context). H is handled by the caller.
-- Everyone sends only own data: victim, lister, releaser or hunter must be the sender (P.Owns, with
-- the full name where the client gives it). known = the sender's surname known from elsewhere.
local function apply(ctx, m, short, full, t, known)
  local st, kind = ctx.stats, m.kind
  if ctx == GCTX and (setting("receive") ~= true or not list) then return end
  if kind == "K" or kind == "R" then
    if not owns(m.victim, short, known) then
      st.dropped = st.dropped + 1; st.lastReason = "victim"
      return
    end
    local res, e, deed = P.Merge(ctx.store, m, short, { maxPerSender = C.MAX_PER_SENDER, protect = myName() })
    if res ~= "new" then
      if res == "cap" then st.dropped = st.dropped + 1; st.lastReason = "cap" end
      return
    end
    setHook()
    updated()
    if kind == "K" and t - m.t <= C.FRESH and setting("announce") == true and mayAnnounce(full, t) then
      ns:Fire("GUILD_KILL", deed, e.key, ctx.src)
    end
  elseif kind == "M" or kind == "X" then
    local isM = kind == "M"
    if isM then st.listReceived = st.listReceived + 1 else st.unlistReceived = st.unlistReceived + 1 end
    if not owns(m.by, short, known) then
      st.dropped = st.dropped + 1; st.lastReason = "by"
      if isM then st.listDropped = st.listDropped + 1 else st.unlistDropped = st.unlistDropped + 1 end
      return
    end
    local res
    if isM then
      res = P.MergeListed(ctx.store, m, short,
        { maxPerSender = C.MAX_PER_SENDER, maxListed = C.LISTED_MAX, protect = myName() })
      if res == "cap" then
        st.dropped = st.dropped + 1; st.listDropped = st.listDropped + 1; st.lastReason = "cap"
      end
      if res ~= "new" and res ~= "add" and res ~= "upd" then return end
    else
      res = P.Unlist(ctx.store, m.key, m.by)
      if not res then return end
    end
    setHook()
    updated()
  elseif kind == "S" then
    if setting("sightings") ~= true then return end
    local e = ctx.store.enemies[m.key]
    local h = ctx.hunts and ctx.hunts[m.key]
    local fresh = false
    if e and not (e.lastSeen and (e.lastSeen.t or 0) >= m.t) then
      e.lastSeen = { t = m.t, zone = m.zone, by = short }; fresh = true
    end
    if h and not (h.lastSeen and (h.lastSeen.t or 0) >= m.t) then
      h.lastSeen = { t = m.t, zone = m.zone, by = short }; fresh = true
    end
    if not fresh then return end
    updated()
    ns:Fire("GUILD_SIGHTING", m.key, m.zone, short, ctx.src)
  elseif kind == "Z" then
    if not owns(m.by, short, known) then st.dropped = st.dropped + 1; st.lastReason = "by"; return end
    if applySnapshot(ctx, m, short, full) then setHook(); updated() end
  elseif kind == "J" or kind == "A" or kind == "E" then
    local hunts = ctx.hunts
    if not hunts then return end
    if not owns(m.by, short, known) then
      st.dropped = st.dropped + 1; st.lastReason = "by"
      return
    end
    st.huntReceived = (st.huntReceived or 0) + 1
    if kind == "J" then
      noteAnswered(ctx, full, m.key)
      local age = expireAge()
      if age and m.t < t - age then st.dropped = st.dropped + 1; st.lastReason = "old"; return end
      -- cleared by the player (1.2.0): the same release does not come back with the next answer
      local cl = ctx.cleared and ctx.cleared[m.key]
      if cl and type(cl[m.by]) == "number" and m.t <= cl[m.by] then st.dropped = st.dropped + 1; st.lastReason = "cleared"; return end
      -- a new release of this sender (not an update of his own): answer or live cap
      local h, owner, have = hunts[m.key], short:lower(), false
      if h then for c, r in pairs(h.by) do if P.OwnerOf(c, r) == owner then have = true; break end end end
      local mode = "upd"
      if not have then
        mode = mayTakeRelease(ctx, full, t)
        if not mode then st.dropped = st.dropped + 1; st.lastReason = "later"; return end
      end
      local res = P.MergeHunt(hunts, m, { maxPerSender = C.HUNT_PER_SENDER, maxTotal = C.HUNT_MAX, via = short,
        protect = isOwnChar })
      if res == "cap" then st.dropped = st.dropped + 1; st.lastReason = "cap"; return end
      if res ~= "new" and res ~= "add" and res ~= "upd" then return end
      setHook()
      updated()
      -- new targets of others: always one collective notice, also from an answer (1.2.0)
      if mode ~= "upd" and (res == "new" or res == "add") then noticeNew(m.key, m.by, ctx.src) end
    elseif kind == "A" then
      -- a call-off on GUILD also takes back the copy of the same char's release in the friends' book (a friend
      -- who became a guildmate hears neither A nor Z by whisper any more)
      local fh = ctx == GCTX and fhunts() or nil
      local gone = P.CallOffHunt(hunts, m.key, m.by)
      if fh and fh ~= hunts and P.CallOffHunt(fh, m.key, m.by) then gone = true end
      if not gone then return end
      setHook()
      updated()
    else
      -- live only (E is never part of an answer): a kill older than 10 minutes or from the future is
      -- dropped, a sender reports at most BAG_PER_SENDER kills in BAG_WINDOW
      if t - m.t > C.BAG_FRESH or m.t - t > C.FUTURE then st.dropped = st.dropped + 1; st.lastReason = "time"; return end
      if not hunts[m.key] then return end
      if not mayTakeBag(ctx, full, t) then st.dropped = st.dropped + 1; st.lastReason = "flood"; return end
      if not P.BagHunt(hunts, m.key, m.by, m.t) then return end
      countBag(ctx, full)
      updated()
      fireBagged(m.key, m.by, m.t, ctx.src)
    end
  end
end

-- Hot path: every addon message of every addon arrives here. Foreign prefixes leave after one
-- comparison; WHISPER goes to Friends.lua (which drops non-friends before decoding).
function Guild.OnAddonMessage(_, prefix, text, channel, sender)
  if IsSecret(prefix) or prefix ~= PREFIX then return end
  if IsSecret(channel) or IsSecret(text) or type(text) ~= "string" then return end
  if channel ~= "GUILD" then
    if channel == "WHISPER" and friends then friends.OnWhisper(text, sender) end
    return
  end
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
  -- 1.2.0: which name form the client gives (probe: "full" = with surname, "first" = first name only)
  stats.senderForm = short:find(" ", 1, true) and "full" or "first"
  if not inGuild() then return end
  if not list then bind() end
  noteMember(short, full, m.version)
  if m.kind == "H" then
    -- 1.2.0: the hello of another member no longer opens the answer window (only the own one does)
    if friends and friends.OnMateHello then friends.OnMateHello(short) end
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
  apply(GCTX, m, short, full, t, not short:find(" ", 1, true) and rosterSurname(short) or nil)
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
  local fe = friends and friends.store.enemies[key]
  local hg = GH and GH[key]
  local fh = friends and friends.hunts()[key]
  if not (e or fe or hg or fh) then return end
  -- 1.2.0: data of a bound friend in a conflict stays, but does not alarm
  if (fe or fh) and friends.AnyMuted() then fe, fh = Guild.Unmuted(fe, fh) end
  local gt = GetTime()
  if not seenWrite[key] or gt - seenWrite[key] >= C.SEEN_WRITE then
    seenWrite[key] = gt
    local zone = Util.Zone()
    local t, me = now(), myName()
    if e then e.lastSeen = { t = t, zone = zone, by = me } end
    if fe then fe.lastSeen = { t = t, zone = zone, by = me } end
    if hg then hg.lastSeen = { t = t, zone = zone, by = me } end
    if fh then fh.lastSeen = { t = t, zone = zone, by = me } end
    updated()
    if setting("sightings") == true and (not sightSent[key] or gt - sightSent[key] >= C.SIGHT_SEND) then
      sightSent[key] = gt
      local text = P.EncodeSight(key, zone, t)
      if (e or hg) and canSend() then enqueue(text) end
      if (fe or fh) and friends then friends.Broadcast(text, "S") end
    end
  end
  if spotFrame[key] == gt then return end
  -- a target of the hunt list: its own switch, no kill threshold (that is the point of the list).
  -- Also when it stands in the own book (1.2.0 fix): the alarm decides there (Alert.GuildSpotted):
  -- pardoned wins (no alarm), an own alarm that fires names the hunt list, else the hunt alarm.
  if (hg or fh) and setting("alertHunt") == true and not hiddenOf(key) then
    if type(listed) == "table" and listed.status == "pardoned" then return end
    spotFrame[key] = gt
    ns:Fire("GUILD_ENEMY_SPOTTED", key, unit, how, "hunt")
    return
  end
  if listed then return end
  if not (e or fe) or setting("alert") ~= true then return end
  local x = Guild.Get(key, "all") or e or fe
  if (x.kills or 0) == 0 then
    -- listed by hand only: an alarm only when switched on, no kill threshold
    if setting("alertListed") ~= true then return end
  elseif (x.kills or 0) < (tonumber(setting("minKills")) or 1) then
    return
  end
  spotFrame[key] = gt
  ns:Fire("GUILD_ENEMY_SPOTTED", key, unit, how)
end

-- the parts of a friends' entry and a friends' release that do not come only from muted chars (else nil)
function Guild.Unmuted(fe, fh)
  local M = friends.Muted
  if fe then
    local other = false
    for i = 1, #fe.deeds do if not M(fe.deeds[i].victim) then other = true; break end end
    if not other and fe.listedBy then for c in pairs(fe.listedBy) do if not M(c) then other = true; break end end end
    if not other then fe = nil end
  end
  if fh then
    local other = false
    for c in pairs(fh.by) do if not M(c) then other = true; break end end
    if not other then fh = nil end
  end
  return fe, fh
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

-- Sources (1.2.0): "guild" (default), "friends" or "all". The same enemy in both lists is one
-- entry in "all" (deeds and listings joined, the same deed once).
local EMPTY_STORE = { enemies = {}, count = 0 }
-- default "guild" (the API of 1.1.0); the book's fourth tab asks with its chosen source
local function srcOf(s) return (s == "friends" or s == "all") and s or "guild" end
Guild.SourceOf = srcOf

function P.MergeEntries(a, b)
  local e = { key = a.key, name = a.name, surname = a.surname, class = a.class or b.class,
    level = a.level or b.level, by = a.by, deeds = {}, both = true }
  e.display = (type(b.display) == "string" and #b.display > #(a.display or "")) and b.display or a.display
  local deeds, seen = e.deeds, {}
  for pass = 1, 2 do
    local src = pass == 1 and a.deeds or b.deeds
    for i = 1, #src do
      local d = src[i]
      local id = tostring(d.t) .. "\t" .. tostring(d.victim)
      if not seen[id] then seen[id] = true; deeds[#deeds + 1] = d end
    end
  end
  table.sort(deeds, function(x, y) return x.t > y.t end)
  if a.listedBy or b.listedBy then
    local lb = {}
    for pass = 1, 2 do
      local src = (pass == 1 and a.listedBy or b.listedBy) or EMPTY_STORE.enemies
      for char, t in pairs(src) do if not lb[char] or t > lb[char] then lb[char] = t end end
    end
    e.listedBy = lb
  end
  local la, lb2 = a.lastSeen, b.lastSeen
  e.lastSeen = (la and lb2) and ((la.t or 0) >= (lb2.t or 0) and la or lb2) or la or lb2
  P.Recompute(e)
  return e
end

local function view(src)
  if src == "guild" then return store end
  local fs = friends and friends.store
  if src == "friends" then return fs or EMPTY_STORE end
  if not fs or (fs.count or 0) == 0 then return store end
  if store.count == 0 then return fs end
  local v = views.all
  if v then return v end
  v = { enemies = {}, count = 0 }
  for k, e in pairs(store.enemies) do v.enemies[k] = e; v.count = v.count + 1 end
  for k, e in pairs(fs.enemies) do
    local g = v.enemies[k]
    if g then v.enemies[k] = P.MergeEntries(g, e) else v.enemies[k] = e; v.count = v.count + 1 end
  end
  views.all = v
  return v
end

-- opts (additive): { only = "kills" } entries with kills, { only = "listed" } entries listed
-- by hand only; { foreign = true } (1.1.0) only entries in which another character than the
-- logged-in one takes part (see P.Foreign); { source = "guild" | "friends" | "all" } (1.2.0,
-- default "guild"). Without opts: all entries, those listed by hand only at the end of "rank".
function Guild.List(sort, opts)
  sort = P.SORTS[sort] and sort or "rank"
  local o = type(opts) == "table" and opts or nil
  local only = o and (o.only == "kills" or o.only == "listed") and o.only or nil
  local foreign = o ~= nil and o.foreign == true
  local src = srcOf(o and o.source)
  local ck = src .. "/" .. sort .. "/" .. (only or "") .. (foreign and "/f" or "")
  local out = listCache[ck]
  if not out then
    out = P.Sorted(view(src).enemies, sort, only)
    if foreign then
      local mine = myFullName()
      local f = {}
      for i = 1, #out do if P.Foreign(out[i], mine) then f[#f + 1] = out[i] end end
      out = f
    end
    markMine(out)
    listCache[ck] = out
  end
  return out
end

function Guild.Get(key, src)
  if type(key) ~= "string" then return nil end
  src = srcOf(src)
  local e
  local fs = src == "all" and friends and friends.store or nil
  if fs and not views.all and (fs.count or 0) > 0 and store.count > 0 then
    -- the merged view of both lists is not built (something changed since the last look): this one entry
    -- alone, instead of merging every entry that stands in both lists (the alarm asks at every sighting)
    local g, f = store.enemies[key], fs.enemies[key]
    e = (g and f) and P.MergeEntries(g, f) or g or f
  else
    e = view(src).enemies[key]
  end
  if e then e.mine = (ns.Store and ns.Store.Get(key)) and true or false end
  return e
end

-- where an entry comes from: "guild", "friends", "both" or nil
function Guild.Source(key)
  if type(key) ~= "string" then return nil end
  local g = store.enemies[key] ~= nil
  local f = friends ~= nil and friends.store.enemies[key] ~= nil
  return (g and f and "both") or (g and "guild") or (f and "friends") or nil
end

function Guild.Rank(key, src)
  src = srcOf(src)
  if type(key) ~= "string" or not view(src).enemies[key] then return nil end
  if not rankCache then rankCache = {} end
  local rc = rankCache[src]
  if not rc then
    rc = {}
    local l = Guild.List("rank", { source = src })
    for i = 1, #l do rc[l[i].key] = i end
    rankCache[src] = rc
  end
  return rc[key]
end

-- enemies, deeds, entries listed by hand only (no kills), foreign entries (1.1.0: another
-- character than the logged-in one takes part, as victim or in listedBy; see P.Foreign)
function Guild.Count(src)
  local deeds, listed, foreign = 0, 0, 0
  local mine = myFullName()
  local v = view(srcOf(src))
  for _, e in pairs(v.enemies) do
    deeds = deeds + #e.deeds
    if #e.deeds == 0 then listed = listed + 1 end
    if P.Foreign(e, mine) then foreign = foreign + 1 end
  end
  return v.count or 0, deeds, listed, foreign
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

-- lastHeard/hasAddon of every section from the members tables (cheap, no rebuild)
local function fillHeard(out)
  local heard = {}
  local function take(members)
    for _, m in pairs(members) do
      local k = memberKey(m.name)
      if k and type(m.lastHeard) == "number" and (not heard[k] or m.lastHeard > heard[k]) then heard[k] = m.lastHeard end
    end
  end
  if list then take(list.members) end
  if friends then take(friends.members()) end
  for i = 1, #out do
    local g = out[i]
    g.lastHeard = heard[memberKey(g.name) or ""]
    g.hasAddon = g.me or g.lastHeard ~= nil
  end
end

-- char -> "guild" | "friends" | "both": where a section of "Nach Kollege" comes from
local function charSources(src)
  local out = {}
  local function mark(st, tag)
    for _, e in pairs(st.enemies) do
      for i = 1, #e.deeds do
        local v = e.deeds[i].victim
        if v then out[v] = (out[v] and out[v] ~= tag) and "both" or tag end
      end
      if e.listedBy then
        for c in pairs(e.listedBy) do out[c] = (out[c] and out[c] ~= tag) and "both" or tag end
      end
    end
  end
  if src ~= "friends" then mark(store, "guild") end
  if src ~= "guild" and friends then mark(friends.store, "friends") end
  return out
end

-- Grouped by the member who died / listed (1.1.0). Cached per source; rebuilt only after a
-- change. Sections carry src = "guild" | "friends" | "both" (1.2.0). Not to be changed by callers.
function Guild.ByMember(src)
  src = srcOf(src)
  if not memberCache then memberCache = {} end
  local mc = memberCache[src]
  if mc then
    if mc.mv ~= membersVersion then
      fillHeard(mc.list)
      mc.mv = membersVersion
    end
    return mc.list
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
  local enemies = view(src).enemies
  for key, e in pairs(enemies) do
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
  -- 1.2.0: sections of friends listed without surname carry their tie (bound, contested); both names
  -- of a conflict get a section, also without data, so the player can choose there
  if src ~= "guild" and friends and friends.TieIndex then
    local idx = friends.TieIndex()
    for _, info in pairs(idx) do
      if info.conflict then group(info.full); group(info.rival) end
    end
    for i = 1, #out do
      local g = out[i]
      if not g.me and type(g.name) == "string" then g.tie = idx[g.name:lower()] end
    end
  end
  local cs = charSources(src)
  for i = 1, #out do
    table.sort(out[i].rows, rowLess)
    out[i].src = not out[i].me and (cs[out[i].name] or (out[i].tie and "friends")) or nil
  end
  table.sort(out, memberLess)
  fillHeard(out)
  local Store = ns.Store
  for _, e in pairs(enemies) do e.mine = (Store and Store.Get(e.key)) and true or false end
  memberCache[src] = { list = out, mv = membersVersion }
  return out
end

-- Members heard with DeathNote: the guild's (default) or, with src = "friends", the friends'.
function Guild.Members(src)
  if src == "friends" then return friends and friends.MemberList() or {} end
  local out = {}
  if not list then return out end
  for full, m in pairs(list.members) do
    out[#out + 1] = { name = m.name, full = full, version = m.version, lastHeard = m.lastHeard }
  end
  table.sort(out, function(a, b) return (a.lastHeard or 0) > (b.lastHeard or 0) end)
  return out
end

-- Is `short` (sender form) a guild member heard with DeathNote? (a friend in the own guild hears
-- everything on GUILD and gets no whispers)
-- 1.2.0 fix: "guildmate" is who is in the guild now: the game's guild roster where the client has it
-- (a friend who left the guild is served by whisper again at the next roster read); without the
-- roster API a member heard on GUILD in the last MATE_RECENT seconds (no longer 60 days).
-- 1.2.0: a guildmate is only who matches with the full name (first name and surname). Without a
-- surname, or when the roster gives first names only and nobody with exactly this full name was heard on
-- GUILD lately, the equal first name is no proof: in doubt the friend is served as a friend (whispers;
-- doubles are merged on receipt).
local function fullEq(a, b)
  if type(a) ~= "string" or type(b) ~= "string" then return false end
  local fa, sa = splitName(a)
  local fb, sb = splitName(b)
  return sa ~= nil and sb ~= nil and fa:lower() == fb:lower() and sa:lower() == sb:lower()
end
function Guild.IsGuildmate(short)
  if IsSecret(short) or type(short) ~= "string" or not inGuild() then return false end
  local f, s1 = splitName(short)
  if not s1 then return false end
  local r = rosterNow()
  if r then
    local x = r[f:lower()]
    if not x then return false end
    if x[s1:lower()] then return true end
    if not x[""] then return false end
  end
  -- the roster gives only first names (or there is no roster API): the full name heard on GUILD lately
  if not list then return false end
  local t = now()
  for _, m in pairs(list.members) do
    if type(m.lastHeard) == "number" and t - m.lastHeard <= C.MATE_RECENT and fullEq(short, m.name) then return true end
  end
  return false
end

-- heard on GUILD with DeathNote at all (members table): a guildmate who can take whispers of the
-- friends' list (only releases for friends go that way, see Friends.Broadcast)
function Guild.HasAddon(short)
  if not list or IsSecret(short) or type(short) ~= "string" then return false end
  local f, s1 = splitName(short)
  for _, m in pairs(list.members) do if sameName(f, s1, m.name) then return true end end
  return false
end

---------------------------------------------------------------------------
-- Hunt list views (1.2.0)
---------------------------------------------------------------------------
local function huntLess(a, b)
  -- hidden "for me" (1.2.0 fix): pale at the end of the list
  if (a.hidden or false) ~= (b.hidden or false) then return not a.hidden end
  if a.n ~= b.n then return a.n > b.n end
  local sa, sb = a.lastSeen and a.lastSeen.t or 0, b.lastSeen and b.lastSeen.t or 0
  if sa ~= sb then return sa > sb end
  local na, nb = (a.display or a.key):lower(), (b.display or b.key):lower()
  if na ~= nb then return na < nb end
  return a.key < b.key
end

local function releaseLess(a, b)
  if a.t ~= b.t then return a.t < b.t end
  return a.char < b.char
end

-- One row per target: { key, name, surname, display, class, level, n (releases), names (chars,
-- oldest release first), releases = { { char, t, why } }, since, last, why (newest reason),
-- lastSeen, bagged, lastBagged, src ("guild" | "friends" | "both"), mine (own release) }.
-- the stored target `h` of the list `tag` goes into the row r (seen: char -> release in this row);
-- first = r was made from this very h
local function huntRowAdd(r, seen, h, tag, first)
  if not first then
    if r.src ~= tag then r.src = "both" end
    r.class = r.class or h.class
    r.level = r.level or h.level
    if type(h.display) == "string" and #h.display > #(r.display or "") then r.display = h.display end
  end
  for char, x in pairs(h.by) do
    local have = seen[char]
    if not have then
      have = { char = char, t = x.t, why = x.why }
      seen[char] = have
      r.releases[#r.releases + 1] = have
    elseif x.t > have.t then
      have.t, have.why = x.t, x.why
    end
  end
  -- kills summed per list; the same kill in both lists (own kill) counts once
  local lb, plb = h.lastBagged, r.lastBagged
  r.bagged = r.bagged + (h.bagged or 0)
  if lb and plb and lb.by == plb.by and math.abs(lb.t - plb.t) < C.BAG_DEDUPE then r.bagged = r.bagged - 1 end
  if lb and (not plb or lb.t > plb.t) then r.lastBagged = lb end
  local ls = h.lastSeen
  if ls and (not r.lastSeen or (ls.t or 0) > (r.lastSeen.t or 0)) then r.lastSeen = ls end
end

local function huntRowNew(key, h, tag)
  return { key = key, name = h.name, surname = h.surname, display = h.display, class = h.class, level = h.level,
    releases = {}, bagged = 0, src = tag }
end

-- the derived fields of a row once all its releases are in
local function huntRowDone(r, mine)
  r.hidden = hiddenOf(r.key) or nil
  table.sort(r.releases, releaseLess)
  r.n = #r.releases
  r.since, r.last = r.releases[1].t, r.releases[r.n].t
  r.names = {}
  for k = 1, r.n do
    local x = r.releases[k]
    r.names[k] = x.char
    if x.why then r.why = x.why end      -- the newest reason wins
    if x.char == mine then r.mine = true end
  end
end

local function huntRows(src)
  local rows = huntCache[src]
  if rows then return rows end
  rows = {}
  local byKey, rel = {}, {}
  local function add(hunts, tag)
    if not hunts then return end
    for key, h in pairs(hunts) do
      local r = byKey[key]
      local first = r == nil
      if first then
        r = huntRowNew(key, h, tag)
        byKey[key] = r
        rel[key] = {}
        rows[#rows + 1] = r
      end
      huntRowAdd(r, rel[key], h, tag, first)
    end
  end
  if src ~= "friends" then add(GH, "guild") end
  if src ~= "guild" then add(fhunts(), "friends") end
  local mine = myFullName()
  for i = 1, #rows do huntRowDone(rows[i], mine) end
  table.sort(rows, huntLess)
  huntCache[src] = rows
  huntIndex[src] = byKey
  return rows
end

function Guild.Hunts(src) return huntRows(srcOf(src)) end
function Guild.HuntCount(src) return #huntRows(srcOf(src)) end
-- One target. While the list of the source is built, its row; else (something changed since the last look:
-- a sighting, a message) the row is put together for this one key alone, without building and sorting
-- the whole list (the alarm asks at every sighting).
function Guild.Hunt(key, src)
  if type(key) ~= "string" then return nil end
  src = srcOf(src)
  if huntCache[src] then return huntIndex[src][key] end
  local g = src ~= "friends" and GH and GH[key] or nil
  local fh = src ~= "guild" and fhunts() or nil
  local f = fh and fh[key] or nil
  local r, seen
  if g then
    r, seen = huntRowNew(key, g, "guild"), {}
    huntRowAdd(r, seen, g, "guild", true)
  end
  if f then
    if r then
      huntRowAdd(r, seen, f, "friends", false)
    else
      r, seen = huntRowNew(key, f, "friends"), {}
      huntRowAdd(r, seen, f, "friends", true)
    end
  end
  if not r or #r.releases == 0 then return nil end
  huntRowDone(r, myFullName())
  return r
end

function Guild.Clear()
  if not gdb then return end
  local fresh = {}
  if list then list.enemies = fresh end
  gdb.enemies = fresh
  store.enemies, store.count, store.bySender, store.listedBySender = fresh, 0, {}, {}
  seenWrite, sightSent = {}, {}
  -- 1.2.0 fix: the hunt list of this guild goes too (the releases of others; own releases stay,
  -- only their releaser can call them off)
  if list and list.hunts then
    if type(list.huntCleared) ~= "table" then list.huntCleared = {} end
    GCTX.cleared = list.huntCleared
    P.ClearForeign(list.hunts, isOwnChar, list.huntCleared)
  end
  setHook()
  updated()
end

-- Drops every release that is not of an own char (1.2.0: "Gildenbuch leeren", "Freundesbuch leeren").
-- cleared (1.2.0): { [key] = { [char] = release time } } remembers what was cleared, so the same
-- release does not come back with the next answer (a newer release of that char is a new act and is taken).
function P.ClearForeign(hunts, mine, cleared)
  local n = 0
  for key, h in pairs(hunts) do
    for c, r in pairs(h.by) do
      if not (mine and mine(c)) then
        if type(cleared) == "table" and type(r) == "table" and P.Finite(r.t) then
          cleared[key] = cleared[key] or {}
          cleared[key][c] = r.t
        end
        h.by[c] = nil; n = n + 1
      end
    end
    if next(h.by) == nil then hunts[key] = nil end
  end
  if type(cleared) == "table" then P.SanitizeCleared(cleared) end
  return n
end

-- broken entries out, at most CLEARED_MAX targets (the oldest releases leave first)
function P.SanitizeCleared(cleared)
  local n, oldKey, oldT = 0, nil, nil
  for key, x in pairs(cleared) do
    if type(key) ~= "string" or type(x) ~= "table" then
      cleared[key] = nil
    else
      local newest
      for c, t in pairs(x) do
        if type(c) ~= "string" or not P.Finite(t) then x[c] = nil
        elseif not newest or t > newest then newest = t end
      end
      if not newest then cleared[key] = nil else
        n = n + 1
        if not oldT or newest < oldT then oldKey, oldT = key, newest end
      end
    end
  end
  while n > C.CLEARED_MAX and oldKey do
    cleared[oldKey] = nil
    n = n - 1
    oldKey, oldT = nil, nil
    for key, x in pairs(cleared) do
      for _, t in pairs(x) do if not oldT or t < oldT then oldKey, oldT = key, t end end
    end
  end
end

-- Hide a target "for me" (on = true) or show it again (on = false): no alarm, pale at the end of
-- the list, nothing is sent. Returns the new state.
function Guild.HideHunt(key, on)
  if not gdb or IsSecret(key) or IsSecret(on) or type(key) ~= "string" or not P.ValidKey(key) then return false end
  if type(gdb.huntHidden) ~= "table" then gdb.huntHidden = {} end
  local hh = gdb.huntHidden
  if on == false then
    hh[key] = nil
  else
    hh[key] = now()
    local n, oldKey, oldT = 0, nil, nil
    for k, t in pairs(hh) do
      n = n + 1
      if not oldT or t < oldT then oldKey, oldT = k, t end
    end
    if n > C.HIDDEN_MAX then hh[oldKey] = nil end
  end
  invalidate()
  updated()
  return hh[key] ~= nil
end
function Guild.HuntHidden(key) return type(key) == "string" and hiddenOf(key) or false end

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
  if own and own.note == "" and own.fromGuildKills == nil then
    -- 1.2.0: only a mark is stored (no translated sentence in DeathNoteDB or the export); the
    -- sentence is built in the active language when shown (Util.NoteOf), until the player writes a note
    own.fromGuildKills = math.max(0, math.floor(tonumber(e.kills) or 0))
  end
  invalidate()
  return k
end

---------------------------------------------------------------------------
-- Hunt list actions (1.2.0): release ("Zur Jagd freigeben"), call off ("Jagd abblasen"), bagged
---------------------------------------------------------------------------
local function remember(tombs, key, by)
  tombs[key] = { t = now(), by = by }
  local n, oldKey, oldT = 0, nil, nil
  for k, x in pairs(tombs) do
    n = n + 1
    if not oldT or x.t < oldT then oldKey, oldT = k, x.t end
  end
  if n > C.TOMB_MAX then tombs[oldKey] = nil end
end

-- Expiry (1.2.0): repairs a hunt table and calls off the expired releases of the logged-in char
-- like "abblasen" does (remembered for the answers, call-off sent), so they do not stay forever with the others.
-- src = "guild" | "friends". Returns the number called off.
function Guild.ExpireHunts(hunts, tombs, src)
  if type(hunts) ~= "table" then return 0 end
  local o = Guild.HuntOpts()
  o.self, o.expired = myFullName(), {}
  P.SanitizeHunts(hunts, now(), o)
  for i = 1, #o.expired do
    local x = o.expired[i]
    P.CallOffHunt(hunts, x.key, x.char)
    if type(tombs) == "table" then remember(tombs, x.key, x.char) end
    local text = P.EncodeCallOff(x.key, x.char)
    if src == "friends" then
      if friends then friends.Broadcast(text, "A") end
    elseif canSend() then
      enqueue(text, "A")
    end
  end
  return #o.expired
end

-- Name, class and level of a target: own book first, then the shared lists and the hunt list.
local function targetInfo(key)
  local n, s = P.ValidKey(key)
  if not n then return nil end
  local info = { key = key, name = n, surname = s }
  local Store = ns.Store
  local e = Store and Store.Get(key)
  local x = e or Guild.Get(key, "all") or Guild.Hunt(key, "all")
  if x then
    info.display = e and Util.Display(e) or x.display
    info.class = type(x.class) == "string" and x.class:match("^%u+$") and x.class or nil
    info.level = type(x.level) == "number" and x.level or nil
  end
  if type(info.display) ~= "string" or info.display == "" then info.display = n .. " " .. s end
  return info
end

-- Key for typed input ("/dn jagd Name [Nachname]"): own book, hunt list, shared lists (a unique
-- first name is enough there), else the full name as typed (a surname is needed then).
function Guild.FindTarget(text)
  if type(text) ~= "string" or IsSecret(text) then return nil end
  text = text:gsub("^%s+", ""):gsub("%s+$", "")
  if text == "" then return nil end
  local Store = ns.Store
  local k = Store and Store.Find and Store.Find(text)
  if k and P.ValidKey(k) then return k end
  local key, n, _, hadSurname = Util.KeyFor(text)
  if not key then return nil end
  local all = view("all").enemies
  if all[key] or Guild.Hunt(key, "all") then return key end
  local found
  local first = n:lower()
  local function try(x, kk)
    if type(x.name) == "string" and x.name:lower() == first then
      if found and found ~= kk then found = false elseif found == nil then found = kk end
    end
  end
  if not hadSurname then
    for kk, x in pairs(all) do try(x, kk) end
    for _, r in ipairs(Guild.Hunts("all")) do try(r, r.key) end
    if found then return found end
    return nil
  end
  return P.ValidKey(key) and key or nil
end

-- Where a release can go right now: guild (in a guild, sharing on), friends (sharing with friends on).
function Guild.HuntTargets()
  local g = Guild.Enabled() and guildNameNow() ~= nil
  local f = friends ~= nil and friends.Enabled() == true
  return g, f
end

-- Is "name surname" one of us: an own char, or a guildmate / friend heard with DeathNote (the
-- members of both books)? 1.2.0: only the full name counts; a member heard with the first name
-- only is no proof (in doubt the release is allowed: a namesake enemy must stay releasable).
function Guild.WhoIs(n, s)
  if IsSecret(n) or IsSecret(s) or type(n) ~= "string" then return nil end
  if s ~= nil and type(s) ~= "string" then s = nil end
  local full = s and (n .. " " .. s) or n
  local me = myFullName()
  if isOwnChar(full) or (me and me:lower() == full:lower()) then return "self" end
  if not s then return nil end
  if list then for _, m in pairs(list.members) do if fullEq(full, m.name) then return "mate" end end end
  if friends then for _, m in pairs(friends.members()) do if fullEq(full, m.name) then return "mate" end end end
  return nil
end

-- Releases `key` for the hunt. opts = { to = "all" | "guild" | "friends", why = reason }.
-- Returns guildDone, friendsDone or nil, reason ("key" | "me" | "none" | "cap" | "self" | "mate").
-- 1.2.0 fix: the own chars and guildmates or friends heard with DeathNote cannot be released.
function Guild.Release(key, opts)
  local info = type(key) == "string" and not IsSecret(key) and targetInfo(key)
  if not info then return nil, "key" end
  local mine = myFullName()
  if not mine then return nil, "me" end
  local who = Guild.WhoIs(info.name, info.surname)
  if who then return nil, who end
  if type(opts) == "table" and IsSecret(opts.why) then opts = { to = opts.to } end
  local to = type(opts) == "table" and opts.to or "all"
  local canG, canF = Guild.HuntTargets()
  if canG then bind(); canG = list ~= nil end
  local wantG = canG and (to == "all" or to == "guild")
  local wantF = canF and (to == "all" or to == "friends")
  if not wantG and not wantF then return nil, "none" end
  local m = { key = key, name = info.name, surname = info.surname, display = info.display, class = info.class,
    level = info.level, t = now(), by = mine, why = P.CleanReason(type(opts) == "table" and opts.why or nil), b = book }
  local o = { maxPerSender = C.HUNT_PER_SENDER, maxTotal = C.HUNT_MAX, protect = isOwnChar }
  local doneG, doneF = false, false
  if wantG then
    local res = P.MergeHunt(list.hunts, m, o)
    if res and res ~= "cap" then
      doneG = true
      list.huntOff[key] = nil
      if res ~= "dup" then enqueue(P.EncodeHunt(m), "J") end
    end
  end
  if wantF then
    local res = P.MergeHunt(friends.hunts(), m, o)
    if res and res ~= "cap" then
      doneF = true
      friends.huntOff()[key] = nil
      -- only for friends: friends in the own guild get it by whisper too (they hear no friends' list)
      if res ~= "dup" then friends.Broadcast(P.EncodeHunt(m), "J", not doneG) end
    end
  end
  if not doneG and not doneF then return nil, "cap" end
  setHook()
  updated()
  return doneG, doneF
end

-- Takes back the own release (to = nil: everywhere). true when something was called off.
function Guild.CallOff(key, to)
  local mine = myFullName()
  if type(key) ~= "string" or not mine then return false end
  local done = false
  local hg = list and list.hunts
  if to ~= "friends" and hg and hg[key] and hg[key].by[mine] then
    P.CallOffHunt(hg, key, mine)
    remember(list.huntOff, key, mine)
    if canSend() then enqueue(P.EncodeCallOff(key, mine), "A") end
    done = true
  end
  local inG = done
  local fh = fhunts()
  if to ~= "guild" and fh and fh[key] and fh[key].by[mine] then
    P.CallOffHunt(fh, key, mine)
    remember(friends.huntOff(), key, mine)
    friends.Broadcast(P.EncodeCallOff(key, mine), "A", not inG)
    done = true
  end
  if done then setHook(); updated() end
  return done
end

-- calls off every own release of the logged-in char (both books). The call-offs go out through
-- the shared queue (gap, throttle). Returns the number of targets called off.
function Guild.CallOffAll()
  local mine = myFullName()
  if not mine then return 0 end
  local keys, seen = {}, {}
  for pass = 1, 2 do
    local hunts = pass == 1 and (list and list.hunts) or fhunts()
    if hunts then
      for key, h in pairs(hunts) do
        if h.by[mine] and not seen[key] then seen[key] = true; keys[#keys + 1] = key end
      end
    end
  end
  table.sort(keys)
  local n = 0
  for i = 1, #keys do if Guild.CallOff(keys[i]) then n = n + 1 end end
  return n
end

-- number of own releases of the logged-in char (both books, one per target)
function Guild.OwnReleaseCount()
  local mine = myFullName()
  local seen, n = {}, 0
  if not mine then return 0 end
  for pass = 1, 2 do
    local hunts = pass == 1 and (list and list.hunts) or fhunts()
    if hunts then for key, h in pairs(hunts) do if h.by[mine] and not seen[key] then seen[key] = true; n = n + 1 end end end
  end
  return n
end

-- Own release of `key`? -> inGuildList, inFriendsList
function Guild.Released(key)
  local mine = myFullName()
  if type(key) ~= "string" or not mine then return false, false end
  local hg, fh = list and list.hunts, fhunts()
  return (hg and hg[key] and hg[key].by[mine] and true) or false, (fh and fh[key] and fh[key].by[mine] and true) or false
end

local function isHunted(key)
  local fh = fhunts()
  return (GH and GH[key]) or (fh and fh[key]) or nil
end

-- Key of a killed player for the hunt list: tracker, own book, else a unique first name.
local function huntKeyForGUID(guid)
  local r = ns.Tracker and ns.Tracker.ByGUID and ns.Tracker.ByGUID(guid)
  if type(r) == "table" and type(r.key) == "string" and isHunted(r.key) then return r.key end
  local Store = ns.Store
  local k = Store and Store.ByGUID and Store.ByGUID(guid)
  if k and isHunted(k) then return k end
  local _, _, _, _, _, name = Call(_G.GetPlayerInfoByGUID, guid)
  name = Str(name)
  if not name then return nil end
  local first = (name:match("^([^%s%-]+)") or name):lower()
  local found
  for pass = 1, 2 do
    local hunts = pass == 1 and GH or fhunts()
    if hunts then
      for key, h in pairs(hunts) do
        if type(h.name) == "string" and h.name:lower() == first then
          if found and found ~= key then return nil end   -- two targets with this first name: unsure
          found = key
        end
      end
    end
  end
  return found
end

-- PARTY_KILL with my (or my pet's) GUID as attacker: a sure own killing blow, the same signal
-- that counts revenge. A target of the hunt list is "erlegt" in every list that hunts it.
function Guild.OnPartyKill(attackerGUID, targetGUID)
  if not anyHunt() then return false end
  attackerGUID, targetGUID = Str(attackerGUID), Str(targetGUID)
  if not attackerGUID or not targetGUID or not targetGUID:find("^Player%-") then return false end
  local meG, pet = Str(call1(_G.UnitGUID, "player")), Str(call1(_G.UnitGUID, "pet"))
  if attackerGUID ~= meG and attackerGUID ~= pet then return false end
  if not Util.IsOpenWorld() then return false end
  local key = huntKeyForGUID(targetGUID)
  local mine = myFullName()
  if not key or not mine then return false end
  local t = now()
  local hit = false
  local inG = false
  if GH and GH[key] and P.BagHunt(GH, key, mine, t) then
    hit, inG = true, true
    if canSend() then enqueue(P.EncodeBagged(key, mine, t), "E") end
  end
  local fh = fhunts()
  if fh and fh[key] and P.BagHunt(fh, key, mine, t) then
    hit = true
    friends.Broadcast(P.EncodeBagged(key, mine, t), "E", not inG)
  end
  if not hit then return false end
  updated()
  fireBagged(key, mine, t, "self")
  return true
end

---------------------------------------------------------------------------
-- Bridge for Friends.lua (1.2.0): the same queue, protocol, own data and receiving path
---------------------------------------------------------------------------
Guild.Bridge = {
  enqueue = enqueue, apply = apply, answer = answer, updated = updated, setHook = setHook,
  ownKills = ownKills, ownListed = ownListed, listable = listable, listedMsg = listedMsg,
  addOwn = addOwn, addOwnListed = addOwnListed, myName = myName, myFullName = myFullName,
  holdReason = holdReason, prefixOK = function() return prefixOK end, setting = setting,
  remember = remember, canSendGuild = canSend, mayAnnounce = mayAnnounce, addonVersion = addonVersion,
  touchMembers = function() membersVersion = membersVersion + 1 end,
  ownHunts = ownHunts, ownTombs = ownTombs, released = function(key) return Guild.Released(key) end,
  huntOpts = function() return Guild.HuntOpts() end, fireBagged = fireBagged,
}

function Guild.AttachFriends(F)
  friends = F
  invalidate()
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
  -- hunt list (1.2.0): broken tables out; the releases are checked when the list is used
  if L.hunts ~= nil and type(L.hunts) ~= "table" then L.hunts = nil end
  if type(L.huntOff) == "table" then
    for key, x in pairs(L.huntOff) do
      if type(key) ~= "string" or type(x) ~= "table" or type(x.t) ~= "number" or type(x.by) ~= "string"
        or x.t < t - C.TOMB_AGE then
        L.huntOff[key] = nil
      end
    end
  elseif L.huntOff ~= nil then
    L.huntOff = nil
  end
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
  -- book id (1.2.0, additive): made once per SavedVariables, never sent alone
  if not P.ValidBook(gdb.book) then gdb.book = P.NewBook() end
  book = gdb.book
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
  -- targets hidden "for me" (1.2.0): { [key] = time }
  if type(gdb.huntHidden) ~= "table" then gdb.huntHidden = nil
  else
    for key, x in pairs(gdb.huntHidden) do
      if type(key) ~= "string" or not P.ValidKey(key) or not finite(x) then gdb.huntHidden[key] = nil end
    end
  end
  list, sanitized, GH = nil, {}, nil
  GCTX.hunts, GCTX.huntOff, GCTX.fresh, GCTX.helloAt, GCTX.cleared = nil, nil, {}, nil, nil
  roster, rosterAt, newRel, newPlanned = nil, nil, {}, false
  store.enemies, store.count, store.bySender, store.listedBySender = {}, 0, {}, {}
  if gdb.name and gdb.lists[gdb.name] then useList(gdb.name) end
  flood, queue, queued, reply, backfilled, lastSendAt = {}, {}, {}, nil, false, nil
  seenWrite, sightSent, spotFrame = {}, {}, {}
  helloFrom, announced, lastReplyAt, meFull = {}, {}, nil, nil
  for k in pairs(bagSeen) do bagSeen[k] = nil end
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
-- -> { ok = bool, reason = key, text = short sentence for players in the active language (<= 60 chars,
--      no technical words), short = button label (<= 24 chars), detail = technical note or nil }
-- Only `reason` is ever stored (probe); text and short are for the screen.
-- reason: "noguild" | "off" | "prefix" | "blocked" | "failing" | "hold" | "quiet" | "ok"
local HOLD_TEXT = { instance = "SYNC_HOLD_INSTANCE", combat = "SYNC_HOLD_COMBAT", lockdown = "SYNC_HOLD_LOCKDOWN" }
local HOLD_SHORT = { instance = "SYNC_HOLD_SHORT_INSTANCE", combat = "SYNC_HOLD_SHORT_COMBAT",
  lockdown = "SYNC_HOLD_SHORT_LOCKDOWN" }
local guildHealth
-- src (1.2.0): nil/"guild" the guild's state, "friends" the friends' (Friends.Health), "all" one
-- sentence for both (the not working one first, else both counts).
function Guild.Health(src)
  if src == "friends" then
    return friends and friends.Health() or { ok = false, reason = "off", short = L.HEALTH_SHORT_OFF,
      text = L.SYNC_FRIENDS_OFF }
  end
  if src ~= "all" or not friends then return guildHealth() end
  local g, f = guildHealth(), friends.Health()
  local gOn = g.reason ~= "noguild" and g.reason ~= "off"
  local fOn = f.reason ~= "off" and f.reason ~= "nofriends"
  if not gOn and not fOn then
    return { ok = false, reason = "nobody", short = L.SYNC_SHORT_NOBODY, text = L.SYNC_NOBODY }
  end
  if not gOn then return f end
  if not fOn then return g end
  if not g.ok then return g end
  if not f.ok then return f end
  if g.reason == "hold" then return g end
  local n, k = #Guild.Members(), friends.PeerCount()
  if n + k == 0 then return g end
  return { ok = true, reason = "ok", short = L.HEALTH_SHORT_ASKED, text = Fmt(L.SYNC_RUNNING_ALL, { count = n + k }) }
end

guildHealth = function()
  local h = {}
  if not inGuild() then
    h.ok, h.reason, h.short = false, "noguild", L.HEALTH_SHORT_NOGUILD
    h.text = L.HEALTH_NOGUILD
  elseif setting("share") ~= true then
    h.ok, h.reason, h.short = false, "off", L.HEALTH_SHORT_OFF
    h.text = L.SYNC_GUILD_OFF
  elseif prefixOK == false then
    h.ok, h.reason, h.short = false, "prefix", L.SYNC_SHORT_PREFIX
    h.text = L.SYNC_PREFIX
    h.detail = "RegisterAddonMessagePrefix: " .. tostring(stats.prefixResult)
  elseif stats.hardFail and stats.sent == 0 or (stats.failStreak or 0) >= 3 and stats.sent == 0 then
    h.ok, h.reason, h.short = false, "blocked", L.SYNC_SHORT_BLOCKED
    h.text = L.SYNC_BLOCKED
    h.detail = "SendAddonMessage: " .. tostring(stats.lastFail)
  elseif stats.hardFail or (stats.failStreak or 0) >= 3 then
    h.ok, h.reason, h.short = false, "failing", L.SYNC_SHORT_FAILING
    h.text = L.SYNC_FAILING
    h.detail = "SendAddonMessage: " .. tostring(stats.lastFail)
  else
    local why = holdReason()
    if why and #queue > 0 then
      h.ok, h.reason, h.short = true, "hold", HOLD_SHORT[why] and L[HOLD_SHORT[why]] or L.HEALTH_SHORT_HOLD
      h.text = Fmt(L.SYNC_HOLD, { wait = HOLD_TEXT[why] and L[HOLD_TEXT[why]] or L.SYNC_HOLD_AGAIN })
    elseif stats.sent > 0 and stats.received == 0 then
      h.ok, h.reason, h.short = true, "quiet", L.HEALTH_SHORT_ASKED
      h.text = L.SYNC_QUIET
    else
      h.ok, h.reason, h.short = true, "ok", L.HEALTH_SHORT_ASKED
      local n = list and #Guild.Members() or 0
      if n == 0 then
        h.text = L.SYNC_READY
      else
        h.text = Fmt(L.SYNC_RUNNING, { count = n })
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
  -- ask the server for the guild roster (GUILD_ROSTER_UPDATE follows), as OpenMap/Map/Friends.lua does
  if inGuild() then
    local GI = _G.C_GuildInfo
    if GI and GI.GuildRoster then Call(GI.GuildRoster) elseif _G.GuildRoster then Call(_G.GuildRoster) end
  end
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
  -- a shorter expiry applies at once (own and received releases; call-offs are not sent)
  if path == "guild.huntExpire" and expireAge() then
    if list and list.hunts then Guild.ExpireHunts(list.hunts, list.huntOff, "guild") end
    local fh = fhunts()
    if fh then Guild.ExpireHunts(fh, friends.huntOff(), "friends") end
    setHook()
    updated()
  end
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
-- hunt list: own killing blow on a target (cheap while the hunt list is empty)
ns:RegisterEvent("PARTY_KILL", function(_, a, t) Guild.OnPartyKill(a, t) end)
ns:RegisterEvent("PLAYER_GUILD_UPDATE", function()
  if not gdb then return end
  rosterAt = nil
  if bind() then setHook(); return end
  -- out of the guild (1.2.0 fix): its hunt list neither alarms nor shows, the views are rebuilt
  setHook()
  updated()
end)
-- the guild roster changed (somebody joined or left): read again on the next question; a moment later the
-- releases of members who left go (1.2.0; one read per burst of events). Other addons ask for the roster every
-- few seconds: it is only read again when the number of members changed or the last read is ROSTER_MIN old.
local leaversPlanned = false
ns:RegisterEvent("GUILD_ROSTER_UPDATE", function()
  local n = _G.GetNumGuildMembers and Util.Num(call1(_G.GetNumGuildMembers)) or nil
  if n ~= rosterN or not rosterAt or GetTime() - rosterAt >= C.ROSTER_MIN then rosterAt = nil end
  if leaversPlanned or not gdb then return end
  local After = _G.C_Timer and _G.C_Timer.After
  if not After then return end
  leaversPlanned = true
  After(2, function()
    leaversPlanned = false
    if GH then rosterNow(); Guild.PurgeLeavers() end
  end)
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
