-- 1.6.4 move: shared world of the tests mv164_*.lua. The UI mock with every file of the addon in TOC order (the UI part
-- from Alert.lua on, Place.lua and GrudgeCard.lua included), helpers for combat, Esc, drags and a /reload.
-- Call per test: luajit tests/ui/mv164_x.lua <project>   (exit 1 = red). Names are made up.
local J = {}
J.WT = arg and arg[1] or "."

local function tocUI(dir)
  local out, on = {}, false
  for line in io.lines(dir .. "/DeathNote.toc") do
    line = line:gsub("\r", ""):gsub("%s+$", "")
    if line ~= "" and not line:find("^#") then
      local f = line:gsub("\\", "/")
      if f == "Alert.lua" then on = true end
      if on and f:find("%.lua$") then out[#out + 1] = f end
    end
  end
  return out
end
J.tocUI = tocUI

-- opt.db: saved data (a /reload hands the old table over), opt.ui: UIParent scale, opt.skip: UI files left out,
-- opt.dir: another addon folder (with a trailing slash; GitBase.Archive, the comparison with 1.6.3)
function J.world(code, opt)
  opt = opt or {}
  local WT = J.WT
  package.path = WT .. "/tests/ui/?.lua;" .. WT .. "/tests/?.lua;" .. package.path
  package.loaded.mock_wow, package.loaded.mock = nil, nil
  local AM = require("mock_wow")
  local BM = require("mock")
  local ADDON = opt.dir and opt.dir:gsub("/$", "") or (WT .. "/DeathNote")
  BM.mediaDir = ADDON .. "/Media"
  BM.measure = true
  if opt.ui then BM.SetUIScale(opt.ui) end
  AM.locale = code or "deDE"
  local files = {}
  for _, f in ipairs(AM.Files()) do files[#files + 1] = f end
  files[#files + 1] = "Share.lua"
  rawset(BM.G, "time", function() return math.floor(AM.epoch + AM.now) end)
  _G.DeathNoteDB = opt.db   -- without saved data: a new installation (never the data of the world before)
  local ns
  if opt.whole then
    -- opt.whole: every file in TOC order, then ADDON_LOADED, nothing chosen (as the client starts a new installation;
    -- the way of tests/ui/dr160_draht.lua)
    AM.Reset()
    AM.client = code or "deDE"
    _G.DeathNoteDB = opt.db
    local LOGIC = {}
    for _, f in ipairs(AM.FILES) do LOGIC[f] = true end
    ns = {}
    local ui = false
    for line in io.lines(ADDON .. "/DeathNote.toc") do
      line = line:gsub("\r", ""):gsub("%s+$", "")
      if line ~= "" and not line:find("^#") and line:find("%.lua$") then
        local f = line:gsub("\\", "/")
        if f == "Alert.lua" then ui = true end
        if LOGIC[f] or not ui then assert(loadfile(ADDON .. "/" .. f))("DeathNote", ns) else BM.Load(ADDON .. "/" .. f, ns) end
      end
    end
    AM.ns = ns
    AM.FireEvent("ADDON_LOADED", "DeathNote")
  else
    ns = AM.Load({ noLogin = true, files = files, db = opt.db, dir = opt.dir })
    for _, f in ipairs(tocUI(ADDON)) do
      if not (opt.skip and opt.skip[f]) then BM.Load(ADDON .. "/" .. f, ns) end
    end
  end
  AM.FireEvent("PLAYER_LOGIN")
  AM.FireEvent("PLAYER_ENTERING_WORLD")
  local W = { AM = AM, BM = BM, G = BM.G, ns = ns }
  function W.tick(s) AM.Advance(s or 0.1); BM.Advance(s or 0.1) end
  function W.settle() BM.Advance(13); BM.FinishAnims(); BM.Advance(1); BM.FinishAnims(); BM.Advance(1) end
  function W.frame(name) return rawget(BM.G, name) end
  function W.shown(name) local f = rawget(BM.G, name); return f ~= nil and f:IsShown() and true or false end
  function W.slash(s) ns.HandleSlash(s); W.tick(0.1) end
  function W.combat(v)
    AM.inCombat, BM.combat = v, v
    AM.FireEvent(v and "PLAYER_REGEN_DISABLED" or "PLAYER_REGEN_ENABLED")
    W.tick(0.1)
  end
  -- Esc: the client hides every shown frame named in UISpecialFrames
  function W.esc()
    for _, n in ipairs(BM.G.UISpecialFrames) do
      local f = rawget(BM.G, n)
      if f and f:IsShown() then f:Hide() end
    end
    W.tick(0.1)
  end
  function W.rect(f) return BM.RectUI(f) end
  -- a drag by the left mouse button by dx, dy UIParent units: OnDragStart; when it really started moving (StartMoving)
  -- the frame is anchored where the client leaves it (BOTTOMLEFT of UIParent, offsets in the frame's scale);
  -- then OnDragStop. Returns true when the frame moved.
  function W.drag(f, dx, dy)
    assert(f, "drag ohne Frame")
    local l, b = BM.RectUI(f)
    if f._scripts.OnDragStart then f._scripts.OnDragStart(f, "LeftButton") end
    local moved = false
    if f._moving and l then
      local s = 1
      local o = f
      while o and o ~= BM.G.UIParent do s = s * (o._scale or 1); o = o._parent end
      f._points = { { "BOTTOMLEFT", BM.G.UIParent, "BOTTOMLEFT", (l + dx) / s, (b + dy) / s } }
      moved = true
    end
    if f._scripts.OnDragStop then f._scripts.OnDragStop(f) end
    W.tick(0.1)
    return moved
  end
  -- drag so that the frame's bottom left corner lands on l, b (UIParent units)
  function W.dragTo(f, l, b)
    local l0, b0 = BM.RectUI(f)
    return W.drag(f, l - l0, b - b0)
  end
  function W.rclick(f) assert(f, "Rechtsklick ohne Frame"); f._scripts.OnMouseUp(f, "RightButton"); W.tick(0.1) end
  function W.click(f, b) assert(f, "Klick ohne Frame"); f._scripts.OnClick(f, b or "LeftButton"); W.tick(0.1) end
  function W.chat() return AM.chat end
  function W.said(text)
    local n = 0
    for _, line in ipairs(AM.chat) do if type(line) == "string" and line:find(text, 1, true) then n = n + 1 end end
    return n
  end
  -- the samples on the screen (names of the four pieces)
  function W.samples()
    local out = {}
    for _, n in ipairs({ "DeathNoteAlert", "DeathNoteBanner", "DeathNoteCall", "DeathNoteGrudge" }) do
      local f = rawget(BM.G, n)
      if f and f:IsShown() and f.sample then out[#out + 1] = n end
    end
    return out
  end
  -- the secure button: hidden, or exactly over the shown alarm (center and size within half a unit)
  function W.buttonOk()
    local b, a = rawget(BM.G, "DeathNoteAlertButton"), rawget(BM.G, "DeathNoteAlert")
    if not b or not b:IsShown() then return true, "Knopf weg" end
    if not (a and a:IsShown()) then return false, "Knopf ohne Alarm" end
    local bl, bb, br, bt = BM.RectUI(b)
    local al, ab, ar, at = BM.RectUI(a)
    if not (bl and al) then return false, "nicht messbar" end
    local d = math.max(math.abs(bl - al), math.abs(bb - ab), math.abs(br - ar), math.abs(bt - at))
    return d < 0.5, ("Abstand %.2f"):format(d)
  end
  function W.errors() return #AM.errors + #BM.violations, tostring(AM.errors[1] or BM.violations[1]) end
  -- /reload: a new world on the same saved data (a deep copy, like the file the client writes)
  function W.reload(code2, opt2)
    local function copy(t, seen)
      if type(t) ~= "table" then return t end
      seen = seen or {}
      if seen[t] then return seen[t] end
      local o = {}
      seen[t] = o
      for k, v in pairs(t) do o[copy(k, seen)] = copy(v, seen) end
      return o
    end
    local db = copy(_G.DeathNoteDB)
    opt2 = opt2 or {}
    opt2.db = db
    return J.world(code2 or code, opt2)
  end
  return W
end

J.pass, J.fail = 0, 0
function J.check(name, cond, detail)
  if cond then J.pass = J.pass + 1; print("ok    " .. name)
  else J.fail = J.fail + 1; print("ROT   " .. name .. (detail ~= nil and ("  -> " .. tostring(detail)) or "")) end
end
function J.done(label)
  print(("%s: %d ok, %d rot"):format(label or "mv164", J.pass, J.fail))
  os.exit(J.fail > 0 and 1 or 0)
end
return J
