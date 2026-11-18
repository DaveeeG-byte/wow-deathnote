-- DeathNote - Call.lua (1.6.0 call)
-- Guild, group and friends become useful to each other as soon as two of them have the book: one calls for help, one
-- sees the killer of the other. Logic only (wire, sending, receiving, the probe); the notice on the screen, the button
-- on the grudge notice, the clicks on the chat links and the map are CallUI.lua.
--
-- Help call: one invisible addon message under its own prefix (the game holds back bursts per prefix, so the book's
-- other messages never use up its room), sent at once on the key (Bindings.xml "HELP") or the button of the grudge
-- notice, past the book's send queue (that one waits in combat, Sync.lua holdReason). This way only minds the chat
-- lockdown and instances (dungeons, raids, battlegrounds, arenas: no call there) and reads the result code.
--   1 P map x y t key display      map ID, x and y in tenths of a percent (as L), time, the attacker (key and shown
--                                  name, both empty when there is none; a name without a key when the target has no
--                                  surname the book can read)
--   1 N t                          /dn probe net only: the test message on CHANNEL and YELL (counted, nothing else)
-- Ways: GUILD (in a guild), RAID or PARTY (in a group), each bound friend who answered with the book in this session
-- (WHISPER, else Battle.net). Cooldown COOLDOWN seconds. Received: only from GUILD, PARTY, RAID and from friends
-- (whisper of a name on the friend list, Battle.net), at most one call per sender per PER_SENDER seconds and
-- MINUTE_MAX calls per minute in all. Kept: the last RING calls (DeathNoteDB.call.calls).
--
-- Sighting T (Sync.lua carries it on prefix DeathNote, protocol 1, see its head): sent for an enemy who killed me or a
-- guildmate or friend in the last SIGHT_DAYS days (a sure kill), who is on a hit list or carries a bounty; at most once
-- per enemy per SIGHT_SEND seconds, after a random wait of WAIT_MIN..WAIT_MAX seconds, and not at all when a T for the
-- same enemy came in meanwhile. Received: only for enemies in my book, the guild's or the friends' book or a hit list;
-- lastSeen of the lists, a quiet chat line (no sound) at most once per enemy per SIGHT_LINE seconds, a pin for
-- SIGHT_PIN seconds. Switch guild.layerSight (on by default) for sending and receiving; 1.6.0 fix: it rules the old S
-- too (sent only for the enemies a T goes out for; guild.sightings is no longer read, Sync.lua).
--
-- What goes out is only one's own: one's own place and the enemy in sight. Attacks, notes, suspicion and anything
-- taken over are never sent. Nothing visible goes out unless the player clicks "Call in guild chat" (Share.lua's way).
-- Every error here is caught where the book calls in (Sync.lua pcall): the book, the alarm and the death detection
-- go on. Counters for the probe: DeathNoteDB.probe.call (never names).

local ADDON, ns = ...
local L, Fmt = ns.L, ns.F
local Util = ns.Util
local Guild = ns.Guild
if type(Guild) ~= "table" or type(Guild.Bridge) ~= "table" or type(Guild.Proto) ~= "table" then return end

local B, GP = Guild.Bridge, Guild.Proto
local Call_, IsSecret, Str, Num, True = Util.Call, Util.IsSecret, Util.Str, Util.Num, Util.True

local Call = {}
ns.Call = Call

local C = {
  PREFIX = "DeathNoteSOS", PROTO = "1",
  COOLDOWN = 30,            -- seconds between two own calls
  PER_SENDER = 30,          -- seconds: one call per sender
  MINUTE_MAX = 5,           -- calls per minute in all
  RING = 20,                -- calls kept (DeathNoteDB.call.calls)
  AGE = 300,                -- a call older than this (sender's clock) is stale
  FRESH = 180,              -- seconds a call pulses on the map
  SIGHT_SEND = 120, WAIT_MIN = 2, WAIT_MAX = 6,
  SIGHT_LINE = 300,         -- one chat line per enemy in this time
  SIGHT_PIN = 600,          -- seconds a sighting stands on the map
  SIGHT_DAYS = 30,
  SIGHT_RING = 20,          -- sightings kept for the map (this session)
  SHARD_TTL = 600,          -- seconds a layer mark read from a creature stays valid
  SHARD_GAP = 15,           -- seconds between two reads of the layer mark
  CODES_MAX = 12,           -- different result codes counted per way (probe)
  NAME_MAX = 48,            -- bytes of the attacker's shown name
  LINKS = 40,               -- chat links kept for a click
  NET_CHANNEL = "RBkNetProbe", NET_STAY = 120, NET_WAIT = 2,
  HEARD_MAX = 999,
}
Call.C = C

local function now() return time() end
local function After(d, fn)
  local A = _G.C_Timer and _G.C_Timer.After
  if A then A(d, fn) else fn() end
end
local function inCombat() return True(Call_(_G.InCombatLockdown)) end

---------------------------------------------------------------------------
-- Probe (DeathNoteDB.probe.call): counters, result codes per way, the net test, the guild chat echo
---------------------------------------------------------------------------
local COUNTS = { "sent", "sendRefused", "received", "dropped", "dup", "flood", "stranger", "sightSent", "sightQuiet",
  "sightNoPlace", "sightReceived", "sightUnknown", "sightLine", "shardSeen", "secret",
  "quiet" }
Call.COUNTS = COUNTS
local COUNT_OK = {}
for _, k in ipairs(COUNTS) do COUNT_OK[k] = true end

function Call.Probe()
  local db = ns.Store and ns.Store.DB and ns.Store.DB()
  if type(db) ~= "table" then return nil end
  if type(db.probe) ~= "table" then db.probe = {} end
  local p = db.probe.call
  if type(p) ~= "table" then p = {}; db.probe.call = p end
  if type(p.counts) ~= "table" then p.counts = {} end
  return p
end

function Call.Count(name, n)
  if not COUNT_OK[name] then return end
  local p = Call.Probe()
  if not p then return end
  local v = p.counts[name]
  p.counts[name] = math.min(1e9, (type(v) == "number" and v or 0) + (n or 1))
end

-- one result code of a send: kind "P" or "T", combat or calm, per way
function Call.NoteCode(kind, channel, code)
  local p = Call.Probe()
  if not p then return end
  if type(p.codes) ~= "table" then p.codes = {} end
  local k = tostring(kind) .. "." .. (inCombat() and "combat" or "calm")
  local t = p.codes[k]
  if type(t) ~= "table" then t = {}; p.codes[k] = t end
  local ch = t[channel]
  if type(ch) ~= "table" then ch = {}; t[channel] = ch end
  local c = tostring(code)
  if ch[c] == nil then
    local n = 0
    for _ in pairs(ch) do n = n + 1 end
    if n >= C.CODES_MAX then c = "other" end
  end
  ch[c] = (tonumber(ch[c]) or 0) + 1
end

-- a broken probe table out (a hand-edited file must not break counting)
local CHANNELS = { GUILD = true, PARTY = true, RAID = true, WHISPER = true, BN = true, CHANNEL = true, YELL = true }
function Call.SanitizeProbe(p)
  if type(p) ~= "table" then return nil end
  if type(p.counts) ~= "table" then p.counts = {} end
  for k, v in pairs(p.counts) do if not COUNT_OK[k] or type(v) ~= "number" or v ~= v then p.counts[k] = nil end end
  if type(p.codes) ~= "table" then p.codes = nil
  else
    for k, t in pairs(p.codes) do
      local good = type(k) == "string" and k:match("^[PT]%.%a+$") and type(t) == "table"
      if good then
        for ch, x in pairs(t) do
          local n = 0
          if type(x) == "table" then for _ in pairs(x) do n = n + 1 end end
          if not CHANNELS[ch] or type(x) ~= "table" or n > C.CODES_MAX + 1 then t[ch] = nil end
        end
      else
        p.codes[k] = nil
      end
    end
  end
  if p.net ~= nil and type(p.net) ~= "table" then p.net = nil end
  if p.gchat ~= nil and type(p.gchat) ~= "table" then p.gchat = nil end
  for k in pairs(p) do
    if k ~= "counts" and k ~= "codes" and k ~= "net" and k ~= "gchat" and k ~= "live" then p[k] = nil end
  end
  return p
end

---------------------------------------------------------------------------
-- Wire (pure: no WoW calls, `t` passed in)
---------------------------------------------------------------------------
local function plain(s, max)
  if type(s) ~= "string" or IsSecret(s) then return "" end
  s = s:gsub("[%c|]", "")
  return GP.CutUTF8(s, max or C.NAME_MAX)
end

-- the attacker's shown name: with a key "Name" or "Name Surname" of that key, else a plain name
local function shownName(key, disp)
  if key ~= "" then
    local n, s = GP.ValidKey(key)
    if not n then return nil end
    if disp ~= n and disp ~= n .. " " .. s then disp = n .. " " .. s end
    -- 1.6.0 fix: within NAME_MAX like every shown name (a long name built from the key would not survive loading)
    return GP.CutUTF8(disp, C.NAME_MAX)
  end
  return disp
end

-- c = { mapID, x, y (percent, as Util.Zone), t, key?, display? } -> text or nil
function Call.Encode(c)
  if type(c) ~= "table" or not GP.ValidPlace(c.mapID, c.x, c.y) or not GP.Finite(c.t) then return nil end
  local key = (type(c.key) == "string" and not IsSecret(c.key) and GP.ValidKey(c.key)) and c.key or ""
  local disp = plain(c.display)
  if key ~= "" then disp = shownName(key, disp) or "" end
  local head = table.concat({ C.PROTO, "P", tostring(c.mapID), tostring(math.floor(c.x * 10 + 0.5)),
    tostring(math.floor(c.y * 10 + 0.5)), tostring(math.floor(c.t)) }, "\t")
  local msg = head .. "\t" .. GP.Escape(key) .. "\t" .. GP.Escape(disp)
  if #msg > 255 then msg = head .. "\t" .. GP.Escape(key) .. "\t" end
  if #msg > 255 then return nil end
  return msg
end

local function int(s, lo, hi)
  if type(s) ~= "string" or not s:match("^%d+$") or #s > 12 then return nil end
  local v = tonumber(s)
  if not v or v < lo or v > hi then return nil end
  return v
end

-- text -> { kind = "P", mapID, px, py, t, key?, display? } | { kind = "N", t } or nil, reason. Never raises.
function Call.Decode(text, t)
  if type(text) ~= "string" or IsSecret(text) or #text == 0 or #text > 255 then return nil, "size" end
  local f, pos = {}, 1
  while true do
    local s = text:find("\t", pos, true)
    f[#f + 1] = text:sub(pos, s and s - 1 or nil)
    if #f > 8 then return nil, "fields" end
    if not s then break end
    pos = s + 1
  end
  if f[1] ~= C.PROTO then return nil, "version" end
  if f[2] == "N" then
    if #f ~= 3 then return nil, "fields" end
    local tt = int(f[3], 0, 4e9)
    if not tt then return nil, "time" end
    return { kind = "N", t = tt }
  end
  if f[2] ~= "P" then return nil, "type" end
  if #f ~= 8 then return nil, "fields" end
  local m = { kind = "P" }
  m.mapID, m.px, m.py = int(f[3], 1, Guild.C.PLACE_MAP_MAX), int(f[4], 0, 1000), int(f[5], 0, 1000)
  if not (m.mapID and m.px and m.py) then return nil, "place" end
  m.t = int(f[6], t - C.AGE, t + Guild.C.FUTURE)
  if not m.t then return nil, "time" end
  local key, disp = GP.Unescape(f[7]), GP.Unescape(f[8])
  if not key or not disp then return nil, "name" end
  disp = plain(disp)
  if key ~= "" then
    disp = shownName(key, disp)
    if not disp then return nil, "key" end
    m.key = key
  end
  if disp ~= "" then m.display = disp end
  return m
end

-- 1.6.0 T (Sync.lua decodes it): key, place, time, layer mark or ""
function Call.EncodeSight(key, mapID, x, y, t, shard)
  if type(key) ~= "string" or IsSecret(key) or not GP.ValidKey(key) or not GP.ValidPlace(mapID, x, y) or not GP.Finite(t) then
    return nil
  end
  local sh = (type(shard) == "string" and not IsSecret(shard) and #shard <= 40 and shard:match("^%d+%-%d+%-%d+$")) and shard or ""
  local msg = table.concat({ C.PROTO, "T", GP.Escape(key), tostring(mapID), tostring(math.floor(x * 10 + 0.5)),
    tostring(math.floor(y * 10 + 0.5)), tostring(math.floor(t)), sh }, "\t")
  if #msg > 255 then return nil end
  return msg
end

---------------------------------------------------------------------------
-- The layer: a mark from the GUID of a creature nearby (RareScanner on Forever, RSTelemetryEngine.ParseCreatureGUID:
-- "Creature-0-serverID-instanceID-zoneUID-npcID-spawnUID", secret checked first; the mark is server-instance-zone)
---------------------------------------------------------------------------
function Call.ShardOf(guid)
  if IsSecret(guid) or type(guid) ~= "string" or #guid > 80 then return nil end
  local typ, s, i, z = guid:match("^(%a+)%-%d+%-(%d+)%-(%d+)%-(%d+)%-%d+%-%x+$")
  if typ ~= "Creature" and typ ~= "Vehicle" then return nil end
  return s .. "-" .. i .. "-" .. z
end

local shard, shardAt
function Call.SeeUnit(unit)
  local gt = GetTime()
  if shardAt and gt - shardAt < C.SHARD_GAP and gt >= shardAt then return end
  local s = Call.ShardOf(Call_(_G.UnitGUID, unit))
  if not s then return end
  if s ~= shard then Call.Count("shardSeen") end
  shard, shardAt = s, gt
end
function Call.Shard()
  if shard and shardAt and GetTime() - shardAt <= C.SHARD_TTL then return shard end
  return nil
end
function Call.ResetShard() shard, shardAt = nil, nil end

---------------------------------------------------------------------------
-- Places and names
---------------------------------------------------------------------------
-- the name of a map ID in the client's language, or nil
function Call.MapName(mapID)
  local CM = _G.C_Map
  local info = CM and Call_(CM.GetMapInfo, mapID)
  if IsSecret(info) or type(info) ~= "table" then return nil end
  return Str(info.name)
end

-- the zone a map belongs to (a city, a cave: up to the zone; Enum.UIMapType.Zone = 3)
local function zoneMap(mapID)
  local CM = _G.C_Map
  local id = mapID
  for _ = 1, 5 do
    local info = CM and Call_(CM.GetMapInfo, id)
    if IsSecret(info) or type(info) ~= "table" then return id end
    local mt, parent = Num(info.mapType), Num(info.parentMapID)
    if not mt or mt <= 3 or not parent or parent <= 0 then return id end
    id = parent
  end
  return id
end
-- true, false or nil (unknown) whether the player stands in the zone of mapID
function Call.SameZone(mapID)
  local mine = Num(Call_(_G.C_Map and _G.C_Map.GetBestMapForUnit, "player"))
  if not mine or not mapID then return nil end
  if mine == mapID then return true end
  return zoneMap(mine) == zoneMap(mapID)
end

-- a link in the chat that CallUI.lua turns into a click (map of a call or a sighting, the guild chat call)
Call.links, Call.linkN = {}, 0
function Call.Link(what, rec, label)
  local id = 0
  if rec then
    Call.linkN = Call.linkN + 1
    id = Call.linkN
    Call.links[id] = rec
    Call.links[id - C.LINKS] = nil
  end
  return "|cffe0603a|Haddon:" .. ADDON .. ":call:" .. what .. ":" .. id .. "|h[" .. label .. "]|h|r"
end

---------------------------------------------------------------------------
-- Sending (one message on one way, past the queue): true when the client took it, and the code
---------------------------------------------------------------------------
local function enumOf(name, fallback)
  local E = _G.Enum and _G.Enum.SendAddonMessageResult
  local v = E and E[name]
  return type(v) == "number" and v or fallback
end
function Call.SendOne(prefix, text, channel, target, bn)
  if channel == "BN" then
    local fn = _G.BNSendGameData or (_G.C_BattleNet and _G.C_BattleNet.SendGameData)
    if type(fn) ~= "function" or type(bn) ~= "number" then return false, "noapi" end
    local ok = pcall(fn, bn, prefix, text)
    return ok, ok and "ok" or "error"
  end
  local CI = _G.C_ChatInfo
  if not (CI and type(CI.SendAddonMessage) == "function") then return false, "noapi" end
  local ok, res = pcall(CI.SendAddonMessage, prefix, text, channel, target)
  if not ok then return false, "error" end
  if IsSecret(res) then return true, "secret" end
  if res == nil or res == true then return true, res == nil and "nil" or "true" end
  if res == false then return false, "false" end
  return res == enumOf("Success", 0), res
end

-- the ways of a live message right now: { { channel, target, bn, to = "guild" | "group" | "friend" } }. kind "P" (help
-- call: guild, group, friends) or "T" (sighting: the guild while sharing with it is on, friends; never the group)
function Call.Ways(kind)
  local out = {}
  if kind == "T" then
    if Guild.Enabled() then out[#out + 1] = { channel = "GUILD", to = "guild" } end
  else
    if B.inGuild() then out[#out + 1] = { channel = "GUILD", to = "guild" } end
    if True(Call_(_G.IsInRaid)) then out[#out + 1] = { channel = "RAID", to = "group" }
    elseif True(Call_(_G.IsInGroup)) then out[#out + 1] = { channel = "PARTY", to = "group" } end
  end
  local F = ns.Friends
  if F and F.Enabled and F.Enabled() and F.Peers then
    for _, x in ipairs(F.Peers()) do
      out[#out + 1] = { channel = x.channel, target = x.name, bn = x.bn, to = "friend" }
    end
  end
  return out
end

---------------------------------------------------------------------------
-- Help call: sending
---------------------------------------------------------------------------
local lastSend
Call.last = nil   -- what went out last { text, mapID, x, y, zone, display }: the guild chat line is made of it

-- the attacker: a hostile player in the target, else the first attacker of the running grudge episode
function Call.Attacker()
  local Gp = ns.Grip
  if Gp and Gp.EnemyOf then
    local ok, key, info = pcall(Gp.EnemyOf, "target")
    if ok and type(key) == "string" and type(info) == "table" and type(info.name) == "string" then
      local disp = info.surname and (info.name .. " " .. info.surname) or info.name
      return GP.ValidKey(key) and key or nil, disp
    end
  end
  local Gr = ns.Grudge
  local e = Gr and Gr.Current and Gr.Current()
  if type(e) == "table" and not e.closed and not e.test and type(e.order) == "table" and type(e.rows) == "table" then
    local first
    for _, k in ipairs(e.order) do
      local r = e.rows[k]
      if type(r) == "table" and r.conf ~= "held" and (not first or (r.n or 0) < (first.n or 0)) then first = r end
    end
    if first and type(first.key) == "string" then
      local ok, disp = pcall(Util.Display, first)
      disp = ok and Str(disp) or Str(first.name)
      return GP.ValidKey(first.key) and first.key or nil, disp
    end
  end
  return nil, nil
end

-- Sends the help call. Returns true, { guild = bool, group = bool, friends = n } or false, why, detail
-- (why: "wait" (detail = seconds), "noapi", "lockdown", "instance", "place", "none", "failed" (detail = code))
function Call.Send()
  local gt = GetTime()
  if lastSend and gt - lastSend < C.COOLDOWN and gt >= lastSend then
    return false, "wait", math.ceil(C.COOLDOWN - (gt - lastSend))
  end
  local CI = _G.C_ChatInfo
  if not (CI and type(CI.SendAddonMessage) == "function") then return false, "noapi" end
  if True(Call_(CI.InChatMessagingLockdown)) then return false, "lockdown" end
  if not Util.IsOpenWorld() then return false, "instance" end
  local zone, sub, mapID, x, y = Util.Zone()
  if not GP.ValidPlace(mapID, x, y) then return false, "place" end
  local key, disp = Call.Attacker()
  local text = Call.Encode({ mapID = mapID, x = x, y = y, t = now(), key = key, display = disp })
  if not text then return false, "place" end
  local ways = Call.Ways("P")
  if #ways == 0 then return false, "none" end
  local got = { guild = false, group = false, friends = 0 }
  local any, lastCode = false, nil
  for _, w in ipairs(ways) do
    local ok, code = Call.SendOne(C.PREFIX, text, w.channel, w.target, w.bn)
    Call.NoteCode("P", w.channel, code)
    if ok then
      any = true
      if w.to == "friend" then got.friends = got.friends + 1 else got[w.to] = true end
    else
      lastCode = code
    end
  end
  if not any then Call.Count("sendRefused"); return false, "failed", lastCode end
  -- 1.6.0 fix: the cooldown begins only once the call reached somebody (a refused call may be tried again at once)
  lastSend = gt
  Call.Count("sent")
  local m = Call.Decode(text, now())
  Call.last = { mapID = mapID, x = x, y = y, zone = Str(zone) or Call.MapName(mapID), display = m and m.display }
  return true, got
end

-- the words of the sender's line
function Call.SentLine(got)
  local parts = {}
  if got.guild then parts[#parts + 1] = L.CALL_TO_GUILD end
  if got.group then parts[#parts + 1] = L.CALL_TO_GROUP end
  if (got.friends or 0) > 0 then parts[#parts + 1] = Fmt(L.CALL_TO_FRIENDS, { count = got.friends }) end
  return Fmt(L.CALL_SENT, { list = table.concat(parts, ", ") })
end
local WHY = { lockdown = "CALL_NO_LOCKDOWN", instance = "CALL_NO_INSTANCE", place = "CALL_NO_PLACE", none = "CALL_NO_ONE",
  noapi = "CALL_NO_ONE" }
function Call.WhyLine(why, detail)
  if why == "wait" then return Fmt(L.CALL_WAIT, { seconds = tonumber(detail) or C.COOLDOWN }) end
  if why == "failed" then return Fmt(L.CALL_FAILED, { code = tostring(detail) }) end
  return L[WHY[why] or "CALL_NO_ONE"]
end

-- the key or the button: send and say so (a line in the middle of the screen and in the chat; in a guild the chat
-- line carries the click "Call in guild chat")
function Call.Trigger()
  L, Fmt = ns.L, ns.F
  local ok, got, detail = Call.Send()
  local line = ok and Call.SentLine(got) or Call.WhyLine(got, detail)
  local ef = rawget(_G, "UIErrorsFrame")
  if type(ef) == "table" and type(ef.AddMessage) == "function" then pcall(ef.AddMessage, ef, line, 1, 0.82, 0.3, 1) end
  -- 1.6.0 fix: the link only where it can send (Share.lua never sends in combat or in a chat lockdown)
  local S = ns.Share
  local hold = S and S.Hold and S.Hold() or nil
  if ok and B.inGuild() and hold ~= "combat" and hold ~= "lockdown" then
    line = line .. " " .. Call.Link("gchat", nil, L.CALL_GCHAT_LINK)
  end
  Util.Print(line)
  return ok, got
end

-- "Call in guild chat" (a click on the link): one visible line through Share.lua's way (never in combat, never in a
-- lockdown, its cooldown). Returns true or false, why.
local echo
function Call.GuildChat()
  L, Fmt = ns.L, ns.F
  local p = Call.Probe()
  if p then
    if type(p.gchat) ~= "table" then p.gchat = {} end
    p.gchat.clicked = (tonumber(p.gchat.clicked) or 0) + 1
  end
  local S, last = ns.Share, Call.last
  if not (S and S.Send and last) then return false, "empty" end
  local W = S.Word or function(k) return L[k] end
  local zone = S.Clean and S.Clean(last.zone or "", 60) or (last.zone or "")
  if zone == "" then zone = W("CALL_SOMEWHERE") end
  local vals = { zone = zone, x = math.floor(last.x + 0.5), y = math.floor(last.y + 0.5),
    name = last.display and (S.Clean and S.Clean(last.display, C.NAME_MAX) or last.display) or nil }
  local text = (S.BRAND or "Revenge Book") .. ": " .. Fmt(W(vals.name and "CALL_GCHAT_BY" or "CALL_GCHAT"), vals)
  if S.Cut then text = S.Cut(text, S.MAX_BYTES or 255) end
  local ok, why = S.Send(text, "GUILD")
  if p then
    if ok then
      p.gchat.sent = (tonumber(p.gchat.sent) or 0) + 1
    else
      p.gchat.refused = (tonumber(p.gchat.refused) or 0) + 1
      p.gchat.lastWhy = tostring(why)
    end
  end
  if ok then echo = { text = text, at = GetTime() } end
  return ok, why
end

-- the own line comes back on CHAT_MSG_GUILD when the server took it (probe c: does Forever let it through?)
function Call.OnGuildChat(_, msg, author)
  if not echo then return end
  if IsSecret(msg) or IsSecret(author) or type(msg) ~= "string" then return end
  if GetTime() - echo.at > 15 then echo = nil; return end
  local short = Guild.SenderName(author)
  if not short or not Guild.IsMe(short) or msg ~= echo.text then return end
  echo = nil
  local p = Call.Probe()
  if p and type(p.gchat) == "table" then p.gchat.echo = (tonumber(p.gchat.echo) or 0) + 1 end
end

---------------------------------------------------------------------------
-- Help call: receiving
---------------------------------------------------------------------------
local fromAt, minute = {}, {}

local function cdb()
  local db = ns.Store and ns.Store.DB and ns.Store.DB()
  if type(db) ~= "table" then return nil end
  if type(db.call) ~= "table" then db.call = {} end
  if type(db.call.calls) ~= "table" then db.call.calls = {} end
  return db.call
end
-- the stored calls, newest last (at most RING)
function Call.Calls() local d = cdb(); return d and d.calls or {} end

-- a stored call that cannot be read is dropped (and the ring stays within RING)
local function validRec(r)
  return type(r) == "table" and GP.Finite(r.t) and GP.Finite(r.at) and type(r.by) == "string" and r.by ~= ""
    and #r.by <= 80 and not r.by:find("[%c|]") and GP.ValidPlace(r.mapID, r.x, r.y)
    and (r.key == nil or (type(r.key) == "string" and GP.ValidKey(r.key) ~= nil))
    and (r.display == nil or (type(r.display) == "string" and #r.display <= C.NAME_MAX and not r.display:find("[%c|]")))
    and (r.zone == nil or (type(r.zone) == "string" and #r.zone <= 80 and not r.zone:find("[%c|]")))
end
function Call.SanitizeDB(d)
  if type(d) ~= "table" then return nil end
  if type(d.calls) ~= "table" then d.calls = {} end
  local keep = {}
  for i = 1, #d.calls do if validRec(d.calls[i]) then keep[#keep + 1] = d.calls[i] end end
  while #keep > C.RING do table.remove(keep, 1) end
  d.calls = keep
  for k in pairs(d) do if k ~= "calls" then d[k] = nil end end
  return d
end

local function remember(rec)
  local d = cdb()
  if not d then return end
  local list = d.calls
  list[#list + 1] = rec
  while #list > C.RING do table.remove(list, 1) end
end

-- the words of a received call: "Anna calls for help: Ashenvale (same zone), attacker Grimm"
function Call.InLine(rec)
  local where = rec.same == true and L.CALL_SAME_ZONE or rec.same == false and L.CALL_OTHER_ZONE or nil
  local zone = rec.zone or L.CALL_SOMEWHERE
  if where then zone = zone .. " (" .. where .. ")" end
  if rec.display then return Fmt(L.CALL_IN_BY, { name = rec.by, zone = zone, attacker = rec.display }) end
  return Fmt(L.CALL_IN, { name = rec.by, zone = zone })
end

-- from: "guild" | "group" | "friend"
function Call.Receive(text, short, full, from)
  local t = now()
  local m, why = Call.Decode(text, t)
  if not m or m.kind ~= "P" then Call.Count("dropped"); return nil, why or "type" end
  local gt = GetTime()
  local who = (full or short):lower()
  local last = fromAt[who]
  if last and gt - last < C.PER_SENDER and gt >= last then Call.Count("dup"); return nil, "dup" end
  -- 1.6.0 fix: the same call over two ways (group and Battle.net, where the client names the sender once with and
  -- once without surname) is one call: the same text from the same first name
  local same = "\t" .. ((short:match("^(%S+)") or short):lower()) .. "\t" .. text
  last = fromAt[same]
  if last and gt - last < C.PER_SENDER and gt >= last then Call.Count("dup"); return nil, "dup" end
  for i = #minute, 1, -1 do if gt - minute[i] >= 60 or minute[i] > gt then table.remove(minute, i) end end
  if #minute >= C.MINUTE_MAX then Call.Count("flood"); return nil, "flood" end
  fromAt[who] = gt
  fromAt[same] = gt
  minute[#minute + 1] = gt
  -- the senders' table stays small: who is older than PER_SENDER goes
  local n = 0
  for _ in pairs(fromAt) do n = n + 1 end
  if n > 100 then for k, v in pairs(fromAt) do if gt - v >= C.PER_SENDER or v > gt then fromAt[k] = nil end end end
  local rec = { t = m.t, at = t, by = short, from = from, mapID = m.mapID, x = m.px / 10, y = m.py / 10,
    key = m.key, display = m.display, zone = Call.MapName(m.mapID) }
  if rec.zone and (#rec.zone > 80 or rec.zone:find("[%c|]")) then rec.zone = nil end
  rec.same = Call.SameZone(m.mapID)
  -- 1.6.0 fix: in a dungeon, raid or battleground only the quiet chat line (no sound, no slip; the pin still comes)
  if not Util.IsOpenWorld() then rec.quiet = true; Call.Count("quiet") end
  remember(rec)
  Call.Count("received")
  Util.Print(Call.InLine(rec) .. " " .. Call.Link("map", rec, L.CALL_MAP))
  ns:Fire("HELP_CALL", rec)
  return rec
end

local function netHeard(channel)
  local p = Call.Probe()
  if not p then return end
  if type(p.net) ~= "table" then p.net = {} end
  if type(p.net.heard) ~= "table" then p.net.heard = {} end
  p.net.heard[channel] = math.min(C.HEARD_MAX, (tonumber(p.net.heard[channel]) or 0) + 1)
end

-- CHAT_MSG_ADDON: foreign prefixes leave after one comparison
function Call.OnAddon(_, prefix, text, channel, sender)
  if IsSecret(prefix) or prefix ~= C.PREFIX then return end
  if IsSecret(text) or IsSecret(channel) or IsSecret(sender) or type(text) ~= "string" or type(channel) ~= "string" then
    Call.Count("secret"); return
  end
  local short, full = Guild.SenderName(sender)
  if not short or Guild.IsMe(short) then return end
  if text:find("^1\tN\t") then
    if channel == "CHANNEL" or channel == "YELL" then netHeard(channel) end
    return
  end
  local from
  if channel == "GUILD" then
    if not B.inGuild() then return end
    from = "guild"
  elseif channel == "PARTY" or channel == "RAID" then
    from = "group"
  elseif channel == "WHISPER" then
    local F = ns.Friends
    -- 1.6.0 fix: only a bound friend, by the book's own identity check (a namesake of a friend stays a stranger)
    local x = F and F.Enabled and F.Enabled() and F.Vouch and F.Vouch(short)
    if not x or (F.Muted and F.Muted(full or short)) then Call.Count("stranger"); return end
    from = "friend"
  else
    Call.Count("stranger"); return
  end
  Call.Receive(text, short, full, from)
end

-- BN_CHAT_MSG_ADDON (prefix, text, channel, gameAccountID): only Battle.net friends can send it
function Call.OnBattleNet(_, prefix, text, _, id)
  if IsSecret(prefix) or prefix ~= C.PREFIX then return end
  if IsSecret(text) or IsSecret(id) or type(text) ~= "string" or type(id) ~= "number" then Call.Count("secret"); return end
  local F = ns.Friends
  if not (F and F.Enabled and F.Enabled()) then return end
  local BN = _G.C_BattleNet
  local g = BN and BN.GetGameAccountInfoByID and Call_(BN.GetGameAccountInfoByID, id)
  if IsSecret(g) or type(g) ~= "table" then return end
  if _G.WOW_PROJECT_ID and Num(g.wowProjectID) ~= _G.WOW_PROJECT_ID then return end
  local name = Str(g.characterName)
  if not name or #name > 80 or name:find("[%c|]") then return end
  local short = name:match("^([^%-]+)") or name
  if Guild.IsMe(short) then return end
  if text:find("^1\tN\t") then return end
  Call.Receive(text, short, name, "friend")
end

---------------------------------------------------------------------------
-- Sighting T: sending
---------------------------------------------------------------------------
local sightSent, pending, heard, lineAt = {}, {}, {}, {}
local ownKillers = {}     -- key -> time of the newest sure kill on me (journal), refreshed on deaths
Call.sightings = {}       -- received sightings of this session (map), at most SIGHT_RING

local function setting() return Guild.Setting("layerSight") ~= false end
Call.On = setting

function Call.RefreshKillers()
  ownKillers = {}
  local S = ns.Store
  local list = S and S.Deaths and S.Deaths() or {}
  local t0 = now() - C.SIGHT_DAYS * 86400
  for i = 1, math.min(#list, 200) do
    local j = list[i]
    if type(j) == "table" and j.kind == "pvp" and j.sure == true and j.counted ~= false and type(j.killerKey) == "string"
      and GP.Finite(j.t) and j.t >= t0 then
      if not ownKillers[j.killerKey] or ownKillers[j.killerKey] < j.t then ownKillers[j.killerKey] = j.t end
    end
  end
end
function Call.OwnKiller(key) return ownKillers[key] end

-- the tracker hook (Sync.lua setHook) is wanted for own killers too
function Call.WantHook() return setting() and next(ownKillers) ~= nil end

local function recent(x, t0) return type(x) == "table" and type(x.lastKill) == "number" and x.lastKill >= t0 end
function Call.Eligible(key, e, fe, hg, fh)
  if hg or fh then return true end
  local t0 = now() - C.SIGHT_DAYS * 86400
  if recent(e, t0) or recent(fe, t0) then return true end
  if ownKillers[key] and ownKillers[key] >= t0 then return true end
  if Guild.HasBounty then
    local ok, v = pcall(Guild.HasBounty, key)
    if ok and v == true then return true end
  end
  return false
end

-- Guild.OnUnit (a hostile player in sight): maybe a T after a short random wait
function Call.OnUnit(key, listed, e, fe, hg, fh)
  if type(key) ~= "string" or not setting() then return end
  local gt = GetTime()
  local last = sightSent[key]
  if pending[key] or (last and gt - last < C.SIGHT_SEND and gt >= last) then return end
  if not Call.Eligible(key, e, fe, hg, fh) then return end
  if not GP.ValidKey(key) or not Util.IsOpenWorld() then return end
  if #Call.Ways("T") == 0 then return end
  sightSent[key] = gt
  local _, _, mapID, x, y = Util.Zone()
  if not GP.ValidPlace(mapID, x, y) then Call.Count("sightNoPlace"); return end
  local t, sh = now(), Call.Shard()
  pending[key] = gt
  After(C.WAIT_MIN + math.random() * (C.WAIT_MAX - C.WAIT_MIN), function()
    local at = pending[key]
    pending[key] = nil
    if heard[key] and at and heard[key] >= at then Call.Count("sightQuiet"); return end
    local text = Call.EncodeSight(key, mapID, x, y, t, sh)
    if not text then return end
    local any = false
    for _, w in ipairs(Call.Ways("T")) do
      local ok, code = Call.SendOne(Guild.PREFIX, text, w.channel, w.target, w.bn)
      Call.NoteCode("T", w.channel, code)
      if ok then any = true end
    end
    if any then Call.Count("sightSent") end
  end)
end

---------------------------------------------------------------------------
-- Sighting T: receiving (Sync.lua apply, already decoded and checked: guild member or friend)
---------------------------------------------------------------------------
function Call.SightLine(rec)
  local args = { name = rec.name, by = rec.by, zone = rec.zone or L.CALL_SOMEWHERE, ago = Util.Ago(rec.t) }
  return Fmt(rec.layer == "other" and L.SIGHT_LINE_LAYER or L.SIGHT_LINE, args)
end

function Call.ApplySight(ctx, m, short, full, t)
  local gt = GetTime()
  heard[m.key] = gt          -- someone else saw him: my own T for him stays quiet
  if not setting() then return end
  local S = ns.Store
  local own = S and S.Get and S.Get(m.key)
  local g = Guild.Get(m.key, "all")
  local h = Guild.Hunt and Guild.Hunt(m.key, "all")
  if not (own or g or h) then Call.Count("sightUnknown"); return end
  local zone = Call.MapName(m.mapID)
  if zone and (#zone > 64 or zone:find("[%c|]")) then zone = nil end
  -- lastSeen of the lists of this channel, as S does it (the zone; only newer ones)
  local e = ctx.store.enemies[m.key]
  local hh = ctx.hunts and ctx.hunts[m.key]
  local fresh = false
  if e and not (e.lastSeen and (e.lastSeen.t or 0) >= m.t) then e.lastSeen = { t = m.t, zone = zone, by = short }; fresh = true end
  if hh and not (hh.lastSeen and (hh.lastSeen.t or 0) >= m.t) then hh.lastSeen = { t = m.t, zone = zone, by = short }; fresh = true end
  if fresh then B.updated("seen") end
  Call.Count("sightReceived")
  local name = (own and Util.Display(own)) or (g and g.display) or (h and h.display) or (m.name .. " " .. m.surname)
  local mine = Call.Shard()
  local rec = { key = m.key, name = name, by = short, t = m.t, at = t, mapID = m.mapID, x = m.px / 10, y = m.py / 10,
    zone = zone, src = ctx.src, layer = (m.shard and mine) and (m.shard == mine and "same" or "other") or nil }
  local list = Call.sightings
  list[#list + 1] = rec
  while #list > C.SIGHT_RING do table.remove(list, 1) end
  if fresh then ns:Fire("GUILD_SIGHTING", m.key, zone, short, ctx.src) end
  ns:Fire("SIGHTING", rec)
  local la = lineAt[m.key]
  if not la or gt - la >= C.SIGHT_LINE or gt < la then
    lineAt[m.key] = gt
    Call.Count("sightLine")
    Util.Print(Call.SightLine(rec) .. " " .. Call.Link("map", rec, L.CALL_MAP))
  end
  return rec
end

---------------------------------------------------------------------------
-- Map: calls and sightings as scenes (Scene.lua asks; only fresh ones)
---------------------------------------------------------------------------
function Call.Scenes(out, t)
  t = t or now()
  local calls = Call.Calls()
  for i = 1, #calls do
    local r = calls[i]
    if type(r) == "table" and GP.Finite(r.at) and t - r.at < C.FRESH and t - r.at >= -60 then
      out[#out + 1] = { kind = "call", t = r.t, mapID = r.mapID, x = r.x, y = r.y, zone = r.zone, key = r.key,
        name = r.display, caller = r.by, ref = r, fresh = true, spot = GP.ValidPlace(r.mapID, r.x, r.y) }
    end
  end
  for i = 1, #Call.sightings do
    local r = Call.sightings[i]
    if t - r.at < C.SIGHT_PIN and t - r.at >= -60 then
      out[#out + 1] = { kind = "sight", t = r.t, mapID = r.mapID, x = r.x, y = r.y, zone = r.zone, key = r.key,
        name = r.name, caller = r.by, src = r.src, layer = r.layer, ref = r, spot = GP.ValidPlace(r.mapID, r.x, r.y) }
    end
  end
end

---------------------------------------------------------------------------
-- /dn probe net: one try of a channel of our own and of YELL (for a test with two clients)
---------------------------------------------------------------------------
local function codeText(ok, code) return (ok and "ok:" or "no:") .. tostring(code) end
function Call.ProbeNet()
  L = ns.L
  local p = Call.Probe()
  if not p then return false end
  local net = { at = now(), heard = type(p.net) == "table" and type(p.net.heard) == "table" and p.net.heard or {} }
  p.net = net
  local join = rawget(_G, "JoinChannelByName")
  if type(join) == "function" then
    local ok, a = pcall(join, C.NET_CHANNEL)
    net.join = ok and (IsSecret(a) and "secret" or tostring(a)) or "error"
  else
    net.join = "noapi"
  end
  Util.Print(L.PROBE_NET)
  local t = tostring(now())
  After(C.NET_WAIT, function()
    local gcn = rawget(_G, "GetChannelName")
    local id = type(gcn) == "function" and Num(Call_(gcn, C.NET_CHANNEL)) or nil
    net.channelId = id
    if id and id > 0 then
      net.channel = codeText(Call.SendOne(C.PREFIX, "1\tN\t" .. t, "CHANNEL", id))
    else
      net.channel = "nochannel"
    end
    net.yell = codeText(Call.SendOne(C.PREFIX, "1\tN\t" .. t, "YELL"))
    Util.Print(("probe net: join %s · CHANNEL %s · YELL %s"):format(tostring(net.join), tostring(net.channel), tostring(net.yell)))
  end)
  After(C.NET_STAY, function()
    local leave = rawget(_G, "LeaveChannelByName")
    if type(leave) == "function" then
      local ok = pcall(leave, C.NET_CHANNEL)
      net.left = ok
    end
    local hd = net.heard
    Util.Print(("probe net: heard CHANNEL %d · YELL %d"):format(tonumber(hd.CHANNEL) or 0, tonumber(hd.YELL) or 0))
  end)
  return true
end

-- for /dn probe: what is true right now (the counters themselves stay in DeathNoteDB.probe.call)
function Call.ProbeLive()
  return { prefix = Call.prefixResult, shard = Call.Shard() ~= nil, on = setting(), calls = #Call.Calls(),
    sightings = #Call.sightings, killers = (function() local n = 0; for _ in pairs(ownKillers) do n = n + 1 end; return n end)() }
end

---------------------------------------------------------------------------
-- Start and events
---------------------------------------------------------------------------
function Call.Reset()
  sightSent, pending, heard, lineAt, fromAt, minute = {}, {}, {}, {}, {}, {}
  Call.sightings, Call.links, Call.linkN, Call.last = {}, {}, 0, nil
  lastSend, echo = nil, nil
  Call.ResetShard()
end

Guild.CallExt = { onUnit = Call.OnUnit, applySight = Call.ApplySight, wantHook = Call.WantHook, eligible = Call.Eligible }

ns:On("READY", function()
  local db = ns.Store and ns.Store.DB and ns.Store.DB()
  if type(db) == "table" then
    if db.call ~= nil then db.call = Call.SanitizeDB(db.call) end
    if type(db.probe) == "table" and db.probe.call ~= nil then db.probe.call = Call.SanitizeProbe(db.probe.call) end
  end
  local CI = _G.C_ChatInfo
  if CI and CI.RegisterAddonMessagePrefix then
    local ok, res = pcall(CI.RegisterAddonMessagePrefix, C.PREFIX)
    Call.prefixResult = ok and (IsSecret(res) and "secret" or tostring(res)) or "error"
  end
  Call.RefreshKillers()
  if B.setHook then B.setHook() end
end)
ns:On("DEATH_RECORDED", function(journal, key)
  Call.RefreshKillers()
  -- the death just recorded counts at once (the journal may be written after this event)
  if type(journal) == "table" and journal.kind == "pvp" and journal.sure == true and journal.counted ~= false
    and type(key) == "string" and GP.Finite(journal.t) and journal.t >= now() - C.SIGHT_DAYS * 86400 then
    if not ownKillers[key] or ownKillers[key] < journal.t then ownKillers[key] = journal.t end
  end
  if B.setHook then B.setHook() end
end)
ns:On("SETTINGS_CHANGED", function(path)
  if path == "guild.layerSight" and B.setHook then B.setHook() end
end)
ns:RegisterEvent("CHAT_MSG_ADDON", Call.OnAddon)
ns:RegisterEvent("BN_CHAT_MSG_ADDON", Call.OnBattleNet)
ns:RegisterEvent("CHAT_MSG_GUILD", Call.OnGuildChat)
-- the layer mark: a creature's GUID now and then (target, mouse, a new plate); a new zone forgets it
ns:RegisterEvent("PLAYER_TARGET_CHANGED", function() Call.SeeUnit("target") end)
ns:RegisterEvent("UPDATE_MOUSEOVER_UNIT", function() Call.SeeUnit("mouseover") end)
ns:RegisterEvent("NAME_PLATE_UNIT_ADDED", function(_, unit) if type(unit) == "string" and not IsSecret(unit) then Call.SeeUnit(unit) end end)
ns:RegisterEvent("ZONE_CHANGED_NEW_AREA", function() Call.ResetShard() end)
ns:RegisterEvent("PLAYER_ENTERING_WORLD", function() Call.ResetShard() end)
