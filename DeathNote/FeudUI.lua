local ADDON, ns = ...

-- 1.6.0 feud: what the book shows of Feud.lua.
--   Wanted: a word switch "Players | Guilds" at the bottom left. Guilds = "Which guilds kill you": one head row per enemy
--   guild (deaths by them, the standing "you : them", members in the book, last seen), a click opens its members (the
--   rows of the player list), the word on the head row declares or ends a feud.
--   Unsolved: a word switch "Open | Claims | Filed" at the bottom left (only while there are claims or filed entries):
--   the claims on own bounties (Paid, Decline) and the old suspicions filed away (Take back).
--   1.7.0 claim: Claims shows both ways, each under its own head: what I owe (claims on my bounties, as before) and
--   what is owed to me (bounties I earned, from Claim.lua of the wire package: Claim.Earned, Claim.Dismiss). The
--   notice and chat lines of the shooter ("Bounty earned", paid, declined, no bounty) and of the poster after "Paid".
--   The quiet alarm of a feud guild and the notice of a new claim; the page in the game's options.
-- Everything goes through UI.Kit (the book's own row and page pieces); UI.lua calls in through UX.FD under pcall.

local Look = ns.Look
local L, Fmt = ns.L, ns.F

local FD = {}
ns.FeudUI = FD

FD.view = "players"          -- Wanted: "players" | "guilds"
FD.oview = "open"            -- Unsolved: "open" | "claims" | "filed"
FD.opened = {}               -- guild name -> true: its members are shown
local heads = {}             -- guild name -> head row item (reused)
local wrapped = {}           -- claim table / filed entry -> row item (weak keys)
setmetatable(wrapped, { __mode = "k" })
local K                      -- UI.Kit

local function kit()
  if not K then K = ns.UI and ns.UI.Kit end
  return K
end
local function Feud() return ns.Feud end
local function C(t, a) return t[1], t[2], t[3], a or t[4] or 1 end

---------------------------------------------------------------------------
-- State
---------------------------------------------------------------------------
function FD.On()
  local k = kit()
  return k ~= nil and Feud() ~= nil and k.state.filter == "wanted" and FD.view == "guilds"
end
local function OpenView()
  local k = kit()
  return k ~= nil and Feud() ~= nil and k.state.filter == "open" and FD.oview ~= "open"
end
function FD.SetView(v)
  if v ~= "players" and v ~= "guilds" then return end
  local k = kit()
  if FD.view == v or not k then return end
  FD.view = v
  k.state.offset = 0
  k.HideMenu()
  k.Refresh()
end
function FD.SetOpenView(v)
  if v ~= "open" and v ~= "claims" and v ~= "filed" then return end
  local k = kit()
  if FD.oview == v or not k then return end
  FD.oview = v
  k.state.offset = 0
  k.state.osel = nil
  k.HideMenu()
  k.Refresh()
end

---------------------------------------------------------------------------
-- Wanted: the guild page
---------------------------------------------------------------------------
local list = {}
function FD.WantedData()
  if not FD.On() then return nil end
  local k = kit()
  for i = #list, 1, -1 do list[i] = nil end
  local q = k.state.query ~= "" and k.OV.Fold(k.state.query) or nil
  local members = 0
  for _, g in ipairs(Feud().Guilds()) do
    local nameHit = not q or k.OV.Fold(g.name):find(q, 1, true) ~= nil
    local hits
    if not nameHit then
      for _, e in ipairs(g.members) do
        if k.OV.Fold(Look.Name(e)):find(q, 1, true) then hits = hits or {}; hits[#hits + 1] = e end
      end
    end
    if nameHit or hits then
      local h = heads[g.name]
      if not h then h = { fdHead = true, ovHead = true }; heads[g.name] = h end
      h.g, h.key = g, "guild\0" .. g.name
      h.open = (q ~= nil) or FD.opened[g.name] == true
      list[#list + 1] = h
      if h.open then
        local src = hits or g.members
        for i = 1, #src do list[#list + 1] = src[i]; members = members + 1 end
      end
    end
  end
  k.OV.total, k.OV.hidden = #list, 0
  return list
end

local function GuildFacts(g)
  local stand = Fmt(L.STAND_LINE, { score = g.rev .. " : " .. g.deaths })
  local killed = g.deaths > 0 and Fmt(L.FEUD_KILLED_YOU, { times = Look.Times(g.deaths) }) or nil
  local seen = g.seen and Fmt(L.ROW_SEEN, { time = Look.Ago(g.seen) }) or nil
  return killed, stand, seen
end

function FD.HeadTip(h)
  local g = h.g
  local killed, stand, seen = GuildFacts(g)
  local tip = { g.name }
  if killed then tip[#tip + 1] = killed end
  tip[#tip + 1] = stand
  tip[#tip + 1] = Fmt(L.FEUD_MEMBERS, { count = g.n })
  if seen then tip[#tip + 1] = seen end
  if g.feud then tip[#tip + 1] = L.FEUD_TIP_ON end
  if g.n > 0 then tip[#tip + 1] = L.FEUD_TIP_CLICK end
  return tip
end

-- the small word at the bottom right of a row (the row's "take over" button of the guild tab)
local function Word(r, text)
  local k = kit()
  r.mark:SetText("")
  r.take.text:SetText(text)
  r.take:SetWidth(math.ceil(k.TextWidth(r.take.text, 50) + 8))
  r.take:Show()
end

local function BindHead(r, h)
  local k = kit()
  local g = h.g
  k.SetRowMode(r, "head")
  r.right:SetText(Fmt(L.FEUD_MEMBERS, { count = g.n }))
  local inset = math.floor(math.max(48, k.TextWidth(r.right, 96) + 18))
  if r.nameInset ~= inset then
    r.nameInset = inset
    r.name:ClearAllPoints()
    r.name:SetPoint("TOPLEFT", 40, -2)
    r.name:SetPoint("RIGHT", -inset, 0)
  end
  -- design fix 1.6.0: "seen ..." stays in the tooltip and on the sheet; the row says deaths and score whole
  local killed, stand = GuildFacts(g)
  local word = g.feud and L.FEUD_END or L.FEUD_DECLARE
  k.SetRow(r, g.name, { Look.Join(killed, stand), killed or stand }, word,
    g.feud and "red" or "normal", true)
  Word(r, word)
  r.tri:SetShown(g.n > 0)
  r.tri:SetRotation(h.open and -1.5708 or 0)
  r.under:Hide()
  r.tipFn = FD.HeadTip
end

---------------------------------------------------------------------------
-- Unsolved: claims and filed entries
---------------------------------------------------------------------------
local olist = {}
local function ClaimName(c)
  if type(c.name) == "string" and c.name ~= "" then return c.name end
  return (tostring(c.key):gsub("%-", " "))
end
local function Wrap(kind, x, key)
  local w = wrapped[x]
  if not w then w = { fdItem = kind }; wrapped[x] = w end
  w.key = key
  if kind == "claim" then
    w.c, w.name, w.display = x, ClaimName(x), ClaimName(x)
  elseif kind == "earned" then
    w.x, w.name, w.display = x, FD.ETarget(x), FD.ETarget(x)
  else
    w.e, w.name, w.display = x, x.name, ns.Util.Display(x)
  end
  return w
end

---------------------------------------------------------------------------
-- 1.7.0 claim: what is owed to me (the shooter's side). Every field comes from saved data that the wire package
-- fills from the line: read through these helpers only, a broken entry shows "?" and never breaks the view.
---------------------------------------------------------------------------
local NONE = {}
local EARNED_STATES = { sent = true, open = true, paid = true, declined = true, gone = true }
local function Str(v) return type(v) == "string" and not Look.Secret(v) and v ~= "" and v or nil end
local function Num(v)
  if Look.Secret(v) then return nil end
  v = tonumber(v)
  if not v or v ~= v or v == math.huge or v == -math.huge then return nil end
  return v
end
FD.EStr, FD.ENum = Str, Num
-- the list of Claim.Earned (newest first), never nil; without Claim.lua (an older logic) empty
function FD.Earned()
  local Cl = ns.Claim
  if type(Cl) ~= "table" or type(Cl.Earned) ~= "function" then return NONE end
  local ok, l = pcall(Cl.Earned)
  if not ok or type(l) ~= "table" then return NONE end
  return l
end
function FD.EarnedCount()
  local n = 0
  for _, x in ipairs(FD.Earned()) do if type(x) == "table" then n = n + 1 end end
  return n
end
-- the key of an entry's row (also for the click on its slip, JU-08)
function FD.EarnedKey(x)
  return "earned\0" .. tostring(Str(x.key)) .. "\0" .. tostring(Str(x.owner)) .. "\0" .. tostring(Num(x.t))
    .. "\0" .. tostring(Str(x.char))
end
function FD.EState(x) local s = Str(x.state); return EARNED_STATES[s] and s or "sent" end
function FD.EGold(x) local g = Num(x.g); return g and g >= 0 and math.floor(g) or 0 end
function FD.ETarget(x)
  local n = Str(x.name)
  if n then return n end
  local k = Str(x.key)
  return k and (k:gsub("%-", " ")) or "?"
end
function FD.EOwner(x) local o = Str(x.owner); return o and Look.First(o) or "?" end
-- may the shooter take it out of the list? In an end state, or unconfirmed for more than FD.DISMISS_AFTER
-- fixer 1.7.0 (JU-18): unconfirmed only after the 30 days the wire package keeps sending it (before that, taking it
-- out would end the claim for good while the poster is merely away)
FD.DISMISS_AFTER = 30 * 86400
function FD.MayDismiss(x)
  local st = FD.EState(x)
  if st == "paid" or st == "declined" or st == "gone" then return true end
  local t = Num(x.t)
  return st == "sent" and t ~= nil and time() - t > FD.DISMISS_AFTER
end

local secs = {}
local function Sec(kind, n)
  local h = secs[kind]
  if not h then h = { fdHead = true, ovHead = true, fdSec = kind, key = "sec\0" .. kind }; secs[kind] = h end
  h.n = n
  return h
end

function FD.OpenData()
  if not OpenView() then return nil end
  for i = #olist, 1, -1 do olist[i] = nil end
  if FD.oview == "claims" then
    -- 1.7.0 claim: what I owe first (as before), then what is owed to me; the heads only once there is something
    -- owed to me (without it the view stays as in 1.6.4)
    local owe, earned = Feud().Claims(), FD.Earned()
    local ne = FD.EarnedCount()
    if ne > 0 and #owe > 0 then olist[#olist + 1] = Sec("owe", #owe) end
    -- fixer 1.7.0 (JU-02): the key of a row never holds its place in the list (a new entry would move the selection)
    for _, c in ipairs(owe) do
      olist[#olist + 1] = Wrap("claim", c, "claim\0" .. tostring(c.key) .. "\0" .. tostring(c.by) .. "\0" .. tostring(c.t))
    end
    if ne > 0 then
      olist[#olist + 1] = Sec("earn", ne)
      for i, x in ipairs(earned) do
        if type(x) == "table" then
          olist[#olist + 1] = Wrap("earned", x, FD.EarnedKey(x))
        end
      end
    end
  else
    for _, x in ipairs(Feud().Expired()) do olist[#olist + 1] = Wrap("filed", x.e, x.key) end
  end
  return olist
end

local STATE_WORD = { open = "CLAIM_OPEN", paid = "CLAIM_PAID", declined = "CLAIM_DECLINED" }
-- 1.7.0 claim: the shooter's states (the words of the poster's side where they are the same)
local EARNED_WORD = { sent = "EARNED_SENT", open = "CLAIM_OPEN", paid = "CLAIM_PAID", declined = "CLAIM_DECLINED",
  gone = "EARNED_GONE" }
FD.EARNED_WORD = EARNED_WORD
FD.NO_SHEET = "none\0"
local function BindItem(r, w)
  local k = kit()
  k.SetRowMode(r, "normal")
  k.SetRank(r, nil)
  r.skull:Hide(); r.strike:Hide()
  r.tipFn = nil
  if w.fdItem == "earned" then
    local x = w.x
    local st = FD.EState(x)
    local sub = Look.Join(Fmt(L.CLAIM_BY, { name = FD.EOwner(x) }), k.GF.Gold(FD.EGold(x)), Look.Ago(Num(x.t)))
    local live = st == "sent" or st == "open"
    k.SetRow(r, w.name, sub, L[EARNED_WORD[st]], live and "normal" or "pale", not live)
    r.icon:Hide()
    r.coin:Show()
  elseif w.fdItem == "claim" then
    local c = w.c
    local sub = Look.Join(Fmt(L.CLAIM_BY, { name = Look.First(c.by) }), k.GF.Gold(c.g), Look.Ago(c.t))
    local open = c.state == "open"
    k.SetRow(r, w.name, sub, L[STATE_WORD[c.state] or "CLAIM_OPEN"], open and "normal" or "pale", not open)
    r.icon:Hide()
    r.coin:Show()
  else
    local e = w.e
    local sub = Look.Join(Look.Tally(e), Fmt(L.FILED_SINCE, { time = Look.Ago(e.expiredAt) }))
    k.SetRow(r, w.name and Look.Name(e) or "?", sub, L.ACT_RESTORE, "pale", false)
    Word(r, L.ACT_RESTORE)
    Look.ClassIcon(r.icon, e.class)
    r.icon:Show()
    r.coin:Hide()
  end
  r.under:SetShown(k.state.osel == w.key)
  r.under:SetWidth(k.InkWidth(r.name))
end

-- 1.7.0 claim: the head of one way in Claims ("YOU OWE" / "OWED TO YOU"), small print like the heads of Wanted
local SEC_WORD = { owe = { "SECTION_OWE", "SECTION_OWE_SUB" }, earn = { "SECTION_EARNED", "SECTION_EARNED_SUB" } }
local function BindSec(r, h)
  local k = kit()
  k.SetRowMode(r, "sect")
  r.right:SetText(tostring(h.n or 0))
  local inset = math.floor(math.max(48, k.TextWidth(r.right, 30) + 18))
  if r.nameInset ~= inset then
    r.nameInset = inset
    r.name:ClearAllPoints()
    r.name:SetPoint("TOPLEFT", 40, -2)
    r.name:SetPoint("RIGHT", -inset, 0)
  end
  local w = SEC_WORD[h.fdSec] or SEC_WORD.owe
  k.SetRow(r, k.Spaced(L[w[1]]), L[w[2]], nil, "normal")
  r.name:SetTextColor(C(Look.INK, Look.TONE.label))
  r.tri:Hide(); r.under:Hide()
  r.tipFn = nil
end

function FD.BindRow(r, item)
  r.take:Hide()
  if item.fdSec then BindSec(r, item)
  elseif item.fdHead then BindHead(r, item) else BindItem(r, item) end
end

---------------------------------------------------------------------------
-- Clicks
---------------------------------------------------------------------------
local function ToggleFeud(name)
  local Fe = Feud()
  if Fe.Is(name) then
    Fe.End(name)
  else
    local ok, why = Fe.Declare(name)
    if not ok and why == "cap" and ns.Util and ns.Util.Print then
      ns.Util.Print(Fmt(L.FEUD_CAP, { count = Fe.MAX_FEUDS }))
    end
  end
  Look.Sound("click")
  Fe.Touched()
  kit().Refresh()
end
FD.ToggleFeud = ToggleFeud

function FD.HeadClick(row, mouse)
  local h = row.item
  if not h or h.fdSec or not h.g then return end
  if h.g.n == 0 then return end
  Look.Sound("click")
  FD.opened[h.g.name] = not FD.opened[h.g.name] or nil
  kit().Refresh()
end

local function Restore(key)
  if Feud().Restore(key) then Look.Sound("click") end
  local k = kit()
  k.state.osel = nil
  k.Refresh()
end

function FD.RowWord(r)
  local item = r and r.item
  if not item then return end
  if item.fdHead then ToggleFeud(item.g.name)
  elseif item.fdItem == "filed" then Restore(item.key) end
end

-- the row menu and poster menu: "Keep" for an entry that would expire
function FD.KeepAct(e)
  local Fe = Feud()
  if not Fe or not Fe.MayKeep(e) then return nil end
  local key, on = e.key, e.keep == true
  return { on and L.ACT_UNKEEP or L.ACT_KEEP, function() Fe.SetKeep(key, not on); kit().Refresh() end }
end

---------------------------------------------------------------------------
-- Right page
---------------------------------------------------------------------------
-- design fix 1.6.0: the right page of a guild, a claim and a filed entry is a sheet pinned with tape like the death
-- file and the cause's file (head left, date right, a line, the text left-aligned, the buttons at the bottom left),
-- not the empty page with the skull (that one says "nothing here"). Built on P (the poster frame), shown as a card.
FD.SHEET_W, FD.BTN_W = 352, 150
FD.FIT_HEAD = { sizes = { 26, 22, 19, 16 } }
FD.FIT_BIG = { sizes = { 22, 19, 16 }, lines = 2, wrapFirst = true }
FD.FIT_SMALL = { sizes = { 13, 11 }, lines = 3, wrapFirst = true }
FD.FIT_TINY = { sizes = { 11, 10 }, lines = 4, wrapFirst = true }
FD.FIT_WHEN = { sizes = { 11, 10, 9 } }
local function SheetOf()
  local k = kit()
  local _, _, _, P = k.Frames()
  if not P then return nil end
  local S = P.feud
  if S then return S, P end
  S = CreateFrame("Frame", nil, P)
  S:SetAllPoints()
  S.head = Look.Text(S, "head", 26, Look.INK)
  S.head:SetPoint("TOPLEFT", 24, -16)
  S.head:SetWidth(150)
  S.head:SetJustifyH("LEFT")
  S.head:SetWordWrap(false)
  S.when = Look.Text(S, "type", 11, Look.INK)
  S.when:SetPoint("TOPRIGHT", -24, -28)
  S.when:SetWidth(160)
  S.whenHit = CreateFrame("Frame", nil, S)
  S.whenHit:SetAllPoints(S.when)
  Look.TipIfCut(S.whenHit, S.when)
  S.when:SetJustifyH("RIGHT")
  S.when:SetWordWrap(false)
  local rule = S:CreateTexture(nil, "ARTWORK")
  rule:SetHeight(1)
  rule:SetPoint("TOPLEFT", 24, -52)
  rule:SetPoint("TOPRIGHT", -24, -52)
  rule:SetColorTexture(Look.INK[1], Look.INK[2], Look.INK[3], 0.7)
  S.big = Look.Text(S, "hand", 22, Look.INK)
  S.big:SetPoint("TOPLEFT", 24, -66)
  S.big:SetWidth(304)
  S.big:SetJustifyH("LEFT")
  S.small = Look.Text(S, "type", 13, Look.INK)
  S.small:SetPoint("TOPLEFT", S.big, "BOTTOMLEFT", 0, -8)
  S.small:SetWidth(304)
  S.small:SetJustifyH("LEFT")
  S.small:SetSpacing(3)
  S.tiny = Look.Text(S, "type", 11, Look.INK)
  S.tiny:SetTextColor(Look.INK[1], Look.INK[2], Look.INK[3], Look.TONE.sub)
  S.tiny:SetPoint("TOPLEFT", S.small, "BOTTOMLEFT", 0, -14)
  S.tiny:SetWidth(304)
  S.tiny:SetJustifyH("LEFT")
  S.tiny:SetSpacing(2)
  S.fdA = k.InkButton(S, "", FD.BTN_W, 24, nil)
  S.fdB = k.InkButton(S, "", FD.BTN_W, 24, nil)
  S.fdA:SetPoint("BOTTOMLEFT", 20, 10)
  S.fdB:SetPoint("LEFT", S.fdA, "RIGHT", 8, 0)
  S.fdA:Hide(); S.fdB:Hide()
  S:Hide()
  P.feud = S
  return S, P
end
FD.Sheet = SheetOf
local function HideButtons()
  local k = kit()
  local _, _, _, P = k.Frames()
  if P and P.feud then P.feud:Hide() end
end
-- fixer 1.7.0 (JU-02, JU-03): after a click on the sheet, and after the shown sheet changed by itself (a state that
-- came in), both buttons are deaf for FD.DEAF seconds: a second click on the same place never hits the button that
-- took the place of the first one ("Paid" after "Remove from list", "Open again" after "Paid"). Picking a row is no
-- such change (the player looks at the new sheet first). The pattern of the book: "Undo" after "Note revenge".
FD.DEAF = 0.5
local deafUntil = 0
local function Deafen() deafUntil = GetTime() + FD.DEAF end
function FD.Deaf() return GetTime() < deafUntil end
local function SetButton(b, text, fn)
  if not text then b:Hide(); b.fn = nil; return end
  b:SetLabel(text)
  b.fn = function(...)
    if FD.Deaf() then return end
    Deafen()
    return fn(...)
  end
  b:Show()
end
local lastSheet = { sel = nil, sig = nil }

-- shows the sheet: head word, date, the big line, two smaller blocks and up to two buttons
local function Page(head, when, big, small, tiny, a, fa, b, fb)
  local k = kit()
  local _, _, RP = k.Frames()
  local S, P = SheetOf()
  if not S then return end
  RP.empty:Hide()
  P.enemy:Hide(); P.death:Hide()
  if P.record then P.record:Hide() end
  -- the card: tape instead of the thumbtack
  P.pin:Hide()
  if P.dnPin then P.dnPin:Hide() end
  P.card:Show()
  -- the same selection with another content or other buttons: it changed under the cursor
  local sel = kit().state.osel
  local sig = table.concat({ tostring(head), tostring(big), tostring(small), tostring(tiny), tostring(a), tostring(b) }, "\1")
  if lastSheet.sel == sel and lastSheet.sig ~= nil and lastSheet.sig ~= sig then Deafen() end
  lastSheet.sel, lastSheet.sig = sel, sig
  Look.FitText(S.head, head or "", FD.FIT_HEAD)
  Look.FitText(S.when, when or "", FD.FIT_WHEN)
  Look.FitText(S.big, big or "", FD.FIT_BIG)
  Look.FitText(S.small, small or "", FD.FIT_SMALL)
  Look.FitText(S.tiny, tiny or "", FD.FIT_TINY)
  SetButton(S.fdA, a, fa)
  SetButton(S.fdB, b, fb)
  P:Show()
  S:Show()
end

function FD.EmptyKind()
  HideButtons()
  local k = kit()
  if not k then return nil end
  if FD.On() then return k.state.query ~= "" and "searchro" or "fguilds" end
  if OpenView() then return FD.oview == "claims" and "fclaims" or "ffiled" end
  return nil
end

function FD.ShowRight()
  HideButtons()
  local k = kit()
  local data = k.Data()
  local st = k.state
  if FD.On() then
    -- a member row shown: the book's own poster (the wanted branch finds it); none: the first guild's page
    for i = 1, #data do
      if not data[i].ovHead and data[i].key == st.selected then return nil end
    end
    for i = 1, #data do
      if not data[i].ovHead then st.selected = data[i].key; return nil end
    end
    local h = data[1]
    for i = 1, #data do if data[i].g and FD.opened[data[i].g.name] then h = data[i]; break end end
    local g = h and h.g
    if not g then return nil end
    local killed, stand = GuildFacts(g)
    local lines = {}
    if killed then lines[#lines + 1] = killed end
    lines[#lines + 1] = stand
    lines[#lines + 1] = Fmt(L.FEUD_MEMBERS, { count = g.n })
    Page(L.FEUD_SHEET_HEAD, g.seen and Fmt(L.ROW_SEEN, { time = Look.Ago(g.seen) }) or "", g.name, table.concat(lines, "\n"),
      L.FEUD_TIP_ON, g.feud and L.FEUD_END or L.FEUD_DECLARE, function() ToggleFeud(g.name) end)   -- 1.6.2: also before the feud
    return true
  end
  if not OpenView() then return nil end
  if st.osel == FD.NO_SHEET and FD.oview == "claims" then
    -- nothing picked: the view's empty page (no sheet, no button under the cursor); fixer 2 1.7.0 (JN-4): it holds
    -- only until a slip is clicked, the book opens again or a new entry comes
    if k.ShowEmpty then k.ShowEmpty("fpick") end
    return true
  end
  local w
  for i = 1, #data do if not data[i].ovHead and data[i].key == st.osel then w = data[i]; break end end
  if not w then
    for i = 1, #data do if not data[i].ovHead then w = data[i]; break end end
    st.osel = w and w.key
  end
  if not w then return nil end
  if w.fdItem == "earned" then
    FD.EarnedPage(w)
    return true
  end
  if w.fdItem == "claim" then
    local c = w.c
    -- design fix 1.6.0: the head line is what to do (how much to whom), the target below it
    local big = Fmt(L.CLAIM_HEAD, { gold = k.GF.Gold(c.g), name = Look.First(c.by) })
    local small = Fmt(L.CLAIM_FOR, { target = w.name })
    local state = L[STATE_WORD[c.state] or "CLAIM_OPEN"]
    local Fe = Feud()
    -- fixer 1.7.0 (JU-04, new E4): the paid claim on the same bounty (Feud.Rival) takes away "Paid" and "Open again"
    -- (they would do nothing); the sheet says to whom it is paid. Other open claims on it (Feud.Rivals) are named
    -- with their number, "Paid" declines them. A refused change still says so in the chat.
    local rival = FD.Rival(c)
    local rivalLine = rival and Fmt(rival.state == "paid" and L.CLAIM_RIVAL_PAID or L.CLAIM_RIVAL_OPEN,
      { name = Look.First(rival.by) }) or nil
    local function set(state)
      if not Fe.SetClaim(c, state) and ns.Util and ns.Util.Print then
        local r = FD.Rival(c)
        ns.Util.Print(r and Fmt(r.state == "paid" and L.CLAIM_RIVAL_PAID or L.CLAIM_RIVAL_OPEN, { name = Look.First(r.by) })
          or L.CHAT_CLAIM_UNCHANGED)
      end
      k.Refresh()
    end
    if c.state == "open" then
      -- 1.7.0 claim: with the wire package "Paid" takes the own bounty back (decision E5); the sheet says so first
      local note = L.CLAIM_NOTE
      local Cl = ns.Claim
      if rivalLine then
        Page(L.SHEET_CLAIM, Look.When(c.t), big, small .. "\n" .. state, note .. "\n" .. rivalLine,
          L.ACT_DECLINE, function() set("declined") end)
      else
        -- fixer 1.7.0 (JU-10): the bounty of another own char goes at that char's next login (second answer "later")
        if type(Cl) == "table" and type(Cl.WouldTake) == "function" then
          local ok, takes, later = pcall(Cl.WouldTake, c)
          later = Str(later)
          if ok and takes == true then
            note = note .. "\n" .. (later and Fmt(L.CLAIM_PAID_TAKES_LATER, { button = L.ACT_PAID, char = Look.First(later) })
              or Fmt(L.CLAIM_PAID_TAKES, { button = L.ACT_PAID }))
          end
        end
        local n = FD.RivalCount(c)
        if n > 0 then note = note .. "\n" .. Fmt(L.CLAIM_RIVALS, { count = n, button = L.ACT_PAID }) end
        Page(L.SHEET_CLAIM, Look.When(c.t), big, small .. "\n" .. state, note,
          L.ACT_PAID, function() set("paid") end,
          L.ACT_DECLINE, function() set("declined") end)
      end
    elseif rivalLine then
      Page(L.SHEET_CLAIM, Look.When(c.t), big, small .. "\n" .. state, rivalLine)
    else
      Page(L.SHEET_CLAIM, Look.When(c.t), big, small .. "\n" .. state, nil,
        L.ACT_REOPEN, function() set("open") end)
    end
  else
    local e = w.e
    Page(L.VIEW_FILED, Look.When(e.expiredAt), Look.Name(e), Look.Tally(e),
      Fmt(L.FILED_TINY, { time = Look.When(e.expiredAt) }), L.ACT_RESTORE, function() Restore(w.key) end)
  end
  return true
end

-- 1.7.0 claim: the sheet of a bounty owed to me: how much from whom, the target, my char who took him down and when,
-- the state, one sentence what to do now; "Remove from list" in an end state or unconfirmed for more than 30 days
local EARNED_NOTE = { sent = "EARNED_NOTE_SENT", open = "EARNED_NOTE_OPEN", paid = "EARNED_NOTE_PAID",
  declined = "EARNED_NOTE_DECLINED", gone = "EARNED_NOTE_GONE" }
function FD.EarnedPage(w)
  local k = kit()
  local x = w.x
  local st = FD.EState(x)
  local owner = FD.EOwner(x)
  local big = Fmt(L.EARNED_HEAD, { gold = k.GF.Gold(FD.EGold(x)), name = owner })
  local lines = { Fmt(L.CLAIM_FOR, { target = w.name }) }
  local char = Str(x.char)
  if char then lines[#lines + 1] = Fmt(L.EARNED_KILLED_BY, { name = Look.First(char) }) end
  lines[#lines + 1] = L[EARNED_WORD[st]]
  local t = Num(x.t)
  local a, fa
  if FD.MayDismiss(x) then
    a = L.ACT_EARNED_REMOVE
    fa = function()
      -- fixer 1.7.0 (JU-02): the selection stays on this side: the next entry owed to me, else the one before, else
      -- no sheet (never the first row of the view, which may be a claim of mine with "Paid" on this very place)
      local data, after, before, seen = k.Data(), nil, nil, false
      for i = 1, #data do
        local d = data[i]
        if d == w then seen = true
        elseif d.fdItem == "earned" then
          if seen and not after then after = d end
          if not seen then before = d end
        end
      end
      local Cl = ns.Claim
      if type(Cl) == "table" and type(Cl.Dismiss) == "function" then pcall(Cl.Dismiss, x) end
      Look.Sound("click")
      local nxt = after or before
      k.state.osel = nxt and nxt.key or FD.NO_SHEET
      k.Refresh()
    end
  end
  Page(L.SHEET_EARNED, t and Look.When(t) or "", big, table.concat(lines, "\n"), Fmt(L[EARNED_NOTE[st]], { name = owner, char = char and Look.First(char) or "?" }), a, fa)   -- fixer 2 (JN-10): the char that killed
end

-- fixer 1.7.0: the other claims on the same bounty (wire package, Feud.Rival = the paid one, Feud.Rivals = the other
-- open ones); without them (an older logic) none
function FD.Rival(c)
  local Fe = Feud()
  if not Fe or type(Fe.Rival) ~= "function" then return nil end
  local ok, r = pcall(Fe.Rival, c)
  return ok and type(r) == "table" and r ~= c and r or nil
end
function FD.RivalCount(c)
  local Fe = Feud()
  if not Fe or type(Fe.Rivals) ~= "function" then return 0 end
  local ok, l = pcall(Fe.Rivals, c)
  if not ok or type(l) ~= "table" then return 0 end
  local n = 0
  for _, y in ipairs(l) do if type(y) == "table" and y ~= c then n = n + 1 end end
  return n
end

---------------------------------------------------------------------------
-- The word switches at the bottom left
---------------------------------------------------------------------------
local function Switch(LP, items)
  local k = kit()
  local f = CreateFrame("Frame", nil, LP)
  f:SetSize(260, 18)
  f:SetPoint("BOTTOMLEFT", 44, 34)
  f.items = {}
  local prev
  for i, v in ipairs(items) do
    local b = k.WordTab(f, L[v[2]], 60, function(self) v[3](self.view) end)
    b.view, b.label = v[1], L[v[2]]
    b:SetSize(math.min(110, math.max(30, k.TextWidth(b.text, 50) + 6)), 18)
    b.text:SetWordWrap(false)
    if prev then b:SetPoint("LEFT", prev, "RIGHT", 10, 0) else b:SetPoint("LEFT", 0, 0) end
    f.items[i] = b
    prev = b
  end
  f:Hide()
  return f
end

local function Count(b, n)
  local k = kit()
  local text = (n and n > 0) and (b.label .. "  " .. n) or b.label
  b.text:SetText(text)
  b:SetWidth(math.min(120, math.max(30, k.TextWidth(b.text, 50) + 6)))
  b.text:SetWidth(b:GetWidth() - 4)
end

function FD.Layout()
  local k = kit()
  if not k or not Feud() then return end
  local _, LP = k.Frames()
  if not LP then return end
  if not LP.fdWanted then
    LP.fdWanted = Switch(LP, { { "players", "VIEW_PLAYERS", FD.SetView }, { "guilds", "VIEW_GUILDS", FD.SetView } })
    LP.fdOpen = Switch(LP, { { "open", "VIEW_OPEN", FD.SetOpenView }, { "claims", "VIEW_CLAIMS", FD.SetOpenView },
      { "filed", "VIEW_FILED", FD.SetOpenView } })
  end
  local st = k.state
  local Fe = Feud()
  local wantedOn = st.filter == "wanted" and (FD.view == "guilds" or #Fe.Guilds() > 0)
  LP.fdWanted:SetShown(wantedOn)
  if wantedOn then for _, b in ipairs(LP.fdWanted.items) do b:SetOn(b.view == FD.view) end end
  local claims, filed = Fe.OpenClaims(), Fe.ExpiredCount()
  local anyClaim = #Fe.Claims() > 0 or FD.EarnedCount() > 0   -- 1.7.0 claim: or owed to me
  if st.filter == "open" and FD.oview ~= "open" and not anyClaim and filed == 0 then FD.oview = "open" end
  local openOn = st.filter == "open" and (anyClaim or filed > 0)
  LP.fdOpen:SetShown(openOn)
  if openOn then
    local prev
    for _, b in ipairs(LP.fdOpen.items) do
      b:SetOn(b.view == FD.oview)
      if b.view == "claims" then Count(b, claims) elseif b.view == "filed" then Count(b, filed) end
      b:ClearAllPoints()
      if prev then b:SetPoint("LEFT", prev, "RIGHT", 10, 0) else b:SetPoint("LEFT", 0, 0) end
      prev = b
    end
  end
end

---------------------------------------------------------------------------
-- Alarm, notice, chat
---------------------------------------------------------------------------
ns:On("FEUD_SPOTTED", function(guild, key)
  if not Look.Setting("alert.enabled", true) then return end
  Look.Alarm("quiet")
  local T = ns.Tracker
  local r = T and T.Get and T.Get(key)
  local name = r and (r.surname and (r.name .. " " .. r.surname) or r.name) or (type(key) == "string" and (key:gsub("%-", " ")) or "?")
  if ns.Util and ns.Util.Print then ns.Util.Print(Fmt(L.FEUD_ALARM, { guild = guild, name = name })) end
end)

-- the book at Unsolved > Claims (a click on the slip of a claim or of an earned bounty)
-- x (fixer 1.7.0, JU-08): the entry owed to me whose slip was clicked; its sheet is shown, never another one
function FD.ShowClaims(x)
  if ns.UI and ns.UI.Open then
    ns.UI.Open()
    FD.oview = "claims"
    if ns.UI.SetFilter then ns.UI.SetFilter("open") end
    local k = kit()
    if k and type(x) == "table" then k.state.osel = FD.EarnedKey(x)
    elseif k and k.state.osel == FD.NO_SHEET then k.state.osel = nil end      -- fixer 2 (JN-4): the first row again
    if k then k.Refresh() end
  end
end

ns:On("CLAIM_NEW", function(c)
  if type(c) ~= "table" then return end
  local name = ClaimName(c)
  local line = Fmt(L.CLAIM_LINE, { name = Look.First(c.by), target = name, gold = c.g })
  if ns.Util and ns.Util.Print then ns.Util.Print(line) end
  local X = ns.Extras
  if X and X.Slip then
    X.Slip(L.BANNER_CLAIM, name, nil, line, c.key, FD.ShowClaims)
  end
  local k = kit()
  if k then k.Refresh() end
end)
-- fixer 2 1.7.0 (JN-4): "nothing picked" never outlives the moment: a new entry either way or the book opened again
-- shows a sheet again
function FD.ClearNoSheet()
  local k = kit()
  if k and k.state.osel == FD.NO_SHEET then k.state.osel = nil; k.Refresh() end
end
for _, ev in ipairs({ "CLAIM_NEW", "EARNED_NEW", "TOGGLE_UI" }) do ns:On(ev, function() pcall(FD.ClearNoSheet) end) end
for _, ev in ipairs({ "CLAIMS_CHANGED", "EXPIRED_CHANGED", "FEUDS_CHANGED" }) do
  ns:On(ev, function() local k = kit(); if k then k.Refresh() end end)
end

---------------------------------------------------------------------------
-- 1.7.0 claim: the shooter ("Bounty earned") and the poster after "Paid". The wire package only fires the events;
-- every word is here. One window per event: the chat line comes at once; the slip waits a moment
-- (FD.EARNED_DELAY), so the notice of the same kill (payback, taken down) is up first, and then queues behind it
-- (Extras.Slip waits for a notice on the screen) instead of pushing it away or being pushed away by it. Several
-- posters on one target in that moment give one slip (the sum and "Anna +1"), each its own chat line.
---------------------------------------------------------------------------
FD.EARNED_DELAY = 1
local function Print(s) if ns.Util and ns.Util.Print then ns.Util.Print(s) end end
local function Gold(g)
  local k = kit()
  return (k and k.GF and k.GF.Gold) and k.GF.Gold(g) or Fmt(L.MONEY_GOLD, { count = g })
end
local earnedWait = {}      -- target key -> { entries } waiting for the slip
local function EarnedSlip(key)
  local all = earnedWait[key]
  earnedWait[key] = nil
  if type(all) ~= "table" then return end
  -- fixer 1.7.0 (JU-01): the state is read again now: an entry the poster already answered (no bounty, declined,
  -- paid) gets no slip "Bounty earned"; its chat lines said it
  local list = {}
  for _, x in ipairs(all) do
    local st = FD.EState(x)
    if st == "sent" or st == "open" then list[#list + 1] = x end
  end
  if #list == 0 then return end
  local sum, top = 0, list[1]
  for _, x in ipairs(list) do
    sum = sum + FD.EGold(x)
    if FD.EGold(x) > FD.EGold(top) then top = x end
  end
  local who = FD.EOwner(top)
  if #list > 1 then who = Fmt(L.NAMES_PLUS, { name = who, count = #list - 1 }) end
  local short = Fmt(L.EARNED_SLIP_LINE, { gold = Gold(sum), name = who })
  local full = Look.Join(short, L.TAB_UNSOLVED .. " > " .. L.VIEW_CLAIMS)
  local X = ns.Extras
  if X and X.Slip then
    X.Slip(L.BANNER_EARNED, FD.ETarget(top), nil, { full, short }, Str(top.key), function() FD.ShowClaims(top) end)
  end
end
function FD.OnEarned(x)
  if type(x) ~= "table" then return end
  local target, gold = FD.ETarget(x), Gold(FD.EGold(x))
  Print(Fmt(L.CHAT_EARNED, { gold = gold, name = FD.EOwner(x), target = target,
    where = L.TAB_UNSOLVED .. " > " .. L.VIEW_CLAIMS }))
  local key = Str(x.key) or target
  local wait = earnedWait[key]
  if not wait then
    wait = {}
    earnedWait[key] = wait
    local T = rawget(_G, "C_Timer")
    if T and T.After then T.After(FD.EARNED_DELAY, function() EarnedSlip(key) end) end
  end
  wait[#wait + 1] = x
  if not (rawget(_G, "C_Timer") and C_Timer.After) then EarnedSlip(key) end
  local k = kit()
  if k then k.Refresh() end
end
local CHANGED_LINE = { paid = "CHAT_EARNED_PAID", declined = "CHAT_EARNED_DECLINED", gone = "CHAT_EARNED_GONE" }
function FD.OnEarnedChanged(x, old)
  if type(x) ~= "table" then return end
  local st = FD.EState(x)
  -- unconfirmed to open is silent (the poster has it now, nothing for me to do); fixer 1.7.0 (JU-09): from an end
  -- state back to open says that the last line no longer holds
  if CHANGED_LINE[st] and st ~= old then
    Print(Fmt(L[CHANGED_LINE[st]], { name = FD.EOwner(x), target = FD.ETarget(x), gold = Gold(FD.EGold(x)) }))
  elseif st == "open" and (old == "paid" or old == "declined" or old == "gone") then
    Print(Fmt(L.CHAT_EARNED_REOPENED, { name = FD.EOwner(x), target = FD.ETarget(x), gold = Gold(FD.EGold(x)) }))
  end
  local k = kit()
  if k then k.Refresh() end
end
-- later (fixer 1.7.0, JU-10): the own char whose bounty guild and friends drop only at his next login
function FD.OnSettled(c, taken, later)
  if type(c) ~= "table" then return end
  local g = Num(c.g)
  local by = Str(c.by)
  later = Str(later)
  local key = taken == true and (later and "CHAT_CLAIM_SETTLED_LATER" or "CHAT_CLAIM_SETTLED") or "CHAT_CLAIM_SETTLED_KEPT"
  Print(Fmt(L[key], { target = ClaimName(c), gold = Gold(g and g >= 0 and math.floor(g) or 0),
    name = by and Look.First(by) or "?", char = later and Look.First(later) or "?" }))   -- fixer 2 (JN-10): first names as everywhere
  local k = kit()
  if k then k.Refresh() end
end
-- every handler under pcall: an error in a word never reaches the logic that fired the event
local function Safe(fn)
  return function(...)
    local ok, err = pcall(fn, ...)
    if not ok and ns.ReportError then ns.ReportError(err) end
  end
end
ns:On("EARNED_NEW", Safe(FD.OnEarned))
ns:On("EARNED_CHANGED", Safe(FD.OnEarnedChanged))
ns:On("CLAIM_SETTLED", Safe(FD.OnSettled))

---------------------------------------------------------------------------
-- The page in the game's options (Esc > Options > AddOns): title, one line, "Open House Rules"
---------------------------------------------------------------------------
function FD.Options()
  local S = rawget(_G, "Settings")
  if type(S) ~= "table" or type(S.RegisterCanvasLayoutCategory) ~= "function" or type(S.RegisterAddOnCategory) ~= "function" then
    return false
  end
  if FD.optionsPanel then return true end
  local panel = CreateFrame("Frame")
  local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
  title:SetPoint("TOPLEFT", 16, -16)
  title:SetText(L.BOOK_TITLE)
  local line = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  line:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
  line:SetWidth(560)
  line:SetJustifyH("LEFT")
  line:SetText(L.OPTIONS_LINE)
  local button = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  button:SetSize(200, 26)
  button:SetPoint("TOPLEFT", line, "BOTTOMLEFT", 0, -14)
  button.label = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  button.label:SetPoint("CENTER", 0, 0)
  button.label:SetText(L.OPTIONS_OPEN)
  button:SetScript("OnClick", function()
    local SP = rawget(_G, "SettingsPanel")
    if SP and HideUIPanel then pcall(HideUIPanel, SP) end
    if InCombatLockdown and InCombatLockdown() then return end
    if ns.UI and ns.UI.Open then ns.UI.Open() end
    if ns.UI and ns.UI.OpenPanel then ns.UI.OpenPanel("settings") end
  end)
  FD.optionsPanel, FD.optionsButton = panel, button
  S.RegisterAddOnCategory(S.RegisterCanvasLayoutCategory(panel, L.BOOK_TITLE))
  return true
end

ns:On("READY", function()
  local k = kit()
  if k and k.EMPTY then
    k.EMPTY.fguilds = { "EMPTY_FGUILDS", 2 }
    k.EMPTY.fguild = { "EMPTY_FGUILDS", 2 }
    k.EMPTY.fclaims = { "EMPTY_FCLAIMS", 2 }
    k.EMPTY.fpick = { "EMPTY_FPICK", 2 }       -- fixer 2 1.7.0 (JN-4)
    k.EMPTY.ffiled = { "EMPTY_FFILED", 2 }
  end
  local ok, err = pcall(FD.Options)
  if not ok and ns.ReportError then ns.ReportError(err) end
end)
