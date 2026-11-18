-- DeathNote - Share.lua (1.5.0 share)
-- "Show": one plain chat line per click that anybody can read, and that a reader with the addon gets as a link.
--   [Revenge Book: Grimwald Ashbrand] WANTED · Score 2 : 5 · 131g bounty · last seen Stranglethorn Vale
-- The bracket is the pattern: the brand from Share.BRAND (the rename sets it here and only here) and the name. The rest
-- are segments in the sender's language, joined by " · ": a reader without the addon reads his guild's language, a
-- reader with it gets the name as a link (the click opens the own poster, else the guild's or friends', else a guest
-- poster that shows the segments as the sender wrote them). The server never forwards self-made links (addon links
-- are local only, hunt-technik §1), so the line is plain text, never "|" from foreign data.
-- Data only here (lines, the Discord block, the week, the chat filter, sending, the probe); the window, the guest
-- poster and the click are ShareUI.lua. Nothing is ever sent without the player's click on a channel in that window
-- (the click is the hardware event SAY needs), never in combat, never in a chat lockdown, at most one line per 10 s.
-- Never in a line: attacks (role "attack"), suspicion, notes, anything copied from someone else's book or read in from
-- a text (an entry made only of such offers no "Show" at all; 1.5.0 fixer: nor the week, nor Discord), names of guildmates or friends (posters of bounties, victims, callers).

local ADDON, ns = ...
local L, Fmt = ns.L, ns.F
local Util = ns.Util
local Share = {}
ns.Share = Share

Share.BRAND = "Revenge Book"   -- the mark of the pattern; the rename sets it here
Share.MAX_BYTES = 255          -- one chat message
Share.NAME_MAX = 60            -- bytes of a name in the bracket (Forever: first name and surname)
Share.SEG_MAX = 80             -- bytes of one segment
Share.SEGS_MAX = 6             -- segments read from a received line
Share.COOLDOWN = 10            -- seconds between two shown lines
Share.WEEK = 7 * 86400
Share.SEP = " \194\183 "       -- " · "
Share.LINK_HEX = "ffe0603a"    -- colour of the link in the chat (red ink that reads on the dark chat frame)
Share.LINKS_MAX = 64           -- received lines kept for a click (oldest go first)
Share.FILTER_EVENTS = { "CHAT_MSG_SAY", "CHAT_MSG_YELL", "CHAT_MSG_GUILD", "CHAT_MSG_OFFICER", "CHAT_MSG_PARTY",
  "CHAT_MSG_PARTY_LEADER", "CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER", "CHAT_MSG_INSTANCE_CHAT",
  "CHAT_MSG_INSTANCE_CHAT_LEADER", "CHAT_MSG_WHISPER", "CHAT_MSG_WHISPER_INFORM", "CHAT_MSG_CHANNEL" }
-- channel -> locale key of its word in the window
Share.CHANNEL_WORD = { GUILD = "SHARE_CH_GUILD", RAID = "SHARE_CH_RAID", INSTANCE_CHAT = "SHARE_CH_INSTANCE",
  PARTY = "SHARE_CH_PARTY", SAY = "SHARE_CH_SAY" }

local IsSecret = Util.IsSecret
local function G(name) return rawget(_G, name) end

-- 1.5.0 fixer: what goes into a chat or the Discord block uses the plain words of the language (WANTED, PAYBACK, hit
-- list), never the chosen cover's (a reader without the addon or with another cover would not know them)
function Share.Word(key)
  local Lc = ns.Locale
  if Lc and Lc.Plain then return Lc.Plain(key) end
  return L[key]
end
local W = Share.Word

------------------------------------------------------------------------
-- Probe (probe.share): counters since login (session) and over all sessions (counts, in DeathNoteDB.probe.share)
------------------------------------------------------------------------
Share.counts = {}
function Share.Count(k)
  if type(k) ~= "string" then return end
  Share.counts[k] = (Share.counts[k] or 0) + 1
  local db = ns.Store and ns.Store.DB and ns.Store.DB()
  if type(db) ~= "table" then return end
  if type(db.probe) ~= "table" then db.probe = {} end
  local p = db.probe.share
  if type(p) ~= "table" then p = {}; db.probe.share = p end
  if type(p.counts) ~= "table" then p.counts = {} end
  p.counts[k] = (tonumber(p.counts[k]) or 0) + 1
