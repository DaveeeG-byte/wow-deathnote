-- 1.3.0: the on-screen notice looks the same on its first appearance after loading as on every later one.
-- The frame is built at READY (hidden, alpha 0, textures and fonts set), every appearance starts at alpha 0 and
-- only fades (no animation brings it above its standing alpha, no scale jump of the frame), and the first and the
-- second notice of the same event have the same geometry, font sizes and textures.
-- Also: both building styles (Extras.BANNER_STYLE "slip" and "bare") build and show every kind of notice.
-- Use: luajit tests/ui/notice_first.lua [project folder]
local DIR = ((arg and arg[1]) or "."):gsub("/+$", "")
package.path = DIR .. "/tests/ui/?.lua;" .. DIR .. "/tests/?.lua;" .. package.path
local ADDON = DIR .. "/DeathNote"
local ok, bad = 0, 0
local function check(name, cond, info)
  if cond then ok = ok + 1
  else bad = bad + 1; io.write("RED   ", name, info ~= nil and ("  -> " .. tostring(info)) or "", "\n") end
end

-- a fresh world; style: building style of the notice (set right after Extras.lua loaded, before READY);
-- every alpha and scale animation the UI files create is recorded
local function world(code, style)
  package.loaded.mock_wow, package.loaded.mock = nil, nil
  local AM = require("mock_wow")
  local BM = require("mock")
  BM.mediaDir = ADDON .. "/Media"
  BM.measure = true
  AM.locale = code
  local ns = AM.Load({ noLogin = true })
  local anims = {}
  for _, f in ipairs({ "Alert.lua", "UI.lua", "Extras.lua", "Humor.lua" }) do
    if io.open(ADDON .. "/" .. f) then BM.Load(ADDON .. "/" .. f, ns) end
    if f == "Alert.lua" then
      local Look = ns.Look
      local A, S = Look.AlphaAnim, Look.ScaleAnim
      Look.AlphaAnim = function(g, from, to, dur, order, delay)
        anims[#anims + 1] = { kind = "alpha", g = g, from = from, to = to, order = order or 1 }
        return A(g, from, to, dur, order, delay)
      end
      Look.ScaleAnim = function(g, from, to, dur, order)
        anims[#anims + 1] = { kind = "scale", g = g, from = from, to = to, order = order or 1 }
        return S(g, from, to, dur, order)
      end
    end
    if f == "Extras.lua" and style then ns.Extras.BANNER_STYLE = style end
  end
  AM.FireEvent("PLAYER_LOGIN")
  AM.FireEvent("PLAYER_ENTERING_WORLD")
  local W = { AM = AM, BM = BM, G = BM.G, ns = ns, anims = anims }
  function W.tick(s) AM.Advance(s or 0.1); BM.Advance(s or 0.1) end
  function W.settle() BM.Advance(13); BM.FinishAnims(); BM.Advance(1); BM.FinishAnims(); BM.Advance(1) end
  return W
end

-- geometry, sizes, textures and colours of the parts of the notice
local function snapshot(W, b)
  local BM = W.BM
  local s = {}
  local function rect(o) local l, bt, r, t = BM.RectUI(o); return ("%.1f,%.1f,%.1f,%.1f"):format(l or -1, bt or -1, r or -1, t or -1) end
  s.frame = rect(b)
  for _, k in ipairs({ "kicker", "name", "line", "stampText" }) do
    local fs = b[k]
    s[k] = ("%s|%s|%s|%s|%s"):format(rect(fs), tostring(fs._fontSize), tostring(fs:IsShown()), tostring(fs._text),
      table.concat(fs._tc or {}, ","))
  end
  s.stamp = rect(b.stamp) .. "|" .. tostring(b.stamp._tex) .. "|" .. tostring(b.stamp:IsShown())
  s.bg = b.bg and tostring(b.bg._tex) or "none"
  return s
end

------------------------------------------------------------------------
-- 1) First against second appearance (deDE and enUS, the default style)
------------------------------------------------------------------------
for _, code in ipairs({ "deDE", "enUS" }) do
  local W = world(code)
  local ns, G = W.ns, W.G
  local b = rawget(G, "DeathNoteBanner")
  check(code .. " notice built at READY, before any event", b ~= nil)
  if b then
    check(code .. " built notice waits hidden at alpha 0", not b:IsShown() and b:GetAlpha() == 0, b:GetAlpha())
    if ns.Extras.BANNER_STYLE == "slip" then
      check(code .. " slip texture set at build time", b.bg and tostring(b.bg._tex):find("slip.tga", 1, true) ~= nil, b.bg and b.bg._tex)
    end
    check(code .. " name font set at build time (19 pt)", b.name._fontSize == 19, b.name._fontSize)
  end
  ns.Store.Setting("humor", false)   -- no surprise stamp of a milestone on the first revenge
  local t = _G.time()
  local k = ns.Store.AddManual("Torvik", "Greyhammer")
  ns.Store.ApplyKill({ name = "Torvik", surname = "Greyhammer", class = "WARRIOR", level = 60 }, { t = t - 100, zone = "Z" }, true)
  W.tick(30); W.settle()
  b = rawget(G, "DeathNoteBanner")
  if b then b:Hide() end
  local shots = {}
  for i = 1, 2 do
    ns:Fire("REVENGE", k)
    b = rawget(G, "DeathNoteBanner")
    check(code .. " appearance " .. i .. ": shown", b and b:IsShown())
    check(code .. " appearance " .. i .. ": starts at alpha 0 (the fade brings it in)", b and b:GetAlpha() == 0, b and b:GetAlpha())
    check(code .. " appearance " .. i .. ": fade-in running", b and b.inAnim and b.inAnim:IsPlaying())
    shots[i] = snapshot(W, b)
    W.settle()
    check(code .. " appearance " .. i .. ": gone after its time, back at alpha 0", not b:IsShown() and b:GetAlpha() == 0, b:GetAlpha())
  end
  for _, key in ipairs({ "frame", "kicker", "name", "line", "stamp", "stampText", "bg" }) do
    check(code .. " first equals second: " .. key, shots[1][key] == shots[2][key], tostring(shots[1][key]) .. "  vs  " .. tostring(shots[2][key]))
  end
  -- the animations of the notice: the frame only fades (from 0 to 1, then 1 to 0), no scale on the frame,
  -- nothing above the standing alpha (stamp 0.95)
  local frameGroups = { [b.inAnim] = true, [b.anim] = true }
  local nFrame, worst, scaleOnFrame = 0, 0, false
  for _, a in ipairs(W.anims) do
    if frameGroups[a.g] then
      nFrame = nFrame + 1
      if a.kind == "scale" then scaleOnFrame = true end
      if a.kind == "alpha" then worst = math.max(worst, a.from, a.to) end
    end
    if a.g == b.stampAnim and a.kind == "alpha" then
      check(code .. " stamp never above its standing alpha 0.95", a.to <= 0.95 and a.from <= 0.95, a.to)
    end
  end
  check(code .. " frame animations recorded", nFrame == 2, nFrame)
  check(code .. " frame never above alpha 1", worst <= 1, worst)
  check(code .. " no scale animation on the frame (no jump)", not scaleOnFrame)
end

------------------------------------------------------------------------
-- 2) Both styles: every kind of notice builds, no black surface, text colours readable on the surface
------------------------------------------------------------------------
for _, style in ipairs({ "slip", "bare" }) do
  local W = world("deDE", style)
  local ns, G = W.ns, W.G
  local b = rawget(G, "DeathNoteBanner")
  check(style .. ": style taken", ns.Extras.BANNER_STYLE == style and b and b.style == style, b and b.style)
  local t = _G.time()
  local k = ns.Store.AddManual("Torvik", "Greyhammer")
  ns.Store.ApplyKill({ name = "Torvik", surname = "Greyhammer", class = "PRIEST", level = 60 }, { t = t - 100, zone = "Z" }, true)
  W.tick(30); W.settle()
  ns:Fire("REVENGE", k)
  b = rawget(G, "DeathNoteBanner")
  check(style .. ": revenge notice shows", b and b:IsShown())
  -- no texture of the frame is a dark fill: no cover, no colour fill below the text
  local dark = {}
  for _, f in ipairs(W.BM.frames) do
    local o, under = f, false
    while o do if o == b then under = true; break end o = o._parent end
    if under and f._kind == "Texture" and f ~= b.stamp then
      local tex = tostring(f._tex or "")
      if tex:find("cover", 1, true) or f._color then dark[#dark + 1] = tex ~= "" and tex or "colour" end
    end
  end
  check(style .. ": no cover texture and no colour fill in the notice", #dark == 0, table.concat(dark, ","))
  check(style .. ": no backdrop edge", not (b.GetBackdrop and b:GetBackdrop()))
  if style == "bare" then
    local function shaded(fs) return fs._shadow and (fs._shadow[1] ~= 0 or fs._shadow[2] ~= 0) end
    check("bare: name, kicker and line carry a shadow", shaded(b.name) and shaded(b.kicker) and shaded(b.line))
  else
    -- priest white becomes dark ink on paper
    local c = b.name._tc
    check("slip: the name is class ink, not the white of the class", c and c[1] < 0.5 and c[2] < 0.5, c and table.concat(c, ","))
  end
end

io.write(("Notice first appearance and styles: %d green, %d red\n"):format(ok, bad))
os.exit(bad == 0 and 0 or 1)
