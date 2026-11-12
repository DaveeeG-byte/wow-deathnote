-- 1.2.2 layout guard ("nothing overlaps"): builds every view in all 21 languages with the longest data and
-- checks the frame tree in the UI mock with width factors at the wide end of the real fonts
-- (tests/ui/mock.lua: Nimrod 0.60, Friz 0.56, capitals 0.70, Morpheus 0.56, CJK 1.07 em, line 1.10).
-- Call from the project root: luajit tests/ui/layout_guard.lua . [code ...]
--   FLOW   running text (wraps, no line limit) shares its frame with something hanging at the bottom, outside a
--          scroll body (the pattern of the manual before 1.2.2)
--   CUT    a cut text (ellipsis or missing lines) without a way to read it whole (tooltip); the alarm popup
--          cannot have one (secure button above it), so nothing there may be cut
--   SIZE   a font size outside Look.SIZE
--   OVER   two visible texts or controls of the same view overlap by more than 1 px
--   OUT    a text or control leaves its page, poster, popup or banner
--   CLAMP  a frame opened at the cursor is not clamped or opens towards the near screen edge
--   PAGE   a scroll page: body inside its window, foot outside it, the wheel reaches the end and the start,
--          the bar only when needed
--   FIT    a text fitted by Look.FitText was written again past it (plain SetText keeps the size and wrap of
--          the old text)
-- Every message names file:line where the object was made, the language key of its text and the language.
-- DeathNote/Libs (foreign code) is not looked at.
local DIR = (arg[1] or "."):gsub("/+$", "")
package.path = DIR .. "/tests/ui/?.lua;" .. DIR .. "/tests/?.lua;" .. package.path
arg[0] = DIR .. "/tests/ui/layout_guard.lua"
local CODES = {}
for i = 2, #arg do CODES[#CODES + 1] = arg[i] end
if #CODES == 0 then CODES = { "enUS", "deDE", "frFR", "esES", "itIT", "ptBR", "ruRU", "koKR", "zhCN", "zhTW", "svSE", "nbNO",
  "daDK", "fiFI", "nlNL", "plPL", "csCZ", "huHU", "hrHR", "ukUA", "trTR" } end
local ADDON = DIR .. "/DeathNote"

-- Known and accepted, with the reason (keep short). Key: kind .. " " .. language key or "(data)" .. " " .. file
local ALLOW = {
}

local AM, BM, G
local function world(code)
  package.loaded.mock_wow, package.loaded.mock = nil, nil
  AM = require("mock_wow")
  BM = require("mock")
  BM.mediaDir = ADDON .. "/Media"
  BM.measure, BM.trace = true, true
  G = BM.G
  AM.locale = code
  local FR = { "Fritz Frei" }
  local ns = AM.Load({ noLogin = true, before = function()
    AM.units.player.guild = "Die Wuchtwaldwallwaechter"
    _G.C_FriendList = {
      GetNumFriends = function() return #FR end,
      GetFriendInfoByIndex = function(i) local n = FR[i]; if n then return { name = n, connected = true } end end,
      ShowFriends = function() end,
    }
  end })
  for _, f in ipairs({ "Alert.lua", "UI.lua", "Extras.lua", "Humor.lua" }) do
    if io.open(ADDON .. "/" .. f) then BM.Load(ADDON .. "/" .. f, ns) end
  end
  AM.FireEvent("PLAYER_LOGIN")
  AM.FireEvent("PLAYER_ENTERING_WORLD")
  return ns
end
local function tick(s) AM.Advance(s or 0.1); BM.Advance(s or 0.1) end
local function settle() BM.Advance(13); BM.FinishAnims(); BM.Advance(1); BM.FinishAnims(); BM.Advance(1) end

local total, perKind = 0, {}

