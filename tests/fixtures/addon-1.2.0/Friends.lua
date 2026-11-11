-- DeathNote - Friends.lua (1.2.0)
-- Friends' book: the same invisible messages as in the guild (Sync.lua, protocol 1), sent as
-- WHISPER to character friends of the friend list who are online. Accepted is only what comes
-- from a name on the own friend list; everything else is dropped before decoding (that is the hot
-- path: anybody can whisper addon messages). Friends in the own guild get nothing by whisper, they
-- hear it on GUILD (only releases for friends alone go to them by whisper too). Received data lives
-- in DeathNoteDB.friends (account-wide, not per guild).
--
-- Battle.net friends playing this game (same project) are reached with BNSendGameData and heard
-- through BN_CHAT_MSG_ADDON, the way OpenMap does it (OpenMap/Map/Friends.lua: ScanBattleNet, Send,
-- OnBattleNetMessage). A Battle.net message can only come from a Battle.net friend. The same person
-- on the friend list and on Battle.net is one friend; the character whisper is preferred.
--
-- Which friend belongs to which own char (1.2.0 fix): fdb.ties[list name] = { chars = { [own char]
-- = scans missed in a row }, bn = last seen on Battle.net, seen = last seen anywhere, full = the full
-- name bound at the first contact when the list has no surname }. A friend is gone only when every
-- own char that had him missed him in MISS_SCANS non-empty scans in a row and he was not seen for
-- GONE_DAYS own play days; an empty or unloaded list never removes anybody.
--
-- 1.2.0, all additive:
-- * Time is counted in own play days (fdb.days: days on which a char of this account was logged in), never
--   in calendar days of the own absence (tie.seenDay, tie.bnDay). A Battle.net friend counts as there while
--   he is on the Battle.net list (tie.bnTag, a hash of his BattleTag, never the tag itself), online or not.
-- * An own char loses a friend only through misses of its own scans: a char that is not logged in loses
--   nothing, play days of other chars never count against it (fdb.mineAt[char] = { t, day } is only noted).
-- * The bound full name (tie.full) is provisional until it is proven: the friend's hello over whisper carries
--   his GUID, which must be the one the friend list gives (tie.sure, tie.guid), or the player chose it. A
--   second full name with the same first name before that is a conflict (tie.rival): nothing of either is
--   taken, the data of the bound one stays without alarm, the player chooses ("Das ist mein Freund") or
--   loosens the tie ("Bindung loesen"); removing the friend from the list loosens it too.
-- * "since" of a hello to a friend: the last logout of the logged-in char (fdb.lastOnlineBy), and everything
--   for a friend this char never heard from (tie.heard[char], set once his answer to the own hello came in full).

local ADDON, ns = ...
-- Texte (1.2.0): L.KEY nur in Funktionen lesen; gespeichert und gesendet wird nie Uebersetztes
local L, Fmt = ns.L, ns.F
local Util = ns.Util
local Guild = ns.Guild
if type(Guild) ~= "table" or type(Guild.Bridge) ~= "table" then return end

local B, P, C = Guild.Bridge, Guild.Proto, Guild.C
local Call, IsSecret, Str = Util.Call, Util.IsSecret, Util.Str

local Friends = {}
ns.Friends = Friends

local FC = {
  PEERS_MAX = 10,          -- friends with DeathNote served at once: every live message goes to each
  HELLO_MAX = 30,          -- hellos per HELLO_WINDOW (sliding), friend list order
  HELLO_WINDOW = 600,
  HELLO_GAP = 300,         -- one hello per friend every 5 min at most
  HELLO_MIN = 22, HELLO_MAX_DELAY = 34,   -- after the guild hello (8 to 20 s) and its answers
  ONLINE_MIN = 25, ONLINE_MAX = 40,       -- a friend came online: after his own guild hello (8 to 20 s)
  HELLO_RETRY = 15, HELLO_TRIES = 12,     -- a hello that found the queue full is tried again
  -- an answer waits until the shared queue has room for a whole one (R + M + X + J + A)
  REPLY_ROOM = C.REPLY_MAX + C.LISTED_REPLY + C.UNLISTED_REPLY + C.HUNT_REPLY + C.HUNTOFF_REPLY,
  REPLY_WAIT = 10, REPLY_TRIES = 12,
  FAIL_MAX = 3,            -- refused whispers in a row to one friend: that friend rests for the session
  SCAN_DELAY = 1,          -- friend list events come in bursts: one scan
  PURGE_AFTER = 20,        -- removed friends are purged by scans this long after the login
  MISS_SCANS = 3,          -- non-empty scans in a row without the friend (per own char)
  GONE_DAYS = 14,          -- ... own play days (1.2.0: not calendar days)
  BN_KEEP_DAYS = 60,       -- a Battle.net friend neither seen nor on the Battle.net list for this many play days
  MAX_HEARD = 20,          -- own chars remembered per friend (tie.heard)
  MAX_TIES = 400,
  IMPOSTOR_SHOW = 600,     -- a refused second full name stays in the status line this long
  SYNC_COOLDOWN = 60,
  MAX_MEMBERS = 100, MEMBER_MAX_AGE = 60 * 86400,
  MAX_FRIENDS = 200, MAX_MINE = 50,
}
Friends.C = FC

local fdb                -- DeathNoteDB.friends = { enemies, members, hunts, huntOff, mine, ties, lastOnline }
local fstore = { enemies = {}, count = 0, bySender = {}, listedBySender = {} }
local EMPTY = {}
local stats = { sent = 0, received = 0, dropped = 0, strangers = 0, mates = 0, hellos = 0,
  listReceived = 0, listDropped = 0, unlistReceived = 0, unlistDropped = 0, huntReceived = 0 }
local FCTX = { src = "friends", store = fstore, stats = stats, fresh = {}, helloAt = nil }
Friends.store, Friends.stats = fstore, stats

local roster = {}        -- lower first word -> array of friends { name, first, surname, online, listed, bn }
local byName = {}        -- name as the friend list gives it -> friend
local order = {}         -- friends in list order
local known = false      -- the friend list was read at least once
local peers, peerN = {}, 0   -- list name -> true: heard with DeathNote in this session (live targets)
local helloAt, helloLog = {}, {}
local helloFrom, replies, mateFrom = {}, {}, {}
local helloRetry = {}    -- list name -> tries of a hello that found the queue full
local flood = {}
local blocked = false    -- the realm refuses whispers altogether (no success, several friends refused)
local suspended, failsOf, failedFriends, totalFails = {}, {}, {}, 0
local impostorSeen = {}
local proven = {}   -- list name -> true: a hello with the GUID of the list came in this session (sender without surname)
local loginAt
local muted                -- lower full names of bound friends in a conflict (no alarm), nil when none
local scanPending = false
local lastSync
local scratch = {}
local on = true          -- setting guild.friends, cached (read on every whisper)

local function now() return time() end
local function After(d, fn)
  local A = _G.C_Timer and _G.C_Timer.After
  if A then A(d, fn) else fn() end
end

-- own play days (1.2.0): counted once per calendar day on which a char of this account is logged in
local function countDay()
  if not fdb then return end
  local d = math.floor(now() / 86400)
  -- only a later calendar day counts (a clock set back and forth again counts nothing twice)
  if not P.Finite(fdb.dayAt) or d > fdb.dayAt then fdb.dayAt = d; fdb.days = (fdb.days or 0) + 1 end
end
local function days() return fdb and fdb.days or 0 end

