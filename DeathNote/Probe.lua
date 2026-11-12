-- DeathNote - Probe.lua
-- Diagnose: which APIs/events exist, what is secret, what the last death delivered per stage.
-- Secrets are only ever stored as the marker "<secret>".

local ADDON, ns = ...
local Util = ns.Util
local Call, IsSecret = Util.Call, Util.IsSecret

local Probe = {}
ns.Probe = Probe

local MAX_DEPTH, MAX_ITEMS, MAX_DEATHS = 4, 25, 5

-- Copy for SavedVariables: secrets -> "<secret>", functions/userdata -> "<type>", size-limited.
function Probe.Sanitize(v, depth)
  depth = depth or 0
  if IsSecret(v) then return "<secret>" end
  if v == nil then return nil end
  local t = type(v)
  if t == "string" then return #v > 200 and v:sub(1, 200) .. "…" or v end
  if t == "number" or t == "boolean" then return v end
  if t ~= "table" then return "<" .. t .. ">" end
  if depth >= MAX_DEPTH then return "<table>" end
  local out, n = {}, 0
  for k, val in pairs(v) do
    if IsSecret(k) then
      out["<secret-key>"] = "<secret>"
    elseif type(k) == "string" or type(k) == "number" then
      n = n + 1
      if n > MAX_ITEMS then out["…"] = "gekürzt"; break end
      out[k] = Probe.Sanitize(val, depth + 1)
    end
  end
  return out
end
local S = Probe.Sanitize

local function path(p)
  local t = _G
  for part in p:gmatch("[^%.]+") do
    if type(t) ~= "table" then return nil end
    t = t[part]
  end
  return t
end

Probe.APIS = {
  "issecretvalue", "issecrettable", "canaccessvalue", "scrubsecretvalues", "C_Secrets.ShouldUnitIdentityBeSecret",
  "C_DeathRecap.GetRecapEvents", "C_DeathRecap.GetRecapLink", "C_DeathRecap.HasRecapEvents",
  "C_DeathRecap.GetRecapMaxHealth", "DeathRecap_GetEvents",
  "C_DamageMeter.GetCombatSessionFromType", "C_DamageMeter.GetCombatSessionSourceFromType",
  "C_DamageMeter.GetAvailableCombatSessions", "Enum.DamageMeterType.DamageTaken", "Enum.DamageMeterType.Deaths",
  "Enum.DamageMeterSessionType.Current",
  "CombatLogGetCurrentEventInfo", "C_RestrictedActions.GetAddOnRestrictionState", "GetPlayerInfoByGUID",
  "UnitNameUnmodified", "GetNormalizedRealmName", "C_NamePlate.GetNamePlateForUnit", "C_CVar.GetCVarBool",
  "C_Map.GetPlayerMapPosition", "SELFKILLOTHER", "UNITDIESOTHER", "COMBATLOG_HONORGAIN",
  -- guild sharing (Sync.lua)
  "C_ChatInfo.RegisterAddonMessagePrefix", "C_ChatInfo.SendAddonMessage", "C_ChatInfo.InChatMessagingLockdown",
  "C_ChatInfo.AreOutgoingAddonChatMessagesRestricted", "Enum.SendAddonMessageResult", "IsInGuild", "GetGuildInfo",
  "Ambiguate", "GetNumGuildMembers", "GetGuildRosterInfo", "C_GuildInfo.GuildRoster",
  -- friends' book (Friends.lua, 1.2.0)
  "C_FriendList.GetNumFriends", "C_FriendList.GetFriendInfoByIndex", "C_FriendList.ShowFriends",
  "BNGetNumFriends", "BNSendGameData", "C_BattleNet.GetFriendAccountInfo", "C_BattleNet.GetGameAccountInfoByID",
}

-- COMBAT_LOG_EVENT_UNFILTERED is not in this list: the client closes it to addons and an
-- attempt to register it is only made on an explicit "/dn probe combatlog".
Probe.EVENTS = {
  "PARTY_KILL", "UNIT_DIED", "PLAYER_DEAD", "CHAT_MSG_COMBAT_HOSTILE_DEATH",
  "CHAT_MSG_COMBAT_HONOR_GAIN", "PLAYER_PVP_KILLS_CHANGED", "NAME_PLATE_UNIT_ADDED", "UNIT_TARGET",
  "PLAYER_FOCUS_CHANGED", "UPDATE_MOUSEOVER_UNIT", "DUEL_REQUESTED", "DUEL_FINISHED",
  "CHAT_MSG_ADDON", "PLAYER_GUILD_UPDATE", "ADDON_RESTRICTION_STATE_CHANGED",
  "FRIENDLIST_UPDATE", "BN_CHAT_MSG_ADDON", "CVAR_UPDATE",
}

