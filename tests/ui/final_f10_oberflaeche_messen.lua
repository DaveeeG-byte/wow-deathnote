-- (fix-2) Proof test of the final hunt, taken into the suite (run from the project root: luajit <file> .)
-- Measures the UI in several languages (default: deDE enUS ruRU fiFI zhCN, more as arguments).
-- Usage: nice -n 15 luajit beleg_f10_oberflaeche_messen.lua <project copy> [code ...]
-- The UI mock returns rectangles; text widths are estimated (characters x font size x font factor,
-- CJK characters as a full em). Reported:
--   FEST   a fixed label (text is exactly one locale text) is wider than its single line field
--   KNOPF  a label sticks out of its button
--   LAGE   two visible texts of the same frame overlap
-- Keys instead of wording: every report names the locale key. Red if there is any FEST/KNOPF/LAGE.
local DIR = (arg[1] or "."):gsub("/+$", "")
package.path = DIR .. "/tests/ui/?.lua;" .. DIR .. "/tests/?.lua;" .. package.path
arg[0] = DIR .. "/tests/ui/beleg.lua"
local CODES = {}
for i = 2, #arg do CODES[#CODES + 1] = arg[i] end
-- (fix-2) all 21 languages in the suite (under one second)
if #CODES == 0 then CODES = { "enUS", "deDE", "frFR", "esES", "itIT", "ptBR", "ruRU", "koKR", "zhCN", "zhTW", "svSE", "nbNO",
  "daDK", "fiFI", "nlNL", "plPL", "csCZ", "huHU", "hrHR", "ukUA", "trTR" } end
local ADDON = DIR .. "/DeathNote"

local AM, BM, G
local function wide(cp)
  return (cp >= 0x1100 and cp <= 0x115F) or (cp >= 0x2E80 and cp <= 0xA4CF) or (cp >= 0xAC00 and cp <= 0xD7A3)
    or (cp >= 0xF900 and cp <= 0xFAFF) or (cp >= 0xFE30 and cp <= 0xFE4F) or (cp >= 0xFF00 and cp <= 0xFF60)
end
-- 1.2.2: factors at the wide end of the real fonts (Nimrod was 0.45, calibrated 0.55 to 0.56 on the client screenshot)
local FACT = { ["Fonts\\MORPHEUS.TTF"] = 0.56, ["Fonts\\MORPHEUS_CYR.TTF"] = 0.60, ["Fonts\\FRIZQT__.TTF"] = 0.56,
  ["Fonts\\FRIZQT___CYR.TTF"] = 0.58, ["Fonts\\NIM_____.ttf"] = 0.60, ["Fonts\\SKURRI_CYR.TTF"] = 0.70,
  ["Fonts\\SKURRI.TTF"] = 0.70, ["Fonts\\ARIALN.TTF"] = 0.45 }
local function estimate(fs)
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
      w = w + (wide(cp) and 1.07 or f) * size
      i = i + len
    end
    if w > best then best = w end
  end
  return best
end

local function world(code)
  package.loaded.mock_wow, package.loaded.mock = nil, nil
  AM = require("mock_wow")
  BM = require("mock")
  BM.mediaDir = ADDON .. "/Media"
  G = BM.G
  AM.locale = code
  local FR = { "Fritz Frei" }
  local ns = AM.Load({ noLogin = true, before = function()
    AM.units.player.guild = "Die Testgilde"
    _G.C_FriendList = {
      GetNumFriends = function() return #FR end,
      GetFriendInfoByIndex = function(i) local n = FR[i]; if n then return { name = n, connected = true } end end,
      ShowFriends = function() end,
    }
  end })
  for _, f in ipairs({ "Alert.lua", "UI.lua", "Extras.lua" }) do BM.Load(ADDON .. "/" .. f, ns) end
  -- hook our own width estimate into the mock (also for the stretching tabs and buttons)
  local mt = getmetatable(BM.frames[1])
  local i = 1
  while true do
    local n, v = debug.getupvalue(mt.__index, i)
    if not n then break end
    if n == "methods" then v.GetStringWidth = function(self) return estimate(self) end end
    i = i + 1
  end
  AM.FireEvent("PLAYER_LOGIN")
  AM.FireEvent("PLAYER_ENTERING_WORLD")
  return ns
end
local function tick(s) AM.Advance(s or 0.1); BM.Advance(s or 0.1) end
local function settle() BM.Advance(13); BM.FinishAnims(); BM.Advance(1); BM.FinishAnims(); BM.Advance(1) end

