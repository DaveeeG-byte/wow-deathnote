-- DeathNote - Store.lua
-- SavedVariables, data model, ranking, export/import.

local ADDON, ns = ...
-- Texte (1.2.0): nur die Meldungen des Einlesens; gespeichert wird nie Uebersetztes
local L, Fmt = ns.L, ns.F
local Util = ns.Util
local Store = {}
ns.Store = Store

local DB_VERSION = 3      -- 2: combat log stage off by default (closed on Forever)
                          -- 3: every deed has a role (kill/assist/suspect), entries count assists
local MAX_ENEMY_DEATHS = 30
local MAX_JOURNAL = 100
local HAND_TIMES = 10     -- 1.2.1: times of hand revenges kept per entry (revengeHandAt)
local VALID_STATUS = { wanted = true, suspect = true, pardoned = true }
local VALID_ROLE = { kill = true, assist = true, suspect = true }

local DEFAULT_SETTINGS = {
  -- sound is the master switch; soundKey/volume (1..5)/channel are read by Alert.lua (1.1.0)
  alert = { enabled = true, sound = true, cooldown = 90, flash = true, minKills = 1, suspects = false,
    soundKey = "warnung", volume = 3, channel = "Master" },
  -- guildView: "enemy" | "member" (1.1.0) | "hunt" (1.2.0); guildCollapsed: member char name -> true (1.1.0)
  -- guildSource (1.2.0): "all" | "guild" | "friends", the source chosen in the fourth tab
  -- guildMore (1.2.0): true = House Rules, sheet Guild shows its second page "More"; absent = closed
  -- minimap: hide and angle (own button, read by 1.2.1 too); minimapPos (1.2.2, LibDBIcon) has no default here,
  -- repairSettings derives it from angle
  ui = { scale = 1, sort = "rank", minimap = { hide = false, angle = 215 }, guildView = "enemy", guildCollapsed = {},
    guildSource = "all" },
  deathMessage = true,
  tooltip = true,
  debug = false,
  welcomed = false,       -- the greeting in the chat was shown (1.1.0)
  -- 1.2.0: lang (a code, Locale.lua) has no default: absent = automatic = the client's language (English when
  -- DeathNote lacks it); langAsked (earlier 1.2.0 builds) may stand in old files, nothing reads it
  -- additive: stages of the killer search, each can be switched off.
  -- combatlog is off: the client closes it to addons; registering it at every login only costs.
  attribution = { recap = true, meter = true, combatlog = false, suspect = true },
  -- additive: guild death list (Sync.lua)
  -- shareManual: own entries added by hand go to the guild (M/X); alertListed: alarm for
  -- guild entries that are only listed by hand (no kills)
  guild = { share = true, receive = true, alert = true, announce = true, sightings = false, minKills = 1,
    shareManual = true, alertListed = false,
    -- 1.2.0: friends: share with friends of the friend list (WHISPER); alertHunt: alarm for targets of the hunt list
    friends = true, alertHunt = true,
    -- 1.2.0 fix: announceHunt = notice "taken down" / "new targets"; huntExpire = days until releases
    -- expire, 0 = never (default)
    announceHunt = true, huntExpire = 0 },
}

local db           -- DeathNoteDB
local enemies      -- db.enemies
local guidIndex = {}
local rankCache    -- array of wanted keys in rank order, or nil when dirty
-- first-name index: lower(first name) -> { [key] = true }. Serves Find (quick "not listed")
-- and placeholder entries (no known surname, key "Name-<realm>"), which a sighting with the
-- full name moves to the full key.
local byFirst = {}
local placeholders = 0   -- entries without surname (only a hint; Promote re-checks)

local function now() return time() end

-- Missing defaults are filled, values of a broken type (e.g. a string where a number
-- belongs) are reset to the default. Keys without a default stay untouched.
local function fillDefaults(dst, src)
  for k, v in pairs(src) do
    if type(v) == "table" then
      if type(dst[k]) ~= "table" then dst[k] = {} end
      fillDefaults(dst[k], v)
    elseif type(dst[k]) ~= type(v) or dst[k] ~= dst[k] then
      dst[k] = v
    end
  end
end

local SOUND_CHANNELS = { Master = true, SFX = true, Music = true, Ambience = true, Dialog = true }
local GUILD_VIEWS = { enemy = true, member = true, hunt = true }
local GUILD_SOURCES = { all = true, guild = true, friends = true }

-- Value repairs beyond the type (1.1.0 fields). Store.Setting itself stays a plain accessor.
local function repairSettings(st)
  local a, ui = st.alert, st.ui
  local v = a.volume
  if v < 1 or v > 5 or v ~= math.floor(v) then
    a.volume = math.max(1, math.min(5, math.floor(v + 0.5)))
  end
  if not SOUND_CHANNELS[a.channel] then a.channel = DEFAULT_SETTINGS.alert.channel end
  if a.soundKey == "" or #a.soundKey > 64 then a.soundKey = DEFAULT_SETTINGS.alert.soundKey end
  if not GUILD_VIEWS[ui.guildView] then ui.guildView = DEFAULT_SETTINGS.ui.guildView end
  if not GUILD_SOURCES[ui.guildSource] then ui.guildSource = DEFAULT_SETTINGS.ui.guildSource end
  for k, x in pairs(ui.guildCollapsed) do
    if type(k) ~= "string" or x ~= true then ui.guildCollapsed[k] = nil end
  end
  -- 1.2.2: LibDBIcon reads and writes ui.minimap.minimapPos (degrees, a float while dragging); angle (whole
  -- degrees) stays for the own button and for 1.2.1 after a downgrade. Same angle, so the button does not jump.
  -- A minimapPos that no longer matches angle was left behind by 1.2.1 moving the button: angle wins.
  local mm = ui.minimap
  if mm.angle == math.huge or mm.angle == -math.huge then mm.angle = DEFAULT_SETTINGS.ui.minimap.angle end
  local pos = mm.minimapPos
  if type(pos) ~= "number" or pos ~= pos or pos == math.huge or pos == -math.huge
     or math.floor(pos + 0.5) % 360 ~= math.floor(mm.angle + 0.5) % 360 then
    mm.minimapPos = mm.angle
  end
  -- LibDBIcon:AddButtonToCompartment (called by another addon) leaves showInCompartment in OUR table, and the
  -- library would then add a second compartment entry on every login. The TOC already provides ours.
  mm.showInCompartment = nil
  -- releases expire after one of these (0 = never)
  local g = st.guild
  if type(g) == "table" then
    local d = g.huntExpire
    if d ~= 0 and d ~= 30 and d ~= 90 and d ~= 180 then g.huntExpire = 0 end
  end
end

local function changed(key)
  rankCache = nil
  ns:Fire("ENEMY_UPDATED", key)
end

local function num(v, d) return (type(v) == "number" and v == v and v < math.huge and v > -math.huge) and v or d end

