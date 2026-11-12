local ADDON, ns = ...

-- Tooltip-Zeile "GESUCHT" bzw. "GILDENFEIND" und Bildschirmmeldungen nach Tod, Rache und Gildentod.

local Look = ns.Look
local Extras = {}
ns.Extras = Extras
local ready = false
-- Texte (1.2.0): L.KEY nur in Funktionen lesen (ns.L ist ab ADDON_LOADED gefuellt)
local L, Fmt = ns.L, ns.F

-- Kopfzeile der Meldung gesperrt: "NEUER EINTRAG" -> "N E U E R   E I N T R A G" (UTF-8-bewusst);
-- Chinesisch und Koreanisch bleiben ungesperrt
local NO_SPACING = { koKR = true, zhCN = true, zhTW = true }
local function Spaced(s)
  if type(s) ~= "string" then return "" end
  if ns.Locale and NO_SPACING[ns.Locale.code] then return s end
  local out, n = {}, 0
  for ch in s:gmatch("[%z\1-\127\194-\244][\128-\191]*") do n = n + 1; out[n] = ch end
  return table.concat(out, " ", 1, n)
end
Extras.Spaced = Spaced

-- Stempel der Meldung: Deutsch zeigt die Bilder wie 1.1.0, jede andere Sprache den leeren Rahmen
-- (gleiche Optik) mit dem Text aus der Sprachtabelle darueber, gedreht wie das Bild (Grad, ImageMagick
-- im Uhrzeigersinn). FontString:SetRotation ist nur wo vorhanden benutzt (Beleg: Details/Libs/DF/fw.lua).
local STAMPS = {
  nr1   = { img = "nr1",   key = "STAMP_NR1",     ang = -11, rgb = { 0.69, 0.04, 0.04 } },
  rache = { img = "rache", key = "STAMP_REVENGE", ang = 9,   rgb = { 0.69, 0.04, 0.04 } },
  hunt  = { img = "hunt",  key = "STAMP_HUNT",    ang = 8,   rgb = { 0.69, 0.04, 0.04 } },
}
Extras.STAMPS = STAMPS
local function StampImage(kind)
  local st = STAMPS[kind]
  if not st then return nil end
  if not ns.Locale or ns.Locale.code == "deDE" then return Look.TEX[st.img], nil, st end
  return Look.MEDIA .. "stamp_" .. st.img .. "_blank.tga", L[st.key], st
end

------------------------------------------------------------------------
-- Tooltip
------------------------------------------------------------------------
-- "IM BUCH: 2× getötet · 1× beteiligt · Rang 1 · Rache 2×" (dieselben Woerter wie im Buch)
local function TooltipText(e)
  local rank = e.status == "wanted" and ns.Store.Rank(e.key) or nil
  local rv = tonumber(e.revenge) or 0
  local s = Look.Join(e.status == "pardoned" and L.TIP_PARDONED or nil, Look.Tally(e),
                      rank and Fmt(L.TIP_RANK, { rank = rank }), rv > 0 and Fmt(L.TIP_REVENGE, { times = Look.Times(rv) }))
  return "|cffe03020" .. L.TIP_IN_BOOK .. "|r |cffd8c8a8" .. s .. "|r"
end

-- Unit-Token des Tooltips: GetUnit, sonst ueber die GUID der Tooltip-Daten; Secrets fallen raus
local function TooltipUnit(tt, data)
  local ok, _, unit = pcall(tt.GetUnit, tt)
  if ok and type(unit) == "string" and not Look.Secret(unit) then return unit end
  if type(data) == "table" and not Look.Secret(data) and UnitTokenFromGUID then
    local guid = data.guid
    if type(guid) == "string" and not Look.Secret(guid) then
      local ok2, u = pcall(UnitTokenFromGUID, guid)
      if ok2 and type(u) == "string" and not Look.Secret(u) then return u end
    end
  end
end

local tipNames = {}

