-- Fixer 1.7.0: copy of hunt test ju11 (unchanged).
-- Jagd 1.7.0 Fund JU-11: in 16 von 21 Sprachen tragen zwei gegenlaeufige Zettel dieselbe Ueberschrift. BANNER_CLAIM
-- (seit 1.6.0, beim Auslober: "Kopfgeld faellig", enUS "Bounty due": ich schulde) heisst dort woertlich wie der neue
-- BANNER_EARNED (beim Schuetzen: "Kopfgeld verdient": mir steht zu), z. B. frFR beide "Prime gagnee", nlNL beide
-- "Premie verdiend". deDE, enUS, itIT, zhCN und zhTW trennen die zwei. Wer in einer der 16 Sprachen ein Kopfgeld
-- schuldet, liest dieselbe Ueberschrift wie der, der es verdient hat; die Neuigkeiten-Zeile 1.7.0 nennt genau dieses
-- Wort als das Zeichen fuer "du hast verdient".
-- Erwartet: die zwei Ueberschriften unterscheiden sich in jeder Sprache.
local DIR = assert(arg and arg[1], "Aufruf: luajit <datei> <Projektpfad>"):gsub("/+$", "")
local fail, same = 0, {}
local p = io.popen('ls "' .. DIR .. '/DeathNote/Locales/"')
for file in p:lines() do
  local code = file:match("^(%a%a%u%u)%.lua$")
  if code then
    local claim, earned
    for line in io.lines(DIR .. "/DeathNote/Locales/" .. file) do
      local k, v = line:match('^%s*L%.([%u%d_]+)%s*=%s*"(.-)"')
      if k == "BANNER_CLAIM" then claim = v elseif k == "BANNER_EARNED" then earned = v end
    end
    if claim and earned and claim == earned then fail = fail + 1; same[#same + 1] = code .. " (" .. claim .. ")" end
  end
end
p:close()
if fail > 0 then io.write("ROT gleiche Ueberschrift fuer 'faellig' und 'verdient' in ", fail, " Sprachen: ", table.concat(same, ", "), "\n") end
io.write(("ju11_zwei_zettel_ein_wort: %d rot\n"):format(fail))
os.exit(fail == 0 and 0 or 1)
