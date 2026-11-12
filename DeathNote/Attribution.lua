-- DeathNote - Attribution.lua
-- Own death -> killer, in stages (first usable one wins), and revenge detection.
--   a) death recap   (C_DeathRecap.GetRecapEvents / GetRecapLink)
--   b) damage meter  (C_DamageMeter, damage taken of the last session)
--   c) combat log    (only if the client still delivers it; switches itself off otherwise)
--   d) suspects      (exactly one hostile player had me targeted in the last 6 s -> suspicion)
-- The decision itself (Classify/Decide) is pure and has no WoW calls.

local ADDON, ns = ...
local Util = ns.Util
local Call, IsSecret, Str, Num = Util.Call, Util.IsSecret, Util.Str, Util.Num

local A = {}
ns.Attribution = A

A.DELAYS = { 0.5, 2, 4 }      -- read again after PLAYER_DEAD (recap/meter fill in late)
A.SUSPECT_WINDOW = 6          -- seconds: "had me targeted" before death
A.CANDIDATE_WINDOW = 20       -- seconds: shown as candidates in the journal
A.STALE_RECAP = 60            -- seconds: recap older than this belongs to an earlier death
A.REVENGE_ENGAGE = 15         -- seconds: "I was fighting him"
A.REVENGE_DEDUPE = 10         -- seconds: one kill reported by several events
A.DUEL_WINDOW = 30            -- seconds after a duel event in which a death counts as duel
A.PENDING_MAX = 10            -- seconds: an unfinished evaluation older than this is dropped
A.DEATH_DUEL_AFTER = 30       -- 1.3.0: seconds after a duel to the death in which the opponent's kill or death is the duel's
A.DEATH_DUEL_MAX = 900        -- 1.3.0: a duel to the death that never finished is let go after this long

---------------------------------------------------------------------------
-- Pure part
---------------------------------------------------------------------------
local function guidKind(guid)
  if type(guid) ~= "string" then return nil end
  local p = guid:match("^(%a+)%-")
  return p
end
A.GuidKind = guidKind

-- src: { guid, name, amount, kb, spell, isPet, isMob, class, ownerGUID }
-- ctx: { myGUID, myKey, lookupGUID(guid) -> info|nil, lookupName(name, surname) -> info|nil }
-- returns { key, info, isPlayer (true|false|nil), isPet, amount, kb, spell } or nil (self / nothing)
function A.Classify(src, ctx)
  if type(src) ~= "table" then return nil end
  local guid = Str(src.guid)
  local name = Str(src.name)
  if guid and ctx.myGUID and guid == ctx.myGUID then return nil end
  local out = { amount = tonumber(src.amount) or 0, kb = src.kb and true or false, spell = src.spell }
  local kind = guidKind(guid)
  local info
  if kind == "Player" then
    out.isPlayer = true
    info = ctx.lookupGUID and ctx.lookupGUID(guid)
    if not info and name then
      local n, s = Util.SplitFull(name)
      info = (ctx.lookupName and ctx.lookupName(n, s)) or { name = n, surname = s }
    end
    if info then
      info.guid = info.guid or guid
      if not info.class and src.class then info.class = src.class end
      -- The GUID lookup may know the first name only (GetPlayerInfoByGUID on Forever), while the
      -- recap names the source in full ("Name Surname", seen live 11.11.2026): take the surname from there.
      if not info.surname and name then
        local n, s = Util.SplitFull(name)
        if s and n == info.name then info.surname = s end
      end
    end
  elseif kind == "Pet" or kind == "Creature" or kind == "Vehicle" or kind == "GameObject" then
    out.isPlayer = false
    out.isPet = kind == "Pet" or src.isPet == true
    if out.isPet and src.ownerGUID then
      local owner = ctx.lookupGUID and ctx.lookupGUID(src.ownerGUID)
      if owner then out.ownerKey = Util.KeyFor(owner.name, owner.surname or owner.realm); out.ownerInfo = owner end
    end
    out.name = name
  else
    -- no usable GUID: the name alone is not enough, unless we saw the player
    if src.isPet then
      out.isPlayer, out.isPet = false, true
    elseif src.isMob then
      out.isPlayer = false
    elseif name then
      local n, s = Util.SplitFull(name)
      info = ctx.lookupName and ctx.lookupName(n, s)
      if info then
        out.isPlayer = true
      elseif src.class and src.isMob == false then
        -- damage meter: class file + not a mob = a player
        out.isPlayer = true
        info = { name = n, surname = s, class = src.class }
      end
    end
    out.name = name
  end
  if info then
    out.info = info
    out.key = Util.KeyFor(info.name, info.surname or info.realm)
    if out.isPlayer and not out.key then out.isPlayer = nil end
    if out.key and ctx.myKey and out.key == ctx.myKey then return nil end
  end
  if out.isPlayer and not out.key then out.isPlayer = nil end
  return out
end

