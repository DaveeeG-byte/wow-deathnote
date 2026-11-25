-- 1.7.0 fix JL-7 (copy of the hunt's jl06, adapted to the new E4: one V gives a claim on EVERY own bounty that
-- stood; a later kill stands open beside it, the poster chooses).
-- jl06 (Notiz 3): der Auslober hat auf zwei eigenen Chars ein Kopfgeld auf dasselbe Ziel (Berta 45, offline; Bianca 20,
-- eingeloggt). Antons V erzeugt nur EINEN Anspruch (Biancas); Bertas Kopfgeld bleibt frei, obwohl Anton auch dafuer
-- einen Eintrag hat. Doras spaeterer Kill bekommt dann Bertas Kopfgeld (judge faellt bei V vom vergebenen Kopfgeld
-- des eingeloggten Chars auf das naechste freie durch). Loggt Berta ein, wird Antons C mit "kein Kopfgeld" quittiert.
-- Ausserdem bleibt Doras Eintrag fuer Bianca "sent" (kein Q 3), obwohl Bianca online ist.
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local K = require("_fx170")
local H, M = K.H, K.M

local function von(c, owner) for _, x in ipairs(K.earned(c)) do if x.owner == owner then return x end end return {} end

H.lauf("zwei Chars, zwei Kopfgelder, zwei Schuetzen", function()
  local W = K.welt()
  local a, b = K.paar(W)
  local d = W.client("Dora", "Dorn", K.G, { fullSender = true }); d.login(); W.run(60)
  b.ns.Guild.SetBounty(K.KEY, 45); W.run(10)
  local z = K.weg(W, b, { name = "Bianca" }); z.login(); W.run(60)
  z.ns.Guild.SetBounty(K.KEY, 20); W.run(10)
  M.Advance(200)
  K.toetet(a); W.run(10)
  H.erwartet("Vorbedingung: Anton hat zwei Eintraege", #K.earned(a) == 2, #K.earned(a))
  M.Advance(200)
  K.toetet(d); W.run(10)
  local n = { ["Berta Senf"] = 0, ["Bianca Senf"] = 0 }
  for _, y in ipairs(K.claims(z)) do if y.by == "Anton Wurst" and n[y.char] then n[y.char] = n[y.char] + 1 end end
  H.erwartet("Antons eines V: ein Anspruch je eigenem Kopfgeld", n["Berta Senf"] == 1 and n["Bianca Senf"] == 1,
    n["Berta Senf"] .. "/" .. n["Bianca Senf"])
  H.erwartet("Anton: Bianca hat sofort quittiert", von(a, "Bianca Senf").state == "open", von(a, "Bianca Senf").state)
  H.erwartet("Dora: Biancas Kopfgeld steht offen daneben (kein Durchfallen)", von(d, "Bianca Senf").state == "open",
    von(d, "Bianca Senf").state)
  local b3 = K.weg(W, z, { name = "Berta" }); M.Advance(400); b3.login(); W.run(90)
  H.erwartet("Anton (erster Kill): Bertas Kopfgeld offen", von(a, "Berta Senf").state == "open", von(a, "Berta Senf").state)
  H.erwartet("Dora: Bertas Kopfgeld offen", von(d, "Berta Senf").state == "open", von(d, "Berta Senf").state)
end)

H.fertig()
