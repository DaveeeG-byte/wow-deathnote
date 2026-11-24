local ADDON, ns = ...

-- 1.6.0 call: what the help call and the sightings show (the logic is Call.lua).
--   * the notice of a received call: a paper slip at the top of the screen like the bounty notice ("CALL FOR HELP",
--     the caller big, "Ashenvale (same zone) · attacker Grimm"), the loud alarm sound (Look.Alarm, the player's sound
--     and volume). A click opens the map there (out of combat; in combat the map says so, as the book's places do),
--     a right click closes it; it goes by itself after SHOW seconds. With the alarm switched off (/dn quiet): only the
--     chat line, no sound, no slip.
--   * the button "Help" at the head of the grudge notice while an attacker stands on it (GrudgeCard.lua asks).
--   * the chat links of Call.lua: [Map] (a call or a sighting on the map), [Call in guild chat] (the visible line).
--   * the map: a new call or sighting redraws the pins while the map is open (SceneMap waits for the end of a fight).
-- Every call into the game goes through pcall; an error costs the slip, never the book, the alarm or the death detection.

local Look = ns.Look
local L, Fmt = ns.L, ns.F
local CU = {}
ns.CallUI = CU

-- design fix 1.6.0: built like the bounty slip (a strip torn from a page): the spaced red kicker "CALL FOR HELP",
-- the caller's name big in the head font, the place and the attacker in ink, the hint small and faded. It hangs below
-- the band of the client's red error texts (UIErrorsFrame, TOP -122, 60 high), so it never reads as one of them.
CU.W, CU.PAD, CU.SHOW = 352, 26, 20
CU.LINE_W = 300
CU.POINT = { "TOP", "TOP", 0, -186 }     -- below the client's error band (TOP -122 to -182)
CU.FIT_KICKER = { sizes = { 10, 9 } }
CU.FIT_NAME = { sizes = { 19, 16, 13 } }
CU.FIT_LINE = { sizes = { 11, 10 }, lines = 2, wrapFirst = true }
CU.FIT_HINT = { sizes = { 9 } }
CU.HINT_ALPHA = 0.6
-- design fix 1.6.0: the button on the grudge notice is a target for a click in a fight: 72 x 18, the word at 11 pt
CU.BTN_W, CU.BTN_H = 72, 18
CU.FIT_BTN = { sizes = { 11, 10, 9 } }

local slip
local function C(c, a) return c[1], c[2], c[3], a or c[4] or 1 end
local function G(n) return rawget(_G, n) end

local function hide() if slip then slip:Hide(); slip.rec = nil end end

-- the map at a call or sighting (SceneMap.Show: in combat only a chat line)
function CU.ShowOnMap(rec)
  local SM = ns.SceneMap
  if type(rec) ~= "table" or not (SM and SM.Show) then return nil end
  local ok, res = pcall(SM.Show, { mapID = rec.mapID, x = rec.x, y = rec.y, zone = rec.zone, t = rec.t }, rec)
  return ok and res or nil
end

local function build()
  slip = CreateFrame("Frame", "DeathNoteCall", UIParent)
  slip:SetSize(CU.W, 80)
  slip:SetFrameStrata("HIGH")
  slip:SetClampedToScreen(true)
  slip:EnableMouse(true)
  slip:Hide()
  local p = CU.POINT
  slip:SetPoint(p[1], UIParent, p[2], p[3], p[4])
  -- the slip of the bounty notice (ragged ends that fade out), tinted like the theme's slip
  local bg = slip:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  Look.Skin(bg, "slip")
  Look.Tint(bg, Look.TINT.slip or Look.TINT.paper)
  slip.bg = bg
  slip.kicker = Look.Text(slip, "body", 10, Look.RED_INK)
  slip.kicker:SetPoint("TOP", 0, -7)
  slip.kicker:SetWidth(CU.LINE_W)
  slip.kicker:SetWordWrap(false)
  slip.name = Look.Text(slip, "head", 19, Look.INK)
  slip.name:SetPoint("TOP", slip.kicker, "BOTTOM", 0, -1)
  slip.name:SetWidth(CU.LINE_W)
  slip.name:SetWordWrap(false)
  slip.line = Look.Text(slip, "body", 11, Look.INK)
  slip.line:SetPoint("TOP", slip.name, "BOTTOM", 0, -2)
  slip.line:SetWidth(CU.LINE_W)
  slip.line:SetJustifyH("CENTER")
  slip.hint = Look.Text(slip, "body", 9, { Look.INK[1], Look.INK[2], Look.INK[3], CU.HINT_ALPHA })
  slip.hint:SetPoint("BOTTOM", 0, 7)
  slip.hint:SetWidth(CU.LINE_W)
  slip.hint:SetWordWrap(false)
  slip:SetScript("OnMouseUp", function(self, mouse)
    -- 1.6.4 move: on the sample of the placing mode a right click ends the mode, a left click does nothing
    if self.sample then
      if mouse == "RightButton" then CU.SampleDone("click") end
      return
    end
    if mouse == "RightButton" then hide(); return end
    local rec = self.rec
    hide()
    if rec then CU.ShowOnMap(rec) end
  end)
  slip:SetScript("OnEnter", function(self)
    local tip = G("GameTooltip")
    if not tip then return end
    tip:SetOwner(self, "ANCHOR_BOTTOM")
    tip:SetText(self.full or "", 1, 1, 1, 1, true)
    for i = 1, #(self.kept or {}) do tip:AddLine(self.kept[i], 1, 1, 1, true) end   -- 1.6.2: the calls before it
    tip:AddLine(L.CALL_TIP, 0.85, 0.82, 0.75, true)
    tip:Show()
  end)
  slip:SetScript("OnLeave", function() local tip = G("GameTooltip"); if tip then tip:Hide() end end)
  -- 1.6.4 move: dragged only as the sample of the placing mode; the place is kept in call.point
  slip:SetMovable(true)
  slip:RegisterForDrag("LeftButton")
  slip:SetScript("OnDragStart", function(self)
    if not self.sample or (InCombatLockdown and InCombatLockdown()) then return end
    self.moving = true
    self:StartMoving()
  end)
  slip:SetScript("OnDragStop", function(self)
    if not self.moving then return end
    CU.EndDrag()
    if ns.Place and ns.Place.Moved then pcall(ns.Place.Moved, "call") end
  end)
end

-- the slip's third line: "Ashenvale (same zone) · attacker Grimm" (the words of Call.InLine without the caller)
function CU.Where(rec)
  local where = rec.same == true and L.CALL_SAME_ZONE or rec.same == false and L.CALL_OTHER_ZONE or nil
  local zone = rec.zone or L.CALL_SOMEWHERE
  if where then zone = zone .. " (" .. where .. ")" end
  if rec.display then return Fmt(L.CALL_SLIP_BY, { zone = zone, attacker = rec.display }) end
  return zone
end

-- 1.6.0 fix: the slip and the alarm never cover each other. While the alarm stands where the slip would, the slip goes
-- above it (the bounty slip and the remark use the room below), below it only when there is no room above; when the
-- alarm goes, the slip goes back. Alert.lua calls this after placing its popup; the popup's OnHide is hooked here.
CU.GAP = 4
CU.KEPT = 4   -- 1.6.2: earlier calls a slip keeps for its tooltip
local hooked
-- 1.6.4 move: the place the player dragged the slip to (call.point): its top, left and right edge in UIParent units,
-- true alone when it is kept but cannot be measured (it stays as anchored), nil without one or off the screen
local function held()
  local hp, hrp, hx, hy = Look.Point(Look.Setting("call.point"))
  if not hp then return nil end
  slip:ClearAllPoints()
  slip:SetPoint(hp, UIParent, hrp, hx, hy)
  if Look.OnScreen(slip) == false then return nil end
  local l, _, r, t = Look.Rect(slip)
  if not l then return true end
  return t, l, r
end

function CU.Place()
  if not slip or slip.moving then return end
  local p = CU.POINT
  local l, b, r, t
  if slip:IsShown() and ns.Alert and ns.Alert.Rect then l, b, r, t = ns.Alert.Rect() end
  local W, H = UIParent:GetWidth(), UIParent:GetHeight()
  local sh = slip:GetHeight()
  local where
  local kt, kl, kr = held()
  if kt == true then return end
  if l and type(W) == "number" and type(H) == "number" and type(sh) == "number"
    and not (Look.Secret(W) or Look.Secret(H) or Look.Secret(sh)) then
    local st = kt or (H + p[4])
    local sb, sl, sr = st - sh, kl or (W / 2 - CU.W / 2), kr or (W / 2 + CU.W / 2)
    if sl < r and sr > l and sb < t + CU.GAP and st > b - CU.GAP then
      -- design fix 1.6.0: below the alarm (above it would be the client's error band), above only without room below
      if b - CU.GAP - sh >= 0 then where = { "TOP", (l + r) / 2, b - CU.GAP }
      else where = { "BOTTOM", (l + r) / 2, t + CU.GAP } end
    end
  end
  if where then
    slip:ClearAllPoints()
    slip:SetPoint(where[1], UIParent, "BOTTOMLEFT", where[2], where[3])
  elseif not kt then
    slip:ClearAllPoints()
    slip:SetPoint(p[1], UIParent, p[2], p[3], p[4])
  end
  if not hooked then
    local pop = G("DeathNoteAlert")
    if pop and pop.HookScript then
      hooked = true
      pop:HookScript("OnHide", function() pcall(CU.Place) end)
    end
  end
  -- the bounty notice keeps clear of the slip (Extras.PlaceBanner asks CU.Rect)
  local X = ns.Extras
  if X and X.PlaceBanner then pcall(X.PlaceBanner) end
end

-- the shown slip in UIParent units (for the bounty notice), else nil
function CU.Rect()
  if not (slip and slip:IsShown()) then return nil end
  return Look.Rect(slip)
end

-- the slip for a received call
function CU.Show(rec)
  L, Fmt = ns.L, ns.F
  if not slip then build() end
  -- 1.6.4 move: a real call ends the placing mode first (the sample goes, the slip comes as always)
  if slip.sample then CU.SampleDone("call") end
  -- 1.6.2: a call that replaces a slip still shown: the kicker counts the calls ("+1"), the tooltip keeps the lines
  -- of the earlier ones (newest first, at most CU.KEPT); the next slip after a pause starts anew
  local was = slip:IsShown() and slip.rec ~= nil and slip.rec ~= rec
  local kept = slip.kept or {}
  slip.kept = kept
  if was then
    table.insert(kept, 1, slip.full)
    while #kept > CU.KEPT do table.remove(kept) end
    slip.more = (slip.more or 0) + 1
  else
    for i = #kept, 1, -1 do kept[i] = nil end
    slip.more = 0
  end
  slip.rec = rec
  slip.full = ns.Call.InLine(rec)
  local Ex = ns.Extras
  local kick = Ex and Ex.Spaced and Ex.Spaced(L.CALL_SLIP_HEAD) or L.CALL_SLIP_HEAD
  if slip.more > 0 then kick = kick .. "   +" .. slip.more end
  Look.FitText(slip.kicker, kick, CU.FIT_KICKER)
  Look.FitText(slip.name, tostring(rec.by or "?"), CU.FIT_NAME)
  Look.FitText(slip.line, CU.Where(rec), CU.FIT_LINE)
  Look.FitText(slip.hint, L.CALL_TIP, CU.FIT_HINT)
  local function h(fs, n, d)
    local v = Look.TextH and Look.TextH(fs, n) or (fs.GetStringHeight and fs:GetStringHeight())
    if type(v) ~= "number" or Look.Secret(v) or v <= 0 then v = d end
    return math.ceil(v)
  end
  -- 7 top, kicker, 1, name, 2, place (one or two lines), 3, hint, 7 bottom
  slip:SetHeight(7 + h(slip.kicker, 1, 12) + 1 + h(slip.name, 1, 22) + 2 + h(slip.line, 2, 13) + 3
    + h(slip.hint, 1, 11) + 7)
  slip:Show()
  pcall(CU.Place)
  local token = {}
  slip.token = token
  local T = G("C_Timer")
  if T and T.After then T.After(CU.SHOW, function() if slip and slip.token == token then hide() end end) end
  return slip
end
function CU.Slip() return slip end

---------------------------------------------------------------------------
-- 1.6.4 move: the sample of the placing mode (Place.lua): a made-up call that stays until the mode ends, "Drag to
-- move" in place of the hint. A real slip on the screen gives way (its call stays in the chat line).
---------------------------------------------------------------------------
CU.SAMPLE = { by = "Liora", display = "Grimmzahn", same = true }
function CU.EndDrag()
  if not (slip and slip.moving) then return end
  slip.moving = nil
  slip:StopMovingOrSizing()
  if slip.SetUserPlaced then pcall(slip.SetUserPlaced, slip, false) end
  local p, _, rp, x, y = slip:GetPoint(1)
  if p and ns.Store and ns.Store.Setting then ns.Store.Setting("call.point", { p, rp, x, y }) end
  pcall(CU.Place)
end

function CU.ShowSample()
  L, Fmt = ns.L, ns.F
  if not slip then build() end
  slip.token = nil              -- the timer of a real slip no longer hides it
  slip.rec, slip.more, slip.full = nil, 0, nil
  if slip.kept then for i = #slip.kept, 1, -1 do slip.kept[i] = nil end end
  slip.sample = true
  local Ex = ns.Extras
  Look.FitText(slip.kicker, Ex and Ex.Spaced and Ex.Spaced(L.CALL_SLIP_HEAD) or L.CALL_SLIP_HEAD, CU.FIT_KICKER)
  Look.FitText(slip.name, CU.SAMPLE.by, CU.FIT_NAME)
  local rec = { zone = L.SAMPLE_ZONE, same = CU.SAMPLE.same, display = CU.SAMPLE.display }
  Look.FitText(slip.line, CU.Where(rec), CU.FIT_LINE)
  Look.FitText(slip.hint, L.MOVE_DRAG, CU.FIT_HINT)
  local function h(fs, n, d)
    local v = Look.TextH and Look.TextH(fs, n) or (fs.GetStringHeight and fs:GetStringHeight())
    if type(v) ~= "number" or Look.Secret(v) or v <= 0 then v = d end
    return math.ceil(v)
  end
  slip:SetHeight(7 + h(slip.kicker, 1, 12) + 1 + h(slip.name, 1, 22) + 2 + h(slip.line, 2, 13) + 3
    + h(slip.hint, 1, 11) + 7)
  slip:Show()
  pcall(CU.Place)
  return true
end

function CU.EndSample()
  if not (slip and slip.sample) then return end
  CU.EndDrag()
  slip.sample = nil
  local tip = G("GameTooltip")
  if tip and tip.IsOwned and tip:IsOwned(slip) then tip:Hide() end
  hide()
  pcall(CU.Place)
end

function CU.SampleShown() return slip ~= nil and slip.sample == true and slip:IsShown() end

function CU.SampleDone(why)
  local P = ns.Place
  if P and P.Stop then pcall(P.Stop, why) end
  if slip and slip.sample then CU.EndSample() end
end

function CU.ResetPosition()
  if ns.Store and ns.Store.Setting then ns.Store.Setting("call.point", nil) end
  pcall(CU.Place)
end

-- a received call: loud (the alarm's sound and the slip) unless the alarm is off or the player stands in an
-- instance (rec.quiet: only the chat line there)
function CU.OnCall(rec)
  if type(rec) == "table" and rec.quiet == true then return end
  if Look.Setting("alert.enabled", true) == false then return end
  pcall(Look.Alarm, "alert")
  CU.Show(rec)
end

---------------------------------------------------------------------------
-- The button "Help" on the grudge notice (GrudgeCard.Fill asks; returns the room the head gives up)
---------------------------------------------------------------------------
function CU.OnCard(card, e, n)
  L = ns.L
  local b = card.dnCall
  local want = type(e) == "table" and (tonumber(n) or 0) > 0 and ns.Call ~= nil
  if not want then
    if b then b:Hide() end
    return 0
  end
  if not b then
    local Kit = ns.UI and ns.UI.Kit
    if not (Kit and Kit.InkButton) then return 0 end
    b = Kit.InkButton(card, "", CU.BTN_W, CU.BTN_H)
    b:SetPoint("TOPRIGHT", card, "TOPRIGHT", -6, -3)
    b.fn = function() if ns.Call then ns.Call.Trigger() end end
    b:HookScript("OnEnter", function(self)
      local tip = G("GameTooltip")
      if not tip then return end
      tip:SetOwner(self, "ANCHOR_LEFT")
      tip:SetText(L.BIND_HELP, 1, 1, 1, 1, true)
      tip:AddLine(L.CALL_BUTTON_TIP, 0.85, 0.82, 0.75, true)
      tip:Show()
    end)
    b:HookScript("OnLeave", function() local tip = G("GameTooltip"); if tip then tip:Hide() end end)
    card.dnCall = b
  end
  b.text:SetWidth(CU.BTN_W - 6)
  Look.FitText(b.text, L.CALL_BUTTON, CU.FIT_BTN)
  b:Show()
  return CU.BTN_W + 6
end

---------------------------------------------------------------------------
-- From the map into the book (SceneMap.OpenBook): the enemy in Guild & Friends, else in my book, else the book
---------------------------------------------------------------------------
function CU.OpenBook(it)
  local UI, Gd, S = ns.UI, ns.Guild, ns.Store
  if not UI then return end
  local key = type(it) == "table" and it.key or nil
  if key and Gd and Gd.Get and Gd.Get(key, "all") and UI.ShowGuildEnemy then
    local src = it.src or (Gd.Source and Gd.Source(key) == "friends" and "friends") or "guild"
    UI.ShowGuildEnemy(key, src == "friends" and "friends" or "guild")
  elseif key and S and S.Get and S.Get(key) and UI.ShowEnemy then
    UI.ShowEnemy(key)
  elseif UI.Open then
    UI.Open()
  end
end

---------------------------------------------------------------------------
-- Chat links: addon:DeathNote:call:<what>:<id>
---------------------------------------------------------------------------
function CU.OnLink(link)
  if type(link) ~= "string" or Look.Secret(link) then return false end
  local what, id = link:match("^addon:" .. ADDON .. ":call:(%a+):(%d+)$")
  if not what or not ns.Call then return false end
  if what == "gchat" then
    local ok, why = ns.Call.GuildChat()
    if not ok and ns.Util then
      local SU = ns.ShareUI
      local text = SU and SU.Reason and SU.Reason(why) or tostring(why)
      ns.Util.Print(Fmt(L.CALL_GCHAT_NO, { reason = tostring(text) }))
    end
    return true
  end
  if what == "map" then
    local rec = ns.Call.links[tonumber(id)]
    if rec then CU.ShowOnMap(rec) end
    return true
  end
  return false
end

function CU.HookClicks()
  if CU.clickVia then return end
  local ER = G("EventRegistry")
  if type(ER) == "table" and type(ER.RegisterCallback) == "function" then
    local ok = pcall(ER.RegisterCallback, ER, "SetItemRef", function(_, link) pcall(CU.OnLink, link) end, CU)
    if ok then CU.clickVia = "EventRegistry"; return end
  end
  local hook = G("hooksecurefunc")
  if type(hook) == "function" and type(G("SetItemRef")) == "function" then
    if pcall(hook, "SetItemRef", function(link) pcall(CU.OnLink, link) end) then CU.clickVia = "hook"; return end
  end
  CU.clickVia = "none"
end

-- the open map shows a new pin at once (SceneMap.Refresh waits for the end of a fight by itself)
local function redraw()
  local SM = ns.SceneMap
  local map = SM and SM.Map and SM.Map()
  if map and map.IsShown and map:IsShown() and SM.Refresh then pcall(SM.Refresh) end
end

ns:On("READY", function() pcall(CU.HookClicks) end)
ns:On("HELP_CALL", function(rec)
  local ok, err = pcall(CU.OnCall, rec)
  if not ok and ns.ReportError then ns.ReportError(err) end
  redraw()
end)
ns:On("SIGHTING", redraw)
