-- Jagd 1.7.0 Fund JU-02: "Aus der Liste nehmen" springt mit der Auswahl auf die erste Zeile der Ansicht. Schulde ich
-- selbst etwas (offener Anspruch oben unter "Du schuldest"), liegt nach dem Klick an derselben Stelle der Knopf
-- "Bezahlt" eines ganz anderen Anspruchs. Ein zweiter Klick auf dieselbe Stelle (Doppelklick, oder der naechste
-- Eintrag soll auch weg) hakt diesen Anspruch als bezahlt ab, nimmt mein Kopfgeld bei allen zurueck und schickt dem
-- Schuetzen "bezahlt". Erwartet: der zweite Klick trifft keinen "Bezahlt"-Knopf. Alle Namen sind erfunden.
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_fx170.lua")
local check = J.check
local W = J.welt("deDE")
local a = J.client(W, "Anton", "Wurst", J.GILDE, { ui = true })
local b = J.client(W, "Berta", "Senf", J.GILDE)
local c = J.client(W, "Carl", "Kraut", J.GILDE)
a.login(); b.login(); c.login(); W.lauf(90)
local L = a.ns.L
-- Anton schuldet: sein Kopfgeld auf Rabe Schwarz, Carl erlegt ihn
check("Vorbedingung: Antons Kopfgeld", a.ns.Guild.SetBounty(J.KEY2, 70) == true)
-- Anton steht etwas zu: Bertas Kopfgeld auf Taeter Lamm, Anton erlegt ihn, Berta lehnt ab
check("Vorbedingung: Bertas Kopfgeld", b.ns.Guild.SetBounty(J.KEY, 50) == true)
W.lauf(10)
J.toetet(c, J.GUID2); W.lauf(5)
J.toetet(a, J.GUID); W.lauf(5)
local bc = J.claims(b)[1]
if bc then b.ns.Feud.SetClaim(bc, "declined") end
W.lauf(20); W.ruhe()
local mine = J.claims(a)[1] or {}
local x = J.earned(a)[1] or {}
check("Vorbedingung: Anton schuldet Carl (offen)", mine.state == "open" and mine.by == "Carl Kraut", mine.state)
check("Vorbedingung: Antons Eintrag abgelehnt", x.state == "declined", x.state)
-- Buch auf, Zu klaeren > Ansprueche, den verdienten Eintrag waehlen
a.ns.FeudUI.ShowClaims(); W.lauf(0.3); W.ruhe()
local row
for _, r in ipairs(a.rows()) do if r.item.fdItem == "earned" then row = r end end
check("Vorbedingung: Zeile des verdienten Eintrags", row ~= nil)
if row then row._scripts.OnClick(row, "LeftButton") end
W.lauf(0.2)
local S = a.sheet()
check("Vorbedingung: Knopf 'Aus der Liste nehmen'", S and S.fdA:IsShown() and S.fdA.text._text == L.ACT_EARNED_REMOVE, S and S.fdA.text._text)
a.chat = {}
a.click(S.fdA)        -- erster Klick: Eintrag weg
a.click(S.fdA)        -- zweiter Klick auf dieselbe Stelle
W.lauf(5)
check("erster Klick nahm den Eintrag heraus", #J.earned(a) == 0, #J.earned(a))
check("zweiter Klick hakt keinen fremden Anspruch als bezahlt ab", mine.state == "open", mine.state)
check("mein Kopfgeld auf Rabe Schwarz steht noch", a.ns.Guild.HasBounty(J.KEY2) == true)
check("Carl bekam kein 'bezahlt'", (J.earned(c)[1] or {}).state ~= "paid", (J.earned(c)[1] or {}).state)
J.done()