end
-- for Probe.Run: the stored totals, this session, and which client paths exist
function Share.ProbeSnapshot(keep)
  local s = {}
  for k, v in pairs(Share.counts) do s[k] = v end
  local CI = G("C_ChatInfo")
  return { counts = type(keep) == "table" and type(keep.counts) == "table" and keep.counts or {}, session = s,
    filter = Share.filterVia, click = Share.clickVia,
    send = (type(CI) == "table" and CI.SendChatMessage and "C_ChatInfo") or (G("SendChatMessage") and "global") or "none",
    lockdownApi = type(CI) == "table" and CI.InChatMessagingLockdown ~= nil or false }
end

------------------------------------------------------------------------
-- Text pieces
------------------------------------------------------------------------
-- a UTF-8 string cut to at most n bytes, never inside a character
function Share.Cut(s, n)
  if type(s) ~= "string" or #s <= n then return s end
  if n <= 0 then return "" end
  local i = n
  while i > 0 do
    local b = s:byte(i)
    if b < 0x80 or b >= 0xC0 then break end
    i = i - 1
  end
  if i == 0 then return "" end
  local b = s:byte(i)
  local len = (b >= 0xF0 and 4) or (b >= 0xE0 and 3) or (b >= 0xC0 and 2) or 1
  if i + len - 1 <= n then return s:sub(1, i + len - 1) end
  return s:sub(1, i - 1)
end

-- one field for a line: no control bytes, no "|" (escape codes), no brackets (the pattern), one space at most
function Share.Clean(s, max)
  if type(s) ~= "string" or IsSecret(s) then return nil end
  s = s:gsub("[%c|%[%]]", ""):gsub("%s+", " ")
  s = s:gsub("^ ", ""):gsub(" $", "")
  if s == "" then return nil end
  if max then s = Share.Cut(s, max) end
  return s
end

function Share.Prefix() return "[" .. Share.BRAND .. ": " end

