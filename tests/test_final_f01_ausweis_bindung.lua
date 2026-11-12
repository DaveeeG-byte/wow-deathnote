-- (fix-2) Finding 1 of the final hunt (high): identity and binding for friends without surname on the list.
-- Proof of the hunt: the stranger with the same first name who reports FIRST took the binding silently and
-- forever, with no way back. Orchestrator's decision (checked here):
-- (1) with GUID (the friend list gives it, the hello to friends carries the own one): only who has the GUID of
--     the list entry is accepted; the stranger never, not even as the first.
-- (2) without GUID: the first contact binds provisionally; a second full name makes a conflict: nothing is
--     accepted from either any more, the bound one's data stays without alert, a message names both, the
--     player chooses ("That is my friend"); only the choice binds for good, the data of the one not chosen goes.
-- (3) Ways back: release the binding (deletes their data), remove and add again, a changed surname
--     lands in the same dialog.
-- (4) Calls of a provisionally bound friend alert (normal case), the rate cap applies, the summary message
--     names the full name.
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local H = require("beleg_helfer")
local M = H.M

local function J(P, key, by) return P.EncodeHunt({ key = key, t = time(), by = by, why = "x" }) end
local function prints(c)
  local out = {}
  for _, l in ipairs(M.chat or {}) do out[#out + 1] = tostring(l) end
  return table.concat(out, "\n")
end

H.lauf("(1) mit GUID: der Fremde kommt nie herein, auch nicht als Erster", function()
  local W = H.welt()
  W.guids = true
  local a = W.client("Anton", "Wurst", nil, { friends = { "Berta" } })
  local b = W.client("Berta", "Senf", nil, { friends = { "Anton Wurst" }, fullSender = true })
  local f = W.client("Berta", "Fremd", nil, { friends = { "Anton Wurst" }, fullSender = true })
  a.login(); W.run(40)
  local P = a.ns.Guild.Proto
  -- the stranger sends his hello first, with his own (valid) GUID
  H.fluestern(a, P.EncodeHello(0, "1.2.0", W.guidOf(f)), "Berta Fremd-Forever")
  H.fluestern(a, J(P, "Falsch-Lamm", "Berta Fremd"), "Berta Fremd-Forever")
  -- a hello without GUID (he poses as an old version) does not help him: the list gives a GUID
  H.fluestern(a, P.EncodeHello(0, "1.2.0"), "Berta Fremd-Forever")
  H.fluestern(a, J(P, "Falsch-Lamm", "Berta Fremd"), "Berta Fremd-Forever")
  H.erwartet("das Hallo mit fremder GUID bindet nicht", a.env.DeathNoteDB.friends.ties["Berta"] == nil
    or a.env.DeathNoteDB.friends.ties["Berta"].full ~= "Berta Fremd", a.env.DeathNoteDB.friends.ties["Berta"])
  H.erwartet("der Fremde bringt keine Freigabe ins Freundesbuch (GUID auf der Liste, er ist nicht belegt)",
    a.ns.Guild.Hunt("Falsch-Lamm", "friends") == nil)
  -- the real friend logs in: her hello (matching GUID) binds her for sure
  b.login(); W.run(60)
  local tie = a.env.DeathNoteDB.friends.ties["Berta"]
  H.erwartet("das Hallo der echten Freundin (passende GUID) bindet sie sicher", tie and tie.full == "Berta Senf" and tie.sure == true,
    tie and tostring(tie.full) .. "/" .. tostring(tie.sure))
  H.erwartet("was der Fremde gebracht hat, ist weg", a.ns.Guild.Hunt("Falsch-Lamm", "friends") == nil)
  H.fluestern(a, J(P, "Echt-Lamm", "Berta Senf"), "Berta Senf-Forever")
  H.erwartet("die echte Freundin wird angenommen", a.ns.Guild.Hunt("Echt-Lamm", "friends") ~= nil)
  H.fluestern(a, J(P, "Falsch2-Lamm", "Berta Fremd"), "Berta Fremd-Forever")
  H.erwartet("der Fremde bleibt draussen, ohne Konflikt-Dialog (Beleg statt Wahl)", a.ns.Guild.Hunt("Falsch2-Lamm", "friends") == nil
    and a.ns.Friends.Health().reason ~= "conflict", a.ns.Friends.Health().reason)
  H.erwartet("das Hallo an Freunde traegt die eigene GUID, das an die Gilde nicht", (function()
    for _, m in ipairs(W.sent) do
      if m.text:match("^1\tH\t") then
        local n = select(2, m.text:gsub("\t", "")) + 1
        if m.channel == "GUILD" and n ~= 4 then return false end
        if m.channel == "WHISPER" and n ~= 5 then return false end
      end
    end
    return true
  end)())
end)

H.lauf("(2) ohne GUID: Fremder zuerst, dann die echte Freundin -> Konflikt, Wahl, Rueckweg", function()
  local W = H.welt({ "GUILD_ENEMY_SPOTTED", "HUNT_NEW", "GUILD_UPDATED" })
  local a = W.client("Anton", "Wurst", nil, { friends = { "Berta" } })
  a.login(); W.run(40)
  local P = a.ns.Guild.Proto
  H.fluestern(a, P.EncodeHello(0, "1.2.0"), "Berta Fremd-Forever")
  H.fluestern(a, J(P, "Falsch-Lamm", "Berta Fremd"), "Berta Fremd-Forever")
  H.erwartet("erster Kontakt bindet vorlaeufig (Normalfall bleibt heil)", a.ns.Guild.Hunt("Falsch-Lamm", "friends") ~= nil)
  W.run(10)
  H.erwartet("Sammelmeldung nennt den vollen Namen des Freigebenden", (function()
    for _, e in ipairs(a.events) do if e[1] == "HUNT_NEW" and e[4] == "Berta Fremd" and e[5] == "friends" then return true end end
    return false
  end)())
  M.chat = {}
  H.fluestern(a, J(P, "Echt-Lamm", "Berta Senf"), "Berta Senf-Forever")
  H.erwartet("die echte Freundin wird nicht still abgewiesen: Konflikt", a.ns.Friends.Health().reason == "conflict",
    a.ns.Friends.Health().reason)
  H.erwartet("einmal eine Meldung im Chat mit beiden Namen", (function()
    local t = prints(a)
    return t:find("Berta Fremd", 1, true) and t:find("Berta Senf", 1, true)
  end)() ~= nil, prints(a))
  H.fluestern(a, J(P, "Falsch2-Lamm", "Berta Fremd"), "Berta Fremd-Forever")
  H.erwartet("im Konflikt nimmt das Buch von keinem etwas an", a.ns.Guild.Hunt("Echt-Lamm", "friends") == nil
    and a.ns.Guild.Hunt("Falsch2-Lamm", "friends") == nil)
  H.erwartet("die Daten des Gebundenen bleiben stehen", a.ns.Guild.Hunt("Falsch-Lamm", "friends") ~= nil)
  -- no alert from the bound one's data while the conflict lasts
  local n0 = H.zaehle(a, "GUILD_ENEMY_SPOTTED")
  a.ns.Guild.OnUnit("Falsch-Lamm", "nameplate1", "plate")
  H.erwartet("kein Alarm aus den Daten des Gebundenen im Konflikt", H.zaehle(a, "GUILD_ENEMY_SPOTTED") == n0)
  -- the "By guildmate" view has both names, with the choice
  local both = 0
  for _, g in ipairs(a.ns.Guild.ByMember("all")) do
    if (g.name == "Berta Fremd" or g.name == "Berta Senf") and g.tie and g.tie.conflict then both = both + 1 end
  end
  H.erwartet("Nach Kollege zeigt beide Namen mit der Wahl", both == 2, both)
  -- stays beyond the login (saved) until a choice is made
  local a2 = H.relog(W, a); a2.login(); W.run(40)
  H.fluestern(a2, J(P, "Echt2-Lamm", "Berta Senf"), "Berta Senf-Forever")
  H.erwartet("nach dem Login: weiter Konflikt statt stiller Sperre", a2.ns.Friends.Health().reason == "conflict"
    and a2.ns.Guild.Hunt("Echt2-Lamm", "friends") == nil)
  H.erwartet("Wahl: Das ist mein Freund (Berta Senf)", a2.ns.Friends.Choose("Berta", "Berta Senf") == true)
  H.erwartet("die Daten des Abgewaehlten gehen", a2.ns.Guild.Hunt("Falsch-Lamm", "friends") == nil)
  H.fluestern(a2, J(P, "Echt3-Lamm", "Berta Senf"), "Berta Senf-Forever")
  H.erwartet("nach der Wahl kommt die echte Freundin durch", a2.ns.Guild.Hunt("Echt3-Lamm", "friends") ~= nil)
  local a3 = H.relog(W, a2); a3.login(); W.run(40)
  H.fluestern(a3, J(P, "Echt4-Lamm", "Berta Senf"), "Berta Senf-Forever")
  H.erwartet("die Wahl ist gespeichert", a3.ns.Guild.Hunt("Echt4-Lamm", "friends") ~= nil)
end)

H.lauf("(3) Rueckwege: Bindung loesen, Entfernen und neu Hinzufuegen, /dn freunde", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", nil, { friends = { "Berta", "Carla" } })
  a.login(); W.run(40)
  local P = a.ns.Guild.Proto
  H.fluestern(a, J(P, "Falsch-Lamm", "Berta Fremd"), "Berta Fremd-Forever")
  M.chat = {}
  a.ns.HandleSlash("freunde")
  H.erwartet("/dn freunde nennt den gebundenen vollen Namen", prints(a):find("Berta Fremd", 1, true) ~= nil, prints(a))
  H.erwartet("Bindung loesen: es gibt den Weg", type(a.ns.Friends.Unbind) == "function" and a.ns.Friends.Unbind("Berta") == true)
  H.erwartet("Bindung loesen loescht seine Daten", a.ns.Guild.Hunt("Falsch-Lamm", "friends") == nil)
  H.fluestern(a, J(P, "Echt-Lamm", "Berta Senf"), "Berta Senf-Forever")
  H.erwartet("der naechste Kontakt bindet neu", a.ns.Guild.Hunt("Echt-Lamm", "friends") ~= nil)
  -- removing and adding again releases the binding too
  H.fluestern(a, P.EncodeHello(0, "1.2.0"), "Berta Fremd-Forever")
  -- since 1.2.0 only missing from three scans in a row (MISS_SCANS) releases the binding, a single scan does not
  a.friendNames = { "Carla" }
  for _ = 1, 3 do a.fire("FRIENDLIST_UPDATE"); W.run(5) end
  a.friendNames = { "Berta", "Carla" }
  a.fire("FRIENDLIST_UPDATE"); W.run(5)
  H.fluestern(a, J(P, "Neu-Lamm", "Berta Mostrich"), "Berta Mostrich-Forever")
  H.erwartet("nach Entfernen und neu Hinzufuegen gilt der erste Kontakt neu", a.ns.Guild.Hunt("Neu-Lamm", "friends") ~= nil)
end)

H.lauf("(4) geaenderter Nachname: derselbe Dialog statt stiller Sperre", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", nil, { friends = { "Berta" } })
  a.login(); W.run(40)
  local P = a.ns.Guild.Proto
  H.fluestern(a, J(P, "Eins-Lamm", "Berta Senf"), "Berta Senf-Forever")
  H.erwartet("Vorbedingung: gebunden an Berta Senf", a.ns.Guild.Hunt("Eins-Lamm", "friends") ~= nil)
  H.tage(30)
  local a2 = H.relog(W, a); a2.login(); W.run(40)
  H.fluestern(a2, J(P, "Zwei-Lamm", "Berta Mostrich"), "Berta Mostrich-Forever")
  H.erwartet("der umbenannte Freund landet im Dialog", a2.ns.Friends.Health().reason == "conflict", a2.ns.Friends.Health().reason)
  H.erwartet("Wahl: Berta Mostrich", a2.ns.Friends.Choose("Berta", "Berta Mostrich") == true)
  H.fluestern(a2, J(P, "Zwei-Lamm", "Berta Mostrich"), "Berta Mostrich-Forever")
  H.erwartet("nach der Wahl kommt er wieder durch", a2.ns.Guild.Hunt("Zwei-Lamm", "friends") ~= nil)
end)

H.fertig()
