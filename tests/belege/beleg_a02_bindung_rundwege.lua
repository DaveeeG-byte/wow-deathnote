-- Feld 2: Konflikt-Dialog und "Bindung loesen" auf Rundwegen (Liste ohne GUID).
-- (1) Gegenprobe zu Fund 5 der vorigen Jagd: "von diesem Freund nie gehoert: ganz zurueck fragen" gilt nur,
--     wenn MEIN Hallo vor seinem ankommt. Loggt der Freund nach mir ein (sein Hallo kommt zuerst), setzt
--     schon sein Hallo den Merker "gehoert", mein Hallo fragt nur drei Tage zurueck, seine Geschichte fehlt.
--     Dasselbe nach Wahl im Konflikt und nach "Bindung loesen" (der Merker bleibt stehen).
-- (2) Konflikt offen, Freund wird von der Liste genommen und wieder hinzugefuegt (benannter Rueckweg): der
--     Konflikt ist weg, die Daten des vorlaeufig Gebundenen (hier: des Fremden) bleiben und alarmieren wieder.
-- (3) Eine vom Spieler getroffene Wahl geht verloren, wenn EIN einziger Scan den Freund nicht nennt (die
--     Liste ist dabei nicht leer); das Entfernen selbst braucht drei Scans und 14 Spieltage.
-- (4) Wahl treffen, waehrend der Abgewaehlte gerade sendet; loesen, sofort neuer Kontakt, wieder loesen.
local H = dofile((arg[0]:match("^(.*)/") or ".") .. "/_kopf.lua")
local M = H.M

-- Anton hat zwei Freunde; Carla sorgt dafuer, dass das Freundesbuch nie leer ist (ein leeres Buch fragt immer
-- ganz zurueck und wuerde den Fund verdecken). Berta starb vor 6 Tagen, Anton hat nie von ihr gehoert.
-- werZuerst = "ich": Berta ist schon im Spiel, Anton loggt ein. "sie": Anton ist im Spiel, Berta loggt ein.
local function geschichte(werZuerst, saat)
  math.randomseed(saat)
  local W = H.welt()
  local a = W.client("Anton", "Wurst", nil, { friends = { "Berta", "Carla Klein" } })
  local b = W.client("Berta", "Senf", nil, { friends = { "Anton Wurst" }, fullSender = true })
  local c = W.client("Carla", "Klein", nil, { friends = { "Anton Wurst" }, fullSender = true })
  b.login(); W.run(5)
  local key = H.tod(b, "Taeter", "Lamm")
  W.run(90)   -- ihre Sitzung laeuft aus (kein Zeitgeber der alten Sitzung bleibt uebrig)
  local bdb = H.raus(W, b)
  H.tage(2)   -- Antons letzte Sitzung liegt nach der Tat (sonst deckt die Rueckschau sie zufaellig)
  a.login(); c.login(); W.run(90)
  H.tod(c, "Anderer", "Wolf"); W.run(10)
  local adb = H.raus(W, a)
  W.run(120)
  H.tage(6)
  local a2, b2
  local function A() a2 = W.client("Anton", "Wurst", nil, { db = adb, friends = { "Berta", "Carla Klein" } }); a2.login() end
  local function B() b2 = W.client("Berta", "Senf", nil, { db = bdb, friends = { "Anton Wurst" }, fullSender = true }); b2.login() end
  if werZuerst == "ich" then B(); W.run(90); A() else A(); W.run(90); B() end
  W.run(180)
  local tie = a2.env.DeathNoteDB.friends.ties["Berta"]
  H.erwartet("Vorbedingung (" .. werZuerst .. "): Anton hat jetzt von Berta gehoert", tie and tie.full == "Berta Senf")
  return a2.ns.Guild.Get(key, "friends") ~= nil
end

H.lauf("(1) Gegenprobe Fund 5: nie gehoert heisst ganz zurueck fragen", function()
  local okIch, okSie = 0, 0
  for saat = 1, 12 do
    if geschichte("ich", saat) then okIch = okIch + 1 end
    if geschichte("sie", saat) then okSie = okSie + 1 end
  end
  H.erwartet("Gegenprobe: Freundin ist im Spiel, ich logge ein: ihre Tat von vor 8 Tagen kommt an (12 Saaten)", okIch == 12, okIch)
  H.erwartet("ich bin im Spiel, die Freundin loggt ein: ihre Tat von vor 8 Tagen kommt an (12 Saaten)", okSie == 12,
    "kam nur in " .. okSie .. " von 12 Laeufen an: kommt ihr Hallo vor meinem, gilt sie als 'gehoert' und mein Hallo fragt nur drei Tage zurueck")
end)

