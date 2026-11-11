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
  "Ambiguate",
}

-- COMBAT_LOG_EVENT_UNFILTERED is not in this list: the client closes it to addons and an
-- attempt to register it is only made on an explicit "/dn probe combatlog".
Probe.EVENTS = {
  "PARTY_KILL", "UNIT_DIED", "PLAYER_DEAD", "CHAT_MSG_COMBAT_HOSTILE_DEATH",
  "CHAT_MSG_COMBAT_HONOR_GAIN", "PLAYER_PVP_KILLS_CHANGED", "NAME_PLATE_UNIT_ADDED", "UNIT_TARGET",
  "PLAYER_FOCUS_CHANGED", "UPDATE_MOUSEOVER_UNIT", "DUEL_REQUESTED", "DUEL_FINISHED",
  "CHAT_MSG_ADDON", "PLAYER_GUILD_UPDATE", "ADDON_RESTRICTION_STATE_CHANGED",
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
      queue = G.QueueSize(), inGuild = G.Name() ~= nil, enabled = G.Enabled(),
      enemies = enemies, deeds = deeds, members = #G.Members(),
      -- 1.1.0: names listed by hand (M) and taken off again (X)
      listedOnly = listedOnly, shareManual = G.Setting("shareManual") == true,
      foreign = foreign, health = h.reason, healthDetail = h.detail,
      listSent = st.listSent, listReceived = st.listReceived, listDropped = st.listDropped,
      unlistSent = st.unlistSent, unlistReceived = st.unlistReceived, unlistDropped = st.unlistDropped,
    }
  end
  if db then
    local keep = db.probe and db.probe.deaths
    db.probe = out
    out.deaths = keep or {}
  end
  if verbose then
    Util.Print(("Sonde: %d/%d Schnittstellen da, %d/%d Ereignisse registrierbar."):format(
      present, #Probe.APIS, #events - #evNo, #events))
    if #missing > 0 then Util.Print("Fehlt: ", table.concat(missing, ", ")) end
    if #evNo > 0 then Util.Print("Nicht registrierbar: ", table.concat(evNo, ", ")) end
    Util.Print("Recap jetzt: ", out.recapNow and (out.recapNow.ok and "lesbar" or tostring(out.recapNow.why)) or "?",
      " · Meter: ", out.meterNow and (out.meterNow.ok and "lesbar" or tostring(out.meterNow.why)) or "?",
      " · Combat-Log: ", out.combatlog and (out.combatlog.dead and "tot" or (out.combatlog.on and "an" or "aus")) or "?")
    Util.Print("Feindliche Namensplaketten: ", out.nameplatesOn and "an" or "AUS (nur Ziel/Maus erkennen Feinde)",
      " · Offene Welt: ", out.openWorld and "ja" or "nein")
    if out.target then
      Util.Print("Ziel: Name=", out.target.name, " GUID=", out.target.guid, " Klasse=", out.target.class,
        " feindlich=", out.target.enemy, " zielt auf mich=", out.target.targetsMe)
    end
    if out.guild then
      local g = out.guild
      Util.Print("Gilde: Präfix ", g.prefixOK and "registriert" or ("NICHT registriert (" .. tostring(g.prefixResult) .. ")"),
        " · Senden ", g.canSend and "möglich" or "fehlt", " · letzter Rückgabewert ", tostring(g.lastSendResult),
        " · gesendet ", g.sent or 0, ", empfangen ", g.received or 0, ", verworfen ", g.dropped or 0,
        g.holdNow and (" · wartet: " .. g.holdNow) or "")
      Util.Print("Hand-Einträge (M): gesendet ", g.listSent or 0, ", empfangen ", g.listReceived or 0,
        ", verworfen ", g.listDropped or 0, " · gestrichen (X): gesendet ", g.unlistSent or 0,
        ", empfangen ", g.unlistReceived or 0, ", verworfen ", g.unlistDropped or 0)
    end
    if out.guild and out.guild.health then
      local h = G and G.Health and G.Health()
      if h and h.text then Util.Print("Gildenbuch: ", h.text, h.detail and (" (" .. h.detail .. ")") or "") end
    end
    Util.Print("Gespeichert in DeathNoteDB.probe (nach /reload in der Datei).")
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
