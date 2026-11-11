-- Gegenproben UI (sollen gruen sein): was am Design-Rueckbau von fix-3 gemessen und in Ordnung befunden wurde.
-- Aufruf: nice -n 15 luajit beleg_ui_5_gegenproben.lua <Projektkopie>
-- (1) Hausordnung, Blatt Gilde, Seite 1 und Seite "Mehr" in 21 Sprachen: keine Ueberdeckung, kein Ueberlauf
--     (Standzeilen sind mit Absicht einzeilig gekuerzt), zehn Haken, zwei Stufen, zwei Leeren-Knoepfe mit Pfaden.
-- (2) Rundwege der Seite "Mehr": Neuladen, Blattwechsel, Buch zu/auf, kaputte Werte, Kampf, Sprachpfeil (21 Sprachen).
-- (3) Alarm: Stufenzeile mit Grenzwerten und Secrets (kein Fehler, kein Rechnen mit einem Secret), Lage von Name
--     und Stufe in 21 Sprachen.
-- (4) Gebrauchsanweisung in 21 Sprachen: Luft bis Fusszeile bzw. Knopf (Zeilenhoehe = Schriftgrad).
-- (5) Rang je Quelle: Rangzahl der Zeile, Guild.Rank und Stempel Nr. 1 am Plakat stimmen ueberein.
-- Breiten sind geschaetzt (Zeichen x Schriftgrad x Faktor, CJK als Geviert), wie in der finalen Jagd.
-- Alle Namen sind erfunden.
package.path = (arg[0]:match("^(.*)/[^/]+$") or ".") .. "/?.lua;" .. package.path
local K = require("_kopf_ui")

local function sheet(W, n) local s = W.frameWith(function(f) return f.page == n and f._scripts and f._scripts.OnClick end); W.click(s) end
local function openSheet(W)
  W.ns:Fire("TOGGLE_UI"); W.tick(); W.settle()
  W.ns.UI.OpenPanel("settings"); W.tick()
  sheet(W, 3)
  return W.frameWith(function(f) return f.gmk and f.hexp end)
