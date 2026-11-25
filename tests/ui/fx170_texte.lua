-- Fixer 1.7.0: words of the fixes in all 21 languages (the language files only, no UI).
-- JU-05: the sheet of an unconfirmed entry names the other character and says the claim goes out once the book hears
-- the poster online (never "once you both are online": that held in one order only). All names are made up.
local X = dofile((arg[0]:match("^(.*)/") or ".") .. "/_cu170.lua")
local check = X.check
local Ls = {}
for _, code in ipairs(X.CODES) do Ls[code] = X.world(code).L end
check("deDE: unbestaetigt nennt den anderen Charakter", Ls.deDE.EARNED_NOTE_SENT:find("anderen Charakter", 1, true) ~= nil)
check("enUS: unbestaetigt nennt den anderen Charakter", Ls.enUS.EARNED_NOTE_SENT:find("another character", 1, true) ~= nil)
check("deDE: nicht mehr 'sobald ihr beide online seid'", not Ls.deDE.EARNED_NOTE_SENT:find("beide online", 1, true))
for _, code in ipairs(X.CODES) do
  local s = Ls[code].EARNED_NOTE_SENT
  local n = select(2, s:gsub("{name}", ""))
  check(code .. ": Satz unbestaetigt nennt den Auslober zweimal", n == 2, s)
  -- fixer 2 (JN-10): and the own character that killed (the claim goes out from him only)
  check(code .. ": Satz unbestaetigt nennt den eigenen Char", s:find("{char}", 1, true) ~= nil, s)
end
-- JU-15: the 1.7.0 words of trTR and ukUA say the word of the poster (kelle parası, нагорода)
check("trTR: kein 'ödül' fuer das ausgelobte Kopfgeld im Zettel", Ls.trTR.BANNER_EARNED:lower():find("kelle", 1, true) ~= nil, Ls.trTR.BANNER_EARNED)
check("ukUA: Zettel mit dem Wort des Plakats", Ls.ukUA.BANNER_EARNED:find("Нагород", 1, true) ~= nil, Ls.ukUA.BANNER_EARNED)
-- the dead key SORT_BOUNTY (the sort reads SORT_BOOK_VALUE since 1.7.0) is gone from every language file
for _, code in ipairs(X.CODES) do
  local h = io.open(X.DIR .. "/DeathNote/Locales/" .. code .. ".lua")
  local src = h:read("*a"); h:close()
  check(code .. ": kein SORT_BOUNTY mehr", not src:find("\nL%.SORT_BOUNTY%s*="))
end
X.done("fx170 texte")
