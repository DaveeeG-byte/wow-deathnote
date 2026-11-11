-- 1.2.1 nach der Jagd (H2, M1, M2): der Ausweis verwirft nie Daten auf Verdacht.
-- (1) echte Freundin, die Liste nennt ihre GUID erst spaeter: ihr Hallo trug sie schon, die Bindung ist damit bewiesen,
--     nichts geht, sie wird nicht als Fremde genannt.
-- (2) Fremder gebunden, sein Hallo trug eine andere GUID: bleibt mit seinen Daten, bis das Hallo der echten Freundin
--     entscheidet; dann gehen seine Daten, er wird einmal genannt.
-- (3) M1: Battle.net-Freundin zuerst, Fremder per Char-Fluestern gebunden; spaeter steht sie mit Nachnamen und GUID
--     auf der Liste (dasselbe Battle.net-Konto): Bindung und Daten des Fremden gehen, auch nach Tagen nicht zurueck.
-- (4) M2: Kollegin und Freundin ohne Nachnamen auf der Liste: ohne brauchbare GUID im Gildenverzeichnis wird ihre
--     Freigabe "nur fuer Freunde" angenommen wie in 1.2.0; eine fremde GUID im Verzeichnis wird verworfen.
local H = dofile((arg[0]:match("^(.*)/") or ".") .. "/_kopf_c.lua")
local M = H.M
local G = "Die Testgilde"

H.lauf("(1) echte Freundin, GUID der Liste kommt spaeter", function()
  local W = H.welt()
  local b = W.client("Berta", "Senf", nil, { friends = { "Anton Wurst" }, fullSender = true })
  local a = W.client("Anton", "Wurst", nil, { friends = { "Berta" }, fullSender = true })
  local guids = false
  W.guids = true
  local gfi = a.env.C_FriendList.GetFriendInfoByIndex
  a.env.C_FriendList.GetFriendInfoByIndex = function(i) local f = gfi(i); if f and not guids then f.guid = nil end; return f end
  a.login(); b.login(); W.run(120)
  for i = 1, 40 do
    M.epoch = M.epoch + 3600
    H.tod(b, "Taeter" .. string.char(64 + math.ceil(i / 26)) .. string.char(96 + (i - 1) % 26 + 1), "Lamm"); W.run(5)
  end
  b.ns.Guild.Release("Ziel-Eins", { to = "friends", why = "x" }); W.run(10)
  b.ns.Guild.SetBounty("Ziel-Eins", 300); W.run(10)
  local tie = a.env.DeathNoteDB.friends.ties["Berta"]
  local vorher = a.ns.Guild.Count("friends")
  H.erwartet("Vorbedingung: vorlaeufig gebunden, ihr Hallo-GUID gemerkt, 40 Taeter", tie and tie.full == "Berta Senf"
    and not tie.guid and tie.hg ~= nil and vorher == 40, tostring(tie and tie.full) .. "/" .. tostring(vorher))
  local bdb = H.raus(W, b)
  guids = true
  W.client("Berta", "Senf", nil, { friends = { "Anton Wurst" }, fullSender = true, db = bdb })   -- (offline, nennt die GUID)
  a.fire("FRIENDLIST_UPDATE"); W.run(5)
  tie = a.env.DeathNoteDB.friends.ties["Berta"]
  local imp = a.ns.Friends.stats.impostor
  H.erwartet("Daten bleiben (40)", a.ns.Guild.Count("friends") == vorher, a.ns.Guild.Count("friends"))
  H.erwartet("Freigabe und Kopfgeld bleiben", a.ns.Guild.Hunt("Ziel-Eins", "friends") ~= nil and a.ns.Guild.HasBounty("Ziel-Eins"))
  H.erwartet("nicht als Fremde genannt", not (imp and imp.name == "Berta Senf"), imp and imp.name)
  H.erwartet("Bindung jetzt per GUID bewiesen", tie and tie.sure == true and tie.guid ~= nil)
end)

