local ADDON, ns = ...

-- 1.6.4 move: the placing mode (the anchors). /dn move (also unlock, verschieben, anchors, anchor, anker; or the button
-- on the House Rules, sheet Alert) shows the pieces of the
-- addon that stand free on the screen as samples with made-up content: the alarm, the notice after a death or a
-- revenge, the slip of a help call, the grudge notice. Each sample is dragged with the left mouse button and says
-- so on itself under its name; its place is kept when it is dropped (alert.point, notice.point, call.point,
-- grudge.point). A bar above the action bars (it makes room for the samples, Place.PlaceBar) says what to do and
-- carries "Reset positions" and "Done".
-- Done: a right click on a sample or the bar, Esc, "Done", or the command again. The mode also ends cleanly, before
-- anything else happens, when combat starts, the player dies, a loading screen comes, the book opens, or a new real
-- alarm, notice, help call or grudge notice comes (each of those then runs as always; except for the book one chat line
-- says the mode ended). It never starts in combat (one chat line says so). Alarms standing or waiting when it starts
-- give way (Alert.ShowSample).
-- The secure button of the alarm stays hidden for the whole mode: the sample has nobody to target, so there is
-- never a click area without the alarm under it. Nothing is sent, nothing is saved but the four places.
-- Every call into the pieces goes through pcall: an error costs the sample, never the book, the alarm or the
-- death detection. Unmeasured in the game: counters in the saved data, DeathNoteDB.probe.move (numbers only; /dn probe
-- keeps them, it does not print them).

local Look = ns.Look
local L, Fmt = ns.L, ns.F
local Place = {}
ns.Place = Place

Place.BAR_W, Place.BAR_H = 380, 98
Place.BAR_POINT = { "BOTTOM", "BOTTOM", 0, 160 }   -- above the action bars; makes room for the samples (Place.PlaceBar)
Place.BAR_GAP = 10
Place.BAR_LOW = "MEDIUM"   -- the bar's layer when it finds no free place: below the samples (HIGH, DIALOG)
Place.FIT_HEAD = { sizes = { 10, 9 } }
Place.FIT_HOW = { sizes = { 11, 10 }, lines = 2, wrapFirst = true }
Place.BTN_H = 22
Place.FIT_MEASURE = { sizes = { 10 } }
-- the four pieces in the order they are shown (the slip makes room for the alarm, the notice for both)
Place.PIECES = { "Alert", "CallUI", "Extras", "GrudgeCard" }
Place.COUNTS = { "start", "combat", "reset", "error", "stop_cmd", "stop_click", "stop_esc", "stop_done",
  "stop_combat", "stop_death", "stop_book", "stop_world", "stop_test", "stop_alert", "stop_notice", "stop_call", "stop_grudge",
  "drag_alert", "drag_notice", "drag_call", "drag_grudge" }
local COUNT_OK = {}
for _, k in ipairs(Place.COUNTS) do COUNT_OK[k] = true end

local active = false
local bar

local function G(n) return rawget(_G, n) end
local function InCombat() local f = G("InCombatLockdown"); return f and f() and true or false end
local function Print(s) if ns.Util and ns.Util.Print and type(s) == "string" then ns.Util.Print(s) end end

-- Probe (DeathNoteDB.probe.move): how often the mode ran, how it ended, which piece was dragged (kept over sessions)
function Place.Count(name)
  if not COUNT_OK[name] then return end
  local db = ns.Store and ns.Store.DB and ns.Store.DB()
  if type(db) ~= "table" then return end
  if type(db.probe) ~= "table" then db.probe = {} end
  local p = db.probe.move
  if type(p) ~= "table" then p = {}; db.probe.move = p end
  if type(p.counts) ~= "table" then p.counts = {} end
  local v = p.counts[name]
  p.counts[name] = math.min(1e9, (type(v) == "number" and v or 0) + 1)
end

local function Call(piece, fn, ...)
  local M = ns[piece]
  if not (M and M[fn]) then return nil end
  local ok, res = pcall(M[fn], ...)
  if not ok then
    Place.Count("error")
    if ns.ReportError then pcall(ns.ReportError, res) end
    return nil
  end
  return res
