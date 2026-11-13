-- 1.3.1 rap sheet: a group kill (a group member's killing blow, a proof that I took part) in the chat line, in the
-- latest kills and on the victim sheet (tag and tooltip), and the left page of the empty rap sheet in 21 languages.
-- UI mock with the real logic. All names are invented. Call from the project root: luajit tests/ui/rapsheet_group.lua .
local DIR = (arg[1] or "."):gsub("/+$", "")
local K = dofile(DIR .. "/tests/ui/layout_kit.lua")(DIR, "rapsheet_group")
local check = K.check

local MATE = "Player-93-0000BBBB"
local ns, AM, BM, G
local plate = 0
local function world(code)
  ns = K.world(code or "deDE")
  AM, BM, G = K.AM, K.BM, K.G
  AM.units.player.level = 40
  K.tick(30); K.settle()
  return ns
end
local function party()
  AM.units.party1 = { exists = true, isPlayer = true, name = "Kumpel", surname = "Treu", guid = MATE, faction = "Horde" }
  AM.FireEvent("GROUP_ROSTER_UPDATE")
end
local function seen(name, surname, level)
  plate = plate + 1
  local guid = "Player-93-" .. name .. surname
  AM.AddEnemy("nameplate" .. plate, { name = name, surname = surname, level = level or 40, guid = guid, class = "MAGE" })
  AM.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate" .. plate)
  return guid
end
local function frame() return rawget(G, "DeathNoteFrame") end
local function open() if not (frame() and frame():IsShown()) then ns:Fire("TOGGLE_UI") end K.tick(); K.settle() end
local function tab(id) for _, f in ipairs(BM.frames) do if f.id == id and f.mark and f._scripts and f._scripts.OnClick then return f end end end
local function click(f, b) f._scripts.OnClick(f, b or "LeftButton"); K.tick() end
local function poster() for _, f in ipairs(BM.frames) do if f.enemy and f.death then return f end end end
local function visible(text)
  for _, f in ipairs(BM.frames) do
    if f._kind == "FontString" and f._text == text and f:IsVisible() then return f end
  end
end

------------------------------------------------------------------------
-- Chat line, latest kills, victim sheet
------------------------------------------------------------------------
for _, code in ipairs({ "deDE", "enUS" }) do
  world(code)
  local L = ns.L
  local chat = {}
  ns.Util.Print = function(t) chat[#chat + 1] = tostring(t) end
  party()
  local g = seen("Grimm", "Bart", 41)
  AM.FireEvent("PARTY_KILL", MATE, g); K.tick(0.4)
  AM.FireEvent("PLAYER_PVP_KILLS_CHANGED"); K.tick(0.6)
  AM.FireEvent("CHAT_MSG_COMBAT_HONOR_GAIN", "Ihr habt 198 Ehrenpunkte erhalten."); K.tick(1)
  local line
  for _, c in ipairs(chat) do if c:find("Grimm", 1, true) then line = c end end
  check(code .. ": chat line after the group kill", line and line:find(L.BAND_GELB, 1, true), table.concat(chat, " / "))
  check(code .. ": ...with the group", line and line:sub(-#L.KILL_WITH_GROUP) == L.KILL_WITH_GROUP, line)
  -- an own kill: no addition
  local h = seen("Hanna", "Hain", 40)
  AM.FireEvent("PARTY_KILL", "Player-93-0000AAAA", h); K.tick(1)
  local own
  for _, c in ipairs(chat) do if c:find("Hanna", 1, true) then own = c end end
  check(code .. ": an own kill's line has no addition", own and not own:find(L.KILL_WITH_GROUP, 1, true), own)
  -- the latest kills: the tag "group" and the tooltip line
  open(); click(tab("record"))
  local R = poster().record
  click(R.file.word)
  check(code .. ": latest kills shown", R.log:IsShown())
  local b
  for _, x in ipairs(R.log.lines) do if x:IsShown() and (x.text._text or ""):find("Grimm", 1, true) then b = x end end
  check(code .. ": the group kill's line carries the group tag", b and b.tag._text == L.KILL_TAG_GROUP, b and b.tag._text)
  local tip = b and K.hover(b) or ""
  check(code .. ": its tooltip says: with the group", tip:find(L.KILL_WITH_GROUP, 1, true), tip)
  local hb
  for _, x in ipairs(R.log.lines) do if x:IsShown() and (x.text._text or ""):find("Hanna", 1, true) then hb = x end end
  local htip = hb and K.hover(hb) or "?"
  check(code .. ": the own kill's tooltip does not", hb and not htip:find(L.KILL_WITH_GROUP, 1, true), htip)
  -- the victim sheet
  local row
  for _, f in ipairs(BM.frames) do if f.item and f.under and f:IsVisible() and f.item.key == "Grimm-Bart" then row = f end end
  click(row)
  check(code .. ": victim sheet shown", R.vic:IsShown())
  local vb
  for _, x in ipairs(R.vic.lines or {}) do if x:IsShown() then vb = x end end
  if not vb then
    for _, f in ipairs(BM.frames) do
      if f.tag and f.tipFn and f:IsVisible() and K.under(f, R.vic) then vb = f end
    end
  end
  check(code .. ": the victim sheet's kill line carries the group tag", vb and vb.tag._text == L.KILL_TAG_GROUP, vb and vb.tag._text)
  local vtip = vb and K.hover(vb) or ""
  check(code .. ": ...and its tooltip says: with the group", vtip:find(L.KILL_WITH_GROUP, 1, true), vtip)
  check(code .. ": the left page has no empty line with victims", not visible(L.EMPTY_RECORD_HEAD))
  check(code .. ": no errors", #AM.errors == 0 and #BM.violations == 0, AM.errors[1] or BM.violations[1])
end

------------------------------------------------------------------------
-- The empty rap sheet: a line on the left page, in every language; gone with the first victim
------------------------------------------------------------------------
local CODES = { "enUS", "deDE", "csCZ", "daDK", "esES", "fiFI", "frFR", "hrHR", "huHU", "itIT", "koKR", "nbNO", "nlNL",
  "plPL", "ptBR", "ruRU", "svSE", "trTR", "ukUA", "zhCN", "zhTW" }
for _, code in ipairs(CODES) do
  world(code)
  local L = ns.L
  open(); click(tab("record"))
  local head, sub = visible(L.EMPTY_RECORD_HEAD), visible(L.EMPTY_RECORD_SUB)
  check(code .. ": empty rap sheet: the line on the left page", head and sub, L.EMPTY_RECORD_HEAD)
  if head and sub then
    local fl = BM.RectUI(frame())
    local hl, hb, hr = BM.RectUI(head)     -- left, bottom, right, top
    local sl, _, sr, st = BM.RectUI(sub)
    -- the left page spans x = 0 .. 380 of the book
    check(code .. ": ...inside the left page", hl - fl >= 0 and hr - fl <= 380 and sl - fl >= 0 and sr - fl <= 380,
      ("%.0f..%.0f / %.0f..%.0f"):format(hl - fl, hr - fl, sl - fl, sr - fl))
    check(code .. ": ...the small line under the big one", st <= hb + 0.5, ("%s %s"):format(tostring(hb), tostring(st)))
  end
  click(tab("wanted"))
  check(code .. ": other tabs: not there", not visible(L.EMPTY_RECORD_HEAD))
  click(tab("record"))
  AM.FireEvent("PARTY_KILL", "Player-93-0000AAAA", seen("Erna", "Eben", 40)); K.tick(1)
  check(code .. ": gone with the first victim", not visible(L.EMPTY_RECORD_HEAD))
  check(code .. ": no errors", #AM.errors == 0 and #BM.violations == 0, AM.errors[1] or BM.violations[1])
end

K.done("rap sheet: group kills and the empty list")
