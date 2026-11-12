-- 1.2.2: the status line "enemy nameplates are off" follows the plates at once.
-- (1) CVAR_UPDATE (any first argument): the line changes without a redraw of the book
-- (2) NAME_PLATE_UNIT_ADDED while the plates count as off: the line clears; with plates on the hot path reads nothing
-- (3) no event at all (V key), book open: the line clears after the poll interval
-- (4) book closed: no poll timer, no CVar reads; reopening shows the current state at once
-- (5) a secret CVar value changes nothing and raises nothing
-- Call: nice -n 15 luajit beleg_ui_10_status_plates.lua <project copy>. All names are made up.
package.path = (arg[0]:match("^(.*)/[^/]+$") or ".") .. "/?.lua;" .. package.path
local K = require("_kopf_ui")

local function world()
  local W = K.world("deDE")
  W.ns:Fire("TOGGLE_UI"); W.tick(); W.settle()
  W.F = rawget(W.BM.G, "DeathNoteFrame")
  -- the status line: the FontString that shows STATUS_NO_PLATES (found once while it is shown)
  W.off = function()
    for _, f in ipairs(W.BM.frames) do
      if f._kind == "FontString" and f._text == W.L.STATUS_NO_PLATES and f:IsVisible() then return true end
    end
    return false
  end
  W.cvar = function(v) W.AM.cvars.nameplateShowEnemies = v end
  -- count CVar reads through the logic's accessor
  W.reads = 0
  local U = W.ns.Util
  local orig = U.NameplatesOn
  U.NameplatesOn = function(...) W.reads = W.reads + 1; return orig(...) end
  -- pending, not cancelled UI timers
  W.timers = function()
    local n = 0
    for _, t in ipairs(W.BM.timers) do if not t.cancelled then n = n + 1 end end
    return n
  end
  return W
end

------------------------------------------------------------------------ (1) CVAR_UPDATE
do
  local W = world()
  K.check("1 book open, plates on: no line", W.F:IsShown() and not W.off())
  W.cvar(false)
  W.AM.FireEvent("CVAR_UPDATE", "NAMEPLATES_SHOW_ENEMIES", "0")   -- glue name: the value decides
  K.check("1 CVAR_UPDATE (glue name), plates off: line at once", W.off())
  W.cvar(true)
  W.AM.FireEvent("CVAR_UPDATE", "nameplateShowEnemies", "1")
  K.check("1 CVAR_UPDATE (CVar name), plates on: line empty at once", not W.off())
  W.cvar(false)
  W.AM.FireEvent("CVAR_UPDATE", "SomethingElse", "1")
  K.check("1 CVAR_UPDATE of another CVar still compares the value", W.off())
  local n, e = W.errs(); K.check("1 no errors", n == 0, e)
end

------------------------------------------------------------------------ (2) NAME_PLATE_UNIT_ADDED
do
  local W = world()
  W.cvar(false); W.AM.FireEvent("CVAR_UPDATE", "x", "0")
  K.check("2 line shown while off", W.off())
  W.cvar(true)                                   -- switched on without any CVar event
  W.AM.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate1")
  K.check("2 NAME_PLATE_UNIT_ADDED: line empty at once", not W.off())
  W.reads = 0
  for i = 1, 50 do W.AM.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate" .. i) end
  K.check("2 hot path with plates on: no CVar read per plate", W.reads == 0, W.reads)
  local n, e = W.errs(); K.check("2 no errors", n == 0, e)
end

------------------------------------------------------------------------ (3) no event, book open: poll
do
  local W = world()
  W.cvar(false); W.AM.FireEvent("CVAR_UPDATE", "x", "0")
  K.check("3 line shown while off", W.off())
  W.cvar(true)                                   -- the V key: no event at all
  K.check("3 before the poll the line still stands", W.off())
  W.tick(0.6)
  K.check("3 after the poll interval the line is empty", not W.off())
  W.cvar(false); W.tick(0.6)
  K.check("3 and back: the poll shows it again", W.off())
  local n, e = W.errs(); K.check("3 no errors", n == 0, e)
end

------------------------------------------------------------------------ (4) book closed: nothing runs
do
  local W = world()
  local UI = W.ns.UI
  K.check("4 poll runs while the book is open", UI.PlatePollActive and UI.PlatePollActive() == true)
  W.tick(1)
  W.F:Hide()
  K.check("4 book closed", not W.F:IsShown())
  K.check("4 no poll handle after closing", UI.PlatePollActive and UI.PlatePollActive() == false)
  local before = W.timers()
  W.reads = 0
  W.cvar(false)                                  -- silent change while closed
  W.tick(10)
  K.check("4 closed: no CVar reads in 10 s", W.reads == 0, W.reads)
  K.check("4 closed: no timer left behind", W.timers() <= before, W.timers() .. " > " .. before)
  W.F:Show(); W.tick(0)
  K.check("4 reopened: the line shows the current state at once", W.off())
  K.check("4 reopened: poll runs again", UI.PlatePollActive and UI.PlatePollActive() == true)
  -- open: about two reads per second
  W.reads = 0
  for _ = 1, 50 do W.tick(0.1) end            -- the UI mock runs one due timer per step
  K.check("4 open: poll reads the CVar about every 0.5 s", W.reads >= 8 and W.reads <= 12, W.reads)
  local n, e = W.errs(); K.check("4 no errors", n == 0, e)
end

------------------------------------------------------------------------ (5) secret value
do
  local W = world()
  W.cvar(W.AM.Secret("bool", "boolean"))
  W.AM.FireEvent("CVAR_UPDATE", "nameplateShowEnemies", "0")
  W.AM.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate1")
  W.tick(1)
  K.check("5 secret CVar: no line, no change", not W.off())
  local n, e = W.errs(); K.check("5 secret CVar: no errors", n == 0, e)
end

K.done("beleg_ui_10 status nameplates")
