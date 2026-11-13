local ADDON, ns = ...

-- The notebook: black leather cover, on the left a ruled page with the names written in by hand,
-- on the right the wanted poster of the selected one, pasted in.
-- Four tabs: Wanted, Unsolved, Death Log, Guild (1.2.0: Guild & Friends, with the hit list);
-- plus "?" (manual) and the
-- cog (house rules). Built on the first TOGGLE_UI; the rows come from a fixed pool.

local Look = ns.Look
-- Texts (1.2.0): read L.KEY only in functions that run after ADDON_LOADED; Fmt fills {placeholders}
local L, Fmt = ns.L, ns.F
local UI = {}
ns.UI = UI
-- 1.2.0: rarely called helpers and fixed tables without a local name of their own (keeps room below the limit of
-- 200 local names per file; tests/test_grenzen.lua guards it)
local UX = {}
-- 1.3.0: the rap sheet's tab (fifth tab, own file, victims), filled further down
local RS = {}

local W, H = 800, 548
local PAGE_W, PAGE_H = 380, 490
local ROWS, ROW_H, ROW_TOP = 9, 44, -42
local LINE_H = 22                 -- line spacing of the left page: name on the first line, subtext on the second
local DEATH_LINES = 6
local INFO_LINES = 4
local TONE = Look.TONE

UX.FILTERS = {
  { id = "wanted",  key = "TAB_WANTED" },
  { id = "open",    key = "TAB_UNSOLVED" },
  { id = "journal", key = "TAB_DEATHLOG" },
  { id = "guild",   key = "TAB_GUILD" },
  { id = "record",  key = "TAB_RECORD" },   -- 1.3.0: only from the first own kill on (RS.On)
}
UX.SORTS = { "rank", "recent", "name", "seen" }
UX.GSORTS = { "rank", "recent", "name" }
local SORT_LABEL = { rank = "SORT_RANK", recent = "SORT_RECENT", name = "SORT_NAME", seen = "SORT_SEEN",
  state = "SORT_STATE", points = "SORT_POINTS", count = "SORT_COUNT" }   -- locale keys (the last three: rap sheet)
-- Empty states: large, small, very small (only the first tab explains what the book does)
-- per state: key stem and number of lines (STEM_HEAD, _SUB, _HINT in the locale table)
local EMPTY = {
  wanted = { "EMPTY_WANTED", 3 }, open = { "EMPTY_OPEN", 1 }, journal = { "EMPTY_JOURNAL", 2 },
  noguild = { "EMPTY_NOGUILD", 2 }, guildoff = { "EMPTY_GUILDOFF", 2 }, guildnil = { "EMPTY_GUILDNIL", 2 },
  guildquiet = { "EMPTY_GUILDQUIET", 2 },
  -- 1.2.0: friends, both sources together, hit list
  friendsoff = { "EMPTY_FRIENDSOFF", 2 }, friendsnil = { "EMPTY_FRIENDSNIL", 2 }, friendsquiet = { "EMPTY_FRIENDSQUIET", 2 },
  nobody = { "EMPTY_NOBODY", 3 }, sharednil = { "EMPTY_SHAREDNIL", 2 }, sharedquiet = { "EMPTY_SHAREDQUIET", 2 },
  hunt = { "EMPTY_HUNT", 3 }, search = { "EMPTY_SEARCH", 2 }, searchro = { "EMPTY_SEARCHRO", 2 },
}
local EXPORT_WARN = 100 * 1024     -- above this, "Back up the book" gets sluggish in the EditBox
-- Guild book: only entries a guildmate (1.2.0: or friend) took part in; per source
local FOREIGN = { all = { foreign = true, source = "all" }, guild = { foreign = true, source = "guild" },
                  friends = { foreign = true, source = "friends" } }
-- 1.2.0: helpers for Guild & Friends and the hit list in one table (UI.lua is at the limit
-- of 200 local names per file)
local GF = { SOURCES = { { "all", "SRC_ALL" }, { "guild", "SRC_GUILD" }, { "friends", "SRC_FRIENDS" } },
             STAMP_W = 140, STAMP_H = 70, MENU_MAX = 6, CAND_MAX = 6, ASSIST_MAX = 4,
             WHY_ROW = 24,    -- reason in a hit list row: at most this many characters (then "…")
             -- 1.2.1: seconds of "Undo" after "Note revenge", bounty posters or avengers per row (then "and n more");
             -- the coin on a killer with a bounty is Look.TEX.coin (1.3.0, theme)
             UNDO_SECONDS = 8, UNDO_LOCK = 0.5 }

-- Manual ("?"): every paragraph describes what is really built (acceptance mirror)
UX.HELP = {
  { "MANUAL_BOOK_HEAD", "MANUAL_BOOK" },
  { "MANUAL_WANTED_HEAD", "MANUAL_WANTED" },
  { "MANUAL_UNSOLVED_HEAD", "MANUAL_UNSOLVED" },
  { "MANUAL_ALERT_HEAD", "MANUAL_ALERT" },
  { "MANUAL_ADD_HEAD", "MANUAL_ADD" },
  { "MANUAL_GUILD_HEAD", "MANUAL_GUILD" },
  { "MANUAL_SHARE_HEAD", "MANUAL_SHARE" },
  { "MANUAL_QUIET_HEAD", "MANUAL_QUIET" },
  { "MANUAL_RECORD_HEAD", "MANUAL_RECORD" },   -- 1.3.0
}
-- UI.HELP: the same paragraphs as texts of the active language (filled on activation)
UI.HELP = {}
if ns.Locale and ns.Locale.OnActivate then
  ns.Locale.OnActivate(function()
    for i, p in ipairs(UX.HELP) do UI.HELP[i] = { L[p[1]], L[p[2]] } end
  end)
end

local F            -- main window
local LP, RP       -- left and right page
local P            -- poster (on the right page)
local rows = {}
local data = {}    -- current list (enemies, deaths, open cases or guild enemies), filtered by the search if any
local dataIdx      -- journal with search only: position in the unfiltered list
-- Selection per tab: selected (Wanted, key), osel (Unsolved: journal entry or key),
-- deathRef (Death Log: the entry itself), gselected/gmember (Guild), hselected (hit list)
-- gview: guild "enemy" (by killer), "member" (by guildmate) or "hunt" (hit list, 1.2.0)
-- gsource: source in the fourth tab "all" | "guild" | "friends" (1.2.0); viewPicked: view chosen by the user
local state = { filter = "wanted", sort = "rank", gsort = "rank", offset = 0, selected = nil, osel = nil,
                gselected = nil, death = nil, deathRef = nil, panel = nil, query = "", spage = 1,
                gview = "enemy", gmember = nil, gsource = "all", hselected = nil, viewPicked = false,
                release = nil,
                -- 1.3.0 rap sheet: selected victim (nil = the own file), view of the file ("file" | "log"), sort
                rsel = nil, rview = "file", rsort = "recent" }
local dirty = true
local pending = false
local ready = false
local menu

local function Store() return ns.Store end
local function Set(path, v) if ns.Store and ns.Store.Setting then ns.Store.Setting(path, v) end end
local function C(t, a) return t[1], t[2], t[3], a or t[4] or 1 end
local GCall = Look.GCall
local function HasGuild() return Look.HasGuild() end
-- "By guildmate" exists only when the logic provides ns.Guild.ByMember
local function HasMemberView() return Look.HasGuild() and type(ns.Guild.ByMember) == "function" end
local function MemberView() return state.filter == "guild" and state.gview == "member" and HasMemberView() end
-- 1.2.0: friends' book (Friends.lua) and hit list (Guild.Hunts) exist only with the new logic
function GF.HasFriends() return HasGuild() and type(ns.Friends) == "table" end
function GF.HasHunts() return HasGuild() and type(ns.Guild.Hunts) == "function" end
function GF.HuntView() return state.filter == "guild" and state.gview == "hunt" and GF.HasHunts() end
-- 1.2.0: the source choice exists only when both sources really exist (GF.Survey); otherwise "All" applies
function GF.Src() return GF.HasFriends() and (GF.both == false and "all" or state.gsource) or "guild" end
function GF.FriendsOn()
  if not GF.HasFriends() or type(ns.Friends.Enabled) ~= "function" then return false end
  local ok, v = pcall(ns.Friends.Enabled)
  return ok and v == true
end
-- is the chosen source sharing anything right now? (guild: in a guild; friends: sharing with friends on)
function GF.SrcOn(src)
  src = src or GF.Src()
  local g = GCall("Name") ~= nil
  if src == "guild" then return g end
  if src == "friends" then return GF.FriendsOn() end
  return g or GF.FriendsOn()
end
local AnyCollapsed, SetAllMembers -- forward declaration (guild by guildmate)

------------------------------------------------------------------------
-- 1.3.0 standing "me : him" (Ledger.Standing): one place for row, poster, tooltip (Extras), alarm line (Alert),
-- notice. Everything returns nil while the rap sheet is off or missing: then the book looks as in 1.2.2.
------------------------------------------------------------------------
Look.STATE_WORD = { open = "STATE_OPEN", even = "STATE_EVEN", ahead = "STATE_AHEAD", victim = "STATE_VICTIM",
  pardoned = "TIP_PARDONED" }   -- locale key
-- mine, his and the score text of a book entry (or a key) through Look.Score (Alert.lua: one notation for alarm and
-- book), nil while the rap sheet is off
function Look.Stand(e)
  local key = type(e) == "table" and e.key or e
  if not Look.Score or type(key) ~= "string" then return nil end
  local ok, text, m, h = pcall(Look.Score, key)
  if not ok or type(text) ~= "string" or type(m) ~= "number" or type(h) ~= "number" then return nil end
  return m, h, text
end
-- the state of the numbers alone (the poster of a pardoned one shows its second stamp too); 1.3.0: with the status of
-- the book entry, a pardoned one is "pardoned", never an open case (as Ledger.State: the rap sheet's row and sheet)
function Look.ScoreState(m, h, status)
  if status == "pardoned" then return "pardoned" end
  if h > m or m == 0 then return "open" end
  return h == m and "even" or "ahead"
end
-- "1 : 2" once I killed him, "2 : 2 · even" when settled; nil before my first kill (alarm line, notice)
function Look.StandLine(e)
  local m, h, text = Look.Stand(e)
  if not m or m == 0 then return nil end
  local st = Look.ScoreState(m, h)
  return Look.Join(text, st ~= "open" and L[Look.STATE_WORD[st]] or nil)
end

------------------------------------------------------------------------
-- Building blocks
------------------------------------------------------------------------
local function Rule(parent, y, x1, x2, alpha)
  local t = parent:CreateTexture(nil, "ARTWORK")
  t:SetColorTexture(C(Look.INK, alpha or 0.55))
  t:SetHeight(1)
  t:SetPoint("TOPLEFT", x1 or 24, y)
  t:SetPoint("TOPRIGHT", -(x2 or x1 or 24), y)
  return t
end

-- letter-spaced label: "D E E D S"
local function Spaced(s)
  local out = {}
  for ch in tostring(s):gmatch("[%z\1-\127\194-\244][\128-\191]*") do out[#out + 1] = ch == " " and "  " or ch end
  return table.concat(out, " ")
end

-- label on paper (10 pt, letter-spaced); red = red (small red print)
local function Label(parent, text, red)
  local fs = Look.Text(parent, "body", 10, red and Look.RED_INK or Look.INK)
  if not red then fs:SetTextColor(C(Look.INK, TONE.label)) end
  fs:SetText(Spaced(text))
  return fs
end

-- Button: black, bone-white text, blood-red edge; the text stays inside the button
GF.FIT_INK = { sizes = { 10, 9 } }
local function InkButton(parent, text, w, h, onClick)
  local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
  w, h = w or 104, h or 22
  b:SetSize(w, h)
  b:SetBackdrop({ bgFile = Look.TEX.white, edgeFile = Look.TEX.white, edgeSize = 1 })
  b:SetBackdropColor(C(Look.COLOR.btnFill))
  b:SetBackdropBorderColor(C(Look.COLOR.btnEdge))
  b.text = Look.Text(b, "body", 10, Look.BONE)
  b.text:SetPoint("CENTER", 0, 0)
  b.text:SetWidth(w - 8)
  b.text:SetWordWrap(false)
  b:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(C(Look.COLOR.btnEdgeHot)) end)
  b:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(C(Look.COLOR.btnEdge)) end)
  b:SetScript("OnClick", function(self, mouse)
    Look.Sound("click")
    if self.fn then self.fn(self, mouse) end
  end)
  -- 1.2.0: a label too long for the button in another language gets 9 pt instead of being cut;
  -- 1.2.2: through Look.FitText in the width of the button, and still cut: the whole label in a tooltip
  -- (hooked after the edge colour above, both run)
  function b:SetLabel(t)
    self.text:SetWidth(self:GetWidth() - 8)
    Look.FitText(self.text, t or "", GF.FIT_INK)
  end
  b:SetLabel(text)
  Look.TipIfCut(b, b.text)
  b.fn = onClick
  return b
end

-- Word button on paper (handwriting or file font): hover turns it red, nothing else moves
local function WordButton(parent, text, kind, size, tone)
  local b = CreateFrame("Button", nil, parent)
  b.text = Look.Text(b, kind or "hand", size or 13, Look.INK)
  b.text:SetPoint("LEFT", 0, 0)
  b.text:SetJustifyH("LEFT")
  b.text:SetWordWrap(false)
  b.tone = tone or TONE.sub
  b.text:SetTextColor(C(Look.INK, b.tone))
  b.text:SetText(text or "")
  b:SetSize(80, (size or 13) + 6)
  b:SetScript("OnEnter", function(self) self.text:SetTextColor(C(Look.RED)) end)
  b:SetScript("OnLeave", function(self) self.text:SetTextColor(C(Look.INK, self.tone)) end)
  return b
end

-- Word tabs (sheets of the house rules, channel, guild view): the active word in full ink with a red
-- underline, the others paler. One building block for all word toggles.
local function WordTab(parent, text, w, onClick)
  local t = CreateFrame("Button", nil, parent)
  t:SetSize(w or 90, 20)
  t.text = Look.Text(t, "body", 11, Look.INK)
  t.text:SetPoint("LEFT", 2, 0)
  t.text:SetText(text)
  t.mark = t:CreateTexture(nil, "ARTWORK")
  t.mark:SetColorTexture(C(Look.RED, 1))
  t.mark:SetHeight(2)
  t.mark:SetPoint("BOTTOMLEFT", 0, 0)
  t.mark:SetPoint("BOTTOMRIGHT", 0, 0)
  local hl = t:CreateTexture(nil, "HIGHLIGHT")
  hl:SetAllPoints()
  hl:SetColorTexture(C(Look.INK, 0.06))
  t:SetScript("OnClick", function(self) Look.Sound("click"); if onClick then onClick(self) end end)
  function t:SetOn(on, off)
    self.mark:SetShown(on and true or false)
    self.text:SetTextColor(C(Look.INK, off and TONE.off or (on and TONE.ink or TONE.sub)))
  end
  return t
end

-- Box with an ink border, checked = hand-drawn cross; the label is part of the click area
function UX.InkCheck(parent, label, width)
  local cb = CreateFrame("CheckButton", nil, parent)
  cb:SetSize(width or 300, 20)
  local box = cb:CreateTexture(nil, "ARTWORK")
  box:SetSize(16, 16)
  box:SetPoint("LEFT", 2, 0)
  box:SetColorTexture(C(Look.INK, 0.7))
  local inner = cb:CreateTexture(nil, "ARTWORK", nil, 1)
  inner:SetPoint("TOPLEFT", box, "TOPLEFT", 1, -1)
  inner:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", -1, 1)
  Look.Tex(inner, Look.TEX.white, Look.FB("white"))
  inner:SetVertexColor(C(Look.COLOR.boxFill))
  cb.cross = cb:CreateTexture(nil, "OVERLAY")
  cb.cross:SetSize(20, 20)
  cb.cross:SetPoint("CENTER", box, "CENTER", 1, 1)
  Look.Skin(cb.cross, "check")
  cb.cross:SetVertexColor(C(Look.INK, 0.95))
  cb.cross:Hide()
  local hl = cb:CreateTexture(nil, "HIGHLIGHT")
  hl:SetAllPoints()
  hl:SetColorTexture(C(Look.INK, 0.05))
  cb.label = Look.Text(cb, "body", 11, Look.INK)
  cb.label:SetPoint("LEFT", box, "RIGHT", 8, 0)
  cb.label:SetText(label or "")
  function cb:SetInk(v)
    self:SetChecked(v and true or false)
    self.cross:SetShown(v and true or false)
  end
  return cb
end

-- key: texture of the theme (paper, page, cover) with its fallback colour and tint
local function Tex(frame, layer, key, sub)
  local t = frame:CreateTexture(nil, layer or "BACKGROUND", nil, sub)
  Look.Skin(t, key)
  return t
end

function UX.Shadow(frame, dx, dy, a)
  local s = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
  s:SetColorTexture(C(Look.COLOR.shadow, a or 0.45))
  s:SetPoint("TOPLEFT", dx or 3, -(dy or 3))
  s:SetPoint("BOTTOMRIGHT", dx or 3, -(dy or 3))
  return s
end

-- tape strip at an angle across a corner
local function Tape(frame, corner, rot, dx)
  local t = frame:CreateTexture(nil, "OVERLAY", nil, 6)
  t:SetSize(52, 20)
  t:SetPoint("CENTER", frame, corner, dx or 0, 0)
  Look.Skin(t, "tape")
  t:SetRotation(rot)
  return t
end

-- small ink triangle (tri.tga points right; rot = rotation in radians)
local function Tri(parent, size, rot)
  local t = parent:CreateTexture(nil, "ARTWORK")
  t:SetSize(size, size)
  Look.Skin(t, "tri")
  t:SetVertexColor(C(Look.INK, 0.9))
  if rot and rot ~= 0 then t:SetRotation(rot) end
  return t
end

-- mugshot without a colour spot: desaturated and tinted like paper
local function MugIcon(tex)
  tex:SetDesaturated(true)
  tex:SetVertexColor(C(Look.COLOR.mugTint))
end

local function PlaceText(z, sz)
  if sz and sz ~= "" and z and z ~= "" and sz ~= z then return z .. ", " .. sz end
  return Look.Place(z, sz)
end

local function NameOfKey(key, fallback)
  local e = key and Store().Get(key)
  if e then return Look.Name(e), e end
  return fallback or key or "?"
end

-- width of a text (secret guard, falls back to an estimate)
local function TextWidth(fs, guess)
  local w = fs.GetStringWidth and fs:GetStringWidth()
  if type(w) ~= "number" or Look.Secret(w) then return guess or 140 end
  return w
end

-- width for underline/strike-through from the text length
local function InkWidth(fs)
  return math.max(40, math.min(300, TextWidth(fs, 140) + 10))
end

