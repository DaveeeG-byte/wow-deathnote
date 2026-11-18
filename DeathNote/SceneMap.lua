-- DeathNote - SceneMap.lua (1.5.0 scene)
-- The crime scenes on the world map: own pins on the map's canvas (plain frames, no Blizzard pin template, no embedded
-- library), a small switch at the map's corner, and the way from the book to the map (SceneMap.Show). What goes on the
-- map and the words of a pin come from Scene.lua.
--
-- Pins: a red pin with a skull (my death), a black pin with crossed blades (my kill), a light pin in a quiet colour
-- with a dark skull (a guildmate's or a friend's death; 1.5.0 fixer: guild a shield head, friend a round head with a
-- small heart, so they differ without colour). Pins that would cover each other are one pin with a count. A mate's
-- death younger than Scene.FRESH pulses (an animation group, no OnUpdate). A pin's tooltip says who killed whom, when
-- and where; a click closes the map and opens the book there (a bundle: a small list of its scenes to pick from).
-- The switch at the map's corner is a closed book with a red pin (its own sign, never a crime scene pin); its tooltip
-- names the pins. A place shown from the book closes the book; closing the map again opens it again.
-- Combat: nothing on the map is touched in combat (taint and "action blocked" on Forever, hunt-technik §2). A refresh
-- asked in combat waits for PLAYER_REGEN_ENABLED; a click from the book in combat only says so in the chat (nothing
-- is opened later). Pins are positioned like Leatrix Maps' (Leatrix_Maps.lua: canvas child, scale 1 / canvas scale).
-- Every call into the map goes through pcall: an error costs the pins, never the book, the alarm or the death detection.

local ADDON, ns = ...
local Look = ns.Look
local L, Fmt = ns.L, ns.F

local SceneMap = {}
ns.SceneMap = SceneMap

SceneMap.PIN = 28          -- pin size in map pixels (the canvas scale is taken out: the pin stays this size)
SceneMap.PULSES = 3        -- pulses of the ring after a click from the book
SceneMap.HINT_SECONDS = 6  -- the hint on the map ("exact spot unknown")

local TEX = {
  death = "scene_death.tga", kill = "scene_kill.tga", guild = "scene_guild.tga", friend = "scene_friend.tga",
}
SceneMap.TEX = TEX
SceneMap.SWITCH = "scene_switch.tga"   -- the switch at the map's corner
SceneMap.PICK_MAX = 8                  -- scenes in the list of a bundle (the rest: "… and n more")
-- the mates' quiet colours (multiplied into the light pin): guild a muted green, friends a muted blue
SceneMap.TINT = { guild = { 0.62, 0.80, 0.58 }, friend = { 0.60, 0.72, 0.92 } }

local function G(name) return rawget(_G, name) end
local function Scene() return ns.Scene end
local function inCombat()
  local f = G("InCombatLockdown")
  return f and f() and true or false
end
local function media(file) return (Look.MEDIA or ("Interface\\AddOns\\" .. ADDON .. "\\Media\\")) .. file end
local function guard(where, fn, ...)
  local ok, a, b = pcall(fn, ...)
  if not ok then
    local S = Scene()
    if S then S.Error(where .. ": " .. tostring(a)) end
    return nil
  end
  return a, b
end
-- the clock of the book (Scene.lua): the same as the times of its entries
local function now() local S = Scene(); return S and S.Now() or 0 end

local map            -- WorldMapFrame
local pool, used = {}, {}
local button, menu, hint, marker, pick
local pending = false
SceneMap.focus, SceneMap.focusUntil = nil, 0

---------------------------------------------------------------------------
-- Pins
---------------------------------------------------------------------------
local function canvasOf() return map and map.GetCanvas and map:GetCanvas() end
local function canvasScale()
  local s = map and map.GetCanvasScale and map:GetCanvasScale()
  return (type(s) == "number" and s > 0) and s or 1
end

