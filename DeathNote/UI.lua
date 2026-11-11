local ADDON, ns = ...

-- Das Notizbuch: schwarzer Ledereinband, links eine linierte Seite mit den handschriftlich
-- eingetragenen Namen, rechts das eingeklebte Fahndungsplakat des Gewaehlten.
-- Vier Reiter: Gesucht, Zu klaeren, Todesjournal, Gilde (1.2.0: Gilde & Freunde, mit Abschussliste);
-- dazu "?" (Gebrauchsanweisung) und das
-- Zahnrad (Hausordnung). Wird erst beim ersten TOGGLE_UI gebaut; die Zeilen kommen aus einem festen Pool.

local Look = ns.Look
-- Texte (1.2.0): L.KEY nur in Funktionen lesen, die nach ADDON_LOADED laufen; Fmt fuellt {platzhalter}
local L, Fmt = ns.L, ns.F
local UI = {}
ns.UI = UI
-- 1.2.0: selten gerufene Helfer und feste Tabellen ohne eigenen lokalen Namen (Luft bis zur Grenze von 200
-- lokalen Namen je Datei; tests/test_grenzen.lua wacht darueber)
local UX = {}

local W, H = 800, 548
local PAGE_W, PAGE_H = 380, 490
local ROWS, ROW_H, ROW_TOP = 9, 44, -42
local LINE_H = 22                 -- Linienabstand der linken Seite: Name auf der ersten, Untertext auf der zweiten
local DEATH_LINES = 6
local INFO_LINES = 4
local TONE = Look.TONE

UX.FILTERS = {
  { id = "wanted",  key = "TAB_WANTED" },
  { id = "open",    key = "TAB_UNSOLVED" },
  { id = "journal", key = "TAB_DEATHLOG" },
  { id = "guild",   key = "TAB_GUILD" },
}
UX.SORTS = { "rank", "recent", "name", "seen" }
UX.GSORTS = { "rank", "recent", "name" }
local SORT_LABEL = { rank = "SORT_RANK", recent = "SORT_RECENT", name = "SORT_NAME", seen = "SORT_SEEN" }   -- Schluessel
-- Leerzustaende: gross, klein, ganz klein (nur der erste Reiter erklaert, was das Buch tut)
-- je Zustand: Schluessel-Stamm und Zahl der Zeilen (STAMM_HEAD, _SUB, _HINT in der Sprachtabelle)
local EMPTY = {
  wanted = { "EMPTY_WANTED", 3 }, open = { "EMPTY_OPEN", 1 }, journal = { "EMPTY_JOURNAL", 2 },
  noguild = { "EMPTY_NOGUILD", 2 }, guildoff = { "EMPTY_GUILDOFF", 2 }, guildnil = { "EMPTY_GUILDNIL", 2 },
  guildquiet = { "EMPTY_GUILDQUIET", 2 },
  -- 1.2.0: Freunde, beide Quellen zusammen, Abschussliste
  friendsoff = { "EMPTY_FRIENDSOFF", 2 }, friendsnil = { "EMPTY_FRIENDSNIL", 2 }, friendsquiet = { "EMPTY_FRIENDSQUIET", 2 },
  nobody = { "EMPTY_NOBODY", 3 }, sharednil = { "EMPTY_SHAREDNIL", 2 }, sharedquiet = { "EMPTY_SHAREDQUIET", 2 },
  hunt = { "EMPTY_HUNT", 3 }, search = { "EMPTY_SEARCH", 2 }, searchro = { "EMPTY_SEARCHRO", 2 },
}
local EXPORT_WARN = 100 * 1024     -- ab hier wird "Buch sichern" in der EditBox zaeh
-- Gildenbuch: nur Eintraege, an denen ein Kollege (1.2.0: oder Freund) beteiligt ist; je Quelle
local FOREIGN = { all = { foreign = true, source = "all" }, guild = { foreign = true, source = "guild" },
                  friends = { foreign = true, source = "friends" } }
-- 1.2.0: Helfer fuer Gilde & Freunde und die Abschussliste in einer Tabelle (UI.lua ist an der Grenze
-- von 200 lokalen Namen je Datei)
local GF = { SOURCES = { { "all", "SRC_ALL" }, { "guild", "SRC_GUILD" }, { "friends", "SRC_FRIENDS" } },
             STAMP_W = 140, STAMP_H = 70, MENU_MAX = 6, CAND_MAX = 6, ASSIST_MAX = 4,
             WHY_ROW = 24 }   -- Grund in der Zeile der Abschussliste hoechstens so viele Zeichen (dann "…")

-- Gebrauchsanweisung ("?"): jeder Absatz beschreibt, was wirklich gebaut ist (Abnahmespiegel)
UX.HELP = {
  { "MANUAL_BOOK_HEAD", "MANUAL_BOOK" },
  { "MANUAL_WANTED_HEAD", "MANUAL_WANTED" },
  { "MANUAL_UNSOLVED_HEAD", "MANUAL_UNSOLVED" },
  { "MANUAL_ALERT_HEAD", "MANUAL_ALERT" },
  { "MANUAL_ADD_HEAD", "MANUAL_ADD" },
  { "MANUAL_GUILD_HEAD", "MANUAL_GUILD" },
  { "MANUAL_SHARE_HEAD", "MANUAL_SHARE" },
  { "MANUAL_QUIET_HEAD", "MANUAL_QUIET" },
}
-- UI.HELP: dieselben Absaetze als Texte der aktiven Sprache (gefuellt bei der Aktivierung)
UI.HELP = {}
if ns.Locale and ns.Locale.OnActivate then
  ns.Locale.OnActivate(function()
    for i, p in ipairs(UX.HELP) do UI.HELP[i] = { L[p[1]], L[p[2]] } end
  end)
end

local F            -- Hauptfenster
local LP, RP       -- linke und rechte Seite
local P            -- Plakat (auf der rechten Seite)
local rows = {}
local data = {}    -- aktuelle Liste (Feinde, Tode, offene Faelle oder Gildenfeinde), ggf. nach Suche gefiltert
local dataIdx      -- nur Journal mit Suche: Position in der ungefilterten Liste
-- Auswahl je Reiter: selected (Gesucht, Schluessel), osel (Zu klaeren: Journal-Eintrag oder Schluessel),
-- deathRef (Todesjournal: der Eintrag selbst), gselected/gmember (Gilde), hselected (Abschussliste)
-- gview: Gilde "enemy" (nach Taeter), "member" (nach Kollege) oder "hunt" (Abschussliste, 1.2.0)
-- gsource: Quelle im vierten Reiter "all" | "guild" | "friends" (1.2.0); viewPicked: Ansicht selbst gewaehlt
local state = { filter = "wanted", sort = "rank", gsort = "rank", offset = 0, selected = nil, osel = nil,
                gselected = nil, death = nil, deathRef = nil, panel = nil, query = "", spage = 1,
                gview = "enemy", gmember = nil, gsource = "all", hselected = nil, viewPicked = false,
                release = nil }
local dirty = true
local pending = false
local ready = false
local menu

local function Store() return ns.Store end
local function Set(path, v) if ns.Store and ns.Store.Setting then ns.Store.Setting(path, v) end end
local function C(t, a) return t[1], t[2], t[3], a or t[4] or 1 end
local GCall = Look.GCall
local function HasGuild() return Look.HasGuild() end
-- "Nach Kollege" gibt es nur, wenn die Logik ns.Guild.ByMember liefert
local function HasMemberView() return Look.HasGuild() and type(ns.Guild.ByMember) == "function" end
local function MemberView() return state.filter == "guild" and state.gview == "member" and HasMemberView() end
-- 1.2.0: Freundesbuch (Friends.lua) und Abschussliste (Guild.Hunts) gibt es nur mit der neuen Logik
function GF.HasFriends() return HasGuild() and type(ns.Friends) == "table" end
function GF.HasHunts() return HasGuild() and type(ns.Guild.Hunts) == "function" end
function GF.HuntView() return state.filter == "guild" and state.gview == "hunt" and GF.HasHunts() end
-- 1.2.0: die Quellenwahl gibt es nur, wenn es beide Quellen wirklich gibt (GF.Survey); sonst gilt "Alle"
function GF.Src() return GF.HasFriends() and (GF.both == false and "all" or state.gsource) or "guild" end
function GF.FriendsOn()
  if not GF.HasFriends() or type(ns.Friends.Enabled) ~= "function" then return false end
  local ok, v = pcall(ns.Friends.Enabled)
  return ok and v == true
end
-- teilt die gewaehlte Quelle gerade etwas? (Gilde: in einer Gilde; Freunde: Teilen mit Freunden an)
function GF.SrcOn(src)
  src = src or GF.Src()
  local g = GCall("Name") ~= nil
  if src == "guild" then return g end
  if src == "friends" then return GF.FriendsOn() end
  return g or GF.FriendsOn()
end
local AnyCollapsed, SetAllMembers -- vorwaerts (Gilde nach Kollege)

------------------------------------------------------------------------
-- Bausteine
------------------------------------------------------------------------
local function Rule(parent, y, x1, x2, alpha)
  local t = parent:CreateTexture(nil, "ARTWORK")
  t:SetColorTexture(C(Look.INK, alpha or 0.55))
  t:SetHeight(1)
  t:SetPoint("TOPLEFT", x1 or 24, y)
  t:SetPoint("TOPRIGHT", -(x2 or x1 or 24), y)
  return t
end

-- gesperrtes Etikett: "T A T E N"
local function Spaced(s)
  local out = {}
  for ch in tostring(s):gmatch("[%z\1-\127\194-\244][\128-\191]*") do out[#out + 1] = ch == " " and "  " or ch end
  return table.concat(out, " ")
end

-- Etikett auf Papier (10 pt, gesperrt); red = rot (kleine rote Schrift)
local function Label(parent, text, red)
  local fs = Look.Text(parent, "body", 10, red and Look.RED_INK or Look.INK)
  if not red then fs:SetTextColor(C(Look.INK, TONE.label)) end
  fs:SetText(Spaced(text))
  return fs
end

-- Knopf: schwarz, knochenweisse Schrift, blutrote Kante; Text bleibt im Knopf
local function InkButton(parent, text, w, h, onClick)
  local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
  w, h = w or 104, h or 22
  b:SetSize(w, h)
  b:SetBackdrop({ bgFile = Look.TEX.white, edgeFile = Look.TEX.white, edgeSize = 1 })
  b:SetBackdropColor(0.07, 0.06, 0.06, 0.94)
  b:SetBackdropBorderColor(0.45, 0.04, 0.04, 1)
  b.text = Look.Text(b, "body", 10, Look.BONE)
  b.text:SetPoint("CENTER", 0, 0)
  b.text:SetWidth(w - 8)
  b.text:SetWordWrap(false)
  -- 1.2.0: a label too long for the button in another language gets 9 pt instead of being cut
  function b:SetLabel(t)
    local fs = self.text
    if fs.small then Look.Font(fs, "body", 10); fs.small = nil end
    fs:SetText(t or "")
    local ok, tw = pcall(fs.GetStringWidth, fs)
    if ok and type(tw) == "number" and not Look.Secret(tw) and tw > self:GetWidth() - 8 then
      Look.Font(fs, "body", 9); fs.small = true; fs:SetText(t or "")
    end
  end
  b:SetLabel(text)
  b:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(0.95, 0.1, 0.08, 1) end)
  b:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(0.45, 0.04, 0.04, 1) end)
  b:SetScript("OnClick", function(self, mouse)
    Look.Sound("click")
    if self.fn then self.fn(self, mouse) end
  end)
  b.fn = onClick
  return b
end

-- Wort-Knopf auf Papier (Handschrift oder Akte): Hover faerbt rot, sonst nichts bewegt sich
local function WordButton(parent, text, kind, size, tone)
  local b = CreateFrame("Button", nil, parent)
  b.text = Look.Text(b, kind or "hand", size or 13, Look.INK)
  b.text:SetPoint("LEFT", 0, 0)
  b.text:SetJustifyH("LEFT")
  b.text:SetWordWrap(false)
  b.tone = tone or TONE.sub
  b.text:SetTextColor(C(Look.INK, b.tone))
  b.text:SetText(text or "")
  b:SetSize(80, (size or 13) + 6)
  b:SetScript("OnEnter", function(self) self.text:SetTextColor(C(Look.RED)) end)
  b:SetScript("OnLeave", function(self) self.text:SetTextColor(C(Look.INK, self.tone)) end)
  return b
end

-- Wort-Reiter (Blaetter der Hausordnung, Kanal, Ansicht der Gilde): aktives Wort volle Tinte mit roter
-- Unterkante, die anderen blasser. Ein Baustein fuer alle Wort-Umschalter.
local function WordTab(parent, text, w, onClick)
  local t = CreateFrame("Button", nil, parent)
  t:SetSize(w or 90, 20)
  t.text = Look.Text(t, "body", 11, Look.INK)
  t.text:SetPoint("LEFT", 2, 0)
  t.text:SetText(text)
  t.mark = t:CreateTexture(nil, "ARTWORK")
  t.mark:SetColorTexture(C(Look.RED, 1))
  t.mark:SetHeight(2)
  t.mark:SetPoint("BOTTOMLEFT", 0, 0)
  t.mark:SetPoint("BOTTOMRIGHT", 0, 0)
  local hl = t:CreateTexture(nil, "HIGHLIGHT")
  hl:SetAllPoints()
  hl:SetColorTexture(C(Look.INK, 0.06))
  t:SetScript("OnClick", function(self) Look.Sound("click"); if onClick then onClick(self) end end)
  function t:SetOn(on, off)
    self.mark:SetShown(on and true or false)
    self.text:SetTextColor(C(Look.INK, off and TONE.off or (on and TONE.ink or TONE.sub)))
  end
  return t
end

-- Kaestchen mit Tintenrand, gesetzt = handgezeichnetes Kreuz; die Beschriftung ist Teil der Klickflaeche
function UX.InkCheck(parent, label, width)
  local cb = CreateFrame("CheckButton", nil, parent)
  cb:SetSize(width or 300, 20)
  local box = cb:CreateTexture(nil, "ARTWORK")
  box:SetSize(16, 16)
  box:SetPoint("LEFT", 2, 0)
  box:SetColorTexture(C(Look.INK, 0.7))
  local inner = cb:CreateTexture(nil, "ARTWORK", nil, 1)
  inner:SetPoint("TOPLEFT", box, "TOPLEFT", 1, -1)
  inner:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", -1, 1)
  Look.Tex(inner, Look.TEX.white, 0.93, 0.90, 0.82, 1)
  inner:SetVertexColor(0.93, 0.90, 0.82, 1)
  cb.cross = cb:CreateTexture(nil, "OVERLAY")
  cb.cross:SetSize(20, 20)
  cb.cross:SetPoint("CENTER", box, "CENTER", 1, 1)
  Look.Tex(cb.cross, Look.TEX.check, 0.1, 0.1, 0.1, 1)
  cb.cross:SetVertexColor(C(Look.INK, 0.95))
  cb.cross:Hide()
  local hl = cb:CreateTexture(nil, "HIGHLIGHT")
  hl:SetAllPoints()
  hl:SetColorTexture(C(Look.INK, 0.05))
  cb.label = Look.Text(cb, "body", 11, Look.INK)
  cb.label:SetPoint("LEFT", box, "RIGHT", 8, 0)
  cb.label:SetText(label or "")
  function cb:SetInk(v)
    self:SetChecked(v and true or false)
    self.cross:SetShown(v and true or false)
  end
  return cb
end

local function Tex(frame, layer, path, sub)
  local t = frame:CreateTexture(nil, layer or "BACKGROUND", nil, sub)
  Look.Tex(t, path, 0.85, 0.80, 0.70, 1)
  return t
end

function UX.Shadow(frame, dx, dy, a)
  local s = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
  s:SetColorTexture(0, 0, 0, a or 0.45)
  s:SetPoint("TOPLEFT", dx or 3, -(dy or 3))
  s:SetPoint("BOTTOMRIGHT", dx or 3, -(dy or 3))
  return s
end

-- Klebestreifen schraeg ueber eine Ecke
local function Tape(frame, corner, rot, dx)
  local t = frame:CreateTexture(nil, "OVERLAY", nil, 6)
  t:SetSize(52, 20)
  t:SetPoint("CENTER", frame, corner, dx or 0, 0)
  Look.Tex(t, Look.TEX.tape, 0.9, 0.86, 0.7, 0.6)
  t:SetRotation(rot)
  return t
end

-- kleines Tinten-Dreieck (tri.tga zeigt nach rechts; rot = Drehung im Bogenmass)
local function Tri(parent, size, rot)
  local t = parent:CreateTexture(nil, "ARTWORK")
  t:SetSize(size, size)
  Look.Tex(t, Look.TEX.tri, 0.1, 0.1, 0.1, 1)
  t:SetVertexColor(C(Look.INK, 0.9))
  if rot and rot ~= 0 then t:SetRotation(rot) end
  return t
end

-- Fahndungsfoto ohne Farbfleck: entsaettigt und papierfarben getoent
local function MugIcon(tex)
  tex:SetDesaturated(true)
  tex:SetVertexColor(0.85, 0.80, 0.70, 1)
end

local function PlaceText(z, sz)
  if sz and sz ~= "" and z and z ~= "" and sz ~= z then return z .. ", " .. sz end
  return Look.Place(z, sz)
end

local function NameOfKey(key, fallback)
  local e = key and Store().Get(key)
  if e then return Look.Name(e), e end
  return fallback or key or "?"
end

-- Breite einer Schrift (Secret-Schutz, Rueckfall auf eine Schaetzung)
local function TextWidth(fs, guess)
  local w = fs.GetStringWidth and fs:GetStringWidth()
  if type(w) ~= "number" or Look.Secret(w) then return guess or 140 end
  return w
end

-- Breite fuer Unter-/Durchstreichen nach der Textlaenge
local function InkWidth(fs)
  return math.max(40, math.min(300, TextWidth(fs, 140) + 10))
end

