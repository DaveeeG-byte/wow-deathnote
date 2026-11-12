-- Field 2: the new identity check via the GUID in the hello (WHISPER).
-- (1) Whoever knows the friend's GUID and carries her first name does not only bind (known limit), he
--     also DELETES everything the real friend brought; her older deeds never come back.
-- (2) If the sender arrives without a surname, the GUID is not checked at all: a hello with a WRONG GUID
--     and everything after it is accepted.
-- (3) Friend listed without surname, the list gives a GUID, and she is also a guildmate: her calls
--     "friends only" (sent by whisper) are never accepted, because guildmates do not whisper a hello.
-- (4) The list gives a GUID, the friend sends a hello without GUID (UnitGUID unreadable, interim build):
--     locked out for good and without any hint.
local H = dofile((arg[0]:match("^(.*)/") or ".") .. "/_kopf.lua")
local M = H.M
local G = "Die Testgilde"

H.lauf("(1) Angreifer mit der GUID der Freundin loescht ihre Daten", function()
  local W = H.welt({ "GUILD_ENEMY_SPOTTED", "HUNT_NEW", "GUILD_UPDATED" })
  W.guids = true
  local a = W.client("Anton", "Wurst", nil, { friends = { "Berta" } })
  local b = W.client("Berta", "Senf", nil, { friends = { "Anton Wurst" }, fullSender = true })
  a.login(); b.login(); W.run(90)
  local key = H.tod(b, "Taeter", "Lamm"); W.run(10)
  b.ns.Guild.Release("Ziel-Lamm", { to = "friends", why = "Grund" }); W.run(10)
  local tie = a.env.DeathNoteDB.friends.ties["Berta"]
  H.erwartet("Vorbedingung: Freundin sicher gebunden", tie and tie.sure == true and tie.full == "Berta Senf")
  H.erwartet("Vorbedingung: Tat und Freigabe der Freundin im Freundesbuch",
    a.ns.Guild.Get(key, "friends") ~= nil and a.ns.Guild.Hunt("Ziel-Lamm", "friends") ~= nil)
  -- one week later (so the deed is older than the three-day look-back)
  H.tage(7)
  local a2 = H.relog(W, a); local b2 = H.relog(W, b)
  a2.login(); b2.login(); W.run(90)
  H.erwartet("Vorbedingung: nach einer Woche alles noch da",
    a2.ns.Guild.Get(key, "friends") ~= nil and a2.ns.Guild.Hunt("Ziel-Lamm", "friends") ~= nil)
  local P = a2.ns.Guild.Proto
  -- the attacker: same first name, other surname, sends the friend's GUID along
  H.fluestern(a2, P.EncodeHello(0, "1.2.0", W.guidOf(b2)), "Berta Fremd-Forever")
  H.erwartet("ein Hallo mit der GUID der Freundin loescht nicht, was die Freundin gebracht hat (Tat)",
    a2.ns.Guild.Get(key, "friends") ~= nil, "Tat der Freundin geloescht")
  H.erwartet("... und nicht ihre Freigabe", a2.ns.Guild.Hunt("Ziel-Lamm", "friends") ~= nil, "Freigabe geloescht")
  -- the real friend returns (her next hello): does her old deed come back?
  b2.ns.Friends.SyncNow(); W.run(90)
  a2.ns.Friends.SyncNow(); W.run(120)
  local t2 = a2.env.DeathNoteDB.friends.ties["Berta"]
  H.erwartet("Gegenprobe: die echte Freundin bindet sich mit ihrem naechsten Hallo zurueck", t2 and t2.full == "Berta Senf")
  H.erwartet("nach dem Zurueckbinden ist die alte Tat der Freundin wieder da", a2.ns.Guild.Get(key, "friends") ~= nil,
    "bleibt weg (Rueckschau nur bis zum letzten Logout)")
end)