H.lauf("(2) Fremder mit eigener Hallo-GUID: bleibt bis zum Hallo der Echten, dann weg und genannt", function()
  local W = H.welt()
  W.guids = true
  local x = W.client("Berta", "Fremd", nil, { friends = { "Anton Wurst" }, fullSender = true })
  local a = W.client("Anton", "Wurst", nil, { friends = { "Berta" }, fullSender = true })
  -- die Liste nennt zuerst keine GUID (die echte Berta ist noch nicht da)
  local guids = false
  local gfi = a.env.C_FriendList.GetFriendInfoByIndex
  a.env.C_FriendList.GetFriendInfoByIndex = function(i) local f = gfi(i); if f and not guids then f.guid = nil end; return f end
  a.login(); x.login(); W.run(120)
  local kx = H.tod(x, "Fremd", "Taeter"); W.run(10)
  x.ns.Guild.Release("Ziel-Fremd", { to = "friends", why = "x" }); W.run(10)
  local tie = a.env.DeathNoteDB.friends.ties["Berta"]
  H.erwartet("Vorbedingung: Fremder gebunden mit seiner Hallo-GUID", tie and tie.full == "Berta Fremd" and tie.hg == W.guidOf(x))
  H.raus(W, x)
  local b = W.client("Berta", "Senf", nil, { friends = { "Anton Wurst" }, fullSender = true })
  guids = true
  a.fire("FRIENDLIST_UPDATE"); W.run(2)
  tie = a.env.DeathNoteDB.friends.ties["Berta"]
  H.erwartet("ohne Hallo der Echten: Bindung und Daten bleiben", tie.full == "Berta Fremd" and a.ns.Guild.Get(kx, "friends") ~= nil
    and a.ns.Guild.Hunt("Ziel-Fremd", "friends") ~= nil)
  b.login(); W.run(120)
  tie = a.env.DeathNoteDB.friends.ties["Berta"]
  local imp = a.ns.Friends.stats.impostor
  H.erwartet("nach ihrem Hallo: die Echte gebunden", tie.full == "Berta Senf" and tie.guid == W.guidOf(b), tie.full)
  H.erwartet("Daten des Fremden weg", a.ns.Guild.Get(kx, "friends") == nil and a.ns.Guild.Hunt("Ziel-Fremd", "friends") == nil)
  H.erwartet("der Fremde einmal genannt", imp and imp.name == "Berta Fremd", imp and imp.name)
end)