local function OnTooltipUnit(tt, data)
  if not ready or tt ~= GameTooltip then return end
  if tt.IsForbidden and tt:IsForbidden() then return end
  if not Look.Setting("tooltip", true) then return end
  local unit = TooltipUnit(tt, data)
  if not unit then return end
  local key = ns.Util.KeyOfUnit(unit)   -- nil bei Secret oder Nicht-Spieler
  if not key then return end
  -- Ziel der Abschussliste (1.2.0): eine eigene Zeile, auch wenn er im eigenen Buch steht
  local h = Look.HasGuild() and Look.GCall("Hunt", key, "all")
  if type(h) == "table" and type(h.names) == "table" and #h.names > 0 then
    tt:AddLine("|cffe03020" .. L.TIP_HUNT .. "|r |cffd8c8a8" .. Fmt(L.HUNT_LINE_BY, { names = Look.NameList(h.names, 2) }) .. "|r")
  end
  local e = ns.Store.Get(key)
  if not e then
    -- Gildenfeind (1.2.0: oder Taeter der Freunde), der (noch) nicht im eigenen Buch steht
    local g = Look.HasGuild() and Look.GCall("Get", key, "all")
    if type(g) == "table" and (g.kills or 0) > 0 then
      tt:AddLine("|cffe03020" .. L.TIP_GUILDBOOK .. "|r |cffd8c8a8" .. Fmt(L.GUILD_LINE_KILLED_GUILD, { kills = Look.GKills(g.kills) }) .. "|r")
    elseif type(g) == "table" and Look.ListedOnly(g) then
      local names = Look.ListedNames(g, tipNames)
      if #names > 0 then
        tt:AddLine("|cffb05040" .. L.TIP_GUILDBOOK .. "|r |cffd8c8a8" .. Fmt(L.TIP_LISTED_BY, { names = Look.NameList(names, 2) }) .. "|r")
      end
    end
    return
  end
  tt:AddLine(TooltipText(e))
  local note = Look.NoteOf(e)
  if note ~= "" then tt:AddLine("|cffa89878" .. Fmt(L.TIP_NOTE, { note = note }) .. "|r", nil, nil, nil, true) end
end

local hooked = false
local function HookTooltip()
  if hooked then return end
  hooked = true
  local function safe(tt, data)
    local ok, err = pcall(OnTooltipUnit, tt, data)
    if not ok and Look.Setting("debug", false) and ns.Util.Print then ns.Util.Print("Tooltip: " .. tostring(err)) end
  end
  if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType
     and Enum.TooltipDataType.Unit then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, safe)
  elseif GameTooltip and GameTooltip.HasScript and GameTooltip:HasScript("OnTooltipSetUnit") then
    GameTooltip:HookScript("OnTooltipSetUnit", safe)
  end
end

------------------------------------------------------------------------
-- Bildschirmmeldung (Steckbrief-Streifen in der Bildschirmmitte)
------------------------------------------------------------------------
local banner
local BANNER_W, BANNER_H, BANNER_Y = 480, 92, -310
local guildQueue = {}     -- wartende Gilden-Meldungen; die eigene Meldung hat immer Vorrang
local GUILD_QUEUE_MAX = 3
local NextGuild -- vorwaerts

