-- DeathNote - Ledger.lua (1.3.0)
-- The rap sheet: own killing blows on players, the standing "me : him" per enemy, and the repute (four accounts,
-- rank, path, needle). Data and rules only; the book (UI.lua, Extras.lua) and the alarm (Alert.lua) read it through
-- the functions and the five bus events below. Nothing of this goes over the wire.
--
-- Data, account-wide and language-neutral (DeathNoteDB.ledger, DB version 4, see Store.Init):
--   victims[key] = { key, name, surname, guid, class, level, guild, faction, n, first, last, dn, dt, pts, old,
--                    zone, mapID }        n = my killing blows on him (the "me" of the standing)
--   log          = newest kills first, at most LOG_MAX: { t, key, vl, ml, band, r, e, j, s, f, zone, mapID, x, y,
--                    me, state }          f = flag letters (see FLAGS)
--   acc, mood    = { r, e, j, s }       lifetime accounts (never sink) and the sliding values (path and needle)
--   n, counted   = own kills, kills that earned points
--   tier, path   = the rank and path last reported (REPUTE_RANK fires once per change)
--   bands, best, cur, awards, gone
-- The standing itself is never stored: Ledger.Standing reads victims[key].n and the book entry.
--
-- Detection (decision 7): PARTY_KILL with my GUID or my pet's as attacker is the source. The honour line
-- (COMBATLOG_HONORGAIN of the client, made into a pattern) is the fallback when no PARTY_KILL came for that victim.
-- Dropped: no player, my own faction, the opponent of a duel to the death, instances, the same victim within 10 s.
-- Whatever the client does here is unmeasured: /dn debug writes every case to DeathNoteDB.probe.kills.

local ADDON, ns = ...
local Util = ns.Util
local Call, IsSecret, Str, Num = Util.Call, Util.IsSecret, Util.Str, Util.Num

local Ledger = {}
ns.Ledger = Ledger

Ledger.VICTIMS_MAX = 200     -- victims kept; the oldest one that is not in the book goes first
Ledger.LOG_MAX = 60          -- newest kills kept
Ledger.DEDUPE = 10           -- seconds: the same victim twice is one kill
Ledger.KICK = 600            -- seconds: a second kill on the same victim within this is "kicking"
Ledger.WINDOW = 86400        -- seconds: the wear window per victim
Ledger.WEAR = { 1, 0.8, 0.6, 0.4, 0.2 }   -- factor of the 1st..5th kill in the window, 0 from the 6th on
Ledger.DECAY = 0.98          -- mood = mood * DECAY + points
Ledger.PATH_FROM = 10        -- counted kills before a path is named
Ledger.PATH_SWITCH = 1.15    -- another account must beat the current path by 15 % to take over
Ledger.OLD_POINTS = 3        -- honour per old case from the migration (revenge, level unknown)
Ledger.OLD_MAX = 10          -- old cases per enemy that earn points
Ledger.HONOR_WAIT = 2        -- seconds the honour line waits for a PARTY_KILL of the same kill
Ledger.HONOR_FALLBACK = true -- the honour line books a kill when no PARTY_KILL came (decision 7; see the probe)
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
-- u level unknown, m booked from the honour line
Ledger.FLAGS = "vshbgnpum"

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

-- the path: the biggest account of mood, from PATH_FROM counted kills on; another one takes over only when it
-- beats the current path by PATH_SWITCH
function Ledger.Path(mood, prevPath, counted)
  if type(mood) ~= "table" or not finite(counted) or counted < Ledger.PATH_FROM then return nil end
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
    path = Ledger.Path(st.mood, path, st.counted)
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
local reputeCache

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

-- repairs one victim in place; false = beyond repair
local function sanitizeVictim(key, v)
  if type(key) ~= "string" or type(v) ~= "table" then return false end
  local n, s = Util.SplitKey(key)
  v.key = key
  v.name = Util.CleanName(v.name) or Util.CleanName(n)
  if not v.name then return false end
  if v.surname ~= nil then v.surname = Util.CleanName(v.surname) end
  v.n = count(v.n)
  if v.n < 1 then return false end
  v.old = math.min(count(v.old), v.n)
  if v.old == 0 then v.old = nil end
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
  row.zone, row.me = cleanStr(row.zone, 80), cleanStr(row.me, 64)
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
  if type(d.gone) ~= "table" then d.gone = {} end
  for k, v in pairs(d.gone) do if type(k) ~= "string" or not finite(v) then d.gone[k] = nil end end
  return d