local function pinEnter(self)
  local p = self.data
  if not p then return end
  local S = Scene()
  local tip = G("GameTooltip")
  if not (S and tip) then return end
  tip:SetOwner(self, "ANCHOR_RIGHT")
  local lines = S.TipLines(p, now())
  for i, l in ipairs(lines) do
    -- every line may wrap (long names; the client sets the width)
    if i == 1 then tip:SetText(l[1], l[2] or 1, l[3] or 1, l[4] or 1, 1, true)
    else tip:AddLine(l[1], l[2] or 0.85, l[3] or 0.82, l[4] or 0.75, true) end
  end
  tip:Show()
end
local function pinLeave() local tip = G("GameTooltip"); if tip then tip:Hide() end end

-- a click on a pin: the map closes (out of combat), the book opens on the pin's scene; 1.5.0 fixer: a bundle shows the
-- list of its scenes (the one of the pin's look first), a click there opens that one
local function pinClick(self, mouse)
  if mouse == "RightButton" or not self.data then return end
  local it = self.data.items[1]
  if not it then return end
  if #self.data.items > 1 then SceneMap.ShowPick(self); return end
  SceneMap.Go(it)
end
-- from the map into the book on one scene
function SceneMap.Go(it)
  if pick then pick:Hide() end
  SceneMap.fromBook = nil   -- the book opens on the scene: closing the map must not open it a second time
  if not inCombat() then SceneMap.CloseMap() end
  SceneMap.OpenBook(it)
end

local function makePin()
  local canvas = canvasOf()
  local f = CreateFrame("Frame", nil, canvas)
  f:SetSize(SceneMap.PIN, SceneMap.PIN)
  f:SetFrameStrata("HIGH")
  f:EnableMouse(true)
  f.icon = f:CreateTexture(nil, "ARTWORK")
  f.icon:SetAllPoints()
  -- the ring around the pin's head (pulse after a click from the book, steady pulse for a fresh mate's death)
  f.ring = f:CreateTexture(nil, "OVERLAY")
  f.ring:SetSize(SceneMap.PIN * 1.25, SceneMap.PIN * 1.25)
  f.ring:SetPoint("CENTER", f, "TOP", 0, -SceneMap.PIN * 0.34)
  Look.Tex(f.ring, media("scene_ring.tga"))
  f.ring:SetAlpha(0)
  local g = f.ring:CreateAnimationGroup()
  Look.ScaleAnim(g, 0.6, 1.5, 0.9, 1)
  Look.AlphaAnim(g, 1, 0, 0.9, 1)
  g:SetLooping("REPEAT")
  f.pulse = g
  -- count of a bundle: a bone badge with the number
  f.badge = f:CreateTexture(nil, "ARTWORK", nil, 2)   -- above the pin, below the number (OVERLAY)
  f.badge:SetSize(15, 15)
  f.badge:SetPoint("CENTER", f, "TOPRIGHT", -2, -3)
  Look.Tex(f.badge, media("scene_badge.tga"))
  f.count = Look.Text(f, "type", 9, Look.INK, nil, "OVERLAY")
  f.count:SetPoint("CENTER", f.badge, "CENTER", 0, 0)
  f:SetScript("OnEnter", pinEnter)
  f:SetScript("OnLeave", pinLeave)
  f:SetScript("OnMouseUp", pinClick)
  return f
end

local function stopPulse(f)
  if f.pulse:IsPlaying() then f.pulse:Stop() end
  f.ring:SetAlpha(0)
  f.pulsing = nil
end
local function startPulse(f, times)
  f.ring:SetAlpha(1)
  f.pulse:Play()
  f.pulsing = true
  if times then
    local token = {}
    f.pulseToken = token
    local T = G("C_Timer")
    if T and T.After then
      T.After(0.9 * times, function()
        if f.pulseToken == token and not (f.data and f.data.fresh) then stopPulse(f) end
      end)
    end
  end
end

