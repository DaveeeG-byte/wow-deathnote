-- Jagd 1.7.0 Fund JU-09: der Schuetze liest im Chat "Berta hat dein Kopfgeld ... als bezahlt abgehakt". Oeffnet der
-- Auslober den Anspruch danach wieder (er hat sich verklickt, oder es war doch nicht bezahlt) oder lehnt er erst ab
-- und oeffnet wieder, wechselt der Eintrag beim Schuetzen still: keine Chatzeile nimmt "bezahlt" bzw. "abgelehnt"
-- zurueck. Der Kommentar im Code nennt nur "unbestaetigt -> offen" als stillen Wechsel.
-- Erwartet: eine Zeile, wenn ein Endzustand zurueckgenommen wird. Alle Namen sind erfunden.
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_fx170.lua")
local check = J.check
local W = J.welt("deDE")
local a = J.client(W, "Anton", "Wurst", J.GILDE, { ui = true })
local b = J.client(W, "Berta", "Senf", J.GILDE)
a.login(); b.login(); W.lauf(90)
b.ns.Guild.SetBounty(J.KEY, 50); W.lauf(10)
J.toetet(a); W.lauf(5); W.ruhe()
local c = J.claims(b)[1]
b.ns.Feud.SetClaim(c, "declined"); W.lauf(70)
local x = J.earned(a)[1] or {}
check("Vorbedingung: Chat sagte abgelehnt", x.state == "declined" and a.chatHas("Berta"), x.state)
a.chat = {}
b.ns.Feud.SetClaim(c, "open"); W.lauf(70)
check("Vorbedingung: der Eintrag ist wieder offen", x.state == "open", x.state)
check("der Schuetze erfaehrt im Chat, dass 'abgelehnt' nicht mehr gilt", #a.chat >= 1, #a.chat .. " Zeilen")
J.done()