-- Schwarzer Streifen mit blutroter Kante; der Name erscheint wie frisch ins Buch geschrieben
local function BuildBanner()
  banner = CreateFrame("Frame", "DeathNoteBanner", UIParent, "BackdropTemplate")
  banner:SetSize(BANNER_W, BANNER_H)
  banner:SetPoint("TOP", UIParent, "TOP", 0, BANNER_Y)   -- unter dem Alarm-Popup, nie darueber
  banner:SetClampedToScreen(true)
  banner:SetFrameStrata("HIGH")
  banner:EnableMouse(false)
  banner:Hide()
  -- Meldungen nach dem eigenen Tod sind anklickbar (man ist tot, es stoert keinen Kampf):
  -- Linksklick schlaegt den Taeter bzw. den Fall auf, Rechtsklick schliesst
  -- Stop() loest im Client OnFinished nicht aus: nach einem Klick selbst aufraeumen, sonst bleibt
  -- der Klick-Zustand stehen und wartende Gilden-Meldungen kommen nie dran
  local function Dismiss(self)
    self.anim:Stop(); self:Hide()
    self.open, self.key, self.guild = nil, nil, false
    self:EnableMouse(false)
    if GameTooltip and GameTooltip.IsOwned and GameTooltip:IsOwned(self) then GameTooltip:Hide() end
    if #guildQueue > 0 then C_Timer.After(0.4, NextGuild) end
  end
  banner:SetScript("OnMouseUp", function(self, mouse)
    if not self.open then return end
    local open = self.open
    Dismiss(self)
    if mouse ~= "RightButton" then open() end
  end)
  banner:SetScript("OnEnter", function(self)
    if not self.open then return end
    self:SetBackdropBorderColor(Look.RED_ON_BLACK[1], Look.RED_ON_BLACK[2], Look.RED_ON_BLACK[3], 1)
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
    GameTooltip:SetText(L.BANNER_TIP)
    GameTooltip:Show()
  end)
  banner:SetScript("OnLeave", function(self)
    self:SetBackdropBorderColor(Look.RED[1], Look.RED[2], Look.RED[3], 1)
    GameTooltip:Hide()
  end)
  banner:SetBackdrop({ edgeFile = Look.TEX.white, edgeSize = 2 })
  banner:SetBackdropBorderColor(Look.RED[1], Look.RED[2], Look.RED[3], 1)
  local bg = banner:CreateTexture(nil, "BACKGROUND")
  bg:SetPoint("TOPLEFT", 2, -2); bg:SetPoint("BOTTOMRIGHT", -2, 2)
  Look.Tex(bg, Look.TEX.cover, 0.06, 0.05, 0.05, 1)
  bg:SetTexCoord(0, 1, 0.3, 0.6)

  banner.kicker = Look.Text(banner, "body", 11, Look.RED_ON_BLACK)
  banner.kicker:SetPoint("TOP", 0, -8)
  banner.name = Look.Text(banner, "hand", 26, Look.BONE)
  banner.name:SetPoint("TOP", 0, -26)
  banner.name:SetWidth(380)
  banner.name:SetWordWrap(false)
  banner.line = Look.Text(banner, "body", 11, Look.BONE)
  banner.line:SetPoint("BOTTOM", 0, 10)
  banner.line:SetWidth(440)
  banner.line:SetWordWrap(false)

  -- Stempel haengt ueber die rechte obere Ecke
  banner.stamp = banner:CreateTexture(nil, "OVERLAY")
  banner.stamp:SetSize(120, 60)
  banner.stamp:SetPoint("TOPRIGHT", banner, "TOPRIGHT", 26, 18)
  banner.stamp:SetAlpha(0.95)
  banner.stamp:Hide()
  -- 1.2.0: Stempeltext fuer alle Sprachen ausser Deutsch (auf dem leeren Rahmen)
  banner.stampText = Look.Text(banner, "title", 13, { 0.69, 0.04, 0.04 })
  banner.stampText:SetPoint("CENTER", banner.stamp, "CENTER", 0, 0)
  banner.stampText:SetWidth(96)
  banner.stampText:SetJustifyH("CENTER")
  banner.stampText:SetMaxLines(2)
  banner.stampText:Hide()

  local g = banner:CreateAnimationGroup()
  Look.AlphaAnim(g, 0, 1, 0.25, 1)
  Look.ScaleAnim(g, 1.15, 1, 0.3, 1)
  Look.AlphaAnim(g, 1, 0, 0.8, 2, 4.5)   -- 4,5 s stehen lassen, dann ausblenden
  if g.SetToFinalAlpha then g:SetToFinalAlpha(true) end   -- kein Aufblitzen mit Alpha 1 am Ende
  g:SetScript("OnFinished", function()
    banner:Hide()
    banner.open = nil
    banner:EnableMouse(false)
    banner.guild = false
    banner.key = nil
    if #guildQueue > 0 then C_Timer.After(0.4, NextGuild) end
  end)
  banner.anim = g

  -- Name: kurz unsichtbar halten, dann einblenden (Alpha springt danach auf 1 zurueck)
  local ng = banner.name:CreateAnimationGroup()
  Look.AlphaAnim(ng, 0, 0, 0.2, 1)
  Look.AlphaAnim(ng, 0, 1, 0.7, 2)
  banner.nameAnim = ng

  -- Stempel kommt mit einem "Rumms" nach
  local sg = banner.stamp:CreateAnimationGroup()
  Look.AlphaAnim(sg, 0, 0, 0.6, 1)
  Look.AlphaAnim(sg, 0, 1, 0.08, 2)
  Look.ScaleAnim(sg, 1.8, 1, 0.12, 2)
  banner.stampAnim = sg
  local tg = banner.stampText:CreateAnimationGroup()
  Look.AlphaAnim(tg, 0, 0, 0.6, 1)
  Look.AlphaAnim(tg, 0, 1, 0.08, 2)
  banner.stampTextAnim = tg
