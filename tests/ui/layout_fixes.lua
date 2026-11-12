-- 1.2.2 proofs for the findings of the second hunt over the layout diff (B01 to B13): each check went red on the
-- code before its fix and is green after it. Behaviour on the addon's own paths in the UI mock with measured widths.
-- Call from the project root: luajit tests/ui/layout_fixes.lua .
local DIR = (arg[1] or "."):gsub("/+$", "")
package.path = DIR .. "/tests/ui/?.lua;" .. DIR .. "/tests/?.lua;" .. package.path
arg[0] = DIR .. "/tests/ui/layout_fixes.lua"
local ADDON = DIR .. "/DeathNote"
local K = { ok = 0, bad = 0 }
function K.check(name, cond, info)
  if cond then K.ok = K.ok + 1
  else K.bad = K.bad + 1; io.write("RED   ", name, info ~= nil and ("  -> " .. tostring(info)) or "", "\n") end
end
-- a fresh world in one language; opts.before(AM, BM) runs before the addon loads (font factors of the mock)
function K.world(code, opts)
  opts = opts or {}
  package.loaded.mock_wow, package.loaded.mock = nil, nil
  local AM = require("mock_wow")
  local BM = require("mock")
  BM.mediaDir = ADDON .. "/Media"
  BM.measure = true
  BM.trace = true
  K.AM, K.BM, K.G = AM, BM, BM.G
  AM.locale = code
  local ns = AM.Load({ noLogin = true, before = function()
    AM.units.player.guild = "Die Wuchtwaldwallwaechter"
    if opts.before then opts.before(AM, BM) end
  end })
  for _, f in ipairs({ "Alert.lua", "UI.lua", "Extras.lua", "Humor.lua" }) do
    if io.open(ADDON .. "/" .. f) then BM.Load(ADDON .. "/" .. f, ns) end
  end
  AM.FireEvent("PLAYER_LOGIN")
  AM.FireEvent("PLAYER_ENTERING_WORLD")
  -- tooltip that keeps its lines
  local GT = BM.G.GameTooltip
  GT.SetOwner = function(self, o) self._lines = {}; self._owner = o end
  GT.SetText = function(self, t) self._lines = { t } end
  GT.AddLine = function(self, t) self._lines = self._lines or {}; self._lines[#self._lines + 1] = t end
  GT.AddDoubleLine = function(self, a, b) self._lines = self._lines or {}; self._lines[#self._lines + 1] = tostring(a) .. "  " .. tostring(b) end
  K.ns = ns
  return ns
end
function K.tick(s) K.AM.Advance(s or 0.1); K.BM.Advance(s or 0.1) end
function K.settle() local BM = K.BM; BM.Advance(13); BM.FinishAnims(); BM.Advance(1); BM.FinishAnims(); BM.Advance(1) end
function K.find(pred) for _, f in ipairs(K.BM.frames) do if pred(f) then return f end end end
function K.gmsg(text, from) K.AM.FireEvent("CHAT_MSG_ADDON", "DeathNote", text, "GUILD", from or "Kollege-Forever") end
function K.under(f, anc) local o = f; while o do if o == anc then return true end o = o._parent end return false end
-- text of the tooltip while hovering owner
function K.hover(owner)
  local GT = K.G.GameTooltip
  GT._lines = {}
  local f = owner._scripts and owner._scripts.OnEnter
  if f then f(owner) end
  local s = table.concat(GT._lines or {}, "\n")
  local g = owner._scripts and owner._scripts.OnLeave
  if g then pcall(g, owner) end
  return s
end
function K.plain(s) return (tostring(s):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")) end
local function hex(c) return ("|cff%02x%02x%02x"):format(c[1] * 255, c[2] * 255, c[3] * 255) end

------------------------------------------------------------------------
-- B01: the level in front of the alarm line survives every refresh of the line (ENEMY_UPDATED after the next
-- sighting, GUILD_UPDATED after any sync message), keeps its warning colour and the two-line fitting
------------------------------------------------------------------------
local function levelShown(popup, needle)
  for _, f in ipairs(K.BM.frames) do
    if f._kind == "FontString" and K.under(f, popup) and f:IsVisible() and type(f._text) == "string"
       and K.plain(f._text):find(needle, 1, true) then return true end
  end
  return false
end
for _, code in ipairs({ "deDE", "enUS", "ruRU" }) do
  local ns = K.world(code)
  local AM, BM, G, Look = K.AM, K.BM, K.G, ns.Look
  local k = ns.Store.AddManual("Hoch", "Drueber")
  BM.levels.player, BM.levels.mouseover = 40, 60
  AM.AddEnemy("mouseover", { name = "Hoch", surname = "Drueber", guid = "Player-1-HD", level = 60, class = "MAGE" })
  AM.FireEvent("UPDATE_MOUSEOVER_UNIT"); K.tick()
  local popup = rawget(G, "DeathNoteAlert")
  K.check(code .. " B01 own: alarm shows the level with the gap", popup and popup:IsShown() and levelShown(popup, "(+20)"))
  -- the enemy stays in view: the next lastSeen write comes after WRITE_EVERY seconds, the popup is still up (HOLD 12 s)
  K.tick((ns.Tracker and ns.Tracker.WRITE_EVERY or 5) + 1)
  AM.FireEvent("UPDATE_MOUSEOVER_UNIT"); K.tick()
  K.check(code .. " B01 own: level still shown after the next sighting", popup:IsShown() and levelShown(popup, "(+20)"), popup.line._text)
  ns:Fire("ENEMY_UPDATED", k); K.tick()
  K.check(code .. " B01 own: level still shown after ENEMY_UPDATED", popup:IsShown() and levelShown(popup, "(+20)"), popup.line._text)
  K.check(code .. " B01 own: level still in the warning colour after ENEMY_UPDATED",
    popup.line._text:sub(1, 10) == hex(Look.WARN), popup.line._text:sub(1, 10))
  K.settle()

  ns = K.world(code)
  AM, BM, G = K.AM, K.BM, K.G
  local P = ns.Guild.Proto
  K.tick(30); K.settle(); AM.Advance(120)
  local why = "Camps the road in Stranglethorn all night long, again and x"
  K.gmsg(P.EncodeHunt({ key = "Mit-Stufe", display = "Mit Stufe", level = 60, t = _G.time(), by = "Kollege Langername", why = why }))
  K.gmsg(P.EncodeHunt({ key = "Mit-Stufe", display = "Mit Stufe", level = 60, t = _G.time(), by = "Zweiter Kollegenname", why = why }), "Zweiter-Forever")
  K.tick(10); K.settle()
  BM.levels.player = 40
  ns:Fire("GUILD_ENEMY_SPOTTED", "Mit-Stufe", nil, "other", "hunt"); K.tick()
  popup = rawget(G, "DeathNoteAlert")
  K.check(code .. " B01 hit list: level shown, line whole", popup and popup:IsShown() and levelShown(popup, "(+20)")
    and not popup.line:IsTruncated(), popup and popup.line._text)
  ns:Fire("GUILD_UPDATED"); K.tick()
  K.check(code .. " B01 hit list: level still shown after GUILD_UPDATED", popup:IsShown() and levelShown(popup, "(+20)"), popup.line._text)
  K.check(code .. " B01 hit list: line not cut after GUILD_UPDATED", popup:IsShown() and not popup.line:IsTruncated(), popup.line._text)
end

------------------------------------------------------------------------
-- B06: the fuller name after a move of the entry (ENEMY_REKEYED) shrinks like the first one instead of being cut
------------------------------------------------------------------------
do
  local ns = K.world("deDE")
  local BM, G = K.BM, K.G
  local short = ns.Store.AddManual("Maximilianus")
  K.tick(30); for _ = 1, 3 do K.settle() end
  BM.levels.player = 40
  ns:Fire("ENEMY_SPOTTED", short, nil, "other"); K.tick()
  local popup = rawget(G, "DeathNoteAlert")
  K.check("B06 alarm for the first name, whole", popup and popup:IsShown() and not popup.name:IsTruncated(), popup and popup.name._text)
  local full = ns.Store.Promote("Maximilianus", "Wunderkammerdiener", "Player-1-MW"); K.tick()
  K.check("B06 the store moved the entry to the full key", type(full) == "string" and ns.Store.Get(full) ~= nil, tostring(full))
  K.check("B06 popup shows the fuller name", (popup.name._text or ""):find("Wunderkammerdiener", 1, true) ~= nil, popup.name._text)
  K.check("B06 the fuller name is whole (smaller instead of cut)", not popup.name:IsTruncated(),
    ("%.0f px at %s pt in 286 px"):format(BM.Unbounded(popup.name), tostring(popup.name._fontSize)))
end

------------------------------------------------------------------------
-- B02: nothing of Look.FitText sticks. The Humor stamp goes through it after the regular stamp word fitted on
-- one line ("REVENGE TAKEN"); a field of two lines keeps its wrap after a short text; a font changed from outside
-- is not taken for the cached answer. Title font at the measured width of the picture tool (0.56 em, capitals 0.50).
------------------------------------------------------------------------
do
  local ns = K.world("enUS", { before = function(_, BM)
    BM.CAPS = 0.50
    BM.WIDTH["Fonts\\SKURRI.TTF"], BM.WIDTH["Fonts\\SKURRI_CYR.TTF"] = 0.56, 0.56
  end })
  local BM, G, Look = K.BM, K.G, ns.Look
  ns.Store.Setting("humor", true)
  local t = _G.time()
  local k = ns.Store.AddManual("Maximilianus", "Wunderkammer")
  ns.Store.ApplyKill({ name = "Maximilianus", surname = "Wunderkammer", class = "MAGE", level = 60 }, { t = t - 100, zone = "Z" }, true)
  K.tick(30); K.settle()
  if ns.Humor then ns.Humor.QUIET = 0 end
  ns.Store.AddRevenge(k); K.tick()
  local banner = rawget(G, "DeathNoteBanner")
  local fs = banner and banner.stampText
  local want = ns.Humor and ns.Humor.TEXTS and ns.Humor.TEXTS.enUS and ns.Humor.TEXTS.enUS.STAMP.nr1
  K.check("B02 banner with the Humor stamp came", banner and banner:IsShown() and fs and fs:IsVisible() and fs._text == want, fs and fs._text)
  K.check("B02 Humor stamp text is not cut (two lines allowed)", fs and not fs:IsTruncated(),
    fs and ("wrap=" .. tostring(fs._wrap) .. " size=" .. tostring(fs._fontSize) .. " width " .. math.floor(BM.Unbounded(fs)) .. " in " .. tostring(fs._w)))
  K.check("B02 Humor stamp text went through Look.FitText", fs and fs.fitText == fs._text, fs and tostring(fs.fitText))
  -- the building block on its own
  local parent = G.CreateFrame("Frame", nil, G.UIParent)
  parent:SetSize(400, 200); parent:SetPoint("CENTER")
  local f2 = Look.Text(parent, "body", 11, Look.INK)
  f2:SetPoint("TOPLEFT", 0, 0); f2:SetWidth(200)
  local two = { sizes = { 11, 10 }, lines = 2 }
  Look.FitText(f2, "short", two)
  K.check("B02 a two-line field keeps its wrap after a text that took one line", f2._wrap == true and f2._maxl == 2,
    ("wrap %s, lines %s"):format(tostring(f2._wrap), tostring(f2._maxl)))
  Look.FitText(f2, "short", { sizes = { 11 } })
  K.check("B02 a one-line field ends without wrap", f2._wrap == false and f2._maxl == 1, tostring(f2._wrap))
  Look.FitText(f2, "short", two)
  Look.Font(f2, "body", 9)
  Look.FitText(f2, "short", two)
  K.check("B02 a font changed from outside is fitted again (not the cached answer)", f2._fontSize == 11, f2._fontSize)
end

------------------------------------------------------------------------
-- B03: a Chinese text without spaces that fits its lines is not "a word too wide" (the client breaks between
-- CJK characters); one that needs more lines still counts as cut, and so does a Latin word too wide in it
------------------------------------------------------------------------
for _, code in ipairs({ "zhCN", "zhTW" }) do
  local ns = K.world(code)
  local AM, BM, G, Look = K.AM, K.BM, K.G, ns.Look
  local parent = G.CreateFrame("Frame", nil, G.UIParent)
  parent:SetSize(400, 200); parent:SetPoint("CENTER")
  local fs = Look.Text(parent, "body", 11, Look.INK)
  fs:SetPoint("TOPLEFT", 0, 0); fs:SetWidth(286)
  local text = "他在荆棘谷的路上一次又一次地偷袭我们公会的低级成员整整一个晚上"   -- 31 characters: two lines of 286 px
  local opts = { sizes = { 11, 10 }, lines = 2, wrapFirst = true }
  local ret = Look.FitText(fs, text, opts)
  K.check(code .. " B03 FitText keeps 11 pt for a CJK text that fits two lines", ret == true and fs.cut == false and fs._fontSize == 11,
    ("ret=%s cut=%s size=%s"):format(tostring(ret), tostring(fs.cut), tostring(fs._fontSize)))
  ret = Look.FitText(fs, text .. text .. text, opts)
  K.check(code .. " B03 a CJK text of six lines is still cut", ret == false and fs.cut == true, tostring(ret))
  ret = Look.FitText(fs, "他在" .. ("W"):rep(40) .. "的路上", opts)
  K.check(code .. " B03 a Latin word wider than the line inside CJK is still cut", ret == false, tostring(ret))
  -- the real path: alarm for a target of the hit list, two releasers, a reason of 20 characters
  local P = ns.Guild.Proto
  K.tick(30); K.settle(); AM.Advance(120)
  local why = "他在荆棘谷的路上一次又一次地偷袭我们公会的"
  K.gmsg(P.EncodeHunt({ key = "Ziel-Eins", display = "Ziel Eins", class = "ROGUE", level = 55, t = _G.time(), by = "Kollege Langername", why = why }))
  K.gmsg(P.EncodeHunt({ key = "Ziel-Eins", display = "Ziel Eins", class = "ROGUE", level = 55, t = _G.time(), by = "Zweiter Kollegenname", why = why }), "Zweiter-Forever")
  K.tick(10); K.settle()
  BM.levels.player = 40
  ns:Fire("GUILD_ENEMY_SPOTTED", "Ziel-Eins", nil, "other", "hunt"); K.tick()
  local popup = rawget(G, "DeathNoteAlert")
  local line = popup and popup:IsShown() and popup.line
  K.check(code .. " B03 alarm came", line ~= nil)
  if line then
    K.check(code .. " B03 alarm line names both releasers at 11 pt (it fits two lines)",
      line._fontSize == 11 and K.plain(line._text):find("Zweiter", 1, true) ~= nil and line.cut ~= true,
      ("size %s, cut %s, text %s"):format(tostring(line._fontSize), tostring(line.cut), K.plain(line._text)))
  end
end

------------------------------------------------------------------------
-- B04: poster foot row. The widths are shared fairly: while the needs fit, no label and not the word is cut; a cut
-- label shows whole in its tooltip and the edge still turns red on hover (every InkButton). Cyrillic handwriting
-- at the measured width of the picture tool (0.71 em: "Викреслити" 96 px).
------------------------------------------------------------------------
do
  local ns = K.world("ukUA", { before = function(_, BM) BM.WIDTH["Fonts\\MORPHEUS_CYR.TTF"] = 0.71 end })
  local AM, BM = K.AM, K.BM
  local P = ns.Guild.Proto
  K.tick(30); K.settle(); AM.Advance(120)
  local t = _G.time()
  local k = ns.Store.AddManual("Anna", "Beispiel")
  ns.Store.ApplyKill({ name = "Anna", surname = "Beispiel", class = "MAGE", level = 60 }, { t = t - 86400, zone = "Z" }, true)
  K.gmsg(P.EncodeKill({ key = "Fremder-Langername", display = "Fremder Langername", class = "MAGE", level = 60, zone = "Z", t = t - 30, victim = "Kollege Lang" }, "K"))
  K.tick(10); for _ = 1, 4 do K.settle() end
  K.gmsg(P.EncodeHunt({ key = "Ziel-Eins", display = "Ziel Eins", class = "ROGUE", level = 55, t = t - 86400, by = "Kollege Lang", why = "x" }))
  K.tick(10); K.settle()
  ns:Fire("TOGGLE_UI"); K.tick(); K.settle()
  local E = K.find(function(f) return f.bounty and f.stampRache end)
  local seen = 0
  local function look(where)
    for i, b in ipairs(E.buttons) do
      if b:IsVisible() and (b.text._text or "") ~= "" then
        seen = seen + 1
        local tip = K.hover(b)
        K.check(("B04 ukUA %s, button %d '%s' whole, or whole in its tooltip"):format(where, i, b.text._text),
          not b.text:IsTruncated() or tip == b.text.full,
          ("%.1f px at %s pt in %s px, tooltip '%s'"):format(BM.Unbounded(b.text), tostring(b.text._fontSize), tostring(b.text._w), tip))
      end
    end
  end
  ns.UI.ShowEnemy(k); K.tick(); K.settle(); look("wanted")
  for _, f in ipairs(BM.frames) do if f.id == "guild" and f._scripts and f._scripts.OnClick then f._scripts.OnClick(f, "LeftButton"); break end end
  K.tick(); K.settle()
  ns.UI.SetGuildView("enemy"); K.tick(); K.settle(); look("guild enemy")
  ns.UI.SetGuildView("hunt"); K.tick(); K.settle()
  ns.UI.ShowHunts("Ziel-Eins"); K.tick(); K.settle(); look("hit list")
  K.check("B04 ukUA poster showed its buttons", seen >= 4, seen)
  -- at this width the needs (2 x 108 at 9 pt plus the word at 11 pt) are 301 px for 296: all give way a little
  K.check("B04 ukUA the word 'strike out' is whole, or whole in its tooltip", not E.strike.text:IsTruncated()
    or K.hover(E.strike) == ns.L.ACT_STRIKE, ("%.1f px in %s px"):format(BM.Unbounded(E.strike.text), tostring(E.strike.text._w)))
  for _, b in ipairs(E.buttons) do
    if b.text._text ~= "" then
      K.check("B04 ukUA label " .. b.text._text .. " loses at most 3 px", BM.Unbounded(b.text) - b.text._w <= 3,
        ("%.1f px in %s"):format(BM.Unbounded(b.text), tostring(b.text._w)))
    end
  end
  local _, _, r2 = BM.RectUI(E.buttons[2])
  local sl = BM.RectUI(E.strike)
  K.check("B04 ukUA second button ends before the word", r2 and sl and r2 <= sl + 0.5, r2 and sl and (r2 - sl))
  -- a label that cannot fit: tooltip with the whole label, the edge still turns red
  local b = E.buttons[1]
  local long = "Оголосити полювання на дуже довгу ціль"
  b:SetLabel(long)
  local tip = K.hover(b)
  K.check("B04 a cut poster label shows whole in its tooltip", b.text:IsTruncated() and tip == long, tip)
  local edge
  b._scripts.OnEnter(b); edge = b._bdb; b._scripts.OnLeave(b)
  K.check("B04 the edge of the button still turns red on hover", edge and edge[1] > 0.9, edge and edge[1])
  b:SetLabel("ok")
  K.check("B04 no tooltip once the label is whole again", K.hover(b) == "", K.hover(b))
end
-- every language: the needs of the foot row fit, so nothing in it is cut
for _, code in ipairs({ "enUS", "deDE", "frFR", "esES", "itIT", "ptBR", "ruRU", "koKR", "zhCN", "zhTW", "svSE", "nbNO",
  "daDK", "fiFI", "nlNL", "plPL", "csCZ", "huHU", "hrHR", "ukUA", "trTR" }) do
  local ns = K.world(code)
  local BM, L = K.BM, ns.L
  ns.Store.AddManual("Anna", "Beispiel")
  K.tick(30); K.settle()
  ns:Fire("TOGGLE_UI"); K.tick(); K.settle()
  local E = K.find(function(f) return f.bounty and f.stampRache end)
  local worst, what = -999, nil
  local probe = E.buttons[2].text
  for _, key in ipairs({ "ACT_CONFIRM", "ACT_DISMISS", "ACT_HUNT_AGAIN", "ACT_REVENGE", "ACT_UNDO", "ACT_PARDON",
                         "ACT_OPEN_OWN", "ACT_ADOPT", "ACT_CALLOFF", "ACT_RELEASE" }) do
    E.buttons[2]:SetLabel(L[key])
    if probe:IsTruncated() and BM.Unbounded(probe) - probe._w > worst then worst, what = BM.Unbounded(probe) - probe._w, key end
  end
  K.check(code .. " B04 every poster label fits its button", what == nil, what and ("%s %.1f px over"):format(what, worst))
  K.check(code .. " B04 the word 'strike out' is whole", not E.strike.text:IsTruncated(), E.strike.text._text)
end

------------------------------------------------------------------------
-- B05: a hit area made only for a tooltip (Look.TipIfCut on a frame without mouse) takes the hover but no click:
-- a right click on the tally line of the poster opens the poster menu, the tooltip of a cut tally still shows
------------------------------------------------------------------------
do
  local ns = K.world("deDE")
  local BM, G = K.BM, K.G
  local t = _G.time()
  local k = ns.Store.AddManual("Anna", "Beispiel")
  ns.Store.ApplyKill({ name = "Anna", surname = "Beispiel", class = "MAGE", level = 60 }, { t = t - 86400, zone = "Z" }, true)
  K.tick(30); for _ = 1, 4 do K.settle() end
  ns:Fire("TOGGLE_UI"); K.tick(); K.settle()
  ns.UI.ShowEnemy(k); K.tick(); K.settle()
  local E = K.find(function(f) return f.bounty and f.stampRache end)
  local function depth(f) local n = 0; while f._parent do n = n + 1; f = f._parent end return n end
  -- the frame that gets a click at a spot of fs: the deepest visible click-enabled frame of the poster there
  local function target(fs)
    local l, b, _, tp = BM.RectUI(fs)
    local x, y = l + 20, (b + tp) / 2
    local best, bd
    for _, f in ipairs(BM.frames) do
      if (f._kind == "Frame" or f._kind == "Button") and f._mouse and f:IsVisible() and K.under(f, E) then
        local fl, fb, fr, ft = BM.RectUI(f)
        if fl and x >= fl and x <= fr and y >= fb and y <= ft then
          local d = depth(f)
          if not best or d >= bd then best, bd = f, d end
        end
      end
    end
    return best
  end
  local hit = target(E.tally)
  local s = hit and hit._scripts or {}
  if s.OnMouseUp then s.OnMouseUp(hit, "RightButton") elseif s.OnClick then s.OnClick(hit, "RightButton") end
  K.tick()
  local menu = rawget(G, "DeathNoteMenu")
  K.check("B05 right click on the tally line opens the poster menu", menu and menu:IsShown(), hit and hit._src)
  if menu and menu:IsShown() then menu.blocker._scripts.OnClick(menu.blocker); K.tick() end
  K.check("B05 the tooltip area of the tally takes the hover but no click", E.tallyHit._motion == true and E.tallyHit._mouse == false,
    ("motion %s, click %s"):format(tostring(E.tallyHit._motion), tostring(E.tallyHit._mouse)))
  E.tally.cut = true
  local tip = K.hover(E.tallyHit)
  K.check("B05 a cut tally still shows whole in its tooltip", tip ~= "" and tip == E.tally.full, tip)
end

io.write(("Layout fixes 1.2.2 (hunt B): %d green, %d red\n"):format(K.ok, K.bad))
os.exit(K.bad == 0 and 0 or 1)