end

local function total(acc) return acc.r + acc.e + acc.j + acc.s end

---------------------------------------------------------------------------
-- Standing
---------------------------------------------------------------------------
local function handRevenge(e)
  local S = ns.Store
  return (S and S.HandRevenge) and S.HandRevenge(e) or 0
end

-- me : him for a key (book or rap sheet). nil while the rap sheet is switched off.
function Ledger.Standing(key)
  if not enabled() or type(key) ~= "string" then return nil end
  local S = ns.Store
  local e = S and S.Get(key)
  local v = victims[key]
  local mine = (v and v.n or 0) + (e and handRevenge(e) or 0)
  local his = e and count(e.kills) or 0
  local state = Ledger.StateOf(mine, his, e and e.assists, e and e.status)
  if not state then return nil end
  return mine, his, state
end

-- "me" alone (Store.Bounty, sorting); nil while switched off
function Ledger.Mine(key, e)
  if not enabled() or type(key) ~= "string" then return nil end
  local v = victims[key]
  if e == nil and ns.Store then e = ns.Store.Get(key) end
  return (v and v.n or 0) + (type(e) == "table" and handRevenge(e) or 0)
end

local STATUS_CODE = { wanted = 0, suspect = 1, pardoned = 2 }
local function standCode(key)
  local S = ns.Store
  local e = S and S.Get(key)
  local v = victims and victims[key]
  local mine = (v and v.n or 0) + (e and handRevenge(e) or 0)
  local his = e and count(e.kills) or 0
  local st = e and (STATUS_CODE[e.status] or 0) or 3
  return (mine * 1048576 + his) * 4 + st
end

-- returns true when the standing changed
local function standingTouched(key)
  if type(key) ~= "string" then return false end
  local code = standCode(key)
  if standCache[key] == code then return false end
  standCache[key] = code
  if enabled() then ns:Fire("STANDING_CHANGED", key) end
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

local function dropVictim(key)
  local v = victims[key]
  if not v then return end
  if v.guid and byGuid[v.guid] == key then byGuid[v.guid] = nil end
  if v.surname == nil then nPlaceholders = nPlaceholders - 1 end
  victims[key] = nil
  nVictims = nVictims - 1
end

-- the cap: the victim with the oldest last kill that is not in the book goes
local function capVictims()
  while nVictims > Ledger.VICTIMS_MAX do
    local oldK, oldT
    for k, v in pairs(victims) do
      if not inBook(k) then
        local t = v.last or 0
        if not oldT or t < oldT then oldK, oldT = k, t end
      end
    end
    if not oldK then break end
    dropVictim(oldK)
  end
end

local function addVictim(key, info)
  local v = { key = key, n = 0, pts = 0, dn = 0 }
  local n, s = Util.SplitKey(key)
  v.name = Util.CleanName(info and info.name) or n
  v.realm = s
  local sn = info and Util.CleanName(info.surname)
  if sn then v.surname = Util.CapFirst(sn) end
  victims[key] = v
  nVictims = nVictims + 1
  if v.surname == nil then nPlaceholders = nPlaceholders + 1 end
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
    moveVictim(other, v.key)
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

-- moves a victim to a new key (placeholder seen with surname, or the book entry moved); merges into an existing one
function moveVictim(oldKey, newKey)
  local v = victims[oldKey]
  if not v or oldKey == newKey then return end
  local into = victims[newKey]
  dropVictim(oldKey)
  if into then
    into.n = into.n + v.n
    into.old = ((into.old or 0) + (v.old or 0) > 0) and (into.old or 0) + (v.old or 0) or nil
    into.pts = into.pts + v.pts
    if v.first and (not into.first or v.first < into.first) then into.first = v.first end
    if v.last and (not into.last or v.last > into.last) then into.last, into.zone, into.mapID = v.last, v.zone, v.mapID end
    if not into.guid and v.guid then into.guid = v.guid; byGuid[v.guid] = newKey end
  else
    v.key = newKey
    local n, s = Util.SplitKey(newKey)
    v.name, v.realm = n, s
    victims[newKey] = v
    nVictims = nVictims + 1
    if v.surname == nil then nPlaceholders = nPlaceholders + 1 end
    if v.guid then byGuid[v.guid] = newKey end
  end
  for i = 1, #db.log do if db.log[i].key == oldKey then db.log[i].key = newKey end end
  if db.gone[oldKey] then db.gone[newKey] = math.max(db.gone[newKey] or 0, db.gone[oldKey]); db.gone[oldKey] = nil end
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
  if not full then return end
  local cs = Util.CleanName(sn)
  if not cs then return end
  -- first: the victim stops counting as placeholder
  nPlaceholders = nPlaceholders - 1
  v.surname = Util.CapFirst(cs)
  moveVictim(k, full)
  updateHook()
