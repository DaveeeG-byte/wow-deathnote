-- 1.2.1 after the hunt (M4, M5, N2, N3): bounties arrive reliably with the answer, also under the client's
-- throttle and when the own hello had to wait; Y acts only on a complete delivery; the bounty
-- of someone who left goes like his call; Y on GUILD also clears the copy in the friends' book; nobody sets a
-- bounty on the receiver himself.
local H = dofile((arg[0]:match("^(.*)/") or ".") .. "/_kopf_c.lua")
local M = H.M
local G = "Die Testgilde"
local function gbounty(c) return c.env.DeathNoteDB.guild.lists[G].bounty end
local function volles_buch(a)
  for i = 1, 30 do
    M.epoch = M.epoch + 600
    H.tod(a, "Moerder" .. string.char(64 + math.ceil(i / 26)) .. string.char(96 + (i - 1) % 26 + 1), "Lamm")
  end
  for i = 1, 20 do a.ns.Store.AddManual("Hand" .. string.char(96 + i), "Lamm") end
  for i = 1, 10 do a.ns.Guild.Release("Jagd" .. string.char(96 + i) .. "-Lamm", { to = "guild", why = "x" }) end
  local n = 0
  for i = 1, 20 do if a.ns.Guild.SetBounty("Gold" .. string.char(96 + i) .. "-Lamm", 100 + i) then n = n + 1 end end
  return n
end

for _, mitDrossel in ipairs({ false, true }) do
  H.lauf("(1) volles Buch, Antwort auf ein Hallo" .. (mitDrossel and " unter der Drossel (10 + 1/s)" or ""), function()
    local W = H.welt()
    local a = W.client("Anton", "Wurst", G, { fullSender = true })
    a.login(); W.run(60)
    H.erwartet("Vorbedingung: 20 eigene Kopfgelder", volles_buch(a) == 20)
    W.run(120)
    if mitDrossel then H.drossel(a) end
    local b = W.client("Berta", "Senf", G, { fullSender = true })
    b.login(); W.run(400)
    H.erwartet("alle 20 Kopfgelder kommen an", H.anzahl(gbounty(b)) == 20, H.anzahl(gbounty(b)))
    H.erwartet("alle 10 Freigaben kommen an", H.freigaben(b.env.DeathNoteDB.guild.lists[G].hunts) == 10)
    local bdb = H.raus(W, b)
    for i = 1, 20 do a.ns.Guild.SetBounty("Gold" .. string.char(96 + i) .. "-Lamm", 0) end
    W.run(120)
    b = W.client("Berta", "Senf", G, { fullSender = true, db = bdb })
    b.login(); W.run(400)
    H.erwartet("zurueckgenommene sind nach dem naechsten Login weg (Y)", H.anzahl(gbounty(b)) == 0, H.anzahl(gbounty(b)))
  end)
end

H.lauf("(2) Y wirkt nicht auf eine unvollstaendige Lieferung (ein B ging verloren)", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", G, { fullSender = true })
  local b = W.client("Berta", "Senf", G, { fullSender = true })
  a.login(); b.login(); W.run(120)
  for i = 1, 3 do a.ns.Guild.SetBounty("Gold" .. string.char(96 + i) .. "-Lamm", 50) end
  W.run(30)
  H.erwartet("Vorbedingung: 3 bei Berta", H.anzahl(gbounty(b)) == 3)
  -- Berta's next hello; one B of Anton's answer is lost
  local deliver = W.deliver
  local weg = false
  function W.deliver()
    for i = #W.wire, 1, -1 do local m = W.wire[i]
      if not weg and m.sender == a and m.text:find("^1\tB\tGoldb%-Lamm") then table.remove(W.wire, i); weg = true end end
    return deliver()
  end
  M.Advance(400); b.ns.Guild.SyncNow(); W.run(120)
  H.erwartet("Vorbedingung: ein B verloren", weg)
  H.erwartet("nichts geloescht (die Zahlen im Y stimmen nicht)", H.anzahl(gbounty(b)) == 3, H.anzahl(gbounty(b)))
end)

