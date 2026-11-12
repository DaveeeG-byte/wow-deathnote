-- 1.2.0 (fix-3): das Buch wieder ruhig. Oberflaeche mit der echten Logik, auf Deutsch.
-- (1) Raenge je Quelle (Nach Taeter, Alle und Freunde): jeder Rang einmal, nur ein roter.
-- (2) Plakat: Notiz, Opferzeile und Grund-Feld mit zwei Ankern an derselben Oberkante; kein Wort unter einem
--     Fotostempel; "Auf der Abschussliste" vor Rasse und Gilde; Opferzahl ohne Rolle.
-- (3) Alarm: der eigene Name steht nie im Zusatz "auf der Abschussliste".
-- (4) Kennzeichen nur in "Alle" und nur beim Freund; Tooltip der Statuszeile ohne Wiederholung des Stands.
-- (5) "Keine Freunde auf der Freundesliste" gedaempft statt rot; ohne Gilde und ohne Freund der ruhige Leerzustand.
-- (6) Reisszwecke nur mit "Trockene Bemerkungen"; Gebrauchsanweisung mit acht Absaetzen und einer Fusszeile.
-- Alle Namen sind erfunden.
local DIR0 = (arg[1] or "."):gsub("/+$", "")
package.path = DIR0 .. "/tests/ui/?.lua;" .. DIR0 .. "/tests/?.lua;" .. package.path
arg[0] = DIR0 .. "/tests/ui/fix3.lua"
local DIR = DIR0 .. "/DeathNote"
local AM = require("mock_wow")
local BM = require("mock")
BM.mediaDir = DIR .. "/Media"
local G = BM.G

local pass, fail = 0, 0
local function check(name, cond, detail)
  if cond then pass = pass + 1 else fail = fail + 1; print("ROT   " .. name .. (detail ~= nil and ("  -> " .. tostring(detail)) or "")) end