end
Ledger.Promote = promote

---------------------------------------------------------------------------
-- Migration and the check at every start (DB version 4, repute concept 4.3)
---------------------------------------------------------------------------
-- revenge the old book recognised (own killing blow, honour): revenge minus revenge noted by hand
local function autoRevenge(e)
  if type(e) ~= "table" then return 0 end
  return math.max(0, count(e.revenge) - handRevenge(e))
end

-- every book entry whose recognised revenge exceeds the rap sheet gets the difference as old cases.
-- Idempotent: a second run finds nothing. Silent: no events, the reported rank follows without a banner.
function Ledger.Reconcile()
  if not db then return 0 end
  local S = ns.Store
  if not S then return 0 end
  local added = 0
  for key, e in pairs(S.All()) do
    local auto = autoRevenge(e)
    if auto > 0 then
      local v = victims[key]
      local have = v and v.n or count(db.gone[key])
      local diff = auto - have
      if diff > 0 then
        if not v then
          v = addVictim(key, { name = e.name, surname = e.surname })
          db.gone[key] = nil
        end
        applyInfo(v, { guid = e.guid, class = e.class, guild = e.guild, faction = e.faction })
        if not v.level then v.level = level(e.level) end
        local was = v.old or 0
        v.n = v.n + diff
        v.old = was + diff
        local t = finite(e.revengeAutoAt) and e.revengeAutoAt or (finite(e.lastRevenge) and e.lastRevenge or nil)
        if t then
          if not v.last or t > v.last then v.last = t end
          if not v.first or t < v.first then v.first = t end
        end
        local scored = math.min(v.old, Ledger.OLD_MAX) - math.min(was, Ledger.OLD_MAX)
        if scored > 0 then
          local p = scored * Ledger.OLD_POINTS
          db.acc.e = db.acc.e + p
          db.mood.e = db.mood.e + p
          v.pts = v.pts + p
          db.counted = db.counted + scored
        end
        db.n = db.n + diff
        added = added + diff
      end
    end
  end
  if added > 0 then
    db.tier = Ledger.Tier(total(db.acc))
    db.path = Ledger.Path(db.mood, db.path, db.counted)
    reputeCache = nil
    capVictims()
  end
  return added
end

-- Store.Init calls this (login and tests): repairs the data, migrates, primes the standing cache
function Ledger.Init(saved)
  if type(saved) ~= "table" then return end
  saved.ledger = sanitize(saved.ledger)
  db = saved.ledger
  victims = db.victims
  indexVictims()
  Ledger.Reconcile()
  capVictims()
  standCache = {}
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

local VSORT = {
  recent = function(a, b)
    if (a.last or 0) ~= (b.last or 0) then return (a.last or 0) > (b.last or 0) end
    return a.key < b.key
  end,
  count = function(a, b)
    if a.n ~= b.n then return a.n > b.n end
    if (a.last or 0) ~= (b.last or 0) then return (a.last or 0) > (b.last or 0) end
    return a.key < b.key
  end,
  name = function(a, b)
    local na, nb = Util.Display(a):lower(), Util.Display(b):lower()
    if na ~= nb then return na < nb end
    return a.key < b.key
  end,
}

