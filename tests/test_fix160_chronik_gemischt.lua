-- Fixer 1.6.0 (jl07, counter-check): a sighting keeps the chronicle's cache, but a deed arriving in the same throttle
-- window still renews it; afterwards a mere sighting keeps it again. Names made up.
local DIR = ((arg and arg[1]) or "."):gsub("/+$", "")
package.path = DIR .. "/tests/?.lua;" .. package.path
local H = require("beleg_helfer")
local G = "Die Testgilde"

H.lauf("Sichtung und neue Tat im selben Fenster: die Chronik baut neu", function()
  local W = H.welt({ "GUILD_UPDATED" })
  local a = W.client("Anton", "Wurst", G)
  local b = W.client("Berta", "Senf", G)
  a.login(); b.login(); W.run(45)
  local key = H.tod(a, "Grimm", "Bart")
  W.run(5)
  local GL = b.ns.GuildLog
  local n0 = #GL.All("all")
  local v0 = GL.Version()
  b.ns.Guild.OnUnit(key, "nameplate1", "plate", nil)   -- a sighting (reason "seen")
  H.tod(a, "Kalt", "Herz")                              -- and a new deed of the guild at the same time
  W.run(5)
  H.erwartet("Version neu", GL.Version() ~= v0, GL.Version() .. " / " .. v0)
  H.erwartet("die neue Tat steht in der Chronik", #GL.All("all") == n0 + 1, #GL.All("all") .. " / " .. n0)
  local v1 = GL.Version()
  W.run(30)
  b.ns.Guild.OnUnit(key, "nameplate1", "plate", nil)
  W.run(2)
  H.erwartet("danach wieder: Sichtung allein laesst den Cache", GL.Version() == v1, GL.Version() .. " / " .. v1)
end)

H.fertig()
