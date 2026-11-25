-- Jagd 1.7.0 Fund JU-03: nach "Bezahlt" liegt an derselben Stelle "Wieder oeffnen". Ein Doppelklick auf "Bezahlt"
-- nimmt das Kopfgeld bei allen zurueck (seit 1.7.0, nicht umkehrbar) und oeffnet den Anspruch gleich wieder: der
-- Auslober liest "eingeloest ... zurueckgenommen", der Anspruch steht auf "offen", der Schuetze bekam "bezahlt" in
-- den Chat und steht still wieder auf "offen". In 1.6.4 war derselbe Doppelklick folgenlos.
-- Erwartet: zwei schnelle Klicks auf dieselbe Stelle lassen den Anspruch bezahlt. Alle Namen sind erfunden.
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_fx170.lua")
local check = J.check
local W = J.welt("deDE")
local a = J.client(W, "Anton", "Wurst", J.GILDE)
local b = J.client(W, "Berta", "Senf", J.GILDE, { ui = true })
a.login(); b.login(); W.lauf(90)
local L, F = b.ns.L, b.ns.F
b.ns.Guild.SetBounty(J.KEY, 50); W.lauf(10)
J.toetet(a); W.lauf(5); W.ruhe()
b.ns.FeudUI.ShowClaims(); W.lauf(0.3); W.ruhe()
local S = b.sheet()
check("Vorbedingung: Knopf Bezahlt", S and S.fdA:IsShown() and S.fdA.text._text == L.ACT_PAID, S and S.fdA.text._text)
a.chat, b.chat = {}, {}
b.click(S.fdA); b.click(S.fdA)
W.lauf(5)
local c = J.claims(b)[1] or {}
local x = J.earned(a)[1] or {}
check("Vorbedingung: das Kopfgeld ist zurueckgenommen", b.ns.Guild.HasBounty(J.KEY) ~= true)
check("Vorbedingung: Chat des Auslobers sagt eingeloest", b.chatHas(F(L.CHAT_CLAIM_SETTLED, { target = "Taeter Lamm",
  gold = b.ns.UI.Kit.GF.Gold(50), name = "Anton" })), b.chat[1])
check("nach dem Doppelklick ist der Anspruch bezahlt (nicht wieder offen bei zurueckgenommenem Kopfgeld)", c.state == "paid", c.state)
check("der Schuetze steht auf bezahlt", x.state == "paid", x.state)
J.done()
