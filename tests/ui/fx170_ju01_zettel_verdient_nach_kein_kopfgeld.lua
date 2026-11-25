-- Jagd 1.7.0 Fund JU-01: der Zettel "Kopfgeld verdient" erscheint, obwohl der Auslober schon geantwortet hat, dass
-- es kein Kopfgeld (mehr) gibt. Ein Kopfgeld, ein Anspruch: Carl erlegt das Ziel zuerst (Anspruch offen). Das
-- Kopfgeld bleibt bis "Bezahlt" bei allen sichtbar. Anton erlegt das Ziel danach: Chat "Kopfgeld verdient", gleich
-- darauf die Quittung "kein Kopfgeld" (Chatzeile), und eine Sekunde spaeter kommt trotzdem der Zettel
-- "Kopfgeld verdient: 50g von Berta". Erwartet: kein Zettel fuer einen Eintrag, der schon erledigt ist.
-- Alle Namen sind erfunden.
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_fx170.lua")
local check = J.check
local W = J.welt("deDE")
local a = J.client(W, "Anton", "Wurst", J.GILDE, { ui = true })
local b = J.client(W, "Berta", "Senf", J.GILDE)
local c = J.client(W, "Carl", "Kraut", J.GILDE)
a.login(); b.login(); c.login(); W.lauf(90)
local L, F = a.ns.L, a.ns.F
check("Vorbedingung: Kopfgeld", b.ns.Guild.SetBounty(J.KEY, 50) == true)
W.lauf(10)
J.toetet(c); W.lauf(120)
check("Vorbedingung: Carls Anspruch offen", #J.claims(b) == 1 and J.claims(b)[1].state == "open")
check("Vorbedingung: Anton sieht das Kopfgeld weiter", a.ns.Guild.HasBounty(J.KEY) == true)
a.chat = {}
J.toetet(a); W.lauf(0.6)
local x = J.earned(a)[1] or {}
-- since "one bounty, one paid claim" a later kill is a second open claim, no longer "no bounty" at once: the poster's
-- receipt "no bounty" within the slip's second is laid here by hand (the state and its event, as applyQ does)
check("Vorbedingung: Antons Eintrag steht (offen oder unbestaetigt)", x.state == "open" or x.state == "sent", x.state)
local old = x.state
x.state = "gone"
a.ns:Fire("EARNED_CHANGED", x, old)
local goneAt = a.chatIndex(F(L.CHAT_EARNED_GONE, { name = "Berta", target = "Taeter Lamm", gold = a.ns.UI.Kit.GF.Gold(50) }))
check("Vorbedingung: Chatzeile kein Kopfgeld steht schon", goneAt ~= nil, table.concat(a.chat, " // "))
W.lauf(2)
local late = 0
for _, s in ipairs(a.slips) do if s.kicker == L.BANNER_EARNED then late = late + 1 end end
check("kein Zettel 'Kopfgeld verdient' fuer einen Eintrag, der schon 'kein Kopfgeld' ist", late == 0,
  late .. " Zettel, Zeile: " .. tostring(a.slips[1] and a.slips[1].line and a.slips[1].line[2]))
J.done()
