-- DeathNote - Store.lua
-- SavedVariables, data model, ranking, export/import.

local ADDON, ns = ...
-- Texts (1.2.0): only the messages of the import; nothing translated is ever stored
local L, Fmt = ns.L, ns.F
local Util = ns.Util
local Store = {}
ns.Store = Store

local DB_VERSION = 5      -- 2: combat log stage off by default (closed on Forever)
                          -- 3: every deed has a role (kill/assist/suspect), entries count assists
                          -- 4: the rap sheet (DeathNoteDB.ledger, Ledger.lua), created empty
                          -- 5: deeds with role "attack" (1.4.0 grudge, Grudge.lua), entries count attacks.
                          --    An older client reads such a deed as a suspicion (source "grudge"); this one
                          --    gives it its role back (sanitizeEntry), nothing is counted twice
local MAX_ENEMY_DEATHS = 30
local MAX_JOURNAL = 100
local HAND_TIMES = 10     -- 1.2.1: times of hand revenges kept per entry (revengeHandAt)
local VALID_STATUS = { wanted = true, suspect = true, pardoned = true }
-- 1.4.0 grudge: "attack" = attacked me without killing me, entered by the player (tick on the grudge notice). Never
-- shared (Sync.lua and Friends.lua send kills of role "kill" and entries by hand only), never a kill or an assist.
local VALID_ROLE = { kill = true, assist = true, suspect = true, attack = true }
local MAX_ATTACK_DEEDS = 5   -- 1.4.0 grudge: attack deeds kept per entry (the count goes on): kills keep their room

local DEFAULT_SETTINGS = {
  -- sound is the master switch; soundKey/volume (1..5)/channel are read by Alert.lua (1.1.0)
  -- 1.3.0: soundKey has no default here: a new installation stores none until the player picks one, so the alarm
  -- plays the cover's suggestion (Look.THEME_SOUND, else "warnung"); data of an older version keep or get "warnung"
  -- (Store.Init, repairSettings), so nothing sounds different for them
  alert = { enabled = true, sound = true, cooldown = 90, flash = true, minKills = 1, suspects = false,
    volume = 3, channel = "Master",
    -- 1.3.0: alarm for an enemy whose standing is even or ahead: "always" | "quiet" (no sound) | "off";
    -- victims: alarm when an own victim shows up (read by Alert.lua)
    settled = "always", victims = false },
  -- guildView: "enemy" | "member" (1.1.0) | "hunt" (1.2.0); guildCollapsed: member char name -> true (1.1.0)
  -- guildSource (1.2.0): "all" | "guild" | "friends", the source chosen in the fourth tab
  -- guildMore (1.2.0): true = House Rules, sheet Guild shows its second page "More"; absent = closed
  -- minimap: hide and angle (own button, read by 1.2.1 too); minimapPos (1.2.2, LibDBIcon) has no default here,
  -- repairSettings derives it from angle
  -- theme (1.3.0): id of the cover (Theme.lua), read at ADDON_LOADED; an unknown id falls back to "notebook" there
  ui = { scale = 1, sort = "rank", minimap = { hide = false, angle = 215 }, guildView = "enemy", guildCollapsed = {},
    guildSource = "all", theme = "notebook" },
  -- 1.3.0 (Ledger.lua): enabled = keep the rap sheet (off: nothing is booked, the data stays); chat = a chat line
  -- after an own kill (written by the book)
  ledger = { enabled = true, chat = true },
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
  -- 1.4.0 grudge (Grudge.lua): the small notice after an attack. enabled: open world (dungeons and raids never);
  -- battlegrounds: also in battlegrounds and arenas (other rules there, off by default); seconds: how long the
  -- notice stays after the fight (10/20/30/60); point: where it was dragged to (absent = the default place)
  grudge = { enabled = true, battlegrounds = false, seconds = 20 },
}

local db           -- DeathNoteDB
local enemies      -- db.enemies
local guidIndex = {}
local rankCache    -- array of wanted keys in rank order, or nil when dirty
local debtCache = {}   -- 1.3.0: filter -> list in the order "debt", emptied with rankCache (Store.Ranked hands out copies)
-- first-name index: lower(first name) -> { [key] = true }. Serves Find (quick "not listed")
-- and placeholder entries (no known surname, key "Name-<realm>"), which a sighting with the
-- full name moves to the full key.
local byFirst = {}
local placeholders = 0   -- entries without surname (only a hint; Promote re-checks)

local function now() return time() end

-- fixer 2 1.6.0 (jb03): the core calls the feud's code (Feud.lua) only through pcall: an error there is reported once per
-- function and session and never costs a death, a deed, a sighting or the start of the book
local feudErr = {}
local function feud(name, ...)
  local Fe = ns.Feud
  local fn = Fe and Fe[name]
  if type(fn) ~= "function" then return end
  local ok, err = pcall(fn, ...)
  if not ok and not feudErr[name] then
    feudErr[name] = true
    if ns.ReportError then ns.ReportError(err) end
  end
