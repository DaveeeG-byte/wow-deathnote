-- 1.7.0 fix JL-2 (copy of the hunt's jl02). jl02 (Notiz 2): V geht live verloren (Flutdeckel AVENGE_PER_SENDER = 3 in 10 Minuten beim Auslober), beide bleiben
-- online. Der vierte Kill binnen 10 Minuten trifft ein Ziel mit Kopfgeld. Erwartet: der Anspruch kommt trotzdem an,
-- solange beide online sind. Ist: V verworfen ("flood"), kein C (niemand sagt Hallo), Eintrag bleibt "sent".
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local K = require("_fx170")
local H, M = K.H, K.M
local ZIELE = { { "Erster", "Feind" }, { "Zweiter", "Feind" }, { "Dritter", "Feind" } }

H.lauf("vierter Kill in 10 Minuten: Kopfgeld-Ziel", function()
  local W = K.welt()
  local a, b = K.paar(W)
  -- drei weitere Ziele, je mit Kopfgeld von Berta (so zaehlt jedes V bei ihr)
  for i, z in ipairs(ZIELE) do
    M.AddEnemy("nameplate" .. i, { name = z[1], surname = z[2], guid = "Player-1-00000" .. i })
    H.erwartet("Kopfgeld " .. i, b.ns.Guild.SetBounty(z[1] .. "-" .. z[2], 10) == true)
  end
  b.ns.Guild.SetBounty(K.KEY, 500); W.run(20)
  for i = 1, 3 do
    a.fire("NAME_PLATE_UNIT_ADDED", "nameplate" .. i)
    a.fire("PARTY_KILL", a.env.UnitGUID("player"), "Player-1-00000" .. i)
    W.run(20); M.Advance(100)
  end
  H.erwartet("Vorbedingung: drei Ansprueche", #K.claims(b) == 3, #K.claims(b))
  K.toetet(a); W.run(30)
  local x
  for _, y in ipairs(K.earned(a)) do if y.key == K.KEY then x = y end end
  H.erwartet("Vorbedingung: Eintrag fuer das grosse Kopfgeld", x ~= nil)
  -- beide bleiben zwei Stunden online
  for i = 1, 12 do M.Advance(600); W.run(30) end
  local n = 0
  for _, y in ipairs(K.claims(b)) do if y.key == K.KEY then n = n + 1 end end
  H.erwartet("Berta hat den Anspruch auf das grosse Kopfgeld", n == 1, n)
  H.erwartet("Anton: Eintrag bestaetigt", x and x.state == "open", x and x.state)
end)

-- zweite Ursache: der Schuetze bleibt nach dem Kill laenger als BAG_FRESH (10 Minuten) im Kampf, die Schlange haelt
H.lauf("Kill, danach 11 Minuten im Kampf", function()
  local W = K.welt()
  local a, b = K.paar(W)
  b.ns.Guild.SetBounty(K.KEY, 500); W.run(20)
  a.combat = true
  K.toetet(a)
  for i = 1, 11 do W.run(60) end
  a.combat = false
  a.fire("PLAYER_REGEN_ENABLED"); W.run(60)
  local x = K.earned(a)[1]
  H.erwartet("Vorbedingung: Eintrag", x ~= nil)
  for i = 1, 6 do M.Advance(600); W.run(30) end
  H.erwartet("Kampf: Berta hat den Anspruch", #K.claims(b) == 1, #K.claims(b))
  H.erwartet("Kampf: Eintrag bestaetigt", x and x.state == "open", x and x.state)
end)

H.fertig()