end

function Place.Active() return active end

-- the bar: what to do, "Reset positions", "Done"; named for Esc (UISpecialFrames)
local function BuildBar()
  local bar = CreateFrame("Frame", "DeathNoteMove", UIParent)
  bar:SetSize(Place.BAR_W, Place.BAR_H)
  bar:SetFrameStrata("DIALOG")
  bar:SetClampedToScreen(true)
  bar:EnableMouse(true)
  local p = Place.BAR_POINT
  bar:SetPoint(p[1], UIParent, p[2], p[3], p[4])
  bar:Hide()
  local bg = bar:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  Look.Skin(bg, "slip")
  Look.Tint(bg, Look.TINT.slip or Look.TINT.paper)
  bar.head = Look.Text(bar, "body", 10, Look.RED_INK)
  bar.head:SetPoint("TOP", 0, -9)
  bar.head:SetWidth(Place.BAR_W - 60)
  bar.head:SetWordWrap(false)
  bar.how = Look.Text(bar, "body", 11, Look.INK)
  bar.how:SetPoint("TOP", bar.head, "BOTTOM", 0, -4)
  bar.how:SetWidth(Place.BAR_W - 60)
  bar.how:SetJustifyH("CENTER")
  local Kit = ns.UI and ns.UI.Kit
  local function button(onClick)
    local b
    if Kit and Kit.InkButton then
      b = Kit.InkButton(bar, "", 120, Place.BTN_H, onClick)
    else
      b = CreateFrame("Button", nil, bar)
      b:SetSize(120, Place.BTN_H)
      b.text = Look.Text(b, "body", 10, Look.INK)
      b.text:SetPoint("CENTER", 0, 0)
      b:SetScript("OnClick", onClick)
      function b:SetLabel(t) self.text:SetText(t or "") end
    end
    return b
  end
  bar.reset = button(function() Place.Reset() end)
  bar.done = button(function() Place.Stop("done") end)
  bar:SetScript("OnMouseUp", function(_, mouse) if mouse == "RightButton" then Place.Stop("click") end end)
  -- the bar can be dragged aside for the time of the mode (its place is not kept; the next start places it anew)
  bar:SetMovable(true)
  bar:RegisterForDrag("LeftButton")
  bar:SetScript("OnDragStart", function(self) if not InCombat() then self:StartMoving() end end)
  bar:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    if self.SetUserPlaced then pcall(self.SetUserPlaced, self, false) end
  end)
  -- Esc hides the bar (UISpecialFrames): that ends the mode; a hide by Place.Stop itself finds it ended already
  bar:SetScript("OnHide", function() if active then Place.Stop("esc") end end)
  local special = G("UISpecialFrames")
  if type(special) == "table" then
    local listed = false
    for _, n in ipairs(special) do if n == "DeathNoteMove" then listed = true end end
    if not listed then table.insert(special, "DeathNoteMove") end
  end
  return bar
end

-- the words of the bar in the active language (also after a change of language)
function Place.FillBar()
  if not bar then return end
  L, Fmt = ns.L, ns.F
  local Ex = ns.Extras
  Look.FitText(bar.head, Ex and Ex.Spaced and Ex.Spaced(L.MOVE_HEAD) or L.MOVE_HEAD, Place.FIT_HEAD)
  Look.FitText(bar.how, L.MOVE_HOW, Place.FIT_HOW)
  -- the button as wide as its word at 10 pt (between min and max; a longer word shrinks, the tooltip has it whole)
  local function width(b, text, min, max)
    Look.FitText(b.text, text, Place.FIT_MEASURE)
    local w = Look.TextW(b.text)
    if type(w) ~= "number" then w = min - 16 end
    b:SetWidth(math.max(min, math.min(max, math.ceil(w + 16))))
    b:SetLabel(text)
  end
  width(bar.reset, L.MOVE_RESET, 132, 180)
  width(bar.done, L.MOVE_DONE, 96, 140)
  local gap = 10
  local total = bar.reset:GetWidth() + gap + bar.done:GetWidth()
  bar.reset:ClearAllPoints()
  bar.reset:SetPoint("BOTTOMLEFT", bar, "BOTTOM", -total / 2, 12)
  bar.done:ClearAllPoints()
  bar.done:SetPoint("LEFT", bar.reset, "RIGHT", gap, 0)