local scratch
local function eventExists(ev)
  scratch = scratch or CreateFrame("Frame")
  local ok = pcall(scratch.RegisterEvent, scratch, ev)
  if ok then pcall(scratch.UnregisterEvent, scratch, ev) end
  return ok
end

-- What the client returns for a unit: type or "<secret>" per value (names are stored only for players we see anyway).
local function describeUnit(unit)
  local function m(...)
    local n = select("#", ...)
    local out = {}
    for i = 1, n do
      local v = select(i, ...)
      out[i] = IsSecret(v) and "<secret>" or (v == nil and "nil" or (type(v) == "string" and v or tostring(v)))
    end
    return table.concat(out, ", ")
  end
  local function try(fn, ...)
    if type(fn) ~= "function" then return "fehlt" end
    local r = { pcall(fn, ...) }
    if not r[1] then return "Fehler" end
    return m(unpack(r, 2, math.max(2, table.maxn(r))))
  end
  return {
    exists = try(UnitExists, unit), isPlayer = try(UnitIsPlayer, unit), name = try(UnitName, unit),
    guid = try(UnitGUID, unit), class = try(UnitClass, unit), race = try(UnitRace, unit), level = try(UnitLevel, unit),
    enemy = try(UnitIsEnemy, "player", unit), canAttack = try(UnitCanAttack, "player", unit),
    faction = try(UnitFactionGroup, unit), targetsMe = try(UnitIsUnit, unit .. "target", "player"),
    identitySecret = try(_G.C_Secrets and _G.C_Secrets.ShouldUnitIdentityBeSecret, unit),
    key = Util.KeyOfUnit(unit) or "nil",
  }
end