-- Role of a deed (1.1.0): "kill" = sure killing blow, "assist" = damage source in the death
-- recap but not the killing blow, "suspect" = heuristic only (had me targeted) or unproven.
local function roleOf(sure, source)
  if sure == true then return "kill" end
  if source == "recap" then return "assist" end
  return "suspect"
end
Store.RoleOf = roleOf

-- Status after the counters changed: kills or assists make a suspect wanted; pardoned stays.
local function settleStatus(e)
  if e.status == "suspect" and ((e.kills or 0) > 0 or (e.assists or 0) > 0) then e.status = "wanted" end
end

-- Gives every deed of an entry a role (deeds of DB version <= 2 have none). Idempotent:
-- deeds that already carry a valid role stay untouched. `journal` (optional) is the list of
-- own deaths: a deed without source takes the source of the journal entry with the same time.
-- Returns the number of former suspicions that became assists.
local function migrateRoles(e, journal)
  local converted = 0
  for i = 1, #e.deaths do
    local d = e.deaths[i]
    if not VALID_ROLE[d.role] then
      local source = d.source
      if source == nil and type(journal) == "table" and type(d.t) == "number" then
        for j = 1, #journal do
          local x = journal[j]
          if type(x) == "table" and x.t == d.t then
            if type(x.source) == "string" and x.kind == "pvp" then source = x.source; d.source = source end
            break
          end
        end
      end
      d.role = roleOf(d.sure, source)
      if d.role == "assist" then converted = converted + 1 end
    end
    d.sure = d.role == "kill"
  end
  if converted > 0 then
    local open = 0
    for i = 1, #e.deaths do if e.deaths[i].role == "suspect" then open = open + 1 end end
    e.assists = (e.assists or 0) + converted
    -- suspicions without a stored deed (import, older caps) stay counted
    e.suspected = math.max(open, (e.suspected or 0) - converted)
  end
  settleStatus(e)
  return converted
end
Store.MigrateRoles = migrateRoles

-- Repairs one entry in place; returns false when it is beyond repair.
local function sanitizeEntry(key, e)
  if type(key) ~= "string" or type(e) ~= "table" then return false end
  local n, s = Util.SplitKey(key)
  e.key = key
  e.name = Util.CleanName(e.name) or Util.CleanName(n) or "?"
  if type(e.realm) ~= "string" then e.realm = s end
  -- older data: no control bytes or "|" in the parts that go into /targetexact
  if e.surname ~= nil then e.surname = Util.CleanName(e.surname) end
  if e.surname then e.display = e.name .. " " .. e.surname
  elseif e.display ~= nil then e.display = Util.CleanName(e.display) end
  e.kills = num(e.kills, 0)
  e.suspected = num(e.suspected, 0)
  e.assists = num(e.assists, 0)
  e.revenge = num(e.revenge, 0)
  -- 1.2.1: revenge noted by hand (part of revenge); a broken or too big mark is repaired, never grows the count
  if e.revengeHand ~= nil then
    local h = num(e.revengeHand, 0)
    h = math.min(math.floor(h), e.revenge)
    e.revengeHand = h >= 1 and h or nil
  end
  -- 1.2.1 fix: times of the hand revenges (newest last) and of the last recognised one, for "last revenge" after
  -- taking one back; broken ones go (then the time simply stays as it was)
  if e.revengeHandAt ~= nil then
    local l, ok = e.revengeHandAt, type(e.revengeHandAt) == "table" and e.revengeHand ~= nil
    if ok then
      for i = #l, 1, -1 do if type(l[i]) ~= "number" or l[i] ~= l[i] or l[i] == math.huge or l[i] == -math.huge then ok = false end end
      ok = ok and #l <= math.min(HAND_TIMES, e.revengeHand)
    end
    if not ok then e.revengeHandAt = nil end
  end
  if e.revengeAutoAt ~= nil and (type(e.revengeAutoAt) ~= "number" or e.revengeAutoAt ~= e.revengeAutoAt
    or e.revenge <= (e.revengeHand or 0)) then e.revengeAutoAt = nil end
  -- 1.2.1 fix: an older version recognised a revenge after these times (back to 1.2.0 and up again): its time is
  -- the last revenge, newer than every noted one; it becomes the time of the last recognised one
  local lr = e.lastRevenge
  if (e.revengeAutoAt ~= nil or e.revengeHandAt ~= nil) and e.revenge > (e.revengeHand or 0) and type(lr) == "number"
    and lr == lr and lr < math.huge and lr > (e.revengeAutoAt or -math.huge) then
    local l, newer = e.revengeHandAt or {}, true
    for i = 1, #l do if l[i] >= lr then newer = false end end
    if newer then e.revengeAutoAt = lr end
  end
  e.sightings = num(e.sightings, 0)
  if not VALID_STATUS[e.status] then
    e.status = (e.kills > 0 or e.assists > 0 or e.manual) and "wanted" or (e.suspected > 0 and "suspect" or "wanted")
  end
  e.manual = e.manual == true
  if type(e.note) ~= "string" then e.note = "" end
  if type(e.deaths) ~= "table" then e.deaths = {} end
  for i = #e.deaths, 1, -1 do
    if type(e.deaths[i]) ~= "table" then table.remove(e.deaths, i) end
  end
  while #e.deaths > MAX_ENEMY_DEATHS do table.remove(e.deaths) end
  -- a role that does not match: repaired from sure/source (never counted again)
  for i = 1, #e.deaths do
    local d = e.deaths[i]
    if d.role ~= nil and not VALID_ROLE[d.role] then d.role = nil end
    if d.role then d.sure = d.role == "kill" end
  end
  if e.lastSeen ~= nil and type(e.lastSeen) ~= "table" then e.lastSeen = nil end
  -- additive (1.1.0): who added it by hand, when, and where it came from
  if e.by ~= nil and (type(e.by) ~= "string" or e.by == "") then e.by = nil end
  if e.listedAt ~= nil and type(e.listedAt) ~= "number" then e.listedAt = nil end
  if e.fromGuild ~= nil and e.fromGuild ~= true then e.fromGuild = nil end
  if e.imported ~= nil and e.imported ~= true then e.imported = nil end
  -- 1.2.0: the note of an entry taken over from the guild book is a mark, not a sentence; the
  -- German sentence of 1.1.0 and the English one of the 1.2.0 test builds are recognised and replaced
  if e.fromGuildKills ~= nil and not (type(e.fromGuildKills) == "number" and e.fromGuildKills >= 0
    and e.fromGuildKills < 1e6 and e.fromGuildKills == math.floor(e.fromGuildKills)) then e.fromGuildKills = nil end
  if e.fromGuild and e.note ~= "" then
    local k = e.note:match("^Aus dem Gildenbuch übernommen %((%d+)× getötet in der Gilde%)%.$")
      or e.note:match("^Taken over from the guild book %(killed guildmates (%d+)×%)%.$")
    if k and #k <= 6 then e.note, e.fromGuildKills = "", tonumber(k) end
  end
  return true
end

