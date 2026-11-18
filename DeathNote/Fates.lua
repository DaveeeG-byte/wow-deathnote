-- DeathNote - Fates.lua (1.6.0 deaths)
-- Every own death with its cause, not only the ones by players: creatures, a pet without a known owner, the world
-- (falling, drowning, fire, lava, fatigue, slime). Data and words only; the journal's views are FatesUI.lua.
--
-- Rules:
--   * The feud between players stays the heart. A death by a player never gets a row here (the journal has it).
--   * No alarm, no sharing: nothing of this goes over the wire (Sync.lua and Friends.lua never read db.fates).
--   * Fed by DEATH_RECORDED (Attribution.lua: the journal entry with `cause`), one row per death of kind "pve".
--     The switch fates.on (House Rules, sheet Book, default on): off = nothing new is recorded, what is there stays.
--   * Caps: 300 rows (oldest go first), 150 causes (the one met longest ago goes first). One death touches one row
--     and one cause, never the whole book.
--   * Every value from the client is checked with IsSecret first (Core.lua Util.Str/Num), only then compared.
--   * Unmeasured on Forever: the death recap's environmental rows (event ENVIRONMENTAL_DAMAGE, environmentalType;
--     no such row in the owner's 60 recorded recap rows) and C_CreatureInfo.GetCreatureID. Counters in probe.pve.
--
-- DeathNoteDB.fates = {
--   rows   = { { t, zone, subzone, mapID, x, y, me, myLevel, kind = "pve", art, env, name, npc, spell }, ... } newest first
--   foes   = { [fkey] = { n, t, art, env, name, npc, spell, zone, subzone, mapID, x, y } }   fkey: "npc:<id>",
--            "name:<name>", "env:<type>", "pet", "unknown"
--   awards = { [id] = time }, recent = { t, t, t } (the last deaths here, for the streak award) }

local _, ns = ...
local Util = ns.Util
local L, Fmt = ns.L, ns.F
local IsSecret, Str, Num, Call = Util.IsSecret, Util.Str, Util.Num, Util.Call

local Fates = {}
ns.Fates = Fates

Fates.MAX_ROWS = 300
Fates.MAX_FOES = 150
Fates.NEMESIS = 3           -- a cause that killed you this often gets a place and, as number one, the stamp
Fates.STREAK = 3            -- award "bad streak": this many deaths by creatures or the world ...
Fates.STREAK_WINDOW = 600   -- ... within this many seconds
Fates.WEEK = 7 * 86400
Fates.NAME_MAX = 60         -- bytes of a creature's name kept

-- environmental types of the combat log / death recap (Blizzard: Drowning, Falling, Fatigue, Fire, Lava, Slime;
-- ForeverAuras Types.lua and Details parser.lua on Forever use exactly these) -> own id
Fates.ENV = { drowning = "drown", falling = "fall", fatigue = "fatigue", fire = "fire", lava = "lava", slime = "slime" }
local ENV_WORD = { drown = "FATE_ENV_DROWN", fall = "FATE_ENV_FALL", fatigue = "FATE_ENV_FATIGUE", fire = "FATE_ENV_FIRE",
  lava = "FATE_ENV_LAVA", slime = "FATE_ENV_SLIME", other = "FATE_ENV_OTHER" }
local VALID_ART = { creature = true, pet = true, env = true, unknown = true }

-- awards for dying (rap sheet, own row below the kill awards); names and conditions in every language (Locales)
Fates.AWARDS = {
  { id = "fall" }, { id = "drown" }, { id = "fire" }, { id = "fatigue" },
  { id = "beast3" }, { id = "beast10", hidden = true }, { id = "streak" }, { id = "zoo", hidden = true },
}
local AWARD_IDS = {}
for _, a in ipairs(Fates.AWARDS) do AWARD_IDS[a.id] = true end
Fates.ZOO = 10              -- award "zoo": killed by this many different creatures

local function finite(v) return type(v) == "number" and not IsSecret(v) and v == v and v > -math.huge and v < math.huge end
local function now() return Num(Call(_G.time)) or 0 end

