local ADDON, ns = ...

-- 1.6.0 call: what the help call and the sightings show (the logic is Call.lua).
--   * the notice of a received call: a small paper slip at the top of the screen with the red edge of the alarm, the
--     loud alarm sound (Look.Alarm, the player's sound and volume), "Anna calls for help: Ashenvale (same zone),
--     attacker Grimm". A click opens the map there (out of combat; in combat the map says so, as the book's places do),
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

CU.W, CU.PAD, CU.SHOW = 320, 10, 20
CU.POINT = { "TOP", "TOP", 0, -150 }     -- below the raid warning, above the middle of the screen
CU.FIT_HEAD = { sizes = { 13, 11, 10 }, lines = 3 }
CU.FIT_HINT = { sizes = { 10, 9 } }
CU.BTN_W, CU.BTN_H = 54, 15

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
  slip:SetSize(CU.W, 56)
  slip:SetFrameStrata("HIGH")
  slip:SetClampedToScreen(true)
  slip:EnableMouse(true)
  slip:Hide()
  local p = CU.POINT
  slip:SetPoint(p[1], UIParent, p[2], p[3], p[4])
  local bg = slip:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  Look.Skin(bg, "paper")
  local edge = slip:CreateTexture(nil, "BORDER")
  edge:SetPoint("TOPLEFT", 0, 0); edge:SetPoint("BOTTOMLEFT", 0, 0)
  edge:SetWidth(3)
  edge:SetColorTexture(C(Look.RED_INK, 0.9))
  slip.head = Look.Text(slip, "body", 13, Look.RED_INK)
  slip.head:SetPoint("TOPLEFT", CU.PAD + 2, -8)
  slip.head:SetWidth(CU.W - 2 * CU.PAD - 2)
  slip.head:SetJustifyH("LEFT")
  slip.hint = Look.Text(slip, "body", 10, Look.INK)
  slip.hint:SetPoint("BOTTOMLEFT", CU.PAD + 2, 7)
  slip.hint:SetWidth(CU.W - 2 * CU.PAD - 2)
  slip.hint:SetJustifyH("LEFT")
  slip.hint:SetWordWrap(false)
  slip:SetScript("OnMouseUp", function(self, mouse)
    if mouse == "RightButton" then hide(); return end
    local rec = self.rec
    hide()
    if rec then CU.ShowOnMap(rec) end
  end)
  slip:SetScript("OnEnter", function(self)
    local tip = G("GameTooltip")
    if not tip then return end
    tip:SetOwner(self, "ANCHOR_BOTTOM")
    tip:SetText(self.head:GetText() or "", 1, 1, 1, 1, true)
    tip:AddLine(L.CALL_TIP, 0.85, 0.82, 0.75, true)
    tip:Show()
  end)
  slip:SetScript("OnLeave", function() local tip = G("GameTooltip"); if tip then tip:Hide() end end)
end

-- the slip for a received call
function CU.Show(rec)
  L, Fmt = ns.L, ns.F
  if not slip then build() end
  slip.rec = rec
  Look.FitText(slip.head, ns.Call.InLine(rec), CU.FIT_HEAD)
  Look.FitText(slip.hint, L.CALL_TIP, CU.FIT_HINT)
  local h = (slip.head.GetStringHeight and slip.head:GetStringHeight()) or 16
  if type(h) ~= "number" or h <= 0 then h = 16 end
  slip:SetHeight(math.max(48, math.ceil(h) + 8 + 22))
  slip:Show()
  local token = {}
  slip.token = token
  local T = G("C_Timer")
  if T and T.After then T.After(CU.SHOW, function() if slip and slip.token == token then hide() end end) end
  return slip
end
function CU.Slip() return slip end

-- a received call: loud (the alarm's sound and the slip) unless the alarm is off
function CU.OnCall(rec)
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
  b:SetLabel(L.CALL_BUTTON)
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
