-- Shared head of the UI proof tests (design rollback). Usage per file:
--   nice -n 15 luajit <file> <project copy>
-- Loads the real logic per world (tests/mock_wow.lua) and the UI through the UI mock (tests/ui/mock.lua)
-- of the given copy. All names are made up. Checks go through keys and data, never through wording.
local K = {}
local DIR = assert(arg and arg[1], "Aufruf: luajit <datei> <Projektkopie>"):gsub("/+$", "")
K.DIR = DIR
K.ADDON = DIR .. "/DeathNote"
package.path = DIR .. "/tests/ui/?.lua;" .. DIR .. "/tests/?.lua;" .. package.path
arg[0] = DIR .. "/tests/ui/beleg.lua"

K.CODES = { "enUS", "deDE", "frFR", "esES", "itIT", "ptBR", "ruRU", "koKR", "zhCN", "zhTW", "svSE", "nbNO",
  "daDK", "fiFI", "nlNL", "plPL", "csCZ", "huHU", "hrHR", "ukUA", "trTR" }

-- Width estimate as in the final hunt (characters x font size x factor, CJK as em square)
local function wide(cp)
  return (cp >= 0x1100 and cp <= 0x115F) or (cp >= 0x2E80 and cp <= 0xA4CF) or (cp >= 0xAC00 and cp <= 0xD7A3)
    or (cp >= 0xF900 and cp <= 0xFAFF) or (cp >= 0xFE30 and cp <= 0xFE4F) or (cp >= 0xFF00 and cp <= 0xFF60)
end
K.wide = wide
local FACT = { ["Fonts\\MORPHEUS.TTF"] = 0.5, ["Fonts\\MORPHEUS_CYR.TTF"] = 0.5, ["Fonts\\FRIZQT__.TTF"] = 0.52,
  ["Fonts\\FRIZQT___CYR.TTF"] = 0.55, ["Fonts\\NIM_____.ttf"] = 0.45, ["Fonts\\SKURRI_CYR.TTF"] = 0.6,
  ["Fonts\\SKURRI.TTF"] = 0.6, ["Fonts\\ARIALN.TTF"] = 0.42 }
function K.estimate(fs)
  local t = fs._text
  if type(t) ~= "string" then return 0 end
  t = t:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
  local size, f = fs._fontSize or 12, FACT[fs._font] or 0.5
  local best = 0
  for line in (t .. "\n"):gmatch("([^\n]*)\n") do
    local w, i, n = 0, 1, #line
    while i <= n do
      local b = line:byte(i)
      local len = b >= 0xF0 and 4 or b >= 0xE0 and 3 or b >= 0xC0 and 2 or 1
      local cp = b
      if len == 3 then cp = (b - 0xE0) * 4096 + ((line:byte(i + 1) or 128) - 128) * 64 + ((line:byte(i + 2) or 128) - 128) end
      w = w + (wide(cp) and 1.0 or f) * size
      i = i + len
    end
    if w > best then best = w end
  end
  return best
end