local function indexAdd(key, e)
  if type(e.name) ~= "string" then return end
  local ln = e.name:lower()
  local set = byFirst[ln]
  if not set then set = {}; byFirst[ln] = set end
  set[key] = true
  if e.surname == nil then placeholders = placeholders + 1 end
end

local function indexRemove(key, e)
  if type(e.name) ~= "string" then return end
  local ln = e.name:lower()
  local set = byFirst[ln]
  if set and set[key] then
    set[key] = nil
    if next(set) == nil then byFirst[ln] = nil end
    if e.surname == nil and placeholders > 0 then placeholders = placeholders - 1 end
  end
end

-- The only way a surname is set on a stored entry (keeps the placeholder count right).
local function setSurname(e, s)
  s = Util.CleanName(s)
  if not s then return end
  if e.surname == nil and enemies and enemies[e.key] == e and placeholders > 0 then
    placeholders = placeholders - 1
  end
  e.surname = s
  e.display = e.name .. " " .. s
end

local function rebuildIndex()
  guidIndex, byFirst, placeholders = {}, {}, 0
  for key, e in pairs(enemies) do
    if type(e.guid) == "string" then guidIndex[e.guid] = key end
    indexAdd(key, e)
  end
end

-- Loads/migrates the SavedVariables. Safe to call again (tests).
function Store.Init()
  if type(_G.DeathNoteDB) ~= "table" then _G.DeathNoteDB = {} end
  db = _G.DeathNoteDB
  if type(db.version) ~= "number" then
    -- no version: a fresh DB is current, anything with content counts as version 1
    db.version = (next(db) == nil) and DB_VERSION or 1
  end
  if type(db.settings) ~= "table" then db.settings = {} end
  if db.version < 2 then
    -- the closed combat log was on by default in version 1
    local a = db.settings.attribution
    if type(a) == "table" and a.combatlog == true then a.combatlog = false end
    db.version = 2
  end
  fillDefaults(db.settings, DEFAULT_SETTINGS)
  repairSettings(db.settings)
  if type(db.enemies) ~= "table" then db.enemies = {} end
  enemies = db.enemies
  for key, e in pairs(enemies) do
    if not sanitizeEntry(key, e) then enemies[key] = nil end
  end
  if type(db.deaths) ~= "table" then db.deaths = {} end
  for i = #db.deaths, 1, -1 do
    if type(db.deaths[i]) ~= "table" then table.remove(db.deaths, i) end
  end
  while #db.deaths > MAX_JOURNAL do table.remove(db.deaths) end
  if db.tally ~= nil and type(db.tally) ~= "table" then db.tally = nil end
  if db.probe ~= nil and type(db.probe) ~= "table" then db.probe = nil end
  if db.guild ~= nil and type(db.guild) ~= "table" then db.guild = nil end   -- filled by Sync.lua
  if db.version < 3 then
    for _, e in pairs(enemies) do migrateRoles(e, db.deaths) end
    db.version = 3
  else
    -- deeds without a role (e.g. written by an older client meanwhile): role only, no recount
    for _, e in pairs(enemies) do
      for i = 1, #e.deaths do
        if e.deaths[i].role == nil then migrateRoles(e, db.deaths); break end
      end
    end
  end
  rankCache = nil
  Store.TouchJournal()
  rebuildIndex()
  return db
end

function Store.DB() return db end

-- 1.2.2: before the SavedVariables are written, angle follows the LibDBIcon position (1.2.1 reads only angle)
function Store.SyncMinimapAngle()
  local st = db and db.settings
  local mm = type(st) == "table" and type(st.ui) == "table" and st.ui.minimap
  if type(mm) ~= "table" then return end
  local pos = mm.minimapPos
  if type(pos) == "number" and pos == pos and pos > -math.huge and pos < math.huge then
    mm.angle = math.floor(pos + 0.5) % 360
  end
end
ns:RegisterEvent("PLAYER_LOGOUT", Store.SyncMinimapAngle)

---------------------------------------------------------------------------
-- Reading
---------------------------------------------------------------------------
function Store.Get(key)
  if not enemies or type(key) ~= "string" then return nil end
  return enemies[key]
end

function Store.All() return enemies or {} end

-- wanted, suspect, pardoned, open (open = Store.OpenCases(), 1.1.0)
function Store.Count()
  local w, s, p = 0, 0, 0
  for _, e in pairs(enemies or {}) do
    if e.status == "wanted" then w = w + 1
    elseif e.status == "suspect" then s = s + 1
    elseif e.status == "pardoned" then p = p + 1 end
  end
  return w, s, p, (Store.OpenCases())
end

-- Weight of an entry for the alarm threshold (alert.minKills): kills + assists.
function Store.Weight(e)
  if type(e) ~= "table" then return 0 end
  return (tonumber(e.kills) or 0) + (tonumber(e.assists) or 0)
end

-- Open cases (1.1.0): own PvP deaths without a killer that wait for a decision.
-- open = kind == "pvp", no killerKey, at least one candidate, counted ~= false.
-- Returns count, list (journal entries, newest first; the list must not be changed).
-- Cached; every journal change in this file calls Store.TouchJournal(), and the cache also
-- notices a changed length or a new first entry (journal written from outside).
local openCache, openN, openLen, openFirst
local logCache, logLen, logFirst
function Store.TouchJournal() openCache, logCache = nil, nil end