end
Store.CallFeud = feud

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
local SETTLED_MODES = { always = true, quiet = true, off = true }
local SOUND_OF_OLD = "warnung"   -- the alarm sound every version before 1.3.0 stored as its default

-- Value repairs beyond the type (1.1.0 fields). Store.Setting itself stays a plain accessor.
local function repairSettings(st)
  local a, ui = st.alert, st.ui
  local v = a.volume
  if v < 1 or v > 5 or v ~= math.floor(v) then
    a.volume = math.max(1, math.min(5, math.floor(v + 0.5)))
  end
  if not SOUND_CHANNELS[a.channel] then a.channel = DEFAULT_SETTINGS.alert.channel end
  if a.soundKey ~= nil and (type(a.soundKey) ~= "string" or a.soundKey == "" or #a.soundKey > 64) then
    a.soundKey = SOUND_OF_OLD
  end
  if not GUILD_VIEWS[ui.guildView] then ui.guildView = DEFAULT_SETTINGS.ui.guildView end
  if not GUILD_SOURCES[ui.guildSource] then ui.guildSource = DEFAULT_SETTINGS.ui.guildSource end
  if not SETTLED_MODES[a.settled] then a.settled = DEFAULT_SETTINGS.alert.settled end
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

local rankedCache = {}  -- 1.6.0 feud: filter .. "\0" .. sort -> sorted list (Store.Ranked hands out copies)
Store.rankedSorts = 0  -- tests and measuring: how often Store.Ranked really sorted
local function changed(key)
  rankCache = nil
  if next(debtCache) then debtCache = {} end
  if next(rankedCache) then rankedCache = {} end
  ns:Fire("ENEMY_UPDATED", key)
end

local function num(v, d) return (type(v) == "number" and v == v and v < math.huge and v > -math.huge) and v or d end

-- Role of a deed (1.1.0): "kill" = sure killing blow, "assist" = damage source in the death
-- recap but not the killing blow, "suspect" = heuristic only (had me targeted) or unproven.
local function roleOf(sure, source)
  -- 1.4.0 grudge: an attack is never a kill; an older client turned it into a suspicion, its source tells
  if source == "grudge" then return "attack" end
  if sure == true then return "kill" end
  if source == "recap" then return "assist" end
  return "suspect"
end
Store.RoleOf = roleOf

-- Status after the counters changed: kills or assists make a suspect wanted; pardoned stays.
-- 1.4.0 grudge: an attack entered by the player does the same (whoever is entered stands under Wanted)
local function settleStatus(e)
  if e.status == "suspect" and ((e.kills or 0) > 0 or (e.assists or 0) > 0 or (e.attacks or 0) > 0) then
    e.status = "wanted"
  end
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
  -- 1.4.0 grudge: attacks entered by the player (absent = none; older clients leave the field alone)
  if e.attacks ~= nil then
    local a = math.floor(num(e.attacks, 0))
    e.attacks = (a >= 1 and a < 1e6) and a or nil
  end
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
  -- 1.3.0: the part of revenge that came in by "Import book" (foreign data, never "me" in the rap sheet's standing)
  if e.revengeForeign ~= nil then
    local fr = math.min(math.floor(num(e.revengeForeign, 0)), e.revenge)
    e.revengeForeign = fr >= 1 and fr or nil
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
  -- 1.4.0 grudge: an attack deed that an older client read as a suspicion (or left without role) gets its role back;
  -- one the player confirmed there as a kill (or an assist) stays what he made of it
  local attackDeeds = 0
  for i = 1, #e.deaths do
    local d = e.deaths[i]
    if d.role ~= nil and not VALID_ROLE[d.role] then d.role = nil end
    if d.source == "grudge" and (d.role == nil or d.role == "suspect") then d.role = "attack" end
    if d.role == "attack" and d.source ~= "grudge" then d.source = "grudge" end
    if d.role then d.sure = d.role == "kill" end
    if d.role == "attack" then attackDeeds = attackDeeds + 1 end
  end
  if attackDeeds > (e.attacks or 0) then e.attacks = attackDeeds end
  if e.lastSeen ~= nil and type(e.lastSeen) ~= "table" then e.lastSeen = nil end
  if e.lastAttack ~= nil and (type(e.lastAttack) ~= "number" or e.lastAttack ~= e.lastAttack) then e.lastAttack = nil end
  -- additive (1.1.0): who added it by hand, when, and where it came from
  if e.by ~= nil and (type(e.by) ~= "string" or e.by == "") then e.by = nil end
  if e.listedAt ~= nil and type(e.listedAt) ~= "number" then e.listedAt = nil end
  if e.fromGuild ~= nil and e.fromGuild ~= true then e.fromGuild = nil end
  if e.imported ~= nil and e.imported ~= true then e.imported = nil end
  -- 1.4.0 overview: taken over from whom (a character name), from where ("guild" | "friends" | "text") and when
  if e.adoptFrom ~= nil and (type(e.adoptFrom) ~= "string" or e.adoptFrom == "" or #e.adoptFrom > 64
    or e.adoptFrom:find("[%c|]")) then e.adoptFrom = nil end
  if e.adoptSrc ~= nil and e.adoptSrc ~= "guild" and e.adoptSrc ~= "friends" and e.adoptSrc ~= "text" then e.adoptSrc = nil end
  if e.adoptAt ~= nil and type(e.adoptAt) ~= "number" then e.adoptAt = nil end
  -- 1.6.0 feud: the guild of each deed, the guilds of the revenge, the play day of the last deed or sighting, "keep"
  feud("SanitizeEntry", e)
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
local initBody
function Store.Init()
  -- 1.6.0 feud: the time of the start is measured (probe.feud)
  local clock = _G.debugprofilestop
  local t0 = type(clock) == "function" and clock() or os.clock() * 1000
  local out = initBody()
  local t1 = type(clock) == "function" and clock() or os.clock() * 1000
  if ns.Feud and ns.Feud.InitTime then pcall(ns.Feud.InitTime, t1 - t0) end
  return out
end
initBody = function()
  if type(_G.DeathNoteDB) ~= "table" then _G.DeathNoteDB = {} end
  db = _G.DeathNoteDB
  if type(db.version) ~= "number" then
    -- no version: a fresh DB is current, anything with content counts as version 1
    db.version = (next(db) == nil) and DB_VERSION or 1
  end
  -- 1.3.0: data of an older version had alert.soundKey filled with "warnung"; one without it (1.0.x) gets it too
  -- (1.4.0: "older" = before version 4; a book of 1.3.x keeps playing the cover's suggestion, DB_VERSION is 5 now)
  local fromOld = db.version < 4
  if type(db.settings) ~= "table" then db.settings = {} end
  if db.version < 2 then
    -- the closed combat log was on by default in version 1
    local a = db.settings.attribution
    if type(a) == "table" and a.combatlog == true then a.combatlog = false end
    db.version = 2
  end
  fillDefaults(db.settings, DEFAULT_SETTINGS)
  if fromOld and db.settings.alert.soundKey == nil then db.settings.alert.soundKey = SOUND_OF_OLD end
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
  -- 1.6.0 feud: play days, old suspicions to the archive, the hard cap of the book (Feud.lua); never breaks the start
  if ns.Feud and ns.Feud.OnInit then
    local ok, err = pcall(ns.Feud.OnInit, db, enemies)
    if not ok and ns.ReportError then ns.ReportError(err) end
  end
  rankCache = nil
  debtCache = {}
  rankedCache = {}
  Store.TouchJournal()
  rebuildIndex()
  -- 4: the rap sheet (DeathNoteDB.ledger). The start only repairs it and keeps its keys in line with the book; it
  -- books nothing, also after a downgrade to 1.2.x and back (Ledger.Init).
  if ns.Ledger and ns.Ledger.Init then
    local ok, err = pcall(ns.Ledger.Init, db)
    if not ok then ns.ReportError(err) end
  end
  if db.version < 4 then db.version = 4 end
  -- 5 (1.4.0 grudge): attack deeds; sanitizeEntry already gave them their role, nothing else to do
  if db.version < 5 then db.version = 5 end
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

-- 1.3.0 (decision 4): the open debt of an entry, max(0, his kills - my kills incl. revenge noted by hand); 0 while the
-- rap sheet is off. open = the standing is open (debt, or 0 : 0 with assists or by hand)
function Store.Debt(e)
  if type(e) ~= "table" or type(e.key) ~= "string" then return 0, false end
  local Lg = ns.Ledger
  local mine, his, state
  if Lg and Lg.Standing then mine, his, state = Lg.Standing(e.key) end
  if not mine then return 0, false end
  return math.max(0, his - mine), state == "open"
end

-- open debt first (biggest first), open cases without debt next, then even and ahead; inside each the old rank.
-- Debts are read once per sort, not per comparison.
-- 1.3.0 (package B, measured): an entry without any revenge and without a victim of the rap sheet stands at 0 : his
-- kills, open; only the others need the standing (a book of 400: 1275 -> see the report)
local function quickDebt(e, Lg)
  if e.status == "wanted" and (tonumber(e.revenge) or 0) == 0 and not Lg.Victim(e.key) then
    return math.min(tonumber(e.kills) or 0, Lg.COUNT_MAX or 9999), true
  end
end
local function debtSort(list)
  local debt, open = {}, {}
  local Lg = ns.Ledger
  local quick = Lg and Lg.Victim and Lg.Enabled and Lg.Enabled()
  for i = 1, #list do
    local e = list[i]
    local d, o
    if quick then d, o = quickDebt(e, Lg) end
    if d then debt[e], open[e] = d, o else debt[e], open[e] = Store.Debt(e) end
  end
  table.sort(list, function(a, b)
    if debt[a] ~= debt[b] then return debt[a] > debt[b] end
    if open[a] ~= open[b] then return open[a] end
    return rankLess(a, b)
  end)
  return list
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

-- sort "debt" (1.3.0): the order of decision 4 (open debt first); the book's default stays "rank" until the
-- book switches over
function Store.Ranked(filter, sort)
  filter = filter or "wanted"
  local cached = sort == "debt" and debtCache[filter]
  if cached then
    local copy = {}
    for i = 1, #cached do copy[i] = cached[i] end
    return copy
  end
  -- 1.6.0 feud: every other sort is cached per filter too (emptied by every change, like "debt")
  local ck = sort ~= "debt" and (filter .. "\0" .. tostring(sort)) or nil
  local hit = ck and rankedCache[ck]
  if hit then
    local copy = {}
    for i = 1, #hit do copy[i] = hit[i] end
    return copy
  end
  Store.rankedSorts = Store.rankedSorts + 1
  local out = {}
  for _, e in pairs(enemies or {}) do
    if filter == "all" or e.status == filter then out[#out + 1] = e end
  end
  if sort == "debt" then
    debtSort(out)
    local keep = {}
    for i = 1, #out do keep[i] = out[i] end
    debtCache[filter] = keep
    return out
  end
  table.sort(out, SORTS[sort] or rankLess)
  local keep = {}
  for i = 1, #out do keep[i] = out[i] end
  rankedCache[ck] = keep
  return out
end

-- 1.3.0 (decision 4): with the rap sheet on, the rank follows the open debt (sort "debt"), and an enemy whose
-- standing is settled (even or ahead) has no rank at all. So rank 1, the top title (public enemy No. 1), is always an
-- open case, and with every enemy settled there is none. With the rap sheet off: the rank of 1.2.x.
local function settledState(e)
  if quickDebt(e, ns.Ledger) then return false end
  local _, _, state = ns.Ledger.Standing(e.key)
  return state == "even" or state == "ahead"
end
function Store.RankOrder()
  local Lg = ns.Ledger
  return (Lg and Lg.Enabled and Lg.Standing and Lg.Enabled()) and "debt" or "rank"
end
function Store.Rank(key)
  local e = Store.Get(key)
  if not e or e.status ~= "wanted" then return nil end
  if not rankCache then
    rankCache = {}
    local order = Store.RankOrder()
    local list = Store.Ranked("wanted", order)
    local n = 0
    for i = 1, #list do
      if not (order == "debt" and settledState(list[i])) then n = n + 1; rankCache[list[i].key] = n end
    end
  end
  return rankCache[key]
end
-- The rank `key` had right before his latest revenge (one "me" less), for "public enemy down" (Humor.lua): the
-- revenge that settles the top enemy takes his rank away, yet it is exactly the one that took down rank 1. Without the
-- debt order a revenge never moved the rank (1.2.x): Store.Rank. Costs one pass over the book, only on a revenge.
function Store.RankBefore(key)
  local e = Store.Get(key)
  if not e or e.status ~= "wanted" then return nil end
  if Store.RankOrder() ~= "debt" then return Store.Rank(key) end
  local mine, his = ns.Ledger.Standing(key)
  if not mine or mine < 1 then return Store.Rank(key) end
  mine = mine - 1
  if not (his > mine or mine == 0) then return nil end    -- settled before as well
  local d0 = math.max(0, his - mine)
  local n = 1
  for _, o in pairs(enemies) do
    if o ~= e and o.status == "wanted" then
      local d, open = Store.Debt(o)
      if open and (d > d0 or (d == d0 and rankLess(o, e))) then n = n + 1 end
    end
  end
  return n
end
-- the standing of an enemy changed (own kill, Ledger.Clear) or the rap sheet was switched: ranks anew
ns:On("STANDING_CHANGED", function() rankCache = nil; if next(debtCache) then debtCache = {} end end)
ns:On("SETTINGS_CHANGED", function(path) if path == "ledger.enabled" then rankCache = nil; debtCache = {} end end)


-- Fun value in copper, deterministic.
function Store.Bounty(e)
  if type(e) ~= "table" then return 0 end
  local kills, susp, rev = e.kills or 0, e.suspected or 0, e.revenge or 0
  -- 1.3.0: the bounty sinks with "me" of the standing (Ledger.Mine: never below revenge, so never higher than in
  -- 1.2.x; own killing blows before he was listed lower it further)
  local Lg = ns.Ledger
  local mine = Lg and Lg.Mine and type(e.key) == "string" and Lg.Mine(e.key, e) or nil
  if mine then rev = mine end
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
  feud("Touch", e)
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
  -- 1.6.0 feud: a name or a sighting may change the sorts "name" and "seen" (the rank cache stays)
  -- fixer 2 1.6.0 (je04): only those two go; "rank", "recent" and "debt" read neither identity nor lastSeen
  for ck in pairs(rankedCache) do
    local sort = ck:match("%z(.*)$")
    if sort == "name" or sort == "seen" then rankedCache[ck] = nil end
  end
  local hasSurname = false
  local sn = info.surname
  if not Util.IsSecret(sn) and type(sn) == "string" and sn ~= "" then hasSurname = true end
  -- 1.3.0: the GUID beats the first name. Info of another GUID never lands on an entry with a GUID unless both
  -- name the player in full (a first name alone is a namesake, not this player)
  local ig = plainField(info.guid)
  if type(e.guid) == "string" and type(ig) == "string" and ig ~= e.guid and not (hasSurname and e.surname ~= nil) then
    return
  end
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
-- 1.4.0 overview: { adopt = { from = "Name Surname", src = "guild" | "friends" | "text", kills = n } } takes an entry
-- over from someone else's book: marked fromGuild (never shared, as before) with origin and time of the take-over.
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
  local ad = type(opts) == "table" and type(opts.adopt) == "table" and opts.adopt or nil
  if ad then
    e.fromGuild = true
    e.adoptAt = now()
    if type(ad.from) == "string" and ad.from ~= "" and #ad.from <= 64 and not ad.from:find("[%c|]") then e.adoptFrom = ad.from end
    if ad.src == "guild" or ad.src == "friends" or ad.src == "text" then e.adoptSrc = ad.src end
    local k = tonumber(ad.kills)
    if k and k >= 0 and k < 1e6 then e.fromGuildKills = math.floor(k) end
  end
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

-- 1.6.0 feud: an entry back into the book (from the archive of old suspicions, Feud.lua). Only under a free key;
-- repaired like at the start. Fires ENEMY_UPDATED. Returns true when it is in the book again.
function Store.PutBack(key, e)
  if not enemies or type(key) ~= "string" or type(e) ~= "table" or enemies[key] then return false end
  if not sanitizeEntry(key, e) then return false end
  if type(e.guid) == "string" and guidIndex[e.guid] and enemies[guidIndex[e.guid]] then e.guid = nil end
  enemies[key] = e
  indexAdd(key, e)
  if type(e.guid) == "string" then guidIndex[e.guid] = key end
  changed(key)
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
  e.statusHand = true   -- 1.6.0 fix: a standing set by the player keeps the entry from expiring (Feud.MayKeep)
  changed(key)
  if old ~= status then ns:Fire("ENEMY_STATUS", key, old, status) end
  return true
end

local function pushCapped(list, item, cap)
  table.insert(list, 1, item)
  while #list > cap do table.remove(list) end
end

-- 1.4.0 fixer: the deeds of an entry (newest first) within their caps. Attacks never push out a kill, an assist or a
-- suspicion: beyond MAX_ATTACK_DEEDS attacks, and beyond MAX_ENEMY_DEATHS deeds, the oldest attack goes first, only
-- then the oldest deed. The count e.attacks goes on.
local function capDeeds(e)
  local list = e.deaths
  local function oldestAttack()
    for i = #list, 1, -1 do if list[i].role == "attack" then return i end end
  end
  local n = 0
  for i = 1, #list do if list[i].role == "attack" then n = n + 1 end end
  while n > MAX_ATTACK_DEEDS do table.remove(list, oldestAttack()); n = n - 1 end
  while #list > MAX_ENEMY_DEATHS do table.remove(list, oldestAttack() or #list) end
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
  -- 1.6.0 feud: the guild he wore at this deed (a later change of guild never moves it)
  if rec.guild == nil then rec.guild = plainField(info.guild) end
  if type(rec.guild) ~= "string" then rec.guild = nil end
  feud("Touch", e)
  local role = VALID_ROLE[death.role] and death.role or roleOf(sure and true or false, death.source)
  rec.role = role
  rec.sure = role == "kill"
  if type(death.others) == "table" then
    local o = {}
    for i = 1, #death.others do if death.others[i] ~= key then o[#o + 1] = death.others[i] end end
    rec.others = o
  end
  table.insert(e.deaths, 1, rec)
  capDeeds(e)
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

-- 1.4.0 grudge: the attacks the player entered (tick on the grudge notice), 0 for none. For the book's list (filter
-- "attack", the core line "3× attacked") and for others that read the book: Store.Attacks(e) counts every attack ever
-- entered (the deeds keep only the newest MAX_ATTACK_DEEDS); Store.OnlyAttacks(e) = the entry has nothing but attacks
-- (no kill, no assist, no suspicion, not by hand), shown with the stamp GRUDGE.
function Store.Attacks(e)
  if Util.IsSecret(e) or type(e) ~= "table" then return 0 end
  local a = tonumber(e.attacks) or 0
  return a >= 1 and math.floor(a) or 0
end
function Store.OnlyAttacks(e)
  return Store.Attacks(e) > 0 and (tonumber(e.kills) or 0) == 0 and (tonumber(e.assists) or 0) == 0
    and (tonumber(e.suspected) or 0) == 0 and e.manual ~= true
end

-- 1.4.0 grudge (Grudge.lua): the player ticked an attacker. info = identity { name, surname, guid, class, level, ... }
-- (plain values only), rec = { t, zone, subzone, mapID, x, y, me, myLevel }. Writes a deed of role "attack" (source
-- "grudge", never sure), counts it and puts the entry under Wanted (a suspect too; pardoned stays pardoned). One deed
-- per entry and time stamp (the same fight is not entered twice). Never sets `manual`: the entry is not shared.
-- Returns the key, or nil.
function Store.AddAttack(info, rec)
  if type(rec) ~= "table" or type(rec.t) ~= "number" then return nil end
  local key, e = Store.Upsert(info, true)
  if not key then return nil end
  for i = 1, #e.deaths do
    local d = e.deaths[i]
    if d.t == rec.t and d.role == "attack" then return key end
  end
  local d = copyDeath(rec)
  d.role, d.sure, d.source, d.others = "attack", false, "grudge", {}
  -- 1.6.0 feud: the guild of the attacker at this attack
  if d.guild == nil then d.guild = plainField(info.guild) end
  if type(d.guild) ~= "string" then d.guild = nil end
  feud("Touch", e)
  -- the oldest attack deed gives way (never a kill, an assist or a suspicion: capDeeds)
  local pos = #e.deaths + 1
  for i = 1, #e.deaths do if (e.deaths[i].t or 0) <= d.t then pos = i; break end end
  table.insert(e.deaths, pos, d)
  capDeeds(e)
  e.attacks = Store.Attacks(e) + 1
  e.lastAttack = math.max(tonumber(e.lastAttack) or 0, d.t)
  if e.status == "suspect" then e.status = "wanted" end
  if type(rec.theirLevel) == "number" then e.level = rec.theirLevel end
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
  feud("Touch", e)
  -- the rank does not depend on sightings or identity fields: keep the rank cache
  -- 1.6.0 feud: "seen" lets the book bundle the rebuilds of a crowd of sightings (UI.lua)
  ns:Fire("ENEMY_UPDATED", key, "seen")
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
      local r = e.deaths[i].role
      if r ~= "kill" and r ~= "attack" then d = e.deaths[i]; break end
    end
  end
  -- only a deed that is no kill yet can be confirmed (repeated clicks must not inflate kills); 1.4.0 grudge: an
  -- attack belongs to no death, it never becomes a kill
  if not d or d.role == "kill" or d.role == "attack" then return false end
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
  if e.kills == 0 and (e.assists or 0) == 0 and not e.manual and e.revenge == 0 and (e.attacks or 0) == 0 then
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

-- byHand (1.2.1): noted by the player ("Note revenge"), counted apart in e.revengeHand (additive) so that
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
  -- 1.6.0 feud: the guild he wore at this revenge (Feud.lua counts the revenge per guild from it)
  feud("RevengeGuild", e, 1)
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
  feud("RevengeGuild", e, -1)
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
      if old.kills == 0 and (old.assists or 0) == 0 and not old.manual and old.status == "wanted"
        and (old.attacks or 0) == 0 then
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
      if d.t == j.t and d.role ~= "kill" and d.role ~= "attack" then
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
-- E|key|status|manual|kills|suspected|revenge|firstKill|lastKill|lastRevenge|sightings|class|race|level|guild|faction|surname|guid|note|assists|attacks
-- D|key|t|sure|source|zone|subzone|mapID|x|y|me|myLevel|spell|role
-- (assists and role are 1.1.0 additions at the end; older texts without them still read)
-- (1.4.0 grudge: attacks at the end of E, role "attack" with source "grudge" in D; an older client reads the E line
-- as before and an attack deed as a suspicion of source "grudge", which this version turns back into an attack)
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

-- 1.4.0 fixer: field 22 of an E line = where a copied entry came from: "src;kills;at;from" (src guild, friends, text
-- or empty; kills = the deaths of the guild or friends; at = when it was copied; from = whose list). Left out for
-- the own entries. Older clients read 19 to 21 fields and leave the rest alone.
local function originOf(e)
  if e.fromGuild ~= true then return nil end
  local k = tonumber(e.fromGuildKills)
  return table.concat({ e.adoptSrc or "", k and tostring(math.floor(k)) or "", tonumber(e.adoptAt) and tostring(math.floor(e.adoptAt)) or "",
    type(e.adoptFrom) == "string" and e.adoptFrom or "" }, ";")
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
    local fields = { "E", esc(k), esc(e.status), esc(e.manual), esc(e.kills), esc(e.suspected),
      esc(e.revenge), esc(e.firstKill), esc(e.lastKill), esc(e.lastRevenge), esc(e.sightings), esc(e.class),
      esc(e.race), esc(e.level), esc(e.guild), esc(e.faction), esc(e.surname), esc(e.guid), esc(e.note),
      esc(e.assists or 0), esc(Store.Attacks(e)) }
    local origin = originOf(e)
    if origin then fields[#fields + 1] = esc(origin) end   -- only for copied entries: other lines stay as before
    lines[#lines + 1] = table.concat(fields, "|")
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

-- 1.4.0 overview: reads a text from Export() without changing anything.
-- Returns true, parsedE, parsedD (fields of the E and D lines, keys made canonical)  |  false, message.
function Store.ImportParse(text)
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
  return true, parsedE, parsedD
end

-- 1.4.0 overview: what an import would do, nothing is changed. info = { total, new, have, owner, ownerMine }:
-- entries in the text, of them not yet in the book, already in it; owner = the character named most often as the
-- victim of the text's deeds (the one whose book it is, nil without deeds), ownerMine = that is one of the own
-- characters (the logged-in one or one named as victim in the own book). Returns true, info | false, message.
local function ownChars()
  local out = {}
  local me = Util.PlayerFullName and Util.PlayerFullName()
  if type(me) == "string" then out[me:lower()] = true; out[(me:match("^(%S+)") or me):lower()] = true end
  for _, e in pairs(enemies) do
    for i = 1, #e.deaths do
      local d = e.deaths[i]
      if not d.imported and type(d.me) == "string" then out[d.me:lower()] = true end
    end
  end
  return out
end
function Store.ImportPreview(text)
  local ok, parsedE, parsedD = Store.ImportParse(text)
  if not ok then return false, parsedE end
  -- wantedNew/wantedHave: the same for the entries wanted in the text (what a friend's book gives, ImportFriend)
  local info = { total = 0, new = 0, have = 0, wantedNew = 0, wantedHave = 0 }
  local seen = {}
  for _, f in ipairs(parsedE) do
    if not seen[f[2]] then
      seen[f[2]] = true
      info.total = info.total + 1
      local n, s = Util.SplitKey(f[2])
      local has = enemies[f[2]] ~= nil
      if has then info.have = info.have + 1 else info.new = info.new + 1 end
      if f[3] == "wanted" or f[3] == "" then
        if has or Store.Find(n, s) then info.wantedHave = info.wantedHave + 1 else info.wantedNew = info.wantedNew + 1 end
      end
    end
  end
  local count, best, bestN = {}, nil, 0
  for _, f in ipairs(parsedD) do
    local who = toStr(f[11], 64)
    if who then
      count[who] = (count[who] or 0) + 1
      if count[who] > bestN or (count[who] == bestN and who < best) then best, bestN = who, count[who] end
    end
  end
  info.owner = best
  local own = ownChars()
  info.ownerMine = best == nil or own[best:lower()] == true or own[(best:match("^(%S+)") or best):lower()] == true
  return true, info
end

-- 1.4.0 overview: the last import can be taken back once: the entries it added are struck, the ones it merged get
-- their state from before. Kept until the next import or /reload.
local lastImport
local function snapshot(e)
  local c = {}
  for k, v in pairs(e) do
    if type(v) == "table" then
      local t = {}
      for k2, v2 in pairs(v) do t[k2] = v2 end
      c[k] = t
    else
      c[k] = v
    end
  end
  return c
end
-- 1.4.0 fixer: what an entry looked like right after an import or a take-over (a deep copy), and whether it still
-- looks like that. An undo takes back only entries nobody touched since: a kill, a death, an attack, a note, a pardon,
-- a sighting after it are own data, and such an entry stays as it is.
local function deepCopy(v, seen)
  if type(v) ~= "table" then return v end
  seen = seen or {}
  if seen[v] then return seen[v] end
  local c = {}
  seen[v] = c
  for k, x in pairs(v) do c[deepCopy(k, seen)] = deepCopy(x, seen) end
  return c
end
local function deepEqual(a, b)
  if type(a) ~= "table" or type(b) ~= "table" then
    if a ~= a and b ~= b then return true end   -- NaN
    return a == b
  end
  for k, v in pairs(a) do if not deepEqual(v, b[k]) then return false end end
  for k in pairs(b) do if a[k] == nil then return false end end
  return true
end
function Store.Fingerprint(key)
  local e = enemies and enemies[key]
  return e and deepCopy(e) or nil
end
function Store.Untouched(key, fp)
  local e = enemies and enemies[key]
  return e ~= nil and type(fp) == "table" and deepEqual(e, fp)
end

function Store.CanUndoImport() return lastImport ~= nil end
-- returns the number taken back and the number kept (touched since the import: they keep everything)
function Store.UndoImport()
  local u = lastImport
  lastImport = nil
  if not u or not enemies then return 0, 0 end
  local n, kept = 0, 0
  local after = u.after or {}
  for i = 1, #u.added do
    local key = u.added[i]
    local e = enemies[key]
    if not e then
      -- struck by hand since: nothing to take back
    elseif e.imported and Store.Untouched(key, after[key]) and Store.Remove(key) then
      n = n + 1
    else
      kept = kept + 1
    end
  end
  for key, before in pairs(u.before) do
    local e = enemies[key]
    if e and not Store.Untouched(key, after[key]) then
      kept = kept + 1
    elseif e then
      if e.guid and e.guid ~= before.guid and guidIndex[e.guid] == key then guidIndex[e.guid] = nil end
      if e.surname and not before.surname then placeholders = placeholders + 1 end
      for k in pairs(e) do e[k] = nil end
      for k, v in pairs(before) do e[k] = v end
      if e.guid then guidIndex[e.guid] = key end
      n = n + 1
      changed(key)
    end
  end
  return n, kept
end

-- 1.4.0 overview: a friend's book as text. Only who is wanted there and not yet in the own book is taken, as a manual
-- entry taken over from `from` (Store.AddManual opts.adopt, src "text"): his kills stay his (a number in the note, never
-- kills on me), his pardoned and suspects stay out, nothing of it is ever shared. Entries already in the book stay
-- untouched. Returns true, keys of the new entries, number already in the book  |  false, message.
function Store.ImportFriend(text, from)
  local okp, parsedE = Store.ImportParse(text)
  if not okp then return false, parsedE end
  if type(from) ~= "string" or from == "" then from = nil end
  local added, have, seen = {}, 0, {}
  for _, f in ipairs(parsedE) do
    local key = f[2]
    if not seen[key] and (f[3] == "wanted" or f[3] == "") then
      seen[key] = true
      local n, s = Util.SplitKey(key)
      if enemies[key] or Store.Find(n, s) then
        have = have + 1
      else
        local k = Store.AddManual(n, s, { fromGuild = true, adopt = { from = from, src = "text", kills = toCount(f[5]) } })
        local e = k and enemies[k]
        if e then
          local class = toStr(f[12], 16)
          Store.Upsert({ name = n, surname = s, class = class and class:match("^%u+$") or nil, level = toNum(f[14], 0, 999) }, false)
          added[#added + 1] = k
        end
      end
    end
  end
  return true, added, have
end

-- Merges a text from Export(). Existing data is never overwritten (counters take the max,
-- missing fields are filled, deaths are added by time stamp).
-- Returns true, added, merged  |  false, message.
function Store.Import(text)
  local okp, parsedE, parsedD = Store.ImportParse(text)
  if not okp then return false, parsedE end
  local added, merged = 0, 0
  local touched = {}
  local undo = { added = {}, before = {} }
  for _, f in ipairs(parsedE) do
    local e = enemies[f[2]]
    if e and not undo.before[f[2]] then undo.before[f[2]] = snapshot(e) end
  end
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
      -- 1.4.0 fixer: a copied entry of the own backup comes back as copied, with its origin (field 22)
      local src, kills, at, from = (type(f[22]) == "string" and f[22] or ""):match("^(%l*);(%d*);(%d*);(.*)$")
      if src then
        e.fromGuild = true
        if src == "guild" or src == "friends" or src == "text" then e.adoptSrc = src end
        local k = toNum(kills, 0, 1e6 - 1)
        if k then e.fromGuildKills = math.floor(k) end
        e.adoptAt = toTime(at)
        e.adoptFrom = toStr(from, 64)
      end
      added = added + 1
      undo.added[#undo.added + 1] = key
    else
      merged = merged + 1
      if e.note == "" and note then e.note = note end
    end
    e.kills = math.max(e.kills, toCount(f[5]))
    e.suspected = math.max(e.suspected, toCount(f[6]))
    e.assists = math.max(e.assists or 0, toCount(f[20]))
    -- 1.4.0 grudge: attacks (a text of an older version has no such field: 0)
    local att = math.max(Store.Attacks(e), toCount(f[21]))
    e.attacks = att > 0 and att or nil
    local rev0 = e.revenge
    e.revenge = math.max(e.revenge, toCount(f[7]))
    -- 1.3.0: what the text added to revenge is foreign data: the book counts it as before (bounty), the rap sheet's
    -- standing does not take it as "me"
    if e.revenge > rev0 then e.revengeForeign = math.min(e.revenge, (e.revengeForeign or 0) + e.revenge - rev0) end
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
        -- 1.4.0 grudge: an attack read as a suspicion by an older client is an attack again; an attack keeps its source
        if source == "grudge" and role == "suspect" then role = "attack" end
        if role == "attack" then source = "grudge" end
        local d = { t = t, sure = role == "kill", role = role, source = source, zone = toStr(f[6]),
          subzone = toStr(f[7]), mapID = toNum(f[8], 0, 1e7), x = toNum(f[9], 0, 100), y = toNum(f[10], 0, 100),
          me = toStr(f[11], 64), myLevel = toNum(f[12], 0, 999), spell = toStr(f[13]), others = {},
          imported = true }   -- foreign data: never shared in the guild
        local pos = #e.deaths + 1
        for i = 1, #e.deaths do if (e.deaths[i].t or 0) < t then pos = i; break end end
        table.insert(e.deaths, pos, d)
        capDeeds(e)
      end
    end
  end
  for key in pairs(touched) do
    local e = enemies[key]
    if e then
      -- a 1.0.x text has no assists column: its recap co-attackers count from their deeds
      local n, na = 0, 0
      for i = 1, #e.deaths do
        if e.deaths[i].role == "assist" then n = n + 1 elseif e.deaths[i].role == "attack" then na = na + 1 end
      end
      if n > e.assists then e.assists = n end
      -- 1.4.0 grudge: so does a text whose E line lacks the attacks (written by hand, cut)
      if na > Store.Attacks(e) then e.attacks = na end
      settleStatus(e)
    end
    changed(key)
  end
  for key in pairs(undo.before) do if not touched[key] then undo.before[key] = nil end end
  undo.after = {}
  for key in pairs(touched) do undo.after[key] = Store.Fingerprint(key) end
  lastImport = (added > 0 or merged > 0) and undo or nil
  if added > 0 or merged > 0 then ns:Fire("BOOK_IMPORTED", added, merged) end
  return true, added, merged
end
