-- Beleg UI 3: Gildenbuch-Plakat der Nr. 1, die zugleich auf der Abschussliste steht (UI.lua, FillGuild).
-- Aufruf: nice -n 15 luajit beleg_ui_3_plakat_nr1_abschussliste.lua <Projektkopie>
-- Regel aus fix-3: am Fotoplatz steht ein Stempel (Nr. 1 vor ZUR JAGD FREIGEGEBEN); was nicht gestempelt ist, steht
-- als Steckbriefzeile ("Auf der Abschussliste"); unter einem Fotostempel steht kein Wort mehr.
-- Erwartet: das Plakat zeigt irgendwo, dass der Spieler auf der Abschussliste steht (Stempel, Steckbriefzeile oder,
-- bei eigener Freigabe, das Wort "abblasen"). Das eigene Plakat (Gegenprobe) zeigt die Zeile.
-- Dazu: jede Aktion bleibt erreichbar (Zeilenmenue), in allen Zustaenden.
-- Alle Namen sind erfunden; geprueft wird ueber Schluessel (enUS ist nur die Sprache der Welt).
package.path = (arg[0]:match("^(.*)/[^/]+$") or ".") .. "/?.lua;" .. package.path
local K = require("_kopf_ui")

local function welt(own, hunt)
  local W = K.world("enUS")
  local ns, P, t = W.ns, W.P, _G.time()
  W.whisper(P.EncodeHello(0, "1.2.0"))
  local key = "Ziel-Eins"
  if own then ns.Store.ApplyKill({ name = "Ziel", surname = "Eins", class = "MAGE", level = 40 }, { t = t - 100, zone = "Z" }, true) end
  W.gmsg(P.EncodeKill({ key = key, display = "Ziel Eins", class = "MAGE", level = 40, zone = "Z", t = t - 60, victim = "Kollege Wurst" }, "K"))
  if hunt:find("mate") then W.gmsg(P.EncodeHunt({ key = key, display = "Ziel Eins", class = "MAGE", level = 40, t = t - 50, by = "Kollege Wurst", why = "weil" })) end
  if hunt:find("friend") then W.whisper(P.EncodeHunt({ key = key, display = "Ziel Eins", class = "MAGE", level = 40, t = t - 50, by = "Fritz Frei", why = "weil" })) end
  W.tick(2)
  if hunt:find("mine") then ns.Guild.Release(key, { to = "all", why = "x" }) end
  W.tick(12); W.settle()
  ns:Fire("TOGGLE_UI"); W.tick(); W.settle()
  W.E = W.frameWith(function(f) return f.stampNr1 and f.hunt end)
  W.key = key
  return W
end
local function stempel(W, tex)
  if not tex:IsShown() then return nil end
  -- Schluessel ueber den Wortlaut der aktiven Sprache (mehrere Schluessel koennen gleich lauten: fest vergleichen)
  local t = tex.label and tex.label.on and tex.label.text
  for _, k in ipairs({ "STAMP_GUILD_NR1", "STAMP_NR1", "STAMP_HUNT", "STAMP_PARDONED", "STAMP_SUSPECT", "STAMP_REVENGE" }) do
    if t == W.L[k] then return k end
  end
  return "?"
end
local function zeile(W)
  local pre = W.L.POSTER_ON_HUNTLIST:match("^(.-){") or W.L.POSTER_ON_HUNTLIST
  for i = 1, #W.E.info do if W.E.info[i]:IsVisible() and (W.E.info[i]._text or ""):find(pre, 1, true) then return true end end
  return false
end
local function menue(W, row)
  row._scripts.OnClick(row, "RightButton"); W.tick()
  local menu, m = rawget(W.BM.G, "DeathNoteMenu"), {}
  if menu and menu:IsShown() then
    for _, it in ipairs(menu.items) do
      if it:IsShown() then
        local t = (it.text or it.label)._text
        for _, k in ipairs({ "ACT_RELEASE", "ACT_CALLOFF", "ACT_HUNT_HIDE", "ACT_HUNT_SHOW", "ACT_CALLOFF_ALL", "ACT_ADOPT", "ACT_OPEN_OWN" }) do
          if t == W.L[k] then m[k] = true end
        end
      end
    end
    menu.blocker._scripts.OnClick(menu.blocker)
  end
  return m
