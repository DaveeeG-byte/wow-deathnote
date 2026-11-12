-- 1.3.0: a texture file that does not load shows the theme's fallback colour, and that colour is the finished one: the
-- theme's tint is not laid over it a second time (the client multiplies a colour texture with the vertex colour too).
-- Covers harbor and trade (the black book has no tints) with the book, a notice with a stamp and the slip. Also: with
-- the files there, the tint still lies on the textures.
-- Call from the project root: luajit tests/ui/theme_fallback.lua .
local DIR = (arg[1] or "."):gsub("/+$", "")
package.path = DIR .. "/tests/ui/?.lua;" .. DIR .. "/tests/?.lua;" .. package.path
arg[0] = DIR .. "/tests/ui/theme_fallback.lua"
local okN, badN = 0, 0
local function check(name, cond, info)
  if cond then okN = okN + 1 else badN = badN + 1; io.write("RED   ", name, info ~= nil and ("  -> " .. tostring(info)) or "", "\n") end
end

local function world(code, theme, fails)
  package.loaded.mock_wow, package.loaded.mock = nil, nil
  local AM = require("mock_wow")
  local BM = require("mock")
  BM.mediaDir = DIR .. "/DeathNote/Media"
  BM.textureFails = fails
  AM.locale = code
  local files = {}
  for _, f in ipairs(AM.FILES) do
    files[#files + 1] = f
    if f == "Themes/harbor.lua" then files[#files + 1] = "../tests/ui/theme_noslip.lua" end
  end
  local saved = AM.FILES
  AM.FILES = files
  local ns = AM.Load({ noLogin = true, db = { settings = { ui = { theme = theme } } } })
  AM.FILES = saved
  for _, f in ipairs({ "Alert.lua", "UI.lua", "Start.lua", "Extras.lua", "Humor.lua" }) do BM.Load(DIR .. "/DeathNote/" .. f, ns) end
  AM.FireEvent("PLAYER_LOGIN")
  AM.FireEvent("PLAYER_ENTERING_WORLD")
  local W = { AM = AM, BM = BM, ns = ns }
  function W.tick(s) AM.Advance(s or 0.1); BM.Advance(s or 0.1) end
  function W.settle() BM.Advance(13); BM.FinishAnims(); BM.Advance(1); BM.FinishAnims(); BM.Advance(1) end
  return W
end
local function hex(c) return ("#%02x%02x%02x"):format(math.floor(c[1] * 255 + .5), math.floor(c[2] * 255 + .5), math.floor(c[3] * 255 + .5)) end
local function white(v) return not v or (math.abs(v[1] - 1) < 0.01 and math.abs(v[2] - 1) < 0.01 and math.abs(v[3] - 1) < 0.01) end

for _, theme in ipairs({ "harbor", "trade" }) do
  for _, fails in ipairs({ true, false }) do
    local W = world("deDE", theme, fails)
    local ns = W.ns
    local n = theme .. (fails and " files missing: " or " files there: ")
    check(n .. "theme active", ns.Theme.id == theme, ns.Theme.id)
    W.tick(30); W.settle()
    ns:Fire("TOGGLE_UI"); W.tick(); W.settle()
    local k = ns.Store.AddManual("Wilmwardwulf", "Mummelwammer")
    ns.Store.ApplyKill({ name = "Wilmwardwulf", surname = "Mummelwammer", class = "MAGE", level = 60 }, { t = _G.time() - 100, zone = "Z" }, true)
    W.tick(); W.settle()
    ns:Fire("REVENGE", k); W.tick(0.5)
    local d = ns.Theme.Get(theme)
    local fb, tints = {}, {}
    for name, v in pairs(d.fallback or {}) do fb[hex(ns.Theme.ParseColor(v))] = name end
    for _, v in pairs(d.tint or {}) do tints[hex(ns.Theme.ParseColor(v))] = true end
    local twice, flat, tinted = {}, 0, 0
    for _, f in ipairs(W.BM.frames) do
      if f._kind == "Texture" then
        local c, v = f._color, f._vc
        if c and fb[hex(c)] then
          flat = flat + 1
          if not white(v) then twice[#twice + 1] = fb[hex(c)] .. " " .. hex(c) .. " x " .. hex(v) .. " at " .. tostring(f._src) end
        end
        if not c and v and tints[hex(v)] and not white(v) then tinted = tinted + 1 end
      end
    end
    if fails then
      check(n .. "fallback colours shown", flat > 0, flat)
      check(n .. "no fallback colour tinted a second time", #twice == 0, table.concat(twice, "; "))
    else
      check(n .. "the theme's tint lies on its textures", tinted > 0, tinted)
    end
    check(n .. "no errors", #W.AM.errors == 0 and #W.BM.violations == 0, W.AM.errors[1] or W.BM.violations[1])
  end
end

-- a cover without its own slip tint colours the notice slip like its paper
do
  local W = world("deDE", "noslip", false)
  local ns = W.ns
  check("noslip: theme active", ns.Theme.id == "noslip", ns.Theme.id)
  W.tick(30); W.settle()
  local b = rawget(W.BM.G, "DeathNoteBanner")
  local paper = ns.Look.TINT.paper
  local v = b and b.bg and b.bg._vc
  check("noslip: the slip carries the paper's tint", v and paper and hex(v) == hex(paper), v and hex(v))
end

io.write(("Theme fallback colours: %d green, %d red\n"):format(okN, badN))
os.exit(badN == 0 and 0 or 1)