-- rectangle of a region in UIParent units; texts get the box of their shown text (justify, wrapped height)
local function textBox(fs)
  local keepW, keepH, keepWs = fs._w, fs._h, fs._wset
  local eff = BM.EffWidth(fs)
  local U = BM.Unbounded(fs) or 0
  local lines = BM.Lines(fs)
  if fs._maxl and fs._maxl > 0 and lines > fs._maxl then lines = fs._maxl end
  local h = lines * (fs._fontSize or 12) * BM.LINE + math.max(0, lines - 1) * (fs._spacing or 0)
  local w = eff and (lines > 1 and eff or math.min(eff, U)) or U
  local l, b, r, t
  if #fs._points == 1 then
    fs._w, fs._h = eff or w, h
    l, b, r, t = BM.RectUI(fs)
    fs._w, fs._h, fs._wset = keepW, keepH, keepWs
  elseif #fs._points == 2 and eff then
    -- two anchors: left edge from the first, top from the first
    local p1 = fs._points[1]
    local probe = { _kind = "FontString", _parent = fs._parent, _points = { p1 }, _w = eff, _h = h }
    setmetatable(probe, getmetatable(fs))
    l, b, r, t = BM.RectUI(probe)
  end
  if not l then return nil end
  if eff and w < eff and lines <= 1 then
    local j = fs._jh or "CENTER"
    if j == "LEFT" then r = l + w elseif j == "RIGHT" then l = r - w else local c = (l + r) / 2; l, r = c - w / 2, c + w / 2 end
  end
  -- vertical: the client centres a single line in a taller box
  return l, b, r, t
end

local function isScrollChild(f) return f._parent and f._parent._child == f end
local function scrollClip(f)
  local o = f._parent
  while o do
    if o._kind == "ScrollFrame" then return o end
    o = o._parent
  end
end
local function under(f, anc)
  local o = f
  while o do if o == anc then return true end o = o._parent end
  return false
end