local total = 0
local function run(code)
  local ns = world(code)
  local L = ns.L
  local keyOf = {}
  for k, v in pairs(L) do if type(v) == "string" and not keyOf[v] then keyOf[v] = k end end
  local found, seen = {}, {}
  local stat = { fest = 0 }
  local function note(kind, where, what)
    local id = kind .. "|" .. what
    if seen[id] then return end
    seen[id] = true
    found[#found + 1] = ("  %-5s %-22s %s"):format(kind, where, what)
  end
  local function rect(fs, w)
    local keep = fs._w
    if w then fs._w = w end
    local l, b, r, t = BM.RectUI(fs)
    fs._w = keep
    return l, b, r, t
  end
  local function scan(where)
    local byParent = {}
    for _, f in ipairs(BM.frames) do
      if f._kind == "FontString" and type(f._text) == "string" and f._text ~= "" and f:IsVisible() and (f._alpha or 1) > 0.05 then
        local est = estimate(f)
        local key = keyOf[f._text]
        local one = f._wrap == false or f._maxl == 1
        if key and f._wset and one then stat.fest = stat.fest + 1 end
        -- status lines (guild, friends) are single line on purpose and show the whole sentence in the tooltip
        local status = key and (key:find("^FRIENDS_") or key:find("^SYNC_") or key:find("^HEALTH_"))
        if key and f._wset and one and est > f._w + 1 and not status then
          note("FEST", where, ("%s: Text %d px, Feld %d px"):format(key, est, f._w))
        end
        local p = f._parent
        if key and p and p._kind == "Button" and p._wset and not f._wset and est > p._w + 1 then
          note("KNOPF", where, ("%s: Text %d px, Knopf %d px"):format(key, est, p._w))
        end
        if p then byParent[p] = byParent[p] or {}; table.insert(byParent[p], f) end
      end
    end
    for p, list in pairs(byParent) do
      for i = 1, #list do
        for j = i + 1, #list do
          local a, b = list[i], list[j]
          if #a._points == 1 and #b._points == 1 and a._rot == nil and b._rot == nil then
            local wa = a._wset and math.min(a._w, (a._wrap == false or a._maxl == 1) and estimate(a) or a._w) or estimate(a)
            local wb = b._wset and math.min(b._w, (b._wrap == false or b._maxl == 1) and estimate(b) or b._w) or estimate(b)
            local ha, hb = (a._fontSize or 12), (b._fontSize or 12)
            local ka, kb = a._h, b._h
            a._h, b._h = ha, hb
            local l1, b1, r1, t1 = rect(a, wa)
            local l2, b2, r2, t2 = rect(b, wb)
            a._h, b._h = ka, kb
            if l1 and l2 then
              local ox, oy = math.min(r1, r2) - math.max(l1, l2), math.min(t1, t2) - math.max(b1, b2)
              if ox > 3 and oy > 3 then
                note("LAGE", where, ("%s gegen %s: %d x %d px ueberdeckt"):format(keyOf[a._text] or "(Daten)", keyOf[b._text] or "(Daten)", ox, oy))
              end
            end
          end
        end
      end
    end
  end

  -- Data: own wanted, guild book, hit list with long names and a long reason
  local P = ns.Guild.Proto
  tick(30); settle(); AM.Advance(120)
  local function gmsg(text, from) AM.FireEvent("CHAT_MSG_ADDON", "DeathNote", text, "GUILD", from or "Kollege-Forever") end
  local long = "Maximilianus Donnerschlagbringer"
  local why = code == "zhCN" and "他在荆棘谷的路上一次又一次地偷袭我们公会的低级成员整整一个晚上都没有停手真的太过分了必须有人管管他才行啊啊"
    or "Camps the road in Stranglethorn all night long, again and x"
  local t = _G.time()
  ns.Store.AddManual("Grimm", "Bart")
  local k1 = ns.Store.AddManual("Maximilianus", "Donnerschlagbringer")
  ns.Store.SetNote(k1, "x")
  gmsg(P.EncodeKill({ key = "Maximilianus-Donnerschlagbringer", display = long, class = "MAGE", level = 60, zone = "Schlingendorntal", t = t - 30, victim = "Kollege Lang" }, "K"))
  for i = 1, 4 do
    gmsg(P.EncodeHunt({ key = "Ziel" .. string.char(64 + i) .. "-Donnerschlagbringer", display = "Ziel" .. string.char(64 + i) .. " Donnerschlagbringer",
      class = "ROGUE", level = 55 + i, t = t - 86400 * i, by = "Kollege Lang", why = why }))
  end
  gmsg(P.EncodeHunt({ key = "Maximilianus-Donnerschlagbringer", display = long, class = "MAGE", level = 60, t = t - 5, by = "Zweiter Kollegenname", why = why }), "Zweiter-Forever")
  gmsg(P.EncodeBagged("ZielA-Donnerschlagbringer", "Kollege Lang", t))
  ns.Guild.Release("ZielB-Donnerschlagbringer", { to = "all", why = why })
  tick(10); settle()

  ns:Fire("TOGGLE_UI"); tick(); settle()
  scan("Gesuchte")
  local function tab(id)
    for _, f in ipairs(BM.frames) do
      if f.id == id and f._scripts and f._scripts.OnClick then f._scripts.OnClick(f, "LeftButton"); break end
    end
    tick(); settle()
  end
  -- Tabs: rectangles, spacing, end before the question mark
  do
    local tabs = {}
    for _, f in ipairs(BM.frames) do
      if (f.id == "wanted" or f.id == "open" or f.id == "journal" or f.id == "guild") and f.label and f._kind == "Button" then tabs[#tabs + 1] = f end
    end
    table.sort(tabs, function(a, b) return (a._points[1][2] or 0) < (b._points[1][2] or 0) end)
    local line = {}
    for i, f in ipairs(tabs) do
      local x = f._points[1][2]
      local est = estimate(f.text)
      line[#line + 1] = ("%s x=%d w=%d Text~%d"):format(f.id, x, f._w, est)
      if est > f.text._w + 1 then note("FEST", "Reiter", ("Reiter %s (%s): Text %d px, Feld %d px"):format(f.id, keyOf[f.text._text] or "?", est, f.text._w)) end
      if tabs[i + 1] and x + f._w > tabs[i + 1]._points[1][2] then note("LAGE", "Reiter", "Reiter " .. f.id .. " ueberdeckt den naechsten") end
      if x + f._w > 704 then note("LAGE", "Reiter", "Reiter " .. f.id .. " ragt ueber x=704") end
    end
    io.write("  Reiter " .. code .. ": " .. table.concat(line, " | ") .. "\n")
  end
  for _, id in ipairs({ "open", "journal", "guild" }) do tab(id); scan("Reiter " .. id) end
  for _, v in ipairs({ "hunt", "enemy", "member" }) do
    ns.UI.SetGuildView(v); tick(); settle()
    for _, src in ipairs({ "all", "guild", "friends" }) do ns.UI.SetGuildSource(src); tick(); scan("Gilde " .. v .. "/" .. src) end
  end
  ns.UI.SetGuildSource("all"); ns.UI.SetGuildView("hunt"); tick(); settle()
  ns.UI.ShowHunts("Maximilianus-Donnerschlagbringer"); tick(); settle(); scan("Plakat Abschussliste")
  ns.UI.ShowHunts("ZielA-Donnerschlagbringer"); tick(); settle(); scan("Plakat erlegt")
  ns.UI.ShowHunts("ZielB-Donnerschlagbringer"); tick(); settle(); scan("Plakat eigene Freigabe")
  ns.UI.OpenRelease(k1); tick(); scan("Blatt Freigeben"); ns.UI.ClosePanel(); tick()
  tab("wanted"); ns.UI.ShowEnemy(k1); tick(); settle(); scan("Plakat Gesuchter")
  ns.UI.OpenPanel("settings"); tick(); settle()
  local sheets = {}
  for _, k in ipairs({ "SHEET_BOOK", "SHEET_ALERT", "SHEET_GUILD" }) do sheets[#sheets + 1] = { k, L[k] } end
  for _, s in ipairs(sheets) do
    for _, f in ipairs(BM.frames) do
      local fs = f.text or f.label
      local tx = fs and type(fs) == "table" and fs._text
      if tx == s[2] and f._scripts and f._scripts.OnClick and f:IsVisible() then f._scripts.OnClick(f, "LeftButton"); tick() end
    end
    scan("Hausordnung " .. s[1])
    if s[1] == "SHEET_GUILD" then
      -- does everything fit on the sheet? The page fills its sheet (two anchors), so compute from the anchors:
      -- lowest bottom edge of the checkboxes, steppers and buttons against the top edge of the hint line (at 44).
      local page
      for _, f in ipairs(BM.frames) do
        if f._kind == "CheckButton" and f:IsVisible() and type(f.opt) == "table" and f.opt.guild then page = f._parent end
      end
      local ph, o = nil, page
      while o and not ph do if o._hset then ph = o._h end; o = o._parent end
      if page and ph then
        local low, n, hintTop = 0, 0, 44
        for _, f in ipairs(BM.frames) do
          if f._parent == page and f:IsVisible() and #f._points == 1 then
            local pt = f._points[1]
            if pt[1] == "TOPLEFT" and type(pt[3]) == "number" and f._kind ~= "Texture" then
              local h = f._kind == "FontString" and (f._fontSize or 12) or f._h
              local bottom = -pt[3] + h
              n = n + 1
              if bottom > low then low = bottom end
            elseif pt[1] == "BOTTOMLEFT" and f._kind == "FontString" and type(f._text) == "string" then
              local lines = math.max(1, math.ceil(estimate(f) * 1.06 / (380 - 60)))
              hintTop = pt[3] + lines * ((f._fontSize or 11) + 2)
            end
          end
        end
        local room = (ph - low) - hintTop
        io.write(("  Blatt Gilde %s: %d Elemente, tiefste Unterkante %d von %d px, Hinweis bis %d px ueber dem Rand, Luft %d px\n"):format(code, n, low, ph, hintTop, room))
        if room < 0 then note("LAGE", "Hausordnung Gilde", ("Hinweiszeile und Knoepfe ueberdecken sich um %d px"):format(-room)) end
      else
        note("LAGE", "Hausordnung Gilde", "Blatt nicht gefunden")
      end
    end
  end
  ns.UI.OpenPanel("help"); tick(); scan("Gebrauchsanweisung")
  ns.UI.OpenIO("export"); tick(); scan("Sichern")
  ns.UI.OpenIO("import"); tick(); scan("Einlesen")
  ns.UI.ClosePanel(); tick()
  -- Alarm: own wanted target three levels higher, also on the hit list; warning line
  BM.levels.player = 40
  BM.levels.mouseover = 60
  AM.AddEnemy("mouseover", { name = "Maximilianus", surname = "Donnerschlagbringer", guid = "Player-1-MD", level = 60, class = "MAGE" })
  AM.FireEvent("UPDATE_MOUSEOVER_UNIT"); tick()
  local popup = rawget(G, "DeathNoteAlert")
  if popup and popup:IsShown() then
    scan("Alarm")
    local nameW, lvlW = estimate(popup.name), 0
    -- fix-3: no warning line any more; the level carries the difference ("Level 60 (+20)") in warning colour
    io.write(("  Alarm %s: Popup %dx%d, Name~%d px, Stufe~%d px (%s)\n"):format(code, popup:GetWidth(), popup:GetHeight(),
      nameW, lvlW, tostring(popup.levelText)))
    if lvlW + 60 > popup:GetWidth() / 2 then note("LAGE", "Alarm", "Stufe nimmt mehr als die halbe Popup-Breite: " .. lvlW .. " px") end
  else
    note("LAGE", "Alarm", "Popup kam nicht")
  end
  settle()
  ns:Fire("HUNT_BAGGED", "ZielA-Donnerschlagbringer", "Kollege Lang", _G.time(), "guild"); tick(); scan("Meldung erlegt"); settle()
  ns:Fire("HUNT_NEW", 3, "ZielA-Donnerschlagbringer", "Kollege Lang", "guild"); tick(); scan("Meldung neu"); settle()
  local errs = #AM.errors + #BM.violations
  io.write(("%s: %d feste einzeilige Beschriftungen gemessen\n"):format(code, stat.fest))
  io.write(("%s: %d Meldungen, %d Fehler/Verstoesse%s\n"):format(code, #found, errs, errs > 0 and ("  -> " .. tostring(AM.errors[1] or BM.violations[1])) or ""))
  table.sort(found)
  for _, l in ipairs(found) do io.write(l .. "\n") end
  total = total + #found + errs
end

for _, c in ipairs(CODES) do run(c) end
io.write(("Oberflaeche gemessen in %d Sprachen: %d Meldungen\n"):format(#CODES, total))
os.exit(total == 0 and 0 or 1)
