-- Gildenliste (1.2.0): GUILD_ROSTER_UPDATE kommt oft (andere Addons fragen die Liste alle paar Sekunden an).
-- Neu gelesen wird nur, wenn sich die Zahl der Mitglieder geaendert hat oder das letzte Lesen ROSTER_MIN Sekunden
-- her ist; ein Austritt wirkt also hoechstens so viel spaeter. Alle Namen sind erfunden.
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local H = require("beleg_helfer")
local G = "Die Testgilde"

H.lauf("Gildenliste: neu lesen nur bei geaenderter Mitgliederzahl oder nach ROSTER_MIN", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", G, { fullSender = true })
  local b = W.client("Berta", "Senf", G, { fullSender = true })
  a.login(); b.login(); W.run(60)
  local reads = 0
  local orig = a.env.GetGuildRosterInfo
  a.env.GetGuildRosterInfo = function(i, ...) if i == 1 then reads = reads + 1 end return orig(i, ...) end
  local function frage() return a.ns.Guild.IsGuildmate("Berta Senf") end
  local min = a.ns.Guild.C.ROSTER_MIN
  H.erwartet("Konstante ROSTER_MIN vorhanden (5 s)", min == 5, min)
  a.fire("GUILD_ROSTER_UPDATE"); H.erwartet("Kollegin erkannt", frage())
  local r1 = reads
  H.erwartet("nach dem ersten Ereignis gelesen", r1 >= 1, r1)
  W.run(1)
  for _ = 1, 3 do a.fire("GUILD_ROSTER_UPDATE"); frage(); W.run(1) end
  H.erwartet("drei Ereignisse in kurzer Folge, gleiche Zahl: kein neues Lesen", reads == r1, reads - r1)
  -- ein neues Mitglied: die Zahl aendert sich, sofort neu gelesen
  local c = W.client("Carla", "Klein", G, { fullSender = true })
  c.login(); W.run(0.5)
  a.fire("GUILD_ROSTER_UPDATE"); frage()
  local r2 = reads
  H.erwartet("geaenderte Zahl: neu gelesen", r2 > r1, r2 - r1)
  -- nach ROSTER_MIN wird auch bei gleicher Zahl wieder gelesen
  W.run(min + 1)
  a.fire("GUILD_ROSTER_UPDATE"); frage()
  H.erwartet("nach ROSTER_MIN: neu gelesen", reads > r2, reads - r2)
end)

H.fertig()