local function run(code)
  local ns = world(code)
  local L = ns.L
  local keyOf = {}
  for k, v in pairs(L) do if type(v) == "string" and not keyOf[v] then keyOf[v] = k end end
  local found, seen = {}, {}
  local function note(kind, where, f, what)
    local key = (f and f._text and keyOf[f._text]) or "(data)"
    local src = f and f._src or "?"
    local id = kind .. " " .. key .. " " .. src
    if ALLOW[id] then return end
    if seen[id .. where] then return end
    seen[id .. where] = true
    found[#found + 1] = ("  %-5s %-24s %-22s %s %s"):format(kind, where, src, key, what or "")
    perKind[kind] = (perKind[kind] or 0) + 1
  end
  local function visible(f)
    if not f:IsVisible() or (f._alpha or 1) < 0.05 then return false end
    local o = f
    while o do if (o._alpha or 1) < 0.05 then return false end o = o._parent end
    return true
  end
  -- inside the window of its scroll frame (else clipped by the client)
  -- the part inside the window of its scroll frame (the client clips the rest); nil when nothing shows
  local function inView(f, l, b, r, t)
    local sf = scrollClip(f)
    if not sf then return l, b, r, t end
    local sl, sb, sr, st = BM.RectUI(sf)
    if not sl then return l, b, r, t end
    b, t = math.max(b, sb), math.min(t, st)
    if t - b <= 1 then return nil end
    return l, b, r, t
  end
  local function hasTipWay(fs)
    if fs.tipOwner and fs.tipOwner:IsVisible() then return true end
    local o = fs._parent
    for _ = 1, 3 do
      if not o then break end
      if o._scripts and (o._scripts.OnEnter) then return true end
      o = o._parent
    end
    return false
  end

  local function scan(where, panel, opts)
    opts = opts or {}
    local pl, pb, pr, pt = BM.RectUI(panel)
    local items = {}
    for _, f in ipairs(BM.frames) do
      if f._kind == "FontString" and type(f._text) == "string" and f._text ~= "" and under(f, panel) and visible(f) then
        -- FIT
        if rawget(f, "fitText") ~= nil and f._text ~= f.fitText then note("FIT", where, f, "written past Look.FitText") end
        -- CUT
        local cut = f.IsTruncated and f:IsTruncated()
        if cut then
          if under(f, rawget(G, "DeathNoteAlert") or {}) then note("CUT", where, f, "cut in the alarm popup (no tooltip possible)")
          elseif not hasTipWay(f) then note("CUT", where, f, "cut without tooltip") end
        end
        -- FLOW
        if f._wrap ~= false and not (f._maxl and f._maxl > 0) and BM.EffWidth(f) and BM.Lines(f) > 1 and not scrollClip(f) then
          for _, g in ipairs(BM.frames) do
            if g ~= f and g._parent == f._parent and visible(g) and g._points[1] and tostring(g._points[1][1]):find("^BOTTOM")
               and (g._kind == "FontString" and g._text and g._text ~= "" or g._kind == "Button") then
              note("FLOW", where, f, "running text in the frame of a bottom-anchored " .. (g._src or "?"))
              break
            end
          end
        end
        if not f._rot then
          local l, b, r, t = textBox(f)
          if l then l, b, r, t = inView(f, l, b, r, t) end
          if l then items[#items + 1] = { f, l, b, r, t } end
        end
      elseif (f._kind == "Button" or f._kind == "CheckButton" or f._kind == "EditBox") and under(f, panel) and visible(f)
             and (f._backdrop or f._kind == "EditBox" or f._kind == "CheckButton") then
        local l, b, r, t = BM.RectUI(f)
        if l then l, b, r, t = inView(f, l, b, r, t) end
        if l then items[#items + 1] = { f, l, b, r, t, ctl = true } end
      end
    end
    for i = 1, #items do
      local a = items[i]
      if pl and not opts.noOut then
        local d = math.max(pl - a[2], a[4] - pr, pb - a[3], a[5] - pt)
        if d > 1 then note("OUT", where, a[1], ("%.1f px out of the view"):format(d)) end
      end
      for j = i + 1, #items do
        local c = items[j]
        if not under(a[1], c[1]) and not under(c[1], a[1]) then
          local ox = math.min(a[4], c[4]) - math.max(a[2], c[2])
          local oy = math.min(a[5], c[5]) - math.max(a[3], c[3])
          if ox > 2 and oy > 2 then   -- 2 px: the mock's line box (1.10 x size) is taller than the ink of a large word
            note("OVER", where, a[1], ("%.1f x %.1f over %s %s"):format(ox, oy, c[1]._src or "?", (c[1]._text and keyOf[c[1]._text]) or "(data)"))
          end
        end
      end
    end
  end
  local function page(where, pg, mustScroll)
    if not pg then note("PAGE", where, nil, "no scroll page"); return end
    local sf, body, foot = pg.scroll, pg.body, pg.foot
    if not (sf and body and foot) then note("PAGE", where, nil, "no page"); return end
    local vh = sf._h
    local range = sf:GetVerticalScrollRange()
    if (body._h or 0) - vh > 0.5 and not pg.bar:IsShown() then note("PAGE", where, nil, "content taller than its window, no bar") end
    if (body._h or 0) <= vh and pg.bar:IsShown() then note("PAGE", where, nil, "bar without need") end
    if mustScroll ~= nil and (range > 0) ~= mustScroll then note("PAGE", where, nil, "scrolls: " .. tostring(range > 0)) end
    -- the wheel reaches the end and the start
    local wheel = sf._scripts.OnMouseWheel
    for _ = 1, 100 do wheel(sf, -1) end
    if math.abs(sf:GetVerticalScroll() - range) > 0.5 then note("PAGE", where, nil, "wheel does not reach the end") end
    for _ = 1, 100 do wheel(sf, 1) end
    if sf:GetVerticalScroll() ~= 0 then note("PAGE", where, nil, "wheel does not reach the start") end
    -- the foot is no child of the scroll frame
    if under(foot, sf) then note("PAGE", where, nil, "foot inside the scroll window") end
  end

  -- data: long names, long reason, hit list, bounty, revenge, pardoned, suspect
  local P = ns.Guild.Proto
  tick(30); settle(); AM.Advance(120)
  local function gmsg(text, from) AM.FireEvent("CHAT_MSG_ADDON", "DeathNote", text, "GUILD", from or "Kollege-Forever") end
  local long = "Maximilianus Wunderkammer"
  local why = (code == "zhCN" or code == "zhTW") and "他在荆棘谷的路上一次又一次地偷袭我们公会的低级成员整整一个晚上都没有停手真的太过分了必须有人管管他才行啊啊"
    or "Camps the road in Stranglethorn all night long, again and x"
  local t = _G.time()
  local k1 = ns.Store.AddManual("Maximilianus", "Wunderkammer")
  ns.Store.SetNote(k1, "A note that is much longer than the field on the poster can show in one line.")
  ns.Store.ApplyKill({ name = "Maximilianus", surname = "Wunderkammer", class = "MAGE", level = 60 }, { t = t - 100, zone = "Schlingendorntal" }, true)
  ns.Store.ApplyKill({ name = "Maximilianus", surname = "Wunderkammer", class = "MAGE", level = 60 }, { t = t - 50, zone = "Schlingendorntal" }, true)
  local k2 = ns.Store.AddManual("Bartholomaeus", "Donnerschlag")
  local k3 = ns.Store.AddManual("Konstantinos", "Abendroete")
  ns.Store.AddRevenge(k1); ns.Store.AddRevenge(k1)
  if ns.Store.Pardon then pcall(ns.Store.Pardon, k3) end
  gmsg(P.EncodeKill({ key = "Maximilianus-Wunderkammer", display = long, class = "MAGE", level = 60, zone = "Schlingendorntal", t = t - 30, victim = "Kollege Langername" }, "K"))
  for i = 1, 4 do
    gmsg(P.EncodeHunt({ key = "Ziel" .. string.char(64 + i) .. "-Wunderkammer", display = "Ziel" .. string.char(64 + i) .. "ianus Wunderkammer",
      class = "ROGUE", level = 55 + i, t = t - 86400 * i, by = "Kollege Langername", why = why }))
  end
  gmsg(P.EncodeHunt({ key = "Maximilianus-Wunderkammer", display = long, class = "MAGE", level = 60, t = t - 5, by = "Zweiter Kollegenname", why = why }), "Zweiter-Forever")
  gmsg(P.EncodeBagged("ZielA-Wunderkammer", "Kollege Langername", t))
  tick(10); settle()

  ns:Fire("TOGGLE_UI"); tick(); settle()
  local F = rawget(G, "DeathNoteFrame")
  scan("list wanted", F)
  ns.UI.ShowEnemy(k1); tick(); settle()
  local RPf
  for _, f in ipairs(BM.frames) do if f.enemy and f.death then RPf = f end end
  scan("poster wanted", F)
  ns.UI.ShowEnemy(k3); tick(); settle(); scan("poster pardoned", F)
  ns.UI.ShowEnemy(k2); tick(); settle(); scan("poster plain", F)
  for _, f in ipairs(BM.frames) do
    if f.id == "journal" and f._scripts and f._scripts.OnClick then f._scripts.OnClick(f, "LeftButton"); break end
  end
  tick(); settle(); scan("case file", F)
  if RPf and RPf.death then page("case file", RPf.death.page) end
  for _, f in ipairs(BM.frames) do
    if f.id == "guild" and f._scripts and f._scripts.OnClick then f._scripts.OnClick(f, "LeftButton"); break end
  end
  tick(); settle()
  for _, v in ipairs({ "enemy", "member", "hunt" }) do ns.UI.SetGuildView(v); tick(); settle(); scan("guild " .. v, F) end
  ns.UI.ShowHunts("Maximilianus-Wunderkammer"); tick(); settle(); scan("poster hit list", F)
  ns.UI.ShowHunts("ZielA-Wunderkammer"); tick(); settle(); scan("poster taken", F)
  ns.UI.OpenRelease(k1); tick(); scan("release sheet", F)
  local RP
  for _, f in ipairs(BM.frames) do if f.release and f.settings then RP = f end end
  if RP and RP.release then page("release sheet", RP.release.page, false) end
  ns.UI.ClosePanel(); tick()
  ns.UI.OpenPanel("help"); tick(); scan("manual", F)
  if RP and RP.help then page("manual", RP.help.page) end
  -- manual: back and in again starts at the top
  if RP and RP.help and RP.help.page then
    RP.help.page.scroll._scripts.OnMouseWheel(RP.help.page.scroll, -3)
    ns.UI.ClosePanel(); ns.UI.OpenPanel("help"); tick()
    if RP.help.page.scroll:GetVerticalScroll() ~= 0 then note("PAGE", "manual", nil, "reopened, not at the top") end
  end
  ns.UI.OpenPanel("settings"); tick(); settle()
  local S = RP and RP.settings
  for i = 1, 3 do
    if S and S.tabs[i] and S.tabs[i]:IsShown() then
      S.tabs[i]._scripts.OnClick(S.tabs[i]); tick()
      scan("house rules " .. i, F)
      page("house rules " .. i, S.page, false)
      if S.page then S.page.scroll._scripts.OnMouseWheel(S.page.scroll, -3) end
    end
  end
  if S and S.gmore then
    S.gmore._scripts.OnClick(S.gmore); tick(); scan("house rules more", F); page("house rules more", S.page, false)
    S.gmore._scripts.OnClick(S.gmore); tick()
  end
  ns.UI.OpenIO("export"); tick(); scan("export", F)
  ns.UI.OpenIO("import"); tick(); scan("import", F)
  ns.UI.ClosePanel(); tick()
  -- menu at the bottom right edge of the screen
  local cx, cy = G.GetCursorPosition
  G.GetCursorPosition = function() return 2550, 10 end
  for _, f in ipairs(BM.frames) do
    if f.id == "wanted" and f._scripts and f._scripts.OnClick then f._scripts.OnClick(f, "LeftButton"); break end
  end
  tick(); settle()
  for _, f in ipairs(BM.frames) do
    if f.item and f.under and f:IsVisible() and f._scripts.OnClick then f._scripts.OnClick(f, "RightButton"); break end
  end
  local menu = rawget(G, "DeathNoteMenu")
  if menu and menu:IsShown() then
    if not menu._clamped then note("CLAMP", "menu", menu, "not clamped to the screen") end
    local p = menu._points[1] and menu._points[1][1]
    if p ~= "BOTTOMRIGHT" then note("CLAMP", "menu", menu, "opens towards the edge: " .. tostring(p)) end
    scan("menu", menu, { noOut = true })
    menu.blocker._scripts.OnClick(menu.blocker)
  else
    note("CLAMP", "menu", nil, "menu did not open")
  end
  G.GetCursorPosition = cx
  ns:Fire("TOGGLE_UI"); tick()
  -- alarm: own wanted far above you, also on the hit list
  BM.levels.player = 1
  BM.levels.mouseover = 60
  AM.AddEnemy("mouseover", { name = "Maximilianus", surname = "Wunderkammer", guid = "Player-1-MW", level = 60, class = "MAGE" })
  AM.FireEvent("UPDATE_MOUSEOVER_UNIT"); tick()
  local popup = rawget(G, "DeathNoteAlert")
  if popup and popup:IsShown() then scan("alarm", popup) else note("PAGE", "alarm", nil, "popup did not come") end
  settle()
  ns:Fire("GUILD_ENEMY_SPOTTED", "ZielB-Wunderkammer", nil, "other", "hunt"); tick()
  if popup and popup:IsShown() then scan("alarm hit list", popup) end
  settle()
  ns:Fire("HUNT_BAGGED", "ZielA-Wunderkammer", "Kollege Langername", _G.time(), "guild"); tick()
  local banner = rawget(G, "DeathNoteBanner")
  if banner and banner:IsShown() then scan("banner taken", banner) end
  settle()
  ns:Fire("REVENGE", k1); tick()
  if banner and banner:IsShown() then scan("banner revenge", banner) end
  settle()
  -- sizes only from the scale
  local SIZE_OK = {}
  for _, x in ipairs(ns.Look.SIZE) do SIZE_OK[x] = true end
  for s in pairs(BM.fontSizes or {}) do if not SIZE_OK[s] then note("SIZE", "all", nil, "font size " .. s) end end
  local errs = #AM.errors + #BM.violations
  if errs > 0 then found[#found + 1] = "  ERROR " .. tostring(AM.errors[1] or BM.violations[1]) end
  io.write(("%s: %d findings\n"):format(code, #found + errs))
  table.sort(found)
  for _, l in ipairs(found) do io.write(l .. "\n") end
  total = total + #found + errs
end

for _, c in ipairs(CODES) do run(c) end
local kinds = {}
for k, n in pairs(perKind) do kinds[#kinds + 1] = k .. " " .. n end
table.sort(kinds)
io.write(("Layout guard in %d languages: %d findings%s\n"):format(#CODES, total, #kinds > 0 and (" (" .. table.concat(kinds, ", ") .. ")") or ""))
os.exit(total == 0 and 0 or 1)