local function playersOf(sources)
  local byKey, list = {}, {}
  for i = 1, #sources do
    local s = sources[i]
    if s.isPlayer and s.key then
      local p = byKey[s.key]
      if not p then
        p = { key = s.key, info = s.info, amount = 0, kb = false }
        byKey[s.key] = p
        list[#list + 1] = p
      end
      p.amount = p.amount + (s.amount or 0)
      if s.kb then p.kb = true; p.spell = s.spell end
      p.spell = p.spell or s.spell
    end
  end
  table.sort(list, function(a, b)
    if a.kb ~= b.kb then return a.kb end
    if a.amount ~= b.amount then return a.amount > b.amount end
    return a.key < b.key
  end)
  return list, byKey
end

local function keysExcept(list, skip)
  local out = {}
  for i = 1, #list do if list[i].key ~= skip then out[#out + 1] = list[i].key end end
  return out
end

-- stages: array of { stage = "recap"|"meter"|"combatlog", ok = bool, sources = { classified... } }
-- suspects: { targeters = { {key, info}... } (window 6 s), recent = { ... } (window 20 s) }
-- returns { kind, killerKey, killerInfo, sure, source, others = {keys}, othersInfo = {key->info},
--           candidates = {keys}, spell }
function A.Decide(stages, suspects, opts)
  opts = opts or {}
  for i = 1, #(stages or {}) do
    local st = stages[i]
    if st.ok and type(st.sources) == "table" and #st.sources > 0 then
      local players, byKey = playersOf(st.sources)
      local kb
      for j = 1, #st.sources do if st.sources[j].kb then kb = st.sources[j]; break end end
      local res = { source = st.stage, others = {}, candidates = {}, othersInfo = {} }
      for _, p in ipairs(players) do res.othersInfo[p.key] = p.info end
      if kb and kb.isPlayer and kb.key then
        local p = byKey[kb.key]
        res.kind, res.killerKey, res.killerInfo, res.sure, res.spell = "pvp", kb.key, p.info, true, kb.spell
        res.others = keysExcept(players, kb.key)
        res.candidates = keysExcept(players, nil)
        return res
      elseif kb and kb.isPet and kb.ownerKey then
        res.kind, res.killerKey, res.killerInfo, res.sure, res.spell = "pvp", kb.ownerKey, kb.ownerInfo, true, kb.spell
        res.othersInfo[kb.ownerKey] = kb.ownerInfo
        res.others = keysExcept(players, kb.ownerKey)
        res.candidates = keysExcept(players, nil)
        return res
      elseif kb and kb.isPet and #players > 0 then
        local top = players[1]
        res.kind, res.killerKey, res.killerInfo, res.sure, res.spell = "pvp", top.key, top.info, false, kb.spell
        res.others = keysExcept(players, top.key)
        res.candidates = keysExcept(players, nil)
        return res
      elseif kb and kb.isPet then
        -- a pet without a known owner: "Pet-" GUIDs belong to players' pets, so this is no
        -- PvE death; this stage cannot name the owner -> next stage / suspects decide
        res = nil
      elseif kb then
        -- killing blow by a creature / environment / someone we cannot identify
        res.kind = (kb.isPlayer == false) and "pve" or "unknown"
        res.spell = kb.spell
        res.candidates = keysExcept(players, nil)
        return res
      elseif #players > 0 then
        local top = players[1]
        res.kind, res.killerKey, res.killerInfo, res.sure, res.spell = "pvp", top.key, top.info, false, top.spell
        res.others = keysExcept(players, top.key)
        res.candidates = keysExcept(players, nil)
        return res
      elseif st.stage == "recap" then
        -- only the recap is trusted to say "no player involved"; meter/log may hold older fights
        local allMobs, pets = true, false
        for j = 1, #st.sources do
          local x = st.sources[j]
          if x.isPlayer ~= false then allMobs = false end
          if x.isPet then pets = true end
        end
        if not (allMobs and pets) then
          res.kind = allMobs and "pve" or "unknown"
          return res
        end
        -- only mobs and player pets (owner unknown): suspects may still name the killer
      end
    end
  end
  -- d) suspects
  local res = { source = nil, kind = "unknown", others = {}, candidates = {}, othersInfo = {} }
  if opts.suspect == false or not suspects then return res end
  local t = suspects.targeters or {}
  if #t == 1 then
    res.kind, res.source, res.killerKey, res.killerInfo, res.sure = "pvp", "suspect", t[1].key, t[1].info, false
    res.candidates = { t[1].key }
    res.othersInfo[t[1].key] = t[1].info
  elseif #t > 1 then
    res.kind, res.source = "pvp", "suspect"
    for i = 1, #t do res.candidates[#res.candidates + 1] = t[i].key; res.othersInfo[t[i].key] = t[i].info end
  else
    local r = suspects.recent or {}
    for i = 1, #r do res.candidates[#res.candidates + 1] = r[i].key; res.othersInfo[r[i].key] = r[i].info end
  end
  return res
end

