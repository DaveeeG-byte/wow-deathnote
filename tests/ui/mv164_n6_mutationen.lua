-- 1.6.4 move, follow-up hunt N6: checks for the mutations that survived the tests of the first fix round (M10, M25,
-- M12, M13, M15, M24, M28; M05 is in mv164_n1_opfer, M11 in mv164_jn03, M17 and M18 in mv164_n3_ohne_leiste) and
-- for N5 (the line after an end by itself, none after the player's own tests). Names are made up.
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_mv164.lua")
local check = J.check
local function db(extra)
  local st = { welcomed = true, firstRun = "done", news164 = true, news160 = true, news150 = true, news140 = true, lang = "deDE" }
  for k, v in pairs(extra or {}) do st[k] = v end
  return { version = 5, settings = st, enemies = {}, deaths = {} }
end
local CALL = { by = "Liora", zone = "Ashenvale", same = true, display = "Grimwald Ashbrand", mapID = 1440, x = 1, y = 1 }

-- M10, M25: with Humor on the sample shows the remark's strip faintly; after the mode it is hidden at full alpha again
do
  local W = J.world("deDE", { db = db({ humor = true }) })
  W.slash("move")
  local q = W.frame("DeathNoteBanner").dnQuip
  check("M10: Streifen im Modus sichtbar und blass", q and q:IsShown() and q:GetAlpha() < 1)
  W.slash("move")
  check("M10: Streifen nach dem Modus versteckt", q and not q:IsShown())
  check("M25: Streifen nach dem Modus wieder voll deckend", q and q:GetAlpha() == 1, q and q:GetAlpha())
end

-- M12: the bar never takes a free place off the screen (alarm dragged onto the bar near the bottom edge: the place
-- below would be off the screen)
do
  local W = J.world("deDE", { db = db(), ui = 2560 / 1366 })
  W.slash("move")
  local bar = W.frame("DeathNoteMove")
  local bl, bb = W.rect(bar)
  W.dragTo(W.frame("DeathNoteAlert"), bl, bb - 20)
  local l, b, r, t = W.rect(bar)
  local H, Wd = W.G.UIParent:GetHeight(), W.G.UIParent:GetWidth()
  check("M12: Leiste ganz auf dem Schirm", l >= 0 and b >= 0 and r <= Wd and t <= H, ("%.0f %.0f %.0f %.0f"):format(l, b, r, t))
  W.slash("move")
end

-- M13 and N5: one line MOVE_ENDED for each end by itself; none after the player's own test alarm or test grudge notice
local ENDS = {
  { "Ladebildschirm", function(W) W.AM.FireEvent("PLAYER_ENTERING_WORLD", false, false) end },
  { "Tod", function(W) W.AM.FireEvent("PLAYER_DEAD") end },
  { "Meldung", function(W) W.ns.Extras.Notice("RANG", "Grimwald", "Zeile") end },
  { "Hilferuf", function(W) W.ns.CallUI.Show(CALL) end },
  { "Kampf", function(W) W.combat(true) end },
  { "Alarm", function(W) local k = W.ns.Store.AddManual("Borin Ashfall"); W.ns.Alert.Spotted(k, nil, "x") end },
}
for _, e in ipairs(ENDS) do
  local W = J.world("deDE", { db = db() })
  W.slash("move")
  e[2](W); W.tick(0.6)
  check("M13 " .. e[1] .. ": Modus aus, genau eine Zeile MOVE_ENDED", not W.ns.Place.Active() and W.said(W.ns.L.MOVE_ENDED) == 1, W.said(W.ns.L.MOVE_ENDED))
  W.combat(false)
end
do
  local W = J.world("deDE", { db = db() })
  W.slash("move")
  W.ns.Grudge.Test(); W.tick(0.6)
  check("M13 Rachsucht (Probe): Modus aus, keine Zeile MOVE_ENDED", not W.ns.Place.Active() and W.said(W.ns.L.MOVE_ENDED) == 0)
  W.ns.Grudge.Close("click"); W.tick(0.1)
  W.slash("move")
  W.slash("test")
  check("N5 /dn test im Modus: Modus aus, keine Zeile MOVE_ENDED, die Zeile zum Verschieben", not W.ns.Place.Active()
    and W.said(W.ns.L.MOVE_ENDED) == 0 and W.said("/dn ") >= 1)
end

-- M15: the window "Show" with a kept place off the screen opens at its default place
do
  local D = J.world("deDE", { db = db() })
  local k = D.ns.Store.AddManual("Velka Thornheart")
  D.ns.ShareUI.Open({ item = D.ns.Store.Get(k), kind = "own" }); D.tick(0.1)
  local def = { D.rect(D.frame("DeathNoteShare")) }
  local W = J.world("deDE", { db = db({ share = { point = { "BOTTOMLEFT", "BOTTOMLEFT", 9000, 9000 } } }) })
  local k2 = W.ns.Store.AddManual("Velka Thornheart")
  W.ns.ShareUI.Open({ item = W.ns.Store.Get(k2), kind = "own" }); W.tick(0.1)
  local l, b = W.rect(W.frame("DeathNoteShare"))
  check("M15: Lage ausserhalb des Schirms -> Standardlage", math.abs(l - def[1]) < 0.5 and math.abs(b - def[2]) < 0.5, ("%.0f/%.0f"):format(l, b))
end

-- M24: a kept notice, then the kept place removed from the data directly: the next notice stands at the default place
do
  local W = J.world("deDE", { db = db() })
  W.ns.Extras.Notice("RANG", "Grimwald", "Zeile"); W.tick(0.1)
  local b = W.frame("DeathNoteBanner")
  local def = { W.rect(b) }
  W.settle(); W.settle()
  W.ns.Store.Setting("notice.point", { "BOTTOMLEFT", "BOTTOMLEFT", 300, 300 })
  W.ns.Extras.Notice("RANG", "Borin", "Zeile"); W.tick(0.1)
  local l1 = W.rect(b)
  W.settle(); W.settle()
  W.ns.Store.Setting("notice.point", nil)
  W.ns.Extras.Notice("RANG", "Torvik", "Zeile"); W.tick(0.1)
  local l2, b2 = W.rect(b)
  check("M24: Voraussetzung gehalten bei 300", math.abs(l1 - 300) < 0.5)
  check("M24: danach wieder auf der Standardlage", math.abs(l2 - def[1]) < 0.5 and math.abs(b2 - def[2]) < 0.5, ("%.0f/%.0f"):format(l2, b2))
end

-- M28: Humor off, the notice dragged to the right edge: the stamp (16 over the right edge) stays on the screen
do
  local W = J.world("deDE", { db = db({ humor = false }) })
  local key = W.ns.Store.AddManual("Velka Thornheart")
  local UW = W.G.UIParent:GetWidth()
  W.slash("move"); W.dragTo(W.frame("DeathNoteBanner"), UW - 352, 400); W.slash("move")
  W.ns:Fire("REVENGE", key); W.tick(0.3)
  local b = W.frame("DeathNoteBanner")
  local _, _, r = W.rect(b.stamp)
  check("M28: Voraussetzung Stempel steht", b:IsShown() and b.stamp:IsShown())
  check("M28: Stempel rechts auf dem Schirm", r <= UW + 0.5, ("%.0f > %.0f"):format(r, UW))
end

J.done("mv164_n6_mutationen")