------------------------------------------------------------------------
-- Probe (probe.pve): counters since login and over all sessions, numbers only
------------------------------------------------------------------------
Fates.counts = {}
local function store() return ns.Store end
local function rawDB()
  local S = store()
  return S and S.DB and S.DB() or nil
end
function Fates.Count(k)
  if type(k) ~= "string" then return end
  Fates.counts[k] = (Fates.counts[k] or 0) + 1
  local db = rawDB()
  if type(db) ~= "table" then return end
  if type(db.probe) ~= "table" then db.probe = {} end
  local p = db.probe.pve
  if type(p) ~= "table" then p = {}; db.probe.pve = p end
  if type(p.counts) ~= "table" then p.counts = {} end
  p.counts[k] = (tonumber(p.counts[k]) or 0) + 1
end
-- for Probe.Run: the stored totals, this session, whether the NPC id API exists
function Fates.ProbeSnapshot(keep)
  local s = {}
  for k, v in pairs(Fates.counts) do s[k] = v end
  local CI = rawget(_G, "C_CreatureInfo")
  local f = rawDB() and rawDB().fates
  return { counts = type(keep) == "table" and type(keep.counts) == "table" and keep.counts or {}, session = s,
    npcApi = type(CI) == "table" and type(CI.GetCreatureID) == "function" or false,
    rows = type(f) == "table" and type(f.rows) == "table" and #f.rows or 0 }
end

------------------------------------------------------------------------
-- Storage
------------------------------------------------------------------------
local checked            -- the fates table already repaired this session
Fates.version = 0        -- goes up with every change (caches of the views)

local function plainStr(v, max)
  local s = Str(v)
  if not s then return nil end
  if max and #s > max then s = s:sub(1, max) end
  return s
end

local function cleanPlace(src, dst)
  dst.t = finite(src.t) and src.t or nil
  dst.zone, dst.subzone = plainStr(src.zone, 80), plainStr(src.subzone, 80)
  dst.mapID = finite(src.mapID) and src.mapID or nil
  dst.x, dst.y = finite(src.x) and src.x or nil, finite(src.y) and src.y or nil
end

local function cleanRow(r)
  if type(r) ~= "table" or not finite(r.t) then return nil end
  if not VALID_ART[r.art] then r.art = "unknown" end
  r.kind = "pve"
  if r.env ~= nil and not ENV_WORD[r.env] then r.env = "other" end
  if r.name ~= nil and not Str(r.name) then r.name = nil end
  if r.npc ~= nil and not finite(r.npc) then r.npc = nil end
  return r
end

function Fates.Repair(f)
  if type(f) ~= "table" then f = {} end
  if type(f.rows) ~= "table" then f.rows = {} end
  local rows = {}
  for i = 1, #f.rows do
    local r = cleanRow(f.rows[i])
    if r then rows[#rows + 1] = r end
  end
  table.sort(rows, function(a, b) return a.t > b.t end)
  while #rows > Fates.MAX_ROWS do rows[#rows] = nil end
  f.rows = rows
  if type(f.foes) ~= "table" then f.foes = {} end
  local n = 0
  for k, x in pairs(f.foes) do
    if type(k) ~= "string" or type(x) ~= "table" or not finite(x.n) or x.n < 1 then
      f.foes[k] = nil
    else
      x.n = math.floor(x.n)
      if not VALID_ART[x.art] then x.art = "unknown" end
      if x.t ~= nil and not finite(x.t) then x.t = nil end
      n = n + 1
    end
  end
  if n > Fates.MAX_FOES then Fates.CapFoes(f.foes) end
  if type(f.awards) ~= "table" then f.awards = {} end
  for k, v in pairs(f.awards) do if not AWARD_IDS[k] or not finite(v) then f.awards[k] = nil end end
  if type(f.recent) ~= "table" then f.recent = {} end
  local rec = {}
  for i = 1, #f.recent do if finite(f.recent[i]) then rec[#rec + 1] = f.recent[i] end end
  while #rec > Fates.STREAK do table.remove(rec, 1) end
  f.recent = rec
  return f
end

-- the fates table (repaired once per session), or nil before the book is loaded
function Fates.DB()
  local db = rawDB()
  if type(db) ~= "table" then return nil end
  if type(db.fates) ~= "table" or checked ~= db.fates then
    db.fates = Fates.Repair(db.fates)
    checked = db.fates
    Fates.version = Fates.version + 1
  end
  return db.fates
end

-- the cause met longest ago goes first (equal: the one with fewer deaths)
function Fates.CapFoes(foes)
  local list = {}
  for k, x in pairs(foes) do list[#list + 1] = { k = k, t = tonumber(x.t) or 0, n = x.n or 0 } end
  if #list <= Fates.MAX_FOES then return end
  table.sort(list, function(a, b)
    if a.t ~= b.t then return a.t < b.t end
    if a.n ~= b.n then return a.n < b.n end
    return a.k < b.k
  end)
  for i = 1, #list - Fates.MAX_FOES do foes[list[i].k] = nil end
end

------------------------------------------------------------------------
-- The cause
------------------------------------------------------------------------
-- NPC id of a creature's GUID: C_CreatureInfo.GetCreatureID when the client has it (RareScanner uses it on Forever),
-- else the sixth field of "Creature-0-server-instance-zone-npcID-spawn" (also "Vehicle-")
function Fates.NpcOf(guid)
  if type(guid) ~= "string" or IsSecret(guid) then return nil end
  local CI = rawget(_G, "C_CreatureInfo")
  if type(CI) == "table" and type(CI.GetCreatureID) == "function" then
    local id = Num(Call(CI.GetCreatureID, guid))
    if id and id > 0 then return math.floor(id) end
  end
  local kind, id = guid:match("^(%a+)%-%d+%-%d+%-%d+%-%d+%-(%d+)%-")
  if (kind == "Creature" or kind == "Vehicle") and id then
    id = tonumber(id)
    if id and id > 0 then return id end
  end
  return nil
end

-- environmental type of the recap ("Falling", ...) -> own id ("fall"), unknown text -> "other"
function Fates.EnvOf(v)
  local s = Str(v)
  if not s then return nil end
  return Fates.ENV[s:lower()] or "other"
end

-- the key of a cause: creature by NPC id (else by name), the world by its kind, a nameless creature as "unknown"
function Fates.FoeKey(r)
  if type(r) ~= "table" then return "unknown" end
  if r.art == "env" then return "env:" .. (r.env or "other") end
  if r.art == "creature" then
    if r.npc then return "npc:" .. r.npc end
    if r.name then return "name:" .. r.name end
    return "unknown"
  end
  if r.art == "pet" then return "pet" end
  return "unknown"
end

-- the name a row or cause shows: the creature's name, the world's word, or a plain fallback
function Fates.Name(r)
  if type(r) ~= "table" then return L.FATE_UNKNOWN end
  if r.art == "env" then return L[ENV_WORD[r.env or "other"] or "FATE_ENV_OTHER"] end
  local n = Str(r.name)
  if n then return n end
  if r.art == "creature" then return L.FATE_CREATURE end
  if r.art == "pet" then return L.FATE_PET end
  return L.FATE_UNKNOWN
end

-- the kind of cause as a word (file: label above the name)
function Fates.ArtWord(art)
  if art == "creature" then return L.FATE_ART_CREATURE end
  if art == "pet" then return L.FATE_ART_PET end
  if art == "env" then return L.FATE_ART_ENV end
  return L.FATE_UNKNOWN
end

------------------------------------------------------------------------
-- Recording
------------------------------------------------------------------------
function Fates.On()
  local S = store()
  return not (S and S.Setting and S.Setting("fates.on") == false)
end

-- new awards go out one frame after the death (AWARD: notice in Extras.lua, remark in Humor.lua): the death's own
-- handlers (Humor.OnDeath counts the death) run first and see the book as it was
local function announce(list)
  if #list == 0 then return end
  local function go() for _, id in ipairs(list) do ns:Fire("AWARD", id) end end
  local CT = rawget(_G, "C_Timer")
  if type(CT) == "table" and type(CT.After) == "function" then CT.After(0, go) else go() end
end

local function award(f, id, list)
  if f.awards[id] then return end
  f.awards[id] = now()
  list[#list + 1] = id
end

local function distinctCreatures(f)
  local n = 0
  for k in pairs(f.foes) do if k:sub(1, 4) == "npc:" or k:sub(1, 5) == "name:" then n = n + 1 end end
  return n
end

local function checkAwards(f, row, foe, t)
  local new = {}
  if row.art == "env" then
    if row.env == "fall" then award(f, "fall", new)
    elseif row.env == "drown" then award(f, "drown", new)
    elseif row.env == "fire" or row.env == "lava" then award(f, "fire", new)
    elseif row.env == "fatigue" then award(f, "fatigue", new) end
  end
  if row.art == "creature" and foe and (row.npc or row.name) then
    if foe.n >= Fates.NEMESIS then award(f, "beast3", new) end
    if foe.n >= 10 then award(f, "beast10", new) end
    if not f.awards.zoo and distinctCreatures(f) >= Fates.ZOO then award(f, "zoo", new) end
  end
  local rec = f.recent
  if #rec >= Fates.STREAK and t - rec[#rec - Fates.STREAK + 1] <= Fates.STREAK_WINDOW and t >= rec[#rec - Fates.STREAK + 1] then
    award(f, "streak", new)
  end
  return new
end

-- the streak counts the deaths of this file (by creatures and the world): the feud between players stays apart
local function remember(f, t)
  local rec = f.recent
  rec[#rec + 1] = t
  while #rec > Fates.STREAK do table.remove(rec, 1) end
end

-- One own death (journal entry of Attribution.lua). Returns the row, or nil (a player's death, switch off, broken).
function Fates.Record(j)
  if type(j) ~= "table" or not Fates.On() then return nil end
  local f = Fates.DB()
  if not f then return nil end
  local t = finite(j.t) and j.t or now()
  if j.kind ~= "pve" then return nil end
  local c = type(j.cause) == "table" and j.cause or {}
  local row = { kind = "pve", me = plainStr(j.me, 80), myLevel = finite(j.myLevel) and j.myLevel or nil,
    counted = j.counted ~= false }
  cleanPlace(j, row)
  row.t = t
  row.art = VALID_ART[c.art] and c.art or "unknown"
  if row.art == "env" then row.env = ENV_WORD[c.env] and c.env or "other" end
  row.name = plainStr(c.name, Fates.NAME_MAX)
  row.npc = finite(c.npc) and c.npc or nil
  if row.art == "creature" and not row.npc and c.guid then row.npc = Fates.NpcOf(c.guid) end
  local sp = c.spell or j.spell
  row.spell = plainStr(sp, 80) or (finite(sp) and sp) or nil
  -- probe: per kind, a name that was secret or empty, a creature without NPC id
  Fates.Count("art_" .. row.art)
  if row.env then Fates.Count("env_" .. row.env) end
  if row.art == "creature" or row.art == "pet" then
    if c.nameSecret then Fates.Count("nameSecret") elseif not row.name then Fates.Count("nameEmpty") end
  end
  if row.art == "creature" and not row.npc then Fates.Count("npcMissing") end
  if not finite(j.mapID) then Fates.Count("noMap") end
  table.insert(f.rows, 1, row)
  while #f.rows > Fates.MAX_ROWS do f.rows[#f.rows] = nil end
  -- the cause
  local key = Fates.FoeKey(row)
  local foe, new = f.foes[key], false
  if not foe then
    foe, new = { n = 0 }, true
    f.foes[key] = foe
  end
  foe.n = foe.n + 1
  foe.art, foe.env, foe.npc = row.art, row.env, row.npc or foe.npc
  foe.name = row.name or foe.name
  foe.spell = row.spell or foe.spell
  cleanPlace(row, foe)
  if new then
    local cnt = 0
    for _ in pairs(f.foes) do cnt = cnt + 1 end
    if cnt > Fates.MAX_FOES then Fates.CapFoes(f.foes) end
  end
  remember(f, t)
  Fates.version = Fates.version + 1
  j.fate, j.fateN = row, foe.n      -- for the dry remarks (Humor.lua), never stored with the journal
  announce(checkAwards(f, row, foe, t))
  return row
end

------------------------------------------------------------------------
-- Reading
------------------------------------------------------------------------
function Fates.Rows()
  local f = Fates.DB()
  return f and f.rows or {}
end

-- causes ranked: most deaths first, then the latest; cached per version. Items are copies with key and rank.
local rankCache, rankVer
function Fates.Ranked()
  local f = Fates.DB()
  if not f then return {} end
  if rankCache and rankVer == Fates.version then return rankCache end
  local list = {}
  for k, x in pairs(f.foes) do
    local it = { foe = true, key = k, kind = "pve", counted = true }
    for kk, v in pairs(x) do it[kk] = v end
    list[#list + 1] = it
  end
  table.sort(list, function(a, b)
    if a.n ~= b.n then return a.n > b.n end
    local at, bt = a.t or 0, b.t or 0
    if at ~= bt then return at > bt end
    return a.key < b.key
  end)
  for i, it in ipairs(list) do it.rank = i end
  rankCache, rankVer = list, Fates.version
  return list
end

-- the cause on rank one when it killed you at least NEMESIS times (it carries the stamp), else nil
function Fates.Nemesis()
  local top = Fates.Ranked()[1]
  if top and top.n >= Fates.NEMESIS then return top end
  return nil
end

-- player deaths (newest first, the journal's view) and these rows merged by time; cached
local mergeCache, mergeKey = nil, {}
function Fates.Merged(players)
  players = type(players) == "table" and players or {}
  local rows = Fates.Rows()
  local k = mergeKey
  if mergeCache and k.p == players and k.n == #players and k.first == players[1] and k.v == Fates.version
    and k.rows == rows then
    return mergeCache
  end
  local out, i, j = {}, 1, 1
  while i <= #players or j <= #rows do
    local a, b = players[i], rows[j]
    local at = a and tonumber(a.t) or -math.huge
    local bt = b and tonumber(b.t) or -math.huge
    if a and (not b or at >= bt) then out[#out + 1] = a; i = i + 1 else out[#out + 1] = b; j = j + 1 end
  end
  mergeCache = out
  k.p, k.n, k.first, k.v, k.rows = players, #players, players[1], Fates.version, rows
  return out
end

-- the week (Share.lua): number of other deaths since `since`, the deadliest creature (name, deaths) among them
function Fates.Week(since)
  local rows = Fates.Rows()
  local n, by, best, bestN, bestT = 0, {}, nil, 0, 0
  for i = 1, #rows do
    local r = rows[i]
    if (tonumber(r.t) or 0) >= since then
      n = n + 1
    end
    if (tonumber(r.t) or 0) >= since and r.art == "creature" and r.name then
      local k = Fates.FoeKey(r)
      local c = by[k] or { n = 0, name = r.name, t = r.t }
      by[k] = c
      c.n = c.n + 1
      if c.n > bestN or (c.n == bestN and r.t > bestT) then best, bestN, bestT = c, c.n, c.t end
    end
  end
  return n, best and best.name or nil, bestN
end

function Fates.Awards()
  local f = Fates.DB()
  return f and f.awards or {}
end

-- name and condition of an award (every language; Extras.lua shows the notice, the rap sheet the coin)
function Fates.AwardText(id)
  if not AWARD_IDS[id] then return nil end
  local up = id:upper()
  return L["FATE_AW_" .. up], L["FATE_AW_" .. up .. "_COND"]
end

------------------------------------------------------------------------
-- Events
------------------------------------------------------------------------
ns:On("DEATH_RECORDED", function(j) Fates.Record(j) end)
