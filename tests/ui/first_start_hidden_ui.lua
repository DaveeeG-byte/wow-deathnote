-- 1.3.0 first start: only an explicit close (the cross, Esc through UISpecialFrames, Go) answers the window. A hide of
-- the whole interface (Alt+Z, a cinematic: UIParent hides, the client runs OnHide of the shown window while its own
-- shown flag stays) is no answer: the builders stay held, firstRun stays "new", the language can still switch without
-- a reload, and Esc afterwards still answers. The UI mock does not pass a parent's hide on, so the test calls OnHide
-- the way the client does.
-- Call from the project root: luajit tests/ui/first_start_hidden_ui.lua .
local DIR = (arg[1] or "."):gsub("/+$", "")
package.path = DIR .. "/tests/ui/?.lua;" .. DIR .. "/tests/?.lua;" .. package.path
arg[0] = DIR .. "/tests/ui/first_start_hidden_ui.lua"
local ADDON = DIR .. "/DeathNote"
local okN, badN = 0, 0
local function check(name, cond, info)
  if cond then okN = okN + 1 else badN = badN + 1; io.write("RED   ", name, info ~= nil and ("  -> " .. tostring(info)) or "", "\n") end
end

local function tocFiles()
  local out = {}
  for line in io.lines(ADDON .. "/DeathNote.toc") do
    line = line:gsub("\r", ""):gsub("%s+$", "")
    if line ~= "" and not line:find("^#") and line:find("%.lua$") then out[#out + 1] = (line:gsub("\\", "/")) end
  end
  return out
end

local AM, BM, G
local function world()
  package.loaded.mock_wow, package.loaded.mock = nil, nil
  AM = require("mock_wow")
  BM = require("mock")
  BM.mediaDir = ADDON .. "/Media"
  G = BM.G
  AM.Reset()
  AM.locale, AM.client = "deDE", "deDE"
  _G.DeathNoteDB = nil
  local LOGIC = {}
  for _, f in ipairs(AM.FILES) do LOGIC[f] = true end
  local ns, ui = {}, false
  for _, f in ipairs(tocFiles()) do
    if f == "Alert.lua" then ui = true end
    if LOGIC[f] or not ui then assert(loadfile(ADDON .. "/" .. f))("DeathNote", ns) else BM.Load(ADDON .. "/" .. f, ns) end
  end
  AM.ns = ns
  AM.FireEvent("ADDON_LOADED", "DeathNote")
  AM.FireEvent("PLAYER_LOGIN")
  AM.FireEvent("PLAYER_ENTERING_WORLD")
  return ns
end
local function tick(s) AM.Advance(s or 0.1); BM.Advance(s or 0.1) end
-- the client hides UIParent (Alt+Z): OnHide of the shown window runs, its own flag stays shown
local function hideInterface(d)
  G.UIParent:Hide()
  local f = d._scripts.OnHide
  if f then f(d) end
  tick()
end
local function showInterface() G.UIParent:Show(); tick() end

-- 1) Alt+Z and back, then Esc
do
  local ns = world()
  tick(3.2)
  local d = rawget(G, "DeathNoteStart")
  check("window shown on a new installation", d ~= nil and d:IsShown())
  hideInterface(d)
  check("Alt+Z: not counted as an answer", ns.Start.Holding() == true)
  check("Alt+Z: the builders stay held", ns.Locale.Held() == true)
  check("Alt+Z: firstRun stays new", _G.DeathNoteDB.settings.firstRun == "new", _G.DeathNoteDB.settings.firstRun)
  showInterface()
  check("interface back: the window is there", d:IsShown() and d:IsVisible())
  -- Esc (UISpecialFrames hides the window itself)
  d:Hide(); tick()
  check("Esc afterwards answers", ns.Start.Holding() == false)
  check("Esc: firstRun done", _G.DeathNoteDB.settings.firstRun == "done", _G.DeathNoteDB.settings.firstRun)
  check("no errors", #AM.errors == 0 and #BM.violations == 0, AM.errors[1] or BM.violations[1])
end

-- 2) Alt+Z, back, then a language switch and Go: takes effect without a reload
do
  local ns = world()
  tick(3.2)
  local d = rawget(G, "DeathNoteStart")
  hideInterface(d)
  showInterface()
  ns.Start.Pick("ruRU", nil)
  ns.Start.Go(); tick()
  check("Go after Alt+Z: answered", ns.Start.Holding() == false)
  check("Go after Alt+Z: the language took effect without a reload", ns.Locale.code == "ruRU", ns.Locale.code)
  check("no errors (Go)", #AM.errors == 0 and #BM.violations == 0, AM.errors[1] or BM.violations[1])
end

io.write(("first start, interface hidden: %d green, %d red\n"):format(okN, badN))
os.exit(badN == 0 and 0 or 1)
