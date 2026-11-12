local ADDON, ns = ...

-- Naeherungs-Alarm: Fahndungs-Popup oben mittig, Ton, roter Randblitz, Klick visiert an.
-- Dazu ns.Look: gemeinsame Optik-Helfer fuer Alert, UI und Extras (Schriften, Texturen, Farben).

local Look = {}
ns.Look = Look
-- Texte (1.2.0): ns.L ist ab ADDON_LOADED gefuellt; L.KEY nur in Funktionen lesen, nie auf Dateiebene
local L, Fmt = ns.L, ns.F

-- Medienpfad immer ueber den Ordnernamen (ADDON), nie fest verdrahtet
local MEDIA = "Interface\\AddOns\\" .. ADDON .. "\\Media\\"
Look.MEDIA = MEDIA
Look.TEX = {
  paper   = MEDIA .. "paper.tga",     -- Fahndungsplakat
  page    = MEDIA .. "page.tga",      -- Notizbuchseite
  cover   = MEDIA .. "cover.tga",     -- schwarzer Ledereinband
  ink     = MEDIA .. "ink.tga",       -- Federstrich
  mugshot = MEDIA .. "mugshot.tga",
  edge    = MEDIA .. "edge.tga",
  nr1     = MEDIA .. "stamp_nr1.tga",
  rache   = MEDIA .. "stamp_rache.tga",
  pardon  = MEDIA .. "stamp_pardon.tga",
  suspect = MEDIA .. "stamp_suspect.tga",
  guild   = MEDIA .. "stamp_guild.tga",
  hunt    = MEDIA .. "stamp_hunt.tga",    -- ZUR JAGD FREIGEGEBEN (Abschussliste, 1.2.0)
  check   = MEDIA .. "check.tga",
  pin     = MEDIA .. "pin.tga",
  skull   = MEDIA .. "skull.tga",
  icon    = MEDIA .. "icon.tga",
  tape    = MEDIA .. "tape.tga",
  tri     = MEDIA .. "tri.tga",       -- Dreieck auf/zu (Gilde nach Mitglied)
  white   = "Interface\\Buttons\\WHITE8X8",
  border  = "Interface\\Tooltips\\UI-Tooltip-Border",
  classes = "Interface\\Glues\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES",
}
-- Nur Client-Schriften (Pfade wie in OpenMap bzw. ElvUI-LibSharedMedia belegt), je Liste der Reihe nach
-- versucht, zuletzt GameFontNormal.
Look.FONT = {
  title = { "Fonts\\SKURRI_CYR.TTF", "Fonts\\SKURRI.TTF" },        -- kantig: Titel, Alarm-Kopf
  hand  = { "Fonts\\MORPHEUS.TTF", "Fonts\\MORPHEUS_CYR.TTF" },    -- Feder-Handschrift, WANTED
  body  = { "Fonts\\FRIZQT__.TTF" },                                -- Beschriftung
  type  = { "Fonts\\NIM_____.ttf" },                                -- Aktenvermerk
}
Look.FONT.head = Look.FONT.hand
-- 1.2.0: Schriften je Schriftsystem der aktiven Sprache (Locale.FONTS); Latein-West bleibt wie oben
if ns.Locale and ns.Locale.OnActivate then
  ns.Locale.OnActivate(function()
    for _, kind in ipairs({ "title", "hand", "body", "type" }) do Look.FONT[kind] = ns.Locale.FontList(kind) end
    Look.FONT.head = Look.FONT.hand
  end)
end
-- Farbwelt: Schwarz, Knochenweiss, Tintenschwarz, Blutrot als einzige Akzentfarbe
Look.INK   = { 0.08, 0.07, 0.07 }
Look.RED   = { 0.72, 0.04, 0.04 }       -- grosse Schrift (ab 16 pt) und Flaechen auf Papier
Look.RED_INK = { 0.55, 0.03, 0.03 }     -- kleine rote Schrift auf Papier (Kontrast ab 4,5:1)
Look.RED_ON_BLACK = { 1.0, 0.40, 0.33 }   -- rote Schrift auf dem schwarzen Einband, Popup und Meldung
Look.BONE  = { 0.93, 0.90, 0.82 }
Look.CREAM = Look.BONE
Look.FADED = { 0.38, 0.35, 0.31 }
Look.BLACK = { 0.05, 0.045, 0.045 }
Look.TAB_OFF = { 0.62, 0.59, 0.54 }     -- inaktive Reiter auf dem Einband
Look.WARN = { 1.0, 0.62, 0.18 }         -- Warnfarbe im Popup (Ziel hoeher als du), auf Schwarz
-- Tinte auf Papier: Deckkraft je Rolle. Gemessen gegen Seite und Plakat (tests/ui Kontrast-Waechter):
-- jede Rolle fuer kleine Schrift haelt 4,5:1, "hand" und "off" gelten nur fuer Schrift ab 16 pt.
Look.TONE = { ink = 1, label = 0.85, sub = 0.8, hint = 0.8, hand = 0.7, off = 0.5 }

local issecret = issecretvalue or function() return false end
function Look.Secret(v) return issecret(v) and true or false end
-- Wahrheitswert, der ein Secret wie "falsch" behandelt (nie boolean-Test auf Secrets)
function Look.True(v)
  if issecret(v) then return false end
  return v and true or false
end

-- list (1.2.0, optional): eigene Schriftliste statt Look.FONT[kind], z. B. fuer den Eigennamen einer Sprache
function Look.Font(fs, kind, size, flags, list)
  -- 1.2.2: kind, size and flags stay on the string (Look.FitText steps through the sizes of the same font)
  if not list then fs.fontKind, fs.fontSize, fs.fontFlags = kind, size, flags end
  list = list or Look.FONT[kind] or Look.FONT.body
  for i = 1, #list do
    if fs:SetFont(list[i], size or 12, flags or "") then return fs end
  end
  -- Standardschrift des Clients (deckt dessen Sprache), dann das Schriftobjekt
  local std = ns.Locale and ns.Locale.Global and ns.Locale.Global("STANDARD_TEXT_FONT")
  if type(std) == "string" and fs:SetFont(std, size or 12, flags or "") then return fs end
  fs:SetFontObject(GameFontNormal)
  return fs
end

-- Schriftliste fuer einen Text in einer bestimmten Sprache (Sprachliste der Hausordnung)
function Look.FontOf(code, kind)
  if ns.Locale and ns.Locale.FontList then return ns.Locale.FontList(kind or "body", code) end
  return Look.FONT[kind or "body"]
end

-- FontString in einem Rutsch
function Look.Text(parent, kind, size, color, flags, layer)
  local fs = parent:CreateFontString(nil, layer or "OVERLAY")
  Look.Font(fs, kind, size, flags)
  local c = color or Look.INK
  fs:SetTextColor(c[1], c[2], c[3], c[4] or 1)
  fs:SetShadowOffset(0, 0)
  return fs
end

-- Textur mit Rueckfallfarbe (kein gruenes Fehlquadrat, falls die Datei fehlt)
function Look.Tex(tex, path, r, g, b, a)
  local ok = tex:SetTexture(path)
  if ok == false then tex:SetColorTexture(r or 0.5, g or 0.4, b or 0.3, a or 1) end
  return tex
end

function Look.ClassIcon(tex, class)
  local tc = class and CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[class]
  if tc then
    Look.Tex(tex, Look.TEX.classes, 0.3, 0.3, 0.3, 1)
    tex:SetTexCoord(tc[1], tc[2], tc[3], tc[4])
  else
    Look.Tex(tex, Look.TEX.skull, 0.2, 0.2, 0.2, 1)
    tex:SetTexCoord(0, 1, 0, 1)
  end
end

function Look.ClassRGB(class)
  if class and ns.Util and ns.Util.ClassColor then
    local r, g, b = ns.Util.ClassColor(class)
    if r then return r, g, b end
  end
  return 0.85, 0.85, 0.85
end

function Look.Name(e)
  if not e then return "?" end
  if ns.Util and ns.Util.Display then return ns.Util.Display(e) end
  return e.display or e.name or e.key or "?"
end

-- Name fuer /targetexact und die Chat-Eingabe. nil, wenn er Steuerzeichen, "|" oder "/" enthaelt oder zu
-- lang ist: ein Zeilenumbruch wuerde im Makro des Anvisieren-Knopfs eine weitere Befehlszeile ergeben.
local TARGET_MAX = 60
local function SafeTargetName(n)
  if type(n) ~= "string" or Look.Secret(n) or n == "" or #n > TARGET_MAX then return nil end
  if n:find("[%c|/\\]") then return nil end
  return n
end
function Look.TargetName(e)
  if type(e) ~= "table" then return nil end
  if ns.Util and ns.Util.TargetName then
    local ok, n = pcall(ns.Util.TargetName, e)
    if ok and type(n) == "string" and not Look.Secret(n) and n ~= "" then return SafeTargetName(n) end
  end
  return SafeTargetName(e.name)
end

------------------------------------------------------------------------
-- Bausteine fuer Text: jede wiederkehrende Form genau einmal (Waechter in tests/ui pruefen das)
------------------------------------------------------------------------
-- Zeit: nur zwei Formen. Ago = wie lange her ("vor 2 Tagen"), When = Zeitpunkt ("11.11. 01:01").
-- Beide kommen aus der Logik (ns.Util); hier steht nur der Rueckfall fuer eine aeltere Logik.
function Look.Ago(t)
  if type(t) ~= "number" or Look.Secret(t) then return nil end
  if ns.Util and ns.Util.Ago then return ns.Util.Ago(t) end
  return Look.When(t)
end

-- Notiz wie angezeigt (1.2.0): eigener Text, sonst der Satz einer Uebernahme aus dem Gildenbuch in der
-- aktiven Sprache (gespeichert ist nur ein Merker, Util.NoteOf)
function Look.NoteOf(e)
  if ns.Util and ns.Util.NoteOf then return ns.Util.NoteOf(e) end
  return type(e) == "table" and type(e.note) == "string" and e.note or ""
