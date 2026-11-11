-- Funde an Deckeln und Grenzen der Abschussliste:
-- (a) Kein Tempo-Deckel fuer Freigaben: ein Mitglied kann durch Freigeben und Abblasen in einer
--     Minute Dutzende verschiedene Ziele ueber die Liste aller schicken (jedes loest in der Naehe Alarm aus).
-- (b) Man kann sich selbst und Gildenkollegen/Freunde zur Jagd freigeben.
-- (c) "Gildenbuch leeren" laesst die Abschussliste der Gilde stehen; fremde Freigaben lassen sich
--     lokal gar nicht entfernen.
-- (d) Ein Freund, der auch in der Gilde ist, bekommt eine Freigabe "nur fuer Freunde" nie zu sehen.
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local H = require("beleg_helfer")
local M = H.M
local G = "Die Testgilde"

H.lauf("Freigaben im Sekundentakt", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", G)
  a.login(); W.run(40)
  local P = a.ns.Guild.Proto
  local seen, alarms = 0, 0
  for i = 1, 70 do
    local key = "Ziel" .. string.char(65 + i % 26) .. string.char(65 + math.floor(i / 26)) .. "-Lamm"
    H.gilde(a, P.EncodeHunt({ key = key, t = time(), by = "Berta Senf", why = "Flut" }), "Berta-Forever")
    if a.ns.Guild.Hunt(key, "guild") then
      seen = seen + 1
      a.events = {}
      a.ns.Guild.OnUnit(key, "nameplate1", "plate", false)
      alarms = alarms + H.zaehle(a, "GUILD_ENEMY_SPOTTED")
    end
    H.gilde(a, P.EncodeCallOff(key, "Berta Senf"), "Berta-Forever")
    M.Advance(0.5)
  end
  H.erwartet("ein Mitglied bringt in 35 Sekunden hoechstens 20 verschiedene Ziele auf die Liste", seen <= 20,
    seen .. " Ziele, " .. alarms .. " Alarm-Ereignisse")
end)

H.lauf("Sich selbst und Kollegen freigeben", function()
  local W = H.welt()
  -- fix-2 (Fund 7 der finalen Jagd): "einer von euch" nur mit vollem Namen; der Client nennt ihn hier mit
  local a = W.client("Anton", "Wurst", G, { fullSender = true })
  local b = W.client("Berta", "Senf", G, { fullSender = true })
  a.login(); b.login(); W.run(40)
  H.tod(b, "Grimm", "Bart"); W.run(5)        -- Anton kennt Berta als Kollegin mit DeathNote
  local g1 = a.ns.Guild.Release("Anton-Wurst", { to = "guild" })
  H.erwartet("der eigene Char laesst sich nicht freigeben", not g1, "Anton Wurst steht auf der Abschussliste")
  local g2 = a.ns.Guild.Release("Berta-Senf", { to = "guild", why = "Kollegin" })
  H.erwartet("eine gehoerte Gildenkollegin laesst sich nicht freigeben", not g2, "Berta Senf steht auf der Abschussliste")
end)

H.lauf("Gildenbuch leeren und die Abschussliste", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", G)
  local b = W.client("Berta", "Senf", G)
  a.login(); b.login(); W.run(40)
  b.ns.Guild.Release("Opfer-Lamm", { to = "guild", why = "stoert mich" }); W.run(5)
  H.erwartet("Vorbedingung: fremde Freigabe steht", a.ns.Guild.Hunt("Opfer-Lamm", "guild") ~= nil)
  a.ns.Guild.Release("Mein-Lamm", { to = "guild" })
  a.ns.Guild.Clear()
  -- (fix-1, Entscheidung) beides: Gildenbuch leeren leert die fremden Freigaben der Gilde, eigene bleiben;
  -- dazu "Fuer mich ausblenden" je Ziel
  H.erwartet("nach 'Gildenbuch leeren' ist die fremde Freigabe weg", a.ns.Guild.Hunt("Opfer-Lamm", "guild") == nil,
    a.ns.Guild.HuntCount("guild") .. " Ziel(e)")
  H.erwartet("die eigene Freigabe bleibt (nur ich kann sie abblasen)", a.ns.Guild.Hunt("Mein-Lamm", "guild") ~= nil)
  b.ns.Guild.Release("Zwei-Lamm", { to = "guild" }); W.run(5)
  a.ns.Guild.HideHunt("Zwei-Lamm", true)
  local rows = a.ns.Guild.Hunts("guild")
  H.erwartet("ausgeblendet: am Ende der Liste", rows[#rows].key == "Zwei-Lamm" and rows[#rows].hidden == true)
end)

H.lauf("Freund in der Gilde und Freigabe nur fuer Freunde", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", G, { friends = { "Berta" } })
  local b = W.client("Berta", "Senf", G, { friends = { "Anton" } })
  a.login(); b.login(); W.run(60)
  H.tod(b, "Grimm", "Bart"); H.tod(a, "Fies", "Ling"); W.run(10)
  a.ns.Guild.Release("Opfer-Lamm", { to = "friends", why = "nur Freunde" })
  W.run(30)
  M.Advance(400); a.ns.Friends.SyncNow(); b.ns.Friends.SyncNow(); b.ns.Guild.SyncNow(); W.run(120)
  H.erwartet("die Freundin (auch Kollegin) sieht die Freigabe 'nur fuer Freunde'", b.ns.Guild.Hunt("Opfer-Lamm", "all") ~= nil,
    "kommt nie an")
end)

H.fertig()
