-- 1.4.0 fixer (hunt UI 2 and 3): filter and search together. The search finds someone only the filter hides: the
-- page and the foot say "n matches hidden by the filter · show all", Enter shows them (the filter goes, the search
-- stays) and adds nothing; Enter adds only a name that is nowhere in the book. Role and class filter together: both
-- words ("Killed me · Paladin"), else "2 filters", the tooltip names both. Real logic. All names are made up.
local WT = arg[1] or "."
package.path = WT .. "/tests/ui/?.lua;" .. WT .. "/tests/?.lua;" .. package.path
local DIR = WT .. "/DeathNote"
local AM = require("mock_wow")
local BM = require("mock")
BM.mediaDir = DIR .. "/Media"
local G = BM.G
local pass, fail = 0, 0
local function check(name, cond, detail)
  if cond then pass = pass + 1 else fail = fail + 1; print("ROT   " .. name .. (detail ~= nil and ("  -> " .. tostring(detail)) or "")) end
end
local ns = AM.Load({ noLogin = true })
for _, f in ipairs({ "Alert.lua", "UI.lua", "Extras.lua" }) do BM.Load(DIR .. "/" .. f, ns) end
AM.FireEvent("PLAYER_LOGIN"); AM.FireEvent("PLAYER_ENTERING_WORLD")
local L, UI, F, S = ns.L, ns.UI, ns.F, ns.Store
local function tick(s) AM.Advance(s or 0.1); BM.Advance(s or 0.1) end
local function settle() BM.Advance(13); BM.FinishAnims(); BM.Advance(1); BM.FinishAnims(); BM.Advance(1) end
local function frameWith(pred) for _, f in ipairs(BM.frames) do if pred(f) then return f end end end
local function vis(needle)
  for _, f in ipairs(BM.frames) do
    if f._kind == "FontString" and type(f._text) == "string" and f._text:find(needle, 1, true) and f:IsVisible() then return f end
  end
end
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
local function count() local n = 0; for _ in pairs(S.DB().enemies) do n = n + 1 end; return n end

S.AddManual("Pala Hammerfaust"); local pk = S.Find("Pala Hammerfaust")
S.Get(pk).class = "PALADIN"; S.Get(pk).kills = 2
S.AddManual("Velkora Schattenhand"); local vk = S.Find("Velkora Schattenhand")
S.Get(vk).class = "WARLOCK"; S.Get(vk).assists = 1
S.AddManual("Ruhig Gnade"); local rk = S.Find("Ruhig Gnade")
S.SetStatus(rk, "pardoned")
BM.measure = true
ns:Fire("TOGGLE_UI"); tick(30); settle()
UI.SetFilter("wanted"); tick()

-- role and class: both words, tooltip both
local fb = frameWith(function(f) return f.ovPart and f.tri and f:IsVisible() end)
fb._scripts.OnClick(fb, "LeftButton"); tick(); pick(L.FILTER_KILL)
fb._scripts.OnClick(fb, "LeftButton"); tick(); pick(L.FILTER_CLASS)
local cls = (rawget(G, "LOCALIZED_CLASS_NAMES_MALE") or {}).PALADIN or "PALADIN"
pick(cls)
check("Filterwort: Rolle und Klasse", fb.text._text == L.FILTER_KILL .. " · " .. cls, fb.text._text)
check("Tooltip nennt beide", fb.tip and fb.tip[2] == L.FILTER_KILL and fb.tip[3] == cls)
local search = G.DeathNoteSearch
check("Suchfeld behaelt Platz", (search:GetWidth() or 0) >= ns.UI.OV.SEARCH_MIN, search:GetWidth())
-- too narrow: "2 filters"
ns.UI.OV.FILTER_W2 = 40; UI.Refresh(); tick()
check("passt nicht: 2 Filter", fb.text._text == F(L.FILTER_TWO, { count = 2 }), fb.text._text)
check("Tooltip nennt weiter beide", fb.tip and fb.tip[2] == L.FILTER_KILL and fb.tip[3] == cls)
ns.UI.OV.FILTER_W2 = 170; UI.Refresh(); tick()

-- search "Velk": only the filter hides her
local before = count()
search:SetText("Velk"); search._scripts.OnTextChanged(search, true); tick()
check("leere Seite: vom Filter verdeckt", vis(L.EMPTY_HIDDEN_HEAD) ~= nil)
check("keine Enter-legt-an-Zeile", vis(L.EMPTY_SEARCH_SUB) == nil)
check("Fuss: 1 Treffer vom Filter verdeckt", vis(F(L.FILTER_HIDDEN, { count = 1 })) ~= nil)
search._scripts.OnEnterPressed(search); tick()
check("Enter legt nichts an", count() == before and not S.Find("Velk"))
check("Enter zeigt sie: Filter weg, Suche bleibt", ns.UI.OV.Filtered() == false and search:GetText() == "Velk"
  and vis("Velkora Schattenhand") ~= nil)

-- the foot line: a click drops only the filter while it hides matches
fb._scripts.OnClick(fb, "LeftButton"); tick(); pick(L.FILTER_KILL)
check("wieder verdeckt", vis(F(L.FILTER_HIDDEN, { count = 1 })) ~= nil)
local fh = frameWith(function(f) return f.ovPart and f.text and f:IsVisible() and f._scripts.OnClick and not f.tri end)
fh._scripts.OnClick(fh, "LeftButton"); tick()
check("Fussklick: Filter weg, Suche bleibt", ns.UI.OV.Filtered() == false and search:GetText() == "Velk")

-- a pardoned entry while the pardoned are hidden: "in your book already", Enter opens it, nothing new
S.Setting("ui.showPardoned", false); UI.Refresh(); tick()
search:SetText("Ruhig"); search._scripts.OnTextChanged(search, true); tick()
check("Begnadigter versteckt: steht schon im Buch", vis(L.EMPTY_SEARCHHAS_HEAD) ~= nil)
before = count()
search._scripts.OnEnterPressed(search); tick()
check("Enter legt nichts an", count() == before)
check("Enter oeffnet ihn", vis("Ruhig Gnade") ~= nil)

-- a name that is nowhere: Enter adds it as before
search:SetText("Neu Ling"); search._scripts.OnTextChanged(search, true); tick()
check("unbekannt: Enter legt an (Hinweis)", vis(L.EMPTY_SEARCH_SUB) ~= nil)
search._scripts.OnEnterPressed(search); tick()
check("unbekannt: angelegt", S.Find("Neu Ling") ~= nil)
check("keine Fehler", #AM.errors == 0, AM.errors[#AM.errors])

print(("fix140 filter UI: %d gruen, %d rot"):format(pass, fail))
os.exit(fail == 0 and 0 or 1)