-- opts (additive): { combatlog = true } also tries to register the combat log event.
function Probe.Run(verbose, opts)
  local db = ns.Store and ns.Store.DB()
  local out = { t = time(), apis = {}, events = {} }
  local missing, present = {}, 0
  for _, a in ipairs(Probe.APIS) do
    local v = path(a)
    local have = v ~= nil
    out.apis[a] = have and (type(v) == "function" and true or S(v)) or false
    if have then present = present + 1 else missing[#missing + 1] = a end
  end
  local evNo = {}
  local events = Probe.EVENTS
  if type(opts) == "table" and opts.combatlog then
    events = { "COMBAT_LOG_EVENT_UNFILTERED" }
    for i = 1, #Probe.EVENTS do events[#events + 1] = Probe.EVENTS[i] end
  end
  for _, e in ipairs(events) do
    local ok = eventExists(e)
    out.events[e] = ok
    if not ok then evNo[#evNo + 1] = e end
  end
  -- restrictions
  local CR, E = _G.C_RestrictedActions, _G.Enum
  if CR and CR.GetAddOnRestrictionState and E and E.AddOnRestrictionType then
    out.restrictions = {}
    for name, id in pairs(E.AddOnRestrictionType) do
      out.restrictions[name] = S(Call(CR.GetAddOnRestrictionState, id))
    end
  end
  out.openWorld = Util.IsOpenWorld()
  out.inCombat = S(Call(InCombatLockdown))
  out.nameplatesOn = Util.NameplatesOn()
  -- 1.2.2: which event noticed the last switch of the enemy plates, and the last CVAR_UPDATE arguments
  out.plates = { known = Util.platesOn, by = Util.platesSource, events = {} }
  for i, e in ipairs(Util.plateLog or {}) do
    out.plates.events[i] = { t = e.t, event = e.event, a1 = e.a1, a2 = e.a2, switched = e.switched }
  end
  out.player = { name = describeUnit("player").name, key = Util.KeyOfUnit("player"), realm = Util.OwnRealm() }
  if Util.True(Call(UnitExists, "target")) then out.target = describeUnit("target") end
  -- current recap / meter as seen now
  local A = ns.Attribution
  if A then
    local r = A.ReadRecap()
    out.recapNow = { ok = r.ok, why = r.why, stale = r.stale, id = r.id, n = #r.sources, raw = S(r.raw) }
    local m = A.ReadMeter()
    out.meterNow = { ok = m.ok, why = m.why, n = #m.sources, raw = S(m.raw) }
    out.combatlog = { on = A.state.clogOn and true or false, dead = A.state.clogDead, fails = A.state.clogFails }
    if A.last then
      out.lastDeath = Probe.DeathRecord(A.last.p or {}, A.last.result, A.last.journal, A.last.evidence, A.last.suspects)
    end
  end
  if ns.Tracker then out.trackerCount = ns.Tracker.Count(); out.trackerActive = ns.Tracker.active end
  -- additive: guild sharing
  local G = ns.Guild
  if G then
    local CI = _G.C_ChatInfo
    local st = G.stats or {}
    local enemies, deeds, listedOnly, foreign = G.Count()
    local h = G.Health and G.Health() or {}
    out.guild = {
      canRegister = (CI and CI.RegisterAddonMessagePrefix) and true or false,
      canSend = (CI and CI.SendAddonMessage) and true or false,
      prefixOK = G.PrefixOK(), prefixResult = st.prefixResult,
      lastSendResult = st.lastResult, lastReason = st.lastReason, holdNow = G.HoldReason(), realmRestricted = st.realmRestricted,
      sent = st.sent, received = st.received, dropped = st.dropped, lastSender = S(st.lastSender),
      -- 1.2.0: which name form the client gives a sender ("full" = with surname, "first" = first name only)
      senderForm = st.senderForm, roster = (_G.GetGuildRosterInfo and _G.GetNumGuildMembers) and true or false,
      -- name form in the guild roster ("full" = with surname, "first"), from its first entry
      rosterForm = (function()
        if not _G.GetGuildRosterInfo then return nil end
        local okr, n = pcall(_G.GetGuildRosterInfo, 1)
        n = okr and S(n) or nil
        if type(n) ~= "string" then return nil end
        return (n:match("^([^%-]+)") or n):find(" ", 1, true) and "full" or "first"
      end)(),
      queue = G.QueueSize(), inGuild = G.Name() ~= nil, enabled = G.Enabled(),
      enemies = enemies, deeds = deeds, members = #G.Members(),
      -- 1.1.0: names listed by hand (M) and taken off again (X)
      listedOnly = listedOnly, shareManual = G.Setting("shareManual") == true,
      foreign = foreign, health = h.reason, healthDetail = h.detail,
      listSent = st.listSent, listReceived = st.listReceived, listDropped = st.listDropped,
      unlistSent = st.unlistSent, unlistReceived = st.unlistReceived, unlistDropped = st.unlistDropped,
      -- 1.2.0: hunt list of this guild
      hunts = G.HuntCount and G.HuntCount("guild") or nil, huntReceived = st.huntReceived,
      -- 1.2.1: the first send attempt in an instance ({ kind, result = ok | throttle | refused, code, at }), also
      -- from an earlier session; bounties and "avenged" received on GUILD
      instanceSend = st.instanceSend or (db and type(db.probe) == "table" and type(db.probe.guild) == "table"
        and type(db.probe.guild.instanceSend) == "table" and db.probe.guild.instanceSend or nil),
      bountyReceived = st.bountyReceived, avengedReceived = st.avengedReceived,
    }
  end
  -- 1.2.0: friends' book (sent, received, lastSendResult, lastReason, health, online, withAddon, ...)
  if ns.Friends and ns.Friends.Probe then
    local okp, pf = pcall(ns.Friends.Probe)
    if okp and type(pf) == "table" then
      pf.lastSender = S(pf.lastSender)
      out.friends = pf
    end
  end
  if db then
    local keep = db.probe and db.probe.deaths
    db.probe = out
    out.deaths = keep or {}
  end
  if verbose then
    -- 1.2.0: framing words from the language table; the values (codes, numbers) stay technical
    local L, Fmt = ns.L, ns.F
    local function yn(v) return v and L.WORD_YES or L.WORD_NO end
    local function readable(x) return x and (x.ok and L.PROBE_READABLE or tostring(x.why)) or "?" end
    Util.Print(Fmt(L.PROBE_HEAD, { apis = present, apisAll = #Probe.APIS, events = #events - #evNo, eventsAll = #events }))
    if #missing > 0 then Util.Print(Fmt(L.PROBE_MISSING, { list = table.concat(missing, ", ") })) end
    if #evNo > 0 then Util.Print(Fmt(L.PROBE_NOT_REGISTERABLE, { list = table.concat(evNo, ", ") })) end
    Util.Print(Fmt(L.PROBE_SOURCES, { recap = readable(out.recapNow), meter = readable(out.meterNow),
      clog = out.combatlog and (out.combatlog.dead and L.PROBE_DEAD or (out.combatlog.on and L.WORD_ON or L.WORD_OFF)) or "?" }))
    Util.Print(Fmt(L.PROBE_PLATES, { plates = out.nameplatesOn and L.WORD_ON or L.PROBE_PLATES_OFF,
      open = yn(out.openWorld) }))
    -- technical line (event names and raw arguments, no translation): newest first, * = this one switched them
    do
      local parts = {}
      local nowT = Util.Num(Call(GetTime)) or 0
      for _, e in ipairs(out.plates.events) do
        local args = e.event == "CVAR_UPDATE" and ("(" .. e.a1 .. ", " .. e.a2 .. ")") or ""
        parts[#parts + 1] = e.event .. args .. (e.switched and "*" or "") .. " -" .. math.floor(nowT - (e.t or 0) + 0.5) .. "s"
      end
      Util.Print("nameplateShowEnemies: " .. tostring(out.plates.known) .. " (" .. tostring(out.plates.by) .. ") · "
        .. (#parts > 0 and table.concat(parts, " · ") or "CVAR_UPDATE -"))
    end
    if out.target then
      Util.Print(Fmt(L.PROBE_TARGET, { name = tostring(out.target.name), guid = tostring(out.target.guid),
        class = tostring(out.target.class), enemy = tostring(out.target.enemy), me = tostring(out.target.targetsMe) }))
    end
    if out.guild then
      local g = out.guild
      Util.Print(Fmt(L.PROBE_GUILD, {
        prefix = g.prefixOK and L.PROBE_REGISTERED or Fmt(L.PROBE_NOT_REGISTERED, { result = tostring(g.prefixResult) }),
        send = g.canSend and L.PROBE_POSSIBLE or L.PROBE_ABSENT, result = tostring(g.lastSendResult),
        sent = g.sent or 0, received = g.received or 0, dropped = g.dropped or 0 })
        .. (g.holdNow and Fmt(L.PROBE_WAITS, { why = g.holdNow }) or ""))
      Util.Print(Fmt(L.PROBE_LISTED, { sent = g.listSent or 0, received = g.listReceived or 0, dropped = g.listDropped or 0,
        usent = g.unlistSent or 0, ureceived = g.unlistReceived or 0, udropped = g.unlistDropped or 0 }))
    end
    if out.guild and out.guild.health then
      local h = G and G.Health and G.Health()
      if h and h.text then Util.Print(Fmt(L.PROBE_GUILDBOOK, { text = h.text }) .. (h.detail and (" (" .. h.detail .. ")") or "")) end
    end
    Util.Print(L.PROBE_SAVED)
  end
  return out
end

-- Compact, sanitized record of one death (all stages).
function Probe.DeathRecord(p, result, journal, evidence, suspects)
  local rec = { t = p.t or (journal and journal.t), tries = p.tries, openWorld = p.openWorld, duel = p.duel, stages = {} }
  for _, ev in ipairs(evidence or p.evidence or {}) do
    rec.stages[#rec.stages + 1] = { stage = ev.stage, ok = ev.ok, why = ev.why, stale = ev.stale, id = ev.id,
      n = ev.sources and #ev.sources or 0, raw = S(ev.raw, 1) }
  end
  local sus = suspects or p.suspects
  if sus then
    rec.targeters, rec.recent = {}, {}
    for _, s in ipairs(sus.targeters or {}) do rec.targeters[#rec.targeters + 1] = { key = s.key, ago = s.ago } end
    for _, s in ipairs(sus.recent or {}) do rec.recent[#rec.recent + 1] = { key = s.key, ago = s.ago } end
  end
  if result then
    rec.result = { kind = result.kind, killer = result.killerKey, sure = result.sure, source = result.source,
      others = S(result.others), candidates = S(result.candidates) }
  end
  return rec
end

-- Called by Attribution after each death when settings.debug is on: ring buffer of the last 5.
function Probe.RecordDeath(p, result, journal)
  local db = ns.Store and ns.Store.DB()
  if not db then return end
  if type(db.probe) ~= "table" then db.probe = {} end
  if type(db.probe.deaths) ~= "table" then db.probe.deaths = {} end
  local list = db.probe.deaths
  table.insert(list, 1, Probe.DeathRecord(p, result, journal, p.evidence, p.suspects))
  while #list > MAX_DEATHS do table.remove(list) end
end
