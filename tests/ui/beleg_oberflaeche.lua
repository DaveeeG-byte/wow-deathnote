-- Oberflaeche ueber den UI-Mock (tests/ui/mock.lua) mit der echten Logik. Rundwege und Zustaende.
-- Funde: (a) Freigabe "nur Freunde" bei Quelle "Gilde": das Buch springt in die Abschussliste, das
-- Ziel steht dort aber nicht. (b) Die Erlegt-Meldung kommt auch, wenn alle Meldungen und Warnungen
-- der Gilde abgeschaltet sind (kein Schalter). Der Rest sind Rundwege, die gruen sein sollen.
-- (fix-1: in die Suite uebernommen; Teil (b) an den neuen Schalter guild.announceHunt angepasst.)
package.path = (arg[0]:match("^(.*)/") or ".") .. "/../?.lua;" .. (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local H = require("beleg_helfer")
package.path = H.DIR .. "/tests/ui/?.lua;" .. package.path
local AM = H.M
local BM = require("mock")
local DIR = H.DIR .. "/DeathNote"
BM.mediaDir = DIR .. "/Media"
local G = BM.G

local FRIENDS = { "Fritz Frei" }
local ns = AM.Load({ noLogin = true, before = function()
  AM.units.player.guild = "Die Testgilde"
  _G.C_FriendList = {
    GetNumFriends = function() return #FRIENDS end,
    GetFriendInfoByIndex = function(i) local n = FRIENDS[i]; if n then return { name = n, connected = true } end end,
    ShowFriends = function() end,
  }
end })
for _, f in ipairs({ "Alert.lua", "UI.lua", "Extras.lua" }) do BM.Load(DIR .. "/" .. f, ns) end
AM.FireEvent("PLAYER_LOGIN")
AM.FireEvent("PLAYER_ENTERING_WORLD")

local function tick(s) AM.Advance(s or 0.1); BM.Advance(s or 0.1) end
local function settle() BM.Advance(13); BM.FinishAnims(); BM.Advance(1); BM.FinishAnims(); BM.Advance(1) end
local function frameWith(pred) for _, f in ipairs(BM.frames) do if pred(f) then return f end end end
local function tab(id) local t = frameWith(function(f) return f.id == id and f._scripts.OnClick end); t._scripts.OnClick(t); tick() end
local function click(f, b) f._scripts.OnClick(f, b or "LeftButton"); tick() end
local function word(label)
  return frameWith(function(f) return f.text and f.text._text == label and f._scripts.OnClick and f:IsVisible() end)
end
local function rows()
  local out = {}
  for _, f in ipairs(BM.frames) do if f._kind == "Button" and f.item and f._shown and f.under then out[#out + 1] = f end end
  table.sort(out, function(a, b) return (a.index or 0) < (b.index or 0) end)
  return out
end
local function rowKeys() local t = {} for _, r in ipairs(rows()) do t[#t + 1] = tostring(r.item.key) end return table.concat(t, ",") end
local function whisper(text, from) AM.FireEvent("CHAT_MSG_ADDON", "DeathNote", text, "WHISPER", from or "Fritz-Forever") end
local function guildMsg(text, from) AM.FireEvent("CHAT_MSG_ADDON", "DeathNote", text, "GUILD", from or "Kollege-Forever") end
local function sauber(name)
  H.erwartet(name .. ": keine Lua-Fehler", #AM.errors == 0, AM.errors[#AM.errors])
  H.erwartet(name .. ": keine Verstoesse im UI-Mock", #BM.violations == 0, BM.violations[#BM.violations])
  AM.errors = {}; for i = #BM.violations, 1, -1 do BM.violations[i] = nil end
end

ns:Fire("TOGGLE_UI"); tick(30); settle()
local P = ns.Guild.Proto
tab("guild")
local SRCS = frameWith(function(f) return f.items and f.items[1] and f.items[1].src end)
local VIEWS = frameWith(function(f) return f.items and f.items[1] and f.items[1].view end)
local function view(i) VIEWS.items[i]._scripts.OnClick(VIEWS.items[i]); tick() end
local function src(i) click(SRCS.items[i]); tick() end
sauber("Start")

-- Daten: ein Freund, ein Kollege
whisper(P.EncodeHello(0, "1.2.0"))
whisper(P.EncodeKill({ key = "Grimm-Bart", display = "Grimm Bart", class = "MAGE", level = 40, zone = "Z", t = time() - 60, victim = "Fritz Frei" }, "K"))
guildMsg(P.EncodeKill({ key = "Rauf-Bold", display = "Rauf Bold", class = "ROGUE", level = 44, zone = "Z", t = time() - 90, victim = "Kollege Wurst" }, "K"))
tick(2); settle()

------------------------------------------------------------------------
-- (a) Freigabe nur fuer Freunde, waehrend die Quelle auf "Gilde" steht
------------------------------------------------------------------------
src(2); view(2)
local rb
for _, r in ipairs(rows()) do if r.item.key == "Rauf-Bold" then rb = r end end
H.erwartet("Vorbedingung: Rauf Bold in Quelle Gilde", rb ~= nil, rowKeys())
if rb then
  click(rb)
  local hw = word("Zur Jagd freigeben") or frameWith(function(f) return f.key == "Rauf-Bold" and f.text and f._scripts.OnClick and f:IsVisible() end)
  -- fix-3: unter dem Stempel Nr. 1 kein Wort am Plakat; dann ueber das Zeilenmenue
  if not hw then click(rb, "RightButton"); hw = word("Zur Jagd freigeben") end
  click(hw)
  local R = frameWith(function(f) return f.edit and f.tabs and f.go end)
  click(R.tabs[3])                       -- nur Freunde
  R.edit:SetText("nur fuer Freunde")
  click(R.go)
  sauber("Freigabe nur Freunde")
  local g, f = ns.Guild.Released("Rauf-Bold")
  H.erwartet("Freigabe steht nur im Freundesbuch", g == false and f == true, tostring(g) .. "/" .. tostring(f))
  H.erwartet("nach dem Freigeben steht das Ziel in der aufgeschlagenen Abschussliste",
    rowKeys():find("Rauf-Bold", 1, true) ~= nil, "Quelle " .. tostring(ns.Store.Setting("ui.guildSource")) .. ", Zeilen: [" .. rowKeys() .. "]")
end

------------------------------------------------------------------------
-- Rundwege: Ansicht und Quelle wechseln bei offenem Plakat, Buch zu und auf
------------------------------------------------------------------------
src(1); view(3)
ns.Guild.Release("Grimm-Bart", { to = "all", why = "beide" }); tick(1); ns.UI.Refresh()
local before = rowKeys()
for _ = 1, 3 do for i = 1, 3 do view(i); for s = 1, 3 do src(s) end end end
src(1); view(3)
sauber("Rundweg Ansicht mal Quelle")
H.erwartet("nach dem Rundweg dieselbe Abschussliste", rowKeys() == before, before .. " / " .. rowKeys())
ns:Fire("TOGGLE_UI"); tick(1); settle(); ns:Fire("TOGGLE_UI"); tick(1); settle()
sauber("Buch zu und auf")
H.erwartet("nach Zu und Auf dieselbe Abschussliste", rowKeys() == before, before .. " / " .. rowKeys())

-- Quelle wechseln, waehrend ein Ziel gewaehlt ist, das es dort nicht gibt
local rr
for _, r in ipairs(rows()) do if r.item.key == "Rauf-Bold" then rr = r end end
if rr then click(rr) end
src(2)
sauber("Quelle wechseln mit gewaehltem Ziel")
src(1)

-- Freigeben, sofort abblasen (Knopf am Plakat), wieder freigeben
for _, r in ipairs(rows()) do if r.item.key == "Grimm-Bart" then click(r) end end
local ab = word("Jagd abblasen")
H.erwartet("Knopf Jagd abblasen am Plakat der eigenen Freigabe", ab ~= nil)
if ab then click(ab) end
sauber("Abblasen am Plakat")
H.erwartet("Ziel nach dem Abblasen weg", ns.Guild.Hunt("Grimm-Bart", "all") == nil)
H.erwartet("Liste ohne das Ziel", rowKeys():find("Grimm-Bart", 1, true) == nil, rowKeys())

-- fremdes Abblasen der letzten Freigabe bei offenem Plakat
guildMsg(P.EncodeHunt({ key = "Einzel-Ziel", display = "Einzel Ziel", t = time(), by = "Kollege Wurst", why = "x" }))
tick(2); ns.UI.Refresh()
for _, r in ipairs(rows()) do if r.item.key == "Einzel-Ziel" then click(r) end end
guildMsg(P.EncodeCallOff("Einzel-Ziel", "Kollege Wurst")); tick(2); settle()
sauber("Fremdes Abblasen bei offenem Plakat")
ns.Guild.CallOff("Rauf-Bold"); tick(2); settle()
sauber("Leere Abschussliste nach dem letzten Abblasen")
H.erwartet("Abschussliste ist leer", ns.Guild.HuntCount("all") == 0, ns.Guild.HuntCount("all"))

-- Kampf: Freigeben-Blatt oeffnen, Grund tippen, freigeben, abblasen
AM.inCombat = true
ns.UI.OpenRelease("Grimm-Bart"); tick()
local R = frameWith(function(f) return f.edit and f.tabs and f.go end)
R.edit:SetText("im Kampf"); click(R.go)
sauber("Freigeben im Kampf")
H.erwartet("Freigabe im Kampf angenommen", ns.Guild.Hunt("Grimm-Bart", "all") ~= nil)
ns.Guild.CallOff("Grimm-Bart"); tick(1)
AM.inCombat = false
AM.FireEvent("PLAYER_REGEN_ENABLED"); tick(5)
sauber("Kampfende")

------------------------------------------------------------------------
-- (b) Erlegt-Meldung ohne Schalter
------------------------------------------------------------------------
settle(); BM.Advance(60); AM.Advance(60)
guildMsg(P.EncodeHunt({ key = "Einzel-Ziel", display = "Einzel Ziel", t = time(), by = "Kollege Wurst", why = "x" })); tick(2)
-- (fix-1) eigener Schalter "Abschussliste melden" (guild.announceHunt) auf dem Blatt Gilde; die anderen
-- Schalter lassen die Meldung, er allein nimmt sie weg
ns.Store.Setting("guild.announce", false)
ns.Store.Setting("guild.alertHunt", false)
ns.Store.Setting("guild.alert", false)
if rawget(G, "DeathNoteBanner") then rawget(G, "DeathNoteBanner"):Hide() end
guildMsg(P.EncodeBagged("Einzel-Ziel", "Kollege Wurst", time())); tick(1)
local shown = rawget(G, "DeathNoteBanner") and rawget(G, "DeathNoteBanner"):IsShown()
H.erwartet("Schalter Abschussliste melden an: die Erlegt-Meldung kommt", shown, "kein Fenster")
for _ = 1, 3 do settle(); BM.Advance(30); AM.Advance(60) end   -- mehr als 2 Minuten: eine neue Toetung
ns.Store.Setting("guild.announceHunt", false)
if rawget(G, "DeathNoteBanner") then rawget(G, "DeathNoteBanner"):Hide() end
guildMsg(P.EncodeBagged("Einzel-Ziel", "Kollege Wurst", time())); tick(1)
shown = rawget(G, "DeathNoteBanner") and rawget(G, "DeathNoteBanner"):IsShown()
H.erwartet("mit abgeschalteter Meldung zur Abschussliste kommt kein Erlegt-Fenster", not shown,
  "Fenster trotz announceHunt=false")
local hh = ns.Guild.Hunt("Einzel-Ziel", "all")
H.erwartet("gezaehlt wird trotzdem (zwei Toetungen)", hh and hh.bagged == 2, hh and hh.bagged)
sauber("Erlegt-Meldung")

H.fertig()