-- Line count of a wrapping text of width w (word wrap at spaces; CJK breaks per character)
function K.lines(fs, w)
  local t = fs._text
  if type(t) ~= "string" or t == "" then return 0 end
  local size, f = fs._fontSize or 12, FACT[fs._font] or 0.5
  local n, cur = 1, 0
  local function cw(s)
    local x, i = 0, 1
    while i <= #s do
      local b = s:byte(i)
      local len = b >= 0xF0 and 4 or b >= 0xE0 and 3 or b >= 0xC0 and 2 or 1
      local cp = b
      if len == 3 then cp = (b - 0xE0) * 4096 + ((s:byte(i + 1) or 128) - 128) * 64 + ((s:byte(i + 2) or 128) - 128) end
      x = x + (wide(cp) and 1.0 or f) * size
      i = i + len
    end
    return x
  end
  -- units: words (with the following space), CJK characters one by one
  local units, i = {}, 1
  local word = ""
  while i <= #t do
    local b = t:byte(i)
    local len = b >= 0xF0 and 4 or b >= 0xE0 and 3 or b >= 0xC0 and 2 or 1
    local ch = t:sub(i, i + len - 1)
    local cp = b
    if len == 3 then cp = (b - 0xE0) * 4096 + ((t:byte(i + 1) or 128) - 128) * 64 + ((t:byte(i + 2) or 128) - 128) end
    if ch == " " then units[#units + 1] = word .. " "; word = ""
    elseif ch == "\n" then units[#units + 1] = word; units[#units + 1] = "\n"; word = ""
    elseif wide(cp) then if word ~= "" then units[#units + 1] = word; word = "" end; units[#units + 1] = ch
    else word = word .. ch end
    i = i + len
  end
  if word ~= "" then units[#units + 1] = word end
  for _, u in ipairs(units) do
    if u == "\n" then n = n + 1; cur = 0
    else
      local x = cw(u)
      local bare = cw((u:gsub(" $", "")))
      if cur > 0 and cur + bare > w then n = n + 1; cur = 0 end
      cur = cur + x
    end
  end
  return n
end

-- A fresh world. opts: guild (text or false), friends (list), db, humor (load Humor.lua),
-- before (function before loading), noOpen
function K.world(code, opts)
  opts = opts or {}
  package.loaded.mock_wow, package.loaded.mock = nil, nil
  local AM = require("mock_wow")
  local BM = require("mock")
  BM.mediaDir = K.ADDON .. "/Media"
  AM.locale = code or "deDE"
  local FR = opts.friends or { "Fritz Frei" }
  local ns = AM.Load({ noLogin = true, db = opts.db, before = function()
    if opts.guild ~= false then AM.units.player.guild = opts.guild or "Die Testgilde" end
    _G.C_FriendList = {
      GetNumFriends = function() return #FR end,
      GetFriendInfoByIndex = function(i) local n = FR[i]; if n then return { name = n, connected = true } end end,
      ShowFriends = function() end,
    }
    if opts.before then opts.before(AM, BM) end
  end })
  local files = { "Alert.lua", "UI.lua", "Extras.lua" }
  if opts.humor then files[#files + 1] = "Humor.lua" end
  for _, f in ipairs(files) do BM.Load(K.ADDON .. "/" .. f, ns) end
  local mt = getmetatable(BM.frames[1])
  local i = 1
  while true do
    local n, v = debug.getupvalue(mt.__index, i)
    if not n then break end
    if n == "methods" then v.GetStringWidth = function(self) return K.estimate(self) end end
    i = i + 1
  end
  AM.FireEvent("PLAYER_LOGIN")
  AM.FireEvent("PLAYER_ENTERING_WORLD")
  local W = { ns = ns, AM = AM, BM = BM, G = BM.G, L = ns.L, FR = FR, P = ns.Guild and ns.Guild.Proto }
  function W.tick(s) AM.Advance(s or 0.1); BM.Advance(s or 0.1) end
  function W.settle() BM.Advance(13); BM.FinishAnims(); BM.Advance(1); BM.FinishAnims(); BM.Advance(1) end
  function W.frameWith(pred) for _, f in ipairs(BM.frames) do if pred(f) then return f end end end
  function W.all(pred) local o = {} for _, f in ipairs(BM.frames) do if pred(f) then o[#o + 1] = f end end return o end
  function W.click(f, b) f._scripts.OnClick(f, b or "LeftButton"); W.tick() end
  function W.tab(id) local t = W.frameWith(function(f) return f.id == id and f._scripts and f._scripts.OnClick end); W.click(t) end
  function W.gmsg(text, from) AM.FireEvent("CHAT_MSG_ADDON", "DeathNote", text, "GUILD", from or "Kollege-Forever") end
  function W.whisper(text, from) AM.FireEvent("CHAT_MSG_ADDON", "DeathNote", text, "WHISPER", from or "Fritz-Forever") end
  function W.rows()
    local out = {}
    for _, f in ipairs(BM.frames) do if f._kind == "Button" and f.item and f._shown and f.under and f:IsVisible() then out[#out + 1] = f end end
    table.sort(out, function(a, b) return (a.index or 0) < (b.index or 0) end)
    return out
  end
  function W.errs()
    local n = #AM.errors + #BM.violations
    local first = AM.errors[1] or BM.violations[1]
    AM.errors = {}
    for j = #BM.violations, 1, -1 do BM.violations[j] = nil end
    return n, first
  end
  -- key for a wording (for messages)
  W.keyOf = {}
  for k, v in pairs(ns.L) do if type(v) == "string" and not W.keyOf[v] then W.keyOf[v] = k end end
  -- Rectangle of an element in UI units, also with several anchors (SetAllPoints, TOPLEFT plus TOPRIGHT).
  -- FontString: rectangle of the ink (estimated width, line count from wrapping, justification). nil without position.
  local ANCH = { TOPLEFT = { 0, 1 }, TOP = { 0.5, 1 }, TOPRIGHT = { 1, 1 }, LEFT = { 0, 0.5 }, CENTER = { 0.5, 0.5 },
    RIGHT = { 1, 0.5 }, BOTTOMLEFT = { 0, 0 }, BOTTOM = { 0.5, 0 }, BOTTOMRIGHT = { 1, 0 } }
  local LINE = K.LINE or 1.0   -- line height per font size (client: line height = font size; K.LINE = 1.2 as a strict check)
  local function box(f, depth, ink)
    if f == BM.G.UIParent then return 0, 0, f._w, f._h end
    depth = (depth or 0) + 1
    if depth > 30 or not f._points or #f._points == 0 then return nil end
    local xs, ys = {}, {}
    for _, pt in ipairs(f._points) do
      local p, rel, rp, x, y = pt[1], pt[2], pt[3], pt[4], pt[5]
      if type(rel) == "number" then rel, rp, x, y = f._parent, p, pt[2], pt[3]
      elseif type(rel) == "string" then rel, rp, x, y = f._parent, rel, pt[3], pt[4] end
      rel, rp, x, y = rel or f._parent, rp or p, x or 0, y or 0
      if not rel or not ANCH[rp] or not ANCH[p] then return nil end
      local l, b, r, t = box(rel, depth, false)
      if not l then return nil end
      local a, q = ANCH[rp], ANCH[p]
      xs[q[1]] = l + (r - l) * a[1] + x
      ys[q[2]] = b + (t - b) * a[2] + y
    end
    local isText = f._kind == "FontString"
    local function span(c, size)
      -- edge plus middle (BOTTOMLEFT plus RIGHT, the pattern of the hint lines since 1.1.0): the edge counts
      if c[0.5] and (c[0] or c[1]) then c[0.5] = nil end
      local k1, k2
      for k in pairs(c) do if not k1 then k1 = k elseif k ~= k1 then k2 = k end end
      if k2 then
        local lo = c[k1] - (c[k2] - c[k1]) / (k2 - k1) * k1
        local full = (c[k2] - c[k1]) / (k2 - k1)
        return lo, lo + full, true
      end
      return c[k1] - size * k1, c[k1] - size * k1 + size, false
    end
    local est = isText and K.estimate(f) or 0
    local one = isText and (f._wrap == false or f._maxl == 1)
    local w = f._w or 0
    if isText and not f._wset then w = est end
    local L0, R0, wfix = span(xs, w)
    local bw = R0 - L0
    local h = f._h or 0
    local lines = 1
    if isText then
      if (f._wset or wfix) and not one and bw > 0 then lines = math.max(1, math.min(f._maxl or 99, K.lines(f, bw))) end
      local _, nl = (f._text or ""):gsub("\n", "")
      if nl + 1 > lines then lines = math.min(f._maxl or 99, nl + 1) end
      local th = lines * (f._fontSize or 12) * LINE + (lines - 1) * (f._spacing or 0)
      if not f._hset then h = th end
    end
    local B0, T0, hfix = span(ys, h)
    if isText and ink ~= false then
      -- ink in the box: horizontally by justification, vertically centred or at the top
      local iw = (lines > 1) and bw or math.min(est, bw > 0 and bw or est)
      if not f._wset and not wfix then iw = est end
      local jh = f._jh or "CENTER"
      local l = jh == "LEFT" and L0 or jh == "RIGHT" and (R0 - iw) or (L0 + (bw - iw) / 2)
      local th = lines * (f._fontSize or 12) * LINE + (lines - 1) * (f._spacing or 0)
      local bh = T0 - B0
      local jv = f._jv or "MIDDLE"
      local t = jv == "TOP" and T0 or jv == "BOTTOM" and (B0 + th) or (T0 - (bh - th) / 2)
      return l, t - th, l + iw, t, lines
    end
    return L0, B0, R0, T0, lines
  end
  W.box = function(f) return box(f, 0, true) end
  W.frameBox = function(f) return box(f, 0, false) end
  function W.under(f, root) local o = f; while o do if o == root then return true end; o = o._parent end return false end
  -- is a hung onto b (or the other way round) with all anchors? (click area over a text and the like)
  function W.tied(a, b)
    local function all(x, y)
      if not x._points or #x._points == 0 then return false end
      for _, pt in ipairs(x._points) do if pt[2] ~= y then return false end end
      return #x._points >= 2
    end
    return all(a, b) or all(b, a)
  end
  function W.nameOf(f)
    local t = f._kind == "FontString" and f._text or (type(f.text) == "table" and f.text._text) or (type(f.label) == "table" and f.label._text) or nil
    return (t and (W.keyOf[t] or ("(Daten)"))) or f._kind
  end
  -- Measure all visible texts and click areas under root. Returns a list of messages
  -- { art = "LAGE"|"FEST"|"KNOPF"|"RAND", a = name, b = name, x = px, y = px }.
  -- opts.extra(f): include more elements (e.g. stamp textures); opts.rand: distance to the edge of root
  function W.scan(root, opts)
    opts = opts or {}
    local items, out = {}, {}
    for _, f in ipairs(BM.frames) do
      if f ~= root and f.IsVisible and f:IsVisible() and (f._alpha or 1) > 0.05 and W.under(f, root)
         and (f._kind == "FontString" or f._kind == "Button" or f._kind == "CheckButton" or f._kind == "EditBox" or (opts.extra and opts.extra(f))) then
        if not (f._kind == "FontString" and (f._text == nil or f._text == "")) then
          local l, b, r, t, n = W.box(f)
          if l then items[#items + 1] = { f = f, l = l, b = b, r = r, t = t, n = n } end
        end
      end
    end
    local sl, sb, sr, st = W.frameBox(root)
    for i = 1, #items do
      local a = items[i]
      local fs = a.f._kind == "FontString"
      if fs and sl and opts.rand and (a.r > sr - opts.rand + 0.5 or a.l < sl + opts.rand - 0.5 or a.b < sb - 0.5 or a.t > st + 0.5) then
        out[#out + 1] = { art = "RAND", a = W.nameOf(a.f), x = math.floor(math.max(a.r - sr, sl - a.l)), y = math.floor(sb - a.b) }
      end
      if fs and a.f._wset and (a.f._wrap == false or a.f._maxl == 1) and K.estimate(a.f) > a.f._w + 1 then
        out[#out + 1] = { art = "FEST", a = W.nameOf(a.f), x = math.floor(K.estimate(a.f)), y = a.f._w }
      end
      local p = a.f._parent
      if fs and p and p._kind ~= "Frame" and not a.f._wset then
        local pl, pb, pr = W.frameBox(p)
        if pl and (a.r > pr + 1 or a.l < pl - 1) then out[#out + 1] = { art = "KNOPF", a = W.nameOf(a.f), x = math.floor(math.max(a.r - pr, pl - a.l)), y = 0 } end
      end
      for j = i + 1, #items do
        local c = items[j]
        if not W.tied(a.f, c.f) and a.f._parent ~= c.f and c.f._parent ~= a.f
           and not (a.f._parent == c.f._parent and a.f._parent._kind ~= "Frame") then
          local ox, oy = math.min(a.r, c.r) - math.max(a.l, c.l), math.min(a.t, c.t) - math.max(a.b, c.b)
          if ox > 2 and oy > 2 then
            out[#out + 1] = { art = "LAGE", a = W.nameOf(a.f), b = W.nameOf(c.f), x = math.floor(ox), y = math.floor(oy), fa = a.f, fb = c.f }
          end
        end
      end
    end
    return out, items
  end
  W.tick(30); W.settle()
  return W
end

-- Counters and summary
local rot, gruen = 0, 0
function K.check(name, cond, detail)
  if cond then gruen = gruen + 1
  else rot = rot + 1; print("rot   " .. name .. (detail ~= nil and ("  -> " .. tostring(detail)) or "")) end
  return cond
end
function K.info(s) print("      " .. s) end
function K.done(titel)
  print(("%s: %d gruen, %d rot"):format(titel, gruen, rot))
  os.exit(rot == 0 and 0 or 1)
end

return K
