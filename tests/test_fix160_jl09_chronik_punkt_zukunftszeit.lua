-- Jagd Logik 160/09: Sync nimmt Zeiten bis 300 s in der Zukunft an (C.FUTURE, Uhr eines Gildies geht vor). Die
-- Chronik zaehlt "neu seit dem letzten Blick" mit e.t > seenTab (GL.NewSince). Ein Tod mit Zeit in der Zukunft
-- bleibt nach dem Blick in den Reiter "neu": der Punkt am Reiter Gilde kommt beim Wechsel auf einen anderen Reiter
-- sofort wieder, die Zahl am Band ebenso, bis die Uhr die fremde Zeit eingeholt hat (bis 5 Minuten).
-- Erwartet: nach MarkSeen ist nichts mehr ungesehen (z. B. seen = max(now, neueste gesehene Zeit)).
-- Lauf: cd ~/Projects/wow-deathnote-jagd && luajit <diese Datei> .   (Exit 1 = Fund belegt)
local DIR = ((arg and arg[1]) or "."):gsub("/+$", "")
package.path = DIR .. "/tests/?.lua;" .. package.path
local H = require("beleg_helfer")
local G = "Die Testgilde"

H.lauf("Tod eines Gildies mit Zeit +240 s, dann in den Reiter geschaut", function()
  local W = H.welt({ "GUILD_KILL" })
  local a = W.client("Anton", "Wurst", G)
  local b = W.client("Berta", "Senf", G)
  a.login(); b.login(); W.run(45)
  local P = b.ns.Guild.Proto
  local text = P.EncodeKill({ key = "Grimm-Bart", display = "Grimm Bart", class = "MAGE", level = 30, zone = "Z",
    t = time() + 240, victim = "Anton Wurst" }, "K")
  H.gilde(b, text, "Anton Wurst-Forever")
  W.run(1)
  local GL = b.ns.GuildLog
  H.erwartet("Vorbedingung: Tod in Bertas Chronik", #GL.All("all") >= 1, #GL.All("all"))
  GL.MarkSeen("seenTab"); GL.MarkSeen("seenFeed")
  W.run(2)
  H.erwartet("nach dem Blick nichts mehr neu (Reiter)", GL.Unseen("seenTab") == 0, GL.Unseen("seenTab") .. " neu")
  H.erwartet("nach dem Blick nichts mehr neu (Band)", GL.Unseen("seenFeed") == 0, GL.Unseen("seenFeed") .. " neu")
end)

H.fertig()