-- a BattleTag is never stored, only a short hash of it (enough to find the friend on the list again)
local function tagHash(tag)
  if IsSecret(tag) or type(tag) ~= "string" or tag == "" or #tag > 64 or tag:find("[%c|]") then return nil end
  local h = 5381
  for i = 1, #tag do h = (h * 33 + tag:byte(i)) % 4294967296 end
  return ("%08x"):format(h)
end

-- the GUID of a char as the client gives it (UnitGUID, friend list), nil when unusable
local function guidOf(v)
  v = Str(v)
  return v and P.ValidGUID(v) and v or nil
end

---------------------------------------------------------------------------
-- Friend list
---------------------------------------------------------------------------
-- "Name Surname-Realm" -> "Name", "Surname"; "Name-Realm" / "Name" -> "Name", nil
local function split(name)
  local short = name:match("^([^%-]+)") or name
  local first, sur = short:match("^(%S+)%s+(.+)$")
  if not first then first = short end
  return first, sur
end

-- the full name bound to a friend listed without surname (first valid contact), or nil
local function boundOf(x)
  local tie = fdb and fdb.ties[x.name]
  return tie and tie.full or nil
end
-- surname of a friend: from the list, else from the bound full name
local function surnameOf(x)
  if x.surname then return x.surname end
  local b = boundOf(x)
  return b and b:match("^%S+%s+(.+)$") or nil
end

-- The friend behind a sender or char name, or nil. First names must match; when both sides
-- carry a surname, it must match too (a stranger with the same first name stays out).
local function friendOf(short)
  if IsSecret(short) or type(short) ~= "string" or short == "" then return nil end
  local first, sur = split(short)
  local l = roster[first:lower()]
  if not l then return nil end
  for i = 1, #l do
    local f = l[i]
    if not (f.surname and sur and f.surname:lower() ~= sur:lower()) then return f end
  end
  return nil
end
Friends.FriendOf = friendOf

local function fullOf(x) return x.surname and (x.first .. " " .. x.surname) or x.first end

-- the tie of a friend (created on demand)
local function tieOf(name)
  local ties = fdb.ties
  local tie = ties[name]
  if not tie then
    tie = { chars = {} }
    ties[name] = tie
  end
  return tie
end

