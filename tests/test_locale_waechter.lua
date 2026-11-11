-- Waechter (1.2.0): fest verdrahtete sichtbare Texte ausserhalb von Locales/ machen diesen Test rot.
-- Aufruf: luajit tests/test_locale_waechter.lua [addon-ordner]
-- Findet String-Literale (auch '...' und [[...]]) mit Umlaut/ß oder mit einem deutschen Wort der Liste.
-- Kommentare werden uebersprungen. Ausnahmen: Locale.lua (Eigennamen der Sprachen), ERLAUBT unten.

local DIR = arg[1] or ((arg[0]:match("^(.*)/tests/") or ".") .. "/DeathNote/")

-- Woerter, die in 1.1.0 sichtbar waren (Auswahl, kleingeschrieben verglichen, ganze Woerter)
local WORDS = { "buch", "gilde", "gildenbuch", "täter", "kollege", "kollegen", "gesucht", "hausordnung",
  "todesjournal", "alarm", "begnadigt", "verdacht", "staatsfeind", "rache", "nie", "vor", "und", "nicht",
  "kein", "keine", "noch", "ist", "aus", "an", "der", "die", "das", "dich", "du", "dein", "deine", "mit", "jetzt",
  "klick", "rechtsklick", "gesehen", "neueste", "rang", "kopfgeld", "notiz", "vermerk", "sek", "min", "std",
  -- 1.2.0 dazu (Freunde, Abschussliste, Hausordnung)
  "ein", "eine", "einen", "von", "zum", "zur", "nach", "bis", "oder", "wird", "hat", "sind", "alle", "schon", "wieder",
  "freigegeben", "erlegt", "freund", "freundesbuch", "sichern", "einlesen", "teilen", "plakat", "stempel", "grund",
  "tod", "tode", "taten", "sichtung", "sichtungen", "zuletzt", "weitere", "weiterer", "abschussliste", "jagen",
  "warnen", "melden", "zeigen", "einstellungen", "ton", "leise", "laut", "groesse", "spaeter", "neu", "laden" }
local WORD = {}
for _, w in ipairs(WORDS) do WORD[w] = true end

-- Literale, die bleiben duerfen (Protokoll, Pfade, Schluessel, WANTED, Befehle)
local ERLAUBT = {
  ["WANTED"] = true, ["DeathNote"] = true, ["/dn"] = true,
  -- deutsche Unterbefehle (gelten fuer immer, neben den englischen) und interne Kennungen (Stempelart)
  ["gilde"] = true, ["freunde"] = true, ["jagd"] = true, ["abblasen"] = true, ["still"] = true, ["ruhe"] = true,
  ["hilfe"] = true, ["sprache"] = true, ["rache"] = true,
  ["kopfgeld"] = true,   -- 1.2.1: /dn kopfgeld (neben /dn bounty)
}
-- technische Kennungen, die gespeichert werden (Sonde/Fehlersuche) und darum fest bleiben;
-- sie erscheinen nur als Wert in /dn probe, nie als Satz
local ERLAUBT_IN = {
  ["Attribution.lua"] = { ["keine API"] = true, ["keine Daten"] = true, ["nicht registriert"] = true, ["keine Treffer"] = true },
  ["Probe.lua"] = { ["gekürzt"] = true },
  -- fix-2: erkennt den alten gespeicherten Satz der uebernommenen Notiz (1.1.0) und stellt ihn auf einen Merker um
  ["Store.lua"] = { ["^Aus dem Gildenbuch übernommen %((%d+)× getötet in der Gilde%)%.$"] = true },
}
local SKIP_FILES = { ["Locale.lua"] = true }