end

-- Die Meldung liegt nie auf dem Alarm-Popup: ueberdecken sie sich (groesserer Alarm, verschobenes
-- Popup), rueckt die Meldung unter das Popup, und wenn dort kein Platz ist, darueber.
-- Alles in UIParent-Einheiten; beide haengen an UIParent, dessen Skalierung (z. B. 0,6) kuerzt sich.
local GAP, STAMP_TOP = 10, 18
function Extras.PlaceBanner()
  if not banner then return end
  local W, H = UIParent:GetWidth(), UIParent:GetHeight()
  local y = BANNER_Y
  local l, b, r, t = nil, nil, nil, nil
  if ns.Alert and ns.Alert.Rect then l, b, r, t = ns.Alert.Rect() end
  if type(W) == "number" and type(H) == "number" and not Look.Secret(W) and not Look.Secret(H) and l then
    local bl, br = W / 2 - BANNER_W / 2, W / 2 + BANNER_W / 2
    -- the strip of a dry remark hangs below the message (Humor.lua: 4 below, 22 high)
    local strip = (ns.Humor and ns.Humor.On and ns.Humor.On()) and 26 or 0
    local bt = H + BANNER_Y + STAMP_TOP
    local bb = H + BANNER_Y - BANNER_H - strip
    if l < br and r > bl and b < bt and t > bb then
      if b - GAP - STAMP_TOP - BANNER_H >= 0 then
        y = (b - GAP - STAMP_TOP) - H              -- unter das Popup
      else
        y = (t + GAP + BANNER_H + strip) - H       -- darueber
      end
    end
  end
  if banner.y ~= y then
    banner.y = y
    banner:ClearAllPoints()
    banner:SetPoint("TOP", UIParent, "TOP", 0, y)
  end
end

-- zeigt die Meldung gerade diesen Spieler?
function Extras.BannerShows(key)
  return banner ~= nil and banner:IsShown() and banner.key ~= nil and banner.key == key
end

local function Silence(key)
  if type(key) == "string" and ns.Alert and ns.Alert.Silence then ns.Alert.Silence(key) end
end

