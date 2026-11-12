-- 1.2.2: the minimap button with the REAL embedded libraries (DeathNote/Libs) in the UI mock, not stand-ins.
-- (0) reference: one LibDBIcon button on our settings table, tooltip through the real OnEnter with the drag line,
--     the switch hides and shows at once, drag + logout keeps the angle, no unknown widget method
-- (3) ui.minimap.showInCompartment left by another addon (LibDBIcon:AddButtonToCompartment): no second
--     compartment entry next to the one from the TOC; a lock (LibDBIcon:Lock) stays, the tooltip drops the drag line
-- (4) Register raises half way: the own button takes over, no half-built library button stays registered or shown
-- (5) without C_Timer.NewTimer the book still opens without an error
-- Call: luajit tests/ui/minimap_real_libs.lua <project copy>
local DIR = assert(arg[1], "project copy"):gsub("/+$", "")
package.path = DIR .. "/tests/belege/?.lua;" .. package.path
local K = require("_kopf_ui")
local R = dofile(K.DIR .. "/tests/ui/real_libs.lua")

local function world(opts)
  opts = opts or {}
  local W = K.world("deDE", { db = opts.db, before = function(AM, BM)
    local n0 = #BM.frames + 1
    R.load(BM, K.ADDON, { compartment = opts.compartment })
    if opts.cripple then BM.WHITELIST.Button[opts.cripple] = nil end
    if opts.before then opts.before(AM, BM) end
    R.libLogin(BM, n0)
  end })
  W.lib = rawget(W.G, "LibStub")("LibDBIcon-1.0", true)
  W.btn = rawget(W.G, "LibDBIcon10_DeathNote")
  W.own = rawget(W.G, "DeathNoteMinimapButton")
  W.mm = W.ns.Store.DB().settings.ui.minimap
  return W
end

local function dbWith(mm)
  mm.hide = false
  return { version = 3, settings = { welcomed = true, ui = { minimap = mm } } }
end

local function hasDragLine(W)
  W.btn._scripts.OnEnter(W.btn)
  local tt = rawget(W.G, "LibDBIconTooltip")
  for _, l in ipairs(tt._lines or {}) do if l == W.L.MM_DRAG then return true end end
  return false
end

------------------------------------------------------------------------ (0) reference
do
  local W = world({ db = dbWith({ angle = 100 }), compartment = true })
  K.check("0 real library: standard button, no own button", W.btn ~= nil and W.own == nil)
  K.check("0 button uses our settings table", W.btn and W.btn.db == W.mm)
  K.check("0 position taken from angle 100", W.mm.minimapPos == 100, W.mm.minimapPos)
  K.check("0 LibDBIcon adds no compartment entry (the TOC has one)", #W.G.AddonCompartmentFrame.registeredAddons == 0)
  if W.btn then
    K.check("0 tooltip through the real OnEnter has the drag line", hasDragLine(W))
    W.ns.Store.Setting("ui.minimap.hide", true)
    K.check("0 switch off hides at once", not W.btn:IsShown())
    W.ns.Store.Setting("ui.minimap.hide", false)
    K.check("0 switch on shows at once", W.btn:IsShown())
    W.btn._scripts.OnDragStart(W.btn)
    local upd = W.btn._scripts.OnUpdate
    if upd then upd(W.btn) end
    W.btn._scripts.OnDragStop(W.btn)
    W.AM.FireEvent("PLAYER_LOGOUT")
    K.check("0 drag + logout: angle follows minimapPos", W.mm.angle == math.floor(W.mm.minimapPos + 0.5) % 360, W.mm.angle)
  end
  local unknown = {}
  for k in pairs(W.BM.unknown or {}) do unknown[#unknown + 1] = k end
  table.sort(unknown)
  K.check("0 the mock lists every widget method the libraries call", #unknown == 0, table.concat(unknown, " "))
  local n, e = W.errs(); K.check("0 no errors", n == 0, e)
end

------------------------------------------------------------------------ (3) foreign fields in ui.minimap
do
  local W = world({ compartment = true, db = dbWith({ angle = 215, minimapPos = 215, showInCompartment = true }) })
  K.check("3 showInCompartment left in the SavedVariables: no second compartment entry",
    #W.G.AddonCompartmentFrame.registeredAddons == 0, #W.G.AddonCompartmentFrame.registeredAddons .. " entries by LibDBIcon")
  K.check("3 showInCompartment is removed", W.mm.showInCompartment == nil)
  local n, e = W.errs(); K.check("3 no errors", n == 0, e)
end
do
  local W = world({ db = dbWith({ angle = 215, lock = true }) })
  K.check("3 lock stays", W.mm.lock == true)
  K.check("3 lock: the library keeps the button from dragging", W.btn and W.btn._scripts.OnDragStart == nil)
  K.check("3 lock: the tooltip has no drag line", W.btn and not hasDragLine(W))
  local n, e = W.errs(); K.check("3 lock: no errors", n == 0, e)
end

------------------------------------------------------------------------ (4) Register raises half way
do
  local W = world({ cripple = "SetFixedFrameStrata" })
  K.check("4 fallback: the own button is there", W.own ~= nil and W.own:IsShown())
  local left = W.lib and W.lib:GetMinimapButton("DeathNote")
  K.check("4 the half-built library button is not registered", left == nil)
  K.check("4 the half-built library button is hidden", not (W.btn and W.btn:IsShown()))
end

------------------------------------------------------------------------ (5) no C_Timer.NewTimer
do
  local W = world({ before = function(_, BM) BM.G.C_Timer.NewTimer = nil end })
  W.errs()
  W.ns:Fire("TOGGLE_UI"); W.tick()
  local F = rawget(W.G, "DeathNoteFrame")
  local n, e = W.errs()
  K.check("5 without C_Timer.NewTimer the book opens without an error", F and F:IsShown() and n == 0, e)
end

K.done("minimap_real_libs")
