-- 1.2.1: vorlaeufig gebundener Fremder, die Freundesliste nennt spaeter die GUID des echten Freunds.
-- Aufruf: luajit beleg_b05_ausweis_guid_spaeter.lua <Projektkopie>
-- Erwartet (1.2.1 fix nach der Jagd: nichts wird auf Verdacht geloescht): die Bindung bleibt mit ihren Daten, bis
-- ein Hallo entscheidet; Neues nimmt der Gebundene ohne Beweis nicht mehr an. Weist sich der echte Freund mit seinem
-- Hallo aus, gehen Bindung und Daten des Fremden (Taten, Freigaben, Kopfgeld), der Name steht einmal in der Statuszeile.
local H = dofile((arg[0]:match("^(.*)/") or ".") .. "/_kopf.lua")
local M = H.M

-- (Welt: ein Fluestern an "Berta" erreicht den ersten Berta der Welt; darum ist zuerst nur der Namensvetter da,
-- dann geht er offline und die echte Berta kommt; die Liste nennt dann ihre GUID)
H.lauf("(1) Fremder zuerst, GUID kommt spaeter", function()
  local W = H.welt()
  local x = W.client("Berta", "Fremd", nil, { friends = { "Anton Wurst" }, fullSender = true })  -- der Namensvetter
  local a = W.client("Anton", "Wurst", nil, { friends = { "Berta" } })
  a.login(); x.login(); W.run(120)
  local kx = H.tod(x, "Fremd", "Taeter"); W.run(10)
  x.ns.Guild.Release("Ziel-Fremd", { to = "friends", why = "x" }); W.run(10)
  x.ns.Guild.SetBounty("Ziel-Fremd", 999); W.run(10)
  local tie = a.env.DeathNoteDB.friends.ties["Berta"]
  H.erwartet("Vorbedingung: Fremder vorlaeufig gebunden, seine Daten im Freundesbuch", tie and tie.full == "Berta Fremd"
    and not tie.guid and a.ns.Guild.Get(kx, "friends") ~= nil and a.ns.Guild.Hunt("Ziel-Fremd", "friends") ~= nil
    and a.ns.Guild.HasBounty("Ziel-Fremd"))
  -- die Liste nennt jetzt die GUID (der Namensvetter geht, die echte Berta kommt online, die Liste liest neu)
  H.raus(W, x)
  local b = W.client("Berta", "Senf", nil, { friends = { "Anton Wurst" }, fullSender = true })
  W.guids = true
  b.login(); W.run(5)
  a.fire("FRIENDLIST_UPDATE"); W.run(3)
  tie = a.env.DeathNoteDB.friends.ties["Berta"]
  H.erwartet("ohne Hallo nichts auf Verdacht geloescht: Bindung und Daten bleiben", tie and tie.full == "Berta Fremd"
    and a.ns.Guild.Get(kx, "friends") ~= nil and a.ns.Guild.Hunt("Ziel-Fremd", "friends") ~= nil, tie and tie.full)
  local P = a.ns.Guild.Proto
  H.fluestern(a, H.J(P, "Ziel-Drei", "Berta Fremd"), "Berta Fremd-Forever")
  H.erwartet("ohne Beweis nimmt der Gebundene nichts Neues an", a.ns.Guild.Hunt("Ziel-Drei", "friends") == nil)
  -- das Hallo der echten Berta (mit der GUID der Liste) entscheidet
  W.run(60)
  tie = a.env.DeathNoteDB.friends.ties["Berta"]
  H.erwartet("Bindung geloest", tie and tie.full ~= "Berta Fremd", tie and tie.full)
  H.erwartet("Daten des Fremden weg (Tat, Freigabe, Kopfgeld)", a.ns.Guild.Get(kx, "friends") == nil
    and a.ns.Guild.Hunt("Ziel-Fremd", "friends") == nil and not a.ns.Guild.HasBounty("Ziel-Fremd"))
  local imp = a.ns.Friends.stats.impostor
  H.erwartet("einmal in der Statuszeile genannt", imp and imp.name == "Berta Fremd" and a.ns.Friends.Health().reason == "impostor",
    imp and imp.name)
  -- der Fremde schreibt weiter: nichts kommt herein
  H.fluestern(a, P.EncodeHello(0, "1.2.1"), "Berta Fremd-Forever")
  H.fluestern(a, H.J(P, "Ziel-Zwei", "Berta Fremd"), "Berta Fremd-Forever")
  H.erwartet("der Fremde kommt nicht wieder herein", a.ns.Guild.Hunt("Ziel-Zwei", "friends") == nil)
  -- die echte Freundin: ihr Hallo mit GUID bindet sie, ihre Daten kommen
  local kb = H.tod(b, "Echt", "Taeter"); W.run(60)
  tie = a.env.DeathNoteDB.friends.ties["Berta"]
  H.erwartet("echte Freundin sicher gebunden", tie and tie.full == "Berta Senf" and tie.sure == true and tie.guid ~= nil,
    tie and tostring(tie.full))
  H.erwartet("ihre Tat kommt an", a.ns.Guild.Get(kb, "friends") ~= nil)
end)

