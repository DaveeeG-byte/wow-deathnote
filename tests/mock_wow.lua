-- Minimal WoW API mock for running the DeathNote logic under luajit.
-- Secret values are userdata proxies that raise on index, arithmetic, concat, compare (<,<=),
-- length, call and tostring. Like in the client, type(secret) reports the type of the hidden
-- value ("string", "boolean", "number", "table"), so a guard that relies on type() alone lets
-- the secret through and the next string method / # / index raises here as in the game.
-- Limits (Lua 5.1): `==`/`~=` against a plain value and plain boolean tests (`if v then`)
-- cannot be trapped at runtime; test_secrets.lua checks the guard ORDER statically instead.
-- Set the global DN_PLAIN_TYPE = true before loading to keep the builtin type() (benchmarks).

local M = {}
local ADDON_DIR = (arg and arg[0] and arg[0]:match("^(.*)/tests/") or ".") .. "/DeathNote/"
M.ADDON_DIR = ADDON_DIR
-- 1.2.0: the language scaffold loads first (Locale.lua, English, German). Without a choice the addon
-- runs in the client's language (English when DeathNote lacks it); the tests choose explicitly: M.locale
-- (env DN_LANG, default deDE, the existing tests read German texts) is activated and stored as settings.lang.
-- opts.lang = false (M.Load / W.client) leaves the language unchosen like a fresh install.
-- GetLocale() returns M.client or M.locale (the client's language: the default without an own choice).
M.FILES = { "Locale.lua", "Locales/enUS.lua", "Locales/deDE.lua", "Theme.lua", "Themes/notebook.lua",
  "Core.lua", "Store.lua", "Tracker.lua", "Attribution.lua", "Ranks.lua", "Ledger.lua", "Probe.lua", "Sync.lua",
  "Friends.lua", "Bounty.lua" }
M.locale = os.getenv("DN_LANG") or "deDE"

-- the file list for the active M.locale (its file is added after deDE when it is another one)
function M.Files(list)
  list = list or M.FILES
  local code = M.locale
  if code == "enUS" or code == "deDE" then return list end
  local out = {}
  for _, f in ipairs(list) do
    out[#out + 1] = f
    if f == "Locales/deDE.lua" then out[#out + 1] = "Locales/" .. code .. ".lua" end
  end
  return out
end

---------------------------------------------------------------------------
-- Secrets
---------------------------------------------------------------------------
local secrets = setmetatable({}, { __mode = "k" })
local secretTables = setmetatable({}, { __mode = "k" })
local secretKind = setmetatable({}, { __mode = "k" })   -- proxy -> type the client would report

local rawtype = type
M.rawtype = rawtype
local function mockType(v)
  local k = secretKind[v]
  if k then return k end
  return rawtype(v)
end
if not rawget(_G, "DN_PLAIN_TYPE") then _G.type = mockType end
local type = rawtype   -- the mock itself sees the real types

-- labels of older tests that stand for booleans / numbers (default: string)
local KIND_OF_LABEL = { bool = "boolean", b = "boolean", ["true"] = "boolean", h = "boolean", UnitIsUnit = "boolean",
  num = "number", o = "number", t = "number", amount = "number" }

local function boom(what) return function() error("secret value: " .. what, 2) end end

-- M.Secret(label[, kind]): kind = "string"|"boolean"|"number"|"table" (what type() reports).
function M.Secret(label, kind)
  local p = newproxy(true)
  local mt = getmetatable(p)
  mt.__index = boom("indexed")
  mt.__newindex = boom("indexed")
  mt.__call = boom("called")
  mt.__concat = boom("concatenated")
  mt.__len = boom("length")
  mt.__lt = boom("compared")
  mt.__le = boom("compared")
  mt.__add, mt.__sub, mt.__mul, mt.__div, mt.__mod, mt.__pow, mt.__unm =
    boom("arithmetic"), boom("arithmetic"), boom("arithmetic"), boom("arithmetic"),
    boom("arithmetic"), boom("arithmetic"), boom("arithmetic")
  mt.__tostring = boom("tostring")
  secrets[p] = label or true
  secretKind[p] = kind or KIND_OF_LABEL[label] or "string"
  return p
end

function M.SecretTable()
  local p = M.Secret("table", "table")
  secretTables[p] = true
  return p
end

function M.IsSecretObj(v) return secrets[v] ~= nil end

-- Deep scan: true if a secret object sits anywhere in t (keys or values).
function M.ContainsSecret(t, seen)
  seen = seen or {}
  if secrets[t] then return true end
  if type(t) ~= "table" or seen[t] then return false end
  seen[t] = true
  for k, v in pairs(t) do
    if secrets[k] or secrets[v] then return true end
    if type(v) == "table" and M.ContainsSecret(v, seen) then return true end
  end
  return false
end

---------------------------------------------------------------------------
-- World state
---------------------------------------------------------------------------
function M.Reset()
  M.now = 1000
  M.epoch = 1700000000
  M.timers = {}
  M.frames = {}
  M.errors = {}
  M.chat = {}
  M.closedEvents = { COMBAT_LOG_EVENT_UNFILTERED = true }  -- Forever: closed to addons
  -- 1.3.0: CHAT_MSG_COMBAT_HONOR_GAIN registers on Forever (probe in the real SavedVariables); nothing is unknown
  M.unknownEvents = {}
  M.instance = { false, "none" }
  M.units = {}
  M.recap = nil          -- { id = n, events = {...} }  or a secret table via M.SecretTable()
  M.meter = nil
  M.cvars = { nameplateShowEnemies = true }
  M.units.player = { exists = true, isPlayer = true, name = "Varorak", surname = "Narenmar",
    guid = "Player-93-0000AAAA", class = "WARRIOR", classLoc = "Krieger", level = 40, faction = "Horde" }
  M.fired = {}
  -- additive: addon messages (guild sharing)
  M.addonSent = {}        -- { prefix, text, channel, at }
  M.prefixes = {}
  M.sendResult = nil      -- nil = old style (no return), number = Enum result, function(text) -> result
  M.inCombat = false
  M.chatLockdown = false
  M.InstallGlobals()
end

function M.AddEnemy(token, o)
  o = o or {}
  local u = {
    exists = true, isPlayer = true, name = o.name or "Feind", surname = o.surname,
    guid = o.guid or ("Player-93-" .. (type(o.name) == "string" and o.name or "Feind")), class = o.class or "ROGUE", classLoc = o.classLoc or "Schurke",
    race = o.race or "Human", raceLoc = o.raceLoc or "Mensch", level = o.level or 40, guild = o.guild,
    faction = o.faction or "Alliance", enemy = (o.enemy == nil) and true or o.enemy,
    canAttack = (o.canAttack == nil) and true or o.canAttack, target = o.target,
  }
  for k, v in pairs(o) do u[k] = v end
  M.units[token] = u
  return u
end

local function resolve(token)
  if type(token) ~= "string" then return nil end
  local base = token:match("^(.-)target$")
  if base and base ~= "" then
    local u = M.units[base]
    if u and u.target then return M.units[u.target] end
    return nil
  end
  return M.units[token]
end

function M.Advance(sec)
  local target = M.now + sec
  while true do
    table.sort(M.timers, function(a, b) return a.at < b.at end)
    local t = M.timers[1]
    if not t or t.at > target then break end
    table.remove(M.timers, 1)
    M.now = t.at
    local ok, err = pcall(t.fn)
    if not ok then M.errors[#M.errors + 1] = err end
  end
  M.now = target
end

function M.FireEvent(event, ...)
  for _, f in ipairs(M.frames) do
    if f.events[event] and f.scripts.OnEvent then
      local ok, err = pcall(f.scripts.OnEvent, f, event, ...)
      if not ok then M.errors[#M.errors + 1] = err end
    end
  end
end

---------------------------------------------------------------------------
-- Globals
---------------------------------------------------------------------------
function M.InstallGlobals()
  local G = _G
  G.DeathNoteDB = nil
  G.DeathNote = nil
  G.issecretvalue = function(v) return secrets[v] ~= nil end
  G.issecrettable = function(v) return secretTables[v] ~= nil end
  G.GetTime = function() return M.now end
  G.time = function() return math.floor(M.epoch + M.now) end
  G.geterrorhandler = function() return function(err) M.errors[#M.errors + 1] = err end end
  G.SlashCmdList = {}
  G.GetLocale = function() return M.client or M.locale or "deDE" end
  G.UNKNOWNOBJECT = "Unbekannt"
  G.SELFKILLOTHER = "Ihr habt %s getötet!"
  G.UNITDIESOTHER = "%s stirbt."
  -- 1.3.0: the text of the German Forever client (probe), not the Classic one
  G.COMBATLOG_HONORGAIN = "%s stirbt (Ehrenhafter Sieg: %s). Ihr erhaltet %d Ehre."
  G.RAID_CLASS_COLORS = { WARRIOR = { r = 0.78, g = 0.61, b = 0.43 }, ROGUE = { r = 1, g = 0.96, b = 0.41 } }
  G.DEFAULT_CHAT_FRAME = { AddMessage = function(_, msg) M.chat[#M.chat + 1] = msg end }
  G.Enum = { DamageMeterType = { DamageTaken = 7, Deaths = 9 }, DamageMeterSessionType = { Overall = 0, Current = 1 } }
  G.C_Timer = { After = function(d, fn) M.timers[#M.timers + 1] = { at = M.now + d, fn = fn } end }
  G.CreateFrame = function()
    local f = { events = {}, scripts = {} }
    function f:RegisterEvent(ev)
      if M.closedEvents[ev] then error("Attempt to register protected event " .. ev) end
      if M.unknownEvents[ev] then error("Attempt to register unknown event " .. ev) end
      self.events[ev] = true
    end
    function f:UnregisterEvent(ev) self.events[ev] = nil end
    function f:SetScript(k, fn) self.scripts[k] = fn end
    M.frames[#M.frames + 1] = f
    return f
  end
  G.GetNormalizedRealmName = function() return "Forever" end
  G.GetRealmName = function() return "Forever" end
  G.GetRealZoneText = function() return M.zone or "Schlingendorntal" end
  G.GetSubZoneText = function() return M.subzone or "Grom'gol" end
  G.C_Map = {
    GetBestMapForUnit = function() return 1434 end,
    GetPlayerMapPosition = function() return { GetXY = function() return 0.4123, 0.5678 end } end,
  }
  G.IsInInstance = function() return M.instance[1], M.instance[2] end
  G.InCombatLockdown = function() return M.inCombat == true end
  G.IsInGuild = function() return M.units.player and M.units.player.guild ~= nil or false end
  G.Ambiguate = function(name, how)
    if type(name) ~= "string" then return name end
    return (name:gsub("%-Forever$", ""))
  end
  G.C_AddOns = { GetAddOnMetadata = function(_, field) if field == "Version" then return "1.0.0" end end }
  G.C_ChatInfo = {
    RegisterAddonMessagePrefix = function(p)
      if type(p) ~= "string" or #p > 16 then return 2 end
      M.prefixes[p] = true
      return 0
    end,
    SendAddonMessage = function(prefix, text, channel)
      if type(text) ~= "string" or #text > 255 then error("message too long") end
      local r = M.sendResult
      if type(r) == "function" then r = r(text) end
      if r == nil or r == 0 then
        M.addonSent[#M.addonSent + 1] = { prefix = prefix, text = text, channel = channel, at = M.now }
      end
      return r
    end,
    InChatMessagingLockdown = function() return M.chatLockdown == true end,
  }
  G.C_CVar = { GetCVarBool = function(n) return M.cvars[n] end }
  local function u(t) return resolve(t) end
  G.UnitExists = function(t) local x = u(t); return x and x.exists or false end
  G.UnitIsPlayer = function(t) local x = u(t); return x and x.isPlayer or false end
  G.UnitName = function(t) local x = u(t); if not x then return nil end return x.name, x.surname end
  G.UnitGUID = function(t) local x = u(t); return x and x.guid end
  G.UnitClass = function(t) local x = u(t); if x then return x.classLoc, x.class end end
  G.UnitRace = function(t) local x = u(t); if x then return x.raceLoc, x.race end end
  G.UnitLevel = function(t) local x = u(t); return x and x.level end
  G.UnitSex = function(t) local x = u(t); return x and 2 end
  G.GetGuildInfo = function(t) local x = u(t); return x and x.guild end
  G.UnitFactionGroup = function(t) local x = u(t); return x and x.faction end
  G.UnitIsEnemy = function(_, t) local x = u(t); return x and x.enemy or false end
  G.UnitCanAttack = function(_, t) local x = u(t); return x and x.canAttack or false end
  G.UnitIsFriend = function(_, t)
    local x = u(t)
    if not x then return false end
    if x.friend ~= nil then return x.friend end
    if x == M.units.player then return true end
    return rawequal(x.enemy, false) and rawequal(x.canAttack, false)
  end
  G.UnitIsUnit = function(a, b)
    local x, y = u(a), u(b)
    if x and x.isUnitOverride ~= nil and b == "player" then return x.isUnitOverride end
    if not x or not y then return false end
    if a:find("target$") and M.units[a:match("^(.-)target$")] and M.units[a:match("^(.-)target$")].targetsMeSecret then
      return M.Secret("UnitIsUnit")
    end
    return x == y
  end
  G.GetPlayerInfoByGUID = function(guid)
    for _, x in pairs(M.units) do
      if x.guid == guid then return x.classLoc, x.class, x.raceLoc, x.race, 2, x.name, "" end
    end
  end
  G.C_DeathRecap = {
    GetRecapEvents = function(id)
      if not M.recap then return nil end
      if secretTables[M.recap] then return M.recap end
      if id and id ~= M.recap.id then return nil end
      return M.recap.events
    end,
    GetRecapLink = function()
      if not M.recap or secretTables[M.recap] or not M.recap.id then return nil end
      return "|Hdeath:" .. M.recap.id .. "|h[Todesübersicht]|h"
    end,
  }
  G.C_DamageMeter = {
    GetCombatSessionSourceFromType = function(sessionType, dmType, guid)
      if not M.meter then return nil end
      return M.meter
    end,
    GetCombatSessionFromType = function() return nil end,
  }
end

---------------------------------------------------------------------------
-- Loading the addon
---------------------------------------------------------------------------
function M.Load(opts)
  opts = opts or {}
  if not opts.keepWorld then M.Reset() else M.frames, M.timers = {}, {} end
  if opts.db then _G.DeathNoteDB = opts.db end
  if opts.before then opts.before() end
  local ns = {}
  -- opts.dir / opts.files (1.3.0): another addon folder in this Lua state (the differential run against 1.2.2)
  for _, f in ipairs(opts.files or M.Files()) do
    local chunk = assert(loadfile((opts.dir or ADDON_DIR) .. f))
    chunk("DeathNote", ns)
  end
  M.ns = ns
  M.ChooseLanguage(ns, opts.lang)
  -- like the client: ADDON_LOADED (SavedVariables are there) before PLAYER_LOGIN
  M.FireEvent("ADDON_LOADED", "DeathNote")
  for _, ev in ipairs({ "READY", "ENEMY_UPDATED", "DEATH_RECORDED", "ENEMY_SPOTTED", "REVENGE", "SETTINGS_CHANGED",
    "TOGGLE_UI", "TEST_ALERT", "ENEMY_REKEYED", "GUILD_UPDATED", "GUILD_KILL", "GUILD_ENEMY_SPOTTED", "GUILD_SIGHTING" }) do
    ns:On(ev, function(...) M.fired[#M.fired + 1] = { ev, ... } end)
  end
  if not opts.noLogin then
    M.FireEvent("PLAYER_LOGIN")
    M.FireEvent("PLAYER_ENTERING_WORLD")
  end
  return ns
end

-- the explicit language of a test client: activate it now and store it as the player's choice
-- once the Store is up (READY), so no first-start dialog comes. lang == false: nothing chosen.
function M.ChooseLanguage(ns, lang)
  if lang == false or not ns.Locale then return end
  lang = lang or M.locale
  ns.Locale.Activate(lang)
  ns:On("READY", function()
    local db = ns.Store and ns.Store.DB and ns.Store.DB()
    if db and db.settings and db.settings.lang == nil then db.settings.lang = lang end
  end)
end

function M.Fired(ev)
  local out = {}
  for _, f in ipairs(M.fired) do if f[1] == ev then out[#out + 1] = f end end
  return out
end

function M.ClearFired() M.fired = {} end

---------------------------------------------------------------------------
-- Several isolated clients in one Lua state (additive, 1.1.0): own globals, frames and
-- SavedVariables, shared clock and timers, one guild channel per guild name.
-- M.NewWorld() -> W; W.client(name, surname, guild) -> c (c.ns, c.env, c.events, c.fire(ev, ...));
-- W.deliver() hands everything on the wire to every client of the same guild (sender too: echo);
-- W.run(sec) advances the clock in 0.1 s steps and delivers.
---------------------------------------------------------------------------
function M.NewWorld(watch)
  local W = { clients = {}, wire = {}, sent = {} }
  -- opts: { dir = other addon folder (e.g. an installed 1.0.0), patch = function(file, src) -> src }
  function W.client(name, surname, guild, opts)
    opts = opts or {}
    local c = { name = name, surname = surname, guild = guild, frames = {}, sendResult = nil, combat = false,
      fullSender = opts.fullSender,
      version = opts.version, friendNames = opts.friends or {}, online = true, bnNames = opts.bn or {} }
    W.nextBn = (W.nextBn or 100) + 1
    c.bnId = W.nextBn
    local env = setmetatable({}, { __index = _G })
    env._G = env
    env.DeathNoteDB = opts.db
    env.CreateFrame = function()
      local f = _G.CreateFrame()
      table.remove(M.frames)
      c.frames[#c.frames + 1] = f
      return f
    end
    env.UnitName = function(t) if t == "player" then return c.name, c.surname end return _G.UnitName(t) end
    env.UnitGUID = function(t) if t == "player" then return W.guidOf(c) end return _G.UnitGUID(t) end
    env.GetGuildInfo = function(t) if t == "player" then return c.guild end return _G.GetGuildInfo(t) end
    env.IsInGuild = function() return c.guild ~= nil end
    env.InCombatLockdown = function() return c.combat end
    env.C_AddOns = { GetAddOnMetadata = function(_, f) if f == "Version" then return c.version or "1.1.0" end end }
    env.C_ChatInfo = {
      RegisterAddonMessagePrefix = function() return 0 end,
      SendAddonMessage = function(prefix, text, channel, target)
        assert(#text <= 255)
        if c.sendResult and c.sendResult ~= 0 then return c.sendResult end
        if channel == "WHISPER" then
          c.whispers = (c.whispers or 0) + 1
          if c.whisperResult and c.whisperResult ~= 0 then return c.whisperResult end
        end
        -- opts.fullSender (fix-1): the client names this sender with surname ("Name Surname-Realm")
        local from = (c.fullSender and c.surname) and (c.name .. " " .. c.surname .. "-Forever") or (c.name .. "-Forever")
        local m = { prefix = prefix, text = text, channel = channel, from = from, guild = c.guild,
          to = target, sender = c }
        W.wire[#W.wire + 1] = m
        W.sent[#W.sent + 1] = m
        return 0
      end,
    }
    -- 1.2.0: the friend list of this client (names as the game lists them), online state from the world
    env.C_FriendList = {
      GetNumFriends = function() return #c.friendNames end,
      GetFriendInfoByIndex = function(i)
        local n = c.friendNames[i]
        if not n then return nil end
        -- fix-2: W.guids = true: the list gives the friend's GUID (as FriendGroups/ElvUI read info.guid)
        local x = W.guids and W.find(n)
        return { name = n, connected = W.online(n), className = "Krieger", level = 40, guid = x and W.guidOf(x) or nil }
      end,
      ShowFriends = function() end,
    }
    -- 1.2.0 (fix-1): the guild roster as OpenMap/Map/Friends.lua reads it (GetNumGuildMembers,
    -- GetGuildRosterInfo: name "Name-Realm", ..., online as 9th value). Every client of the same guild,
    -- online or not; opts.noRoster = true: a client without this API.
    if not opts.noRoster then
      local function mates()
        local out = {}
        if c.guild then for _, x in ipairs(W.clients) do if x.guild == c.guild then out[#out + 1] = x end end end
        return out
      end
      env.GetNumGuildMembers = function() return #mates() end
      env.GetGuildRosterInfo = function(i)
        local x = mates()[i]
        if not x then return nil end
        -- 1.2.1: W.guids = true: the GUID as 17th value (OpenMap/ElvUI read it there)
        -- 1.2.1: with W.guids a client that is named with surname (fullSender) stands so in the roster too
        local rn = (W.guids and x.fullSender and x.surname) and (x.name .. " " .. x.surname) or x.name
        return rn .. "-Forever", "Mitglied", 1, 40, "Krieger", "Zone", "", "", x.online ~= false and x.loggedIn == true,
          nil, "WARRIOR", 0, 0, false, false, 0, W.guids and W.guidOf(x) or nil
      end
      env.C_GuildInfo = { GuildRoster = function() end }
    end
    -- Battle.net friends in the same game (as OpenMap reads them), game data by game account
    env.BNGetNumFriends = function() return #c.bnNames end
    env.C_BattleNet = {
      GetFriendAccountInfo = function(i)
        local n = c.bnNames[i]
        local x = n and W.find(n)
        if not x then return nil end
        -- fix-2: the BattleTag (an offline friend stays on the Battle.net list); W.noTags = true: no tags
        return { battleTag = not W.noTags and (x.name .. "#" .. x.bnId) or nil,
          gameAccountInfo = { isOnline = W.online(n), clientProgram = "WoW", characterName = x.name,
          gameAccountID = x.bnId } }
      end,
      GetGameAccountInfoByID = function(id)
        for _, x in ipairs(W.clients) do
          if x.bnId == id then return { characterName = x.name, clientProgram = "WoW", isOnline = x.online } end
        end
      end,
    }
    env.BNSendGameData = function(id, prefix, text)
      assert(#text <= 255)
      c.bnSends = (c.bnSends or 0) + 1
      if c.bnResult then error("BN refused") end
      local m = { prefix = prefix, text = text, channel = "BN", toId = id, fromId = c.bnId, sender = c }
      W.wire[#W.wire + 1] = m
      W.sent[#W.sent + 1] = m
    end
    c.env = env
    local ns = {}
    for _, f in ipairs(opts.files or M.Files()) do
      local h = io.open((opts.dir or M.ADDON_DIR) .. f, "rb")
      -- an older folder (opts.dir: 1.0.0/1.1.0) has no Locale.lua and no Locales/
      if not h and opts.dir and f:find("Locale", 1, true) then goto continue end
      assert(h, f)
      local src = h:read("*a"); h:close()
      if opts.patch then src = opts.patch(f, src) end
      local chunk = assert(loadstring(src, "@" .. f))
      setfenv(chunk, env)
      chunk("DeathNote", ns)
      ::continue::
    end
    c.ns = ns
    M.ChooseLanguage(ns, opts.lang)
    c.events = {}
    for _, ev in ipairs(watch or { "GUILD_KILL", "GUILD_UPDATED", "GUILD_ENEMY_SPOTTED" }) do
      ns:On(ev, function(...) c.events[#c.events + 1] = { ev, ... } end)
    end
    function c.fire(event, ...)
      for _, f in ipairs(c.frames) do
        if f.events[event] and f.scripts.OnEvent then
          local okc, err = pcall(f.scripts.OnEvent, f, event, ...)
          if not okc then M.errors[#M.errors + 1] = err end
        end
      end
    end
    function c.login()
      c.loggedIn = true
      c.fire("ADDON_LOADED", "DeathNote")
      c.fire("PLAYER_LOGIN"); c.fire("PLAYER_ENTERING_WORLD")
      W.setOnline(c, true)
    end
    W.clients[#W.clients + 1] = c
    return c
  end
  -- GUID of a client: hexadecimal like the game's ("Player-1-" plus the name bytes) when W.guids is set,
  -- else the old form of the tests ("Player-1-Name", not a valid hex GUID: never sent with a hello)
  function W.guidOf(c)
    if not W.guids then return "Player-1-" .. c.name end
    local full = c.name .. (c.surname or "")
    return "Player-1-" .. (full:gsub(".", function(ch) return ("%02X"):format(ch:byte()) end)):sub(1, 16)
  end
  -- client behind a name of the friend list ("Name", "Name Surname", "Name-Realm")
  function W.find(n)
    local short = n:match("^([^%-]+)") or n
    local first, sur = short:match("^(%S+)%s+(.+)$")
    first = first or short
    for _, c in ipairs(W.clients) do
      if c.name == first and (not sur or sur == c.surname) then return c end
    end
  end
  function W.online(n)
    local c = W.find(n)
    return c ~= nil and c.online ~= false and c.loggedIn == true
  end
  -- a client comes online or goes offline: everybody who has him on the friend list hears of it
  function W.setOnline(x, v)
    x.online = v
    for _, c in ipairs(W.clients) do
      for _, n in ipairs(c.friendNames) do
        if c ~= x and W.find(n) == x and c.loggedIn then c.fire("FRIENDLIST_UPDATE"); break end
      end
    end
  end
  function W.deliver()
    local n = 0
    while #W.wire > 0 do
      local m = table.remove(W.wire, 1)
      n = n + 1
      if m.channel == "BN" then
        for _, c in ipairs(W.clients) do
          if c.bnId == m.toId and c.online ~= false and c.loggedIn then
            c.fire("BN_CHAT_MSG_ADDON", m.prefix, m.text, "WHISPER", m.fromId)
          end
        end
      elseif m.channel == "WHISPER" then
        local c = W.find(m.to or "")
        if c and c.online ~= false and c.loggedIn then c.fire("CHAT_MSG_ADDON", m.prefix, m.text, m.channel, m.from) end
      else
        for _, c in ipairs(W.clients) do
          if c.guild == m.guild then c.fire("CHAT_MSG_ADDON", m.prefix, m.text, m.channel, m.from) end
        end
      end
    end
    return n
  end
  function W.run(sec)
    for _ = 1, math.ceil(sec / 0.1) do M.Advance(0.1); W.deliver() end
  end
  return W
end

---------------------------------------------------------------------------
-- Tiny test harness
---------------------------------------------------------------------------
local results = { pass = 0, fail = 0, failures = {} }

local function fmt(v)
  if secrets[v] then return "<secret>" end
  if type(v) == "string" then return ("%q"):format(v) end
  return tostring(v)
end

function M.test(name, fn)
  local ok, err = pcall(fn)
  if ok and M.errors and #M.errors > 0 then ok, err = false, "addon error: " .. tostring(M.errors[1]) end
  if ok then
    results.pass = results.pass + 1
  else
    results.fail = results.fail + 1
    results.failures[#results.failures + 1] = name .. ": " .. tostring(err)
  end
end

function M.eq(a, b, msg)
  if a ~= b then error((msg or "eq") .. ": expected " .. fmt(b) .. ", got " .. fmt(a), 2) end
end

function M.ok(v, msg)
  if not v then error((msg or "ok") .. ": expected truthy, got " .. fmt(v), 2) end
end

function M.no(v, msg)
  if v then error((msg or "no") .. ": expected falsy, got " .. fmt(v), 2) end
end

function M.done(suite)
  io.write(("%-18s %3d ok, %d rot\n"):format(suite, results.pass, results.fail))
  for _, f in ipairs(results.failures) do io.write("  ROT: " .. f .. "\n") end
  os.exit(results.fail == 0 and 0 or 1)
end

return M