-- "2875" -> "2.875"
function UX.Thousands(n)
  local s = tostring(math.floor(n))
  local sep = L.THOUSANDS_SEP
  local out = s:reverse():gsub("(%d%d%d)", "%1" .. sep:reverse():gsub("%%", "%%%%")):reverse()
  if out:sub(1, #sep) == sep then out = out:sub(#sep + 1) end
  return out
end

-- bounty in whole gold pieces: "328 GOLD", below 1 gold "50 SILVER"
local function GoldText(copper)
  copper = tonumber(copper) or 0
  local g = math.floor(copper / 10000)
  if g >= 1 then return Fmt(L.BOUNTY_GOLD, { count = UX.Thousands(g) }) end
  local s = math.floor(copper / 100)
  if s >= 1 then return Fmt(L.BOUNTY_SILVER, { count = s }) end
  return Fmt(L.BOUNTY_GOLD, { count = 0 })
end

-- is the FontString really truncated? (with secret guard, as in Details)
local function Truncated(fs)
  if not fs.IsTruncated then return false end
  local ok, v = pcall(fs.IsTruncated, fs)
  if not ok or Look.Secret(v) then return false end
  return v and true or false
end

local function Tip(owner, lines, anchor)
  if type(lines) ~= "table" or not lines[1] then return end
  GameTooltip:SetOwner(owner, anchor or "ANCHOR_RIGHT")
  GameTooltip:SetText(lines[1], Look.BONE[1], Look.BONE[2], Look.BONE[3], 1, true)   -- 1.2.2: a long first line wraps
  for i = 2, #lines do GameTooltip:AddLine(lines[i], 0.82, 0.80, 0.75, true) end
  GameTooltip:Show()
end

-- insert a name into an open chat input (only if the user has one open; never send)
function UX.InsertIntoChat(text)
  if type(text) ~= "string" or text == "" then return false end
  local util = ChatFrameUtil
  local active = (util and util.GetActiveWindow) or ChatEdit_GetActiveWindow
  local insert = (util and util.InsertLink) or ChatEdit_InsertLink
  if type(active) ~= "function" or type(insert) ~= "function" then return false end
  local ok, win = pcall(active)
  if not ok or not win then return false end
  pcall(insert, text)
  return true
end

function UX.Shift()
  if not IsShiftKeyDown then return false end
  local ok, v = pcall(IsShiftKeyDown)
  return ok and not Look.Secret(v) and v and true or false
end

-- Confirmation: one pattern for everything destructive (StaticPopup)
UX.CONFIRM = {
  DEATHNOTE_DELETE = { "CONFIRM_DELETE", "CONFIRM_DELETE_OK",
                       function(_, key) if key then Store().Remove(key) end end },
  DEATHNOTE_GUILD_CLEAR = { "CONFIRM_GUILD_CLEAR", "CONFIRM_GUILD_CLEAR_OK",
                            function() GCall("Clear"); UI.Refresh() end },
  -- 1.2.0: empty the friends' book (with its hit list), call off all own calls
  DEATHNOTE_FRIENDS_CLEAR = { "CONFIRM_FRIENDS_CLEAR", "CONFIRM_GUILD_CLEAR_OK",
                              function() if ns.Friends and ns.Friends.Clear then ns.Friends.Clear() end UI.Refresh() end },
  DEATHNOTE_CALLOFF_ALL = { "CONFIRM_CALLOFF_ALL", "CONFIRM_CALLOFF_ALL_OK",
                            function() GCall("CallOffAll"); UI.Refresh() end },
  -- 1.2.0: friend without surname on the list: release the link to the full name (their data goes with it)
  -- 1.3.0: empty the rap sheet (victims and log; rank, points and awards stay), strike one victim (its points stay)
  DEATHNOTE_RECORD_CLEAR = { "CONFIRM_RECORD_CLEAR", "CONFIRM_RECORD_CLEAR_OK",
                             function() if ns.Ledger and ns.Ledger.Clear then ns.Ledger.Clear() end state.rsel = nil; UI.Refresh() end },
  DEATHNOTE_VICTIM_STRIKE = { "CONFIRM_VICTIM_STRIKE", "CONFIRM_DELETE_OK",
                              function(_, key) if key and ns.Ledger and ns.Ledger.RemoveVictim then ns.Ledger.RemoveVictim(key) end
                                if state.rsel == key then state.rsel = nil end UI.Refresh() end },
  DEATHNOTE_TIE_LOOSE = { "CONFIRM_TIE_LOOSE", "ACT_TIE_LOOSE",
                          function(_, list) if ns.Friends and ns.Friends.Unbind then ns.Friends.Unbind(list) end UI.Refresh() end },
}
function UX.RegisterConfirms()
  for which, c in pairs(UX.CONFIRM) do
    StaticPopupDialogs[which] = {
      -- StaticPopup inserts the name via %s: {name} becomes that, every other % is doubled
      text = Fmt((L[c[1]]:gsub("%%", "%%%%")), { name = "%s" }), button1 = L[c[2]], button2 = L.CONFIRM_CANCEL,
      OnAccept = c[3],
      timeout = 0, whileDead = true, hideOnEscape = true,
    }
  end
end
local function Confirm(which, text, data) StaticPopup_Show(which, text, nil, data) end

------------------------------------------------------------------------
-- Tab data
------------------------------------------------------------------------
local function IsCase(item) return type(item) == "table" and item.status == nil and item.kind ~= nil end

-- open cases: Store.OpenCases (logic), otherwise built from the journal here
local fallbackCases = {}
local function OpenCases()
  local S = Store()
  if S.OpenCases then
    local ok, n, list = pcall(S.OpenCases)
    if ok and type(list) == "table" then return list, tonumber(n) or #list end
  end
  for i = #fallbackCases, 1, -1 do fallbackCases[i] = nil end
  for _, d in ipairs(S.Deaths() or {}) do
    if type(d) == "table" and d.kind == "pvp" and d.killerKey == nil and d.counted ~= false
       and type(d.candidates) == "table" and #d.candidates > 0 then
      fallbackCases[#fallbackCases + 1] = d
    end
  end
  return fallbackCases, #fallbackCases
end

-- time of an entry in "Unsolved": case = time of death, suspicion = latest deed
local function OpenTime(item)
  if IsCase(item) then return tonumber(item.t) or 0 end
  local d = Look.LastDeed(item)
  return d and tonumber(d.t) or 0
end
local function OpenLess(a, b)
  local ta, tb = OpenTime(a), OpenTime(b)
  if ta ~= tb then return ta > tb end
  return tostring(a.key or a.t) < tostring(b.key or b.t)
end

-- Unsolved: open cases and real suspects, newest first (reused table)
local openData = {}
function UX.OpenData()
  for i = #openData, 1, -1 do openData[i] = nil end
  local cases = OpenCases()
  for i = 1, #cases do openData[#openData + 1] = cases[i] end
  local sus = Store().Ranked("suspect", "recent") or {}
  for i = 1, #sus do openData[#openData + 1] = sus[i] end
  table.sort(openData, OpenLess)
  return openData
end

-- wanted, suspect, pardoned, open
local function Counts()
  local S = Store()
  local w, s, p, o = S.Count()
  if type(o) ~= "number" then local _, n = OpenCases(); o = n end
  return w or 0, s or 0, p or 0, o or 0
end

-- Wanted: the wanted, behind them the pardoned (can be switched off in the sort menu)
local wantedData = {}
local function ShowPardoned() return Look.Setting("ui.showPardoned", true) ~= false end
function UX.WantedData()
  local S = Store()
  -- 1.3.0 (decision 4): "Rank" sorts by the open debt while the rap sheet is on (Store.RankOrder), the same order as
  -- Store.Rank, so the numbers on the rows stay 1, 2, 3 ... and the settled ones follow without a number
  local list = S.Ranked("wanted", state.sort == "rank" and S.RankOrder and S.RankOrder() or state.sort) or {}
  for i = #wantedData, 1, -1 do wantedData[i] = nil end
  for i = 1, #list do wantedData[i] = list[i] end
  local pard = S.Ranked("pardoned", state.sort) or {}
  local all = ShowPardoned()
  for i = 1, #pard do
    if all or pard[i].key == state.selected then wantedData[#wantedData + 1] = pard[i] end
  end
  return wantedData
end

-- Guild book by killer: only entries with guildmates, pure manual entries at the end.
-- Sorted/filtered again only when the logic's list changes.
local gpart = { src = nil, n = -1, out = {}, res = nil }
local function GuildEnemies(sort)
  local src = GF.Src()
  local list = GF.SrcOn(src) and GCall("List", sort, FOREIGN[src]) or nil
  if type(list) ~= "table" then return {} end
  if gpart.src == list and gpart.n == #list then return gpart.res end
  gpart.src, gpart.n = list, #list
  -- if the logic provides the fourth counter (foreign), it filters itself; otherwise filter here
  local _, _, _, foreign = GCall("Count", src)
  local trusted = type(foreign) == "number"
  local need, seen = false, false
  for i = 1, #list do
    local g = list[i]
    if not trusted and not Look.Foreign(g) then need = true; break end
    if Look.ListedOnly(g) then seen = true elseif seen then need = true; break end
  end
  if not need then gpart.res = list; return list end
  local out = gpart.out
  for i = #out, 1, -1 do out[i] = nil end
  for i = 1, #list do if (trusted or Look.Foreign(list[i])) and not Look.ListedOnly(list[i]) then out[#out + 1] = list[i] end end
  for i = 1, #list do if (trusted or Look.Foreign(list[i])) and Look.ListedOnly(list[i]) then out[#out + 1] = list[i] end end
  gpart.res = out
  return out
end

function UX.GuildCount()
  local src = GF.Src()
  if src ~= "guild" and not GF.SrcOn(src) then return 0 end
  local enemies, _, _, foreign = GCall("Count", src)
  if type(foreign) == "number" then return foreign end
  if not GCall("Name") then return 0 end
  return #GuildEnemies("rank")
end

-- Guildmates (1.2.0: and friends) with DeathNote, depending on the source
local function MemberCount()
  local src = GF.Src()
  local n = 0
  if src ~= "friends" then
    local m = GCall("Members")
    n = n + (type(m) == "table" and #m or 0)
  end
  if src ~= "guild" and GF.HasFriends() then
    local m = GCall("Members", "friends")
    n = n + (type(m) == "table" and #m or 0)
  end
  return n
end

-- Hit list of the chosen source (rows of the logic, do not modify)
-- 1.2.0: what the fourth tab should show, once per rebuild: both sources (guild and a friend with
-- DeathNote), nobody to share with (no guild, no friend on the list), hit list worthwhile (there are
-- calls, or one is being created right now)
function GF.Survey()
  local g = GCall("Name") ~= nil and GCall("Enabled") ~= false
  local fOn = GF.FriendsOn()
  local fm = fOn and GCall("Members", "friends")
  local fN = type(fm) == "table" and #fm or 0
  local total = 0
  if fOn and type(ns.Friends.OnlineCount) == "function" then
    local ok, _, t = pcall(ns.Friends.OnlineCount)
    total = ok and tonumber(t) or 0
  end
  GF.both = GF.HasFriends() and GCall("Name") ~= nil and fN > 0
  -- "nobody" only without targets on the hit list: calls (own ones too) keep views, status line and
  -- sync reachable, even with both share switches off (alarm and display follow the same state)
  local hunts = (tonumber((GCall("HuntCount", "all"))) or 0) > 0 or (tonumber((GCall("OwnReleaseCount"))) or 0) > 0
  GF.nobody = not g and (not fOn or (total == 0 and fN == 0)) and not hunts
  GF.hunts = GF.HasHunts() and ((tonumber(GCall("HuntCount", "all")) or 0) > 0 or state.panel == "release")
  if state.gview == "hunt" and not GF.hunts then state.gview = "enemy" end
end

function GF.Hunts()
  if not GF.HasHunts() then return {} end
  local rows = GCall("Hunts", GF.Src())
  return type(rows) == "table" and rows or {}
end

------------------------------------------------------------------------
-- Actions per entry (poster buttons and right-click menu)
------------------------------------------------------------------------
-- Poster: two buttons; strike out is only in the menu and as a small word at the bottom of the poster
local function EnemySpec(e)
  local key = e.key
  local S = Store()
  if e.status == "suspect" then
    return {
      { L.ACT_CONFIRM, function() S.ConfirmSuspect(key) end },
      { L.ACT_DISMISS, function() S.DismissSuspect(key) end },
    }
  elseif e.status == "pardoned" then
    return {
      { L.ACT_HUNT_AGAIN, function() S.SetStatus(key, "wanted") end },
      GF.RevengeAct(key),
    }
  end
  return {
    GF.RevengeAct(key),
    { L.ACT_PARDON, function() S.SetStatus(key, "pardoned") end },
  }
end

-- 1.2.1: "Note revenge"; right after it "Undo" on the same button for a few seconds (one timer, no ticker)
function GF.RevengeAct(key)
  local u = GF.undo
  if u and u.key == key then return { L.ACT_UNDO, GF.UndoRevenge } end
  return { L.ACT_REVENGE, function() GF.NoteRevenge(key) end }
end
function GF.NoteRevenge(key)
  local S = Store()
  local e = S.Get(key)
  if not e then return end
  -- 1.2.1 fix: a second click on the same revenge (double click, twice in the same frame) does not count again
  if GF.undo and GF.undo.key == key then return end
  local prev = e.lastRevenge
  local u = { key = key, prev = prev, at = GetTime() }
  GF.undo = u
  if not S.AddRevenge(key, true) then GF.undo = nil; return end
  C_Timer.After(GF.UNDO_SECONDS, function()
    if GF.undo == u then GF.undo = nil; UI.Refresh() end
  end)
end
function GF.UndoRevenge()
  local u = GF.undo
  -- 1.2.1 fix: "Undo" only accepts after a short lock (otherwise the second click of a double click hits it)
  if u and u.at and GetTime() - u.at < GF.UNDO_LOCK then return end
  GF.undo = nil
  local S = Store()
  if u and S.UndoRevenge then S.UndoRevenge(u.key, u.prev) end
  UI.Refresh()
end

local function MenuSpec(e)
  local spec = EnemySpec(e)
  local out = { spec[1], spec[2], { L.ACT_STRIKE, function() UI.ConfirmDelete(e.key) end } }
  -- 1.2.1: take back a revenge noted by hand (the one the book detected stays)
  local S = Store()
  local u = GF.undo
  if S.HandRevenge and (tonumber(S.HandRevenge(e)) or 0) > 0 and not (u and u.key == e.key) then
    out[#out + 1] = { L.ACT_REVENGE_TAKE, function() S.UndoRevenge(e.key); UI.Refresh() end }
  end
  return out
end

-- Guild: nothing destructive, only take over or open the own poster
local function GuildSpec(g)
  local key = g.key
  if Store().Get(key) then
    return { { L.ACT_OPEN_OWN, function() UI.ShowEnemy(key) end } }
  end
  return { { L.ACT_ADOPT, function()
    local k = GCall("Adopt", key)
    UI.Refresh()
    if type(k) == "string" and Store().Get(k) then UI.ShowEnemy(k) end
  end } }
end

-- Hit list (1.2.0): take back an own call or post one ("Put on hit list" opens
-- the sheet with target and reason); "call off" only takes back the own call.
function GF.Released(key)
  local g, f = GCall("Released", key)
  return (g or f) and true or false
end
function GF.HuntAction(key)
  if GF.Released(key) then
    return { L.ACT_CALLOFF, function() GCall("CallOff", key); UI.Refresh() end }
  end
  return { L.ACT_RELEASE, function() UI.OpenRelease(key) end }
end
function GF.MenuWithHunt(spec, key)
  if not GF.HasHunts() or type(key) ~= "string" then return spec end
  local out = {}
  for i = 1, #spec do out[i] = spec[i] end
  out[#out + 1] = GF.HuntAction(key)
  return out
end

------------------------------------------------------------------------
-- Menu (right click and sorting): one column of black buttons at the mouse
------------------------------------------------------------------------
local function HideMenu() if menu then menu:Hide(); menu.blocker:Hide() end end

function UX.BuildMenu()
  menu = CreateFrame("Frame", "DeathNoteMenu", F, "BackdropTemplate")
  menu:SetFrameStrata("DIALOG")
  menu:SetBackdrop({ bgFile = Look.TEX.white, edgeFile = Look.TEX.white, edgeSize = 1 })
  menu:SetBackdropColor(C(Look.COLOR.menuFill))
  menu:SetBackdropBorderColor(C(Look.COLOR.btnEdge))
  menu:Hide()
  -- a click anywhere else in the book closes the menu
  local bl = CreateFrame("Button", nil, F)
  bl:SetAllPoints(F)
  bl:SetFrameStrata("DIALOG")
  bl:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  bl:SetScript("OnClick", HideMenu)
  bl:Hide()
  menu.blocker = bl
  menu.items = {}
  for i = 1, GF.MENU_MAX do
    local b = InkButton(menu, "", 148, 20)
    b:SetPoint("TOPLEFT", 4, -4 - (i - 1) * 22)
    menu.items[i] = b
  end
  menu:SetScript("OnShow", function(self) self:Raise() end)
end

-- 1.2.2: width from the longest entry (148 to 252 px, beyond that 9 pt), clamped to the screen and opened
-- away from the mouse (right of the middle to the left, in the lower half upwards)
GF.MENU_W0, GF.MENU_W1 = 148, 252
local function OpenMenu(spec, fallbackAnchor)
  if not menu then UX.BuildMenu() end
  local n = math.min(#spec, GF.MENU_MAX)
  local need = GF.MENU_W0
  for i = 1, n do
    local t = menu.items[i].text
    need = math.max(need, math.ceil((GF.MeasureAt(t, spec[i][1], 10) or 0) + 16))   -- SetLabel fits it below
  end
  local bw = math.min(GF.MENU_W1, need)
  for i = 1, GF.MENU_MAX do
    local b, s = menu.items[i], spec[i]
    if s and i <= n then
      local fn = s[2]
      b:SetWidth(bw); b.text:SetWidth(bw - 8)
      b:SetLabel(s[1]); b.fn = function() HideMenu(); fn() end; b:Show()
    else
      b:Hide()
    end
  end
  menu:SetSize(bw + 8, 8 + n * 22 - 2)
  menu:ClearAllPoints()
  local s = menu:GetEffectiveScale()
  local x, y = GetCursorPosition()
  if type(x) == "number" and type(y) == "number" and type(s) == "number" and s > 0
     and not Look.Secret(x) and not Look.Secret(y) and not Look.Secret(s) then
    Look.KeepOnScreen(menu, x / s + 2, y / s - 2)
  else
    menu:SetClampedToScreen(true)
    menu:SetPoint("TOPLEFT", fallbackAnchor, "RIGHT", -40, 0)
  end
  menu.blocker:Show()
  menu:Show()
end

-- 1.2.0: head row of a friend without surname on the list (By guildmate): who it is, release the link
function GF.TieMenu(row)
  local t = row.item.m and row.item.m.tie
  if type(t) ~= "table" or not ns.Friends then return false end
  local spec = {}
  if t.conflict then
    for _, n in ipairs({ t.full, t.rival }) do
      spec[#spec + 1] = { Fmt(L.ACT_TIE_MINE, { name = n }), function() ns.Friends.Choose(t.list, n); UI.Refresh() end }
    end
  end
  spec[#spec + 1] = { L.ACT_TIE_LOOSE, function() Confirm("DEATHNOTE_TIE_LOOSE", t.full, t.list) end }
  OpenMenu(spec, row)
  return true
end

------------------------------------------------------------------------
-- Rows of the left page
------------------------------------------------------------------------
local Refresh, BindRows, ShowRight -- forward declaration
local ClassName -- forward declaration (class name in the book's wording)
local ToggleMember -- forward declaration

-- guild entry behind a row (child row by guildmate or row by killer)
local function GuildItem(item)
  if item.wrap then
    if item.head then return nil end
    return item.r.entry or GCall("Get", item.r.key)
  end
  return item
end

local function SelectRow(row)
  if not row.item then return end
  if row.item.wrap then
    if row.item.head then return end               -- a head row is not a killer
    state.gselected, state.gmember = row.item.r.key, row.item.m.name
  elseif state.filter == "journal" then
    state.death, state.deathRef = row.index, row.item
  elseif state.filter == "record" then
    -- a click on the selected victim goes back to the own file
    state.rsel = (state.rsel ~= row.item.key) and row.item.key or nil
  elseif state.filter == "open" then
    state.osel = IsCase(row.item) and row.item or row.item.key
  elseif state.filter == "guild" then
    if GF.HuntView() then state.hselected = row.item.key else state.gselected = row.item.key end
  else
    state.selected = row.item.key
  end
  if state.panel then UI.ClosePanel(true) end
  BindRows()
  ShowRight()
end

function UX.RowMenu(row, anchor)
  local item = row.item
  if not item or state.filter == "journal" or state.filter == "record" or IsCase(item) then return end
  if item.wrap then
    item = GuildItem(item)
    if not item then return end
  end
  local spec
  if GF.HuntView() then
    spec = GF.HuntSpec(item)
    -- call off all own calls (with confirmation). 1.2.0: in the row menu of an own call when there is
    -- more than one (the sort button it hung on is not visible in the hit list)
    if GF.Released(item.key) and (tonumber(GCall("OwnReleaseCount")) or 0) > 1 then
      spec[#spec + 1] = { L.ACT_CALLOFF_ALL, function() Confirm("DEATHNOTE_CALLOFF_ALL") end }
    end
  elseif state.filter == "guild" then spec = GF.MenuWithHunt(GuildSpec(item), item.key)
  elseif item.status == "wanted" then spec = GF.MenuWithHunt(MenuSpec(item), item.key)
  else spec = MenuSpec(item) end
  -- 1.2.1: post a bounty (own wanted and suspects, guild, friends, hit list; the same rule as on the poster)
  if GF.MayBounty(item) then
    spec[#spec + 1] = { L.ACT_BOUNTY, function() GF.EditBounty(item.key) end }
  end
  OpenMenu(spec, anchor or row)
end

local function RowClick(row, mouse)
  if not row.item then return end
  if row.item.wrap and row.item.head then
    if mouse == "RightButton" and GF.TieMenu(row) then return end
    ToggleMember(row.item.m)
    return
  end
  if mouse == "RightButton" then
    SelectRow(row)
    UX.RowMenu(row)
    return
  end
  if UX.Shift() and state.filter ~= "journal" and not IsCase(row.item)
     and UX.InsertIntoChat(Look.TargetName(GuildItem(row.item) or row.item)) then return end
  SelectRow(row)
end

local function RowEnter(row)
  if not row.item then return end
  if row.tipFn then
    Tip(row, row.tipFn(row.item))
  elseif row.full then
    Tip(row, type(row.full) == "table" and row.full or { row.full })
  elseif Truncated(row.name) or row.subFull then
    -- 1.2.2: truncated name or subtext: both in full
    Tip(row, { row.name:GetText() or "", row.subFull })
  end
end

function UX.MakeRow(parent, i)
  local r = CreateFrame("Button", nil, parent)
  r:SetSize(PAGE_W - 24, ROW_H - 2)
  r:SetPoint("TOPLEFT", 4, ROW_TOP - (i - 1) * ROW_H)
  r:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  local hl = r:CreateTexture(nil, "HIGHLIGHT")
  hl:SetAllPoints()
  hl:SetColorTexture(C(Look.INK, 0.06))

  -- rank and name stand on the first line, the subtext on the second
  r.rank = Look.Text(r, "hand", 19, Look.INK)
  r.rank:SetPoint("TOPRIGHT", r, "TOPLEFT", 32, -1)
  r.rank:SetJustifyH("RIGHT")
  r.rank:SetWidth(32)          -- 1.2.2: "128." gets smaller instead of sticking out of the row on the left
  r.skull = r:CreateTexture(nil, "ARTWORK")
  r.skull:SetSize(18, 18)
  r.skull:SetPoint("TOPLEFT", 12, -2)
  Look.Skin(r.skull, "skull")
  r.skull:SetVertexColor(C(Look.COLOR.skullTint))
  r.skull:Hide()

  r.name = Look.Text(r, "hand", 19, Look.INK)
  r.name:SetPoint("TOPLEFT", 40, -1)
  r.name:SetPoint("RIGHT", -40, 0)
  r.name:SetJustifyH("LEFT")
  r.name:SetWordWrap(false)

  r.subX, r.subInset = 42, 12
  r.sub = Look.Text(r, "body", 10, Look.INK)
  r.sub:SetPoint("BOTTOMLEFT", 42, -1)
  r.sub:SetPoint("RIGHT", -12, 0)
  r.sub:SetJustifyH("LEFT")
  r.sub:SetWordWrap(false)
  Look.TipShows(r, r.name)   -- RowEnter shows a cut name and sub line whole
  Look.TipShows(r, r.sub)

  r.mark = Look.Text(r, "body", 10, Look.RED_INK)
  r.mark:SetPoint("BOTTOMRIGHT", -6, -1)

  r.icon = r:CreateTexture(nil, "ARTWORK")
  r.icon:SetSize(16, 16)
  r.icon:SetPoint("TOPRIGHT", -8, -3)
  MugIcon(r.icon)
  -- 1.2.1: small coin left of the class icon when a bounty is posted on the killer (quiet, desaturated)
  r.coin = r:CreateTexture(nil, "ARTWORK")
  r.coin:SetSize(11, 11)
  r.coin:SetPoint("TOPRIGHT", -28, -6)
  r.coin:SetTexture(Look.TEX.coin)
  r.coin:SetDesaturated(true)
  r.coin:SetVertexColor(C(Look.COLOR.coinTint))
  r.coin:Hide()

  -- underlined = selected, struck through = pardoned
  r.under = r:CreateTexture(nil, "OVERLAY")
  r.under:SetHeight(8)
  r.under:SetPoint("TOPLEFT", r.name, "BOTTOMLEFT", -4, 4)
  Look.Skin(r.under, "ink")
  r.under:SetVertexColor(C(Look.INK, 0.95))
  r.under:Hide()
  r.strike = r:CreateTexture(nil, "OVERLAY", nil, 1)
  r.strike:SetHeight(9)
  r.strike:SetPoint("LEFT", r.name, "LEFT", -3, -1)
  Look.Skin(r.strike, "ink")
  r.strike:SetVertexColor(C(Look.INK, 0.8))
  r.strike:SetTexCoord(1, 0, 0, 1)
  r.strike:Hide()

  -- guild by guildmate: head row with triangle, pale band and counter at the top right
  r.band = r:CreateTexture(nil, "BACKGROUND")
  r.band:SetPoint("TOPLEFT", 0, 1); r.band:SetPoint("BOTTOMRIGHT", 0, -1)
  r.band:SetColorTexture(C(Look.INK, 0.07))
  r.band:Hide()
  r.rule = r:CreateTexture(nil, "ARTWORK")
  r.rule:SetHeight(1)
  r.rule:SetPoint("BOTTOMLEFT", 6, -1); r.rule:SetPoint("BOTTOMRIGHT", -6, -1)
  r.rule:SetColorTexture(C(Look.INK, 0.5))
  r.rule:Hide()
  r.tri = Tri(r, 14, 0)
  r.tri:SetPoint("TOPLEFT", 18, -5)
  r.tri:Hide()
  r.right = Look.Text(r, "body", 10, Look.INK)
  r.right:SetPoint("TOPRIGHT", -8, -6)
  r.right:SetJustifyH("RIGHT")
  r.right:SetTextColor(C(Look.INK, TONE.sub))
  r.right:Hide()
  r.mode = "normal"

  r:SetScript("OnClick", RowClick)
  r:SetScript("OnEnter", RowEnter)
  r:SetScript("OnLeave", GameTooltip_Hide)
  r:Hide()
  return r
end

-- switch the row kind (only on change: set anchors and font anew)
local function SetRowMode(r, mode)
  if r.mode == mode then return end
  r.mode = mode
  r.nameInset = nil
  local head, child = mode == "head", mode == "child"
  r.band:SetShown(head); r.rule:SetShown(head); r.tri:SetShown(head); r.right:SetShown(head)
  Look.Font(r.name, "hand", head and 22 or 19)
  r.name:ClearAllPoints()
  r.name:SetPoint("TOPLEFT", child and 58 or 40, head and -2 or -1)
  r.name:SetPoint("RIGHT", head and -112 or -40, 0)
  r.subX = child and 60 or 42
  r.subInset = nil
  if head then r.icon:Hide(); r.strike:Hide(); r.skull:Hide(); Look.FitText(r.rank, "", GF.FIT_RANK); r.coin:Hide() end
end

-- tones of a row: normal, red (rank 1, killer unknown), pale (pardoned, manual only, does not count)
local ROW_TONE = {
  normal = { Look.INK, TONE.ink },
  red    = { Look.RED, TONE.ink },
  pale   = { Look.INK, TONE.hand },
}

-- Fill one row: name, subtext, mark at the bottom right (red or ink), tone.
-- The subtext reaches up to the mark, without a mark almost to the edge.
local function SetRow(r, name, sub, mark, tone, markInk)
  local t = ROW_TONE[tone] or ROW_TONE.normal
  r.name:SetText(name or "")
  r.name:SetTextColor(C(t[1], t[2]))
  -- 1.2.2: sub may be a list (full, then shorter): the first that fits whole; when truncated it is in the tooltip
  local full = type(sub) == "table" and sub[1] or sub
  r.sub:SetText(full or "")
  r.sub:SetTextColor(C(Look.INK, TONE.sub))
  r.mark:SetText(mark or "")
  if markInk then r.mark:SetTextColor(C(Look.INK, TONE.sub)) else r.mark:SetTextColor(C(Look.RED_INK)) end
  local inset = 12
  if mark and mark ~= "" then inset = math.floor(math.max(70, TextWidth(r.mark, 58) + 14)) end
  if r.subInset ~= inset then
    r.subInset = inset
    r.sub:ClearAllPoints()
    r.sub:SetPoint("BOTTOMLEFT", r.subX or 42, -1)
    r.sub:SetPoint("RIGHT", -inset, 0)
  end
  if type(sub) == "table" then
    for i = 2, #sub do
      if not Truncated(r.sub) then break end
      r.sub:SetText(sub[i])
    end
  end
  r.subFull = (full and (Truncated(r.sub) or r.sub:GetText() ~= full)) and full or nil
  r.full, r.tipFn = nil, nil
end

GF.FIT_RANK = { sizes = { 19, 16, 13 } }
local function SetRank(r, rank, text)
  Look.FitText(r.rank, text or (rank and (rank .. ".")) or "", GF.FIT_RANK)
  r.rank:SetTextColor(C(rank == 1 and Look.RED or Look.INK))
end

function UX.Seen(e)
  local ls = e.lastSeen
  local ago = type(ls) == "table" and Look.Ago(ls.t)
  return ago and Fmt(L.ROW_SEEN, { time = ago }) or L.ROW_NOT_SEEN
end

-- place and time of the latest deed
local function DeedWhere(d)
  if not d then return nil end
  return Look.Join(Look.When(d.t), Look.Place(d.zone, d.subzone))
end

function UX.BindEnemyRow(r, e)
  SetRowMode(r, "normal")
  local rank = (e.status == "wanted") and Store().Rank(e.key) or nil
  local pardoned, suspect = e.status == "pardoned", e.status == "suspect"
  r.skull:Hide()
  SetRank(r, rank, suspect and "?" or nil)
  -- 1.3.0: the standing "me : him" replaces "REVENGE n×" at the right (from my first kill on); a settled one
  -- (even, ahead) says so first in its sub line, has no rank and is drawn pale
  local m, h, score = Look.Stand(e)
  local settled = m and m > 0 and not pardoned and not suspect and Look.ScoreState(m, h) ~= "open" and Look.ScoreState(m, h)
  local sub
  if pardoned then sub = Look.Join(L.ROW_PARDONED, Look.Tally(e))
  elseif suspect then sub = Look.Join(L.ROW_SUSPECT, DeedWhere(Look.LastDeed(e)))
  else
    -- "seen … ago" goes first when the row does not fit
    local tally = Look.Tally(e)
    local word = settled and L[Look.STATE_WORD[settled]] or nil
    sub = { Look.Join(word, tally, UX.Seen(e)), Look.Join(word, tally) }
  end
  local mark
  if m then
    mark = m > 0 and score or nil
  else
    local rv = tonumber(e.revenge) or 0
    mark = rv > 0 and Fmt(L.MARK_REVENGE, { times = Look.Times(rv) }) or nil
  end
  SetRow(r, Look.Name(e), sub, mark, (rank == 1 and "red") or ((pardoned or settled) and "pale") or "normal", settled and true or false)
  if mark and m then
    -- the row's tooltip says what the numbers mean ("you 1, them 2"), with name and sub line whole (one table per row)
    local t = r.standTip or {}
    r.standTip = t
    t[1], t[2], t[3] = Look.Name(e), type(sub) == "table" and sub[1] or sub, Fmt(L.STAND_TIP, { mine = m, his = h })
    r.full = t
  end
  Look.ClassIcon(r.icon, e.class)
  r.icon:Show()
  GF.Coin(r, e.key)
  r.under:SetShown((state.filter == "open" and state.osel or state.selected) == e.key)
  r.under:SetWidth(InkWidth(r.name))
  -- struck through only when pardoned; revenge stands on the right as a note
  r.strike:SetShown(pardoned)
  r.strike:SetWidth(InkWidth(r.name))
end

-- case without a killer (Unsolved): red, with the number of candidates
function UX.BindCaseRow(r, d)
  SetRowMode(r, "normal")
  SetRank(r, nil)
  r.skull:Show()
  r.icon:Hide(); r.coin:Hide()
  r.strike:Hide()
  local n = type(d.candidates) == "table" and #d.candidates or 0
  SetRow(r, L.ROW_KILLER_UNCLEAR, DeedWhere(d), n > 0 and Look.Count(n, L.MARK_CANDIDATES) or nil, "red")
  r.under:SetShown(state.osel == d)
  r.under:SetWidth(InkWidth(r.name))
end

function UX.BindDeathRow(r, d, index)
  SetRowMode(r, "normal")
  SetRank(r, nil)
  r.skull:Show()
  r.icon:Hide(); r.coin:Hide()
  r.strike:Hide()
  local name, mark, tone, markInk = nil, nil, "normal", false
  if d.kind == "pvp" and d.killerKey then
    name = (NameOfKey(d.killerKey, d.killerName))
    if d.sure == false then mark = L.MARK_SUSPECT end
  elseif d.kind == "pvp" then
    local n = type(d.candidates) == "table" and #d.candidates or 0
    name, tone = L.ROW_KILLER_UNCLEAR, "red"
    if n > 0 then mark = Look.Count(n, L.MARK_CANDIDATES) end
  else
    name, tone = (d.kind == "pve" and L.ROW_NO_PLAYER or L.ROW_UNCLEAR), "pale"
  end
  if d.counted == false then tone, mark, markInk = "pale", L.MARK_NOT_COUNTED, true end
  SetRow(r, name, DeedWhere(d), mark, tone, markInk)
  r.under:SetShown(state.death == index)
  r.under:SetWidth(InkWidth(r.name))
end

local listedNames = {}   -- work table for listedBy names

function UX.BindGuildRow(r, g, pos)
  SetRowMode(r, "normal")
  local only = Look.ListedOnly(g)
  local rank = not only and (GCall("Rank", g.key, GF.Src()) or (state.gsort == "rank" and pos)) or nil   -- 1.2.0: rank in the chosen source
  r.skull:Hide()
  r.strike:Hide()
  SetRank(r, rank)
  Look.ClassIcon(r.icon, g.class)
  r.icon:Show()
  local sub
  if only then
    local names = Look.ListedNames(g, listedNames)
    sub = #names > 0 and Fmt(L.ROW_LISTED_BY, { names = Look.NameList(names, 2) }) or L.TALLY_MANUAL
  else
    -- 1.2.1: how often guildmates or friends took him down for others (total)
    local av = tonumber(GCall("AvengedTotal", g.key)) or 0
    -- 1.2.2: if the row does not fit, the last victim goes first, then "avenged" (in full in the row's tooltip)
    local killed, victims = Fmt(L.ROW_GKILLED, { kills = Look.GKills(g.kills) }), Look.Count(g.victimCount, L.ROW_VICTIMS)
    local avt = av > 0 and Fmt(L.ROW_AVENGED, { times = Look.Times(av) })
    sub = { Look.Join(killed, victims, avt,
                      type(g.lastVictim) == "string" and g.lastVictim ~= "" and Fmt(L.ROW_LAST, { text = Look.First(g.lastVictim) })),
            Look.Join(killed, victims, avt), Look.Join(killed, victims) }
  end
  -- small sign: already in the own book
  local mine = g.mine or Store().Get(g.key)
  SetRow(r, Look.Name(g), sub, mine and L.MARK_IN_BOOK or nil, (rank == 1 and "red") or (only and "pale") or "normal", true)
  GF.Coin(r, g.key)
  r.under:SetShown(state.gselected == g.key)
  r.under:SetWidth(InkWidth(r.name))
end

------------------------------------------------------------------------
-- Guild by guildmate: a flat list of head and child rows in the same row pool
------------------------------------------------------------------------
function UX.BindMemberHead(r, w)
  SetRowMode(r, "head")
  local m = w.m
  local killers, listed = tonumber(m.killers) or 0, tonumber(m.listed) or 0
  if killers > 0 then
    r.right:SetText(Look.Join(Look.Count(killers, L.MEMBER_KILLERS), Look.Count(m.deaths, L.MEMBER_DEATHS)))
  elseif listed > 0 then
    r.right:SetText(Fmt(L.MEMBER_LISTED, { count = listed }))
  else
    r.right:SetText("")
  end
  -- the name may reach up to the counter
  local inset = math.floor(math.max(48, TextWidth(r.right, 96) + 18))
  if r.nameInset ~= inset then
    r.nameInset = inset
    r.name:ClearAllPoints()
    r.name:SetPoint("TOPLEFT", 40, -2)
    r.name:SetPoint("RIGHT", -inset, 0)
  end
  local empty = type(m.rows) ~= "table" or #m.rows == 0
  local sub
  if m.me then sub = L.MEMBER_ME
  elseif m.tie and m.tie.conflict then sub = L.MEMBER_CONFLICT
  elseif empty then sub = L.MEMBER_NOTHING
  else local last = m.lastDeath and Look.Ago(m.lastDeath); sub = last and Fmt(L.MEMBER_LAST_DIED, { time = last }) or "" end
  -- 1.2.0: show whether it is a friend (only in "All")
  local srcMark = not m.me and GF.SrcMark(m.src) or nil
  SetRow(r, Look.First(m.name), sub, m.me and L.MARK_YOU or srcMark, "normal", srcMark ~= nil)
  if Look.First(m.name) ~= tostring(m.name) then r.full = tostring(m.name) end
  r.tri:SetShown(not empty)
  -- closed: tip to the right, open: downwards
  r.tri:SetRotation(w.open and -1.5708 or 0)
  r.under:Hide()
end

function UX.BindMemberChild(r, w)
  SetRowMode(r, "child")
  local row = w.r
  local e = row.entry
  SetRank(r, nil)
  r.skull:Hide(); r.strike:Hide()
  Look.ClassIcon(r.icon, e and e.class)
  r.icon:Show()
  local kills = tonumber(row.kills) or 0
  local sub, tone
  if kills > 0 then
    local ago = row.lastKill and Look.Ago(row.lastKill)
    local last = ago and Fmt(L.ROW_LAST, { text = ago })
    if last and type(row.lastZone) == "string" and row.lastZone ~= "" then
      last = Fmt(L.ALERT_LINE_IN, { text = last, zone = row.lastZone })
    end
    sub, tone = Look.Join(Fmt(L.ROW_GKILLED, { kills = Look.GKills(kills) }), last), "normal"
  else
    sub, tone = Look.Join(L.TALLY_MANUAL, row.listedAt and Look.Ago(row.listedAt)), "pale"
  end
  SetRow(r, e and Look.Name(e) or tostring(row.key or "?"), sub, Store().Get(row.key) and L.MARK_IN_BOOK or nil, tone, true)
  GF.Coin(r, row.key)
  r.under:SetShown(state.gselected == row.key and (state.gmember == nil or state.gmember == w.m.name))
  r.under:SetWidth(InkWidth(r.name))
end

-- Hit list (1.2.0): name with class icon, below it who posted the call and since when;
-- on the right the taken-down counter or the number of calls
function GF.SrcMark(src)
  -- 1.2.0: only in "All", and only for a friend (a guildmate is the normal case and gets no sign)
  if GF.Src() ~= "all" then return nil end
  if src == "friends" then return L.MARK_FRIEND end
  if src == "both" then return L.MARK_BOTH end
  return nil
end

-- tooltip of a hit list row: everything, including the long reason and all names
function GF.HuntTip(h)
  local names = type(h.names) == "table" and h.names or {}
  local n = tonumber(h.n) or #names
  local lvl = type(h.level) == "number" and Fmt(L.POSTER_LEVEL, { level = h.level }) or nil
  local tip = { Look.Name(h) }
  local who = Look.Join(lvl, ClassName(h))
  if who ~= "" then tip[#tip + 1] = who end
  if n > 0 then tip[#tip + 1] = Fmt(L.HUNT_ROW_CALLS, { count = n, names = table.concat(names, ", ") }) end
  if type(h.why) == "string" and h.why ~= "" then tip[#tip + 1] = Fmt(L.HUNT_REASON, { reason = h.why }) end
  -- 1.2.2: with the age the row shows ("1 day ago"), so a cut row line is whole in its tooltip
  if type(h.since) == "number" then tip[#tip + 1] = Look.Join(Fmt(L.TIP_RELEASED_AT, { time = Look.When(h.since) }), Look.Ago(h.since)) end
  local ls = type(h.lastSeen) == "table" and h.lastSeen or nil
  local seen = ls and Look.Ago(ls.t)
  tip[#tip + 1] = seen and Fmt(L.ROW_SEEN, { time = seen }) or L.ROW_NOT_SEEN
  local bag = tonumber(h.bagged) or 0
  if bag > 0 then tip[#tip + 1] = Fmt(L.MARK_TAKEN_DOWN, { times = Look.Times(bag) }) end
  if h.hidden then tip[#tip + 1] = L.HUNT_ROW_HIDDEN end
  return tip
end

function GF.BindHuntRow(r, h)
  SetRowMode(r, "normal")
  SetRank(r, nil)
  r.skull:Hide()
  r.strike:Hide()
  Look.ClassIcon(r.icon, h.class)
  r.icon:Show()
  -- 1.2.0: second line with three facts: who posted the call (hidden: that), the reason truncated,
  -- last seen or since when; on the right the taken-down counter. Level and everything else: poster and tooltip.
  local names = type(h.names) == "table" and h.names or {}
  local ls = type(h.lastSeen) == "table" and h.lastSeen or nil
  local seen = ls and Look.Ago(ls.t)
  local why = type(h.why) == "string" and h.why ~= "" and h.why or nil
  if why then
    -- count characters, not bytes (Cyrillic and CJK would be much shorter otherwise); always cut at a character boundary
    local n, cut = 0, nil
    for pos in why:gmatch("()[^\128-\191]") do
      n = n + 1
      if n == GF.WHY_ROW + 1 then cut = pos; break end
    end
    if cut then why = why:sub(1, cut - 1) .. "…" end
  end
  local who = h.hidden and L.HUNT_ROW_HIDDEN or (#names > 0 and Look.NameList(names, 2)) or nil
  local sinceT = type(h.since) == "number" and Look.Ago(h.since) or nil
  local sub = Look.Join(who, why, seen and Fmt(L.ROW_SEEN, { time = seen }) or sinceT)
  local bag = tonumber(h.bagged) or 0
  local mark = bag > 0 and Fmt(L.MARK_TAKEN_DOWN, { times = Look.Times(bag) }) or nil
  SetRow(r, Look.Name(h), sub, mark, h.hidden and "pale" or "normal", false)
  GF.Coin(r, h.key)
  r.tipFn = GF.HuntTip          -- build the tooltip only when shown (rebuilds stay cheap)
  r.under:SetShown(state.hselected == h.key)
  r.under:SetWidth(InkWidth(r.name))
end

BindRows = function()
  local n = #data
  local maxOff = math.max(0, n - ROWS)
  if state.offset > maxOff then state.offset = maxOff end
  for i = 1, ROWS do
    local r = rows[i]
    local idx = state.offset + i
    local item = data[idx]
    r.item, r.index = item, (dataIdx and dataIdx[idx]) or idx
    if item then
      if state.filter == "journal" then UX.BindDeathRow(r, item, r.index)
      elseif state.filter == "record" then RS.BindRow(r, item)
      elseif item.wrap then
        if item.head then UX.BindMemberHead(r, item) else UX.BindMemberChild(r, item) end
      elseif state.filter == "guild" then
        if GF.HuntView() then GF.BindHuntRow(r, item) else UX.BindGuildRow(r, item, idx) end
      elseif IsCase(item) then UX.BindCaseRow(r, item)
      else UX.BindEnemyRow(r, item) end
      r:Show()
    else
      r:Hide()
    end
  end
  LP.scroll:SetMinMaxValues(0, maxOff)
  LP.scroll:SetValue(state.offset)
  LP.scroll:SetShown(maxOff > 0)
end

------------------------------------------------------------------------
-- Right page: poster, death file, empty state
------------------------------------------------------------------------
-- build the tooltip content only when shown (not on every rebuild of the list)
local function DeedEnter(self)
  if self.tipItem and self.tipFn then Tip(self, self.tipFn(self.tipItem)) end
end

local function CandEnter(self)
  if self.tip then Tip(self, self.tip) end
end
local function CandLeave(self)
  if self.tip then GameTooltip:Hide() end
end

-- Stamps (1.2.0): German shows the images with burnt-in text (as 1.1.0); every other language the
-- textless frame (same angle, colour, wear) with the text from the locale table on top.
-- per stamp: key, angle from make_media.sh (degrees, ImageMagick clockwise), ink
GF.STAMPS = { nr1 = { "STAMP_NR1", -11, 1 }, guild = { "STAMP_GUILD_NR1", -9, 1 }, rache = { "STAMP_REVENGE", 9, 1 },
              pardon = { "STAMP_PARDONED", -6, 2 }, suspect = { "STAMP_SUSPECT", 7, 3 }, hunt = { "STAMP_HUNT", 8, 1 },
              -- 1.3.0: the standing's second stamp; no picture of their own: the frame of "rache" (4th field) with the
              -- word in every language, German too
              quitt = { "STAMP_QUITT", 9, 2, "rache" }, overpaid = { "STAMP_OVERPAID", 9, 1, "rache" } }
GF.STAMP_INK = Look.STAMP_INK   -- 1.3.0: the theme's stamp inks (red, dark, darker), filled in place
GF.STAMP_TEXT_W = 104       -- inner frame of the stamp at 140x70 px
GF.FIT_STAMP = { sizes = { 16, 13, 11, 9 }, lines = 2, wrapFirst = 2 }

function GF.StampLabel(layer, tex)
  local fs = Look.Text(layer, "title", 16, GF.STAMP_INK[1])
  -- (own layer above the photo; the frame is empty inside, the text stays visible)
  fs:SetPoint("CENTER", tex, "CENTER", 0, 0)
  fs:SetWidth(GF.STAMP_TEXT_W)
  fs:SetJustifyH("CENTER")
  fs:SetMaxLines(2)
  fs.on = false
  fs:Hide()
  tex.label = fs
end

-- set the stamp image; id = name in Look.TEX (nr1, guild, rache, pardon, suspect, hunt)
function GF.Stamp(tex, id)
  local s, fs = GF.STAMPS[id], tex.label
  local code = ns.Locale and ns.Locale.code
  -- 1.3.0: the picture with burnt-in text only where the theme has one (the black book, German)
  local frame = s and s[4] or id
  local baked = not (s and s[4]) and Look.StampTex(id)
  if not (s and fs and code) or (code == "deDE" and baked) then
    Look.StampSkin(tex, baked or Look.StampTex(frame, true))
    if fs then fs.on = false; fs:Hide() end
    return
  end
  Look.StampSkin(tex, Look.StampTex(frame, true))
  local text = L[s[1]]
  if fs.text ~= text then
    fs.text = text
    -- one line at 16 pt, otherwise one or two lines at 13, 11, 9 pt (1.2.2: a single word that is too wide
    -- and a third line also get smaller instead of being cut)
    Look.FitText(fs, text, GF.FIT_STAMP)
  end
  local c = GF.STAMP_INK[s[3]]
  fs:SetTextColor(c[1], c[2], c[3], 0.92)
  if fs.SetRotation then pcall(fs.SetRotation, fs, math.rad(-s[2])) end
  fs.on = true
  fs:SetShown(tex:IsShown())
end

function GF.ShowStamp(tex, on)
  tex:SetShown(on and true or false)
  if tex.label then tex.label:SetShown((on and tex.label.on) and true or false) end
end

------------------------------------------------------------------------
-- Bounty and "avenged" (1.2.1): posted by whom, own input on the poster, avengers for others
------------------------------------------------------------------------
function GF.CanBounty() return type(ns.Guild) == "table" and type(ns.Guild.SetBounty) == "function" end
-- 1.2.1 fix: one rule for menu and poster: not on the pardoned, except to take back one's own
function GF.MayBounty(item)
  if not GF.CanBounty() or type(item) ~= "table" or type(item.key) ~= "string" then return false end
  return item.status ~= "pardoned" or GCall("OwnBounty", item.key) ~= nil
end
function GF.Coin(r, key) r.coin:SetShown(GCall("HasBounty", key) == true) end
function GF.Gold(g) return Fmt(L.MONEY_GOLD, { count = UX.Thousands(g) }) end

-- rows { char, g, own, mine } and the sum in gold
function GF.BountyRows(key)
  local rows, sum = GCall("Bounties", key)
  if type(rows) ~= "table" then return {}, 0 end
  return rows, tonumber(sum) or 0
end

-- the first name, with several "+n" (1.2.1 fix: short, the line stays within 192 px; all are in the tooltip)
function GF.FirstPlus(first, n)
  if n <= 1 then return first end
  return Fmt(L.NAMES_PLUS, { name = first, count = n - 1 })
end

-- one line for the poster: "500g, posted by you" / "... by Anna" / "Bounty 700g: Anna +2"
-- (cut: the truncated first name when the line would be too wide otherwise)
function GF.BountyLine(rows, sum, cut)
  if #rows == 0 then return nil end
  if #rows == 1 then
    local r = rows[1]
    if r.mine then return Fmt(L.POSTER_BOUNTY_MINE, { gold = GF.Gold(r.g) }) end
    return Fmt(L.POSTER_BOUNTY_BY, { gold = GF.Gold(r.g), name = cut or Look.First(r.char) })
  end
  -- several: the sum, the largest poster and how many more (amounts per poster in the line's tooltip)
  return Fmt(L.POSTER_BOUNTY_MANY, { gold = GF.Gold(sum), names = GF.FirstPlus(cut or Look.First(rows[1].char), #rows) })
end

-- 1.2.1 fix: a line wider than its 192 px truncates the first name ("Annabel… +3"); all are in the line's
-- tooltip. make(cut) builds the line with the truncated name.
function GF.Fit(fs, first, make)
  if type(first) ~= "string" or TextWidth(fs, 0) <= 192 then return end
  local chars = {}
  for c in first:gmatch("[%z\1-\127\194-\244][\128-\191]*") do chars[#chars + 1] = c end
  for n = #chars - 1, 2, -1 do
    fs:SetText(make(table.concat(chars, "", 1, n) .. "…"))
    if TextWidth(fs, 0) <= 192 then return end
  end
end

-- Tooltip: every poster with amount (at most 20, then "and n more"), below it how to set one
function GF.BountyTip(rows)
  local t = { Spaced(L.POSTER_BOUNTY) }
  for i = 1, math.min(#rows, 20) do t[#t + 1] = tostring(rows[i].char) .. ": " .. GF.Gold(rows[i].g) end
  if #rows > 20 then t[#t + 1] = Fmt(L.MORE_LINE, { count = #rows - 20 }) end
  if GF.CanBounty() then t[#t + 1] = L.BOUNTY_TIP_CLICK end
  return t
end

-- "Avenged by Anna 2×" / "Avenged by Anna +2" (all with their counts in the tooltip)
function GF.AvengedText(rows, cut)
  local first = cut or Look.First(rows[1].char)
  if #rows == 1 then first = first .. " " .. Look.Times(rows[1].n) end
  return Fmt(L.POSTER_AVENGED, { names = GF.FirstPlus(first, #rows) })
end
function GF.AvengedLine(key)
  local rows = GCall("Avenged", key)
  if type(rows) ~= "table" or #rows == 0 then return nil end
  return GF.AvengedText(rows), rows
end

function GF.AvengedTip(rows)
  -- (the head without its colon, also the full-width one of zhCN and zhTW)
  local t = { (Fmt(L.POSTER_AVENGED, { names = "" }):gsub("[%s:]+$", ""):gsub("\239\188\154$", "")) }
  for i = 1, math.min(#rows, 20) do t[#t + 1] = tostring(rows[i].char) .. " " .. Look.Times(rows[i].n) end
  if #rows > 20 then t[#t + 1] = Fmt(L.MORE_LINE, { count = #rows - 20 }) end
  return t
end

-- invisible area over a line of the poster details (bounty: tooltip with everyone, click: set your own;
-- avenged: tooltip with everyone). If the line is dropped, the tooltip over the details shows everything.
function GF.PlaceLineHit(E, hit, idx, tip)
  local shown = idx and E.shownOf and E.shownOf[idx]
  if not shown then hit.tip = nil; hit:Hide(); return end
  hit:ClearAllPoints()
  hit:SetPoint("TOPLEFT", E.info[shown], "TOPLEFT", 0, 0)
  hit.tip = tip
  hit:SetFrameLevel(E.infoHit:GetFrameLevel() + 2)
  hit:Show()
end
function GF.PlaceBountyLine(E, idx, rows, aidx, arows, sum)
  GF.PlaceLineHit(E, E.bountyLineHit, idx, idx and GF.BountyTip(rows))
  GF.PlaceLineHit(E, E.avengedHit, aidx, aidx and arows and GF.AvengedTip(arows))
  local b = idx and E.shownOf and E.shownOf[idx]
  if b and rows[1] and not (#rows == 1 and rows[1].mine) then
    GF.Fit(E.info[b], Look.First(rows[1].char), function(cut) return GF.BountyLine(rows, sum, cut) end)
  end
  local a = aidx and E.shownOf and E.shownOf[aidx]
  if a and arows and arows[1] then
    GF.Fit(E.info[a], Look.First(arows[1].char), function(cut) return GF.AvengedText(arows, cut) end)
  end
end

-- input in place of the large value: Enter sets, empty or 0 takes back, Esc or losing focus cancels
function GF.EditBounty(key)
  local E = P and P.enemy
  if not (E and GF.CanBounty() and type(key) == "string" and E.current and E.current.key == key and E:IsVisible()) then return end
  if not GF.MayBounty(E.current) then return end
  local ed = E.bountyEdit
  ed.key = key
  local g = GCall("OwnBounty", key)
  ed:SetText(g and tostring(g) or "")
  E.bounty:Hide()
  E.bountyHit:Hide()     -- 1.2.1 fix: otherwise the click area lies over the field
  ed:Show()
  ed:SetFocus()
  ed:HighlightText()
  Tip(ed, { L.BOUNTY_TIP_HEAD, L.BOUNTY_TIP_RULES, L.BOUNTY_TIP_PROMISE })
end

function GF.EndBounty(ed, save)
  local key = ed.key
  if not key then return end
  local text = tostring(ed:GetText() or ""):gsub("^%s+", ""):gsub("%s+$", "")
  local gold
  if save then
    if text == "" then gold = 0 else gold = text:match("^%d+$") and tonumber(text) or nil end
    if not gold or gold > 99999 then
      if ns.Util and ns.Util.Print then ns.Util.Print(L.CHAT_BOUNTY_BAD) end
      ed:HighlightText()
      return
    end
  end
  ed.key = nil
  ed:ClearFocus()
  ed:Hide()
  if GameTooltip.IsOwned and GameTooltip:IsOwned(ed) then GameTooltip:Hide() end
  local E = P.enemy
  E.bounty:Show()
  if save then
    local had = GCall("OwnBounty", key)
    if gold > 0 or had then
      local ok, why = GCall("SetBounty", key, gold)
      if ns.Util and ns.Util.BountyReport then
        local x = GCall("Hunt", key, "all") or GCall("Get", key, "all") or Store().Get(key)
        ns.Util.BountyReport(type(x) == "table" and Look.Name(x) or key, gold, ok, why)
      end
    end
  end
  UI.Refresh()
end

-- at the end of every poster: an open input only for exactly this killer (otherwise cancel), else the value is visible
function GF.BountySlot(E, key)
  local ed = E.bountyEdit
  if ed:IsShown() and ed.key ~= key then ed.key = nil; ed:ClearFocus(); ed:Hide() end
  E.bounty:SetShown(not ed:IsShown())
  if ed:IsShown() then E.bountyHit:Hide() end
end

GF.FIT_STRIKE = { sizes = { 13, 11 } }
GF.FIT_IO_HELP = { sizes = { 11, 10 }, lines = 2, wrapFirst = true }
GF.FIT_NAME22, GF.FIT_NAME26, GF.FIT_WORD = { sizes = { 22, 19, 16 } }, { sizes = { 26, 22, 19 } }, { sizes = { 11, 10 } }
function UX.BuildPoster()
  P = CreateFrame("Frame", nil, RP)
  P:SetSize(352, 452)
  P:SetPoint("TOP", 2, -20)
  UX.Shadow(P, 4, 5, 0.5)
  local bg = Tex(P, "BACKGROUND", "paper")
  bg:SetAllPoints()
  P.pin = P:CreateTexture(nil, "OVERLAY", nil, 7)
  P.pin:SetSize(28, 28)
  P.pin:SetPoint("TOP", 0, 12)
  Look.Skin(P.pin, "pin")
  if ns.Humor then pcall(ns.Humor.Pin, P, P.pin) end -- Humor: thumbtack (an error there only costs the thumbtack)
  P.tapes = { Tape(P, "BOTTOMLEFT", 0.6), Tape(P, "BOTTOMRIGHT", -0.55) }
  P.card = Tape(P, "TOPLEFT", 0.75)            -- index card (file): tape instead of a thumbtack
  P.card:Hide()

  -- killer poster (also for the guild book)
  local E = CreateFrame("Frame", nil, P)
  E:SetAllPoints()
  P.enemy = E
  -- 1.2.1: right click on the poster: the same menu as on the row (take back revenge, post a bounty ...)
  E:EnableMouse(true)
  E:SetScript("OnMouseUp", function(self, mouse)
    if mouse == "RightButton" and type(self.current) == "table" and self.current.key then UX.RowMenu({ item = self.current }, self) end
  end)
  -- the poster takes the mouse: dragging with the left button still moves the book (as everywhere else)
  E:RegisterForDrag("LeftButton")
  E:SetScript("OnDragStart", function() local f = F and F:GetScript("OnDragStart"); if f then f(F) end end)
  E:SetScript("OnDragStop", function() local f = F and F:GetScript("OnDragStop"); if f then f(F) end end)
  E.wanted = Look.Text(E, "head", 46, Look.INK)
  E.wanted:SetPoint("TOP", 0, -12)
  E.wanted:SetText(L.POSTER_HEAD)
  Rule(E, -56, 24, 24, 0.7)
  E.doa = Look.Text(E, "body", 11, Look.INK)
  E.doa:SetPoint("TOP", 0, -61)
  Rule(E, -76, 24, 24, 0.7)

  local photo = CreateFrame("Frame", nil, E)
  photo:SetSize(100, 100)
  photo:SetPoint("TOPLEFT", 20, -88)
  E.photo = photo
  local pb = photo:CreateTexture(nil, "BACKGROUND")
  pb:SetPoint("TOPLEFT", -3, 3); pb:SetPoint("BOTTOMRIGHT", 3, -3)
  pb:SetColorTexture(C(Look.INK, 1))
  local mug = photo:CreateTexture(nil, "BORDER")
  mug:SetAllPoints()
  Look.Skin(mug, "mugshot")
  E.icon = photo:CreateTexture(nil, "ARTWORK")
  E.icon:SetSize(70, 70)
  E.icon:SetPoint("CENTER", 0, -4)
  MugIcon(E.icon)
  E.portrait = photo:CreateTexture(nil, "ARTWORK", nil, 1)
  E.portrait:SetSize(86, 86)
  E.portrait:SetPoint("CENTER", 0, -3)
  E.portrait:Hide()
  Tape(photo, "TOPLEFT", 0.7)
  Tape(photo, "TOPRIGHT", -0.7, -10)     -- slightly indented: the name next to it stays clear

  -- name (at most 2 lines), class bar, the key number in handwriting, below it the poster details
  E.name = Look.Text(E, "hand", 19, Look.INK)
  E.name:SetPoint("TOPLEFT", 140, -86)
  E.name:SetWidth(192)
  E.name:SetJustifyH("LEFT")
  E.name:SetMaxLines(2)
  E.bar = E:CreateTexture(nil, "ARTWORK")
  E.bar:SetSize(100, 3)
  E.bar:SetPoint("TOPLEFT", E.name, "BOTTOMLEFT", 0, -3)
  E.tally = Look.Text(E, "hand", 16, Look.INK)
  E.tally:SetPoint("TOPLEFT", E.bar, "BOTTOMLEFT", 0, -4)
  E.tally:SetWidth(192)
  E.tally:SetJustifyH("LEFT")
  -- 1.2.2: key number in at most two lines (before: one, "… · 1× involved" dropped out in 16 of 21 languages),
  -- truncated: full text in the tooltip; the details below then lose one line
  E.tally:SetMaxLines(2)
  E.tallyHit = CreateFrame("Frame", nil, E)
  E.tallyHit:SetAllPoints(E.tally)
  -- 1.3.0: over the standing, what the numbers mean ("you 1, them 2"); a cut line still shows whole (hook below)
  E.tallyHit:SetScript("OnEnter", function(self) if self.standTip then Tip(self, { E.tally.full or E.tally:GetText() or "", self.standTip }) end end)
  E.tallyHit:SetScript("OnLeave", function(self) if self.standTip then GameTooltip:Hide() end end)
  Look.TipIfCut(E.tallyHit, E.tally)
  E.measure = Look.Text(E, "type", 11, Look.INK)   -- 1.3.0: measures the line "last seen" (never shown)
  E.measure:Hide()
  E.info = {}
  for i = 1, INFO_LINES do
    local l = Look.Text(E, "type", 11, Look.INK)
    if i == 1 then l:SetPoint("TOPLEFT", E.tally, "BOTTOMLEFT", 0, -3)
    else l:SetPoint("TOPLEFT", E.info[i - 1], "BOTTOMLEFT", 0, -2) end
    l:SetWidth(192)
    l:SetJustifyH("LEFT")
    l:SetWordWrap(false)
    E.info[i] = l
  end

  -- invisible areas: "In the book of: …" or the whole details when lines are missing
  E.listHit = CreateFrame("Button", nil, E)
  E.listHit:SetSize(200, 13)
  E.listHit:SetScript("OnEnter", CandEnter)
  E.listHit:SetScript("OnLeave", CandLeave)
  E.listHit:Hide()
  E.infoHit = CreateFrame("Button", nil, E)
  E.infoHit:SetPoint("TOPLEFT", E.info[1], "TOPLEFT", 0, 0)
  E.infoHit:SetSize(200, 60)    -- 1.2.2: over all four lines (before 30 px, the lower lines had no tooltip)
  E.infoHit:SetScript("OnEnter", CandEnter)
  E.infoHit:SetScript("OnLeave", CandLeave)
  E.infoHit:Hide()
  -- full name and all victims in the tooltip (long names are truncated)
  E.nameHit = CreateFrame("Button", nil, E)
  E.nameHit:SetPoint("TOPLEFT", E.name, "TOPLEFT", 0, 0)
  E.nameHit:SetSize(192, 22)
  E.nameHit:SetScript("OnEnter", CandEnter)
  E.nameHit:SetScript("OnLeave", CandLeave)

  E.bountyLabel = Look.Text(E, "body", 10, Look.RED_INK)
  E.bounty = Look.Text(E, "hand", 22, Look.INK)
  E.bountySize = 22
  -- 1.2.1: click on the bounty (own poster): post your own bounty; tooltip with all posters
  E.bountyHit = CreateFrame("Button", nil, E)
  E.bountyHit:SetSize(150, 40)
  E.bountyHit:SetPoint("TOP", E.bountyLabel, "TOP", 0, 2)
  E.bountyHit:SetScript("OnEnter", CandEnter)
  E.bountyHit:SetScript("OnLeave", CandLeave)
  E.bountyHit:SetScript("OnClick", function(self) Look.Sound("click"); GF.EditBounty(self.key) end)
  E.bountyHit:Hide()
  E.bountyLineHit = CreateFrame("Button", nil, E)
  E.bountyLineHit:SetSize(192, 13)
  E.bountyLineHit:SetScript("OnEnter", CandEnter)
  E.bountyLineHit:SetScript("OnLeave", CandLeave)
  E.bountyLineHit:SetScript("OnClick", function() Look.Sound("click"); GF.EditBounty(E.current and E.current.key) end)
  E.bountyLineHit:Hide()
  E.avengedHit = CreateFrame("Button", nil, E)
  E.avengedHit:SetSize(192, 13)
  E.avengedHit:SetScript("OnEnter", CandEnter)
  E.avengedHit:SetScript("OnLeave", CandLeave)
  E.avengedHit:Hide()
  local ed = CreateFrame("EditBox", nil, E)
  ed:SetSize(110, 24)
  ed:SetPoint("TOP", E.bountyLabel, "BOTTOM", 0, -1)
  ed:SetAutoFocus(false)
  ed:SetMaxLetters(5)
  ed:SetJustifyH("CENTER")
  Look.Font(ed, "hand", 19)
  ed:SetTextColor(C(Look.RED_INK))
  local edl = ed:CreateTexture(nil, "BACKGROUND")
  edl:SetColorTexture(C(Look.INK, 0.35))
  edl:SetHeight(1)
  edl:SetPoint("BOTTOMLEFT", 0, 1); edl:SetPoint("BOTTOMRIGHT", 0, 1)
  ed:SetScript("OnEnterPressed", function(self) GF.EndBounty(self, true) end)
  ed:SetScript("OnEscapePressed", function(self) GF.EndBounty(self, false) end)
  ed:SetScript("OnEditFocusLost", function(self) GF.EndBounty(self, false) end)
  ed:Hide()
  E.bountyEdit = ed

  E.fileLabel = Label(E, "")
  E.fileLabel:SetPoint("TOPLEFT", 20, -256)
  Rule(E, -267, 20, 20, 0.45)
  -- deeds as small frames: full text and accomplices in the tooltip. On the right the role ("involved",
  -- "suspect") as a column of its own so it is never cut; the place gets truncated instead.
  E.lines = {}
  for i = 1, DEATH_LINES do
    local b = CreateFrame("Button", nil, E)
    b:SetSize(312, 16)
    b:SetPoint("TOPLEFT", 20, -271 - (i - 1) * 16)
    b.text = Look.Text(b, "hand", 13, Look.INK)
    b.text:SetPoint("LEFT", 0, 0)
    b.text:SetWidth(312)
    b.text:SetJustifyH("LEFT")
    b.text:SetWordWrap(false)
    b.tag = Look.Text(b, "hand", 13, Look.INK)
    b.tag:SetPoint("RIGHT", 0, 0)
    b.tag:SetJustifyH("RIGHT")
    b.tag:SetTextColor(C(Look.INK, TONE.sub))
    b.tagged = false
    b:SetScript("OnEnter", DeedEnter)
    b:SetScript("OnLeave", GameTooltip_Hide)
    Look.TipShows(b, b.text)
    E.lines[i] = b
  end

  E.noteLabel = Label(E, "")
  E.noteLabel:SetPoint("TOPLEFT", 20, -381)
  local note = CreateFrame("EditBox", nil, E)
  -- 1.2.0: width from the label (language). 1.2.0: two anchors on the same top edge (before LEFT plus
  -- RIGHT: two vertical centres that disagreed by about 100 px)
  note:SetPoint("TOPLEFT", E.noteLabel, "TOPRIGHT", 8, 4)
  note:SetPoint("TOPRIGHT", E, "TOPRIGHT", -20, -377)
  note:SetHeight(18)
  note:SetAutoFocus(false)
  note:SetMaxLetters(200)
  Look.Font(note, "hand", 13)
  note:SetTextColor(C(Look.INK))
  local ul = note:CreateTexture(nil, "BACKGROUND")
  ul:SetColorTexture(C(Look.INK, 0.35))
  ul:SetHeight(1)
  ul:SetPoint("BOTTOMLEFT", 0, 1); ul:SetPoint("BOTTOMRIGHT", 0, 1)
  local function save(self)
    local key = self.key
    if not key then return end
    local e = Store().Get(key)
    local text = self:GetText() or ""
    -- the shown sentence of an entry taken over from the guild book is no own note (1.2.0)
    if e and (e.note or "") ~= text and text ~= Look.NoteOf(e) then Store().SetNote(key, text) end
  end
  note:SetScript("OnEnterPressed", function(self) save(self); self:ClearFocus() end)
  note:SetScript("OnEditFocusLost", save)
  note:SetScript("OnEscapePressed", function(self)
    local e = self.key and Store().Get(self.key)
    self:SetText(e and Look.NoteOf(e) or "")
    self:ClearFocus()
  end)
  E.note = note
  -- 1.2.2: note longer than the field shows: in full in the tooltip (measured on show with an invisible font string)
  note.measure = Look.Text(E, "hand", 13, Look.INK)
  note.measure:Hide()
  note:SetScript("OnEnter", function(self)
    local t = self:GetText()
    if type(t) ~= "string" or t == "" or Look.Secret(t) then return end
    self.measure:SetText(t)
    local w, fw = Look.TextW(self.measure), self:GetWidth()
    if w and type(fw) == "number" and not Look.Secret(fw) and w > fw - 2 then Tip(self, { t }); self.tipped = true end
  end)
  note:SetScript("OnLeave", function(self) if self.tipped then self.tipped = nil; GameTooltip:Hide() end end)
  -- guild poster: the victims instead of the note
  E.victims = Look.Text(E, "hand", 13, Look.INK)
  E.victims:SetPoint("TOPLEFT", E.noteLabel, "TOPRIGHT", 8, 2)
  E.victims:SetPoint("TOPRIGHT", E, "TOPRIGHT", -20, -379)
  E.victims:SetJustifyH("LEFT")
  E.victims:SetWordWrap(false)
  E.victims:Hide()
  E.victimsHit = CreateFrame("Button", nil, E)
  E.victimsHit:SetPoint("LEFT", E.victims, "LEFT", 0, 0)
  E.victimsHit:SetPoint("RIGHT", E.victims, "RIGHT", 0, 0)
  E.victimsHit:SetHeight(16)
  E.victimsHit:SetScript("OnEnter", CandEnter)
  E.victimsHit:SetScript("OnLeave", CandLeave)
  E.victimsHit:Hide()
  Look.TipShows(E.victimsHit, E.victims)

  -- Stamps (pre-rotated textures). No. 1 / Pardoned / Suspect on the lower half of the photo,
  -- revenge next to the bounty: no stamp lies on text.
  -- Own layer ABOVE the photo: the photo is a child frame, and regions of a child frame are always drawn
  -- above those of the parent frame in the client, whatever the draw layer. Without this layer the stamp
  -- disappears behind the photo.
  local SL = CreateFrame("Frame", nil, E)
  SL:SetAllPoints(E)
  SL:SetFrameLevel(photo:GetFrameLevel() + 3)
  E.stampLayer = SL
  -- 1.2.0: one font string per stamp for the version without burnt-in text (all languages except German)
  E.stampNr1 = SL:CreateTexture(nil, "OVERLAY", nil, 3)
  E.stampNr1:SetSize(GF.STAMP_W, GF.STAMP_H)
  E.stampNr1:SetPoint("TOPLEFT", photo, "TOPLEFT", -22, -54)
  E.stampNr1:SetAlpha(0.92)
  E.stampOther = SL:CreateTexture(nil, "OVERLAY", nil, 3)
  E.stampOther:SetSize(GF.STAMP_W, GF.STAMP_H)
  E.stampOther:SetPoint("TOPLEFT", photo, "TOPLEFT", -22, -54)
  E.stampOther:SetAlpha(0.92)
  E.stampRache = SL:CreateTexture(nil, "OVERLAY", nil, 4)
  E.stampRache:SetSize(GF.STAMP_W, GF.STAMP_H)
  E.stampRache:SetPoint("TOP", 70, -200)
  E.stampRache:SetAlpha(0.92)
  for _, st in ipairs({ E.stampNr1, E.stampOther, E.stampRache }) do GF.StampLabel(SL, st) end
  GF.Stamp(E.stampRache, "rache")
  E.racheCount = Look.Text(E, "body", 19, Look.COLOR.stampCount, "THICKOUTLINE")
  E.racheCount:SetPoint("LEFT", E.stampRache, "RIGHT", -6, -8)
  if E.racheCount.SetRotation then pcall(E.racheCount.SetRotation, E.racheCount, 0.16) end

  -- Poster foot row (1.2.2): two buttons on the left, "Strike out" on the right, together 296 px (x = 20 to 332, two
  -- gaps of 8). Fair shares: the need of each is measured first (the longest label the buttons can carry plus 8,
  -- the word plus 4). While the needs fit, nobody is cut: first at 10 pt (buttons) and 13 pt (word), then the
  -- buttons at 9 pt, then the word at 11 pt; the room left goes to the buttons up to 108 px, then to the word (64 to
  -- 120 px). If even that does not fit, all give way in proportion to their need; a cut label or word shows whole
  -- in its tooltip (the word is also in the menu of the poster).
  E.strike = WordButton(E, L.ACT_STRIKE, "hand", 13)
  E.strike:SetPoint("BOTTOMRIGHT", -20, 11)
  E.buttons = {}
  for i = 1, 2 do E.buttons[i] = InkButton(E, "", 108, 22) end
  local function needS(size) return math.ceil((GF.MeasureAt(E.strike.text, L.ACT_STRIKE, size) or 60) + 4) end
  local function needB(size)
    local n = 0
    for _, k in ipairs(GF.POSTER_LABELS) do n = math.max(n, math.ceil((GF.MeasureAt(E.buttons[1].text, L[k] or "", size) or 0) + 8)) end
    return n
  end
  local room = GF.FOOT_ROOM
  local b10, b9, s13, s11 = needB(10), needB(9), needS(13), needS(11)
  local bw, sw
  for _, n in ipairs({ { b10, s13 }, { b9, s13 }, { b9, s11 } }) do
    if 2 * n[1] + n[2] <= room then
      bw = math.min(108, math.max(n[1], math.floor((room - math.max(n[2], 64)) / 2)))
      sw = math.min(120, room - 2 * bw)
      break
    end
  end
  if not bw then
    bw = math.floor(b9 * room / (2 * b9 + s11))
    sw = room - 2 * bw
  end
  E.strike:SetSize(sw, 20)
  E.strike.text:SetWidth(sw)
  Look.FitText(E.strike.text, L.ACT_STRIKE, GF.FIT_STRIKE)
  Look.TipIfCut(E.strike, E.strike.text)
  for i = 1, 2 do
    E.buttons[i]:SetWidth(bw)
    E.buttons[i]:SetLabel("")
    E.buttons[i]:SetPoint("BOTTOMLEFT", 20 + (i - 1) * (bw + 8), 10)
  end
  E.strike:SetScript("OnClick", function(self) Look.Sound("click"); if self.key then UI.ConfirmDelete(self.key) end end)
  -- 1.2.0: "Put on hit list" / "Call off the hunt" as a word below the photo (own wanted, guild, friends)
  E.hunt = WordButton(E, "", "hand", 13)
  E.hunt:SetPoint("TOPLEFT", 20, -193)
  E.hunt:SetSize(120, 18)
  E.hunt:SetScript("OnClick", function(self)
    Look.Sound("click")
    if not self.key then return end
    if self.hide then GF.HideAction(self.key)[2]() else GF.HuntAction(self.key)[2]() end
  end)
  E.hunt:Hide()

  -- death file (journal, Unsolved): index card, left aligned
  local D = CreateFrame("Frame", nil, P)
  D:SetAllPoints()
  D:Hide()
  P.death = D
  D.head = Look.Text(D, "head", 26, Look.INK)
  D.head:SetPoint("TOPLEFT", 24, -16)
  D.head:SetText(L.CASE_HEAD)
  D.when = Look.Text(D, "type", 11, Look.INK)
  D.when:SetPoint("TOPRIGHT", -24, -28)
  D.when:SetJustifyH("RIGHT")
  Rule(D, -52, 24, 24, 0.7)
  -- 1.2.2: below the head the file scrolls (same coordinates as before), the source line stands in the foot
  D.page = Look.Page(D, { top = 54, foot = 46, w = 352, h = 452, paper = "paper" })
  local Ds = CreateFrame("Frame", nil, D.page.body)
  Ds:SetPoint("TOPLEFT", D.page.body, "TOPLEFT", 0, 54)
  Ds:SetSize(352, 452)
  D.sheet = Ds
  D.info = Look.Text(Ds, "type", 11, Look.INK)
  D.info:SetPoint("TOPLEFT", 24, -62)
  D.info:SetWidth(304)
  D.info:SetJustifyH("LEFT")
  D.info:SetSpacing(3)
  D.killLabel = Look.Text(Ds, "body", 10, Look.RED_INK)
  D.killLabel:SetPoint("TOPLEFT", D.info, "BOTTOMLEFT", 0, -16)
  D.killer = CreateFrame("Button", nil, Ds)
  D.killer:SetSize(304, 32)
  D.killer:SetPoint("TOPLEFT", D.killLabel, "BOTTOMLEFT", 0, -2)
  D.killer.text = Look.Text(D.killer, "hand", 26, Look.INK)
  D.killer.text:SetPoint("LEFT", 0, 0)
  D.killer.text:SetWidth(304)
  D.killer.text:SetJustifyH("LEFT")
  D.killer.text:SetWordWrap(false)
  Look.TipIfCut(D.killer, D.killer.text)   -- 1.2.2: 26, 22, 19 pt, then tooltip
  D.killer:SetScript("OnClick", function(self)
    if self.key and Store().Get(self.key) then UI.ShowEnemy(self.key) end
  end)
  D.note = Look.Text(Ds, "type", 11, Look.INK)
  D.note:SetPoint("TOPLEFT", D.killer, "BOTTOMLEFT", 0, -2)
  D.note:SetWidth(304)
  D.note:SetJustifyH("LEFT")
  D.note:SetTextColor(C(Look.INK, TONE.sub))
  -- accomplices: clickable names in handwriting
  D.assistLabel = Label(Ds, L.CASE_ASSISTS)
  D.assistLabel:SetPoint("TOPLEFT", D.note, "BOTTOMLEFT", 0, -14)
  D.assists = {}
  for i = 1, GF.ASSIST_MAX do
    local b = WordButton(Ds, "", "hand", 16, TONE.ink)
    b:SetSize(304, 20)
    if i == 1 then b:SetPoint("TOPLEFT", D.assistLabel, "BOTTOMLEFT", 0, -2)
    else b:SetPoint("TOPLEFT", D.assists[i - 1], "BOTTOMLEFT", 0, 0) end
    b:SetScript("OnClick", function(self) if self.key and Store().Get(self.key) then UI.ShowEnemy(self.key) end end)
    D.assists[i] = b
  end
  D.candLabel = Label(Ds, L.CASE_PICK)
  D.candLabel:SetPoint("TOPLEFT", D.note, "BOTTOMLEFT", 0, -14)
  D.cands = {}
  for i = 1, GF.CAND_MAX do
    local b = InkButton(Ds, "", 148, 22)
    local col, row = (i - 1) % 2, math.floor((i - 1) / 2)
    b:SetPoint("TOPLEFT", D.candLabel, "BOTTOMLEFT", col * 156, -6 - row * 28)
    b:HookScript("OnEnter", CandEnter)
    b:HookScript("OnLeave", CandLeave)
    D.cands[i] = b
  end
  D.source = Look.Text(D.page.foot, "type", 11, Look.INK)
  D.source:SetPoint("BOTTOMLEFT", 24, 18)
  D.source:SetWidth(304)
  D.source:SetJustifyH("LEFT")
  D.source:SetTextColor(C(Look.INK, TONE.sub))

  -- empty state: written by hand on the empty right page
  local X = CreateFrame("Frame", nil, RP)
  X:SetAllPoints()
  X:Hide()
  RP.empty = X
  X.big = Look.Text(X, "head", 26, Look.INK)
  X.big:SetPoint("CENTER", 0, 20)
  X.big:SetWidth(PAGE_W - 40)
  X.small = Look.Text(X, "hand", 16, Look.INK)
  X.small:SetTextColor(C(Look.INK, TONE.sub))
  X.small:SetPoint("TOP", X.big, "BOTTOM", 0, -12)
  X.small:SetWidth(PAGE_W - 40)
  X.tiny = Look.Text(X, "type", 11, Look.INK)
  X.tiny:SetTextColor(C(Look.INK, TONE.sub))
  X.tiny:SetPoint("TOP", X.small, "BOTTOM", 0, -14)
  X.tiny:SetWidth(PAGE_W - 80)
  local xs = X:CreateTexture(nil, "ARTWORK")
  xs:SetSize(64, 64)
  xs:SetPoint("BOTTOM", X.big, "TOP", 0, 20)
  Look.Skin(xs, "skull")
  xs:SetVertexColor(C(Look.COLOR.skullFaint))
end

-- empty state of the right page: one pattern for all tabs
local function ShowEmpty(kind)
  local t = EMPTY[kind] or EMPTY.wanted
  RP.empty.big:SetText(L[t[1] .. "_HEAD"])
  RP.empty.small:SetText(t[2] >= 2 and L[t[1] .. "_SUB"] or "")
  RP.empty.tiny:SetText(t[2] >= 3 and L[t[1] .. "_HINT"] or "")
  if kind == "wanted" and ns.Humor then pcall(ns.Humor.EmptyWanted, RP.empty) end -- Humor: empty book, 1 April
  P:Hide()
  RP.empty:Show()
end

-- two buttons side by side at the bottom left (the word "Strike out" stands to their right)
-- every label they can carry (EnemySpec, GF.RevengeAct, GuildSpec, GF.HuntSpec): the foot row is measured on them
GF.POSTER_LABELS = { "ACT_CONFIRM", "ACT_DISMISS", "ACT_HUNT_AGAIN", "ACT_REVENGE", "ACT_UNDO", "ACT_PARDON",
                     "ACT_OPEN_OWN", "ACT_ADOPT", "ACT_CALLOFF", "ACT_RELEASE" }
GF.FOOT_ROOM = 352 - 40 - 16
-- width of text in fs at one size, only to measure (the field is fitted again by its owner afterwards)
GF.FIT_AT = {}
function GF.MeasureAt(fs, text, size)
  local o = GF.FIT_AT[size]
  if not o then o = { sizes = { size } }; GF.FIT_AT[size] = o end
  Look.FitText(fs, text, o)
  return Look.TextW(fs)
end
local function ConfigButtons(E, spec)
  for i = 1, 2 do
    local b, s = E.buttons[i], spec[i]
    if s then b:SetLabel(s[1]); b.fn = s[2]; b:Show() else b:Hide() end
  end
end

-- valid unit token for the portrait (tracker first, otherwise target/mouseover)
function UX.PortraitUnitFor(key)
  if ns.Tracker and ns.Tracker.UnitFor then
    local ok, u = pcall(ns.Tracker.UnitFor, key)
    if ok and type(u) == "string" and not Look.Secret(u) then return u end
  end
  if not (ns.Util and ns.Util.KeyOfUnit) then return nil end
  for _, u in ipairs({ "target", "mouseover" }) do
    local ok, k = pcall(ns.Util.KeyOfUnit, u)
    if ok and k == key then return u end
  end
end

UX.ROLE_TAG = { assist = "ROLE_ASSIST", suspect = "ROLE_SUSPECT" }   -- locale key

-- Deed line: "11.11. 01:01 · Seal of Command · The Untamed Coast" (important first, place last);
-- own character only if it was a different one. The role stands to the right of it.
function UX.DeathLine(d)
  local me = Look.Me()
  local who = (d.me and d.me ~= me) and ("(" .. Look.First(d.me) .. ")") or nil
  local tag = UX.ROLE_TAG[Look.Role(d)]
  return Look.Join(Look.When(d.t), d.spell ~= "" and d.spell or nil, Look.Place(d.zone, d.subzone), who),
         tag and L[tag]
end

function UX.DeathTip(d)
  local t = { Look.When(d.t), PlaceText(d.zone, d.subzone) }
  if d.spell and d.spell ~= "" then t[#t + 1] = Fmt(L.TIP_CAUSE, { spell = tostring(d.spell) }) end
  if d.me then t[#t + 1] = GF.VictimLine(d.me, d.myLevel) end
  if d.theirLevel then t[#t + 1] = Fmt(L.TIP_KILLER_LEVEL, { level = tostring(d.theirLevel) }) end
  if type(d.others) == "table" and #d.others > 0 then
    local names = {}
    for i = 1, math.min(#d.others, 6) do names[i] = (NameOfKey(d.others[i])) end
    t[#t + 1] = Fmt(L.TIP_ASSISTS, { names = table.concat(names, ", ") .. (#d.others > 6 and " …" or "") })
  end
  local role = Look.Role(d)
  if role == "assist" then t[#t + 1] = L.TIP_ROLE_ASSIST
  elseif role == "suspect" then t[#t + 1] = L.TIP_ROLE_SUSPECT end
  return t
end

-- guild deed: "12.11. 21:04 · Grom'gol · Anna"
function UX.GuildDeedLine(d)
  return Look.Join(Look.When(d.t), Look.Place(d.zone), Look.First(d.victim))
end

-- "Victim: Anna Beispiel (level 34)"
function GF.VictimLine(name, level)
  if level then return Fmt(L.TIP_VICTIM_LEVEL, { name = name, level = level }) end
  return Fmt(L.TIP_VICTIM, { name = name })
end

function UX.GuildDeedTip(d)
  local t = { Look.When(d.t), PlaceText(d.zone) }
  if d.victim then t[#t + 1] = GF.VictimLine(tostring(d.victim), d.level) end
  return t
end

local function FillLines(E, list, lineFn, tipFn, emptyText)
  local n = #list
  for i = 1, DEATH_LINES do
    local b = E.lines[i]
    b.tipItem, b.tipFn = nil, nil
    local text, tag = "", nil
    if i == DEATH_LINES and n > DEATH_LINES then
      text = Fmt(L.MORE_LINE, { count = n - DEATH_LINES + 1 })
    elseif list[i] then
      text, tag = lineFn(list[i])
      b.tipItem, b.tipFn = list[i], tipFn
    elseif i == 1 then
      text = emptyText
    end
    b.text:SetText(text)
    b.tag:SetText(tag or "")
    -- room for the role on the right by its width; the place before it gets truncated if needed
    local w = tag and math.floor(312 - TextWidth(b.tag, 60) - 10) or 312
    if b.tagged ~= w then
      b.tagged = w
      b.text:SetWidth(w)
    end
  end
end

local function SetPhoto(E, e)
  -- thumbtack (easter egg) only with "Dry remarks" on and only where the thumbtack is visible
  if P.dnPin then P.dnPin:SetShown(P.pin:IsShown() and ns.Humor and ns.Humor.On() or false) end
  E.name:SetText(Look.Name(e))
  E.nameHit.tip = Truncated(E.name) and { Look.Name(e) } or nil
  E.bar:SetColorTexture(Look.ClassRGB(e.class))
  local unit = UX.PortraitUnitFor(e.key)
  local pok = false
  if unit and SetPortraitTexture then
    E.portrait:SetTexCoord(0, 1, 0, 1)
    pok = pcall(SetPortraitTexture, E.portrait, unit)
  end
  E.portrait:SetShown(pok)
  E.icon:SetShown(not pok)
  if not pok then Look.ClassIcon(E.icon, e.class); MugIcon(E.icon) end
end

-- Poster details: at most as many lines as fit below the name. If a line drops out (long name
-- in two lines), the tooltip over the details shows everything.
local scratchInfo, scratchTip = {}, {}
local function SetInfo(E, info, optional)
  -- 1.2.2: real width without wrapping (GetStringWidth can end at the set width); a name and key number
  -- in two lines each take one line from the details
  local twoLines = (Look.TextW(E.name) or 0) > 192
  local room = INFO_LINES - (twoLines and 1 or 0) - ((Look.TextW(E.tally) or 0) > 192 and 1 or 0)
  local shown, dropped = 0, false
  -- 1.2.1: which line of the details (index in info) stands on which ruled line
  local at = E.shownOf or {}
  E.shownOf = at
  for k in pairs(at) do at[k] = nil end
  for i = 1, #info do
    -- 1.2.0: optional lines (race, guild) always give way when a later line would otherwise have no room
    if shown < room and not (optional[i] and #info - i + shown >= room) then
      shown = shown + 1
      E.info[shown]:SetText(info[i])
      at[i] = shown
    else
      dropped = true
    end
  end
  for i = shown + 1, INFO_LINES do E.info[i]:SetText("") end
  -- 1.2.2: a truncated line (ellipsis) also shows the whole details in the tooltip
  for i = 1, shown do if not dropped and Truncated(E.info[i]) then dropped = true end end
  for i = 1, INFO_LINES do E.info[i].tipOwner = dropped and E.infoHit or nil end
  if dropped then
    local t = wipe(scratchTip)
    t[1] = Look.Name(P.enemy.current)
    for i = 1, #info do t[#t + 1] = info[i] end
    E.infoHit.tip = t
    E.infoHit:Show()
  else
    E.infoHit.tip = nil
    E.infoHit:Hide()
  end
end

-- Bounty: font size ladder 22, 19, 16 pt, from four digits ("2.875 GOLD") 19, 16, 13 pt (1.2.2), picked by the
-- measured width; with a revenge stamp up to the stamp frame (124 px), otherwise the poster width (300 px)
GF.FIT_BOUNTY, GF.FIT_BOUNTY_BIG = { sizes = { 22, 19, 16 } }, { sizes = { 19, 16, 13 } }
local function SetBounty(E, text, big)
  E.bountyText, E.bountyFit = text, big and GF.FIT_BOUNTY_BIG or GF.FIT_BOUNTY
end

-- bounty block; with a revenge stamp it moves to the left, the stamp stands next to it
local function PlaceBounty(E, shifted)
  local x = shifted and -62 or 0
  E.bountyLabel:ClearAllPoints()
  E.bountyLabel:SetPoint("TOP", x, -212)
  E.bounty:ClearAllPoints()
  E.bounty:SetPoint("TOP", x, -225)
  E.bounty:SetWidth(shifted and 124 or 300)
  Look.FitText(E.bounty, E.bountyText or "", E.bountyFit)
  E.bountySize = E.bounty.fontSize
end

ClassName = function(e)
  if e.classLoc then return e.classLoc end
  -- Guild entries only carry the class token: if the same killer is in the own book, its wording
  -- ("Magierin") applies, so the same person is called the same everywhere
  local S = ns.Store
  local own = e.key and S and S.Get and S.Get(e.key)
  if type(own) == "table" and type(own.classLoc) == "string" and own.class == e.class then return own.classLoc end
  local CN = LOCALIZED_CLASS_NAMES_MALE
  if e.class and type(CN) == "table" and CN[e.class] then return CN[e.class] end
  return e.class
end

local optInfo = {}
GF.FIT_TALLY = { sizes = { 16 }, lines = 2, wrapFirst = true }
local function FillEnemy(e)
  local E = P.enemy
  E.current = e
  E.listHit:Hide()
  local S = Store()
  local rank = (e.status == "wanted") and S.Rank(e.key) or nil
  E.doa:SetText(Spaced(L.POSTER_DOA))
  SetPhoto(E, e)
  -- 1.3.0: the key number is the standing "Score 1 : 2 · 1× involved" (not for suspects and pure hand entries)
  local m, h, score = Look.Stand(e)
  if m and e.status ~= "suspect" and (m > 0 or h > 0) then
    local a = Look.Assists(e)
    Look.FitText(E.tally, Look.Join(e.status == "pardoned" and L.ROW_PARDONED or nil, Fmt(L.STAND_LINE, { score = score }),
      a > 0 and Fmt(L.TALLY_ASSISTED, { times = Look.Times(a) }) or nil), GF.FIT_TALLY)
    E.tallyHit.standTip = Fmt(L.STAND_TIP, { mine = m, his = h })
  else
    m = nil
    E.tallyHit.standTip = nil
    Look.FitText(E.tally, e.status == "pardoned" and Look.Join(L.ROW_PARDONED, Look.Tally(e)) or Look.Tally(e), GF.FIT_TALLY)
  end

  -- Details: "Level 36 · Mage", race, "Guild: Beispielgilde", last seen (race and guild drop out
  -- first with a two-line name)
  local info, opt = wipe(scratchInfo), wipe(optInfo)
  local cls = ClassName(e)
  local who = Look.Join(e.level and Fmt(L.POSTER_LEVEL, { level = e.level }), cls)
  if who ~= "" then info[#info + 1] = who end
  -- 1.2.0: pardoned, suspect or rank 1 and on the hit list at the same time (the stamp does not show it then).
  -- 1.2.0: right after the level, before race and guild (they give way first), so the line is always visible
  if e.status ~= "wanted" or rank == 1 then
    local h = GF.HasHunts() and GCall("Hunt", e.key, "all")
    if type(h) == "table" then
      local names = type(h.names) == "table" and h.names or {}
      -- 1.2.2: "Anna +2" as with the bounty (the line fits in 192 px; the hit list shows all names)
      info[#info + 1] = Fmt(L.POSTER_ON_HUNTLIST, { names = #names > 0 and GF.FirstPlus(Look.First(names[1]), #names) or Look.NameList(names, 2) })
    end
  end
  if e.raceLoc or e.race then info[#info + 1] = e.raceLoc or e.race; opt[#info] = true end
  if e.guild and e.guild ~= "" then info[#info + 1] = Fmt(L.POSTER_GUILD, { guild = e.guild }); opt[#info] = true end
  -- 1.2.1: posted bounty and "avenged by" as lines. They give way when room is short (race first, then guild,
  -- then the bounty, whose sum stands large next to it, then "avenged by"); "last seen" always stays.
  local brows, bsum = GF.BountyRows(e.key)
  local bline = GF.BountyLine(brows, bsum)
  local bidx, aidx
  if bline then info[#info + 1] = bline; bidx = #info; opt[#info] = true end
  local aline, arows = GF.AvengedLine(e.key)
  if aline then info[#info + 1] = aline; aidx = #info; opt[#info] = true end
  -- 1.3.0: "Last seen: Stranglethorn Vale, 2 hrs ago"; when that is wider than the line, the line of 1.2.2
  local seen, short = RS.LastSeen(e)
  local full
  if short and (GF.MeasureAt(E.measure, seen, 11) or 0) > 192 then full, seen = seen, short end
  info[#info + 1] = seen
  SetInfo(E, info, opt)
  if full and not E.infoHit:IsShown() then
    -- the zone did not fit: the whole line in the tooltip over the details
    local t = wipe(scratchTip)
    t[1], t[2] = Look.Name(e), full
    E.infoHit.tip = t
    E.infoHit:Show()
  end
  GF.PlaceBountyLine(E, bidx, brows, aidx, arows, bsum)

  -- second stamp place: REVENGE TAKEN (1.2.x: from the revenge count; 1.3.0: open and me > 0), EVEN, OVERPAID
  local rv = tonumber(e.revenge) or 0
  local second = (not m and rv > 0 and "rache") or nil
  if m and m > 0 then
    local st = Look.ScoreState(m, h)
    second = (st == "open" and "rache") or (st == "even" and "quitt") or "overpaid"
  end
  E.bountyLabel:SetText(Spaced(L.POSTER_BOUNTY))
  -- 1.2.1: posted: the sum large in red ink; otherwise the book's value as before
  if bsum > 0 then
    SetBounty(E, GoldText(bsum * 10000), bsum >= 1000)
    E.bounty:SetTextColor(C(Look.RED_INK))
  else
    local bounty = tonumber(S.Bounty and S.Bounty(e)) or 0
    SetBounty(E, GoldText(bounty), bounty >= 1000 * 10000)
    E.bounty:SetTextColor(C(Look.INK))
  end
  PlaceBounty(E, second ~= nil)
  E.bountyHit.key = GF.MayBounty(e) and e.key or nil
  E.bountyHit.tip = E.bountyHit.key and GF.BountyTip(brows) or nil
  E.bountyHit:SetShown(E.bountyHit.key ~= nil)
  GF.BountySlot(E, e.key)

  FillLines(E, e.deaths or {}, UX.DeathLine, UX.DeathTip,
            e.status == "suspect" and L.POSTER_ONLY_SUSPECT or L.POSTER_NO_DEEDS)
  E.fileLabel:SetText(Spaced(L.POSTER_DEEDS))

  E.noteLabel:SetText(Spaced(L.POSTER_NOTE))
  E.victims:Hide()
  E.victimsHit:Hide()
  E.note:Show()
  -- another entry while the field has focus: save under the old key first
  if E.note.key ~= e.key and E.note:HasFocus() then E.note:ClearFocus() end
  E.note.key = e.key
  if not E.note:HasFocus() then E.note:SetText(Look.NoteOf(e)) end

  if rank == 1 then GF.Stamp(E.stampNr1, "nr1") end
  GF.ShowStamp(E.stampNr1, rank == 1)
  -- SUSPECT only for real suspicion cases (those involved are wanted)
  if e.status == "pardoned" then
    GF.Stamp(E.stampOther, "pardon"); GF.ShowStamp(E.stampOther, true)
  elseif e.status == "suspect" then
    GF.Stamp(E.stampOther, "suspect"); GF.ShowStamp(E.stampOther, true)
  else
    GF.HuntStamp(E, e.key, rank == 1)
  end
  GF.SetHuntWord(E, e.status == "wanted" and e.key or nil)
  if second then GF.Stamp(E.stampRache, second) end
  GF.ShowStamp(E.stampRache, second ~= nil)
  -- the count "×2" next to the stamp only without the standing (the key number says it then)
  E.racheCount:SetShown(second == "rache" and not m)
  E.racheCount:SetText("×" .. rv)
  E.strike.key = e.key
  E.strike:Show()

  -- rebuild buttons (with their closures) only when entry or status changed
  local sig = "e\0" .. e.key .. "\0" .. tostring(e.status) .. (GF.undo and GF.undo.key == e.key and "\0u" or "")
  if E.specSig ~= sig then
    E.specSig = sig
    ConfigButtons(E, EnemySpec(e))
  end
end

-- 1.2.0: stamp ON THE HIT LIST in the place of the other stamps (No. 1 takes precedence)
function GF.HuntStamp(E, key, nr1)
  local h = not nr1 and GF.HasHunts() and GCall("Hunt", key, "all")
  if type(h) == "table" then
    GF.Stamp(E.stampOther, "hunt")
    GF.ShowStamp(E.stampOther, true)
  else
    GF.ShowStamp(E.stampOther, false)
  end
end

-- Word below the photo: post a call or call off the own one (key = nil: hide).
-- 1.2.0: only when no stamp is on the photo (it would lie on the word); otherwise the action is
-- only in the row menu. Call after the stamps.
function GF.SetHuntWord(E, key)
  E.hunt.hide = nil
  if key and (E.stampNr1:IsShown() or E.stampOther:IsShown()) then key = nil end
  if not key or not GF.HasHunts() then E.hunt.key = nil; E.hunt:Hide(); return end
  E.hunt.key = key
  -- 1.2.2: at most up to the details (x = 136), otherwise smaller, then tooltip
  E.hunt:SetWidth(116)
  E.hunt.text:SetWidth(116)
  Look.FitText(E.hunt.text, GF.Released(key) and L.ACT_CALLOFF or L.ACT_RELEASE, GF.FIT_STRIKE)
  Look.TipIfCut(E.hunt, E.hunt.text)
  E.hunt:Show()
end

-- manual entry: "Bert · 12.11. 21:04"
local function ListedLine(x) return Look.Join(Look.First(x[1]), Look.When(x[2])) end
local function ListedTip(x) return { tostring(x[1]), Fmt(L.TIP_LISTED_AT, { time = Look.When(x[2]) }) } end

-- "Seen 2 hrs ago by Anna" (by = who saw him, may be missing)
function GF.SeenBy(ago, by)
  if type(by) == "string" and by ~= "" then return Fmt(L.POSTER_SEEN_BY, { time = ago, name = Look.First(by) }) end
  return Fmt(L.POSTER_SEEN, { time = ago })
end

local scratchListed = {}
UX.scratchPairs = {}

-- Guild book: same poster, number of victims instead of bounty, deeds "date · place · victim".
-- Only entered by hand: no No. 1 stamp, "ENTERED BY HAND" instead of the victim count, the
-- entries (who, when) instead of the deeds.
local function FillGuild(g)
  local E = P.enemy
  E.current = g
  local only = Look.ListedOnly(g)
  local rank = not only and GCall("Rank", g.key, GF.Src()) or nil
  E.doa:SetText(Spaced(L.POSTER_GUILDBOOK))
  SetPhoto(E, g)
  Look.FitText(E.tally, only and L.TALLY_MANUAL or Fmt(L.ROW_GKILLED, { kills = Look.GKills(g.kills) }), GF.FIT_TALLY)

  local names = Look.ListedNames(g, scratchListed)
  local info, opt = wipe(scratchInfo), wipe(optInfo)
  local who = Look.Join(g.level and Fmt(L.POSTER_LEVEL, { level = g.level }), ClassName(g))
  if who ~= "" then info[#info + 1] = who end
  -- No. 1 and on the hit list at the same time: the stamp shows No. 1, the call stands as a line (as in the own book)
  if rank == 1 then
    local h = GF.HasHunts() and GCall("Hunt", g.key, "all")
    if type(h) == "table" then
      local hn = type(h.names) == "table" and h.names or {}
      info[#info + 1] = Fmt(L.POSTER_ON_HUNTLIST, { names = #hn > 0 and GF.FirstPlus(Look.First(hn[1]), #hn) or Look.NameList(hn, 2) })
    end
  end
  local listLine
  if #names > 0 then
    info[#info + 1] = Fmt(L.POSTER_IN_BOOK_OF, { names = Look.NameList(names, 2) })
    listLine = #info
    opt[#info] = true
  end
  -- 1.2.1: posted bounty and "avenged by" as lines (the victim count keeps its place); when room is short,
  -- "in the book of", the bounty and "avenged by" give way in this order, "last seen" stays
  local brows, bsum = GF.BountyRows(g.key)
  local bline = GF.BountyLine(brows, bsum)
  local bidx, aidx
  if bline then info[#info + 1] = bline; bidx = #info; opt[#info] = true end
  local aline, arows = GF.AvengedLine(g.key)
  if aline then info[#info + 1] = aline; aidx = #info; opt[#info] = true end
  local ls = type(g.lastSeen) == "table" and g.lastSeen or nil
  local ago = ls and Look.Ago(ls.t)
  if ago then
    info[#info + 1] = GF.SeenBy(ago, ls.by)
  else
    info[#info + 1] = L.POSTER_NOT_SEEN
  end
  SetInfo(E, info, opt)
  GF.PlaceBountyLine(E, bidx, brows, aidx, arows, bsum)
  -- tooltip with all names when truncated (more than two, first names, or too wide)
  local listAt = listLine and E.shownOf[listLine]
  if listAt and (#names > 2 or Truncated(E.info[listAt]) or Look.First(names[1]) ~= names[1]) then
    E.listHit.tip = { L.TIP_IN_BOOK_OF, table.concat(names, ", ") }
    E.listHit:ClearAllPoints()
    E.listHit:SetPoint("TOPLEFT", E.info[listAt], "TOPLEFT", 0, 0)
    E.listHit:Show()
  else
    E.listHit.tip = nil
    E.listHit:Hide()
  end

  if only then
    E.bountyLabel:SetText(Spaced(L.POSTER_REMARK))
    SetBounty(E, L.POSTER_BY_HAND, true)
  else
    -- 1.2.0: number of victims without a role (guildmate or friend), the label VICTIMS appears only once (below)
    E.bountyLabel:SetText("")
    SetBounty(E, Look.Count(g.victimCount, L.ROW_VICTIMS), false)
  end
  E.bounty:SetTextColor(C(Look.INK))
  PlaceBounty(E, false)
  E.bountyHit.key, E.bountyHit.tip = nil, nil
  E.bountyHit:Hide()
  GF.BountySlot(E, g.key)

  if only then
    -- who entered him and when, oldest first
    local list = UX.scratchPairs
    for i = #list, 1, -1 do list[i] = nil end
    for i = 1, #names do list[i] = { names[i], g.listedBy[names[i]] } end
    E.fileLabel:SetText(Spaced(L.POSTER_LISTED))
    FillLines(E, list, ListedLine, ListedTip, L.POSTER_LISTED_EMPTY)
  else
    E.fileLabel:SetText(Spaced(L.POSTER_DEEDS))
    FillLines(E, type(g.deeds) == "table" and g.deeds or {}, UX.GuildDeedLine, UX.GuildDeedTip, L.POSTER_NO_DEEDS_SENT)
  end

  -- victims by count, with first names
  local list = {}
  if type(g.victims) == "table" then
    for name, n in pairs(g.victims) do list[#list + 1] = { name, tonumber(n) or 0 } end
    table.sort(list, function(a, b) if a[2] ~= b[2] then return a[2] > b[2] end return tostring(a[1]) < tostring(b[1]) end)
  end
  local parts = {}
  for i = 1, math.min(#list, 6) do parts[i] = Look.First(list[i][1]) .. " " .. Look.Times(list[i][2]) end
  E.noteLabel:SetText(Spaced(L.POSTER_VICTIMS))
  if E.note:HasFocus() then E.note:ClearFocus() end
  E.note.key = nil
  E.note:Hide()
  E.victims:SetText(#parts > 0 and table.concat(parts, ", ") or (only and L.POSTER_NONE_KNOWN or L.POSTER_NO_NAMES))
  E.victims:Show()
  if #list > 0 then
    local full = { L.TIP_VICTIMS }
    for i = 1, math.min(#list, 20) do full[#full + 1] = tostring(list[i][1]) .. " " .. Look.Times(list[i][2]) end
    E.victimsHit.tip = full
    E.victimsHit:Show()
  else
    E.victimsHit.tip = nil
    E.victimsHit:Hide()
  end

  if rank == 1 then GF.Stamp(E.stampNr1, "guild") end
  GF.ShowStamp(E.stampNr1, rank == 1)
  GF.HuntStamp(E, g.key, rank == 1)
  GF.SetHuntWord(E, g.key)
  GF.ShowStamp(E.stampRache, false)
  E.racheCount:Hide()
  E.strike.key = nil
  E.strike:Hide()

  local sig = "g\0" .. g.key .. "\0" .. (Store().Get(g.key) and "1" or "0")
  if E.specSig ~= sig then
    E.specSig = sig
    ConfigButtons(E, GuildSpec(g))
  end
end

-- Hit list (1.2.0): poster with calls (who, when, reason), taken-down counter, stamp
function GF.HuntSpec(h)
  local key = h.key
  local second
  if Store().Get(key) then
    second = { L.ACT_OPEN_OWN, function() UI.ShowEnemy(key) end }
  else
    second = { L.ACT_ADOPT, function()
      local k = GCall("Adopt", key)
      if type(k) ~= "string" and Store().AddManual then
        k = Store().AddManual(h.name, h.surname, { fromGuild = true })
      end
      UI.Refresh()
      if type(k) == "string" and Store().Get(k) then UI.ShowEnemy(k) end
    end }
  end
  return { GF.HuntAction(key), second, GF.HideAction(key) }
end

-- 1.2.0: hide someone else's call for me (no alarm, pale at the end of the list) or bring it back
function GF.HideAction(key)
  if GCall("HuntHidden", key) then
    return { L.ACT_HUNT_SHOW, function() GCall("HideHunt", key, false); UI.Refresh() end }
  end
  return { L.ACT_HUNT_HIDE, function() GCall("HideHunt", key, true); UI.Refresh() end }
end

function UX.HuntLine(x) return Look.Join(Look.First(x.char), Look.When(x.t), x.why) end
function UX.HuntTip(x)
  local t = { tostring(x.char), Fmt(L.TIP_RELEASED_AT, { time = Look.When(x.t) }) }
  if type(x.why) == "string" and x.why ~= "" then t[#t + 1] = Fmt(L.HUNT_REASON, { reason = x.why }) end
  return t
end

function GF.FillHunt(h)
  local E = P.enemy
  E.current = h
  E.listHit:Hide()
  E.doa:SetText(Spaced(L.POSTER_HUNTLIST))
  SetPhoto(E, h)
  local n = tonumber(h.n) or 0
  Look.FitText(E.tally, Fmt(L.POSTER_RELEASED_N, { times = Look.Times(n) }), GF.FIT_TALLY)
  local info, opt = wipe(scratchInfo), wipe(optInfo)
  local who = Look.Join(h.level and Fmt(L.POSTER_LEVEL, { level = h.level }), ClassName(h))
  if who ~= "" then info[#info + 1] = who end
  if type(h.why) == "string" and h.why ~= "" then info[#info + 1] = Fmt(L.HUNT_REASON, { reason = h.why }) end
  local names = type(h.names) == "table" and h.names or {}
  if #names > 0 then info[#info + 1] = Fmt(L.POSTER_RELEASED_BY, { names = Look.NameList(names, 2) }); opt[#info] = true end
  -- 1.2.1: posted bounty and "avenged by" before the sighting; when room is short they give way after "called by"
  local brows, bsum = GF.BountyRows(h.key)
  local bline = GF.BountyLine(brows, bsum)
  local bidx, aidx
  if bline then info[#info + 1] = bline; bidx = #info; opt[#info] = true end
  local aline, arows = GF.AvengedLine(h.key)
  if aline then info[#info + 1] = aline; aidx = #info; opt[#info] = true end
  local ls = type(h.lastSeen) == "table" and h.lastSeen or nil
  local ago = ls and Look.Ago(ls.t)
  if ago then
    info[#info + 1] = GF.SeenBy(ago, ls.by)
  elseif Look.GuildSetting("sightings") == true then
    info[#info + 1] = L.POSTER_NOT_SEEN
  end
  SetInfo(E, info, opt)
  GF.PlaceBountyLine(E, bidx, brows, aidx, arows, bsum)
  local bag = tonumber(h.bagged) or 0
  E.bountyLabel:SetText(Spaced(L.POSTER_TAKEN_DOWN))
  SetBounty(E, bag > 0 and Look.Times(bag) or L.POSTER_NOT_YET, bag <= 0)
  E.bounty:SetTextColor(C(Look.INK))
  PlaceBounty(E, false)
  E.bountyHit.key, E.bountyHit.tip = nil, nil
  E.bountyHit:Hide()
  GF.BountySlot(E, h.key)
  E.fileLabel:SetText(Spaced(L.POSTER_CALLS))
  FillLines(E, type(h.releases) == "table" and h.releases or {}, UX.HuntLine, UX.HuntTip, L.POSTER_NOBODY_LEFT)
  E.noteLabel:SetText(Spaced(L.POSTER_LAST))
  if E.note:HasFocus() then E.note:ClearFocus() end
  E.note.key = nil
  E.note:Hide()
  local lb = type(h.lastBagged) == "table" and h.lastBagged or nil
  local taken = lb and Fmt(L.POSTER_TAKEN_BY, { name = Look.First(lb.by), time = Look.Ago(lb.t) }) or L.POSTER_TAKEN_NOBODY
  E.victims:SetText(taken)
  E.victims:Show()
  -- 1.2.2: the whole sentence with full name and time always in the tooltip (truncated with long first names and the
  -- wide label in ruRU/ukUA; with two anchors only the client knows whether it is truncated)
  -- (the shown sentence with the full name, then the exact time)
  E.victimsHit.tip = lb and { Fmt(L.POSTER_TAKEN_BY, { name = tostring(lb.by), time = Look.Ago(lb.t) }), Look.When(lb.t) } or { taken }
  E.victimsHit:Show()
  GF.ShowStamp(E.stampNr1, false)
  GF.Stamp(E.stampOther, "hunt")
  GF.ShowStamp(E.stampOther, true)
  GF.ShowStamp(E.stampRache, false)
  E.racheCount:Hide()
  E.strike.key = nil
  E.strike:Hide()
  -- 1.2.0: no word below the photo (the stamp ON THE HIT LIST would lie on it); "Hide for
  -- me" is in the row menu
  E.hunt.key, E.hunt.hide = nil, nil
  E.hunt:Hide()
  local sig = "h\0" .. h.key .. "\0" .. (Store().Get(h.key) and "1" or "0") .. (GF.Released(h.key) and "1" or "0")
    .. (h.hidden and "1" or "0")
  if E.specSig ~= sig then
    E.specSig = sig
    ConfigButtons(E, GF.HuntSpec(h))
  end
end

-- accomplices of a death: from the deed at the killer (others), otherwise the candidates without the killer
local assistScratch = {}
function UX.AssistsOf(d)
  local out = wipe(assistScratch)
  local e = d.killerKey and Store().Get(d.killerKey)
  if e and type(e.deaths) == "table" then
    for i = 1, #e.deaths do
      local x = e.deaths[i]
      if x.t == d.t and type(x.others) == "table" then
        for k = 1, #x.others do out[#out + 1] = x.others[k] end
        return out
      end
    end
  end
  if type(d.candidates) == "table" then
    for i = 1, #d.candidates do if d.candidates[i] ~= d.killerKey then out[#out + 1] = d.candidates[i] end end
  end
  return out
end

local function FillDeath(d, index)
  local D = P.death
  D.when:SetText(Look.When(d.t))
  local place = PlaceText(d.zone, d.subzone)
  if type(d.x) == "number" and type(d.y) == "number" then
    place = place .. (" (%d, %d)"):format(math.floor(d.x + 0.5), math.floor(d.y + 0.5))
  end
  local info = { place }
  if d.me then info[#info + 1] = GF.VictimLine(d.me, d.myLevel) end
  if d.spell and d.spell ~= "" then info[#info + 1] = Fmt(L.TIP_CAUSE, { spell = tostring(d.spell) }) end
  if d.counted == false then info[#info + 1] = L.CASE_NOT_COUNTED end
  D.info:SetText(table.concat(info, "\n"))

  D.killer.key = nil
  local cands = (type(d.candidates) == "table") and d.candidates or {}
  if d.kind == "pvp" and d.killerKey then
    D.killLabel:SetText(Spaced(d.sure == false and L.CASE_KILLER_SUSPECT or L.CASE_KILLER))
    local name, e = NameOfKey(d.killerKey, d.killerName)
    Look.FitText(D.killer.text, name, GF.FIT_NAME26)
    D.killer.key = e and d.killerKey or nil
    D.note:SetText(e and L.CASE_CLICK_NAME or L.CASE_GONE)
  elseif d.kind == "pvp" then
    D.killLabel:SetText(Spaced(L.CASE_KILLER_UNCLEAR))
    Look.FitText(D.killer.text, "?", GF.FIT_NAME26)
    D.note:SetText(#cands > 0 and L.CASE_SEVERAL or L.CASE_NOBODY)
  elseif d.kind == "pve" then
    D.killLabel:SetText(Spaced(L.CASE_HOW))
    Look.FitText(D.killer.text, L.ROW_NO_PLAYER, GF.FIT_NAME26)
    D.note:SetText(L.CASE_PVE)
  else
    D.killLabel:SetText(Spaced(L.CASE_HOW))
    Look.FitText(D.killer.text, L.CASE_UNCLEAR, GF.FIT_NAME26)
    D.note:SetText(L.CASE_DARK)
  end

  -- set the killer (open or suspicion only), otherwise those involved
  local showC = (d.kind == "pvp") and d.sure ~= true and #cands > 0 and Store().AssignDeath ~= nil
  D.candLabel:SetShown(showC)
  local nc = showC and #cands or 0
  for i = 1, GF.CAND_MAX do
    local b, key = D.cands[i], showC and cands[i]
    b.tip = nil
    if i == GF.CAND_MAX and nc > GF.CAND_MAX then
      -- more candidates than buttons: the last one names the rest in the tooltip
      local rest = { L.TIP_MORE_CANDIDATES }
      for k = GF.CAND_MAX, nc do rest[#rest + 1] = (NameOfKey(cands[k])) end
      b:SetLabel(Fmt(L.MORE_LINE, { count = nc - GF.CAND_MAX + 1 }))
      b.fn = nil
      b.tip = rest
      b:Show()
    elseif key then
      b:SetLabel((NameOfKey(key)))
      -- look up the position only on click: a new death in between shifts the journal
      b.fn = function()
        local list = Store().Deaths() or {}
        local at = index
        for k = 1, #list do if list[k] == d then at = k; break end end
        Store().AssignDeath(at, key)
      end
      b:Show()
    else
      b:Hide()
    end
  end
  local assists = (not showC and d.kind == "pvp" and d.killerKey) and UX.AssistsOf(d) or assistScratch
  if showC or not (d.kind == "pvp" and d.killerKey) then wipe(assistScratch) end
  local na = #assists
  D.assistLabel:SetShown(na > 0)
  for i = 1, GF.ASSIST_MAX do
    local b, key = D.assists[i], assists[i]
    if i == GF.ASSIST_MAX and na > GF.ASSIST_MAX then
      b.text:SetText(Fmt(L.MORE_LINE, { count = na - GF.ASSIST_MAX + 1 }))
      b.key = nil
      b:Show()
    elseif key then
      local name, e = NameOfKey(key)
      b.text:SetText(name)
      b.key = e and key or nil
      b:Show()
    else
      b.key = nil
      b:Hide()
    end
  end
  -- only for suspicion does it say what it is based on
  D.source:SetText(d.source == "suspect" and L.CASE_SOURCE_SUSPECT or "")
  -- height of the file from the stack: place, killer, note, then candidates or accomplices
  local y = 62 + Look.TextH(D.info, #info) + 16 + 12 + 2 + 32 + 2 + Look.TextH(D.note, 2)
  if nc > 0 then y = y + 14 + 12 + 6 + math.ceil(math.min(nc, GF.CAND_MAX) / 2) * 28
  elseif na > 0 then y = y + 14 + 12 + 2 + math.min(na, GF.ASSIST_MAX) * 20 end
  D.page:Layout(math.ceil(y + 6 - 54))
  if D.ref ~= d then D.ref = d; D.page:Top() end
end

-- Journal, Unsolved and Guild: Enter only searches, never adds an entry
local function SearchOnly() return state.filter ~= "wanted" end

local function EmptyKind()
  if state.query ~= "" then return SearchOnly() and "searchro" or "search" end
  if state.filter == "guild" then
    local src = GF.Src()
    if src == "guild" then
      if not GCall("Name") then return "noguild" end
      if GCall("Enabled") == false then return "guildoff" end
      if GF.HuntView() then return "hunt" end
      if MemberCount() == 0 then return "guildnil" end
      return "guildquiet"
    elseif src == "friends" then
      if not GF.FriendsOn() then return "friendsoff" end
      if GF.HuntView() then return "hunt" end
      if MemberCount() == 0 then return "friendsnil" end
      return "friendsquiet"
    end
    local g = GCall("Name") ~= nil and GCall("Enabled") ~= false
    if not g and (not GF.FriendsOn() or GF.nobody) then return "nobody" end
    if GF.HuntView() then return "hunt" end
    if MemberCount() == 0 then return "sharednil" end
    return "sharedquiet"
  end
  return state.filter
end

-- index card (file) or poster: thumbtack only on the poster, tape on the card
local function PosterMode(card)
  P.pin:SetShown(not card)
  if card and P.dnPin then P.dnPin:Hide() end
  P.card:SetShown(card)
end

function UX.ShowCaseOrEnemy(item, index)
  if IsCase(item) then
    PosterMode(true)
    FillDeath(item, index)
    P.death:Show()
  else
    PosterMode(false)
    FillEnemy(item)
    P.enemy:Show()
  end
end

------------------------------------------------------------------------
-- 1.3.0 Rap sheet (fifth tab): on the left the victims (rows of the same pool), on the right the own file, the list of
-- the latest kills ("Show more") or the sheet of one victim. Built on the first visit; reads Ledger.Victims, .Log,
-- .Repute, .Victim, .Standing only (never writes into what they return).
------------------------------------------------------------------------
RS.SORTS = { "recent", "state", "points", "count", "name" }
RS.LOG_LINES = 60          -- Ledger.LOG_MAX: one line per kill of the log
RS.KILL_LINES = 8          -- kill lines on a victim sheet
RS.FIT_TITLE = { sizes = { 26, 22, 19 }, lines = 2, wrapFirst = 3 }
RS.FIT_LINE = { sizes = { 11, 10 }, lines = 2, wrapFirst = true }
RS.FIT_ONE = { sizes = { 11, 10 } }
RS.FIT_SCORE = { sizes = { 26, 22, 19 } }
RS.FIT_BTN = { sizes = { 10, 9 } }
RS.PATHS = { "r", "e", "j", "s" }
RS.TAG = { { "n", "KILL_TAG_KICK" }, { "v", "KILL_TAG_REVENGE" }, { "g", "KILL_TAG_GROUP" } }   -- flag, locale key

-- the tab is there whenever the rap sheet is kept (1.3.1: also before the first own kill; hidden until then,
-- nobody found it after the update)
function RS.On()
  local Lg = ns.Ledger
  if not (Lg and Lg.Enabled and Lg.Victims and Lg.Repute) or not Lg.Enabled() then return false end
  return true
end

-- the one place that forms the name of a victim (never from its key: "Name-Realm#1A2B" of a second namesake)
function RS.Name(v)
  if type(v) ~= "table" or type(v.name) ~= "string" then return "?" end
  if type(v.surname) == "string" and v.surname ~= "" then return v.name .. " " .. v.surname end
  return v.name
end
-- the book entry of a victim (a key of the rap sheet alone, "…#…", never goes to the book)
function RS.Book(v)
  if type(v) ~= "table" or type(v.key) ~= "string" or v.key:find("#", 1, true) then return nil end
  return Store().Get(v.key)
end

-- "+3 Honour, +2 Hunt" of a log row, or "no points"
function Look.KillPoints(row)
  local out = {}
  for _, p in ipairs(RS.PATHS) do
    local n = tonumber(row[p]) or 0
    if n > 0 then out[#out + 1] = Fmt(L.RECORD_POINTS, { points = n, path = ns.Ranks and ns.Ranks.PathWord(p) or p }) end
  end
  return #out > 0 and table.concat(out, ", ") or L.RECORD_NO_POINTS
end
Look.BAND_KEY = { grau = "BAND_GRAU", gruen = "BAND_GRUEN", gelb = "BAND_GELB", orange = "BAND_ORANGE", rot = "BAND_ROT",
  schaedel = "BAND_SCHAEDEL", unbekannt = "BAND_UNBEKANNT" }      -- band id (Ledger.BANDS) -> locale key
function Look.BandWord(b) return L[Look.BAND_KEY[b] or "BAND_UNBEKANNT"] end
function RS.Level(lv) return type(lv) == "number" and Fmt(L.POSTER_LEVEL, { level = lv }) or L.ALERT_LEVEL_UNKNOWN end
function RS.Tag(f)
  if type(f) ~= "string" then return nil end
  for _, t in ipairs(RS.TAG) do if f:find(t[1], 1, true) then return L[t[2]] end end
end
-- "12 s", "4 min", "3 h"
function RS.Duration(s)
  s = math.max(0, math.floor(tonumber(s) or 0))
  if s < 120 then return Fmt(L.DUR_SECONDS, { count = s }) end
  if s < 7200 then return Fmt(L.DUR_MINUTES, { count = math.floor(s / 60 + 0.5) }) end
  return Fmt(L.DUR_HOURS, { count = math.floor(s / 3600 + 0.5) })
end

-- the left page: a row per victim; the score at the right (red while he still leads)
function RS.Sub(v)
  local ago = Look.Ago(v.last)
  local last = ago and Fmt(L.ROW_LAST, { text = ago }) or nil
  return Look.Join(last, v.zone), last or ""
end
function RS.BindRow(r, v)
  SetRowMode(r, "normal")
  SetRank(r, nil)
  r.skull:Hide(); r.strike:Hide(); r.coin:Hide()
  Look.ClassIcon(r.icon, v.class)
  r.icon:Show()
  local m, h, score = Look.Stand(v.key)
  local full, short = RS.Sub(v)
  local e = RS.Book(v)
  local lead = m and e ~= nil and Look.ScoreState(m, h, e.status) == "open"
  local sub = r.rsSub or {}
  r.rsSub = sub
  sub[1], sub[2] = full, short
  SetRow(r, RS.Name(v), sub, score, "normal", not lead)
  r.tipFn = RS.RowTip
  r.under:SetShown(state.rsel == v.key)
  r.under:SetWidth(InkWidth(r.name))
end
function RS.RowTip(v)
  local t = { RS.Name(v) }
  local who = Look.Join(type(v.level) == "number" and Fmt(L.POSTER_LEVEL, { level = v.level }) or nil, ClassName(v), v.guild)
  if who ~= "" then t[#t + 1] = who end
  t[#t + 1] = (RS.Sub(v))
  local m, h, score = Look.Stand(v.key)
  if m then t[#t + 1] = Look.Join(Fmt(L.STAND_LINE, { score = score }), Fmt(L.STAND_TIP, { mine = m, his = h })) end
  t[#t + 1] = Fmt(L.VICTIM_POINTS, { points = tonumber(v.pts) or 0 })
  return t
end

-- index card on the right page: head at the top, body that scrolls (card coordinates as the case file), foot with a
-- word at the bottom right and room for one button at the bottom left
function RS.Card(R)
  local C = CreateFrame("Frame", nil, R)
  C:SetAllPoints()
  C:Hide()
  C.head = Look.Text(C, "head", 26, Look.INK)
  C.head:SetPoint("TOPLEFT", 24, -16)
  C.head:SetWidth(220)
  C.head:SetJustifyH("LEFT")
  C.headHit = CreateFrame("Button", nil, C)
  C.headHit:SetAllPoints(C.head)
  Look.TipIfCut(C.headHit, C.head)
  C.right = Look.Text(C, "type", 11, Look.INK)
  C.right:SetPoint("TOPRIGHT", -24, -28)
  C.right:SetJustifyH("RIGHT")
  Rule(C, -52, 24, 24, 0.7)
  C.page = Look.Page(C, { top = 54, foot = 46, w = 352, h = 452, paper = "paper" })
  local S = CreateFrame("Frame", nil, C.page.body)
  S:SetPoint("TOPLEFT", C.page.body, "TOPLEFT", 0, 54)
  S:SetSize(352, 452)
  C.sheet = S
  C.word = WordButton(C.page.foot, "", "hand", 13)
  C.word:SetPoint("BOTTOMRIGHT", -20, 11)
  C.word:SetSize(120, 20)
  C.word.text:SetWidth(120)
  C.word.text:SetJustifyH("RIGHT")
  C.word.text:ClearAllPoints()
  C.word.text:SetPoint("RIGHT", 0, 0)
  Look.TipIfCut(C.word, C.word.text)
  return C
end
function RS.Text(parent, kind, size, tone)
  local fs = Look.Text(parent, kind or "type", size or 11, Look.INK)
  fs:SetWidth(304)
  fs:SetJustifyH("LEFT")
  if tone then fs:SetTextColor(C(Look.INK, tone)) end
  return fs
end
-- an invisible area over a text with its own tooltip lines (tipFn(self) -> lines); a cut text shows whole there too
function RS.Hit(parent, fs, tipFn)
  local b = CreateFrame("Button", nil, parent)
  b:SetAllPoints(fs)
  b.tipFn = tipFn
  b:SetScript("OnEnter", function(self) local t = self.tipFn and self.tipFn(self); if t then Tip(self, t) end end)
  b:SetScript("OnLeave", GameTooltip_Hide)
  Look.TipShows(b, fs)
  return b
end
-- a kill line (log, victim sheet): text with its tag at the right, tooltip with everything
function RS.Line(parent, y)
  local b = CreateFrame("Button", nil, parent)
  b:SetSize(312, 16)
  b:SetPoint("TOPLEFT", 20, y)
  b.text = Look.Text(b, "hand", 13, Look.INK)
  b.text:SetPoint("LEFT", 0, 0)
  b.text:SetWidth(312)
  b.text:SetJustifyH("LEFT")
  b.text:SetWordWrap(false)
  b.tag = Look.Text(b, "hand", 13, Look.INK)
  b.tag:SetPoint("RIGHT", 0, 0)
  b.tag:SetJustifyH("RIGHT")
  b.tag:SetTextColor(C(Look.INK, TONE.sub))
  b:SetScript("OnEnter", DeedEnter)
  b:SetScript("OnLeave", GameTooltip_Hide)
  Look.TipShows(b, b.text)
  b:Hide()
  return b
end
RS.FIT_KILL = { sizes = { 13, 11 } }
function RS.SetLine(b, text, tag, row, tipFn)
  b.tag:SetText(tag or "")
  local w = tag and math.floor(312 - TextWidth(b.tag, 60) - 10) or 312
  if b.tagged ~= w then b.tagged = w; b.text:SetWidth(w) end
  -- 13 pt, else 11 pt, else cut with the whole line (and more) in the tooltip
  Look.FitText(b.text, text or "", RS.FIT_KILL)
  b.tipItem, b.tipFn = row, tipFn
  b:Show()
end
function RS.LogTip(row)
  local t = { Look.When(row.t), tostring(row.name or "?") }
  t[#t + 1] = Look.Join(RS.Level(row.vl), Look.BandWord(row.band))
  t[#t + 1] = Look.KillPoints(row)
  local tag = RS.Tag(row.f)
  if tag then t[#t + 1] = tag end
  if type(row.zone) == "string" and row.zone ~= "" then t[#t + 1] = Fmt(L.VICTIM_SCENE, { zone = row.zone, time = Look.Ago(row.t) or "?" }) end
  if row.me and row.me ~= Look.Me() then t[#t + 1] = "(" .. Look.First(row.me) .. ")" end
  return t
end

function RS.Build()
  local R = CreateFrame("Frame", nil, P)
  R:SetAllPoints()
  R:Hide()
  P.record = R

  -- own file
  local F = RS.Card(R)
  R.file = F
  Look.FitText(F.head, L.RECORD_HEAD, GF.FIT_NAME26)
  local S = F.sheet
  F.title = Look.Text(S, "head", 26, Look.INK)
  F.title:SetPoint("TOP", 0, -62)
  F.title:SetWidth(304)
  F.title:SetJustifyH("CENTER")
  F.titleHit = RS.Hit(S, F.title, RS.TitleTip)
  F.line = Look.Text(S, "type", 11, Look.INK)
  F.line:SetWidth(304)
  F.line:SetJustifyH("CENTER")
  F.line:SetTextColor(C(Look.INK, TONE.sub))
  F.nums = Look.Text(S, "type", 10, Look.INK)
  F.nums:SetTextColor(C(Look.INK, TONE.sub))
  F.nums:SetJustifyH("RIGHT")
  F.track = S:CreateTexture(nil, "ARTWORK")
  F.track:SetSize(304, 8)
  F.track:SetColorTexture(C(Look.INK, 0.14))
  F.fill = S:CreateTexture(nil, "ARTWORK", nil, 1)
  F.fill:SetHeight(8)
  F.fill:SetPoint("LEFT", F.track, "LEFT", 0, 0)
  F.fill:SetColorTexture(C(Look.RED, 0.8))
  F.barHit = CreateFrame("Button", nil, S)
  F.barHit:SetPoint("TOPLEFT", F.track, "TOPLEFT", 0, 14)
  F.barHit:SetPoint("BOTTOMRIGHT", F.track, "BOTTOMRIGHT", 0, -2)
  F.barHit:SetScript("OnEnter", function(self) if self.tip then Tip(self, self.tip) end end)
  F.barHit:SetScript("OnLeave", GameTooltip_Hide)
  F.next = RS.Text(S, "type", 11)
  F.nextHit = RS.Hit(S, F.next, function() return { F.next.full or F.next:GetText() } end)
  -- needle: words at both ends, a line between them, a tick in the middle, the triangle and the value
  F.low = Look.Text(S, "body", 10, Look.INK)
  F.low:SetTextColor(C(Look.INK, TONE.sub))
  F.high = Look.Text(S, "body", 10, Look.INK)
  F.high:SetTextColor(C(Look.INK, TONE.sub))
  F.scale = S:CreateTexture(nil, "ARTWORK")
  F.scale:SetHeight(1)
  F.scale:SetColorTexture(C(Look.INK, 0.55))
  F.tick = S:CreateTexture(nil, "ARTWORK")
  F.tick:SetSize(1, 7)
  F.tick:SetColorTexture(C(Look.INK, 0.55))
  F.tick:SetPoint("CENTER", F.scale, "CENTER", 0, 0)
  F.needle = Tri(S, 10, -1.5708)
  F.value = Look.Text(S, "body", 10, Look.INK)
  F.needleHit = CreateFrame("Button", nil, S)
  F.needleHit:SetPoint("TOPLEFT", F.low, "TOPLEFT", 0, 4)
  F.needleHit:SetPoint("BOTTOMRIGHT", F.high, "BOTTOMRIGHT", 0, -14)
  F.needleHit:SetScript("OnEnter", function(self) Tip(self, { L.RECORD_NEEDLE_TIP, self.value }) end)
  F.needleHit:SetScript("OnLeave", GameTooltip_Hide)
  F.acc = RS.Text(S, "type", 11)
  F.accHit = RS.Hit(S, F.acc, RS.AccTip)
  F.kills = RS.Text(S, "type", 11)
  F.killsHit = RS.Hit(S, F.kills, RS.BandTip)
  F.best = RS.Text(S, "type", 11)
  F.bestHit = RS.Hit(S, F.best, function() return { F.best.full or F.best:GetText() } end)
  F.awardLabel = Label(S, L.RECORD_AWARDS)
  F.awardRule = S:CreateTexture(nil, "ARTWORK")
  F.awardRule:SetHeight(1)
  F.awardRule:SetColorTexture(C(Look.INK, 0.45))
  F.awardCount = Look.Text(S, "body", 10, Look.INK)
  F.awardCount:SetTextColor(C(Look.INK, TONE.sub))
  F.awards = {}
  for i = 1, #((ns.Ledger and ns.Ledger.AWARDS) or {}) do
    local b = CreateFrame("Button", nil, S)
    b:SetSize(20, 20)
    b.tex = b:CreateTexture(nil, "ARTWORK")
    b.tex:SetAllPoints()
    Look.Skin(b.tex, "coin")
    b.tex:SetDesaturated(true)
    b:SetScript("OnEnter", function(self) if self.tip then Tip(self, self.tip) end end)
    b:SetScript("OnLeave", GameTooltip_Hide)
    F.awards[i] = b
  end
  F.word.fn = function() state.rview = "log"; ShowRight() end
  F.word:SetScript("OnClick", function(self) Look.Sound("click"); if self.fn then self.fn() end end)

  -- latest kills
  local G = RS.Card(R)
  R.log = G
  Look.FitText(G.head, L.RECORD_LOG_HEAD, GF.FIT_NAME26)
  G.lines = {}
  for i = 1, RS.LOG_LINES do G.lines[i] = RS.Line(G.sheet, -62 - (i - 1) * 16) end
  G.empty = RS.Text(G.sheet, "hand", 13, TONE.sub)
  G.empty:SetPoint("TOPLEFT", 20, -62)
  G.word:SetScript("OnClick", function() Look.Sound("click"); state.rview = "file"; ShowRight() end)

  -- one victim
  local V = RS.Card(R)
  R.vic = V
  V.head:SetWidth(230)
  V.headHit:SetScript("OnClick", function(self) if self.key and Store().Get(self.key) then UI.ShowEnemy(self.key) end end)
  V.score = Look.Text(V, "hand", 26, Look.INK)
  V.score:SetPoint("TOPRIGHT", -24, -16)
  V.score:SetJustifyH("RIGHT")
  V.score:SetWidth(80)
  V.scoreHit = RS.Hit(V, V.score, function(self) return self.tip end)
  local VS = V.sheet
  V.who = RS.Text(VS, "type", 11)
  V.state = Look.Text(VS, "body", 10, Look.RED_INK)
  V.state:SetWidth(304)
  V.state:SetJustifyH("LEFT")
  V.note = RS.Text(VS, "type", 11, TONE.sub)
  V.sum = RS.Text(VS, "type", 11)
  V.scene = RS.Text(VS, "type", 11)
  V.seen = RS.Text(VS, "type", 11)
  for _, k in ipairs({ "who", "note", "sum", "scene", "seen" }) do
    local fs = V[k]
    V[k .. "Hit"] = RS.Hit(VS, fs, function() return { fs.full or fs:GetText() } end)
  end
  V.label = Label(VS, L.VICTIM_KILLS_LABEL)
  V.rule = VS:CreateTexture(nil, "ARTWORK")
  V.rule:SetHeight(1)
  V.rule:SetColorTexture(C(Look.INK, 0.45))
  V.rule:SetPoint("TOPLEFT", V.label, "BOTTOMLEFT", -4, -2)
  V.rule:SetWidth(312)
  V.lines = {}
  for i = 1, RS.KILL_LINES do V.lines[i] = RS.Line(VS, 0) end
  V.strike = InkButton(V.page.foot, "", 132, 22, function(self)
    local v = self.key and ns.Ledger.Victim(self.key)
    if v then Confirm("DEATHNOTE_VICTIM_STRIKE", RS.Name(v), self.key) end
  end)
  V.strike:SetPoint("BOTTOMLEFT", 20, 10)
  -- the button grows with its label (132 to 200 px), the word at the right keeps its room
  V.strike:SetWidth(math.max(132, math.min(200, math.ceil((GF.MeasureAt(V.strike.text, L.ACT_VICTIM_STRIKE, 10) or 120) + 16))))
  V.strike:SetLabel(L.ACT_VICTIM_STRIKE)
  V.word:SetScript("OnClick", function() Look.Sound("click"); state.rsel = nil; BindRows(); ShowRight() end)
  for _, X in ipairs({ G, V }) do
    X.word.text:SetText("")
    Look.FitText(X.word.text, L.RECORD_BACK, GF.FIT_STRIKE)
  end
  Look.FitText(F.word.text, L.RECORD_MORE, GF.FIT_STRIKE)
end

-- tooltips of the file
function RS.TitleTip()
  local r = ns.Ledger.Repute()
  local t = { ns.Ranks.Title(r.tier, r.path), Fmt(L.REPUTE_LINE, { tier = r.tier, path = ns.Ranks.PathWord(r.path) }) }
  for _, p in ipairs(RS.PATHS) do
    local s = r.share and tonumber(r.share[p]) or 0
    if s > 0 then t[#t + 1] = ns.Ranks.PathWord(p) .. " " .. math.floor(s * 100 + 0.5) .. " %" end
  end
  return t
end
function RS.AccTip()
  local r = ns.Ledger.Repute()
  local t = {}
  for _, p in ipairs(RS.PATHS) do
    t[#t + 1] = Look.Join(ns.Ranks.PathWord(p) .. " " .. math.floor(tonumber(r.acc[p]) or 0), L["TIP_PATH_" .. p:upper()])
  end
  return t
end
function RS.BandTip()
  local r = ns.Ledger.Repute()
  local t = { L.RECORD_BANDS }
  for _, b in ipairs((ns.Ledger.BANDS) or {}) do
    local n = r.bands and tonumber(r.bands[b]) or 0
    if n > 0 then t[#t + 1] = Look.BandWord(b) .. " " .. n end
  end
  t[#t + 1] = P.record.file.kills.full or P.record.file.kills:GetText()
  return t
end

-- "Last seen: Stranglethorn Vale, 2 hrs ago" (zone of the sighting, written by the tracker every 5 s); the line without
-- the zone as the shorter form
function RS.LastSeen(e)
  local ls = type(e) == "table" and e.lastSeen
  local ago = type(ls) == "table" and Look.Ago(ls.t)
  if not ago then return L.POSTER_NOT_SEEN end
  local short = Fmt(L.POSTER_LAST_SEEN, { time = ago })
  if type(ls.zone) == "string" and ls.zone ~= "" and not Look.Secret(ls.zone) then
    return Fmt(L.POSTER_LAST_SEEN_IN, { zone = ls.zone, time = ago }), short
  end
  return short
end

-- place a text at y (card coordinates) and fit it; returns the y below it
function RS.Put(fs, y, text, fit, gap)
  fs:ClearAllPoints()
  fs:SetPoint("TOPLEFT", 24, -y)
  if not text or text == "" then fs:SetText(""); fs:Hide(); return y end
  fs:Show()
  Look.FitText(fs, text, fit or RS.FIT_LINE)
  return y + Look.TextH(fs, (fit or RS.FIT_LINE).lines or 1) + (gap or 3)
end

function RS.FillFile()
  local F = P.record.file
  local Lg, Rk = ns.Ledger, ns.Ranks
  local r = Lg.Repute()
  local y = 62
  Look.FitText(F.title, Rk.Title(r.tier, r.path), RS.FIT_TITLE)
  y = y + Look.TextH(F.title, 2) + 2
  F.line:ClearAllPoints()
  F.line:SetPoint("TOP", F.sheet, "TOP", 0, -y)
  if Rk.Name(r.tier, r.path) then
    -- the title is a name: the line below says rank and path; else the title is that line already
    Look.FitText(F.line, Fmt(L.REPUTE_LINE, { tier = r.tier, path = Rk.PathWord(r.path) }), RS.FIT_ONE)
    F.line:Show()
    y = y + 14
  else
    F.line:SetText(""); F.line:Hide()
  end
  y = y + 10
  -- the bar from where this rank began to where the next begins
  local total = math.floor(tonumber(r.total) or 0)
  local goal = r.next and (total + math.floor(r.next)) or nil
  local floor0 = tonumber(r.floor) or 0
  F.nums:ClearAllPoints()
  F.nums:SetPoint("TOPRIGHT", F.sheet, "TOPRIGHT", -24, -y)
  F.nums:SetText(goal and (total .. " / " .. goal) or tostring(total))
  y = y + 13
  F.track:ClearAllPoints()
  F.track:SetPoint("TOPLEFT", 24, -y)
  local frac = (goal and goal > floor0) and (total - floor0) / (goal - floor0) or 1
  frac = math.max(0, math.min(1, frac))
  F.fill:SetWidth(math.max(1, math.floor(304 * frac + 0.5)))
  F.fill:SetShown(frac > 0)
  y = y + 12
  local nextName = goal and (Lg.NextRankName() or Rk.Title(r.nextTier, r.nextPath)) or nil
  y = RS.Put(F.next, y, goal and Fmt(L.RECORD_NEXT, { points = math.floor(r.next), rank = nextName }) or L.RECORD_TOP)
  F.barHit.tip = { goal and Fmt(L.RECORD_BAR_TIP, { total = total, goal = goal }) or L.RECORD_TOP, F.next.full or F.next:GetText() }
  y = y + 12
  -- the needle: -100 ruthless .. +100 honourable
  local FIT_END = RS.FIT_END or { sizes = { 10, 9 }, width = 96 }
  RS.FIT_END = FIT_END
  for _, x in ipairs({ { F.low, L.RECORD_NEEDLE_LOW, "TOPLEFT", 24 }, { F.high, L.RECORD_NEEDLE_HIGH, "TOPRIGHT", -24 } }) do
    local fs = x[1]
    fs:SetWidth(96)
    fs:SetJustifyH(x[3] == "TOPLEFT" and "LEFT" or "RIGHT")
    fs:ClearAllPoints()
    fs:SetPoint(x[3], F.sheet, x[3], x[4], -y)
    Look.FitText(fs, x[2], FIT_END)
  end
  local lw, hw = math.min(96, math.ceil(Look.TextW(F.low) or 60)), math.min(96, math.ceil(Look.TextW(F.high) or 60))
  local sw = 304 - lw - hw - 16
  F.scale:ClearAllPoints()
  F.scale:SetPoint("TOPLEFT", F.sheet, "TOPLEFT", 24 + lw + 8, -(y + 6))
  F.scale:SetWidth(sw)
  local needle = math.max(-100, math.min(100, math.floor(tonumber(r.needle) or 0)))
  local x = math.floor(sw * (needle + 100) / 200 + 0.5)
  F.needle:ClearAllPoints()
  F.needle:SetPoint("BOTTOM", F.scale, "TOPLEFT", x, 1)
  F.value:ClearAllPoints()
  F.value:SetPoint("TOP", F.scale, "TOPLEFT", x, -5)
  F.value:SetText(needle > 0 and ("+" .. needle) or tostring(needle))
  F.needleHit.value = Look.Join(L.RECORD_NEEDLE_LOW .. " -100", L.RECORD_NEEDLE_HIGH .. " +100") .. ": " .. F.value:GetText()
  y = y + 34
  -- the accounts, biggest first; kills and victims; best marks
  local order = RS.order or {}
  RS.order = order
  for i, p in ipairs(RS.PATHS) do order[i] = p end
  table.sort(order, function(a, b)
    local va, vb = tonumber(r.acc[a]) or 0, tonumber(r.acc[b]) or 0
    if va ~= vb then return va > vb end
    return a < b
  end)
  local parts = RS.parts or {}
  RS.parts = parts
  for i, p in ipairs(order) do parts[i] = Rk.PathWord(p) .. " " .. math.floor(tonumber(r.acc[p]) or 0) end
  y = RS.Put(F.acc, y, table.concat(parts, " · ", 1, #order))
  y = RS.Put(F.kills, y, Fmt(L.RECORD_KILLS, { kills = tonumber(r.n) or 0, victims = Lg.VictimCount() }))
  local b = r.best or {}
  local best = Look.Join((tonumber(b.gap) or 0) > 0 and Fmt(L.RECORD_BEST_GAP, { count = b.gap }) or nil,
    (tonumber(b.streak) or 0) > 1 and Fmt(L.RECORD_BEST_STREAK, { count = b.streak }) or nil,
    b.quick and Fmt(L.RECORD_BEST_QUICK, { time = RS.Duration(b.quick) }) or nil)
  y = RS.Put(F.best, y, best ~= "" and Fmt(L.RECORD_BEST, { list = best }) or nil)
  -- awards: names and conditions live in Humor.lua (German and English only); other languages show none
  local H = ns.Humor
  local AW = Lg.AWARDS or {}
  local named = H and H.Award and AW[1] and H.Award(AW[1].id)
  F.awardLabel:SetShown(named and true or false)
  F.awardRule:SetShown(named and true or false)
  F.awardCount:SetShown(named and true or false)
  local got = 0
  for i, btn in ipairs(F.awards) do
    local a = AW[i]
    if named and a then
      local t = r.awards and r.awards[a.id]
      local name, cond = H.Award(a.id)
      if t then got = got + 1 end
      btn:ClearAllPoints()
      btn:SetPoint("TOPLEFT", F.sheet, "TOPLEFT", 24 + (i - 1) * 28, -(y + 20))
      btn.tex:SetVertexColor(C(t and Look.COLOR.stampInk or Look.INK, t and 0.9 or 0.22))
      if t then btn.tip = { name, cond, Fmt(L.RECORD_AWARD_AT, { time = Look.When(t) }) }
      elseif a.hidden then btn.tip = { "???", L.RECORD_AWARD_OPEN }
      else btn.tip = { name, cond, L.RECORD_AWARD_OPEN } end
      btn:Show()
    else
      btn:Hide()
    end
  end
  if named then
    F.awardLabel:ClearAllPoints()
    F.awardLabel:SetPoint("TOPLEFT", F.sheet, "TOPLEFT", 24, -(y + 2))
    F.awardRule:ClearAllPoints()
    F.awardRule:SetPoint("TOPLEFT", F.sheet, "TOPLEFT", 20, -(y + 14))
    F.awardRule:SetWidth(312)
    F.awardCount:ClearAllPoints()
    F.awardCount:SetPoint("TOPRIGHT", F.sheet, "TOPRIGHT", -24, -(y + 2))
    F.awardCount:SetText(got .. "/" .. #AW)
    y = y + 20 + 20
  end
  F.right:SetText("")
  F.page:Layout(math.ceil(y + 6 - 54))
end

function RS.FillLog()
  local G = P.record.log
  local log = ns.Ledger.Log() or {}
  local n = math.min(#log, RS.LOG_LINES)
  for i = 1, RS.LOG_LINES do
    local row = log[i]
    if i <= n and type(row) == "table" then
      -- date, victim, points; level and colour in the tooltip
      RS.SetLine(G.lines[i], Look.Join(Look.When(row.t), tostring(row.name or "?"), Look.KillPoints(row)), RS.Tag(row.f), row, RS.LogTip)
    else
      G.lines[i]:Hide()
    end
  end
  G.empty:SetText(n == 0 and L.POSTER_NO_DEEDS or "")
  G.right:SetText("")
  G.page:Layout(math.ceil(62 + math.max(n, 1) * 16 + 6 - 54))
end

function RS.FillVictim(v)
  local V = P.record.vic
  local e = RS.Book(v)
  V.headHit.key = e and v.key or nil
  Look.FitText(V.head, RS.Name(v), GF.FIT_NAME26)
  local m, h, score = Look.Stand(v.key)
  local st = (e and m) and Look.ScoreState(m, h, e.status) or "victim"
  Look.FitText(V.score, score or "", RS.FIT_SCORE)
  V.score:SetTextColor(C(st == "open" and Look.RED or Look.INK))
  V.scoreHit.tip = m and { Fmt(L.STAND_LINE, { score = score }), Fmt(L.STAND_TIP, { mine = m, his = h }) } or nil
  local y = 62
  y = RS.Put(V.who, y, Look.Join(type(v.level) == "number" and Fmt(L.POSTER_LEVEL, { level = v.level }) or nil, ClassName(v), v.guild), RS.FIT_ONE)
  y = y + 5
  V.state:ClearAllPoints()
  V.state:SetPoint("TOPLEFT", 24, -y)
  V.state:SetText(Spaced(L[Look.STATE_WORD[st]] or ""))
  y = y + 14
  y = RS.Put(V.note, y, e and L.CASE_CLICK_NAME or nil)
  y = y + 6
  y = RS.Put(V.sum, y, Look.Join(Fmt(L.VICTIM_KILLED, { times = Look.Times(v.n) }), Fmt(L.VICTIM_POINTS, { points = tonumber(v.pts) or 0 })))
  y = RS.Put(V.scene, y, (type(v.zone) == "string" and v.zone ~= "") and Fmt(L.VICTIM_SCENE, { zone = v.zone, time = Look.Ago(v.last) or "?" }) or nil)
  y = RS.Put(V.seen, y, e and (RS.LastSeen(e)) or nil)
  y = y + 12
  V.label:ClearAllPoints()
  V.label:SetPoint("TOPLEFT", 24, -y)
  y = y + 16
  -- his kills from the log, newest first; the older ones (fallen out of the log) as "… and n more"
  local log, shown = ns.Ledger.Log() or {}, 0
  local more = 0
  for i = 1, #log do
    local row = log[i]
    if type(row) == "table" and row.key == v.key then
      if shown < RS.KILL_LINES then
        shown = shown + 1
        local b = V.lines[shown]
        b:ClearAllPoints()
        b:SetPoint("TOPLEFT", 20, -(y + (shown - 1) * 16))
        RS.SetLine(b, Look.Join(Look.When(row.t), Look.BandWord(row.band), Look.KillPoints(row)), RS.Tag(row.f), row, RS.LogTip)
      else
        more = more + 1
      end
    end
  end
  more = math.max(more, (tonumber(v.n) or 0) - shown)
  if more > 0 and shown == RS.KILL_LINES then
    -- the last line names the rest
    local b = V.lines[shown]
    RS.SetLine(b, Fmt(L.MORE_LINE, { count = more + 1 }), nil, nil, nil)
  elseif more > 0 and shown < RS.KILL_LINES then
    shown = shown + 1
    local b = V.lines[shown]
    b:ClearAllPoints()
    b:SetPoint("TOPLEFT", 20, -(y + (shown - 1) * 16))
    RS.SetLine(b, Fmt(L.MORE_LINE, { count = more }), nil, nil, nil)
  end
  for i = shown + 1, RS.KILL_LINES do V.lines[i]:Hide() end
  V.strike.key = v.key
  V.right:SetText("")
  V.page:Layout(math.ceil(y + math.max(shown, 1) * 16 + 6 - 54))
  if V.ref ~= v.key then V.ref = v.key; V.page:Top() end
end

-- the right page of the tab; returns true when the selection had to be dropped (victim struck meanwhile)
function RS.Show()
  if not P.record then RS.Build() end
  local R = P.record
  local v = state.rsel and ns.Ledger.Victim(state.rsel)
  local dropped = state.rsel ~= nil and not v
  if dropped then state.rsel = nil end
  PosterMode(true)
  R.file:SetShown(not v and state.rview ~= "log")
  R.log:SetShown(not v and state.rview == "log")
  R.vic:SetShown(v and true or false)
  if v then RS.FillVictim(v)
  elseif state.rview == "log" then RS.FillLog()
  else RS.FillFile() end
  R:Show()
  return dropped
end

-- true if ShowRight had to set a selection first (then refresh the rows once)
local picked = false
ShowRight = function()
  if state.panel then return end
  local n = #data
  P.enemy:Hide(); P.death:Hide(); RP.empty:Hide()
  if P.record then P.record:Hide() end
  P:Show()
  if state.filter == "record" then
    -- 1.3.0: the own file, the latest kills or one victim; never the empty page (the file is always there)
    if RS.Show() then picked = true end
  elseif n == 0 then
    ShowEmpty(EmptyKind())
  elseif state.filter == "journal" then
    -- the selection is the entry itself; the position follows it when new deaths slide in before it
    local pos
    if state.deathRef then
      for i = 1, n do if data[i] == state.deathRef then pos = i; break end end
    end
    if not pos and not state.deathRef then
      for i = 1, n do if ((dataIdx and dataIdx[i]) or i) == state.death then pos = i; break end end
    end
    if not pos then pos = 1 end
    picked = picked or state.death ~= ((dataIdx and dataIdx[pos]) or pos)
    state.death = (dataIdx and dataIdx[pos]) or pos
    state.deathRef = data[pos]
    PosterMode(true)
    FillDeath(data[pos], state.death)
    P.death:Show()
  elseif state.filter == "open" then
    local item
    for i = 1, n do
      local x = data[i]
      if x == state.osel or (not IsCase(x) and x.key == state.osel) then item = x; break end
    end
    if not item then item = data[1]; state.osel = IsCase(item) and item or item.key; picked = true end
    local index
    if IsCase(item) then
      local list = Store().Deaths() or {}
      for k = 1, #list do if list[k] == item then index = k; break end end
    end
    UX.ShowCaseOrEnemy(item, index or 1)
  elseif MemberView() then
    -- selected child row (in the same section), otherwise the same killer elsewhere, otherwise the first
    local g, first
    for i = 1, n do
      local w = data[i]
      if not w.head then
        first = first or w
        if w.r.key == state.gselected and (not g or w.m.name == state.gmember) then g = w end
      end
    end
    local entry
    if g then
      entry = g.r.entry or GCall("Get", g.r.key)
    elseif state.gselected then
      entry = GCall("Get", state.gselected)
    end
    if not entry then
      local w = first
      if not w then
        -- everything collapsed: first killer of the first section
        for i = 1, n do
          local m = data[i].m
          local r1 = type(m.rows) == "table" and m.rows[1]
          if r1 then w = { r = r1, m = m }; break end
        end
      end
      if w then
        entry = w.r.entry or GCall("Get", w.r.key)
        state.gselected, state.gmember = w.r.key, w.m.name
        picked = true
      end
    end
    if entry then
      PosterMode(false)
      FillGuild(entry)
      P.enemy:Show()
    else
      ShowEmpty(EmptyKind())
    end
  elseif GF.HuntView() then
    local h
    for i = 1, n do if data[i].key == state.hselected then h = data[i]; break end end
    if not h then h = data[1]; state.hselected = h.key; picked = true end
    PosterMode(false)
    GF.FillHunt(h)
    P.enemy:Show()
  elseif state.filter == "guild" then
    local g
    for i = 1, n do if data[i].key == state.gselected then g = data[i]; break end end
    if not g then g = data[1]; state.gselected = g.key; picked = true end
    PosterMode(false)
    FillGuild(g)
    P.enemy:Show()
  else
    local e
    for i = 1, n do if data[i].key == state.selected then e = data[i]; break end end
    if not e then e = data[1]; state.selected = e.key; picked = true end
    PosterMode(false)
    FillEnemy(e)
    P.enemy:Show()
  end
end

------------------------------------------------------------------------
-- Book size: never larger than the screen, never smaller than readable
------------------------------------------------------------------------
-- pixels per UI unit (nil if the client does not tell)
local function PxPerUnit()
  if not GetPhysicalScreenSize then return nil end
  local ok, _, ph = pcall(GetPhysicalScreenSize)
  local uh = UIParent:GetHeight()
  if not ok or type(ph) ~= "number" or type(uh) ~= "number" or Look.Secret(ph) or Look.Secret(uh) or uh <= 0 then return nil end
  return ph / uh
end

-- largest scale at which the book (with margin) still fits on the screen (at most 150 %)
function UX.MaxScale()
  local w, h = UIParent:GetWidth(), UIParent:GetHeight()
  if type(w) ~= "number" or type(h) ~= "number" or Look.Secret(w) or Look.Secret(h) or w <= 0 or h <= 0 then return 1.5 end
  return math.min(1.5, h / (H + 12), w / (W + 20))
end

-- offered scales: fit on the screen; below 100 % only if a unit then still has 1.4 px
local scaleSteps = {}
function UI.ScaleSteps()
  for i = #scaleSteps, 1, -1 do scaleSteps[i] = nil end
  local max, ppu = UX.MaxScale(), PxPerUnit()
  for _, s in ipairs(Look.SCALES) do
    if s <= max + 0.001 and (s >= 1 or not ppu or ppu * s >= 1.4) then scaleSteps[#scaleSteps + 1] = s end
  end
  if #scaleSteps == 0 then scaleSteps[1] = math.min(1, max) end
  return scaleSteps
end

local function ClampScale(s)
  local steps = UI.ScaleSteps()
  local best = steps[1]
  for i = 1, #steps do if steps[i] <= s + 0.001 then best = steps[i] end end
  return best
end

local function ApplyScale()
  if F then F:SetScale(ClampScale(tonumber(Look.Setting("ui.scale", 1)) or 1)) end
end

-- once: without an own choice the smallest scale from 100 % at which a unit has 1.4 px
function UX.AutoScale()
  if Look.Setting("ui.autoScale") == true then return end
  local cur = tonumber(Look.Setting("ui.scale", 1)) or 1
  local ppu = PxPerUnit()
  if cur == 1 and ppu then
    local steps, pick = UI.ScaleSteps(), nil
    for i = 1, #steps do
      if not pick and steps[i] >= 1 and ppu * steps[i] >= 1.4 then pick = steps[i] end
    end
    pick = pick or steps[#steps]
    if pick and pick ~= cur then Set("ui.scale", pick) end
  elseif cur ~= ClampScale(cur) then
    Set("ui.scale", ClampScale(cur))
  end
  Set("ui.autoScale", true)
end

------------------------------------------------------------------------
-- House rules (sheets Book, Alarm, Guild), manual, back up/import
------------------------------------------------------------------------
local SyncClick, MembersTip, BuildSettings, BuildHelp -- assigned in the block below
do
local BOOK_OPTIONS = {
  { "tooltip",         "OPT_TOOLTIP", true },
  { "ui.minimap.hide", "OPT_MINIMAP", false, invert = true },
}
local ALERT_OPTIONS = {
  { "alert.enabled",   "OPT_ALERT", true },
  { "alert.flash",     "OPT_FLASH", true },
  { "alert.suspects",  "OPT_SUSPECTS", false },
  { "deathMessage",    "OPT_DEATHMSG", true },
}
local GUILD_OPTIONS = {
  { "share",       "OPT_G_SHARE" },
  { "shareManual", "OPT_G_SHAREMANUAL" },
  { "receive",     "OPT_G_RECEIVE" },
  { "alert",       "OPT_G_ALERT" },
  { "alertListed", "OPT_G_ALERTLISTED" },
  { "announce",    "OPT_G_ANNOUNCE" },
  { "sightings",   "OPT_G_SIGHTINGS" },
}
-- 1.2.0 with the friends' book: sharing with friends, hit list alarm; the switches for alarm, message and
-- sightings apply to guild and friends and are named so.
-- 1.2.0: two calm groups SHARE and WARN with the five checkboxes a player needs; everything else
-- (manual entries, receiving, messages, threshold, expiry, status, emptying) behind "More" on a second
-- page of the sheet. Grid 24 px as 1.1.0. No setting is lost, none changes its value.
GF.FRIEND_SHARE = {
  { "share",       "OPT_F_SHARE" },
  { "friends",     "OPT_F_FRIENDS" },
  { "sightings",   "OPT_F_SIGHTINGS" },
}
GF.FRIEND_WARN = {
  { "alert",       "OPT_F_ALERT" },
  { "alertHunt",   "OPT_F_ALERTHUNT" },
}
GF.MORE_SHARE = {
  { "shareManual", "OPT_G_SHAREMANUAL" },
  { "receive",     "OPT_G_RECEIVE" },
}
GF.MORE_WARN = {
  { "alertListed", "OPT_G_ALERTLISTED" },
  { "announce",    "OPT_F_ANNOUNCE" },
  { "announceHunt", "OPT_F_ANNOUNCEHUNT" },   -- 1.2.0 fix: the message taken down / new targets had no switch
}
local SHEETS = { "SHEET_BOOK", "SHEET_ALERT", "SHEET_GUILD", "SHEET_RECORD" }   -- locale key (4th: 1.3.0, the rap sheet)
-- 1.3.0: sheet 4, the rap sheet's switches (the sheets Book and Alarm are full: a row more would make them scroll)
GF.RECORD_OPTIONS = {
  { "ledger.enabled", "OPT_LEDGER", true },
  { "ledger.chat",    "OPT_LEDGER_CHAT", true },
  { "alert.victims",  "OPT_VICTIMS", false },
}
GF.SETTLED = { { "always", "SET_SETTLED_ALWAYS" }, { "quiet", "SET_SETTLED_QUIET" }, { "off", "SET_SETTLED_OFF" } }
function GF.SheetOn(i)
  if i == 3 then return HasGuild() end
  if i == 4 then return type(ns.Ledger) == "table" and type(ns.Ledger.Enabled) == "function" end
  return true
end
GF.SHEET_TOP = 76     -- 1.2.2: head and sheet tabs stand still, the sheet scrolls below them
GF.TIP_NAMES = 12    -- 1.2.2: at most this many names per list in the status line tooltip (before 20 + 20)
GF.SYNC_MIN, GF.SYNC_MAX = 84, 150   -- sync button: grows with its text (1.2.0)
GF.COOLDOWNS = { 30, 60, 90, 120, 180, 300, 600 }
local ROW_Y0, OPT_H = -84, 24

local function Step(list, cur, dir)
  local idx = 1
  for i = 1, #list do if list[i] <= (cur or list[1]) + 0.001 then idx = i end end
  idx = math.max(1, math.min(#list, idx + dir))
  return list[idx]
end

local function PageLayer(parent)
  local f = CreateFrame("Frame", nil, parent)
  f:SetAllPoints()
  f:EnableMouse(true)
  f:Hide()
  local bg = Tex(f, "BACKGROUND", "page")
  bg:SetAllPoints()
  return f
end

local function SheetHead(parent, text)
  local head = Look.Text(parent, "head", 26, Look.INK)
  head:SetPoint("TOP", 0, -16)
  head:SetWidth(PAGE_W - 60)                -- 1.2.2: no wider than the rule under it (x = 30 to PAGE_W - 30)
  Look.FitText(head, text, GF.FIT_NAME26)   -- 1.2.2: 26, 22, 19 pt (REL_HEAD ukUA was wider than the rule)
  Rule(parent, -50, 30, 30, 0.6)
  return head
end

-- arrow to step through values: small ink triangle, click area 22x20, hover red
local function Arrow(parent, dir, onClick)
  local b = CreateFrame("Button", nil, parent)
  b:SetSize(22, 20)
  b.tri = Tri(b, 12, dir < 0 and math.pi or 0)
  b.tri:SetPoint("CENTER", 0, 0)
  b:SetScript("OnEnter", function(self) if not self.off then self.tri:SetVertexColor(C(Look.RED)) end end)
  b:SetScript("OnLeave", function(self) self.tri:SetVertexColor(C(Look.INK, self.off and TONE.off or 0.9)) end)
  b:SetScript("OnClick", function(self) if self.off then return end Look.Sound("click"); onClick() end)
  return b
end

-- row "Label      ◂ value ▸": value in handwriting, underlined; vw = width of the value
GF.FIT_LANG_HINT = { sizes = { 11, 10 }, lines = 2 }
GF.FIT_STEP, GF.FIT_STEP_LABEL = { sizes = { 16, 13, 11 } }, { sizes = { 11, 10 } }
local function Stepper(parent, y, label, onStep, vw)
  vw = vw or 56
  local x = 348 - 44 - vw
  local l = Look.Text(parent, "body", 11, Look.INK)
  l:SetPoint("TOPLEFT", 34, y - 4)
  l:SetWidth(x - 42)
  l:SetJustifyH("LEFT")
  -- 1.2.2: label and value get smaller instead of truncated, the full text is in the tooltip
  Look.FitText(l, label, GF.FIT_STEP_LABEL)
  local function go(d) onStep(d); UI.FillSettings() end
  local minus = Arrow(parent, -1, function() go(-1) end)
  minus:SetPoint("TOPLEFT", x, y)
  local v = Look.Text(parent, "hand", 16, Look.INK)
  v:SetPoint("LEFT", minus, "RIGHT", 0, 0)
  v:SetWidth(vw)
  v:SetJustifyH("CENTER")
  v:SetWordWrap(false)
  v.hit = CreateFrame("Frame", nil, parent)
  v.hit:SetAllPoints(v)
  Look.TipIfCut(v.hit, v)
  local lh = CreateFrame("Frame", nil, parent)
  lh:SetAllPoints(l)
  Look.TipIfCut(lh, l)
  function v:SetValue(t) Look.FitText(self, t, GF.FIT_STEP) end
  local ul = parent:CreateTexture(nil, "ARTWORK")
  ul:SetColorTexture(C(Look.INK, 0.45))
  ul:SetHeight(1)
  ul:SetPoint("TOPLEFT", minus, "BOTTOMRIGHT", 4, 1)
  ul:SetWidth(vw - 8)
  local plus = Arrow(parent, 1, function() go(1) end)
  plus:SetPoint("LEFT", v, "RIGHT", 0, 0)
  v.label, v.minus, v.plus, v.ul = l, minus, plus, ul
  return v
end

-- grey out a row (label, value, arrows); greyed-out arrows do nothing
local function Dim(v, off)
  local a = off and TONE.off or TONE.ink
  v.label:SetTextColor(C(Look.INK, a)); v:SetTextColor(C(Look.INK, a))
  for _, b in ipairs({ v.minus, v.plus }) do
    b.off = off and true or false
    b.tri:SetVertexColor(C(Look.INK, off and TONE.off or 0.9))
  end
end

local function Preview() if Look.Alarm then Look.Alarm("preview") end end

local function Percent(v) return math.floor((tonumber(v) or 1) * 100 + 0.5) .. " %" end

-- "Sync": labels itself after the click from the sharing state
SyncClick = function(b)
  local h = Look.GuildHealth(GF.HasFriends() and GF.Src() or nil)
  local ok, why = GCall("SyncNow")
  -- 1.2.0: friends as well
  if GF.HasFriends() and type(ns.Friends.SyncNow) == "function" then
    local fok, fok2, fwhy = pcall(ns.Friends.SyncNow)
    if fok and fok2 then ok, why = true, nil elseif fok and ok == false and tonumber(fwhy) then why = fwhy end
  end
  if ok == false and tonumber(why) then
    b:SetLabel(Fmt(L.SYNC_AGAIN_IN, { seconds = tonumber(why) }))
  elseif ok == false or not h.ok then
    b:SetLabel(h.short or L.HEALTH_SHORT_FAIL)
  else
    b:SetLabel(L.HEALTH_SHORT_ASKED)
  end
  if b.resetTimer then b.resetTimer:Cancel() end
  b.resetTimer = C_Timer.NewTimer(3, function() b.resetTimer = nil; b:SetLabel(L.SYNC_BUTTON) end)
end

-- guildmates with DeathNote, below that what is shared and what is not
MembersTip = function(owner)
  local name = GCall("Name")
  GameTooltip:SetOwner(owner, "ANCHOR_TOP")
  if GF.Src() == "friends" then
    GameTooltip:SetText(L.TIP_FRIENDS, Look.BONE[1], Look.BONE[2], Look.BONE[3])
  else
    GameTooltip:SetText(name and Fmt(L.TIP_GUILD_NAME, { guild = name }) or L.HEALTH_SHORT_NOGUILD, Look.BONE[1], Look.BONE[2], Look.BONE[3])
  end
  -- 1.2.0: the status already stands in the line below; the tooltip does not repeat it.
  -- 1.2.2: unless the line is truncated (two long names): then the whole sentence first
  if LP and owner == LP.statusHit and Truncated(LP.status) then
    GameTooltip:AddLine(LP.status:GetText() or "", 1, 1, 1, true)
  end
  local src = GF.Src()
  local function list(members, head, none)
    if type(members) == "table" and #members > 0 then
      GameTooltip:AddLine(head, 0.82, 0.80, 0.75)
      for i = 1, math.min(#members, GF.TIP_NAMES) do
        local m = members[i]
        local ago = m.lastHeard and Look.Ago(m.lastHeard) or ""
        GameTooltip:AddDoubleLine(tostring(m.name or "?") .. (m.version and ("  " .. tostring(m.version)) or ""), ago,
                                  1, 1, 1, 0.7, 0.7, 0.7)
      end
      if #members > GF.TIP_NAMES then GameTooltip:AddLine(Fmt(L.MORE_LINE, { count = #members - GF.TIP_NAMES }), 0.7, 0.7, 0.7) end
    else
      GameTooltip:AddLine(none, 0.82, 0.80, 0.75)
    end
  end
  if src ~= "friends" then list(GCall("Members"), L.TIP_MATES_WITH, L.TIP_NO_MATE) end
  if src ~= "guild" and GF.HasFriends() then
    list(GCall("Members", "friends"), L.TIP_FRIENDS_WITH, L.EMPTY_FRIENDSNIL_HEAD)
  end
  GameTooltip:AddLine(L.TIP_SHARED, 0.7, 0.7, 0.7, true)
  GameTooltip:AddLine(L.TIP_NOT_SHARED, 0.7, 0.7, 0.7, true)
  GameTooltip:Show()
end

BuildSettings = function()
  local S = PageLayer(RP)
  RP.settings = S
  SheetHead(S, L.HEAD_RULES)

  -- sheets: Book | Alarm | Guild (the third only if the guild feature exists)
  S.tabs = {}
  -- 1.2.0: width from the word (70 to 96 px, at least 70 px as 1.1.0), 28 px gap. 1.3.0: with four sheets 50 to 96 px
  -- and 16 px gap; if even that is wider than the rule (320 px), all get narrower alike and the word 10 pt (tooltip)
  local prevTab
  local on, ws, total = {}, {}, 0
  for i = 1, #SHEETS do if GF.SheetOn(i) then on[#on + 1] = i end end
  local four = #on >= 4
  local minW, gap = four and 50 or 70, four and 16 or 28
  for i, key in ipairs(SHEETS) do
    local t = WordTab(S, L[key], 70, function(self) state.spage = self.page; UI.FillSettings() end)
    ws[i] = math.max(minW, math.min(96, TextWidth(t.text, 60) + 6))
    t:SetWidth(ws[i])
    t.page = i
    S.tabs[i] = t
  end
  for k, i in ipairs(on) do total = total + ws[i] + (k > 1 and gap or 0) end
  local fit = four and total > PAGE_W - 60 and (PAGE_W - 60 - gap * (#on - 1)) / (total - gap * (#on - 1)) or 1
  for _, i in ipairs(on) do
    local t = S.tabs[i]
    if fit < 1 then
      t:SetWidth(math.floor(ws[i] * fit))
      t.text:SetWidth(math.floor(ws[i] * fit) - 4)
      Look.FitText(t.text, L[SHEETS[i]], GF.FIT_WORD)
      Look.TipIfCut(t, t.text)
    end
    if prevTab then t:SetPoint("LEFT", prevTab, "RIGHT", gap, 0) else t:SetPoint("TOPLEFT", 30, -56) end
    prevTab = t
  end

  local function onCheck(self)
    local on = self:GetChecked() and true or false
    self.cross:SetShown(on)
    if self.opt.invert then on = not on end
    Set(self.opt.path, on)
    Look.Sound("click")
  end
  S.checks = {}
  local function checks(page, list, prefix, y0, step)
    y0 = y0 or ROW_Y0
    step = step or OPT_H
    for i, o in ipairs(list) do
      local cb = UX.InkCheck(page, o.text or L[o[2]], 310) -- Humor: o.text (switch without a locale key)
      cb:SetPoint("TOPLEFT", 30, y0 - (i - 1) * step)
      cb.label:SetWidth(280)
      cb.label:SetJustifyH("LEFT")
      cb.label:SetWordWrap(false)
      -- 1.2.2: 11, then 10 pt, otherwise truncated with tooltip
      Look.FitText(cb.label, cb.label:GetText(), GF.FIT_WORD)
      Look.TipIfCut(cb, cb.label)
      if prefix then cb.opt = { path = prefix .. o[1], guild = o[1] }
      else cb.opt = { path = o[1], def = o[3], invert = o.invert } end
      cb:SetScript("OnClick", onCheck)
      S.checks[#S.checks + 1] = cb
    end
    return y0 - #list * step - 4
  end
  local function section(page, y, text)
    local l = Label(page, text)
    l:SetPoint("TOPLEFT", 34, y - 6)
    return y - 22
  end
  -- 1.2.2: the hint is part of the sheet's flow (GF.LayoutSheet): at its old place above the foot bar
  -- as long as the content above ends before it, otherwise below, and the sheet scrolls
  local function hint(page, text)
    local h = Look.Text(page, "type", 11, Look.INK)
    h:SetTextColor(C(Look.INK, TONE.hint))
    h:SetWidth(PAGE_W - 60)
    h:SetJustifyH("LEFT")
    h:SetText(text or "")
    page.hint = h
    return h
  end
  -- sheets lie in the scroll child; their top edge stays the top edge of the page (same coordinates as before)
  S.page = Look.Page(S, { top = GF.SHEET_TOP, foot = 44, w = PAGE_W, h = PAGE_H })
  local function sheet()
    local f = CreateFrame("Frame", nil, S.page.body)
    f:SetPoint("TOPLEFT", S.page.body, "TOPLEFT", 0, GF.SHEET_TOP)
    f:SetSize(PAGE_W, PAGE_H)
    return f
  end

  -- sheet 1: book (display, size, passing on)
  local A = sheet()
  S.pageA = A
  local y = checks(A, ns.Humor and ns.Humor.BookOptions(BOOK_OPTIONS) or BOOK_OPTIONS) -- Humor: switch, de/en only
  S.size = Stepper(A, y, L.SET_BOOK_SIZE, function(d)
    local steps = UI.ScaleSteps()
    Set("ui.scale", Step(steps, ClampScale(tonumber(Look.Setting("ui.scale", 1)) or 1), d))
  end)
  -- 1.2.0: language of the book (takes effect after /reload)
  if ns.Locale and ns.Locale.CODES then
    y = y - OPT_H
    S.lang = Stepper(A, y, L.SET_LANGUAGE, function(d) GF.StepLanguage(d) end, 150)
    y = y - OPT_H
    -- 1.3.0: the cover (theme), same kind of row, the same hint and button (takes effect after /reload)
    if ns.Theme and ns.Theme.List then
      S.theme = Stepper(A, y, L.SET_THEME, function(d) GF.StepTheme(d) end, 150)
      y = y - OPT_H
    end
    S.langHint = Look.Text(A, "type", 11, Look.INK)
    S.langHint:SetTextColor(C(Look.INK, TONE.hint))
    S.langHint:SetPoint("TOPLEFT", 34, y - 6)
    S.langHint:SetWidth(170)
    S.langHint:SetJustifyH("LEFT")
    Look.FitText(S.langHint, L.SET_LANG_RELOAD_HINT, GF.FIT_LANG_HINT)
    S.reload = InkButton(A, L.SET_LANG_RELOAD, 132, 22, function()
      if InCombatLockdown and InCombatLockdown() then return end
      if ReloadUI then ReloadUI() end
    end)
    S.reload:SetPoint("TOPLEFT", 214, y - 2)
  end
  y = y - OPT_H - 6
  y = section(A, y, L.SET_SEC_SHARE)
  local exp = InkButton(A, L.IO_EXPORT, 104, 22, function() UI.OpenIO("export") end)
  exp:SetPoint("TOPLEFT", 30, y - 4)
  local imp = InkButton(A, L.IO_IMPORT, 104, 22, function() UI.OpenIO("import") end)
  imp:SetPoint("LEFT", exp, "RIGHT", 8, 0)
  S.ioButtons = { exp, imp }
  A.bottom = -(y - 4) + 22
  hint(A, L.SET_HINT_BOOK)

  -- sheet 2: alarm with sound, volume and channel
  local AL = sheet()
  AL:Hide()
  S.pageL = AL
  y = checks(AL, ALERT_OPTIONS)
  y = section(AL, y, L.SET_SEC_SOUND)
  S.tone = Stepper(AL, y, L.SET_SOUND, function(d)
    local n = #Look.SOUNDS
    local cur = Look.SoundChoice()
    local idx = 1
    for i, x in ipairs(Look.SOUNDS) do if x.key == cur.key then idx = i end end
    local nxt = Look.SOUNDS[(idx - 1 + d) % n + 1]
    Look.SetSound(nxt.key)
    Preview()
  end, 132)
  y = y - OPT_H
  S.vol = Stepper(AL, y, L.SET_VOLUME, function(d)
    local v = tonumber(Look.Setting("alert.volume", 3)) or 3
    local nv = math.max(1, math.min(Look.VOLUMES, math.floor(v) + d))
    if nv ~= v then Set("alert.volume", nv) end
    Preview()
  end, 120)
  -- volume as five ink bars instead of a number
  S.vol.bars = {}
  for i = 1, Look.VOLUMES do
    local t = AL:CreateTexture(nil, "ARTWORK")
    t:SetSize(9, 12)
    t:SetPoint("LEFT", S.vol.minus, "RIGHT", 32 + (i - 1) * 12, 0)
    t:SetColorTexture(C(Look.INK, 0.85))
    S.vol.bars[i] = t
  end
  y = y - OPT_H
  -- channel: three words, the active one underlined in red
  local kl = Look.Text(AL, "body", 11, Look.INK)
  kl:SetPoint("TOPLEFT", 34, y - 4)
  kl:SetText(L.SET_CHANNEL)
  S.chan = { label = kl }
  -- 1.2.0: word width from the text (at least 52 px); as 1.1.0 from x = 176, moves left for long words
  local total = 0
  for i, ch in ipairs(Look.CHANNELS) do
    local b = WordTab(AL, ch.label or L[ch.lkey], 52, function(self)
      if self.off then return end
      Set("alert.channel", self.channel)
      UI.FillSettings()
      Preview()
    end)
    b:SetWidth(math.max(52, TextWidth(b.text, 48) + 6))
    total = total + b:GetWidth() + (i > 1 and 6 or 0)
    b.channel = ch.key
    S.chan[i] = b
  end
  local cx = math.max(34 + TextWidth(kl, 40) + 12, math.min(176, 348 - total))
  for i, b in ipairs(S.chan) do
    if i == 1 then b:SetPoint("TOPLEFT", cx, y) else b:SetPoint("LEFT", S.chan[i - 1], "RIGHT", 6, 0) end
  end
  y = y - OPT_H
  y = section(AL, y, L.SET_SEC_THRESHOLD)
  S.cd = Stepper(AL, y, L.SET_COOLDOWN, function(d)
    Set("alert.cooldown", Step(GF.COOLDOWNS, Look.Setting("alert.cooldown", 90), d))
  end)
  y = y - OPT_H
  S.mk = Stepper(AL, y, L.SET_MINKILLS, function(d)
    local v = tonumber(Look.Setting("alert.minKills", 1)) or 1
    Set("alert.minKills", math.max(1, math.min(20, v + d)))
  end)
  y = y - OPT_H
  S.asize = Stepper(AL, y, L.SET_ALERT_SIZE, function(d)
    Set("alert.scale", Step(Look.SCALES, tonumber(Look.Setting("alert.scale", 1)) or 1, d))
  end)
  y = y - OPT_H - 6
  local test = InkButton(AL, L.SET_TEST_ALERT, 104, 22, function() ns:Fire("TEST_ALERT") end)
  test:SetPoint("TOPLEFT", 30, y - 4)
  AL.bottom = -(y - 4) + 22
  S.soundHint = hint(AL, "")

  -- sheet 3: guild
  local B = sheet()
  B:Hide()
  S.pageB = B
  -- 1.2.0: with friends, one status line each (full sentence in the tooltip and on the left page), below that
  -- empty the guild book and the friends' book. 1.2.0: page 1 (B1) SHARE and WARN, page 2 (B2) "More".
  local friendsSheet = GF.HasFriends()
  local B2 = B
  local function expireRow(page, yy)
    -- calls expire after never, 30, 90, 180 days (default never)
    S.hexp = Stepper(page, yy, L.SET_HUNT_EXPIRE, function(d)
      local days = (ns.Guild and ns.Guild.C and ns.Guild.C.EXPIRE_DAYS) or { 0, 30, 90, 180 }
      Set("guild.huntExpire", Step(days, tonumber(Look.GuildSetting("huntExpire")) or 0, d))
    end, 84)
    return yy - OPT_H - 4
  end
  local function minKillsRow(page, yy, label)
    S.gmk = Stepper(page, yy, label, function(d)
      local v = tonumber(Look.GuildSetting("minKills")) or 1
      Set("guild.minKills", math.max(1, math.min(20, v + d)))
    end)
    return yy - OPT_H
  end
  if friendsSheet then
    local B1 = CreateFrame("Frame", nil, B)
    B1:SetAllPoints()
    B2 = CreateFrame("Frame", nil, B)
    B2:SetAllPoints()
    B2:Hide()
    S.pageB1, S.pageB2 = B1, B2
    y = section(B1, ROW_Y0 + 6, L.SET_SEC_SHARING)
    y = checks(B1, GF.FRIEND_SHARE, "guild.", y)
    y = section(B1, y - 6, L.SET_SEC_WARN)
    B1.bottom = -checks(B1, GF.FRIEND_WARN, "guild.", y)
    y = section(B2, ROW_Y0 + 6, L.SET_SEC_SHARING)
    y = checks(B2, GF.MORE_SHARE, "guild.", y)
    y = expireRow(B2, y)
    y = section(B2, y - 6, L.SET_SEC_WARN)
    y = checks(B2, GF.MORE_WARN, "guild.", y)
    y = minKillsRow(B2, y, L.SET_F_MINKILLS) - 10
    -- "More": word at the bottom right on both pages, underlined while the second page is open
    S.gmore = WordTab(S.page.foot, L.SET_MORE, 50, function()
      Set("ui.guildMore", Look.Setting("ui.guildMore", false) ~= true)
      UI.FillSettings()
    end)
    S.gmore:SetSize(math.max(50, math.min(110, TextWidth(S.gmore.text, 46) + 6)), 20)
    S.gmore:SetPoint("BOTTOMRIGHT", -30, 13)
  else
    y = checks(B, GUILD_OPTIONS, "guild.")
    y = minKillsRow(B, y, L.SET_G_MINKILLS)
    y = expireRow(B, y)
  end
  y = section(B2, y, L.SET_SEC_STATUS)
  local function statusLine(anchorY, prev)
    local fs = Look.Text(B2, "body", 11, Look.INK)
    if prev then fs:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -3) else fs:SetPoint("TOPLEFT", 34, anchorY) end
    fs:SetWidth(312)
    fs:SetJustifyH("LEFT")
    fs:SetMaxLines(friendsSheet and 1 or 2)
    if friendsSheet then fs:SetWordWrap(false) end
    -- truncated sentence: in full in the tooltip
    local hit = CreateFrame("Button", nil, B2)
    hit:SetAllPoints(fs)
    hit:SetScript("OnEnter", function(self) if Truncated(fs) then Tip(self, { fs:GetText() or "" }) end end)
    hit:SetScript("OnLeave", GameTooltip_Hide)
    fs.tipOwner = hit
    return fs
  end
  S.gstatus = statusLine(y - 2)
  local clearY = y - 36
  if friendsSheet then
    -- second line: status with friends (a sentence of its own, as for the guild)
    S.fstatus = statusLine(nil, S.gstatus)
    clearY = y - 38
  end
  local clear = InkButton(B2, L.SET_GUILD_CLEAR, 132, 22, function() Confirm("DEATHNOTE_GUILD_CLEAR") end)
  clear:SetPoint("TOPLEFT", 30, clearY)
  B2.bottom = -clearY + 22
  if friendsSheet then
    -- 1.2.0: the counterpart for the friends' book (also empties its hit list, own calls stay)
    local fclear = InkButton(B2, L.SET_FRIENDS_CLEAR, 132, 22, function() Confirm("DEATHNOTE_FRIENDS_CLEAR") end)
    fclear:SetPoint("TOPLEFT", 30 + 132 + 10, clearY)
    S.fclear = fclear
  end
  hint(B, friendsSheet and L.SET_HINT_FRIENDS or L.SET_HINT_GUILD)

  -- sheet 4 (1.3.0): the rap sheet: keep it, chat line, victim alarm, alarm when settled, empty it
  local RR = sheet()
  RR:Hide()
  S.pageR = RR
  if GF.SheetOn(4) then
    y = checks(RR, GF.RECORD_OPTIONS)
    S.settled = Stepper(RR, y, L.SET_SETTLED, function(d)
      local cur, idx = Look.Setting("alert.settled", "always"), 1
      for i, x in ipairs(GF.SETTLED) do if x[1] == cur then idx = i end end
      Set("alert.settled", GF.SETTLED[(idx - 1 + d) % #GF.SETTLED + 1][1])
    end, 96)
    y = y - OPT_H - 6
    S.recordClear = InkButton(RR, "", 132, 22, function() Confirm("DEATHNOTE_RECORD_CLEAR") end)
    S.recordClear:SetPoint("TOPLEFT", 30, y - 4)
    S.recordClear:SetWidth(math.max(132, math.min(200, math.ceil((GF.MeasureAt(S.recordClear.text, L.RECORD_CLEAR, 10) or 120) + 16))))
    S.recordClear:SetLabel(L.RECORD_CLEAR)
    RR.bottom = -(y - 4) + 22
  end

  local back = InkButton(S, L.BTN_BACK, 104, 22, function() UI.ClosePanel() end)
  back:SetPoint("BOTTOM", 0, 12)

  -- back up/import
  local IO = PageLayer(RP)
  RP.io = IO
  IO.head = SheetHead(IO, "")
  IO.help = Look.Text(IO, "type", 11, Look.INK)
  IO.help:SetTextColor(C(Look.INK, TONE.hint))
  IO.help:SetPoint("TOP", 0, -58)
  IO.help:SetWidth(330)
  -- 1.2.2: fixed place above the text field: at most two lines (11, then 10 pt), otherwise tooltip
  IO.help:SetMaxLines(2)
  IO.helpHit = CreateFrame("Frame", nil, IO)
  IO.helpHit:SetAllPoints(IO.help)
  Look.TipIfCut(IO.helpHit, IO.help)
  local box = CreateFrame("Frame", nil, IO, "BackdropTemplate")
  box:SetPoint("TOPLEFT", 20, -88)
  box:SetPoint("BOTTOMRIGHT", -20, 70)
  box:SetBackdrop({ bgFile = Look.TEX.white, edgeFile = Look.TEX.white, edgeSize = 1 })
  box:SetBackdropColor(C(Look.COLOR.editFill))
  box:SetBackdropBorderColor(C(Look.INK, 0.6))
  local sf = CreateFrame("ScrollFrame", nil, box, "UIPanelScrollFrameTemplate")
  sf:SetPoint("TOPLEFT", 6, -6)
  sf:SetPoint("BOTTOMRIGHT", -26, 6)
  local eb = CreateFrame("EditBox", nil, sf)
  eb:SetMultiLine(true)
  eb:SetAutoFocus(false)
  eb:SetMaxLetters(0)
  eb:SetWidth(300)
  Look.Font(eb, "body", 11)
  eb:SetTextColor(C(Look.INK))
  eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  sf:SetScrollChild(eb)
  sf:SetScript("OnMouseDown", function() eb:SetFocus() end)
  IO.edit = eb
  IO.msg = Look.Text(IO, "body", 11, Look.RED_INK)
  IO.msg:SetPoint("BOTTOM", 0, 44)
  IO.msg:SetWidth(330)
  IO.go = InkButton(IO, L.IO_GO, 104, 22, function()
    local okc, ok, a, b = pcall(Store().Import, eb:GetText() or "")
    if not okc then ok, a = false, nil end
    if ok then
      IO.msg:SetText(Fmt(L.IO_DONE, { new = tostring(a or 0), merged = tostring(b or 0) }))
      IO.msg:SetTextColor(C(Look.INK))
    else
      IO.msg:SetText(type(a) == "string" and a or L.IO_FAILED)
      IO.msg:SetTextColor(C(Look.RED_INK))
    end
    UI.Refresh()
  end)
  IO.go:SetPoint("BOTTOM", -57, 12)
  -- back up: toggle between the small version (without deeds) and the whole book
  IO.size = InkButton(IO, "", 104, 22, function() UI.ShowExport(not IO.full) end)
  IO.size:SetPoint("BOTTOM", -57, 12)
  IO.size:Hide()
  local close = InkButton(IO, L.BTN_BACK, 104, 22, function() UI.OpenPanel("settings") end)
  close:SetPoint("BOTTOM", 57, 12)
end

-- Manual: on the left the letter-spaced keyword, on the right the paragraph
-- 1.2.2: the head stands still, the paragraphs scroll (mouse wheel, scroll bar only when needed), imprint and button
-- stand in the foot bar. Before, imprint and button hung on the bottom edge of the same page the paragraphs flowed
-- down on: in 11 of 21 languages text lay over text (in game, deDE: imprint over RUHE).
GF.HELP_LABEL_W, GF.HELP_LABEL = 100, { sizes = { 10, 9 }, lines = 2, width = 100 }
GF.HELP_FOOT = { sizes = { 11, 10 }, lines = 2 }
BuildHelp = function()
  local Hp = PageLayer(RP)
  RP.help = Hp
  SheetHead(Hp, L.HEAD_HELP)
  -- foot bar: button at the bottom, the imprint above it in at most two lines (Humor.lua sets UI.HELP_FOOT, de/en only)
  local pg = Look.Page(Hp, { top = 58, foot = 44, w = PAGE_W, h = PAGE_H, bar = 4 })
  Hp.page = pg
  if type(UI.HELP_FOOT) == "string" then
    local foot = Look.Text(pg.foot, "type", 11, Look.INK)
    foot:SetTextColor(C(Look.INK, TONE.hint))
    foot:SetWidth(PAGE_W - 40)
    foot:SetJustifyH("CENTER")
    foot:SetPoint("BOTTOM", pg.foot, "BOTTOM", 0, 40)
    Look.FitText(foot, UI.HELP_FOOT, GF.HELP_FOOT)
    Look.TipIfCut(pg.foot, foot)
    pg:SetFoot(40 + math.ceil(Look.TextH(foot, 2)) + 6)
    Hp.foot = foot
  end
  Hp.paras = {}
  for i, p in ipairs(UI.HELP) do
    local label = Label(pg.body, p[1])
    label:SetJustifyH("RIGHT")
    label:SetWidth(GF.HELP_LABEL_W)
    -- keyword: 10 pt, otherwise 9 pt, otherwise two lines (nbNO, esES reached into the fold)
    Look.FitText(label, label:GetText(), GF.HELP_LABEL)
    local text = Look.Text(pg.body, "type", 11, Look.INK)
    text:SetWidth(232)
    text:SetJustifyH("LEFT")
    text:SetSpacing(1)
    text:SetText(p[2])
    label:SetPoint("TOPRIGHT", text, "TOPLEFT", -10, -1)
    Hp.paras[i] = { label, text }
  end
  local back = InkButton(pg.foot, L.BTN_BACK, 104, 22, function() UI.ClosePanel() end)
  back:SetPoint("BOTTOM", 0, 12)
  Hp.back = back
  GF.LayoutHelp()
end

-- stack the paragraphs from the top (real heights) and set the height of the scroll area; on build and on every open
function GF.LayoutHelp()
  local Hp = RP.help
  local y = 4
  for _, p in ipairs(Hp.paras) do
    p[2]:ClearAllPoints()
    p[2]:SetPoint("TOPLEFT", 116, -y)
    y = y + math.max(Look.TextH(p[2]), Look.TextH(p[1]) + 1) + 7
  end
  Hp.page:Layout(y - 7)   -- 1.2.2: the gap after the last paragraph is no content
end

-- 1.2.0: sheet "Put on hit list": for whom (Guild & Friends, Guild, Friends) and a short reason.
-- The reason is the only freely written text that is ever shared; the note stays separate.
GF.TARGETS = { { "all", "TAB_GUILD_FRIENDS" }, { "guild", "SRC_GUILD" }, { "friends", "SRC_FRIENDS" } }
GF.REASON_HINT = { all = "REL_HINT_ALL", guild = "REL_HINT_GUILD", friends = "REL_HINT_FRIENDS" }   -- locale key

function GF.BuildRelease()
  local R = PageLayer(RP)
  RP.release = R
  SheetHead(R, L.REL_HEAD)
  -- 1.2.2: content in the scroll child (same coordinates as before), message and buttons in the foot bar
  local pg = Look.Page(R, { top = 58, foot = 74, w = PAGE_W, h = PAGE_H })
  R.page = pg
  local Rs = CreateFrame("Frame", nil, pg.body)
  Rs:SetPoint("TOPLEFT", pg.body, "TOPLEFT", 0, 58)
  Rs:SetSize(PAGE_W, PAGE_H)
  R.name = Look.Text(Rs, "hand", 22, Look.INK)
  R.name:SetPoint("TOP", 0, -66)
  R.name:SetWidth(320)
  R.name:SetWordWrap(false)
  R.nameHit = CreateFrame("Frame", nil, Rs)
  R.nameHit:SetAllPoints(R.name)
  Look.TipIfCut(R.nameHit, R.name)
  R.who = Look.Text(Rs, "type", 11, Look.INK)
  R.who:SetPoint("TOP", R.name, "BOTTOM", 0, -4)
  R.who:SetTextColor(C(Look.INK, TONE.sub))
  local forL = Label(Rs, L.REL_FOR)
  forL:SetPoint("TOPLEFT", 34, -134)
  R.tabs = {}
  local prev
  for i, v in ipairs(GF.TARGETS) do
    local b = WordTab(Rs, L[v[2]], 90, function(self)
      if self.off then return end
      state.release.to = self.to
      GF.FillRelease()
    end)
    b.to = v[1]
    b:SetSize(math.max(40, TextWidth(b.text, 80) + 6), 20)
    if prev then b:SetPoint("LEFT", prev, "RIGHT", 12, 0)
    else b:SetPoint("TOPLEFT", math.max(92, 34 + TextWidth(forL, 40) + 12), -128) end
    R.tabs[i] = b
    prev = b
  end
  -- 1.2.2: the three words end before the edge (x = 346); otherwise all are squeezed alike, font 11 or 10 pt
  local x0 = math.max(92, 34 + TextWidth(forL, 40) + 12)
  local total = 0
  for _, b in ipairs(R.tabs) do total = total + b:GetWidth() end
  local room = 346 - x0 - 12 * (#R.tabs - 1)
  if total > room then
    for _, b in ipairs(R.tabs) do
      local w = math.floor(b:GetWidth() * room / total)
      b:SetWidth(w)
      b.text:SetWidth(w - 4)
      Look.FitText(b.text, b.text:GetText(), GF.FIT_WORD)
    end
  end
  local whyL = Label(Rs, L.REL_REASON)
  whyL:SetPoint("TOPLEFT", 34, -176)
  local eb = CreateFrame("EditBox", nil, Rs)
  eb:SetPoint("TOPLEFT", whyL, "TOPRIGHT", 8, 4)      -- 1.2.0: both anchors on the top edge
  eb:SetPoint("TOPRIGHT", Rs, "TOPRIGHT", -34, -172)
  eb:SetHeight(18)
  eb:SetAutoFocus(false)
  eb:SetMaxLetters(60)
  Look.Font(eb, "hand", 13)
  eb:SetTextColor(C(Look.INK))
  local ul = eb:CreateTexture(nil, "BACKGROUND")
  ul:SetColorTexture(C(Look.INK, 0.35))
  ul:SetHeight(1)
  ul:SetPoint("BOTTOMLEFT", 0, 1); ul:SetPoint("BOTTOMRIGHT", 0, 1)
  eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  eb:SetScript("OnEnterPressed", function(self) self:ClearFocus(); GF.DoRelease() end)
  R.edit = eb
  R.hint = Look.Text(Rs, "type", 11, Look.INK)
  R.hint:SetTextColor(C(Look.INK, TONE.hint))
  R.hint:SetPoint("TOPLEFT", 34, -204)
  R.hint:SetWidth(312)
  R.hint:SetJustifyH("LEFT")
  R.hint2 = Look.Text(Rs, "type", 11, Look.INK)
  R.hint2:SetTextColor(C(Look.INK, TONE.hint))
  R.hint2:SetPoint("TOPLEFT", R.hint, "BOTTOMLEFT", 0, -6)
  R.hint2:SetWidth(312)
  R.hint2:SetJustifyH("LEFT")
  R.hint2:SetText(L.REL_HINT2)
  R.msg = Look.Text(pg.foot, "body", 11, Look.RED_INK)
  R.msg:SetPoint("BOTTOM", 0, 44)
  R.msg:SetMaxLines(2)
  R.msg:SetWidth(330)
  R.go = InkButton(pg.foot, L.REL_GO, 104, 22, function() GF.DoRelease() end)
  R.go:SetPoint("BOTTOM", -57, 12)
  local back = InkButton(pg.foot, L.BTN_BACK, 104, 22, function() UI.ClosePanel() end)
  back:SetPoint("BOTTOM", 57, 12)
  R.sheet = Rs
end

-- height of the scroll area from the lowest hint
function GF.LayoutRelease(R)
  local bottom = 204 + Look.TextH(R.hint, 3) + 6 + Look.TextH(R.hint2, 3)
  R.page:Layout(math.ceil(bottom + 8 - 58))
end

function GF.FillRelease()
  local R, st = RP.release, state.release
  if not R or not st then return end
  local key = st.key
  local x = Store().Get(key) or GCall("Get", key, "all") or GCall("Hunt", key, "all")
  Look.FitText(R.name, x and Look.Name(x) or (NameOfKey(key)), GF.FIT_NAME22)
  R.who:SetText(x and Look.Join(x.level and Fmt(L.POSTER_LEVEL, { level = x.level }), ClassName(x)) or "")
  local g, f = GCall("HuntTargets")
  local avail = { all = g and f, guild = g, friends = f }
  if not avail[st.to] then st.to = (g and f and "all") or (g and "guild") or (f and "friends") or nil end
  for _, b in ipairs(R.tabs) do
    b.off = not avail[b.to]
    b:SetOn(b.to == st.to, b.off)
  end
  if st.to then
    R.hint:SetText(L[GF.REASON_HINT[st.to]])
    R.msg:SetText("")
  else
    R.hint:SetText("")
    R.msg:SetText(L.REL_NONE)
  end
  R.go:SetShown(st.to ~= nil)
  GF.LayoutRelease(R)
end

function GF.DoRelease()
  local R, st = RP.release, state.release
  if not R or not st or not st.to then return end
  local why = R.edit:GetText() or ""
  if Look.Secret(why) then why = "" end
  local a, b = GCall("Release", st.key, { to = st.to, why = why })
  if a == nil then
    R.msg:SetText((b == "cap" and Fmt(L.REL_CAP, { own = 10, max = 100 })) or (b == "self" and L.REL_SELF)
      or (b == "mate" and L.REL_MATE) or L.REL_FAILED)
    return
  end
  R.edit:SetText("")
  R.edit:ClearFocus()
  UI.ShowHunts(st.key)
end

function UI.OpenRelease(key)
  if not F or type(key) ~= "string" then return end
  if not RP.settings then BuildSettings() end
  if not RP.release then GF.BuildRelease() end
  HideMenu()
  state.release = { key = key, to = "all" }
  state.panel = "release"
  P:Hide(); RP.empty:Hide()
  RP.settings:Hide(); RP.io:Hide()
  if RP.help then RP.help:Hide() end
  RP.release.edit:SetText("")
  RP.release:Show()
  RP.release.page:Top()
  GF.FillRelease()
  if state.filter == "guild" and LP then GF.Survey(); UX.UpdateTabs() end   -- 1.2.0: show the hit list view
end

-- 1.2.0: language choice. First value "Automatic" (no stored choice: the game's language, otherwise English),
-- then the 21 codes; every native name in the font of its language
function GF.CurLanguage()
  local Lc = ns.Locale
  local cur = Lc.StoredChoice and Lc.StoredChoice() or nil
  if type(cur) ~= "string" or not (Lc.NATIVE and Lc.NATIVE[cur]) then cur = Lc.AUTO or "auto" end
  return cur
end

function GF.StepLanguage(d)
  local Lc = ns.Locale
  if not (Lc and Lc.SetChoice) then return end
  local list = { Lc.AUTO or "auto" }
  for i, c in ipairs(Lc.CODES) do list[i + 1] = c end
  local cur = GF.CurLanguage()
  local idx = 1
  for i, c in ipairs(list) do if c == cur then idx = i end end
  Lc.SetChoice(list[(idx - 1 + d) % #list + 1])
end

-- 1.3.0: cover choice, through the registered themes in their order
function GF.StepTheme(d)
  local T = ns.Theme
  local list = T and T.List and T.List() or {}
  if #list == 0 then return end
  local cur, idx = T.Resolve(T.StoredChoice()), 1
  for i, id in ipairs(list) do if id == cur then idx = i end end
  T.SetChoice(list[(idx - 1 + d) % #list + 1])
end

function GF.FillLanguage(S)
  local Lc = ns.Locale
  if not (S.lang and Lc and Lc.CODES) then return end
  local cur = GF.CurLanguage()
  local name, script = Lc.NATIVE[cur], cur
  if not name then
    -- Automatic: the word in the active language (its font)
    script = Lc.code or "enUS"
    name = L.SET_LANG_AUTO
  end
  if S.lang.code ~= cur then
    S.lang.code = cur
    -- native name in the font of its language (Cyrillic, Korean, Chinese)
    Look.Font(S.lang, "body", 11, nil, Look.FontOf(script))
  end
  S.lang:SetText(name)
  local pending = Lc.Pending and Lc.Pending() or false
  -- 1.3.0: the cover row; one hint for both
  local T = ns.Theme
  if S.theme and T then
    local id = T.Resolve(T.StoredChoice())
    local d = T.Get(id)
    S.theme:SetValue(d and type(d.nameKey) == "string" and L[d.nameKey] or id)
    pending = pending or (T.Pending and T.Pending()) or false
  end
  S.langHint:SetShown(pending)
  S.reload:SetShown(pending)
end

function UI.FillSettings()
  local S = RP and RP.settings
  if not S then return end
  local guild = HasGuild()
  if not GF.SheetOn(state.spage) then state.spage = 1 end
  for i, t in ipairs(S.tabs) do
    t:SetShown(GF.SheetOn(i))
    t:SetOn(state.spage == i)
  end
  S.pageA:SetShown(state.spage == 1)
  S.pageL:SetShown(state.spage == 2)
  S.pageB:SetShown(state.spage == 3)
  S.pageR:SetShown(state.spage == 4)
  if S.settled then
    local cur = Look.Setting("alert.settled", "always")
    for _, x in ipairs(GF.SETTLED) do if x[1] == cur then S.settled:SetValue(L[x[2]]) end end
  end
  if S.gmore then
    -- 1.2.0: second page of the guild sheet ("More"), state remembered, closed by default
    local more = Look.Setting("ui.guildMore", false) == true
    S.gmore:SetShown(state.spage == 3)
    S.gmore:SetOn(more)
    S.pageB1:SetShown(not more)
    S.pageB2:SetShown(more)
  end
  for _, cb in ipairs(S.checks) do
    local v
    if cb.opt.guild then v = Look.GuildSetting(cb.opt.guild) == true
    else v = Look.Setting(cb.opt.path, cb.opt.def) and true or false end
    if cb.opt.invert then v = not v end
    cb:SetInk(v)
  end
  S.cd:SetValue(Fmt(L.SET_SECONDS, { seconds = Look.Setting("alert.cooldown", 90) or 90 }))
  S.mk:SetValue(tostring(Look.Setting("alert.minKills", 1) or 1))
  S.size:SetValue(Percent(ClampScale(tonumber(Look.Setting("ui.scale", 1)) or 1)))
  S.asize:SetValue(Percent(Look.Setting("alert.scale", 1)))
  S.gmk:SetValue(tostring(Look.GuildSetting("minKills") or 1))
  local days = tonumber(Look.GuildSetting("huntExpire")) or 0
  S.hexp:SetValue(days > 0 and Fmt(L.SET_EXPIRE_DAYS, { count = days }) or L.SET_EXPIRE_NEVER)
  if guild then
    local h = Look.GuildHealth()
    S.gstatus:SetText(h.text)
    if h.ok or h.calm then S.gstatus:SetTextColor(C(Look.INK, h.ok and TONE.ink or TONE.sub)) else S.gstatus:SetTextColor(C(Look.RED_INK)) end
    if S.fstatus then
      local fh = Look.GuildHealth("friends")
      S.fstatus:SetText(fh.text)
      if fh.ok or fh.calm then S.fstatus:SetTextColor(C(Look.INK, fh.ok and TONE.ink or TONE.sub)) else S.fstatus:SetTextColor(C(Look.RED_INK)) end
    end
  else
    S.gstatus:SetText("")
    if S.fstatus then S.fstatus:SetText("") end
  end
  local io = Store().Export ~= nil
  for _, b in ipairs(S.ioButtons) do b:SetShown(io) end

  -- sound: "No sound" is silence; built-in sounds have no volume of their own
  local sound, vol, ch = Look.SoundChoice()
  S.tone:SetValue(sound.label or L[sound.lkey])
  local fixed = sound.builtin or sound.silent
  for i, bar in ipairs(S.vol.bars) do bar:SetAlpha((i <= vol and 0.85 or 0.15) * ((fixed and 0.5) or 1)) end
  S.vol:SetText("")
  Dim(S.tone, false)
  Dim(S.vol, fixed)
  local chOff = sound.silent
  S.chan.label:SetTextColor(C(Look.INK, chOff and TONE.off or TONE.ink))
  for i = 1, #Look.CHANNELS do
    local b = S.chan[i]
    b.off = chOff
    b:SetOn(b.channel == ch, chOff)
  end
  if sound.silent then
    S.soundHint:SetText(L.SET_HINT_SILENT)
  elseif sound.builtin then
    S.soundHint:SetText(L.SET_HINT_BUILTIN)
  else
    S.soundHint:SetText(L.SET_HINT_LEVELS)
  end
  GF.FillLanguage(S)
  GF.LayoutSheet(S)
end

-- 1.2.2: put the hint of the open sheet into the flow and set the height of the scroll area; another sheet
-- (or "More") starts at the top
function GF.LayoutSheet(S)
  local X = (state.spage == 1 and S.pageA) or (state.spage == 2 and S.pageL) or (state.spage == 4 and S.pageR) or S.pageB
  local inner = X
  if X == S.pageB and S.pageB2 then inner = S.pageB2:IsShown() and S.pageB2 or S.pageB1 end
  local h = X.hint
  local low = inner.bottom or 0
  local hh = h and h:GetText() ~= "" and Look.TextH(h, 3) or 0
  local top = math.max(low + 10, PAGE_H - 44 - hh)
  if h then
    h:ClearAllPoints()
    h:SetPoint("TOPLEFT", X, "TOPLEFT", 30, -top)
  end
  local key = tostring(state.spage) .. (inner == S.pageB2 and "m" or "")
  if S.sheetKey ~= key then S.sheetKey = key; S.page:Top() end
  S.page:Layout(math.floor(top + hh - GF.SHEET_TOP + 0.5))
end

function UI.OpenPanel(which)
  if not F then return end
  if not RP.settings then BuildSettings() end
  if which == "help" and not RP.help then BuildHelp() end
  HideMenu()
  state.panel = which
  P:Hide(); RP.empty:Hide()
  if RP.release then RP.release:Hide() end
  RP.settings:SetShown(which == "settings")
  RP.io:SetShown(which == "export" or which == "import")
  if RP.help then RP.help:SetShown(which == "help") end
  if which == "help" then GF.LayoutHelp(); RP.help.page:Top() end
  if which == "settings" then
    if RP.settings.page then RP.settings.sheetKey = nil end   -- 1.2.2: house rules open at the top
    UI.FillSettings()
  end
end

function UI.ClosePanel(silent)
  state.panel = nil
  if RP.release then RP.release:Hide() end
  if RP.settings then RP.settings:Hide(); RP.io:Hide() end
  if RP.help then RP.help:Hide() end
  if not silent then ShowRight() end
end

local function KB(n) return math.floor(n / 1024 + 0.5) .. " KB" end

local function ExportText(short)
  local ok, text = pcall(Store().Export, short)
  if ok and type(text) == "string" then return text end
  return ""
end

-- full == true: whole book with deeds, false: small version (if the store knows one),
-- nil: automatic (the small one from EXPORT_WARN on)
function UI.ShowExport(full)
  local IO = RP and RP.io
  if not IO then return end
  local whole = ExportText()
  local short = ExportText(true)       -- older store version without a short form: the same text
  local hasShort = #short < #whole
  if full == nil then full = #whole < EXPORT_WARN end
  IO.full = full or not hasShort
  IO.edit:SetText(IO.full and whole or short)
  if hasShort then
    IO.size:SetLabel(IO.full and L.IO_SMALL or L.IO_ALL)
    IO.size:Show()
    if IO.full then
      IO.msg:SetText(Fmt(L.IO_MSG_FULL, { size = KB(#whole) }))
    else
      IO.msg:SetText(Fmt(L.IO_MSG_SHORT, { size = KB(#short), full = KB(#whole) }))
    end
  else
    IO.size:Hide()
    IO.msg:SetText(#whole >= EXPORT_WARN and Fmt(L.IO_MSG_BIG, { size = KB(#whole) }) or "")
  end
  IO.msg:SetTextColor(C(Look.INK))
  IO.edit:SetFocus()
  IO.edit:HighlightText()
end

function UI.OpenIO(mode)
  UI.OpenPanel(mode)
  local IO = RP.io
  IO.msg:SetText("")
  IO.size:Hide()
  if mode == "export" then
    Look.FitText(IO.head, L.IO_EXPORT, GF.FIT_NAME26)
    Look.FitText(IO.help, L.IO_HELP_EXPORT, GF.FIT_IO_HELP)
    IO.go:Hide()
    -- show large books small first (an EditBox with thousands of lines is slow)
    UI.ShowExport(nil)
  else
    Look.FitText(IO.head, L.IO_IMPORT, GF.FIT_NAME26)
    Look.FitText(IO.help, L.IO_HELP_IMPORT, GF.FIT_IO_HELP)
    IO.edit:SetText("")
    IO.go:SetShown(Store().Import ~= nil)
    IO.edit:SetFocus()
  end
end

end -- house rules

------------------------------------------------------------------------
-- Main window
------------------------------------------------------------------------

-- number on the tab: only when there is something; "Unsolved" in red
function UX.TabCount(id)
  if id == "record" then return 0 end     -- 1.3.0: the rap sheet's tab carries no number (it stays calm and narrow)
  if id == "journal" then return #UX.Journal() end
  if id == "guild" then return UX.GuildCount() end
  local w, s, _, o = Counts()
  if id == "open" then return s + o end
  return w
end

function UX.UpdateTabs()
  local guild, record = HasGuild(), RS.On()
  -- 1.3.0: the fifth tab comes with the first own kill; the row is laid out again when the shown tabs change
  local sig, shown = "", 0
  for _, t in ipairs(F.tabs) do
    local show = (t.id ~= "guild" or guild) and (t.id ~= "record" or record)
    t:SetShown(show)
    if show then sig = sig .. t.id; shown = shown + 1 end
  end
  if F.tabSig ~= sig then F.tabSig = sig; GF.LayoutTabs() end
  for _, t in ipairs(F.tabs) do
    local on = t.id == state.filter
    local n = UX.TabCount(t.id) or 0
    local text
    if n <= 0 then text = t.label
    elseif t.id == "open" then text = t.label .. "  " .. Look.HEX.accentOnCover .. n .. "|r"
    else text = t.label .. "  " .. n end
    if shown >= 5 then
      -- five tabs: a label that does not fit gets 10 pt, then the whole of it in the tab's tooltip
      Look.FitText(t.text, text, GF.FIT_TAB)
    else
      t.text.fitText = nil      -- written plainly as in 1.2.2 (four tabs always fit)
      t.text:SetText(text)
    end
    t.text:SetTextColor(C(on and Look.BONE or Look.TAB_OFF))
    t.mark:SetShown(on)
  end
  -- 1.2.2: a four-digit number does not fit the room for "  123": lay out the tabs again
  for _, t in ipairs(F.tabs) do
    if (Look.TextW(t.text) or 0) > (t.text:GetWidth() or 999) + 0.5 then GF.LayoutTabs(true); break end
  end
  -- Guild with "By guildmate": the toggle at the top (search field shorter); sorting at the bottom right
  -- 1.2.0: views only when there is more than one that makes sense (nobody to share with: none; the
  -- hit list only with calls); sources only when both really exist. Normally one row.
  local guildTab = state.filter == "guild"
  local views = guildTab and not GF.nobody and (HasMemberView() or GF.hunts) and true or false
  LP.views:SetShown(views)
  if views then
    for _, b in ipairs(LP.views.items) do
      b:SetOn(b.view == state.gview)
      if b.view == "hunt" then b:SetShown(GF.hunts and true or false) end
    end
  end
  -- 1.2.0: source (All, Guild, Friends) at the bottom left, only with the friends' book
  local srcs = guildTab and GF.HasFriends() and GF.both and true or false
  LP.srcs:SetShown(srcs)
  if srcs then
    for _, b in ipairs(LP.srcs.items) do b:SetOn(b.src == state.gsource) end
  end
  -- Morpheus 13 is wider than the estimate in the still image: room for the toggle (search field 80 px with three views, 120 with two, else 200)
  local three = views and #LP.views.items > 2 and GF.hunts
  local sw = views and (three and 80 or 120) or 200
  -- 1.2.0: never below the view words (their width depends on the language)
  local vw = views and (three and LP.views.width or LP.views.width2)
  if vw then sw = math.max(60, math.min(sw, PAGE_W - 14 - vw - 46 - 8)) end
  if LP.search.w ~= sw then LP.search.w = sw; LP.search:SetWidth(sw) end
  -- all open/closed: double triangle left of the search field
  local member = MemberView()
  LP.all:SetShown(member)
  if member then
    LP.all.open = not AnyCollapsed()          -- true: a click collapses all
    LP.all.a:SetRotation(LP.all.open and -1.5708 or 0)
    LP.all.b:SetRotation(LP.all.open and -1.5708 or 0)
  end
  -- sorting: Wanted at the top right, guild by killer at the bottom right, otherwise none
  local foot = state.filter == "guild"
  if LP.sort.foot ~= foot then
    LP.sort.foot = foot
    LP.sort:ClearAllPoints()
    if foot then LP.sort:SetPoint("BOTTOMRIGHT", -14, 32) else LP.sort:SetPoint("TOPRIGHT", -14, -14) end
  end
  local sortKey = (state.filter == "guild" and state.gsort) or (state.filter == "record" and state.rsort) or state.sort
  LP.sort.text:SetText(SORT_LABEL[sortKey] and L[SORT_LABEL[sortKey]] or "")
  LP.sort:SetWidth(math.max(90, math.min(120, TextWidth(LP.sort.text, 60) + 16)))
  LP.sort:SetShown(state.filter == "wanted" or state.filter == "record" or (state.filter == "guild" and not member and not GF.HuntView()))
  -- 1.2.2: the placeholder stays inside the field (smaller, then truncated)
  LP.search.ph:SetWidth(sw - 4)
  Look.FitText(LP.search.ph, (state.filter == "guild" and ((views or GF.HuntView()) and L.SEARCH_SHORT or L.SEARCH_KILLER))
                       or (state.filter == "journal" and L.SEARCH_JOURNAL)
                       or ((state.filter == "open" or state.filter == "record") and L.SEARCH_SHORT) or L.SEARCH_ADD, GF.FIT_PH)
end

function UX.UpdateStatus()
  local U = ns.Util
  if state.filter == "guild" then
    -- honest sharing status, red when it does not work; tooltip: guildmates, what is shared
    -- 1.2.0: nobody to share with: no line, the empty state on the right says it calmly; "no friends" muted
    local h = Look.GuildHealth(GF.HasFriends() and GF.Src() or nil)
    local quiet = GF.nobody
    LP.status:SetText(quiet and "" or h.text)
    if h.ok or h.calm then LP.status:SetTextColor(C(Look.INK, TONE.sub)) else LP.status:SetTextColor(C(Look.RED_INK)) end
    LP.status:SetWidth(PAGE_W - 46 - (LP.sync:GetWidth() or 84) - 20)
    LP.statusHit:SetShown(not quiet)
    LP.sync:SetShown(GF.SrcOn() and not quiet)
  elseif U and U.NameplatesOn and U.NameplatesOn() == false then
    LP.status:SetText(L.STATUS_NO_PLATES)
    LP.status:SetTextColor(C(Look.RED_INK))
    LP.status:SetWidth(PAGE_W - 46 - 14)
    LP.statusHit:Hide()
    LP.sync:Hide()
  else
    LP.status:SetText("")
    LP.statusHit:Hide()
    LP.sync:Hide()
  end
end

-- 1.2.2: the line "enemy nameplates are off" follows the plates at once. Events (CVAR_UPDATE, a nameplate
-- appearing) reach Util.CheckPlates in Core/Tracker; the V key may change the CVar without any event, so while
-- the book is open a cheap poll compares the CVar every PLATE_POLL seconds. The poll is a C_Timer chain that is
-- started by the book's OnShow and cancelled by its OnHide: with the book closed nothing runs.
UX.PLATE_POLL = 0.5
local platePoll          -- C_Timer handle while the book is open, nil otherwise
local function PlatePollTick()
  platePoll = nil
  if not F or not F:IsShown() then return end
  local U = ns.Util
  if U and U.CheckPlates then U.CheckPlates("poll") end
  -- without C_Timer.NewTimer there is no poll (one read per opening), but OnShow must not fail
  local NewTimer = C_Timer and C_Timer.NewTimer
  if NewTimer and F:IsShown() then platePoll = NewTimer(UX.PLATE_POLL, PlatePollTick) end
end
function UX.StartPlatePoll()
  if platePoll then platePoll:Cancel(); platePoll = nil end
  PlatePollTick()
end
function UX.StopPlatePoll()
  if platePoll then platePoll:Cancel(); platePoll = nil end
end
function UI.PlatePollActive() return platePoll ~= nil end

-- search: substring of the shown name (journal and cases: killer, candidate or place)
local function Matches(text, q)
  return type(text) == "string" and text:lower():find(q, 1, true) ~= nil
end

local function DeathMatches(d, q)
  local name = d.killerKey and NameOfKey(d.killerKey, d.killerName) or d.killerName
  if Matches(name, q) or Matches(d.zone, q) or Matches(d.subzone, q) then return true end
  if not d.killerKey and type(d.candidates) == "table" then
    for i = 1, #d.candidates do if Matches((NameOfKey(d.candidates[i])), q) then return true end end
  end
  return false
end

-- Death Log: only deaths by players (pvp and unclear), not monsters and environment (1.2.0)
function UX.Journal()
  local S = Store()
  if S.Journal then
    local ok, list = pcall(S.Journal)
    if ok and type(list) == "table" then return list end
  end
  return S.Deaths() or {}
end

function UX.ApplyQuery(list)
  dataIdx = nil
  local q = state.query
  if q == "" then return list end
  q = q:lower()
  local out = {}
  if state.filter == "journal" then
    dataIdx = {}
    for i = 1, #list do
      if DeathMatches(list[i], q) then
        out[#out + 1] = list[i]
        dataIdx[#out] = i
      end
    end
  else
    for i = 1, #list do
      local x = list[i]
      if IsCase(x) then
        if DeathMatches(x, q) then out[#out + 1] = x end
      elseif Matches(state.filter == "record" and RS.Name(x) or Look.Name(x), q) then
        out[#out + 1] = x
      end
    end
  end
  return out
end

------------------------------------------------------------------------
-- Guild: flat list "by guildmate" (rebuilt only on change)
------------------------------------------------------------------------
local mflat = {}            -- head and child rows, wrappers from wpool
local wpool = {}
local mv = { src = nil, cver = -1, q = nil, dirty = true, n = 0, builds = 0 }
local collapseVer = 0
local NOTHING = {}
UI.mv = mv                  -- for tests: how often the flat list was built
function UI.DataCount() return #data end   -- for tests and measuring: rows of the current list

-- ui.guildCollapsed: name -> true means "different from the default" (default: own section open,
-- all others closed). The store keeps only true values in this table.
local function IsCollapsed(m, t)
  local def = not m.me
  if t and t[m.name] == true then return not def end
  return def
end

local function CollapsedTable()
  local t = Look.Setting("ui.guildCollapsed")
  return type(t) == "table" and t or nil
end

local function RowName(row)
  local e = row.entry
  return e and Look.Name(e) or row.key
end

function UX.BuildMemberList(src, q)
  mv.builds = mv.builds + 1
  local t = CollapsedTable()
  local n = 0
  local function add(m, row, head, open)
    n = n + 1
    local w = wpool[n]
    if not w then w = { wrap = true }; wpool[n] = w end
    w.m, w.r, w.head, w.open = m, row, head, open
    mflat[n] = w
  end
  for i = 1, #src do
    local m = src[i]
    local rows = type(m) == "table" and m.rows
    if type(m) == "table" and (m.me or (m.tie and m.tie.conflict)) and (type(rows) ~= "table" or #rows == 0) and q == "" then
      -- the own character is always at the top, even without entries; 1.2.0: so are both names of a friend
      -- for whom the player has to choose who it is (right click)
      add(m, nil, true, false)
    elseif type(rows) == "table" and #rows > 0 then
      if q == "" then
        local open = not IsCollapsed(m, t)
        add(m, nil, true, open)
        if open then for k = 1, #rows do add(m, rows[k], false) end end
      elseif Matches(m.name, q) then
        -- a match opens the section only for the search (the remembered state stays)
        add(m, nil, true, true)
        for k = 1, #rows do add(m, rows[k], false) end
      else
        local hit = false
        for k = 1, #rows do if Matches(RowName(rows[k]), q) then hit = true; break end end
        if hit then
          add(m, nil, true, true)
          for k = 1, #rows do if Matches(RowName(rows[k]), q) then add(m, rows[k], false) end end
        end
      end
    end
  end
  for i = n + 1, mv.n do mflat[i] = nil end
  mv.n = n
end

function UX.MemberSource()
  local s = GF.Src()
  local src = GF.SrcOn(s) and GCall("ByMember", s) or nil
  return type(src) == "table" and src or NOTHING
end

function UX.MemberData()
  local src = UX.MemberSource()
  local q = state.query:lower()
  if src ~= mv.src or mv.dirty or mv.cver ~= collapseVer or mv.q ~= q then
    UX.BuildMemberList(src, q)
    mv.src, mv.dirty, mv.cver, mv.q = src, false, collapseVer, q
  end
  return mflat
end

-- is any section (with entries) collapsed right now?
AnyCollapsed = function()
  local src, t = mv.src or NOTHING, CollapsedTable()
  for i = 1, #src do
    local m = src[i]
    if type(m) == "table" and type(m.rows) == "table" and #m.rows > 0 and IsCollapsed(m, t) then return true end
  end
  return false
end

-- write the state back: copy the whole table, change it, set it (that is how the store wants it)
local function WriteCollapsed(fn)
  local copy = {}
  local t = CollapsedTable()
  if t then for k, v in pairs(t) do copy[k] = v end end
  fn(copy)
  collapseVer = collapseVer + 1
  Set("ui.guildCollapsed", copy)
  Refresh()
end

ToggleMember = function(m)
  if state.query ~= "" or type(m) ~= "table" or type(m.name) ~= "string" then return end
  if type(m.rows) ~= "table" or #m.rows == 0 then return end
  Look.Sound("click")
  WriteCollapsed(function(copy) if copy[m.name] then copy[m.name] = nil else copy[m.name] = true end end)
end

SetAllMembers = function(open)
  local src = mv.src or NOTHING
  WriteCollapsed(function(copy)
    for k in pairs(copy) do copy[k] = nil end
    for i = 1, #src do
      local m = src[i]
      if type(m) == "table" and type(m.name) == "string" then
        local default = not m.me
        if (not open) ~= default then copy[m.name] = true end
      end
    end
  end)
end

Refresh = function()
  if not F or not F:IsShown() then dirty = true; return end
  dirty = false
  local S = Store()
  if state.filter == "guild" and not HasGuild() then state.filter = "wanted" end
  if state.filter == "record" and not RS.On() then state.filter = "wanted" end
  if state.filter == "guild" then GF.Survey() end
  local list
  if state.filter == "journal" then
    list = UX.Journal()
  elseif state.filter == "open" then
    list = UX.OpenData()
  elseif GF.HuntView() then
    list = GF.SrcOn() and GF.Hunts() or {}
  elseif state.filter == "guild" and not MemberView() then
    list = GuildEnemies(state.gsort)
  elseif state.filter == "record" then
    list = ns.Ledger.Victims(state.rsort)    -- the rap sheet's own list, read only
  elseif state.filter ~= "guild" then
    list = UX.WantedData()
  end
  if MemberView() then
    dataIdx = nil
    data = UX.MemberData()
  else
    data = UX.ApplyQuery(list)
  end
  UX.UpdateTabs()
  UX.UpdateStatus()
  BindRows()
  picked = false
  ShowRight()
  if picked then BindRows() end      -- underline the selection just set right away
  if state.panel == "settings" then UI.FillSettings() end
end
UI.Refresh = Refresh

-- merge several changes in the same frame into one rebuild
local function RequestRefresh()
  if not F or not F:IsShown() then dirty = true; return end
  if pending then return end
  pending = true
  C_Timer.After(0, function() pending = false; Refresh() end)
end

local function SetFilter(id)
  if state.filter == id then
    if state.panel then UI.ClosePanel() end
    return
  end
  -- 1.2.0: the hit list is the first view as soon as there is a call (until the user picks one)
  if id == "guild" and not state.viewPicked and GF.HasHunts() and #GF.Hunts() > 0 then state.gview = "hunt" end
  state.filter = id
  state.offset = 0
  state.death, state.deathRef = nil, nil
  HideMenu()
  if state.panel then UI.ClosePanel(true) end
  Refresh()
end
UI.SetFilter = SetFilter

function UX.SavePoint()
  local p, _, rp, x, y = F:GetPoint(1)
  if p then Set("ui.point", { p, rp, x, y }) end
end

-- Enter in the search field: pick a match, without a match add the name to the book (only in the Wanted tab)
local function SubmitSearch(box)
  local q = state.query
  if q == "" then box:ClearFocus(); return end
  if #data > 0 then
    local first = data[1]
    if state.filter == "journal" then state.death, state.deathRef = (dataIdx and dataIdx[1]) or 1, first
    elseif first.wrap then
      for i = 1, #data do
        if not data[i].head then state.gselected, state.gmember = data[i].r.key, data[i].m.name; break end
      end
    elseif state.filter == "open" then state.osel = IsCase(first) and first or first.key
    elseif state.filter == "record" then state.rsel = first.key
    elseif state.filter == "guild" then state.gselected = first.key
    else state.selected = first.key end
    state.offset = 0
    box:ClearFocus()
    if state.panel then UI.ClosePanel(true) end
    BindRows()
    ShowRight()
    return
  end
  if SearchOnly() then return end
  local S = Store()
  local key = S.AddManual and S.AddManual(q)
  if type(key) == "string" then
    box:ClearFocus()
    UI.ShowEnemy(key)
  end
end

function UX.BuildSearch(parent)
  local sb = CreateFrame("EditBox", "DeathNoteSearch", parent)
  sb:SetPoint("TOPLEFT", 46, -8)
  sb:SetSize(200, 26)
  sb:SetAutoFocus(false)
  sb:SetMaxLetters(40)
  Look.Font(sb, "hand", 19)
  sb:SetTextColor(C(Look.INK))
  local ul = sb:CreateTexture(nil, "BACKGROUND")
  ul:SetColorTexture(C(Look.INK, 0.35))
  ul:SetHeight(1)
  ul:SetPoint("BOTTOMLEFT", 0, 1); ul:SetPoint("BOTTOMRIGHT", 0, 1)
  sb.ph = Look.Text(sb, "hand", 16, Look.INK)
  sb.ph:SetPoint("LEFT", 1, -1)
  sb.ph:SetTextColor(C(Look.INK, TONE.hand))
  sb.ph:SetText(L.SEARCH_ADD)
  local function changed(self)
    local t = self:GetText() or ""
    if Look.Secret(t) then t = "" end
    self.ph:SetShown(t == "")
    t = t:gsub("^%s+", ""):gsub("%s+$", "")
    if t == state.query then return end
    state.query = t
    state.offset = 0
    Refresh()
  end
  sb:SetScript("OnTextChanged", changed)
  sb:SetScript("OnEnterPressed", SubmitSearch)
  sb:SetScript("OnEscapePressed", function(self)
    if (self:GetText() or "") ~= "" then self:SetText(""); changed(self) else self:ClearFocus() end
  end)
  return sb
end

function UI.SetGuildView(v)
  if v ~= "enemy" and v ~= "member" and v ~= "hunt" then return end
  state.viewPicked = true
  if state.gview == v then return end
  Look.Sound("click")
  state.gview = v
  state.offset = 0
  HideMenu()
  Set("ui.guildView", v)
  Refresh()
end

-- 1.2.0: source in the fourth tab
function UI.SetGuildSource(src)
  if src ~= "all" and src ~= "guild" and src ~= "friends" then return end
  if state.gsource == src then return end
  Look.Sound("click")
  state.gsource = src
  state.offset = 0
  HideMenu()
  mv.dirty = true
  gpart.src = nil
  Set("ui.guildSource", src)
  Refresh()
end

function UI.ClearSearch()
  state.query = ""
  if LP and LP.search then
    LP.search:SetText("")
    LP.search.ph:Show()
  end
end

-- sort menu: the values as a list, in the Wanted tab also "show/hide pardoned"
function UX.SortMenu(btn)
  local guild, record = state.filter == "guild", state.filter == "record"
  local list = (guild and UX.GSORTS) or (record and RS.SORTS) or UX.SORTS
  local cur = (guild and state.gsort) or (record and state.rsort) or state.sort
  local spec = {}
  for _, k in ipairs(list) do
    spec[#spec + 1] = { (k == cur and "• " or "") .. L[SORT_LABEL[k]], function()
      if guild then state.gsort = k
      elseif record then state.rsort = k; Set("ui.recordSort", k)
      else state.sort = k; Set("ui.sort", k) end
      state.offset = 0
      Refresh()
    end }
  end
  if not guild and not record then
    local on = ShowPardoned()
    spec[#spec + 1] = { on and L.SORT_HIDE_PARDONED or L.SORT_SHOW_PARDONED, function()
      Set("ui.showPardoned", not on)
      Refresh()
    end }
  end
  OpenMenu(spec, btn)
end

function UX.BuildLeftPage()
  LP = CreateFrame("Frame", nil, F)
  LP:SetSize(PAGE_W, PAGE_H)
  LP:SetPoint("TOPLEFT", 16, -44)
  local bg = Tex(LP, "BACKGROUND", "page")
  bg:SetAllPoints()
  bg:SetTexCoord(1, 0, 0, 1)          -- mirrored: the dark edge lies at the fold
  -- lines every 22 px: name on the first, subtext on the second; pale red margin
  for k = 1, ROWS * 2 do
    local l = LP:CreateTexture(nil, "BORDER")
    l:SetColorTexture(C(Look.COLOR.rule, k % 2 == 0 and 0.28 or 0.16))
    l:SetHeight(1)
    l:SetPoint("TOPLEFT", 6, ROW_TOP - k * LINE_H + 1)
    l:SetPoint("TOPRIGHT", -6, ROW_TOP - k * LINE_H + 1)
  end
  local margin = LP:CreateTexture(nil, "BORDER")
  margin:SetColorTexture(Look.RED[1], Look.RED[2], Look.RED[3], 0.35)
  margin:SetWidth(1)
  margin:SetPoint("TOPLEFT", 40, 0)
  margin:SetPoint("BOTTOMLEFT", 40, 0)

  LP.search = UX.BuildSearch(LP)

  -- sorting: one word with a triangle; a click opens the list of values, hover underlines
  local sort = CreateFrame("Button", nil, LP)
  sort:SetSize(90, 18)
  sort:SetPoint("TOPRIGHT", -14, -14)
  sort.arrow = Tri(sort, 9, -1.5708)
  sort.arrow:SetPoint("RIGHT", 0, 0)
  sort.text = Look.Text(sort, "body", 11, Look.INK)
  sort.text:SetTextColor(C(Look.INK, TONE.sub))
  sort.text:SetPoint("RIGHT", sort.arrow, "LEFT", -3, 0)
  sort.text:SetJustifyH("RIGHT")
  sort.ul = sort:CreateTexture(nil, "ARTWORK")
  sort.ul:SetColorTexture(C(Look.INK, 0.6))
  sort.ul:SetHeight(1)
  sort.ul:SetPoint("TOPLEFT", sort.text, "BOTTOMLEFT", 0, -1)
  sort.ul:SetPoint("TOPRIGHT", sort.arrow, "BOTTOMRIGHT", 0, 1)
  sort.ul:Hide()
  sort:SetScript("OnEnter", function(self) self.ul:Show() end)
  sort:SetScript("OnLeave", function(self) self.ul:Hide() end)
  sort:SetScript("OnClick", function(self) Look.Sound("click"); UX.SortMenu(self) end)
  LP.sort = sort

  -- all open/closed (guild by guildmate): double triangle left of the search field
  local all = CreateFrame("Button", nil, LP)
  all:SetSize(20, 20)
  all:SetPoint("TOPLEFT", 14, -12)
  all.a = Tri(all, 10, 0); all.a:SetPoint("CENTER", -3, 0)
  all.b = Tri(all, 10, 0); all.b:SetPoint("CENTER", 3, 0)
  all:SetScript("OnClick", function(self) SetAllMembers(not self.open) end)
  all:SetScript("OnEnter", function(self) Tip(self, { self.open and L.TIP_COLLAPSE_ALL or L.TIP_EXPAND_ALL }, "ANCHOR_TOP") end)
  all:SetScript("OnLeave", GameTooltip_Hide)
  all:Hide()
  LP.all = all

  -- toggle "By killer | By guildmate": two word tabs, the active one underlined in red
  local views = CreateFrame("Frame", nil, LP)
  views:SetSize(180, 22)
  views:SetPoint("TOPRIGHT", -14, -10)
  views.items = {}
  local prev
  -- 1.2.0: the hit list comes first (on the left) when the logic knows it
  local viewList = { { "member", "VIEW_BY_MATE" }, { "enemy", "VIEW_BY_KILLER" } }
  if GF.HasHunts() then viewList[3] = { "hunt", "VIEW_HUNT" } end
  local gap = #viewList > 2 and 8 or 10
  -- 1.2.0: width from the word; together at most so wide that the search field keeps 60 px
  local ws, total = {}, 0
  for i, v in ipairs(viewList) do
    local b = WordTab(views, L[v[2]], 78, function(self) UI.SetGuildView(self.view) end)
    b.view = v[1]
    ws[i] = math.max(40, TextWidth(b.text, 70) + 6)
    total = total + ws[i] + (i > 1 and gap or 0)
    views.items[i] = b
  end
  local room = PAGE_W - 14 - 46 - 8 - 60
  local k = total > room and (room - gap * (#ws - 1)) / (total - gap * (#ws - 1)) or 1
  for i, b in ipairs(views.items) do
    local w = math.floor(ws[i] * k)
    b:SetSize(w, 20)
    if k < 1 then b.text:SetWidth(w - 4); b.text:SetWordWrap(false) end
    if prev then b:SetPoint("RIGHT", prev, "LEFT", -gap, 0) else b:SetPoint("RIGHT", 0, 0) end
    prev = b
  end
  views.width = math.min(total, room)
  -- 1.2.0: width without the hit list (it stands on the left and may be missing)
  views.width2 = #ws > 2 and math.floor((ws[1] + ws[2] + gap) * k) or views.width
  views:Hide()
  LP.views = views

  -- 1.2.0: source "All | Guild | Friends" at the bottom left (pattern of the view toggles)
  local srcs = CreateFrame("Frame", nil, LP)
  srcs:SetSize(200, 18)
  srcs:SetPoint("BOTTOMLEFT", 44, 34)
  srcs.items = {}
  local prevS
  for i, v in ipairs(GF.SOURCES) do
    local b = WordTab(srcs, L[v[2]], 50, function(self) UI.SetGuildSource(self.src) end)
    b.src = v[1]
    local w = math.min(80, math.max(30, TextWidth(b.text, 40) + 6))
    b:SetSize(w, 18)
    b.text:SetWidth(w - 4); b.text:SetWordWrap(false)
    if prevS then b:SetPoint("LEFT", prevS, "RIGHT", 10, 0) else b:SetPoint("LEFT", 0, 0) end
    srcs.items[i] = b
    prevS = b
  end
  srcs:Hide()
  LP.srcs = srcs

  local LR = CreateFrame("Frame", nil, LP)
  LR:SetAllPoints()
  LR:EnableMouseWheel(true)
  LR:SetScript("OnMouseWheel", function(_, delta)
    local maxOff = math.max(0, #data - ROWS)
    local o = math.max(0, math.min(maxOff, state.offset - delta * 2))
    if o ~= state.offset then state.offset = o; HideMenu(); BindRows() end
  end)
  for i = 1, ROWS do rows[i] = UX.MakeRow(LR, i) end

  -- scroll bar: 14 px grip area, 5 px visible
  local sc = CreateFrame("Slider", nil, LP)
  sc:SetOrientation("VERTICAL")
  sc:SetSize(14, ROWS * ROW_H - 8)
  sc:SetPoint("TOPRIGHT", -4, ROW_TOP - 4)
  local track = sc:CreateTexture(nil, "BACKGROUND")
  track:SetColorTexture(C(Look.INK, 0.12))
  track:SetWidth(5)
  track:SetPoint("TOP"); track:SetPoint("BOTTOM")
  local thumb = sc:CreateTexture(nil, "OVERLAY")
  thumb:SetColorTexture(0, 0, 0, 0)
  thumb:SetSize(14, 34)
  sc:SetThumbTexture(thumb)
  local tv = sc:CreateTexture(nil, "OVERLAY", nil, 1)
  tv:SetColorTexture(C(Look.INK, 0.75))
  tv:SetWidth(5)
  tv:SetPoint("TOP", thumb, "TOP"); tv:SetPoint("BOTTOM", thumb, "BOTTOM")
  sc:SetMinMaxValues(0, 0)
  sc:SetValueStep(1)
  if sc.SetObeyStepOnDrag then sc:SetObeyStepOnDrag(true) end
  sc:SetScript("OnValueChanged", function(_, v)
    v = math.floor((v or 0) + 0.5)
    if v ~= state.offset then state.offset = v; HideMenu(); BindRows() end
  end)
  LP.scroll = sc

  -- foot line: on the left the status (guild: sharing, otherwise a hint), at the bottom right "Sync"
  LP.status = Look.Text(LP, "body", 10, Look.INK)
  LP.status:SetPoint("BOTTOMLEFT", 46, 10)
  LP.status:SetWidth(PAGE_W - 46 - 104)
  LP.status:SetJustifyH("LEFT")
  LP.status:SetMaxLines(2)
  local hit = CreateFrame("Button", nil, LP)
  hit:SetPoint("BOTTOMLEFT", 44, 6)
  hit:SetSize(PAGE_W - 46 - 102, 30)
  hit:SetScript("OnEnter", MembersTip)
  hit:SetScript("OnLeave", GameTooltip_Hide)
  hit:Hide()
  LP.statusHit = hit
  LP.sync = InkButton(LP, L.SYNC_BUTTON, 84, 20, SyncClick)
  LP.sync:SetPoint("BOTTOMRIGHT", -14, 8)
  LP.sync:Hide()
  -- 1.2.0: the button grows with its text like the tabs (84 to GF.SYNC_MAX px; short states like
  -- "Realm blocks whispers"); the status line on the left makes room for it
  local setLabel = LP.sync.SetLabel
  function LP.sync:SetLabel(t)
    local w = math.max(GF.SYNC_MIN, math.min(GF.SYNC_MAX, math.floor((GF.MeasureAt(self.text, t or "", 10) or 60) + 16 + 0.5)))
    self:SetWidth(w)
    setLabel(self, t)   -- fitted in the final width (9 pt or the tooltip only beyond GF.SYNC_MAX)
    LP.status:SetWidth(PAGE_W - 46 - w - 20)
  end
  LP.sync:SetLabel(L.SYNC_BUTTON)
end

-- 1.2.0: tab width from the text (plus room for "  123"), at least as 1.1.0 (104, with friends 132),
-- at most 150 px; the row starts at x = 184 and ends before the "?" (x = 704). If the room is not enough,
-- all get evenly narrower (the text is then truncated, never overlapping).
GF.TAB_X0, GF.TAB_X1, GF.TAB_GAP, GF.TAB_MAX, GF.TAB_ROOM = 184, 704, 4, 150, 34
GF.FIT_PH = { sizes = { 16, 13, 11 } }
-- withCount (1.2.2): width also from the shown text with its number (four digits), the text stays
GF.TAB_BASE5 = 92        -- 1.3.0: with five tabs every tab may be this narrow (repute concept 8.1)
GF.FIT_TAB = { sizes = { 11, 10 } }
GF.tabList = {}
function GF.LayoutTabs(withCount)
  local ws, total = {}, 0
  -- 1.3.0: only the shown tabs, one after the other (the fifth comes and goes with the rap sheet)
  local list = GF.tabList
  for i = #list, 1, -1 do list[i] = nil end
  for _, t in ipairs(F.tabs) do if t:IsShown() then list[#list + 1] = t end end
  local five = #list >= 5
  for i, t in ipairs(list) do
    local cur = withCount and t.text:GetText()
    local cw = cur and math.floor((Look.TextW(t.text) or 0) + 8 + 0.5) or 0
    t.text:SetText(t.label)
    local base = five and math.min(t.base, GF.TAB_BASE5) or t.base
    ws[i] = math.min(GF.TAB_MAX, math.max(base, cw, math.floor(TextWidth(t.text, 60) + GF.TAB_ROOM + 0.5)))
    total = total + ws[i] + (i > 1 and GF.TAB_GAP or 0)
    if cur then t.text:SetText(cur) end
  end
  local room = GF.TAB_X1 - GF.TAB_X0
  if total > room then
    local k = (room - GF.TAB_GAP * (#ws - 1)) / (total - GF.TAB_GAP * (#ws - 1))
    for i = 1, #ws do ws[i] = math.floor(ws[i] * k) end
  end
  local x = GF.TAB_X0
  for i, t in ipairs(list) do
    t:SetWidth(ws[i])
    t.text:SetWidth(ws[i] - 4)
    t:ClearAllPoints()
    t:SetPoint("TOPLEFT", x, -12)
    x = x + ws[i] + GF.TAB_GAP
  end
end

-- head buttons: bone white, red on hover (only the colour changes)
local function HeadButton(text, size, tip)
  local b = CreateFrame("Button", nil, F)
  b:SetSize(22, 22)
  b.text = Look.Text(b, "body", size, Look.BONE)
  b.text:SetPoint("CENTER", 0, 1)
  b.text:SetText(text)
  b:SetScript("OnEnter", function(self)
    self.text:SetTextColor(C(Look.RED_ON_BLACK))
    if tip then GameTooltip:SetOwner(self, "ANCHOR_LEFT"); GameTooltip:SetText(tip); GameTooltip:Show() end
  end)
  b:SetScript("OnLeave", function(self) self.text:SetTextColor(C(Look.BONE)); GameTooltip:Hide() end)
  return b
end

local function Build()
  F = CreateFrame("Frame", "DeathNoteFrame", UIParent, "BackdropTemplate")
  F:SetSize(W, H)
  F:SetFrameStrata("HIGH")
  F:SetClampedToScreen(true)
  F:SetMovable(true)
  F:EnableMouse(true)
  F:RegisterForDrag("LeftButton")
  F:Hide()
  F:SetScript("OnDragStart", function(self) self:StartMoving() end)
  F:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    if self.SetUserPlaced then pcall(self.SetUserPlaced, self, false) end   -- position only in DeathNoteDB
    UX.SavePoint()
  end)
  F:SetScript("OnShow", function()
    Look.Sound("open")
    UX.StartPlatePoll()
    if dirty then Refresh() end
  end)
  F:SetScript("OnHide", function()
    UX.StopPlatePoll()
    HideMenu()
    if P and P.enemy and P.enemy.note:HasFocus() then P.enemy.note:ClearFocus() end
    if LP and LP.search:HasFocus() then LP.search:ClearFocus() end
  end)
  tinsert(UISpecialFrames, "DeathNoteFrame")
  -- 1.2.2: another resolution or UI scale in game: check the largest scale again (the book stays on screen)
  F:RegisterEvent("UI_SCALE_CHANGED")
  F:RegisterEvent("DISPLAY_SIZE_CHANGED")
  F:SetScript("OnEvent", function() ApplyScale() end)

  -- cover
  F:SetBackdrop({ edgeFile = Look.TEX.border, edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 } })
  F:SetBackdropBorderColor(C(Look.COLOR.frameEdge))
  local cover = Tex(F, "BACKGROUND", "cover", -8)
  cover:SetPoint("TOPLEFT", 4, -4); cover:SetPoint("BOTTOMRIGHT", -4, 4)
  -- fold: dark strip between the pages
  local spine = F:CreateTexture(nil, "BORDER")
  spine:SetColorTexture(C(Look.COLOR.fold))
  spine:SetPoint("TOPLEFT", 394, -40)
  spine:SetPoint("BOTTOMLEFT", 394, 10)
  spine:SetWidth(12)

  local title = Look.Text(F, "title", 26, Look.BONE)
  title:SetPoint("TOPLEFT", 22, -9)
  title:SetText(L.BOOK_TITLE)
  title:SetShadowOffset(1, -1)
  title:SetShadowColor(C(Look.COLOR.titleShadow))

  -- close, cog (house rules), "?" (manual)
  local close = HeadButton("×", 22)
  close:SetSize(26, 26)
  close:SetPoint("TOPRIGHT", -8, -9)
  close:SetScript("OnClick", function() Look.Sound("click"); F:Hide() end)

  local gear = CreateFrame("Button", nil, F)
  gear:SetSize(20, 20)
  gear:SetPoint("RIGHT", close, "LEFT", -6, 0)
  local gt = gear:CreateTexture(nil, "ARTWORK")
  gt:SetAllPoints()
  Look.Skin(gt, "gear")
  gt:SetDesaturated(true)
  gt:SetVertexColor(C(Look.BONE))
  gear:SetScript("OnClick", function()
    Look.Sound("click")
    if state.panel == "settings" then UI.ClosePanel() else UI.OpenPanel("settings") end
  end)
  gear:SetScript("OnEnter", function(self)
    gt:SetVertexColor(C(Look.RED_ON_BLACK))
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText(L.HEAD_RULES)
    GameTooltip:Show()
  end)
  gear:SetScript("OnLeave", function()
    gt:SetVertexColor(C(Look.BONE))
    GameTooltip:Hide()
  end)

  local help = HeadButton("?", 16, L.TIP_HELP_BUTTON)
  help:SetSize(20, 20)
  help:SetPoint("RIGHT", gear, "LEFT", -8, 0)
  help:SetScript("OnClick", function()
    Look.Sound("click")
    if state.panel == "help" then UI.ClosePanel() else UI.OpenPanel("help") end
  end)
  F.help = help

  -- tabs: leather flaps on the cover, the active one with a blood-red bottom edge
  F.tabs = {}
  for _, f in ipairs(UX.FILTERS) do
    local t = CreateFrame("Button", nil, F)
    -- 1.2.0: with the friends' book the fourth tab is called "Guild & Friends" and is wider (up to the "?")
    local wide = f.id == "guild" and GF.HasFriends()
    t.base = wide and 132 or 104
    t:SetSize(t.base, 24)
    t.id, t.label = f.id, wide and L.TAB_GUILD_FRIENDS or L[f.key]
    local tb = t:CreateTexture(nil, "BACKGROUND")
    tb:SetAllPoints()
    tb:SetColorTexture(C(Look.COLOR.tabFill))
    local hl = t:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(C(Look.COLOR.tabHi))
    t.mark = t:CreateTexture(nil, "ARTWORK")
    t.mark:SetColorTexture(C(Look.RED, 1))
    t.mark:SetHeight(2)
    t.mark:SetPoint("BOTTOMLEFT", 6, 0); t.mark:SetPoint("BOTTOMRIGHT", -6, 0)
    t.text = Look.Text(t, "body", 11, Look.BONE)
    t.text:SetPoint("CENTER", 0, 1)
    t.text:SetWordWrap(false)
    t:SetScript("OnClick", function(self) Look.Sound("click"); SetFilter(self.id) end)
    Look.TipIfCut(t, t.text)
    if f.id == "record" then t:Hide() end      -- 1.3.0: shown by UX.UpdateTabs from the first own kill on
    F.tabs[#F.tabs + 1] = t
  end
  GF.LayoutTabs()

  UX.BuildLeftPage()

  RP = CreateFrame("Frame", nil, F)
  RP:SetSize(PAGE_W, PAGE_H)
  RP:SetPoint("TOPLEFT", 404, -44)
  local rbg = Tex(RP, "BACKGROUND", "page")
  rbg:SetAllPoints()
  UX.BuildPoster()

  UX.RegisterConfirms()

  UX.AutoScale()
  ApplyScale()
  local pt = Look.Setting("ui.point")
  if type(pt) == "table" and pt[1] then
    F:SetPoint(pt[1], UIParent, pt[2] or pt[1], pt[3] or 0, pt[4] or 0)
  else
    F:SetPoint("CENTER", 0, 40)
  end
  local sort = Look.Setting("ui.sort", "rank")
  if SORT_LABEL[sort] then state.sort = sort end
  local gv = Look.Setting("ui.guildView", "enemy")
  if gv == "member" or gv == "enemy" or (gv == "hunt" and GF.HasHunts()) then state.gview = gv end
  local rs = Look.Setting("ui.recordSort", "recent")
  for _, k in ipairs(RS.SORTS) do if k == rs then state.rsort = rs end end
  local gs = Look.Setting("ui.guildSource", "all")
  if gs == "all" or gs == "guild" or gs == "friends" then state.gsource = gs end
end

function UI.ConfirmDelete(key)
  local e = Store().Get(key)
  if not e then return end
  Confirm("DEATHNOTE_DELETE", Look.Name(e), key)
end

function UI.Toggle()
  if not ready then return end
  if not F then Build() end
  if F:IsShown() then F:Hide() else F:Show() end
end

function UI.Open()
  if not ready then return end
  if not F then Build() end
  if not F:IsShown() then F:Show() end
end

-- scroll the selected row into view
local function ScrollTo(pred)
  for i = 1, #data do
    if pred(data[i]) then
      state.offset = math.max(0, math.min(i - 1, #data - ROWS))
      break
    end
  end
  BindRows()
end

-- open the poster of a given killer (from the journal, the search, the message or from outside)
function UI.ShowEnemy(key)
  local e = ready and Store().Get(key)
  if not e then return end
  UI.Open()
  UI.ClearSearch()
  HideMenu()
  if e.status == "suspect" then state.filter, state.osel = "open", key
  else state.filter, state.selected = "wanted", key end
  state.offset = 0
  if state.panel then UI.ClosePanel(true) end
  Refresh()
  ScrollTo(function(x) return x.key == key end)
end

-- open a death: if open under "Unsolved", otherwise in the Death Log
function UI.ShowCase(d)
  if not ready or type(d) ~= "table" then return end
  UI.Open()
  UI.ClearSearch()
  HideMenu()
  local open = false
  for _, x in ipairs((OpenCases())) do if x == d then open = true; break end end
  if open then state.filter, state.osel = "open", d
  else state.filter, state.deathRef, state.death = "journal", d, nil end
  state.offset = 0
  if state.panel then UI.ClosePanel(true) end
  Refresh()
  ScrollTo(function(x) return x == d end)
end

-- open the hit list (/dn jagd without a name, after posting a call)
function UI.ShowHunts(key)
  if not ready or not GF.HasHunts() then return end
  UI.Open()
  UI.ClearSearch()
  HideMenu()
  state.filter, state.gview = "guild", "hunt"
  if type(key) == "string" then
    state.hselected = key
    -- 1.2.0 fix: a call only for friends with source "Guild" (or the other way round): the source switches to "All"
    if GF.HasFriends() and not GCall("Hunt", key, GF.Src()) and GCall("Hunt", key, "all") then
      state.gsource = "all"
      Set("ui.guildSource", "all")
      mv.dirty = true
      gpart.src = nil
    end
  end
  state.offset = 0
  if state.panel then UI.ClosePanel(true) end
  Refresh()
  if type(key) == "string" then ScrollTo(function(x) return x.key == key end) end
end

------------------------------------------------------------------------
-- Minimap button and AddonCompartment.
-- 1.2.2: with LibDBIcon-1.0 (and LibDataBroker-1.1, both embedded in Libs/) the button is the library's standard
-- button "LibDBIcon10_DeathNote" with a launcher data object "DeathNote": button collectors and LDB displays
-- recognise it and show our tooltip through OnTooltipShow. Without the libraries (tests, a broken zip) the own
-- button "DeathNoteMinimapButton" of 1.2.1 stays. Both read ui.minimap: hide, minimapPos (LibDBIcon) and angle
-- (own button, 1.2.1); Store keeps angle and minimapPos in step.
------------------------------------------------------------------------
local mm                 -- own button (fallback only)
local LDB_NAME = "DeathNote"
local LDB_ICON = Look.TEX.icon   -- Interface\\AddOns\\DeathNote\\Media\\icon.tga
local iconLib            -- LibDBIcon-1.0; false = looked for and missing
local ldbObj             -- our LibDataBroker launcher

function UX.Radius() return Minimap:GetWidth() / 2 + 6 end

local function PlaceAt(deg)
  local a = math.rad(deg)
  local r = UX.Radius()
  mm:ClearAllPoints()
  mm:SetPoint("CENTER", Minimap, "CENTER", math.cos(a) * r, math.sin(a) * r)
end

local function AlarmOn() return Look.Setting("alert.enabled", true) ~= false end

-- the library button, when the libraries are there and it is registered
local function LibButton()
  if not iconLib then return nil end
  local ok, b = pcall(iconLib.GetMinimapButton, iconLib, LDB_NAME)
  return ok and b or nil
end

-- tooltip lines (own button, compartment, LibDBIcon tooltip, LDB displays); drag = the line about dragging
local function FillTip(tt, drag)
  tt:SetText("DeathNote", Look.BONE[1], Look.BONE[2], Look.BONE[3])
  if ready then
    local w, s, _, o = Counts()
    tt:AddLine(Look.Join(Fmt(L.MM_WANTED, { count = w }), (s + o) > 0 and Fmt(L.MM_UNSOLVED, { count = s + o })), 1, 1, 1)
    if not AlarmOn() then tt:AddLine(L.MM_ALERT_OFF, 1, 0.45, 0.4) end
  end
  tt:AddLine(L.MM_CLICK, 0.8, 0.8, 0.8)
  tt:AddLine(L.MM_MIDDLE, 0.8, 0.8, 0.8)
  if drag then tt:AddLine(L.MM_DRAG, 0.6, 0.6, 0.6) end
end

local function MinimapTip(owner)
  GameTooltip:SetOwner(owner, "ANCHOR_LEFT")
  FillTip(GameTooltip, owner == mm)
  GameTooltip:Show()
end

-- alarm on/off (like /dn still); the icon shows "off" half transparent
function UI.ToggleAlarm()
  if not ready then return end
  local on = not AlarmOn()
  Set("alert.enabled", on)
  if ns.Util and ns.Util.Print then ns.Util.Print(on and L.MM_CHAT_ALERT_ON or L.MM_CHAT_ALERT_OFF) end
end

local function Click(mouse)
  if mouse == "RightButton" then
    UI.Open()
    if F then UI.OpenPanel("settings") end
  elseif mouse == "MiddleButton" then
    UI.ToggleAlarm()
  else
    UI.Toggle()
  end
end

-- LibDBIcon-1.0 with its launcher, or nil (then the own button). Looked up once; LibStub is optional.
local function IconLib()
  if iconLib ~= nil then return iconLib or nil end
  iconLib = false
  local LS = rawget(_G, "LibStub")
  if type(LS) ~= "table" then return nil end
  local okB, ldb = pcall(LS, "LibDataBroker-1.1", true)
  local okI, dbi = pcall(LS, "LibDBIcon-1.0", true)
  if not (okB and okI and type(ldb) == "table" and type(dbi) == "table") then return nil end
  local okG, obj = pcall(ldb.GetDataObjectByName, ldb, LDB_NAME)
  if not (okG and type(obj) == "table") then
    local okN
    okN, obj = pcall(ldb.NewDataObject, ldb, LDB_NAME, {
      type = "launcher",
      text = "DeathNote",
      icon = LDB_ICON,
      OnClick = function(_, mouse) Click(mouse) end,
      OnTooltipShow = function(tt)
        if not tt or not tt.AddLine then return end
        -- the drag line only on the minimap button (LDB displays show the same tooltip elsewhere), and not
        -- while LibDBIcon:Lock (another addon) keeps it from moving
        local okO, owner = pcall(function() return tt:GetOwner() end)
        local db = Look.Setting("ui.minimap")
        local locked = type(db) == "table" and db.lock
        FillTip(tt, okO and owner ~= nil and owner == LibButton() and not locked)
      end,
    })
    if not (okN and type(obj) == "table") then return nil end
  end
  ldbObj = obj
  iconLib = dbi
  return dbi
end
UX.IconLib = IconLib

-- active only while dragging
local function DragUpdate(self)
  local mx, my = Minimap:GetCenter()
  if not mx then return end
  local cx, cy = GetCursorPosition()
  local s = Minimap:GetEffectiveScale()
  self.angle = math.deg(math.atan2(cy / s - my, cx / s - mx)) % 360
  PlaceAt(self.angle)
end

function UX.BuildMinimap()
  if not Minimap then return end
  mm = CreateFrame("Button", "DeathNoteMinimapButton", Minimap)
  mm:SetSize(31, 31)
  mm:SetFrameStrata("MEDIUM")
  mm:SetFrameLevel(8)
  mm:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
  local icon = mm:CreateTexture(nil, "ARTWORK")
  icon:SetSize(20, 20)
  icon:SetPoint("TOPLEFT", 6, -5)
  Look.Tex(icon, Look.TEX.icon, Look.FB("icon"))
  mm.icon = icon
  local border = mm:CreateTexture(nil, "OVERLAY")
  border:SetSize(53, 53)
  border:SetPoint("TOPLEFT")
  border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  mm:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp")
  mm:RegisterForDrag("LeftButton")
  mm:SetScript("OnClick", function(_, mouse) Click(mouse) end)
  mm:SetScript("OnEnter", MinimapTip)
  mm:SetScript("OnLeave", GameTooltip_Hide)
  mm:SetScript("OnDragStart", function(self)
    GameTooltip:Hide()
    self.dragging = true
    self:SetScript("OnUpdate", DragUpdate)
  end)
  mm:SetScript("OnDragStop", function(self)
    self:SetScript("OnUpdate", nil)
    self.dragging = false
    if self.angle then
      -- minimapPos too (LibDBIcon's field), so the logout sync in Store keeps this angle
      local db = Look.Setting("ui.minimap")
      if type(db) == "table" then db.minimapPos = math.floor(self.angle + 0.5) % 360 end
      Set("ui.minimap.angle", math.floor(self.angle + 0.5) % 360)
    end
  end)
end

-- the alarm-off look: the icon half transparent (either button)
local function IconAlpha()
  local b = mm or LibButton()
  if b and b.icon then b.icon:SetAlpha(AlarmOn() and 1 or 0.45) end
end

-- LibDBIcon path. Returns false when the library refused (then the own button takes over).
local function UpdateLibButton(lib)
  local db = Look.Setting("ui.minimap")
  if type(db) ~= "table" then return true end
  local b = LibButton()
  if not b then
    if not pcall(lib.Register, lib, LDB_NAME, ldbObj, db) then
      -- LibDBIcon lists the button before it is built: hide the half-built one and take it off the list, so
      -- neither the library nor button collectors keep it next to the own button
      pcall(function()
        local half = type(lib.objects) == "table" and lib.objects[LDB_NAME]
        if half then
          lib.objects[LDB_NAME] = nil
          half:Hide()
        end
      end)
      return false
    end
    b = LibButton()
    if not b then return false end
  elseif b.db ~= db then
    pcall(lib.Refresh, lib, LDB_NAME, db)     -- the settings table was replaced (import, new DB)
  end
  if db.hide then pcall(lib.Hide, lib, LDB_NAME) else pcall(lib.Show, lib, LDB_NAME) end
  return true
end

function UI.UpdateMinimap()
  local lib = not mm and IconLib()
  if lib and UpdateLibButton(lib) then IconAlpha(); return end
  if Look.Setting("ui.minimap.hide", false) then
    if mm then mm:Hide() end
    return
  end
  if not mm then UX.BuildMinimap() end
  if mm then
    PlaceAt(Look.Setting("ui.minimap.angle", 215) or 215)
    IconAlpha()
    mm:Show()
  end
end

-- global names for the TOC fields AddonCompartmentFunc*
function DeathNote_OnCompartmentClick(_, mouse) Click(mouse) end
function DeathNote_OnCompartmentEnter(_, owner) MinimapTip(owner) end
function DeathNote_OnCompartmentLeave() GameTooltip:Hide() end

------------------------------------------------------------------------
-- Bus
------------------------------------------------------------------------
ns:On("READY", function()
  ready = true
  UI.UpdateMinimap()
end)
ns:On("TOGGLE_UI", function() UI.Toggle() end)
-- 1.2.2: enemy plates switched: the status line at once (only the non-guild sheets show the plates line)
ns:On("PLATES_CHANGED", function()
  if F and F:IsShown() and LP then
    if state.filter ~= "guild" then UX.UpdateStatus() end
  else
    dirty = true
  end
end)
ns:On("ENEMY_UPDATED", RequestRefresh)
-- 1.3.0 rap sheet: an own kill, a new standing, rank, path or award, the rap sheet emptied (also while switched off)
for _, ev in ipairs({ "OWN_KILL", "STANDING_CHANGED", "REPUTE_RANK", "REPUTE_PATH", "AWARD" }) do ns:On(ev, RequestRefresh) end
ns:On("LEDGER_CLEARED", function() state.rsel, state.rview = nil, "file"; RequestRefresh() end)
ns:On("DEATH_RECORDED", RequestRefresh)
ns:On("REVENGE", RequestRefresh)
ns:On("GUILD_UPDATED", function() mv.dirty = true; gpart.src = nil; RequestRefresh() end)
ns:On("GUILD_SIGHTING", function() if state.filter == "guild" then RequestRefresh() end end)
ns:On("HUNT_BAGGED", function() if state.filter == "guild" then RequestRefresh() end end)
-- the store moves an entry to a new key: selection and note field move with it
ns:On("ENEMY_REKEYED", function(old, new)
  if type(old) ~= "string" or type(new) ~= "string" or old == new then return end
  if state.selected == old then state.selected = new end
  if state.osel == old then state.osel = new end
  if P and P.enemy and P.enemy.note.key == old then P.enemy.note.key = new end
  if P and P.enemy and P.enemy.specSig and P.enemy.specSig:find("\0" .. old .. "\0", 1, true) then P.enemy.specSig = nil end
  RequestRefresh()
end)
ns:On("SETTINGS_CHANGED", function(path)
  if type(path) == "string" and path:find("^ui%.minimap") and not (mm and mm.dragging == false and path == "ui.minimap.angle") then
    UI.UpdateMinimap()
  end
  if path == "alert.enabled" then IconAlpha() end
  if path == "ui.scale" then ApplyScale() end
  if path == "ledger.enabled" then RequestRefresh() end
  if path == "ui.guildCollapsed" then collapseVer = collapseVer + 1; if MemberView() then RequestRefresh() end end
  if type(path) == "string" and path:find("^guild%.") then RequestRefresh() end
  if F and F:IsShown() and state.panel == "settings" then UI.FillSettings() end
end)