-- Reads the friend list. Returns true and the friends who came online since the last read.
local function scan()
  local CF = _G.C_FriendList
  if not (CF and CF.GetNumFriends and CF.GetFriendInfoByIndex) then return false end
  local n = Util.Num(Call(CF.GetNumFriends)) or 0
  local newRoster, newBy, newOrder, came = {}, {}, {}, {}
  local function compatible(first, sur)
    local l = newRoster[first:lower()]
    if not l then return nil end
    for i = 1, #l do
      local f = l[i]
      if not (f.surname and sur and f.surname:lower() ~= sur:lower()) then return f end
    end
  end
  local listed = 0
  for i = 1, math.min(n, FC.MAX_FRIENDS) do
    local f = Call(CF.GetFriendInfoByIndex, i)
    if type(f) == "table" and not IsSecret(f) then
      local name = Str(f.name)
      if name and #name <= 80 and not name:find("[%c|]") then
        local first, sur = split(name)
        local x = { name = name, first = first, surname = sur, online = Util.True(f.connected), listed = true }
        x.listOnline = x.online
        -- 1.2.0: the GUID the friend list gives (FriendGroups/FriendGroups.lua: info.guid)
        x.guid = not IsSecret(f.guid) and guidOf(f.guid) or nil
        local k = first:lower()
        local l = newRoster[k]
        if not l then l = {}; newRoster[k] = l end
        l[#l + 1] = x
        newBy[name] = x
        newOrder[#newOrder + 1] = x
        listed = listed + 1
        local old = byName[name]
        if x.online and known and not (old and old.online) then came[#came + 1] = x end
      end
    end
  end
  -- Battle.net friends in this game: the same roster; the same person on the friend list (first
  -- name equal, surnames when both have one) is one friend (1.2.0 fix)
  local BN = _G.C_BattleNet
  local nb = _G.BNGetNumFriends and Util.Num(Call(_G.BNGetNumFriends)) or 0
  local bnSeen, bnTags, bnTagOf = {}, {}, {}
  if nb > 0 and BN and BN.GetFriendAccountInfo then
    for i = 1, math.min(nb, FC.MAX_FRIENDS) do
      local a = Call(BN.GetFriendAccountInfo, i)
      -- 1.2.0: every account on the Battle.net list, also offline ones, by the hash of its tag
      local tag = type(a) == "table" and not IsSecret(a) and tagHash(a.battleTag) or nil
      if tag then bnTags[tag] = true end
      local g = type(a) == "table" and not IsSecret(a) and a.gameAccountInfo
      if type(g) == "table" and not IsSecret(g) and Util.True(g.isOnline) and Str(g.clientProgram) == (_G.BNET_CLIENT_WOW or "WoW")
        and (not _G.WOW_PROJECT_ID or Util.Num(g.wowProjectID) == _G.WOW_PROJECT_ID) then
        local name, id = Str(g.characterName), Util.Num(g.gameAccountID)
        if name and id and #name <= 80 and not name:find("[%c|]") then
          local first, sur = split(name)
          local x = newBy[name] or compatible(first, sur)
          if not x then
            x = { name = name, first = first, surname = sur }
            local k = first:lower()
            local l = newRoster[k]
            if not l then l = {}; newRoster[k] = l end
            l[#l + 1] = x
            newBy[name] = x
            newOrder[#newOrder + 1] = x
          end
          local was = x.online
          x.bn, x.online = id, true
          bnSeen[x.name] = true
          if tag then bnTagOf[x.name] = tag end
          local old = byName[x.name]
          if known and not was and not (old and old.online) then came[#came + 1] = x end
        end
      end
    end
  end
  roster, byName, order = newRoster, newBy, newOrder
  known = true
  -- ties: who is on the list of this char; misses only count for a list that is there at all
  if fdb then
    local t, mine, d = now(), B.myFullName(), days()
    for name in pairs(bnSeen) do
      local tie = tieOf(name)
      tie.bn, tie.seen, tie.bnDay, tie.seenDay = t, t, d, d
      if bnTagOf[name] then tie.bnTag = bnTagOf[name] end
    end
    -- on the Battle.net list (online or not): still a friend
    if next(bnTags) then
      for _, tie in pairs(fdb.ties) do
        if tie.bnTag and bnTags[tie.bnTag] and tie.bn then tie.bnDay = d end
      end
    end
    if listed > 0 and mine then
      for i = 1, #newOrder do
        local x = newOrder[i]
        if x.listed then
          local tie = tieOf(x.name)
          tie.chars[mine] = 0
          tie.seen, tie.seenDay = t, d
        end
      end
      for name, tie in pairs(fdb.ties) do
        local x = newBy[name]
        if tie.chars[mine] and not (x and x.listed) then
          tie.chars[mine] = tie.chars[mine] + 1
          -- 1.2.0: taken off the list: the bound full name is loosened (the next contact binds anew)
          if (tie.full or tie.rival) and tie.chars[mine] >= FC.MISS_SCANS then Friends.Loosen(name, false) end
        end
      end
    end
  end
  -- peers who went offline or left the list are no longer served
  for name in pairs(peers) do
    local x = byName[name]
    if not x or not x.online then peers[name] = nil; peerN = peerN - 1 end
  end
  return true, came
end
Friends.Scan = scan

-- 1.2.0: a friend is a guildmate only with his full name (the list's or the bound one); without a
-- known surname he is served as a friend (Guild.IsGuildmate never takes a first name alone as proof)
local function isMate(x)
  local sur = surnameOf(x)
  return sur ~= nil and Guild.IsGuildmate(x.first .. " " .. sur)
end

---------------------------------------------------------------------------
-- Sending (the shared queue in Sync.lua, channel WHISPER)
---------------------------------------------------------------------------
function Friends.Enabled() return on and fdb ~= nil end

-- One message to one friend: the character whisper when he is on the friend list and online there
-- (and his whispers are not resting), else Battle.net. Returns the queue's answer.
local function sendTo(x, text, kind)
  local whisper = x.listed and x.listOnline and not suspended[x.name]
  if not whisper and not x.bn then return false end
  return B.enqueue(text, kind, whisper and "WHISPER" or "BN", x.name)
end

-- game account of a Battle.net friend (the queue asks right before sending)
function Friends.BNTarget(name)
  local x = byName[name]
  return x and x.bn or nil
end

-- Called by the queue right before a whisper goes out.
function Friends.MaySend(target, channel)
  if not on or blocked then return false end
  local x = byName[target]
  if x == nil or x.online ~= true then return false end
  if channel == "WHISPER" and suspended[target] then return false end
  return true
end

-- Result of one message to a friend (after the stats were counted by the queue). Refusals count per
-- friend: three in a row and that friend rests for the session (Battle.net stays open for him).
-- Only when nothing ever got through and two or more friends were refused, the realm refuses
-- whispers: then the friends' book is quiet for the session.
function Friends.OnSent(target, outcome, channel)
  if channel == "BN" then return end
  if outcome == "ok" or outcome == "throttle" then
    if outcome == "ok" then failsOf[target] = 0 end
    return
  end
  failsOf[target] = (failsOf[target] or 0) + 1
  totalFails = totalFails + 1
  if not failedFriends[target] then failedFriends[target] = true end
  if failsOf[target] >= FC.FAIL_MAX and not suspended[target] then
    suspended[target] = true
    stats.lastReason = "refused"
    B.updated()
  end
  if stats.sent == 0 and not blocked and totalFails >= FC.FAIL_MAX then
    local n = 0
    for _ in pairs(failedFriends) do n = n + 1 end
    if n >= 2 then
      blocked = true
      stats.lastReason = "blocked"
      B.updated()
    end
  end
end

-- A live message (K, M, X, S, J, A, E) to every friend who answered in this session.
-- mates = true (only J/A/E of a release for friends alone): friends in the own guild who use
-- DeathNote get it by whisper too (1.2.0, they hear no friends' list on GUILD).
function Friends.Broadcast(text, kind, mates)
  if not text or not on or blocked or not fdb then return 0 end
  local n = 0
  for name in pairs(peers) do
    local x = byName[name]
    if x and x.online and not isMate(x) then
      if sendTo(x, text, kind) then n = n + 1 end
    end
  end
  if mates then
    -- 1.2.0: also a friend who answered as a friend and became a guildmate since (the first loop
    -- left him out as a mate; peers or not does not matter here)
    -- A friend listed without surname is taken when a guildmate with his first name uses DeathNote (the
    -- whisper goes to the friend himself, so a namesake never gets it); doubles of the first loop are skipped.
    for i = 1, #order do
      local x = order[i]
      local first = peers[x.name] and not isMate(x)
      if x.online and not first and (isMate(x) or not surnameOf(x)) and Guild.HasAddon(fullOf(x)) then
        if sendTo(x, text, kind) then n = n + 1 end
      end
    end
  end
  return n
end

-- 1.2.0: per own char and friend. The last logout of the logged-in char (not of the account), and
-- all the way back for a friend this char never heard from.
local function since(x)
  local mine = B.myFullName()
  local tie = x and fdb and fdb.ties[x.name]
  local heard = tie and type(tie.heard) == "table" and mine and tie.heard[mine]
  local last = mine and fdb and type(fdb.lastOnlineBy) == "table" and fdb.lastOnlineBy[mine] or nil
  if not heard then last = nil end
  return P.Since(now(), last, fstore.count == 0 or last == nil)
end

-- hellos in the sliding window (1.2.0 fix: no longer a fixed number per session)
function Friends.HelloText(x)
  return P.EncodeHello(since(x), B.addonVersion(), guidOf(Call(_G.UnitGUID, "player")))
end

local function hellosNow(gt)
  local i = 1
  while helloLog[i] and gt - helloLog[i] > FC.HELLO_WINDOW do i = i + 1 end
  if i > 1 then
    for k = 1, #helloLog - i + 1 do helloLog[k] = helloLog[k + i - 1] end
    for k = #helloLog, #helloLog - i + 2, -1 do helloLog[k] = nil end
  end
  return #helloLog
end

local sendHelloTo
-- A hello that found the queue full is tried again later (1.2.0 fix: it was lost and booked)
local function retryHello(name)
  local tries = (helloRetry[name] or 0) + 1
  if tries > FC.HELLO_TRIES then helloRetry[name] = nil; return end
  helloRetry[name] = tries
  After(FC.HELLO_RETRY, function()
    if not helloRetry[name] then return end
    local x = byName[name]
    if x then sendHelloTo(x, true, true) else helloRetry[name] = nil end
  end)
end

sendHelloTo = function(x, force, retry)
  if not on or blocked or not fdb or not x.online or isMate(x) then return false end
  local gt = GetTime()
  if not force and helloAt[x.name] and gt - helloAt[x.name] < FC.HELLO_GAP then return false end
  if hellosNow(gt) >= FC.HELLO_MAX then return false end
  if peerN >= FC.PEERS_MAX and not peers[x.name] then return false end
  -- 1.2.0: the own GUID goes with the hello to a friend (never on GUILD), the friend checks it
  -- against his friend list
  local ok, why = sendTo(x, Friends.HelloText(x), "H")
  if not ok and why ~= "dup" then
    if why == "full" and (retry or not helloRetry[x.name]) then retryHello(x.name) end
    return false
  end
  -- booked only once it is on its way
  helloRetry[x.name] = nil
  helloAt[x.name] = gt
  helloLog[#helloLog + 1] = gt
  stats.hellos = stats.hellos + 1
  return true
end

local function helloAll(force)
  local n = 0
  for i = 1, #order do
    if order[i].online and sendHelloTo(order[i], force) then n = n + 1 end
  end
  return n
end

---------------------------------------------------------------------------
-- Receiving
---------------------------------------------------------------------------
local function notePeer(x, short, version)
  if not peers[x.name] and peerN < FC.PEERS_MAX then
    peers[x.name] = true
    peerN = peerN + 1
  end
  local mem = fdb.members
  local m = mem[x.name]
  if not m then
    local n = 0
    for _ in pairs(mem) do n = n + 1 end
    if n >= FC.MAX_MEMBERS then return end
    m = {}
    mem[x.name] = m
  end
  m.name, m.lastHeard = short, now()
  if version then m.version = version end
  B.touchMembers()
end

local function sendAnswer(name)
  local r = replies[name]
  replies[name] = nil
  local x = byName[name]
  if not r or not x or not x.online or not on or blocked or not fdb or isMate(x) then return end
  if Guild.QueueRoom() < FC.REPLY_ROOM then
    -- the queue is busy (guild answer, other friends): wait instead of dropping
    r.tries = r.tries + 1
    if r.tries <= FC.REPLY_TRIES then
      replies[name] = r
      After(FC.REPLY_WAIT, function() sendAnswer(name) end)
    end
    return
  end
  -- the answer begins with the own hello (with GUID): the friend can check who sends before the data comes
  -- (a hello he answered already within HELLO_PER_SENDER is not answered again: no loop)
  sendTo(x, Friends.HelloText(x), "H")
  B.answer(FCTX, r.since, function(text, kind) return sendTo(x, text, kind) end)
end

local function answerLater(x, s)
  local gt = GetTime()
  local last = helloFrom[x.name]
  if last and gt - last < C.HELLO_PER_SENDER then return end
  helloFrom[x.name] = gt
  local r = replies[x.name]
  if r then
    if s < r.since then r.since = s end
    return
  end
  replies[x.name] = { since = s, tries = 0 }
  After(C.REPLY_MIN + math.random() * (C.REPLY_MAX_DELAY - C.REPLY_MIN), function() sendAnswer(x.name) end)
end

-- a second full name with the first name of a bound friend: refused, named once in the status line
local function impostor(x, short)
  stats.strangers = stats.strangers + 1
  local k = short:lower()
  if impostorSeen[k] then return end
  impostorSeen[k] = true
  stats.impostor = { name = short, friend = x.name, at = GetTime() }
  B.updated()
end

local MATE_KINDS = { J = true, A = true, E = true }

-- the muted names (bound friends in a conflict: their data stays, without alarm)
local function remute()
  local m
  for _, tie in pairs(fdb.ties) do
    if tie.rival and tie.full then m = m or {}; m[tie.full:lower()] = true end
  end
  muted = m
end

-- drops the data of one full name from the friends' book (deeds as victim, listings, releases)
local function dropChar(full)
  if type(full) ~= "string" then return 0 end
  local lf = full:lower()
  local n = P.PurgeChars(fstore, fdb.hunts, function(char) return type(char) ~= "string" or char:lower() ~= lf end)
  if n > 0 then B.setHook(); B.updated() end
  return n
end

-- Who is behind a full name for a friend listed without surname (1.2.0)? Returns true when the
-- message may be taken. The first contact binds provisionally; a GUID-proven hello or the player's choice
-- binds for good; a second full name before that is a conflict the player resolves.
local function identity(x, tie, short, m, mate)
  -- a sender the client names without surname: when the list gives the friend's GUID, a hello with that GUID
  -- in this session is the proof (no way around the GUID check); without a GUID on the list as before
  if not short:find(" ", 1, true) then
    if not x.guid then return true end
    if m.kind == "H" then
      if m.guid == x.guid then proven[x.name] = true; return true end
      proven[x.name] = nil
      impostor(x, short)
      return false
    end
    return proven[x.name] == true
  end
  if x.surname then return true end
  local ls = short:lower()
  -- a guildmate (full name in the roster or on GUILD) whispers releases for friends alone without a hello
  if mate and MATE_KINDS[m.kind] and not tie.rival and (not tie.full or tie.full:lower() == ls) then return true end
  -- the friend's hello with GUID, and the friend list gives one: the strong proof
  if m.kind == "H" and m.guid and x.guid then
    if m.guid == x.guid then
      -- a binding the GUID or the player confirmed is not deleted silently: its data stays until the clean-up
      if tie.full and tie.full:lower() ~= ls and not tie.sure then dropChar(tie.full) end
      if tie.rival and tie.rival:lower() ~= ls then dropChar(tie.rival) end
      tie.full, tie.sure, tie.guid, tie.rival, tie.said = short, true, m.guid, nil, nil
      remute()
      return true
    end
    -- not the char on the list: a stranger; a provisional binding to him ends here
    if tie.full and tie.full:lower() == ls and not tie.sure then
      dropChar(tie.full)
      tie.full, tie.rival, tie.said = tie.rival, nil, nil
      remute()
    end
    impostor(x, short)
    return false
  end
  -- the friend list gives his GUID: only a sender proven by it is taken (every 1.2.0 sends its GUID with the
  -- hello to a friend, and its answers begin with that hello); no name comparison as proof any more
  if x.guid then
    if tie.sure and tie.guid == x.guid and tie.full and tie.full:lower() == ls then return true end
    -- never silent: a sender without the proof is named once in the status line
    impostor(x, short)
    return false
  end
  if not tie.full then tie.full = short; return true end
  if tie.full:lower() == ls then return tie.rival == nil end
  if tie.rival and tie.rival:lower() == ls then return false end
  -- a second full name: proven or chosen binding -> a stranger; else a conflict for the player
  if tie.sure then impostor(x, short); return false end
  tie.rival = short
  remute()
  B.updated()
  if not tie.said then
    tie.said = true
    Friends.SayConflict(x.name, tie)
  end
  return false
end

local function heard(x, text, short, full, channel)
  -- a friend in the own guild: everything comes on GUILD (no doubles), except the releases for
  -- friends alone (J/A/E), which go to him by whisper too
  local mate = Guild.IsGuildmate(short)
  if mate and not text:find("^%d+\t[JAE]\t") then stats.mates = stats.mates + 1; return end
  local t = now()
  if not P.Flood(flood, x.name, t) then stats.dropped = stats.dropped + 1; stats.lastReason = "flood"; return end
  local m, why = P.Decode(text, t, scratch)
  if not m then stats.dropped = stats.dropped + 1; stats.lastReason = why; return end
  if mate and not MATE_KINDS[m.kind] then stats.mates = stats.mates + 1; return end
  local tie = tieOf(x.name)
  -- a friend listed without surname: the full name behind him (1.2.0; Battle.net names are given
  -- by the game itself and need no check)
  if channel ~= "BN" and not identity(x, tie, short, m, mate) then
    stats.dropped = stats.dropped + 1; stats.lastReason = "identity"
    return
  end
  stats.received = stats.received + 1
  stats.lastSender = full
  stats.senderForm = short:find(" ", 1, true) and "full" or "first"
  local d = days()
  tie.seen, tie.seenDay = t, d
  if x.bn then tie.bn, tie.bnDay = t, d end
  if not mate then notePeer(x, short, m.version) end
  if m.kind == "H" then answerLater(x, m.since); return end
  FCTX.helloAt = helloAt[x.name]
  local z = m.kind == "Z" and helloAt[x.name] and GetTime() - helloAt[x.name] <= C.ANSWER_WINDOW
  B.apply(FCTX, m, short, full, t, not short:find(" ", 1, true) and surnameOf(x) or nil)
  -- 1.2.0: this char heard from this friend (since of the next hello) only once his ANSWER to the own hello
  -- came in full (it ends with Z); his hello alone does not count
  local mine = B.myFullName()
  if z and mine then
    if type(tie.heard) ~= "table" then tie.heard = {} end
    if tie.heard[mine] or Friends.CountKeys(tie.heard) < FC.MAX_HEARD then tie.heard[mine] = t end
  end
end

-- Hot path for whispers of strangers: one pattern, one lower(), one table lookup, no decoding.
function Friends.OnWhisper(text, sender)
  if not on or not fdb or IsSecret(sender) or type(sender) ~= "string" then return end
  local w = sender:match("^([^%s%-]+)")
  if not w or not roster[w:lower()] then stats.strangers = stats.strangers + 1; return end
  local short, full = Guild.SenderName(sender)
  if not short or Guild.IsMe(short) then return end
  local x = friendOf(short)
  if not x then stats.strangers = stats.strangers + 1; return end
  heard(x, text, short, full, "WHISPER")
end

-- BN_CHAT_MSG_ADDON (prefix, text, channel, gameAccountID): other addons use it too, so the prefix first.
function Friends.OnBattleNet(_, prefix, text, _, id)
  if IsSecret(prefix) or prefix ~= Guild.PREFIX then return end
  if not on or not fdb or IsSecret(text) or IsSecret(id) or type(text) ~= "string" or type(id) ~= "number" then return end
  local BN = _G.C_BattleNet
  local g = BN and BN.GetGameAccountInfoByID and Call(BN.GetGameAccountInfoByID, id)
  if type(g) ~= "table" or IsSecret(g) then return end
  if _G.WOW_PROJECT_ID and Util.Num(g.wowProjectID) ~= _G.WOW_PROJECT_ID then return end
  local name = Str(g.characterName)
  if not name or #name > 80 or name:find("[%c|]") then return end
  local short = name:match("^([^%-]+)") or name
  if Guild.IsMe(short) then return end
  -- the same person on the friend list is the same friend (1.2.0 fix)
  local x = byName[name] or friendOf(short)
  if not x then
    -- not in the last scan (came online just now): a Battle.net friend all the same
    local first, sur = split(name)
    x = { name = name, first = first, surname = sur, online = true }
    local k = first:lower()
    roster[k] = roster[k] or {}
    table.insert(roster[k], x)
    byName[name] = x
    order[#order + 1] = x
  end
  x.bn, x.online = id, true
  heard(x, text, short, name, "BN")
end

function Friends.CountKeys(t)
  local n = 0
  for _ in pairs(t) do n = n + 1 end
  return n
end

---------------------------------------------------------------------------
-- Ties of friends listed without surname: what the player sees and decides (1.2.0)
---------------------------------------------------------------------------
-- once per conflict a clear line in the chat with both names (the status line says it as long as it lasts)
function Friends.SayConflict(listName, tie)
  if not ns.Util or not ns.Util.Print or not L.CHAT_FRIENDS_CONFLICT then return end
  ns.Util.Print(Fmt(L.CHAT_FRIENDS_CONFLICT, { friend = (listName:match("^([^%-]+)") or listName),
    a = tie.full or "?", b = tie.rival or "?" }))
end

-- Loosens the tie of a friend (list name): the next contact binds anew. drop = true also deletes what the
-- bound name brought into the friends' book ("Bindung loesen", with a question first in the book).
function Friends.Loosen(listName, drop)
  if not fdb or IsSecret(listName) or type(listName) ~= "string" then return false end
  local tie = fdb.ties[listName]
  if not tie or not (tie.full or tie.rival) then return false end
  if drop then dropChar(tie.full); dropChar(tie.rival); tie.heard = nil end
  tie.full, tie.sure, tie.guid, tie.rival, tie.said = nil, nil, nil, nil, nil
  impostorSeen = {}
  remute()
  B.updated()
  return true
end
function Friends.Unbind(listName) return Friends.Loosen(listName, true) end

-- The player says who his friend is: `full` is bound for good, the other name's data goes.
function Friends.Choose(listName, full)
  if not fdb or IsSecret(listName) or IsSecret(full) or type(listName) ~= "string" or type(full) ~= "string" then return false end
  local tie = fdb.ties[listName]
  if not tie then return false end
  local lf = full:lower()
  if tie.rival and tie.rival:lower() == lf then
    dropChar(tie.full)
    tie.full, tie.heard = tie.rival, nil
  elseif not (tie.full and tie.full:lower() == lf) then
    return false
  else
    dropChar(tie.rival)
  end
  tie.sure, tie.rival, tie.said = true, nil, nil
  impostorSeen = {}
  remute()
  B.setHook()
  B.updated()
  return true
end

-- bound and contested full names: lower name -> { list, full, rival, sure, conflict }
function Friends.TieIndex()
  local out = {}
  if not fdb then return out end
  for name, tie in pairs(fdb.ties) do
    if tie.full then
      local info = { list = name, full = tie.full, rival = tie.rival, sure = tie.sure == true, conflict = tie.rival ~= nil }
      out[tie.full:lower()] = info
      if tie.rival then out[tie.rival:lower()] = info end
    end
  end
  return out
end

-- conflicts waiting for the player: array of { list, full, rival }
function Friends.Conflicts()
  local out = {}
  if not fdb then return out end
  for name, tie in pairs(fdb.ties) do
    if tie.full and tie.rival then out[#out + 1] = { list = name, full = tie.full, rival = tie.rival } end
  end
  table.sort(out, function(a, b) return a.list < b.list end)
  return out
end

-- bound full names for /dn freunde: array of { list, full, sure }
function Friends.Bound()
  local out = {}
  if not fdb then return out end
  for name, tie in pairs(fdb.ties) do
    if tie.full then out[#out + 1] = { list = name, full = tie.full, sure = tie.sure == true, rival = tie.rival } end
  end
  table.sort(out, function(a, b) return a.list < b.list end)
  return out
end

-- a char of a bound friend in a conflict: his data stays, but it does not alarm (Sync.lua, Guild.OnUnit)
function Friends.Muted(char)
  if IsSecret(char) then return false end
  return muted ~= nil and type(char) == "string" and muted[char:lower()] == true
end
function Friends.AnyMuted() return muted ~= nil end

---------------------------------------------------------------------------
-- Own data into the friends' book and out to the friends
---------------------------------------------------------------------------
local function backfill()
  local added = 0
  for _, k in ipairs(B.ownKills(0)) do
    if B.addOwn(k, fstore, true) == "new" then added = added + 1 end
  end
  if B.setting("shareManual") == true then
    for _, l in ipairs(B.ownListed(nil, false)) do
      local res = B.addOwnListed(l, fstore)
      if res == "new" or res == "add" or res == "upd" then added = added + 1 end
    end
  end
  if added > 0 then B.setHook(); B.updated() end
  return added
end

function Friends.OnDeath(journal, key)
  if not on or not fdb or type(journal) ~= "table" or not key or journal.sure ~= true or journal.counted == false then return end
  if journal.kind ~= "pvp" or type(journal.t) ~= "number" or type(journal.me) ~= "string" then return end
  local Store = ns.Store
  local e = Store and Store.Get(key)
  if not e then return end
  local lvl
  for i = 1, #e.deaths do
    if e.deaths[i].t == journal.t then lvl = e.deaths[i].theirLevel; break end
  end
  local k = { key = key, display = Util.Display(e), class = e.class, level = lvl or e.level,
    zone = journal.zone, t = journal.t, victim = journal.me }
  if B.addOwn(k, fstore) == "new" then B.setHook(); B.updated() end
  Friends.Broadcast(P.EncodeKill(k, "K"), "K")
end

function Friends.OnListed(key)
  local Store = ns.Store
  if not on or not fdb or not Store or B.setting("shareManual") ~= true then return end
  local e = Store.Get(key)
  if not B.listable(key, e) then return end
  local mine = B.myFullName()
  if not mine then return end
  if e.by == nil then e.by = mine end
  if e.by ~= mine then return end
  if type(e.listedAt) ~= "number" then e.listedAt = now() end
  local gdb = Guild.DB()
  if gdb and type(gdb.unlisted) == "table" then gdb.unlisted[key] = nil end
  local l = B.listedMsg(key, e)
  local res = B.addOwnListed(l, fstore)
  if res == "new" or res == "add" or res == "upd" then B.setHook(); B.updated() end
  Friends.Broadcast(P.EncodeListed(l), "M")
end

function Friends.OnUnlisted(key, e)
  if not fdb or type(e) ~= "table" or e.manual ~= true or e.fromGuild or e.imported then return end
  local by = e.by
  if type(by) ~= "string" then return end
  if fstore.enemies[key] and P.Unlist(fstore, key, by) then B.setHook(); B.updated() end
  if on and B.setting("shareManual") == true and by == B.myFullName() then
    Friends.Broadcast(P.EncodeUnlisted(key, by), "X")
  end
end

-- A guildmate who is also my friend logged in (his hello on GUILD): my releases for friends alone
-- and their call-offs go to him by whisper (he hears no friends' list on GUILD). 1.2.0.
local function sendMateHunts(name)
  local x = byName[name]
  if not x or not x.online or not on or blocked or not fdb then return end
  local mine = B.myFullName()
  if not mine then return end
  for _, r in ipairs(B.ownHunts(fdb.hunts, C.HUNT_REPLY)) do
    local inG = B.released(r.key)
    if not inG then sendTo(x, P.EncodeHunt(r), "J") end
  end
  local gdb = Guild.DB()
  local gl = gdb and gdb.name and gdb.lists and gdb.lists[gdb.name]
  local gOff = gl and gl.huntOff or EMPTY
  for _, key in ipairs(B.ownTombs(fdb.huntOff, C.HUNTOFF_REPLY)) do
    if not gOff[key] then sendTo(x, P.EncodeCallOff(key, mine), "A") end
  end
end

function Friends.OnMateHello(short)
  if not on or blocked or not fdb or IsSecret(short) or type(short) ~= "string" then return end
  local x = friendOf(short)
  if not x or not x.online then return end
  local gt = GetTime()
  local last = mateFrom[x.name]
  if last and gt - last < C.HELLO_PER_SENDER then return end
  mateFrom[x.name] = gt
  After(C.REPLY_MIN + math.random() * (C.REPLY_MAX_DELAY - C.REPLY_MIN), function() sendMateHunts(x.name) end)
end

---------------------------------------------------------------------------
-- Removed friends: their entries leave at a later clean-up (see the ties at the top)
---------------------------------------------------------------------------
-- updates the ties: an own char lets go of a friend after MISS_SCANS misses and GONE_DAYS own play days
-- unseen (misses come only from scans of exactly this char: a char that is not logged in loses nothing, play days of
-- other chars never count against it); Battle.net after BN_KEEP_DAYS play days neither seen nor on
-- the Battle.net list. Ties without any hold leave. (1.2.0: play days, not calendar days of the own absence)
local function settleTies()
  local d = days()
  local n, oldName, oldT = 0, nil, nil
  for name, tie in pairs(fdb.ties) do
    local unseen = d - (tie.seenDay or d)
    for c, miss in pairs(tie.chars) do
      if miss >= FC.MISS_SCANS and unseen >= FC.GONE_DAYS then tie.chars[c] = nil end
    end
    if tie.bn and d - (tie.bnDay or d) >= FC.BN_KEEP_DAYS then tie.bn, tie.bnDay, tie.bnTag = nil, nil, nil end
    if next(tie.chars) == nil and not tie.bn then
      fdb.ties[name] = nil
    else
      n = n + 1
      if not oldT or (tie.seen or 0) < oldT then oldName, oldT = name, tie.seen or 0 end
    end
  end
  if n > FC.MAX_TIES and oldName then fdb.ties[oldName] = nil end
end

-- is `char` (a name in the data: victim, lister, releaser) an own char or a friend still tied?
local function keeper()
  local byFirst = {}
  for name, tie in pairs(fdb.ties) do
    local first, sur = split(name)
    if not sur and tie.full then sur = tie.full:match("^%S+%s+(.+)$") end
    local k = first:lower()
    byFirst[k] = byFirst[k] or {}
    table.insert(byFirst[k], sur or false)
  end
  -- the answer per name is remembered for this one purge: a full friends' book asks 8000 times for some
  -- hundred names (nothing the answer depends on changes while the purge runs)
  local memo = {}
  local function decide(char)
    if fdb.mine[char] then return true end
    local first, sur = split(char)
    local l = byFirst[first:lower()]
    if not l then return false end
    for i = 1, #l do
      local s = l[i]
      if not (s and sur and s:lower() ~= sur:lower()) then return true end
    end
    return false
  end
  return function(char)
    if type(char) ~= "string" then return false end
    local r = memo[char]
    if r == nil then r = decide(char); memo[char] = r end
    return r
  end
end

function Friends.Purge()
  if not fdb or not known then return 0 end
  settleTies()
  local keep = keeper()
  local n = P.PurgeChars(fstore, fdb.hunts, keep)
  for name in pairs(fdb.members) do
    if not fdb.ties[name] then fdb.members[name] = nil; n = n + 1 end
  end
  if n > 0 then B.touchMembers(); B.setHook(); B.updated() end
  return n
end

local function rescan()
  scanPending = false
  if not fdb then return end
  countDay()
  local ok, came = scan()
  if not ok then return end
  if on then
    for i = 1, #came do
      local x = came[i]
      After(FC.ONLINE_MIN + math.random() * (FC.ONLINE_MAX - FC.ONLINE_MIN), function()
        local y = byName[x.name]
        if y then sendHelloTo(y) end
      end)
    end
  end
  if loginAt and GetTime() - loginAt >= FC.PURGE_AFTER then Friends.Purge() end
  Friends.OnGuildChange()
  B.updated()
end

function Friends.OnFriendList()
  if scanPending or not fdb then return end
  scanPending = true
  After(FC.SCAN_DELAY, rescan)
end

-- 1.2.0: a friend who is no longer a guildmate (he or I left the guild) is greeted by
-- whisper at once, from then on he gets everything that way. Checked on roster and guild events.
local wasMate = {}
local mateCheckPending = false
local function mateCheck()
  mateCheckPending = false
  if not on or blocked or not fdb then return end
  for i = 1, #order do
    local x = order[i]
    if x.online then
      local m = isMate(x)
      if wasMate[x.name] and not m and not peers[x.name] then sendHelloTo(x, true) end
      wasMate[x.name] = m or nil
    end
  end
end
function Friends.OnGuildChange()
  if mateCheckPending or not fdb then return end
  mateCheckPending = true
  After(FC.SCAN_DELAY + 1, mateCheck)
end

-- "Freundesbuch leeren" (1.2.0): the friends' book and the releases of others in it go; own kills,
-- own hand entries and own releases stay (only their releaser can call them off).
function Friends.Clear()
  if not fdb then return end
  for k in pairs(fdb.enemies) do fdb.enemies[k] = nil end
  fstore.enemies, fstore.count, fstore.bySender, fstore.listedBySender = fdb.enemies, 0, {}, {}
  if type(fdb.huntCleared) ~= "table" then fdb.huntCleared = {} end
  FCTX.cleared = fdb.huntCleared
  P.ClearForeign(fdb.hunts, Guild.IsOwnChar, fdb.huntCleared)
  backfill()
  B.setHook()
  B.updated()
end

---------------------------------------------------------------------------
-- Reading
---------------------------------------------------------------------------
function Friends.hunts() return fdb and fdb.hunts or EMPTY end
function Friends.huntOff() return fdb and fdb.huntOff or EMPTY end
function Friends.members() return fdb and fdb.members or EMPTY end
function Friends.PeerCount() return peerN end
function Friends.Known() return known end
function Friends.Blocked() return blocked end
function Friends.Suspended(name) return suspended[name] == true end

function Friends.OnlineCount()
  local n = 0
  for i = 1, #order do if order[i].online then n = n + 1 end end
  return n, #order
end

-- friends heard with DeathNote: { name, full (list name), version, lastHeard, online, live }
function Friends.MemberList()
  local out = {}
  if not fdb then return out end
  for full, m in pairs(fdb.members) do
    local x = byName[full]
    out[#out + 1] = { name = m.name, full = full, version = m.version, lastHeard = m.lastHeard,
      online = x ~= nil and x.online == true, live = peers[full] == true }
  end
  table.sort(out, function(a, b) return (a.lastHeard or 0) > (b.lastHeard or 0) end)
  return out
end

-- Like Guild.Health: { ok, reason, text (<= 60 chars, no technical words), short (<= 24), detail }
-- reason: "off" | "prefix" | "blocked" | "failing" | "conflict" | "impostor" | "nofriends" | "hold" | "quiet" | "ok"
function Friends.Health()
  local h = {}
  local online = Friends.OnlineCount()
  local imp = stats.impostor
  if not on then
    h.ok, h.reason, h.short = false, "off", L.HEALTH_SHORT_OFF
    h.text = L.FRIENDS_OFF
  elseif B.prefixOK() == false then
    h.ok, h.reason, h.short = false, "prefix", L.SYNC_SHORT_PREFIX
    h.text = L.SYNC_PREFIX
  elseif blocked then
    h.ok, h.reason, h.short = false, "blocked", L.FRIENDS_SHORT_BLOCKED
    h.text = L.FRIENDS_BLOCKED
    h.detail = "SendAddonMessage WHISPER: " .. tostring(stats.lastFail)
  elseif next(suspended) ~= nil or stats.hardFail or (stats.failStreak or 0) >= FC.FAIL_MAX then
    h.ok, h.reason, h.short = false, "failing", L.FRIENDS_SHORT_FAILING
    h.text = L.FRIENDS_FAILING
    h.detail = "SendAddonMessage WHISPER: " .. tostring(stats.lastFail)
  elseif next(Friends.Conflicts()) ~= nil then
    -- 1.2.0: two full names for one friend, the player decides (shown until he did)
    local c = Friends.Conflicts()[1]
    h.ok, h.reason, h.short = false, "conflict", L.FRIENDS_SHORT_CONFLICT
    h.text = Fmt(L.FRIENDS_CONFLICT, { friend = (c.list:match("^([^%-]+)") or c.list), a = c.full, b = c.rival })
  elseif imp and GetTime() - imp.at < FC.IMPOSTOR_SHOW then
    h.ok, h.reason, h.short = false, "impostor", L.FRIENDS_SHORT_IMPOSTOR
    h.text = Fmt(L.FRIENDS_IMPOSTOR, { name = imp.name, friend = (imp.friend:match("^([^%-]+)") or imp.friend) })
  elseif peerN == 0 and online == 0 then
    h.ok, h.reason, h.short = false, "nofriends", L.FRIENDS_SHORT_NONE_ONLINE
    h.text = known and #order == 0 and L.FRIENDS_NONE_LISTED or L.FRIENDS_NONE_ONLINE
  elseif peerN == 0 and stats.hellos > 0 then
    h.ok, h.reason, h.short = true, "quiet", L.HEALTH_SHORT_ASKED
    h.text = L.FRIENDS_QUIET
  elseif peerN == 0 then
    h.ok, h.reason, h.short = true, "ok", L.HEALTH_SHORT_ASKED
    h.text = L.FRIENDS_READY
  else
    local why = B.holdReason()
    if why and Guild.QueueSize() > 0 then
      h.ok, h.reason, h.short = true, "hold", L.HEALTH_SHORT_HOLD
      h.text = L.FRIENDS_HOLD
    else
      h.ok, h.reason, h.short = true, "ok", L.HEALTH_SHORT_ASKED
      h.text = Fmt(L.FRIENDS_RUNNING, { count = peerN })
    end
  end
  return h
end

-- /dn sync: friends again (one minute cool-down). Returns ok, number of hellos or seconds to wait.
function Friends.SyncNow()
  if not on or not fdb then return false, "aus" end
  local gt = GetTime()
  if lastSync and gt - lastSync < FC.SYNC_COOLDOWN then return false, math.ceil(FC.SYNC_COOLDOWN - (gt - lastSync)) end
  lastSync = gt
  scan()
  helloLog = {}
  return true, helloAll(true)
end

-- Block for /dn probe
function Friends.Probe()
  local h = Friends.Health()
  local online, total = Friends.OnlineCount()
  local n = 0
  for _ in pairs(fdb and fdb.members or EMPTY) do n = n + 1 end
  local ns2 = 0
  for _ in pairs(suspended) do ns2 = ns2 + 1 end
  return { sent = stats.sent, received = stats.received, dropped = stats.dropped, strangers = stats.strangers,
    mates = stats.mates, hellos = stats.hellos, lastSendResult = stats.lastResult, lastReason = stats.lastReason,
    lastSender = stats.lastSender, health = h.reason, detail = h.detail,   -- 1.2.0: no sentence (language) in the file
    -- 1.2.0: name form of the last sender ("full" = with surname, "first" = first name only)
    senderForm = stats.senderForm, suspended = ns2 > 0 and ns2 or nil,
    friends = total, online = online, withAddon = peerN, heard = n, blocked = blocked or nil,
    enabled = on, entries = fstore.count, hunts = (function() local c = 0; for _ in pairs(Friends.hunts()) do c = c + 1 end return c end)(),
    api = (_G.C_FriendList and _G.C_FriendList.GetFriendInfoByIndex) and true or false }
end

---------------------------------------------------------------------------
-- Startup and events
---------------------------------------------------------------------------
local function sanitizeTies(t, d)
  if type(fdb.ties) ~= "table" then fdb.ties = {} end
  for name, tie in pairs(fdb.ties) do
    local good = type(name) == "string" and #name <= 80 and not name:find("[%c|]") and type(tie) == "table"
      and type(tie.chars) == "table"
    if good then
      for c, miss in pairs(tie.chars) do
        if type(c) ~= "string" or type(miss) ~= "number" or miss ~= miss or miss < 0 then tie.chars[c] = nil end
      end
      if tie.bn ~= nil and (type(tie.bn) ~= "number" or tie.bn ~= tie.bn) then tie.bn = nil end
      if tie.seen ~= nil and (type(tie.seen) ~= "number" or tie.seen ~= tie.seen) then tie.seen = nil end
      if tie.seen and tie.seen > t + C.FUTURE then tie.seen = t end
      if tie.full ~= nil and (type(tie.full) ~= "string" or #tie.full > 80 or tie.full:find("[%c|]")
        or not tie.full:find(" ", 1, true)) then tie.full = nil end
      -- 1.2.0 (additive): proof, conflict, play days, Battle.net tag hash, chars that heard him
      if tie.rival ~= nil and (type(tie.rival) ~= "string" or #tie.rival > 80 or tie.rival:find("[%c|]")
        or not tie.rival:find(" ", 1, true) or not tie.full) then tie.rival = nil end
      if tie.sure ~= nil and (tie.sure ~= true or not tie.full) then tie.sure = nil end
      if tie.said ~= nil and tie.said ~= true then tie.said = nil end
      if tie.guid ~= nil and not P.ValidGUID(tie.guid) then tie.guid = nil end
      if tie.bnTag ~= nil and not (type(tie.bnTag) == "string" and tie.bnTag:match("^%x%x%x%x%x%x%x%x$")) then tie.bnTag = nil end
      for _, k in ipairs({ "seenDay", "bnDay" }) do
        local v = tie[k]
        if v ~= nil and not (P.Finite(v) and v >= 0) then tie[k] = nil end
        if tie[k] == nil and (k == "seenDay" or tie.bn) then tie[k] = d end
        if tie[k] and tie[k] > d then tie[k] = d end
      end
      if tie.heard ~= nil then
        if type(tie.heard) ~= "table" then tie.heard = nil else
          local nh = 0
          for c, v in pairs(tie.heard) do
            if type(c) ~= "string" or not P.Finite(v) or nh >= FC.MAX_HEARD then tie.heard[c] = nil else nh = nh + 1 end
          end
        end
      end
    else
      fdb.ties[name] = nil
    end
  end
end

function Friends.Init()
  local db = ns.Store and ns.Store.DB()
  if not db then return end
  if type(db.friends) ~= "table" then db.friends = {} end
  fdb = db.friends
  for _, k in ipairs({ "enemies", "members", "hunts", "huntOff", "mine" }) do
    if type(fdb[k]) ~= "table" then fdb[k] = {} end
  end
  if fdb.lastOnline ~= nil and type(fdb.lastOnline) ~= "number" then fdb.lastOnline = nil end
  local t = now()
  -- 1.2.0: own play days, last login per own char, last logout per own char, cleared releases (additive)
  if fdb.days ~= nil and not (P.Finite(fdb.days) and fdb.days >= 0) then fdb.days = nil end
  if fdb.dayAt ~= nil and not P.Finite(fdb.dayAt) then fdb.dayAt = nil end
  countDay()
  local d = days()
  for _, k in ipairs({ "mineAt", "lastOnlineBy" }) do
    if type(fdb[k]) ~= "table" then fdb[k] = {} end
    local nk = 0
    for c, v in pairs(fdb[k]) do
      local good = type(c) == "string" and nk < FC.MAX_MINE and (k == "lastOnlineBy" and P.Finite(v)
        or k == "mineAt" and type(v) == "table" and P.Finite(v.t) and P.Finite(v.day))
      if good then nk = nk + 1 else fdb[k][c] = nil end
    end
  end
  if fdb.huntCleared ~= nil and type(fdb.huntCleared) ~= "table" then fdb.huntCleared = nil end
  if fdb.huntCleared then P.SanitizeCleared(fdb.huntCleared) end
  FCTX.cleared = fdb.huntCleared
  sanitizeTies(t, d)
  for full, m in pairs(fdb.members) do
    if type(full) ~= "string" or type(m) ~= "table" or type(m.name) ~= "string" or type(m.lastHeard) ~= "number"
      or m.lastHeard < t - FC.MEMBER_MAX_AGE then
      fdb.members[full] = nil
    elseif not fdb.ties[full] then
      -- heard before the ties existed: tied to the logged-in char until the list says otherwise
      local tie = tieOf(full)
      tie.seen = m.lastHeard
    end
  end
  for key, x in pairs(fdb.huntOff) do
    if type(key) ~= "string" or type(x) ~= "table" or type(x.t) ~= "number" or type(x.by) ~= "string"
      or x.t < t - C.TOMB_AGE then
      fdb.huntOff[key] = nil
    end
  end
  local nm = 0
  for char, v in pairs(fdb.mine) do
    if type(char) ~= "string" or v ~= true or nm >= FC.MAX_MINE then fdb.mine[char] = nil else nm = nm + 1 end
  end
  local mine = B.myFullName()
  if mine and nm < FC.MAX_MINE then fdb.mine[mine] = true end
  -- members heard before the ties existed belong to the logged-in char
  if mine then for _, tie in pairs(fdb.ties) do if next(tie.chars) == nil and not tie.bn then tie.chars[mine] = 0 end end end
  -- 1.2.0: when each own char was last logged in (chars of older ties: counted from now on)
  for _, tie in pairs(fdb.ties) do
    for c in pairs(tie.chars) do
      if not fdb.mineAt[c] and Friends.CountKeys(fdb.mineAt) < FC.MAX_MINE then fdb.mineAt[c] = { t = t, day = d } end
    end
  end
  if mine then fdb.mineAt[mine] = { t = t, day = d } end
  fstore.enemies, fstore.count, fstore.bySender, fstore.listedBySender = fdb.enemies, 0, {}, {}
  P.Sanitize(fstore, t)
  remute()
  FCTX.hunts, FCTX.huntOff, FCTX.fresh, FCTX.helloAt = fdb.hunts, fdb.huntOff, {}, nil
  roster, byName, order, known = {}, {}, {}, false
  peers, peerN, helloAt, helloLog, helloFrom, replies, flood, mateFrom = {}, 0, {}, {}, {}, {}, {}, {}
  helloRetry, suspended, failsOf, failedFriends, totalFails, impostorSeen, proven = {}, {}, {}, {}, 0, {}, {}
  stats.impostor = nil
  blocked, scanPending, lastSync = false, false, nil
  loginAt = GetTime()
  on = B.setting("friends") == true
  -- Expiry: own releases of this char call themselves off (1.2.0), the others are repaired
  Guild.ExpireHunts(fdb.hunts, fdb.huntOff, "friends")
  if on then backfill() end
  B.setHook()
  B.updated()
end

function Friends.DB() return fdb end

local function planHello()
  After(FC.HELLO_MIN + math.random() * (FC.HELLO_MAX_DELAY - FC.HELLO_MIN), function()
    if not on or not fdb then return end
    scan()
    helloAll(false)
  end)
end

Guild.AttachFriends(Friends)

ns:On("READY", function()
  Friends.Init()
  -- ask the server for the friend list (FRIENDLIST_UPDATE follows)
  local CF = _G.C_FriendList
  if CF and CF.ShowFriends then Call(CF.ShowFriends) end
  scan()
  planHello()
end)
ns:On("DEATH_RECORDED", Friends.OnDeath)
ns:On("MANUAL_ADDED", function(key) Friends.OnListed(key) end)
ns:On("ENEMY_REMOVED", function(key, e) Friends.OnUnlisted(key, e) end)
ns:On("ENEMY_STATUS", function(key, old, new)
  local e = ns.Store and ns.Store.Get(key)
  if not e then return end
  if old == "wanted" and new ~= "wanted" then Friends.OnUnlisted(key, e)
  elseif new == "wanted" and old ~= "wanted" then Friends.OnListed(key) end
end)
ns:On("ENEMY_REKEYED", function(oldKey, newKey)
  local e = ns.Store and ns.Store.Get(newKey)
  if not e or not B.listable(newKey, e) or type(e.by) ~= "string" then return end
  Friends.OnUnlisted(oldKey, e)
  Friends.OnListed(newKey)
end)
ns:On("SETTINGS_CHANGED", function(path)
  if path == "guild.friends" then
    on = B.setting("friends") == true
    if on and fdb then
      backfill()
      scan()
      helloAll(false)
    else
      peers, peerN = {}, 0
    end
    B.setHook()
    B.updated()
  elseif path == "guild.shareManual" and on and fdb and B.setting("shareManual") == true then
    local listed = B.ownListed(C.LISTED_REPLY, true)
    local changed = false
    for i = 1, #listed do
      local res = B.addOwnListed(listed[i], fstore)
      if res == "new" or res == "add" or res == "upd" then changed = true end
      Friends.Broadcast(P.EncodeListed(listed[i]), "M")
    end
    if changed then B.setHook(); B.updated() end
  end
end)

ns:RegisterEvent("FRIENDLIST_UPDATE", function() Friends.OnFriendList() end)
for _, ev in ipairs({ "BN_FRIEND_INFO_CHANGED", "BN_FRIEND_ACCOUNT_ONLINE", "BN_FRIEND_ACCOUNT_OFFLINE" }) do
  ns:RegisterEvent(ev, function() Friends.OnFriendList() end)
end
ns:RegisterEvent("BN_CHAT_MSG_ADDON", Friends.OnBattleNet)
-- Sync.lua reads the roster again on these; the check runs a moment later
ns:RegisterEvent("GUILD_ROSTER_UPDATE", function() Friends.OnGuildChange() end)
ns:RegisterEvent("PLAYER_GUILD_UPDATE", function() Friends.OnGuildChange() end)
ns:RegisterEvent("PLAYER_LOGOUT", function()
  if not fdb then return end
  local t, mine = now(), B.myFullName()
  fdb.lastOnline = t
  -- 1.2.0: per own char
  if mine and type(fdb.lastOnlineBy) == "table" then fdb.lastOnlineBy[mine] = t end
  if mine and type(fdb.mineAt) == "table" then fdb.mineAt[mine] = { t = t, day = days() } end
end)