-- the victims as a list (the tables themselves, read only); sort "recent" (default), "count", "name"
function Ledger.Victims(sort)
  local out = {}
  if not db then return out end
  for _, v in pairs(victims) do out[#out + 1] = v end
  table.sort(out, VSORT[sort] or VSORT.recent)
  return out
end

-- the newest kills, newest first (read only)
function Ledger.Log() return db and db.log or {} end

-- { tier, path, total, next, needle, acc, n, counted, best, awards, bands }; one table, rebuilt after a change
-- (read only)
function Ledger.Repute()
  if not db then return { tier = 1, total = 0, needle = 0, acc = newAcc(), n = 0, counted = 0, best = {}, awards = {},
    bands = {} } end
  if reputeCache then return reputeCache end
  local sum = total(db.acc)
  local tier, nxt = Ledger.Tier(sum)
  reputeCache = { tier = tier, path = Ledger.Path(db.mood, db.path, db.counted), total = sum, next = nxt,
    needle = Ledger.Needle(db.mood), acc = db.acc, n = db.n, counted = db.counted, best = db.best, awards = db.awards,
    bands = db.bands }
  return reputeCache
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

-- strikes a victim from the rap sheet: name and count go, the points earned stay
function Ledger.RemoveVictim(key)
  if not db or type(key) ~= "string" or not victims[key] then return false end
  local S = ns.Store
  local e = S and S.Get(key)
  -- the check at the next start must not bring him back from the book's revenge count
  if e then db.gone[key] = autoRevenge(e) end
  dropVictim(key)
  reputeCache = nil
  standingTouched(key)
  updateHook()
  return true
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

-- the key for a victim: full name when known; else a book entry or victim with this GUID or a unique first name;
-- else the placeholder "Name-<realm>" (moved later when he is seen with surname)
local function keyOf(info)
  if info.key then return info.key end
  local sn = Str(info.surname)
  if sn then return (Util.KeyFor(info.name, sn)) end
  local S = ns.Store
  local g = Str(info.guid)
  if g then
    local k = S and S.ByGUID(g)
    if k then return k end
    if byGuid[g] then return byGuid[g] end
  end
  local name = Str(info.name)
  if not name then return nil end
  local found = S and S.Find(name)
  local fe = found and S.Get(found)
  if fe and guidFits(fe.guid, g) then return found end
  local ln, hit, hits = name:lower(), nil, 0
  for k, v in pairs(victims) do
    if v.name and v.name:lower() == ln and guidFits(v.guid, g) then hit, hits = k, hits + 1 end
  end
  if hits == 1 then return hit end
  return (Util.KeyFor(name))
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

local function onHitList(key)
  local G = ns.Guild
  if not (G and G.Hunt) then return false end
  local ok, h = pcall(G.Hunt, key, "all")
  return ok and h ~= nil
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
  honor = 0, honorNamed = 0, honorPlain = 0, honorMatched = 0, honorAlone = 0, honorBooked = 0, rejected = {} }
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

local function isDup(gt, guid, key, first)
  for i = #recent, 1, -1 do
    local x = recent[i]
    if gt - x.gt < Ledger.DEDUPE then
      if (guid and x.guid == guid) or (key and x.key == key) or (first and x.first == first) then return true end
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

