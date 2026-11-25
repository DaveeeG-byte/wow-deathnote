-- 1.7.0 fixer round 2 (copy of the hunt's jn08). jn08 (Nachjagd 1.7.0, Fixer-Diff Claim.lua sanitizeEnded und READY bountyBack): gespeicherte Grabsteine und
-- Vormerkungen werden beim Start nur auf Typ und Mindestalter geprueft, nicht auf Obergrenzen.
-- (a) Ein Grabstein mit Gold ueber BOUNTY_GOLD_MAX und einem Ende in ferner Zukunft bleibt liegen; ein C darauf ergibt
--     einen Anspruch ueber 7.777.777.777 Gold auf ein Kopfgeld, das "noch ein Jahr steht".
-- (b) Eine Vormerkung mit Zeit in der Zukunft geht als B mit Gold 0 und dieser Zeit hinaus, fuer ein Ziel, auf dem
--     der Char ein lebendes Kopfgeld hat (bei allen, die die Zeit annehmen, faellt es weg; im eigenen Buch bleibt es).
-- Erwartet: Grabstein verworfen oder gekappt (Gold hoechstens BOUNTY_GOLD_MAX, Ende hoechstens jetzt); Vormerkung aus
-- der Zukunft verworfen. Alle Namen sind erfunden.
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local K = require("_fx170")
local H, M = K.H, K.M

H.lauf("kaputte gespeicherte Daten", function()
  local W = K.welt()
  local a, b = K.paar(W)
  b.ns.Guild.SetBounty(K.KEY, 40); W.run(10)
  local d = b.env.DeathNoteDB
  local t = time()
  local max = b.ns.Guild.C.BOUNTY_GOLD_MAX or 999999
  d.bountyEnded = { { key = K.KEY2, char = "Berta Senf", t0 = t - 5000, g = 7777777777, e = t + 86400 * 365 } }
  d.bountyBack = { ["Berta Senf"] = { [K.KEY] = t + 1e9 } }
  local b2 = K.weg(W, b); b2.login(); W.run(120)
  local e = (b2.env.DeathNoteDB.bountyEnded or {})[1]
  H.erwartet("(a) Grabstein: Gold hoechstens BOUNTY_GOLD_MAX", not e or e.g <= max, e and e.g)
  H.erwartet("(a) Grabstein: Ende nicht in der Zukunft", not e or e.e <= time() + 600, e and (e.e - time()))
  local P = b2.ns.Guild.Proto
  H.gilde(b2, P.EncodeClaim(K.KEY2, "Dora Dorn", time() - 60, "Berta Senf", 40), "Dora Dorn-Forever"); W.run(5)
  local c = K.claims(b2)[1]
  H.erwartet("(a) kein Anspruch ueber Milliarden Gold", not c or c.g <= max, c and c.g)
  local zukunft = 0
  for _, m in ipairs(K.msgs(W, "B", b2)) do
    local g, bt = m.text:match("^1\tB\t[^\t]+\t[^\t]+\t(%d+)\t(%d+)")
    if g == "0" and tonumber(bt) > time() + 86400 then zukunft = zukunft + 1 end
  end
  H.erwartet("(b) kein B Gold 0 mit Zeit aus der Zukunft", zukunft == 0, zukunft)
  H.erwartet("Vorbedingung: eigenes Kopfgeld steht noch", b2.ns.Bounty.Own(K.KEY) == 40)
end)

H.fertig()
