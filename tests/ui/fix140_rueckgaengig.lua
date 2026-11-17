-- 1.4.0 fixer (hunt logic 2, UI): "Undo" after "Copy all" and after copying one row never costs own data: an entry
-- that got a note, a pardon or a death in between stays, the untouched ones go, the result line says how many stayed.
-- Real logic. All names are made up.
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
local L, UI, F = ns.L, ns.UI, ns.F
local S = ns.Store
local function tick(s) AM.Advance(s or 0.1); BM.Advance(s or 0.1) end
local function settle() BM.Advance(13); BM.FinishAnims(); BM.Advance(1); BM.FinishAnims(); BM.Advance(1) end
local function frameWith(pred) for _, f in ipairs(BM.frames) do if pred(f) then return f end end end
local function vis(needle)
  for _, f in ipairs(BM.frames) do
    if f._kind == "FontString" and type(f._text) == "string" and f._text:find(needle, 1, true) and f:IsVisible() then return f end
  end
end
local function click(f, b) f._scripts.OnClick(f, b or "LeftButton"); tick() end
local function button(label)
  return frameWith(function(f) return f.text and f.text._text == label and f._scripts.OnClick and f:IsVisible() end)
end
local function rows()
  local out = {}
  for _, f in ipairs(BM.frames) do if f._kind == "Button" and f.item and f._shown and f.under then out[#out + 1] = f end end
  return out
end
local function rowOf(key) for _, r in ipairs(rows()) do if r.item.key == key then return r end end end
local function whisper(text) AM.FireEvent("CHAT_MSG_ADDON", "DeathNote", text, "WHISPER", "Fritz-Forever") end

BM.measure = true
ns:Fire("TOGGLE_UI"); tick(30); settle()
local P = ns.Guild.Proto
local t = time()
whisper(P.EncodeHello(0, "1.4.0"))
local KILLERS = { { "Grimm-Bart", "Grimm Bart", "Grimm", "Bart" }, { "Fies-Ling", "Fies Ling", "Fies", "Ling" },
  { "Dorn-Fels", "Dorn Fels", "Dorn", "Fels" }, { "Rabe-Ruf", "Rabe Ruf", "Rabe", "Ruf" } }
for i, x in ipairs(KILLERS) do
  whisper(P.EncodeKill({ key = x[1], display = x[2], class = "MAGE", level = 40, zone = "Ödland", t = t - 60 * i, victim = "Fritz Frei" }, "K"))
end
tick(2); settle()
UI.SetFilter("guild"); tick()
UI.SetGuildView("enemy"); tick()

-- all four copied; then a note, a pardon and a death of mine at three of them
click(button(L.ACT_TAKE_ALL))
click(button(L.ACT_TAKE))
check("alle vier im Buch", S.Get("Grimm-Bart") and S.Get("Fies-Ling") and S.Get("Dorn-Fels") and S.Get("Rabe-Ruf") and true)
S.SetNote("Grimm-Bart", "der mit dem Hut")
S.SetStatus("Fies-Ling", "pardoned")
S.ApplyKill({ name = "Dorn", surname = "Fels" }, { t = time(), zone = "Ödland", source = "recap" }, true)
tick(1)
click(button(L.ACT_UNDO))
check("Notiz bleibt", S.Get("Grimm-Bart") and S.Get("Grimm-Bart").note == "der mit dem Hut")
check("Begnadigung bleibt", S.Get("Fies-Ling") and S.Get("Fies-Ling").status == "pardoned")
check("Tod bleibt", S.Get("Dorn-Fels") and S.Get("Dorn-Fels").kills == 1)
check("Unberuehrtes geht", S.Get("Rabe-Ruf") == nil)
check("Ergebniszeile nennt die gebliebenen", vis(F(L.TAKE_UNDONE_KEPT, { count = 1, kept = 3 })) ~= nil)
click(button(L.BTN_DONE))

-- one row: copied, a note, undo keeps it
local rabe = rowOf("Rabe-Ruf")
check("Zeile Rabe", rabe ~= nil)
if rabe then click(rabe.take) end
check("Rabe kopiert", S.Get("Rabe-Ruf") ~= nil)
S.SetNote("Rabe-Ruf", "Notiz")
tick(1)
click(button(L.ACT_UNDO))
check("einzeln: Notiz bleibt", S.Get("Rabe-Ruf") and S.Get("Rabe-Ruf").note == "Notiz")
check("einzeln: gemeldet", vis(F(L.TAKE_UNDONE_KEPT, { count = 0, kept = 1 })) ~= nil)
check("keine Fehler", #AM.errors == 0, AM.errors[#AM.errors])

print(("fix140 rueckgaengig UI: %d gruen, %d rot"):format(pass, fail))
os.exit(fail == 0 and 0 or 1)