end

function Place.Bar() return bar end

-- the bar never covers a sample and always lies wholly on the screen: its default place when that is free, else the
-- nearest free place below, above or beside a sample; when there is none, the default place on a lower layer (under
-- the samples, never off the screen). All in UIParent units.
function Place.PlaceBar()
  if not bar then return end
  local p = Place.BAR_POINT
  bar:SetFrameStrata("DIALOG")
  bar:ClearAllPoints()
  bar:SetPoint(p[1], UIParent, p[2], p[3], p[4])
  local l, b, r, t = Look.Rect(bar)
  local W, H = UIParent:GetWidth(), UIParent:GetHeight()
  if not l or type(W) ~= "number" or type(H) ~= "number" or Look.Secret(W) or Look.Secret(H) then return end
  local w, h, gap = r - l, t - b, Place.BAR_GAP
  local rects = {}
  for _, n in ipairs({ "DeathNoteAlert", "DeathNoteBanner", "DeathNoteCall", "DeathNoteGrudge" }) do
    local f = G(n)
    if f and f.IsShown and f:IsShown() then
      local fl, fb, fr, ft = Look.Rect(f)
      if fl then rects[#rects + 1] = { fl, fb, fr, ft } end
    end
  end
  local function free(x, y)
    if x < 0 or y < 0 or x + w > W or y + h > H then return false end
    for _, q in ipairs(rects) do
      if x < q[3] + gap and x + w > q[1] - gap and y < q[4] + gap and y + h > q[2] - gap then return false end
    end
    return true
  end
  if free(l, b) then return end
  local cands = {}
  for _, q in ipairs(rects) do
    cands[#cands + 1] = { l, q[2] - gap - h }
    cands[#cands + 1] = { l, q[4] + gap }
    cands[#cands + 1] = { q[1] - gap - w, b }
    cands[#cands + 1] = { q[3] + gap, b }
  end
  table.sort(cands, function(x, y) return math.abs(x[1] - l) + math.abs(x[2] - b) < math.abs(y[1] - l) + math.abs(y[2] - b) end)
  for _, c in ipairs(cands) do
    if free(c[1], c[2]) then
      bar:ClearAllPoints()
      bar:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", c[1], c[2])
      return
    end
  end
  -- no free place (a small screen, the samples stacked over it): the bar lies under the samples, so every sample
  -- stays to be grabbed; the bar itself can be dragged aside (its place is not kept)
  bar:SetFrameStrata(Place.BAR_LOW)
end

-- Esc ends the mode even without the bar: a frame of its own, one pixel, no mouse, no text (nothing in it can fail
-- the way the bar's words could), named in UISpecialFrames, shown while the mode runs
local esc
local function EscFrame()
  if esc then return esc end
  local f = CreateFrame("Frame", "DeathNoteMoveEsc", UIParent)
  f:SetSize(1, 1)
  f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
  f:EnableMouse(false)
  f:Hide()
  f:SetScript("OnHide", function() if active then Place.Stop("esc") end end)
  local special = G("UISpecialFrames")
  if type(special) == "table" then
    local listed = false
    for _, n in ipairs(special) do if n == "DeathNoteMoveEsc" then listed = true end end
    if not listed then table.insert(special, "DeathNoteMoveEsc") end
  end
  esc = f
  return f
end

function Place.Start()
  if active then return true end
  L, Fmt = ns.L, ns.F
  if InCombat() then
    Print(L.MOVE_COMBAT)
    Place.Count("combat")
    return false
  end
  -- the book lies on the layer of the samples: it closes (opening it again ends the mode)
  local book = G("DeathNoteFrame")
  if book and book.IsShown and book:IsShown() then book:Hide() end
  active = true
  Place.Count("start")
  for _, piece in ipairs(Place.PIECES) do Call(piece, "ShowSample") end
  local okE, e = pcall(EscFrame)
  if okE and e then e:Show() end
  -- 1.6.4 fixer: built into a local frame and kept only when whole; a half-built one is hidden and the next start
  -- builds anew (the mode runs without the bar meanwhile: right click, the command)
  if not bar then
    local ok, res = pcall(BuildBar)
    if ok then
      bar = res
    else
      Place.Count("error")
      if ns.ReportError then pcall(ns.ReportError, res) end
      local half = G("DeathNoteMove")
      if half and half.Hide then pcall(half.Hide, half) end
      -- without the bar a chat line names the ways out (right click, Esc, the command)
      Print(L.MOVE_HOW)
    end
  end
  if bar then
    pcall(Place.FillBar)
    bar:Show()
    pcall(Place.PlaceBar)
  end
  return true
end

-- why: cmd, click, esc, done, combat, death, book, world, test, alert, notice, call, grudge
-- an end by something real (not by the player): one chat line says so and how to start again; not after the player's
-- own test alarm or test grudge notice ("test": the test alarm brings its own line on how to move it)
Place.BY_EVENT = { alert = true, notice = true, call = true, grudge = true, combat = true, death = true, world = true }
function Place.Stop(why)
  if not active then return end
  active = false
  why = tostring(why or "cmd")
  Place.Count("stop_" .. why)
  for _, piece in ipairs(Place.PIECES) do Call(piece, "EndSample") end
  if bar and bar:IsShown() then bar:Hide() end
  if esc and esc:IsShown() then esc:Hide() end
  if Place.BY_EVENT[why] then L = ns.L; Print(L.MOVE_ENDED) end
end

function Place.Toggle()
  if active then Place.Stop("cmd") else Place.Start() end
end

-- every place back to its default (also the grudge notice's); not in combat (the alarm's button could not follow)
function Place.Reset()
  L, Fmt = ns.L, ns.F
  if InCombat() then Print(L.MOVE_COMBAT); Place.Count("combat"); return false end
  Place.Count("reset")
  Call("Alert", "ResetPosition")
  Call("CallUI", "ResetPosition")
  Call("Extras", "ResetPosition")
  Call("GrudgeCard", "ResetPosition")
  Call("ShareUI", "ResetPosition")
  if active then pcall(Place.PlaceBar) end
  Print(L.MOVE_RESET_DONE)
  return true
end

-- a sample was dropped: count it; after the alarm the slip and the notice make room again (as for a real alarm)
function Place.Moved(what)
  Place.Count("drag_" .. tostring(what))
  if what == "alert" then
    Call("CallUI", "Place")
    Call("Extras", "PlaceBanner")
  elseif what == "call" then
    Call("Extras", "PlaceBanner")
  end
  pcall(Place.PlaceBar)
end

-- /dn move [word]: nothing toggles; reset (also the German word, with and without the umlaut; the umlaut as bytes, the
-- locale guard keeps umlauts out of the code), on/an start, off/aus/done/fertig end; any other word changes nothing
-- and shows the help line
Place.RESET_WORDS = { reset = true, zuruecksetzen = true, ["zur\195\188cksetzen"] = true }
Place.ON_WORDS = { on = true, an = true }
Place.OFF_WORDS = { off = true, aus = true, done = true, fertig = true }
function Place.Slash(rest)
  L, Fmt = ns.L, ns.F
  rest = type(rest) == "string" and rest:lower():gsub("^%s+", ""):gsub("%s+$", "") or ""
  if rest == "" then Place.Toggle()
  elseif Place.RESET_WORDS[rest] then Place.Reset()
  elseif Place.ON_WORDS[rest] then Place.Start()
  elseif Place.OFF_WORDS[rest] then Place.Stop("cmd")
  else Print(L.HELP_MOVE) end
end

ns:RegisterEvent("PLAYER_REGEN_DISABLED", function() Place.Stop("combat") end)
ns:RegisterEvent("PLAYER_DEAD", function() Place.Stop("death") end)
-- a loading screen (instance, battleground, arena, portal) ends the mode too
ns:RegisterEvent("PLAYER_ENTERING_WORLD", function() Place.Stop("world") end)