local function times(n) return Fmt(L.TIMES, { count = tonumber(n) or 0 }) end
function Share.Thousands(n)
  local s = tostring(math.floor(tonumber(n) or 0))
  local sep = type(L.THOUSANDS_SEP) == "string" and L.THOUSANDS_SEP or ","
  local out = s:reverse():gsub("(%d%d%d)", "%1" .. sep:reverse():gsub("%%", "%%%%")):reverse()
  if out:sub(1, #sep) == sep then out = out:sub(#sep + 1) end
  return out
end
local function gold(g) return Fmt(L.MONEY_GOLD, { count = Share.Thousands(g) }) end

-- name as the game shows it ("Name Surname")
local function display(e)
  if type(e) ~= "table" then return nil end
  return Share.Clean(Util.Display(e), Share.NAME_MAX)
end

-- the line: "[Brand: name] seg · seg ..."; segments drop from the end until it fits Share.MAX_BYTES
function Share.Build(name, segs)
  name = Share.Clean(name, Share.NAME_MAX)
  local head = name and (Share.Prefix() .. name .. "]") or ("[" .. Share.BRAND .. "]")
  local list = {}
  for i = 1, #(segs or {}) do
    local s = Share.Clean(segs[i], Share.SEG_MAX)
    if s then list[#list + 1] = s end
  end
  for n = #list, 0, -1 do
    local line = n > 0 and (head .. " " .. table.concat(list, Share.SEP, 1, n)) or head
    if #line <= Share.MAX_BYTES then return line end
  end
  return Share.Cut(head, Share.MAX_BYTES)
end

------------------------------------------------------------------------
-- What may be shown
------------------------------------------------------------------------
function Share.Adopted(e) return type(e) == "table" and (e.fromGuild == true or e.imported == true) end

-- me : him from the rap sheet (nil while it is off)
local function standing(key)
  local Lg = ns.Ledger
  if not (Lg and Lg.Standing) or type(key) ~= "string" then return nil end
  local ok, m, h = pcall(Lg.Standing, key)
  if not ok or type(m) ~= "number" or type(h) ~= "number" then return nil end
  return m, h
end
Share.Standing = standing

-- a deed of my own (killing blow or assist on me), never read in from a text (Store.Import: d.imported)
local function ownDeed(d)
  if type(d) ~= "table" or d.imported then return false end
  local r = d.role
  if r == nil then r = d.sure == true and "kill" or "suspect" end
  return r == "kill" or r == "assist"
end

-- killing blows on me that are my own (not read in); nil for an entry that was never read in (its counter is mine)
local function ownKills(e)
  if not e.imported then return nil end
  local n = 0
  for _, d in ipairs(type(e.deaths) == "table" and e.deaths or {}) do
    if ownDeed(d) and (d.role == "kill" or (d.role == nil and d.sure == true)) then n = n + 1 end
  end
  return n
end

-- own deeds: he killed me (or I took part), or I killed him. Attacks, suspicion and copied or read-in data are no own
-- deeds (1.5.0 fixer: an entry read in from a text counts only the deeds that happened to me since).
function Share.OwnDeeds(e)
  if type(e) ~= "table" then return false end
  if e.imported then
    for _, d in ipairs(type(e.deaths) == "table" and e.deaths or {}) do if ownDeed(d) then return true end end
  elseif (tonumber(e.kills) or 0) > 0 or (tonumber(e.assists) or 0) > 0 then
    return true
  end
  local m = standing(e.key)
  return m ~= nil and m > 0
end

-- may this own book entry be shown? Not a suspect, not an entry made only of attacks or of copied data; one entered
-- by hand (by me, not copied) shows its name.
function Share.Offer(e)
  if type(e) ~= "table" or type(e.key) ~= "string" or IsSecret(e.key) then return false end
  if e.status == "suspect" then return false end
  if Share.OwnDeeds(e) then return true end
  return e.manual == true and not Share.Adopted(e)
end

-- a guild or friends' book entry: only with kills on guildmates or friends (an entry listed by hand carries the
-- names of who listed it, nothing else)
function Share.OfferGuild(g)
  return type(g) == "table" and type(g.key) == "string" and (tonumber(g.kills) or 0) > 0
end
function Share.OfferHunt(h) return type(h) == "table" and type(h.key) == "string" end

-- posted bounties (sum in gold) of a key, from Bounty.lua
local function posted(key)
  local Gd = ns.Guild
  if not (Gd and Gd.Bounties) then return 0 end
  local ok, _, sum = pcall(Gd.Bounties, key)
  return ok and tonumber(sum) or 0
end

-- the book's own bounty without the suspicion part (gold), else 0
local function ownBounty(e)
  local S = ns.Store
  if not (S and S.Bounty) then return 0 end
  local proxy = { key = e.key, kills = e.kills, assists = e.assists, revenge = e.revenge, level = e.level, suspected = 0 }
  local ok, v = pcall(S.Bounty, proxy)
  return ok and math.floor((tonumber(v) or 0) / 10000) or 0
end

local function bountySeg(key, e)
  local g = posted(key)
  if g <= 0 and e then g = ownBounty(e) end
  if g <= 0 then return nil end
  return Fmt(L.SHARE_BOUNTY, { gold = gold(g) })
end

-- the newest own deed of an entry (killing blow or assist on me; never an attack or a suspicion)
function Share.LastOwnDeed(e)
  if type(e) ~= "table" or type(e.deaths) ~= "table" then return nil end
  for i = 1, #e.deaths do
    if ownDeed(e.deaths[i]) then return e.deaths[i] end
  end
  return nil
end

local function place(z, sz)
  z, sz = Share.Clean(z), Share.Clean(sz)
  if z and sz and z ~= sz then return z .. ", " .. sz end
  return sz or z
end

local function scoreSeg(e)
  local m, h = standing(e.key)
  local own = ownKills(e)
  if m and own then h = math.min(h, own) end   -- read-in killing blows are not part of what I show
  if m and (m > 0 or h > 0) then return Fmt(L.STAND_LINE, { score = m .. " : " .. h }), m, h end
  local k = own or tonumber(e.kills) or 0
  if k > 0 then return Fmt(L.SHARE_KILLED_ME, { times = times(k) }) end
  return nil
end

local function placeSeg(e)
  local ls = e.lastSeen
  local z = type(ls) == "table" and Share.Clean(ls.zone) or nil
  if z then return Fmt(L.SHARE_SEEN, { zone = z }) end
  local d = Share.LastOwnDeed(e)
  local p = d and place(d.zone, d.subzone)
  if p then return Fmt(L.SHARE_DEED_AT, { place = p }) end
  return nil
end

-- kind word of an own entry: WANTED (the poster's head), PARDONED
local function kindOf(e)
  if e.status == "pardoned" then return W("SHARE_KIND_PARDONED") end
  return W("POSTER_HEAD")
end

------------------------------------------------------------------------
-- Lines
------------------------------------------------------------------------
-- own book entry; nil when it may not be shown
function Share.LineFor(e)
  if not Share.Offer(e) then return nil end
  return Share.Build(display(e), { kindOf(e), (scoreSeg(e)), bountySeg(e.key, e), placeSeg(e) })
end

-- payback just taken: "[Brand: name] PAYBACK · now 3 : 5 · <where I am>"
function Share.RevengeLine(e)
  if not Share.Offer(e) then return nil end
  local m, h = standing(e.key)
  local seg = m and Fmt(L.SHARE_REVENGE_NOW, { score = m .. " : " .. h }) or nil
  local z, sz = Util.Zone()
  return Share.Build(display(e), { W("BANNER_REVENGE"), seg, bountySeg(e.key, e), place(z, sz) })
end

-- guild or friends' book entry (src: "guild" | "friends" | "both" | nil)
function Share.GuildLine(g, src)
  if not Share.OfferGuild(g) then return nil end
  local ls = type(g.lastSeen) == "table" and g.lastSeen or nil
  local z = ls and Share.Clean(ls.zone)
  return Share.Build(display(g), { src == "friends" and W("POSTER_FRIENDSBOOK") or W("POSTER_GUILDBOOK"),
    Fmt(L.ROW_GKILLED, { kills = tonumber(g.kills) or 0 }), bountySeg(g.key), z and Fmt(L.SHARE_SEEN, { zone = z }) or nil })
end

-- hit list target (never the reason or who called it)
function Share.HuntLine(h)
  if not Share.OfferHunt(h) then return nil end
  local ls = type(h.lastSeen) == "table" and h.lastSeen or nil
  local z = ls and Share.Clean(ls.zone)
  return Share.Build(display(h), { W("POSTER_HUNTLIST"), Fmt(L.POSTER_RELEASED_N, { times = times(tonumber(h.n) or 0) }),
    bountySeg(h.key), z and Fmt(L.SHARE_SEEN, { zone = z }) or nil })
end

------------------------------------------------------------------------
-- The week: most wanted (most killing blows on me in 7 days), revenge taken, open debts. Own data only.
------------------------------------------------------------------------
local function isKill(d)
  if type(d) ~= "table" or d.imported then return false end   -- read in from a text: not my week
  if d.role ~= nil then return d.role == "kill" end
  return d.sure == true
end

function Share.Week(now)
  now = now or time()
  local since = now - Share.WEEK
  local S = ns.Store
  local all = S and S.All and S.All() or {}
  local top, topN, topT = nil, 0, 0
  local debts = 0
  for key, e in pairs(all) do
    if type(e) == "table" and type(key) == "string" and e.status ~= "suspect" then
      local n, last = 0, 0
      for _, d in ipairs(type(e.deaths) == "table" and e.deaths or {}) do
        local t = tonumber(d.t)
        if isKill(d) and t and t >= since then n = n + 1; if t > last then last = t end end
      end
      if n > topN or (n == topN and n > 0 and last > topT) then top, topN, topT = e, n, last end
      if e.status == "wanted" then
        local m, h = standing(key)
        local own = ownKills(e)
        if m then
          if own then h = math.min(h, own) end
          if h > m then debts = debts + 1 end
        elseif (own or tonumber(e.kills) or 0) > (tonumber(e.revenge) or 0) then
          debts = debts + 1
        end
      end
    end
  end
  local revenge = 0
  local Lg = ns.Ledger
  local log = Lg and Lg.Log and Lg.Log()
  if type(log) == "table" and #log > 0 then
    for _, r in ipairs(log) do
      if type(r) == "table" and (tonumber(r.t) or 0) >= since and type(r.f) == "string" and r.f:find("v", 1, true) then
        revenge = revenge + 1
      end
    end
  else
    for _, e in pairs(all) do
      if type(e) == "table" and (tonumber(e.lastRevenge) or 0) >= since then revenge = revenge + 1 end
    end
  end
  return { top = top, topN = topN, revenge = revenge, debts = debts }
end

function Share.WeekLine(now)
  local w = Share.Week(now)
  local segs = { L.SHARE_WEEK_HEAD,
    w.top and Fmt(L.SHARE_WEEK_TOP, { times = times(w.topN) }) or L.SHARE_WEEK_NONE,
    Fmt(L.SHARE_WEEK_REVENGE, { count = w.revenge }), Fmt(L.SHARE_WEEK_DEBTS, { count = w.debts }) }
  return Share.Build(w.top and display(w.top) or nil, segs), w
end

------------------------------------------------------------------------
-- Discord: a block of a few lines, markdown sparingly (the name bold). Never the note.
------------------------------------------------------------------------
local function md(s) return (tostring(s):gsub("([%*_~`\\>|])", "\\%1")) end

local function className(e)
  if type(e.classLoc) == "string" and not IsSecret(e.classLoc) then return e.classLoc end
  local CN = G("LOCALIZED_CLASS_NAMES_MALE")
  if type(CN) == "table" and e.class and CN[e.class] then return CN[e.class] end
  return nil
end

local function whenOf(t)
  if type(t) ~= "number" then return nil end
  local ok, s = pcall(Util.When, t)
  return ok and type(s) == "string" and s or nil
end

local function join(...)
  local out = {}
  for i = 1, select("#", ...) do
    local v = select(i, ...)
    if type(v) == "string" and v ~= "" then out[#out + 1] = v end
  end
  return table.concat(out, Share.SEP)
end

-- item: own entry (kind "own"), guild entry ("guild", src) or hit list target ("hunt")
function Share.Discord(item, kind, src)
  if type(item) ~= "table" then return nil end
  local lines = {}
  local name = display(item)
  if not name then return nil end
  local head
  if kind == "guild" then
    if not Share.OfferGuild(item) then return nil end
    head = src == "friends" and W("POSTER_FRIENDSBOOK") or W("POSTER_GUILDBOOK")
  elseif kind == "hunt" then
    head = W("POSTER_HUNTLIST")
  else
    if not Share.Offer(item) then return nil end
    head = kindOf(item)
  end
  lines[1] = "**" .. md(name) .. "**" .. Share.SEP .. md(head)
  local guild = Share.Clean(item.guild)
  lines[#lines + 1] = md(join(type(item.level) == "number" and Fmt(L.POSTER_LEVEL, { level = item.level }) or nil,
    Share.Clean(className(item)), guild and Fmt(L.POSTER_GUILD, { guild = guild }) or nil))
  if kind == "guild" then
    lines[#lines + 1] = md(join(Fmt(L.ROW_GKILLED, { kills = tonumber(item.kills) or 0 }), bountySeg(item.key)))
  elseif kind == "hunt" then
    lines[#lines + 1] = md(join(Fmt(L.POSTER_RELEASED_N, { times = times(tonumber(item.n) or 0) }), bountySeg(item.key)))
  else
    lines[#lines + 1] = md(join((scoreSeg(item)), bountySeg(item.key, item)))
    local d = Share.LastOwnDeed(item)
    local p = d and place(d.zone, d.subzone)
    if p then lines[#lines + 1] = md(Fmt(L.SHARE_DC_LAST, { place = p, time = whenOf(d.t) or "?" })) end
  end
  local ls = type(item.lastSeen) == "table" and item.lastSeen or nil
  local z = ls and Share.Clean(ls.zone)
  if z and type(ls.t) == "number" then
    local ago = Util.Ago and Util.Ago(ls.t)
    if type(ago) == "string" then lines[#lines + 1] = md(Fmt(L.POSTER_LAST_SEEN_IN, { zone = z, time = ago })) end
  end
  lines[#lines + 1] = "*" .. Share.BRAND .. "*"
  local out = {}
  for _, l in ipairs(lines) do if l ~= "" then out[#out + 1] = l end end
  return table.concat(out, "\n")
end

------------------------------------------------------------------------
-- Reading a line (receiver): find the pattern, the name, the segments
------------------------------------------------------------------------
-- start, end and name of the first pattern at or after init; nil when there is none or the name is odd
function Share.Find(msg, init)
  if type(msg) ~= "string" then return nil end
  local p = Share.Prefix()
  local s = msg:find(p, init or 1, true)
  while s do
    local close = msg:find("]", s + #p, true)
    if not close then return nil end
    local name = msg:sub(s + #p, close - 1)
    -- already the text of a link ("|h[" before it), or an odd name: no link here, look further
    local inLink = s > 2 and msg:sub(s - 2, s - 1) == "|h"
    if not inLink and name ~= "" and #name <= Share.NAME_MAX and not name:find("[%c|%[]") and name:find("%S") then
      return s, close, name
    end
    s = msg:find(p, close + 1, true)
  end
  return nil
end

-- 1.5.0 fixer: what kind of line a received one is, from its first segment (the sender's head word): "wanted",
-- "pardoned", "revenge", "guild", "friends", "hunt", "week", or nil when the word is not one of ours (another
-- language). Both the plain word and the receiver's cover word are known (a sender of the same language).
local KIND_KEYS = { { "POSTER_HEAD", "wanted" }, { "SHARE_KIND_PARDONED", "pardoned" }, { "BANNER_REVENGE", "revenge" },
  { "POSTER_GUILDBOOK", "guild" }, { "POSTER_FRIENDSBOOK", "friends" }, { "POSTER_HUNTLIST", "hunt" },
  { "SHARE_WEEK_HEAD", "week" } }
Share.KIND_KEYS = KIND_KEYS
function Share.KindOf(rec)
  local first = type(rec) == "table" and type(rec.segs) == "table" and rec.segs[1]
  if type(first) ~= "string" then return nil end
  for _, kk in ipairs(KIND_KEYS) do
    local a, b = Share.Clean(W(kk[1])), Share.Clean(L[kk[1]])
    if first == a or first == b then return kk[2] end
  end
  return nil
end

-- { name, segs = { ... }, m, h } of a received line, nil when it has no pattern
function Share.Parse(msg)
  local s, e, name = Share.Find(msg)
  if not s then return nil end
  local rest = msg:sub(e + 1)
  local cut = rest:find("|", 1, true)          -- another link or colour code ends what the sender wrote
  if cut then rest = rest:sub(1, cut - 1) end
  local rec = { name = name, segs = {} }
  local sep = Share.SEP
  local pos = 1
  rest = rest:gsub("^%s+", "")
  while #rec.segs < Share.SEGS_MAX and pos <= #rest do
    local a = rest:find(sep, pos, true)
    local seg = Share.Clean(rest:sub(pos, (a or #rest + 1) - 1), Share.SEG_MAX)
    if seg then rec.segs[#rec.segs + 1] = seg end
    if not a then break end
    pos = a + #sep
  end
  for _, seg in ipairs(rec.segs) do
    local m, h = seg:match("(%d+) : (%d+)")
    if m then rec.m, rec.h = tonumber(m), tonumber(h); break end
  end
  rec.kind = Share.KindOf(rec)
  return rec
end

------------------------------------------------------------------------
-- The chat filter: only the pattern becomes a local link, the rest of the line stays as it came. Cheap: one plain
-- find on the fixed prefix, then more. Never on secret text or sender (instances, lockdown), never throws.
------------------------------------------------------------------------
Share.links, Share.linkN = {}, 0
local seen = {}            -- line id or text -> the line made of it (one message comes once per chat frame)
local seenN = 0

local function remember(rec)
  Share.linkN = Share.linkN + 1
  Share.links[Share.linkN] = rec
  Share.links[Share.linkN - Share.LINKS_MAX] = nil
  return Share.linkN
end

function Share.LinkText(id, name)
  return "|c" .. Share.LINK_HEX .. "|Haddon:" .. ADDON .. ":share:" .. id .. "|h" .. Share.Prefix() .. name .. "]|h|r"
end

-- the message with its first pattern as a link, or nil (counts a hit once per message)
function Share.Linkify(msg, author, lineID)
  local s, e, name = Share.Find(msg)
  if not s then return nil end
  local k = (type(lineID) == "number" and not IsSecret(lineID)) and lineID or msg
  local hit = seen[k]
  if hit and hit.msg == msg then return hit.out end
  local rec = Share.Parse(msg)
  if not rec then return nil end
  rec.sender = Share.Clean(type(author) == "string" and (author:match("^([^%-]+)") or author) or nil, Share.NAME_MAX)
  rec.msg = msg
  local id = remember(rec)
  local out = msg:sub(1, s - 1) .. Share.LinkText(id, name) .. msg:sub(e + 1)
  if seenN >= Share.LINKS_MAX then seen, seenN = {}, 0 end
  seen[k] = { msg = msg, out = out }
  seenN = seenN + 1
  Share.Count("filterHit")
  return out
end

local lastSecret
function Share.Filter(_, _, msg, author, ...)
  if IsSecret(msg) or IsSecret(author) then
    -- once per message, not once per chat frame
    local now = (G("GetTime") and GetTime()) or 0
    if lastSecret ~= now then lastSecret = now; Share.Count("secret") end
    return false
  end
  if type(msg) ~= "string" or not msg:find(Share.Prefix(), 1, true) then return false end
  local lineID = select(9, ...)
  local ok, out = pcall(Share.Linkify, msg, author, lineID)
  if ok and type(out) == "string" then return false, out, author, ... end
  if not ok then Share.Count("filterError") end
  return false
end

function Share.Hook()
  if Share.filterVia then return end
  local util = G("ChatFrameUtil")
  local add = (type(util) == "table" and util.AddMessageEventFilter) or G("ChatFrame_AddMessageEventFilter")
  if type(add) ~= "function" then Share.filterVia = "none"; return end
  for _, ev in ipairs(Share.FILTER_EVENTS) do pcall(add, ev, Share.Filter) end
  Share.filterVia = (type(util) == "table" and util.AddMessageEventFilter) and "ChatFrameUtil" or "global"
end

------------------------------------------------------------------------
-- Sending (only from a click in the window)
------------------------------------------------------------------------
local function call(fn, ...)
  if type(fn) ~= "function" then return nil end
  local ok, a = pcall(fn, ...)
  if not ok or IsSecret(a) then return nil end
  return a
end

-- channels that work right now, in the order of the window
function Share.Channels()
  local out = {}
  if call(G("IsInGuild")) == true then out[#out + 1] = "GUILD" end
  local cat = G("LE_PARTY_CATEGORY_INSTANCE")
  if call(G("IsInRaid")) == true then
    out[#out + 1] = "RAID"
  elseif cat ~= nil and call(G("IsInGroup"), cat) == true then
    out[#out + 1] = "INSTANCE_CHAT"
  elseif call(G("IsInGroup")) == true then
    out[#out + 1] = "PARTY"
  end
  out[#out + 1] = "SAY"
  return out
end

Share.last = nil   -- GetTime() of the last shown line
function Share.Wait()
  if not Share.last then return 0 end
  local w = Share.COOLDOWN - ((GetTime() or 0) - Share.last)
  return w > 0 and math.ceil(w) or 0
end

-- why sending is not possible right now: "lockdown" | "combat" | "cooldown" | nil
function Share.Hold()
  local CI = G("C_ChatInfo")
  if type(CI) == "table" and type(CI.InChatMessagingLockdown) == "function" then
    local ok, v = pcall(CI.InChatMessagingLockdown)
    if not ok or IsSecret(v) or v then return "lockdown" end
  end
  local ic = G("InCombatLockdown")
  if type(ic) == "function" then
    local ok, v = pcall(ic)
    if ok and (IsSecret(v) or v) then return "combat" end
  end
  if Share.Wait() > 0 then return "cooldown" end
  return nil
end

-- true | false, reason ("empty", "channel", "lockdown", "combat", "cooldown", "noapi", "error")
function Share.Send(text, channel)
  local why
  if type(text) ~= "string" or text == "" or #text > Share.MAX_BYTES or text:find("|", 1, true) then why = "empty" end
  if not why then
    local okc = false
    for _, c in ipairs(Share.Channels()) do if c == channel then okc = true end end
    if not okc then why = "channel" end
  end
  why = why or Share.Hold()
  local CI = G("C_ChatInfo")
  local fn = (type(CI) == "table" and CI.SendChatMessage) or G("SendChatMessage")
  if not why and type(fn) ~= "function" then why = "noapi" end
  if not why then
    local ok = pcall(fn, text, channel)
    if not ok then why = "error" end
  end
  if why then Share.Count("refused." .. why); return false, why end
  Share.last = GetTime()
  Share.Count("sent." .. channel)
  return true
end

-- the filter goes in once the chat is there (every client has it at login)
ns:RegisterEvent("PLAYER_LOGIN", function() pcall(Share.Hook) end)