-- a pin's width and height in percent of the canvas (the pin keeps PIN px on the screen whatever the canvas scale)
function SceneMap.PinSize()
  local canvas = canvasOf()
  if not canvas then return nil end
  local w, h = canvas:GetWidth() or 0, canvas:GetHeight() or 0
  if type(w) ~= "number" or type(h) ~= "number" or w <= 0 or h <= 0 then return nil end
  local px = SceneMap.PIN / canvasScale()
  return { rx = px / w * 100, ry = px / h * 100 }
end

local function place(f, p)
  local canvas = canvasOf()
  local sc = 1 / canvasScale()
  f:SetScale(sc)
  f:ClearAllPoints()
  local w, h = canvas:GetWidth() or 0, canvas:GetHeight() or 0
  f:SetPoint("BOTTOM", canvas, "TOPLEFT", (w * p.x / 100) / sc, -(h * p.y / 100) / sc)
end

local function fill(f, p)
  f.data = p
  Look.Tex(f.icon, media(TEX[p.kind] or TEX.death))
  local tint = SceneMap.TINT[p.kind]
  if tint then f.icon:SetVertexColor(tint[1], tint[2], tint[3], 1) else f.icon:SetVertexColor(1, 1, 1, 1) end
  local many = p.count > 1
  f.badge:SetShown(many)
  f.count:SetShown(many)
  f.count:SetText(many and (p.count > 99 and "99+" or tostring(p.count)) or "")
  place(f, p)
  if p.fresh then startPulse(f) elseif f.pulsing then stopPulse(f) end
  f:Show()
end