H.lauf("(2) Absender ohne Nachnamen: falsche GUID im Hallo wird nicht geprueft", function()
  local W = H.welt()
  W.guids = true
  local a = W.client("Anton", "Wurst", nil, { friends = { "Berta" } })
  local b = W.client("Berta", "Senf", nil, { friends = { "Anton Wurst" }, fullSender = true })
  a.login(); b.login(); W.run(90)
  local P = a.ns.Guild.Proto
  local tie = a.env.DeathNoteDB.friends.ties["Berta"]
  H.erwartet("Vorbedingung: Freundin sicher ueber GUID gebunden", tie and tie.sure == true and tie.guid == W.guidOf(b))
  local st0 = a.ns.Friends.stats.received
  -- a sender the client names by first name only, with a GUID that is NOT the one of the list entry
  H.fluestern(a, P.EncodeHello(0, "1.2.0", "Player-1-DEADBEEF"), "Berta-Forever")
  H.erwartet("ein Hallo mit falscher GUID wird nicht angenommen (auch ohne Nachnamen im Absender)",
    a.ns.Friends.stats.received == st0, "angenommen, GUID nicht geprueft")
  H.fluestern(a, H.J(P, "Falsch-Lamm", "Berta Senf"), "Berta-Forever")
  H.erwartet("und danach keine Freigabe unter dem Namen der Freundin", a.ns.Guild.Hunt("Falsch-Lamm", "friends") == nil,
    "Freigabe im Namen der Freundin angenommen")
end)

local function nurFreunde(guids, bListet, aListet)
  local W = H.welt()
  W.guids = guids
  local a = W.client("Anton", "Wurst", G, { friends = { aListet }, fullSender = true })
  local b = W.client("Berta", "Senf", G, { friends = { bListet }, fullSender = true })
  a.login(); b.login(); W.run(120)
  b.ns.Guild.Release("Nurfreunde-Lamm", { to = "friends", why = "Grund" }); W.run(30)
  local gesendet = 0
  for _, m in ipairs(W.sent) do
    if m.channel == "WHISPER" and m.sender == b and m.text:find("^1\tJ\t") then gesendet = gesendet + 1 end
  end
  return a.ns.Guild.Hunt("Nurfreunde-Lamm", "friends") ~= nil, gesendet, a.ns.Friends.stats.lastReason
end

H.lauf("(3) Freund ist auch Kollege: Freigabe nur fuer Freunde", function()
  local an, ges = nurFreunde(false, "Anton Wurst", "Berta Senf")
  H.erwartet("Gegenprobe: beide mit vollem Namen auf der Liste: kommt an", an, ges)
  an, ges = nurFreunde(false, "Anton Wurst", "Berta")
  H.erwartet("Gegenprobe: Empfaenger listet ohne Nachnamen, Liste ohne GUID: kommt an", an, ges)
  -- (3a) the sharer lists the friend without surname: no whisper goes out at all
  an, ges = nurFreunde(false, "Anton", "Berta Senf")
  H.erwartet("(3a) Freigebender listet den Kollegen-Freund ohne Nachnamen: Freigabe nur fuer Freunde kommt an", an,
    "gefluesterte J: " .. ges)
  -- (3b) the receiver lists without surname and his list gives GUIDs: dropped as 'identity'
  local why
  an, ges, why = nurFreunde(true, "Anton Wurst", "Berta")
  H.erwartet("(3b) Empfaenger listet ohne Nachnamen, Liste nennt GUID: kommt an", an,
    "gefluesterte J: " .. ges .. ", verworfen als " .. tostring(why))
end)

H.lauf("(4) Liste nennt GUID, Hallo der Freundin ohne GUID: still draussen", function()
  local W = H.welt()
  W.guids = true
  local a = W.client("Anton", "Wurst", nil, { friends = { "Berta" } })
  local b = W.client("Berta", "Senf", nil, { friends = { "Anton Wurst" }, fullSender = true })   -- only for the GUID on the list
  a.login(); W.run(40)
  local P = a.ns.Guild.Proto
  H.erwartet("Vorbedingung: die Liste nennt eine GUID", a.ns.Friends.FriendOf("Berta").guid ~= nil)
  M.chat = {}
  H.fluestern(a, P.EncodeHello(0, "1.2.0"), "Berta Senf-Forever")
  H.fluestern(a, H.J(P, "Echt-Lamm", "Berta Senf"), "Berta Senf-Forever")
  local h = a.ns.Friends.Health()
  H.erwartet("die Freundin ohne lesbare GUID kommt herein ODER der Spieler erfaehrt davon (Statuszeile, Chat)",
    a.ns.Guild.Hunt("Echt-Lamm", "friends") ~= nil or h.reason == "conflict" or h.reason == "impostor" or #M.chat > 0,
    "verworfen, Stand: " .. tostring(h.reason) .. ", Chatzeilen: " .. #M.chat)
end)

H.fertig()
