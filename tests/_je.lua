-- Jagd 2 "Effizienz" 1.6.0: gemeinsames Messgeruest der Belegtests je*.lua und der Messlaeufe je_m*.lua.
-- Laedt alle Dateien der TOC eines Standes (Logik in der Attrappe tests/mock_wow.lua, Oberflaeche in tests/ui/mock.lua),
-- zaehlt je Ereignis und je Handler Aufrufe, Zeit (os.clock) und erzeugten Muell (collectgarbage("count") bei
-- angehaltenem Sammler) und zaehlt Aufrufe der Client-API. Die Attrappe ist nicht der Client: Zaehlungen uebertragen
-- sich, Zeiten nur der Groessenordnung nach.
-- Aufruf je Test: cd <stand> && luajit <pfad>/jeNN_x.lua .   (Exit 1 = Fund belegt)
local J = {}
local clock, gc = os.clock, collectgarbage
local realLoadfile, setfenv, getfenv, getinfo = loadfile, setfenv, getfenv, debug.getinfo

J.handlers = {}     -- id -> { id, n, t, kb }
J.events = {}       -- Ereignis -> { n, t, kb }
J.api = {}          -- Name -> Aufrufe
J.on = false

local function base(p) return (tostring(p):match("([^/]+)$") or tostring(p)) end

local function wrapHandler(kind, event, fn)
  local info = getinfo(fn, "S")
  local id = ("%s %s @%s:%d"):format(kind, event, base(info.short_src), info.linedefined)
  local s = J.handlers[id]
  if not s then s = { id = id, kind = kind, event = event, n = 0, t = 0, kb = 0 }; J.handlers[id] = s end
  return function(...)
    if not J.on then return fn(...) end
    s.n = s.n + 1
    local k0, c0 = gc("count"), clock()
    fn(...)
    s.t = s.t + (clock() - c0)
    s.kb = s.kb + (gc("count") - k0)
  end
end

local function instrument(ns)
  local reg, on = ns.RegisterEvent, ns.On
  ns.RegisterEvent = function(self, event, fn)
    if type(fn) ~= "function" then return reg(self, event, fn) end
    return reg(self, event, wrapHandler("WoW", event, fn))
  end
  ns.On = function(self, event, fn)
    if type(fn) ~= "function" then return on(self, event, fn) end
    return on(self, event, wrapHandler("Bus", event, fn))
  end
end

local function exists(p) local h = io.open(p, "r"); if h then h:close(); return true end return false end

