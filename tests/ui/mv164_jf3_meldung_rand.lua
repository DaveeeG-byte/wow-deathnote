-- Jagd 1.6.4, Jaeger A, Fund 3. Aufruf: luajit jf3_meldung_rand.lua <projekt>   (rot = Exit 1)
-- Erwartet: Eine Meldung, die der Spieler im Platzier-Modus an den Rand gezogen hat, zeigt im Ernstfall alles, was zu
-- ihr gehoert, auf dem Schirm: den Stempel (ragt 14 ueber die Oberkante und 16 ueber die rechte Kante) und den
-- Spruchstreifen (Humor an; haengt 24 unter der Meldung, 440 breit bei 352 der Meldung).
-- Auf 4f30098 rot: das Muster zeigt weder Stempel noch Streifen, SetClampedToScreen deckt nur den Rahmen selbst
-- (keine SetClampRectInsets), die echte Meldung steht danach mit Stempel bzw. Streifen ausserhalb des Schirms.
local WT = arg[1] or "."
local J = dofile(WT .. "/tests/ui/_mv164.lua")
local db = { version = 5, settings = { welcomed = true, firstRun = "done", news164 = true, news160 = true, news150 = true,
  news140 = true, lang = "deDE", humor = true }, enemies = {}, deaths = {} }
local W = J.world("deDE", { db = db })
local UW, UH = W.G.UIParent:GetWidth(), W.G.UIParent:GetHeight()
local key = W.ns.Store.AddManual("Velka Thornheart")
local b
local function place(l, bt)
  W.slash("move")
  b = W.frame("DeathNoteBanner")
  W.dragTo(b, l, bt)
  W.slash("move")
  W.ns:Fire("REVENGE", key); W.tick(0.3)
end
-- oben rechts: der Stempel der Rache-Meldung
place(UW - 352, UH - 64)
J.check("oben rechts: echte Meldung steht mit Stempel (Voraussetzung)", b:IsShown() and not b.sample and b.stamp:IsShown())
local l, bo, r, t = W.rect(b.stamp)
J.check("oben rechts: Stempel ganz auf dem Schirm", t <= UH + 0.5 and r <= UW + 0.5, ("Stempel %.0f..%.0f x %.0f..%.0f, Schirm %.0f x %.0f"):format(l, r, bo, t, UW, UH))
W.settle(); W.settle()
-- unten Mitte: der Spruchstreifen (wird gewuerfelt; gemessen wird der Platz, an dem er haengt)
place(UW / 2 - 176, 0)
J.check("unten: echte Meldung steht (Voraussetzung)", b:IsShown() and not b.sample)
J.check("unten: Humor an, Streifen gebaut (Voraussetzung)", W.ns.Humor.On() and b.dnQuip ~= nil)
if b.dnQuip then
  local ql, qb, qr, qt = W.rect(b.dnQuip)
  J.check("unten: Platz des Spruchstreifens auf dem Schirm", qb >= -0.5, ("Streifen unten %.0f, oben %.0f"):format(qb, qt))
end
W.settle(); W.settle()
-- links oben: der Streifen ist breiter als die Meldung
place(0, UH - 300)
if b.dnQuip then
  local ql = W.rect(b.dnQuip)
  J.check("links: Spruchstreifen nicht links abgeschnitten", ql >= -0.5, ("Streifen links %.0f"):format(ql))
end
J.done("jf3_meldung_rand")
