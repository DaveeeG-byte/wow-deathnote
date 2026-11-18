-- 1.5.0 share: the window "Show" (ShareUI.lua) with the real logic. The word on the poster (own book, guild book, hit
-- list) and in the row menu only where the entry may be shown; the window: preview = the line, only the channels that
-- work, one click = one line, the wait, combat; the week; the Discord block (marked, never the note); the click on a
-- link: own poster, guild poster, guest poster with "Copy to my book"; the button on the payback notice only with the
-- switch, and the line of the next notice back in its place; the switch on the Guild sheet. 21 languages: the word
-- and the strip under the head side by side, the window's texts inside it, nothing cut without a tooltip.
-- Use: luajit tests/ui/share.lua [project folder]. All names are made up.
local DIR = ((arg and arg[1]) or "."):gsub("/+$", "")
package.path = DIR .. "/tests/ui/?.lua;" .. DIR .. "/tests/?.lua;" .. package.path
local ADDON = DIR .. "/DeathNote"
local ok, bad = 0, 0
local function check(name, cond, info)
  if cond then ok = ok + 1
  else bad = bad + 1; io.write("RED   ", name, info ~= nil and ("  -> " .. tostring(info)) or "", "\n") end
end

local function world(code, settings)
  package.loaded.mock_wow, package.loaded.mock = nil, nil
  local AM = require("mock_wow")
  local BM = require("mock")
  BM.mediaDir = ADDON .. "/Media"
  BM.measure = true
  AM.locale = code or "deDE"
  local files = {}
  for _, f in ipairs(AM.Files()) do files[#files + 1] = f end
  files[#files + 1] = "Share.lua"
  local ns = AM.Load({ noLogin = true, files = files, db = settings and { settings = settings } or nil })
  for _, f in ipairs({ "Alert.lua", "UI.lua", "Extras.lua", "ShareUI.lua" }) do BM.Load(ADDON .. "/" .. f, ns) end
  local W = { AM = AM, BM = BM, G = BM.G, ns = ns, sent = {}, clicks = {} }
  rawset(BM.G, "EventRegistry", { RegisterCallback = function(_, ev, fn, owner) W.clicks[ev] = { fn, owner } end })
  AM.FireEvent("PLAYER_LOGIN")
  AM.FireEvent("PLAYER_ENTERING_WORLD")
  _G.SendChatMessage = function(text, ch) W.sent[#W.sent + 1] = { text = text, ch = ch } end
  _G.IsInRaid, _G.IsInGroup = function() return W.raid == true end, function() return W.party == true end
  function W.tick(s) AM.Advance(s or 0.1); BM.Advance(s or 0.1) end
  function W.settle() BM.Advance(13); BM.FinishAnims(); BM.Advance(1); BM.FinishAnims(); BM.Advance(1) end
  function W.win() return rawget(BM.G, "DeathNoteShare") end
  function W.guest() return rawget(BM.G, "DeathNoteShareGuest") end
  function W.button(label, parent)
    for _, f in ipairs(BM.frames) do
      if (f._kind == "Button") and f.text and f.text._text == label and f._scripts.OnClick and f:IsVisible() then
        if not parent then return f end
        local o = f
        while o do if o == parent then return f end o = o._parent end
      end
    end
  end
  function W.click(b) if b then b._scripts.OnClick(b, "LeftButton") end end
  function W.kill(name, surname, t)
    return ns.Store.ApplyKill({ name = name, surname = surname, class = "ROGUE", level = 40 },
      { t = t or _G.time() - 60, zone = "Schlingendorntal", subzone = "Grom'gol", source = "recap" }, true)
  end
  ns:Fire("TOGGLE_UI"); W.tick(30); W.settle()
  return W
end

local W = world("deDE")
local ns, L, S, Sh, SU = W.ns, W.ns.L, W.ns.Store, W.ns.Share, W.ns.ShareUI
local UI = ns.UI
local Fmt = ns.F

------------------------------------------------------------------------
-- 1) the word on the poster and the menu entry
------------------------------------------------------------------------
local grimm = W.kill("Grimm", "Bart")
S.SetNote(grimm, "GEHEIMNOTIZ")
local sus = S.ApplyKill({ name = "Vera", surname = "Verdacht" }, { t = _G.time() - 30, zone = "Z", source = "suspect" }, false)
local att = S.AddAttack({ name = "Arno", surname = "Angriff", class = "MAGE" }, { t = _G.time() - 20, zone = "Z" })
UI.ShowEnemy(grimm); W.tick(); W.settle()
local F = rawget(W.G, "DeathNoteFrame")
local word = W.button(L.ACT_SHARE, F)
check("Wort Zeigen am Plakat eines Gesuchten", word ~= nil)
UI.ShowEnemy(att); W.tick(); W.settle()
check("kein Wort bei nur Angriffen", W.button(L.ACT_SHARE, F) == nil)
UI.ShowEnemy(sus); W.tick(); W.settle()
check("kein Wort bei Verdacht", W.button(L.ACT_SHARE, F) == nil)

-- right click: the menu has "Show" for Grimm, not for the attacker
UI.ShowEnemy(grimm); W.tick(); W.settle()
local menu = rawget(W.G, "DeathNoteMenu")
local function menuHas(label)
  if not (menu and menu:IsShown()) then return false end
  for _, b in ipairs(menu.items) do if b:IsShown() and b.text._text == label then return b end end
  return false
end
local poster
for _, f in ipairs(W.BM.frames) do if f.current and f.buttons and f.share then poster = f end end
check("Plakat gefunden", poster ~= nil)
poster._scripts.OnMouseUp(poster, "RightButton"); W.tick()
menu = rawget(W.G, "DeathNoteMenu")
check("Menue: Zeigen bei Grimm", menuHas(L.ACT_SHARE))
menu:Hide()
poster.current = S.Get(att)
poster._scripts.OnMouseUp(poster, "RightButton"); W.tick()
check("Menue: kein Zeigen bei nur Angriffen", not menuHas(L.ACT_SHARE))
menu:Hide()

------------------------------------------------------------------------
-- 2) the window: preview, channels, sending, wait, combat
------------------------------------------------------------------------
UI.ShowEnemy(grimm); W.tick(); W.settle()
W.click(W.button(L.ACT_SHARE, F)); W.tick()
local win = W.win()
check("Fenster offen", win and win:IsShown())
check("Vorschau = die Zeile", win and win.preview._text == Sh.LineFor(S.Get(grimm)), win and win.preview._text)
check("Vorschau ohne Notiz", win and not win.preview._text:find("GEHEIMNOTIZ", 1, true))
local function chans()
  local out = {}
  for _, b in ipairs(win.chans) do if b:IsShown() then out[#out + 1] = b.channel end end
  return table.concat(out, ",")
end
check("ohne Gilde und Gruppe: nur Sagen", chans() == "SAY", chans())
W.AM.units.player.guild = "Die Probe"; W.party = true
SU.Fill()
check("Gilde, Gruppe, Sagen", chans() == "GUILD,PARTY,SAY", chans())
W.raid = true; SU.Fill()
check("Schlachtzug statt Gruppe", chans() == "GUILD,RAID,SAY", chans())
W.click(W.button(L.SHARE_CH_GUILD, win)); W.tick()
check("eine Zeile in die Gilde", #W.sent == 1 and W.sent[1].ch == "GUILD" and W.sent[1].text == win.text)
check("Rueckmeldung gesendet", win.status._text == Fmt(L.SHARE_SENT, { channel = L.SHARE_CH_GUILD }), win.status._text)
W.click(W.button(L.SHARE_CH_SAY, win)); W.tick()
check("zweiter Klick: warten", #W.sent == 1 and win.status._text:find("10", 1, true) ~= nil, win.status._text)
W.AM.Advance(10); W.BM.Advance(10)
W.AM.inCombat = true
W.click(W.button(L.SHARE_CH_SAY, win)); W.tick()
check("im Kampf: nichts gesendet, Hinweis", #W.sent == 1 and win.status._text == L.SHARE_COMBAT, win.status._text)
W.AM.inCombat = false
W.AM.chatLockdown = true
W.click(W.button(L.SHARE_CH_SAY, win)); W.tick()
check("Sperre: nichts gesendet, Hinweis", #W.sent == 1 and win.status._text == L.SHARE_LOCKED, win.status._text)
W.AM.chatLockdown = false
W.click(W.button(L.SHARE_CH_SAY, win)); W.tick()
check("danach Sagen", #W.sent == 2 and W.sent[2].ch == "SAY")

-- the week
SU.SetMode("week")
check("Woche: Vorschau = Wochenzeile", win.preview._text == (Sh.WeekLine()), win.preview._text)
check("Woche: Grimm meistgesucht", win.preview._text:find("[Revenge Book: Grimm Bart]", 1, true) == 1)
-- Discord
SU.SetMode("discord")
check("Discord: Feld sichtbar, Kanaele weg", win.box:IsShown() and not win.chans[1]:IsShown())
check("Discord: Block = Share.Discord", win.edit._text == Sh.Discord(S.Get(grimm), "own"))
check("Discord: Name fett, ohne Notiz", win.edit._text:find("**Grimm Bart**", 1, true) == 1 and not win.edit._text:find("GEHEIMNOTIZ", 1, true))
check("Discord: Feld hat den Fokus (markiert zum Kopieren)", win.edit:HasFocus() == true)
win.edit._scripts.OnTextChanged(win.edit, true)
check("Discord: Tippen stellt den Block wieder her", win.edit._text == Sh.Discord(S.Get(grimm), "own"))
SU.SetMode("line")
W.click(W.button(L.SHARE_CLOSE, win)); W.tick()
check("Schliessen", not win:IsShown())

------------------------------------------------------------------------
-- 3) the click on a link: own poster, guest poster, copy to my book
------------------------------------------------------------------------
check("Klick ueber EventRegistry", W.clicks.SetItemRef ~= nil and Sh.clickVia == "EventRegistry")
local function linkOf(line, author)
  local out = Sh.Linkify(line, author or "Anna-Forever")
  return out and out:match("|H(addon:DeathNote:share:%d+)|h")
end
local link = linkOf("[Revenge Book: Grimm Bart] WANTED · Stand 3 : 1")
UI.SetFilter("journal"); W.tick()
W.clicks.SetItemRef[1](W.clicks.SetItemRef[2], link, "x", "LeftButton")
W.tick(); W.settle()
check("Klick auf eigenen: Plakat im Buch", poster.current and poster.current.key == grimm and poster:IsVisible())
link = linkOf("[Revenge Book: Fremd Ling] WANTED · Stand 1 : 4 · 99g Kopfgeld · zuletzt gesehen Ödland", "Bertram-Forever")
W.clicks.SetItemRef[1](W.clicks.SetItemRef[2], link, "x", "LeftButton"); W.tick()
local gp = W.guest()
check("Gast-Plakat offen", gp and gp:IsShown())
check("Gast-Plakat: von wem", gp and gp.by._text == Fmt(L.SHARE_GUEST_BY, { name = "Bertram" }), gp and gp.by._text)
check("Gast-Plakat: Name", gp and gp.name._text == "Fremd Ling")
-- 1.5.0 fixer: the head word (WANTED) stands in the head, no longer again as the first line
check("Gast-Plakat: Teile der Zeile", gp and gp.lines[2]._text == "99g Kopfgeld" and gp.lines[2]:IsShown())
check("Gast-Plakat: fuenfte Zeile leer", gp and not gp.lines[5]:IsShown())
W.click(gp.add); W.tick(); W.settle()
local fk = S.Find("Fremd Ling")
local fe = fk and S.Get(fk)
check("Ins eigene Buch: Eintrag da, als uebernommen markiert", fe and fe.fromGuild == true and fe.adoptFrom == "Bertram" and fe.adoptSrc == "text")
check("uebernommene Toetungen = seine aus der Zeile", fe and fe.fromGuildKills == 4)
check("Gast-Plakat zu, eigenes Plakat offen", not gp:IsShown() and poster.current and poster.current.key == fk)
check("uebernommen: kein Zeigen", not SU.Offer(fe, "own"))
-- a link that is not ours does nothing
check("fremder Linktyp", SU.OnLink("addon:Other:share:1") == false and SU.OnLink("item:123") == false)

------------------------------------------------------------------------
-- 4) the payback notice: button only with the switch; the next notice gets its line back
------------------------------------------------------------------------
local banner = rawget(W.G, "DeathNoteBanner")
S.AddRevenge(grimm, true); W.tick()
banner = rawget(W.G, "DeathNoteBanner")
check("Rache-Meldung da", banner and banner:IsShown())
check("Schalter aus: kein Knopf", not (banner.dnShare and banner.dnShare:IsShown()))
S.Setting("share.revengeButton", true)
W.settle()
S.AddRevenge(grimm, true); W.tick()
local rb = banner.dnShare
check("Schalter an: Knopf da", rb and rb:IsShown() and rb.text._text == L.ACT_SHARE)
local lineW = banner.line._w
check("Zeile rechts neben dem Knopf", lineW and lineW < 300, lineW)
local l1, _, r1 = W.BM.RectUI(rb)
local l2 = W.BM.RectUI(banner.line)
check("Knopf und Zeile ueberdecken sich nicht", r1 and l2 and r1 <= l2, tostring(r1) .. " / " .. tostring(l2))
local _, bb, _, bt = W.BM.RectUI(banner)
local _, kb, _, kt = W.BM.RectUI(rb)
check("Knopf in der Meldung", kb and bb and kb >= bb - 0.5 and kt <= bt + 0.5)
banner.anim:Play()
rb._scripts.OnEnter(rb); W.tick()
check("Maus auf dem Knopf haelt die Meldung", not banner.anim:IsPlaying())
rb._scripts.OnLeave(rb)
check("Maus weg: Meldung laeuft weiter", banner.anim:IsPlaying())
W.click(rb); W.tick()
win = W.win()
check("Knopf oeffnet das Fenster mit der Rache-Zeile", win:IsShown() and Sh.Parse(win.text).segs[1] == L.BANNER_REVENGE, win.text)
win:Hide()
-- another notice: the button goes, the line is whole again
W.settle()
local tod = W.kill("Neu", "Moerder")
ns:Fire("DEATH_RECORDED", { t = _G.time(), kind = "pvp", sure = true, killerKey = tod }, tod); W.tick()
check("naechste Meldung: kein Knopf", banner:IsShown() and not rb:IsShown())
check("naechste Meldung: Zeile wieder 300 breit, mittig", banner.line._w == 300 and banner.line._points[1][1] == "BOTTOM")
-- a pardoned one gets no button (not wanted)
W.settle()
S.SetStatus(grimm, "pardoned")
S.AddRevenge(grimm, true); W.tick()
check("Begnadigter: kein Knopf", not rb:IsShown())
S.SetStatus(grimm, "wanted")

------------------------------------------------------------------------
-- 5) guild book and hit list: the word, the line without names of guildmates
------------------------------------------------------------------------
do
  local P = ns.Guild.Proto
  local function whisper(text) W.AM.FireEvent("CHAT_MSG_ADDON", "DeathNote", text, "GUILD", "Liora-Forever") end
  W.AM.FireEvent("PLAYER_GUILD_UPDATE", "player"); W.tick(2)
  whisper(P.EncodeHello(0, "1.5.0"))
  whisper(P.EncodeKill({ key = "Torvik-Stahl", display = "Torvik Stahl", class = "WARRIOR", level = 40, zone = "Ödland",
    t = _G.time() - 60, victim = "Liora Lindwurm" }, "K"))
  W.tick(2); W.settle()
  local g = ns.Guild.Get("Torvik-Stahl", "all")
  check("Gildeneintrag da", g ~= nil)
  if g then
    check("Gildeneintrag: Zeigen angeboten", SU.Offer(g, "guild"))
    local line = Sh.GuildLine(g, "guild")
    check("Gildenzeile ohne Opfername", line and not line:find("Liora", 1, true), line)
    check("Gildenzeile: GILDENBUCH", line and line:find(L.POSTER_GUILDBOOK, 1, true))
    UI.SetFilter("guild"); W.tick()
    UI.SetGuildView("enemy"); W.tick()
    check("Klick oeffnet Gildenplakat", UI.ShowGuildEntry("Torvik-Stahl"))
    W.tick(); W.settle()
    check("Gildenplakat: Wort Zeigen", W.button(L.ACT_SHARE, F) ~= nil)
    link = linkOf("[Revenge Book: Torvik Stahl] WANTED")
    check("Link auf Gildeneintrag oeffnet ihn", SU.OpenRecord(Sh.links[tonumber(link:match("(%d+)$"))]) == "guild")
  end
end

------------------------------------------------------------------------
-- 6) the switch on the Guild sheet
------------------------------------------------------------------------
UI.OpenPanel("settings"); W.tick()
local cb
for _, f in ipairs(W.BM.frames) do
  if f._kind == "CheckButton" and f.label and f.label._text == L.OPT_SHARE_REVENGE then cb = f end
end
check("Schalter auf dem Blatt Gilde", cb ~= nil and cb.opt and cb.opt.path == "share.revengeButton")
check("Schalter steht an (gesetzt oben)", cb and cb:GetChecked())
check("keine Fehler", #W.AM.errors == 0 and #W.BM.violations == 0, W.AM.errors[1] or W.BM.violations[1])

------------------------------------------------------------------------
-- 7) 21 languages: word and strip side by side inside the poster, window texts inside the window, nothing cut
-- without a tooltip
------------------------------------------------------------------------
local CODES = { "enUS", "deDE", "frFR", "esES", "itIT", "ptBR", "ruRU", "koKR", "zhCN", "zhTW", "svSE", "nbNO", "daDK",
  "fiFI", "nlNL", "plPL", "csCZ", "huHU", "hrHR", "ukUA", "trTR" }
local function inside(a, b) return a[1] >= b[1] - 0.5 and a[3] <= b[3] + 0.5 and a[2] >= b[2] - 0.5 and a[4] <= b[4] + 0.5 end
local function rect(f) local l, b, r, t = W.BM.RectUI(f); return l and { l, b, r, t } or nil end
local function cutNoTip(fs)
  if not fs:IsVisible() or not fs.IsTruncated then return false end
  if not fs:IsTruncated() then return false end
  local o = fs.tipOwner or fs:GetParent()
  return not (o and (o.cutHooked or (o._scripts and o._scripts.OnEnter)))
end
for _, code in ipairs(CODES) do
  W = world(code)
  ns, L, S, Sh, SU, UI = W.ns, W.ns.L, W.ns.Store, W.ns.Share, W.ns.ShareUI, W.ns.UI
  local key = W.kill("Wunderkammerlein", "Langenamebauer")
  ns.Store.Get(key).lastSeen = { t = _G.time() - 60, zone = "Vorgebirge des Hügellands" }
  W.AM.units.player.guild = "Die Probe"; W.party = true
  UI.ShowEnemy(key); W.tick(); W.settle()
  F = rawget(W.G, "DeathNoteFrame")
  local P
  for _, f in ipairs(W.BM.frames) do if f.current and f.buttons and f.share then P = f end end
  local wr, dr, pr = rect(P.share), rect(P.doa), rect(P)
  local problems = {}
  if not (P.share:IsShown() and wr and dr) then problems[#problems + 1] = "word missing" end
  if wr and dr and wr[1] < dr[3] then problems[#problems + 1] = "word on the strip" end
  if wr and pr and not inside(wr, { pr[1] + 20, pr[2], pr[3] - 20, pr[4] }) then problems[#problems + 1] = "word outside" end
  if P.share.text:IsTruncated() then problems[#problems + 1] = "word cut" end
  if P.doa:IsTruncated() then problems[#problems + 1] = "strip cut: " .. tostring(P.doa._text) end
  W.click(W.button(L.ACT_SHARE, F)); W.tick()
  local win = W.win()
  local wrect = rect(win)
  for _, mode in ipairs({ "line", "week", "discord" }) do
    SU.SetMode(mode)
    for _, f in ipairs(W.BM.frames) do
      local o, under = f, false
      while o do if o == win then under = true end o = o._parent end
      if under and f:IsVisible() and (f._kind == "FontString" or f._kind == "Button") and f ~= win then
        local r = rect(f)
        if r and not inside(r, wrect) then problems[#problems + 1] = mode .. ": outside " .. tostring(f._text or (f.text and f.text._text)) end
        if f._kind == "FontString" and cutNoTip(f) then problems[#problems + 1] = mode .. ": cut " .. tostring(f._text) end
      end
    end
  end
  -- channels in one row, not on each other
  local rs = {}
  for _, b in ipairs(win.chans) do if b:IsShown() then rs[#rs + 1] = rect(b) end end
  for i = 2, #rs do if rs[i][1] < rs[i - 1][3] then problems[#problems + 1] = "channels overlap" end end
  -- guest poster
  local l2 = Sh.Linkify("[Revenge Book: Wunderkammerlein Langenamebauer-Zwei] WANTED · Stand 12 : 34 · 1.234g · " ..
    "zuletzt gesehen Vorgebirge des Hügellands", "Bertramwunderlich-Forever")
  SU.OnLink(l2:match("|H(addon:DeathNote:share:%d+)|h"))
  local gp = W.guest()
  local grect = rect(gp)
  for _, f in ipairs(W.BM.frames) do
    local o, under = f, false
    while o do if o == gp then under = true end o = o._parent end
    if under and f:IsVisible() and (f._kind == "FontString" or f._kind == "Button") and f ~= gp then
      local r = rect(f)
      if r and not inside(r, grect) then problems[#problems + 1] = "guest: outside " .. tostring(f._text or (f.text and f.text._text)) end
      if f._kind == "FontString" and cutNoTip(f) then problems[#problems + 1] = "guest: cut " .. tostring(f._text) end
    end
  end
  if #W.AM.errors > 0 or #W.BM.violations > 0 then problems[#problems + 1] = tostring(W.AM.errors[1] or W.BM.violations[1]) end
  check(code .. ": Wort, Fenster und Gast-Plakat", #problems == 0, table.concat(problems, "; "))
end

io.write(("share (Zeigen): %d green, %d red\n"):format(ok, bad))
os.exit(bad == 0 and 0 or 1)