local function literals(src)
  local out, i, n, line = {}, 1, #src, 1
  while i <= n do
    local c = src:sub(i, i)
    if c == "\n" then line = line + 1; i = i + 1
    elseif src:sub(i, i + 1) == "--" then
      local lvl = src:match("^%-%-%[(=*)%[", i)
      if lvl then
        local close = "]" .. lvl .. "]"
        local e = src:find(close, i, true) or n
        for _ in src:sub(i, e):gmatch("\n") do line = line + 1 end
        i = e + #close
      else
        local e = src:find("\n", i, true) or n + 1
        i = e
      end
    elseif c == '"' or c == "'" then
      local j, buf = i + 1, {}
      while j <= n do
        local d = src:sub(j, j)
        if d == "\\" then buf[#buf + 1] = src:sub(j, j + 1); j = j + 2
        elseif d == c then break
        else buf[#buf + 1] = d; j = j + 1 end
      end
      out[#out + 1] = { line = line, s = table.concat(buf) }
      i = j + 1
    elseif c == "[" and src:match("^%[=*%[", i) then
      local lvl = src:match("^%[(=*)%[", i)
      local close = "]" .. lvl .. "]"
      local e = src:find(close, i, true) or n
      local s = src:sub(i + #lvl + 2, e - 1)
      out[#out + 1] = { line = line, s = s }
      for _ in s:gmatch("\n") do line = line + 1 end
      i = e + #close
    else
      i = i + 1
    end
  end
  return out
end

local function suspicious(s)
  if ERLAUBT[s] then return false end
  if s:find("[\195][\132\150\156\164\182\188\159]") then return "Umlaut/ß" end   -- Ä Ö Ü ä ö ü ß
  if s:match("%.tga$") or s:match("%.ogg$") then return false end
  if s:match("^Interface\\") or s:match("^Fonts\\") or s:match("^[%u_%d]+$") then return false end
  for w in s:gmatch("[%a\128-\255]+") do
    if WORD[w:lower()] and (s:find("%s") or #w >= 4) then return "Wort '" .. w .. "'" end
  end
  return false
end

local found = {}
local p = io.popen('ls "' .. DIR .. '"')
for f in p:lines() do
  if f:match("%.lua$") and not SKIP_FILES[f] then
    local h = assert(io.open(DIR .. f, "rb")); local src = h:read("*a"); h:close()
    -- Humor.lua (1.2.0, Autor): die Humor-Texte gibt es nur in Deutsch und Englisch, sie sind keine
    -- Schluessel der Sprachtabelle und stehen darum im markierten Block HUMOR-TEXTE der Datei selbst;
    -- nur dieser Block ist ausgenommen (Zeilenumbrueche bleiben fuer die Zeilennummern), der Rest
    -- der Datei wird wie jede andere geprueft
    if f == "Humor.lua" then
      src = src:gsub("(%-%- >>> HUMOR%-TEXTE.-%-%- <<< HUMOR%-TEXTE)", function(b) return (b:gsub("[^\n]", "")) end)
    end
    for _, lit in ipairs(literals(src)) do
      local why = not (ERLAUBT_IN[f] and ERLAUBT_IN[f][lit.s]) and suspicious(lit.s)
      if why then found[#found + 1] = ("%s:%d  %s  %q"):format(f, lit.line, why, lit.s:sub(1, 60)) end
    end
  end
end
p:close()
-- jeder im Code gelesene Schluessel (L.KEY) steht in enUS.lua; fehlte er, zeigte das Spiel den Schluessel
do
  local h = assert(io.open(DIR .. "Locales/enUS.lua", "rb")); local en = h:read("*a"); h:close()
  local have = {}
  for k in en:gmatch("\nL%.([%w_]+)%s*=") do have[k] = true end
  local p2 = io.popen('ls "' .. DIR .. '"')
  for f in p2:lines() do
    if f:match("%.lua$") and f ~= "Locale.lua" then
      local h2 = assert(io.open(DIR .. f, "rb")); local src = h2:read("*a"); h2:close()
      local ln = 0
      for line in (src .. "\n"):gmatch("([^\n]*)\n") do
        ln = ln + 1
        local code = line:gsub("%-%-.*$", "")
        for k in code:gmatch("%f[%w_]L%.([%u][%u%d_]+)") do
          if not have[k] then found[#found + 1] = ("%s:%d  Schluessel fehlt in enUS: %s"):format(f, ln, k) end
        end
      end
    end
  end
  p2:close()
end
io.write(("%-18s %3d Funde\n"):format("locale-waechter", #found))
for i = 1, math.min(#found, 15) do io.write("  ROT: " .. found[i] .. "\n") end
if #found > 15 then io.write(("  ... und %d weitere\n"):format(#found - 15)) end
os.exit(#found == 0 and 0 or 1)
