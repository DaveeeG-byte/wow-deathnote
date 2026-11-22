-- DeathNote - FatesUI.lua (1.6.0 deaths)
-- The death log's views (tab 3): "Players | All | Causes" at the top right (default: All). All = the deaths by
-- players and the deaths by creatures and the world, mixed by time, each with a small sign of its kind (the skull for
-- players; FatesUI draws the others from Media/fates.tga). Causes = "What else kills you": the creatures and the
-- world ranked by deaths, last place, last spell; number one carries a stamp from NEMESIS deaths on. No alarm, no
-- poster, no hit list. The awards for dying stand in a row of their own on the rap sheet's file.
-- The book's row and page kit comes from UI.lua (UI.JK); the hooks there call FU.Journal, FU.BindRow, FU.FillDeath,
-- FU.Layout and FU.Awards (each in pcall: an error here never breaks the book).

local _, ns = ...
local L, Fmt = ns.L, ns.F
local Look = ns.Look

local FU = {}
ns.FatesUI = FU

FU.VIEWS = { { "players", "FATE_VIEW_PLAYERS" }, { "all", "FATE_VIEW_ALL" }, { "causes", "FATE_VIEW_CAUSES" } }
-- cells of Media/fates.tga (eight 32x32 cells in one strip)
FU.CELL = { creature = 0, pet = 1, fall = 2, drown = 3, fire = 4, lava = 4, fatigue = 5, slime = 6, other = 6, unknown = 7 }
FU.CELLS = 8
FU.TEX = "fates.tga"
FU.STAMP = { "FATE_STAMP", 9, 1, "rache" }
FU.HEAD_W = 220             -- head of a cause's file: 352 px page minus the margins and the date on the right
FU.FIT_HEAD = { sizes = { 26, 22, 19, 16, 14 } }   -- the stamp of number one: frame of "rache", the word in every language

local function K() return ns.UI and ns.UI.JK end
local function C(t, a) return t[1], t[2], t[3], a or t[4] or 1 end

function FU.Mode()
  local v = Look.Setting("ui.journalView", "all")
  if v ~= "players" and v ~= "causes" then v = "all" end
  return v
end

function FU.SetMode(v)
  if v ~= "players" and v ~= "all" and v ~= "causes" then return end
  if FU.Mode() == v then return end
  if ns.Store and ns.Store.Setting then ns.Store.Setting("ui.journalView", v) end
  local k = K()
  if not k then return end
  local st = k.state
  st.offset, st.death, st.deathRef = 0, nil, nil
  k.Refresh()
end