-- (2) seit fix2: eine Wahl von Hand wird von keinem Hallo ueberstimmt (die GUID im Hallo laesst sich am Ziel ablesen).
-- Das Hallo mit der GUID der Liste unter anderem Namen macht einen Konflikt, die Daten beider bleiben, der Spieler
-- entscheidet; danach bindet das Hallo der Gewaehlten ueber die GUID.
H.lauf("(2) Wahl von Hand vor der GUID: Hallo mit der GUID der Liste fragt den Spieler; eine bewiesene Bindung bleibt", function()
  local W = H.welt()
  local x = W.client("Berta", "Fremd", nil, { friends = { "Anton Wurst" }, fullSender = true })
  local a = W.client("Anton", "Wurst", nil, { friends = { "Berta" } })
  a.login(); x.login(); W.run(120)
  a.ns.Friends.Choose("Berta", "Berta Fremd")
  x.ns.Guild.Release("Ziel-Fremd", { to = "friends", why = "x" }); W.run(10)
  H.erwartet("Vorbedingung: gewaehlt, Freigabe da", a.env.DeathNoteDB.friends.ties["Berta"].sure == true
    and a.ns.Guild.Hunt("Ziel-Fremd", "friends") ~= nil)
  H.raus(W, x)
  local b = W.client("Berta", "Senf", nil, { friends = { "Anton Wurst" }, fullSender = true })
  W.guids = true
  b.login(); W.run(5); a.fire("FRIENDLIST_UPDATE"); W.run(90)
  local tie = a.env.DeathNoteDB.friends.ties["Berta"]
  H.erwartet("kein Hallo ueberstimmt die Wahl: Konflikt, Freigabe der Gewaehlten bleibt", tie and tie.full == "Berta Fremd"
    and tie.rival == "Berta Senf" and a.ns.Guild.Hunt("Ziel-Fremd", "friends") ~= nil, tie and tostring(tie.full) .. "/" .. tostring(tie.rival))
  a.fire("FRIENDLIST_UPDATE"); W.run(30)
  H.erwartet("auch das Aufraeumen nach dem naechsten Listen-Lauf laesst sie stehen", a.ns.Guild.Hunt("Ziel-Fremd", "friends") ~= nil)
  -- der Spieler waehlt die echte: die Daten der zuerst gewaehlten gehen, ihr Hallo von eben beweist sie
  a.ns.Friends.Choose("Berta", "Berta Senf"); W.run(90)
  H.erwartet("nach der neuen Wahl: Freigabe des Fremden weg", a.ns.Guild.Hunt("Ziel-Fremd", "friends") == nil)
  tie = a.env.DeathNoteDB.friends.ties["Berta"]
  H.erwartet("die echte ist jetzt ueber die GUID gebunden", tie and tie.full == "Berta Senf" and tie.guid ~= nil)
  -- ein weiterer Lauf der Liste aendert an einer bewiesenen Bindung nichts
  a.fire("FRIENDLIST_UPDATE"); W.run(3)
  tie = a.env.DeathNoteDB.friends.ties["Berta"]
  H.erwartet("bewiesene Bindung bleibt", tie and tie.full == "Berta Senf" and tie.guid ~= nil)
  H.erwartet("keine Fehler", #M.errors == 0, M.errors[1])
end)

H.lauf("(3) Kollege mit dem Vornamen eines Freunds: die GUID des Gildenverzeichnisses muss passen", function()
  local W = H.welt()
  W.guids = true
  local G = "Die Testgilde"
  local d = W.client("Dora", "Dick", nil, { friends = { "Anton Wurst" }, fullSender = true })    -- die Freundin (nicht in der Gilde)
  local a = W.client("Anton", "Wurst", G, { friends = { "Dora" }, fullSender = true })
  local x = W.client("Dora", "Fremd", G, { fullSender = true })                                 -- Kollegin gleichen Vornamens
  a.login(); x.login(); W.run(120)
  local P = a.ns.Guild.Proto
  H.erwartet("Vorbedingung: die Liste nennt Doras GUID, Dora Fremd ist Kollegin",
    a.ns.Friends.FriendOf("Dora").guid == W.guidOf(d) and a.ns.Guild.IsGuildmate("Dora Fremd"))
  H.fluestern(a, H.J(P, "Ziel-Kollegin", "Dora Fremd"), "Dora Fremd-Forever")
  H.erwartet("Freigabe 'nur fuer Freunde' der Namensvetterin: verworfen", a.ns.Guild.Hunt("Ziel-Kollegin", "friends") == nil)
  local imp = a.ns.Friends.stats.impostor
  H.erwartet("einmal genannt", imp and imp.name == "Dora Fremd", imp and imp.name)
  H.erwartet("keine Fehler", #M.errors == 0, M.errors[1])
end)

H.fertig()