end

function Look.When(t)
  if type(t) ~= "number" or Look.Secret(t) then return "?" end
  if ns.Util and ns.Util.When then
    local ok, s = pcall(ns.Util.When, t)
    if ok and type(s) == "string" then return s end
  end
  -- Jahr nur, wenn es nicht das laufende ist; Formatzeilen aus der Sprachdatei, geprueft (Util.FmtDate)
  local key = date("%Y", t) ~= date("%Y", time()) and "TIME_FMT_WHEN_YEAR" or "TIME_FMT_WHEN"
  if ns.Util and ns.Util.FmtDate then return ns.Util.FmtDate(key, t) end
  local fmt = L[key]
  if type(fmt) ~= "string" or fmt:gsub("%%[dmyYHM%%]", ""):find("%", 1, true) then fmt = "%m/%d %H:%M" end
  return date(fmt, t)
end

-- Teile einer Unterzeile mit " · " verbinden; leere und nil-Teile fallen weg
local joinScratch = {}
function Look.Join(...)
  local n = 0
  for i = 1, select("#", ...) do
    local v = select(i, ...)
    if v ~= nil and v ~= "" and v ~= false then n = n + 1; joinScratch[n] = tostring(v) end
  end
  local s = table.concat(joinScratch, " · ", 1, n)
  for i = 1, n do joinScratch[i] = nil end
  return s
end

-- Zahl mit Mal-Zeichen: "3×"
function Look.Times(n) return Fmt(L.TIMES, { count = tonumber(n) or 0 }) end

-- Zaehlwort: "1 Opfer", "3 Kandidaten". 1.2.0: text ist ein Sprachtext mit {count} und
-- {count|eins|mehr}; die alte Form Look.Count(n, eins, mehr) bleibt fuer aeltere Aufrufer.
function Look.Count(n, text, many)
  n = tonumber(n) or 0
  if many == nil and type(text) == "string" and text:find("{", 1, true) then return Fmt(text, { count = n }) end
  return n .. " " .. (n == 1 and text or (many or text))
end

-- Kollegen erscheinen in Zeilen, Meldungen und Tooltip-Zeilen nur mit dem Vornamen
function Look.First(name)
  if type(name) ~= "string" or Look.Secret(name) then return "?" end
  return name:match("^(%S+)") or name
end

-- Rolle einer Tat: "kill" (Todesstoss), "assist" (belegt beteiligt), "suspect" (nur vermutet).
-- Aeltere Logik ohne Rolle: sicher = Todesstoss, sonst Verdacht.
function Look.Role(d)
  if type(d) ~= "table" then return "suspect" end
  local r = d.role
  if r == "kill" or r == "assist" or r == "suspect" then return r end
  return d.sure == true and "kill" or "suspect"
end

function Look.Assists(e)
  if type(e) ~= "table" then return 0 end
  return tonumber(e.assists) or 0
end

-- Gewicht fuer Schwellen (Alarm ab n Toden): Todesstoesse plus Beteiligungen
function Look.Weight(e)
  if type(e) ~= "table" then return 0 end
  local S = ns.Store
  if S and S.Weight then
    local ok, w = pcall(S.Weight, e)
    if ok and type(w) == "number" then return w end
  end
  return (tonumber(e.kills) or 0) + Look.Assists(e)
end

-- Kernzahl eines Eintrags in Worten: "2× getötet · 1× beteiligt", "unter Verdacht", "von Hand eingetragen"
function Look.Tally(e)
  if type(e) ~= "table" then return "" end
  if e.status == "suspect" then return L.TALLY_SUSPECT end
  local k, a = tonumber(e.kills) or 0, Look.Assists(e)
  if k == 0 and a == 0 then return e.manual and L.TALLY_MANUAL or L.TALLY_NONE end
  return Look.Join(k > 0 and Fmt(L.TALLY_KILLED, { times = Look.Times(k) }),
    a > 0 and Fmt(L.TALLY_ASSISTED, { times = Look.Times(a) }))
end

-- neueste Tat eines Eintrags (deaths, neueste zuerst)
function Look.LastDeed(e)
  return type(e) == "table" and type(e.deaths) == "table" and e.deaths[1] or nil
end

-- genauester Ort: Unterzone, sonst Zone
function Look.Place(z, sz)
  if type(sz) == "string" and sz ~= "" then return sz end
  if type(z) == "string" and z ~= "" then return z end
  return L.PLACE_UNKNOWN
end

function Look.Setting(path, default)
  if not (ns.Store and ns.Store.Setting) then return default end
  local v = ns.Store.Setting(path)
  if v == nil then return default end
  return v
end

-- Scale-Animation (neue API SetScaleFrom/To, alte SetFromScale/ToScale)
function Look.ScaleAnim(group, from, to, dur, order)
  local a = group:CreateAnimation("Scale")
  if a.SetScaleFrom then
    a:SetScaleFrom(from, from); a:SetScaleTo(to, to)
  elseif a.SetFromScale then
    a:SetFromScale(from, from); a:SetToScale(to, to)
  end
  a:SetDuration(dur); a:SetOrder(order or 1); a:SetSmoothing("OUT")
  return a
end

function Look.AlphaAnim(group, from, to, dur, order, delay)
  local a = group:CreateAnimation("Alpha")
  a:SetFromAlpha(from); a:SetToAlpha(to); a:SetDuration(dur); a:SetOrder(order or 1)
  if delay then a:SetStartDelay(delay) end
  return a
end

-- Klick- und Oeffnen-Geraeusch der Oberflaeche (kurz, ungedrosselt)
function Look.Sound(kind)
  if kind == "alert" or kind == "revenge" then return Look.Alarm(kind) end
  local kit = SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON
  if kit then pcall(PlaySound, kit, "Master") end
end

------------------------------------------------------------------------
-- Alarmton: alle Alarme und Meldungen laufen ueber Look.Alarm
------------------------------------------------------------------------
-- Die API kennt keine Lautstaerke je Ton, nur den Kanal. Darum liegt jeder eigene Ton in fuenf
-- Pegeln als Datei vor (wie RareScanner: <name>-1..4.ogg), erzeugt von tests/ui/make_sounds.sh.
-- Dateinamen klein und ohne Umlaute; der Client unterscheidet unter Linux Gross/Klein.
-- "Kein Ton" steht vorn: der einzige Weg zur Stille (alert.sound folgt der Wahl, siehe Look.SetSound)
-- key ist gespeichert (sprachneutral), lkey der Text in der Sprachtabelle; label fuellt die Aktivierung
Look.SOUNDS = {
  { key = "aus",        lkey = "SOUND_NONE", silent = true },
  { key = "warnung",    lkey = "SOUND_RAIDWARNING", builtin = true },
  { key = "glocke",     lkey = "SOUND_BELL" },
  { key = "gong",       lkey = "SOUND_GONG" },
  { key = "herzschlag", lkey = "SOUND_HEARTBEAT" },
  { key = "feder",      lkey = "SOUND_FEATHER" },
  { key = "sirene",     lkey = "SOUND_SIREN" },
}
Look.SOUND_BY_KEY = {}
for _, s in ipairs(Look.SOUNDS) do Look.SOUND_BY_KEY[s.key] = s end
Look.CHANNELS = { { key = "Master", lkey = "CHANNEL_MASTER" }, { key = "SFX", lkey = "CHANNEL_SFX" },
  { key = "Dialog", lkey = "CHANNEL_DIALOG" } }
if ns.Locale and ns.Locale.OnActivate then
  ns.Locale.OnActivate(function()
    for _, s in ipairs(Look.SOUNDS) do s.label = L[s.lkey] end
    for _, c in ipairs(Look.CHANNELS) do c.label = L[c.lkey] end
  end)
end
local CHANNEL_OK = { Master = true, SFX = true, Dialog = true, Music = true, Ambience = true }
Look.VOLUMES = 5
Look.SOUND_GAP = 1.5          -- hoechstens ein Alarmton je 1,5 s

-- Tonwahl schreibt beides: den Ton und den alten Hauptschalter alert.sound (Kein Ton = aus)
function Look.SetSound(key)
  local s = Look.SOUND_BY_KEY[key]
  if not (s and ns.Store and ns.Store.Setting) then return end
  if Look.Setting("alert.soundKey") ~= key then ns.Store.Setting("alert.soundKey", key) end
  local on = not s.silent
  if Look.Setting("alert.sound", true) ~= on then ns.Store.Setting("alert.sound", on) end
end

function Look.SoundFile(key, level)
  return MEDIA .. "Sounds\\" .. key .. "_" .. level .. ".ogg"
end

function Look.SoundChoice()
  local key = Look.Setting("alert.soundKey", "warnung")
  local s = Look.SOUND_BY_KEY[key] or Look.SOUND_BY_KEY.warnung
  -- aeltere Einstellung "Ton beim Alarm" aus: gilt als "Kein Ton"
  if Look.Setting("alert.sound", true) == false then s = Look.SOUND_BY_KEY.aus end
  local vol = math.floor(tonumber(Look.Setting("alert.volume", 3)) or 3)
  if vol < 1 then vol = 1 elseif vol > Look.VOLUMES then vol = Look.VOLUMES end
  local ch = Look.Setting("alert.channel", "Master")
  if not CHANNEL_OK[ch] then ch = "Master" end
  return s, vol, ch
end

-- eingebauter Ton ueber SOUNDKIT, sonst Datei-ID wie DBM
local function PlayBuiltin(kind, ch)
  local kit = SOUNDKIT and (kind == "revenge" and SOUNDKIT.LFG_REWARDS or SOUNDKIT.RAID_WARNING)
  if kit then
    local ok, will = pcall(PlaySound, kit, ch)
    if ok and will ~= false then return true end
  end
  if kind ~= "revenge" then
    local ok, will = pcall(PlaySoundFile, 567478, ch)
    return ok and will ~= false
  end
  return false
end