H.lauf("(3) das eigene Hallo wartet 2 Minuten (Login im Kampf): Freigaben und Kopfgelder kommen alle an", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", G, { fullSender = true })
  a.login(); W.run(60)
  for i = 1, 10 do a.ns.Guild.Release("Ziel" .. string.char(96 + i) .. "-Lamm", { to = "guild", why = "x" }) end
  for i = 1, 10 do a.ns.Guild.SetBounty("Gold" .. string.char(96 + i) .. "-Lamm", 100) end
  W.run(60)
  local b = W.client("Berta", "Senf", G, { fullSender = true })
  b.combat = true
  b.login(); W.run(120)
  b.combat = false; b.fire("PLAYER_REGEN_ENABLED"); W.run(300)
  local L = b.env.DeathNoteDB.guild.lists[G]
  H.erwartet("alle 10 Freigaben", H.freigaben(L.hunts) == 10, H.freigaben(L.hunts))
  H.erwartet("alle 10 Kopfgelder", H.anzahl(L.bounty) == 10, H.anzahl(L.bounty))
end)

H.lauf("(4) M5: Kopfgeld eines Ausgetretenen geht wie seine Freigabe", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", G, { fullSender = true })
  local b = W.client("Berta", "Senf", G, { fullSender = true })
  a.login(); b.login(); W.run(90)
  a.ns.Guild.Release("Ziel-Eins", { to = "guild", why = "x" })
  a.ns.Guild.SetBounty("Ziel-Zwei", 500); W.run(20)
  H.erwartet("Vorbedingung: Freigabe und Kopfgeld bei Berta", b.ns.Guild.Hunt("Ziel-Eins", "guild") ~= nil and b.ns.Guild.HasBounty("Ziel-Zwei"))
  H.raus(W, a)
  for _ = 1, 6 do H.tage(5); b = H.relog(W, b); b.login(); W.run(400); b.fire("GUILD_ROSTER_UPDATE"); W.run(30) end
  H.erwartet("Gegenprobe: Freigabe weg", b.ns.Guild.Hunt("Ziel-Eins", "guild") == nil)
  H.erwartet("Kopfgeld auch weg (auch ohne Freigabe im Buch)", not b.ns.Guild.HasBounty("Ziel-Zwei"))
end)

H.lauf("(5) N2: Freund wird Kollege und nimmt zurueck, waehrend ich offline bin: auch die Kopie im Freundesbuch geht", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", G, { friends = { "Fritz Frei" }, fullSender = true })
  local f = W.client("Fritz", "Frei", nil, { friends = { "Anton Wurst" }, fullSender = true })
  a.login(); f.login(); W.run(120)
  f.ns.Guild.SetBounty("Ziel-Eins", 500); W.run(20)
  H.erwartet("Vorbedingung: im Freundesbuch", a.env.DeathNoteDB.friends.bounty["Ziel-Eins"] ~= nil)
  local adb = H.raus(W, a)
  f.guild = G; f.fire("PLAYER_GUILD_UPDATE"); W.run(60)
  f.ns.Guild.SetBounty("Ziel-Eins", 0); W.run(20)
  a = W.client("Anton", "Wurst", G, { friends = { "Fritz Frei" }, fullSender = true, db = adb })
  a.login(); W.run(300)
  for _ = 1, 2 do a.ns.Guild.SyncNow(); a.ns.Friends.SyncNow(); W.run(300) end
  local _, sum = a.ns.Guild.Bounties("Ziel-Eins")
  H.erwartet("nicht mehr gezeigt", sum == 0 and not a.ns.Guild.HasBounty("Ziel-Eins"), sum)
end)

H.lauf("(6) N3: ein Kopfgeld auf den Empfaenger selbst oder einen Kollegen wird nicht gespeichert", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", G, { fullSender = true })
  local b = W.client("Berta", "Senf", G, { fullSender = true })
  local c = W.client("Carl", "Kurz", G, { fullSender = true })
  a.login(); b.login(); c.login(); W.run(90)
  local P = b.ns.Guild.Proto
  H.gilde(b, P.EncodeBounty("Berta-Senf", "Anton Wurst", 99999, time()), "Anton Wurst-Forever")
  H.gilde(b, P.EncodeBounty("Carl-Kurz", "Anton Wurst", 99999, time()), "Anton Wurst-Forever")
  H.gilde(b, P.EncodeBounty("Ziel-Eins", "Anton Wurst", 99, time()), "Anton Wurst-Forever")
  H.erwartet("nicht auf den Empfaenger", not b.ns.Guild.HasBounty("Berta-Senf"))
  H.erwartet("nicht auf einen Kollegen", not b.ns.Guild.HasBounty("Carl-Kurz"))
  H.erwartet("Gegenprobe: auf einen Fremden ja", b.ns.Guild.HasBounty("Ziel-Eins"))
end)
H.fertig()