end
local function visChecks(W)
  local out = {}
  for _, f in ipairs(W.BM.frames) do if f._kind == "CheckButton" and f.opt and f.opt.guild and f:IsVisible() then out[#out + 1] = f end end
  return out
end

------------------------------------------------------------------------ (1)
local gemessen, standKurz = 0, 0
for _, code in ipairs(K.CODES) do
  local W = K.world(code)
  local S = openSheet(W)
  local paths = {}
  for page = 1, 2 do
    if page == 2 then W.click(S.gmore) end
    local out, items = W.scan(S, { rand = 14 })
    gemessen = gemessen + #items
    local bad = {}
    for _, m in ipairs(out) do
      local stand = m.art == "FEST" and (tostring(m.a):find("^SYNC_") or tostring(m.a):find("^FRIENDS_") or tostring(m.a):find("^HEALTH_") or m.a == "(Daten)")
      if stand then standKurz = standKurz + 1 else bad[#bad + 1] = ("%s %s/%s %dx%d"):format(m.art, tostring(m.a), tostring(m.b), m.x, m.y) end
    end
    K.check(("1 %s Seite %d: keine Ueberdeckung, kein Ueberlauf"):format(code, page), #bad == 0, table.concat(bad, "; "))
    for _, cb in ipairs(visChecks(W)) do
      local before = W.ns.Store.Setting(cb.opt.path)
      cb:SetChecked(not cb:GetChecked()); W.click(cb)
      local after = W.ns.Store.Setting(cb.opt.path)
      cb:SetChecked(not cb:GetChecked()); W.click(cb)
      if type(after) == "boolean" and after ~= before and W.ns.Store.Setting(cb.opt.path) == before then paths[#paths + 1] = cb.opt.path end
    end
  end
  table.sort(paths)
  K.check("1 " .. code .. ": zehn Haken schreiben ihre Pfade",
    table.concat(paths, " ") == "guild.alert guild.alertHunt guild.alertListed guild.announce guild.announceHunt guild.friends guild.receive guild.share guild.shareManual guild.sightings",
    table.concat(paths, " "))
  if code == "deDE" then
    local function steps(v, path)
      local seen = {}
      for _ = 1, 25 do W.click(v.minus) end
      seen[1] = tostring(W.ns.Store.Setting(path))
      for _ = 1, 25 do W.click(v.plus); local x = tostring(W.ns.Store.Setting(path)); if seen[#seen] ~= x then seen[#seen + 1] = x end end
      return table.concat(seen, ",")
    end
    K.check("1 Stufe Schwelle: 1 bis 20", steps(S.gmk, "guild.minKills") == "1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20")
    K.check("1 Stufe Freigaben gelten: 0, 30, 90, 180", steps(S.hexp, "guild.huntExpire") == "0,30,90,180")
    local p0, which = #W.BM.popups, {}
    for _, f in ipairs(W.BM.frames) do
      if f._kind == "Button" and f.IsVisible and f:IsVisible() and f._scripts.OnClick and W.under(f, S) then
        local t = (type(f.text) == "table" and f.text._text) or (type(f.label) == "table" and f.label._text)
        if t == W.L.SET_GUILD_CLEAR or t == W.L.SET_FRIENDS_CLEAR then W.click(f) end
      end
    end
    for i = p0 + 1, #W.BM.popups do which[#which + 1] = W.BM.popups[i].which end
    K.check("1 beide Leeren-Knoepfe fragen nach", table.concat(which, ",") == "DEATHNOTE_GUILD_CLEAR,DEATHNOTE_FRIENDS_CLEAR", table.concat(which, ","))
  end
  local n, e = W.errs()
  K.check("1 " .. code .. ": keine Fehler", n == 0, e)
end
K.info(("(1) %d Elemente vermessen, %d gekuerzte Standzeilen (Absicht)"):format(gemessen, standKurz))

------------------------------------------------------------------------ (2)
do
  local function st(S) return (S.pageB1:IsVisible() and "1" or "") .. (S.pageB2:IsVisible() and "2" or "") .. (S.gmore.mark:IsShown() and "*" or "") end
  local function copy(t) if type(t) ~= "table" then return t end local o = {} for k, v in pairs(t) do o[k] = copy(v) end return o end
  local W = K.world("deDE"); local S = openSheet(W)
  K.check("2 Standard: Seite 1", st(S) == "1", st(S))
  W.click(S.gmore)
  K.check("2 Mehr: Seite 2, gemerkt", st(S) == "2*" and W.ns.Store.Setting("ui.guildMore") == true, st(S))
  W.AM.FireEvent("PLAYER_LOGOUT")
  local db = copy(_G.DeathNoteDB)
  W = K.world("deDE", { db = db }); S = openSheet(W)
  K.check("2 nach Neuladen: Seite 2", st(S) == "2*", st(S))
  sheet(W, 1); K.check("2 anderes Blatt: keine Seite des Blatts Gilde sichtbar", st(S) == "*", st(S))
  sheet(W, 3); K.check("2 zurueck: Seite 2", st(S) == "2*", st(S))
  W.ns:Fire("TOGGLE_UI"); W.tick(); W.ns:Fire("TOGGLE_UI"); W.tick(); W.settle()
  W.ns.UI.OpenPanel("settings"); W.tick()
  K.check("2 Buch zu und auf: Seite 2", st(S) == "2*", st(S))
  local n, e = W.errs(); K.check("2 Rundweg: keine Fehler", n == 0, e)
  for _, v in ipairs({ 5, "ja", {}, 0, "true" }) do
    local W2 = K.world("deDE", { db = { settings = { lang = "deDE", ui = { guildMore = v } } } })
    local S2 = openSheet(W2)
    local a = st(S2); W2.click(S2.gmore); local b = st(S2); W2.click(S2.gmore); local c = st(S2)
    local n2, e2 = W2.errs()
    K.check("2 kaputter Wert (" .. type(v) .. "): zu, Klick auf, Klick zu, kein Fehler", a == "1" and b == "2*" and c == "1" and n2 == 0, a .. " " .. b .. " " .. c .. " " .. tostring(e2))
  end
  W = K.world("deDE"); W.BM.combat = true; W.AM.combat = true; S = openSheet(W)
  W.click(S.gmore); W.click(S.gmk.plus); W.click(S.hexp.plus)
  for _, f in ipairs(visChecks(W)) do f:SetChecked(not f:GetChecked()); W.click(f) end
  W.click(S.gmore)
  n, e = W.errs(); K.check("2 im Kampf: keine Fehler, keine geschuetzte Aktion", n == 0 and st(S) == "1", e)
  for _, code in ipairs(K.CODES) do
    local W3 = K.world(code); local S3 = openSheet(W3); W3.click(S3.gmore)
    sheet(W3, 1)
    local seen, u = {}, 0
    for _ = 1, 22 do W3.click(S3.lang.plus); local x = tostring(W3.ns.Store.Setting("lang")); if not seen[x] then seen[x] = true; u = u + 1 end end
    sheet(W3, 3)
    local n3, e3 = W3.errs()
    K.check("2 " .. code .. ": Sprachpfeil durch Automatisch und alle 21, Seite Mehr bleibt", u == 22 and st(S3) == "2*" and n3 == 0, u .. " " .. st(S3) .. " " .. tostring(e3))
  end
end

------------------------------------------------------------------------ (3)
do
  local W = K.world("deDE")
  local BM, ns = W.BM, W.ns
  local p = newproxy(true)
  local mt = getmetatable(p)
  local beruehrt = 0
  local function boom() beruehrt = beruehrt + 1; error("Secret beruehrt", 2) end
  for _, k in ipairs({ "__index", "__newindex", "__call", "__concat", "__len", "__lt", "__le", "__add", "__sub", "__mul", "__div", "__mod", "__pow", "__unm", "__tostring", "__eq" }) do mt[k] = boom end
  BM.secrets[p] = true
  local NIL = {}
  local targets = { 63, 40, 20, -1, 0, NIL, p, 60.9, "63", true }
  local mines = { 40, NIL, 0, p, -1, "40" }
  local stores = { NIL, 55, p, 0, -3, "55", 61.7 }
  local n, fehler, falsch = 0, 0, 0
  for _, tv in ipairs(targets) do for _, mv in ipairs(mines) do for _, sv in ipairs(stores) do
    BM.levelFn = function(u) local v = (u == "player") and mv or tv; if v == NIL then return nil end; return v end
    local stv = sv; if stv == NIL then stv = nil end
    local ok, text, warn = pcall(ns.Look.LevelLine, "mouseover", stv)
    n = n + 1
    if not ok then fehler = fehler + 1 else
      local live = type(tv) == "number" and tv >= 1 and math.floor(tv) or nil
      local skull = (type(tv) == "number" and tv < 1) or tv == NIL
      local last = not live and not skull and type(stv) == "number" and stv >= 1 and math.floor(stv) or nil
      local lvl = live or last
      local mine = type(mv) == "number" and mv >= 1 and mv or nil
      local wantWarn = skull or (lvl ~= nil and mine ~= nil and lvl > mine)
      if (warn == true) ~= (wantWarn and true or false) then falsch = falsch + 1 end
      if not skull and not lvl and text ~= nil then falsch = falsch + 1 end
      if lvl and mine and lvl > mine and not tostring(text):find("(+" .. (lvl - mine) .. ")", 1, true) then falsch = falsch + 1 end
      if lvl and mine and lvl <= mine and tostring(text):find("(+", 1, true) then falsch = falsch + 1 end
    end
    local ok2 = pcall(ns.Look.LevelLine, nil, stv)
    if not ok2 then fehler = fehler + 1 end
  end end end
  BM.levelFn = nil
  K.info(("(3) %d Kombinationen Ziel x eigene Stufe x gespeichert"):format(n))
  K.check("3 Stufenzeile: kein Fehler", fehler == 0, fehler)
  K.check("3 Stufenzeile: kein Secret verglichen oder verrechnet", beruehrt == 0, beruehrt)
  K.check("3 Stufenzeile: Warnfarbe und (+n) genau bei hoeher bzw. unbekannt", falsch == 0, falsch)
  for _, code in ipairs(K.CODES) do
    local worst = 999
    local okAll, err = true, nil
    for _, case in ipairs({ "live", "last", "skull" }) do
      local W2 = K.world(code)
      W2.ns.Store.ApplyKill({ name = "Maximilianus", surname = "Donnerschlagbringer", class = "MAGE", level = 999 }, { t = _G.time() - 100, zone = "Z", theirLevel = 999 }, true)
      W2.BM.levelFn = function(u)
        if u == "player" then return 1 end
        if case == "live" then return 999 elseif case == "skull" then return -1 end
        return "SECRET_NAME"
      end
      W2.AM.AddEnemy("mouseover", { name = "Maximilianus", surname = "Donnerschlagbringer", guid = "Player-1-MD", level = 999, class = "MAGE" })
      W2.AM.FireEvent("UPDATE_MOUSEOVER_UNIT"); W2.tick()
      local popup = rawget(W2.BM.G, "DeathNoteAlert")
      if not (popup and popup:IsShown()) then okAll, err = false, case .. ": kein Popup" else
        local pl = W2.frameBox(popup)
        local ll, _, lr = W2.box(popup.level)
        local nl, _, nr = W2.frameBox(popup.name)
        local feld = nr - nl
        if feld < worst then worst = feld end
        if not (popup.level.warn == true and nr <= ll and ll - pl >= 86 + 100 and lr - pl <= 384 - 12 + 0.5) then okAll, err = false, case .. ": Lage" end
      end
      local n2, e2 = W2.errs(); if n2 > 0 then okAll, err = false, e2 end
    end
    K.check(("3 %s: Stufe in Warnfarbe rechts, Name endet davor (kleinstes Namensfeld %d px)"):format(code, worst), okAll, err)
  end
end

------------------------------------------------------------------------ (4)
for _, code in ipairs(K.CODES) do
  local W = K.world(code, { humor = true })
  W.ns:Fire("TOGGLE_UI"); W.tick(); W.settle()
  W.ns.UI.OpenPanel("help"); W.tick()
  local Hp = W.frameWith(function(f) return f.paras end)
  local _, _, _, pt = W.frameBox(Hp)
  local low, lines, maxl = 0, 0, 0
  for _, p in ipairs(Hp.paras) do
    local _, b, r, _, n = W.box(p[2])
    low = pt - b; lines = lines + n; if n > maxl then maxl = n end
  end
  local limit = Hp.foot and (490 - 44 - 11) or (490 - 34)
  local footOk = not Hp.foot or K.estimate(Hp.foot) <= 380 - 40
  K.check(("4 %s: %d Absaetze, %d Zeilen (hoechstens %d), Luft %d px bis %s"):format(code, #Hp.paras, lines, maxl, limit - low, Hp.foot and "Fusszeile" or "Knopf"),
    #Hp.paras == 8 and limit - low >= 12 and footOk and ((code == "deDE" or code == "enUS") == (Hp.foot ~= nil)), limit - low)
  local n, e = W.errs(); K.check("4 " .. code .. ": keine Fehler", n == 0, e)
end

------------------------------------------------------------------------ (5)
do
  local W = K.world("enUS")
  local ns, P, t = W.ns, W.P, _G.time()
  W.whisper(P.EncodeHello(0, "1.2.0"))
  local function kill(ch, key, n, victim)
    for i = 1, n do
      local m = P.EncodeKill({ key = key, display = key:gsub("-", " "), class = "MAGE", level = 40, zone = "Z", t = t - 60 * i - #key, victim = victim }, "K")
      if ch == "g" then W.gmsg(m) else W.whisper(m) end
    end
  end
  kill("g", "Aaa-Eins", 2, "Kollege Wurst"); kill("f", "Aaa-Eins", 3, "Fritz Frei")
  kill("g", "Bbb-Zwei", 4, "Kollege Wurst"); kill("f", "Ccc-Drei", 4, "Fritz Frei")
  kill("g", "Ddd-Vier", 1, "Kollege Wurst"); kill("f", "Eee-Fuenf", 1, "Fritz Frei")
  W.tick(5)
  ns:Fire("TOGGLE_UI"); W.tick(); W.settle(); W.tab("guild")
  local E = W.frameWith(function(f) return f.stampNr1 and f.hunt end)
  local bad, n = 0, 0
  for _, v in ipairs({ "enemy", "member" }) do for _, s in ipairs({ "all", "guild", "friends" }) do
    ns.UI.SetGuildView(v); ns.UI.SetGuildSource(s); W.tick()
    if v == "member" then
      for _ = 1, 3 do for _, f in ipairs(W.BM.frames) do
        if f._kind == "Button" and f.item and f.item.wrap and f.item.head and f:IsVisible() and not f._auf then f._auf = true; W.click(f) end
      end end
    end
    local seen = {}
    for _, r in ipairs(W.rows()) do
      local it = r.item
      local key = it.key or (it.wrap and it.r and it.r.key)
      if key and not (it.wrap and it.head) then
        local tx = r.rank and r.rank:IsVisible() and r.rank._text or ""
        W.click(r)
        local nr1 = E:IsVisible() and E.stampNr1:IsShown() and true or false
        local want = ns.Guild.Rank(key, s)
        n = n + 1
        if (want == 1) ~= nr1 then bad = bad + 1 end
        if tx ~= "" and tonumber((tx:gsub("%D", ""))) ~= want then bad = bad + 1 end
        if v == "enemy" then if seen[tx] then bad = bad + 1 end; seen[tx] = true end
      end
    end
  end end
  K.check(("5 Rang je Quelle: %d Zeilen, Rangzahl, Guild.Rank und Stempel Nr. 1 stimmen"):format(n), n >= 20 and bad == 0, bad)
  local ne, e = W.errs(); K.check("5 keine Fehler", ne == 0, e)
end

K.done("beleg_ui_5 Gegenproben")