-- the list of the death log in the chosen view; count = the tab's number (the deaths, also in the view Causes)
function FU.Journal(list, count)
  local Fa = ns.Fates
  if not Fa then return list end
  local m = FU.Mode()
  -- a death asked for from outside (the map's pin, the death message: UI.ShowCase) while the view shows causes:
  -- the view All, where it stands
  local k = K()
  local ref = k and k.state.filter == "journal" and k.state.deathRef
  if m == "causes" and not count and type(ref) == "table" and not ref.foe then
    if ns.Store and ns.Store.Setting then ns.Store.Setting("ui.journalView", "all") end
    m = "all"
  end
  if m == "players" then return list end
  if m == "causes" and not count then return Fa.Ranked() end
  return Fa.Merged(list)
end

------------------------------------------------------------------------
-- The view words (top right of the left page, pattern of the guild's views)
------------------------------------------------------------------------
local function build(LP, PAGE_W)
  local k = K()
  local views = CreateFrame("Frame", nil, LP)
  views:SetSize(180, 22)
  views:SetPoint("TOPRIGHT", -14, -10)
  views.items = {}
  local gap, ws, total = 8, {}, 0
  for i, v in ipairs(FU.VIEWS) do
    local b = k.WordTab(views, L[v[2]], 70, function(self) FU.SetMode(self.view) end)
    b.view = v[1]
    b.fateView = true
    ws[i] = math.max(36, k.TextWidth(b.text, 60) + 6)
    total = total + ws[i] + (i > 1 and gap or 0)
    views.items[i] = b
  end
  local room = PAGE_W - 14 - 46 - 8 - 70
  local f = total > room and (room - gap * (#ws - 1)) / (total - gap * (#ws - 1)) or 1
  local prev
  for i = #views.items, 1, -1 do
    local b = views.items[i]
    local w = math.floor(ws[i] * f)
    b:SetSize(w, 20)
    if f < 1 then
      b.text:SetWidth(w - 4); b.text:SetWordWrap(false)
      Look.FitText(b.text, L[FU.VIEWS[i][2]], { sizes = { 11, 10 } })
      Look.TipIfCut(b, b.text)
    end
    if prev then b:SetPoint("RIGHT", prev, "LEFT", -gap, 0) else b:SetPoint("RIGHT", 0, 0) end
    prev = b
  end
  views.width = math.min(total, room)
  views:Hide()
  return views
end

-- shows the words on the death log; returns the search field's width (it gives way), nil elsewhere
function FU.Layout(LP, journal, sw, PAGE_W)
  if not (K() and ns.Fates) then return nil end
  local v = FU.views
  if not v then
    if not journal then return nil end
    v = build(LP, PAGE_W or 380)
    FU.views = v
  end
  v:SetShown(journal and true or false)
  if not journal then return nil end
  local m = FU.Mode()
  for _, b in ipairs(v.items) do b:SetOn(b.view == m) end
  return math.max(60, math.min(sw or 200, (PAGE_W or 380) - 14 - v.width - 46 - 8))
end

------------------------------------------------------------------------
-- Rows
------------------------------------------------------------------------
function FU.CellOf(c)
  if type(c) ~= "table" then return FU.CELL.unknown end
  if c.art == "env" then return FU.CELL[c.env or "other"] or FU.CELL.other end
  return FU.CELL[c.art] or FU.CELL.unknown
end

-- the small sign of the kind: left where the skull stands (a death), right where the class icon stands (a cause)
local function sign(r, c, right)
  local t = r.fateSign
  if not t then
    t = r:CreateTexture(nil, "ARTWORK")
    Look.Tex(t, Look.MEDIA .. FU.TEX, Look.FB("skull"))
    local tint = Look.COLOR and Look.COLOR.skullTint
    if tint and not t.dnFlat then t:SetVertexColor(C(tint)) end
    t.fatePart = true
    r.fateSign = t
  end
  local cell = FU.CellOf(c)
  t:SetTexCoord(cell / FU.CELLS, (cell + 1) / FU.CELLS, 0, 1)
  t:ClearAllPoints()
  if right then
    t:SetSize(16, 16)
    t:SetPoint("TOPRIGHT", -8, -3)
  else
    t:SetSize(18, 18)
    t:SetPoint("TOPLEFT", 12, -2)
  end
  t:Show()
end

local function where(d) return Look.Join(Look.When(d.t), Look.Place(d.zone, d.subzone)) end

-- a death by a creature or the world, an unclear death with a pet's killing blow, a cause of the ranking.
-- Returns true when it bound the row.
function FU.BindRow(r, d, index)
  local Fa, k = ns.Fates, K()
  if not (Fa and k) or type(d) ~= "table" then return false end
  k.SetRowMode(r, "normal")
  r.skull:Hide(); r.icon:Hide(); r.coin:Hide(); r.strike:Hide()
  if d.foe then
    k.SetRank(r, not d.solo and d.rank or nil)
    local spell = d.spell and Fmt(L.FATE_SPELL, { spell = tostring(d.spell) }) or nil
    k.SetRow(r, Fa.Name(d), Look.Join(Look.Place(d.zone, d.subzone), spell), Look.Times(d.n), "normal", true)
    sign(r, d, true)
  elseif d.art then
    k.SetRank(r, nil)
    local tone, mark, ink = "normal", Fa.ArtWord(d.art), true
    if d.counted == false then tone, mark = "pale", L.MARK_NOT_COUNTED end
    k.SetRow(r, Fa.Name(d), where(d), mark, tone, ink)
    sign(r, d, false)
  elseif type(d.cause) == "table" and d.kind ~= "pvp" then
    -- an unclear death of the journal (no player named): as before, with the sign of what dealt the blow
    k.SetRank(r, nil)
    local mark = Fa.ArtWord(d.cause.art)
    if d.counted == false then mark = L.MARK_NOT_COUNTED end
    k.SetRow(r, L.ROW_UNCLEAR, where(d), mark, "pale", true)
    sign(r, d.cause, false)
  else
    return false
  end
  r.under:SetShown(k.state.death == index)
  r.under:SetWidth(k.InkWidth(r.name))
  return true
end

------------------------------------------------------------------------
-- The file on the right page
------------------------------------------------------------------------
local function stampOf(D, k)
  local s = D.fateStamp
  if s then return s end
  k.GF.STAMPS.fate = k.GF.STAMPS.fate or FU.STAMP
  s = D.sheet:CreateTexture(nil, "ARTWORK", nil, 2)
  s:SetSize(140, 70)
  s.fatePart = true
  k.GF.StampLabel(D.sheet, s)
  s:Hide()
  D.fateStamp = s
  return s
end

-- the switch fates.on in the file's foot (a death by a creature or the world, a cause): every sheet of the House Rules
-- is full (Book: a row more scrolls in German; Rap Sheet: the section NAMEPLATE fills it; Alarm: 7 px left; Guild only
-- with a guild), so it stands where those deaths are shown
local function switchOf(D, k)
  local cb = D.fateSwitch
  if cb then return cb end
  cb = k.InkCheck(D.page.foot, L.OPT_FATES, 304)
  cb:SetPoint("BOTTOMLEFT", 20, 14)
  cb.label:SetWidth(276)
  cb.label:SetJustifyH("LEFT")
  cb.label:SetWordWrap(false)
  Look.FitText(cb.label, L.OPT_FATES, { sizes = { 11, 10 } })
  Look.TipIfCut(cb, cb.label)
  cb.opt = { path = "fates.on", def = true }
  cb.fatePart = true
  cb:SetScript("OnClick", function(self)
    local on = self:GetChecked() and true or false
    self.cross:SetShown(on)
    if ns.Store and ns.Store.Setting then ns.Store.Setting("fates.on", on) end
    Look.Sound("click")
  end)
  cb:Hide()
  D.fateSwitch = cb
  return cb
end

-- design fix 1.6.0: the file of a creature or the world fills its sheet with what the book knows of that cause:
-- "DEATHS BY THIS CAUSE" with the count, the latest FU.HIST deaths (date, place, spell), the first and the last one.
-- Nothing new is recorded: the rows of Fates.Rows (capped at Fates.MAX_ROWS), read once when the file opens.
FU.HIST = 3
function FU.History(d)
  local Fa = ns.Fates
  if not (Fa and Fa.Rows and Fa.FoeKey) or type(d) ~= "table" then return {}, 0 end
  local key = d.foe and d.key or Fa.FoeKey(d)
  local out, first = {}, nil
  for _, r in ipairs(Fa.Rows()) do
    if type(r) == "table" and Fa.FoeKey(r) == key then
      if #out < FU.HIST then out[#out + 1] = r end
      first = r
    end
  end
  local n = d.foe and tonumber(d.n) or nil
  if not n then
    local f = Fa.DB and Fa.DB()
    local foe = f and f.foes and f.foes[key]
    n = foe and tonumber(foe.n) or #out
  end
  out.first = first
  return out, n
end

local function histOf(D, k)
  local H = D.fateHist
  if H then return H end
  local S = D.sheet
  H = { rows = {} }
  H.label = k.Label(S, L.FATE_LIST_HEAD)
  H.label.fatePart = true
  H.count = Look.Text(S, "hand", 19, Look.INK)
  H.count:SetJustifyH("RIGHT")
  H.count.fatePart = true
  H.rule = S:CreateTexture(nil, "ARTWORK")
  H.rule:SetHeight(1)
  H.rule:SetColorTexture(C(Look.INK, 0.45))
  H.rule.fatePart = true
  for i = 1, FU.HIST do
    local fs = Look.Text(S, "type", 11, Look.INK)
    fs:SetWidth(304)
    fs:SetJustifyH("LEFT")
    fs:SetWordWrap(false)
    fs.fatePart = true
    H.rows[i] = fs
  end
  H.span = Look.Text(S, "type", 11, Look.INK)
  H.span:SetTextColor(C(Look.INK, Look.TONE.sub))
  H.span:SetWidth(304)
  H.span:SetJustifyH("LEFT")
  H.span.fatePart = true
  -- the negation ("not a player, no alarm, nothing is shared") as a small line above the switch in the foot
  H.foot = Look.Text(D.page.foot, "type", 10, Look.INK)
  H.foot:SetTextColor(C(Look.INK, Look.TONE.sub))
  H.foot:SetPoint("BOTTOMLEFT", 24, 36)
  H.foot:SetWidth(304)
  H.foot:SetJustifyH("LEFT")
  H.foot.fatePart = true
  D.fateHist = H
  return H
end

local function hideHist(D)
  local H = D.fateHist
  if not H then return end
  H.label:Hide(); H.count:Hide(); H.rule:Hide(); H.span:Hide(); H.foot:Hide()
  for _, fs in ipairs(H.rows) do fs:Hide() end
end

-- the list below the file's lines from y (sheet units); returns the new y
local function fillHist(D, k, d, y)
  local H = histOf(D, k)
  local list, n = FU.History(d)
  local S = D.sheet
  H.label:ClearAllPoints()
  H.label:SetPoint("TOPLEFT", S, "TOPLEFT", 24, -(y + 16))
  H.label:Show()
  H.count:ClearAllPoints()
  H.count:SetPoint("BOTTOMRIGHT", S, "TOPRIGHT", -24, -(y + 26))
  H.count:SetText(Look.Times(n))
  H.count:Show()
  H.rule:ClearAllPoints()
  H.rule:SetPoint("TOPLEFT", S, "TOPLEFT", 20, -(y + 28))
  H.rule:SetWidth(312)
  H.rule:Show()
  y = y + 34
  for i, fs in ipairs(H.rows) do
    local r = list[i]
    if r then
      local spell = r.spell and tostring(r.spell) or nil
      Look.FitText(fs, Look.Join(Look.When(r.t), Look.Place(r.zone, r.subzone), spell), { sizes = { 11, 10 } })
      fs:ClearAllPoints()
      fs:SetPoint("TOPLEFT", S, "TOPLEFT", 24, -y)
      fs:Show()
      y = y + 17
    else
      fs:Hide()
    end
  end
  local first = list.first
  if first and list[1] and first ~= list[1] then
    H.span:SetText(Fmt(L.FATE_FIRST_LAST, { first = Look.When(first.t), last = Look.When(list[1].t) }))
    H.span:ClearAllPoints()
    H.span:SetPoint("TOPLEFT", S, "TOPLEFT", 24, -(y + 4))
    H.span:Show()
    y = y + 4 + 15
  else
    H.span:Hide()
  end
  return y
end

-- after FillDeath (UI.lua): the cause's own lines; any other file gets its head back and no stamp
function FU.FillDeath(D, d, nInfo)
  local Fa, k = ns.Fates, K()
  if D.fateHead then D.fateHead:Hide(); D.head:Show() end
  if D.fateStamp and k then k.GF.ShowStamp(D.fateStamp, false) end
  if D.fateSwitch then D.fateSwitch:Hide() end
  hideHist(D)
  if not (Fa and k) or type(d) ~= "table" then return end
  if not (d.art or d.foe) then
    if type(d.cause) == "table" and d.kind ~= "pvp" and d.cause.art == "pet" then
      D.note:SetText(Fmt(L.FATE_NOTE_PET, { name = Fa.Name(d.cause) }))
    elseif type(d.cause) == "table" and d.kind ~= "pvp" and d.cause.art == "env" then
      -- 1.6.0 fix: a player hurt you and the world dealt the blow: the death stays in the book, the world is a note
      D.note:SetText(Fmt(L.FATE_NOTE_ENV, { name = Fa.Name(d.cause) }))
    end
    return
  end
  local sw = switchOf(D, k)
  sw:SetInk(Fa.On())
  sw:Show()
  local art = d.art or "unknown"
  D.killLabel:SetText(k.Spaced(Fa.ArtWord(art)))
  Look.FitText(D.killer.text, Fa.Name(d), k.FIT_NAME26)
  D.killer.key = nil
  local lines = nInfo or 1
  if d.foe then
    -- an own head in place of the death file's (that one stays as it is): it gives way to the date on the right
    local h = D.fateHead
    if not h then
      h = Look.Text(D, "head", 26, Look.INK)
      h:SetPoint("TOPLEFT", 24, -16)
      h:SetWidth(FU.HEAD_W)
      h:SetJustifyH("LEFT")
      h.fatePart = true
      D.fateHead = h
    end
    Look.FitText(h, L.FATE_HEAD, FU.FIT_HEAD)
    D.head:Hide()
    h:Show()
    local place = (D.info:GetText() or ""):match("^[^\n]*") or ""
    local info = { place, Fmt(L.FATE_KILLED, { times = Look.Times(d.n) }) }
    if d.spell then info[#info + 1] = Fmt(L.TIP_CAUSE, { spell = tostring(d.spell) }) end
    -- design fix 1.6.0: no NPC id on the file (technique without use for the player; it stays in the data), and
    -- no line that explains the list: the foot says what the book does not do, the list below what it knows
    D.info:SetText(table.concat(info, "\n"))
    lines = #info
    D.note:SetText("")
    -- the date on the right is the latest death by this cause
    if d.t then D.when:SetText(Fmt(L.FATE_LAST, { time = Look.When(d.t) })) end
    local function fit()
      local ww = Look.TextW(D.when)
      if type(ww) == "number" and not Look.Secret(ww) then
        h:SetWidth(math.max(140, math.min(FU.HEAD_W, 304 - math.ceil(ww) - 10)))
      end
      return Look.FitText(h, L.FATE_HEAD, FU.FIT_HEAD)
    end
    -- the head is never cut for the word: without room the date stands alone, as on every other file
    if not fit() and d.t then D.when:SetText(Look.When(d.t)); fit() end
  else
    D.note:SetText("")
  end
  local y = 62 + Look.TextH(D.info, lines) + 16 + 12 + 2 + 32 + 2 + Look.TextH(D.note, 2)
  -- design fix 1.6.0: what the book knows of this cause, the negation small in the foot
  local ok, ny = pcall(fillHist, D, k, d, y)
  if ok and type(ny) == "number" then y = ny end
  if D.fateHist then
    Look.FitText(D.fateHist.foot, L.FATE_NOTE, { sizes = { 10, 9 } })
    D.fateHist.foot:Show()
  end
  -- number one with NEMESIS deaths or more: the stamp below the lines
  if d.foe and d.rank == 1 and (tonumber(d.n) or 0) >= Fa.NEMESIS then
    local s = stampOf(D, k)
    s:ClearAllPoints()
    s:SetPoint("TOPRIGHT", D.sheet, "TOPRIGHT", -28, -(y + 10))
    k.GF.Stamp(s, "fate")
    k.GF.ShowStamp(s, true)
    y = y + 10 + 70
  end
  D.page:Layout(math.ceil(y + 6 - 54))
end

------------------------------------------------------------------------
-- The awards for dying on the rap sheet's file (a row below the kill awards)
------------------------------------------------------------------------
function FU.Awards(Fr, y)
  local Fa, k = ns.Fates, K()
  if not (Fa and k) or type(Fr) ~= "table" or not Fr.sheet then return y end
  local S = Fr.sheet
  local A = Fr.fateAwards
  if not A then
    A = { coins = {} }
    A.label = k.Label(S, L.FATE_AWARDS)
    A.rule = S:CreateTexture(nil, "ARTWORK")
    A.rule:SetHeight(1)
    A.rule:SetColorTexture(C(Look.INK, 0.45))
    A.count = Look.Text(S, "body", 10, Look.INK)
    A.count:SetTextColor(C(Look.INK, Look.TONE.sub))
    for i = 1, #Fa.AWARDS do
      local b = CreateFrame("Button", nil, S)
      b:SetSize(20, 20)
      b.tex = b:CreateTexture(nil, "ARTWORK")
      b.tex:SetAllPoints()
      Look.Skin(b.tex, "coin")
      b.tex:SetDesaturated(true)
      b:SetScript("OnEnter", function(self) if self.tip then k.Tip(self, self.tip) end end)
      b:SetScript("OnLeave", GameTooltip_Hide)
      b.fatePart = true
      A.coins[i] = b
    end
    Fr.fateAwards = A
  end
  local got, have = 0, Fa.Awards()
  A.label:ClearAllPoints()
  A.label:SetPoint("TOPLEFT", S, "TOPLEFT", 24, -(y + 2))
  A.rule:ClearAllPoints()
  A.rule:SetPoint("TOPLEFT", S, "TOPLEFT", 20, -(y + 14))
  A.rule:SetWidth(312)
  for i, b in ipairs(A.coins) do
    local a = Fa.AWARDS[i]
    local t = have[a.id]
    local name, cond = Fa.AwardText(a.id)
    if t then got = got + 1 end
    b:ClearAllPoints()
    b:SetPoint("TOPLEFT", S, "TOPLEFT", 24 + (i - 1) * 28, -(y + 20))
    b.tex:SetVertexColor(C(t and Look.COLOR.stampInk or Look.INK, t and 0.9 or 0.22))
    if t then b.tip = { name, cond, Fmt(L.RECORD_AWARD_AT, { time = Look.When(t) }) }
    elseif a.hidden then b.tip = { "???", L.RECORD_AWARD_OPEN }
    else b.tip = { name, cond, L.RECORD_AWARD_OPEN } end
    b:Show()
  end
  A.count:ClearAllPoints()
  A.count:SetPoint("TOPRIGHT", S, "TOPRIGHT", -24, -(y + 2))
  A.count:SetText(got .. "/" .. #Fa.AWARDS)
  A.label:Show(); A.rule:Show(); A.count:Show()
  return y + 20 + 20
end

-- a new death by a creature: the book follows (UI.lua refreshes on DEATH_RECORDED already); the views keep their
-- choice across sessions (ui.journalView)