local lastPlay, previewHandle

-- kind: "alert" (Alarm, Gildenalarm), "revenge" (eigener Ton der Rache-Meldung), "preview" (Probe in der
-- Hausordnung, ungedrosselt, auch bei ausgeschaltetem Hauptschalter). Rueckgabe: was gespielt wurde.
function Look.Alarm(kind)
  local preview = kind == "preview"
  if not preview then
    if not Look.Setting("alert.sound", true) then return nil end
    local now = GetTime()
    if lastPlay and now - lastPlay < Look.SOUND_GAP and now >= lastPlay then return nil end
    lastPlay = now
  end
  local s, vol, ch = Look.SoundChoice()
  if s.silent then return nil end                 -- "Kein Ton" gilt auch fuer die Rache-Meldung
  if kind == "revenge" then
    return PlayBuiltin("revenge", ch) and "revenge" or nil
  end
  if not s.builtin then
    local ok, will, handle = pcall(PlaySoundFile, Look.SoundFile(s.key, vol), ch)
    if ok and not Look.Secret(will) and will ~= false then
      if preview then
        if previewHandle and StopSound then pcall(StopSound, previewHandle) end
        previewHandle = (type(handle) == "number") and handle or nil
      end
      return s.key
    end
    -- Datei spielt nicht (fehlt, falscher Name, Format): Rueckfall auf den bisherigen Ton
  end
  return PlayBuiltin("alert", ch) and "warnung" or nil
end

-- Schriftgrade: nur diese Stufen (Design-Regel). 1.2.2: 9 ist die Notstufe fuer Knoepfe, Stempel und Menues,
-- wenn ein Wort einer Sprache sonst nicht passt (vorher schon so im Code, jetzt in der Skala).
Look.SIZE = { 9, 10, 11, 13, 16, 19, 22, 26, 46 }
-- Groessenstufen fuer Buch und Alarm
Look.SCALES = { 0.8, 0.9, 1.0, 1.15, 1.3, 1.5 }

------------------------------------------------------------------------
-- 1.2.2 layout building blocks: one line that shrinks, wraps and shows the whole text in a tooltip,
-- a tooltip only when cut, menus kept on the screen, and a page with standing head and foot and a body
-- that scrolls when its content is taller than the room.
------------------------------------------------------------------------
-- real width of a text on one line (GetUnboundedStringWidth; GetStringWidth can stop at the set width)
function Look.TextW(fs)
  local f = fs.GetUnboundedStringWidth
  if f then
    local ok, w = pcall(f, fs)
    if ok and type(w) == "number" and not Look.Secret(w) then return w end
  end
  f = fs.GetStringWidth
  if not f then return nil end
  local ok, w = pcall(f, fs)
  if ok and type(w) == "number" and not Look.Secret(w) then return w end
  return nil
end

-- is the shown text cut (ellipsis or lines missing)? Secret-safe like Details; nil when the client cannot say
function Look.IsCut(fs)
  if not fs.IsTruncated then return nil end
  local ok, v = pcall(fs.IsTruncated, fs)
  if not ok or Look.Secret(v) or v == nil then return nil end
  return v and true or false
end

-- height of a text in UI units (GetStringHeight; fallback: number of lines x size)
function Look.TextH(fs, lines)
  local ok, h = pcall(fs.GetStringHeight, fs)
  if ok and type(h) == "number" and not Look.Secret(h) and h > 0 then return h end
  local t = fs.GetText and fs:GetText()
  if type(t) ~= "string" or t == "" then return 0 end
  return (lines or 1) * ((fs.fontSize or 12) + 2)
end

-- Look.FitText(fs, text, opts): set text so that it is never cut silently. Order of round 1.2.2:
-- it fits: done; else the next smaller size of opts.sizes (default: the current one only); then wrap up to
-- opts.lines lines in the smallest size; last an ellipsis by the client and fs.full = text for the tooltip
-- (Look.TipIfCut). opts.must = true: never an ellipsis worth hiding (no tooltip possible there): smallest size and
-- all lines. opts.kind/flags: font (default: what Look.Font set last). Returns true when the whole text shows.
-- Costs: one SetText per tried size; same text and width as last time: nothing.
function Look.FitText(fs, text, opts)
  opts = opts or {}
  text = text or ""
  local width = opts.width or (fs.GetWidth and fs:GetWidth()) or 0
  if fs.fitText == text and fs.fitW == width and fs.fitOpts == opts then return not fs.cut end
  fs.fitText, fs.fitW, fs.fitOpts = text, width, opts
  fs.fit, fs.full = true, text
  local kind, flags = opts.kind or fs.fontKind or "body", opts.flags or fs.fontFlags
  local sizes = opts.sizes or { fs.fontSize or 11 }
  local lines = opts.lines or 1
  local function size(s)
    if fs.fontSize ~= s or fs.fontKind ~= kind then Look.Font(fs, kind, s, flags) end
  end
  local function cut()
    local c = Look.IsCut(fs)
    if c ~= nil then return c end
    local w = Look.TextW(fs)
    return w ~= nil and width > 0 and w > width + 0.5
  end
  if fs.SetMaxLines then fs:SetMaxLines(lines) end
  fs:SetWordWrap(false)
  for i = 1, #sizes do
    size(sizes[i])
    fs:SetText(text)
    if not cut() then fs.cut = false; return true end
    -- opts.wrapFirst: running text wraps in this size before it gets smaller
    if lines > 1 and opts.wrapFirst then
      fs:SetWordWrap(true)
      fs:SetText(text)
      if not cut() then fs.cut = false; return true end
      fs:SetWordWrap(false)
    end
  end
  if lines > 1 then
    fs:SetWordWrap(true)
    fs:SetText(text)
    if not cut() then fs.cut = false; return true end
  end
  fs.cut = true
  return false
end

-- tooltip with the whole text over owner, only while fs is cut (fs.full from Look.FitText, else its text)
local function TipEnter(self)
  local fs = self.cutFs
  if not fs or not (fs.cut or Look.IsCut(fs)) then return end
  local t = fs.full or (fs.GetText and fs:GetText())
  if type(t) ~= "string" or t == "" or Look.Secret(t) then return end
  GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
  GameTooltip:SetText(t, Look.BONE[1], Look.BONE[2], Look.BONE[3], 1, true)
  GameTooltip:Show()
  self.cutTip = true
end
local function TipLeave(self)
  if self.cutTip then self.cutTip = nil; GameTooltip:Hide() end
end
function Look.TipIfCut(owner, fs)
  if not owner.cutHooked then
    owner.cutHooked = true
    if owner:GetScript("OnEnter") then owner:HookScript("OnEnter", TipEnter) else owner:SetScript("OnEnter", TipEnter) end
    if owner:GetScript("OnLeave") then owner:HookScript("OnLeave", TipLeave) else owner:SetScript("OnLeave", TipLeave) end
    if owner.EnableMouse and not owner:IsMouseEnabled() then owner:EnableMouse(true) end
  end
  owner.cutFs = fs
  fs.tipOwner = owner
  return owner
end

-- frame opened at the cursor: clamped to the screen and opening away from the nearer edges
-- (cursor right of the middle: grows to the left; in the lower half: grows upwards)
function Look.KeepOnScreen(frame, x, y)
  frame:SetClampedToScreen(true)
  if type(x) ~= "number" or type(y) ~= "number" or Look.Secret(x) or Look.Secret(y) then return end
  local w, h = UIParent:GetWidth(), UIParent:GetHeight()
  if type(w) ~= "number" or type(h) ~= "number" or Look.Secret(w) or Look.Secret(h) then w, h = nil, nil end
  local right = w and x > w / 2
  local low = h and y < h / 2
  local p = (low and "BOTTOM" or "TOP") .. (right and "RIGHT" or "LEFT")
  frame:ClearAllPoints()
  frame:SetPoint(p, UIParent, "BOTTOMLEFT", x, y)
  frame.openPoint = p
end

-- Look.Page(parent, opts): standing head (above opts.top), body that scrolls (only stacked from the top,
-- nothing hangs at its bottom), standing foot (opts.foot high, buttons and foot lines).
-- opts: top (px from the top of parent), foot (px), w, h (size of parent), bar (px from the right edge for the
-- scroll bar), step (px per mouse wheel step). Fields: page.body (scroll child), page.foot, page.scroll, page.bar.
-- page:Layout(height) sets the height of the content, shows the bar only when needed, keeps the offset in range;
-- page:Top() goes back to the start. No OnUpdate: the bar and the wheel move it, nothing else.
local function PageSet(page, v)
  v = math.max(0, math.min(page.range or 0, math.floor((v or 0) + 0.5)))
  page.offset = v
  page.scroll:SetVerticalScroll(v)
  if page.bar:GetValue() ~= v then page.bar:SetValue(v) end
end
local function PageLayout(page, height)
  height = math.max(1, math.ceil(height or page.used or 1))
  page.used = height
  page.body:SetHeight(height)
  page.range = math.max(0, height - page.viewH)
  page.bar:SetMinMaxValues(0, page.range)
  page.bar:SetShown(page.range > 0)
  PageSet(page, page.offset or 0)
  return page.range > 0
