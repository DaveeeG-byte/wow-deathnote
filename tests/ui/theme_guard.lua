-- 1.3.0 theme guard: the look comes from the theme and nowhere else.
-- Builds the same views twice (book with every tab and poster, case file, guild views, hit list, release sheet,
-- manual, house rules, export, menu, alarm, notices) in the UI mock with the real logic: once with the base theme
-- "notebook", once with the test theme "probe" (tests/ui/theme_probe.lua: every value of the schema replaced).
-- Then it compares the two frame trees element by element. A colour (rgb), texture path or font path that is the
-- same at the same element did not come from the theme: a red line with file:line where the object was made.
-- Fixed on purpose (not looked at): the addon icon and the client's technical textures (Look.TEX.icon, white,
-- classes, the minimap border), class colours (game data), fully transparent textures (alpha 0).
-- Also: every show word of the probe reaches the screen in place of the word of the black book.
-- Call from the project root: luajit tests/ui/theme_guard.lua . [code ...]
local DIR = (arg[1] or "."):gsub("/+$", "")
package.path = DIR .. "/tests/ui/?.lua;" .. DIR .. "/tests/?.lua;" .. package.path
arg[0] = DIR .. "/tests/ui/theme_guard.lua"
local CODES = {}
for i = 2, #arg do CODES[#CODES + 1] = arg[i] end
-- Latin and Cyrillic: there every font role has its own file, so a role that does not come from the theme shows
if #CODES == 0 then CODES = { "deDE", "enUS", "ruRU" } end
local ADDON = DIR .. "/DeathNote"
local ok, bad = 0, 0
local function check(name, cond, info)
  if cond then ok = ok + 1 else bad = bad + 1; io.write("RED   ", name, info ~= nil and ("  -> " .. tostring(info)) or "", "\n") end
end

