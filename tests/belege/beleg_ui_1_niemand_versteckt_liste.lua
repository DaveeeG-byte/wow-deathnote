-- Beleg UI 1: "niemand zum Teilen" (GF.Survey, fix-3) versteckt Ansichten und Stand, obwohl es Daten gibt.
-- Aufruf: nice -n 15 luajit beleg_ui_1_niemand_versteckt_liste.lua <Projektkopie>
-- Fall A: Gildenmitglied mit Gildenbuch, fremder Freigabe und eigener Freigabe schaltet "Mit der Gilde teilen" und
--         "Mit Freunden teilen" aus. Erwartet: die Ansichten bleiben erreichbar (es gibt Eintraege und Freigaben),
--         die Statuszeile sagt, dass nicht geteilt wird.
-- Fall B: ohne Gilde, ein Freund mit DeathNote hat ein Ziel freigegeben; "Mit Freunden teilen" aus. Der Alarm
--         fuer das Ziel kommt weiter; erwartet: dann ist die Abschussliste auch zu oeffnen.
-- Alle Namen sind erfunden. Geprueft wird ueber Daten und Schluessel, nicht ueber Wortlaute.
package.path = (arg[0]:match("^(.*)/[^/]+$") or ".") .. "/?.lua;" .. package.path
local K = require("_kopf_ui")

local function lage(W)
  local VIEWS = W.frameWith(function(f) return f.items and f.items[1] and f.items[1].view end)
  local LP = W.frameWith(function(f) return f.status and f.statusHit and f.sync end)
  local o = { views = VIEWS and VIEWS:IsVisible() or false, hunt = false, status = "" }
  if o.views then for _, b in ipairs(VIEWS.items) do if b.view == "hunt" and b:IsVisible() then o.hunt = true end end end
  if LP and LP.status:IsVisible() then o.status = LP.status._text or "" end
  return o
end
local function open(W) W.ns:Fire("TOGGLE_UI"); W.tick(); W.settle(); W.tab("guild"); W.settle() end

-- Fall A
do
  local W = K.world("deDE")
  local ns, P, t = W.ns, W.P, _G.time()
  W.whisper(P.EncodeHello(0, "1.2.0"))
  W.gmsg(P.EncodeKill({ key = "Rauf-Bold", display = "Rauf Bold", class = "ROGUE", level = 44, zone = "Z", t = t - 90, victim = "Kollege Wurst" }, "K"))
  W.gmsg(P.EncodeHunt({ key = "Ziel-Eins", display = "Ziel Eins", t = t, by = "Kollege Wurst", why = "x", level = 40 }))
  ns.Store.AddManual("Ziel", "Zwei")
  ns.Guild.Release("Ziel-Zwei", { to = "all", why = "y" })
  W.tick(12)
  open(W)
  ns.UI.SetGuildView("enemy"); W.tick()
  local vor = lage(W)
  K.check("A Vorbedingung: Ansichten samt Abschussliste, Statuszeile da", vor.views and vor.hunt and vor.status ~= "")
  ns.Store.Setting("guild.share", false)
  ns.Store.Setting("guild.friends", false)
  W.tick(2); W.settle()
  local nach = lage(W)
  local eintraege = (ns.Guild.Count("all"))
  local ziele, eigene = ns.Guild.HuntCount("all"), ns.Guild.OwnReleaseCount()
  K.info(("A nach beiden Schaltern aus: Gildenname %s, Eintraege %s, Ziele %s, eigene Freigaben %s, Zeilen links %d")
    :format(tostring(ns.Guild.Name() ~= nil), tostring(eintraege), tostring(ziele), tostring(eigene), #W.rows()))
  K.check("A Vorbedingung: Daten sind noch da", eintraege > 0 and ziele == 2 and eigene == 1)
  K.check("A Ansicht-Umschalter bleibt, solange es Eintraege und Freigaben gibt", nach.views)
  K.check("A Abschussliste (mit eigener Freigabe) bleibt erreichbar", nach.hunt)
  K.check("A Statuszeile sagt den Stand (Teilen aus), nicht leer", nach.status ~= "", "leer")
  W.AM.AddEnemy("mouseover", { name = "Ziel", surname = "Eins", guid = "Player-1-ZE", level = 40 })
  W.AM.FireEvent("UPDATE_MOUSEOVER_UNIT"); W.tick(1)
  local p = rawget(W.BM.G, "DeathNoteAlert")
  local alarm = p and p:IsShown() or false
  K.info("A Alarm fuer das fremde Ziel in diesem Zustand: " .. tostring(alarm))
  K.check("A wer alarmiert wird, kann die Abschussliste oeffnen", not alarm or nach.hunt)
  local n, e = W.errs()
  K.check("A keine Fehler", n == 0, e)
end

-- Fall B
do
  local W = K.world("deDE", { guild = false })
  local ns, P = W.ns, W.P
  W.whisper(P.EncodeHello(0, "1.2.0")); W.tick(2)
  W.whisper(P.EncodeHunt({ key = "Ziel-Drei", display = "Ziel Drei", t = _G.time(), by = "Fritz Frei", why = "x", level = 40 }))
  W.tick(12)
  open(W)
  ns.UI.SetGuildView("enemy"); W.tick()
  local vor = lage(W)
  K.check("B Vorbedingung: Abschussliste waehlbar", vor.views and vor.hunt)
  ns.Store.Setting("guild.friends", false)
  W.tick(2); W.settle()
  local nach = lage(W)
  W.AM.AddEnemy("mouseover", { name = "Ziel", surname = "Drei", guid = "Player-1-ZD", level = 40 })
  W.AM.FireEvent("UPDATE_MOUSEOVER_UNIT"); W.tick(1)
  local p = rawget(W.BM.G, "DeathNoteAlert")
  local alarm = p and p:IsShown() or false
  K.info(("B Teilen mit Freunden aus: Ziele %s, Alarm %s, Umschalter %s"):format(tostring(ns.Guild.HuntCount("all")), tostring(alarm), tostring(nach.views)))
  K.check("B wer alarmiert wird, kann die Abschussliste oeffnen", not alarm or nach.hunt)
  local n, e = W.errs()
  K.check("B keine Fehler", n == 0, e)
end

K.done("beleg_ui_1 niemand versteckt Liste")