-- open: Funktion fuer den Klick (nur Meldungen nach dem eigenen Tod), sonst nicht anklickbar.
-- kicker ist der ungesperrte Text (1.2.0, gesperrt wird hier); stamp: Art aus STAMPS oder nil
-- 1.2.2: the name steps 26, 22, 19 pt (380 px, 340 px next to the stamp); the line steps 11, 10 pt, and a line
-- given as { full, short } falls back to the short one (zone left out) before it would be cut;
-- the stamp text steps 13, 11, 9 pt on up to two lines (a long single word no longer runs out of the frame)
Extras.FIT_NAME, Extras.FIT_LINE = { sizes = { 26, 22, 19 } }, { sizes = { 11, 10 } }
Extras.FIT_STAMP = { sizes = { 13, 11, 9 }, lines = 2, wrapFirst = true }
local function Banner(kicker, name, nameRGB, line, stamp, guild, key, open)
  local stampTex, stampText, st = StampImage(stamp)
  kicker = Spaced(kicker)
  if not banner then BuildBanner() end
  banner.guild = guild and true or false
  banner.key = key
  banner.kind = stamp
  banner.open = open
  banner:EnableMouse(open ~= nil)
  banner.kicker:SetText(kicker)
  -- mit Stempel ruckt der Name etwas nach links, damit lange Namen frei bleiben
  banner.name:ClearAllPoints()
  banner.name:SetPoint("TOP", stampTex and -24 or 0, -26)
  banner.name:SetWidth(stampTex and 340 or 380)
  Look.FitText(banner.name, name, Extras.FIT_NAME)
  local c = nameRGB or Look.BONE
  banner.name:SetTextColor(c[1], c[2], c[3], 1)
  if type(line) == "table" then
    if not Look.FitText(banner.line, line[1] or "", Extras.FIT_LINE) then Look.FitText(banner.line, line[2] or "", Extras.FIT_LINE) end
  else
    Look.FitText(banner.line, line or "", Extras.FIT_LINE)
  end
  banner.anim:Stop()
  banner.stampAnim:Stop()
  banner:SetAlpha(1)
  banner:Show()
  banner.anim:Play()
  banner.nameAnim:Stop(); banner.nameAnim:Play()
  banner.stampTextAnim:Stop()
  if stampTex then
    Look.Tex(banner.stamp, stampTex, 0.6, 0.1, 0.1, 0.5)
    banner.stamp:Show()
    banner.stampAnim:Play()
  else
    banner.stamp:Hide()
  end
  if stampText then
    local fs = banner.stampText
    Look.FitText(fs, stampText, Extras.FIT_STAMP)
    fs:SetTextColor(st.rgb[1], st.rgb[2], st.rgb[3], 0.95)
    if fs.SetRotation then pcall(fs.SetRotation, fs, math.rad(-st.ang)) end
    fs:Show()
    banner.stampTextAnim:Play()
  else
    banner.stampText:Hide()
  end
  Extras.PlaceBanner()
  -- ein Ereignis, ein Fenster: kein Alarm-Popup fuer denselben Spieler daneben
  if key then Silence(key) end
  if ns.Humor then pcall(ns.Humor.OnBanner, banner, stamp, key, guild) end -- Humor: Spruch und Stempel zur Meldung
end

local function OnDeath(death, key)
  if not ready or type(death) ~= "table" then return end
  if not Look.Setting("deathMessage", true) then return end
  if death.kind ~= "pvp" then return end
  local S = ns.Store
  if key then
    local e = S.Get(key)
    if not e then return end
    local name = Look.Name(e)
    local r, g, b = Look.ClassRGB(e.class)
    local rgb = { r, g, b }
    local function open() if ns.UI and ns.UI.ShowEnemy then ns.UI.ShowEnemy(key) end end
    if death.sure == false or e.status == "suspect" then
      Banner(L.BANNER_SUSPECT, name, rgb, L.BANNER_SUSPECT_LINE, nil, false, key, open)
    elseif (e.kills or 0) <= 1 then
      Banner(L.BANNER_NEW, name, rgb, L.BANNER_NEW_LINE, nil, false, key, open)
    else
      local rank = S.Rank(key)
      Banner(L.BANNER_AGAIN, name, rgb, Fmt(L.BANNER_AGAIN_LINE, { count = e.kills }),
             rank == 1 and "nr1" or nil, false, key, open)
    end
    -- Mittaeter stehen jetzt auch im Buch und sind meist noch in Sicht: auch fuer sie kein Popup
    local others = death.others
    if type(others) ~= "table" and type(e.deaths) == "table" and e.deaths[1] and e.deaths[1].t == death.t then
      others = e.deaths[1].others
    end
    if type(others) == "table" then
      for i = 1, #others do Silence(others[i]) end
    end
  else
    local n = type(death.candidates) == "table" and #death.candidates or 0
    if n > 0 then
      Banner(L.BANNER_UNCLEAR, Fmt(L.BANNER_CANDIDATES, { count = n }), nil, L.BANNER_UNCLEAR_LINE, nil,
             false, nil, function() if ns.UI and ns.UI.ShowCase then ns.UI.ShowCase(death) end end)
    end
  end