end
function Look.Page(parent, opts)
  local top, foot = opts.top or 0, opts.foot or 0
  local w, h = opts.w or parent:GetWidth(), opts.h or parent:GetHeight()
  local page = { viewH = h - top - foot, offset = 0, range = 0, step = opts.step or 40 }
  local sf = CreateFrame("ScrollFrame", nil, parent)
  sf:SetPoint("TOPLEFT", 0, -top)
  sf:SetSize(w, page.viewH)
  local body = CreateFrame("Frame", nil, sf)
  body:SetPoint("TOPLEFT")      -- like AceGUI's ScrollFrame container: anchored, then made the scroll child
  body:SetSize(w, 1)
  sf:SetScrollChild(body)
  sf:EnableMouseWheel(true)
  sf:SetScript("OnMouseWheel", function(_, delta) PageSet(page, page.offset - delta * page.step) end)
  local ft = CreateFrame("Frame", nil, parent)
  ft:SetPoint("BOTTOMLEFT", 0, 0)
  ft:SetSize(w, math.max(1, foot))
  -- scroll bar in the style of the list: 14 px grip, 5 px visible
  local bar = CreateFrame("Slider", nil, parent)
  bar:SetOrientation("VERTICAL")
  bar:SetSize(14, page.viewH - 8)
  bar:SetPoint("TOPRIGHT", -(opts.bar or 6), -top - 4)
  local track = bar:CreateTexture(nil, "BACKGROUND")
  track:SetColorTexture(Look.INK[1], Look.INK[2], Look.INK[3], 0.12)
  track:SetWidth(5)
  track:SetPoint("TOP"); track:SetPoint("BOTTOM")
  local thumb = bar:CreateTexture(nil, "OVERLAY")
  thumb:SetColorTexture(0, 0, 0, 0)
  thumb:SetSize(14, 34)
  bar:SetThumbTexture(thumb)
  local tv = bar:CreateTexture(nil, "OVERLAY", nil, 1)
  tv:SetColorTexture(Look.INK[1], Look.INK[2], Look.INK[3], 0.75)
  tv:SetWidth(5)
  tv:SetPoint("TOP", thumb, "TOP"); tv:SetPoint("BOTTOM", thumb, "BOTTOM")
  bar:SetMinMaxValues(0, 0)
  bar:SetValueStep(1)
  if bar.SetObeyStepOnDrag then bar:SetObeyStepOnDrag(true) end
  bar:SetScript("OnValueChanged", function(_, v)
    v = math.floor((v or 0) + 0.5)
    if v ~= page.offset then page.offset = v; sf:SetVerticalScroll(v) end
  end)
  bar:Hide()
  page.scroll, page.body, page.foot, page.bar = sf, body, ft, bar
  page.Layout = PageLayout
  page.Set = PageSet
  function page:Top() PageSet(self, 0) end
  -- foot height after its content is known (e.g. a foot line that needs two lines)
  function page:SetFoot(fh)
    self.viewH = h - top - fh
    ft:SetHeight(math.max(1, fh))
    sf:SetHeight(self.viewH)
    bar:SetHeight(self.viewH - 8)
    PageLayout(self)
  end
  return page
end

------------------------------------------------------------------------
-- Gilde: jeder Zugriff auf ns.Guild nur ueber diese Helfer (Sync.lua kann fehlen)
------------------------------------------------------------------------
local GUILD_DEFAULTS = { share = true, receive = true, alert = true, announce = true, sightings = false, minKills = 1,
                         shareManual = true, alertListed = false, friends = true, alertHunt = true,
                         announceHunt = true, huntExpire = 0 }

function Look.HasGuild() return type(ns.Guild) == "table" end

-- ruft ns.Guild[fn](...) geschuetzt; nil, wenn es die Funktion nicht gibt oder sie wirft
function Look.GCall(fn, ...)
  local G = ns.Guild
  local f = type(G) == "table" and G[fn]
  if type(f) ~= "function" then return nil end
  local ok, a, b, c, d = pcall(f, ...)
  if ok then return a, b, c, d end
  return nil
end

-- Gildeneintrag, an dem ein anderer Char als ich beteiligt ist (Opfer oder Eintrager)?
-- Die Logik setzt g.foreign; aeltere Logik: selbst aus victims/listedBy ableiten.
function Look.Foreign(g)
  if type(g) ~= "table" then return false end
  if g.foreign ~= nil then return g.foreign == true end
  local me = Look.Me()
  if type(g.victims) == "table" then
    for v in pairs(g.victims) do if v ~= me then return true end end
  end
  if type(g.listedBy) == "table" then
    for v in pairs(g.listedBy) do if v ~= me then return true end end
  end
  return false
end

-- Teilen-Zustand: { ok, reason, text, short } aus ns.Guild.Health, sonst aus den alten Funktionen
local HEALTH_SHORT = { noguild = "HEALTH_SHORT_NOGUILD", off = "HEALTH_SHORT_OFF", prefix = "HEALTH_SHORT_BLOCKED",
                       blocked = "HEALTH_SHORT_BLOCKED", failing = "HEALTH_SHORT_FAILING", hold = "HEALTH_SHORT_HOLD",
                       quiet = "HEALTH_SHORT_ASKED", ok = "HEALTH_SHORT_ASKED" }
-- src (1.2.0): nil/"guild", "friends" oder "all" (die Logik fasst beide in einem Satz zusammen)
function Look.GuildHealth(src)
  local h = Look.GCall("Health", src)
  if type(h) == "table" and type(h.text) == "string" then
    -- 1.2.0: kein Freund auf der Liste bzw. niemand zum Teilen ist kein Fehler: gedaempft statt rot
    if h.reason == "nofriends" or h.reason == "nobody" then h.calm = true end
    if type(h.short) ~= "string" or h.short == "" then
      local k = HEALTH_SHORT[h.reason]
      h.short = k and L[k] or (h.ok and L.HEALTH_SHORT_ASKED or L.HEALTH_SHORT_FAIL)
    end
    return h
  end
  local name = Look.GCall("Name")
  if not name then
    return { ok = false, reason = "noguild", text = L.HEALTH_NOGUILD, short = L.HEALTH_SHORT_NOGUILD }
  end
  if Look.GCall("Enabled") == false or Look.GuildSetting("share") ~= true then
    return { ok = false, reason = "off", text = L.HEALTH_OFF, short = L.HEALTH_SHORT_OFF }
  end
  local m = Look.GCall("Members")
  local n = type(m) == "table" and #m or 0
  return { ok = true, reason = "ok", text = Fmt(L.GUILD_HEARD, { count = n }), short = L.HEALTH_SHORT_ASKED }
end

-- Gilden-Toetungen sind in Sync.lua bei 20 gedeckelt: 20 heisst "20 oder mehr"
function Look.GKills(n)
  n = tonumber(n) or 0
  if n >= 20 then return Fmt(L.GKILLS_CAP, { count = 20 }) end
  return tostring(n)
end

function Look.GuildSetting(name)
  local v = Look.GCall("Setting", name)
  if v ~= nil then return v end
  return Look.Setting("guild." .. name, GUILD_DEFAULTS[name])
end

-- Gildeneintrag nur von Hand eingetragen (keine Tat)?
function Look.ListedOnly(g)
  if type(g) ~= "table" then return false end
  if g.listedOnly ~= nil then return g.listedOnly == true end
  return (tonumber(g.kills) or 0) == 0 and type(g.listedBy) == "table" and next(g.listedBy) ~= nil
end

