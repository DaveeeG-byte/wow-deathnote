-- Fixer 1.7.0: copy of hunt test ju15 (unchanged).
-- Jagd 1.7.0 Fund JU-15: trTR nennt das ausgelobte Kopfgeld im Bestand "kelle parasi" (Plakat POSTER_BOUNTY
-- "KELLE PARASI", Knopf ACT_BOUNTY, Tooltip BOUNTY_TIP_CLICK, alle Chatzeilen des Auslobens). Der Block 1.7.0 nennt
-- es durchgehend "odul" (Belohnung). Die Neuigkeiten-Zeile erklaert die Trennung der zwei Woerter auf dem Plakat
-- ("... artik {value}: odul yalnizca birinin koydugudur"), nennt aber nicht das Wort, das auf dem Plakat steht.
-- Regel der Runde: Woerter fuer Dinge, die es schon gibt, woertlich aus der jeweiligen Sprachdatei.
-- Erwartet: die Saetze, die das Plakat-Wort erklaeren (CHAT_NEWS_170, BOOK_VALUE_TIP), benutzen das Wort des Plakats.
local DIR = assert(arg and arg[1], "Aufruf: luajit <datei> <Projektpfad>"):gsub("/+$", "")
local L = {}
for line in io.lines(DIR .. "/DeathNote/Locales/trTR.lua") do
  local k, v = line:match('^%s*L%.([%u%d_]+)%s*=%s*"(.*)"')
  if k then L[k] = v end
end
local fail = 0
local function check(name, cond, info)
  if not cond then fail = fail + 1; io.write("ROT ", name, "  -> ", tostring(info), "\n") end
end
local function kelle(s) return s ~= nil and (s:lower():find("kelle", 1, true) ~= nil or s:find("KELLE", 1, true) ~= nil) end
check("Vorbedingung: das Plakat und der Knopf sagen kelle parasi", kelle(L.POSTER_BOUNTY) and kelle(L.ACT_BOUNTY) and kelle(L.BOUNTY_TIP_CLICK), L.POSTER_BOUNTY)
check("trTR CHAT_NEWS_170 nennt das Wort des Plakats", kelle(L.CHAT_NEWS_170), L.CHAT_NEWS_170)
check("trTR BOOK_VALUE_TIP nennt das Wort des Plakats", kelle(L.BOOK_VALUE_TIP), L.BOOK_VALUE_TIP)
io.write(("ju15_trTR_kopfgeld_wort: %d rot\n"):format(fail))
os.exit(fail == 0 and 0 or 1)