end
local function clean(name)
  check(name .. ": keine Fehler", #AM.errors == 0, AM.errors[#AM.errors])
  check(name .. ": keine Verstoesse", #BM.violations == 0, BM.violations[#BM.violations])
  AM.errors = {}; for i = #BM.violations, 1, -1 do BM.violations[i] = nil end
end

local FRIENDS = { "Fritz Frei" }
local ns = AM.Load({ noLogin = true, before = function()
  AM.units.player.guild = "Die Testgilde"
  _G.C_FriendList = {
    GetNumFriends = function() return #FRIENDS end,
    GetFriendInfoByIndex = function(i) local n = FRIENDS[i]; if n then return { name = n, connected = true } end end,
    ShowFriends = function() end,
  }
end })
for _, f in ipairs({ "Alert.lua", "UI.lua", "Extras.lua", "Humor.lua" }) do BM.Load(DIR .. "/" .. f, ns) end
AM.FireEvent("PLAYER_LOGIN")
AM.FireEvent("PLAYER_ENTERING_WORLD")
local L, P = ns.L, ns.Guild.Proto

local function tick(s) AM.Advance(s or 0.1); BM.Advance(s or 0.1) end
local function settle() BM.Advance(13); BM.FinishAnims(); BM.Advance(1); BM.FinishAnims(); BM.Advance(1) end
local function frameWith(pred) for _, f in ipairs(BM.frames) do if pred(f) then return f end end end
local function vis(needle)
  for _, f in ipairs(BM.frames) do
    if f._kind == "FontString" and type(f._text) == "string" and f._text:find(needle, 1, true) and f:IsVisible() then return f end
  end
end
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
local function whisper(text, from) AM.FireEvent("CHAT_MSG_ADDON", "DeathNote", text, "WHISPER", from or "Fritz-Forever") end
local function guildMsg(text, from) AM.FireEvent("CHAT_MSG_ADDON", "DeathNote", text, "GUILD", from or "Kollege-Forever") end
local function tab(id) local t = frameWith(function(f) return f.id == id and f._scripts.OnClick end); click(t) end

tick(30); settle()
local t0 = time()
-- Gilde: Rauf Bold 2 Tode, Zwei Ter 1 Tod; Freund: Grimm Bart 3 Tode (nur im Freundesbuch)
whisper(P.EncodeHello(0, "1.2.0"))
for i = 1, 3 do
  whisper(P.EncodeKill({ key = "Grimm-Bart", display = "Grimm Bart", class = "MAGE", level = 40, zone = "Z", t = t0 - 60 * i,
    victim = "Fritz Frei" }, "K"))
end
for i = 1, 2 do
  guildMsg(P.EncodeKill({ key = "Rauf-Bold", display = "Rauf Bold", class = "ROGUE", level = 44, zone = "Z", t = t0 - 90 * i,
    victim = "Kollege Wurst" }, "K"))
end
guildMsg(P.EncodeKill({ key = "Zwei-Ter", display = "Zwei Ter", class = "WARRIOR", level = 30, zone = "Z", t = t0 - 500,
  victim = "Kollege Wurst" }, "K"))
tick(2); settle()
clean("Daten")

ns:Fire("TOGGLE_UI"); tick(); settle()
tab("guild")
ns.UI.SetGuildView("enemy"); tick()
local SRCS = frameWith(function(f) return f.items and f.items[1] and f.items[1].src end)
local VIEWS = frameWith(function(f) return f.items and f.items[1] and f.items[1].view end)

------------------------------------------------------------------------
-- (1) Raenge je Quelle
------------------------------------------------------------------------
local function ranks()
  local seen, list, reds = {}, {}, 0
  local dup = false
  for _, r in ipairs(rows()) do
    local tx = r.rank._text or ""
    if tx ~= "" then
      list[#list + 1] = tx
      if seen[tx] then dup = true end
      seen[tx] = true
      if r.rank._tc and r.rank._tc[1] > 0.5 and r.rank._tc[2] < 0.2 then reds = reds + 1 end
    end
  end
  return table.concat(list, " "), dup, reds
end
check("Beide Quellen da: Quellenwahl sichtbar", SRCS:IsVisible())
click(SRCS.items[1])
local s, dup, reds = ranks()
check("Alle: jeder Rang einmal", not dup and s == "1. 2. 3.", s)
check("Alle: ein roter Rang", reds == 1, reds)
check("Alle: Rang 1 ist der Freundes-Taeter mit drei Toden", rows()[1].item.key == "Grimm-Bart", rows()[1].item.key)
click(SRCS.items[3])
s, dup, reds = ranks()
check("Freunde: nur Rang 1, einmal", s == "1." and reds == 1, s)
click(SRCS.items[2])
s, dup = ranks()
check("Gilde: 1. und 2.", s == "1. 2.", s)
-- Plakat in der Quelle Gilde: Rang aus der Quelle (Rauf Bold ist dort Nr. 1)
for _, r in ipairs(rows()) do if r.item.key == "Rauf-Bold" then click(r) end end
local stamp = frameWith(function(f) return f._kind == "Texture" and f._tex and tostring(f._tex):find("stamp_guild", 1, true) and f:IsVisible() end)
check("Gilde: Plakat von Rauf Bold mit dem Stempel Nr. 1 der Quelle", stamp ~= nil)
click(SRCS.items[1])
for _, r in ipairs(rows()) do if r.item.key == "Rauf-Bold" then click(r) end end
stamp = frameWith(function(f) return f._kind == "Texture" and f._tex and tostring(f._tex):find("stamp_guild", 1, true) and f:IsVisible() end)
check("Alle: Rauf Bold ist Nr. 2, kein Stempel Nr. 1", stamp == nil)
clean("Raenge")

------------------------------------------------------------------------
-- (2) Plakat: Anker, Wort unter dem Stempel, Steckbrief, Opferzahl
------------------------------------------------------------------------
-- Opferzahl ohne Rolle, das Etikett OPFER nur einmal
check("Gildenplakat: Opferzahl ohne Rolle", vis("1 Opfer") ~= nil and vis("KOLLEGE") == nil)
local n = 0
for _, f in ipairs(BM.frames) do if f._kind == "FontString" and f._text == "O P F E R" and f:IsVisible() then n = n + 1 end end
check("Gildenplakat: Etikett OPFER einmal", n == 1, n)
-- kein Fotostempel: das Wort darunter steht
check("ohne Fotostempel: Wort Zur Jagd freigeben unter dem Foto", word("Zur Jagd freigeben") ~= nil)
-- Anker: kein Feld mit zwei senkrechten Mitten (LEFT plus RIGHT)
local function midAnchors(f)
  local m = 0
  for _, p in ipairs(f._points or {}) do if p[1] == "LEFT" or p[1] == "RIGHT" then m = m + 1 end end
  return m
end
local note = frameWith(function(f) return f._kind == "EditBox" and f._maxLetters == 200 end)
    or frameWith(function(f) return f._kind == "EditBox" and f.key ~= nil end)
local bad = {}
for _, f in ipairs(BM.frames) do
  if (f._kind == "EditBox" or f._kind == "FontString") and midAnchors(f) >= 2 then
    local a, b = f._points[1], f._points[2]
    -- erlaubt: zwei Mitten am selben Rahmen (gleiche Hoehe)
    if not (a and b and a[2] == b[2]) then bad[#bad + 1] = tostring(f._kind) .. ":" .. tostring(f._text or f.key or "?") end
  end
end
check("keine zwei Mittel-Anker an verschiedenen Rahmen (Notiz, Opfer, Grund)", #bad == 0, table.concat(bad, ", "))
-- eigenes Buch: Nr. 1 und auf der Abschussliste, mit Rasse und Gilde
local k = ns.Store.AddManual("Ober", "Feind")
local e = ns.Store.Get(k)
e.raceLoc, e.guild, e.level, e.classLoc = "Mensch", "Die Eisenwacht", 60, "Schurke"
ns.Store.ApplyKill({ name = "Ober", surname = "Feind", guid = "Player-1-OF", class = "ROGUE", level = 60 },
  { t = time(), zone = "Z", myLevel = 40, theirLevel = 60 }, true)
guildMsg(P.EncodeHunt({ key = k, display = "Ober Feind", t = time(), by = "Kollege Wurst", why = "x" }))
tick(2)
ns.UI.ShowEnemy(k); tick()
check("Vorbedingung: Rang 1", ns.Store.Rank(k) == 1, ns.Store.Rank(k))
local hl = vis("Auf der Abschussliste (Kollege)")
check("Steckbrief: Abschussliste steht, auch mit Rasse und Gilde", hl ~= nil)
local info = {}
for _, f in ipairs(BM.frames) do
  if f._kind == "FontString" and f:IsVisible() and type(f._text) == "string" and f._text ~= "" and f._fontSize == 11
     and f._points and f._points[1] and f._points[1][1] == "TOPLEFT" and f._w == 192 then info[#info + 1] = f end
end
local order = {}
local cur = frameWith(function(x) return x._kind == "FontString" and x._text == "Stufe 60 · Schurke" and x:IsVisible() end)
while cur do
  order[#order + 1] = cur._text
  local nxt
  for _, f in ipairs(BM.frames) do
    if f._kind == "FontString" and f._points and f._points[1] and f._points[1][2] == cur and f._points[1][3] == "BOTTOMLEFT"
       and f._w == 192 then nxt = f end
  end
  cur = nxt and nxt._text ~= "" and nxt or nil
end
check("Steckbrief: Abschussliste gleich nach der Stufe", order[2] == "Auf der Abschussliste (Kollege)", table.concat(order, " | "))
check("Steckbrief: Rasse weicht zuerst", #order == 4 and order[3] == "Gilde: Die Eisenwacht", table.concat(order, " | "))
check("Fotostempel Nr. 1: kein Wort darunter", word("Zur Jagd freigeben") == nil and word("Jagd abblasen") == nil)
clean("Plakat")

------------------------------------------------------------------------
-- (3) Alarm: eigener Name nie im Zusatz
------------------------------------------------------------------------
local function quiet() for _ = 1, 4 do settle(); BM.Advance(120); AM.Advance(120) end end
local own = ns.Store.AddManual("Selbst", "Gejagt")
ns.Guild.Release(own, { to = "guild", why = "y" }); tick(2)
quiet()
AM.units.mouseover = nil
AM.AddEnemy("mouseover", { name = "Selbst", surname = "Gejagt", guid = "Player-1-SG", level = 40 })
AM.FireEvent("UPDATE_MOUSEOVER_UNIT"); tick()
local popup = rawget(G, "DeathNoteAlert")
check("Alarm fuer den eigenen Gesuchten", popup and popup:IsShown() and (popup.name._text or ""):find("Selbst", 1, true) ~= nil)
check("nur selbst freigegeben: kein Zusatz Abschussliste", popup and not (popup.line._text or ""):find("Abschussliste", 1, true),
  popup and popup.line._text)
guildMsg(P.EncodeHunt({ key = own, display = "Selbst Gejagt", t = time(), by = "Kollege Wurst", why = "z" }))
tick(2); quiet()
AM.FireEvent("UPDATE_MOUSEOVER_UNIT"); tick()
popup = rawget(G, "DeathNoteAlert")
local line = popup and popup.line._text or ""
check("auch ein Kollege: Zusatz mit dem Kollegen, ohne den eigenen Namen", line:find("auf der Abschussliste (Kollege)", 1, true) ~= nil
  and not line:find(ns.Util.Me and tostring(ns.Util.Me()) or "\1", 1, true), line)
ns.Guild.CallOff(own); tick(2)
quiet()
clean("Alarm")

------------------------------------------------------------------------
-- (4) Kennzeichen und Tooltip
------------------------------------------------------------------------
tab("wanted"); tab("guild")
ns.UI.SetGuildView("member"); tick()
click(SRCS.items[1])
local fritz, wurst
for _, r in ipairs(rows()) do
  if r.item.head and r.item.m.name == "Fritz Frei" then fritz = r end
  if r.item.head and r.item.m.name == "Kollege Wurst" then wurst = r end
end
check("Alle: Freund mit FREUND", fritz and fritz.mark._text == "FREUND", fritz and fritz.mark._text)
check("Alle: Kollege ohne Kennzeichen", wurst and (wurst.mark._text or "") == "", wurst and wurst.mark._text)
click(SRCS.items[3])
for _, r in ipairs(rows()) do if r.item.head and r.item.m.name == "Fritz Frei" then fritz = r end end
check("Freunde: kein Kennzeichen (die Quelle sagt es)", fritz and (fritz.mark._text or "") == "", fritz and fritz.mark._text)
click(SRCS.items[1])
local hit = frameWith(function(f) return f._scripts and f._scripts.OnEnter and f._w and f._w > 200 and f._h == 30 and f:IsVisible() end)
G.GameTooltip._lines = {}
if hit then hit._scripts.OnEnter(hit) end
local tl = table.concat(G.GameTooltip._lines or {}, " | ")
local status = vis("Läuft:")
check("Tooltip ohne Wiederholung der Statuszeile", hit ~= nil and status ~= nil and not tl:find(status._text, 1, true), tl)
check("Tooltip: wer und was geteilt wird", tl:find(L.TIP_SHARED, 1, true) ~= nil and tl:find(L.TIP_NOT_SHARED, 1, true) ~= nil, tl)
clean("Kennzeichen und Tooltip")

------------------------------------------------------------------------
-- (5) keine Freunde: gedaempft; niemand: ruhig
------------------------------------------------------------------------
FRIENDS = {}
ns.Friends.Scan(); tick(2)
local fh = ns.Look.GuildHealth("friends")
check("ohne Freunde auf der Liste: gedaempft (calm), nicht rot", fh.reason == "nofriends" and fh.calm == true, fh.reason)
ns.UI.OpenPanel("settings")
click(frameWith(function(f) return f.page == 3 and f._scripts.OnClick end))
if not ns.Store.Setting("ui.guildMore") then click(word("Mehr")) end
local fs = vis(fh.text)
check("Blatt Gilde, Mehr: Stand der Freunde in gedaempfter Tinte", fs and fs._tc and fs._tc[1] < 0.5, fs and fs._tc and fs._tc[1])
click(word("Mehr"))
ns.UI.ClosePanel()
-- niemand: keine Gilde, Teilen mit Freunden aus
AM.units.player.guild = nil
ns.Store.Setting("guild.friends", false)
AM.FireEvent("PLAYER_GUILD_UPDATE"); tick(2)
ns.UI.Refresh(); tick()
check("ohne Gilde und Freunde: Leerzustand", vis("Keine Gilde, keine Freunde.") ~= nil)
check("ohne Gilde und Freunde: keine rote Zeile, kein Umschalter, kein Abgleichen",
  vis("Keine Gilde und keine Freunde zum Teilen.") == nil and not VIEWS:IsVisible() and not SRCS:IsVisible() and word("Abgleichen") == nil)
AM.units.player.guild = "Die Testgilde"
ns.Store.Setting("guild.friends", true)
FRIENDS = { "Fritz Frei" }
AM.FireEvent("PLAYER_GUILD_UPDATE"); ns.Friends.Scan(); tick(2)
ns.UI.Refresh(); tick()
clean("Ruhig")

------------------------------------------------------------------------
-- (6) Reisszwecke, Gebrauchsanweisung
------------------------------------------------------------------------
tab("wanted")
ns.UI.ShowEnemy(k); tick()
local pin = frameWith(function(f) return f._kind == "Button" and f._w == 28 and f._h == 28 and f.wobble end)
check("Reisszwecke klickbar mit Trockenen Bemerkungen", pin and pin:IsShown())
ns.Store.Setting("humor", false)
ns.UI.ShowEnemy(k); tick()
check("Trockene Bemerkungen aus: Reisszwecke nicht klickbar", pin and not pin:IsShown())
ns.Store.Setting("humor", true)
ns.UI.OpenPanel("help"); tick()
check("Gebrauchsanweisung: acht Absaetze", #ns.UI.HELP == 8, #ns.UI.HELP)
local heads = {}
for _, p in ipairs(ns.UI.HELP) do heads[#heads + 1] = p[1] end
check("kein Absatz JAGD, kein IMPRESSUM", not table.concat(heads, ","):find("JAGD", 1, true) and not table.concat(heads, ","):find("IMPRESSUM", 1, true),
  table.concat(heads, ","))
local guildPara
for _, p in ipairs(ns.UI.HELP) do if p[1] == L.MANUAL_GUILD_HEAD then guildPara = p[2] end end
check("Absatz Gilde nennt das Freigeben", guildPara and guildPara:find("zur Jagd freigeben", 1, true) ~= nil, guildPara)
local foot = vis(ns.UI.HELP_FOOT or "\1")
-- 1.2.2: in the standing foot bar of the page, above the button, at most two lines (was one line hanging at BOTTOM 44)
check("Imprint: in the foot bar above the button, at most two lines", foot and foot._points[1][1] == "BOTTOM"
  and foot._points[1][5] == 40 and (foot._maxl or 0) <= 2 and foot._parent and foot._parent._kind == "Frame"
  and foot._parent._parent and foot._parent._parent.page and foot._parent == foot._parent._parent.page.foot,
  foot and tostring(foot._points[1][5]))
check("Impressum nennt die Fachkraefte", (ns.UI.HELP_FOOT or ""):find("Die Fachkräfte", 1, true) ~= nil)
ns.UI.ClosePanel()
clean("Reisszwecke und Gebrauchsanweisung")

print(("Fixe fix-3 UI: %d gruen, %d rot"):format(pass, fail))
os.exit(fail == 0 and 0 or 1)