-- Namen aus listedBy, aelteste Eintragung zuerst; out wird wiederverwendet
function Look.ListedNames(g, out)
  out = out or {}
  for i = #out, 1, -1 do out[i] = nil end
  if type(g) ~= "table" or type(g.listedBy) ~= "table" then return out end
  for name, t in pairs(g.listedBy) do
    if type(name) == "string" and not Look.Secret(name) then out[#out + 1] = name end
  end
  local lb = g.listedBy
  table.sort(out, function(a, b)
    local ta, tb = tonumber(lb[a]) or 0, tonumber(lb[b]) or 0
    if ta ~= tb then return ta < tb end
    return a < b
  end)
  return out
end

-- Kollegen mit Vornamen: "Anna, Bert" bzw. "Anna, Bert und 3 weitere"
local nameHead = {}
function Look.NameList(names, max)
  local n = #names
  if n == 0 then return "" end
  max = max or 2
  local k = math.min(n, max)
  for i = 1, k do nameHead[i] = Look.First(names[i]) end
  local s = table.concat(nameHead, ", ", 1, k)
  for i = 1, k do nameHead[i] = nil end
  if n <= max then return s end
  return Fmt(L.NAMELIST_MORE, { names = s, count = n - max })
end

-- Rechteck eines Frames in UIParent-Einheiten (links, unten, rechts, oben) oder nil
function Look.Rect(f)
  if not (f and f.GetLeft and f.GetTop) then return nil end
  local ok1, l = pcall(f.GetLeft, f)
  local ok2, b = pcall(f.GetBottom, f)
  local ok3, r = pcall(f.GetRight, f)
  local ok4, t = pcall(f.GetTop, f)
  if not (ok1 and ok2 and ok3 and ok4) then return nil end
  -- jeden Wert einzeln pruefen: ohne Anker oder vor dem Layout liefert der Client nil
  if type(l) ~= "number" or type(b) ~= "number" or type(r) ~= "number" or type(t) ~= "number" then return nil end
  if Look.Secret(l) or Look.Secret(b) or Look.Secret(r) or Look.Secret(t) then return nil end
  local s = f:GetScale()
  if type(s) ~= "number" or Look.Secret(s) or s <= 0 then s = 1 end
  return l * s, b * s, r * s, t * s
end

-- eigener Name ("Vorname Nachname"), nil bei Secret
local myName
function Look.Me()
  if myName then return myName end
  if not UnitName then return nil end
  local ok, n, s = pcall(UnitName, "player")
  if not ok or type(n) ~= "string" or Look.Secret(n) or n == "" then return nil end
  if type(s) == "string" and not Look.Secret(s) and s ~= "" then n = n .. " " .. s end
  myName = n
  return n
end

-- Zone des letzten Todes durch diesen Feind
function Look.LastPlace(e)
  local d = Look.LastDeed(e)
  if d then return Look.Place(d.zone, d.subzone) end
end

------------------------------------------------------------------------
-- Alarm
------------------------------------------------------------------------
local Alert = {}
ns.Alert = Alert

local HOLD = 12           -- Sekunden sichtbar
local W, H = 384, 108
local QUEUE_MAX = 9

local ready = false
local lastAlert = {}      -- key -> GetTime()
local queue = {}          -- { { key = k, guild = bool }, ... }
local current             -- key, die gerade angezeigt wird
local currentEntry
local currentGuild        -- true, wenn das Popup einen Gildenfeind zeigt
local popup, button, flash
local hideTimer
local armedFor            -- Ziel-Name, auf den der Secure-Knopf zeigt, solange er sichtbar ist

local function InCombat() return InCombatLockdown() and true or false end

local function Eligible(e)
  if not e or e.status == "pardoned" then return false end
  if not Look.Setting("alert.enabled", true) then return false end
  if e.status == "suspect" then return Look.Setting("alert.suspects", false) and true or false end
  -- von Hand Eingetragene melden auch ohne Kill (sonst wuerde /dn add nie warnen)
  if e.manual then return true end
  -- Schwelle zaehlt Todesstoesse und Beteiligungen
  return Look.Weight(e) >= (tonumber(Look.Setting("alert.minKills", 1)) or 1)
end

-- Gildenfeind (nicht auf der eigenen Liste): eigene Schalter guild.alert / guild.minKills;
-- nur von Hand Eingetragene (ohne Tat) zusaetzlich nur mit guild.alertListed.
-- 1.2.0: gilt fuer Gilde und Freunde; Ziele der Abschussliste (hunt) mit eigenem Schalter guild.alertHunt
local function EligibleGuild(g, hunt)
  if type(g) ~= "table" or type(g.key) ~= "string" then return false end
  local own = ns.Store and ns.Store.Get and ns.Store.Get(g.key)
  if hunt then
    -- 1.2.0 fix: in the own book too. Pardoned there wins (no alarm); an own alarm that fires names the
    -- hit list (OwnLine); suspect or under the own threshold: the hit list alarm
    if own and (own.status == "pardoned" or Eligible(own)) then return false end
    if Look.GCall("HuntHidden", g.key) then return false end
    return Look.GuildSetting("alertHunt") == true
  end
  if own then return false end
  if Look.GuildSetting("alert") ~= true then return false end
  if Look.ListedOnly(g) then return Look.GuildSetting("alertListed") == true end
  return (g.kills or 0) >= (tonumber(Look.GuildSetting("minKills")) or 1)
end

local function SavePoint()
  local p, _, rp, x, y = popup:GetPoint(1)
  if p and ns.Store and ns.Store.Setting then
    ns.Store.Setting("alert.point", { p, rp, x, y })
  end
end

local function Scale()
  local s = popup and popup:GetScale()
  if type(s) ~= "number" or Look.Secret(s) or s <= 0 then return 1 end
  return s
end

local function PlacePopup()
  popup:ClearAllPoints()
  local pt = Look.Setting("alert.point")
  if type(pt) == "table" and pt[1] then
    popup:SetPoint(pt[1], UIParent, pt[2] or pt[1], pt[3] or 0, pt[4] or 0)
  else
    -- unter dem roten Fehlertext des Clients; Abstand in Bildschirmeinheiten, unabhaengig von alert.scale
    popup:SetPoint("TOP", UIParent, "TOP", 0, -190 / Scale())
  end
end

-- Positionen nie zusaetzlich in layout-local.txt (der Client merkt sich gezogene, benannte Frames)
local function NotUserPlaced(f)
  if f.SetUserPlaced then pcall(f.SetUserPlaced, f, false) end
end

-- Secure-Knopf deckungsgleich ueber das Popup legen und Ziel setzen (nur ausserhalb des Kampfes)
local EnsureButton -- vorwaerts

-- Zeigt der (sichtbare) Secure-Knopf auf jemand anderen als das Popup? Das kann nur im Kampf passieren,
-- wenn der Knopf nicht versteckt werden konnte. Dann liegt das Popup eine Schicht ueber dem Knopf und
-- faengt jeden Klick selbst ab: ein Klick visiert nie einen anderen an, als das Popup zeigt.
-- (Das Popup ist kein geschuetzter Frame, SetFrameStrata ist im Kampf erlaubt.)
local function Guard()
  if not popup then return end
  local stale = button and button:IsShown() and (not currentEntry or armedFor ~= Look.TargetName(currentEntry))
  local want = stale and "DIALOG" or "HIGH"
  if popup.strata ~= want then
    popup.strata = want
    popup:SetFrameStrata(want)
  end
end

local function DisarmButton()
  if not button or InCombat() then return end
  button:Hide()
  if not button:IsShown() then armedFor = nil end
  Guard()
end

local function ArmButton()
  if not (popup and popup:IsShown() and currentEntry) or InCombat() then return end
  local name = Look.TargetName(currentEntry)
  -- ohne sicheren Namen nicht scharf schalten (und einen alten Knopf wegnehmen)
  if not name then DisarmButton(); return end
  if not EnsureButton() then return end
  local cx, cy = popup:GetCenter()
  if type(cx) ~= "number" or type(cy) ~= "number" or Look.Secret(cx) or Look.Secret(cy) then return end
  -- GetCenter liefert Werte im Massstab des Popups; der Knopf haengt an UIParent
  local s = Scale()
  local macro = "/cleartarget\n/targetexact " .. name
  button:SetAttribute("type1", "macro")
  button:SetAttribute("macrotext1", macro)
  button:SetAttribute("macrotext", macro)
  button:ClearAllPoints()
  button:SetPoint("CENTER", UIParent, "BOTTOMLEFT", cx * s, cy * s)
  button:SetSize(popup:GetWidth() * s, popup:GetHeight() * s)
  button:Show()
  armedFor = name
  Guard()
end

local function SetHint()
  if not popup or not currentEntry then return end
  local name = Look.TargetName(currentEntry)
  if not name then
    popup.hint:SetText(L.ALERT_HINT_CLOSE)
  elseif armedFor ~= name or not (button and button:IsShown()) then
    popup.hint:SetText(L.ALERT_HINT_COMBAT)
  else
    popup.hint:SetText(L.ALERT_HINT_TARGET)
  end
end

local function UpdateMore()
  if not popup then return end
  local n = #queue
  if n == 0 then popup.more:SetText("")
  else popup.more:SetText(Fmt(L.ALERT_MORE, { count = n })) end
end

local function BuildFlash()
  flash = CreateFrame("Frame", "DeathNoteFlash", UIParent)
  flash:SetAllPoints(UIParent)
  flash:SetFrameStrata("BACKGROUND")
  flash:EnableMouse(false)
  local t = flash:CreateTexture(nil, "BACKGROUND")
  t:SetAllPoints()
  Look.Tex(t, Look.TEX.edge, 1, 0, 0, 0.25)
  t:SetBlendMode("ADD")
  flash:SetAlpha(0)
  flash:Hide()
  -- ein ruhiger Puls; bei Rang 1 ein zweiter, schwaecherer
  local function done() flash:SetAlpha(0); flash:Hide() end
  local g1 = flash:CreateAnimationGroup()
  Look.AlphaAnim(g1, 0, 0.55, 0.25, 1)
  Look.AlphaAnim(g1, 0.55, 0, 0.9, 2)
  g1:SetScript("OnFinished", done)
  local g2 = flash:CreateAnimationGroup()
  Look.AlphaAnim(g2, 0, 0.55, 0.25, 1)
  Look.AlphaAnim(g2, 0.55, 0, 0.9, 2)
  Look.AlphaAnim(g2, 0, 0.35, 0.25, 3)
  Look.AlphaAnim(g2, 0.35, 0, 0.9, 4)
  g2:SetScript("OnFinished", done)
  flash.single, flash.double = g1, g2
end

local function Flash(strong)
  if not flash then BuildFlash() end
  flash.single:Stop(); flash.double:Stop()
  flash:SetAlpha(0)
  flash:Show()
  if strong then flash.double:Play() else flash.single:Play() end
end

local Finish -- vorwaerts

local function Dismiss()
  if not popup or not popup:IsShown() then return end
  if hideTimer then hideTimer:Cancel(); hideTimer = nil end
  if popup.outAnim:IsPlaying() then return end
  popup.inAnim:Stop()
  popup.outAnim:Play()
end
Alert.Dismiss = Dismiss

local EDGE_IDLE = { 0.55, 0.03, 0.03 }
local EDGE_HOT  = { 0.95, 0.10, 0.08 }
local EDGE_NR1  = { 0.90, 0.12, 0.10 }

local function EdgeColor(c) popup:SetBackdropBorderColor(c[1], c[2], c[3], 1) end
local function EdgeIdle() EdgeColor(popup.nr1 and EDGE_NR1 or EDGE_IDLE) end

-- Kante: 2 px, bei Staatsfeind Nr. 1 3 px in hellem Rot
local function SetEdge(nr1)
  popup.nr1 = nr1 and true or false
  popup:SetBackdrop({ edgeFile = Look.TEX.white, edgeSize = nr1 and 3 or 2 })
  EdgeIdle()
end

function Alert.ApplyScale()
  if not popup then return end
  local s = tonumber(Look.Setting("alert.scale", 1)) or 1
  popup:SetScale(s)
  if type(Look.Setting("alert.point")) ~= "table" then PlacePopup() end
  if popup:IsShown() and not InCombat() then ArmButton() end
end

-- Schwarzer Streifen mit blutroter Kante, links das Fahndungsfoto, rechts der frisch eingetragene Name
local function Build()
  popup = CreateFrame("Frame", "DeathNoteAlert", UIParent, "BackdropTemplate")
  popup:SetSize(W, H)
  popup:SetFrameStrata("HIGH")
  popup.strata = "HIGH"
  popup:SetClampedToScreen(true)
  popup:SetMovable(true)
  popup:EnableMouse(true)
  popup:RegisterForDrag("LeftButton")
  popup:Hide()
  SetEdge(false)

  local bg = popup:CreateTexture(nil, "BACKGROUND")
  bg:SetPoint("TOPLEFT", 2, -2); bg:SetPoint("BOTTOMRIGHT", -2, 2)
  Look.Tex(bg, Look.TEX.cover, 0.06, 0.05, 0.05, 1)
  bg:SetTexCoord(0, 1, 0.2, 0.5)
  -- duenne rote Linie unter dem Kopf
  local rule = popup:CreateTexture(nil, "BORDER")
  rule:SetColorTexture(Look.RED[1], Look.RED[2], Look.RED[3], 0.8)
  rule:SetHeight(1)
  rule:SetPoint("TOPLEFT", 86, -27); rule:SetPoint("TOPRIGHT", -10, -27)

  popup.title = Look.Text(popup, "title", 13, Look.RED_ON_BLACK)
  popup.title:SetPoint("TOPLEFT", 86, -9)
  popup.title:SetPoint("RIGHT", popup, "RIGHT", -10, 0)
  popup.title:SetJustifyH("LEFT")
  popup.title:SetWordWrap(false)
  popup.more = Look.Text(popup, "body", 10, Look.BONE)
  popup.more:SetPoint("BOTTOMRIGHT", -10, 8)
  popup.more:SetWordWrap(false)

  -- Fahndungsfoto
  local photo = CreateFrame("Frame", nil, popup)
  photo:SetSize(66, 66)
  photo:SetPoint("LEFT", 10, 0)
  photo:SetFrameLevel(popup:GetFrameLevel() + 3)
  local frame = photo:CreateTexture(nil, "BACKGROUND")
  frame:SetPoint("TOPLEFT", -2, 2); frame:SetPoint("BOTTOMRIGHT", 2, -2)
  frame:SetColorTexture(Look.BONE[1], Look.BONE[2], Look.BONE[3], 0.9)
  local mug = photo:CreateTexture(nil, "BORDER")
  mug:SetAllPoints()
  Look.Tex(mug, Look.TEX.mugshot, 0.45, 0.44, 0.42, 1)
  mug:SetDesaturated(true)
  popup.icon = photo:CreateTexture(nil, "ARTWORK")
  popup.icon:SetSize(44, 44)
  popup.icon:SetPoint("CENTER", 0, -2)
  popup.icon:SetDesaturated(true)
  popup.icon:SetVertexColor(0.85, 0.80, 0.70, 1)
  popup.model = CreateFrame("PlayerModel", nil, photo)
  popup.model:SetAllPoints(mug)
  popup.model:Hide()
  local tape = photo:CreateTexture(nil, "OVERLAY")
  tape:SetSize(34, 14)
  tape:SetPoint("TOP", photo, "TOP", 0, 6)
  Look.Tex(tape, Look.TEX.tape, 0.9, 0.86, 0.7, 0.6)
  tape:SetRotation(0.12)

  -- Name in Feder-Handschrift, Klassenfarbe; erscheint mit kurzer Verzoegerung wie frisch eingetragen.
  -- 1.2.2: die ganze Breite (286 px) fuer den Name; die Stufe steht vorn in der Textzeile. Kein Tooltip moeglich
  -- (der Secure-Knopf liegt darueber): lieber kleiner (22, 19, 16, 13 pt) als gekuerzt.
  popup.name = Look.Text(popup, "hand", 22, nil, nil)
  popup.name:SetPoint("TOPLEFT", 86, -30)
  popup.name:SetWidth(W - 86 - 12)
  popup.name:SetJustifyH("LEFT")
  popup.name:SetWordWrap(false)
  popup.stroke = popup:CreateTexture(nil, "ARTWORK")
  popup.stroke:SetHeight(8)
  popup.stroke:SetPoint("TOPLEFT", popup.name, "BOTTOMLEFT", -2, 3)
  popup.stroke:SetWidth(170)
  Look.Tex(popup.stroke, Look.TEX.ink, 0.6, 0.05, 0.05, 1)
  popup.stroke:SetVertexColor(Look.RED[1], Look.RED[2], Look.RED[3], 0.9)

  popup.line = Look.Text(popup, "body", 11, Look.BONE)
  popup.line:SetPoint("TOPLEFT", popup.name, "BOTTOMLEFT", 0, -6)
  popup.line:SetPoint("RIGHT", popup, "RIGHT", -12, 0)
  popup.line:SetJustifyH("LEFT")
  popup.line:SetWidth(W - 86 - 12)
  popup.line:SetMaxLines(2)

  popup.hint = Look.Text(popup, "body", 10, { 0.62, 0.58, 0.52 })
  popup.hint:SetPoint("BOTTOMLEFT", 86, 8)
  -- 1.2.2: der Hinweis endet vor "+n weitere" (vorher fester Abstand, zwei- und dreistellige Zahlen ragten hinein)
  popup.hint:SetPoint("RIGHT", popup.more, "LEFT", -8, 0)
  popup.hint:SetJustifyH("LEFT")
  popup.hint:SetWordWrap(false)

  -- Einblenden: kurzer Plopp; der Name kommt mit Verzoegerung "in Tinte" nach
  local ia = popup:CreateAnimationGroup()
  Look.AlphaAnim(ia, 0, 1, 0.15, 1)
  Look.ScaleAnim(ia, 1.12, 1, 0.22, 1)
  popup.inAnim = ia
  -- (Alpha-Animationen springen danach auf die eigene Alpha zurueck: darum erst 0->0 halten, dann einblenden)
  local na = popup.name:CreateAnimationGroup()
  Look.AlphaAnim(na, 0, 0, 0.12, 1)
  Look.AlphaAnim(na, 0, 1, 0.6, 2)
  popup.nameAnim = na
  local sa = popup.stroke:CreateAnimationGroup()
  Look.AlphaAnim(sa, 0, 0, 0.6, 1)
  Look.AlphaAnim(sa, 0, 1, 0.3, 2)
  popup.strokeAnim = sa
  local oa = popup:CreateAnimationGroup()
  Look.AlphaAnim(oa, 1, 0, 0.35, 1)
  if oa.SetToFinalAlpha then oa:SetToFinalAlpha(true) end   -- kein Aufblitzen mit Alpha 1 am Ende
  oa:SetScript("OnFinished", function() Finish() end)
  popup.outAnim = oa

  popup:SetScript("OnMouseUp", function(_, mouse)
    if mouse == "RightButton" then Dismiss() end
  end)
  popup:SetScript("OnDragStart", function(self)
    if InCombat() then return end
    self.moving = true
    self:StartMoving()
  end)
  popup:SetScript("OnDragStop", function(self)
    if not self.moving then return end
    self.moving = nil
    self:StopMovingOrSizing()
    NotUserPlaced(self)
    SavePoint()
    ArmButton()
  end)
  popup:SetScript("OnEnter", function() EdgeColor(EDGE_HOT) end)
  popup:SetScript("OnLeave", EdgeIdle)

  PlacePopup()
  Alert.ApplyScale()
end

-- Unsichtbarer Secure-Knopf, erst gebaut, wenn er ausserhalb des Kampfes gebraucht wird
-- (Erzeugen und Einrichten eines geschuetzten Frames im Kampf waere blockiert).
EnsureButton = function()
  if button then return button end
  if InCombat() then return nil end
  -- Unsichtbarer Secure-Knopf: liegt ausserhalb des Kampfes deckungsgleich ueber dem Popup.
  -- Nicht an das Popup geankert, damit das Popup selbst ungeschuetzt bleibt (im Kampf zeig-/versteckbar).
  button = CreateFrame("Button", "DeathNoteAlertButton", UIParent, "SecureActionButtonTemplate")
  button:SetFrameStrata("HIGH")
  button:SetFrameLevel(popup:GetFrameLevel() + 20)
  button:RegisterForClicks("AnyUp", "AnyDown")
  button:RegisterForDrag("LeftButton")
  button:SetMovable(true)
  button:Hide()
  button:SetScript("PostClick", function(_, mouse, down)
    if mouse == "RightButton" and not down then Dismiss() end
  end)
  button:SetScript("OnEnter", function() EdgeColor(EDGE_HOT) end)
  button:SetScript("OnLeave", function() EdgeIdle() end)
  button:SetScript("OnDragStart", function(self)
    if InCombat() then return end
    self.moving = true
    popup:ClearAllPoints()
    popup:SetPoint("CENTER", self, "CENTER", 0, 0)
    self:StartMoving()
  end)
  button:SetScript("OnDragStop", function(self)
    if not self.moving or InCombat() then return end
    Alert.EndButtonDrag()
  end)

  return button
end

-- Ziehen am Knopf beenden: Popup wieder an UIParent haengen (nie an den Secure-Knopf geankert lassen)
function Alert.EndButtonDrag()
  if not (button and button.moving) then return end
  button.moving = nil
  button:StopMovingOrSizing()
  NotUserPlaced(button)
  local cx, cy = button:GetCenter()
  local s = Scale()
  popup:ClearAllPoints()
  if type(cx) == "number" and type(cy) == "number" and not Look.Secret(cx) and not Look.Secret(cy) then
    popup:SetPoint("CENTER", UIParent, "BOTTOMLEFT", cx / s, cy / s)
    SavePoint()
  else
    PlacePopup()
  end
end

local function HeaderFor(e, rank)
  if e.status == "suspect" then return L.ALERT_SIGHTED_SUSPECT end
  if rank == 1 then return L.ALERT_SIGHTED_NR1 end
  return L.ALERT_SIGHTED
end

-- level of the target for the alarm. Live from the unit when there is one (only now, never on the
-- nameplate path), else the stored level ("last level"). Returns text and true when the target is above
-- you (1.2.0: the text then carries the gap, "Level 63 (+3)"; shown in the warning colour).
-- No value from a live unit or the skull (UnitLevel < 1): "Level ??", also a warning. Secret: as unknown.
function Look.LevelLine(unit, stored)
  local lvl, last, skull
  if type(unit) == "string" and not Look.Secret(unit) and UnitLevel then
    local ok, v = pcall(UnitLevel, unit)
    if ok and not Look.Secret(v) then
      if type(v) == "number" and v == v then
        if v < 1 then skull = true else lvl = math.floor(v) end
      elseif v == nil then
        skull = true
      end
    end
  end
  if not lvl and not skull and type(stored) == "number" and not Look.Secret(stored) and stored >= 1 then
    lvl, last = math.floor(stored), true
  end
  if skull then return L.ALERT_LEVEL_UNKNOWN, true end
  if not lvl then return nil, nil end
  local text = last and Fmt(L.ALERT_LEVEL_LAST, { level = lvl }) or Fmt(L.ALERT_LEVEL, { level = lvl })
  local mine
  if UnitLevel then
    local ok, v = pcall(UnitLevel, "player")
    if ok and not Look.Secret(v) and type(v) == "number" and v == v and v >= 1 then mine = v end
  end
  if mine and lvl > mine then return text .. " (+" .. (lvl - mine) .. ")", true end
  return text, nil
end

-- drop (1.2.2): what gives way first when the line does not fit in two lines: 1 = the zone, 2 = also "last ..."
local function LineFor(e, drop)
  drop = drop or 0
  local place = drop < 1 and Look.LastPlace(e)
  local d = Look.LastDeed(e)
  local ago = Look.Ago(e.lastKill or (d and d.t))
  local k, a = tonumber(e.kills) or 0, Look.Assists(e)
  local s
  if e.status == "suspect" then
    s = L.ALERT_LINE_SUSPECT
  elseif k > 0 and a > 0 then
    s = Fmt(L.ALERT_LINE_KILLED_ASSISTED, { times = Look.Times(k), assists = Look.Times(a) })
  elseif k > 0 then
    s = Fmt(L.ALERT_LINE_KILLED, { times = Look.Times(k) })
  elseif a > 0 then
    s = Fmt(L.ALERT_LINE_ASSISTED, { times = Look.Times(a) })
  else
    s = L.ALERT_LINE_MANUAL
  end
  if ago and drop < 2 then s = Fmt(L.ALERT_LINE_LAST, { text = s, time = ago }) end
  if place and place ~= L.PLACE_UNKNOWN then s = Fmt(L.ALERT_LINE_IN, { text = s, zone = place }) end
  if (e.revenge or 0) > 0 then s = Fmt(L.ALERT_LINE_REVENGE, { text = s, times = Look.Times(e.revenge) }) end
  return s
end

-- Modell nur, wenn der Unit-Token jetzt wirklich zu diesem Feind gehoert;
-- ohne mitgeliefertes Token fragt der Tracker nach einem gueltigen.
local function UnitFor(key, unit)
  if type(unit) == "string" and not Look.Secret(unit) and ns.Util and ns.Util.KeyOfUnit then
    local ok, k = pcall(ns.Util.KeyOfUnit, unit)
    if ok and k == key then return unit end
  end
  if ns.Tracker and ns.Tracker.UnitFor then
    local ok, u = pcall(ns.Tracker.UnitFor, key)
    if ok and type(u) == "string" and not Look.Secret(u) then return u end
  end
end

-- "hat 7× Kollegen getötet, zuletzt Anna"; Hand-Eintrag: "steht im Buch von Bert"
local listedScratch = {}
-- Woher ein geteilter Eintrag kommt (1.2.0): "guild", "friends", "both"
local function SourceOf(key) return Look.GCall("Source", key) end

local function GuildLineFor(g)
  local src = SourceOf(g.key)
  if Look.ListedOnly(g) then
    local names = Look.ListedNames(g, listedScratch)
    if #names == 0 then return src == "friends" and L.GUILD_LINE_IN_FRIENDS or L.GUILD_LINE_IN_GUILD end
    return Fmt(L.GUILD_LINE_LISTED_BY, { names = Look.NameList(names, 2) })
  end
  local s
  if src == "friends" then s = Fmt(L.GUILD_LINE_KILLED_FRIENDS, { kills = Look.GKills(g.kills) })
  elseif src == "both" then s = Fmt(L.GUILD_LINE_KILLED_BOTH, { kills = Look.GKills(g.kills) })
  else s = Fmt(L.GUILD_LINE_KILLED_GUILD, { kills = Look.GKills(g.kills) }) end
  if type(g.lastVictim) == "string" and g.lastVictim ~= "" then
    s = Fmt(L.GUILD_LINE_LAST, { text = s, name = Look.First(g.lastVictim) })
  end
  return s
end

-- Ziel der Abschussliste: wer freigegeben hat, dazu der Grund
-- 1.2.2: drop >= 1: the reason as in the list (at most Look.WHY_SHORT characters, then "…"), 2: one name only
Look.WHY_SHORT = 24
function Look.ShortWhy(why, n)
  local count, cut = 0, nil
  for pos in why:gmatch("()[%z\1-\127\194-\244]") do
    count = count + 1
    if count == n + 1 then cut = pos; break end
  end
  if not cut then return why end
  return why:sub(1, cut - 1):gsub("%s+$", "") .. "…"
end
local function HuntLineFor(h, drop)
  drop = drop or 0
  local names = type(h.names) == "table" and h.names or {}
  local s = #names > 0 and Fmt(L.HUNT_LINE_BY, { names = Look.NameList(names, drop >= 2 and 1 or 2) }) or L.HUNT_LINE_RELEASED
  -- der Grund ist Freitext des Spielers und wird nie uebersetzt
  if type(h.why) == "string" and h.why ~= "" and not Look.Secret(h.why) then
    s = Fmt(L.HUNT_LINE_REASON, { text = s, reason = drop >= 1 and Look.ShortWhy(h.why, Look.WHY_SHORT) or h.why })
  end
  return s
end

-- Eigenes Buch: steht der Gesuchte zugleich auf der Abschussliste, nennt der Alarm sie (1.2.0)
local function OwnLine(e, drop)
  local s = LineFor(e, drop)
  local h = Look.HasGuild() and Look.GCall("Hunt", e.key, "all")
  if type(h) == "table" and not h.hidden then
    -- 1.2.0: nur, wenn ein anderer freigegeben hat; der eigene Name steht nie darin
    local names, others = type(h.names) == "table" and h.names or {}, {}
    for i = 1, #names do
      if not Look.GCall("IsOwnChar", names[i]) then others[#others + 1] = names[i] end
    end
    if #others > 0 then s = Fmt(L.ALERT_LINE_HUNT, { text = s, names = Look.NameList(others, 1) }) end
  end
  return s
end

-- guild: false (eigenes Buch), true (Gilde/Freunde) oder "hunt" (Ziel der Abschussliste)
local function GuildTitle(e, guild)
  if guild == "hunt" then return L.ALERT_TITLE_HUNT end
  local src = SourceOf(e.key)
  if src == "friends" then return L.ALERT_TITLE_FRIENDS end
  return L.ALERT_TITLE_GUILD
end

Look.FIT_TITLE, Look.FIT_TITLE_NR1 = { sizes = { 13, 11 } }, { sizes = { 16, 13, 11 } }
Look.FIT_NAME = { sizes = { 22, 19, 16, 13 } }
Look.FIT_LINE = { sizes = { 11 }, lines = 2, must = true, wrapFirst = true }
Look.FIT_LINE_LAST = { sizes = { 11, 10 }, lines = 2, must = true, wrapFirst = true }
local function Fill(e, unit, how, guild)
  local rank = (not guild and e.status == "wanted" and ns.Store.Rank) and ns.Store.Rank(e.key) or nil
  local nr1 = rank == 1
  -- 1.2.2: a long title in another language shrinks step by step instead of being cut (288 px)
  popup.title:SetWidth(W - 86 - 10)
  Look.FitText(popup.title, guild and GuildTitle(e, guild) or HeaderFor(e, rank), nr1 and Look.FIT_TITLE_NR1 or Look.FIT_TITLE)
  Look.FitText(popup.name, Look.Name(e), Look.FIT_NAME)
  popup.name:SetTextColor(Look.ClassRGB(e.class))
  -- Stufe vorn in der Textzeile (1.2.2; vorher rechts neben dem Namen, sie nahm ihm bis 132 px), hoeher als du
  -- in Warnfarbe mit dem Abstand ("Stufe 63 (+3)")
  local lt, warn = Look.LevelLine(unit, e.level)
  popup.levelText, popup.levelWarn = lt, warn or nil
  local lead = ""
  if lt then
    local c = warn and Look.WARN or Look.BONE
    lead = ("|cff%02x%02x%02x%s|r · "):format(c[1] * 255, c[2] * 255, c[3] * 255, lt)
  end
  -- Textzeile in hoechstens zwei Zeilen; passt sie nicht, weicht zuerst der Ort, dann "zuletzt" (eigenes Buch)
  -- bzw. der lange Grund, dann der zweite Name (Abschussliste); zuletzt 10 pt
  for drop = 0, 2 do
    local s = (guild == "hunt" and HuntLineFor(e, drop)) or (guild and GuildLineFor(e)) or OwnLine(e, drop)
    if Look.FitText(popup.line, lead .. s, drop < 2 and Look.FIT_LINE or Look.FIT_LINE_LAST) or (guild and guild ~= "hunt") then break end
  end
  popup.how = how
  SetEdge(nr1)

  -- SetUnit wirft nicht immer, sondern meldet ein nicht ladbares Modell auch mit false
  local shown = false
  if unit then
    popup.model:ClearModel()
    local ok, res = pcall(popup.model.SetUnit, popup.model, unit)
    shown = ok and (Look.Secret(res) or res ~= false)
  end
  if shown then
    popup.model:Show(); popup.icon:Hide()
  else
    popup.model:Hide(); popup.icon:Show()
    Look.ClassIcon(popup.icon, e.class)
  end
  return nr1
end

local currentHunt = false   -- 1.2.0: das Popup zeigt ein Ziel der Abschussliste
local function Show(e, unit, how, silent, guild)
  if not popup then Build() end
  current, currentEntry, currentGuild = e.key, e, guild and true or false
  currentHunt = guild == "hunt"
  local nr1 = Fill(e, unit, how, guild)
  popup.outAnim:Stop()
  popup:SetAlpha(1)
  popup:Show()
  popup.inAnim:Stop()
  popup.inAnim:Play()
  popup.nameAnim:Stop(); popup.nameAnim:Play()
  popup.strokeAnim:Stop(); popup.strokeAnim:Play()
  UpdateMore()
  ArmButton()
  Guard()
  SetHint()
  if not silent then
    Look.Alarm("alert")
    if Look.Setting("alert.flash", true) then Flash(nr1) end
  end
  if hideTimer then hideTimer:Cancel() end
  hideTimer = C_Timer.NewTimer(HOLD, function() hideTimer = nil; Dismiss() end)
  -- eine laufende Meldung (anderer Spieler) rueckt unter bzw. ueber das Popup, nie darunter versteckt
  if ns.Extras and ns.Extras.PlaceBanner then ns.Extras.PlaceBanner() end
end

-- sichtbares Popup in UIParent-Einheiten (fuer die Meldung), sonst nil
function Alert.Rect()
  if not (popup and popup:IsShown()) then return nil end
  return Look.Rect(popup)
end

local function ShowNext()
  -- ist inzwischen ein neuer Alarm zu sehen, wartet die Schlange auf dessen Ende (Finish)
  if current then UpdateMore(); return end
  while #queue > 0 do
    local q = table.remove(queue, 1)
    if q.guild then
      local g = q.hunt and Look.GCall("Hunt", q.key, "all") or Look.GCall("Get", q.key, "all")
      if EligibleGuild(g, q.hunt) then
        Show(g, UnitFor(q.key, nil), "other", false, q.hunt and "hunt" or true)
        return
      end
    else
      local e = ns.Store.Get(q.key)
      if e and Eligible(e) then
        Show(e, UnitFor(q.key, nil), "other")
        return
      end
    end
  end
  UpdateMore()
end

Finish = function()
  popup:Hide()
  popup:SetAlpha(1)
  popup.model:ClearModel()
  current, currentEntry, currentGuild, currentHunt = nil, nil, false, false
  DisarmButton()
  if #queue > 0 then C_Timer.After(0.4, ShowNext) end
end

local function Queued(key)
  for i = 1, #queue do if queue[i].key == key then return true end end
  return false
end

-- gemeinsame Abklingzeit je Schluessel; true = melden waere jetzt dran
local function Due(key)
  local cd = Look.Setting("alert.cooldown", 90) or 90
  local last = lastAlert[key]
  return not (last and GetTime() - last < cd)
end

-- Abklingzeit erst setzen, wenn der Alarm gezeigt oder wirklich eingereiht wurde
local function Mark(key) lastAlert[key] = GetTime() end

-- Zeigt gerade eine Bildschirmmeldung (Tod, Rache, Gildentod) genau diesen Spieler?
local function OnBanner(key)
  local X = ns.Extras
  return X and X.BannerShows and X.BannerShows(key) and true or false
end

-- Ein Ereignis, ein Fenster: die Meldung zeigt den Spieler schon. Abklingzeit gilt als verbraucht,
-- ein laufendes Popup fuer ihn geht zu, ein wartendes faellt aus der Schlange.
function Alert.Silence(key)
  if type(key) ~= "string" or Look.Secret(key) then return end
  Mark(key)
  for i = #queue, 1, -1 do if queue[i].key == key then table.remove(queue, i) end end
  if current == key then Dismiss() else UpdateMore() end
end

local function Enqueue(key, guild, hunt)
  if #queue >= QUEUE_MAX then return false end
  queue[#queue + 1] = { key = key, guild = guild, hunt = hunt }
  UpdateMore()
  return true
end

function Alert.Spotted(key, unit, how)
  if not ready or type(key) ~= "string" or Look.Secret(key) then return end
  local e = ns.Store.Get(key)
  if not Eligible(e) then return end
  -- ein Schluessel, ein Popup; die eigene Liste hat Vorrang vor der Gildenliste
  if current == key then
    if currentGuild then
      currentGuild, currentEntry = false, e
      Fill(e, UnitFor(key, unit), how, false)
      ArmButton(); Guard(); SetHint()
    end
    return
  end
  for i = 1, #queue do if queue[i].key == key then queue[i].guild = false; return end end
  if not Due(key) then return end
  if OnBanner(key) then Mark(key); return end
  if current then
    if Enqueue(key, false) then Mark(key) end
    return
  end
  Mark(key)
  Show(e, UnitFor(key, unit), how)
end

-- Gildenfeind (1.2.0: oder Taeter der Freunde), der nicht auf meiner Liste steht;
-- kind = "hunt": ein Ziel der Abschussliste
function Alert.GuildSpotted(key, unit, how, kind)
  if not ready or type(key) ~= "string" or Look.Secret(key) or not Look.HasGuild() then return end
  local hunt = kind == "hunt"
  local g = hunt and Look.GCall("Hunt", key, "all") or Look.GCall("Get", key, "all")
  if not EligibleGuild(g, hunt) then return end
  if current == key or Queued(key) then return end
  if not Due(key) then return end
  if OnBanner(key) then Mark(key); return end
  if current then
    if Enqueue(key, true, hunt) then Mark(key) end
    return
  end
  Mark(key)
  Show(g, UnitFor(key, unit), how, false, hunt and "hunt" or true)
end

-- 1.2.0: zeigt oder haelt das Popup gerade diesen Spieler? (neue Freigabe in Sicht: Alarm statt Chatzeile)
function Alert.Shows(key) return type(key) == "string" and (current == key or Queued(key)) and true or false end

local SAMPLE = {
  key = "Grimmzahn-Probe", name = "Grimmzahn", surname = "Probe", display = "Grimmzahn Probe", realm = "Probe",
  class = "ROGUE", kills = 3, revenge = 1, status = "wanted", suspected = 0,
  lastKill = nil, deaths = { { zone = "Schlingendorntal", subzone = "Grom'gol" } },
}

function Alert.Test()
  local e
  if ready and ns.Store and ns.Store.Ranked then
    local list = ns.Store.Ranked("wanted", "rank")
    e = list and list[1]
  end
  if not e then
    SAMPLE.lastKill = time() - 2 * 86400
    SAMPLE.deaths[1].zone = L.SAMPLE_ZONE      -- Beispielzone in der Sprache des Buchs
    e = SAMPLE
  end
  Show(e, UnitFor(e.key, "target"), "test")
end

------------------------------------------------------------------------
-- Bus und Kampf-Wechsel
------------------------------------------------------------------------
ns:On("READY", function()
  ready = true
  wipe(lastAlert)
end)

ns:On("ENEMY_SPOTTED", function(key, unit, how) Alert.Spotted(key, unit, how) end)
ns:On("GUILD_ENEMY_SPOTTED", function(key, unit, how, kind) Alert.GuildSpotted(key, unit, how, kind) end)
ns:On("TEST_ALERT", function() Alert.Test() end)

ns:On("ENEMY_UPDATED", function(key)
  if not current or key ~= current or currentGuild then return end
  local e = ns.Store.Get(key)
  if not e then Dismiss(); return end
  currentEntry = e
  popup.line:SetText(OwnLine(e))
end)

ns:On("GUILD_UPDATED", function()
  if not current or not currentGuild then return end
  local g = currentHunt and Look.GCall("Hunt", current, "all") or Look.GCall("Get", current, "all")
  if not g then Dismiss(); return end
  currentEntry = g
  popup.line:SetText(currentHunt and HuntLineFor(g) or GuildLineFor(g))
end)

-- Der Store zieht einen Eintrag auf einen neuen Schluessel um (gleiche GUID, vollerer Name):
-- Popup, Warteschlange und Abklingzeit ziehen mit
ns:On("ENEMY_REKEYED", function(old, new)
  if type(old) ~= "string" or type(new) ~= "string" or old == new then return end
  if lastAlert[old] then lastAlert[new] = lastAlert[old]; lastAlert[old] = nil end
  for i = 1, #queue do if queue[i].key == old and not queue[i].guild then queue[i].key = new end end
  if current == old and not currentGuild then current = new end
  -- derselbe Spieler hoechstens einmal: Doppel in der Schlange (alter und neuer Schluessel) und den
  -- gerade gezeigten aus der Schlange nehmen
  for i = #queue, 1, -1 do
    local k = queue[i].key
    local dup = k == current
    for j = 1, i - 1 do if queue[j].key == k then dup = true; break end end
    if dup then table.remove(queue, i) end
  end
  UpdateMore()
  if current == new and not currentGuild then
    local e = ns.Store.Get(new)
    if e then currentEntry = e end
    if popup and popup:IsShown() then
      popup.name:SetText(Look.Name(currentEntry))
      ArmButton()
      Guard()
      SetHint()
    end
  end
end)

ns:On("SETTINGS_CHANGED", function(path)
  if path == "alert.scale" then Alert.ApplyScale() end
end)

-- Vor dem Kampf-Lockdown den Knopf wegnehmen (sonst bliebe er im Kampf als unsichtbare Klickflaeche).
-- Ob das Verstecken hier noch durchgeht, ist im Spiel unbelegt: armedFor bleibt darum stehen, solange
-- der Knopf sichtbar ist, und Guard() legt das Popup notfalls ueber ihn.
ns:RegisterEvent("PLAYER_REGEN_DISABLED", function()
  if popup and popup.moving then
    popup.moving = nil
    popup:StopMovingOrSizing()
    NotUserPlaced(popup)
    SavePoint()
  end
  if button and not InCombatLockdown() then
    Alert.EndButtonDrag()
    if button:IsShown() then
      pcall(button.Hide, button)
      if not button:IsShown() then armedFor = nil end
    end
  end
  Guard()
  SetHint()
end)

-- Nach dem Kampf: Klick-Ziel nachziehen bzw. liegengebliebenen Knopf wegraeumen
ns:RegisterEvent("PLAYER_REGEN_ENABLED", function()
  if popup and popup:IsShown() and currentEntry then
    ArmButton()
  elseif button and button:IsShown() then
    DisarmButton()
  end
  Guard()
  SetHint()
end)
