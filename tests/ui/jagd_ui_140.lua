-- Jagd UI 1.4.0: Belegtests (heute ROT). Aufruf aus dem Worktree:
--   cd <worktree> && luajit <pfad>/jagd_ui_140.lua [<worktree>]
-- J1 Filterwort zeigt bei Rolle + Klasse nur die Klasse (Rollenfilter unsichtbar)
-- J2 Filter blendet einen Gesuchten aus, Suche nach Teil seines Namens + Enter legt einen neuen Eintrag an
-- J3 Buch offen: die Rachsucht-Meldung liegt unter dem Buch (Strata) und wird teilweise verdeckt (1366x768)
-- Alle Namen erfunden.
local WT = arg[1] or "."
package.path = WT .. "/tests/ui/?.lua;" .. WT .. "/tests/?.lua;" .. package.path
local DIR = WT .. "/DeathNote"
local AM = require("mock_wow")
local BM = require("mock")
BM.mediaDir = DIR .. "/Media"
local G = BM.G

local pass, fail = 0, 0
local function check(name, cond, detail)
  if cond then pass = pass + 1; print("ok    " .. name) else fail = fail + 1; print("ROT   " .. name .. (detail ~= nil and ("  -> " .. tostring(detail)) or "")) end
end

local ns = AM.Load({ noLogin = true })
for _, f in ipairs({ "Alert.lua", "UI.lua", "Extras.lua", "Grudge.lua", "GrudgeCard.lua" }) do
  if not (f == "Grudge.lua" and ns.Grudge) then BM.Load(DIR .. "/" .. f, ns) end
end
AM.FireEvent("PLAYER_LOGIN")
AM.FireEvent("PLAYER_ENTERING_WORLD")
local L, UI = ns.L, ns.UI
local function tick(s) AM.Advance(s or 0.1); BM.Advance(s or 0.1) end
local function settle() BM.Advance(13); BM.FinishAnims(); BM.Advance(1); BM.FinishAnims(); BM.Advance(1) end
local function frameWith(pred) for _, f in ipairs(BM.frames) do if pred(f) then return f end end end
local function menuItems()
  local m = rawget(G, "DeathNoteMenu")
  local out = {}
  if m and m:IsShown() then for _, b in ipairs(m.items) do if b:IsShown() then out[#out + 1] = b end end end
  return out
end
local function pick(label)
  for _, b in ipairs(menuItems()) do
    if b.text._text == label or b.text._text == "• " .. label then b._scripts.OnClick(b, "LeftButton"); tick(); return true end
  end
  return false
end

-- book: a paladin who killed me, a warlock who only assisted
local S = ns.Store
S.AddManual("Pala Hammerfaust"); local pk = S.Find("Pala Hammerfaust")
S.Get(pk).class = "PALADIN"; S.Get(pk).kills = 2
S.AddManual("Velkora Schattenhand"); local vk = S.Find("Velkora Schattenhand")
S.Get(vk).class = "WARLOCK"; S.Get(vk).assists = 1
BM.measure = true
ns:Fire("TOGGLE_UI"); tick(30); settle()
local wanted = frameWith(function(f) return f.id == "wanted" and f._scripts.OnClick and f:IsVisible() end)
wanted._scripts.OnClick(wanted, "LeftButton"); tick()

-- J1: role "killed me" and class "Paladin"
local fb = frameWith(function(f) return f.ovPart and f.tri and f:IsVisible() end)
fb._scripts.OnClick(fb, "LeftButton"); tick()
pick(L.FILTER_KILL)
fb._scripts.OnClick(fb, "LeftButton"); tick()
pick(L.FILTER_CLASS)
local cls = (rawget(G, "LOCALIZED_CLASS_NAMES_MALE") or {}).PALADIN or "PALADIN"
pick(cls)
local word = fb.text._text or ""
check("J1 Filterwort nennt bei Rolle + Klasse auch die Rolle", word:find(L.FILTER_KILL, 1, true) ~= nil, "Filterwort: " .. word)

-- J2: the filter hides the warlock; search "Velk" + Enter must not add a new entry "Velk"
local before = 0
for _ in pairs(S.DB().enemies) do before = before + 1 end
local box = G.DeathNoteSearch
box:SetText("Velk"); if box._scripts.OnTextChanged then box._scripts.OnTextChanged(box, true) end; tick()
if box._scripts.OnEnterPressed then box._scripts.OnEnterPressed(box) end; tick()
local after = 0
for _ in pairs(S.DB().enemies) do after = after + 1 end
check("J2 Enter bei aktivem Filter legt keinen Eintrag aus einem Namensteil an", after == before and not S.Find("Velk"),
  ("Einträge vorher %d, nachher %d, 'Velk' im Buch: %s"):format(before, after, tostring(S.Find("Velk") ~= nil)))

-- J3: book open (scale 1, centred), the notice at its default place on a 1366x768 screen
G.UIParent._w, G.UIParent._h = 1366, 768
if ns.Grudge and ns.Grudge.Test then ns.Grudge.Test() end; tick(1)
local card = rawget(G, "DeathNoteGrudge")
local book = rawget(G, "DeathNoteFrame")
local ORDER = { BACKGROUND = 1, LOW = 2, MEDIUM = 3, HIGH = 4, DIALOG = 5, FULLSCREEN = 6, FULLSCREEN_DIALOG = 7, TOOLTIP = 8 }
local cs, bs = card and card:GetFrameStrata(), book and book:GetFrameStrata()
local above = (ORDER[cs] or 0) > (ORDER[bs] or 0)
local cl, br = card and card:GetLeft(), book and book:GetRight()
local covered = (not above) and cl and br and br > cl
check("J3 Meldung wird vom offenen Buch nicht verdeckt", card and card:IsShown() and not covered,
  ("Meldung %s ab x=%s, Buch %s bis x=%s"):format(tostring(cs), tostring(cl), tostring(bs), tostring(br)))

print(("Jagd UI 1.4.0: %d gruen, %d rot"):format(pass, fail))
os.exit(fail == 0 and 0 or 1)
