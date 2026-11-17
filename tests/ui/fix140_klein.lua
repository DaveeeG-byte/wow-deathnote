-- 1.4.0 fixer, small findings of the UI hunt: "Copy all" with nothing new (the lone button in the middle, no friends'
-- hint), the section heads of Wanted in small letter-spaced print (not the handwriting of a name), the hit list's
-- button says the same as everywhere else ("Copy to my book" / "Übernehmen"). Real logic. All names are made up.
local here = arg[0]:match("^(.*)/[^/]+$") or "."
package.path = here .. "/?.lua;" .. here .. "/../?.lua;" .. package.path
local DIR = here .. "/../../DeathNote"
local AM = require("mock_wow")
local BM = require("mock")
BM.mediaDir = DIR .. "/Media"
local pass, fail = 0, 0
local function check(name, cond, detail)
  if cond then pass = pass + 1 else fail = fail + 1; print("ROT   " .. name .. (detail ~= nil and ("  -> " .. tostring(detail)) or "")) end
end
local FRIENDS = { "Fritz Frei" }
local ns = AM.Load({ noLogin = true, before = function()
  _G.C_FriendList = {
    GetNumFriends = function() return #FRIENDS end,
    GetFriendInfoByIndex = function(i) local n = FRIENDS[i]; if n then return { name = n, connected = true } end end,
    ShowFriends = function() end,
  }
end })
for _, f in ipairs({ "Alert.lua", "UI.lua", "Extras.lua" }) do BM.Load(DIR .. "/" .. f, ns) end
AM.FireEvent("PLAYER_LOGIN"); AM.FireEvent("PLAYER_ENTERING_WORLD")
local L, UI, S = ns.L, ns.UI, ns.Store
local function tick(s) AM.Advance(s or 0.1); BM.Advance(s or 0.1) end
local function settle() BM.Advance(13); BM.FinishAnims(); BM.Advance(1); BM.FinishAnims(); BM.Advance(1) end
local function frameWith(pred) for _, f in ipairs(BM.frames) do if pred(f) then return f end end end
local function button(label)
  return frameWith(function(f) return f.text and f.text._text == label and f._scripts.OnClick and f:IsVisible() end)
end
local function vis(needle)
  for _, f in ipairs(BM.frames) do
    if f._kind == "FontString" and type(f._text) == "string" and f._text:find(needle, 1, true) and f:IsVisible() then return f end
  end
end
local function whisper(text) AM.FireEvent("CHAT_MSG_ADDON", "DeathNote", text, "WHISPER", "Fritz-Forever") end

BM.measure = true
ns:Fire("TOGGLE_UI"); tick(30); settle()
local P = ns.Guild.Proto
whisper(P.EncodeHello(0, "1.4.0"))
whisper(P.EncodeKill({ key = "Grimm-Bart", display = "Grimm Bart", class = "MAGE", level = 40, zone = "Ödland", t = time() - 60, victim = "Fritz Frei" }, "K"))
tick(2); settle()
UI.SetFilter("guild"); tick()
UI.SetGuildView("enemy"); tick()

-- "Copy all" while the one name is new: two buttons side by side, the friends' hint
UI.OV.OpenTake(); tick()
local go, back = button(L.ACT_TAKE), button(L.BTN_BACK)
check("mit Neuem: zwei Knoepfe", go ~= nil and back ~= nil)
check("mit Neuem: Zurueck rechts", back and select(4, back:GetPoint(1)) == 57)
check("mit Neuem: Freundes-Hinweis", vis(L.TAKE_HINT_FRIENDS) ~= nil)
back._scripts.OnClick(back, "LeftButton"); tick()
-- nothing new
S.AddManual("Grimm", "Bart")
UI.Refresh(); tick()
UI.OV.OpenTake(); tick()
back = button(L.BTN_BACK)
check("nichts neu: kein Uebernehmen", button(L.ACT_TAKE) == nil)
check("nichts neu: Zurueck mittig", back and select(4, back:GetPoint(1)) == 0, back and select(4, back:GetPoint(1)))
check("nichts neu: kein Freundes-Hinweis", vis(L.TAKE_HINT_FRIENDS) == nil)
if back then back._scripts.OnClick(back, "LeftButton"); tick() end

-- section head of Wanted: small letter-spaced print
S.AddManual("Ruhig", "Gnade"); S.SetStatus("Ruhig-Gnade", "pardoned")
S.ApplyKill({ name = "Fies", surname = "Ling" }, { t = time(), zone = "Z", source = "recap" }, true)
UI.SetFilter("wanted"); tick(); settle()
local hrow
for _, f in ipairs(BM.frames) do if f._kind == "Button" and f.item and f.item.ovHead and f._shown then hrow = f end end
check("Abschnittskopf da", hrow ~= nil)
check("Abschnittskopf klein (11 pt oder kleiner)", hrow and (hrow.name._fontSize or 99) <= 11, hrow and hrow.name._fontSize)
check("Abschnittskopf gesperrt", hrow and hrow.name._text:find(" ", 1, true) and hrow.name._text:gsub(" ", "") == L.SECTION_PARDONED:gsub(" ", ""),
  hrow and hrow.name._text)
check("Zahl rechts", hrow and hrow.right:IsShown() and hrow.right._text == "1")
check("kein Dreieck", hrow and not hrow.tri:IsShown())

-- the hit list's button: the same word as everywhere else
do
  local f = assert(io.open(DIR .. "/UI.lua"))
  local src = f:read("*a"); f:close()
  local body = src:match("function GF%.HuntSpec%(h%)(.-)\nend")
  check("Abschussliste: Uebernehmen statt Ins eigene Buch", body and body:find("L.ACT_TAKE", 1, true) and not body:find("ACT_ADOPT", 1, true))
end
check("keine Fehler", #AM.errors == 0, AM.errors[#AM.errors])
print(("fix140 klein UI: %d gruen, %d rot"):format(pass, fail))
os.exit(fail == 0 and 0 or 1)