H.lauf("(3) M1: Battle.net-Freundin, Fremder per Char-Fluestern gebunden, spaeter Listeneintrag mit GUID", function()
  local W = H.welt()
  W.guids = true
  local d = W.client("Dora", "Dick", nil, { friends = {}, bn = { "Berta" }, fullSender = true })
  local b = W.client("Berta", "Senf", nil, { friends = {}, bn = { "Dora" }, fullSender = true })
  b.login(); d.login(); W.run(120)
  local P = b.ns.Guild.Proto
  H.fluestern(b, H.J(P, "Ziel-Fremd", "Dora Fremd"), "Dora Fremd-Forever")
  local tie = b.env.DeathNoteDB.friends.ties["Dora"]
  H.erwartet("Vorbedingung: Fremder ueber die Battle.net-Freundin gebunden", tie and tie.full == "Dora Fremd"
    and b.ns.Guild.Hunt("Ziel-Fremd", "friends") ~= nil)
  b.friendNames[#b.friendNames + 1] = "Dora Dick"
  d.friendNames[#d.friendNames + 1] = "Berta Senf"
  b.fire("FRIENDLIST_UPDATE"); d.fire("FRIENDLIST_UPDATE"); W.run(120)
  b.ns.Friends.SyncNow(); W.run(120)
  H.erwartet("Freigabe des Fremden weg", b.ns.Guild.Hunt("Ziel-Fremd", "friends") == nil)
  tie = b.env.DeathNoteDB.friends.ties["Dora"]
  H.erwartet("keine Bindung mehr an den Fremden", not (tie and tie.full == "Dora Fremd"), tie and tie.full)
  local imp = b.ns.Friends.stats.impostor
  H.erwartet("der Fremde einmal genannt", imp and imp.name == "Dora Fremd", imp and imp.name)
  for _ = 1, 3 do H.tage(1); b = H.relog(W, b); b.login(); W.run(400); b.fire("FRIENDLIST_UPDATE"); W.run(5) end
  H.erwartet("nach Tagen und Aufraeumen weiter weg", b.ns.Guild.Hunt("Ziel-Fremd", "friends") == nil)
  H.erwartet("Doras eigene Freigabe kommt an", (function() d.ns.Guild.Release("Ziel-Dora", { to = "friends", why = "x" }); W.run(30)
    return b.ns.Guild.Hunt("Ziel-Dora", "friends") ~= nil end)())
end)

H.lauf("(3b) M1 Gegenprobe: dieselbe Lage, aber ein anderes Battle.net-Konto: nichts wird geloescht", function()
  local W = H.welt()
  W.guids = true
  local d = W.client("Dora", "Dick", nil, { friends = {}, bn = { "Berta" }, fullSender = true })
  local b = W.client("Berta", "Senf", nil, { friends = {}, bn = { "Dora" }, fullSender = true })
  b.login(); d.login(); W.run(120)
  local P = b.ns.Guild.Proto
  H.fluestern(b, H.J(P, "Ziel-Fremd", "Dora Fremd"), "Dora Fremd-Forever")
  -- das Battle.net-Konto der Bindung ist ein anderes (Hash passt nicht zu dem der gelisteten Dora)
  b.env.DeathNoteDB.friends.ties["Dora"].bnTag = "00000000"
  b.friendNames[#b.friendNames + 1] = "Dora Dick"
  b.fire("FRIENDLIST_UPDATE"); W.run(5)
  H.erwartet("Freigabe bleibt (kein Beweis, dass es dieselbe Person ist)", b.ns.Guild.Hunt("Ziel-Fremd", "friends") ~= nil)
end)

for _, fall in ipairs({ "Verzeichnis nennt nur Vornamen", "Verzeichnis ohne GUID", "Verzeichnis mit passender GUID", "Verzeichnis mit fremder GUID" }) do
  H.lauf("(4) M2: Kollegen-Freundin ohne Nachnamen, " .. fall, function()
    local W = H.welt()
    W.guids = true
    local a = W.client("Anton", "Wurst", G, { friends = { "Dora" }, fullSender = true })
    local d = W.client("Dora", "Dick", G, { friends = { "Anton Wurst" }, fullSender = true })
    local gri = a.env.GetGuildRosterInfo
    a.env.GetGuildRosterInfo = function(i)
      local r = { gri(i) }
      if r[1] == nil then return nil end
      if fall:find("nur Vornamen") then r[1] = r[1]:gsub("^(%S+) [^%-]+", "%1") end
      if fall:find("ohne GUID") then r[17] = nil end
      if fall:find("fremder GUID") and tostring(r[1]):find("^Dora") then r[17] = "Player-1-0BADBADBAD" end
      return unpack(r, 1, 17)
    end
    a.login(); d.login(); W.run(120)
    d.ns.Guild.Release("Ziel-Eins", { to = "friends", why = "nur Freunde" }); W.run(30)
    local da = a.ns.Guild.Hunt("Ziel-Eins", "friends") ~= nil
    if fall:find("fremder") then
      H.erwartet("fremde GUID im Verzeichnis: verworfen", not da)
    else
      H.erwartet("Freigabe 'nur fuer Freunde' kommt an", da, "letzter Grund " .. tostring(a.ns.Friends.stats.lastReason))
    end
  end)
end
H.lauf("(5) Freundin ist Kollegin (sendet kein Freundes-Hallo): das Gildenverzeichnis mit ihrer GUID entscheidet", function()
  local W = H.welt()
  W.guids = true
  local x = W.client("Berta", "Fremd", nil, { friends = { "Anton Wurst" }, fullSender = true })
  local a = W.client("Anton", "Wurst", G, { friends = { "Berta" }, fullSender = true })
  local guids = false
  local gfi = a.env.C_FriendList.GetFriendInfoByIndex
  a.env.C_FriendList.GetFriendInfoByIndex = function(i) local f = gfi(i); if f and not guids then f.guid = nil end; return f end
  a.login(); x.login(); W.run(120)
  x.ns.Guild.Release("Ziel-Fremd", { to = "friends", why = "x" }); W.run(10)
  H.erwartet("Vorbedingung: Fremder gebunden, Freigabe da", a.env.DeathNoteDB.friends.ties["Berta"].full == "Berta Fremd"
    and a.ns.Guild.Hunt("Ziel-Fremd", "friends") ~= nil)
  H.raus(W, x)
  local b = W.client("Berta", "Senf", G, { friends = { "Anton Wurst" }, fullSender = true })
  b.login(); W.run(60)
  guids = true
  a.ns.Guild.ReadRoster(); a.fire("FRIENDLIST_UPDATE"); W.run(5)
  local tie = a.env.DeathNoteDB.friends.ties["Berta"]
  H.erwartet("die Kollegin ist ueber das Verzeichnis gebunden", tie.full == "Berta Senf" and tie.guid == W.guidOf(b), tie.full)
  H.erwartet("Freigabe des Fremden weg", a.ns.Guild.Hunt("Ziel-Fremd", "friends") == nil)
end)
H.fertig()
