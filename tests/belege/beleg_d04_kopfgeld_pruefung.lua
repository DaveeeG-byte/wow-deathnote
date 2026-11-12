-- 1.2.1 after the final hunt (efficiency): an incoming bounty already stored exactly like this (the
-- usual repetition in every answer) no longer queries all guildmates and friends (Guild.WhoIs). The check
-- against own characters, guildmates and friends with DeathNote still applies to every new or changed bounty.
-- Usage: nice -n 15 luajit beleg_d04_kopfgeld_pruefung.lua <project copy>. All names made up.
local H = dofile((arg[0]:match("^(.*)/") or ".") .. "/_kopf_c.lua")
local G = "Die Testgilde"
local function gilde(c, text, from) c.fire("CHAT_MSG_ADDON", "DeathNote", text, "GUILD", from) end

H.lauf("Wiederholung ohne Abfrage, Neues mit Pruefung", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", G, { fullSender = true })
  local b = W.client("Berta", "Senf", G, { fullSender = true })
  local c = W.client("Carl", "Kurz", G, { fullSender = true })
  a.login(); b.login(); c.login(); W.run(90)
  local P, Gd = b.ns.Guild.Proto, b.ns.Guild
  local n, who = 0, Gd.WhoIs
  Gd.WhoIs = function(...) n = n + 1; return who(...) end
  local t = time()
  gilde(b, P.EncodeBounty("Ziel-Eins", "Anton Wurst", 99, t), "Anton Wurst-Forever")
  H.erwartet("neues Kopfgeld: gespeichert und geprueft", Gd.HasBounty("Ziel-Eins") and n == 1, n)
  for _ = 1, 5 do gilde(b, P.EncodeBounty("Ziel-Eins", "Anton Wurst", 99, t), "Anton Wurst-Forever") end
  H.erwartet("fuenf Wiederholungen: keine Abfrage", n == 1, n)
  gilde(b, P.EncodeBounty("Ziel-Eins", "Anton Wurst", 120, t + 5), "Anton Wurst-Forever")
  H.erwartet("geaenderter Betrag: geprueft", n == 2, n)
  -- still refused: on the receiver, on a guildmate, also when repeated
  for _ = 1, 3 do
    gilde(b, P.EncodeBounty("Berta-Senf", "Anton Wurst", 500, t), "Anton Wurst-Forever")
    gilde(b, P.EncodeBounty("Carl-Kurz", "Anton Wurst", 500, t), "Anton Wurst-Forever")
  end
  H.erwartet("nicht auf den Empfaenger", not Gd.HasBounty("Berta-Senf"))
  H.erwartet("nicht auf einen Kollegen", not Gd.HasBounty("Carl-Kurz"))
  Gd.WhoIs = who
  H.erwartet("keine Fehler", #H.M.errors == 0, H.M.errors[1])
end)
H.fertig()