H.lauf("(2) Konflikt offen, Freund entfernt und neu hinzugefuegt", function()
  local W = H.welt({ "GUILD_ENEMY_SPOTTED", "HUNT_NEW", "GUILD_UPDATED" })
  local a = W.client("Anton", "Wurst", nil, { friends = { "Berta", "Carla" } })
  a.login(); W.run(40)
  local P = a.ns.Guild.Proto
  H.fluestern(a, H.J(P, "Falsch-Lamm", "Berta Fremd"), "Berta Fremd-Forever")
  H.fluestern(a, H.J(P, "Echt-Lamm", "Berta Senf"), "Berta Senf-Forever")
  H.erwartet("Vorbedingung: Konflikt, Daten des Gebundenen stumm", a.ns.Friends.Health().reason == "conflict"
    and a.ns.Friends.Muted("Berta Fremd"))
  a.friendNames = { "Carla" }; a.fire("FRIENDLIST_UPDATE"); W.run(5)
  a.friendNames = { "Berta", "Carla" }; a.fire("FRIENDLIST_UPDATE"); W.run(5)
  local da = a.ns.Guild.Hunt("Falsch-Lamm", "friends") ~= nil
  local n0 = H.zaehle(a, "GUILD_ENEMY_SPOTTED")
  a.ns.Guild.OnUnit("Falsch-Lamm", "nameplate1", "plate")
  local alarm = H.zaehle(a, "GUILD_ENEMY_SPOTTED") > n0
  H.erwartet("nach Entfernen und neu Hinzufuegen alarmieren die Daten des nie bestaetigten Namens nicht wieder",
    not (da and alarm), "Freigabe des vorlaeufig Gebundenen steht noch: " .. tostring(da) .. ", alarmiert: " .. tostring(alarm))
end)

H.lauf("(3) eine Wahl ueberlebt einen einzelnen Scan ohne den Freund", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", nil, { friends = { "Berta", "Carla" } })
  a.login(); W.run(40)
  local P = a.ns.Guild.Proto
  H.fluestern(a, H.J(P, "Falsch-Lamm", "Berta Fremd"), "Berta Fremd-Forever")
  H.fluestern(a, H.J(P, "Echt-Lamm", "Berta Senf"), "Berta Senf-Forever")
  H.erwartet("Vorbedingung: Wahl", a.ns.Friends.Choose("Berta", "Berta Senf") == true)
  -- ein Scan, in dem die Liste Berta gerade nicht nennt (nicht leer), danach ist sie wieder da
  a.friendNames = { "Carla" }; a.fire("FRIENDLIST_UPDATE"); W.run(2)
  a.friendNames = { "Berta", "Carla" }; a.fire("FRIENDLIST_UPDATE"); W.run(2)
  local tie = a.env.DeathNoteDB.friends.ties["Berta"]
  H.erwartet("die Wahl des Spielers steht noch", tie and tie.sure == true and tie.full == "Berta Senf",
    tie and (tostring(tie.full) .. "/" .. tostring(tie.sure)))
  H.fluestern(a, H.J(P, "Falsch2-Lamm", "Berta Fremd"), "Berta Fremd-Forever")
  H.erwartet("der Abgewaehlte kommt danach nicht wieder herein", a.ns.Guild.Hunt("Falsch2-Lamm", "friends") == nil,
    "angenommen: erster Kontakt bindet neu")
end)

H.lauf("(4) Gegenproben: Wahl waehrend der Abgewaehlte sendet; loesen, neuer Kontakt, wieder loesen", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", nil, { friends = { "Berta" } })
  a.login(); W.run(40)
  local P = a.ns.Guild.Proto
  H.fluestern(a, H.J(P, "Falsch-Lamm", "Berta Fremd"), "Berta Fremd-Forever")
  H.fluestern(a, H.J(P, "Echt-Lamm", "Berta Senf"), "Berta Senf-Forever")
  a.ns.Friends.Choose("Berta", "Berta Senf")
  for i = 1, 5 do H.fluestern(a, H.J(P, "F" .. i .. "-Lamm", "Berta Fremd"), "Berta Fremd-Forever") end
  H.fluestern(a, P.EncodeHello(0, "1.2.0"), "Berta Fremd-Forever")
  local n = 0
  for k in pairs(a.env.DeathNoteDB.friends.hunts) do if k:find("^F") then n = n + 1 end end
  H.erwartet("nach der Wahl kommt vom Abgewaehlten nichts mehr", n == 0 and a.ns.Friends.Health().reason ~= "conflict", n)
  for r = 1, 3 do
    H.erwartet("loesen " .. r, a.ns.Friends.Unbind("Berta") == true)
    H.fluestern(a, H.J(P, "R" .. r .. "-Lamm", "Berta Senf"), "Berta Senf-Forever")
    H.erwartet("neuer Kontakt bindet " .. r, a.ns.Guild.Hunt("R" .. r .. "-Lamm", "friends") ~= nil)
  end
  a.ns.Friends.Unbind("Berta")
  H.erwartet("am Ende keine Reste", H.freigaben(a.env.DeathNoteDB.friends.hunts) == 0, H.freigaben(a.env.DeathNoteDB.friends.hunts))
  H.erwartet("loesen ohne Bindung ist harmlos", a.ns.Friends.Unbind("Berta") == false and a.ns.Friends.Unbind("Niemand") == false
    and a.ns.Friends.Choose("Niemand", "X Y") == false and a.ns.Friends.Choose("Berta", "Berta Nie") == false)
end)

H.fertig()