local AM, BM, G
local function world(code, theme, db)
  package.loaded.mock_wow, package.loaded.mock = nil, nil
  AM = require("mock_wow")
  BM = require("mock")
  BM.mediaDir = ADDON .. "/Media"
  BM.trace = true
  G = BM.G
  AM.locale = code
  local FR = { "Fritz Frei" }
  local files = {}
  for _, f in ipairs(AM.FILES) do
    files[#files + 1] = f
    if f == "Themes/notebook.lua" then files[#files + 1] = "../tests/ui/theme_probe.lua" end
  end
  local saved = AM.FILES
  AM.FILES = files
  local ns = AM.Load({ noLogin = true, db = db or { settings = { ui = { theme = theme } } }, before = function()
    AM.units.player.guild = "Die Wuchtwaldwallwaechter"
    _G.C_FriendList = {
      GetNumFriends = function() return #FR end,
      GetFriendInfoByIndex = function(i) local n = FR[i]; if n then return { name = n, connected = true } end end,
      ShowFriends = function() end,
    }
  end })
  AM.FILES = saved
  for _, f in ipairs({ "Alert.lua", "UI.lua", "Extras.lua", "Humor.lua" }) do BM.Load(ADDON .. "/" .. f, ns) end
  AM.FireEvent("PLAYER_LOGIN")
  AM.FireEvent("PLAYER_ENTERING_WORLD")
  return ns
end
local function tick(s) AM.Advance(s or 0.1); BM.Advance(s or 0.1) end
local function settle() BM.Advance(13); BM.FinishAnims(); BM.Advance(1); BM.FinishAnims(); BM.Advance(1) end

-- the views of the layout guard, in one fixed order (both runs build the same objects in the same order)
local function views(ns)
  local P = ns.Guild.Proto
  tick(30); settle(); AM.Advance(120)
  local function gmsg(text, from) AM.FireEvent("CHAT_MSG_ADDON", "DeathNote", text, "GUILD", from or "Kollege-Forever") end
  local long = "Maximilianus Wunderkammer"
  local t = _G.time()
  local k1 = ns.Store.AddManual("Maximilianus", "Wunderkammer")
  ns.Store.SetNote(k1, "A note.")
  ns.Store.ApplyKill({ name = "Maximilianus", surname = "Wunderkammer", class = "MAGE", level = 60 }, { t = t - 100, zone = "Z" }, true)
  ns.Store.ApplyKill({ name = "Maximilianus", surname = "Wunderkammer", class = "MAGE", level = 60 }, { t = t - 50, zone = "Z" }, true)
  local k2 = ns.Store.AddManual("Bartholomaeus", "Donnerschlag")
  local k3 = ns.Store.AddManual("Konstantinos", "Abendroete")
  ns.Store.AddRevenge(k1); ns.Store.AddRevenge(k1)
  if ns.Store.Pardon then pcall(ns.Store.Pardon, k3) end
  gmsg(P.EncodeKill({ key = "Maximilianus-Wunderkammer", display = long, class = "MAGE", level = 60, zone = "Z", t = t - 30, victim = "Kollege Langername" }, "K"))
  for i = 1, 2 do
    gmsg(P.EncodeHunt({ key = "Ziel" .. string.char(64 + i) .. "-Wunderkammer", display = "Ziel" .. string.char(64 + i) .. "ianus Wunderkammer",
      class = "ROGUE", level = 55 + i, t = t - 86400 * i, by = "Kollege Langername", why = "Camps the road" }))
  end
  gmsg(P.EncodeBagged("ZielA-Wunderkammer", "Kollege Langername", t))
  tick(10); settle()
  ns:Fire("TOGGLE_UI"); tick(); settle()
  ns.UI.ShowEnemy(k1); tick(); settle()
  ns.UI.ShowEnemy(k3); tick(); settle()
  ns.UI.ShowEnemy(k2); tick(); settle()
  local function tab(id)
    for _, f in ipairs(BM.frames) do
      if f.id == id and f._scripts and f._scripts.OnClick then f._scripts.OnClick(f, "LeftButton"); break end
    end
    tick(); settle()
  end
  tab("journal"); tab("open"); tab("guild")
  for _, v in ipairs({ "enemy", "member", "hunt" }) do ns.UI.SetGuildView(v); tick(); settle() end
  ns.UI.ShowHunts("ZielB-Wunderkammer"); tick(); settle()
  ns.UI.ShowHunts("ZielA-Wunderkammer"); tick(); settle()
  ns.UI.OpenRelease(k1); tick()
  ns.UI.ClosePanel(); tick()
  ns.UI.OpenPanel("help"); tick()
  ns.UI.OpenPanel("settings"); tick(); settle()
  local RP
  for _, f in ipairs(BM.frames) do if f.release and f.settings then RP = f end end
  local S = RP and RP.settings
  for i = 1, 3 do
    if S and S.tabs[i] and S.tabs[i]:IsShown() then S.tabs[i]._scripts.OnClick(S.tabs[i]); tick() end
  end
  ns.UI.OpenIO("export"); tick()
  ns.UI.ClosePanel(); tick()
  tab("wanted")
  for _, f in ipairs(BM.frames) do
    if f.item and f.under and f:IsVisible() and f._scripts.OnClick then f._scripts.OnClick(f, "RightButton"); break end
  end
  local menu = rawget(G, "DeathNoteMenu")
  if menu and menu:IsShown() then menu.blocker._scripts.OnClick(menu.blocker) end
  ns:Fire("TOGGLE_UI"); tick()
  BM.levels.player = 1
  BM.levels.mouseover = 60
  AM.AddEnemy("mouseover", { name = "Maximilianus", surname = "Wunderkammer", guid = "Player-1-MW", level = 60, class = "MAGE" })
  AM.FireEvent("UPDATE_MOUSEOVER_UNIT"); tick()
  local popup = rawget(G, "DeathNoteAlert")
  if popup and popup._scripts.OnEnter then popup._scripts.OnEnter(popup); popup._scripts.OnLeave(popup) end
  settle()
  ns:Fire("GUILD_ENEMY_SPOTTED", "ZielB-Wunderkammer", nil, "other", "hunt"); tick(); settle()
  ns:Fire("HUNT_BAGGED", "ZielA-Wunderkammer", "Kollege Langername", _G.time(), "guild"); tick(); settle()
  ns:Fire("REVENGE", k1); tick(); settle()
  local j = { t = _G.time(), kind = "pvp", sure = true, counted = true, killerKey = k2, candidates = {} }
  ns.Store.RecordDeath(j)
  ns:Fire("DEATH_RECORDED", j, k2); tick(); settle()
end

-- the values of one tree: per object kind, colours, texture, font, text, file:line
local COLS = { "_color", "_vc", "_tc", "_bdc", "_bdb", "_shadowc" }
local function snapshot()
  local out = {}
  for i, f in ipairs(BM.frames) do
    local o = { kind = f._kind, src = f._src, tex = f._tex, font = f._font, text = f._text }
    for _, k in ipairs(COLS) do o[k] = f[k] end
    -- the backdrop's own colours live in _bd (bgFile, edgeFile)
    if type(f._bd) == "table" then o.bg, o.edge = f._bd.bgFile, f._bd.edgeFile end
    out[i] = o
  end
  return out
end

local FIXED_TEX = {}
local CLASS = {}
local function rgbKey(c) return ("%.4f %.4f %.4f"):format(c[1] or -1, c[2] or -1, c[3] or -1) end

for _, code in ipairs(CODES) do
  local ns = world(code, "notebook")
  check(code .. ": base theme active", ns.Theme.id == "notebook", ns.Theme.id)
  FIXED_TEX[ns.Look.TEX.icon], FIXED_TEX[ns.Look.TEX.white], FIXED_TEX[ns.Look.TEX.classes] = true, true, true
  FIXED_TEX["Interface\\Minimap\\MiniMap-TrackingBorder"], FIXED_TEX["Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight"] = true, true
  for _, c in pairs(_G.RAID_CLASS_COLORS or {}) do CLASS[rgbKey({ c.r, c.g, c.b })] = true end
  local base = ns.L
  -- show words of the black book; a word that a control key has as well (TAB_GUILD "Guild" = SRC_GUILD) can not be
  -- told apart on screen and is left out
  local words, control = {}, {}
  for k, v in pairs(base) do if type(v) == "string" and not ns.Locale.THEME_KEYS[k] then control[v] = true end end
  for k in pairs(ns.Locale.THEME_KEYS) do
    local w = rawget(base, k)
    if type(w) == "string" and not control[w] then words[k] = w end
  end
  views(ns)
  local A = snapshot()
  local onBase = {}
  for t in pairs(BM.texts) do for k, w in pairs(words) do if t == w or t:find("^" .. w:gsub("%p", "%%%0") .. "%s+%d+$") then onBase[k] = true end end end
  local errA = #AM.errors + #BM.violations

  ns = world(code, "probe")
  check(code .. ": probe theme active", ns.Theme.id == "probe", ns.Theme.id)
  views(ns)
  local B = snapshot()
  check(code .. ": no errors in either run", errA == 0 and #AM.errors + #BM.violations == 0, tostring(AM.errors[1] or BM.violations[1]))
  check(code .. ": same objects in both runs", #A == #B, #A .. " / " .. #B)

  local leaks, seen = {}, {}
  local function leak(what, o)
    local id = what .. " " .. tostring(o.src)
    if seen[id] then return end
    seen[id] = true
    leaks[#leaks + 1] = ("%s at %s (%s)"):format(what, tostring(o.src), tostring(o.kind))
  end
  local compared = 0
  for i = 1, math.min(#A, #B) do
    local a, b = A[i], B[i]
    for _, k in ipairs(COLS) do
      local x, y = a[k], b[k]
      if type(x) == "table" and type(y) == "table" then
        compared = compared + 1
        local same = rgbKey(x) == rgbKey(y)
        local invisible = (x[4] == 0 and y[4] == 0)
        if same and not invisible and not CLASS[rgbKey(x)] then leak(k .. " " .. rgbKey(x), a) end
      end
    end
    for _, k in ipairs({ "tex", "font", "bg", "edge" }) do
      if type(a[k]) == "string" and a[k] == b[k] and not FIXED_TEX[a[k]] then compared = compared + 1; leak(k .. " " .. a[k], a) end
    end
    -- texts: a show word of the black book that still stands at the same place
    if type(a.text) == "string" and a.text == b.text then
      for k, w in pairs(words) do
        if a.text == w and #w >= 3 then leak("word " .. k .. " '" .. w .. "'", a) end
      end
    end
  end
  table.sort(leaks)
  check(("%s: every colour, texture and font from the theme (%d values compared)"):format(code, compared), #leaks == 0,
    "\n      " .. table.concat(leaks, "\n      "))
  -- the probe's words are on screen
  local shown = {}
  for t in pairs(BM.texts) do for k in t:gmatch("ZZ ([A-Z_0-9]+)") do shown[k] = true end end
  for t in pairs(BM.texts) do if t:find("ZZTITLE", 1, true) then shown.BOOK_TITLE = true end; if t:find("ZZHEAD", 1, true) then shown.POSTER_HEAD = true end end
  local n = 0
  for k in pairs(onBase) do
    n = n + 1
    check(code .. ": the probe's word stands where the black book shows " .. k, shown[k] == true)
  end
  check(code .. ": show words of the black book seen in the views", n >= 8, n)
end

---------------------------------------------------------------------------
-- The real themes (every registered theme except the base and the probe): where a theme sets its own value,
-- no value of the black book shows through. Colours (rgb) and textures the theme replaces must not stand at the
-- same element in both runs; values the theme keeps (or uses for another role) are allowed. The theme's own
-- show words stand where the black book shows its word.
---------------------------------------------------------------------------
local function copy(t)
  if type(t) ~= "table" then return t end
  local o = {}
  for k, v in pairs(t) do o[k] = copy(v) end
  return o
end
local REAL = {}
do
  local ns = world("enUS", "notebook")
  for _, id in ipairs(ns.Theme.List()) do if id ~= "notebook" and id ~= "probe" then REAL[#REAL + 1] = id end end
end
check("real themes registered (harbor, trade)", #REAL >= 2, table.concat(REAL, ","))

for _, code in ipairs(CODES) do
  local ns0 = world(code, "notebook")
  local base = ns0.L
  local nbTex = copy(ns0.Look.TEX)
  local nbBlank, nbBaked = copy(ns0.Look.STAMP_BLANK), copy(ns0.Look.STAMP_BAKED)
  local control = {}
  for k, v in pairs(base) do if type(v) == "string" and not ns0.Locale.THEME_KEYS[k] then control[v] = true end end
  views(ns0)
  local A = snapshot()
  for _, id in ipairs(REAL) do
    local ns = world(code, id)
    check(code .. " " .. id .. ": theme active", ns.Theme.id == id, ns.Theme.id)
    local T, d = ns.Theme, ns.Theme.Get(id)
    -- colours the theme replaces, minus every colour the theme itself shows (any role, also inherited)
    local own, forbidden = {}, {}
    for _, role in ipairs(T.COLORS) do own[rgbKey(T.Color(role, id))] = true end
    for key in pairs(d.tint or {}) do local c = T.ParseColor(d.tint[key]); if c then own[rgbKey(c)] = true end end
    for role in pairs(d.color or {}) do
      local nb = rgbKey(T.Color(role, "notebook"))
      if nb ~= rgbKey(T.Color(role, id)) and not own[nb] and not CLASS[nb] then forbidden[nb] = role end
    end
    -- textures the theme replaces (stamps: the theme's frames take the place of the black book's pictures)
    local ownTex, badTex = {}, {}
    for _, v in pairs(ns.Look.TEX) do ownTex[v] = true end
    for _, v in pairs(ns.Look.STAMP_BLANK) do ownTex[v] = true end
    for key in pairs(d.tex or {}) do if nbTex[key] and not ownTex[nbTex[key]] then badTex[nbTex[key]] = key end end
    if d.stamp then
      for _, t in ipairs({ nbBlank, nbBaked }) do for k, v in pairs(t) do if not ownTex[v] then badTex[v] = "stamp " .. k end end end
    end
    -- show words the theme replaces in this language
    local words = {}
    for k in pairs(ns.Locale.THEME_KEYS) do
      local w0, w1 = rawget(base, k), rawget(ns.L, k)
      if type(w0) == "string" and w0 ~= w1 and not control[w0] then words[k] = { w0, w1 } end
    end
    views(ns)
    local B = snapshot()
    check(code .. " " .. id .. ": no errors", #AM.errors + #BM.violations == 0, tostring(AM.errors[1] or BM.violations[1]))
    check(code .. " " .. id .. ": same objects as the black book", #A == #B, #A .. " / " .. #B)
    local leaks, seen, n = {}, {}, 0
    local function leak(what, o)
      local key = what .. " " .. tostring(o.src)
      if not seen[key] then seen[key] = true; leaks[#leaks + 1] = ("%s at %s (%s)"):format(what, tostring(o.src), tostring(o.kind)) end
    end
    for i = 1, math.min(#A, #B) do
      local a, b = A[i], B[i]
      for _, k in ipairs(COLS) do
        local x, y = a[k], b[k]
        if type(x) == "table" and type(y) == "table" and not (x[4] == 0 and y[4] == 0) then
          n = n + 1
          local r = rgbKey(x)
          if r == rgbKey(y) and forbidden[r] then leak(k .. " " .. forbidden[r] .. " " .. r, a) end
        end
      end
      for _, k in ipairs({ "tex", "bg", "edge" }) do
        if type(a[k]) == "string" then n = n + 1 end
        if type(a[k]) == "string" and a[k] == b[k] and badTex[a[k]] then leak(k .. " " .. badTex[a[k]] .. " " .. a[k], a) end
      end
      if type(a.text) == "string" and a.text == b.text then
        for k, w in pairs(words) do if a.text == w[1] and #w[1] >= 3 then leak("word " .. k .. " '" .. w[1] .. "'", a) end end
      end
    end
    table.sort(leaks)
    local nf, nt, nw = 0, 0, 0
    for _ in pairs(forbidden) do nf = nf + 1 end
    for _ in pairs(badTex) do nt = nt + 1 end
    for _ in pairs(words) do nw = nw + 1 end
    check(("%s %s: no value of the black book where the theme sets its own (%d colours, %d textures, %d words; %d values compared)")
      :format(code, id, nf, nt, nw, n), #leaks == 0 and nf > 0 and nt > 0, "\n      " .. table.concat(leaks, "\n      "))
    -- the theme's words reach the screen where the black book shows its word
    for k, w in pairs(words) do
      local onA, onB = false, false
      for i = 1, math.min(#A, #B) do
        if A[i].text == w[1] then onA = true end
        if B[i].text == w[2] then onB = true end
      end
      if onA then check(code .. " " .. id .. ": the theme's word stands where the black book shows " .. k, onB, w[2]) end
    end
  end
end

---------------------------------------------------------------------------
-- There and back: /dn theme <id>, reload, /dn theme notebook, reload: the book is the black book again
-- (every colour, texture, font and text of every element as in a fresh black book). Settings only travel.
---------------------------------------------------------------------------
do
  local code = CODES[1]
  local ns = world(code, "notebook")
  views(ns)
  local A = snapshot()
  local settings
  ns = world(code, nil, { settings = { ui = { theme = "notebook" } } })
  for _, id in ipairs(REAL) do
    _G.SlashCmdList.DEATHNOTE("theme " .. id)
    check(code .. ": /dn theme " .. id .. " is stored and waits for /reload", ns.Theme.Pending() and ns.Theme.StoredChoice() == id)
    settings = copy(_G.DeathNoteDB.settings)
    ns = world(code, nil, { settings = settings })
    check(code .. ": after the reload " .. id .. " is active", ns.Theme.id == id, ns.Theme.id)
  end
  _G.SlashCmdList.DEATHNOTE("theme notebook")
  check(code .. ": /dn theme notebook waits for /reload", ns.Theme.Pending() and ns.Theme.StoredChoice() == "notebook")
  settings = copy(_G.DeathNoteDB.settings)
  ns = world(code, nil, { settings = settings })
  check(code .. ": back on the black book", ns.Theme.id == "notebook", ns.Theme.id)
  views(ns)
  local C = snapshot()
  check(code .. ": same objects as before the round trip", #A == #C, #A .. " / " .. #C)
  local diff = {}
  for i = 1, math.min(#A, #C) do
    local a, c = A[i], C[i]
    for _, k in ipairs({ "tex", "font", "text", "bg", "edge" }) do
      if a[k] ~= c[k] and #diff < 8 then diff[#diff + 1] = ("%s %s: %s / %s"):format(tostring(a.src), k, tostring(a[k]), tostring(c[k])) end
    end
    for _, k in ipairs(COLS) do
      local x, y = a[k], c[k]
      if (type(x) == "table") ~= (type(y) == "table") or (type(x) == "table" and (rgbKey(x) ~= rgbKey(y) or x[4] ~= y[4])) then
        if #diff < 8 then diff[#diff + 1] = ("%s %s"):format(tostring(a.src), k) end
      end
    end
  end
  check(code .. ": every element as in a fresh black book after the round trip", #diff == 0, "\n      " .. table.concat(diff, "\n      "))
end

io.write(("theme guard: %d green, %d red\n"):format(ok, bad))
os.exit(bad == 0 and 0 or 1)