end

local function OnRevenge(key)
  if not ready then return end
  local e = key and ns.Store.Get(key)
  if not e then return end
  local r, g, b = Look.ClassRGB(e.class)
  Banner(L.BANNER_REVENGE, Look.Name(e), { r, g, b },
         Fmt(L.BANNER_REVENGE_LINE, { count = e.revenge or 1 }), "rache", false, key)
  Look.Alarm("revenge")
end

-- 1.2.1: eine von Hand vermerkte Rache wurde zurueckgenommen: steht noch ihre Meldung, geht sie weg
local function OnRevengeUndone(key)
  if not (banner and banner:IsShown() and banner.key == key and banner.kind == "rache") then return end
  banner.anim:Stop(); banner:Hide()
  banner.open, banner.key, banner.kind, banner.guild = nil, nil, nil, false
  banner:EnableMouse(false)
  if #guildQueue > 0 then C_Timer.After(0.4, NextGuild) end
end

-- 1.2.1: ein Kollege oder Freund hat einen Taeter erledigt, der im eigenen Buch steht: eine Chatzeile und der
-- kurze Ton der Rache-Meldung, kein Fenster (ist er zugleich Ziel der Abschussliste, kommt nur die Erlegt-Meldung)
local function OnAvenged(key, char, t)
  if not ready or type(key) ~= "string" or Look.Secret(key) or type(char) ~= "string" or Look.Secret(char) then return end
  local e = ns.Store.Get(key)
  local name = e and Look.Name(e) or (key:match("^([^%-]+)") or key)
  if ns.Util and ns.Util.Print then ns.Util.Print(Fmt(L.CHAT_AVENGED, { name = Look.First(char), killer = name })) end
  Look.Alarm("revenge")
end

-- Ein Kollege (1.2.0: oder Freund) wurde gerade getoetet: "Vorname" gross, darunter
-- "wurde von <Name> getötet · <Zone>"
local function ShowGuild(tat, key, src)
  local g = Look.GCall("Get", key, "all")
  local killer = g and Look.Name(g) or (type(key) == "string" and (key:match("^([^%-]+)") or key)) or "?"
  local by = Fmt(L.BANNER_KILLED_BY, { name = killer })
  local line = { Look.Join(by, type(tat.zone) == "string" and tat.zone or nil), by }
  Banner(src == "friends" and L.BANNER_FRIENDS or L.BANNER_GUILD, Look.First(tat.victim), Look.BONE, line, nil, true,
         type(key) == "string" and key or nil)
end

-- Ein Ziel der Abschussliste wurde erlegt (1.2.0): Name gross, darunter wer und wann, Stempel
local function ShowBagged(key, char, t)
  local h = Look.GCall("Hunt", key, "all")
  local name = h and Look.Name(h) or (key:match("^([^%-]+)") or key)
  local rgb
  if h then local r, g, b = Look.ClassRGB(h.class); rgb = { r, g, b } end
  local line = Fmt(L.BANNER_BAGGED, { name = Look.First(char), time = Look.Ago(t) })
  Banner(L.BANNER_HUNT, name, rgb, line, "hunt", true, key)
end

-- wartende Meldungen: { Funktion, Argumente ... }
NextGuild = function()
  if banner and banner:IsShown() then return end
  local q = table.remove(guildQueue, 1)
  if q then q[1](q[2], q[3], q[4], q[5], q[6]) end
end

local function Later(fn, a, b, c, d, e)
  if banner and banner:IsShown() then
    if #guildQueue < GUILD_QUEUE_MAX then guildQueue[#guildQueue + 1] = { fn, a, b, c, d, e } end
    return
  end
  fn(a, b, c, d, e)
end

local function OnGuildKill(tat, key, src)
  if not ready or type(tat) ~= "table" or not Look.HasGuild() then return end
  if Look.GuildSetting("announce") ~= true then return end
  if type(tat.victim) ~= "string" or Look.Secret(tat.victim) or tat.victim == "" then return end
  if tat.victim == Look.Me() then return end      -- der eigene Tod hat seine eigene Meldung
  Later(ShowGuild, tat, key, src)
