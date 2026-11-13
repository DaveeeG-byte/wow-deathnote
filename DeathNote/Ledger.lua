-- DeathNote - Ledger.lua (1.3.1)
-- The rap sheet: own killing blows on players (1.3.1: and group kills I took part in), the standing "me : him" per
-- enemy, and the repute (four accounts, rank, path, needle). Data and rules only; the book (UI.lua, Extras.lua) and
-- the alarm (Alert.lua) read it through the functions and the bus events below. Nothing of this goes over the wire.
--
-- Events (ns:Fire), in this order for one kill: AWARD(id) for every new award, OWN_KILL(key, row),
-- STANDING_CHANGED(key), REPUTE_RANK(tier, path, oldTier, oldPath) only when the tier changed (a banner shows it
-- without a check of its own), REPUTE_PATH(path, oldPath, tier) only when the path changed (also with the tier).
-- STANDING_CHANGED(key) also for his kills, hand revenge, status, removal, a move (new key only), Ledger.Clear;
-- never at the start. LEDGER_CLEARED(count) after Ledger.Clear. VICTIM_SPOTTED(key, unit, how) while the victim
-- alarm is on. Nothing fires at the start, by the migration or by the check at start.
--
-- Data, account-wide and language-neutral (DeathNoteDB.ledger, DB version 4, see Store.Init):
--   victims[key] = { key, name, surname, guid, class, level, guild, faction, n, pre, first, last, dn, dt, pts,
--                    zone, mapID }        n = my kills on him, pre = those of them booked while he had no
--                                         book entry (no revenge the book could have recognised)
--   log          = newest kills first, at most LOG_MAX: { t, key, name, vl, ml, band, r, e, j, s, f, zone, mapID,
--                    x, y, me, state }    f = flag letters (see FLAGS), name = the victim's name at the kill
--   acc, mood    = { r, e, j, s }       lifetime accounts (never sink) and the sliding values (path and needle)
--   n, counted   = own kills, kills that earned points
--   tier, path   = the rank and path last reported (REPUTE_RANK / REPUTE_PATH fire once per change)
--   bands, best, cur, awards
-- The standing itself is never stored. "me" is read as
--   max(n, recognised revenge of the book + pre) + revenge noted by hand
-- so the book's bounty is never higher than in 1.2.x (its revenge count is the lower bound of "me") and nothing
-- jumps at a reload. Revenge the book recognised without an own killing blow (the "pvpkills" and "honour" paths of
-- Attribution.lua) counts for the standing through the max, but never earns repute: points come only from kills
-- booked here. The start books nothing (DB version 4 only creates the empty structure; the repute starts at zero).
-- Revenge that came in by "Import book" (e.revengeForeign) is foreign data: the bounty reads it like 1.2.x, the
-- standing leaves it out. Counts read for the standing are capped at COUNT_MAX.
-- One player, one key: book and rap sheet are joined by the GUID where there is one, by the key only otherwise. A
-- kill is booked under the book's key for its GUID; a victim follows the book's key for its GUID (ENEMY_UPDATED,
-- ENEMY_REKEYED, the check at start); a book entry and a victim of two different GUIDs never belong together, the
-- victim steps aside to a namesake key "Name-Realm#<GUID part>" (rap sheet and tracker only, never the book). Names
-- to show come from Ledger.NameParts / Ledger.DisplayName or the fields, never from splitting a key.
--
-- Detection (decision 7): PARTY_KILL with my GUID or my pet's as attacker is the source. The honour line
-- (COMBATLOG_HONORGAIN of the client, made into a pattern) is the fallback when no PARTY_KILL came for that victim;
-- it books only with HONOR_FALLBACK on. The named form of that line was never seen on Forever (probe 13.11.2026:
-- only the form without a name), so the fallback stays off.
-- 1.3.1, group kills: a PARTY_KILL by a member of my party or raid (or that member's pet) on an enemy player books a
-- kill for me (flags g and o) when a proof that I took part comes within the window around it: PLAYER_PVP_KILLS_CHANGED
-- or an honour line of any form, from PROOF_BEFORE seconds before the PARTY_KILL to PROOF_AFTER seconds after it.
-- Measured on Forever (probe 13.11.2026, a group of two, the mate's killing blows): PARTY_KILL, then
-- PLAYER_PVP_KILLS_CHANGED +0.4 s, then the honour line without a name +1.0 s. Each proof counts for one PARTY_KILL
-- only, per channel (one PLAYER_PVP_KILLS_CHANGED and one honour line come for the same kill): the oldest open
-- PARTY_KILL takes it. My own PARTY_KILLs on players take their proofs too (they are booked at once), so a proof of
-- my own kill never books a mate's kill out of my reach. No proof, no kill.
-- Dropped: no player, my own faction, the opponent of a duel to the death, instances, the same victim within 10 s
-- (by GUID: a mate's killing blow and mine on the same victim are one kill).
-- Own kills without a PARTY_KILL (totem, guardian, trap, damage over time) are not booked: a proof without any
-- PARTY_KILL names no victim, and whether UNIT_DIED names dead enemy players on Forever is unmeasured (the probe of
-- 13.11.2026 could not show it: it watched UNIT_DIED only for own kills on players, and there were none). The probe
-- counts such proofs (proofLoose) and now watches UNIT_DIED for group kills too (case field "died").
-- Whatever the client does here is unmeasured: /dn debug writes every case to DeathNoteDB.probe.kills.

local ADDON, ns = ...
local Util = ns.Util
local Call, IsSecret, Str, Num = Util.Call, Util.IsSecret, Util.Str, Util.Num

local Ledger = {}
ns.Ledger = Ledger

Ledger.VICTIMS_MAX = 200     -- victims kept; the oldest one that is not in the book goes first, never the newest
Ledger.LOG_MAX = 60          -- newest kills kept
Ledger.DEDUPE = 10           -- seconds: the same victim twice is one kill
Ledger.KICK = 600            -- seconds: a second kill on the same victim within this is "kicking"
Ledger.WINDOW = 86400        -- seconds: the wear window per victim
Ledger.WEAR = { 1, 0.8, 0.6, 0.4, 0.2 }   -- factor of the 1st..5th kill in the window, 0 from the 6th on
Ledger.DECAY = 0.98          -- mood = mood * DECAY + points
Ledger.PATH_FROM = 10        -- counted kills before a path is named ...
Ledger.PATH_TIER = 3         -- ... or this tier, whichever comes first (tiers 1 and 2 are common to all paths)
Ledger.PATH_SWITCH = 1.15    -- another account must beat the current path by 15 % to take over
Ledger.COUNT_MAX = 9999      -- a count read for the standing never goes beyond this (broken or pasted data)
Ledger.HONOR_WAIT = 2        -- seconds the honour line waits for a PARTY_KILL of the same kill
-- the honour line books a kill when no PARTY_KILL came (decision 7). Off: the line with a name was never seen on
-- Forever (probe 13.11.2026: only the form without a name). The probe counts the lines either way (honorAlone,
-- reason "fallback-off").
Ledger.HONOR_FALLBACK = false
-- group kills (1.3.1): the window of a proof around a mate's PARTY_KILL, in seconds. Measured: proof +0.4 s
-- (PLAYER_PVP_KILLS_CHANGED) and +1.0 s (honour line). 1 s before covers events that swap places; 3 s after is three
-- times the slowest measured proof and still far below the 10 s of the dedupe.
Ledger.PROOF_BEFORE = 1
Ledger.PROOF_AFTER = 3
-- a claim that took its first proof waits this long after it for the proof of the other channel (one kill brings
-- both: measured 0.6 s apart), even past PROOF_AFTER: one kill, one pair of proofs, never two bookings
Ledger.PROOF_PAIR = 2
-- seconds: a mate's victim seen this recently by the tracker (or my target) is "near"; with two open mates' claims the
-- proof goes to a near one first (I took part there more likely than at a victim I never saw)
Ledger.NEAR = 10
Ledger.ROSTER_AGE = 1        -- seconds: an unknown attacker GUID rebuilds the group roster at most this often
Ledger.PROBE_MAX = 10        -- cases in DeathNoteDB.probe.kills.cases

-- Greys: the victim's level at or below GreyLevel(my level). warcraft.wiki.gg "Mob experience" (Classic);
-- { up to my level, divisor, minus }: grey = L - floor(L / div) - minus; the first row means "nobody is grey".
Ledger.GREY = { { 5 }, { 39, 10, 5 }, { 59, 5, 1 }, { math.huge, nil, 9 } }

-- Base points per band: r, e, j, s
local BASE = {
  grau = { 4, 0, 0, 0 }, gruen = { 2, 0, 0, 0 }, gelb = { 0, 3, 0, 0 }, orange = { 0, 2, 3, 0 },
  rot = { 0, 1, 6, 0 }, schaedel = { 0, 0, 10, 0 }, unbekannt = { 0, 1, 0, 0 },
}
Ledger.BANDS = { "grau", "gruen", "gelb", "orange", "rot", "schaedel", "unbekannt" }
local VALID_BAND = {}
for _, b in ipairs(Ledger.BANDS) do VALID_BAND[b] = true end
local PATHS = { "r", "e", "j", "s" }
local VALID_PATH = { r = true, e = true, j = true, s = true }
-- f letters: v revenge, s protection, h hit list, b foreign bounty, g in a group, n kicking, p pet,
-- u level unknown, m booked from the honour line, o killing blow by a group member (1.3.1, always with g)
Ledger.FLAGS = "vshbgnpumo"

-- The six awards of stage 1 (ids are stored; names and lines come from the book). hidden: name shows as "???"
Ledger.AWARDS = {
  { id = "first_entry" }, { id = "receipt" }, { id = "david" }, { id = "same_day" },
  { id = "arch_enemy", hidden = true }, { id = "patience", hidden = true },
}
local AWARD_IDS = {}
for _, a in ipairs(Ledger.AWARDS) do AWARD_IDS[a.id] = true end

local floor = math.floor
local function finite(v) return type(v) == "number" and v == v and v > -math.huge and v < math.huge end
local function count(v) return finite(v) and v >= 0 and floor(v) or 0 end
local function round(x)
  if x >= 0 then return floor(x + 0.5) end
  return -floor(-x + 0.5)
end
local function total(acc) return acc.r + acc.e + acc.j + acc.s end

---------------------------------------------------------------------------
-- Pure part (no WoW calls)
---------------------------------------------------------------------------
function Ledger.GreyLevel(L)
  if not finite(L) then return 0 end
  L = floor(L)
  for _, row in ipairs(Ledger.GREY) do
    if L <= row[1] then
      if not row[3] then return 0 end
      local div = row[2]
      return math.max(0, L - (div and floor(L / div) or 0) - row[3])
    end
  end
  return 0
end

local MAX_SANE = 1000   -- levels beyond this are garbage, not a level

local function level(v)
  if IsSecret(v) or not finite(v) then return nil end
  v = floor(v)
  if v < 1 or v > MAX_SANE then return nil end
  return v
end

-- band of a victim seen from me; skull = the client showed "??" (UnitLevel < 0)
function Ledger.Band(myLevel, victimLevel, skull)
  if skull == true then return "schaedel" end
  local m, v = level(myLevel), level(victimLevel)
  if not m or not v then return "unbekannt" end
  local d = v - m
  if d >= 10 then return "schaedel" end
  if d >= 5 then return "rot" end
  if d >= 3 then return "orange" end
  if d >= -2 then return "gelb" end
  if v <= Ledger.GreyLevel(m) then return "grau" end
  return "gruen"
end

local function wear(nth)
  if not finite(nth) or nth < 1 then return 1 end
  return Ledger.WEAR[floor(nth)] or 0
end
Ledger.Wear = wear

-- ctx = { revenge, protect, hunt, bounty, group, kick, nthToday }; returns r, e, j, s (whole numbers).
-- Order of the rules (repute concept 6.2): revenge, protection, hit list, foreign bounty, group, kicking, wear.
function Ledger.Points(band, ctx)
  local b = BASE[band] or BASE.unbekannt
  ctx = type(ctx) == "table" and ctx or {}
  local r, e, j, s = b[1], b[2], b[3], b[4]
  if ctx.revenge then r = 0; e = e + 2 end
  if ctx.protect then r = 0; s = s + 4 end
  -- greys never earn hunt, not even with a hit list or a bounty on them
  if band ~= "grau" then
    if ctx.hunt then j = j + 3 end
    if ctx.bounty then j = j + 5 end
  end
  if ctx.group then e = e / 2; j = j / 2 end
  if ctx.kick then e, j, s = 0, 0, 0; r = math.max(r, 2) end
  local f = wear(ctx.nthToday)
  local function apply(x)
    if f <= 0 or x <= 0 then return 0 end
    return math.max(1, floor(x * f + 0.5))
  end
  return apply(r), apply(e), apply(j), apply(s)
end

-- tier 1..10 of a sum, and the points still missing to the next tier (nil at the top)
function Ledger.Tier(total)
  local th = ns.Ranks and ns.Ranks.THRESHOLDS or { 0, 10, 25, 50, 100, 175, 300, 500, 800, 1250 }
  total = finite(total) and total or 0
  local tier = 1
  for i = 1, #th do if total >= th[i] then tier = i end end
  local nxt = th[tier + 1]
  return tier, nxt and (nxt - total) or nil
end

-- the path: the biggest account of mood, from PATH_FROM counted kills or tier PATH_TIER on (a tier 3 and above
-- always has a path, so it always has a name); another one takes over only when it beats the current path by
-- PATH_SWITCH
function Ledger.Path(mood, prevPath, counted, tier)
  if type(mood) ~= "table" then return nil end
  local byKills = finite(counted) and counted >= Ledger.PATH_FROM
  local byTier = finite(tier) and tier >= Ledger.PATH_TIER
  if not (byKills or byTier) then return nil end
  local best, bv
  for _, p in ipairs(PATHS) do
    local v = finite(mood[p]) and mood[p] or 0
    if v > 0 and (not bv or v > bv) then best, bv = p, v end
  end
  if not best then return nil end
  if not VALID_PATH[prevPath] or prevPath == best then return best end
  local pv = finite(mood[prevPath]) and mood[prevPath] or 0
  if bv > pv * Ledger.PATH_SWITCH then return best end
  return prevPath
end

-- -100 (ruthless) .. +100 (honourable): 100 * (e + s - r) / (r + e + j + s); hunt is neutral
function Ledger.Needle(mood)
  if type(mood) ~= "table" then return 0 end
  local r, e, j, s = 0, 0, 0, 0
  if finite(mood.r) and mood.r > 0 then r = mood.r end
  if finite(mood.e) and mood.e > 0 then e = mood.e end
  if finite(mood.j) and mood.j > 0 then j = mood.j end
  if finite(mood.s) and mood.s > 0 then s = mood.s end
  local den = r + e + j + s
  if den <= 0 then return 0 end
  local x = round(100 * (e + s - r) / den)
  if x > 100 then x = 100 elseif x < -100 then x = -100 end
  return x
end

-- adds the points of one kill to st = { acc, mood, counted } (the booking and Ledger.Simulate share it)
function Ledger.Accrue(st, r, e, j, s)
  local pts = { r = r, e = e, j = j, s = s }
  for _, p in ipairs(PATHS) do
    st.acc[p] = st.acc[p] + pts[p]
    st.mood[p] = st.mood[p] * Ledger.DECAY + pts[p]
  end
  if r + e + j + s > 0 then st.counted = st.counted + 1 end
end

-- the repute after a list of kills { { band, ctx }, ... } from zero, and after each kill when `each` is given:
-- each(i, acc, mood, counted, path)
function Ledger.Simulate(list, each)
  local st = { acc = { r = 0, e = 0, j = 0, s = 0 }, mood = { r = 0, e = 0, j = 0, s = 0 }, counted = 0 }
  local path
  for i, k in ipairs(list) do
    Ledger.Accrue(st, Ledger.Points(k[1], k[2]))
    path = Ledger.Path(st.mood, path, st.counted, (Ledger.Tier(total(st.acc))))
    if each then each(i, st.acc, st.mood, st.counted, path) end
  end
  local sum = st.acc.r + st.acc.e + st.acc.j + st.acc.s
  return { acc = st.acc, mood = st.mood, counted = st.counted, total = sum, tier = (Ledger.Tier(sum)), path = path,
    needle = Ledger.Needle(st.mood) }
end

-- state of a standing. status = the book entry's status, nil = no book entry.
-- "open" (he leads, or 0 : 0 in the book), "even", "ahead", "victim" (only in the rap sheet), "pardoned", "suspect";
-- nil when there is nothing at all
function Ledger.StateOf(mine, his, assists, status)
  mine, his = count(mine), count(his)
  if status == "pardoned" then return "pardoned" end
  if status == "suspect" then return "suspect" end
  if status == nil then return mine > 0 and "victim" or nil end
  if his > mine or mine == 0 then return "open" end
  if his == mine then return "even" end
  return "ahead"
end

---------------------------------------------------------------------------
-- Data
---------------------------------------------------------------------------
local db             -- DeathNoteDB.ledger
local victims        -- db.victims
local byGuid = {}    -- guid -> key (victims)
local nVictims, nPlaceholders = 0, 0
local standCache = {} -- book key -> code of the last standing seen (STANDING_CHANGED fires on a change)
local listCache = {}  -- sort -> sorted victim list (Ledger.Victims), emptied by every change
local reputeCache
local quiet = false   -- true while Ledger.Init runs: no events at the start

local function enabled()
  local S = ns.Store
  return db ~= nil and not (S and S.Setting and S.Setting("ledger.enabled") == false)
end
Ledger.Enabled = enabled

local function nowT() return time() end
local function gtime() return Num(Call(_G.GetTime)) or 0 end

local function newAcc(t)
  t = type(t) == "table" and t or {}
  for _, p in ipairs(PATHS) do
    local v = t[p]
    if not finite(v) or v < 0 then t[p] = 0 end
  end
  return t
end

local function cleanStr(v, max)
  if type(v) ~= "string" or IsSecret(v) or v == "" then return nil end
  v = v:gsub("[%c|]", "")
  if v == "" then return nil end
  return v:sub(1, max or 64)
end

-- The key of a second player with the same first name, known without surname: "Name-Realm#<GUID without
-- "Player-">" (server and player part, so it is unique across realm numbers). It lives in the rap sheet and in the
-- tracker's buffer only: never in the book, the export or the sync, never handed to Store to create an entry.
local function namesakeKey(plain, guid)
  return plain .. "#" .. (guid:match("^Player%-(.+)$") or guid)
end
Ledger.NamesakeKey = namesakeKey

-- name and realm (or surname) of a victim key, without the "#..." part of a namesake key
local function splitVictimKey(key)
  local n, s = Util.SplitKey(key)
  if s then s = s:gsub("#.*$", "") end
  return n, s
end

-- repairs one victim in place; false = beyond repair
local function sanitizeVictim(key, v)
  if type(key) ~= "string" or type(v) ~= "table" then return false end
  local n, s = splitVictimKey(key)
  v.key = key
  v.name = Util.CleanName(v.name) or Util.CleanName(n)
  if not v.name then return false end
  if v.surname ~= nil then v.surname = Util.CleanName(v.surname) end
  v.n = count(v.n)
  if v.n < 1 then return false end
  v.old = nil   -- old cases of the 1.3.0 test builds: the start books nothing any more
  v.pre = math.min(count(v.pre), v.n)
  if v.pre == 0 then v.pre = nil end
  v.pts = count(v.pts)
  for _, f in ipairs({ "first", "last", "dt" }) do if v[f] ~= nil and not finite(v[f]) then v[f] = nil end end
  v.dn = count(v.dn)
  v.guid = cleanStr(v.guid, 64)
  v.class = cleanStr(v.class, 16)
  if v.class and not v.class:match("^%u+$") then v.class = nil end
  v.level = level(v.level)
  v.guild, v.faction, v.zone = cleanStr(v.guild), cleanStr(v.faction, 16), cleanStr(v.zone, 80)
  if v.mapID ~= nil and not finite(v.mapID) then v.mapID = nil end
  if v.realm ~= nil and type(v.realm) ~= "string" then v.realm = nil end
  v.realm = v.realm or s
  return true
end

local LOG_NUM = { "t", "vl", "ml", "mapID", "x", "y" }
local function sanitizeRow(row)
  if type(row) ~= "table" or type(row.key) ~= "string" or not finite(row.t) then return false end
  if not VALID_BAND[row.band] then row.band = "unbekannt" end
  for _, f in ipairs(LOG_NUM) do if row[f] ~= nil and not finite(row[f]) then row[f] = nil end end
  for _, p in ipairs(PATHS) do row[p] = count(row[p]) end
  if type(row.f) ~= "string" or row.f:find("[^" .. Ledger.FLAGS .. "]") then row.f = "" end
  row.zone, row.me, row.name = cleanStr(row.zone, 80), cleanStr(row.me, 64), cleanStr(row.name, 64)
  if row.state ~= nil and type(row.state) ~= "string" then row.state = nil end
  return true
end

local function indexVictims()
  byGuid, nVictims, nPlaceholders = {}, 0, 0
  for key, v in pairs(victims) do
    nVictims = nVictims + 1
    if v.guid then byGuid[v.guid] = key end
    if v.surname == nil then nPlaceholders = nPlaceholders + 1 end
  end
end

local function sanitize(raw)
  local d = type(raw) == "table" and raw or {}
  d.v = 1
  if type(d.victims) ~= "table" then d.victims = {} end
  for key, v in pairs(d.victims) do
    if not sanitizeVictim(key, v) then d.victims[key] = nil end
  end
  if type(d.log) ~= "table" then d.log = {} end
  for i = #d.log, 1, -1 do if not sanitizeRow(d.log[i]) then table.remove(d.log, i) end end
  -- a table with holes or extra keys: keep the array part only
  for k in pairs(d.log) do if type(k) ~= "number" or k > #d.log then d.log[k] = nil end end
  while #d.log > Ledger.LOG_MAX do table.remove(d.log) end
  d.acc, d.mood = newAcc(d.acc), newAcc(d.mood)
  -- a mood lost to broken data while the accounts stand: the accounts are the best guess (a path from tier 3 on)
  if total(d.mood) <= 0 and total(d.acc) > 0 then for _, p in ipairs(PATHS) do d.mood[p] = d.acc[p] end end
  d.n = math.max(count(d.n), #d.log)
  d.counted = math.min(count(d.counted), d.n)
  d.tier = count(d.tier)
  if d.tier < 1 or d.tier > 10 then d.tier = 1 end
  if not VALID_PATH[d.path] then d.path = nil end
  if type(d.bands) ~= "table" then d.bands = {} end
  for k, v in pairs(d.bands) do if not VALID_BAND[k] then d.bands[k] = nil else d.bands[k] = count(v) end end
  if type(d.best) ~= "table" then d.best = {} end
  for _, f in ipairs({ "gap", "streak", "quick" }) do
    if d.best[f] ~= nil and not (finite(d.best[f]) and d.best[f] >= 0) then d.best[f] = nil end
  end
  if type(d.cur) ~= "table" then d.cur = {} end
  d.cur.streak = count(d.cur.streak)
  if type(d.awards) ~= "table" then d.awards = {} end
  for k, v in pairs(d.awards) do if not AWARD_IDS[k] or not finite(v) then d.awards[k] = nil end end
  d.gone = nil   -- 1.3.0 test builds: marks of struck victims for the old check at start
  return d
end


---------------------------------------------------------------------------
-- Standing
---------------------------------------------------------------------------
local function handRevenge(e)
  local S = ns.Store
  return (S and S.HandRevenge) and S.HandRevenge(e) or 0
end

-- revenge the book recognised (own killing blow, honour): revenge minus revenge noted by hand. For the standing
-- (own = true) without the part that came in by "Import book" (e.revengeForeign, Store.Import): foreign data is
-- never "me". The bounty reads it all, as 1.2.x does.
local function recognised(e, own, hand)
  if type(e) ~= "table" then return 0 end
  local x = count(e.revenge) - (hand or handRevenge(e))
  if own and e.revengeForeign ~= nil then x = x - count(e.revengeForeign) end
  return x > 0 and x or 0
end

-- book entry e and victim v under one key belong together unless both carry a GUID and they differ (the GUID beats
-- the key: a namesake's victim is never "me" against the book entry). Returns v or nil.
local function joined(e, v)
  if e and v and v.guid then
    local eg = Str(e.guid)
    if eg and eg ~= v.guid then return nil end
  end
  return v
end

-- "me" of a book entry e (or nil) and a victim v (or nil); see the head of this file
local function mineOf(e, v, own)
  v = joined(e, v)
  local n, pre = v and v.n or 0, v and v.pre or 0
  local hand = e and handRevenge(e) or 0
  local x = recognised(e, own, hand) + pre
  return (n > x and n or x) + hand
end

local function capped(x) return math.min(x, Ledger.COUNT_MAX) end

-- me : him right before an own kill at time t. Attribution.lua handles the same PARTY_KILL first and may have
-- counted it as revenge already (its dedupe lets one recognised revenge per enemy through within 10 s): that one
-- belongs to this kill and is not part of the state before it.
local function standingBefore(key, t)
  local S = ns.Store
  local e = S and S.Get(key)
  local v = joined(e, victims[key])
  local rec = recognised(e, true)
  local at = e and e.revengeAutoAt
  if rec > 0 and finite(at) and t - at >= 0 and t - at <= Ledger.DEDUPE then rec = rec - 1 end
  local mine = math.max(v and v.n or 0, rec + (v and v.pre or 0)) + (e and handRevenge(e) or 0)
  local his = e and count(e.kills) or 0
  return capped(mine), capped(his), Ledger.StateOf(mine, his, e and e.assists, e and e.status)
end

-- me : him for a key (book or rap sheet). nil while the rap sheet is switched off.
function Ledger.Standing(key)
  if not enabled() or type(key) ~= "string" then return nil end
  local S = ns.Store
  local e = S and S.Get(key)
  local mine = capped(mineOf(e, victims[key], true))
  local his = e and capped(count(e.kills)) or 0
  local state = Ledger.StateOf(mine, his, e and e.assists, e and e.status)
  if not state then return nil end
  return mine, his, state
end

-- "me" alone for the book's bounty (Store.Bounty): never below the book's revenge count (imported revenge
-- included), so the bounty is never higher than in 1.2.x; nil while switched off
function Ledger.Mine(key, e)
  if not enabled() or type(key) ~= "string" then return nil end
  if e == nil and ns.Store then e = ns.Store.Get(key) end
  return mineOf(type(e) == "table" and e or nil, victims[key])
end

local STATUS_CODE = { wanted = 0, suspect = 1, pardoned = 2 }
local function standCode(key)
  local S = ns.Store
  local e = S and S.Get(key)
  local mine = capped(mineOf(e, victims and victims[key], true))
  local his = e and capped(count(e.kills)) or 0
  local st = e and (STATUS_CODE[e.status] or 0) or 3
  return (mine * 1048576 + his) * 4 + st
end

-- returns true when the standing changed
local function standingTouched(key)
  if type(key) ~= "string" then return false end
  if next(listCache) then listCache = {} end
  local code = standCode(key)
  if standCache[key] == code then return false end
  standCache[key] = code
  if enabled() and not quiet then ns:Fire("STANDING_CHANGED", key) end
  return true
end

---------------------------------------------------------------------------
-- Victims
---------------------------------------------------------------------------
local updateHook   -- defined below (victim alarm hook and placeholder hook)

local function inBook(key)
  local S = ns.Store
  return S and S.Get(key) ~= nil
end

-- does the victim or the book entry at key carry another GUID than g? (then key is another player's: the tracker
-- may hand over a namesake's record with the surname of the one seen before)
local function otherGuid(key, g)
  if not (key and g) then return false end
  local v = victims[key]
  if v and v.guid and v.guid ~= g then return true end
  local S = ns.Store
  local e = S and S.Get(key)
  local eg = e and Str(e.guid)
  return eg ~= nil and eg ~= g
end

local function dropVictim(key)
  local v = victims[key]
  if not v then return end
  if next(listCache) then listCache = {} end
  if v.guid and byGuid[v.guid] == key then byGuid[v.guid] = nil end
  if v.surname == nil then nPlaceholders = nPlaceholders - 1 end
  victims[key] = nil
  nVictims = nVictims - 1
end

-- the cap: victims without a book entry go first, the oldest last kill first; when all are in the book, the one with
-- the oldest last kill. keep (the victim just booked) never goes. One pass, no quadratic search.
local function capOrder(a, b)
  if a[2] ~= b[2] then return a[2] < b[2] end
  if a[3] ~= b[3] then return a[3] < b[3] end
  return a[1] < b[1]
end

local function capVictims(keep)
  local over = nVictims - Ledger.VICTIMS_MAX
  if over <= 0 then return end
  if over == 1 then
    local best
    for k, v in pairs(victims) do
      if k ~= keep then
        local x = { k, inBook(k) and 1 or 0, v.last or 0 }
        if not best or capOrder(x, best) then best = x end
      end
    end
    if best then dropVictim(best[1]) end
    return
  end
  local list = {}
  for k, v in pairs(victims) do
    if k ~= keep then list[#list + 1] = { k, inBook(k) and 1 or 0, v.last or 0 } end
  end
  table.sort(list, capOrder)
  for i = 1, math.min(over, #list) do dropVictim(list[i][1]) end
end

local function addVictim(key, info)
  local v = { key = key, n = 0, pts = 0, dn = 0 }
  local n, s = splitVictimKey(key)
  v.name = Util.CleanName(info and info.name) or n
  v.realm = s
  local sn = info and Util.CleanName(info.surname)
  if sn then v.surname = Util.CapFirst(sn) end
  victims[key] = v
  nVictims = nVictims + 1
  if v.surname == nil then nPlaceholders = nPlaceholders + 1 end
  if next(listCache) then listCache = {} end
  return v
end

local INFO = { "class", "guild", "faction" }
local moveVictim
local function applyInfo(v, info)
  if type(info) ~= "table" then return end
  local g = Str(info.guid)
  -- a placeholder (first name only) with this GUID belongs to this full name: it moves in here
  local other = g and byGuid[g]
  if other and other ~= v.key and v.surname ~= nil and victims[other] and victims[other].surname == nil then
    moveVictim(other, v.key, v.surname)
  end
  if g and (v.guid == nil or v.surname ~= nil) then
    if v.guid and byGuid[v.guid] == v.key then byGuid[v.guid] = nil end
    v.guid = g
    byGuid[g] = v.key
  end
  for _, f in ipairs(INFO) do
    local x = cleanStr(info[f], f == "class" and 16 or 64)
    if x then v[f] = x end
  end
  local lv = level(Num(info.level))
  if lv then v.level = lv end
end

-- a victim with a GUID leaves a key that belongs to another player for a namesake key of its own
local function stepAside(key)
  local v = victims[key]
  if not (v and v.guid) then return end
  local nk = namesakeKey((key:gsub("#.*$", "")), v.guid)
  if nk ~= key then moveVictim(key, nk) end
end

-- moves a victim to a new key (placeholder seen with surname, or the book entry moved); merges into an existing one
-- of the same player only: a victim of another GUID at the new key steps aside first (two players never become one).
-- surname: the surname the new key stands for (a placeholder stops being one)
function moveVictim(oldKey, newKey, surname)
  local v = victims[oldKey]
  if not v or oldKey == newKey then return end
  local into = victims[newKey]
  if into and into.guid and v.guid and into.guid ~= v.guid then
    stepAside(newKey)
    into = victims[newKey]
  end
  dropVictim(oldKey)
  surname = Util.CleanName(Str(surname)) or v.surname
  if surname then surname = Util.CapFirst(surname) end
  if into then
    if into.surname == nil and surname then into.surname = surname; nPlaceholders = nPlaceholders - 1 end
    into.n = into.n + v.n
    into.pre = ((into.pre or 0) + (v.pre or 0) > 0) and (into.pre or 0) + (v.pre or 0) or nil
    into.pts = into.pts + v.pts
    if v.first and (not into.first or v.first < into.first) then into.first = v.first end
    if v.last and (not into.last or v.last > into.last) then into.last, into.zone, into.mapID = v.last, v.zone, v.mapID end
    if not into.guid and v.guid then into.guid = v.guid; byGuid[v.guid] = newKey end
  else
    v.key = newKey
    local n, s = splitVictimKey(newKey)
    v.name, v.realm = n, s
    if surname then v.surname = surname end
    victims[newKey] = v
    nVictims = nVictims + 1
    if v.surname == nil then nPlaceholders = nPlaceholders + 1 end
    if v.guid then byGuid[v.guid] = newKey end
  end
  local shown = victims[newKey] and Util.Display(victims[newKey]) or nil
  for i = 1, #db.log do
    local row = db.log[i]
    if row.key == oldKey then row.key = newKey; row.name = shown or row.name end
  end
  standCache[oldKey] = nil
  reputeCache = nil
  standingTouched(newKey)
end
Ledger.MoveVictim = moveVictim

-- a placeholder victim (first name only) seen with surname and the same GUID takes the full key
local function promote(r)
  if nPlaceholders <= 0 or type(r) ~= "table" then return end
  local g, sn = Str(r.guid), Str(r.surname)
  if not (g and sn) then return end
  local k = byGuid[g]
  local v = k and victims[k]
  if not v or v.surname ~= nil then return end
  local full = Util.KeyFor(r.name, sn)
  if not full or otherGuid(full, g) then return end
  -- the book knows him under another key: the victim stays with the book (ENEMY_REKEYED moves both)
  local S = ns.Store
  local bk = S and S.ByGUID and S.ByGUID(g)
  if bk and bk ~= full then return end
  local cs = Util.CleanName(sn)
  if not cs then return end
  moveVictim(k, full, cs)
  updateHook()
end
Ledger.Promote = promote

---------------------------------------------------------------------------
-- Migration and the check at every start (DB version 4, repute concept 4.3)
---------------------------------------------------------------------------
-- Keeps the keys consistent at every start, books nothing: a victim whose GUID the book knows under another key
-- (the book entry moved while an older version played) follows it there. Silent, idempotent, and only while the
-- rap sheet is switched on. Returns the number of victims moved.
-- the book's key for a victim (same GUID, another key), or nil: never away from a key the book has itself for him.
-- A victim known with surname follows the book's first-name key too and keeps its surname (the book moves to the
-- full name at the next sighting, ENEMY_REKEYED takes the victim along): one player, one key.
local function bookKeyOf(key, v)
  local S = ns.Store
  local k2 = v.guid and S and S.ByGUID and S.ByGUID(v.guid)
  local be = k2 and k2 ~= key and S.Get(k2)
  if not be then return nil end
  local own = S.Get(key)
  local og = own and Str(own.guid)
  if own and (og == nil or og == v.guid) then return nil end
  return k2, be
end

-- the book learned a GUID (a kill, a sighting): a victim of that GUID under another key follows at once, so the
-- start finds nothing to move and the standing never jumps at a reload
-- A victim of another GUID under the book's key steps aside first (a namesake the book lists under the same
-- first-name key).
local function followBook(key)
  local S = ns.Store
  local e = S and S.Get(key)
  if not e then return end
  local g = Str(e.guid)
  local v = victims[key]
  if v and v.guid and g and v.guid ~= g then stepAside(key); updateHook() end
  -- nothing to do in the common case
  local k = g and byGuid[g]
  if not k or k == key or not victims[k] then return end
  local k2, be = bookKeyOf(k, victims[k])
  if k2 == key then moveVictim(k, key, be.surname); updateHook() end
end

function Ledger.Reconcile()
  if not db or not enabled() then return 0 end
  local S = ns.Store
  if not (S and S.ByGUID) then return 0 end
  local moves
  for key, v in pairs(victims) do
    local k2 = bookKeyOf(key, v)
    local e = not k2 and v.guid and S.Get(key)
    local eg = e and Str(e.guid)
    if k2 then
      moves = moves or {}
      moves[#moves + 1] = { key, k2 }
    elseif eg and eg ~= v.guid then
      -- the book lists another player under this key: the victim steps aside
      moves = moves or {}
      moves[#moves + 1] = { key, namesakeKey((key:gsub("#.*$", "")), v.guid) }
    end
  end
  if not moves then return 0 end
  table.sort(moves, function(a, b) return a[1] < b[1] end)
  for _, m in ipairs(moves) do
    local e = S.Get(m[2])
    moveVictim(m[1], m[2], e and e.surname)
  end
  return #moves
end

-- Store.Init calls this (login and tests): repairs the data, migrates, primes the standing cache
function Ledger.Init(saved)
  if type(saved) ~= "table" then return end
  saved.ledger = sanitize(saved.ledger)
  db = saved.ledger
  victims = db.victims
  indexVictims()
  quiet = true
  local ok, err = pcall(Ledger.Reconcile)
  quiet = false
  if not ok then error(err, 0) end
  capVictims()
  standCache, listCache = {}, {}
  local S = ns.Store
  for key in pairs(S and S.All() or {}) do standCache[key] = standCode(key) end
  reputeCache = nil
  updateHook()
  return db
end

function Ledger.DB() return db end

---------------------------------------------------------------------------
-- Reading
---------------------------------------------------------------------------
function Ledger.Victim(key)
  if not db or type(key) ~= "string" then return nil end
  return victims[key]
end

function Ledger.VictimCount() return db and nVictims or 0 end

-- the rap sheet's key of a GUID (also a namesake's "Name-Realm#..."), nil when no victim has it
function Ledger.KeyOfGUID(guid)
  if not db or type(guid) ~= "string" then return nil end
  local k = byGuid[guid]
  return k and victims[k] and k or nil
end

-- the state of a key alone (Ledger.Standing's third value), nil while switched off or when there is nothing
function Ledger.State(key)
  local _, _, state = Ledger.Standing(key)
  return state
end

-- order of the states in the victim list: debts first, then even, ahead, victims only, suspects, pardoned
Ledger.STATE_ORDER = { open = 1, even = 2, ahead = 3, victim = 4, suspect = 5, pardoned = 6 }

local function byRecent(a, b)
  if (a.last or 0) ~= (b.last or 0) then return (a.last or 0) > (b.last or 0) end
  return a.key < b.key
end
local VSORT = {
  recent = byRecent,
  count = function(a, b)
    if a.n ~= b.n then return a.n > b.n end
    return byRecent(a, b)
  end,
  points = function(a, b)
    if (a.pts or 0) ~= (b.pts or 0) then return (a.pts or 0) > (b.pts or 0) end
    return byRecent(a, b)
  end,
  first = function(a, b)
    if (a.first or 0) ~= (b.first or 0) then return (a.first or 0) < (b.first or 0) end
    return a.key < b.key
  end,
  name = function(a, b)
    local na, nb = Util.Display(a):lower(), Util.Display(b):lower()
    if na ~= nb then return na < nb end
    return a.key < b.key
  end,
}

-- a new list with the same elements: a caller may filter or sort it without changing it for anybody else
local function copyList(list)
  local out = {}
  for i = 1, #list do out[i] = list[i] end
  return out
end

-- the victims as a list of their own for the caller (the victim tables in it are the stored ones: read only).
-- sort: "recent" (default, newest last kill first), "state" (STATE_ORDER, then recent), "points", "count", "first"
-- (oldest first kill first), "name". The order is kept until the rap sheet or the book changes.
function Ledger.Victims(sort)
  if not db then return {} end
  sort = (VSORT[sort] or sort == "state") and sort or "recent"
  if listCache[sort] then return copyList(listCache[sort]) end
  local out = {}
  for _, v in pairs(victims) do out[#out + 1] = v end
  if sort == "state" then
    local rank = {}
    for i = 1, #out do rank[out[i]] = Ledger.STATE_ORDER[Ledger.State(out[i].key) or "victim"] or 9 end
    table.sort(out, function(a, b)
      if rank[a] ~= rank[b] then return rank[a] < rank[b] end
      return byRecent(a, b)
    end)
  else
    table.sort(out, VSORT[sort])
  end
  listCache[sort] = out
  return copyList(out)
end

-- the newest kills, newest first (read only). row.name is the victim's name at the kill (kept when he is struck or
-- falls out of the cap)
function Ledger.Log() return db and db.log or {} end

-- { tier, path, total, next, floor, nextTier, nextPath, needle, acc, mood, share, n, counted, best, awards, bands };
-- a copy for the caller (also of acc, mood, share, best, awards, bands): changing it changes nothing stored.
--   next = points missing to the next tier (nil at the top); floor = the sum where this tier began (the rank bar runs
--   from floor to total + next); nextTier/nextPath = the tier above and the path it would carry now (nil at the top);
--   share = { r, e, j, s } shares of mood, 0..1 (the "Infamy (90 %)" of the rap sheet; 0 each without points)
local function copyFlat(t)
  local out = {}
  for k, x in pairs(t) do out[k] = x end
  return out
end
local REPUTE_TABLES = { "acc", "mood", "share", "best", "awards", "bands" }
local function copyRepute(r)
  local out = copyFlat(r)
  for _, f in ipairs(REPUTE_TABLES) do out[f] = copyFlat(r[f]) end
  return out
end

function Ledger.Repute()
  if not db then return { tier = 1, total = 0, floor = 0, next = 10, nextTier = 2, needle = 0, acc = newAcc(),
    mood = newAcc(), share = newAcc(), n = 0, counted = 0, best = {}, awards = {}, bands = {} } end
  if reputeCache then return copyRepute(reputeCache) end
  local sum = total(db.acc)
  local tier, nxt = Ledger.Tier(sum)
  local th = ns.Ranks and ns.Ranks.THRESHOLDS or {}
  local ms = total(db.mood)
  local share = {}
  for _, p in ipairs(PATHS) do share[p] = ms > 0 and db.mood[p] / ms or 0 end
  local path = Ledger.Path(db.mood, db.path, db.counted, tier)
  local nextTier = nxt and tier + 1 or nil
  reputeCache = { tier = tier, path = path, total = sum, next = nxt, floor = th[tier] or 0, nextTier = nextTier,
    nextPath = nextTier and Ledger.Path(db.mood, path, db.counted, nextTier) or nil,
    needle = Ledger.Needle(db.mood), acc = db.acc, mood = db.mood, share = share, n = db.n, counted = db.counted,
    best = db.best, awards = db.awards, bands = db.bands }
  return copyRepute(reputeCache)
end

-- the name of the next rank in the active theme and language (or the given ones), nil at the top or where no
-- name exists (other languages: Ranks.Title(nextTier, nextPath) gives the line)
function Ledger.NextRankName(theme, lang)
  local r = Ledger.Repute()
  if not r.nextTier or not ns.Ranks then return nil end
  return ns.Ranks.Name(r.nextTier, r.nextPath, theme, lang)
end

-- a table like a book entry, for the alarm popup of a victim
function Ledger.AsEntry(key)
  local v = Ledger.Victim(key)
  if not v then return nil end
  local e = { key = key, name = v.name, surname = v.surname, realm = v.realm, guid = v.guid, class = v.class,
    level = v.level, guild = v.guild, faction = v.faction, status = "victim", victim = true, kills = 0, assists = 0,
    suspected = 0, revenge = 0, note = "", deaths = {}, n = v.n, last = v.last, first = v.first }
  if v.surname then e.display = v.name .. " " .. v.surname end
  local mine, his, state = Ledger.Standing(key)
  e.mine, e.his, e.state = mine, his, state
  return e
end

-- The parts to show for a key of the rap sheet or the book: name, surname (nil when unknown), realm (nil when
-- unknown). Right for namesake keys ("Name-Realm#...") too, which carry no name of their own: the book and the alarm
-- show a victim or an entry only through this (or the fields of Ledger.Victim / Store.Get), never by splitting a key.
local function parts(n, sn, realm)
  -- a full key "Name-Surname" stores its second part as realm too: that is no realm
  if sn and realm == sn then realm = nil end
  return n, sn, realm
end

function Ledger.NameParts(key)
  if type(key) ~= "string" or IsSecret(key) then return nil end
  local v = db and victims[key]
  if v then return parts(v.name, v.surname, v.realm) end
  local S = ns.Store
  local e = S and S.Get(key)
  if e then return parts(e.name, e.surname, e.realm) end
  -- a key nobody holds: the second part may be a surname or a realm, it is shown as neither
  local n = splitVictimKey(key)
  return n, nil, nil
end

-- "Name Surname" or "Name" for a key (Ledger.NameParts), nil for nothing
function Ledger.DisplayName(key)
  local n, sn = Ledger.NameParts(key)
  if not n then return nil end
  return sn and (n .. " " .. sn) or n
end

-- strikes a victim from the rap sheet: name and count go, the points earned stay
function Ledger.RemoveVictim(key)
  if not db or type(key) ~= "string" or not victims[key] then return false end
  dropVictim(key)
  reputeCache = nil
  standingTouched(key)
  updateHook()
  return true
end

-- empties the rap sheet: every victim and the log go; the accounts, rank, path, own kills count, awards and best
-- marks stay (they never sink). Fires LEDGER_CLEARED(count) and STANDING_CHANGED for every key whose standing
-- changed. Returns the number of victims removed.
function Ledger.Clear()
  if not db then return 0 end
  local keys, n = {}, 0
  for key in pairs(victims) do keys[#keys + 1] = key; n = n + 1 end
  table.sort(keys)
  for k in pairs(victims) do victims[k] = nil end
  for i = #db.log, 1, -1 do db.log[i] = nil end
  byGuid, nVictims, nPlaceholders = {}, 0, 0
  listCache, reputeCache = {}, nil
  ns:Fire("LEDGER_CLEARED", n)
  for _, key in ipairs(keys) do standingTouched(key) end
  updateHook()
  return n
end

---------------------------------------------------------------------------
-- WoW side: who was killed
---------------------------------------------------------------------------
local function guidKind(guid)
  if type(guid) ~= "string" then return nil end
  return guid:match("^(%a+)%-")
end

local function myGUID() return Str(Call(_G.UnitGUID, "player")) end

-- group size: GetNumGroupMembers (read on Forever by an installed addon, unproven by us), else party1/raid1
local function groupSize()
  local n = Num(Call(_G.GetNumGroupMembers))
  if n then return n end
  if Util.True(Call(_G.UnitExists, "raid1")) or Util.True(Call(_G.UnitExists, "party1")) then return 2 end
  return 0
end
Ledger.GroupSize = groupSize

-- the client's maximum level (unproven which of these Forever has; installed addons read the first two)
function Ledger.MaxLevel()
  local v = Num(Call(_G.GetMaxLevelForPlayerExpansion)) or Num(Call(_G.GetMaxPlayerLevel)) or Num(_G.MAX_PLAYER_LEVEL)
  if v and v >= 1 and v <= MAX_SANE then return floor(v) end
  return 60
end

-- what we know of a victim GUID: info, how ("buffer", "recall", "book", "ledger", "guid", "none"), age in s
local function lookup(guid)
  local T, S = ns.Tracker, ns.Store
  local r = T and T.ByGUID and T.ByGUID(guid)
  local how = "buffer"
  if not r and T and T.Recall then r = T.Recall(guid); how = "recall" end
  if r then
    return { name = r.name, surname = r.surname, guid = guid, class = r.class, level = r.level, skull = r.skull,
      guild = r.guild, faction = r.faction }, how, gtime() - (r.t or 0)
  end
  local k = S and S.ByGUID(guid)
  local e = k and S.Get(k)
  if e then
    return { name = e.name, surname = e.surname, guid = guid, class = e.class, guild = e.guild, faction = e.faction,
      key = k }, "book"
  end
  k = byGuid[guid]
  local v = k and victims[k]
  if v then
    return { name = v.name, surname = v.surname, guid = guid, class = v.class, guild = v.guild, faction = v.faction,
      key = k }, "ledger"
  end
  -- GetPlayerInfoByGUID: first name only on Forever (Attribution.lua)
  local _, class, _, _, _, name = Call(_G.GetPlayerInfoByGUID, guid)
  name = Str(name)
  if name then return { name = name, guid = guid, class = Str(class) }, "guid" end
  return nil, "none"
end

local function guidFits(known, guid) return known == nil or known == guid end

-- the key for a victim: the book's key for his GUID first (book and rap sheet are joined by the GUID where there is
-- one, the book's key leads: when the book moves to a fuller name, ENEMY_REKEYED takes the victim along), then the
-- rap sheet's; else the full name when known; else a unique first name; else the placeholder "Name-<realm>" (moved
-- later when he is seen with surname)
local function keyOf(info)
  if info.key then return info.key end
  local sn = Str(info.surname)
  local S = ns.Store
  local g = Str(info.guid)
  if g then
    local k = S and S.ByGUID(g)
    if k then return k end
    if byGuid[g] then return byGuid[g] end
  end
  if sn then
    local full = Util.KeyFor(info.name, sn)
    -- that full name belongs to another GUID: this one is known by his first name only
    if not otherGuid(full, g) then return full end
    info.surname = nil
  end
  local name = Str(info.name)
  if not name then return nil end
  local found = S and S.Find(name)
  local fe = found and S.Get(found)
  if fe and guidFits(fe.guid, g) and not otherGuid(found, g) then return found end
  local ln, hit, hits = name:lower(), nil, 0
  for k, v in pairs(victims) do
    if v.name and v.name:lower() == ln and guidFits(v.guid, g) and not otherGuid(k, g) then hit, hits = k, hits + 1 end
  end
  if hits == 1 then return hit end
  local plain = Util.KeyFor(name)
  if not plain then return nil end
  -- the placeholder key is taken by another player with the same first name (another GUID in the rap sheet or the
  -- book): this one gets a placeholder of his own
  if g then
    local pv, pe = victims[plain], S and S.Get(plain)
    if (pv and pv.guid and pv.guid ~= g) or (pe and type(pe.guid) == "string" and pe.guid ~= g) then
      return namesakeKey(plain, g)
    end
  end
  return plain
end

-- is this player in the guild or friends' book for killing someone else than my own chars? (Bounty.lua: the same
-- test decides "avenged")
local function protects(key)
  local G = ns.Guild
  if not (G and G.Get) then return false end
  local ok, ge = pcall(G.Get, key, "all")
  if not ok or type(ge) ~= "table" or type(ge.deeds) ~= "table" then return false end
  local me = Util.PlayerFullName()
  for i = 1, #ge.deeds do
    local d = ge.deeds[i]
    local vic = type(d) == "table" and d.victim or nil
    if type(vic) == "string" and vic ~= me and not (G.IsOwnChar and G.IsOwnChar(vic)) then return true end
  end
  return false
end

-- on the hit list by someone else than me and my own chars (an own release alone earns nothing: one click before
-- the kill would be +3 hunt)
local function onHitList(key)
  local G = ns.Guild
  if not (G and G.Hunt) then return false end
  local ok, h = pcall(G.Hunt, key, "all")
  if not ok or type(h) ~= "table" or type(h.releases) ~= "table" then return false end
  local me = Util.PlayerFullName()
  for i = 1, #h.releases do
    local x = h.releases[i]
    local who = type(x) == "table" and x.char or nil
    if type(who) == "string" and who ~= me and not (G.IsOwnChar and G.IsOwnChar(who)) then return true end
  end
  return false
end

local function foreignBounty(key)
  local B = ns.Bounty
  if not (B and B.Has and B.Rows) or not B.Has(key) then return false end
  local rows = B.Rows(key)
  for i = 1, #rows do if not rows[i].own then return true end end
  return false
end

---------------------------------------------------------------------------
-- Probe (/dn debug): kill cases without names
---------------------------------------------------------------------------
local probeCounts = { partyKill = 0, own = 0, pet = 0, group = 0, foreign = 0, npc = 0, secret = 0, dup = 0, booked = 0,
  honor = 0, honorNamed = 0, honorPlain = 0, honorMatched = 0, honorAlone = 0, honorBooked = 0, rejected = {},
  -- 1.3.1: group kills booked, proofs seen (PLAYER_PVP_KILLS_CHANGED, honour line) and proofs no PARTY_KILL took
  groupBooked = 0, proofKC = 0, proofHonor = 0, proofLoose = 0 }
Ledger.probeCounts = probeCounts
local caseGuid = setmetatable({}, { __mode = "k" })   -- case -> victim GUID, in memory only
local lastKC                                         -- GetTime of the last PLAYER_PVP_KILLS_CHANGED

local function debugOn()
  local S = ns.Store
  return S and S.Setting and S.Setting("debug") == true or false
end

local function probeDB()
  local S = ns.Store
  local d = S and S.DB()
  if not d then return nil end
  if type(d.probe) ~= "table" then d.probe = {} end
  local k = d.probe.kills
  if type(k) ~= "table" then k = {}; d.probe.kills = k end
  if type(k.cases) ~= "table" then k.cases = {} end
  k.counts = probeCounts
  return k
end

local function form(v)
  if IsSecret(v) then return "<secret>" end
  if v == nil then return "nil" end
  if type(v) == "string" then return guidKind(v) or "string" end
  return type(v)
end

local function newCase(src)
  if not debugOn() then return nil end
  local k = probeDB()
  if not k then return nil end
  local c = { t = nowT(), gt = gtime(), src = src }
  table.insert(k.cases, 1, c)
  while #k.cases > Ledger.PROBE_MAX do table.remove(k.cases) end
  if lastKC and c.gt - lastKC <= 10 then c.kc = round((lastKC - c.gt) * 10) / 10 end
  return c
end

local function reject(c, why)
  probeCounts.rejected[why] = (probeCounts.rejected[why] or 0) + 1
  if c then c.result = why end
  return false, why
end

-- the colour the client gives that level (GetQuestDifficultyColor is read on Forever by installed map addons)
local function clientColor(lv)
  if not lv then return nil end
  local c = Call(_G.GetQuestDifficultyColor, lv)
  if IsSecret(c) or type(c) ~= "table" then return nil end
  local r, g, b = Num(c.r), Num(c.g), Num(c.b)
  if not (r and g and b) then return nil end
  return { r = round(r * 100) / 100, g = round(g * 100) / 100, b = round(b * 100) / 100 }
end

-- feigning death? looks once more 10 s after the kill: seen alive again = true, seen dead = false, nil = not seen
local function checkAlive(c, guid)
  local T = ns.Tracker
  local r = T and T.ByGUID and T.ByGUID(guid)
  if not r or (r.t or 0) <= c.gt + 0.5 then c.alive = "unseen"; return end
  local unit = r.unit
  if type(unit) ~= "string" or Str(Call(_G.UnitGUID, unit)) ~= guid then c.alive = "unseen"; return end
  local dead = Call(_G.UnitIsDeadOrGhost, unit)
  if IsSecret(dead) or type(dead) ~= "boolean" then c.alive = "unknown"; return end
  c.alive = not dead
end

---------------------------------------------------------------------------
-- Booking a kill
---------------------------------------------------------------------------
local recent = {}   -- { gt, guid, key, first } of the last own kills (dedupe)
local foreignKills = {}   -- { gt, guid } of PARTY_KILLs by others (the honour line must not book those)

local function firstOf(name)
  name = Str(name)
  if not name then return nil end
  return (name:match("^([^%s%-]+)") or name):lower()
end

-- the same kill twice: same GUID or key within DEDUPE seconds; the first name decides only where a GUID is missing
-- on either side (the honour line names no GUID), so two namesakes killed close together count twice
local function isDup(gt, guid, key, first)
  for i = #recent, 1, -1 do
    local x = recent[i]
    if gt - x.gt < Ledger.DEDUPE then
      if (guid and x.guid == guid) or (key and x.key == key) then return true end
      if first and x.first == first and not (guid and x.guid) then return true end
    end
  end
  return false
end

local function remember(gt, guid, key, first)
  recent[#recent + 1] = { gt = gt, guid = guid, key = key, first = first }
  while #recent > 8 do table.remove(recent, 1) end
end

local function flagsOf(ctx)
  local f = {}
  if ctx.revenge then f[#f + 1] = "v" end
  if ctx.protect then f[#f + 1] = "s" end
  if ctx.hunt then f[#f + 1] = "h" end
  if ctx.bounty then f[#f + 1] = "b" end
  if ctx.group then f[#f + 1] = "g" end
  if ctx.kick then f[#f + 1] = "n" end
  if ctx.pet then f[#f + 1] = "p" end
  if ctx.unknown then f[#f + 1] = "u" end
  if ctx.honor then f[#f + 1] = "m" end
  if ctx.mate then f[#f + 1] = "o" end
  return table.concat(f)
end

local function award(id)
  if db.awards[id] then return end
  db.awards[id] = nowT()
  reputeCache = nil
  ns:Fire("AWARD", id)
end

-- arch-enemy: 5 : 5 or more with the same enemy, reached by either side
local function checkArch(key)
  if not db or db.awards.arch_enemy then return end
  local mine, his = Ledger.Standing(key)
  if mine and mine >= 5 and mine == his then award("arch_enemy") end
end

-- books one own kill. info: what we know of the victim; opts: { pet, honor, mate, case, how, age }
-- mate = a group member's killing blow with a proof (1.3.1): a group kill (half honour and hunt, infamy and
-- protection in full), flag o; the best marks "largest level gap" and "quickest revenge" stay for own blows
local function book(info, opts)
  local c = opts.case
  -- a placeholder of this GUID (first name only) takes the full name now, before the kill is booked (unless the book
  -- knows him: its key leads, promote() leaves him)
  local g = Str(info.guid)
  local S = ns.Store
  if g and byGuid[g] and Str(info.surname) and Str(info.name) then
    promote({ guid = g, name = info.name, surname = info.surname })
  end
  local key = keyOf(info)
  if not key then return reject(c, "name") end
  local t, gt = nowT(), gtime()
  -- the state before the kill
  local mine0, his0, state0 = standingBefore(key, t)
  local e = S and S.Get(key)
  local v = victims[key] or addVictim(key, info)
  applyInfo(v, info)
  local myLevel = Num(Call(_G.UnitLevel, "player"))
  local vl, skull = level(Num(info.level)), info.skull == true
  local band = Ledger.Band(myLevel, vl, skull)
  local size = groupSize()
  -- the wear window per victim, on a clock that never runs back per victim (tv): a clock set back counts as no
  -- time passed (kicking, the window goes on), never as a fresh start
  local tv = (v.last and t < v.last) and v.last or t
  if not v.dt or tv - v.dt >= Ledger.WINDOW then v.dt, v.dn = tv, 0 end
  v.dn = v.dn + 1
  local ctx = {
    -- revenge: a real debt (he leads); an open 0 : 0 (entered by hand, assists only) is none
    revenge = state0 == "open" and his0 > mine0, protect = protects(key), hunt = onHitList(key), bounty = foreignBounty(key),
    group = size > 1 or opts.mate == true, kick = v.last ~= nil and tv - v.last < Ledger.KICK, nthToday = v.dn,
    pet = opts.pet, unknown = band == "unbekannt", honor = opts.honor, mate = opts.mate,
  }
  local r, ee, j, s = Ledger.Points(band, ctx)
  local zone, _, mapID, x, y = Util.Zone()
  local row = { t = t, key = key, name = Util.Display(v), vl = vl, ml = myLevel, band = band, r = r, e = ee, j = j,
    s = s, f = flagsOf(ctx), zone = Str(zone), mapID = mapID, x = x, y = y, me = Util.PlayerFullName() }
  table.insert(db.log, 1, row)
  while #db.log > Ledger.LOG_MAX do table.remove(db.log) end
  -- victim
  v.n = v.n + 1
  v.first = v.first or t
  v.last = tv
  v.zone, v.mapID = row.zone, mapID
  if vl then v.level = vl end
  v.pts = v.pts + r + ee + j + s
  -- no book entry for him (by GUID where there is one): the book could not have counted this kill as revenge
  local eg = e and Str(e.guid)
  if not (e and (not g or not eg or eg == g)) and not (g and S and S.ByGUID(g)) then v.pre = (v.pre or 0) + 1 end
  -- accounts
  Ledger.Accrue(db, r, ee, j, s)
  db.n = db.n + 1
  db.bands[band] = (db.bands[band] or 0) + 1
  -- best marks
  if not ctx.mate and vl and myLevel and vl - myLevel > (db.best.gap or 0) then db.best.gap = vl - myLevel end
  db.cur.streak = db.cur.streak + 1
  if db.cur.streak > (db.best.streak or 0) then db.best.streak = db.cur.streak end
  local hisLast = e and finite(e.lastKill) and e.lastKill or nil
  if not ctx.mate and ctx.revenge and hisLast and t >= hisLast
    and (not db.best.quick or t - hisLast < db.best.quick) then
    db.best.quick = t - hisLast
  end
  remember(gt, Str(info.guid), key, firstOf(info.name))
  capVictims(key)
  reputeCache = nil
  if next(listCache) then listCache = {} end
  local mine1, his1, state1 = Ledger.Standing(key)
  row.state = state1
  if c then
    c.result = ctx.mate and "group-booked" or "booked"
    c.band, c.myLevel, c.vicLevel, c.skull = band, myLevel, vl, skull or nil
    c.color = clientColor(vl)
    c.info = { form = Str(info.surname) and "full" or (Str(info.name) and "first" or "none"), class = info.class ~= nil,
      via = opts.how, age = opts.age and round(opts.age) or nil, level = vl ~= nil }
    c.group = size
  end
  probeCounts.booked = probeCounts.booked + 1
  if opts.honor then probeCounts.honorBooked = probeCounts.honorBooked + 1 end
  if opts.mate then probeCounts.groupBooked = probeCounts.groupBooked + 1 end
  -- awards
  if db.n == 1 then award("first_entry") end
  if state0 == "open" and state1 == "even" then award("receipt") end
  if (band == "rot" or band == "schaedel") and not ctx.group then award("david") end
  if ctx.revenge and hisLast and t - hisLast <= 86400 and t >= hisLast then award("same_day") end
  if ctx.revenge and mine0 == 0 and his0 >= 10 then award("patience") end
  checkArch(key)
  -- events: the kill, the standing, the rank
  standCache[key] = standCode(key)
  ns:Fire("OWN_KILL", key, row)
  ns:Fire("STANDING_CHANGED", key)
  local tier = Ledger.Tier(total(db.acc))
  local path = Ledger.Path(db.mood, db.path, db.counted, tier)
  local oldTier, oldPath = db.tier, db.path
  db.tier, db.path = tier, path
  -- a banner needs no check of its own: REPUTE_RANK only when the tier changes, REPUTE_PATH only for the path
  if tier ~= oldTier then ns:Fire("REPUTE_RANK", tier, path, oldTier, oldPath) end
  if path ~= oldPath then ns:Fire("REPUTE_PATH", path, oldPath, tier) end
  updateHook()
  return true, key
end

-- the shared gate of both sources; returns false, reason when the kill is dropped
local function gate(c, guid, name)
  if not enabled() then return reject(c, "off") end
  if not Util.IsOpenWorld() then return reject(c, "instance") end
  local A = ns.Attribution
  if A and A.DuelFoe and A.DuelFoe(guid, name) then if c then c.duel = true end return reject(c, "duel") end
  return true
end

-- my own faction (mind control, a duel area, a sanctuary): known from the tracker or the book only
local function ownFaction(info)
  local mine = Str(Call(_G.UnitFactionGroup, "player"))
  local theirs = Str(info and info.faction)
  return mine ~= nil and theirs ~= nil and theirs == mine
end

---------------------------------------------------------------------------
-- Group kills (1.3.1): claims and proofs
---------------------------------------------------------------------------
-- the GUIDs of my party or raid and their pets; rebuilt after GROUP_ROSTER_UPDATE or UNIT_PET, and for an unknown
-- GUID at most every ROSTER_AGE seconds (a pet summoned without an event). Only PARTY_KILLs on players look here.
local roster, rosterAt, rosterDirty = {}, nil, true
local function readRoster()
  local r = {}
  local raid = Util.True(Call(_G.UnitExists, "raid1"))
  local n = Num(Call(_G.GetNumGroupMembers))
  local unit, pet, max = raid and "raid" or "party", raid and "raidpet" or "partypet", raid and 40 or 4
  if n then max = math.min(max, math.max(0, floor(n))) end
  for i = 1, max do
    local g = Str(Call(_G.UnitGUID, unit .. i))
    if g then r[g] = true elseif not n then break end
    local pg = Str(Call(_G.UnitGUID, pet .. i))
    if pg then r[pg] = true end
  end
  roster, rosterAt, rosterDirty = r, gtime(), false
end
local function groupMember(guid)
  if groupSize() <= 1 then return false end
  if not rosterDirty and roster[guid] then return true end
  if rosterDirty or not rosterAt or gtime() - rosterAt >= Ledger.ROSTER_AGE then readRoster() end
  return roster[guid] == true
end
Ledger.GroupMember = groupMember

-- claims: PARTY_KILLs on players that a proof can belong to, oldest first: { gt, guid, mate, near, booked, kc, honor,
-- at, info, how, age, case }. mate = a group member's killing blow waiting for its proof; booked = done (an own kill
-- is booked at once and only takes its proofs away from the others); at = GetTime of its first proof.
-- loose: proofs no claim took yet, per channel.
local claims = {}
local loose = { kc = {}, honor = {} }
local PROOF_KINDS = { "kc", "honor" }

local function bookClaim(x, kind, dt)
  x.booked = true
  local c = x.case
  if c then c.proof = { kind = kind, dt = round(dt * 10) / 10 } end
  if not enabled() then return reject(c, "off") end
  -- my own killing blow on him came first meanwhile (or another source booked him): one kill
  if isDup(gtime(), x.guid, x.info.key, firstOf(x.info.name)) then
    probeCounts.dup = probeCounts.dup + 1
    if c then c.dup = true end
    return reject(c, "dup")
  end
  return book(x.info, { mate = true, case = c, how = x.how, age = x.age })
end

-- drops what is too old: claims beyond PROOF_AFTER (a mate's kill without a proof: "group-noproof") unless their
-- first proof came within PROOF_PAIR (x.at), proofs beyond PROOF_BEFORE
local function prune(gt)
  local i = 1
  while claims[i] do
    local x = claims[i]
    if gt - x.gt > Ledger.PROOF_AFTER and not (x.at and gt - x.at <= Ledger.PROOF_PAIR) then
      table.remove(claims, i)
      if x.mate and not x.booked then reject(x.case, "group-noproof") end
    else
      i = i + 1
    end
  end
  for _, k in ipairs(PROOF_KINDS) do
    local l = loose[k]
    while l[1] and gt - l[1] > Ledger.PROOF_BEFORE do
      table.remove(l, 1)
      probeCounts.proofLoose = probeCounts.proofLoose + 1
    end
  end
end

-- the claim a proof of this kind goes to: my own claims first (a proof of my own kill never books a mate's kill,
-- whichever came first), then the mates' claims. Within each, among the claims without a proof of this kind: one that
-- already has the proof of the other channel (the same kill), else the oldest near one (mates' claims: my target or
-- fresh in the tracker), else the oldest.
local function pick(kind)
  for pass = 1, 2 do
    local near, best
    for _, x in ipairs(claims) do
      if not x[kind] and (pass == 1) == (not x.mate) then
        if x.at then return x end
        if x.near then near = near or x end
        best = best or x
      end
    end
    if near or best then return near or best end
  end
  return nil
end

-- a proof of kind "kc" or "honor": the claim pick() names takes it
local function proof(kind)
  local gt = gtime()
  probeCounts[kind == "kc" and "proofKC" or "proofHonor"] = probeCounts[kind == "kc" and "proofKC" or "proofHonor"] + 1
  prune(gt)
  local x = pick(kind)
  if x then
    x[kind] = true
    x.at = x.at or gt
    if x.mate and not x.booked then
      local ok, err = pcall(bookClaim, x, kind, gt - x.gt)
      if not ok and ns.ReportError then ns.ReportError(err) end
    end
    return true
  end
  local l = loose[kind]
  l[#l + 1] = gt
  while #l > 8 do table.remove(l, 1); probeCounts.proofLoose = probeCounts.proofLoose + 1 end
  return false
end
Ledger.Proof = proof

-- a new claim takes the oldest loose proofs of the last PROOF_BEFORE seconds; a mate's claim is booked when it got one
local function claim(x)
  local gt = x.gt
  prune(gt)
  local got, dt
  for _, k in ipairs(PROOF_KINDS) do
    local l = loose[k]
    if l[1] then
      dt = dt or (l[1] - gt)
      table.remove(l, 1)
      x[k] = true
      x.at = x.at or gt
      got = got or k
    end
  end
  claims[#claims + 1] = x
  while #claims > 16 do
    local old = table.remove(claims, 1)
    if old.mate and not old.booked then reject(old.case, "group-noproof") end
  end
  if x.mate and got then return bookClaim(x, got, dt) end
  if x.mate then
    -- the probe learns the end of the window; the booking itself needs no timer
    if x.case and _G.C_Timer and _G.C_Timer.After then
      _G.C_Timer.After(Ledger.PROOF_AFTER + 0.1, function() pcall(prune, gtime()) end)
    end
    if x.case then x.case.result = "group-wait" end
    return false, "group-wait"
  end
  return true
end

-- a claim of the same victim within DEDUPE seconds (a mate's and my own PARTY_KILL on him are one kill)
local function claimOf(guid, gt)
  for i = #claims, 1, -1 do
    local x = claims[i]
    if x.guid == guid and gt - x.gt < Ledger.DEDUPE then return x end
  end
  return nil
end

-- the opponent is my target right now: his level as the client shows it at this moment
local function targetLevel(c, info, tg)
  if Str(Call(_G.UnitGUID, "target")) ~= tg then return end
  if c then
    local tl = Call(_G.UnitLevel, "target")
    if IsSecret(tl) then c.targetLevel = "<secret>" else c.targetLevel = Num(tl) end
  end
  local tl = Num(Call(_G.UnitLevel, "target"))
  if tl and tl > 0 then info.level = tl; info.skull = nil elseif tl and tl < 0 then info.skull = true end
end

-- PARTY_KILL(attackerGUID, targetGUID). Returns true, key when booked; false, reason otherwise.
function Ledger.OnPartyKill(attackerGUID, targetGUID)
  probeCounts.partyKill = probeCounts.partyKill + 1
  local c = newCase("partykill")
  if c then c.args = { a = form(attackerGUID), t = form(targetGUID) } end
  local a, tg = Str(attackerGUID), Str(targetGUID)
  if not a or not tg then probeCounts.secret = probeCounts.secret + 1; return reject(c, "secret") end
  local me, pet = myGUID(), Str(Call(_G.UnitGUID, "pet"))
  local kind = guidKind(tg)
  if c then c.tgt = kind end
  local who = (a == me and "me") or (pet and a == pet and "pet") or nil
  if not who then
    -- a group member, an own totem or guardian (the probe sees which), or anybody else
    if c then
      local ak = guidKind(a)
      who = ak == "Player" and (groupSize() > 1 and "group" or "foreign") or "npc"
      c.att, c.attKind, c.group = who, ak, groupSize()
      probeCounts[who] = (probeCounts[who] or 0) + 1
    end
    if kind ~= "Player" then return reject(c, "attacker") end
    local gt = gtime()
    foreignKills[#foreignKills + 1] = { gt = gt, guid = tg }
    while #foreignKills > 8 do table.remove(foreignKills, 1) end
    -- 1.3.1: a group member's kill (or his pet's) books for me with a proof
    if tg == me or not groupMember(a) then return reject(c, "attacker") end
    if c then caseGuid[c] = tg end
    local ok, why = gate(c, tg)
    if not ok then return false, why end
    local info, how, age = lookup(tg)
    info = info or { guid = tg }
    targetLevel(c, info, tg)
    if ownFaction(info) then return reject(c, "faction") end
    if claimOf(tg, gt) or isDup(gt, tg, info.key, firstOf(info.name)) then
      probeCounts.dup = probeCounts.dup + 1
      if c then c.dup = true end
      return reject(c, "dup")
    end
    local near = Str(Call(_G.UnitGUID, "target")) == tg or (how == "buffer" and age ~= nil and age <= Ledger.NEAR)
    return claim({ gt = gt, guid = tg, mate = true, near = near, info = info, how = how, age = age, case = c })
  end
  if c then c.att = who end
  probeCounts[who == "me" and "own" or "pet"] = probeCounts[who == "me" and "own" or "pet"] + 1
  if kind ~= "Player" then return reject(c, "notplayer") end
  if tg == me then return reject(c, "self") end
  if c then caseGuid[c] = tg end
  local ok, why = gate(c, tg)
  if not ok then return false, why end
  local info, how, age = lookup(tg)
  info = info or { guid = tg }
  targetLevel(c, info, tg)
  if ownFaction(info) then return reject(c, "faction") end
  local gt = gtime()
  -- 1.3.1: my own kill on a player takes its proofs; a mate's open claim on him is this kill. Only a kill that passed
  -- the gate and the faction: a duel to the death, my own faction or an instance bring no proof, such a claim would
  -- only take the proofs of a group kill next to it (hunt N1)
  local x = claimOf(tg, gt)
  if x then
    if x.mate and not x.booked and x.case then x.case.result = "group-own" end
    x.booked, x.mate = true, false     -- my own kill now: its proofs come first (pick)
  else
    claim({ gt = gt, guid = tg, booked = true })
  end
  if isDup(gt, tg, info.key, firstOf(info.name)) then
    probeCounts.dup = probeCounts.dup + 1
    if c then c.dup = true end
    return reject(c, "dup")
  end
  if c and _G.C_Timer and _G.C_Timer.After then _G.C_Timer.After(10, function() pcall(checkAlive, c, tg) end) end
  return book(info, { pet = who == "pet", case = c, how = how, age = age })
end

---------------------------------------------------------------------------
-- The honour line (fallback)
---------------------------------------------------------------------------
local honorPattern, honorOrder, honorPatternOf
local function pattern()
  local fmt = _G.COMBATLOG_HONORGAIN
  if IsSecret(fmt) or type(fmt) ~= "string" then return nil end
  if honorPatternOf ~= fmt then
    local A = ns.Attribution
    honorPattern, honorOrder = nil, nil
    if A and A.FormatToPattern then honorPattern, honorOrder = A.FormatToPattern(fmt) end
    honorPatternOf = fmt
  end
  return honorPattern, honorOrder
end
Ledger.HonorPattern = pattern

-- a group member's (or anybody's) PARTY_KILL on a player with this first name in the last 10 s
local function foreignKillOf(first, gt)
  for i = #foreignKills, 1, -1 do
    local x = foreignKills[i]
    if gt - x.gt < Ledger.DEDUPE then
      local info = lookup(x.guid)
      if info and firstOf(info.name) == first then return true end
    end
  end
  return false
end

-- what the line names: info of the victim (tracker, book, rap sheet, else the bare name)
local function infoByName(name)
  local n, s = Util.SplitFull(name)
  if not n then return nil end
  local T, S = ns.Tracker, ns.Store
  local r = T and T.ByName and T.ByName(n, s)
  if r then
    return { name = r.name, surname = r.surname, guid = r.guid, class = r.class, level = r.level, skull = r.skull,
      guild = r.guild, faction = r.faction }, "buffer", gtime() - (r.t or 0)
  end
  local k = S and S.Find(n, s)
  local e = k and S.Get(k)
  if e then
    local g = Str(e.guid)
    local rr = g and T and T.Recall and T.Recall(g)
    return { name = e.name, surname = e.surname, guid = g, class = e.class, guild = e.guild, faction = e.faction,
      key = k, level = rr and rr.level or nil, skull = rr and rr.skull or nil }, "book"
  end
  return { name = n, surname = s }, "name"
end

local function honorBook(name, c)
  local first = firstOf(name)
  local gt = gtime()
  if isDup(gt, nil, nil, first) then
    probeCounts.honorMatched = probeCounts.honorMatched + 1
    if c then c.dup = true end
    return reject(c, "dup")
  end
  if foreignKillOf(first, gt) then return reject(c, "foreign") end
  local info, how, age = infoByName(name)
  if not info then return reject(c, "name") end
  local ok, why = gate(c, info.guid, name)
  if not ok then return false, why end
  if ownFaction(info) then return reject(c, "faction") end
  probeCounts.honorAlone = probeCounts.honorAlone + 1
  if not Ledger.HONOR_FALLBACK then return reject(c, "fallback-off") end
  return book(info, { honor = true, case = c, how = how, age = age })
end

-- CHAT_MSG_COMBAT_HONOR_GAIN(text). The line with a victim waits HONOR_WAIT seconds for its PARTY_KILL.
function Ledger.OnHonorGain(text)
  probeCounts.honor = probeCounts.honor + 1
  -- 1.3.1: any honour line is a proof that I took part in a kill (group kills)
  proof("honor")
  text = Str(text)
  if not text then return false, "secret" end
  local p, order = pattern()
  local name, rank, honor
  local A = ns.Attribution
  if p and A and A.MatchArgs then name, rank, honor = A.MatchArgs(text, p, order) end
  if not name then
    probeCounts.honorPlain = probeCounts.honorPlain + 1
    local c = newCase("honor")
    if c then c.honor = { form = "plain", len = #text }; c.result = "noname" end
    return false, "noname"
  end
  probeCounts.honorNamed = probeCounts.honorNamed + 1
  local first = firstOf(name)
  local gt = gtime()
  -- the probe notes the line on the own PARTY_KILL case of the last 10 s, else as a case of its own
  local c
  if debugOn() then
    local k = probeDB()
    for _, x in ipairs(k and k.cases or {}) do
      if x.src == "partykill" and gt - (x.gt or 0) <= Ledger.DEDUPE and x.att and (x.att == "me" or x.att == "pet") then
        c = x
        break
      end
    end
    local h = { dt = c and round((gt - c.gt) * 10) / 10 or nil, name = name:find("[%s%-]") and "full" or "first",
      rank = rank and rank:sub(1, 24) or nil, honor = tonumber(honor and honor:gsub("[^%d]", "") or nil), form = "named" }
    if c then c.honor = h else c = newCase("honor"); if c then c.honor = h end end
  end
  if isDup(gt, nil, nil, first) then
    probeCounts.honorMatched = probeCounts.honorMatched + 1
    return false, "dup"
  end
  local own = c and c.src == "partykill"
  local function later()
    local ok, err = pcall(honorBook, name, (not own) and c or nil)
    if not ok and ns.ReportError then ns.ReportError(err) end
  end
  if _G.C_Timer and _G.C_Timer.After and Ledger.HONOR_WAIT > 0 then _G.C_Timer.After(Ledger.HONOR_WAIT, later) else later() end
  return true, "waiting"
end

---------------------------------------------------------------------------
-- Hooks in the tracker: victim alarm (Paket C reads VICTIM_SPOTTED) and placeholders
---------------------------------------------------------------------------
local spottedAt = {}
local function victimSpotted(key, unit, how)
  if not victims[key] then return end
  local t = gtime()
  if spottedAt[key] == t then return end
  spottedAt[key] = t
  ns:Fire("VICTIM_SPOTTED", key, unit, how)
end

-- the hooks stand only while they have work: the alarm on and victims there; placeholders there
function updateHook()
  local T = ns.Tracker
  if not T then return end
  local S = ns.Store
  local on = enabled() and nVictims > 0 and S and S.Setting("alert.victims") == true
  T.victimHook = on and victimSpotted or nil
  T.ledgerHook = (enabled() and nPlaceholders > 0) and promote or nil
end
Ledger.UpdateHook = function() updateHook() end

---------------------------------------------------------------------------
-- Probe snapshot (/dn probe) and the probe-only events
---------------------------------------------------------------------------
function Ledger.ProbeSnapshot()
  local p = pattern()
  local apis = {}
  for _, a in ipairs({ "GetNumGroupMembers", "GetMaxLevelForPlayerExpansion", "GetMaxPlayerLevel",
    "GetQuestDifficultyColor", "UnitIsDeadOrGhost", "GetDuelerInfo", "StartDuel", "hooksecurefunc" }) do
    apis[a] = type(_G[a]) == "function"
  end
  local A = ns.Attribution
  return { counts = probeCounts, pattern = p, maxLevel = Ledger.MaxLevel(), apis = apis, myLevel =
    Num(Call(_G.UnitLevel, "player")), group = groupSize(), enabled = enabled(), victims = nVictims,
    placeholders = nPlaceholders, deathDuel = A and A.DeathDuelState and A.DeathDuelState() or nil }
end

local function onKillsChanged()
  proof("kc")
  if not debugOn() then return end
  lastKC = gtime()
  local k = probeDB()
  for _, c in ipairs(k and k.cases or {}) do
    if lastKC - (c.gt or 0) <= 10 and c.kc == nil then c.kc = round((lastKC - c.gt) * 10) / 10 end
  end
end

local function onUnitDied(_, guid)
  if not debugOn() then return end
  guid = Str(guid)
  if not guid then return end
  local k = probeDB()
  local gt = gtime()
  for _, c in ipairs(k and k.cases or {}) do
    if caseGuid[c] == guid and gt - (c.gt or 0) <= 10 then c.died = true end
  end
end

local diedOn = false
local function watchDied()
  if debugOn() and not diedOn then
    diedOn = ns:RegisterEvent("UNIT_DIED", onUnitDied)
  elseif not debugOn() and diedOn then
    ns:UnregisterEvent("UNIT_DIED")
    diedOn = false
  end
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------
ns:RegisterEvent("PARTY_KILL", function(_, a, t) Ledger.OnPartyKill(a, t) end)
ns:RegisterEvent("CHAT_MSG_COMBAT_HONOR_GAIN", function(_, text) Ledger.OnHonorGain(text) end)
ns:RegisterEvent("PLAYER_PVP_KILLS_CHANGED", onKillsChanged)
-- the group roster of the group kills: read again at the next PARTY_KILL on a player
for _, ev in ipairs({ "GROUP_ROSTER_UPDATE", "UNIT_PET", "PLAYER_ENTERING_WORLD" }) do
  ns:RegisterEvent(ev, function() rosterDirty = true end)
end

ns:On("READY", function() watchDied(); updateHook() end)
ns:On("SETTINGS_CHANGED", function(path)
  if path == "debug" then watchDied() end
  -- switched on again: what the book learned meanwhile (GUIDs, moves) is followed now, not at the next start
  if path == "ledger.enabled" and enabled() then Ledger.Reconcile() end
  if path == "alert.victims" or path == "ledger.enabled" then updateHook() end
end)

-- his kills, hand revenge, status, a new or removed entry: the standing may have changed
ns:On("ENEMY_UPDATED", function(key)
  if not db then return end
  if enabled() then followBook(key) end
  if standingTouched(key) then checkArch(key) end
end)
ns:On("ENEMY_REMOVED", function(key)
  if not db then return end
  standingTouched(key)
end)
-- the book entry moved to a fuller key: the victim follows
ns:On("ENEMY_REKEYED", function(oldKey, newKey)
  if not db then return end
  local v = victims[oldKey]
  if v then
    local e = ns.Store and ns.Store.Get(newKey)
    local eg = e and Str(e.guid)
    -- a victim of another GUID stays where it is: the book's entry is another player's
    if not (v.guid and eg and eg ~= v.guid) then
      moveVictim(oldKey, newKey, e and e.surname)
      updateHook()
    end
  end
  standCache[oldKey] = nil
end)
-- an own death by a player ends the streak
ns:On("DEATH_RECORDED", function(journal)
  if not db or type(journal) ~= "table" then return end
  if journal.kind == "pvp" and journal.counted ~= false then db.cur.streak = 0 end
end)

-- only for tests: the in-memory state between two loads
function Ledger.ResetRuntime()
  recent, foreignKills, spottedAt, lastKC = {}, {}, {}, nil
  claims, loose, roster, rosterAt, rosterDirty = {}, { kc = {}, honor = {} }, {}, nil, true
end