-- Turns a Blizzard format string ("You have slain %s!") into a Lua pattern with captures.
function A.FormatToPattern(fmt)
  if type(fmt) ~= "string" or fmt == "" then return nil end
  local out, i, n = {}, 1, #fmt
  while i <= n do
    local c = fmt:sub(i, i)
    if c == "%" then
      local spec = fmt:match("^%%%d?%$?([sd])", i)
      if spec then
        local len = #fmt:match("^%%%d?%$?[sd]", i)
        out[#out + 1] = spec == "d" and "([%d%.,]+)" or "(.+)"
        i = i + len
      else
        out[#out + 1] = "%%"
        i = i + ((fmt:sub(i + 1, i + 1) == "%") and 2 or 1)
      end
    elseif c:find("[%^%$%(%)%.%[%]%*%+%-%?]") then
      out[#out + 1] = "%" .. c
      i = i + 1
    else
      out[#out + 1] = c
      i = i + 1
    end
  end
  return "^" .. table.concat(out) .. "$"
end

---------------------------------------------------------------------------
-- Probe helpers (markers instead of secrets)
---------------------------------------------------------------------------
local function mark(v)
  if IsSecret(v) then return "<secret>" end
  if v == nil then return nil end
  local t = type(v)
  if t == "string" or t == "number" or t == "boolean" then return v end
  return "<" .. t .. ">"
end
A.Mark = mark

---------------------------------------------------------------------------
-- Stage readers (WoW side, every access guarded)
---------------------------------------------------------------------------
local state = {
  lastRecapID = nil, lastRecapSig = nil,   -- recap already used (avoid blaming an old death)
  clog = {}, clogDead = false, clogFails = 0,
}
A.state = state

local function myGUID() return Str(Call(UnitGUID, "player")) end

local function recapLinkID()
  local C = _G.C_DeathRecap
  if not C or not C.GetRecapLink then return nil end
  local link = Call(C.GetRecapLink)
  link = Str(link)
  return link and tonumber(link:match("death:(%d+)")) or nil
end

local function meterRecapID()
  local DM, E = _G.C_DamageMeter, _G.Enum
  if not (DM and DM.GetCombatSessionFromType and E and E.DamageMeterType and E.DamageMeterType.Deaths) then return nil end
  local sessionType = (E.DamageMeterSessionType and E.DamageMeterSessionType.Current) or 1
  local s = Call(DM.GetCombatSessionFromType, sessionType, E.DamageMeterType.Deaths)
  if IsSecret(s) or type(s) ~= "table" then return nil end
  local list = s.combatSources
  if IsSecret(list) or type(list) ~= "table" then return nil end
  local me, best = myGUID(), nil
  for i = 1, math.min(#list, 40) do
    local src = list[i]
    if not IsSecret(src) and type(src) == "table" then
      local isMe = Util.True(src.isLocalPlayer)
      if not isMe and me then isMe = Str(src.sourceGUID) == me end
      local id = Num(src.deathRecapID)
      if isMe and id and id > 0 and (not best or id > best) then best = id end
    end
  end
  return best
end

-- Returns evidence { stage="recap", ok, why, stale, id, sig, sources = raw sources, raw = probe dump }
function A.ReadRecap()
  local ev = { stage = "recap", ok = false, sources = {}, raw = {} }
  local C = _G.C_DeathRecap
  if not (C and C.GetRecapEvents) then ev.why = "keine API"; return ev end
  local id = recapLinkID()
  ev.id = id
  local events = Call(C.GetRecapEvents)
  if not IsSecret(events) and (type(events) ~= "table" or #events == 0) then
    id = id or meterRecapID()
    ev.id = id
    if id then events = Call(C.GetRecapEvents, id) end
  end
  if IsSecret(events) then ev.why = "secret"; ev.raw.events = "<secret>"; return ev end
  if type(events) ~= "table" then ev.why = "leer"; return ev end
  local sig, newest, kbIdx, maxOverkill = {}, nil, nil, 0
  local n = #events
  for i = 1, math.min(n, 40) do
    local e = events[i]
    if not IsSecret(e) and type(e) == "table" then
      local guid, name = Str(e.sourceGUID), Str(e.sourceName)
      local amount, overkill, ts = Num(e.amount), Num(e.overkill), Num(e.timestamp)
      local hide = Util.True(e.hideCaster)
      local spell = Str(e.spellName)
      local spellId = Num(e.spellId)
      ev.raw[#ev.raw + 1] = { sourceGUID = mark(e.sourceGUID), sourceName = mark(e.sourceName), amount = mark(e.amount),
        overkill = mark(e.overkill), timestamp = mark(e.timestamp), spellName = mark(e.spellName),
        spellId = mark(e.spellId), hideCaster = mark(e.hideCaster), event = mark(e.event),
        environmentalType = mark(e.environmentalType) }
      sig[#sig + 1] = tostring(guid or name or "?") .. ":" .. tostring(amount or "?") .. ":" .. tostring(ts or "?")
      if ts and (not newest or ts > newest) then newest = ts end
      if overkill and overkill > maxOverkill then maxOverkill, kbIdx = overkill, i end
      ev.sources[#ev.sources + 1] = { guid = (not hide) and guid or nil, name = (not hide) and name or nil,
        amount = amount, spell = spell or spellId, ts = ts, idx = i, hidden = hide }
    else
      ev.raw[#ev.raw + 1] = "<secret>"
      sig[#sig + 1] = "secret"
    end
  end
  if #ev.sources == 0 then ev.why = (#sig > 0) and "secret" or "leer"; return ev end
  -- killing blow: overkill > 0, else the newest time stamp, else the first entry (Blizzard order)
  if not kbIdx then
    local newestIdx, newestTs
    for _, s in ipairs(ev.sources) do
      if s.ts and (not newestTs or s.ts > newestTs) then newestTs, newestIdx = s.ts, s.idx end
    end
    local allSame = true
    for _, s in ipairs(ev.sources) do if s.ts ~= newestTs then allSame = false end end
    kbIdx = (newestIdx and not allSame) and newestIdx or ev.sources[1].idx
  end
  for _, s in ipairs(ev.sources) do s.kb = (s.idx == kbIdx) end
  ev.sig = table.concat(sig, "|")
  ev.newest = newest
  if id and id == state.lastRecapID then
    ev.stale, ev.why = true, "alte Recap-ID"
  elseif ev.sig == state.lastRecapSig then
    ev.stale, ev.why = true, "gleiche Signatur wie zuvor"
  elseif newest and newest > 1000000000 and math.abs(time() - newest) > A.STALE_RECAP then
    ev.stale, ev.why = true, "Zeitstempel zu alt"
  end
  ev.ok = not ev.stale
  return ev
end

local function asList(t)
  if IsSecret(t) or type(t) ~= "table" then return {} end
  if t[1] ~= nil then return t end
  return { t }
end

function A.ReadMeter()
  local ev = { stage = "meter", ok = false, sources = {}, raw = {} }
  local DM, E = _G.C_DamageMeter, _G.Enum
  if not (DM and E and E.DamageMeterType and E.DamageMeterType.DamageTaken) then ev.why = "keine API"; return ev end
  local me = myGUID()
  if not me then ev.why = "eigene GUID unbekannt"; return ev end
  local sessionType = (E.DamageMeterSessionType and E.DamageMeterSessionType.Current) or 1
  local src
  if DM.GetCombatSessionSourceFromType then
    src = Call(DM.GetCombatSessionSourceFromType, sessionType, E.DamageMeterType.DamageTaken, me)
  end
  if IsSecret(src) then ev.why = "secret"; ev.raw.session = "<secret>"; return ev end
  if type(src) ~= "table" or IsSecret(src.combatSpells) or type(src.combatSpells) ~= "table" then
    ev.why = "keine Daten"; return ev
  end
  for i = 1, math.min(#src.combatSpells, 40) do
    local sp = src.combatSpells[i]
    if not IsSecret(sp) and type(sp) == "table" then
      local amount, overkill = Num(sp.totalAmount), Num(sp.overkillAmount)
      local deadly = Util.True(sp.isDeadly)
      for _, d in ipairs(asList(sp.combatSpellDetails)) do
        if not IsSecret(d) and type(d) == "table" then
          local isMob
          if Util.True(d.isMob) then isMob = true elseif Util.False(d.isMob) then isMob = false end
          local s = {
            name = Str(d.unitName) or Str(sp.creatureName), guid = Str(d.unitGUID) or Str(d.sourceGUID),
            class = Str(d.unitClassFilename), amount = Num(d.amount) or amount,
            isPet = Util.True(d.isPet),
            isMob = isMob,
            spell = Num(sp.spellID), kb = (overkill and overkill > 0) or deadly or false,
          }
          ev.sources[#ev.sources + 1] = s
          ev.raw[#ev.raw + 1] = { unitName = mark(d.unitName), class = mark(d.unitClassFilename), isMob = mark(d.isMob),
            isPet = mark(d.isPet), amount = mark(d.amount), overkill = mark(sp.overkillAmount), spellID = mark(sp.spellID) }
        else
          ev.raw[#ev.raw + 1] = "<secret>"
        end
      end
    else
      ev.raw[#ev.raw + 1] = "<secret>"
    end
  end
  -- several hits with overkill can't all be the killing blow: keep the biggest only
  local kbCount = 0
  for _, s in ipairs(ev.sources) do if s.kb then kbCount = kbCount + 1 end end
  if kbCount > 1 then for _, s in ipairs(ev.sources) do s.kb = false end end
  ev.ok = #ev.sources > 0
  if not ev.ok then ev.why = ev.why or "leer" end
  return ev
end

-- Combat log ring buffer (only damage to me), filled by the CLEU handler below.
function A.ReadCombatLog(deathGT)
  local ev = { stage = "combatlog", ok = false, sources = {}, raw = {} }
  if state.clogDead then ev.why = "Combat-Log liefert nichts"; return ev end
  if not state.clogOn then ev.why = "nicht registriert"; return ev end
  local maxOk, kbIdx = 0, nil
  for i = 1, #state.clog do
    local c = state.clog[i]
    if deathGT - c.gt <= 10 and c.gt <= deathGT + 1 then
      local s = { guid = c.guid, name = c.name, amount = c.amount, spell = c.spell, idx = i }
      ev.sources[#ev.sources + 1] = s
      if c.overkill and c.overkill > maxOk then maxOk, kbIdx = c.overkill, #ev.sources end
      ev.raw[#ev.raw + 1] = { sub = c.sub, guid = c.guid, name = c.name, amount = c.amount, overkill = c.overkill }
    end
  end
  if #ev.sources > 0 then
    ev.sources[kbIdx or #ev.sources].kb = true
    ev.ok = true
  else
    ev.why = "keine Treffer"
  end
  return ev
end

local DAMAGE_SUB = { SWING_DAMAGE = 1, RANGE_DAMAGE = 2, SPELL_DAMAGE = 2, SPELL_PERIODIC_DAMAGE = 2,
  SPELL_BUILDING_DAMAGE = 2, DAMAGE_SHIELD = 2, DAMAGE_SPLIT = 2 }

local function onCombatLog()
  local r = { pcall(_G.CombatLogGetCurrentEventInfo) }
  local ok, ts, sub, _, sGUID, sName, _, _, dGUID = r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9]
  if not ok or IsSecret(ts) or IsSecret(sub) or IsSecret(dGUID) or ts == nil then
    state.clogFails = state.clogFails + 1
    if state.clogFails >= 5 then
      state.clogDead = true
      ns:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    end
    return
  end
  state.clogFails = 0
  if dGUID ~= state.myGUID then return end
  local kind = DAMAGE_SUB[sub]
  if not kind then return end
  local amount, overkill, spell
  if kind == 1 then
    amount, overkill = r[13], r[14]
  else
    spell, amount, overkill = r[14], r[16], r[17]
  end
  local c = { gt = GetTime(), sub = sub, guid = Str(sGUID), name = Str(sName), amount = Num(amount),
    overkill = Num(overkill), spell = Str(spell) }
  local log = state.clog
  log[#log + 1] = c
  if #log > 20 then table.remove(log, 1) end
end

---------------------------------------------------------------------------
-- Lookups for Classify
---------------------------------------------------------------------------
local function infoFromEntry(e)
  return { name = e.name, surname = e.surname, realm = e.realm, guid = e.guid, class = e.class, race = e.race,
    level = e.level, guild = e.guild, faction = e.faction, classLoc = e.classLoc, raceLoc = e.raceLoc, sex = e.sex }
end

local function infoFromRecord(r)
  return { name = r.name, surname = r.surname, guid = r.guid, class = r.class, classLoc = r.classLoc,
    race = r.race, raceLoc = r.raceLoc, sex = r.sex, level = r.level, guild = r.guild, faction = r.faction }
end
A.InfoFromRecord = infoFromRecord

-- A first-name match is only the same player when it has no GUID yet or the same one
-- (first names are not unique on Forever).
local function guidFits(known, guid)
  return known == nil or known == guid
end

local function lookupGUID(guid)
  local Store, Tracker = ns.Store, ns.Tracker
  local r = Tracker and Tracker.ByGUID(guid)
  if r then return infoFromRecord(r) end
  local key = Store and Store.ByGUID(guid)
  if key then return infoFromEntry(Store.Get(key)) end
  -- GetPlayerInfoByGUID gives the first name only (no surname) on Forever
  local _, class, _, race, sex, name = Call(_G.GetPlayerInfoByGUID, guid)
  name = Str(name)
  if name then
    local found = Store and Store.Find(name)
    local fe = found and Store.Get(found)
    if fe and guidFits(fe.guid, guid) then
      local info = infoFromEntry(fe)
      info.guid = guid
      return info
    end
    local rec = Tracker and Tracker.ByName(name)
    if rec and guidFits(rec.guid, guid) then
      local info = infoFromRecord(rec)
      info.guid = guid
      return info
    end
    return { name = name, guid = guid, class = Str(class), race = Str(race), sex = Num(sex) }
  end
  return nil
end

local function lookupName(name, surname)
  local Store, Tracker = ns.Store, ns.Tracker
  local r = Tracker and Tracker.ByName(name, surname)
  if r then return infoFromRecord(r) end
  local key = Store and Store.Find(name, surname)
  if key then return infoFromEntry(Store.Get(key)) end
  return nil
end

function A.Context()
  local name, second = Call(UnitName, "player")
  return {
    myGUID = myGUID(),
    myKey = (not IsSecret(name) and not IsSecret(second)) and Util.KeyFor(name, second) or nil,
    lookupGUID = lookupGUID,
    lookupName = lookupName,
  }
end

---------------------------------------------------------------------------
-- Death flow
---------------------------------------------------------------------------
local pending
local duelAt          -- GetTime of a duel request/start, cleared when the duel ends
-- a declined request sends no DUEL_FINISHED: the window is short (deaths in a duel itself
-- do not happen, the duel ends at 1 HP; this only covers dying to someone else meanwhile)
local function inDuel() return duelAt ~= nil and GetTime() - duelAt < A.DUEL_WINDOW end

-- 1.3.0: a duel to the death ends with a real death, which is no world PvP. Only the opponent is held out (a third
-- player who kills one of us meanwhile still counts): his death by me is no revenge, no rap sheet kill and no "taken
-- down"; my death by him is no deed in the book. The opponent comes from DUEL_TO_THE_DEATH_REQUESTED (the
-- challenger's name; GetDuelerInfo for the GUID where the client has it) or from my own StartDuel(target, _, true).
-- Event, GetDuelerInfo and the third StartDuel argument are read this way by an addon on the same client; unmeasured
-- here (/dn probe: probe.kills.deathDuel).
local deathDuel   -- { first = lower first name, guid, at, ended } (GetTime)

local function firstName(n)
  n = Str(n)
  if not n then return nil end
  n = n:match("^([^%s%-]+)") or n
  return n:lower()
end

function A.OnDeathDuel(name, guid)
  local first = firstName(name)
  if not guid then
    guid = Str(Call(_G.GetDuelerInfo))
    if guid and not guid:find("^Player%-") then guid = nil end
  end
  if not first and not guid then return false end
  local d = deathDuel
  -- the game may send both challenges for one duel: the same opponent keeps his record
  if d and not d.ended and ((guid and d.guid == guid) or (first and d.first == first)) then
    d.guid, d.first = d.guid or guid, d.first or first
    return true
  end
  deathDuel = { first = first, guid = guid, at = GetTime() }
  return true
end

-- my own challenge: StartDuel(unit or name, _, toTheDeath)
function A.OnStartDuel(target, _, toTheDeath)
  if not Util.True(toTheDeath) then return end
  local unit = Str(target) or "target"
  local guid, name
  if Util.True(Call(_G.UnitExists, unit)) then
    guid = Str(Call(_G.UnitGUID, unit))
    name = Call(_G.UnitName, unit)
  end
  A.OnDeathDuel(Str(name) or Str(target), guid)
end

-- is this player (GUID, or first name when the GUID is not known) the opponent of a duel to the death that is
-- under way or ended at most DEATH_DUEL_AFTER seconds ago?
function A.DuelFoe(guid, name)
  local d = deathDuel
  if not d then return false end
  local t = GetTime()
  if (d.ended and t - d.ended > A.DEATH_DUEL_AFTER) or (not d.ended and t - d.at > A.DEATH_DUEL_MAX) then
    deathDuel = nil
    return false
  end
  guid = Str(guid)
  if guid and d.guid then return guid == d.guid end
  local first = firstName(name)
  if not first and guid then
    local _, _, _, _, _, n = Call(_G.GetPlayerInfoByGUID, guid)
    first = firstName(n)
  end
  return first ~= nil and first == d.first
end

-- for /dn probe: the state without names
function A.DeathDuelState()
  local d = deathDuel
  if not d then return nil end
  return { guid = d.guid ~= nil, name = d.first ~= nil, ago = math.floor(GetTime() - d.at), ended = d.ended and
    math.floor(GetTime() - d.ended) or nil }
end

local function stageOn(name)
  local v = ns.Store and ns.Store.Setting("attribution." .. name)
  return v ~= false
end

local function snapshotSuspects(deathGT)
  local Tracker = ns.Tracker
  local out = { targeters = {}, recent = {} }
  if not Tracker then return out end
  for _, r in ipairs(Tracker.Targeters(A.SUSPECT_WINDOW, deathGT)) do
    out.targeters[#out.targeters + 1] = { key = r.key, info = infoFromRecord(r), ago = deathGT - r.targetedMe }
  end
  for _, r in ipairs(Tracker.Targeters(A.CANDIDATE_WINDOW, deathGT)) do
    out.recent[#out.recent + 1] = { key = r.key, info = infoFromRecord(r), ago = deathGT - r.targetedMe }
  end
  return out
end

local function classifyAll(ev, ctx)
  local out = { stage = ev.stage, ok = ev.ok, why = ev.why, sources = {} }
  if not ev.ok then return out end
  for _, s in ipairs(ev.sources) do
    local c = A.Classify(s, ctx)
    if c then out.sources[#out.sources + 1] = c end
  end
  return out
end

local CANDIDATE_FIELDS = { "name", "surname", "guid", "class", "classLoc", "race", "raceLoc", "level", "guild", "faction" }

-- Identity of the candidates as known at death time (plain values only), so that a later
-- AssignDeath can create a full entry for someone who is not in the book.
local function candidateInfo(result)
  local out
  local infos = result.othersInfo
  if type(infos) ~= "table" then return nil end
  for _, k in ipairs(result.candidates or {}) do
    local info = infos[k]
    if type(info) == "table" then
      local c = {}
      for i = 1, #CANDIDATE_FIELDS do
        local f = CANDIDATE_FIELDS[i]
        local v = info[f]
        if not IsSecret(v) and (type(v) == "string" or type(v) == "number") then c[f] = v end
      end
      if c.name then out = out or {}; out[k] = c end
    end
  end
  return out
end

local function finalize(p, result)
  local Store = ns.Store
  if not Store then return end
  local counted = p.openWorld and not p.duel
  -- 1.3.0: killed by the opponent of a duel to the death: the duel's death, no deed in the book
  local ki = result.killerInfo
  if counted and result.killerKey and type(ki) == "table" and A.DuelFoe(ki.guid, ki.name) then
    counted, p.deathDuel = false, true
  end
  local journal = {
    t = p.t, zone = p.zone, subzone = p.subzone, mapID = p.mapID, x = p.x, y = p.y,
    me = p.me, myLevel = p.myLevel, kind = result.kind or "unknown",
    sure = result.sure or false, source = result.source, candidates = result.candidates or {},
    spell = result.spell, counted = counted, candidateInfo = candidateInfo(result),
  }
  if not counted and journal.kind == "pvp" then journal.kind = "unknown" end
  local fired
  if counted then
    local rec = {
      t = p.t, zone = p.zone, subzone = p.subzone, mapID = p.mapID, x = p.x, y = p.y, me = p.me,
      myLevel = p.myLevel, spell = result.spell, source = result.source, others = result.others,
    }
    if result.killerKey and result.killerInfo then
      local rLevel = result.killerInfo.level
      rec.theirLevel = type(rLevel) == "number" and rLevel or nil
      local key = Store.ApplyKill(result.killerInfo, rec, result.sure)
      if key then
        journal.killerKey = key
        journal.killerName = Util.Display(Store.Get(key))
        fired = key
      end
    end
    -- co-attackers: in the recap their damage is proven -> role "assist" (Store.ApplyKill);
    -- from the other stages (meter may hold an older fight) only "suspect"
    for _, k in ipairs(result.others or {}) do
      local info = result.othersInfo and result.othersInfo[k]
      if info then
        local orec = {}
        for kk, v in pairs(rec) do orec[kk] = v end
        orec.others = { journal.killerKey }
        orec.theirLevel = type(info.level) == "number" and info.level or nil
        Store.ApplyKill(info, orec, false)
      end
    end
  end
  Store.RecordDeath(journal)
  A.last = { p = p, journal = journal, evidence = p.evidence, suspects = p.suspects, result = result }
  if Store.Setting("debug") and ns.Probe and ns.Probe.RecordDeath then
    ns.Probe.RecordDeath(p, result, journal)
  end
  ns:Fire("DEATH_RECORDED", journal, fired)
end

local stageErrorShown = {}
-- One stage reader; an error in it costs only this stage (reported once per session).
local function readStage(name, fn, arg)
  local ok, ev = pcall(fn, arg)
  if ok and type(ev) == "table" then return ev end
  if not stageErrorShown[name] then
    stageErrorShown[name] = true
    ns.ReportError(ok and ("stage " .. name .. ": no result") or ev)
  end
  return { stage = name, ok = false, why = "Fehler", sources = {}, raw = {} }
end

local attempt
-- Timer entry: whatever goes wrong, `pending` is released and the death is still journaled.
local function runAttempt(p)
  local ok, err = pcall(attempt, p)
  if ok then return end
  ns.ReportError(err)
  if pending == p then
    pending = nil
    pcall(finalize, p, { kind = "unknown", candidates = {}, others = {}, othersInfo = {} })
  end
end

function attempt(p)
  if pending ~= p then return end
  p.tries = p.tries + 1
  local final = p.tries >= #A.DELAYS
  local ctx = A.Context()
  local stages, evidence = {}, {}
  local staleRecap = false
  if stageOn("recap") then
    local ev = readStage("recap", A.ReadRecap)
    evidence[#evidence + 1] = ev
    if ev.stale then staleRecap = true end
    stages[#stages + 1] = classifyAll(ev, ctx)
  end
  if stageOn("meter") then
    local ev = readStage("meter", A.ReadMeter)
    evidence[#evidence + 1] = ev
    stages[#stages + 1] = classifyAll(ev, ctx)
  end
  if stageOn("combatlog") then
    local ev = readStage("combatlog", A.ReadCombatLog, p.gt)
    evidence[#evidence + 1] = ev
    stages[#stages + 1] = classifyAll(ev, ctx)
  end
  p.evidence = evidence
  local result = A.Decide(stages, p.suspects, { suspect = stageOn("suspect") })
  local decisive = result.source and result.source ~= "suspect"
  if not decisive and not final then
    if _G.C_Timer and _G.C_Timer.After then
      _G.C_Timer.After(A.DELAYS[p.tries + 1] - A.DELAYS[p.tries], function() runAttempt(p) end)
      return
    end
  end
  -- the recap that was used (or read) now belongs to this death
  for _, ev in ipairs(evidence) do
    if ev.stage == "recap" and ev.sig and not ev.stale then
      state.lastRecapSig, state.lastRecapID = ev.sig, ev.id or state.lastRecapID
    end
  end
  p.staleRecap = staleRecap
  pending = nil
  finalize(p, result)
end

function A.OnPlayerDead()
  local t = GetTime()
  -- never stuck: an evaluation that did not finish in time is dropped
  if pending and t - (pending.gt or 0) > A.PENDING_MAX then pending = nil end
  if pending or (A.lastDeathGT and t - A.lastDeathGT < 5) then return end
  A.lastDeathGT = t
  state.myGUID = myGUID()
  if ns.Tracker then ns.Tracker.ScanAll() end
  local zone, sub, mapID, x, y = Util.Zone()
  local me, second = Call(UnitName, "player")
  local level = Num(Call(UnitLevel, "player"))
  local p = {
    t = time(), gt = t, zone = zone, subzone = sub, mapID = mapID, x = x, y = y,
    me = Str(me) and (Str(second) and (me .. " " .. second) or me) or nil, myLevel = level,
    openWorld = Util.IsOpenWorld(), duel = inDuel(), tries = 0,
  }
  p.suspects = snapshotSuspects(t)
  pending = p
  if _G.C_Timer and _G.C_Timer.After then
    _G.C_Timer.After(A.DELAYS[1], function() runAttempt(p) end)
  else
    runAttempt(p)
  end
end

function A.Pending() return pending end

---------------------------------------------------------------------------
-- Revenge
---------------------------------------------------------------------------
local lastRevenge = {}
local patterns

local function getPatterns()
  if patterns then return patterns end
  patterns = {
    slain = A.FormatToPattern(_G.SELFKILLOTHER),
    dies = A.FormatToPattern(_G.UNITDIESOTHER),
    honor = A.FormatToPattern(_G.COMBATLOG_HONORGAIN),
  }
  return patterns
end

local function engaged(key, window, onlyMine)
  local Tracker = ns.Tracker
  -- my current target: a long fight on the same target has no fresh target change
  if Tracker and Tracker.Identity and Tracker.Identity("target") == key then return true end
  local r = Tracker and Tracker.Get(key)
  if not r then return false end
  local t = GetTime()
  if r.iTargeted and t - r.iTargeted <= window then return true end
  if not onlyMine and r.targetedMe and t - r.targetedMe <= window then return true end
  return false
end

-- Credits a revenge kill (deduplicated). Returns true when counted.
function A.Revenge(key, how)
  local Store = ns.Store
  if not (Store and key and Store.Get(key)) then return false end
  if not Util.IsOpenWorld() then return false end
  -- 1.3.0: the opponent of a duel to the death
  local e = Store.Get(key)
  if A.DuelFoe(e.guid, e.name) then return false end
  local t = GetTime()
  if lastRevenge[key] and t - lastRevenge[key] < A.REVENGE_DEDUPE then return false end
  lastRevenge[key] = t
  A.lastRevengeHow = how
  return Store.AddRevenge(key)
end

local function keyForGUID(guid)
  local Store = ns.Store
  local key = Store and Store.ByGUID(guid)
  if key then return key end
  local r = ns.Tracker and ns.Tracker.ByGUID(guid)
  if r and Store.Get(r.key) then return r.key end
  local _, _, _, _, _, name = Call(_G.GetPlayerInfoByGUID, guid)
  name = Str(name)
  if name then
    local found = Store.Find(name)
    local e = found and Store.Get(found)
    if e and guidFits(e.guid, guid) then return found end
  end
  return nil
end

function A.OnPartyKill(attackerGUID, targetGUID)
  attackerGUID, targetGUID = Str(attackerGUID), Str(targetGUID)
  if not attackerGUID or not targetGUID or guidKind(targetGUID) ~= "Player" then return false end
  local me, pet = myGUID(), Str(Call(UnitGUID, "pet"))
  if attackerGUID ~= me and attackerGUID ~= pet then return false end
  local key = keyForGUID(targetGUID)
  if key then return A.Revenge(key, "partykill") end
  return false
end

local function nameToListed(text)
  local Store = ns.Store
  if not text then return nil end
  local n, s = Util.SplitFull(text)
  return Store and Store.Find(n, s)
end

function A.OnHostileDeath(text)
  text = Str(text)
  if not text then return false end
  -- every mob death in sight lands here: nothing to look up while the list is empty
  local Store = ns.Store
  if not Store or next(Store.All()) == nil then return false end
  local P = getPatterns()
  local who = P.slain and text:match(P.slain)
  if who then
    local key = nameToListed(who)
    if key then return A.Revenge(key, "slain") end
    return false
  end
  who = P.dies and text:match(P.dies)
  if who then
    local key = nameToListed(who)
    if key and engaged(key, A.REVENGE_ENGAGE, true) then return A.Revenge(key, "dies") end
  end
  return false
end

function A.OnHonorGain(text)
  text = Str(text)
  local P = getPatterns()
  if not text or not P.honor then return false end
  local who = text:match(P.honor)
  local key = who and nameToListed(who)
  if key and engaged(key, A.REVENGE_ENGAGE) then return A.Revenge(key, "honor") end
  return false
end

-- PLAYER_PVP_KILLS_CHANGED: no victim given; counts only when exactly one listed enemy was engaged.
function A.OnPvPKillsChanged()
  local Store, Tracker = ns.Store, ns.Tracker
  if not (Store and Tracker) then return false end
  local found
  for _, r in ipairs(Tracker.Recent(A.REVENGE_ENGAGE)) do
    if Store.Get(r.key) and engaged(r.key, 10) then
      if found then return false end
      found = r.key
    end
  end
  if found then return A.Revenge(found, "pvpkills") end
  return false
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------
function A.Setup()
  -- remember the recap present at login (/reload) so it is not blamed on the next death
  local ev = A.ReadRecap()
  if ev.sig then state.lastRecapSig, state.lastRecapID = ev.sig, ev.id end
  state.myGUID = myGUID()
  -- combat log: only if the client offers it; disables itself when it delivers nothing
  if stageOn("combatlog") and type(_G.CombatLogGetCurrentEventInfo) == "function" and not state.clogOn then
    state.clogOn = ns:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", onCombatLog)
  end
end

ns:On("READY", A.Setup)
ns:RegisterEvent("PLAYER_DEAD", function() A.OnPlayerDead() end)
ns:RegisterEvent("PARTY_KILL", function(_, a, t) A.OnPartyKill(a, t) end)
ns:RegisterEvent("CHAT_MSG_COMBAT_HOSTILE_DEATH", function(_, text) A.OnHostileDeath(text) end)
ns:RegisterEvent("CHAT_MSG_COMBAT_HONOR_GAIN", function(_, text) A.OnHonorGain(text) end)
ns:RegisterEvent("PLAYER_PVP_KILLS_CHANGED", function() A.OnPvPKillsChanged() end)
ns:RegisterEvent("DUEL_REQUESTED", function() duelAt = GetTime() end)
ns:RegisterEvent("DUEL_INBOUNDS", function() duelAt = GetTime() end)
ns:RegisterEvent("DUEL_TO_THE_DEATH_REQUESTED", function(_, name) A.OnDeathDuel(name) end)
if type(_G.hooksecurefunc) == "function" and type(_G.StartDuel) == "function" then
  pcall(_G.hooksecurefunc, "StartDuel", function(...) pcall(A.OnStartDuel, ...) end)
end
ns:RegisterEvent("DUEL_FINISHED", function()
  if deathDuel and not deathDuel.ended then deathDuel.ended = GetTime() end
  if _G.C_Timer and _G.C_Timer.After then _G.C_Timer.After(1, function() duelAt = nil end) else duelAt = nil end
end)
