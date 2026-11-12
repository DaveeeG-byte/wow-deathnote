-- 1.2.2: minimap button through LibDataBroker-1.1 + LibDBIcon-1.0, with the own button as fallback.
-- The libraries are minimal stand-ins written here (the real ones live in DeathNote/Libs and are not copied
-- into tests/): LibStub with __call, an LDB registry, and a LibDBIcon that builds "LibDBIcon10_<name>" like the
-- real one (dataObject, db, icon; tooltip through OnTooltipShow; position from db.minimapPos; db.hide).
-- (1) with libraries: one standard button, no "DeathNoteMinimapButton", launcher data, tooltip, clicks, hide
-- (2) settings: migration angle -> minimapPos (no jump), drag + logout keeps angle for 1.2.1, 1.2.1 moved it
-- (3) fallback: no LibStub, LibStub without LibDBIcon, Register raising: the own button of 1.2.1
-- Call: nice -n 15 luajit beleg_ui_11_minimap_libdbicon.lua <project copy>. All names are made up.
package.path = (arg[0]:match("^(.*)/[^/]+$") or ".") .. "/?.lua;" .. package.path
local K = require("_kopf_ui")

local ICON = "Interface\\AddOns\\DeathNote\\Media\\icon.tga"

-- opts.noIcon: LibStub and LDB only; opts.raise: Register raises
local function fakeLibs(BM, opts)
  opts = opts or {}
  local G = BM.G
  local libs = {}
  local LS = setmetatable({ libs = libs }, { __call = function(_, name, silent)
    local l = libs[name]
    if not l and not silent then error("Cannot find a library instance of " .. tostring(name)) end
    return l
  end })
  local ldb = { objs = {} }
  function ldb:NewDataObject(name, obj)
    if self.objs[name] then return nil end
    self.objs[name] = obj
    return obj
  end
  function ldb:GetDataObjectByName(name) return self.objs[name] end
  libs["LibDataBroker-1.1"] = ldb
  local dbi = { objects = {}, registered = 0 }
  local function place(b)
    local deg = (b.db and b.db.minimapPos) or 225
    b.pos = deg
    b:ClearAllPoints()
    b:SetPoint("CENTER", G.Minimap, "CENTER", math.cos(math.rad(deg)) * 75, math.sin(math.rad(deg)) * 75)
  end
  function dbi:Register(name, obj, db)
    if opts.raise then error("refused") end
    if not obj.icon then error("Can't register LDB objects without icons set!") end
    if self.objects[name] then error("already registered") end
    self.registered = self.registered + 1
    local b = G.CreateFrame("Button", nil, G.Minimap)
    rawset(G, "LibDBIcon10_" .. name, b)
    b.dataObject, b.db = obj, db
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetTexture(obj.icon)
    b:SetScript("OnClick", function(self, m) obj.OnClick(self, m) end)
    b:SetScript("OnDragStart", function(self) self.db.minimapPos = 123.4; place(self) end)   -- what the lib writes
    self.objects[name] = b
    place(b)
    if db and db.hide then b:Hide() else b:Show() end
  end
  function dbi:GetMinimapButton(name) return self.objects[name] end
  function dbi:IsRegistered(name) return self.objects[name] ~= nil end
  function dbi:Hide(name) local b = self.objects[name]; if b then b:Hide() end end
  function dbi:Show(name) local b = self.objects[name]; if b then b:Show(); place(b) end end
  function dbi:Refresh(name, db) local b = self.objects[name]; if b then if db then b.db = db end; place(b) end end
  if not opts.noIcon then libs["LibDBIcon-1.0"] = dbi end
  rawset(G, "LibStub", LS)
  return { ldb = ldb, dbi = dbi }
end

local function world(opts)
  opts = opts or {}
  local fakes
  local W = K.world("deDE", { db = opts.db, before = function(AM, BM)
    if opts.libs ~= false then fakes = fakeLibs(BM, opts) end
  end })
  W.fakes = fakes
  W.btn = rawget(W.BM.G, "LibDBIcon10_DeathNote")
  W.own = rawget(W.BM.G, "DeathNoteMinimapButton")
  W.mm = function() return W.ns.Store.DB().settings.ui.minimap end
  return W
