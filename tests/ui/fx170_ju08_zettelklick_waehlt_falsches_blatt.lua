-- Jagd 1.7.0 Fund JU-08: der Klick auf den Zettel "Kopfgeld verdient" oeffnet Zu klaeren > Ansprueche, waehlt aber
-- nicht den Eintrag, um den es geht. Schulde ich selbst etwas, zeigt die rechte Seite das Blatt des ersten
-- Anspruchs unter "Du schuldest" ("70g an Carl", Knopf "Bezahlt"), nicht "50g von Berta". Wer vom Zettel kommt,
-- liest das Gegenteil dessen, was der Zettel sagte, und hat "Bezahlt" unter der Maus.
-- Erwartet: das Blatt des verdienten Kopfgelds. Alle Namen sind erfunden.
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_fx170.lua")
local check = J.check
local W = J.welt("deDE")
local a = J.client(W, "Anton", "Wurst", J.GILDE, { ui = true })
local b = J.client(W, "Berta", "Senf", J.GILDE)
local c = J.client(W, "Carl", "Kraut", J.GILDE)
a.login(); b.login(); c.login(); W.lauf(90)
local L, F = a.ns.L, a.ns.F
a.ns.Guild.SetBounty(J.KEY2, 70)
b.ns.Guild.SetBounty(J.KEY, 50)
W.lauf(10)
J.toetet(c, J.GUID2); W.lauf(30); W.ruhe()
a.slips = {}
J.toetet(a, J.GUID); W.lauf(3)
local s
for _, y in ipairs(a.slips) do if y.kicker == L.BANNER_EARNED then s = y end end
check("Vorbedingung: Zettel Kopfgeld verdient", s ~= nil and s.open ~= nil)
if s and s.open then s.open(); W.lauf(0.3); W.ruhe() end
local S = a.sheet()
local Gd = a.ns.UI.Kit.GF.Gold
check("das Blatt zeigt das verdiente Kopfgeld (50g von Berta)", S and S.big._text == F(L.EARNED_HEAD, { gold = Gd(50), name = "Berta" }),
  S and (tostring(S.head._text) .. ": " .. tostring(S.big._text) .. ", Knopf " .. tostring(S.fdA:IsShown() and S.fdA.text._text)))
J.done()
