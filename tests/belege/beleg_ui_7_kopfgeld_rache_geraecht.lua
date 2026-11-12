-- 1.2.1, UI: bounty on the poster (click, input, line, sum, coin in the list), undo revenge
-- (button, menu, message, milestone), "avenged by" (poster, line, chat with sound), in all 21 languages without errors.
-- Usage: nice -n 15 luajit beleg_ui_7_kopfgeld_rache_geraecht.lua <project copy>
-- Checked via keys (enUS is only the world's language). All names are made up.
package.path = (arg[0]:match("^(.*)/[^/]+$") or ".") .. "/?.lua;" .. package.path
local K = require("_kopf_ui")

local function welt(code, opts)
  local W = K.world(code or "enUS", opts)
  local ns, P, t = W.ns, W.P, _G.time()
  W.key = ns.Store.ApplyKill({ name = "Grimm", surname = "Bart", class = "MAGE", level = 40 },
    { t = t - 100, zone = "Z", me = "Varorak Narenmar", source = "recap" }, true)
  ns.Store.ApplyKill({ name = "Ohne", surname = "Geld", class = "MAGE", level = 40 },
    { t = t - 300, zone = "Z", me = "Varorak Narenmar", source = "recap" }, true)
  W.tick(40); W.settle()
  ns:Fire("TOGGLE_UI"); W.tick(); W.settle()
  W.E = W.frameWith(function(f) return f.stampNr1 and f.hunt end)
  W.zeigen = function(key)
    ns.UI.ShowEnemy(key); W.tick()
  end
  return W
end
local function zeileMit(W, pre)
  for i = 1, #W.E.info do
    local fs = W.E.info[i]
    if fs:IsVisible() and (fs._text or ""):find(pre, 1, true) then return fs._text end
  end
end
local function vorn(s) return (s:match("^(.-){") or s) end
local function hinten(s) return (s:match("}([^}]*)$") or s) end
local function menue(W, row)
  row._scripts.OnClick(row, "RightButton"); W.tick()
  local menu, m = rawget(W.BM.G, "DeathNoteMenu"), {}
  if menu and menu:IsShown() then
    for _, it in ipairs(menu.items) do
      if it:IsShown() then m[W.keyOf[(it.text or it.label)._text] or "?"] = it end
    end
  end
  return m, menu
end
local function zu(menu) if menu and menu:IsShown() then menu.blocker._scripts.OnClick(menu.blocker) end end
local function zeileVon(W, key)
  for _, r in ipairs(W.rows()) do local it = r.item; if it and (it.key == key or (it.wrap and it.r and it.r.key == key)) then return r end end
end

------------------------------------------------------------------------ (1) own bounty on the poster
do
  local W = welt("enUS")
  local ns, E, L = W.ns, W.E, W.L
  W.zeigen(W.key)
  local auto = E.bounty._text
  K.check("1 ohne Ausgelobtes: Wert des Buchs, Klickflaeche da, keine Zeile", auto ~= nil and E.bountyHit:IsShown()
    and not E.bountyLineHit:IsShown(), auto)
  W.click(E.bountyHit)
  local ed = E.bountyEdit
  K.check("1 Klick aufs Kopfgeld: Eingabe offen, Wert verdeckt", ed:IsShown() and not E.bounty:IsShown())
  local chat0 = #W.AM.chat
  ed:SetText("abc"); ed._scripts.OnEnterPressed(ed); W.tick()
  K.check("1 Unsinn: Eingabe bleibt offen, eine Chatzeile", ed:IsShown() and #W.AM.chat == chat0 + 1 and ns.Guild.OwnBounty(W.key) == nil)
  ed:SetText("100000"); ed._scripts.OnEnterPressed(ed); W.tick()
  K.check("1 100000: abgelehnt", ed:IsShown() and ns.Guild.OwnBounty(W.key) == nil)
  ed:SetText("1500"); ed._scripts.OnEnterPressed(ed); W.tick()
  K.check("1 1500 + Enter: gesetzt, Eingabe zu", not ed:IsShown() and ns.Guild.OwnBounty(W.key) == 1500 and E.bounty:IsShown())
  W.zeigen(W.key)
  K.check("1 gross die Summe", E.bounty._text ~= auto and (E.bounty._text or ""):find("1", 1, true) ~= nil, E.bounty._text)
  K.check("1 Zeile: von dir ausgelobt", zeileMit(W, hinten(L.POSTER_BOUNTY_MINE)) ~= nil and E.bountyLineHit:IsShown())
  K.check("1 Muenze in der Zeile des Taeters", (function()
    local r = zeileVon(W, W.key); return r and r.coin:IsShown() end)())
  K.check("1 keine Muenze beim Taeter ohne Kopfgeld", (function()
    local r = zeileVon(W, "Ohne-Geld"); return r and not r.coin:IsShown() end)())
  -- Esc: nothing changes
  W.click(E.bountyHit); ed:SetText("7"); ed._scripts.OnEscapePressed(ed); W.tick()
  K.check("1 Esc bricht ab", ns.Guild.OwnBounty(W.key) == 1500 and not ed:IsShown())
  -- focus lost: cancel, do not save
  W.click(E.bountyHit); ed:SetText("8"); ed._scripts.OnEditFocusLost(ed); W.tick()
  K.check("1 Fokus weg bricht ab", ns.Guild.OwnBounty(W.key) == 1500 and not ed:IsShown())
  -- empty: back to the book's value
  W.click(E.bountyHit); ed:SetText(""); ed._scripts.OnEnterPressed(ed); W.tick()
  W.zeigen(W.key)
  K.check("1 leer + Enter: zurueckgenommen, Wert des Buchs", ns.Guild.OwnBounty(W.key) == nil and E.bounty._text == auto, E.bounty._text)
  -- other posters: 4 of them, large sum, "and 1 more"
  local P, t = W.P, _G.time()
  for i, n in ipairs({ "Anna", "Bert", "Cora", "Dirk" }) do
    W.gmsg(P.EncodeBounty(W.key, n .. " Wurst", 100 * i, t), n .. " Wurst-Forever")
  end
  W.tick(1); W.zeigen(W.key)
  local z = zeileMit(W, vorn(L.POSTER_BOUNTY_MANY))
  local more = vorn(L.NAMELIST_MORE:gsub("{names}", ""))
  K.check("1 vier Auslober: Summe 1000, drei mit Namen und einer weiterer", z ~= nil and z:find("Dirk", 1, true) ~= nil
    and z:find("Anna", 1, true) == nil and (E.bounty._text or ""):find("1", 1, true) ~= nil, z)
  local n, e = W.errs(); K.check("1 keine Fehler", n == 0, e)
end

------------------------------------------------------------------------ (2) menu, right click on the poster, guild, hit list
do
  local W = welt("enUS")
  local ns, E, L, P, t = W.ns, W.E, W.L, W.P, _G.time()
  local r = zeileVon(W, W.key)
  local m, menu = menue(W, r)
  K.check("2 Zeilenmenue: Kopfgeld festlegen", m.ACT_BOUNTY ~= nil)
  if m.ACT_BOUNTY then m.ACT_BOUNTY._scripts.OnClick(m.ACT_BOUNTY, "LeftButton"); W.tick() end
  K.check("2 aus dem Menue: Eingabe offen", E.bountyEdit:IsShown())
  E.bountyEdit._scripts.OnEscapePressed(E.bountyEdit); W.tick()
  zu(menu)
  E._scripts.OnMouseUp(E, "RightButton"); W.tick()
  local menu2 = rawget(W.BM.G, "DeathNoteMenu")
  K.check("2 Rechtsklick aufs Plakat oeffnet das Menue", menu2 and menu2:IsShown())
  zu(menu2)
  -- guild book: bounty as a line, coin, avenged
  W.gmsg(P.EncodeKill({ key = "Gilde-Feind", display = "Gilde Feind", class = "MAGE", level = 40, zone = "Z", t = t - 60,
    victim = "Kollege Wurst" }, "K"))
  W.gmsg(P.EncodeBounty("Gilde-Feind", "Kollege Wurst", 250, t))
  W.gmsg(P.EncodeAvenged("Gilde-Feind", "Kollege Wurst", t - 5, false))
  W.tick(5)
  W.tab("guild"); ns.UI.SetGuildView("enemy"); ns.UI.SetGuildSource("all"); W.tick()
  local gr = zeileVon(W, "Gilde-Feind")
  K.check("2 Gildenzeile: Muenze und Zahl gerächt", gr and gr.coin:IsShown() and (gr.sub._text or ""):find(vorn(L.ROW_AVENGED), 1, true) ~= nil,
    gr and gr.sub._text)
  if gr then W.click(gr) end
  K.check("2 Gildenplakat: Zeile Kopfgeld", zeileMit(W, hinten(L.POSTER_BOUNTY_BY)) ~= nil)
  K.check("2 Gildenplakat: Zeile gerächt von", zeileMit(W, vorn(L.POSTER_AVENGED)) ~= nil)
  K.check("2 Gildenplakat: Opferzahl bleibt am grossen Platz", E.bounty:IsShown() and not E.bountyHit:IsShown())
  local m3, menu3 = menue(W, gr)
  K.check("2 Gildenzeile: Menue mit Kopfgeld festlegen", m3.ACT_BOUNTY ~= nil)
  if m3.ACT_BOUNTY then m3.ACT_BOUNTY._scripts.OnClick(m3.ACT_BOUNTY, "LeftButton"); W.tick() end
  E.bountyEdit:SetText("40"); E.bountyEdit._scripts.OnEnterPressed(E.bountyEdit); W.tick()
  K.check("2 am Gildenplakat gesetzt", ns.Guild.OwnBounty("Gilde-Feind") == 40)
  zu(menu3)
  -- hit list
  W.gmsg(P.EncodeHunt({ key = "Gilde-Feind", display = "Gilde Feind", class = "MAGE", level = 40, t = t - 50, by = "Kollege Wurst", why = "weil" }))
  W.tick(12); W.settle()
  ns.UI.SetGuildView("hunt"); W.tick()
  local hr = zeileVon(W, "Gilde-Feind")
  if hr then W.click(hr) end
  K.check("2 Abschussliste: Muenze, Zeile Kopfgeld mit Summe", hr and hr.coin:IsShown() and zeileMit(W, vorn(L.POSTER_BOUNTY_MANY)) ~= nil)
  local n, e = W.errs(); K.check("2 keine Fehler", n == 0, e)
end

------------------------------------------------------------------------ (3) undo revenge
do
  local W = welt("deDE", { humor = true })
  local ns, E, L = W.ns, W.E, W.L
  W.zeigen(W.key)
  local b1 = E.buttons[1]
  K.check("3 erster Knopf: Rache vermerken", b1.text._text == L.ACT_REVENGE, b1.text._text)
  W.click(b1)
  local e = ns.Store.Get(W.key)
  K.check("3 vermerkt: Rache 1, von Hand 1", e.revenge == 1 and e.revengeHand == 1)
  W.tick(0.5)
  local banner = rawget(W.BM.G, "DeathNoteBanner")
  K.check("3 Rache-Meldung steht", banner and banner:IsShown())
  local db = ns.Store.DB()
  local m1 = db.humor and db.humor.m and db.humor.m.revenge1
  K.check("3 derselbe Knopf heisst jetzt Rueckgaengig", b1.text._text == L.ACT_UNDO, b1.text._text)
  W.click(b1)
  K.check("3 Rueckgaengig: Rache 0, Stempel weg, Meldung weg", e.revenge == 0 and not E.stampRache:IsShown()
    and not (banner and banner:IsShown()) and b1.text._text == L.ACT_REVENGE)
  W.click(b1); W.tick(9)
  K.check("3 nach etwa 8 Sekunden wieder Rache vermerken", b1.text._text == L.ACT_REVENGE and e.revenge == 1)
  K.check("3 Meilenstein 'erste Rache' nicht noch einmal", db.humor.m.revenge1 == m1 and m1 ~= nil, tostring(m1))
  local m, menu = menue(W, zeileVon(W, W.key))
  K.check("3 Zeilenmenue: eine Rache abziehen", m.ACT_REVENGE_TAKE ~= nil)
  if m.ACT_REVENGE_TAKE then m.ACT_REVENGE_TAKE._scripts.OnClick(m.ACT_REVENGE_TAKE, "LeftButton"); W.tick() end
  K.check("3 abgezogen", e.revenge == 0)
  zu(menu)
  m, menu = menue(W, zeileVon(W, W.key))
  K.check("3 ohne Rache von Hand: kein Abziehen im Menue", m.ACT_REVENGE_TAKE == nil)
  zu(menu)
  -- detected revenge (not by hand): cannot be taken back
  ns.Store.AddRevenge(W.key); W.tick()
  m, menu = menue(W, zeileVon(W, W.key))
  K.check("3 erkannte Rache: kein Abziehen", m.ACT_REVENGE_TAKE == nil)
  zu(menu)
  local n, er = W.errs(); K.check("3 keine Fehler", n == 0, er)
end

------------------------------------------------------------------------ (4) "done for you": chat line and sound, no message
do
  local W = welt("deDE")
  local P = W.P
  local chat0, snd0 = #W.AM.chat, #W.BM.sounds
  W.gmsg(P.EncodeAvenged(W.key, "Kollege Wurst", _G.time() - 5, false))
  W.tick(1)
  K.check("4 erst nach kurzer Wartezeit", #W.AM.chat == chat0)
  W.tick(4)
  local line = W.AM.chat[#W.AM.chat] or ""
  K.check("4 eine Chatzeile mit Raecher und Taeter", #W.AM.chat == chat0 + 1 and line:find("Kollege", 1, true) ~= nil
    and line:find("Grimm", 1, true) ~= nil, line)
  K.check("4 der kurze Ton der Rache-Meldung", #W.BM.sounds > snd0 and W.BM.sounds[#W.BM.sounds] == "kit:17316", W.BM.sounds[#W.BM.sounds])
  local banner = rawget(W.BM.G, "DeathNoteBanner")
  K.check("4 kein Fenster", not (banner and banner:IsShown()))
  W.zeigen(W.key)
  K.check("4 Plakat: gerächt von Kollege 1×", zeileMit(W, vorn(W.L.POSTER_AVENGED)) ~= nil)
  K.check("4 Stempel RACHE GENOMMEN bleibt aus", not W.E.stampRache:IsShown())
  local n, e = W.errs(); K.check("4 keine Fehler", n == 0, e)
end

------------------------------------------------------------------------ (5) all 21 languages: poster with everything, buttons and menu fit
for _, code in ipairs(K.CODES) do
  local W = welt(code)
  local ns, E, L, P, t = W.ns, W.E, W.L, W.P, _G.time()
  for i, n in ipairs({ "Anna", "Bert", "Cora", "Dirk" }) do W.gmsg(P.EncodeBounty(W.key, n .. " Wurst", 1000 * i, t), n .. " Wurst-Forever") end
  ns.Guild.SetBounty(W.key, 99999)
  W.gmsg(P.EncodeAvenged(W.key, "Anna Wurst", t - 5, false), "Anna Wurst-Forever")
  W.tick(5)
  W.zeigen(W.key)
  W.click(E.buttons[1])
  local undoW = K.estimate(E.buttons[1].text)
  local m, menu = menue(W, zeileVon(W, W.key))
  local breit = 0
  for _, k in ipairs({ "ACT_BOUNTY", "ACT_UNDO" }) do
    local it = m[k]
    if it then local w = K.estimate(it.text); if w > breit then breit = w end end
  end
  zu(menu)
  local n, e = W.errs()
  io.write(("      %s Rueckgaengig %d px, Menue %d px, Zeile: %s\n"):format(code, undoW, breit, tostring(zeileMit(W, (L.POSTER_BOUNTY_MANY:match("^(.-){") or "")))))
  K.check(("5 %s: Plakat mit Kopfgeld, gerächt, Rueckgaengig; Knopf %d px, Menue %d px"):format(code, undoW, breit),
    n == 0 and undoW <= E.buttons[1]:GetWidth() - 4 and breit <= 148 - 4 and m.ACT_BOUNTY ~= nil, e or (undoW .. "/" .. breit))
end

K.done("beleg_ui_7 Kopfgeld, Rache, gerächt")