-- "2875" -> "2.875"
function UX.Thousands(n)
  local s = tostring(math.floor(n))
  local sep = L.THOUSANDS_SEP
  local out = s:reverse():gsub("(%d%d%d)", "%1" .. sep:reverse():gsub("%%", "%%%%")):reverse()
  if out:sub(1, #sep) == sep then out = out:sub(#sep + 1) end
  return out
end

-- Kopfgeld auf ganze Goldstuecke: "328 GOLD", unter 1 Gold "50 SILBER"
local function GoldText(copper)
  copper = tonumber(copper) or 0
  local g = math.floor(copper / 10000)
  if g >= 1 then return Fmt(L.BOUNTY_GOLD, { count = UX.Thousands(g) }) end
  local s = math.floor(copper / 100)
  if s >= 1 then return Fmt(L.BOUNTY_SILVER, { count = s }) end
  return Fmt(L.BOUNTY_GOLD, { count = 0 })
end

-- FontString wirklich abgeschnitten? (mit Secret-Schutz, wie in Details)
local function Truncated(fs)
  if not fs.IsTruncated then return false end
  local ok, v = pcall(fs.IsTruncated, fs)
  if not ok or Look.Secret(v) then return false end
  return v and true or false
end

local function Tip(owner, lines, anchor)
  if type(lines) ~= "table" or not lines[1] then return end
  GameTooltip:SetOwner(owner, anchor or "ANCHOR_RIGHT")
  GameTooltip:SetText(lines[1], Look.BONE[1], Look.BONE[2], Look.BONE[3])
  for i = 2, #lines do GameTooltip:AddLine(lines[i], 0.82, 0.80, 0.75, true) end
  GameTooltip:Show()
end

-- Name in eine offene Chat-Eingabe einfuegen (nur wenn der Nutzer selbst eine offen hat; nie senden)
function UX.InsertIntoChat(text)
  if type(text) ~= "string" or text == "" then return false end
  local util = ChatFrameUtil
  local active = (util and util.GetActiveWindow) or ChatEdit_GetActiveWindow
  local insert = (util and util.InsertLink) or ChatEdit_InsertLink
  if type(active) ~= "function" or type(insert) ~= "function" then return false end
  local ok, win = pcall(active)
  if not ok or not win then return false end
  pcall(insert, text)
  return true
end

function UX.Shift()
  if not IsShiftKeyDown then return false end
  local ok, v = pcall(IsShiftKeyDown)
  return ok and not Look.Secret(v) and v and true or false
end

-- Rueckfrage: ein Muster fuer alles Zerstoerende (StaticPopup)
UX.CONFIRM = {
  DEATHNOTE_DELETE = { "CONFIRM_DELETE", "CONFIRM_DELETE_OK",
                       function(_, key) if key then Store().Remove(key) end end },
  DEATHNOTE_GUILD_CLEAR = { "CONFIRM_GUILD_CLEAR", "CONFIRM_GUILD_CLEAR_OK",
                            function() GCall("Clear"); UI.Refresh() end },
  -- 1.2.0: Freundesbuch leeren (mit seiner Abschussliste), alle eigenen Freigaben abblasen
  DEATHNOTE_FRIENDS_CLEAR = { "CONFIRM_FRIENDS_CLEAR", "CONFIRM_GUILD_CLEAR_OK",
                              function() if ns.Friends and ns.Friends.Clear then ns.Friends.Clear() end UI.Refresh() end },
  DEATHNOTE_CALLOFF_ALL = { "CONFIRM_CALLOFF_ALL", "CONFIRM_CALLOFF_ALL_OK",
                            function() GCall("CallOffAll"); UI.Refresh() end },
  -- 1.2.0: Freund ohne Nachnamen auf der Liste: Bindung an den vollen Namen loesen (seine Daten gehen mit)
  DEATHNOTE_TIE_LOOSE = { "CONFIRM_TIE_LOOSE", "ACT_TIE_LOOSE",
                          function(_, list) if ns.Friends and ns.Friends.Unbind then ns.Friends.Unbind(list) end UI.Refresh() end },
}
function UX.RegisterConfirms()
  for which, c in pairs(UX.CONFIRM) do
    StaticPopupDialogs[which] = {
      -- StaticPopup setzt den Namen ueber %s ein: {name} wird dazu, jedes andere % verdoppelt
      text = Fmt((L[c[1]]:gsub("%%", "%%%%")), { name = "%s" }), button1 = L[c[2]], button2 = L.CONFIRM_CANCEL,
      OnAccept = c[3],
      timeout = 0, whileDead = true, hideOnEscape = true,
    }
  end
end
local function Confirm(which, text, data) StaticPopup_Show(which, text, nil, data) end

------------------------------------------------------------------------
-- Daten der Reiter
------------------------------------------------------------------------
local function IsCase(item) return type(item) == "table" and item.status == nil and item.kind ~= nil end

-- offene Faelle: Store.OpenCases (Logik), sonst selbst aus dem Journal
local fallbackCases = {}
local function OpenCases()
  local S = Store()
  if S.OpenCases then
    local ok, n, list = pcall(S.OpenCases)
    if ok and type(list) == "table" then return list, tonumber(n) or #list end
  end
  for i = #fallbackCases, 1, -1 do fallbackCases[i] = nil end
  for _, d in ipairs(S.Deaths() or {}) do
    if type(d) == "table" and d.kind == "pvp" and d.killerKey == nil and d.counted ~= false
       and type(d.candidates) == "table" and #d.candidates > 0 then
      fallbackCases[#fallbackCases + 1] = d
    end
  end
  return fallbackCases, #fallbackCases
end

-- Zeitpunkt eines Eintrags in "Zu klaeren": Fall = Todeszeit, Verdacht = letzte Tat
local function OpenTime(item)
  if IsCase(item) then return tonumber(item.t) or 0 end
  local d = Look.LastDeed(item)
  return d and tonumber(d.t) or 0
end
local function OpenLess(a, b)
  local ta, tb = OpenTime(a), OpenTime(b)
  if ta ~= tb then return ta > tb end
  return tostring(a.key or a.t) < tostring(b.key or b.t)
end

-- Zu klaeren: offene Faelle und echte Verdachtsfaelle, neueste zuerst (wiederverwendete Tabelle)
local openData = {}
function UX.OpenData()
  for i = #openData, 1, -1 do openData[i] = nil end
  local cases = OpenCases()
  for i = 1, #cases do openData[#openData + 1] = cases[i] end
  local sus = Store().Ranked("suspect", "recent") or {}
  for i = 1, #sus do openData[#openData + 1] = sus[i] end
  table.sort(openData, OpenLess)
  return openData
end

-- wanted, suspect, pardoned, open
local function Counts()
  local S = Store()
  local w, s, p, o = S.Count()
  if type(o) ~= "number" then local _, n = OpenCases(); o = n end
  return w or 0, s or 0, p or 0, o or 0
end

-- Gesucht: Gesuchte, dahinter die Begnadigten (abschaltbar ueber das Sortiermenue)
local wantedData = {}
local function ShowPardoned() return Look.Setting("ui.showPardoned", true) ~= false end
function UX.WantedData()
  local S = Store()
  local list = S.Ranked("wanted", state.sort) or {}
  for i = #wantedData, 1, -1 do wantedData[i] = nil end
  for i = 1, #list do wantedData[i] = list[i] end
  local pard = S.Ranked("pardoned", state.sort) or {}
  local all = ShowPardoned()
  for i = 1, #pard do
    if all or pard[i].key == state.selected then wantedData[#wantedData + 1] = pard[i] end
  end
  return wantedData
end

-- Gildenbuch nach Taeter: nur Eintraege mit Kollegen, reine Hand-Eintraege ans Ende.
-- Neu sortiert/gefiltert nur, wenn die Liste der Logik wechselt.
local gpart = { src = nil, n = -1, out = {}, res = nil }
local function GuildEnemies(sort)
  local src = GF.Src()
  local list = GF.SrcOn(src) and GCall("List", sort, FOREIGN[src]) or nil
  if type(list) ~= "table" then return {} end
  if gpart.src == list and gpart.n == #list then return gpart.res end
  gpart.src, gpart.n = list, #list
  -- liefert die Logik den vierten Zaehler (fremde), filtert sie selbst; sonst hier filtern
  local _, _, _, foreign = GCall("Count", src)
  local trusted = type(foreign) == "number"
  local need, seen = false, false
  for i = 1, #list do
    local g = list[i]
    if not trusted and not Look.Foreign(g) then need = true; break end
    if Look.ListedOnly(g) then seen = true elseif seen then need = true; break end
  end
  if not need then gpart.res = list; return list end
  local out = gpart.out
  for i = #out, 1, -1 do out[i] = nil end
  for i = 1, #list do if (trusted or Look.Foreign(list[i])) and not Look.ListedOnly(list[i]) then out[#out + 1] = list[i] end end
  for i = 1, #list do if (trusted or Look.Foreign(list[i])) and Look.ListedOnly(list[i]) then out[#out + 1] = list[i] end end
  gpart.res = out
  return out
end

function UX.GuildCount()
  local src = GF.Src()
  if src ~= "guild" and not GF.SrcOn(src) then return 0 end
  local enemies, _, _, foreign = GCall("Count", src)
  if type(foreign) == "number" then return foreign end
  if not GCall("Name") then return 0 end
  return #GuildEnemies("rank")
end

-- Kollegen (1.2.0: und Freunde) mit DeathNote, je nach Quelle
local function MemberCount()
  local src = GF.Src()
  local n = 0
  if src ~= "friends" then
    local m = GCall("Members")
    n = n + (type(m) == "table" and #m or 0)
  end
  if src ~= "guild" and GF.HasFriends() then
    local m = GCall("Members", "friends")
    n = n + (type(m) == "table" and #m or 0)
  end
  return n
end

-- Abschussliste der gewaehlten Quelle (Zeilen der Logik, nicht veraendern)
-- 1.2.0: was der vierte Reiter zeigen soll, einmal je Neuaufbau: beide Quellen (Gilde und ein Freund mit
-- DeathNote), niemand zum Teilen (keine Gilde, kein Freund auf der Liste), Abschussliste sinnvoll (es gibt
-- Freigaben, oder man legt gerade eine an)
function GF.Survey()
  local g = GCall("Name") ~= nil and GCall("Enabled") ~= false
  local fOn = GF.FriendsOn()
  local fm = fOn and GCall("Members", "friends")
  local fN = type(fm) == "table" and #fm or 0
  local total = 0
  if fOn and type(ns.Friends.OnlineCount) == "function" then
    local ok, _, t = pcall(ns.Friends.OnlineCount)
    total = ok and tonumber(t) or 0
  end
  GF.both = GF.HasFriends() and GCall("Name") ~= nil and fN > 0
  -- "niemand" nur ohne Ziele auf der Abschussliste: Freigaben (auch eigene) halten Ansichten, Statuszeile und
  -- Abgleichen erreichbar, auch mit beiden Teilen-Schaltern aus (Alarm und Anzeige folgen demselben Zustand)
  local hunts = (tonumber((GCall("HuntCount", "all"))) or 0) > 0 or (tonumber((GCall("OwnReleaseCount"))) or 0) > 0
  GF.nobody = not g and (not fOn or (total == 0 and fN == 0)) and not hunts
  GF.hunts = GF.HasHunts() and ((tonumber(GCall("HuntCount", "all")) or 0) > 0 or state.panel == "release")
  if state.gview == "hunt" and not GF.hunts then state.gview = "enemy" end
end

function GF.Hunts()
  if not GF.HasHunts() then return {} end
  local rows = GCall("Hunts", GF.Src())
  return type(rows) == "table" and rows or {}
end

------------------------------------------------------------------------
-- Aktionen je Eintrag (Plakat-Knoepfe und Rechtsklick-Menue)
------------------------------------------------------------------------
-- Plakat: zwei Knoepfe; Streichen steht nur im Menue und als kleines Wort unten am Plakat
local function EnemySpec(e)
  local key = e.key
  local S = Store()
  if e.status == "suspect" then
    return {
      { L.ACT_CONFIRM, function() S.ConfirmSuspect(key) end },
      { L.ACT_DISMISS, function() S.DismissSuspect(key) end },
    }
  elseif e.status == "pardoned" then
    return {
      { L.ACT_HUNT_AGAIN, function() S.SetStatus(key, "wanted") end },
      { L.ACT_REVENGE, function() S.AddRevenge(key) end },
    }
  end
  return {
    { L.ACT_REVENGE, function() S.AddRevenge(key) end },
    { L.ACT_PARDON, function() S.SetStatus(key, "pardoned") end },
  }
end

local function MenuSpec(e)
  local spec = EnemySpec(e)
  local out = { spec[1], spec[2], { L.ACT_STRIKE, function() UI.ConfirmDelete(e.key) end } }
  return out
end

-- Gilde: nichts Zerstoerendes, nur uebernehmen bzw. das eigene Plakat aufschlagen
local function GuildSpec(g)
  local key = g.key
  if Store().Get(key) then
    return { { L.ACT_OPEN_OWN, function() UI.ShowEnemy(key) end } }
  end
  return { { L.ACT_ADOPT, function()
    local k = GCall("Adopt", key)
    UI.Refresh()
    if type(k) == "string" and Store().Get(k) then UI.ShowEnemy(k) end
  end } }
end

-- Abschussliste (1.2.0): eigene Freigabe zuruecknehmen oder freigeben ("Zur Jagd freigeben" oeffnet
-- das Blatt mit Ziel und Grund); "abblasen" nimmt nur die eigene Freigabe zurueck.
function GF.Released(key)
  local g, f = GCall("Released", key)
  return (g or f) and true or false
end
function GF.HuntAction(key)
  if GF.Released(key) then
    return { L.ACT_CALLOFF, function() GCall("CallOff", key); UI.Refresh() end }
  end
  return { L.ACT_RELEASE, function() UI.OpenRelease(key) end }
end
function GF.MenuWithHunt(spec, key)
  if not GF.HasHunts() or type(key) ~= "string" then return spec end
  local out = {}
  for i = 1, #spec do out[i] = spec[i] end
  out[#out + 1] = GF.HuntAction(key)
  return out
end

------------------------------------------------------------------------
-- Menue (Rechtsklick und Sortierung): eine Spalte schwarzer Knoepfe an der Maus
------------------------------------------------------------------------
local function HideMenu() if menu then menu:Hide(); menu.blocker:Hide() end end

function UX.BuildMenu()
  menu = CreateFrame("Frame", "DeathNoteMenu", F, "BackdropTemplate")
  menu:SetFrameStrata("DIALOG")
  menu:SetBackdrop({ bgFile = Look.TEX.white, edgeFile = Look.TEX.white, edgeSize = 1 })
  menu:SetBackdropColor(0.05, 0.045, 0.045, 0.97)
  menu:SetBackdropBorderColor(0.45, 0.04, 0.04, 1)
  menu:Hide()
  -- Klick irgendwo sonst ins Buch schliesst das Menue
  local bl = CreateFrame("Button", nil, F)
  bl:SetAllPoints(F)
  bl:SetFrameStrata("DIALOG")
  bl:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  bl:SetScript("OnClick", HideMenu)
  bl:Hide()
  menu.blocker = bl
  menu.items = {}
  for i = 1, GF.MENU_MAX do
    local b = InkButton(menu, "", 148, 20)
    b:SetPoint("TOPLEFT", 4, -4 - (i - 1) * 22)
    menu.items[i] = b
  end
  menu:SetScript("OnShow", function(self) self:Raise() end)
end

local function OpenMenu(spec, fallbackAnchor)
  if not menu then UX.BuildMenu() end
  local n = math.min(#spec, GF.MENU_MAX)
  for i = 1, GF.MENU_MAX do
    local b, s = menu.items[i], spec[i]
    if s and i <= n then
      local fn = s[2]
      b:SetLabel(s[1]); b.fn = function() HideMenu(); fn() end; b:Show()
    else
      b:Hide()
    end
  end
  menu:SetSize(156, 8 + n * 22 - 2)
  menu:ClearAllPoints()
  local s = menu:GetEffectiveScale()
  local x, y = GetCursorPosition()
  if type(x) == "number" and type(y) == "number" and type(s) == "number" and s > 0
     and not Look.Secret(x) and not Look.Secret(y) and not Look.Secret(s) then
    menu:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x / s + 2, y / s - 2)
  else
    menu:SetPoint("TOPLEFT", fallbackAnchor, "RIGHT", -40, 0)
  end
  menu.blocker:Show()
  menu:Show()
end

-- 1.2.0: Kopfzeile eines Freundes ohne Nachnamen auf der Liste (Nach Kollege): wer ist es, Bindung loesen
function GF.TieMenu(row)
  local t = row.item.m and row.item.m.tie
  if type(t) ~= "table" or not ns.Friends then return false end
  local spec = {}
  if t.conflict then
    for _, n in ipairs({ t.full, t.rival }) do
      spec[#spec + 1] = { Fmt(L.ACT_TIE_MINE, { name = n }), function() ns.Friends.Choose(t.list, n); UI.Refresh() end }
    end
  end
  spec[#spec + 1] = { L.ACT_TIE_LOOSE, function() Confirm("DEATHNOTE_TIE_LOOSE", t.full, t.list) end }
  OpenMenu(spec, row)
  return true
end

------------------------------------------------------------------------
-- Zeilen der linken Seite
------------------------------------------------------------------------
local Refresh, BindRows, ShowRight -- vorwaerts
local ClassName -- vorwaerts (Klassenname im Wortlaut des Buchs)
local ToggleMember -- vorwaerts

-- Gildeneintrag hinter einer Zeile (Kindzeile nach Kollege oder Zeile nach Taeter)
local function GuildItem(item)
  if item.wrap then
    if item.head then return nil end
    return item.r.entry or GCall("Get", item.r.key)
  end
  return item
end

local function SelectRow(row)
  if not row.item then return end
  if row.item.wrap then
    if row.item.head then return end               -- Kopfzeile ist kein Taeter
    state.gselected, state.gmember = row.item.r.key, row.item.m.name
  elseif state.filter == "journal" then
    state.death, state.deathRef = row.index, row.item
  elseif state.filter == "open" then
    state.osel = IsCase(row.item) and row.item or row.item.key
  elseif state.filter == "guild" then
    if GF.HuntView() then state.hselected = row.item.key else state.gselected = row.item.key end
  else
    state.selected = row.item.key
  end
  if state.panel then UI.ClosePanel(true) end
  BindRows()
  ShowRight()
end

function UX.RowMenu(row)
  local item = row.item
  if not item or state.filter == "journal" or IsCase(item) then return end
  if item.wrap then
    item = GuildItem(item)
    if not item then return end
  end
  local spec
  if GF.HuntView() then
    spec = GF.HuntSpec(item)
    -- alle eigenen Freigaben abblasen (mit Rueckfrage). 1.2.0: im Zeilenmenue einer eigenen Freigabe,
    -- wenn es mehr als eine gibt (der Sortierknopf, an dem es hing, ist in der Abschussliste nicht zu sehen)
    if GF.Released(item.key) and (tonumber(GCall("OwnReleaseCount")) or 0) > 1 then
      spec[#spec + 1] = { L.ACT_CALLOFF_ALL, function() Confirm("DEATHNOTE_CALLOFF_ALL") end }
    end
  elseif state.filter == "guild" then spec = GF.MenuWithHunt(GuildSpec(item), item.key)
  elseif item.status == "wanted" then spec = GF.MenuWithHunt(MenuSpec(item), item.key)
  else spec = MenuSpec(item) end
  OpenMenu(spec, row)
end

local function RowClick(row, mouse)
  if not row.item then return end
  if row.item.wrap and row.item.head then
    if mouse == "RightButton" and GF.TieMenu(row) then return end
    ToggleMember(row.item.m)
    return
  end
  if mouse == "RightButton" then
    SelectRow(row)
    UX.RowMenu(row)
    return
  end
  if UX.Shift() and state.filter ~= "journal" and not IsCase(row.item)
     and UX.InsertIntoChat(Look.TargetName(GuildItem(row.item) or row.item)) then return end
  SelectRow(row)
end

local function RowEnter(row)
  if not row.item then return end
  if row.tipFn then
    Tip(row, row.tipFn(row.item))
  elseif row.full then
    Tip(row, type(row.full) == "table" and row.full or { row.full })
  elseif Truncated(row.name) then
    Tip(row, { row.name:GetText() or "" })
  end
end

function UX.MakeRow(parent, i)
  local r = CreateFrame("Button", nil, parent)
  r:SetSize(PAGE_W - 24, ROW_H - 2)
  r:SetPoint("TOPLEFT", 4, ROW_TOP - (i - 1) * ROW_H)
  r:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  local hl = r:CreateTexture(nil, "HIGHLIGHT")
  hl:SetAllPoints()
  hl:SetColorTexture(C(Look.INK, 0.06))

  -- Rang und Name stehen auf der ersten Linie, der Untertext auf der zweiten
  r.rank = Look.Text(r, "hand", 19, Look.INK)
  r.rank:SetPoint("TOPRIGHT", r, "TOPLEFT", 32, -1)
  r.rank:SetJustifyH("RIGHT")
  r.skull = r:CreateTexture(nil, "ARTWORK")
  r.skull:SetSize(18, 18)
  r.skull:SetPoint("TOPLEFT", 12, -2)
  Look.Tex(r.skull, Look.TEX.skull, 0.2, 0.2, 0.2, 1)
  r.skull:SetVertexColor(0.25, 0.22, 0.2, 1)
  r.skull:Hide()

  r.name = Look.Text(r, "hand", 19, Look.INK)
  r.name:SetPoint("TOPLEFT", 40, -1)
  r.name:SetPoint("RIGHT", -40, 0)
  r.name:SetJustifyH("LEFT")
  r.name:SetWordWrap(false)

  r.subX, r.subInset = 42, 12
  r.sub = Look.Text(r, "body", 10, Look.INK)
  r.sub:SetPoint("BOTTOMLEFT", 42, -1)
  r.sub:SetPoint("RIGHT", -12, 0)
  r.sub:SetJustifyH("LEFT")
  r.sub:SetWordWrap(false)

  r.mark = Look.Text(r, "body", 10, Look.RED_INK)
  r.mark:SetPoint("BOTTOMRIGHT", -6, -1)

  r.icon = r:CreateTexture(nil, "ARTWORK")
  r.icon:SetSize(16, 16)
  r.icon:SetPoint("TOPRIGHT", -8, -3)
  MugIcon(r.icon)

  -- Unterstrichen = gewaehlt, durchgestrichen = begnadigt
  r.under = r:CreateTexture(nil, "OVERLAY")
  r.under:SetHeight(8)
  r.under:SetPoint("TOPLEFT", r.name, "BOTTOMLEFT", -4, 4)
  Look.Tex(r.under, Look.TEX.ink, 0.1, 0.1, 0.1, 1)
  r.under:SetVertexColor(C(Look.INK, 0.95))
  r.under:Hide()
  r.strike = r:CreateTexture(nil, "OVERLAY", nil, 1)
  r.strike:SetHeight(9)
  r.strike:SetPoint("LEFT", r.name, "LEFT", -3, -1)
  Look.Tex(r.strike, Look.TEX.ink, 0.1, 0.1, 0.1, 1)
  r.strike:SetVertexColor(C(Look.INK, 0.8))
  r.strike:SetTexCoord(1, 0, 0, 1)
  r.strike:Hide()

  -- Gilde nach Kollege: Kopfzeile mit Dreieck, blassem Band und Zaehler rechts oben
  r.band = r:CreateTexture(nil, "BACKGROUND")
  r.band:SetPoint("TOPLEFT", 0, 1); r.band:SetPoint("BOTTOMRIGHT", 0, -1)
  r.band:SetColorTexture(C(Look.INK, 0.07))
  r.band:Hide()
  r.rule = r:CreateTexture(nil, "ARTWORK")
  r.rule:SetHeight(1)
  r.rule:SetPoint("BOTTOMLEFT", 6, -1); r.rule:SetPoint("BOTTOMRIGHT", -6, -1)
  r.rule:SetColorTexture(C(Look.INK, 0.5))
  r.rule:Hide()
  r.tri = Tri(r, 14, 0)
  r.tri:SetPoint("TOPLEFT", 18, -5)
  r.tri:Hide()
  r.right = Look.Text(r, "body", 10, Look.INK)
  r.right:SetPoint("TOPRIGHT", -8, -6)
  r.right:SetJustifyH("RIGHT")
  r.right:SetTextColor(C(Look.INK, TONE.sub))
  r.right:Hide()
  r.mode = "normal"

  r:SetScript("OnClick", RowClick)
  r:SetScript("OnEnter", RowEnter)
  r:SetScript("OnLeave", GameTooltip_Hide)
  r:Hide()
  return r
end

-- Zeilenart umstellen (nur bei Wechsel: Anker und Schrift neu setzen)
local function SetRowMode(r, mode)
  if r.mode == mode then return end
  r.mode = mode
  r.nameInset = nil
  local head, child = mode == "head", mode == "child"
  r.band:SetShown(head); r.rule:SetShown(head); r.tri:SetShown(head); r.right:SetShown(head)
  Look.Font(r.name, "hand", head and 22 or 19)
  r.name:ClearAllPoints()
  r.name:SetPoint("TOPLEFT", child and 58 or 40, head and -2 or -1)
  r.name:SetPoint("RIGHT", head and -112 or -40, 0)
  r.subX = child and 60 or 42
  r.subInset = nil
  if head then r.icon:Hide(); r.strike:Hide(); r.skull:Hide(); r.rank:SetText("") end
end

-- Toene einer Zeile: normal, rot (Rang 1, Taeter unklar), blass (begnadigt, nur von Hand, zaehlt nicht)
local ROW_TONE = {
  normal = { Look.INK, TONE.ink },
  red    = { Look.RED, TONE.ink },
  pale   = { Look.INK, TONE.hand },
}

-- Eine Zeile fuellen: Name, Untertext, Marke rechts unten (rot oder Tinte), Ton.
-- Der Untertext reicht bis an die Marke, ohne Marke fast bis an den Rand.
local function SetRow(r, name, sub, mark, tone, markInk)
  local t = ROW_TONE[tone] or ROW_TONE.normal
  r.name:SetText(name or "")
  r.name:SetTextColor(C(t[1], t[2]))
  r.sub:SetText(sub or "")
  r.sub:SetTextColor(C(Look.INK, TONE.sub))
  r.mark:SetText(mark or "")
  if markInk then r.mark:SetTextColor(C(Look.INK, TONE.sub)) else r.mark:SetTextColor(C(Look.RED_INK)) end
  local inset = 12
  if mark and mark ~= "" then inset = math.floor(math.max(70, TextWidth(r.mark, 58) + 14)) end
  if r.subInset ~= inset then
    r.subInset = inset
    r.sub:ClearAllPoints()
    r.sub:SetPoint("BOTTOMLEFT", r.subX or 42, -1)
    r.sub:SetPoint("RIGHT", -inset, 0)
  end
  r.full, r.tipFn = nil, nil
end

local function SetRank(r, rank, text)
  r.rank:SetText(text or (rank and (rank .. ".")) or "")
  r.rank:SetTextColor(C(rank == 1 and Look.RED or Look.INK))
end

function UX.Seen(e)
  local ls = e.lastSeen
  local ago = type(ls) == "table" and Look.Ago(ls.t)
  return ago and Fmt(L.ROW_SEEN, { time = ago }) or L.ROW_NOT_SEEN
end

-- Ort und Zeitpunkt der neuesten Tat
local function DeedWhere(d)
  if not d then return nil end
  return Look.Join(Look.When(d.t), Look.Place(d.zone, d.subzone))
end

function UX.BindEnemyRow(r, e)
  SetRowMode(r, "normal")
  local rank = (e.status == "wanted") and Store().Rank(e.key) or nil
  local pardoned, suspect = e.status == "pardoned", e.status == "suspect"
  r.skull:Hide()
  SetRank(r, rank, suspect and "?" or nil)
  local sub
  if pardoned then sub = Look.Join(L.ROW_PARDONED, Look.Tally(e))
  elseif suspect then sub = Look.Join(L.ROW_SUSPECT, DeedWhere(Look.LastDeed(e)))
  else sub = Look.Join(Look.Tally(e), UX.Seen(e)) end
  local rv = tonumber(e.revenge) or 0
  SetRow(r, Look.Name(e), sub, rv > 0 and Fmt(L.MARK_REVENGE, { times = Look.Times(rv) }) or nil,
         (rank == 1 and "red") or (pardoned and "pale") or "normal")
  Look.ClassIcon(r.icon, e.class)
  r.icon:Show()
  r.under:SetShown((state.filter == "open" and state.osel or state.selected) == e.key)
  r.under:SetWidth(InkWidth(r.name))
  -- durchgestrichen nur, wer begnadigt ist; Rache steht rechts als Vermerk
  r.strike:SetShown(pardoned)
  r.strike:SetWidth(InkWidth(r.name))
end

-- Fall ohne Taeter (Zu klaeren): rot, mit Zahl der Kandidaten
function UX.BindCaseRow(r, d)
  SetRowMode(r, "normal")
  SetRank(r, nil)
  r.skull:Show()
  r.icon:Hide()
  r.strike:Hide()
  local n = type(d.candidates) == "table" and #d.candidates or 0
  SetRow(r, L.ROW_KILLER_UNCLEAR, DeedWhere(d), n > 0 and Look.Count(n, L.MARK_CANDIDATES) or nil, "red")
  r.under:SetShown(state.osel == d)
  r.under:SetWidth(InkWidth(r.name))
end

function UX.BindDeathRow(r, d, index)
  SetRowMode(r, "normal")
  SetRank(r, nil)
  r.skull:Show()
  r.icon:Hide()
  r.strike:Hide()
  local name, mark, tone, markInk = nil, nil, "normal", false
  if d.kind == "pvp" and d.killerKey then
    name = (NameOfKey(d.killerKey, d.killerName))
    if d.sure == false then mark = L.MARK_SUSPECT end
  elseif d.kind == "pvp" then
    local n = type(d.candidates) == "table" and #d.candidates or 0
    name, tone = L.ROW_KILLER_UNCLEAR, "red"
    if n > 0 then mark = Look.Count(n, L.MARK_CANDIDATES) end
  else
    name, tone = (d.kind == "pve" and L.ROW_NO_PLAYER or L.ROW_UNCLEAR), "pale"
  end
  if d.counted == false then tone, mark, markInk = "pale", L.MARK_NOT_COUNTED, true end
  SetRow(r, name, DeedWhere(d), mark, tone, markInk)
  r.under:SetShown(state.death == index)
  r.under:SetWidth(InkWidth(r.name))
end

local listedNames = {}   -- Arbeitstabelle fuer listedBy-Namen

function UX.BindGuildRow(r, g, pos)
  SetRowMode(r, "normal")
  local only = Look.ListedOnly(g)
  local rank = not only and (GCall("Rank", g.key, GF.Src()) or (state.gsort == "rank" and pos)) or nil   -- 1.2.0: Rang der gewaehlten Quelle
  r.skull:Hide()
  r.strike:Hide()
  SetRank(r, rank)
  Look.ClassIcon(r.icon, g.class)
  r.icon:Show()
  local sub
  if only then
    local names = Look.ListedNames(g, listedNames)
    sub = #names > 0 and Fmt(L.ROW_LISTED_BY, { names = Look.NameList(names, 2) }) or L.TALLY_MANUAL
  else
    sub = Look.Join(Fmt(L.ROW_GKILLED, { kills = Look.GKills(g.kills) }), Look.Count(g.victimCount, L.ROW_VICTIMS),
                    type(g.lastVictim) == "string" and g.lastVictim ~= "" and Fmt(L.ROW_LAST, { text = Look.First(g.lastVictim) }))
  end
  -- kleines Zeichen: steht schon im eigenen Buch
  local mine = g.mine or Store().Get(g.key)
  SetRow(r, Look.Name(g), sub, mine and L.MARK_IN_BOOK or nil, (rank == 1 and "red") or (only and "pale") or "normal", true)
  r.under:SetShown(state.gselected == g.key)
  r.under:SetWidth(InkWidth(r.name))
end

------------------------------------------------------------------------
-- Gilde nach Kollege: eine flache Liste aus Kopf- und Kindzeilen im selben Zeilen-Pool
------------------------------------------------------------------------
function UX.BindMemberHead(r, w)
  SetRowMode(r, "head")
  local m = w.m
  local killers, listed = tonumber(m.killers) or 0, tonumber(m.listed) or 0
  if killers > 0 then
    r.right:SetText(Look.Join(Look.Count(killers, L.MEMBER_KILLERS), Look.Count(m.deaths, L.MEMBER_DEATHS)))
  elseif listed > 0 then
    r.right:SetText(Fmt(L.MEMBER_LISTED, { count = listed }))
  else
    r.right:SetText("")
  end
  -- Name darf bis an den Zaehler reichen
  local inset = math.floor(math.max(48, TextWidth(r.right, 96) + 18))
  if r.nameInset ~= inset then
    r.nameInset = inset
    r.name:ClearAllPoints()
    r.name:SetPoint("TOPLEFT", 40, -2)
    r.name:SetPoint("RIGHT", -inset, 0)
  end
  local empty = type(m.rows) ~= "table" or #m.rows == 0
  local sub
  if m.me then sub = L.MEMBER_ME
  elseif m.tie and m.tie.conflict then sub = L.MEMBER_CONFLICT
  elseif empty then sub = L.MEMBER_NOTHING
  else local last = m.lastDeath and Look.Ago(m.lastDeath); sub = last and Fmt(L.MEMBER_LAST_DIED, { time = last }) or "" end
  -- 1.2.0: erkennbar, ob Freund (1.2.0: nur in "Alle")
  local srcMark = not m.me and GF.SrcMark(m.src) or nil
  SetRow(r, Look.First(m.name), sub, m.me and L.MARK_YOU or srcMark, "normal", srcMark ~= nil)
  if Look.First(m.name) ~= tostring(m.name) then r.full = tostring(m.name) end
  r.tri:SetShown(not empty)
  -- zu: Spitze nach rechts, auf: nach unten
  r.tri:SetRotation(w.open and -1.5708 or 0)
  r.under:Hide()
end

function UX.BindMemberChild(r, w)
  SetRowMode(r, "child")
  local row = w.r
  local e = row.entry
  SetRank(r, nil)
  r.skull:Hide(); r.strike:Hide()
  Look.ClassIcon(r.icon, e and e.class)
  r.icon:Show()
  local kills = tonumber(row.kills) or 0
  local sub, tone
  if kills > 0 then
    local ago = row.lastKill and Look.Ago(row.lastKill)
    local last = ago and Fmt(L.ROW_LAST, { text = ago })
    if last and type(row.lastZone) == "string" and row.lastZone ~= "" then
      last = Fmt(L.ALERT_LINE_IN, { text = last, zone = row.lastZone })
    end
    sub, tone = Look.Join(Fmt(L.ROW_GKILLED, { kills = Look.GKills(kills) }), last), "normal"
  else
    sub, tone = Look.Join(L.TALLY_MANUAL, row.listedAt and Look.Ago(row.listedAt)), "pale"
  end
  SetRow(r, e and Look.Name(e) or tostring(row.key or "?"), sub, Store().Get(row.key) and L.MARK_IN_BOOK or nil, tone, true)
  r.under:SetShown(state.gselected == row.key and (state.gmember == nil or state.gmember == w.m.name))
  r.under:SetWidth(InkWidth(r.name))
end

-- Abschussliste (1.2.0): Name mit Klassensymbol, darunter wer freigegeben hat und seit wann;
-- rechts der Erlegt-Zaehler bzw. die Zahl der Freigaben
function GF.SrcMark(src)
  -- 1.2.0: nur in "Alle", und nur beim Freund (Kollege ist der Normalfall und bleibt ohne Zeichen)
  if GF.Src() ~= "all" then return nil end
  if src == "friends" then return L.MARK_FRIEND end
  if src == "both" then return L.MARK_BOTH end
  return nil
end

-- Tooltip einer Zeile der Abschussliste: alles, auch der lange Grund und alle Namen
function GF.HuntTip(h)
  local names = type(h.names) == "table" and h.names or {}
  local n = tonumber(h.n) or #names
  local lvl = type(h.level) == "number" and Fmt(L.POSTER_LEVEL, { level = h.level }) or nil
  local tip = { Look.Name(h) }
  local who = Look.Join(lvl, ClassName(h))
  if who ~= "" then tip[#tip + 1] = who end
  if n > 0 then tip[#tip + 1] = Fmt(L.HUNT_ROW_CALLS, { count = n, names = table.concat(names, ", ") }) end
  if type(h.why) == "string" and h.why ~= "" then tip[#tip + 1] = Fmt(L.HUNT_REASON, { reason = h.why }) end
  if type(h.since) == "number" then tip[#tip + 1] = Fmt(L.TIP_RELEASED_AT, { time = Look.When(h.since) }) end
  local ls = type(h.lastSeen) == "table" and h.lastSeen or nil
  local seen = ls and Look.Ago(ls.t)
  tip[#tip + 1] = seen and Fmt(L.ROW_SEEN, { time = seen }) or L.ROW_NOT_SEEN
  local bag = tonumber(h.bagged) or 0
  if bag > 0 then tip[#tip + 1] = Fmt(L.MARK_TAKEN_DOWN, { times = Look.Times(bag) }) end
  if h.hidden then tip[#tip + 1] = L.HUNT_ROW_HIDDEN end
  return tip
end

function GF.BindHuntRow(r, h)
  SetRowMode(r, "normal")
  SetRank(r, nil)
  r.skull:Hide()
  r.strike:Hide()
  Look.ClassIcon(r.icon, h.class)
  r.icon:Show()
  -- 1.2.0: zweite Zeile mit drei Angaben: wer freigegeben hat (ausgeblendet: das), der Grund gekuerzt,
  -- zuletzt gesehen bzw. seit wann; rechts der Erlegt-Zaehler. Stufe und alles andere: Plakat und Tooltip.
  local names = type(h.names) == "table" and h.names or {}
  local ls = type(h.lastSeen) == "table" and h.lastSeen or nil
  local seen = ls and Look.Ago(ls.t)
  local why = type(h.why) == "string" and h.why ~= "" and h.why or nil
  if why then
    -- Zeichen zaehlen, nicht Bytes (kyrillisch und CJK sonst viel kuerzer); Schnitt immer an einer Zeichengrenze
    local n, cut = 0, nil
    for pos in why:gmatch("()[^\128-\191]") do
      n = n + 1
      if n == GF.WHY_ROW + 1 then cut = pos; break end
    end
    if cut then why = why:sub(1, cut - 1) .. "…" end
  end
  local who = h.hidden and L.HUNT_ROW_HIDDEN or (#names > 0 and Look.NameList(names, 2)) or nil
  local sinceT = type(h.since) == "number" and Look.Ago(h.since) or nil
  local sub = Look.Join(who, why, seen and Fmt(L.ROW_SEEN, { time = seen }) or sinceT)
  local bag = tonumber(h.bagged) or 0
  local mark = bag > 0 and Fmt(L.MARK_TAKEN_DOWN, { times = Look.Times(bag) }) or nil
  SetRow(r, Look.Name(h), sub, mark, h.hidden and "pale" or "normal", false)
  r.tipFn = GF.HuntTip          -- Tooltip erst beim Zeigen bauen (Neuaufbau bleibt billig)
  r.under:SetShown(state.hselected == h.key)
  r.under:SetWidth(InkWidth(r.name))
end

BindRows = function()
  local n = #data
  local maxOff = math.max(0, n - ROWS)
  if state.offset > maxOff then state.offset = maxOff end
  for i = 1, ROWS do
    local r = rows[i]
    local idx = state.offset + i
    local item = data[idx]
    r.item, r.index = item, (dataIdx and dataIdx[idx]) or idx
    if item then
      if state.filter == "journal" then UX.BindDeathRow(r, item, r.index)
      elseif item.wrap then
        if item.head then UX.BindMemberHead(r, item) else UX.BindMemberChild(r, item) end
      elseif state.filter == "guild" then
        if GF.HuntView() then GF.BindHuntRow(r, item) else UX.BindGuildRow(r, item, idx) end
      elseif IsCase(item) then UX.BindCaseRow(r, item)
      else UX.BindEnemyRow(r, item) end
      r:Show()
    else
      r:Hide()
    end
  end
  LP.scroll:SetMinMaxValues(0, maxOff)
  LP.scroll:SetValue(state.offset)
  LP.scroll:SetShown(maxOff > 0)
end

------------------------------------------------------------------------
-- Rechte Seite: Plakat, Todesakte, Leerzustand
------------------------------------------------------------------------
-- Tooltip-Inhalt erst beim Zeigen bauen (nicht bei jedem Neuaufbau der Liste)
local function DeedEnter(self)
  if self.tipItem and self.tipFn then Tip(self, self.tipFn(self.tipItem)) end
end

local function CandEnter(self)
  if self.tip then Tip(self, self.tip) end
end
local function CandLeave(self)
  if self.tip then GameTooltip:Hide() end
end

-- Stempel (1.2.0): Deutsch zeigt die Bilder mit eingebranntem Text (wie 1.1.0); jede andere Sprache den
-- textlosen Rahmen (gleicher Winkel, Farbe, Abnutzung) und den Text aus der Sprachtabelle darueber.
-- je Stempel: Schluessel, Winkel aus make_media.sh (Grad, ImageMagick im Uhrzeigersinn), Tinte
GF.STAMPS = { nr1 = { "STAMP_NR1", -11, 1 }, guild = { "STAMP_GUILD_NR1", -9, 1 }, rache = { "STAMP_REVENGE", 9, 1 },
              pardon = { "STAMP_PARDONED", -6, 2 }, suspect = { "STAMP_SUSPECT", 7, 3 }, hunt = { "STAMP_HUNT", 8, 1 } }
GF.STAMP_INK = { { 0.69, 0.04, 0.04 }, { 0.12, 0.106, 0.098 }, { 0.18, 0.165, 0.153 } }   -- #b00a0a #1e1b19 #2e2a27
GF.STAMP_TEXT_W = 104       -- Innenrahmen des Stempels bei 140x70 px

function GF.StampLabel(layer, tex)
  local fs = Look.Text(layer, "title", 16, GF.STAMP_INK[1])
  -- (eigene Ebene ueber dem Foto; der Rahmen ist innen leer, die Schrift bleibt sichtbar)
  fs:SetPoint("CENTER", tex, "CENTER", 0, 0)
  fs:SetWidth(GF.STAMP_TEXT_W)
  fs:SetJustifyH("CENTER")
  fs:SetMaxLines(2)
  fs.on = false
  fs:Hide()
  tex.label = fs
end

-- Stempelbild setzen; id = Name in Look.TEX (nr1, guild, rache, pardon, suspect, hunt)
function GF.Stamp(tex, id)
  local s, fs = GF.STAMPS[id], tex.label
  local code = ns.Locale and ns.Locale.code
  if not (s and fs and code) or code == "deDE" then
    Look.Tex(tex, Look.TEX[id], 0.7, 0.05, 0.05, 0.5)
    if fs then fs.on = false; fs:Hide() end
    return
  end
  Look.Tex(tex, Look.MEDIA .. "stamp_" .. id .. "_blank.tga", 0.7, 0.05, 0.05, 0.5)
  local text = L[s[1]]
  if fs.text ~= text then
    fs.text = text
    -- eine Zeile in 16 pt, sonst zwei Zeilen in 13 pt, sonst 11 pt
    Look.Font(fs, "title", 16)
    fs:SetText(text)
    local w = TextWidth(fs, GF.STAMP_TEXT_W)
    if w > GF.STAMP_TEXT_W then Look.Font(fs, "title", w > GF.STAMP_TEXT_W * 1.6 and 11 or 13); fs:SetText(text) end
  end
  local c = GF.STAMP_INK[s[3]]
  fs:SetTextColor(c[1], c[2], c[3], 0.92)
  if fs.SetRotation then pcall(fs.SetRotation, fs, math.rad(-s[2])) end
  fs.on = true
  fs:SetShown(tex:IsShown())
end

function GF.ShowStamp(tex, on)
  tex:SetShown(on and true or false)
  if tex.label then tex.label:SetShown((on and tex.label.on) and true or false) end
end

function UX.BuildPoster()
  P = CreateFrame("Frame", nil, RP)
  P:SetSize(352, 452)
  P:SetPoint("TOP", 2, -20)
  UX.Shadow(P, 4, 5, 0.5)
  local bg = Tex(P, "BACKGROUND", Look.TEX.paper)
  bg:SetAllPoints()
  P.pin = P:CreateTexture(nil, "OVERLAY", nil, 7)
  P.pin:SetSize(28, 28)
  P.pin:SetPoint("TOP", 0, 12)
  Look.Tex(P.pin, Look.TEX.pin, 0.7, 0.05, 0.05, 1)
  if ns.Humor then pcall(ns.Humor.Pin, P, P.pin) end -- Humor: Reisszwecke (ein Fehler dort kostet nur die Zwecke)
  P.tapes = { Tape(P, "BOTTOMLEFT", 0.6), Tape(P, "BOTTOMRIGHT", -0.55) }
  P.card = Tape(P, "TOPLEFT", 0.75)            -- Karteikarte (Akte): Klebestreifen statt Reisszwecke
  P.card:Hide()

  -- Taeter-Plakat (auch fuer das Gildenbuch)
  local E = CreateFrame("Frame", nil, P)
  E:SetAllPoints()
  P.enemy = E
  E.wanted = Look.Text(E, "hand", 46, Look.INK)
  E.wanted:SetPoint("TOP", 0, -12)
  E.wanted:SetText("WANTED")
  Rule(E, -56, 24, 24, 0.7)
  E.doa = Look.Text(E, "body", 11, Look.INK)
  E.doa:SetPoint("TOP", 0, -61)
  Rule(E, -76, 24, 24, 0.7)

  local photo = CreateFrame("Frame", nil, E)
  photo:SetSize(100, 100)
  photo:SetPoint("TOPLEFT", 20, -88)
  E.photo = photo
  local pb = photo:CreateTexture(nil, "BACKGROUND")
  pb:SetPoint("TOPLEFT", -3, 3); pb:SetPoint("BOTTOMRIGHT", 3, -3)
  pb:SetColorTexture(C(Look.INK, 1))
  local mug = photo:CreateTexture(nil, "BORDER")
  mug:SetAllPoints()
  Look.Tex(mug, Look.TEX.mugshot, 0.75, 0.73, 0.69, 1)
  E.icon = photo:CreateTexture(nil, "ARTWORK")
  E.icon:SetSize(70, 70)
  E.icon:SetPoint("CENTER", 0, -4)
  MugIcon(E.icon)
  E.portrait = photo:CreateTexture(nil, "ARTWORK", nil, 1)
  E.portrait:SetSize(86, 86)
  E.portrait:SetPoint("CENTER", 0, -3)
  E.portrait:Hide()
  Tape(photo, "TOPLEFT", 0.7)
  Tape(photo, "TOPRIGHT", -0.7, -10)     -- etwas eingerueckt: der Name daneben bleibt frei

  -- Name (hoechstens 2 Zeilen), Klassenbalken, die Kernzahl in Handschrift, darunter der Steckbrief
  E.name = Look.Text(E, "hand", 19, Look.INK)
  E.name:SetPoint("TOPLEFT", 140, -86)
  E.name:SetWidth(192)
  E.name:SetJustifyH("LEFT")
  E.name:SetMaxLines(2)
  E.bar = E:CreateTexture(nil, "ARTWORK")
  E.bar:SetSize(100, 3)
  E.bar:SetPoint("TOPLEFT", E.name, "BOTTOMLEFT", 0, -3)
  E.tally = Look.Text(E, "hand", 16, Look.INK)
  E.tally:SetPoint("TOPLEFT", E.bar, "BOTTOMLEFT", 0, -4)
  E.tally:SetWidth(192)
  E.tally:SetJustifyH("LEFT")
  E.tally:SetWordWrap(false)
  E.info = {}
  for i = 1, INFO_LINES do
    local l = Look.Text(E, "type", 11, Look.INK)
    if i == 1 then l:SetPoint("TOPLEFT", E.tally, "BOTTOMLEFT", 0, -3)
    else l:SetPoint("TOPLEFT", E.info[i - 1], "BOTTOMLEFT", 0, -2) end
    l:SetWidth(192)
    l:SetJustifyH("LEFT")
    l:SetWordWrap(false)
    E.info[i] = l
  end

  -- unsichtbare Flaechen: "Im Buch von: …" bzw. der ganze Steckbrief, wenn Zeilen fehlen
  E.listHit = CreateFrame("Button", nil, E)
  E.listHit:SetSize(200, 13)
  E.listHit:SetScript("OnEnter", CandEnter)
  E.listHit:SetScript("OnLeave", CandLeave)
  E.listHit:Hide()
  E.infoHit = CreateFrame("Button", nil, E)
  E.infoHit:SetPoint("TOPLEFT", E.info[1], "TOPLEFT", 0, 0)
  E.infoHit:SetSize(200, 30)
  E.infoHit:SetScript("OnEnter", CandEnter)
  E.infoHit:SetScript("OnLeave", CandLeave)
  E.infoHit:Hide()
  -- voller Name und alle Opfer im Tooltip (lange Namen werden gekuerzt)
  E.nameHit = CreateFrame("Button", nil, E)
  E.nameHit:SetPoint("TOPLEFT", E.name, "TOPLEFT", 0, 0)
  E.nameHit:SetSize(192, 22)
  E.nameHit:SetScript("OnEnter", CandEnter)
  E.nameHit:SetScript("OnLeave", CandLeave)

  E.bountyLabel = Look.Text(E, "body", 10, Look.RED_INK)
  E.bounty = Look.Text(E, "hand", 22, Look.INK)
  E.bountySize = 22

  E.fileLabel = Label(E, "")
  E.fileLabel:SetPoint("TOPLEFT", 20, -256)
  Rule(E, -267, 20, 20, 0.45)
  -- Taten als kleine Frames: voller Text und Mittaeter im Tooltip. Rechts die Rolle ("beteiligt",
  -- "Verdacht") als eigene Spalte, damit sie nie abgeschnitten wird; gekuerzt wird der Ort.
  E.lines = {}
  for i = 1, DEATH_LINES do
    local b = CreateFrame("Button", nil, E)
    b:SetSize(312, 16)
    b:SetPoint("TOPLEFT", 20, -271 - (i - 1) * 16)
    b.text = Look.Text(b, "hand", 13, Look.INK)
    b.text:SetPoint("LEFT", 0, 0)
    b.text:SetWidth(312)
    b.text:SetJustifyH("LEFT")
    b.text:SetWordWrap(false)
    b.tag = Look.Text(b, "hand", 13, Look.INK)
    b.tag:SetPoint("RIGHT", 0, 0)
    b.tag:SetJustifyH("RIGHT")
    b.tag:SetTextColor(C(Look.INK, TONE.sub))
    b.tagged = false
    b:SetScript("OnEnter", DeedEnter)
    b:SetScript("OnLeave", GameTooltip_Hide)
    E.lines[i] = b
  end

  E.noteLabel = Label(E, "")
  E.noteLabel:SetPoint("TOPLEFT", 20, -381)
  local note = CreateFrame("EditBox", nil, E)
  -- 1.2.0: Breite nach dem Etikett (Sprache). 1.2.0: zwei Anker an derselben Oberkante (vorher LEFT plus
  -- RIGHT: zwei senkrechte Mitten, die sich um rund 100 px widersprachen)
  note:SetPoint("TOPLEFT", E.noteLabel, "TOPRIGHT", 8, 4)
  note:SetPoint("TOPRIGHT", E, "TOPRIGHT", -20, -377)
  note:SetHeight(18)
  note:SetAutoFocus(false)
  note:SetMaxLetters(200)
  Look.Font(note, "hand", 13)
  note:SetTextColor(C(Look.INK))
  local ul = note:CreateTexture(nil, "BACKGROUND")
  ul:SetColorTexture(C(Look.INK, 0.35))
  ul:SetHeight(1)
  ul:SetPoint("BOTTOMLEFT", 0, 1); ul:SetPoint("BOTTOMRIGHT", 0, 1)
  local function save(self)
    local key = self.key
    if not key then return end
    local e = Store().Get(key)
    local text = self:GetText() or ""
    -- the shown sentence of an entry taken over from the guild book is no own note (1.2.0)
    if e and (e.note or "") ~= text and text ~= Look.NoteOf(e) then Store().SetNote(key, text) end
  end
  note:SetScript("OnEnterPressed", function(self) save(self); self:ClearFocus() end)
  note:SetScript("OnEditFocusLost", save)
  note:SetScript("OnEscapePressed", function(self)
    local e = self.key and Store().Get(self.key)
    self:SetText(e and Look.NoteOf(e) or "")
    self:ClearFocus()
  end)
  E.note = note
  -- Gildenplakat: statt der Notiz die Opfer
  E.victims = Look.Text(E, "hand", 13, Look.INK)
  E.victims:SetPoint("TOPLEFT", E.noteLabel, "TOPRIGHT", 8, 2)
  E.victims:SetPoint("TOPRIGHT", E, "TOPRIGHT", -20, -379)
  E.victims:SetJustifyH("LEFT")
  E.victims:SetWordWrap(false)
  E.victims:Hide()
  E.victimsHit = CreateFrame("Button", nil, E)
  E.victimsHit:SetPoint("LEFT", E.victims, "LEFT", 0, 0)
  E.victimsHit:SetPoint("RIGHT", E.victims, "RIGHT", 0, 0)
  E.victimsHit:SetHeight(16)
  E.victimsHit:SetScript("OnEnter", CandEnter)
  E.victimsHit:SetScript("OnLeave", CandLeave)
  E.victimsHit:Hide()

  -- Stempel (vorgedrehte Texturen). Nr. 1 / Begnadigt / Verdacht auf der unteren Fotohaelfte,
  -- Rache neben dem Kopfgeld: kein Stempel liegt auf Text.
  -- Eigene Ebene UEBER dem Foto: das Foto ist ein Kind-Frame, und Regionen eines Kind-Frames liegen im
  -- Client immer ueber denen des Eltern-Frames, gleich welche Zeichenebene. Ohne diese Ebene verschwindet
  -- der Stempel hinter dem Foto.
  local SL = CreateFrame("Frame", nil, E)
  SL:SetAllPoints(E)
  SL:SetFrameLevel(photo:GetFrameLevel() + 3)
  E.stampLayer = SL
  -- 1.2.0: je Stempel ein Schriftzug fuer die Fassung ohne eingebrannten Text (alle Sprachen ausser Deutsch)
  E.stampNr1 = SL:CreateTexture(nil, "OVERLAY", nil, 3)
  E.stampNr1:SetSize(GF.STAMP_W, GF.STAMP_H)
  E.stampNr1:SetPoint("TOPLEFT", photo, "TOPLEFT", -22, -54)
  E.stampNr1:SetAlpha(0.92)
  E.stampOther = SL:CreateTexture(nil, "OVERLAY", nil, 3)
  E.stampOther:SetSize(GF.STAMP_W, GF.STAMP_H)
  E.stampOther:SetPoint("TOPLEFT", photo, "TOPLEFT", -22, -54)
  E.stampOther:SetAlpha(0.92)
  E.stampRache = SL:CreateTexture(nil, "OVERLAY", nil, 4)
  E.stampRache:SetSize(GF.STAMP_W, GF.STAMP_H)
  E.stampRache:SetPoint("TOP", 70, -200)
  E.stampRache:SetAlpha(0.92)
  for _, st in ipairs({ E.stampNr1, E.stampOther, E.stampRache }) do GF.StampLabel(SL, st) end
  GF.Stamp(E.stampRache, "rache")
  E.racheCount = Look.Text(E, "body", 19, { 0.56, 0.04, 0.04, 0.95 }, "THICKOUTLINE")
  E.racheCount:SetPoint("LEFT", E.stampRache, "RIGHT", -6, -8)
  if E.racheCount.SetRotation then pcall(E.racheCount.SetRotation, E.racheCount, 0.16) end

  E.buttons = {}
  for i = 1, 2 do
    E.buttons[i] = InkButton(E, "", 108, 22)
    E.buttons[i]:SetPoint("BOTTOMLEFT", 20 + (i - 1) * 116, 10)
  end
  -- Streichen: kein Knopf, ein kleines Wort unten rechts (Hover rot); fragt immer nach
  E.strike = WordButton(E, L.ACT_STRIKE, "hand", 13)
  E.strike:SetPoint("BOTTOMRIGHT", -38, 11)
  E.strike:SetSize(math.max(64, math.min(96, TextWidth(E.strike.text, 60) + 4)), 20)
  E.strike:SetScript("OnClick", function(self) Look.Sound("click"); if self.key then UI.ConfirmDelete(self.key) end end)
  -- 1.2.0: "Zur Jagd freigeben" / "Jagd abblasen" als Wort unter dem Foto (eigene Gesuchte, Gilde, Freunde)
  E.hunt = WordButton(E, "", "hand", 13)
  E.hunt:SetPoint("TOPLEFT", 20, -193)
  E.hunt:SetSize(120, 18)
  E.hunt:SetScript("OnClick", function(self)
    Look.Sound("click")
    if not self.key then return end
    if self.hide then GF.HideAction(self.key)[2]() else GF.HuntAction(self.key)[2]() end
  end)
  E.hunt:Hide()

  -- Todesakte (Journal, Zu klaeren): Karteikarte, links buendig
  local D = CreateFrame("Frame", nil, P)
  D:SetAllPoints()
  D:Hide()
  P.death = D
  D.head = Look.Text(D, "hand", 26, Look.INK)
  D.head:SetPoint("TOPLEFT", 24, -16)
  D.head:SetText(L.CASE_HEAD)
  D.when = Look.Text(D, "type", 11, Look.INK)
  D.when:SetPoint("TOPRIGHT", -24, -28)
  D.when:SetJustifyH("RIGHT")
  Rule(D, -52, 24, 24, 0.7)
  D.info = Look.Text(D, "type", 11, Look.INK)
  D.info:SetPoint("TOPLEFT", 24, -62)
  D.info:SetWidth(304)
  D.info:SetJustifyH("LEFT")
  D.info:SetSpacing(3)
  D.killLabel = Look.Text(D, "body", 10, Look.RED_INK)
  D.killLabel:SetPoint("TOPLEFT", D.info, "BOTTOMLEFT", 0, -16)
  D.killer = CreateFrame("Button", nil, D)
  D.killer:SetSize(304, 32)
  D.killer:SetPoint("TOPLEFT", D.killLabel, "BOTTOMLEFT", 0, -2)
  D.killer.text = Look.Text(D.killer, "hand", 26, Look.INK)
  D.killer.text:SetPoint("LEFT", 0, 0)
  D.killer.text:SetWidth(304)
  D.killer.text:SetJustifyH("LEFT")
  D.killer.text:SetWordWrap(false)
  D.killer:SetScript("OnClick", function(self)
    if self.key and Store().Get(self.key) then UI.ShowEnemy(self.key) end
  end)
  D.note = Look.Text(D, "type", 11, Look.INK)
  D.note:SetPoint("TOPLEFT", D.killer, "BOTTOMLEFT", 0, -2)
  D.note:SetWidth(304)
  D.note:SetJustifyH("LEFT")
  D.note:SetTextColor(C(Look.INK, TONE.sub))
  -- Mittaeter: anklickbare Namen in Handschrift
  D.assistLabel = Label(D, L.CASE_ASSISTS)
  D.assistLabel:SetPoint("TOPLEFT", D.note, "BOTTOMLEFT", 0, -14)
  D.assists = {}
  for i = 1, GF.ASSIST_MAX do
    local b = WordButton(D, "", "hand", 16, TONE.ink)
    b:SetSize(304, 20)
    if i == 1 then b:SetPoint("TOPLEFT", D.assistLabel, "BOTTOMLEFT", 0, -2)
    else b:SetPoint("TOPLEFT", D.assists[i - 1], "BOTTOMLEFT", 0, 0) end
    b:SetScript("OnClick", function(self) if self.key and Store().Get(self.key) then UI.ShowEnemy(self.key) end end)
    D.assists[i] = b
  end
  D.candLabel = Label(D, L.CASE_PICK)
  D.candLabel:SetPoint("TOPLEFT", D.note, "BOTTOMLEFT", 0, -14)
  D.cands = {}
  for i = 1, GF.CAND_MAX do
    local b = InkButton(D, "", 148, 22)
    local col, row = (i - 1) % 2, math.floor((i - 1) / 2)
    b:SetPoint("TOPLEFT", D.candLabel, "BOTTOMLEFT", col * 156, -6 - row * 28)
    b:HookScript("OnEnter", CandEnter)
    b:HookScript("OnLeave", CandLeave)
    D.cands[i] = b
  end
  D.source = Look.Text(D, "type", 11, Look.INK)
  D.source:SetPoint("BOTTOMLEFT", 24, 18)
  D.source:SetWidth(304)
  D.source:SetJustifyH("LEFT")
  D.source:SetTextColor(C(Look.INK, TONE.sub))

  -- Leerzustand: von Hand auf die leere rechte Seite geschrieben
  local X = CreateFrame("Frame", nil, RP)
  X:SetAllPoints()
  X:Hide()
  RP.empty = X
  X.big = Look.Text(X, "hand", 26, Look.INK)
  X.big:SetPoint("CENTER", 0, 20)
  X.big:SetWidth(PAGE_W - 40)
  X.small = Look.Text(X, "hand", 16, Look.INK)
  X.small:SetTextColor(C(Look.INK, TONE.sub))
  X.small:SetPoint("TOP", X.big, "BOTTOM", 0, -12)
  X.small:SetWidth(PAGE_W - 40)
  X.tiny = Look.Text(X, "type", 11, Look.INK)
  X.tiny:SetTextColor(C(Look.INK, TONE.sub))
  X.tiny:SetPoint("TOP", X.small, "BOTTOM", 0, -14)
  X.tiny:SetWidth(PAGE_W - 80)
  local xs = X:CreateTexture(nil, "ARTWORK")
  xs:SetSize(64, 64)
  xs:SetPoint("BOTTOM", X.big, "TOP", 0, 20)
  Look.Tex(xs, Look.TEX.skull, 0.2, 0.2, 0.2, 1)
  xs:SetVertexColor(0.2, 0.18, 0.16, 0.7)
end

-- Leerzustand der rechten Seite: ein Muster fuer alle Reiter
local function ShowEmpty(kind)
  local t = EMPTY[kind] or EMPTY.wanted
  RP.empty.big:SetText(L[t[1] .. "_HEAD"])
  RP.empty.small:SetText(t[2] >= 2 and L[t[1] .. "_SUB"] or "")
  RP.empty.tiny:SetText(t[2] >= 3 and L[t[1] .. "_HINT"] or "")
  if kind == "wanted" and ns.Humor then pcall(ns.Humor.EmptyWanted, RP.empty) end -- Humor: leeres Buch, 1. April
  P:Hide()
  RP.empty:Show()
end

-- zwei Knoepfe nebeneinander links unten (rechts davon steht das Wort "Streichen")
local function ConfigButtons(E, spec)
  for i = 1, 2 do
    local b, s = E.buttons[i], spec[i]
    if s then b:SetLabel(s[1]); b.fn = s[2]; b:Show() else b:Hide() end
  end
end

-- gueltiges Unit-Token fuer das Portraet (Tracker zuerst, sonst Ziel/Mouseover)
function UX.PortraitUnitFor(key)
  if ns.Tracker and ns.Tracker.UnitFor then
    local ok, u = pcall(ns.Tracker.UnitFor, key)
    if ok and type(u) == "string" and not Look.Secret(u) then return u end
  end
  if not (ns.Util and ns.Util.KeyOfUnit) then return nil end
  for _, u in ipairs({ "target", "mouseover" }) do
    local ok, k = pcall(ns.Util.KeyOfUnit, u)
    if ok and k == key then return u end
  end
end

UX.ROLE_TAG = { assist = "ROLE_ASSIST", suspect = "ROLE_SUSPECT" }   -- Schluessel

-- Tatzeile: "11.11. 01:01 · Siegel des Befehls · Die ungezähmte Küste" (Wichtiges zuerst, Ort zuletzt);
-- eigener Char nur, wenn es ein anderer war. Die Rolle steht rechts daneben.
function UX.DeathLine(d)
  local me = Look.Me()
  local who = (d.me and d.me ~= me) and ("(" .. Look.First(d.me) .. ")") or nil
  local tag = UX.ROLE_TAG[Look.Role(d)]
  return Look.Join(Look.When(d.t), d.spell ~= "" and d.spell or nil, Look.Place(d.zone, d.subzone), who),
         tag and L[tag]
end

function UX.DeathTip(d)
  local t = { Look.When(d.t), PlaceText(d.zone, d.subzone) }
  if d.spell and d.spell ~= "" then t[#t + 1] = Fmt(L.TIP_CAUSE, { spell = tostring(d.spell) }) end
  if d.me then t[#t + 1] = GF.VictimLine(d.me, d.myLevel) end
  if d.theirLevel then t[#t + 1] = Fmt(L.TIP_KILLER_LEVEL, { level = tostring(d.theirLevel) }) end
  if type(d.others) == "table" and #d.others > 0 then
    local names = {}
    for i = 1, math.min(#d.others, 6) do names[i] = (NameOfKey(d.others[i])) end
    t[#t + 1] = Fmt(L.TIP_ASSISTS, { names = table.concat(names, ", ") .. (#d.others > 6 and " …" or "") })
  end
  local role = Look.Role(d)
  if role == "assist" then t[#t + 1] = L.TIP_ROLE_ASSIST
  elseif role == "suspect" then t[#t + 1] = L.TIP_ROLE_SUSPECT end
  return t
end

-- Gilden-Tat: "12.11. 21:04 · Grom'gol · Anna"
function UX.GuildDeedLine(d)
  return Look.Join(Look.When(d.t), Look.Place(d.zone), Look.First(d.victim))
end

-- "Opfer: Anna Beispiel (Stufe 34)"
function GF.VictimLine(name, level)
  if level then return Fmt(L.TIP_VICTIM_LEVEL, { name = name, level = level }) end
  return Fmt(L.TIP_VICTIM, { name = name })
end

function UX.GuildDeedTip(d)
  local t = { Look.When(d.t), PlaceText(d.zone) }
  if d.victim then t[#t + 1] = GF.VictimLine(tostring(d.victim), d.level) end
  return t
end

local function FillLines(E, list, lineFn, tipFn, emptyText)
  local n = #list
  for i = 1, DEATH_LINES do
    local b = E.lines[i]
    b.tipItem, b.tipFn = nil, nil
    local text, tag = "", nil
    if i == DEATH_LINES and n > DEATH_LINES then
      text = Fmt(L.MORE_LINE, { count = n - DEATH_LINES + 1 })
    elseif list[i] then
      text, tag = lineFn(list[i])
      b.tipItem, b.tipFn = list[i], tipFn
    elseif i == 1 then
      text = emptyText
    end
    b.text:SetText(text)
    b.tag:SetText(tag or "")
    -- Platz fuer die Rolle rechts nach ihrer Breite; der Ort davor wird notfalls gekuerzt
    local w = tag and math.floor(312 - TextWidth(b.tag, 60) - 10) or 312
    if b.tagged ~= w then
      b.tagged = w
      b.text:SetWidth(w)
    end
  end
end

local function SetPhoto(E, e)
  -- Reisszwecke (Osterei) nur mit "Trockene Bemerkungen" an und nur, wo die Zwecke zu sehen ist
  if P.dnPin then P.dnPin:SetShown(P.pin:IsShown() and ns.Humor and ns.Humor.On() or false) end
  E.name:SetText(Look.Name(e))
  E.nameHit.tip = Truncated(E.name) and { Look.Name(e) } or nil
  E.bar:SetColorTexture(Look.ClassRGB(e.class))
  local unit = UX.PortraitUnitFor(e.key)
  local pok = false
  if unit and SetPortraitTexture then
    E.portrait:SetTexCoord(0, 1, 0, 1)
    pok = pcall(SetPortraitTexture, E.portrait, unit)
  end
  E.portrait:SetShown(pok)
  E.icon:SetShown(not pok)
  if not pok then Look.ClassIcon(E.icon, e.class); MugIcon(E.icon) end
end

-- Steckbrief: hoechstens so viele Zeilen, wie unter den Namen passen. Faellt eine Zeile weg (langer Name
-- in zwei Zeilen), zeigt der Tooltip ueber dem Steckbrief alles.
local scratchInfo, scratchTip = {}, {}
local function SetInfo(E, info, optional)
  local twoLines = TextWidth(E.name, 0) > 192
  local room = twoLines and INFO_LINES - 1 or INFO_LINES
  local shown, dropped = 0, false
  for i = 1, #info do
    -- 1.2.0: optionale Zeilen (Rasse, Gilde) weichen immer, wenn sonst eine spaetere Zeile keinen Platz haette
    if shown < room and not (optional[i] and #info - i + shown >= room) then
      shown = shown + 1
      E.info[shown]:SetText(info[i])
    else
      dropped = true
    end
  end
  for i = shown + 1, INFO_LINES do E.info[i]:SetText("") end
  if dropped then
    local t = wipe(scratchTip)
    t[1] = Look.Name(P.enemy.current)
    for i = 1, #info do t[#t + 1] = info[i] end
    E.infoHit.tip = t
    E.infoHit:Show()
  else
    E.infoHit.tip = nil
    E.infoHit:Hide()
  end
end

-- Kopfgeld ab vier Stellen ("2.875 GOLD") einen Grad kleiner, sonst stoesst es an den Rache-Stempel
local function SetBounty(E, text, big)
  local size = big and 19 or 22
  if E.bountySize ~= size then
    E.bountySize = size
    Look.Font(E.bounty, "hand", size)
  end
  E.bounty:SetText(text)
end

-- Kopfgeld-Block; mit Rache-Stempel rueckt er nach links, der Stempel steht daneben
local function PlaceBounty(E, shifted)
  local x = shifted and -62 or 0
  E.bountyLabel:ClearAllPoints()
  E.bountyLabel:SetPoint("TOP", x, -212)
  E.bounty:ClearAllPoints()
  E.bounty:SetPoint("TOP", x, -225)
end

ClassName = function(e)
  if e.classLoc then return e.classLoc end
  -- Gildeneintraege tragen nur das Klassen-Token: steht derselbe Taeter im eigenen Buch, gilt dessen
  -- Wortlaut ("Magierin"), damit dieselbe Person ueberall gleich heisst
  local S = ns.Store
  local own = e.key and S and S.Get and S.Get(e.key)
  if type(own) == "table" and type(own.classLoc) == "string" and own.class == e.class then return own.classLoc end
  local CN = LOCALIZED_CLASS_NAMES_MALE
  if e.class and type(CN) == "table" and CN[e.class] then return CN[e.class] end
  return e.class
end

local optInfo = {}
local function FillEnemy(e)
  local E = P.enemy
  E.current = e
  E.listHit:Hide()
  local S = Store()
  local rank = (e.status == "wanted") and S.Rank(e.key) or nil
  E.doa:SetText(Spaced(L.POSTER_DOA))
  SetPhoto(E, e)
  E.tally:SetText(e.status == "pardoned" and Look.Join(L.ROW_PARDONED, Look.Tally(e)) or Look.Tally(e))

  -- Steckbrief: "Stufe 36 · Magierin", Rasse, "Gilde: Beispielgilde", zuletzt gesehen (Rasse und Gilde fallen
  -- bei zweizeiligem Namen zuerst weg)
  local info, opt = wipe(scratchInfo), wipe(optInfo)
  local cls = ClassName(e)
  local who = Look.Join(e.level and Fmt(L.POSTER_LEVEL, { level = e.level }), cls)
  if who ~= "" then info[#info + 1] = who end
  -- 1.2.0: begnadigt, Verdacht oder Rang 1 und zugleich auf der Abschussliste (der Stempel zeigt es dann nicht).
  -- 1.2.0: gleich nach der Stufe, vor Rasse und Gilde (die weichen zuerst), damit die Zeile immer zu sehen ist
  if e.status ~= "wanted" or rank == 1 then
    local h = GF.HasHunts() and GCall("Hunt", e.key, "all")
    if type(h) == "table" then
      local names = type(h.names) == "table" and h.names or {}
      info[#info + 1] = Fmt(L.POSTER_ON_HUNTLIST, { names = Look.NameList(names, 2) })
    end
  end
  if e.raceLoc or e.race then info[#info + 1] = e.raceLoc or e.race; opt[#info] = true end
  if e.guild and e.guild ~= "" then info[#info + 1] = Fmt(L.POSTER_GUILD, { guild = e.guild }); opt[#info] = true end
  local ls = e.lastSeen
  local ago = type(ls) == "table" and Look.Ago(ls.t)
  info[#info + 1] = ago and Fmt(L.POSTER_LAST_SEEN, { time = ago }) or L.POSTER_NOT_SEEN
  SetInfo(E, info, opt)

  local rv = tonumber(e.revenge) or 0
  E.bountyLabel:SetText(Spaced(L.POSTER_BOUNTY))
  local bounty = tonumber(S.Bounty and S.Bounty(e)) or 0
  SetBounty(E, GoldText(bounty), bounty >= 1000 * 10000)
  PlaceBounty(E, rv > 0)

  FillLines(E, e.deaths or {}, UX.DeathLine, UX.DeathTip,
            e.status == "suspect" and L.POSTER_ONLY_SUSPECT or L.POSTER_NO_DEEDS)
  E.fileLabel:SetText(Spaced(L.POSTER_DEEDS))

  E.noteLabel:SetText(Spaced(L.POSTER_NOTE))
  E.victims:Hide()
  E.victimsHit:Hide()
  E.note:Show()
  -- anderer Eintrag, waehrend das Feld Fokus hat: erst unter dem alten Schluessel speichern
  if E.note.key ~= e.key and E.note:HasFocus() then E.note:ClearFocus() end
  E.note.key = e.key
  if not E.note:HasFocus() then E.note:SetText(Look.NoteOf(e)) end

  if rank == 1 then GF.Stamp(E.stampNr1, "nr1") end
  GF.ShowStamp(E.stampNr1, rank == 1)
  -- VERDACHT nur fuer echte Verdachtsfaelle (Beteiligte sind Gesuchte)
  if e.status == "pardoned" then
    GF.Stamp(E.stampOther, "pardon"); GF.ShowStamp(E.stampOther, true)
  elseif e.status == "suspect" then
    GF.Stamp(E.stampOther, "suspect"); GF.ShowStamp(E.stampOther, true)
  else
    GF.HuntStamp(E, e.key, rank == 1)
  end
  GF.SetHuntWord(E, e.status == "wanted" and e.key or nil)
  GF.ShowStamp(E.stampRache, rv > 0)
  E.racheCount:SetShown(rv > 0)
  E.racheCount:SetText("×" .. rv)
  E.strike.key = e.key
  E.strike:Show()

  -- Knoepfe (mit ihren Closures) nur neu, wenn sich Eintrag oder Status geaendert haben
  local sig = "e\0" .. e.key .. "\0" .. tostring(e.status)
  if E.specSig ~= sig then
    E.specSig = sig
    ConfigButtons(E, EnemySpec(e))
  end
end

-- 1.2.0: Stempel ZUR JAGD FREIGEGEBEN auf dem Platz der anderen Stempel (Nr. 1 hat Vorrang)
function GF.HuntStamp(E, key, nr1)
  local h = not nr1 and GF.HasHunts() and GCall("Hunt", key, "all")
  if type(h) == "table" then
    GF.Stamp(E.stampOther, "hunt")
    GF.ShowStamp(E.stampOther, true)
  else
    GF.ShowStamp(E.stampOther, false)
  end
end

-- Wort unter dem Foto: freigeben oder die eigene Freigabe abblasen (key = nil: verstecken).
-- 1.2.0: nur, wenn kein Stempel auf dem Foto steht (der laege auf dem Wort); sonst steht die Aktion
-- nur im Zeilenmenue. Erst nach den Stempeln rufen.
function GF.SetHuntWord(E, key)
  E.hunt.hide = nil
  if key and (E.stampNr1:IsShown() or E.stampOther:IsShown()) then key = nil end
  if not key or not GF.HasHunts() then E.hunt.key = nil; E.hunt:Hide(); return end
  E.hunt.key = key
  E.hunt.text:SetText(GF.Released(key) and L.ACT_CALLOFF or L.ACT_RELEASE)
  E.hunt:SetWidth(math.max(120, math.min(200, TextWidth(E.hunt.text, 116) + 4)))
  E.hunt:Show()
end

-- Eintragung von Hand: "Bert · 12.11. 21:04"
local function ListedLine(x) return Look.Join(Look.First(x[1]), Look.When(x[2])) end
local function ListedTip(x) return { tostring(x[1]), Fmt(L.TIP_LISTED_AT, { time = Look.When(x[2]) }) } end

-- "Gesehen vor 2 Std. von Anna" (by = wer ihn gesehen hat, darf fehlen)
function GF.SeenBy(ago, by)
  if type(by) == "string" and by ~= "" then return Fmt(L.POSTER_SEEN_BY, { time = ago, name = Look.First(by) }) end
  return Fmt(L.POSTER_SEEN, { time = ago })
end

local scratchListed = {}
UX.scratchPairs = {}

-- Gildenbuch: gleiches Plakat, Opferzahl statt Kopfgeld, Taten "Datum · Ort · Opfer".
-- Nur von Hand Eingetragene: kein Nr.-1-Stempel, "VON HAND EINGETRAGEN" statt Opferzahl, statt
-- der Taten die Eintragungen (wer, wann).
local function FillGuild(g)
  local E = P.enemy
  E.current = g
  local only = Look.ListedOnly(g)
  local rank = not only and GCall("Rank", g.key, GF.Src()) or nil
  E.doa:SetText(Spaced(L.POSTER_GUILDBOOK))
  SetPhoto(E, g)
  E.tally:SetText(only and L.TALLY_MANUAL or Fmt(L.ROW_GKILLED, { kills = Look.GKills(g.kills) }))

  local names = Look.ListedNames(g, scratchListed)
  local info, opt = wipe(scratchInfo), wipe(optInfo)
  local who = Look.Join(g.level and Fmt(L.POSTER_LEVEL, { level = g.level }), ClassName(g))
  if who ~= "" then info[#info + 1] = who end
  -- Nr. 1 und zugleich auf der Abschussliste: der Stempel zeigt Nr. 1, die Freigabe steht als Zeile (wie im eigenen Buch)
  if rank == 1 then
    local h = GF.HasHunts() and GCall("Hunt", g.key, "all")
    if type(h) == "table" then
      info[#info + 1] = Fmt(L.POSTER_ON_HUNTLIST, { names = Look.NameList(type(h.names) == "table" and h.names or {}, 2) })
    end
  end
  local listLine
  if #names > 0 then
    info[#info + 1] = Fmt(L.POSTER_IN_BOOK_OF, { names = Look.NameList(names, 2) })
    listLine = #info
  end
  local ls = type(g.lastSeen) == "table" and g.lastSeen or nil
  local ago = ls and Look.Ago(ls.t)
  if ago then
    info[#info + 1] = GF.SeenBy(ago, ls.by)
  else
    info[#info + 1] = L.POSTER_NOT_SEEN
  end
  SetInfo(E, info, opt)
  -- Tooltip mit allen Namen, wenn gekuerzt (mehr als zwei, Vornamen, oder zu breit)
  if listLine and listLine <= INFO_LINES and (#names > 2 or Truncated(E.info[listLine]) or Look.First(names[1]) ~= names[1]) then
    E.listHit.tip = { L.TIP_IN_BOOK_OF, table.concat(names, ", ") }
    E.listHit:ClearAllPoints()
    E.listHit:SetPoint("TOPLEFT", E.info[listLine], "TOPLEFT", 0, 0)
    E.listHit:Show()
  else
    E.listHit.tip = nil
    E.listHit:Hide()
  end

  if only then
    E.bountyLabel:SetText(Spaced(L.POSTER_REMARK))
    SetBounty(E, L.POSTER_BY_HAND, true)
  else
    -- 1.2.0: Zahl der Opfer ohne Rolle (Kollege oder Freund), das Etikett OPFER steht nur einmal (unten)
    E.bountyLabel:SetText("")
    SetBounty(E, Look.Count(g.victimCount, L.ROW_VICTIMS), false)
  end
  PlaceBounty(E, false)

  if only then
    -- wer ihn wann eingetragen hat, aelteste zuerst
    local list = UX.scratchPairs
    for i = #list, 1, -1 do list[i] = nil end
    for i = 1, #names do list[i] = { names[i], g.listedBy[names[i]] } end
    E.fileLabel:SetText(Spaced(L.POSTER_LISTED))
    FillLines(E, list, ListedLine, ListedTip, L.POSTER_LISTED_EMPTY)
  else
    E.fileLabel:SetText(Spaced(L.POSTER_DEEDS))
    FillLines(E, type(g.deeds) == "table" and g.deeds or {}, UX.GuildDeedLine, UX.GuildDeedTip, L.POSTER_NO_DEEDS_SENT)
  end

  -- Opfer nach Anzahl, mit Vornamen
  local list = {}
  if type(g.victims) == "table" then
    for name, n in pairs(g.victims) do list[#list + 1] = { name, tonumber(n) or 0 } end
    table.sort(list, function(a, b) if a[2] ~= b[2] then return a[2] > b[2] end return tostring(a[1]) < tostring(b[1]) end)
  end
  local parts = {}
  for i = 1, math.min(#list, 6) do parts[i] = Look.First(list[i][1]) .. " " .. Look.Times(list[i][2]) end
  E.noteLabel:SetText(Spaced(L.POSTER_VICTIMS))
  if E.note:HasFocus() then E.note:ClearFocus() end
  E.note.key = nil
  E.note:Hide()
  E.victims:SetText(#parts > 0 and table.concat(parts, ", ") or (only and L.POSTER_NONE_KNOWN or L.POSTER_NO_NAMES))
  E.victims:Show()
  if #list > 0 then
    local full = { L.TIP_VICTIMS }
    for i = 1, math.min(#list, 20) do full[#full + 1] = tostring(list[i][1]) .. " " .. Look.Times(list[i][2]) end
    E.victimsHit.tip = full
    E.victimsHit:Show()
  else
    E.victimsHit.tip = nil
    E.victimsHit:Hide()
  end

  if rank == 1 then GF.Stamp(E.stampNr1, "guild") end
  GF.ShowStamp(E.stampNr1, rank == 1)
  GF.HuntStamp(E, g.key, rank == 1)
  GF.SetHuntWord(E, g.key)
  GF.ShowStamp(E.stampRache, false)
  E.racheCount:Hide()
  E.strike.key = nil
  E.strike:Hide()

  local sig = "g\0" .. g.key .. "\0" .. (Store().Get(g.key) and "1" or "0")
  if E.specSig ~= sig then
    E.specSig = sig
    ConfigButtons(E, GuildSpec(g))
  end
end

-- Abschussliste (1.2.0): Plakat mit Freigaben (wer, wann, Grund), Erlegt-Zaehler, Stempel
function GF.HuntSpec(h)
  local key = h.key
  local second
  if Store().Get(key) then
    second = { L.ACT_OPEN_OWN, function() UI.ShowEnemy(key) end }
  else
    second = { L.ACT_ADOPT, function()
      local k = GCall("Adopt", key)
      if type(k) ~= "string" and Store().AddManual then
        k = Store().AddManual(h.name, h.surname, { fromGuild = true })
      end
      UI.Refresh()
      if type(k) == "string" and Store().Get(k) then UI.ShowEnemy(k) end
    end }
  end
  return { GF.HuntAction(key), second, GF.HideAction(key) }
end

-- 1.2.0: fremde Freigabe fuer mich ausblenden (kein Alarm, blass am Ende der Liste) bzw. zurueckholen
function GF.HideAction(key)
  if GCall("HuntHidden", key) then
    return { L.ACT_HUNT_SHOW, function() GCall("HideHunt", key, false); UI.Refresh() end }
  end
  return { L.ACT_HUNT_HIDE, function() GCall("HideHunt", key, true); UI.Refresh() end }
end

function UX.HuntLine(x) return Look.Join(Look.First(x.char), Look.When(x.t), x.why) end
function UX.HuntTip(x)
  local t = { tostring(x.char), Fmt(L.TIP_RELEASED_AT, { time = Look.When(x.t) }) }
  if type(x.why) == "string" and x.why ~= "" then t[#t + 1] = Fmt(L.HUNT_REASON, { reason = x.why }) end
  return t
end

function GF.FillHunt(h)
  local E = P.enemy
  E.current = h
  E.listHit:Hide()
  E.doa:SetText(Spaced(L.POSTER_HUNTLIST))
  SetPhoto(E, h)
  local n = tonumber(h.n) or 0
  E.tally:SetText(Fmt(L.POSTER_RELEASED_N, { times = Look.Times(n) }))
  local info, opt = wipe(scratchInfo), wipe(optInfo)
  local who = Look.Join(h.level and Fmt(L.POSTER_LEVEL, { level = h.level }), ClassName(h))
  if who ~= "" then info[#info + 1] = who end
  if type(h.why) == "string" and h.why ~= "" then info[#info + 1] = Fmt(L.HUNT_REASON, { reason = h.why }) end
  local names = type(h.names) == "table" and h.names or {}
  if #names > 0 then info[#info + 1] = Fmt(L.POSTER_RELEASED_BY, { names = Look.NameList(names, 2) }); opt[#info] = true end
  local ls = type(h.lastSeen) == "table" and h.lastSeen or nil
  local ago = ls and Look.Ago(ls.t)
  if ago then
    info[#info + 1] = GF.SeenBy(ago, ls.by)
  elseif Look.GuildSetting("sightings") == true then
    info[#info + 1] = L.POSTER_NOT_SEEN
  end
  SetInfo(E, info, opt)
  local bag = tonumber(h.bagged) or 0
  E.bountyLabel:SetText(Spaced(L.POSTER_TAKEN_DOWN))
  SetBounty(E, bag > 0 and Look.Times(bag) or L.POSTER_NOT_YET, bag <= 0)
  PlaceBounty(E, false)
  E.fileLabel:SetText(Spaced(L.POSTER_CALLS))
  FillLines(E, type(h.releases) == "table" and h.releases or {}, UX.HuntLine, UX.HuntTip, L.POSTER_NOBODY_LEFT)
  E.noteLabel:SetText(Spaced(L.POSTER_LAST))
  if E.note:HasFocus() then E.note:ClearFocus() end
  E.note.key = nil
  E.note:Hide()
  local lb = type(h.lastBagged) == "table" and h.lastBagged or nil
  E.victims:SetText(lb and Fmt(L.POSTER_TAKEN_BY, { name = Look.First(lb.by), time = Look.Ago(lb.t) }) or L.POSTER_TAKEN_NOBODY)
  E.victims:Show()
  E.victimsHit.tip = nil
  E.victimsHit:Hide()
  GF.ShowStamp(E.stampNr1, false)
  GF.Stamp(E.stampOther, "hunt")
  GF.ShowStamp(E.stampOther, true)
  GF.ShowStamp(E.stampRache, false)
  E.racheCount:Hide()
  E.strike.key = nil
  E.strike:Hide()
  -- 1.2.0: kein Wort unter dem Foto (der Stempel ZUR JAGD FREIGEGEBEN laege darauf); "Für mich
  -- ausblenden" steht im Zeilenmenue
  E.hunt.key, E.hunt.hide = nil, nil
  E.hunt:Hide()
  local sig = "h\0" .. h.key .. "\0" .. (Store().Get(h.key) and "1" or "0") .. (GF.Released(h.key) and "1" or "0")
    .. (h.hidden and "1" or "0")
  if E.specSig ~= sig then
    E.specSig = sig
    ConfigButtons(E, GF.HuntSpec(h))
  end
end

-- Mittaeter eines Todes: aus der Tat beim Taeter (others), sonst die Kandidaten ohne den Taeter
local assistScratch = {}
function UX.AssistsOf(d)
  local out = wipe(assistScratch)
  local e = d.killerKey and Store().Get(d.killerKey)
  if e and type(e.deaths) == "table" then
    for i = 1, #e.deaths do
      local x = e.deaths[i]
      if x.t == d.t and type(x.others) == "table" then
        for k = 1, #x.others do out[#out + 1] = x.others[k] end
        return out
      end
    end
  end
  if type(d.candidates) == "table" then
    for i = 1, #d.candidates do if d.candidates[i] ~= d.killerKey then out[#out + 1] = d.candidates[i] end end
  end
  return out
end

local function FillDeath(d, index)
  local D = P.death
  D.when:SetText(Look.When(d.t))
  local place = PlaceText(d.zone, d.subzone)
  if type(d.x) == "number" and type(d.y) == "number" then
    place = place .. (" (%d, %d)"):format(math.floor(d.x + 0.5), math.floor(d.y + 0.5))
  end
  local info = { place }
  if d.me then info[#info + 1] = GF.VictimLine(d.me, d.myLevel) end
  if d.spell and d.spell ~= "" then info[#info + 1] = Fmt(L.TIP_CAUSE, { spell = tostring(d.spell) }) end
  if d.counted == false then info[#info + 1] = L.CASE_NOT_COUNTED end
  D.info:SetText(table.concat(info, "\n"))

  D.killer.key = nil
  local cands = (type(d.candidates) == "table") and d.candidates or {}
  if d.kind == "pvp" and d.killerKey then
    D.killLabel:SetText(Spaced(d.sure == false and L.CASE_KILLER_SUSPECT or L.CASE_KILLER))
    local name, e = NameOfKey(d.killerKey, d.killerName)
    D.killer.text:SetText(name)
    D.killer.key = e and d.killerKey or nil
    D.note:SetText(e and L.CASE_CLICK_NAME or L.CASE_GONE)
  elseif d.kind == "pvp" then
    D.killLabel:SetText(Spaced(L.CASE_KILLER_UNCLEAR))
    D.killer.text:SetText("?")
    D.note:SetText(#cands > 0 and L.CASE_SEVERAL or L.CASE_NOBODY)
  elseif d.kind == "pve" then
    D.killLabel:SetText(Spaced(L.CASE_HOW))
    D.killer.text:SetText(L.ROW_NO_PLAYER)
    D.note:SetText(L.CASE_PVE)
  else
    D.killLabel:SetText(Spaced(L.CASE_HOW))
    D.killer.text:SetText(L.CASE_UNCLEAR)
    D.note:SetText(L.CASE_DARK)
  end

  -- Taeter festlegen (offen oder nur Verdacht), sonst die Beteiligten
  local showC = (d.kind == "pvp") and d.sure ~= true and #cands > 0 and Store().AssignDeath ~= nil
  D.candLabel:SetShown(showC)
  local nc = showC and #cands or 0
  for i = 1, GF.CAND_MAX do
    local b, key = D.cands[i], showC and cands[i]
    b.tip = nil
    if i == GF.CAND_MAX and nc > GF.CAND_MAX then
      -- mehr Kandidaten als Knoepfe: der letzte nennt den Rest im Tooltip
      local rest = { L.TIP_MORE_CANDIDATES }
      for k = GF.CAND_MAX, nc do rest[#rest + 1] = (NameOfKey(cands[k])) end
      b:SetLabel(Fmt(L.MORE_LINE, { count = nc - GF.CAND_MAX + 1 }))
      b.fn = nil
      b.tip = rest
      b:Show()
    elseif key then
      b:SetLabel((NameOfKey(key)))
      -- Position erst beim Klick suchen: ein neuer Tod dazwischen verschiebt das Journal
      b.fn = function()
        local list = Store().Deaths() or {}
        local at = index
        for k = 1, #list do if list[k] == d then at = k; break end end
        Store().AssignDeath(at, key)
      end
      b:Show()
    else
      b:Hide()
    end
  end
  local assists = (not showC and d.kind == "pvp" and d.killerKey) and UX.AssistsOf(d) or assistScratch
  if showC or not (d.kind == "pvp" and d.killerKey) then wipe(assistScratch) end
  local na = #assists
  D.assistLabel:SetShown(na > 0)
  for i = 1, GF.ASSIST_MAX do
    local b, key = D.assists[i], assists[i]
    if i == GF.ASSIST_MAX and na > GF.ASSIST_MAX then
      b.text:SetText(Fmt(L.MORE_LINE, { count = na - GF.ASSIST_MAX + 1 }))
      b.key = nil
      b:Show()
    elseif key then
      local name, e = NameOfKey(key)
      b.text:SetText(name)
      b.key = e and key or nil
      b:Show()
    else
      b.key = nil
      b:Hide()
    end
  end
  -- nur bei Verdacht steht dabei, worauf er beruht
  D.source:SetText(d.source == "suspect" and L.CASE_SOURCE_SUSPECT or "")
end

-- Journal, Zu klaeren und Gilde: Enter sucht nur, traegt nie ein
local function SearchOnly() return state.filter ~= "wanted" end

local function EmptyKind()
  if state.query ~= "" then return SearchOnly() and "searchro" or "search" end
  if state.filter == "guild" then
    local src = GF.Src()
    if src == "guild" then
      if not GCall("Name") then return "noguild" end
      if GCall("Enabled") == false then return "guildoff" end
      if GF.HuntView() then return "hunt" end
      if MemberCount() == 0 then return "guildnil" end
      return "guildquiet"
    elseif src == "friends" then
      if not GF.FriendsOn() then return "friendsoff" end
      if GF.HuntView() then return "hunt" end
      if MemberCount() == 0 then return "friendsnil" end
      return "friendsquiet"
    end
    local g = GCall("Name") ~= nil and GCall("Enabled") ~= false
    if not g and (not GF.FriendsOn() or GF.nobody) then return "nobody" end
    if GF.HuntView() then return "hunt" end
    if MemberCount() == 0 then return "sharednil" end
    return "sharedquiet"
  end
  return state.filter
end

-- Karteikarte (Akte) oder Plakat: Reisszwecke nur am Plakat, Klebestreifen an der Karte
local function PosterMode(card)
  P.pin:SetShown(not card)
  if card and P.dnPin then P.dnPin:Hide() end
  P.card:SetShown(card)
end

function UX.ShowCaseOrEnemy(item, index)
  if IsCase(item) then
    PosterMode(true)
    FillDeath(item, index)
    P.death:Show()
  else
    PosterMode(false)
    FillEnemy(item)
    P.enemy:Show()
  end
end

-- true, wenn ShowRight eine Auswahl erst setzen musste (dann die Zeilen einmal nachziehen)
local picked = false
ShowRight = function()
  if state.panel then return end
  local n = #data
  P.enemy:Hide(); P.death:Hide(); RP.empty:Hide()
  P:Show()
  if n == 0 then
    ShowEmpty(EmptyKind())
  elseif state.filter == "journal" then
    -- Auswahl ist der Eintrag selbst; die Position folgt ihm, wenn neue Tode davor rutschen
    local pos
    if state.deathRef then
      for i = 1, n do if data[i] == state.deathRef then pos = i; break end end
    end
    if not pos and not state.deathRef then
      for i = 1, n do if ((dataIdx and dataIdx[i]) or i) == state.death then pos = i; break end end
    end
    if not pos then pos = 1 end
    picked = picked or state.death ~= ((dataIdx and dataIdx[pos]) or pos)
    state.death = (dataIdx and dataIdx[pos]) or pos
    state.deathRef = data[pos]
    PosterMode(true)
    FillDeath(data[pos], state.death)
    P.death:Show()
  elseif state.filter == "open" then
    local item
    for i = 1, n do
      local x = data[i]
      if x == state.osel or (not IsCase(x) and x.key == state.osel) then item = x; break end
    end
    if not item then item = data[1]; state.osel = IsCase(item) and item or item.key; picked = true end
    local index
    if IsCase(item) then
      local list = Store().Deaths() or {}
      for k = 1, #list do if list[k] == item then index = k; break end end
    end
    UX.ShowCaseOrEnemy(item, index or 1)
  elseif MemberView() then
    -- gewaehlte Kindzeile (im selben Abschnitt), sonst derselbe Taeter woanders, sonst der erste
    local g, first
    for i = 1, n do
      local w = data[i]
      if not w.head then
        first = first or w
        if w.r.key == state.gselected and (not g or w.m.name == state.gmember) then g = w end
      end
    end
    local entry
    if g then
      entry = g.r.entry or GCall("Get", g.r.key)
    elseif state.gselected then
      entry = GCall("Get", state.gselected)
    end
    if not entry then
      local w = first
      if not w then
        -- alles zugeklappt: erster Taeter des ersten Abschnitts
        for i = 1, n do
          local m = data[i].m
          local r1 = type(m.rows) == "table" and m.rows[1]
          if r1 then w = { r = r1, m = m }; break end
        end
      end
      if w then
        entry = w.r.entry or GCall("Get", w.r.key)
        state.gselected, state.gmember = w.r.key, w.m.name
        picked = true
      end
    end
    if entry then
      PosterMode(false)
      FillGuild(entry)
      P.enemy:Show()
    else
      ShowEmpty(EmptyKind())
    end
  elseif GF.HuntView() then
    local h
    for i = 1, n do if data[i].key == state.hselected then h = data[i]; break end end
    if not h then h = data[1]; state.hselected = h.key; picked = true end
    PosterMode(false)
    GF.FillHunt(h)
    P.enemy:Show()
  elseif state.filter == "guild" then
    local g
    for i = 1, n do if data[i].key == state.gselected then g = data[i]; break end end
    if not g then g = data[1]; state.gselected = g.key; picked = true end
    PosterMode(false)
    FillGuild(g)
    P.enemy:Show()
  else
    local e
    for i = 1, n do if data[i].key == state.selected then e = data[i]; break end end
    if not e then e = data[1]; state.selected = e.key; picked = true end
    PosterMode(false)
    FillEnemy(e)
    P.enemy:Show()
  end
end

------------------------------------------------------------------------
-- Groesse des Buchs: nie groesser als der Schirm, nie kleiner als lesbar
------------------------------------------------------------------------
-- Bildpunkte je UI-Einheit (nil, wenn der Client es nicht verraet)
local function PxPerUnit()
  if not GetPhysicalScreenSize then return nil end
  local ok, _, ph = pcall(GetPhysicalScreenSize)
  local uh = UIParent:GetHeight()
  if not ok or type(ph) ~= "number" or type(uh) ~= "number" or Look.Secret(ph) or Look.Secret(uh) or uh <= 0 then return nil end
  return ph / uh
end

-- groesste Stufe, bei der das Buch (mit Rand) noch auf den Schirm passt
function UX.MaxScale()
  local w, h = UIParent:GetWidth(), UIParent:GetHeight()
  if type(w) ~= "number" or type(h) ~= "number" or Look.Secret(w) or Look.Secret(h) or w <= 0 or h <= 0 then return 1.5 end
  return math.min(1.5, h / (H + 12), w / (W + 20))
end

-- angebotene Stufen: passen auf den Schirm; unter 100 % nur, wenn eine Einheit dann noch 1,4 px hat
local scaleSteps = {}
function UI.ScaleSteps()
  for i = #scaleSteps, 1, -1 do scaleSteps[i] = nil end
  local max, ppu = UX.MaxScale(), PxPerUnit()
  for _, s in ipairs(Look.SCALES) do
    if s <= max + 0.001 and (s >= 1 or not ppu or ppu * s >= 1.4) then scaleSteps[#scaleSteps + 1] = s end
  end
  if #scaleSteps == 0 then scaleSteps[1] = math.min(1, max) end
  return scaleSteps
end

local function ClampScale(s)
  local steps = UI.ScaleSteps()
  local best = steps[1]
  for i = 1, #steps do if steps[i] <= s + 0.001 then best = steps[i] end end
  return best
end

local function ApplyScale()
  if F then F:SetScale(ClampScale(tonumber(Look.Setting("ui.scale", 1)) or 1)) end
end

-- einmalig: ohne eigene Wahl die kleinste Stufe ab 100 %, bei der eine Einheit 1,4 px hat
function UX.AutoScale()
  if Look.Setting("ui.autoScale") == true then return end
  local cur = tonumber(Look.Setting("ui.scale", 1)) or 1
  local ppu = PxPerUnit()
  if cur == 1 and ppu then
    local steps, pick = UI.ScaleSteps(), nil
    for i = 1, #steps do
      if not pick and steps[i] >= 1 and ppu * steps[i] >= 1.4 then pick = steps[i] end
    end
    pick = pick or steps[#steps]
    if pick and pick ~= cur then Set("ui.scale", pick) end
  elseif cur ~= ClampScale(cur) then
    Set("ui.scale", ClampScale(cur))
  end
  Set("ui.autoScale", true)
end

------------------------------------------------------------------------
-- Hausordnung (Blaetter Buch, Alarm, Gilde), Gebrauchsanweisung, Sichern/Einlesen
------------------------------------------------------------------------
local SyncClick, MembersTip, BuildSettings, BuildHelp -- im Block unten belegt
do
local BOOK_OPTIONS = {
  { "tooltip",         "OPT_TOOLTIP", true },
  { "ui.minimap.hide", "OPT_MINIMAP", false, invert = true },
}
local ALERT_OPTIONS = {
  { "alert.enabled",   "OPT_ALERT", true },
  { "alert.flash",     "OPT_FLASH", true },
  { "alert.suspects",  "OPT_SUSPECTS", false },
  { "deathMessage",    "OPT_DEATHMSG", true },
}
local GUILD_OPTIONS = {
  { "share",       "OPT_G_SHARE" },
  { "shareManual", "OPT_G_SHAREMANUAL" },
  { "receive",     "OPT_G_RECEIVE" },
  { "alert",       "OPT_G_ALERT" },
  { "alertListed", "OPT_G_ALERTLISTED" },
  { "announce",    "OPT_G_ANNOUNCE" },
  { "sightings",   "OPT_G_SIGHTINGS" },
}
-- 1.2.0 mit Freundesbuch: Teilen mit Freunden, Alarm der Abschussliste; die Schalter fuer Alarm, Meldung und
-- Sichtungen gelten fuer Gilde und Freunde und heissen so.
-- 1.2.0: zwei ruhige Gruppen TEILEN und WARNEN mit den fuenf Haken, die ein Spieler braucht; alles andere
-- (Hand-Eintraege, Empfangen, Meldungen, Schwelle, Verfall, Stand, Leeren) hinter "Mehr" auf einer zweiten
-- Seite des Blatts. Raster 24 px wie 1.1.0. Keine Einstellung geht verloren, keine aendert ihren Wert.
GF.FRIEND_SHARE = {
  { "share",       "OPT_F_SHARE" },
  { "friends",     "OPT_F_FRIENDS" },
  { "sightings",   "OPT_F_SIGHTINGS" },
}
GF.FRIEND_WARN = {
  { "alert",       "OPT_F_ALERT" },
  { "alertHunt",   "OPT_F_ALERTHUNT" },
}
GF.MORE_SHARE = {
  { "shareManual", "OPT_G_SHAREMANUAL" },
  { "receive",     "OPT_G_RECEIVE" },
}
GF.MORE_WARN = {
  { "alertListed", "OPT_G_ALERTLISTED" },
  { "announce",    "OPT_F_ANNOUNCE" },
  { "announceHunt", "OPT_F_ANNOUNCEHUNT" },   -- 1.2.0 fix: Meldung erlegt / neue Ziele hatte keinen Schalter
}
local SHEETS = { "SHEET_BOOK", "SHEET_ALERT", "SHEET_GUILD" }   -- Schluessel
GF.SYNC_MIN, GF.SYNC_MAX = 84, 150   -- Abgleichen-Knopf: waechst mit dem Text (1.2.0)
GF.COOLDOWNS = { 30, 60, 90, 120, 180, 300, 600 }
local ROW_Y0, OPT_H = -84, 24

local function Step(list, cur, dir)
  local idx = 1
  for i = 1, #list do if list[i] <= (cur or list[1]) + 0.001 then idx = i end end
  idx = math.max(1, math.min(#list, idx + dir))
  return list[idx]
end

local function PageLayer(parent)
  local f = CreateFrame("Frame", nil, parent)
  f:SetAllPoints()
  f:EnableMouse(true)
  f:Hide()
  local bg = Tex(f, "BACKGROUND", Look.TEX.page)
  bg:SetAllPoints()
  return f
end

local function SheetHead(parent, text)
  local head = Look.Text(parent, "hand", 26, Look.INK)
  head:SetPoint("TOP", 0, -16)
  head:SetText(text)
  Rule(parent, -50, 30, 30, 0.6)
  return head
end

-- Pfeil zum Weiterschalten: kleines Tinten-Dreieck, Klickflaeche 22x20, Hover rot
local function Arrow(parent, dir, onClick)
  local b = CreateFrame("Button", nil, parent)
  b:SetSize(22, 20)
  b.tri = Tri(b, 12, dir < 0 and math.pi or 0)
  b.tri:SetPoint("CENTER", 0, 0)
  b:SetScript("OnEnter", function(self) if not self.off then self.tri:SetVertexColor(C(Look.RED)) end end)
  b:SetScript("OnLeave", function(self) self.tri:SetVertexColor(C(Look.INK, self.off and TONE.off or 0.9)) end)
  b:SetScript("OnClick", function(self) if self.off then return end Look.Sound("click"); onClick() end)
  return b
end

-- Zeile "Beschriftung      ◂ Wert ▸": Wert in Handschrift, unterstrichen; vw = Breite des Werts
local function Stepper(parent, y, label, onStep, vw)
  vw = vw or 56
  local x = 348 - 44 - vw
  local l = Look.Text(parent, "body", 11, Look.INK)
  l:SetPoint("TOPLEFT", 34, y - 4)
  l:SetWidth(x - 42)
  l:SetJustifyH("LEFT")
  l:SetWordWrap(false)
  l:SetText(label)
  local function go(d) onStep(d); UI.FillSettings() end
  local minus = Arrow(parent, -1, function() go(-1) end)
  minus:SetPoint("TOPLEFT", x, y)
  local v = Look.Text(parent, "hand", 16, Look.INK)
  v:SetPoint("LEFT", minus, "RIGHT", 0, 0)
  v:SetWidth(vw)
  v:SetJustifyH("CENTER")
  v:SetWordWrap(false)
  local ul = parent:CreateTexture(nil, "ARTWORK")
  ul:SetColorTexture(C(Look.INK, 0.45))
  ul:SetHeight(1)
  ul:SetPoint("TOPLEFT", minus, "BOTTOMRIGHT", 4, 1)
  ul:SetWidth(vw - 8)
  local plus = Arrow(parent, 1, function() go(1) end)
  plus:SetPoint("LEFT", v, "RIGHT", 0, 0)
  v.label, v.minus, v.plus, v.ul = l, minus, plus, ul
  return v
end

-- Reihe ausgrauen (Beschriftung, Wert, Pfeile); ausgegraute Pfeile tun nichts
local function Dim(v, off)
  local a = off and TONE.off or TONE.ink
  v.label:SetTextColor(C(Look.INK, a)); v:SetTextColor(C(Look.INK, a))
  for _, b in ipairs({ v.minus, v.plus }) do
    b.off = off and true or false
    b.tri:SetVertexColor(C(Look.INK, off and TONE.off or 0.9))
  end
end

local function Preview() if Look.Alarm then Look.Alarm("preview") end end

local function Percent(v) return math.floor((tonumber(v) or 1) * 100 + 0.5) .. " %" end

-- "Abgleichen": beschriftet sich nach dem Klick aus dem Teilen-Zustand
SyncClick = function(b)
  local h = Look.GuildHealth(GF.HasFriends() and GF.Src() or nil)
  local ok, why = GCall("SyncNow")
  -- 1.2.0: Freunde gleich mit
  if GF.HasFriends() and type(ns.Friends.SyncNow) == "function" then
    local fok, fok2, fwhy = pcall(ns.Friends.SyncNow)
    if fok and fok2 then ok, why = true, nil elseif fok and ok == false and tonumber(fwhy) then why = fwhy end
  end
  if ok == false and tonumber(why) then
    b:SetLabel(Fmt(L.SYNC_AGAIN_IN, { seconds = tonumber(why) }))
  elseif ok == false or not h.ok then
    b:SetLabel(h.short or L.HEALTH_SHORT_FAIL)
  else
    b:SetLabel(L.HEALTH_SHORT_ASKED)
  end
  if b.resetTimer then b.resetTimer:Cancel() end
  b.resetTimer = C_Timer.NewTimer(3, function() b.resetTimer = nil; b:SetLabel(L.SYNC_BUTTON) end)
end

-- Kollegen mit DeathNote, darunter, was geteilt wird und was nicht
MembersTip = function(owner)
  local name = GCall("Name")
  GameTooltip:SetOwner(owner, "ANCHOR_TOP")
  if GF.Src() == "friends" then
    GameTooltip:SetText(L.TIP_FRIENDS, Look.BONE[1], Look.BONE[2], Look.BONE[3])
  else
    GameTooltip:SetText(name and Fmt(L.TIP_GUILD_NAME, { guild = name }) or L.HEALTH_SHORT_NOGUILD, Look.BONE[1], Look.BONE[2], Look.BONE[3])
  end
  -- 1.2.0: der Stand steht schon in der Zeile darunter; der Tooltip wiederholt ihn nicht
  local src = GF.Src()
  local function list(members, head, none)
    if type(members) == "table" and #members > 0 then
      GameTooltip:AddLine(head, 0.82, 0.80, 0.75)
      for i = 1, math.min(#members, 20) do
        local m = members[i]
        local ago = m.lastHeard and Look.Ago(m.lastHeard) or ""
        GameTooltip:AddDoubleLine(tostring(m.name or "?") .. (m.version and ("  " .. tostring(m.version)) or ""), ago,
                                  1, 1, 1, 0.7, 0.7, 0.7)
      end
      if #members > 20 then GameTooltip:AddLine(Fmt(L.MORE_LINE, { count = #members - 20 }), 0.7, 0.7, 0.7) end
    else
      GameTooltip:AddLine(none, 0.82, 0.80, 0.75)
    end
  end
  if src ~= "friends" then list(GCall("Members"), L.TIP_MATES_WITH, L.TIP_NO_MATE) end
  if src ~= "guild" and GF.HasFriends() then
    list(GCall("Members", "friends"), L.TIP_FRIENDS_WITH, L.EMPTY_FRIENDSNIL_HEAD)
  end
  GameTooltip:AddLine(L.TIP_SHARED, 0.7, 0.7, 0.7, true)
  GameTooltip:AddLine(L.TIP_NOT_SHARED, 0.7, 0.7, 0.7, true)
  GameTooltip:Show()
end

BuildSettings = function()
  local S = PageLayer(RP)
  RP.settings = S
  SheetHead(S, L.HEAD_RULES)

  -- Blaetter: Buch | Alarm | Gilde (das dritte nur, wenn es die Gildenfunktion gibt)
  S.tabs = {}
  -- 1.2.0: Breite aus dem Wort (mindestens 70 px wie 1.1.0), 28 px Abstand
  local prevTab
  for i, key in ipairs(SHEETS) do
    local t = WordTab(S, L[key], 70, function(self) state.spage = self.page; UI.FillSettings() end)
    t:SetWidth(math.max(70, math.min(96, TextWidth(t.text, 60) + 6)))
    if prevTab then t:SetPoint("LEFT", prevTab, "RIGHT", 28, 0) else t:SetPoint("TOPLEFT", 30, -56) end
    prevTab = t
    t.page = i
    S.tabs[i] = t
  end

  local function onCheck(self)
    local on = self:GetChecked() and true or false
    self.cross:SetShown(on)
    if self.opt.invert then on = not on end
    Set(self.opt.path, on)
    Look.Sound("click")
  end
  S.checks = {}
  local function checks(page, list, prefix, y0, step)
    y0 = y0 or ROW_Y0
    step = step or OPT_H
    for i, o in ipairs(list) do
      local cb = UX.InkCheck(page, o.text or L[o[2]], 310) -- Humor: o.text (Schalter ohne Sprachschluessel)
      cb:SetPoint("TOPLEFT", 30, y0 - (i - 1) * step)
      cb.label:SetWidth(280)
      cb.label:SetJustifyH("LEFT")
      cb.label:SetWordWrap(false)
      if prefix then cb.opt = { path = prefix .. o[1], guild = o[1] }
      else cb.opt = { path = o[1], def = o[3], invert = o.invert } end
      cb:SetScript("OnClick", onCheck)
      S.checks[#S.checks + 1] = cb
    end
    return y0 - #list * step - 4
  end
  local function section(page, y, text)
    local l = Label(page, text)
    l:SetPoint("TOPLEFT", 34, y - 6)
    return y - 22
  end
  local function hint(page, text)
    local h = Look.Text(page, "type", 11, Look.INK)
    h:SetTextColor(C(Look.INK, TONE.hint))
    h:SetPoint("BOTTOMLEFT", 30, 44)
    h:SetPoint("RIGHT", page, "RIGHT", -30, 0)
    h:SetJustifyH("LEFT")
    h:SetText(text or "")
    return h
  end

  -- Blatt 1: Buch (Anzeige, Groesse, Weitergeben)
  local A = CreateFrame("Frame", nil, S)
  A:SetAllPoints()
  S.pageA = A
  local y = checks(A, ns.Humor and ns.Humor.BookOptions(BOOK_OPTIONS) or BOOK_OPTIONS) -- Humor: Schalter, nur de/en
  S.size = Stepper(A, y, L.SET_BOOK_SIZE, function(d)
    local steps = UI.ScaleSteps()
    Set("ui.scale", Step(steps, ClampScale(tonumber(Look.Setting("ui.scale", 1)) or 1), d))
  end)
  -- 1.2.0: Sprache des Buchs (wirkt nach /reload)
  if ns.Locale and ns.Locale.CODES then
    y = y - OPT_H
    S.lang = Stepper(A, y, L.SET_LANGUAGE, function(d) GF.StepLanguage(d) end, 150)
    y = y - OPT_H
    S.langHint = Look.Text(A, "type", 11, Look.INK)
    S.langHint:SetTextColor(C(Look.INK, TONE.hint))
    S.langHint:SetPoint("TOPLEFT", 34, y - 6)
    S.langHint:SetWidth(170)
    S.langHint:SetJustifyH("LEFT")
    S.langHint:SetWordWrap(false)
    S.langHint:SetText(L.SET_LANG_RELOAD_HINT)
    S.reload = InkButton(A, L.SET_LANG_RELOAD, 132, 22, function()
      if InCombatLockdown and InCombatLockdown() then return end
      if ReloadUI then ReloadUI() end
    end)
    S.reload:SetPoint("TOPLEFT", 214, y - 2)
  end
  y = y - OPT_H - 6
  y = section(A, y, L.SET_SEC_SHARE)
  local exp = InkButton(A, L.IO_EXPORT, 104, 22, function() UI.OpenIO("export") end)
  exp:SetPoint("TOPLEFT", 30, y - 4)
  local imp = InkButton(A, L.IO_IMPORT, 104, 22, function() UI.OpenIO("import") end)
  imp:SetPoint("LEFT", exp, "RIGHT", 8, 0)
  S.ioButtons = { exp, imp }
  hint(A, L.SET_HINT_BOOK)

  -- Blatt 2: Alarm mit Ton, Lautstaerke und Kanal
  local AL = CreateFrame("Frame", nil, S)
  AL:SetAllPoints()
  AL:Hide()
  S.pageL = AL
  y = checks(AL, ALERT_OPTIONS)
  y = section(AL, y, L.SET_SEC_SOUND)
  S.tone = Stepper(AL, y, L.SET_SOUND, function(d)
    local n = #Look.SOUNDS
    local cur = Look.SoundChoice()
    local idx = 1
    for i, x in ipairs(Look.SOUNDS) do if x.key == cur.key then idx = i end end
    local nxt = Look.SOUNDS[(idx - 1 + d) % n + 1]
    Look.SetSound(nxt.key)
    Preview()
  end, 132)
  y = y - OPT_H
  S.vol = Stepper(AL, y, L.SET_VOLUME, function(d)
    local v = tonumber(Look.Setting("alert.volume", 3)) or 3
    local nv = math.max(1, math.min(Look.VOLUMES, math.floor(v) + d))
    if nv ~= v then Set("alert.volume", nv) end
    Preview()
  end, 120)
  -- Pegel als fuenf Tintenbalken statt Zahl
  S.vol.bars = {}
  for i = 1, Look.VOLUMES do
    local t = AL:CreateTexture(nil, "ARTWORK")
    t:SetSize(9, 12)
    t:SetPoint("LEFT", S.vol.minus, "RIGHT", 32 + (i - 1) * 12, 0)
    t:SetColorTexture(C(Look.INK, 0.85))
    S.vol.bars[i] = t
  end
  y = y - OPT_H
  -- Kanal: drei Woerter, das aktive rot unterstrichen
  local kl = Look.Text(AL, "body", 11, Look.INK)
  kl:SetPoint("TOPLEFT", 34, y - 4)
  kl:SetText(L.SET_CHANNEL)
  S.chan = { label = kl }
  -- 1.2.0: Wortbreite aus dem Text (mindestens 52 px); wie 1.1.0 ab x = 176, rueckt bei langen Woertern nach links
  local total = 0
  for i, ch in ipairs(Look.CHANNELS) do
    local b = WordTab(AL, ch.label or L[ch.lkey], 52, function(self)
      if self.off then return end
      Set("alert.channel", self.channel)
      UI.FillSettings()
      Preview()
    end)
    b:SetWidth(math.max(52, TextWidth(b.text, 48) + 6))
    total = total + b:GetWidth() + (i > 1 and 6 or 0)
    b.channel = ch.key
    S.chan[i] = b
  end
  local cx = math.max(34 + TextWidth(kl, 40) + 12, math.min(176, 348 - total))
  for i, b in ipairs(S.chan) do
    if i == 1 then b:SetPoint("TOPLEFT", cx, y) else b:SetPoint("LEFT", S.chan[i - 1], "RIGHT", 6, 0) end
  end
  y = y - OPT_H
  y = section(AL, y, L.SET_SEC_THRESHOLD)
  S.cd = Stepper(AL, y, L.SET_COOLDOWN, function(d)
    Set("alert.cooldown", Step(GF.COOLDOWNS, Look.Setting("alert.cooldown", 90), d))
  end)
  y = y - OPT_H
  S.mk = Stepper(AL, y, L.SET_MINKILLS, function(d)
    local v = tonumber(Look.Setting("alert.minKills", 1)) or 1
    Set("alert.minKills", math.max(1, math.min(20, v + d)))
  end)
  y = y - OPT_H
  S.asize = Stepper(AL, y, L.SET_ALERT_SIZE, function(d)
    Set("alert.scale", Step(Look.SCALES, tonumber(Look.Setting("alert.scale", 1)) or 1, d))
  end)
  y = y - OPT_H - 6
  local test = InkButton(AL, L.SET_TEST_ALERT, 104, 22, function() ns:Fire("TEST_ALERT") end)
  test:SetPoint("TOPLEFT", 30, y - 4)
  S.soundHint = hint(AL, "")

  -- Blatt 3: Gilde
  local B = CreateFrame("Frame", nil, S)
  B:SetAllPoints()
  B:Hide()
  S.pageB = B
  -- 1.2.0: mit Freunden Stand in je einer Zeile (voller Satz im Tooltip und auf der linken Seite), darunter
  -- Gildenbuch und Freundesbuch leeren. 1.2.0: Seite 1 (B1) TEILEN und WARNEN, Seite 2 (B2) "Mehr".
  local friendsSheet = GF.HasFriends()
  local B2 = B
  local function expireRow(page, yy)
    -- Freigaben verfallen nach Nie, 30, 90, 180 Tagen (Voreinstellung Nie)
    S.hexp = Stepper(page, yy, L.SET_HUNT_EXPIRE, function(d)
      local days = (ns.Guild and ns.Guild.C and ns.Guild.C.EXPIRE_DAYS) or { 0, 30, 90, 180 }
      Set("guild.huntExpire", Step(days, tonumber(Look.GuildSetting("huntExpire")) or 0, d))
    end, 84)
    return yy - OPT_H - 4
  end
  local function minKillsRow(page, yy, label)
    S.gmk = Stepper(page, yy, label, function(d)
      local v = tonumber(Look.GuildSetting("minKills")) or 1
      Set("guild.minKills", math.max(1, math.min(20, v + d)))
    end)
    return yy - OPT_H
  end
  if friendsSheet then
    local B1 = CreateFrame("Frame", nil, B)
    B1:SetAllPoints()
    B2 = CreateFrame("Frame", nil, B)
    B2:SetAllPoints()
    B2:Hide()
    S.pageB1, S.pageB2 = B1, B2
    y = section(B1, ROW_Y0 + 6, L.SET_SEC_SHARING)
    y = checks(B1, GF.FRIEND_SHARE, "guild.", y)
    y = section(B1, y - 6, L.SET_SEC_WARN)
    checks(B1, GF.FRIEND_WARN, "guild.", y)
    y = section(B2, ROW_Y0 + 6, L.SET_SEC_SHARING)
    y = checks(B2, GF.MORE_SHARE, "guild.", y)
    y = expireRow(B2, y)
    y = section(B2, y - 6, L.SET_SEC_WARN)
    y = checks(B2, GF.MORE_WARN, "guild.", y)
    y = minKillsRow(B2, y, L.SET_F_MINKILLS) - 10
    -- "Mehr": Wort unten rechts auf beiden Seiten, unterstrichen, solange die zweite Seite offen ist
    S.gmore = WordTab(B, L.SET_MORE, 50, function()
      Set("ui.guildMore", Look.Setting("ui.guildMore", false) ~= true)
      UI.FillSettings()
    end)
    S.gmore:SetSize(math.max(50, math.min(110, TextWidth(S.gmore.text, 46) + 6)), 20)
    S.gmore:SetPoint("BOTTOMRIGHT", -30, 13)
  else
    y = checks(B, GUILD_OPTIONS, "guild.")
    y = minKillsRow(B, y, L.SET_G_MINKILLS)
    y = expireRow(B, y)
  end
  y = section(B2, y, L.SET_SEC_STATUS)
  local function statusLine(anchorY, prev)
    local fs = Look.Text(B2, "body", 11, Look.INK)
    if prev then fs:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -3) else fs:SetPoint("TOPLEFT", 34, anchorY) end
    fs:SetWidth(312)
    fs:SetJustifyH("LEFT")
    fs:SetMaxLines(friendsSheet and 1 or 2)
    if friendsSheet then fs:SetWordWrap(false) end
    -- gekuerzter Satz: ganz im Tooltip
    local hit = CreateFrame("Button", nil, B2)
    hit:SetAllPoints(fs)
    hit:SetScript("OnEnter", function(self) if Truncated(fs) then Tip(self, { fs:GetText() or "" }) end end)
    hit:SetScript("OnLeave", GameTooltip_Hide)
    return fs
  end
  S.gstatus = statusLine(y - 2)
  local clearY = y - 36
  if friendsSheet then
    -- zweite Zeile: Stand bei den Freunden (eigener Satz wie bei der Gilde)
    S.fstatus = statusLine(nil, S.gstatus)
    clearY = y - 38
  end
  local clear = InkButton(B2, L.SET_GUILD_CLEAR, 132, 22, function() Confirm("DEATHNOTE_GUILD_CLEAR") end)
  clear:SetPoint("TOPLEFT", 30, clearY)
  if friendsSheet then
    -- 1.2.0: das Gegenstueck fuer das Freundesbuch (leert auch dessen Abschussliste, eigene Freigaben bleiben)
    local fclear = InkButton(B2, L.SET_FRIENDS_CLEAR, 132, 22, function() Confirm("DEATHNOTE_FRIENDS_CLEAR") end)
    fclear:SetPoint("TOPLEFT", 30 + 132 + 10, clearY)
    S.fclear = fclear
  end
  hint(B, friendsSheet and L.SET_HINT_FRIENDS or L.SET_HINT_GUILD)

  local back = InkButton(S, L.BTN_BACK, 104, 22, function() UI.ClosePanel() end)
  back:SetPoint("BOTTOM", 0, 12)

  -- Sichern/Einlesen
  local IO = PageLayer(RP)
  RP.io = IO
  IO.head = SheetHead(IO, "")
  IO.help = Look.Text(IO, "type", 11, Look.INK)
  IO.help:SetTextColor(C(Look.INK, TONE.hint))
  IO.help:SetPoint("TOP", 0, -58)
  IO.help:SetWidth(330)
  local box = CreateFrame("Frame", nil, IO, "BackdropTemplate")
  box:SetPoint("TOPLEFT", 20, -88)
  box:SetPoint("BOTTOMRIGHT", -20, 70)
  box:SetBackdrop({ bgFile = Look.TEX.white, edgeFile = Look.TEX.white, edgeSize = 1 })
  box:SetBackdropColor(1, 0.98, 0.92, 0.5)
  box:SetBackdropBorderColor(C(Look.INK, 0.6))
  local sf = CreateFrame("ScrollFrame", nil, box, "UIPanelScrollFrameTemplate")
  sf:SetPoint("TOPLEFT", 6, -6)
  sf:SetPoint("BOTTOMRIGHT", -26, 6)
  local eb = CreateFrame("EditBox", nil, sf)
  eb:SetMultiLine(true)
  eb:SetAutoFocus(false)
  eb:SetMaxLetters(0)
  eb:SetWidth(300)
  Look.Font(eb, "body", 11)
  eb:SetTextColor(C(Look.INK))
  eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  sf:SetScrollChild(eb)
  sf:SetScript("OnMouseDown", function() eb:SetFocus() end)
  IO.edit = eb
  IO.msg = Look.Text(IO, "body", 11, Look.RED_INK)
  IO.msg:SetPoint("BOTTOM", 0, 44)
  IO.msg:SetWidth(330)
  IO.go = InkButton(IO, L.IO_GO, 104, 22, function()
    local okc, ok, a, b = pcall(Store().Import, eb:GetText() or "")
    if not okc then ok, a = false, nil end
    if ok then
      IO.msg:SetText(Fmt(L.IO_DONE, { new = tostring(a or 0), merged = tostring(b or 0) }))
      IO.msg:SetTextColor(C(Look.INK))
    else
      IO.msg:SetText(type(a) == "string" and a or L.IO_FAILED)
      IO.msg:SetTextColor(C(Look.RED_INK))
    end
    UI.Refresh()
  end)
  IO.go:SetPoint("BOTTOM", -57, 12)
  -- Sichern: zwischen der kleinen Fassung (ohne Taten) und dem ganzen Buch umschalten
  IO.size = InkButton(IO, "", 104, 22, function() UI.ShowExport(not IO.full) end)
  IO.size:SetPoint("BOTTOM", -57, 12)
  IO.size:Hide()
  local close = InkButton(IO, L.BTN_BACK, 104, 22, function() UI.OpenPanel("settings") end)
  close:SetPoint("BOTTOM", 57, 12)
end

-- Gebrauchsanweisung: links das gesperrte Stichwort, rechts der Absatz
BuildHelp = function()
  local Hp = PageLayer(RP)
  RP.help = Hp
  SheetHead(Hp, L.HEAD_HELP)
  local prev
  Hp.paras = {}
  for i, p in ipairs(UI.HELP) do
    local label = Label(Hp, p[1])
    local text = Look.Text(Hp, "type", 11, Look.INK)
    text:SetWidth(232)
    text:SetJustifyH("LEFT")
    text:SetSpacing(1)
    text:SetText(p[2])
    if prev then text:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -7)
    else text:SetPoint("TOPLEFT", 116, -62) end
    label:SetPoint("TOPRIGHT", text, "TOPLEFT", -10, -1)
    label:SetJustifyH("RIGHT")
    Hp.paras[i] = { label, text }
    prev = text
  end
  -- 1.2.0: Impressum als eine Zeile im Hinweis-Ton ueber dem Knopf (Humor.lua setzt UI.HELP_FOOT, nur de/en)
  if type(UI.HELP_FOOT) == "string" then
    local foot = Look.Text(Hp, "type", 11, Look.INK)
    foot:SetTextColor(C(Look.INK, TONE.hint))
    foot:SetPoint("BOTTOM", 0, 44)
    foot:SetWidth(PAGE_W - 40)
    foot:SetWordWrap(false)
    foot:SetText(UI.HELP_FOOT)
    Hp.foot = foot
  end
  local back = InkButton(Hp, L.BTN_BACK, 104, 22, function() UI.ClosePanel() end)
  back:SetPoint("BOTTOM", 0, 12)
end

-- 1.2.0: Blatt "Zur Jagd freigeben": fuer wen (Gilde & Freunde, Gilde, Freunde) und ein kurzer Grund.
-- Der Grund ist der einzige frei geschriebene Text, der je geteilt wird; die Notiz bleibt getrennt.
GF.TARGETS = { { "all", "TAB_GUILD_FRIENDS" }, { "guild", "SRC_GUILD" }, { "friends", "SRC_FRIENDS" } }
GF.REASON_HINT = { all = "REL_HINT_ALL", guild = "REL_HINT_GUILD", friends = "REL_HINT_FRIENDS" }   -- Schluessel

function GF.BuildRelease()
  local R = PageLayer(RP)
  RP.release = R
  SheetHead(R, L.REL_HEAD)
  R.name = Look.Text(R, "hand", 22, Look.INK)
  R.name:SetPoint("TOP", 0, -66)
  R.name:SetWidth(320)
  R.name:SetWordWrap(false)
  R.who = Look.Text(R, "type", 11, Look.INK)
  R.who:SetPoint("TOP", R.name, "BOTTOM", 0, -4)
  R.who:SetTextColor(C(Look.INK, TONE.sub))
  local forL = Label(R, L.REL_FOR)
  forL:SetPoint("TOPLEFT", 34, -134)
  R.tabs = {}
  local prev
  for i, v in ipairs(GF.TARGETS) do
    local b = WordTab(R, L[v[2]], 90, function(self)
      if self.off then return end
      state.release.to = self.to
      GF.FillRelease()
    end)
    b.to = v[1]
    b:SetSize(math.max(40, TextWidth(b.text, 80) + 6), 20)
    if prev then b:SetPoint("LEFT", prev, "RIGHT", 12, 0)
    else b:SetPoint("TOPLEFT", math.max(92, 34 + TextWidth(forL, 40) + 12), -128) end
    R.tabs[i] = b
    prev = b
  end
  local whyL = Label(R, L.REL_REASON)
  whyL:SetPoint("TOPLEFT", 34, -176)
  local eb = CreateFrame("EditBox", nil, R)
  eb:SetPoint("TOPLEFT", whyL, "TOPRIGHT", 8, 4)      -- 1.2.0: beide Anker an der Oberkante
  eb:SetPoint("TOPRIGHT", R, "TOPRIGHT", -34, -172)
  eb:SetHeight(18)
  eb:SetAutoFocus(false)
  eb:SetMaxLetters(60)
  Look.Font(eb, "hand", 13)
  eb:SetTextColor(C(Look.INK))
  local ul = eb:CreateTexture(nil, "BACKGROUND")
  ul:SetColorTexture(C(Look.INK, 0.35))
  ul:SetHeight(1)
  ul:SetPoint("BOTTOMLEFT", 0, 1); ul:SetPoint("BOTTOMRIGHT", 0, 1)
  eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  eb:SetScript("OnEnterPressed", function(self) self:ClearFocus(); GF.DoRelease() end)
  R.edit = eb
  R.hint = Look.Text(R, "type", 11, Look.INK)
  R.hint:SetTextColor(C(Look.INK, TONE.hint))
  R.hint:SetPoint("TOPLEFT", 34, -204)
  R.hint:SetWidth(312)
  R.hint:SetJustifyH("LEFT")
  R.hint2 = Look.Text(R, "type", 11, Look.INK)
  R.hint2:SetTextColor(C(Look.INK, TONE.hint))
  R.hint2:SetPoint("TOPLEFT", R.hint, "BOTTOMLEFT", 0, -6)
  R.hint2:SetWidth(312)
  R.hint2:SetJustifyH("LEFT")
  R.hint2:SetText(L.REL_HINT2)
  R.msg = Look.Text(R, "body", 11, Look.RED_INK)
  R.msg:SetPoint("BOTTOM", 0, 44)
  R.msg:SetWidth(330)
  R.go = InkButton(R, L.REL_GO, 104, 22, function() GF.DoRelease() end)
  R.go:SetPoint("BOTTOM", -57, 12)
  local back = InkButton(R, L.BTN_BACK, 104, 22, function() UI.ClosePanel() end)
  back:SetPoint("BOTTOM", 57, 12)
end

function GF.FillRelease()
  local R, st = RP.release, state.release
  if not R or not st then return end
  local key = st.key
  local x = Store().Get(key) or GCall("Get", key, "all") or GCall("Hunt", key, "all")
  R.name:SetText(x and Look.Name(x) or (NameOfKey(key)))
  R.who:SetText(x and Look.Join(x.level and Fmt(L.POSTER_LEVEL, { level = x.level }), ClassName(x)) or "")
  local g, f = GCall("HuntTargets")
  local avail = { all = g and f, guild = g, friends = f }
  if not avail[st.to] then st.to = (g and f and "all") or (g and "guild") or (f and "friends") or nil end
  for _, b in ipairs(R.tabs) do
    b.off = not avail[b.to]
    b:SetOn(b.to == st.to, b.off)
  end
  if st.to then
    R.hint:SetText(L[GF.REASON_HINT[st.to]])
    R.msg:SetText("")
  else
    R.hint:SetText("")
    R.msg:SetText(L.REL_NONE)
  end
  R.go:SetShown(st.to ~= nil)
end

function GF.DoRelease()
  local R, st = RP.release, state.release
  if not R or not st or not st.to then return end
  local why = R.edit:GetText() or ""
  if Look.Secret(why) then why = "" end
  local a, b = GCall("Release", st.key, { to = st.to, why = why })
  if a == nil then
    R.msg:SetText((b == "cap" and Fmt(L.REL_CAP, { own = 10, max = 100 })) or (b == "self" and L.REL_SELF)
      or (b == "mate" and L.REL_MATE) or L.REL_FAILED)
    return
  end
  R.edit:SetText("")
  R.edit:ClearFocus()
  UI.ShowHunts(st.key)
end

function UI.OpenRelease(key)
  if not F or type(key) ~= "string" then return end
  if not RP.settings then BuildSettings() end
  if not RP.release then GF.BuildRelease() end
  HideMenu()
  state.release = { key = key, to = "all" }
  state.panel = "release"
  P:Hide(); RP.empty:Hide()
  RP.settings:Hide(); RP.io:Hide()
  if RP.help then RP.help:Hide() end
  RP.release.edit:SetText("")
  RP.release:Show()
  GF.FillRelease()
  if state.filter == "guild" and LP then GF.Survey(); UX.UpdateTabs() end   -- 1.2.0: Abschussliste-Ansicht zeigen
end

-- 1.2.0: Sprachwahl. Erster Wert "Automatisch" (keine gespeicherte Wahl: die Sprache des Spiels, sonst Englisch),
-- dann die 21 Kennungen; jeder Eigenname in der Schrift seiner Sprache
function GF.CurLanguage()
  local Lc = ns.Locale
  local cur = Lc.StoredChoice and Lc.StoredChoice() or nil
  if type(cur) ~= "string" or not (Lc.NATIVE and Lc.NATIVE[cur]) then cur = Lc.AUTO or "auto" end
  return cur
end

function GF.StepLanguage(d)
  local Lc = ns.Locale
  if not (Lc and Lc.SetChoice) then return end
  local list = { Lc.AUTO or "auto" }
  for i, c in ipairs(Lc.CODES) do list[i + 1] = c end
  local cur = GF.CurLanguage()
  local idx = 1
  for i, c in ipairs(list) do if c == cur then idx = i end end
  Lc.SetChoice(list[(idx - 1 + d) % #list + 1])
end

function GF.FillLanguage(S)
  local Lc = ns.Locale
  if not (S.lang and Lc and Lc.CODES) then return end
  local cur = GF.CurLanguage()
  local name, script = Lc.NATIVE[cur], cur
  if not name then
    -- Automatisch: das Wort in der aktiven Sprache (ihre Schrift)
    script = Lc.code or "enUS"
    name = L.SET_LANG_AUTO
  end
  if S.lang.code ~= cur then
    S.lang.code = cur
    -- Eigenname in der Schrift seiner Sprache (Kyrillisch, Koreanisch, Chinesisch)
    Look.Font(S.lang, "body", 11, nil, Look.FontOf(script))
  end
  S.lang:SetText(name)
  local pending = Lc.Pending and Lc.Pending() or false
  S.langHint:SetShown(pending)
  S.reload:SetShown(pending)
end

function UI.FillSettings()
  local S = RP and RP.settings
  if not S then return end
  local guild = HasGuild()
  if not guild and state.spage == 3 then state.spage = 1 end
  for i, t in ipairs(S.tabs) do
    t:SetShown(i < 3 or guild)
    t:SetOn(state.spage == i)
  end
  S.pageA:SetShown(state.spage == 1)
  S.pageL:SetShown(state.spage == 2)
  S.pageB:SetShown(state.spage == 3)
  if S.gmore then
    -- 1.2.0: zweite Seite des Blatts Gilde ("Mehr"), Zustand gemerkt, zu als Standard
    local more = Look.Setting("ui.guildMore", false) == true
    S.gmore:SetOn(more)
    S.pageB1:SetShown(not more)
    S.pageB2:SetShown(more)
  end
  for _, cb in ipairs(S.checks) do
    local v
    if cb.opt.guild then v = Look.GuildSetting(cb.opt.guild) == true
    else v = Look.Setting(cb.opt.path, cb.opt.def) and true or false end
    if cb.opt.invert then v = not v end
    cb:SetInk(v)
  end
  S.cd:SetText(Fmt(L.SET_SECONDS, { seconds = Look.Setting("alert.cooldown", 90) or 90 }))
  S.mk:SetText(tostring(Look.Setting("alert.minKills", 1) or 1))
  S.size:SetText(Percent(ClampScale(tonumber(Look.Setting("ui.scale", 1)) or 1)))
  S.asize:SetText(Percent(Look.Setting("alert.scale", 1)))
  S.gmk:SetText(tostring(Look.GuildSetting("minKills") or 1))
  local days = tonumber(Look.GuildSetting("huntExpire")) or 0
  S.hexp:SetText(days > 0 and Fmt(L.SET_EXPIRE_DAYS, { count = days }) or L.SET_EXPIRE_NEVER)
  if guild then
    local h = Look.GuildHealth()
    S.gstatus:SetText(h.text)
    if h.ok or h.calm then S.gstatus:SetTextColor(C(Look.INK, h.ok and TONE.ink or TONE.sub)) else S.gstatus:SetTextColor(C(Look.RED_INK)) end
    if S.fstatus then
      local fh = Look.GuildHealth("friends")
      S.fstatus:SetText(fh.text)
      if fh.ok or fh.calm then S.fstatus:SetTextColor(C(Look.INK, fh.ok and TONE.ink or TONE.sub)) else S.fstatus:SetTextColor(C(Look.RED_INK)) end
    end
  else
    S.gstatus:SetText("")
    if S.fstatus then S.fstatus:SetText("") end
  end
  local io = Store().Export ~= nil
  for _, b in ipairs(S.ioButtons) do b:SetShown(io) end

  -- Ton: "Kein Ton" ist die Stille; eingebaute Toene haben keine eigene Lautstaerke
  local sound, vol, ch = Look.SoundChoice()
  S.tone:SetText(sound.label or L[sound.lkey])
  local fixed = sound.builtin or sound.silent
  for i, bar in ipairs(S.vol.bars) do bar:SetAlpha((i <= vol and 0.85 or 0.15) * ((fixed and 0.5) or 1)) end
  S.vol:SetText("")
  Dim(S.tone, false)
  Dim(S.vol, fixed)
  local chOff = sound.silent
  S.chan.label:SetTextColor(C(Look.INK, chOff and TONE.off or TONE.ink))
  for i = 1, #Look.CHANNELS do
    local b = S.chan[i]
    b.off = chOff
    b:SetOn(b.channel == ch, chOff)
  end
  if sound.silent then
    S.soundHint:SetText(L.SET_HINT_SILENT)
  elseif sound.builtin then
    S.soundHint:SetText(L.SET_HINT_BUILTIN)
  else
    S.soundHint:SetText(L.SET_HINT_LEVELS)
  end
  GF.FillLanguage(S)
end

function UI.OpenPanel(which)
  if not F then return end
  if not RP.settings then BuildSettings() end
  if which == "help" and not RP.help then BuildHelp() end
  HideMenu()
  state.panel = which
  P:Hide(); RP.empty:Hide()
  if RP.release then RP.release:Hide() end
  RP.settings:SetShown(which == "settings")
  RP.io:SetShown(which == "export" or which == "import")
  if RP.help then RP.help:SetShown(which == "help") end
  if which == "settings" then UI.FillSettings() end
end

function UI.ClosePanel(silent)
  state.panel = nil
  if RP.release then RP.release:Hide() end
  if RP.settings then RP.settings:Hide(); RP.io:Hide() end
  if RP.help then RP.help:Hide() end
  if not silent then ShowRight() end
end

local function KB(n) return math.floor(n / 1024 + 0.5) .. " KB" end

local function ExportText(short)
  local ok, text = pcall(Store().Export, short)
  if ok and type(text) == "string" then return text end
  return ""
end

-- full == true: ganzes Buch mit Taten, false: kleine Fassung (falls der Store eine kennt),
-- nil: automatisch (ab EXPORT_WARN die kleine)
function UI.ShowExport(full)
  local IO = RP and RP.io
  if not IO then return end
  local whole = ExportText()
  local short = ExportText(true)       -- aeltere Store-Fassung ohne Kurzform: derselbe Text
  local hasShort = #short < #whole
  if full == nil then full = #whole < EXPORT_WARN end
  IO.full = full or not hasShort
  IO.edit:SetText(IO.full and whole or short)
  if hasShort then
    IO.size:SetLabel(IO.full and L.IO_SMALL or L.IO_ALL)
    IO.size:Show()
    if IO.full then
      IO.msg:SetText(Fmt(L.IO_MSG_FULL, { size = KB(#whole) }))
    else
      IO.msg:SetText(Fmt(L.IO_MSG_SHORT, { size = KB(#short), full = KB(#whole) }))
    end
  else
    IO.size:Hide()
    IO.msg:SetText(#whole >= EXPORT_WARN and Fmt(L.IO_MSG_BIG, { size = KB(#whole) }) or "")
  end
  IO.msg:SetTextColor(C(Look.INK))
  IO.edit:SetFocus()
  IO.edit:HighlightText()
end

function UI.OpenIO(mode)
  UI.OpenPanel(mode)
  local IO = RP.io
  IO.msg:SetText("")
  IO.size:Hide()
  if mode == "export" then
    IO.head:SetText(L.IO_EXPORT)
    IO.help:SetText(L.IO_HELP_EXPORT)
    IO.go:Hide()
    -- grosse Buecher zuerst klein zeigen (eine EditBox mit Tausenden Zeilen bremst)
    UI.ShowExport(nil)
  else
    IO.head:SetText(L.IO_IMPORT)
    IO.help:SetText(L.IO_HELP_IMPORT)
    IO.edit:SetText("")
    IO.go:SetShown(Store().Import ~= nil)
    IO.edit:SetFocus()
  end
end

end -- Hausordnung

------------------------------------------------------------------------
-- Hauptfenster
------------------------------------------------------------------------
GF.OPEN_HEX = ("|cff%02x%02x%02x"):format(Look.RED_ON_BLACK[1] * 255, Look.RED_ON_BLACK[2] * 255, Look.RED_ON_BLACK[3] * 255)

-- Zahl am Reiter: nur, wenn es etwas gibt; "Zu klären" in Rot
function UX.TabCount(id)
  if id == "journal" then return #UX.Journal() end
  if id == "guild" then return UX.GuildCount() end
  local w, s, _, o = Counts()
  if id == "open" then return s + o end
  return w
end

function UX.UpdateTabs()
  local guild = HasGuild()
  for _, t in ipairs(F.tabs) do
    local on = t.id == state.filter
    t:SetShown(t.id ~= "guild" or guild)
    local n = UX.TabCount(t.id) or 0
    if n <= 0 then t.text:SetText(t.label)
    elseif t.id == "open" then t.text:SetText(t.label .. "  " .. GF.OPEN_HEX .. n .. "|r")
    else t.text:SetText(t.label .. "  " .. n) end
    t.text:SetTextColor(C(on and Look.BONE or Look.TAB_OFF))
    t.mark:SetShown(on)
  end
  -- Gilde mit "Nach Kollege": oben der Umschalter (Suchfeld kuerzer); Sortierung unten rechts
  -- 1.2.0: Ansichten nur, wenn es mehr als eine sinnvolle gibt (niemand zum Teilen: keine; die
  -- Abschussliste nur mit Freigaben); Quellen nur, wenn es beide wirklich gibt. Im Normalfall eine Reihe.
  local guildTab = state.filter == "guild"
  local views = guildTab and not GF.nobody and (HasMemberView() or GF.hunts) and true or false
  LP.views:SetShown(views)
  if views then
    for _, b in ipairs(LP.views.items) do
      b:SetOn(b.view == state.gview)
      if b.view == "hunt" then b:SetShown(GF.hunts and true or false) end
    end
  end
  -- 1.2.0: Quelle (Alle, Gilde, Freunde) unten links, nur mit dem Freundesbuch
  local srcs = guildTab and GF.HasFriends() and GF.both and true or false
  LP.srcs:SetShown(srcs)
  if srcs then
    for _, b in ipairs(LP.srcs.items) do b:SetOn(b.src == state.gsource) end
  end
  -- Morpheus 13 ist breiter als die Naeherung im Standbild: Luft fuer den Umschalter (drei Ansichten: 90)
  local three = views and #LP.views.items > 2 and GF.hunts
  local sw = views and (three and 80 or 120) or 200
  -- 1.2.0: nie unter die Ansicht-Woerter (deren Breite haengt an der Sprache)
  local vw = views and (three and LP.views.width or LP.views.width2)
  if vw then sw = math.max(60, math.min(sw, PAGE_W - 14 - vw - 46 - 8)) end
  if LP.search.w ~= sw then LP.search.w = sw; LP.search:SetWidth(sw) end
  -- Alle auf/zu: Doppeldreieck links neben dem Suchfeld
  local member = MemberView()
  LP.all:SetShown(member)
  if member then
    LP.all.open = not AnyCollapsed()          -- true: Klick klappt alle zu
    LP.all.a:SetRotation(LP.all.open and -1.5708 or 0)
    LP.all.b:SetRotation(LP.all.open and -1.5708 or 0)
  end
  -- Sortierung: Gesucht oben rechts, Gilde nach Taeter unten rechts, sonst keine
  local foot = state.filter == "guild"
  if LP.sort.foot ~= foot then
    LP.sort.foot = foot
    LP.sort:ClearAllPoints()
    if foot then LP.sort:SetPoint("BOTTOMRIGHT", -14, 32) else LP.sort:SetPoint("TOPRIGHT", -14, -14) end
  end
  local sortKey = (state.filter == "guild") and state.gsort or state.sort
  LP.sort.text:SetText(SORT_LABEL[sortKey] and L[SORT_LABEL[sortKey]] or "")
  LP.sort:SetWidth(math.max(90, math.min(120, TextWidth(LP.sort.text, 60) + 16)))
  LP.sort:SetShown(state.filter == "wanted" or (state.filter == "guild" and not member and not GF.HuntView()))
  LP.search.ph:SetText((state.filter == "guild" and ((views or GF.HuntView()) and L.SEARCH_SHORT or L.SEARCH_KILLER))
                       or (state.filter == "journal" and L.SEARCH_JOURNAL)
                       or (state.filter == "open" and L.SEARCH_SHORT) or L.SEARCH_ADD)
end

function UX.UpdateStatus()
  local U = ns.Util
  if state.filter == "guild" then
    -- ehrlicher Stand des Teilens, rot, wenn es nicht geht; Tooltip: Kollegen, was geteilt wird
    -- 1.2.0: niemand zum Teilen: keine Zeile, der Leerzustand rechts sagt es ruhig; "keine Freunde" gedaempft
    local h = Look.GuildHealth(GF.HasFriends() and GF.Src() or nil)
    local quiet = GF.nobody
    LP.status:SetText(quiet and "" or h.text)
    if h.ok or h.calm then LP.status:SetTextColor(C(Look.INK, TONE.sub)) else LP.status:SetTextColor(C(Look.RED_INK)) end
    LP.status:SetWidth(PAGE_W - 46 - (LP.sync:GetWidth() or 84) - 20)
    LP.statusHit:SetShown(not quiet)
    LP.sync:SetShown(GF.SrcOn() and not quiet)
  elseif U and U.NameplatesOn and U.NameplatesOn() == false then
    LP.status:SetText(L.STATUS_NO_PLATES)
    LP.status:SetTextColor(C(Look.RED_INK))
    LP.status:SetWidth(PAGE_W - 46 - 14)
    LP.statusHit:Hide()
    LP.sync:Hide()
  else
    LP.status:SetText("")
    LP.statusHit:Hide()
    LP.sync:Hide()
  end
end

-- Suche: Teilstring im angezeigten Namen (Journal und Faelle: Taeter, Kandidat oder Ort)
local function Matches(text, q)
  return type(text) == "string" and text:lower():find(q, 1, true) ~= nil
end

local function DeathMatches(d, q)
  local name = d.killerKey and NameOfKey(d.killerKey, d.killerName) or d.killerName
  if Matches(name, q) or Matches(d.zone, q) or Matches(d.subzone, q) then return true end
  if not d.killerKey and type(d.candidates) == "table" then
    for i = 1, #d.candidates do if Matches((NameOfKey(d.candidates[i])), q) then return true end end
  end
  return false
end

-- Todesjournal: nur Tode durch Spieler (pvp und unklar), Monster und Umwelt nicht (1.2.0)
function UX.Journal()
  local S = Store()
  if S.Journal then
    local ok, list = pcall(S.Journal)
    if ok and type(list) == "table" then return list end
  end
  return S.Deaths() or {}
end

function UX.ApplyQuery(list)
  dataIdx = nil
  local q = state.query
  if q == "" then return list end
  q = q:lower()
  local out = {}
  if state.filter == "journal" then
    dataIdx = {}
    for i = 1, #list do
      if DeathMatches(list[i], q) then
        out[#out + 1] = list[i]
        dataIdx[#out] = i
      end
    end
  else
    for i = 1, #list do
      local x = list[i]
      if IsCase(x) then
        if DeathMatches(x, q) then out[#out + 1] = x end
      elseif Matches(Look.Name(x), q) then
        out[#out + 1] = x
      end
    end
  end
  return out
end

------------------------------------------------------------------------
-- Gilde: flache Liste "nach Kollege" (nur bei Aenderung neu)
------------------------------------------------------------------------
local mflat = {}            -- Kopf- und Kindzeilen, Wrapper aus wpool
local wpool = {}
local mv = { src = nil, cver = -1, q = nil, dirty = true, n = 0, builds = 0 }
local collapseVer = 0
local NOTHING = {}
UI.mv = mv                  -- fuer Tests: wie oft wurde die flache Liste gebaut
function UI.DataCount() return #data end   -- fuer Tests und Messung: Zeilen der aktuellen Liste

-- ui.guildCollapsed: Name -> true heisst "anders als der Standard" (Standard: eigener Abschnitt auf,
-- alle anderen zu). Der Store haelt in dieser Tabelle nur true-Werte.
local function IsCollapsed(m, t)
  local def = not m.me
  if t and t[m.name] == true then return not def end
  return def
end

local function CollapsedTable()
  local t = Look.Setting("ui.guildCollapsed")
  return type(t) == "table" and t or nil
end

local function RowName(row)
  local e = row.entry
  return e and Look.Name(e) or row.key
end

function UX.BuildMemberList(src, q)
  mv.builds = mv.builds + 1
  local t = CollapsedTable()
  local n = 0
  local function add(m, row, head, open)
    n = n + 1
    local w = wpool[n]
    if not w then w = { wrap = true }; wpool[n] = w end
    w.m, w.r, w.head, w.open = m, row, head, open
    mflat[n] = w
  end
  for i = 1, #src do
    local m = src[i]
    local rows = type(m) == "table" and m.rows
    if type(m) == "table" and (m.me or (m.tie and m.tie.conflict)) and (type(rows) ~= "table" or #rows == 0) and q == "" then
      -- eigener Char steht immer oben, auch ohne Eintraege; 1.2.0: ebenso beide Namen eines Freundes, bei dem
      -- der Spieler waehlen muss, wer es ist (Rechtsklick)
      add(m, nil, true, false)
    elseif type(rows) == "table" and #rows > 0 then
      if q == "" then
        local open = not IsCollapsed(m, t)
        add(m, nil, true, open)
        if open then for k = 1, #rows do add(m, rows[k], false) end end
      elseif Matches(m.name, q) then
        -- Treffer klappt den Abschnitt nur fuer die Suche auf (gemerkter Zustand bleibt)
        add(m, nil, true, true)
        for k = 1, #rows do add(m, rows[k], false) end
      else
        local hit = false
        for k = 1, #rows do if Matches(RowName(rows[k]), q) then hit = true; break end end
        if hit then
          add(m, nil, true, true)
          for k = 1, #rows do if Matches(RowName(rows[k]), q) then add(m, rows[k], false) end end
        end
      end
    end
  end
  for i = n + 1, mv.n do mflat[i] = nil end
  mv.n = n
end

function UX.MemberSource()
  local s = GF.Src()
  local src = GF.SrcOn(s) and GCall("ByMember", s) or nil
  return type(src) == "table" and src or NOTHING
end

function UX.MemberData()
  local src = UX.MemberSource()
  local q = state.query:lower()
  if src ~= mv.src or mv.dirty or mv.cver ~= collapseVer or mv.q ~= q then
    UX.BuildMemberList(src, q)
    mv.src, mv.dirty, mv.cver, mv.q = src, false, collapseVer, q
  end
  return mflat
end

-- ist irgendein Abschnitt (mit Eintraegen) gerade zugeklappt?
AnyCollapsed = function()
  local src, t = mv.src or NOTHING, CollapsedTable()
  for i = 1, #src do
    local m = src[i]
    if type(m) == "table" and type(m.rows) == "table" and #m.rows > 0 and IsCollapsed(m, t) then return true end
  end
  return false
end

-- Zustand zurueckschreiben: ganze Tabelle kopieren, aendern, setzen (so will es der Store)
local function WriteCollapsed(fn)
  local copy = {}
  local t = CollapsedTable()
  if t then for k, v in pairs(t) do copy[k] = v end end
  fn(copy)
  collapseVer = collapseVer + 1
  Set("ui.guildCollapsed", copy)
  Refresh()
end

ToggleMember = function(m)
  if state.query ~= "" or type(m) ~= "table" or type(m.name) ~= "string" then return end
  if type(m.rows) ~= "table" or #m.rows == 0 then return end
  Look.Sound("click")
  WriteCollapsed(function(copy) if copy[m.name] then copy[m.name] = nil else copy[m.name] = true end end)
end

SetAllMembers = function(open)
  local src = mv.src or NOTHING
  WriteCollapsed(function(copy)
    for k in pairs(copy) do copy[k] = nil end
    for i = 1, #src do
      local m = src[i]
      if type(m) == "table" and type(m.name) == "string" then
        local default = not m.me
        if (not open) ~= default then copy[m.name] = true end
      end
    end
  end)
end

Refresh = function()
  if not F or not F:IsShown() then dirty = true; return end
  dirty = false
  local S = Store()
  if state.filter == "guild" and not HasGuild() then state.filter = "wanted" end
  if state.filter == "guild" then GF.Survey() end
  local list
  if state.filter == "journal" then
    list = UX.Journal()
  elseif state.filter == "open" then
    list = UX.OpenData()
  elseif GF.HuntView() then
    list = GF.SrcOn() and GF.Hunts() or {}
  elseif state.filter == "guild" and not MemberView() then
    list = GuildEnemies(state.gsort)
  elseif state.filter ~= "guild" then
    list = UX.WantedData()
  end
  if MemberView() then
    dataIdx = nil
    data = UX.MemberData()
  else
    data = UX.ApplyQuery(list)
  end
  UX.UpdateTabs()
  UX.UpdateStatus()
  BindRows()
  picked = false
  ShowRight()
  if picked then BindRows() end      -- die eben gesetzte Auswahl gleich unterstreichen
  if state.panel == "settings" then UI.FillSettings() end
end
UI.Refresh = Refresh

-- mehrere Aenderungen im selben Frame zu einem Neuaufbau zusammenfassen
local function RequestRefresh()
  if not F or not F:IsShown() then dirty = true; return end
  if pending then return end
  pending = true
  C_Timer.After(0, function() pending = false; Refresh() end)
end

local function SetFilter(id)
  if state.filter == id then
    if state.panel then UI.ClosePanel() end
    return
  end
  -- 1.2.0: die Abschussliste ist die erste Ansicht, sobald es eine Freigabe gibt (bis man selbst waehlt)
  if id == "guild" and not state.viewPicked and GF.HasHunts() and #GF.Hunts() > 0 then state.gview = "hunt" end
  state.filter = id
  state.offset = 0
  state.death, state.deathRef = nil, nil
  HideMenu()
  if state.panel then UI.ClosePanel(true) end
  Refresh()
end
UI.SetFilter = SetFilter

function UX.SavePoint()
  local p, _, rp, x, y = F:GetPoint(1)
  if p then Set("ui.point", { p, rp, x, y }) end
end

-- Enter im Suchfeld: Treffer waehlen, ohne Treffer ins Buch eintragen (nur im Reiter Gesucht)
local function SubmitSearch(box)
  local q = state.query
  if q == "" then box:ClearFocus(); return end
  if #data > 0 then
    local first = data[1]
    if state.filter == "journal" then state.death, state.deathRef = (dataIdx and dataIdx[1]) or 1, first
    elseif first.wrap then
      for i = 1, #data do
        if not data[i].head then state.gselected, state.gmember = data[i].r.key, data[i].m.name; break end
      end
    elseif state.filter == "open" then state.osel = IsCase(first) and first or first.key
    elseif state.filter == "guild" then state.gselected = first.key
    else state.selected = first.key end
    state.offset = 0
    box:ClearFocus()
    if state.panel then UI.ClosePanel(true) end
    BindRows()
    ShowRight()
    return
  end
  if SearchOnly() then return end
  local S = Store()
  local key = S.AddManual and S.AddManual(q)
  if type(key) == "string" then
    box:ClearFocus()
    UI.ShowEnemy(key)
  end
end

function UX.BuildSearch(parent)
  local sb = CreateFrame("EditBox", "DeathNoteSearch", parent)
  sb:SetPoint("TOPLEFT", 46, -8)
  sb:SetSize(200, 26)
  sb:SetAutoFocus(false)
  sb:SetMaxLetters(40)
  Look.Font(sb, "hand", 19)
  sb:SetTextColor(C(Look.INK))
  local ul = sb:CreateTexture(nil, "BACKGROUND")
  ul:SetColorTexture(C(Look.INK, 0.35))
  ul:SetHeight(1)
  ul:SetPoint("BOTTOMLEFT", 0, 1); ul:SetPoint("BOTTOMRIGHT", 0, 1)
  sb.ph = Look.Text(sb, "hand", 16, Look.INK)
  sb.ph:SetPoint("LEFT", 1, -1)
  sb.ph:SetTextColor(C(Look.INK, TONE.hand))
  sb.ph:SetText(L.SEARCH_ADD)
  local function changed(self)
    local t = self:GetText() or ""
    if Look.Secret(t) then t = "" end
    self.ph:SetShown(t == "")
    t = t:gsub("^%s+", ""):gsub("%s+$", "")
    if t == state.query then return end
    state.query = t
    state.offset = 0
    Refresh()
  end
  sb:SetScript("OnTextChanged", changed)
  sb:SetScript("OnEnterPressed", SubmitSearch)
  sb:SetScript("OnEscapePressed", function(self)
    if (self:GetText() or "") ~= "" then self:SetText(""); changed(self) else self:ClearFocus() end
  end)
  return sb
end

function UI.SetGuildView(v)
  if v ~= "enemy" and v ~= "member" and v ~= "hunt" then return end
  state.viewPicked = true
  if state.gview == v then return end
  Look.Sound("click")
  state.gview = v
  state.offset = 0
  HideMenu()
  Set("ui.guildView", v)
  Refresh()
end

-- 1.2.0: Quelle im vierten Reiter
function UI.SetGuildSource(src)
  if src ~= "all" and src ~= "guild" and src ~= "friends" then return end
  if state.gsource == src then return end
  Look.Sound("click")
  state.gsource = src
  state.offset = 0
  HideMenu()
  mv.dirty = true
  gpart.src = nil
  Set("ui.guildSource", src)
  Refresh()
end

function UI.ClearSearch()
  state.query = ""
  if LP and LP.search then
    LP.search:SetText("")
    LP.search.ph:Show()
  end
end

-- Sortiermenue: die Werte als Liste, im Reiter Gesucht dazu "Begnadigte zeigen/ausblenden"
function UX.SortMenu(btn)
  local guild = state.filter == "guild"
  local list = guild and UX.GSORTS or UX.SORTS
  local spec = {}
  for _, k in ipairs(list) do
    spec[#spec + 1] = { (k == (guild and state.gsort or state.sort) and "• " or "") .. L[SORT_LABEL[k]], function()
      if guild then state.gsort = k else state.sort = k; Set("ui.sort", k) end
      state.offset = 0
      Refresh()
    end }
  end
  if not guild then
    local on = ShowPardoned()
    spec[#spec + 1] = { on and L.SORT_HIDE_PARDONED or L.SORT_SHOW_PARDONED, function()
      Set("ui.showPardoned", not on)
      Refresh()
    end }
  end
  OpenMenu(spec, btn)
end

function UX.BuildLeftPage()
  LP = CreateFrame("Frame", nil, F)
  LP:SetSize(PAGE_W, PAGE_H)
  LP:SetPoint("TOPLEFT", 16, -44)
  local bg = Tex(LP, "BACKGROUND", Look.TEX.page)
  bg:SetAllPoints()
  bg:SetTexCoord(1, 0, 0, 1)          -- gespiegelt: der dunkle Rand liegt am Falz
  -- Linien alle 22 px: Name auf der ersten, Untertext auf der zweiten; blasser roter Rand
  for k = 1, ROWS * 2 do
    local l = LP:CreateTexture(nil, "BORDER")
    l:SetColorTexture(0.25, 0.27, 0.33, k % 2 == 0 and 0.28 or 0.16)
    l:SetHeight(1)
    l:SetPoint("TOPLEFT", 6, ROW_TOP - k * LINE_H + 1)
    l:SetPoint("TOPRIGHT", -6, ROW_TOP - k * LINE_H + 1)
  end
  local margin = LP:CreateTexture(nil, "BORDER")
  margin:SetColorTexture(Look.RED[1], Look.RED[2], Look.RED[3], 0.35)
  margin:SetWidth(1)
  margin:SetPoint("TOPLEFT", 40, 0)
  margin:SetPoint("BOTTOMLEFT", 40, 0)

  LP.search = UX.BuildSearch(LP)

  -- Sortierung: ein Wort mit Dreieck; Klick oeffnet die Liste der Werte, Hover unterstreicht
  local sort = CreateFrame("Button", nil, LP)
  sort:SetSize(90, 18)
  sort:SetPoint("TOPRIGHT", -14, -14)
  sort.arrow = Tri(sort, 9, -1.5708)
  sort.arrow:SetPoint("RIGHT", 0, 0)
  sort.text = Look.Text(sort, "body", 11, Look.INK)
  sort.text:SetTextColor(C(Look.INK, TONE.sub))
  sort.text:SetPoint("RIGHT", sort.arrow, "LEFT", -3, 0)
  sort.text:SetJustifyH("RIGHT")
  sort.ul = sort:CreateTexture(nil, "ARTWORK")
  sort.ul:SetColorTexture(C(Look.INK, 0.6))
  sort.ul:SetHeight(1)
  sort.ul:SetPoint("TOPLEFT", sort.text, "BOTTOMLEFT", 0, -1)
  sort.ul:SetPoint("TOPRIGHT", sort.arrow, "BOTTOMRIGHT", 0, 1)
  sort.ul:Hide()
  sort:SetScript("OnEnter", function(self) self.ul:Show() end)
  sort:SetScript("OnLeave", function(self) self.ul:Hide() end)
  sort:SetScript("OnClick", function(self) Look.Sound("click"); UX.SortMenu(self) end)
  LP.sort = sort

  -- Alle auf/zu (Gilde nach Kollege): Doppeldreieck links neben dem Suchfeld
  local all = CreateFrame("Button", nil, LP)
  all:SetSize(20, 20)
  all:SetPoint("TOPLEFT", 14, -12)
  all.a = Tri(all, 10, 0); all.a:SetPoint("CENTER", -3, 0)
  all.b = Tri(all, 10, 0); all.b:SetPoint("CENTER", 3, 0)
  all:SetScript("OnClick", function(self) SetAllMembers(not self.open) end)
  all:SetScript("OnEnter", function(self) Tip(self, { self.open and L.TIP_COLLAPSE_ALL or L.TIP_EXPAND_ALL }, "ANCHOR_TOP") end)
  all:SetScript("OnLeave", GameTooltip_Hide)
  all:Hide()
  LP.all = all

  -- Umschalter "Nach Taeter | Nach Kollege": zwei Wort-Reiter, der aktive rot unterstrichen
  local views = CreateFrame("Frame", nil, LP)
  views:SetSize(180, 22)
  views:SetPoint("TOPRIGHT", -14, -10)
  views.items = {}
  local prev
  -- 1.2.0: die Abschussliste steht vorn (links), wenn die Logik sie kennt
  local viewList = { { "member", "VIEW_BY_MATE" }, { "enemy", "VIEW_BY_KILLER" } }
  if GF.HasHunts() then viewList[3] = { "hunt", "VIEW_HUNT" } end
  local gap = #viewList > 2 and 8 or 10
  -- 1.2.0: Breite aus dem Wort; zusammen hoechstens so breit, dass das Suchfeld 60 px behaelt
  local ws, total = {}, 0
  for i, v in ipairs(viewList) do
    local b = WordTab(views, L[v[2]], 78, function(self) UI.SetGuildView(self.view) end)
    b.view = v[1]
    ws[i] = math.max(40, TextWidth(b.text, 70) + 6)
    total = total + ws[i] + (i > 1 and gap or 0)
    views.items[i] = b
  end
  local room = PAGE_W - 14 - 46 - 8 - 60
  local k = total > room and (room - gap * (#ws - 1)) / (total - gap * (#ws - 1)) or 1
  for i, b in ipairs(views.items) do
    local w = math.floor(ws[i] * k)
    b:SetSize(w, 20)
    if k < 1 then b.text:SetWidth(w - 4); b.text:SetWordWrap(false) end
    if prev then b:SetPoint("RIGHT", prev, "LEFT", -gap, 0) else b:SetPoint("RIGHT", 0, 0) end
    prev = b
  end
  views.width = math.min(total, room)
  -- 1.2.0: Breite ohne die Abschussliste (die steht links und kann fehlen)
  views.width2 = #ws > 2 and math.floor((ws[1] + ws[2] + gap) * k) or views.width
  views:Hide()
  LP.views = views

  -- 1.2.0: Quelle "Alle | Gilde | Freunde" unten links (Muster der Ansicht-Umschalter)
  local srcs = CreateFrame("Frame", nil, LP)
  srcs:SetSize(200, 18)
  srcs:SetPoint("BOTTOMLEFT", 44, 34)
  srcs.items = {}
  local prevS
  for i, v in ipairs(GF.SOURCES) do
    local b = WordTab(srcs, L[v[2]], 50, function(self) UI.SetGuildSource(self.src) end)
    b.src = v[1]
    local w = math.min(80, math.max(30, TextWidth(b.text, 40) + 6))
    b:SetSize(w, 18)
    b.text:SetWidth(w - 4); b.text:SetWordWrap(false)
    if prevS then b:SetPoint("LEFT", prevS, "RIGHT", 10, 0) else b:SetPoint("LEFT", 0, 0) end
    srcs.items[i] = b
    prevS = b
  end
  srcs:Hide()
  LP.srcs = srcs

  local LR = CreateFrame("Frame", nil, LP)
  LR:SetAllPoints()
  LR:EnableMouseWheel(true)
  LR:SetScript("OnMouseWheel", function(_, delta)
    local maxOff = math.max(0, #data - ROWS)
    local o = math.max(0, math.min(maxOff, state.offset - delta * 2))
    if o ~= state.offset then state.offset = o; HideMenu(); BindRows() end
  end)
  for i = 1, ROWS do rows[i] = UX.MakeRow(LR, i) end

  -- Rollbalken: 14 px Greifflaeche, sichtbar 5 px
  local sc = CreateFrame("Slider", nil, LP)
  sc:SetOrientation("VERTICAL")
  sc:SetSize(14, ROWS * ROW_H - 8)
  sc:SetPoint("TOPRIGHT", -4, ROW_TOP - 4)
  local track = sc:CreateTexture(nil, "BACKGROUND")
  track:SetColorTexture(C(Look.INK, 0.12))
  track:SetWidth(5)
  track:SetPoint("TOP"); track:SetPoint("BOTTOM")
  local thumb = sc:CreateTexture(nil, "OVERLAY")
  thumb:SetColorTexture(0, 0, 0, 0)
  thumb:SetSize(14, 34)
  sc:SetThumbTexture(thumb)
  local tv = sc:CreateTexture(nil, "OVERLAY", nil, 1)
  tv:SetColorTexture(C(Look.INK, 0.75))
  tv:SetWidth(5)
  tv:SetPoint("TOP", thumb, "TOP"); tv:SetPoint("BOTTOM", thumb, "BOTTOM")
  sc:SetMinMaxValues(0, 0)
  sc:SetValueStep(1)
  if sc.SetObeyStepOnDrag then sc:SetObeyStepOnDrag(true) end
  sc:SetScript("OnValueChanged", function(_, v)
    v = math.floor((v or 0) + 0.5)
    if v ~= state.offset then state.offset = v; HideMenu(); BindRows() end
  end)
  LP.scroll = sc

  -- Fusszeile: links der Stand (Gilde: Teilen, sonst Hinweis), rechts unten "Abgleichen"
  LP.status = Look.Text(LP, "body", 10, Look.INK)
  LP.status:SetPoint("BOTTOMLEFT", 46, 10)
  LP.status:SetWidth(PAGE_W - 46 - 104)
  LP.status:SetJustifyH("LEFT")
  LP.status:SetMaxLines(2)
  local hit = CreateFrame("Button", nil, LP)
  hit:SetPoint("BOTTOMLEFT", 44, 6)
  hit:SetSize(PAGE_W - 46 - 102, 30)
  hit:SetScript("OnEnter", MembersTip)
  hit:SetScript("OnLeave", GameTooltip_Hide)
  hit:Hide()
  LP.statusHit = hit
  LP.sync = InkButton(LP, L.SYNC_BUTTON, 84, 20, SyncClick)
  LP.sync:SetPoint("BOTTOMRIGHT", -14, 8)
  LP.sync:Hide()
  -- 1.2.0: der Knopf waechst mit dem Text wie die Reiter (84 bis GF.SYNC_MAX px; Kurzstaende wie
  -- "Realm blockt Fluestern"); die Statuszeile links weicht ihm aus
  local setLabel = LP.sync.SetLabel
  function LP.sync:SetLabel(t)
    setLabel(self, t)
    local w = math.max(GF.SYNC_MIN, math.min(GF.SYNC_MAX, math.floor(TextWidth(self.text, 60) + 16 + 0.5)))
    self:SetWidth(w)
    self.text:SetWidth(w - 8)
    LP.status:SetWidth(PAGE_W - 46 - w - 20)
  end
  LP.sync:SetLabel(L.SYNC_BUTTON)
end

-- 1.2.0: Reiterbreite aus dem Text (Platz fuer "  123" dazu), mindestens wie 1.1.0 (104, mit Freunden 132),
-- hoechstens 150 px; die Reihe beginnt bei x = 184 und endet vor dem "?" (x = 704). Reicht der Platz nicht,
-- werden alle gleichmaessig schmaler (Text wird dann gekuerzt, nie ueberlappt).
GF.TAB_X0, GF.TAB_X1, GF.TAB_GAP, GF.TAB_MAX, GF.TAB_ROOM = 184, 704, 4, 150, 34
function GF.LayoutTabs()
  local ws, total = {}, 0
  for i, t in ipairs(F.tabs) do
    t.text:SetText(t.label)
    ws[i] = math.min(GF.TAB_MAX, math.max(t.base, math.floor(TextWidth(t.text, 60) + GF.TAB_ROOM + 0.5)))
    total = total + ws[i] + (i > 1 and GF.TAB_GAP or 0)
  end
  local room = GF.TAB_X1 - GF.TAB_X0
  if total > room then
    local k = (room - GF.TAB_GAP * (#ws - 1)) / (total - GF.TAB_GAP * (#ws - 1))
    for i = 1, #ws do ws[i] = math.floor(ws[i] * k) end
  end
  local x = GF.TAB_X0
  for i, t in ipairs(F.tabs) do
    t:SetWidth(ws[i])
    t.text:SetWidth(ws[i] - 4)
    t:ClearAllPoints()
    t:SetPoint("TOPLEFT", x, -12)
    x = x + ws[i] + GF.TAB_GAP
  end
end

-- Kopf-Knoepfe: knochenweiss, bei Hover rot (nur die Farbe aendert sich)
local function HeadButton(text, size, tip)
  local b = CreateFrame("Button", nil, F)
  b:SetSize(22, 22)
  b.text = Look.Text(b, "body", size, Look.BONE)
  b.text:SetPoint("CENTER", 0, 1)
  b.text:SetText(text)
  b:SetScript("OnEnter", function(self)
    self.text:SetTextColor(C(Look.RED_ON_BLACK))
    if tip then GameTooltip:SetOwner(self, "ANCHOR_LEFT"); GameTooltip:SetText(tip); GameTooltip:Show() end
  end)
  b:SetScript("OnLeave", function(self) self.text:SetTextColor(C(Look.BONE)); GameTooltip:Hide() end)
  return b
end

local function Build()
  F = CreateFrame("Frame", "DeathNoteFrame", UIParent, "BackdropTemplate")
  F:SetSize(W, H)
  F:SetFrameStrata("HIGH")
  F:SetClampedToScreen(true)
  F:SetMovable(true)
  F:EnableMouse(true)
  F:RegisterForDrag("LeftButton")
  F:Hide()
  F:SetScript("OnDragStart", function(self) self:StartMoving() end)
  F:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    if self.SetUserPlaced then pcall(self.SetUserPlaced, self, false) end   -- Position nur in DeathNoteDB
    UX.SavePoint()
  end)
  F:SetScript("OnShow", function()
    Look.Sound("open")
    if dirty then Refresh() end
  end)
  F:SetScript("OnHide", function()
    HideMenu()
    if P and P.enemy and P.enemy.note:HasFocus() then P.enemy.note:ClearFocus() end
    if LP and LP.search:HasFocus() then LP.search:ClearFocus() end
  end)
  tinsert(UISpecialFrames, "DeathNoteFrame")

  -- Einband
  F:SetBackdrop({ edgeFile = Look.TEX.border, edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 } })
  F:SetBackdropBorderColor(0.02, 0.02, 0.02, 1)
  local cover = Tex(F, "BACKGROUND", Look.TEX.cover, -8)
  cover:SetPoint("TOPLEFT", 4, -4); cover:SetPoint("BOTTOMRIGHT", -4, 4)
  -- Falz: dunkler Streifen zwischen den Seiten
  local spine = F:CreateTexture(nil, "BORDER")
  spine:SetColorTexture(0, 0, 0, 0.85)
  spine:SetPoint("TOPLEFT", 394, -40)
  spine:SetPoint("BOTTOMLEFT", 394, 10)
  spine:SetWidth(12)

  local title = Look.Text(F, "title", 26, Look.BONE)
  title:SetPoint("TOPLEFT", 22, -9)
  title:SetText("DeathNote")
  title:SetShadowOffset(1, -1)
  title:SetShadowColor(0, 0, 0, 1)

  -- Schliessen, Zahnrad (Hausordnung), "?" (Gebrauchsanweisung)
  local close = HeadButton("×", 22)
  close:SetSize(26, 26)
  close:SetPoint("TOPRIGHT", -8, -9)
  close:SetScript("OnClick", function() Look.Sound("click"); F:Hide() end)

  local gear = CreateFrame("Button", nil, F)
  gear:SetSize(20, 20)
  gear:SetPoint("RIGHT", close, "LEFT", -6, 0)
  local gt = gear:CreateTexture(nil, "ARTWORK")
  gt:SetAllPoints()
  Look.Tex(gt, "Interface\\Buttons\\UI-OptionsButton", 0.8, 0.75, 0.65, 1)
  gt:SetDesaturated(true)
  gt:SetVertexColor(C(Look.BONE))
  gear:SetScript("OnClick", function()
    Look.Sound("click")
    if state.panel == "settings" then UI.ClosePanel() else UI.OpenPanel("settings") end
  end)
  gear:SetScript("OnEnter", function(self)
    gt:SetVertexColor(C(Look.RED_ON_BLACK))
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText(L.HEAD_RULES)
    GameTooltip:Show()
  end)
  gear:SetScript("OnLeave", function()
    gt:SetVertexColor(C(Look.BONE))
    GameTooltip:Hide()
  end)

  local help = HeadButton("?", 16, L.TIP_HELP_BUTTON)
  help:SetSize(20, 20)
  help:SetPoint("RIGHT", gear, "LEFT", -8, 0)
  help:SetScript("OnClick", function()
    Look.Sound("click")
    if state.panel == "help" then UI.ClosePanel() else UI.OpenPanel("help") end
  end)
  F.help = help

  -- Reiter: Lederlaschen auf dem Einband, der aktive mit blutroter Unterkante
  F.tabs = {}
  for _, f in ipairs(UX.FILTERS) do
    local t = CreateFrame("Button", nil, F)
    -- 1.2.0: mit dem Freundesbuch heisst der vierte Reiter "Gilde & Freunde" und ist breiter (bis zum "?")
    local wide = f.id == "guild" and GF.HasFriends()
    t.base = wide and 132 or 104
    t:SetSize(t.base, 24)
    t.id, t.label = f.id, wide and L.TAB_GUILD_FRIENDS or L[f.key]
    local tb = t:CreateTexture(nil, "BACKGROUND")
    tb:SetAllPoints()
    tb:SetColorTexture(1, 1, 1, 0.05)
    local hl = t:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(1, 1, 1, 0.06)
    t.mark = t:CreateTexture(nil, "ARTWORK")
    t.mark:SetColorTexture(C(Look.RED, 1))
    t.mark:SetHeight(2)
    t.mark:SetPoint("BOTTOMLEFT", 6, 0); t.mark:SetPoint("BOTTOMRIGHT", -6, 0)
    t.text = Look.Text(t, "body", 11, Look.BONE)
    t.text:SetPoint("CENTER", 0, 1)
    t.text:SetWordWrap(false)
    t:SetScript("OnClick", function(self) Look.Sound("click"); SetFilter(self.id) end)
    F.tabs[#F.tabs + 1] = t
  end
  GF.LayoutTabs()

  UX.BuildLeftPage()

  RP = CreateFrame("Frame", nil, F)
  RP:SetSize(PAGE_W, PAGE_H)
  RP:SetPoint("TOPLEFT", 404, -44)
  local rbg = Tex(RP, "BACKGROUND", Look.TEX.page)
  rbg:SetAllPoints()
  UX.BuildPoster()

  UX.RegisterConfirms()

  UX.AutoScale()
  ApplyScale()
  local pt = Look.Setting("ui.point")
  if type(pt) == "table" and pt[1] then
    F:SetPoint(pt[1], UIParent, pt[2] or pt[1], pt[3] or 0, pt[4] or 0)
  else
    F:SetPoint("CENTER", 0, 40)
  end
  local sort = Look.Setting("ui.sort", "rank")
  if SORT_LABEL[sort] then state.sort = sort end
  local gv = Look.Setting("ui.guildView", "enemy")
  if gv == "member" or gv == "enemy" or (gv == "hunt" and GF.HasHunts()) then state.gview = gv end
  local gs = Look.Setting("ui.guildSource", "all")
  if gs == "all" or gs == "guild" or gs == "friends" then state.gsource = gs end
end

function UI.ConfirmDelete(key)
  local e = Store().Get(key)
  if not e then return end
  Confirm("DEATHNOTE_DELETE", Look.Name(e), key)
end

function UI.Toggle()
  if not ready then return end
  if not F then Build() end
  if F:IsShown() then F:Hide() else F:Show() end
end

function UI.Open()
  if not ready then return end
  if not F then Build() end
  if not F:IsShown() then F:Show() end
end

-- Zeile des Gewaehlten ins Bild rollen
local function ScrollTo(pred)
  for i = 1, #data do
    if pred(data[i]) then
      state.offset = math.max(0, math.min(i - 1, #data - ROWS))
      break
    end
  end
  BindRows()
end

-- Plakat eines bestimmten Taeters aufschlagen (aus dem Journal, der Suche, der Meldung oder von aussen)
function UI.ShowEnemy(key)
  local e = ready and Store().Get(key)
  if not e then return end
  UI.Open()
  UI.ClearSearch()
  HideMenu()
  if e.status == "suspect" then state.filter, state.osel = "open", key
  else state.filter, state.selected = "wanted", key end
  state.offset = 0
  if state.panel then UI.ClosePanel(true) end
  Refresh()
  ScrollTo(function(x) return x.key == key end)
end

-- einen Todesfall aufschlagen: offen unter "Zu klären", sonst im Todesjournal
function UI.ShowCase(d)
  if not ready or type(d) ~= "table" then return end
  UI.Open()
  UI.ClearSearch()
  HideMenu()
  local open = false
  for _, x in ipairs((OpenCases())) do if x == d then open = true; break end end
  if open then state.filter, state.osel = "open", d
  else state.filter, state.deathRef, state.death = "journal", d, nil end
  state.offset = 0
  if state.panel then UI.ClosePanel(true) end
  Refresh()
  ScrollTo(function(x) return x == d end)
end

-- Abschussliste aufschlagen (/dn jagd ohne Name, nach dem Freigeben)
function UI.ShowHunts(key)
  if not ready or not GF.HasHunts() then return end
  UI.Open()
  UI.ClearSearch()
  HideMenu()
  state.filter, state.gview = "guild", "hunt"
  if type(key) == "string" then
    state.hselected = key
    -- 1.2.0 fix: Freigabe nur fuer Freunde bei Quelle "Gilde" (oder umgekehrt): die Quelle wechselt auf "Alle"
    if GF.HasFriends() and not GCall("Hunt", key, GF.Src()) and GCall("Hunt", key, "all") then
      state.gsource = "all"
      Set("ui.guildSource", "all")
      mv.dirty = true
      gpart.src = nil
    end
  end
  state.offset = 0
  if state.panel then UI.ClosePanel(true) end
  Refresh()
  if type(key) == "string" then ScrollTo(function(x) return x.key == key end) end
end

------------------------------------------------------------------------
-- Minimap-Knopf (ohne Bibliothek) und AddonCompartment
------------------------------------------------------------------------
local mm

function UX.Radius() return Minimap:GetWidth() / 2 + 6 end

local function PlaceAt(deg)
  local a = math.rad(deg)
  local r = UX.Radius()
  mm:ClearAllPoints()
  mm:SetPoint("CENTER", Minimap, "CENTER", math.cos(a) * r, math.sin(a) * r)
end

local function AlarmOn() return Look.Setting("alert.enabled", true) ~= false end

local function MinimapTip(owner)
  GameTooltip:SetOwner(owner, "ANCHOR_LEFT")
  GameTooltip:SetText("DeathNote", Look.BONE[1], Look.BONE[2], Look.BONE[3])
  if ready then
    local w, s, _, o = Counts()
    GameTooltip:AddLine(Look.Join(Fmt(L.MM_WANTED, { count = w }), (s + o) > 0 and Fmt(L.MM_UNSOLVED, { count = s + o })), 1, 1, 1)
    if not AlarmOn() then GameTooltip:AddLine(L.MM_ALERT_OFF, 1, 0.45, 0.4) end
  end
  GameTooltip:AddLine(L.MM_CLICK, 0.8, 0.8, 0.8)
  GameTooltip:AddLine(L.MM_MIDDLE, 0.8, 0.8, 0.8)
  if owner == mm then GameTooltip:AddLine(L.MM_DRAG, 0.6, 0.6, 0.6) end
  GameTooltip:Show()
end

-- Alarm an/aus (wie /dn still); das Symbol zeigt "aus" halb durchsichtig
function UI.ToggleAlarm()
  if not ready then return end
  local on = not AlarmOn()
  Set("alert.enabled", on)
  if ns.Util and ns.Util.Print then ns.Util.Print(on and L.MM_CHAT_ALERT_ON or L.MM_CHAT_ALERT_OFF) end
end

local function Click(mouse)
  if mouse == "RightButton" then
    UI.Open()
    if F then UI.OpenPanel("settings") end
  elseif mouse == "MiddleButton" then
    UI.ToggleAlarm()
  else
    UI.Toggle()
  end
end

-- nur waehrend des Ziehens aktiv
local function DragUpdate(self)
  local mx, my = Minimap:GetCenter()
  if not mx then return end
  local cx, cy = GetCursorPosition()
  local s = Minimap:GetEffectiveScale()
  self.angle = math.deg(math.atan2(cy / s - my, cx / s - mx)) % 360
  PlaceAt(self.angle)
end

function UX.BuildMinimap()
  if not Minimap then return end
  mm = CreateFrame("Button", "DeathNoteMinimapButton", Minimap)
  mm:SetSize(31, 31)
  mm:SetFrameStrata("MEDIUM")
  mm:SetFrameLevel(8)
  mm:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
  local icon = mm:CreateTexture(nil, "ARTWORK")
  icon:SetSize(20, 20)
  icon:SetPoint("TOPLEFT", 6, -5)
  Look.Tex(icon, Look.TEX.icon, 0.5, 0.05, 0.05, 1)
  mm.icon = icon
  local border = mm:CreateTexture(nil, "OVERLAY")
  border:SetSize(53, 53)
  border:SetPoint("TOPLEFT")
  border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  mm:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp")
  mm:RegisterForDrag("LeftButton")
  mm:SetScript("OnClick", function(_, mouse) Click(mouse) end)
  mm:SetScript("OnEnter", MinimapTip)
  mm:SetScript("OnLeave", GameTooltip_Hide)
  mm:SetScript("OnDragStart", function(self)
    GameTooltip:Hide()
    self.dragging = true
    self:SetScript("OnUpdate", DragUpdate)
  end)
  mm:SetScript("OnDragStop", function(self)
    self:SetScript("OnUpdate", nil)
    self.dragging = false
    if self.angle then Set("ui.minimap.angle", math.floor(self.angle + 0.5)) end
  end)
end

function UI.UpdateMinimap()
  if Look.Setting("ui.minimap.hide", false) then
    if mm then mm:Hide() end
    return
  end
  if not mm then UX.BuildMinimap() end
  if mm then
    PlaceAt(Look.Setting("ui.minimap.angle", 215) or 215)
    mm.icon:SetAlpha(AlarmOn() and 1 or 0.45)
    mm:Show()
  end
end

-- Globale Namen fuer die TOC-Felder AddonCompartmentFunc*
function DeathNote_OnCompartmentClick(_, mouse) Click(mouse) end
function DeathNote_OnCompartmentEnter(_, owner) MinimapTip(owner) end
function DeathNote_OnCompartmentLeave() GameTooltip:Hide() end

------------------------------------------------------------------------
-- Bus
------------------------------------------------------------------------
ns:On("READY", function()
  ready = true
  UI.UpdateMinimap()
end)
ns:On("TOGGLE_UI", function() UI.Toggle() end)
ns:On("ENEMY_UPDATED", RequestRefresh)
ns:On("DEATH_RECORDED", RequestRefresh)
ns:On("REVENGE", RequestRefresh)
ns:On("GUILD_UPDATED", function() mv.dirty = true; gpart.src = nil; RequestRefresh() end)
ns:On("GUILD_SIGHTING", function() if state.filter == "guild" then RequestRefresh() end end)
ns:On("HUNT_BAGGED", function() if state.filter == "guild" then RequestRefresh() end end)
-- Der Store zieht einen Eintrag auf einen neuen Schluessel um: Auswahl und Notizfeld ziehen mit
ns:On("ENEMY_REKEYED", function(old, new)
  if type(old) ~= "string" or type(new) ~= "string" or old == new then return end
  if state.selected == old then state.selected = new end
  if state.osel == old then state.osel = new end
  if P and P.enemy and P.enemy.note.key == old then P.enemy.note.key = new end
  if P and P.enemy and P.enemy.specSig and P.enemy.specSig:find("\0" .. old .. "\0", 1, true) then P.enemy.specSig = nil end
  RequestRefresh()
end)
ns:On("SETTINGS_CHANGED", function(path)
  if type(path) == "string" and path:find("^ui%.minimap") and not (mm and mm.dragging == false and path == "ui.minimap.angle") then
    UI.UpdateMinimap()
  end
  if path == "alert.enabled" and mm then mm.icon:SetAlpha(AlarmOn() and 1 or 0.45) end
  if path == "ui.scale" then ApplyScale() end
  if path == "ui.guildCollapsed" then collapseVer = collapseVer + 1; if MemberView() then RequestRefresh() end end
  if type(path) == "string" and path:find("^guild%.") then RequestRefresh() end
  if F and F:IsShown() and state.panel == "settings" then UI.FillSettings() end
end)