end
local function zeileVon(W, key)
  for _, r in ipairs(W.rows()) do local it = r.item; if it and (it.key == key or (it.wrap and it.r and it.r.key == key)) then return r end end
end

for _, hunt in ipairs({ "mate", "friend", "mine", "mine+mate" }) do
  local W = welt(false, hunt)
  W.tab("guild"); W.ns.UI.SetGuildView("enemy"); W.ns.UI.SetGuildSource("all"); W.tick()
  local r = zeileVon(W, W.key)
  K.check(hunt .. ": Zeile im Gildenbuch", r ~= nil)
  if r then
    W.click(r)
    local E = W.E
    local nr1, foto = stempel(W, E.stampNr1), stempel(W, E.stampOther)
    local wort = E.hunt:IsShown() and ((E.hunt.text._text == W.L.ACT_CALLOFF and "ACT_CALLOFF") or (E.hunt.text._text == W.L.ACT_RELEASE and "ACT_RELEASE") or "?") or nil
    local mine = hunt:find("mine") ~= nil
    K.info(("%s: Gildenplakat Nr.1-Stempel %s, Fotostempel %s, Wort %s, Steckbriefzeile %s"):format(hunt, tostring(nr1), tostring(foto), tostring(wort), tostring(zeile(W))))
    K.check(hunt .. ": Vorbedingung Nr. 1 des Gildenbuchs und auf der Abschussliste", nr1 == "STAMP_GUILD_NR1" and W.ns.Guild.Hunt(W.key, "all") ~= nil)
    K.check(hunt .. ": hoechstens ein Stempel am Fotoplatz", not (nr1 and foto))
    K.check(hunt .. ": das Gildenplakat zeigt, dass er auf der Abschussliste steht (Stempel, Zeile oder Wort abblasen)",
      foto == "STAMP_HUNT" or zeile(W) or (mine and wort == "ACT_CALLOFF"))
    local m = menue(W, r)
    K.check(hunt .. ": Aktion im Zeilenmenue erreichbar", (mine and m.ACT_CALLOFF) or (not mine and m.ACT_RELEASE))
  end
  local n, e = W.errs(); K.check(hunt .. ": keine Fehler", n == 0, e)
end

-- Gegenprobe: eigenes Plakat der eigenen Nr. 1 zeigt die Steckbriefzeile; Aktion im Zeilenmenue
for _, hunt in ipairs({ "mate", "mine" }) do
  local W = welt(true, hunt)
  W.tab("wanted")
  local r = zeileVon(W, W.key)
  if r then W.click(r) end
  K.check("eigen/" .. hunt .. ": Stempel Nr. 1 und Steckbriefzeile", r ~= nil and stempel(W, W.E.stampNr1) == "STAMP_NR1" and zeile(W))
  local m = r and menue(W, r) or {}
  K.check("eigen/" .. hunt .. ": Aktion im Zeilenmenue", (hunt == "mine" and m.ACT_CALLOFF) or (hunt ~= "mine" and m.ACT_RELEASE))
  -- Plakat der Abschussliste: Stempel, Knopf, Ausblenden im Zeilenmenue
  W.tab("guild"); W.ns.UI.SetGuildView("hunt"); W.tick()
  r = zeileVon(W, W.key)
  if r then W.click(r) end
  m = r and menue(W, r) or {}
  K.check("abschussliste/" .. hunt .. ": Stempel ZUR JAGD FREIGEGEBEN, kein Wort", r ~= nil and stempel(W, W.E.stampOther) == "STAMP_HUNT" and not W.E.hunt:IsShown())
  K.check("abschussliste/" .. hunt .. ": Freigeben bzw. Abblasen und Ausblenden im Zeilenmenue",
    ((hunt == "mine" and m.ACT_CALLOFF) or (hunt ~= "mine" and m.ACT_RELEASE)) and (m.ACT_HUNT_HIDE or m.ACT_HUNT_SHOW))
  local n, e = W.errs(); K.check("eigen/" .. hunt .. ": keine Fehler", n == 0, e)
end

K.done("beleg_ui_3 Plakat Nr. 1 auf der Abschussliste")
