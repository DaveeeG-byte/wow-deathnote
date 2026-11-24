-- Nachjagd 1.6.4, Fund N4 (niedrig, Grenzfall). Aufruf: luajit jn03_leiste_ueber_muster.lua <projekt>   (rot = Exit 1)
-- Der Fixer hat den Fall "kein freier Platz fuer die Leiste" nur gelesen (fixer.md, A4). Hier ist er gebaut:
-- kleiner Schirm (UIParent 1024 x 576), die vier Lagen als Turm ueber dem Standardplatz der Leiste.
-- Erwartet: von jedem Muster bleibt genug frei, um es zu greifen (hier: ein Streifen von mindestens 16 Einheiten
-- neben oder ueber der Leiste), denn die Leiste nimmt die Maus und liegt dann in Schicht FULLSCREEN ueber den Mustern.
-- Ist auf e9c9b36: die Leiste (380 x 98) liegt fast deckungsgleich auf dem Alarm-Muster (384 x 108), frei bleibt ein
-- Rand von 2 bis 5 Einheiten. Ausweg fuer den Spieler bleibt "Positionen zuruecksetzen" auf der Leiste.
-- Auf ueblichen Schirmen (UIParent ab 1366 x 768, Alarmgroesse bis 150 %) habe ich den Fall nicht erreicht: neben
-- einem Muster ist dort immer Platz.
local WT = arg[1] or "."
local J = dofile(WT .. "/tests/ui/_mv164.lua")
local function pt(l, b) return { "BOTTOMLEFT", "BOTTOMLEFT", l, b, 1 } end
local db = { version = 5, settings = { welcomed = true, firstRun = "done", news164 = true, news160 = true, news150 = true,
  news140 = true, lang = "enUS", alert = { point = pt(320, 155) }, notice = { point = pt(336, 40) },
  call = { point = pt(336, 280) }, grudge = { point = pt(400, 420) } }, enemies = {}, deaths = {} }
local W = J.world("enUS", { db = db, ui = 2560 / 1024 })
W.slash("move")
local bar = W.frame("DeathNoteMove")
local bl, bb, br, bt = W.rect(bar)
print(("Leiste %.0f/%.0f bis %.0f/%.0f, Schicht %s"):format(bl, bb, br, bt, tostring(bar._strata)))
-- Suite copy, adapted (fixer round 2, decision N4): with no free place the bar lies UNDER the samples (layer MEDIUM)
-- instead of over them; then a sample is grabbed where it lies, also over the bar (the mock's TopFrame: who gets the click)
J.check("Voraussetzung: kein freier Platz, Leiste unter den Mustern", bar._strata == "MEDIUM", bar._strata)
J.check("Leiste liegt ganz auf dem Schirm", bl >= 0 and bb >= 0 and br <= 1024 and bt <= 576)
for _, n in ipairs({ "DeathNoteAlert", "DeathNoteBanner", "DeathNoteCall", "DeathNoteGrudge" }) do
  local l, b, r, t = W.rect(W.frame(n))
  local hit = l < br and r > bl and b < bt and t > bb
  local f = W.frame(n)
  local rim = hit and math.max(bl - l, r - br, bb - b, t - bt) or 999
  if hit and W.BM.TopFrame(f, bar) == f then rim = 999 end
  print(("   %-16s %.0f/%.0f bis %.0f/%.0f, freier Rand %s"):format(n, l, b, r, t, hit and ("%.0f"):format(rim) or "ganz frei"))
  J.check(n .. ": greifbar (ueber der Leiste oder 16 Einheiten neben ihr)", rim >= 16, ("%.0f"):format(rim))
end
-- (suite copy) the bar itself can be dragged aside, its place is not kept
J.check("Leiste laesst sich zur Seite ziehen", W.drag(bar, 0, 60) and not bar._userPlaced)
W.slash("move"); W.slash("move")
J.check("naechster Start: Leiste wieder auf ihrem Platz gesucht (nicht gehalten)", W.rect(bar) ~= nil and W.ns.Store.Setting("move.point") == nil)
J.done("jn03")