local function releaseAll()
  if marker and map and map.GetMapID and marker.mapID ~= map:GetMapID() then marker.pulse:Stop(); marker:Hide() end
  for i = #used, 1, -1 do
    local f = used[i]
    stopPulse(f)
    f:Hide()
    f.data = nil
    used[i] = nil
    pool[#pool + 1] = f
  end
end

-- a scene of a zone on its continent (or any map that holds it): C_Map.GetMapRectOnMap where the client has it
local function translate(fromMap, x, y)
  local C_Map = G("C_Map")
  local to = map and map.GetMapID and map:GetMapID()
  if not (C_Map and C_Map.GetMapRectOnMap and to) then return nil end
  local minX, maxX, minY, maxY = C_Map.GetMapRectOnMap(fromMap, to)
  if type(minX) ~= "number" or type(maxX) ~= "number" or maxX <= minX or maxY <= minY then return nil end
  return (minX + (maxX - minX) * x / 100) * 100, (minY + (maxY - minY) * y / 100) * 100
end

-- draws the pins of the shown map (out of combat; in combat it waits for the end of the fight)
function SceneMap.Refresh()
  if not map or not (map.IsShown and map:IsShown()) then return end
  local S = Scene()
  if not S then return end
  if inCombat() then
    if not pending then S.Count("deferred") end
    pending = true
    return
  end
  pending = false
  guard("refresh", function()
    releaseAll()
    local mapID = map.GetMapID and map:GetMapID()
    if type(mapID) ~= "number" then return end
    local focus = (now() <= SceneMap.focusUntil) and SceneMap.focus or nil
    local pins = S.Pins(mapID, now(), translate, focus, SceneMap.PinSize())
    S.Count("refreshes")
    for _, p in ipairs(pins) do
      local f = table.remove(pool) or makePin()
      used[#used + 1] = f
      fill(f, p)
      S.Count("pins")
      if p.count > 1 then S.Count("bundles") end
    end
    SceneMap.UpdateButton()
  end)
end

-- 1.5.0 fixer: a new canvas scale bundles anew (pins that would now cover each other become one)
local function rescale()
  if inCombat() then pending = true; return end
  if pick then pick:Hide() end
  SceneMap.Refresh()
end

-- the shown pin that holds a scene (for the highlight): the same entry, or the same time on the same map
function SceneMap.PinFor(ref)
  local S = Scene()
  for _, f in ipairs(used) do
    if f.data then for _, it in ipairs(f.data.items) do if S.IsFocus(it, ref) then return f end end end
  end
end

-- a spot without a pin of its own (an attack, a filtered kind): the red ring alone pulses there
function SceneMap.Mark(p)
  local canvas = canvasOf()
  if not canvas then return end
  if not marker then
    marker = CreateFrame("Frame", nil, canvas)
    marker:SetSize(SceneMap.PIN * 1.25, SceneMap.PIN * 1.25)
    marker:SetFrameStrata("HIGH")
    marker.ring = marker:CreateTexture(nil, "OVERLAY")
    marker.ring:SetAllPoints()
    Look.Tex(marker.ring, media("scene_ring.tga"))
    local g = marker.ring:CreateAnimationGroup()
    Look.ScaleAnim(g, 0.6, 1.5, 0.9, 1)
    Look.AlphaAnim(g, 1, 0, 0.9, 1)
    g:SetLooping("REPEAT")
    marker.pulse = g
  end
  local sc = 1 / canvasScale()
  marker:SetScale(sc)
  marker:ClearAllPoints()
  local w, h = canvas:GetWidth() or 0, canvas:GetHeight() or 0
  marker:SetPoint("CENTER", canvas, "TOPLEFT", (w * p.x / 100) / sc, -(h * p.y / 100) / sc)
  marker.mapID = p.mapID
  marker:Show()
  marker.pulse:Play()
  local token = {}
  marker.token = token
  local T = G("C_Timer")
  if T and T.After then
    T.After(0.9 * SceneMap.PULSES, function() if marker.token == token then marker.pulse:Stop(); marker:Hide() end end)
  end
end
function SceneMap.Marker() return marker end
function SceneMap.Shown() return used end

---------------------------------------------------------------------------
-- Hint on the map ("exact spot unknown")
---------------------------------------------------------------------------
local function showHint(text)
  local host = map and (map.ScrollContainer or map)
  if not host then return end
  if not hint then
    hint = CreateFrame("Frame", nil, host)
    hint:SetSize(360, 24)
    hint:SetPoint("TOP", host, "TOP", 0, -10)
    hint:SetFrameStrata("HIGH")
    local bg = hint:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.05, 0.03, 0.02, 0.78)
    hint.text = Look.Text(hint, "body", 12, Look.BONE or { 0.92, 0.88, 0.78, 1 })
    hint.text:SetPoint("CENTER", 0, 0)
    hint.text:SetWidth(344)
  end
  hint.text:SetText(text)
  hint:Show()
  local token = {}
  hint.token = token
  local T = G("C_Timer")
  if T and T.After then T.After(SceneMap.HINT_SECONDS, function() if hint.token == token then hint:Hide() end end) end
end
SceneMap.ShowHint = showHint
function SceneMap.Hint() return hint end

---------------------------------------------------------------------------
-- Book -> map, map -> book
---------------------------------------------------------------------------
-- the map open on mapID (taint-free C_Map.OpenWorldMap where there is one, as Leatrix Maps; never in combat)
local function openMap(mapID)
  local C_Map = G("C_Map")
  if C_Map and C_Map.OpenWorldMap then
    C_Map.OpenWorldMap(mapID)
  else
    if not map:IsShown() then
      local show = G("ShowUIPanel")
      if show then show(map) else local tog = G("ToggleWorldMap"); if tog then tog() else map:Show() end end
    end
    if map.SetMapID then map:SetMapID(mapID) end
  end
end

function SceneMap.CloseMap()
  if not map or not map:IsShown() then return end
  guard("close", function()
    local hide = G("HideUIPanel")
    if hide then hide(map) else local tog = G("ToggleWorldMap"); if tog then tog() else map:Hide() end end
  end)
end

-- Shows a place of the book on the map. place = { mapID, x, y, zone, subzone, t } or a scene; ref = the entry behind
-- it (journal entry, log row, mate's deed: its pin is highlighted). Returns what happened: "shown", "zone" (map of the
-- zone, exact spot unknown), "combat", "nomap", "unavailable".
function SceneMap.Show(placeT, ref)
  local S = Scene()
  if not S or type(placeT) ~= "table" then return "unavailable" end
  S.Count("clicks")
  if inCombat() then
    S.Count("combat")
    if ns.Util and ns.Util.Print then ns.Util.Print(L.SCENE_COMBAT) end
    return "combat"
  end
  if not S.ValidMap(placeT.mapID) then
    S.Count("noMap")
    if ns.Util and ns.Util.Print then ns.Util.Print(L.SCENE_NO_MAP) end
    return "nomap"
  end
  SceneMap.Attach()
  if not map then
    S.Count("noMap")
    if ns.Util and ns.Util.Print then ns.Util.Print(L.SCENE_NO_MAP) end
    return "unavailable"
  end
  local spot = S.ValidSpot(placeT.mapID, placeT.x, placeT.y)
  SceneMap.focus = spot and (ref or placeT) or nil
  SceneMap.focusUntil = now() + S.FOCUS
  -- the book gives way to the map (a pin's click opens it again; 1.5.0 fixer: so does closing the map)
  local book = G("DeathNoteFrame")
  if book and book.IsShown and book:IsShown() then book:Hide(); SceneMap.fromBook = true end
  local ok = guard("open", openMap, placeT.mapID)
  if ok == nil and not map:IsShown() then return "unavailable" end
  SceneMap.Refresh()
  if not spot then
    S.Count("noCoords")
    showHint(L.SCENE_NO_SPOT)
    return "zone"
  end
  local f = SceneMap.PinFor(ref or placeT) or SceneMap.PinFor(placeT)
  if f then startPulse(f, SceneMap.PULSES) else guard("mark", SceneMap.Mark, placeT) end
  return "shown"
end

-- the book on a scene: my death -> the death file, my kill -> the poster (or the rap sheet), a mate's death -> the
-- killer in Guild & Friends
function SceneMap.OpenBook(it)
  local UI = ns.UI
  if not UI then return end
  guard("book", function()
    if it.kind == "death" and UI.ShowCase then
      UI.ShowCase(it.ref)
    elseif it.kind == "kill" and it.key and ns.Store and ns.Store.Get(it.key) and UI.ShowEnemy then
      UI.ShowEnemy(it.key)
    elseif (it.kind == "guild" or it.kind == "friend") and UI.ShowGuildEnemy then
      UI.ShowGuildEnemy(it.key, it.kind == "friend" and "friends" or "guild")
    elseif UI.Open then
      UI.Open()
    end
  end)
end

---------------------------------------------------------------------------
-- The switch at the map's corner: on/off, period, only open debts, which kinds
---------------------------------------------------------------------------
local function set(name, v)
  if ns.Store and ns.Store.Setting then ns.Store.Setting("scene." .. name, v) end
end
local function setting(name) local S = Scene(); return S and S.Setting(name) end

function SceneMap.DaysWord(days) return ns.Scene.DaysWord(days) end
function SceneMap.StepDays(dir) return ns.Scene.StepDays(dir) end

local MENU = {
  { kind = "check", name = "on", key = "OPT_SCENE" },
  { kind = "days" },
  { kind = "check", name = "open", key = "OPT_SCENE_OPEN" },
  { kind = "check", name = "own", key = "SCENE_KIND_OWN" },
  { kind = "check", name = "guild", key = "SRC_GUILD" },
  { kind = "check", name = "friends", key = "SRC_FRIENDS" },
}
SceneMap.MENU = MENU
SceneMap.MENU_W, SceneMap.ROW_H = 230, 20

local function menuText(row)
  if row.kind == "days" then return Fmt(L.SCENE_DAYS_LINE, { days = SceneMap.DaysWord(setting("days")) }) end
  return L[row.key] or row.key
end

function SceneMap.FillMenu()
  if not menu then return end
  for i, row in ipairs(MENU) do
    local b = menu.rows[i]
    b.text:SetText(menuText(row))
    if row.kind == "check" then
      local on = setting(row.name) ~= false
      b.check:SetShown(on)
      b.box:Show()
    else
      b.check:Hide()
      b.box:Hide()
    end
  end
end

local function buildMenu()
  menu = CreateFrame("Frame", nil, button)
  menu:SetSize(SceneMap.MENU_W, 12 + #MENU * SceneMap.ROW_H)
  menu:SetPoint("BOTTOMLEFT", button, "TOPLEFT", 0, 4)
  menu:SetFrameStrata("DIALOG")
  menu:EnableMouse(true)
  local bg = menu:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  Look.Skin(bg, "paper")
  menu.rows = {}
  for i, row in ipairs(MENU) do
    local b = CreateFrame("Button", nil, menu)
    b:SetSize(SceneMap.MENU_W - 12, SceneMap.ROW_H)
    b:SetPoint("TOPLEFT", 6, -6 - (i - 1) * SceneMap.ROW_H)
    b.box = b:CreateTexture(nil, "ARTWORK")
    b.box:SetSize(11, 11)
    b.box:SetPoint("LEFT", 4, 0)
    b.box:SetColorTexture(Look.INK[1], Look.INK[2], Look.INK[3], 0.35)
    b.check = b:CreateTexture(nil, "OVERLAY")
    b.check:SetSize(14, 14)
    b.check:SetPoint("CENTER", b.box, "CENTER", 0, 0)
    Look.Tex(b.check, media("check.tga"))
    b.check:SetVertexColor(Look.RED_INK and Look.RED_INK[1] or 0.6, Look.RED_INK and Look.RED_INK[2] or 0.1,
      Look.RED_INK and Look.RED_INK[3] or 0.1, 1)
    b.text = Look.Text(b, "body", 11, Look.INK)
    b.text:SetPoint("LEFT", 22, 0)
    b.text:SetWidth(SceneMap.MENU_W - 40)
    b.text:SetJustifyH("LEFT")
    b.text:SetWordWrap(false)
    Look.TipShows(b, b.text)
    b:SetScript("OnClick", function()
      if row.kind == "days" then SceneMap.StepDays(1)
      else set(row.name, setting(row.name) == false) end
      Look.Sound("click")
      SceneMap.FillMenu()
    end)
    menu.rows[i] = b
  end
  menu:Hide()
end

function SceneMap.ToggleMenu()
  if not button then return end
  if not menu then buildMenu() end
  if menu:IsShown() then menu:Hide() else SceneMap.FillMenu(); menu:Show() end
end
function SceneMap.Menu() return menu end

function SceneMap.UpdateButton()
  if not button then return end
  local on = setting("on") ~= false
  button.icon:SetDesaturated(not on)
  button.icon:SetAlpha(on and 1 or 0.55)
end

local function buildButton()
  local host = map.ScrollContainer or map
  button = CreateFrame("Button", nil, host)
  button:SetSize(26, 26)
  button:SetPoint("BOTTOMLEFT", host, "BOTTOMLEFT", 8, 8)
  -- 1.5.0 fixer: one layer above the pins (HIGH), with a light frame and its own sign (a book, no crime scene pin)
  button:SetFrameStrata("DIALOG")
  local rim = button:CreateTexture(nil, "BACKGROUND", nil, -1)
  rim:SetPoint("TOPLEFT", -3, 3); rim:SetPoint("BOTTOMRIGHT", 3, -3)
  rim:SetColorTexture(0.86, 0.80, 0.66, 0.9)
  local bg = button:CreateTexture(nil, "BACKGROUND")
  bg:SetPoint("TOPLEFT", -2, 2); bg:SetPoint("BOTTOMRIGHT", 2, -2)
  bg:SetColorTexture(0.05, 0.03, 0.02, 0.85)
  button.icon = button:CreateTexture(nil, "ARTWORK")
  button.icon:SetAllPoints()
  Look.Tex(button.icon, media(SceneMap.SWITCH))
  button:SetScript("OnClick", function() Look.Sound("click"); SceneMap.ToggleMenu() end)
  button:SetScript("OnEnter", function(self)
    local tip = G("GameTooltip")
    if not tip then return end
    tip:SetOwner(self, "ANCHOR_RIGHT")
    tip:SetText(L.SCENE_MAP_TIP, 1, 1, 1, 1, true)
    tip:AddLine(Look.Join(setting("on") ~= false and L.WORD_ON or L.WORD_OFF, SceneMap.DaysWord(setting("days"))), 0.85, 0.82, 0.75, true)
    -- 1.5.0 fixer: what the pins mean
    for _, l in ipairs(SceneMap.Legend()) do tip:AddLine(l, 0.85, 0.82, 0.75, true) end
    tip:AddLine(L.SCENE_MAP_CLICK, 0.6, 0.6, 0.6, true)
    tip:Show()
  end)
  button:SetScript("OnLeave", pinLeave)
  SceneMap.UpdateButton()
end
function SceneMap.Button() return button end

-- the legend of the switch's tooltip: one line per kind of pin, its picture in front
local LEGEND = { { "death", "SCENE_LEG_DEATH" }, { "kill", "SCENE_LEG_KILL" }, { "guild", "SCENE_SRC_GUILD" },
  { "friend", "SCENE_SRC_FRIEND" } }
function SceneMap.Legend()
  local out = {}
  for _, row in ipairs(LEGEND) do
    local tint = SceneMap.TINT[row[1]]
    local col = tint and (":0:0:0:0:64:64:0:64:0:64:%d:%d:%d"):format(math.floor(tint[1] * 255), math.floor(tint[2] * 255),
      math.floor(tint[3] * 255)) or ""
    out[#out + 1] = "|T" .. media(TEX[row[1]]) .. ":16:16" .. col .. "|t " .. (L[row[2]] or row[2])
  end
  out[#out + 1] = "|T" .. media("scene_badge.tga") .. ":12:12|t " .. L.SCENE_LEG_BUNDLE
  return out
end

---------------------------------------------------------------------------
-- 1.5.0 fixer: the list of a bundle (a click on a pin with a count): its scenes, a click opens one
---------------------------------------------------------------------------
SceneMap.PICK_W, SceneMap.PICK_ROW = 400, 18   -- 1.5.0 fixer: room for "date · sentence", the rest in the tooltip
local function buildPick()
  local host = map.ScrollContainer or map
  pick = CreateFrame("Frame", nil, host)
  pick:SetSize(SceneMap.PICK_W, 40)
  pick:SetFrameStrata("DIALOG")
  pick:EnableMouse(true)
  local bg = pick:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  Look.Skin(bg, "paper")
  pick.head = Look.Text(pick, "type", 11, Look.INK)
  pick.head:SetPoint("TOPLEFT", 8, -6)
  pick.head:SetWidth(SceneMap.PICK_W - 16)
  pick.head:SetJustifyH("LEFT")
  pick.head:SetWordWrap(false)
  pick.rows = {}
  for i = 1, SceneMap.PICK_MAX + 1 do
    local b = CreateFrame("Button", nil, pick)
    b:SetSize(SceneMap.PICK_W - 12, SceneMap.PICK_ROW)
    b:SetPoint("TOPLEFT", 6, -22 - (i - 1) * SceneMap.PICK_ROW)
    b.text = Look.Text(b, "body", 11, Look.INK)
    b.text:SetPoint("LEFT", 4, 0)
    b.text:SetWidth(SceneMap.PICK_W - 20)
    b.text:SetJustifyH("LEFT")
    b.text:SetWordWrap(false)
    b:SetScript("OnClick", function(self)
      if self.item then Look.Sound("click"); SceneMap.Go(self.item) end
    end)
    Look.TipIfCut(b, b.text)   -- 1.5.0 fixer: a cut row shows itself whole on hover
    pick.rows[i] = b
  end
  pick:Hide()
end

function SceneMap.ShowPick(pin)
  local p = pin and pin.data
  if not (p and map) then return end
  guard("pick", function()
    if not pick then buildPick() end
    local S = Scene()
    pick.head:SetText(Fmt(L.SCENE_BUNDLE, { count = #p.items }))
    local n = math.min(#p.items, SceneMap.PICK_MAX)
    for i, b in ipairs(pick.rows) do
      local it = i <= n and p.items[i] or nil
      b.item = it
      if it then b.text:SetText(S.Short(it)); b:Show()
      elseif i == n + 1 and #p.items > n then b.text:SetText(Fmt(L.MORE_LINE, { count = #p.items - n })); b:Show()
      else b:Hide() end
    end
    local rows = n + ((#p.items > n) and 1 or 0)
    pick:SetHeight(28 + rows * SceneMap.PICK_ROW)
    pick:ClearAllPoints()
    pick:SetPoint("TOPLEFT", pin, "BOTTOMRIGHT", 2, 0)
    pick:SetClampedToScreen(true)
    pick:Show()
    pick:Raise()
  end)
end
function SceneMap.Pick() return pick end

---------------------------------------------------------------------------
-- Attaching to the map (once; the map exists at login on Forever: HereBeDragons in Questie adds its provider at load)
---------------------------------------------------------------------------
function SceneMap.Attach()
  if map then return true end
  local wm = G("WorldMapFrame")
  if type(wm) ~= "table" or type(wm.GetCanvas) ~= "function" then return false end
  local ok = guard("attach", function()
    map = wm
    local hook = G("hooksecurefunc")
    if hook then
      if type(wm.OnMapChanged) == "function" then hook(wm, "OnMapChanged", SceneMap.Refresh) end
      if type(wm.OnCanvasScaleChanged) == "function" then hook(wm, "OnCanvasScaleChanged", rescale) end
    end
    wm:HookScript("OnShow", SceneMap.Refresh)
    wm:HookScript("OnHide", function()
      if menu then menu:Hide() end
      if pick then pick:Hide() end
      -- 1.5.0 fixer: the map was opened from the book and closed without a pin's click: back to the book
      if SceneMap.fromBook then
        SceneMap.fromBook = nil
        local book = G("DeathNoteFrame")
        if book and not inCombat() and not book:IsShown() then guard("back", function() book:Show() end) end
      end
    end)
    buildButton()
    return true
  end)
  if not ok then map = nil; return false end
  local S = Scene()
  if S then S.attached = true end
  return true
end
function SceneMap.Map() return map end
-- what the client offers for the map (probe.scene)
function SceneMap.Api()
  local C_Map, wm = G("C_Map"), G("WorldMapFrame")
  return { mapFrame = type(wm) == "table", canvas = type(wm) == "table" and type(wm.GetCanvas) == "function",
    openWorldMap = type(C_Map) == "table" and type(C_Map.OpenWorldMap) == "function",
    mapRect = type(C_Map) == "table" and type(C_Map.GetMapRectOnMap) == "function",
    hook = type(G("hooksecurefunc")) == "function" }
end

-- tests: back to nothing attached
function SceneMap.Reset()
  releaseAll()
  map, button, menu, hint, marker, pick, pending = nil, nil, nil, nil, nil, nil, false
  SceneMap.fromBook = nil
  pool, used = {}, {}
  SceneMap.focus, SceneMap.focusUntil = nil, 0
  local S = Scene()
  if S then S.attached = false end
end

local function refreshSoon() if map and map:IsShown() then SceneMap.Refresh() end end
ns:On("READY", function() SceneMap.Attach() end)
ns:On("SCENE_PLACE", refreshSoon)
ns:On("DEATH_RECORDED", refreshSoon)
ns:On("OWN_KILL", refreshSoon)
ns:On("SETTINGS_CHANGED", function(path)
  if type(path) == "string" and path:find("^scene%.") then
    SceneMap.UpdateButton()
    if menu and menu:IsShown() then SceneMap.FillMenu() end
    refreshSoon()
  end
end)
ns:RegisterEvent("PLAYER_REGEN_ENABLED", function()
  if pending then pending = false; refreshSoon() end
end)
ns:RegisterEvent("ADDON_LOADED", function(_, name)
  if name == "Blizzard_WorldMap" then SceneMap.Attach() end
end)