-- The death log shows deaths by players only (1.2.0): kind "pve" (monsters, surroundings) is left out,
-- "unknown" stays. Older books keep their pve rows in the file (1.1.0 shows them again); they are only not
-- listed. Cached like the open cases; the list must not be changed.
function Store.Journal()
  local journal = db and db.deaths
  if type(journal) ~= "table" then return {} end
  if logCache and logLen == #journal and logFirst == journal[1] then return logCache end
  local list = {}
  for i = 1, #journal do
    local j = journal[i]
    if type(j) == "table" and j.kind ~= "pve" then list[#list + 1] = j end
  end
  logCache, logLen, logFirst = list, #journal, journal[1]
  return list
end

-- Every own death counts in db.tally = { n, last } (1.2.0, additive, language-neutral): also deaths without a
-- journal row. Read by the dry remarks (milestones, /dn beichte). Repaired from the journal when broken.
local function finiteNum(v) return type(v) == "number" and v == v and v > -math.huge and v < math.huge end
function Store.Tally()
  if not db then return nil end
  local tl = db.tally
  if type(tl) ~= "table" then tl = {}; db.tally = tl end
  local n = #(type(db.deaths) == "table" and db.deaths or {})
  if not finiteNum(tl.n) or tl.n < n then tl.n = n end
  tl.n = math.floor(tl.n)
  local newest = type(db.deaths) == "table" and type(db.deaths[1]) == "table" and db.deaths[1].t or nil
  if not finiteNum(tl.last) then tl.last = nil end
  if finiteNum(newest) and (not tl.last or newest > tl.last) then tl.last = newest end
  return tl
end

local function isOpen(j)
  return type(j) == "table" and j.kind == "pvp" and j.killerKey == nil and j.counted ~= false
    and type(j.candidates) == "table" and #j.candidates > 0
end
Store.IsOpenCase = isOpen

function Store.OpenCases()
  local journal = db and db.deaths
  if type(journal) ~= "table" then return 0, {} end
  if openCache and openLen == #journal and openFirst == journal[1] then return openN, openCache end
  local list = {}
  for i = 1, #journal do
    if isOpen(journal[i]) then list[#list + 1] = journal[i] end
  end
  openCache, openN, openLen, openFirst = list, #list, #journal, journal[1]
  return openN, openCache
end

function Store.ByGUID(guid)
  if Util.IsSecret(guid) or type(guid) ~= "string" then return nil end
  local key = guidIndex[guid]
  if key and enemies[key] then return key end
  return nil
end

-- Key for user input or a bare name: exact key, then case-insensitive, then a unique first-name match.
function Store.Find(text, second)
  if not enemies then return nil end
  local key = Util.KeyFor(text, second)
  if key and enemies[key] then return key end
  local n, s = Util.SplitFull(text)
  if not n then return nil end
  if not Util.IsSecret(second) and type(second) == "string" and second ~= "" then s = second end
  local ln, ls = n:lower(), s and s:lower()
  local set = byFirst[ln]
  if not set then return nil end          -- nobody with this first name (cheap "no")
  local found, count = nil, 0
  for k in pairs(set) do
    local e = enemies[k]
    if e and e.name and e.name:lower() == ln then
      if ls then
        local es = (e.surname or e.realm or ""):lower()
        if es == ls then return k end
      else
        found, count = k, count + 1
      end
    end
  end
  if count == 1 then return found end
  return nil
end

-- Rank (1.1.0): kills, then assists, then the latest kill, then the name (key).
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
    local na, nb = Util.Display(a):lower(), Util.Display(b):lower()
    if na ~= nb then return na < nb end
    return (a.key or "") < (b.key or "")
  end,
  seen = function(a, b)
    local ta, tb = a.lastSeen and a.lastSeen.t or 0, b.lastSeen and b.lastSeen.t or 0
    if ta ~= tb then return ta > tb end
    return rankLess(a, b)
  end,
}

function Store.Ranked(filter, sort)
  filter = filter or "wanted"
  local out = {}
  for _, e in pairs(enemies or {}) do
    if filter == "all" or e.status == filter then out[#out + 1] = e end
  end
  table.sort(out, SORTS[sort] or rankLess)
  return out
end

function Store.Rank(key)
  local e = Store.Get(key)
  if not e or e.status ~= "wanted" then return nil end
  if not rankCache then
    rankCache = {}
    local list = Store.Ranked("wanted", "rank")
    for i = 1, #list do rankCache[list[i].key] = i end
  end
  return rankCache[key]
end

-- Fun value in copper, deterministic.
function Store.Bounty(e)
  if type(e) ~= "table" then return 0 end
  local kills, susp, rev = e.kills or 0, e.suspected or 0, e.revenge or 0
  local assists = tonumber(e.assists) or 0
  local level = tonumber(e.level) or 0
  -- an assist is worth 40 % of a kill
  local base = kills * 250000 + assists * 100000 + susp * 50000 + level * 1000
  local mult = 1 + 0.25 * math.max(0, kills - 1)
  local paid = 1 / (1 + 0.5 * rev)          -- revenge cashes part of the bounty
  local v = math.floor(base * mult * paid / 100 + 0.5) * 100
  if (kills > 0 or assists > 0) and v < 10000 then v = 10000 end
  return v
end

function Store.Deaths() return db and db.deaths or {} end

---------------------------------------------------------------------------
-- Settings
---------------------------------------------------------------------------
local pathParts = {}   -- path -> array of parts (paths are a small fixed set of literals)
function Store.Setting(path, ...)
  if not db or type(path) ~= "string" then return nil end
  local t = db.settings
  local parts = pathParts[path]
  if not parts then
    parts = {}
    for p in path:gmatch("[^%.]+") do parts[#parts + 1] = p end
    if #parts == 0 then return nil end
    pathParts[path] = parts
  end
  for i = 1, #parts - 1 do
    if type(t[parts[i]]) ~= "table" then
      if select("#", ...) == 0 then return nil end
      t[parts[i]] = {}
    end
    t = t[parts[i]]
  end
  local last = parts[#parts]
  if select("#", ...) == 0 then return t[last] end
  t[last] = (...)
  ns:Fire("SETTINGS_CHANGED", path)
  return t[last]
end

---------------------------------------------------------------------------
-- Writing
---------------------------------------------------------------------------
local INFO_FIELDS = { "guid", "class", "classLoc", "race", "raceLoc", "sex", "level", "faction", "guild" }

local function newEntry(key, name, realm)
  local e = {
    key = key, name = name, realm = realm,
    kills = 0, assists = 0, suspected = 0, revenge = 0, status = "wanted", manual = false, note = "",
    sightings = 0, deaths = {},
  }
  enemies[key] = e
  indexAdd(key, e)
  return e
end

local function retarget(list, oldKey, newKey)
  if type(list) ~= "table" then return end
  for i = 1, #list do if list[i] == oldKey then list[i] = newKey end end
end

-- Moves an entry to a new key (same GUID seen under a fuller name). Returns the entry.
-- Journal and co-attacker references follow; ENEMY_UPDATED fires for both keys.
local function rekey(oldKey, newKey)
  local e = enemies[oldKey]
  if not e or enemies[newKey] then return e end
  indexRemove(oldKey, e)
  enemies[oldKey] = nil
  enemies[newKey] = e
  e.key = newKey
  e.name, e.realm = Util.SplitKey(newKey)
  indexAdd(newKey, e)
  if e.guid then guidIndex[e.guid] = newKey end
  -- additive: lets the UI move selection, note field, popup and cooldowns along
  ns:Fire("ENEMY_REKEYED", oldKey, newKey)
  if db and type(db.deaths) == "table" then
    Store.TouchJournal()
    for i = 1, #db.deaths do
      local j = db.deaths[i]
      if j.killerKey == oldKey then j.killerKey = newKey end
      retarget(j.candidates, oldKey, newKey)
      local ci = j.candidateInfo
      if type(ci) == "table" and ci[oldKey] then
        if ci[newKey] == nil then ci[newKey] = ci[oldKey] end
        ci[oldKey] = nil
      end
    end
  end
  for _, x in pairs(enemies) do
    for i = 1, #x.deaths do retarget(x.deaths[i].others, oldKey, newKey) end
  end
  changed(oldKey)
  changed(newKey)
  return e
end

local function plainField(v)
  if Util.IsSecret(v) then return nil end
  local t = type(v)
  if (t == "string" and v ~= "") or (t == "number" and v == v) then return v end
  return nil
end

-- Copies plain identity info onto an entry (never secrets). info.surname marks a real surname.
local function applyInfo(e, info)
  if type(info) ~= "table" then return end
  local hasSurname = false
  local sn = info.surname
  if not Util.IsSecret(sn) and type(sn) == "string" and sn ~= "" then hasSurname = true end
  for i = 1, #INFO_FIELDS do
    local f = INFO_FIELDS[i]
    local v = plainField(info[f])
    if v ~= nil then
      -- a placeholder (first name only) keeps its GUID: another GUID is another player
      -- with the same first name, not a new GUID of this one
      if f ~= "guid" or e.guid == nil or hasSurname or e.surname ~= nil then e[f] = v end
    end
  end
  if hasSurname then sn = Util.CleanName(sn); hasSurname = sn ~= nil end
  if hasSurname then
    local cs = Util.CapFirst(sn)
    if e.surname ~= cs then setSurname(e, cs) end
  end
  if e.surname then e.display = e.name .. " " .. e.surname end
  if type(e.guid) == "string" then guidIndex[e.guid] = e.key end
end

function Store.HasPlaceholders() return placeholders > 0 end

-- Moves a placeholder entry ("Name" without surname) onto the full key "Name-Surname"
-- once the player is seen with the full name. With a known GUID on the entry only when it
-- matches; an entry without GUID only when it is the only placeholder of that first name.
-- Returns the new key or nil. Fires ENEMY_UPDATED (old and new key).
function Store.Promote(name, surname, guid)
  if placeholders <= 0 or not enemies then return nil end
  if Util.IsSecret(name) or Util.IsSecret(surname) or Util.IsSecret(guid) then return nil end
  if type(name) ~= "string" or type(surname) ~= "string" or surname == "" then return nil end
  if type(guid) ~= "string" then guid = nil end
  local set = byFirst[name:lower()]
  if not set then return nil end
  local full, _, s, had = Util.KeyFor(name, surname)
  if not full or not had or enemies[full] then return nil end
  local exact, loose, looseN = nil, nil, 0
  for k in pairs(set) do
    local e = enemies[k]
    if e and e.surname == nil then
      if e.guid then
        if guid and e.guid == guid then exact = k end
      else
        loose, looseN = k, looseN + 1
      end
    end
  end
  local pick = exact or (looseN == 1 and loose) or nil
  if not pick then return nil end
  local e = enemies[pick]
  setSurname(e, s)             -- first: the entry stops counting as placeholder
  if guid and not e.guid then e.guid = guid end
  rekey(pick, full)            -- moves index, GUID index and journal references
  for i = 1, #(db and db.deaths or {}) do
    local j = db.deaths[i]
    if j.killerKey == full then j.killerName = e.display end
  end
  return full
end

-- Finds or creates an entry for identity info { name, surname|realm, guid, ... }.
-- Returns key, entry, isNew. Never fires; callers fire.
function Store.Upsert(info, create)
  if not enemies or type(info) ~= "table" then return nil end
  local sn = Util.Str(info.surname)
  local key, n, s = Util.KeyFor(info.name, sn or Util.Str(info.realm))
  local byGuid = Store.ByGUID(info.guid)
  if not byGuid and key and not enemies[key] and placeholders > 0 and sn then
    -- a placeholder of this player (by hand or GUID only) takes the full name now
    key = Store.Promote(info.name, sn, info.guid) or key
  end
  if byGuid and key and byGuid ~= key and not enemies[key] then
    -- same player, better name now (e.g. surname learned): move
    local e = enemies[byGuid]
    if sn or not e.surname then
      rekey(byGuid, key)
    else
      key = byGuid
    end
  elseif byGuid then
    key = byGuid
  end
  if not key then return nil end
  local e = enemies[key]
  local isNew = false
  if not e then
    if not create then return nil end
    e = newEntry(key, n, s)
    isNew = true
  end
  applyInfo(e, info)
  return key, e, isNew
end

-- opts (additive): { fromGuild = true } marks an entry taken over from the guild list
-- (it is never sent back to the guild). A new entry remembers the character that added it
-- (`by`, "Name Surname") and when (`listedAt`). Fires ENEMY_UPDATED, then MANUAL_ADDED.
function Store.AddManual(name, realm, opts)
  if not enemies then return nil end
  local key, n, s, had = Util.KeyFor(name, realm)
  if not key then return nil end
  local existing = Store.Find(name, realm)
  if existing then
    -- entering a mere suspect by hand puts him on the wanted list (he was only noted before)
    local x = enemies[existing]
    if x and x.status == "suspect" and not x.manual and not (type(opts) == "table" and opts.fromGuild) then
      x.manual = true
      x.by = x.by or Util.PlayerFullName()
      x.listedAt = x.listedAt or now()
      Store.SetStatus(existing, "wanted")
      ns:Fire("MANUAL_ADDED", existing)
    end
    return existing
  end
  local e = newEntry(key, n, s)
  e.manual = true
  e.by = Util.PlayerFullName()
  e.listedAt = now()
  if type(opts) == "table" and opts.fromGuild then e.fromGuild = true end
  if had then setSurname(e, s) end
  changed(key)
  ns:Fire("MANUAL_ADDED", key)
  return key
end

-- Fires ENEMY_UPDATED, then ENEMY_REMOVED(key, entry) with the removed entry (read only).
function Store.Remove(key)
  local e = Store.Get(key)
  if not e then return false end
  if e.guid and guidIndex[e.guid] == key then guidIndex[e.guid] = nil end
  indexRemove(key, e)
  enemies[key] = nil
  changed(key)
  ns:Fire("ENEMY_REMOVED", key, e)
  return true
end

function Store.SetNote(key, text)
  local e = Store.Get(key)
  if not e then return false end
  e.note = type(text) == "string" and text:sub(1, 1000) or ""
  changed(key)
  return true
end

function Store.SetStatus(key, status)
  local e = Store.Get(key)
  if not e or not VALID_STATUS[status] then return false end
  local old = e.status
  e.status = status
  changed(key)
  if old ~= status then ns:Fire("ENEMY_STATUS", key, old, status) end
  return true
end

local function pushCapped(list, item, cap)
  table.insert(list, 1, item)
  while #list > cap do table.remove(list) end
end

local function copyDeath(d)
  local c = {}
  for k, v in pairs(d) do
    if type(v) ~= "table" then c[k] = v end
  end
  return c
end

-- Internal (Attribution): credits a death to an enemy. The role of the deed is death.role
-- when given, else from sure/source: sure -> "kill"; not sure and source "recap" -> "assist"
-- (damage in the recap, not the killing blow); else "suspect" (heuristic).
-- `death` is the per-enemy record { t, zone, ..., source, sure, role, others }.
function Store.ApplyKill(info, death, sure)
  local key, e, isNew = Store.Upsert(info, true)
  if not key then return nil end
  local rec = copyDeath(death)
  local role = VALID_ROLE[death.role] and death.role or roleOf(sure and true or false, death.source)
  rec.role = role
  rec.sure = role == "kill"
  if type(death.others) == "table" then
    local o = {}
    for i = 1, #death.others do if death.others[i] ~= key then o[#o + 1] = death.others[i] end end
    rec.others = o
  end
  pushCapped(e.deaths, rec, MAX_ENEMY_DEATHS)
  if role == "kill" then
    e.kills = e.kills + 1
    e.firstKill = e.firstKill or rec.t
    e.lastKill = rec.t
    if e.status ~= "pardoned" then e.status = "wanted" end
  elseif role == "assist" then
    e.assists = (e.assists or 0) + 1
    if e.status ~= "pardoned" then e.status = "wanted" end
  else
    e.suspected = e.suspected + 1
    if isNew then e.status = "suspect" end
  end
  if type(death.theirLevel) == "number" then e.level = death.theirLevel end
  changed(key)
  return key
end

-- Internal (Attribution): adds a journal entry, returns it.
-- Deaths by monsters and surroundings (kind "pve") only count in db.tally, they get no journal row (1.2.0).
function Store.RecordDeath(entry)
  if not db then return nil end
  local tl = Store.Tally()
  tl.n = tl.n + 1
  if type(entry) == "table" and finiteNum(entry.t) and (not tl.last or entry.t > tl.last) then tl.last = entry.t end
  if type(entry) == "table" and entry.kind == "pve" then return entry end
  pushCapped(db.deaths, entry, MAX_JOURNAL)
  Store.TouchJournal()
  return entry
end

-- Internal (Tracker): a listed enemy was seen. Returns true when written.
function Store.Seen(key, info, where, newEncounter)
  local e = Store.Get(key)
  if not e then return false end
  applyInfo(e, info)
  e.lastSeen = where
  if newEncounter then e.sightings = (e.sightings or 0) + 1 end
  -- the rank does not depend on sightings or identity fields: keep the rank cache
  ns:Fire("ENEMY_UPDATED", key)
  return true
end

local function journalMatch(e, deathRec)
  -- journal entry with the same time stamp
  if not db or not deathRec then return nil end
  for i = 1, #db.deaths do
    local j = db.deaths[i]
    if j.t == deathRec.t then return j end
  end
end

-- Turns a deed into a kill: a suspicion or an assist (1.1.0). Without index the newest
-- deed that is not a kill yet.
function Store.ConfirmSuspect(key, deathIndex)
  local e = Store.Get(key)
  if not e then return false end
  local d
  if type(deathIndex) == "number" then
    d = e.deaths[deathIndex]
  else
    for i = 1, #e.deaths do
      if e.deaths[i].role ~= "kill" then d = e.deaths[i]; break end
    end
  end
  -- only a deed that is no kill yet can be confirmed (repeated clicks must not inflate kills)
  if not d or d.role == "kill" then return false end
  -- the death already has another sure killer: one death, one kill. Hand over to AssignDeath,
  -- which takes the kill from the other one first.
  if db then
    for i = 1, #db.deaths do
      local j = db.deaths[i]
      if j.t == d.t then
        if j.killerKey and j.sure and j.killerKey ~= key then return Store.AssignDeath(i, key) end
        break
      end
    end
  end
  if d.role == "assist" then
    if (e.assists or 0) > 0 then e.assists = e.assists - 1 end
  elseif e.suspected > 0 then
    e.suspected = e.suspected - 1
  end
  d.role, d.sure = "kill", true
  e.kills = e.kills + 1
  local t = d and d.t or now()
  e.firstKill = (e.firstKill and e.firstKill < t) and e.firstKill or t
  if not e.lastKill or t > e.lastKill then e.lastKill = t end
  if e.status ~= "pardoned" then e.status = "wanted" end
  local j = journalMatch(e, d)
  if j and not (j.killerKey and j.sure) then
    j.killerKey, j.killerName, j.sure, j.kind = key, Util.Display(e), true, "pvp"
    Store.TouchJournal()
  end
  changed(key)
  return true
end

-- Drops the suspicions (role "suspect") of an entry; kills and assists stay. An entry that
-- is left with nothing (no kill, no assist, not by hand, no revenge) is removed.
function Store.DismissSuspect(key)
  local e = Store.Get(key)
  if not e then return false end
  if e.kills == 0 and (e.assists or 0) == 0 and not e.manual and e.revenge == 0 then
    return Store.Remove(key)
  end
  for i = #e.deaths, 1, -1 do
    if e.deaths[i].role == "suspect" then table.remove(e.deaths, i) end
  end
  e.suspected = 0
  if e.status == "suspect" then e.status = "wanted" end
  changed(key)
  return true
end

-- byHand (1.2.1): noted by the player ("Rache vermerken"), counted apart in e.revengeHand (additive) so that
-- only such a revenge can be taken back; revenge the addon recognised (own killing blow, honor) stays. Books of
-- 1.2.0 and older carry no mark: their revenge counts as recognised.
function Store.AddRevenge(key, byHand)
  local e = Store.Get(key)
  if not e then return false end
  local t = now()
  if byHand == true then
    -- the recognised revenge before the first hand one (books of 1.2.0 and older): its time is the last one so far
    if e.revengeAutoAt == nil and e.revenge > (tonumber(e.revengeHand) or 0) then e.revengeAutoAt = e.lastRevenge end
    e.revengeHand = (tonumber(e.revengeHand) or 0) + 1
    local l = type(e.revengeHandAt) == "table" and e.revengeHandAt or {}
    l[#l + 1] = t
    while #l > HAND_TIMES do table.remove(l, 1) end
    e.revengeHandAt = l
  else
    e.revengeAutoAt = t
  end
  e.revenge = e.revenge + 1
  e.lastRevenge = t
  changed(key)
  ns:Fire("REVENGE", key)
  return true
end

-- Takes back the newest revenge noted by hand (1.2.1). The last revenge time becomes the newest that is left (the
-- remaining hand ones, the last recognised one); when none of them is known: prevLast (the undo right after noting
-- knows it), else it stays. Fires ENEMY_UPDATED and REVENGE_UNDONE.
function Store.UndoRevenge(key, prevLast)
  local e = Store.Get(key)
  if not e or (tonumber(e.revengeHand) or 0) < 1 or (tonumber(e.revenge) or 0) < 1 then return false end
  local l = type(e.revengeHandAt) == "table" and e.revengeHandAt or nil
  if l then table.remove(l) end
  e.revenge = e.revenge - 1
  e.revengeHand = e.revengeHand - 1
  if e.revengeHand <= 0 then e.revengeHand, e.revengeHandAt, l = nil, nil, nil end
  if e.revenge <= (e.revengeHand or 0) then e.revengeAutoAt = nil end
  local last = l and l[#l] or nil
  local auto = tonumber(e.revengeAutoAt)
  if auto and (not last or auto > last) then last = auto end
  -- known: every kind that is left has a time (hand revenges beyond HAND_TIMES are older than the noted ones)
  local hand = e.revengeHand or 0
  local known = (hand == 0 or (l ~= nil and #l > 0)) and (e.revenge <= hand or auto ~= nil)
  if e.revenge == 0 then
    e.lastRevenge = nil
  elseif known and last then
    e.lastRevenge = last
  elseif type(prevLast) == "number" and prevLast == prevLast then
    e.lastRevenge = prevLast
  end
  changed(key)
  ns:Fire("REVENGE_UNDONE", key)
  return true
end

-- revenge noted by hand that can still be taken back
function Store.HandRevenge(e)
  if Util.IsSecret(e) or type(e) ~= "table" then return 0 end
  return math.min(tonumber(e.revengeHand) or 0, tonumber(e.revenge) or 0)
end

-- Additive: turns journal entry `index` into a sure kill by `key` (source "manual").
function Store.AssignDeath(index, key)
  if not db then return false end
  local j = db.deaths[index]
  if type(j) ~= "table" then return false end
  if j.killerKey == key and j.sure then return true end
  Store.TouchJournal()
  local info
  local e = Store.Get(key)
  if e then
    info = { name = e.name, realm = e.realm, guid = e.guid }
  else
    -- a candidate not in the book: the identity noted at death time (surname, class, ...)
    local ci = type(j.candidateInfo) == "table" and j.candidateInfo[key]
    if type(ci) == "table" and Util.KeyFor(ci.name, ci.surname) == key then
      info = { name = ci.name, surname = ci.surname, guid = ci.guid, class = ci.class, classLoc = ci.classLoc,
        race = ci.race, raceLoc = ci.raceLoc, level = ci.level, guild = ci.guild, faction = ci.faction }
    else
      local n, s = Util.SplitKey(key)
      if not n then return false end
      info = { name = n, realm = s }
    end
  end
  -- undo a previous sure kill credited for this death
  if j.killerKey and j.sure and j.killerKey ~= key then
    local old = Store.Get(j.killerKey)
    if old then
      for i = 1, #old.deaths do
        local od = old.deaths[i]
        if od.t == j.t and od.role == "kill" then
          old.kills = math.max(0, old.kills - 1)
          if od.source == "recap" then
            -- the recap proved his damage: he stays involved in this death
            od.role, od.sure = "assist", false
            old.assists = (old.assists or 0) + 1
          else
            table.remove(old.deaths, i)
          end
          break
        end
      end
      -- his newest remaining kill, and no "wanted" without any kill or assist
      local last
      for i = 1, #old.deaths do
        local od = old.deaths[i]
        if od.role == "kill" and type(od.t) == "number" and (not last or od.t > last) then last = od.t end
      end
      if old.kills == 0 then old.lastKill, old.firstKill = nil, nil elseif last then old.lastKill = last end
      if old.kills == 0 and (old.assists or 0) == 0 and not old.manual and old.status == "wanted" then
        if (old.suspected or 0) > 0 then
          old.status = "suspect"
        elseif #old.deaths == 0 and (old.revenge or 0) == 0 and (old.note or "") == "" then
          Store.Remove(j.killerKey)
        end
      end
      changed(j.killerKey)
    end
  end
  -- an existing suspicion or assist for this death becomes the kill
  if e then
    for i = 1, #e.deaths do
      local d = e.deaths[i]
      if d.t == j.t and d.role ~= "kill" then
        table.remove(e.deaths, i)
        if d.role == "assist" then
          e.assists = math.max(0, (e.assists or 0) - 1)
        else
          e.suspected = math.max(0, e.suspected - 1)
        end
        break
      end
    end
  end
  local rec = {
    t = j.t, zone = j.zone, subzone = j.subzone, mapID = j.mapID, x = j.x, y = j.y,
    me = j.me, myLevel = j.myLevel, source = "manual", sure = true, role = "kill", others = {},
  }
  local k = Store.ApplyKill(info, rec, true)
  if not k then return false end
  j.killerKey, j.sure, j.source, j.kind = k, true, "manual", "pvp"
  j.killerName = Util.Display(Store.Get(k))
  return true
end

---------------------------------------------------------------------------
-- Export / Import (versioned plain text, no loadstring)
-- Line 1: "DEATHNOTE:1"
-- E|key|status|manual|kills|suspected|revenge|firstKill|lastKill|lastRevenge|sightings|class|race|level|guild|faction|surname|guid|note|assists
-- D|key|t|sure|source|zone|subzone|mapID|x|y|me|myLevel|spell|role
-- (assists and role are 1.1.0 additions at the end; older texts without them still read)
-- Fields are percent-escaped (%, |, newline, CR).
---------------------------------------------------------------------------
local EXPORT_HEADER = "DEATHNOTE:1"

local function esc(v)
  if v == nil then return "" end
  if type(v) == "boolean" then return v and "1" or "0" end
  return (tostring(v):gsub("[%%|\r\n]", function(c) return ("%%%02X"):format(c:byte()) end))
end

local function unesc(s)
  return (s:gsub("%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end))
end

local function splitBar(line)
  local out = {}
  for f in (line .. "|"):gmatch("([^|]*)|") do out[#out + 1] = unesc(f) end
  return out
end

-- short == true: entries only (names, counters, status, time stamps), no deed lines,
-- so that a full list stays small. Import reads both forms.
function Store.Export(short)
  local lines = { EXPORT_HEADER }
  local keys = {}
  for k in pairs(enemies or {}) do keys[#keys + 1] = k end
  table.sort(keys)
  for _, k in ipairs(keys) do
    local e = enemies[k]
    lines[#lines + 1] = table.concat({ "E", esc(k), esc(e.status), esc(e.manual), esc(e.kills), esc(e.suspected),
      esc(e.revenge), esc(e.firstKill), esc(e.lastKill), esc(e.lastRevenge), esc(e.sightings), esc(e.class),
      esc(e.race), esc(e.level), esc(e.guild), esc(e.faction), esc(e.surname), esc(e.guid), esc(e.note),
      esc(e.assists or 0) }, "|")
    for i = (short == true) and 0 or #e.deaths, 1, -1 do
      local d = e.deaths[i]
      lines[#lines + 1] = table.concat({ "D", esc(k), esc(d.t), esc(d.sure), esc(d.source), esc(d.zone),
        esc(d.subzone), esc(d.mapID), esc(d.x), esc(d.y), esc(d.me), esc(d.myLevel), esc(d.spell),
        esc(d.role or roleOf(d.sure, d.source)) }, "|")
    end
  end
  return table.concat(lines, "\n")
end

local MAX_IMPORT_LINES = 2000
local MAX_COUNT = 9999

-- Plain decimal only (no nan/inf/hex/exponent/sign), optionally clamped to lo..hi.
local function toNum(s, lo, hi)
  if type(s) ~= "string" or #s > 20 or not s:match("^%d+%.?%d*$") then return nil end
  local v = tonumber(s)
  if not v or v ~= v then return nil end
  if lo and v < lo then v = lo end
  if hi and v > hi then v = hi end
  return v
end
local function toCount(s) return toNum(s, 0, MAX_COUNT) or 0 end
-- a time stamp: plain, not in the future (5 min clock skew tolerated), else nil
local function toTime(s)
  local v = toNum(s)
  if not v or v > now() + 300 then return nil end
  return v
end
local function toStr(s, max)
  if type(s) ~= "string" or s == "" then return nil end
  s = s:gsub("[%c|]", "")          -- no UI escape codes from foreign text
  if s == "" then return nil end
  return s:sub(1, max or 200)
end

-- canonical key of an export line, or nil
local function importKey(raw)
  if type(raw) ~= "string" or raw:find("[%c|]") or not raw:find("-", 1, true) then return nil end
  local n, s = Util.SplitKey(raw)
  if not n or not s then return nil end
  local key, _, _, had = Util.KeyFor(n, s)
  if not had then return nil end
  return key
end

-- Merges a text from Export(). Existing data is never overwritten (counters take the max,
-- missing fields are filled, deaths are added by time stamp).
-- Returns true, added, merged  |  false, message.
function Store.Import(text)
  if not enemies then return false, L.IMPORT_NO_DB end
  if type(text) ~= "string" then return false, L.IMPORT_NO_TEXT end
  text = text:gsub("\r\n", "\n"):gsub("\r", "\n")
  -- pasted from a chat program: code fences (``` or ```text) and anything before the header go
  text = ("\n" .. text):gsub("\n[ \t]*```[%w]*[ \t]*", "\n")
  -- the trailing "\n" is added for the search only: a text that ends with the header (empty book) reads too
  local at = ("\n" .. text .. "\n"):find("\n[ \t]*" .. EXPORT_HEADER:gsub("%p", "%%%0") .. "[ \t]*\n")
  if not at then
    if text:find(EXPORT_HEADER, 1, true) == nil and text:find("\n[ED]|") then
      return false, Fmt(L.IMPORT_NO_HEADER, { header = EXPORT_HEADER })
    end
    return false, L.IMPORT_NOT_EXPORT
  end
  text = ("\n" .. text):sub(at + 1):gsub("^%s+", "")
  local parsedE, parsedD = {}, {}
  local lineNo = 0
  for line in (text .. "\n"):gmatch("([^\n]*)\n") do
    lineNo = lineNo + 1
    if lineNo > MAX_IMPORT_LINES + 1 then
      return false, Fmt(L.IMPORT_TOO_LONG, { count = MAX_IMPORT_LINES })
    end
    line = line:gsub("%s+$", "")
    if lineNo > 1 and line ~= "" then
      local f = splitBar(line)
      if f[1] == "E" and #f >= 19 then
        local key = importKey(f[2])
        if not key then
          return false, Fmt(L.IMPORT_BAD_KEY, { line = lineNo })
        end
        f[2] = key
        parsedE[#parsedE + 1] = f
      elseif f[1] == "D" and #f >= 13 then
        local key = importKey(f[2])
        if not key then return false, Fmt(L.IMPORT_BAD_KEY, { line = lineNo }) end
        if not toTime(f[3]) then return false, Fmt(L.IMPORT_BAD_TIME, { line = lineNo }) end
        f[2] = key
        parsedD[#parsedD + 1] = f
      else
        return false, Fmt(L.IMPORT_BROKEN, { line = lineNo })
      end
    end
  end
  local added, merged = 0, 0
  local touched = {}
  for _, f in ipairs(parsedE) do
    local key = f[2]
    local e = enemies[key]
    local n, s = Util.SplitKey(key)
    -- the note is free text of the user (newlines allowed), only capped like SetNote
    local note = (type(f[19]) == "string" and f[19] ~= "") and f[19]:sub(1, 1000) or nil
    if not e then
      e = newEntry(key, n, s)
      e.status = VALID_STATUS[f[3]] and f[3] or "wanted"
      e.manual = f[4] == "1"
      e.imported = true      -- foreign entry: never shared in the guild
      e.note = note or ""
      added = added + 1
    else
      merged = merged + 1
      if e.note == "" and note then e.note = note end
    end
    e.kills = math.max(e.kills, toCount(f[5]))
    e.suspected = math.max(e.suspected, toCount(f[6]))
    e.assists = math.max(e.assists or 0, toCount(f[20]))
    e.revenge = math.max(e.revenge, toCount(f[7]))
    local fk = toTime(f[8]); if fk and (not e.firstKill or fk < e.firstKill) then e.firstKill = fk end
    local lk = toTime(f[9]); if lk and (not e.lastKill or lk > e.lastKill) then e.lastKill = lk end
    local lr = toTime(f[10]); if lr and (not e.lastRevenge or lr > e.lastRevenge) then e.lastRevenge = lr end
    e.sightings = math.max(e.sightings, toCount(f[11]))
    e.class = e.class or (toStr(f[12], 16) and toStr(f[12], 16):match("^%u+$"))
    e.race = e.race or toStr(f[13], 32)
    e.level = e.level or toNum(f[14], 0, 999)
    e.guild = e.guild or toStr(f[15], 64)
    e.faction = e.faction or toStr(f[16], 32)
    local sn = toStr(f[17], 64)
    if not e.surname and sn then setSurname(e, sn) end
    if e.surname then e.display = e.name .. " " .. e.surname end
    local guid = toStr(f[18], 64)
    if not e.guid and guid and not guidIndex[guid] then
      e.guid = guid; guidIndex[guid] = key
    end
    touched[key] = true
  end
  for _, f in ipairs(parsedD) do
    local e = enemies[f[2]]
    if e then
      local t = toTime(f[3])
      local dup = false
      for i = 1, #e.deaths do if e.deaths[i].t == t then dup = true; break end end
      if not dup then
        local sure, source = f[4] == "1", toStr(f[5], 16) or "manual"
        local role = VALID_ROLE[f[14]] and f[14] or roleOf(sure, source)
        local d = { t = t, sure = role == "kill", role = role, source = source, zone = toStr(f[6]),
          subzone = toStr(f[7]), mapID = toNum(f[8], 0, 1e7), x = toNum(f[9], 0, 100), y = toNum(f[10], 0, 100),
          me = toStr(f[11], 64), myLevel = toNum(f[12], 0, 999), spell = toStr(f[13]), others = {},
          imported = true }   -- foreign data: never shared in the guild
        local pos = #e.deaths + 1
        for i = 1, #e.deaths do if (e.deaths[i].t or 0) < t then pos = i; break end end
        table.insert(e.deaths, pos, d)
        while #e.deaths > MAX_ENEMY_DEATHS do table.remove(e.deaths) end
      end
    end
  end
  for key in pairs(touched) do
    local e = enemies[key]
    if e then
      -- a 1.0.x text has no assists column: its recap co-attackers count from their deeds
      local n = 0
      for i = 1, #e.deaths do if e.deaths[i].role == "assist" then n = n + 1 end end
      if n > e.assists then e.assists = n end
      settleStatus(e)
    end
    changed(key)
  end
  if added > 0 or merged > 0 then ns:Fire("BOOK_IMPORTED", added, merged) end
  return true, added, merged
end