end

-- a tooltip stand-in with an owner (LibDBIcon's tooltip is a GameTooltip owned by the button)
local function tip(owner)
  local t = { lines = {} }
  function t:SetText(s) self.lines[#self.lines + 1] = s end
  function t:AddLine(s) self.lines[#self.lines + 1] = s end
  function t:GetOwner() return owner end
  return t
end
local function has(t, s) for _, l in ipairs(t.lines) do if l == s then return true end end return false end

------------------------------------------------------------------------ (1) with libraries
do
  local W = world()
  local L, ns = W.L, W.ns
  K.check("1 the standard button LibDBIcon10_DeathNote exists", W.btn ~= nil)
  K.check("1 no own button DeathNoteMinimapButton beside it", W.own == nil)
  K.check("1 registered once", W.fakes.dbi.registered == 1, W.fakes.dbi.registered)
  local obj = W.fakes.ldb.objs.DeathNote
  K.check("1 LDB object named DeathNote, type launcher", obj and obj.type == "launcher")
  K.check("1 LDB icon is the addon icon", obj and obj.icon == ICON, obj and obj.icon)
  K.check("1 no own OnEnter: the tooltip comes through OnTooltipShow", obj and type(obj.OnTooltipShow) == "function")
  K.check("1 LibDBIcon gets the settings table ui.minimap", W.btn and W.btn.db == W.mm())
  K.check("1 button shown", W.btn and W.btn:IsShown())
  if obj and W.btn then   -- (red on 1.2.1: neither exists)
    local t = tip(W.btn)
    obj.OnTooltipShow(t)
    K.check("1 tooltip title", t.lines[1] == "DeathNote", t.lines[1])
    K.check("1 tooltip click lines", has(t, L.MM_CLICK) and has(t, L.MM_MIDDLE))
    K.check("1 tooltip drag line on the minimap button", has(t, L.MM_DRAG))
    local t2 = tip(W.BM.G.UIParent)
    obj.OnTooltipShow(t2)
    K.check("1 no drag line in another LDB display", not has(t2, L.MM_DRAG) and has(t2, L.MM_CLICK))
    local t3 = { lines = {} }
    function t3:SetText(s) self.lines[#self.lines + 1] = s end
    function t3:AddLine(s) self.lines[#self.lines + 1] = s end
    obj.OnTooltipShow(t3)
    K.check("1 tooltip without GetOwner works", has(t3, L.MM_CLICK))
    -- clicks like the own button
    local function book() local F = rawget(W.BM.G, "DeathNoteFrame"); return F and F:IsShown() end
    W.click(W.btn, "LeftButton")
    K.check("1 left click opens the book", book())
    W.click(W.btn, "LeftButton")
    K.check("1 left click again closes it", not book())
    W.click(W.btn, "MiddleButton")
    K.check("1 middle click: alarm off", ns.Store.Setting("alert.enabled") == false)
    K.check("1 icon half transparent", W.btn.icon._alpha == 0.45, W.btn.icon._alpha)
    W.click(W.btn, "MiddleButton")
    K.check("1 middle click: alarm on again", ns.Store.Setting("alert.enabled") == true and W.btn.icon._alpha == 1)
    W.click(W.btn, "RightButton")
    K.check("1 right click opens the book with the settings", book())
  end
  -- the option "show minimap button" acts at once
  ns.Store.Setting("ui.minimap.hide", true); W.tick()
  K.check("1 hide: button hidden at once", W.btn and not W.btn:IsShown())
  ns.Store.Setting("ui.minimap.hide", false); W.tick()
  K.check("1 show: button shown at once", W.btn and W.btn:IsShown())
  K.check("1 still one registration, still no own button",
    W.fakes.dbi.registered == 1 and rawget(W.BM.G, "DeathNoteMinimapButton") == nil)
  -- AddonCompartment entries of the TOC still work
  W.BM.G.DeathNote_OnCompartmentClick("DeathNote", "MiddleButton")
  K.check("1 compartment middle click", ns.Store.Setting("alert.enabled") == false)
  W.BM.G.DeathNote_OnCompartmentEnter("DeathNote", W.BM.G.UIParent)
  W.BM.G.DeathNote_OnCompartmentLeave("DeathNote", W.BM.G.UIParent)
  local n, e = W.errs(); K.check("1 no errors", n == 0, e)
end

------------------------------------------------------------------------ (1b) hidden from the start
do
  local W = world({ db = { version = 3, settings = { ui = { minimap = { hide = true, angle = 40 } } } } })
  K.check("1b hidden in the settings: registered but hidden", W.btn ~= nil and not W.btn:IsShown())
  local n, e = W.errs(); K.check("1b no errors", n == 0, e)
end

------------------------------------------------------------------------ (2) settings, migration, downgrade
do
  -- 1.2.1 user: angle 100, no minimapPos
  local W = world({ db = { version = 3, settings = { ui = { minimap = { hide = false, angle = 100 } } } } })
  local mm = W.mm()
  K.check("2 migration: minimapPos = angle (same place)", mm.minimapPos == 100, mm.minimapPos)
  K.check("2 the button sits at that angle", W.btn and W.btn.pos == 100, W.btn and W.btn.pos)
  K.check("2 1.2.1 fields stay valid", mm.angle == 100 and mm.hide == false)
  -- drag with the library, then logout: angle follows for 1.2.1
  if W.btn then W.btn._scripts.OnDragStart(W.btn) end
  K.check("2 drag writes minimapPos", mm.minimapPos == 123.4)
  W.AM.FireEvent("PLAYER_LOGOUT")
  K.check("2 logout: angle follows as whole degrees", mm.angle == 123, mm.angle)
  local n, e = W.errs(); K.check("2 no errors", n == 0, e)
  -- next login with that DB: the precise position stays
  local db = W.ns.Store.DB()
  local W2 = world({ db = db })
  K.check("2 relog: minimapPos kept (no rounding jump)", W2.mm().minimapPos == 123.4, W2.mm().minimapPos)
  -- downgrade to 1.2.1 moved the button to 40 (minimapPos stale): angle wins
  db = W2.ns.Store.DB()
  db.settings.ui.minimap.angle = 40
  local W3 = world({ db = db })
  K.check("2 after 1.2.1 moved it: minimapPos = new angle", W3.mm().minimapPos == 40, W3.mm().minimapPos)
  K.check("2 broken minimapPos repaired", (function()
    local d = W3.ns.Store.DB(); d.settings.ui.minimap.minimapPos = "x"
    W3.ns.Store.Init(); return d.settings.ui.minimap.minimapPos == 40
  end)())
  -- fresh install
  local W4 = world()
  K.check("2 fresh install: angle 215 and minimapPos 215", W4.mm().angle == 215 and W4.mm().minimapPos == 215)
  local n2, e2 = W4.errs(); K.check("2 fresh: no errors", n2 == 0, e2)
end

------------------------------------------------------------------------ (3) fallback
do
  local W = world({ libs = false })
  K.check("3 without LibStub: own button", W.own ~= nil and W.own:IsShown())
  K.check("3 without LibStub: no library button", W.btn == nil)
  W.own._scripts.OnDragStart(W.own)
  W.own._scripts.OnUpdate(W.own, 0.016)
  W.own._scripts.OnDragStop(W.own)
  local mm = W.mm()
  K.check("3 own drag keeps angle and minimapPos together", type(mm.angle) == "number" and mm.minimapPos == mm.angle,
    tostring(mm.angle) .. " / " .. tostring(mm.minimapPos))
  W.AM.FireEvent("PLAYER_LOGOUT")
  K.check("3 logout keeps the dragged angle", mm.minimapPos == mm.angle)
  local n, e = W.errs(); K.check("3 no errors", n == 0, e)

  local W2 = world({ noIcon = true })
  K.check("3 LibStub without LibDBIcon: own button", W2.own ~= nil and W2.btn == nil)
  local n2, e2 = W2.errs(); K.check("3 partial libraries: no errors", n2 == 0, e2)

  local W3 = world({ raise = true })
  K.check("3 Register raising: own button", W3.own ~= nil and W3.own:IsShown())
  local n3, e3 = W3.errs(); K.check("3 Register raising: no errors", n3 == 0, e3)
end

K.done("beleg_ui_11 minimap LibDBIcon")