-- books one own kill. info: what we know of the victim; opts: { pet, honor, case, how, age }
local function book(info, opts)
  local c = opts.case
  -- a placeholder of this GUID (first name only) takes the full name now, before the kill is booked
  local g = Str(info.guid)
  if g and byGuid[g] and Str(info.surname) and Str(info.name) then
    promote({ guid = g, name = info.name, surname = info.surname })
  end
  local key = keyOf(info)
  if not key then return reject(c, "name") end
  local S = ns.Store
  local t, gt = nowT(), gtime()
  -- the state before: revenge = the standing was open
  local _, _, state0 = Ledger.Standing(key)
  local mine0, his0 = Ledger.Standing(key)
  mine0, his0 = mine0 or 0, his0 or 0
  local e = S and S.Get(key)
  local v = victims[key] or addVictim(key, info)
  applyInfo(v, info)
  local myLevel = Num(Call(_G.UnitLevel, "player"))
  local vl, skull = level(Num(info.level)), info.skull == true
  local band = Ledger.Band(myLevel, vl, skull)
  local size = groupSize()
  -- the wear window per victim
  if not v.dt or t - v.dt >= Ledger.WINDOW or t < v.dt then v.dt, v.dn = t, 0 end
  v.dn = v.dn + 1
  local ctx = {
    revenge = state0 == "open", protect = protects(key), hunt = onHitList(key), bounty = foreignBounty(key),
    group = size > 1, kick = v.last ~= nil and t - v.last >= 0 and t - v.last < Ledger.KICK, nthToday = v.dn,
    pet = opts.pet, unknown = band == "unbekannt", honor = opts.honor,
  }
  local r, ee, j, s = Ledger.Points(band, ctx)
  local zone, _, mapID, x, y = Util.Zone()
  local row = { t = t, key = key, vl = vl, ml = myLevel, band = band, r = r, e = ee, j = j, s = s, f = flagsOf(ctx),
    zone = Str(zone), mapID = mapID, x = x, y = y, me = Util.PlayerFullName() }
  table.insert(db.log, 1, row)
  while #db.log > Ledger.LOG_MAX do table.remove(db.log) end
  -- victim
  v.n = v.n + 1
  v.first = v.first or t
  v.last = t
  v.zone, v.mapID = row.zone, mapID
  if vl then v.level = vl end
  v.pts = v.pts + r + ee + j + s
  db.gone[key] = nil
  -- accounts
  Ledger.Accrue(db, r, ee, j, s)
  db.n = db.n + 1
  db.bands[band] = (db.bands[band] or 0) + 1
  -- best marks
  if vl and myLevel and vl - myLevel > (db.best.gap or 0) then db.best.gap = vl - myLevel end
  db.cur.streak = db.cur.streak + 1
  if db.cur.streak > (db.best.streak or 0) then db.best.streak = db.cur.streak end
  local hisLast = e and finite(e.lastKill) and e.lastKill or nil
  if ctx.revenge and hisLast and t >= hisLast and (not db.best.quick or t - hisLast < db.best.quick) then
    db.best.quick = t - hisLast
  end
  remember(gt, Str(info.guid), key, firstOf(info.name))
  capVictims()
  reputeCache = nil
  local mine1, his1, state1 = Ledger.Standing(key)
  row.state = state1
  if c then
    c.result = "booked"
    c.band, c.myLevel, c.vicLevel, c.skull = band, myLevel, vl, skull or nil
    c.color = clientColor(vl)
    c.info = { form = Str(info.surname) and "full" or (Str(info.name) and "first" or "none"), class = info.class ~= nil,
      via = opts.how, age = opts.age and round(opts.age) or nil, level = vl ~= nil }
    c.group = size
  end
  probeCounts.booked = probeCounts.booked + 1
  if opts.honor then probeCounts.honorBooked = probeCounts.honorBooked + 1 end
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
  local path = Ledger.Path(db.mood, db.path, db.counted)
  if tier ~= db.tier or path ~= db.path then
    local oldTier, oldPath = db.tier, db.path
    db.tier, db.path = tier, path
    ns:Fire("REPUTE_RANK", tier, path, oldTier, oldPath)
  end
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
    if kind == "Player" then
      foreignKills[#foreignKills + 1] = { gt = gtime(), guid = tg }
      while #foreignKills > 8 do table.remove(foreignKills, 1) end
    end
    return reject(c, "attacker")
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
  if c and Str(Call(_G.UnitGUID, "target")) == tg then
    local tl = Call(_G.UnitLevel, "target")
    if IsSecret(tl) then c.targetLevel = "<secret>" else c.targetLevel = Num(tl) end
  end
  -- the opponent is my target right now: his level as the client shows it at this moment
  if Str(Call(_G.UnitGUID, "target")) == tg then
    local tl = Num(Call(_G.UnitLevel, "target"))
    if tl and tl > 0 then info.level = tl; info.skull = nil elseif tl and tl < 0 then info.skull = true end
  end
  if ownFaction(info) then return reject(c, "faction") end
  local gt = gtime()
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
local honorPattern, honorPatternOf
local function pattern()
  local fmt = _G.COMBATLOG_HONORGAIN
  if IsSecret(fmt) or type(fmt) ~= "string" then return nil end
  if honorPatternOf ~= fmt then
    local A = ns.Attribution
    honorPattern = A and A.FormatToPattern and A.FormatToPattern(fmt) or nil
    honorPatternOf = fmt
  end
  return honorPattern
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
  text = Str(text)
  if not text then return false, "secret" end
  local p = pattern()
  local name, rank, honor
  if p then name, rank, honor = text:match(p) end
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

ns:On("READY", function() watchDied(); updateHook() end)
ns:On("SETTINGS_CHANGED", function(path)
  if path == "debug" then watchDied() end
  if path == "alert.victims" or path == "ledger.enabled" then updateHook() end
end)

-- his kills, hand revenge, status, a new or removed entry: the standing may have changed
ns:On("ENEMY_UPDATED", function(key)
  if not db then return end
  if standingTouched(key) then checkArch(key) end
end)
ns:On("ENEMY_REMOVED", function(key)
  if not db then return end
  standingTouched(key)
end)
-- the book entry moved to a fuller key: the victim follows
ns:On("ENEMY_REKEYED", function(oldKey, newKey)
  if not db then return end
  if victims[oldKey] then moveVictim(oldKey, newKey) end
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
end
