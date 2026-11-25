-- Fixer 1.7.0 round 2: copy of the hunt test jn04, plus the empty page.
-- jn04 (Nachjagd 1.7.0, Fixer-Diff JU-02): nach "Aus der Liste nehmen" des letzten Eintrags "Dir steht zu" steht die
-- Auswahl auf FD.NO_SHEET (leeres Blatt). Niemand setzt sie zurueck: weder das Schliessen und Oeffnen des Buchs noch
-- der Klick auf den Zettel "Kopfgeld faellig" eines NEUEN Anspruchs (FD.ShowClaims ohne Eintrag) noch der Reiter.
-- Der Spieler klickt den Zettel und sieht ein leeres Blatt statt des Anspruchs mit "Bezahlt" / "Ablehnen".
-- (FD.SetOpenView raeumt die Auswahl nur beim Wechsel in eine ANDERE Ansicht.)
-- Erwartet: der Klick auf den Zettel eines neuen Anspruchs zeigt ein Blatt mit Knoepfen. Alle Namen sind erfunden.
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_fx170.lua")
local check = J.check
local X = J.cu()
local W = X.world("deDE")
X.fake(W)
local ns, L = W.ns, W.L
W.kill("Grimm", "Bart")
local x = W.earn({ key = "Kalt-Herz", name = "Kalt Herz", owner = "Anna Wurst", char = "Ich Selbst", t = _G.time() - 3600, g = 50,
  via = "guild", state = "gone" }, true)
W.open(); W.tab("open")
ns.FeudUI.ShowClaims(x); W.tick(1)
local rm = W.find(L.ACT_EARNED_REMOVE)
check("Vorbedingung: Knopf 'Aus der Liste nehmen'", rm ~= nil)
W.click(rm); W.tick(1)
check("Vorbedingung: Eintrag weg, leeres Blatt", #W.earned == 0 and ns.UI.Kit.state.osel == ns.FeudUI.NO_SHEET)
-- fixer 2: the right page is the view's empty page "Nothing picked", no sheet
local _, _, RP = ns.UI.Kit.Frames()
check("leere Seite der Ansicht, kein Blatt", RP.empty:IsShown() and not ns.FeudUI.Sheet():IsVisible(), RP.empty.big._text)
-- das Buch zu, eine Stunde spaeter kommt ein Anspruch auf ein eigenes Kopfgeld
ns:Fire("TOGGLE_UI"); W.tick(3600); W.settle()
local c = ns.Feud.AddClaim("Rabe-Schwarz", "Rabe Schwarz", "Egon Wurst", _G.time() - 5, 70, "Ich Selbst", _G.time() - 900)
check("Vorbedingung: neuer Anspruch", c ~= nil and c.state == "open")
W.tick(2)
-- Klick auf den Zettel "Kopfgeld faellig" (sein open ist FD.ShowClaims ohne Argument)
ns.FeudUI.ShowClaims(); W.tick(1); W.settle()
local paid = W.find(L.ACT_PAID)
local S = ns.FeudUI.Sheet()
check("nach dem Klick auf den Zettel: Blatt des Anspruchs mit 'Bezahlt'", paid ~= nil,
  "leeres Blatt: big='" .. tostring(S and S.big._text) .. "', Auswahl haengt auf NO_SHEET")
-- auch Buch zu und wieder auf hilft nicht
ns:Fire("TOGGLE_UI"); W.tick(1); ns:Fire("TOGGLE_UI"); W.tick(1); W.settle()
check("nach Schliessen und Oeffnen: Blatt mit 'Bezahlt'", W.find(L.ACT_PAID) ~= nil, "weiter leer")
-- with a claim of mine still listed: the empty page "Nothing picked" of Claims, not the claim with "Paid"
do
  local W2 = X.world("deDE")
  X.fake(W2)
  local ns2, L2 = W2.ns, W2.L
  ns2.Feud.AddClaim("Rabe-Schwarz", "Rabe Schwarz", "Dirk Wurst", _G.time() - 5, 70, "Ich Selbst", _G.time() - 900)
  local y = W2.earn({ key = "Kalt-Herz", name = "Kalt Herz", owner = "Anna Wurst", char = "Ich Selbst", t = _G.time() - 3600,
    g = 50, via = "guild", state = "gone" }, true)
  W2.open(); W2.tab("open"); W2.tick(1)
  ns2.FeudUI.ShowClaims(y); W2.tick(1)
  W2.click(W2.find(L2.ACT_EARNED_REMOVE)); W2.tick(1)
  local _, _, RP2 = ns2.UI.Kit.Frames()
  check("mit eigenem Anspruch: Seite 'Nichts gewaehlt'", RP2.empty:IsShown() and RP2.empty.big._text == L2.EMPTY_FPICK_HEAD
    and W2.find(L2.ACT_PAID) == nil, RP2.empty.big._text)
end
J.done()
