-- DeathNote - Scene.lua (1.5.0 scene)
-- Crime scenes: which places of the book belong on the world map, filtered and bundled. Data and words only; the pins
-- on the map are SceneMap.lua (loaded after the book), the links in the book are UI.lua.
--
-- A scene is one place with a story:
--   "death"   my own death (journal, kind "pvp"): "Here <killer> killed you" (without a sure killing blow: "Here you
--             died; suspicion: <name>")
--   "kill"    my own kill on a player of the book or a revenge (rap sheet log): "Here you took down <name>"
--   "guild"   a guildmate's death, "friend" a friend's death (1.5.0: the sender's spot comes with message L, Sync.lua):
--             "Here <mate> was killed by <killer>"
--   "call"    1.6.0 call: a help call of a guildmate, group member or friend (Call.lua), pulsing for 3 minutes
--   "sight"   1.6.0 call: a killer seen by a guildmate or friend (message T), for 10 minutes
-- A scene needs a map ID and x/y (percent of the map, as Util.Zone stores them). Older entries without them have no
-- pin; with a map ID only, a click in the book opens the zone's map ("exact spot unknown").
-- Attacks (grudge), suspicions without a death, notes and anything taken over never become a scene of their own.
--
-- Settings (settings.scene, absent = default): on (true), days (30; 7, 30 or 0 = all), open (false: only enemies who
-- still lead against me), own, guild, friends (true: which kinds of pins). Read with Scene.Setting.

local ADDON, ns = ...
local L, Fmt = ns.L, ns.F
local Util = ns.Util
local IsSecret = Util.IsSecret

local Scene = {}
ns.Scene = Scene

Scene.DEFAULTS = { on = true, days = 30, open = false, own = true, guild = true, friends = true }
Scene.DAYS = { 7, 30, 0 }        -- the period's steps (0 = all)
Scene.FRESH = 600                -- seconds: a mate's death this young pulses on the map ("go and help")
-- bundling: two scenes whose pins would cover each other are one pin with a count. 1.5.0 fixer: measured in pixels of
-- the shown map (SceneMap passes the pin's size as percent of the canvas, rx and ry: it changes with the canvas scale),
-- so pins never cover each other at any map size. Without a map (tests, the probe) the pin of 28 px on the zone map of
-- 1002 x 668 px at scale 1: 2.8 % of the width, 4.2 % of the height.
Scene.RX, Scene.RY = 2.8, 4.2
-- at most this many pins per map. Measured on the stand-in map (tests/ui/scene_map.lua, 1002 x 668 px, pins 24 px):
-- 40 pins at the bundling radius cover about a fifth of a zone map; more makes the map unreadable. The scenes behind
-- them are not lost: the oldest go first (newest scenes are bundled first) and the count says how many were left out.
Scene.MAX_PINS = 40
Scene.MAX_ITEMS = 200            -- scenes per map looked at (journal 100 + log 60 + mates); a guard, not a choice
Scene.FOCUS = 15                 -- seconds a scene shown from the book stays on the map whatever the filter says
Scene.MAP_MAX = 100000           -- plausible map IDs (Forever: 947 .. 2548 measured)

local function num(v) return type(v) == "number" and v == v and v > -math.huge and v < math.huge and not IsSecret(v) end
local function str(v) return type(v) == "string" and not IsSecret(v) and v ~= "" and v or nil end

-- counters for the probe (probe.scene): never names
Scene.counts = { pins = 0, bundles = 0, clicks = 0, combat = 0, noCoords = 0, noMap = 0, errors = 0, hidden = 0,
  placeSent = 0, placeReceived = 0, placeDropped = 0, placeReasons = {}, refreshes = 0, deferred = 0 }

function Scene.Now() return time() end

function Scene.Count(name, n)
  local c = Scene.counts
  c[name] = (c[name] or 0) + (n or 1)
end
-- a pcall error in the map code: counted, never shown (the book, the alarm and the death detection go on)
function Scene.Error(where)
  Scene.Count("errors")
  Scene.counts.lastError = type(where) == "string" and where:sub(1, 60) or nil
end

function Scene.Setting(name)
  local v = ns.Store and ns.Store.Setting and ns.Store.Setting("scene." .. name)
  if v == nil then return Scene.DEFAULTS[name] end
  return v
end

-- a place the map can show: map ID a positive whole number, x/y within 0..100
function Scene.ValidSpot(mapID, x, y)
  if not (num(mapID) and mapID >= 1 and mapID <= Scene.MAP_MAX and mapID == math.floor(mapID)) then return false end
  if not (num(x) and num(y)) then return false end
  return x >= 0 and x <= 100 and y >= 0 and y <= 100
end
function Scene.ValidMap(mapID)
  return num(mapID) and mapID >= 1 and mapID <= Scene.MAP_MAX and mapID == math.floor(mapID) or false
end

-- the period as a word ("30 days", "all") and one step of it (House Rules, the map's switch)
function Scene.DaysWord(days)
  days = tonumber(days) or 30
  if days <= 0 then return L.SCENE_DAYS_ALL end
  return Fmt(L.SET_EXPIRE_DAYS, { count = days })
end
function Scene.StepDays(dir)
  local list, cur, idx = Scene.DAYS, tonumber(Scene.Setting("days")) or 30, 2
  for i, d in ipairs(list) do if d == cur then idx = i end end
  idx = (idx - 1 + (dir or 1)) % #list + 1
  if ns.Store and ns.Store.Setting then ns.Store.Setting("scene.days", list[idx]) end
  return list[idx]
end

-- the shown name of a book key: the entry's full name, else the fallback (a name noted at the time), else nil.
-- Never a key ("Name-Realm"): a key alone gives no name.
function Scene.NameOf(key, fallback)
  local S = ns.Store
  local e = S and type(key) == "string" and S.Get(key)
  if e then return Util.Display(e), e.class end
  fallback = str(fallback)
  if fallback and not (type(key) == "string" and fallback == key) then return fallback end
  return nil
end

local function myName()
  local ok, n = pcall(Util.PlayerFullName)
  return ok and str(n) or nil
end

-- every scene of the book, unfiltered (also the ones without a spot: spot = false). now = time().
-- fixer 2 1.6.0 (je03): the part from the book (my deaths, my kills, deaths of guild and friends) is collect(); the
-- part that depends on the time (a mate's death "fresh", calls and sightings) is added per call.
local function collect()
  local out = {}
  local S = ns.Store
  if not S then return out end
  -- my deaths
  local deaths = S.Deaths and S.Deaths() or {}
  for i = 1, #deaths do
    local j = deaths[i]
    if type(j) == "table" and j.kind == "pvp" and j.counted ~= false and num(j.t) then
      local name, class = Scene.NameOf(j.killerKey, j.killerName)
      out[#out + 1] = { kind = "death", t = j.t, mapID = j.mapID, x = j.x, y = j.y, zone = j.zone, subzone = j.subzone,
        key = j.killerKey, name = name, class = class, spell = str(j.spell), ref = j, suspect = j.sure == false,
        spot = Scene.ValidSpot(j.mapID, j.x, j.y) }
    end
  end
  -- my kills (rap sheet log): on a player of the book, or a revenge
  local Lg = ns.Ledger
  if Lg and Lg.Log then
    local ok, log = pcall(Lg.Log)
    for i = 1, ok and type(log) == "table" and #log or 0 do
      local row = log[i]
      if type(row) == "table" and num(row.t) and type(row.key) == "string" then
        local revenge = type(row.f) == "string" and row.f:find("v", 1, true) ~= nil
        local e = S.Get(row.key)
        if e or revenge then
          local v = Lg.Victim and Lg.Victim(row.key)
          out[#out + 1] = { kind = "kill", t = row.t, mapID = row.mapID, x = row.x, y = row.y, zone = row.zone,
            key = row.key, name = e and Util.Display(e) or str(row.name), class = (e and e.class) or (v and v.class),
            revenge = revenge, ref = row, spot = Scene.ValidSpot(row.mapID, row.x, row.y) }
        end
      end
    end
  end
  -- deaths of guildmates and friends (not mine: those are in the journal)
  local G = ns.Guild
  if G and G.List then
    local mine = myName()
    local seen = {}
    for _, src in ipairs({ "guild", "friends" }) do
      local ok, list = pcall(G.List, "recent", { source = src })
      for i = 1, ok and type(list) == "table" and #list or 0 do
        local g = list[i]
        for k = 1, #(type(g) == "table" and type(g.deeds) == "table" and g.deeds or {}) do
          local d = g.deeds[k]
          local id = type(d) == "table" and tostring(d.t) .. "\t" .. tostring(d.victim)
          if id and num(d.t) and str(d.victim) and d.victim ~= mine and not seen[id] then
            seen[id] = true
            out[#out + 1] = { kind = src == "friends" and "friend" or "guild", t = d.t, mapID = d.mapID, x = d.x, y = d.y,
              zone = d.zone, key = g.key, name = str(g.display) or (g.name and Util.Display(g)) or nil, class = g.class,
              victim = d.victim, ref = d, spot = Scene.ValidSpot(d.mapID, d.x, d.y), mate = true }
          end
        end
      end
    end
  end
  return out
end

local function timed(out, now)
  for i = 1, #out do
    local it = out[i]
    if it.mate then it.fresh = now and now - it.t < Scene.FRESH and now - it.t >= -60 or false end
  end
  -- 1.6.0 call: help calls and sightings of guild, group and friends while they are fresh (Call.lua)
  local CX = ns.Call
  if CX and CX.Scenes then
    local ok = pcall(CX.Scenes, out, now)
    if not ok then Scene.Error("call") end
  end
  return out
end

function Scene.All(now)
  return timed(collect(), now)
end

-- fixer 2 1.6.0 (je03): the scenes for the map from a cache of the book's part. It goes stale with every change of the
-- book, the rap sheet, the guild's and friends' books (Scene.Stale, the events below) and after ITEMS_TTL seconds at the
-- latest; a new scale of the map only bundles anew. The list returned is the caller's (a copy).
Scene.ITEMS_TTL = 10
Scene.stat = { reads = 0, cached = 0 }
local items = { ver = -1 }
local itemsVer = 0
function Scene.Stale() itemsVer = itemsVer + 1 end
function Scene.Items(now)
  local G = _G.GetTime
  local t = type(G) == "function" and G() or 0
  local c = items
  if c.ver ~= itemsVer or not c.list or t < c.at or t - c.at >= Scene.ITEMS_TTL then
    c = { ver = itemsVer, at = t, list = collect() }
    items = c
    Scene.stat.reads = Scene.stat.reads + 1
  else
    Scene.stat.cached = Scene.stat.cached + 1
  end
  local out = {}
  for i = 1, #c.list do out[i] = c.list[i] end
  return timed(out, now)
end
for _, ev in ipairs({ "READY", "DEATH_RECORDED", "SCENE_PLACE", "OWN_KILL", "ENEMY_REMOVED", "ENEMY_REKEYED",
  "ENEMY_STATUS", "MANUAL_ADDED", "REVENGE", "REVENGE_UNDONE", "LEDGER_CLEARED", "BOOK_IMPORTED", "EXPIRED_CHANGED",
  "STANDING_CHANGED", "AVENGED", "GUILD_KILL" }) do
  ns:On(ev, Scene.Stale)
end
-- every change of the journal goes through Store.TouchJournal (Store.lua says so); Store is loaded before this file
do
  local St = ns.Store
  if St and type(St.TouchJournal) == "function" then
    local touch = St.TouchJournal
    St.TouchJournal = function(...) Scene.Stale(); return touch(...) end
  end
end
-- a mere sighting (lastSeen) is no scene
ns:On("ENEMY_UPDATED", function(_, why) if why ~= "seen" then Scene.Stale() end end)
ns:On("GUILD_UPDATED", function(reason) if reason ~= "seen" then Scene.Stale() end end)

-- the scene a click in the book asked for: the same entry, or the same time on the same map (a deed of the poster and
-- its journal entry are one death)
function Scene.IsFocus(item, focus)
  if type(focus) ~= "table" then return false end
  if item.ref == focus then return true end
  return num(focus.t) and item.t == focus.t and item.mapID == focus.mapID or false
end

-- the filter of the settings (on, period, open debts, kinds). focus = a scene shown from the book (passes always)
function Scene.Keep(item, now, focus)
  if focus and Scene.IsFocus(item, focus) then return true end
  if Scene.Setting("on") == false then return false end
  local days = tonumber(Scene.Setting("days")) or 30
  if days > 0 and now and item.t < now - days * 86400 then return false end
  if item.kind == "death" or item.kind == "kill" then
    if Scene.Setting("own") == false then return false end
    -- only open debts: an enemy whose standing is even or ahead goes (an unclear killer and a stand the rap sheet does
    -- not know stay)
    if Scene.Setting("open") == true and item.key and ns.Ledger and ns.Ledger.State then
      local ok, st = pcall(ns.Ledger.State, item.key)
      if ok and st ~= nil and st ~= "open" then return false end
    end
    return true
  end
  if item.kind == "guild" then return Scene.Setting("guild") ~= false end
  if item.kind == "call" or item.kind == "sight" then return true end   -- 1.6.0 call: fresh ones only (Call.Scenes)
  if item.kind == "friend" then return Scene.Setting("friends") ~= false end
  return false
end

-- order of the pin's look when kinds share a bundle: a fresh mate's death first (go and help), then my death, then
-- my kill, then guild and friends
local RANK = { death = 2, kill = 3, guild = 4, friend = 5, sight = 6, call = 1 }
local function rankOf(it) return it.fresh and 1 or RANK[it.kind] or 9 end

-- The pins of one map: { { x, y, items = { the lead first, then newest first }, kind, fresh, count, lead } }, and how
-- many scenes were left out. translate(mapID, x, y) -> x, y on this map or nil (scenes of other maps, e.g. a zone on its
-- continent; optional). size = { rx, ry }: a pin's width and height in percent of the map (optional).
function Scene.Pins(mapID, now, translate, focus, size)
  local all = Scene.Items(now)
  local items = {}
  for i = 1, #all do
    local it = all[i]
    if it.spot and Scene.Keep(it, now, focus) then
      local x, y
      if it.mapID == mapID then x, y = it.x, it.y
      elseif translate then
        local ok, tx, ty = pcall(translate, it.mapID, it.x, it.y)
        if ok and num(tx) and num(ty) and tx >= 0 and tx <= 100 and ty >= 0 and ty <= 100 then x, y = tx, ty end
      end
      if x then it.px, it.py = x, y; items[#items + 1] = it end
    end
  end
  table.sort(items, function(a, b)
    local fa, fb = Scene.IsFocus(a, focus), Scene.IsFocus(b, focus)
    if fa ~= fb then return fa end
    if a.t ~= b.t then return a.t > b.t end
    return (RANK[a.kind] or 9) < (RANK[b.kind] or 9)
  end)
  while #items > Scene.MAX_ITEMS do table.remove(items) end
  local pins, left = {}, 0
  local rx = type(size) == "table" and num(size.rx) and size.rx > 0 and size.rx or Scene.RX
  local ry = type(size) == "table" and num(size.ry) and size.ry > 0 and size.ry or Scene.RY
  for i = 1, #items do
    local it = items[i]
    local home
    for k = 1, #pins do
      local p = pins[k]
      -- the pins would cover each other (a pin stands on its spot: its box is rx wide and ry high)
      if math.abs(it.px - p.x) < rx and math.abs(it.py - p.y) < ry then home = p; break end
    end
    if home then
      home.items[#home.items + 1] = it
    elseif #pins < Scene.MAX_PINS then
      pins[#pins + 1] = { x = it.px, y = it.py, items = { it } }
    else
      left = left + 1
    end
  end
  for _, p in ipairs(pins) do
    local best = p.items[1]
    for _, it in ipairs(p.items) do
      if rankOf(it) < rankOf(best) then best = it end
      if it.fresh then p.fresh = true end
    end
    p.kind, p.count, p.lead = best.kind, #p.items, best
    -- 1.5.0 fixer: the scene the pin's look stands for first (its click and its list start there)
    if p.items[1] ~= best then
      for i = 2, #p.items do if p.items[i] == best then table.remove(p.items, i); break end end
      table.insert(p.items, 1, best)
    end
  end
  return pins, left
end

-- the pin that holds a scene (ref = journal entry, log row or mate's deed, or a place with t and mapID)
function Scene.PinOf(pins, ref)
  for _, p in ipairs(pins or {}) do
    for _, it in ipairs(p.items) do if Scene.IsFocus(it, ref) then return p end end
  end
end

---------------------------------------------------------------------------
-- Words of a pin (tooltip): lines { text, r, g, b } (r, g, b optional = the tooltip's default)
---------------------------------------------------------------------------
local function colored(name, class)
  if not name then return L.SCENE_SOMEONE end
  local r, g, b
  if class and Util.ClassColor then r, g, b = Util.ClassColor(class) end
  if not r then return name end
  return ("|cff%02x%02x%02x%s|r"):format(math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5), name)
end
Scene.Colored = colored

local function placeOf(it) return str(it.subzone) or str(it.zone) end

-- the head line of one scene: "Here Grimwald Eisenbart killed you"
function Scene.Head(it)
  if it.kind == "death" then
    if not it.name then return L.SCENE_TIP_DEATH_UNCLEAR end
    -- 1.5.0 fixer: no sure killing blow (the book holds a suspicion): the map says suspicion, never "killed you"
    if it.suspect then return Fmt(L.SCENE_TIP_SUSPECT, { name = colored(it.name, it.class) }) end
    return Fmt(L.SCENE_TIP_DEATH, { killer = colored(it.name, it.class) })
  elseif it.kind == "kill" then
    return Fmt(L.SCENE_TIP_KILL, { name = colored(it.name, it.class) })
  elseif it.kind == "call" then
    return Fmt(L.SCENE_TIP_CALL, { caller = str(it.caller) or "?" })
  elseif it.kind == "sight" then
    return Fmt(L.SCENE_TIP_SIGHT, { name = colored(it.name, it.class), by = str(it.caller) or "?" })
  end
  return Fmt(L.SCENE_TIP_MATE, { victim = str(it.victim) or "?", killer = colored(it.name, it.class) })
end

-- a short line of a bundle: "11/10 21:40 · Here Grimwald killed you"
function Scene.Short(it)
  return (Util.When and Util.When(it.t) or "?") .. " · " .. Scene.Head(it)
end

-- assists of my death (book entries only: a key without an entry gives no name)
local function assistsOf(it)
  local S = ns.Store
  local e = S and it.key and S.Get(it.key)
  local names, more = {}, 0
  if e and type(e.deaths) == "table" then
    for i = 1, #e.deaths do
      local d = e.deaths[i]
      if type(d) == "table" and d.t == it.t and type(d.others) == "table" then
        for k = 1, #d.others do
          local n = Scene.NameOf(d.others[k])
          if n and #names < 4 then names[#names + 1] = n elseif not n or #names >= 4 then more = more + 1 end
        end
        break
      end
    end
  end
  return names, more
end

-- all lines of a pin's tooltip
function Scene.TipLines(pin, now)
  local out = {}
  local items = pin.items
  if #items == 1 then
    local it = items[1]
    out[1] = { Scene.Head(it), 1, 1, 1 }
    out[#out + 1] = { Util.When(it.t) .. (placeOf(it) and (" · " .. placeOf(it)) or "") }
    if it.kind == "death" then
      if it.spell then out[#out + 1] = { Fmt(L.TIP_CAUSE, { spell = it.spell }) } end
      local names, more = assistsOf(it)
      if #names > 0 then
        local s = table.concat(names, ", ") .. (more > 0 and (" " .. Fmt(L.MORE_LINE, { count = more })) or "")
        out[#out + 1] = { Fmt(L.TIP_ASSISTS, { names = s }) }
      end
    elseif it.kind == "kill" and it.revenge then
      out[#out + 1] = { L.SCENE_REVENGE, 0.9, 0.25, 0.2 }
    elseif it.kind == "guild" or it.kind == "friend" then
      out[#out + 1] = { it.kind == "guild" and L.SCENE_SRC_GUILD or L.SCENE_SRC_FRIEND, 0.7, 0.7, 0.7 }
      if it.fresh then out[#out + 1] = { Fmt(L.SCENE_FRESH, { ago = Util.Ago(it.t) }), 1, 0.82, 0 } end
    elseif it.kind == "call" then
      if it.name then out[#out + 1] = { Fmt(L.SCENE_TIP_ATTACKER, { name = it.name }) } end
      out[#out + 1] = { Fmt(L.SCENE_FRESH, { ago = Util.Ago(it.t) }), 1, 0.82, 0 }
    elseif it.kind == "sight" and it.layer == "other" then
      out[#out + 1] = { L.SIGHT_OTHER_LAYER, 1, 0.82, 0 }
    end
  else
    out[1] = { Fmt(L.SCENE_BUNDLE, { count = #items }), 1, 1, 1 }
    local SHOW = 6
    for i = 1, math.min(#items, SHOW) do out[#out + 1] = { Scene.Short(items[i]) } end
    if #items > SHOW then out[#out + 1] = { Fmt(L.MORE_LINE, { count = #items - SHOW }), 0.7, 0.7, 0.7 } end
  end
  out[#out + 1] = { #items > 1 and L.SCENE_TIP_PICK or L.SCENE_TIP_CLICK, 0.6, 0.6, 0.6 }
  return out
end

---------------------------------------------------------------------------
-- Probe (/dn probe: probe.scene)
---------------------------------------------------------------------------
function Scene.ProbeSnapshot()
  local c = {}
  for k, v in pairs(Scene.counts) do
    if type(v) == "table" then
      local t = {}
      for k2, v2 in pairs(v) do t[k2] = v2 end
      c[k] = t
    else c[k] = v end
  end
  local api = ns.SceneMap and ns.SceneMap.Api and ns.SceneMap.Api() or {}
  c.mapFrame, c.openWorldMap, c.mapRect, c.canvas, c.hook = api.mapFrame == true, api.openWorldMap == true,
    api.mapRect == true, api.canvas == true, api.hook == true
  c.attached = Scene.attached == true
  local all = Scene.All(time and time() or nil)
  local spots, zones = 0, 0
  for _, it in ipairs(all) do if it.spot then spots = spots + 1 elseif Scene.ValidMap(it.mapID) then zones = zones + 1 end end
  c.scenes, c.withSpot, c.zoneOnly = #all, spots, zones
  return c
end