end

-- Ein Ereignis, ein Fenster: der eigene Todesstoss auf einen Taeter des eigenen Buchs hat schon die
-- Rache-Meldung; dann keine zweite. Zeigt die Rache-Meldung ihn nicht (z. B. begnadigt, 1.2.0 fix),
-- kommt die Erlegt-Meldung. Eigener Schalter guild.announceHunt (1.2.0 fix: vorher keiner).
local function OnBagged(key, char, t, src)
  if not ready or type(key) ~= "string" or Look.Secret(key) or type(char) ~= "string" or type(t) ~= "number" then return end
  if Look.GuildSetting("announceHunt") == false then return end
  if src == "self" and Extras.BannerShows(key) then return end
  Later(ShowBagged, key, char, t)
end

-- Neue Ziele anderer auf der Abschussliste (1.2.0): eine Zeile fuer mehrere ("3 neue Ziele").
-- 1.2.0: releases from the friends' book name the releaser with his full name (a friend listed
-- without surname is bound provisionally: the player sees who it really is)
-- 1.2.0: neue Freigaben aus Gilde und Freunden kommen als eine Chatzeile, nicht als Fenster (die Liste zeigt
-- sie, der Alarm meldet das Ziel, wenn es auftaucht). Ist das eine Ziel gerade in Sicht: der normale Alarm.
local function ChatNew(count, key, by, src, one)
  local h = Look.GCall("Hunt", key, "all")
  local who = src == "friends" and by or Look.First(by)
  local text
  if count <= 1 and h then
    text = Look.Join(Look.Name(h), Fmt(L.HUNT_LINE_BY, { names = who }), type(h.why) == "string" and h.why ~= "" and h.why or nil)
  else
    text = Look.Join(Fmt(L.BANNER_NEW_HUNTS, { count = count }), L.BANNER_NEW_HUNTS_LINE,
                     one and Fmt(L.HUNT_LINE_BY, { names = who }) or nil)
  end
  if ns.Util and ns.Util.Print then ns.Util.Print(text) end
end

local function OnNewHunt(count, key, by, src, one, list)
  if not ready or type(count) ~= "number" or count < 1 or type(key) ~= "string" or type(by) ~= "string" then return end
  if type(list) ~= "table" or #list == 0 then list = { { key = key, by = by, src = src } } end
  -- every new target in sight gets the normal alarm (its own switch "warn"), whatever "announce" says;
  -- the rest goes into the one chat line
  local rest = {}
  local T, A = ns.Tracker, ns.Alert
  for i = 1, #list do
    local x = list[i]
    local shown = false
    if type(x) == "table" and type(x.key) == "string" and T and T.UnitFor and A and A.GuildSpotted then
      local ok, unit = pcall(T.UnitFor, x.key)
      if ok and type(unit) == "string" and not Look.Secret(unit) then
        A.GuildSpotted(x.key, unit, "other", "hunt")
        shown = A.Shows and A.Shows(x.key) or false
      end
    end
    if not shown and type(x) == "table" and type(x.key) == "string" and type(x.by) == "string" then rest[#rest + 1] = x end
  end
  if #rest == 0 or Look.GuildSetting("announceHunt") == false then return end
  local same = true
  for i = 2, #rest do if rest[i].by ~= rest[1].by then same = false; break end end
  if #rest == #list then same = one == true end
  ChatNew(#rest, rest[1].key, rest[1].by, rest[1].src, same)
end

ns:On("READY", function()
  ready = true
  HookTooltip()
end)
ns:On("DEATH_RECORDED", OnDeath)
ns:On("REVENGE", OnRevenge)
ns:On("REVENGE_UNDONE", OnRevengeUndone)
ns:On("AVENGED", OnAvenged)
ns:On("GUILD_KILL", OnGuildKill)
ns:On("HUNT_BAGGED", OnBagged)
ns:On("HUNT_NEW", OnNewHunt)