-- TOC-Reihenfolge der Lua-Dateien (ohne Sprachdateien, die laedt die Attrappe selbst)
local function tocFiles(dir)
  local out = {}
  for line in io.lines(dir .. "/DeathNote.toc") do
    line = line:gsub("\r", ""):gsub("%s+$", "")
    if line:find("%.lua$") and not line:find("^#") then out[#out + 1] = (line:gsub("\\", "/")) end
  end
  return out
end

-- opt: db, guild, lang, before(AM), plainType (Vorgabe true), noUI, countApi (Vorgabe true), skip = { ["Datei.lua"] = true }
function J.world(WT, opt)
  opt = opt or {}
  WT = (WT or "."):gsub("/+$", "")
  if opt.plainType ~= false then _G.DN_PLAIN_TYPE = true end
  package.path = WT .. "/tests/ui/?.lua;" .. WT .. "/tests/?.lua;" .. package.path
  package.loaded.mock_wow, package.loaded.mock = nil, nil
  arg[0] = WT .. "/tests/ui/je.lua"
  local AM = require("mock_wow")
  local BM = require("mock")
  local ADDON = WT .. "/DeathNote"
  BM.mediaDir = ADDON .. "/Media"
  BM.measure = true
  AM.locale = opt.lang or "deDE"
  J.handlers, J.events, J.api, J.widget, J.on = {}, {}, {}, {}, false
  -- Aufrufe der Widget-Methoden zaehlen (die Tabelle `methods` der UI-Attrappe, ueber den Upvalue von __index)
  do
    local mt = getmetatable(BM.G.UIParent)
    local idx = mt and mt.__index
    for i = 1, 20 do
      local name, v = debug.getupvalue(idx, i)
      if not name then break end
      if name == "methods" and type(v) == "table" and not v._jeCounted then
        for k, fn in pairs(v) do
          if type(fn) == "function" then
            v[k] = function(...) if J.on then J.widget[k] = (J.widget[k] or 0) + 1 end return fn(...) end
          end
        end
        v._jeCounted = true
      end
    end
  end

  -- Logik: die Liste der Attrappe dieses Standes, dazu Share.lua (wie die UI-Tests); Oberflaeche: der Rest der TOC
  local logic, isLogic = {}, {}
  for _, f in ipairs(AM.Files()) do logic[#logic + 1] = f; isLogic[f] = true end
  if exists(ADDON .. "/Share.lua") and not isLogic["Share.lua"] then logic[#logic + 1] = "Share.lua"; isLogic["Share.lua"] = true end
  local ui = {}
  for _, f in ipairs(tocFiles(ADDON)) do
    if not isLogic[f] and not f:find("^Locales/") and not (opt.skip and opt.skip[f]) then ui[#ui + 1] = f end
  end

  -- nach Core.lua die beiden Anmelde-Funktionen umhuellen (jede Datei danach meldet ueber die Huelle an)
  _G.loadfile = function(path, ...)
    local chunk, err = realLoadfile(path, ...)
    if not chunk then return chunk, err end
    if base(path) ~= "Core.lua" then return chunk end
    local w
    w = function(addon, ns, ...)
      setfenv(chunk, getfenv(w))
      local r = chunk(addon, ns, ...)
      instrument(ns)
      return r
    end
    return w
  end
  rawset(BM.G, "time", function() return math.floor(AM.epoch + AM.now) end)
  rawset(BM.G, "GetTime", function() return AM.now end)
  local T = {}
  local c0 = clock()
  local ns = AM.Load({ noLogin = true, files = logic, db = opt.db, before = function()
    if opt.guild then AM.units.player.guild = opt.guild end
    -- Aufrufe der Client-API zaehlen (alles, was die Attrappe als Funktion in _G oder in C_* legt)
    if opt.countApi ~= false then
      local function count(name, fn)
        return function(...) if J.on then J.api[name] = (J.api[name] or 0) + 1 end return fn(...) end
      end
      for k, v in pairs(_G) do
        if type(k) == "string" and type(v) == "function"
          and (k:find("^Unit") or k:find("^GetGuild") or k:find("^GetPlayerInfo") or k:find("^IsIn") or k == "GetRealZoneText"
            or k == "GetSubZoneText" or k == "InCombatLockdown" or k == "Ambiguate" or k == "GetNumGuildMembers") then
          _G[k] = count(k, v)
        elseif type(k) == "string" and k:find("^C_") and type(v) == "table" and k ~= "C_Timer" then
          for k2, v2 in pairs(v) do if type(v2) == "function" then v[k2] = count(k .. "." .. k2, v2) end end
        end
      end
    end
    if opt.before then opt.before(AM, BM) end
  end })
  T.load = (clock() - c0) * 1000      -- Logik-Dateien samt ADDON_LOADED (Store.Init)
  c0 = clock()
  J.uiErrors = {}
  if not opt.noUI then
    for _, f in ipairs(ui) do
      local ok, err = pcall(BM.Load, ADDON .. "/" .. f, ns)
      if not ok then J.uiErrors[#J.uiErrors + 1] = f .. ": " .. tostring(err) end
    end
  end
  _G.loadfile = realLoadfile
  T.ui = (clock() - c0) * 1000
  c0 = clock(); AM.FireEvent("PLAYER_LOGIN"); T.login = (clock() - c0) * 1000
  c0 = clock(); AM.FireEvent("PLAYER_ENTERING_WORLD"); T.world = (clock() - c0) * 1000

  local W = { AM = AM, BM = BM, G = BM.G, ns = ns, sent = {}, ui = ui, logic = logic, T = T }
  _G.SendChatMessage = function(text, ch) W.sent[#W.sent + 1] = { text = text, ch = ch } end
  function W.tick(s) AM.Advance(s or 0.1); BM.now = AM.now; BM.Advance(0) end
  function W.settle() BM.Advance(13); BM.FinishAnims(); BM.Advance(1); BM.FinishAnims(); BM.Advance(1); AM.now = BM.now end
  function W.open()
    if not (rawget(BM.G, "DeathNoteFrame") and BM.G.DeathNoteFrame:IsShown()) then ns:Fire("TOGGLE_UI") end
    W.tick(1); W.settle()
  end
  function W.find(pred) for _, f in ipairs(BM.frames) do if pred(f) then return f end end end
  function W.click(f, b) assert(f, "click ohne Frame"); f._scripts.OnClick(f, b or "LeftButton"); W.tick(1) end
  function W.tab(id) W.click(W.find(function(f) return f.id == id and f._scripts and f._scripts.OnClick and f:IsVisible() end)) end
  -- ein Ereignis des Clients, gezaehlt je Ereignisname (Summe ueber alle Handler samt Bus und UI dahinter)
  function W.fire(event, ...)
    local e = J.events[event]
    if not e then e = { n = 0, t = 0, kb = 0 }; J.events[event] = e end
    if not J.on then return AM.FireEvent(event, ...) end
    e.n = e.n + 1
    local k0, c0 = gc("count"), clock()
    AM.FireEvent(event, ...)
    e.t = e.t + (clock() - c0)
    e.kb = e.kb + (gc("count") - k0)
  end
  -- hat irgendein Frame der Logik-Attrappe das Ereignis angemeldet?
  function W.registered(event)
    for _, f in ipairs(AM.frames) do if f.events[event] and f.scripts.OnEvent then return true end end
    return false
  end
  -- Frames der Oberflaeche mit laufendem OnUpdate (sichtbar oder nicht)
  function W.onUpdates()
    local out = {}
    for _, f in ipairs(BM.frames) do
      if f._scripts and f._scripts.OnUpdate then out[#out + 1] = f end
    end
    return out
  end
  function W.timers()
    local n = 0
    for _, t in ipairs(AM.timers) do n = n + 1 end
    for _, t in ipairs(BM.timers) do if not t.cancelled then n = n + 1 end end
    return n
  end
  return W
end

-- Messung an (Sammler angehalten, damit die KB-Zahl die erzeugte Menge ist) und aus
function J.start() gc("collect"); gc("collect"); gc("stop"); J.on = true end
function J.stop() J.on = false; gc("restart") end
function J.reset()
  for _, s in pairs(J.handlers) do s.n, s.t, s.kb = 0, 0, 0 end
  J.events, J.api, J.widget = {}, {}, {}
end
function J.widgetTotal() local n = 0; for _, v in pairs(J.widget) do n = n + v end return n end

-- eine Funktion messen: ms, KB, dazu Sortierlaeufe und Vergleiche (table.sort gezaehlt)
function J.measure(fn, ...)
  local sorts, cmps, elems = 0, 0, 0
  local realSort = table.sort
  table.sort = function(t, less)
    sorts = sorts + 1; elems = elems + #t
    if less then return realSort(t, function(a, b) cmps = cmps + 1; return less(a, b) end) end
    return realSort(t)
  end
  local was = J.on
  J.widget = {}
  J.on = true
  gc("collect"); gc("collect"); gc("stop")
  local k0, c0 = gc("count"), clock()
  local ok, err = pcall(fn, ...)
  local ms, kb = (clock() - c0) * 1000, gc("count") - k0
  gc("restart")
  J.on = was
  table.sort = realSort
  if not ok then error(err, 0) end
  return { ms = ms, kb = kb, sorts = sorts, cmps = cmps, elems = elems, widgets = J.widgetTotal(),
    setText = J.widget.SetText or 0, created = (J.widget.CreateFontString or 0) + (J.widget.CreateTexture or 0) }
end

function J.apiTotal() local n = 0; for _, v in pairs(J.api) do n = n + v end return n end

J.pass, J.fail = 0, 0
function J.check(name, cond, detail)
  if cond then J.pass = J.pass + 1; print("ok    " .. name .. (detail ~= nil and ("  (" .. tostring(detail) .. ")") or ""))
  else J.fail = J.fail + 1; print("ROT   " .. name .. (detail ~= nil and ("  -> " .. tostring(detail)) or "")) end
end
function J.done() print(("%d ok, %d rot"):format(J.pass, J.fail)); os.exit(J.fail > 0 and 1 or 0) end
return J
