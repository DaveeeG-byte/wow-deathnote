-- 1.2.1: a provisionally bound stranger, the friend list later gives the real friend's GUID.
-- Usage: luajit beleg_b05_ausweis_guid_spaeter.lua <project copy>
-- Expected (1.2.1 fix after the hunt: nothing is deleted on suspicion): the binding stays with its data until
-- a hello decides; the bound one no longer gets new data in without proof. Once the real friend proves herself with her
-- hello, the stranger's binding and data go (deeds, calls, bounty), the name appears once in the status line.
local H = dofile((arg[0]:match("^(.*)/") or ".") .. "/_kopf.lua")
local M = H.M

-- (World: a whisper to "Berta" reaches the first Berta in the world; so first only the namesake is there,
-- then he goes offline and the real Berta comes; the list then gives her GUID)
H.lauf("(1) Fremder zuerst, GUID kommt spaeter", function()
  local W = H.welt()
  local x = W.client("Berta", "Fremd", nil, { friends = { "Anton Wurst" }, fullSender = true })  -- the namesake
  local a = W.client("Anton", "Wurst", nil, { friends = { "Berta" } })
  a.login(); x.login(); W.run(120)
  local kx = H.tod(x, "Fremd", "Taeter"); W.run(10)
  x.ns.Guild.Release("Ziel-Fremd", { to = "friends", why = "x" }); W.run(10)
  x.ns.Guild.SetBounty("Ziel-Fremd", 999); W.run(10)
  local tie = a.env.DeathNoteDB.friends.ties["Berta"]
  H.erwartet("Vorbedingung: Fremder vorlaeufig gebunden, seine Daten im Freundesbuch", tie and tie.full == "Berta Fremd"
    and not tie.guid and a.ns.Guild.Get(kx, "friends") ~= nil and a.ns.Guild.Hunt("Ziel-Fremd", "friends") ~= nil
    and a.ns.Guild.HasBounty("Ziel-Fremd"))
  -- the list now gives the GUID (the namesake leaves, the real Berta comes online, the list rereads)
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
  -- the real Berta's hello (with the list's GUID) decides
  W.run(60)
  tie = a.env.DeathNoteDB.friends.ties["Berta"]
  H.erwartet("Bindung geloest", tie and tie.full ~= "Berta Fremd", tie and tie.full)
  H.erwartet("Daten des Fremden weg (Tat, Freigabe, Kopfgeld)", a.ns.Guild.Get(kx, "friends") == nil
    and a.ns.Guild.Hunt("Ziel-Fremd", "friends") == nil and not a.ns.Guild.HasBounty("Ziel-Fremd"))
  local imp = a.ns.Friends.stats.impostor
  H.erwartet("einmal in der Statuszeile genannt", imp and imp.name == "Berta Fremd" and a.ns.Friends.Health().reason == "impostor",
    imp and imp.name)
  -- the stranger keeps writing: nothing comes in
  H.fluestern(a, P.EncodeHello(0, "1.2.1"), "Berta Fremd-Forever")
  H.fluestern(a, H.J(P, "Ziel-Zwei", "Berta Fremd"), "Berta Fremd-Forever")
  H.erwartet("der Fremde kommt nicht wieder herein", a.ns.Guild.Hunt("Ziel-Zwei", "friends") == nil)
  -- the real friend: her hello with GUID binds her, her data come in
  local kb = H.tod(b, "Echt", "Taeter"); W.run(60)
  tie = a.env.DeathNoteDB.friends.ties["Berta"]
  H.erwartet("echte Freundin sicher gebunden", tie and tie.full == "Berta Senf" and tie.sure == true and tie.guid ~= nil,
    tie and tostring(tie.full))
  H.erwartet("ihre Tat kommt an", a.ns.Guild.Get(kb, "friends") ~= nil)
end)

-- (2) since fix2: no hello overrides a choice made by hand (the GUID in the hello can be read off the target).
-- The hello with the list's GUID under another name makes a conflict, both data sets stay, the player
-- decides; afterwards the chosen one's hello binds via the GUID.
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
  -- the player chooses the real one: the first choice's data go, her hello from just now proves her
  a.ns.Friends.Choose("Berta", "Berta Senf"); W.run(90)
  H.erwartet("nach der neuen Wahl: Freigabe des Fremden weg", a.ns.Guild.Hunt("Ziel-Fremd", "friends") == nil)
  tie = a.env.DeathNoteDB.friends.ties["Berta"]
  H.erwartet("die echte ist jetzt ueber die GUID gebunden", tie and tie.full == "Berta Senf" and tie.guid ~= nil)
  -- another list run changes nothing about a proven binding
  a.fire("FRIENDLIST_UPDATE"); W.run(3)
  tie = a.env.DeathNoteDB.friends.ties["Berta"]
  H.erwartet("bewiesene Bindung bleibt", tie and tie.full == "Berta Senf" and tie.guid ~= nil)
  H.erwartet("keine Fehler", #M.errors == 0, M.errors[1])
end)

H.lauf("(3) Kollege mit dem Vornamen eines Freunds: die GUID des Gildenverzeichnisses muss passen", function()
  local W = H.welt()
  W.guids = true
  local G = "Die Testgilde"
  local d = W.client("Dora", "Dick", nil, { friends = { "Anton Wurst" }, fullSender = true })    -- the friend (not in the guild)
  local a = W.client("Anton", "Wurst", G, { friends = { "Dora" }, fullSender = true })
  local x = W.client("Dora", "Fremd", G, { fullSender = true })                                 -- guildmate with the same first name
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
