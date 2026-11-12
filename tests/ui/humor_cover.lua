-- 1.3.0: the milestone "rank 1 paid back" (Humor.lua: stamp and remark on the notice) follows the top title of the
-- cover: the stamp is the show word STAMP_NR1_DOWN (Locale.THEME_KEYS, the cover's own word in every language), the
-- remark is the cover's one. No shown text of that notice carries the top title of another cover.
-- Also: every cover lays STAMP_NR1_DOWN over the base word in all 21 languages (the limits: tests/test_locales.lua).
-- Call from the project root: luajit tests/ui/humor_cover.lua .
local DIR = (arg[1] or "."):gsub("/+$", "")
package.path = DIR .. "/tests/ui/?.lua;" .. DIR .. "/tests/?.lua;" .. package.path
arg[0] = DIR .. "/tests/ui/humor_cover.lua"
local okN, badN = 0, 0
local function check(name, cond, info)
  if cond then okN = okN + 1 else badN = badN + 1; io.write("RED   ", name, info ~= nil and ("  -> " .. tostring(info)) or "", "\n") end
end

local function world(code, theme)
  package.loaded.mock_wow, package.loaded.mock = nil, nil
  local AM = require("mock_wow")
  local BM = require("mock")
  BM.mediaDir = DIR .. "/DeathNote/Media"
  AM.locale = code
  local ns = AM.Load({ noLogin = true, db = { settings = { ui = { theme = theme } } } })
  for _, f in ipairs({ "Alert.lua", "UI.lua", "Start.lua", "Extras.lua", "Humor.lua" }) do BM.Load(DIR .. "/DeathNote/" .. f, ns) end
  AM.FireEvent("PLAYER_LOGIN")
  AM.FireEvent("PLAYER_ENTERING_WORLD")
  local W = { AM = AM, BM = BM, ns = ns, G = BM.G }
  function W.tick(s) AM.Advance(s or 0.1); BM.Advance(s or 0.1) end
  function W.settle() BM.Advance(13); BM.FinishAnims(); BM.Advance(1); BM.FinishAnims(); BM.Advance(1) end
  return W
end

-- the top titles of all covers in one language
local TOP = {}
for _, code in ipairs({ "deDE", "enUS" }) do
  TOP[code] = {}
  for _, id in ipairs({ "notebook", "harbor", "trade" }) do TOP[code][id] = world(code, id).ns.L.STAMP_NR1 end
end
-- the leading word of a top title ("STAATSFEIND", "PUBLIC", "HÖCHSTES", ...)
local function root(s) return (s:match("^(%S+)") or s):upper() end

for _, theme in ipairs({ "notebook", "harbor", "trade" }) do
  for _, code in ipairs({ "deDE", "enUS" }) do
    local W = world(code, theme)
    local ns = W.ns
    local n = theme .. " " .. code .. ": "
    W.tick(30); W.settle(); W.AM.Advance(120)
    check(n .. "cover active", ns.Theme.Id() == theme, ns.Theme.Id())
    ns.Store.Setting("humor", true)
    local t = _G.time()
    local k = ns.Store.AddManual("Wilmwardwulf", "Mummelwammer")
    for i = 1, 3 do ns.Store.ApplyKill({ name = "Wilmwardwulf", surname = "Mummelwammer", class = "MAGE", level = 60 }, { t = t - 100 * i, zone = "Z" }, true) end
    W.tick(); W.settle()
    check(n .. "rank 1", ns.Store.Rank(k) == 1, ns.Store.Rank(k))
    ns.Store.AddRevenge(k)
    W.tick(0.5)
    local b = rawget(W.G, "DeathNoteBanner")
    local stamp = b and b.stampText and b.stampText:IsVisible() and b.stampText._text
    local quip = b and b.dnQuip and b.dnQuip:IsVisible() and b.dnQuip.text._text
    local T = ns.Humor.TEXTS[code]
    check(n .. "stamp is the cover's word STAMP_NR1_DOWN", stamp == ns.L.STAMP_NR1_DOWN, stamp)
    check(n .. "remark is the cover's one", quip == (T.MILESTONE["nr1_" .. theme] or T.MILESTONE.nr1), quip)
    if theme ~= "notebook" then check(n .. "the cover has its own remark", T.MILESTONE["nr1_" .. theme] ~= nil) end
    -- no text on screen names the top title of another cover
    for other, title in pairs(TOP[code]) do
      if other ~= theme and root(title) ~= root(TOP[code][theme]) then
        local hits = {}
        for _, f in ipairs(W.BM.frames) do
          local txt = f._kind == "FontString" and f._text
          if type(txt) == "string" and f:IsVisible() and txt:upper():find(root(title), 1, true) then hits[#hits + 1] = txt end
        end
        check(n .. "no top title of " .. other .. " on screen", #hits == 0, table.concat(hits, " / "))
      end
    end
    check(n .. "no errors", #W.AM.errors == 0 and #W.BM.violations == 0, W.AM.errors[1] or W.BM.violations[1])
  end
end

-- every cover has the word in every language (one block per language in Locales/Themes/<id>.lua)
for _, id in ipairs({ "harbor", "trade" }) do
  local f = assert(io.open(DIR .. "/DeathNote/Locales/Themes/" .. id .. ".lua"))
  local src = f:read("*a")
  f:close()
  local blocks, with = 0, 0
  local starts = {}
  for at in src:gmatch('()Locale%.RegisterWords%("' .. id .. '", "%a%a%a%a"') do starts[#starts + 1] = at end
  starts[#starts + 1] = #src + 1
  for i = 1, #starts - 1 do
    blocks = blocks + 1
    if src:sub(starts[i], starts[i + 1] - 1):find('T%.STAMP_NR1_DOWN%s*=%s*"[^"]+"') then with = with + 1 end
  end
  check(id .. ": STAMP_NR1_DOWN in every language block", blocks == 21 and with == 21, with .. " of " .. blocks)
end

io.write(("Humor milestone follows the cover: %d green, %d red\n"):format(okN, badN))
os.exit(badN == 0 and 0 or 1)
