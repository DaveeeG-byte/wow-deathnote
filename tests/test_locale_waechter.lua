-- Guard (1.2.0): hard-coded visible texts outside Locales/ turn this test red.
-- Usage: luajit tests/test_locale_waechter.lua [addon folder]
-- Finds string literals (also '...' and [[...]]) with umlaut/ß or with a German word from the list.
-- Comments are skipped. Exceptions: Locale.lua (native names of the languages), ERLAUBT below.

local DIR = arg[1] or ((arg[0]:match("^(.*)/tests/") or ".") .. "/DeathNote/")

-- words that were visible in 1.1.0 (a selection, compared in lower case, whole words)
local WORDS = { "buch", "gilde", "gildenbuch", "täter", "kollege", "kollegen", "gesucht", "hausordnung",
  "todesjournal", "alarm", "begnadigt", "verdacht", "staatsfeind", "rache", "nie", "vor", "und", "nicht",
  "kein", "keine", "noch", "ist", "aus", "an", "der", "die", "das", "dich", "du", "dein", "deine", "mit", "jetzt",
  "klick", "rechtsklick", "gesehen", "neueste", "rang", "kopfgeld", "notiz", "vermerk", "sek", "min", "std",
  -- added in 1.2.0 (friends, hit list, house rules)
  "ein", "eine", "einen", "von", "zum", "zur", "nach", "bis", "oder", "wird", "hat", "sind", "alle", "schon", "wieder",
  "freigegeben", "erlegt", "freund", "freundesbuch", "sichern", "einlesen", "teilen", "plakat", "stempel", "grund",
  "tod", "tode", "taten", "sichtung", "sichtungen", "zuletzt", "weitere", "weiterer", "abschussliste", "jagen",
  "warnen", "melden", "zeigen", "einstellungen", "ton", "leise", "laut", "groesse", "spaeter", "neu", "laden" }
local WORD = {}
for _, w in ipairs(WORDS) do WORD[w] = true end

-- Literals that may stay (protocol, paths, keys, WANTED, commands)
local ERLAUBT = {
  ["WANTED"] = true, ["DeathNote"] = true, ["/dn"] = true,
  -- German subcommands (valid for good, next to the English ones) and internal ids (stamp kind)
  ["gilde"] = true, ["freunde"] = true, ["jagd"] = true, ["abblasen"] = true, ["still"] = true, ["ruhe"] = true,
  ["hilfe"] = true, ["sprache"] = true, ["rache"] = true,
  ["kopfgeld"] = true,   -- 1.2.1: /dn kopfgeld (next to /dn bounty)
}
-- technical ids that are stored (probe/debugging) and so stay fixed;
-- they only appear as a value in /dn probe, never as a sentence
local ERLAUBT_IN = {
  ["Attribution.lua"] = { ["keine API"] = true, ["keine Daten"] = true, ["nicht registriert"] = true, ["keine Treffer"] = true },
  ["Probe.lua"] = { ["gekürzt"] = true },
  -- fix-2: recognises the old stored sentence of the taken-over note (1.1.0) and turns it into a marker
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
-- 1.3.0: the theme data files (Themes/<id>.lua) count as code too: a theme's words live in Locales/Themes/
local files = {}
for _, sub in ipairs({ "", "Themes/" }) do
  local p = io.popen('ls "' .. DIR .. sub .. '" 2>/dev/null')
  for f in p:lines() do if f:match("%.lua$") then files[#files + 1] = sub .. f end end
  p:close()
end
for _, f in ipairs(files) do
  if not SKIP_FILES[f] then
    local h = assert(io.open(DIR .. f, "rb")); local src = h:read("*a"); h:close()
    -- Humor.lua (1.2.0, author): the humor texts exist only in German and English, they are not
    -- keys of the locale table and so live in the marked HUMOR-TEXTE block of the file itself;
    -- only this block is exempt (line breaks stay for the line numbers), the rest
    -- of the file is checked like any other
    if f == "Humor.lua" then
      src = src:gsub("(%-%- >>> HUMOR%-TEXTE.-%-%- <<< HUMOR%-TEXTE)", function(b) return (b:gsub("[^\n]", "")) end)
    end
    -- Ranks.lua (1.3.0): the rank names are data in German and English by design (repute concept 14), in the
    -- marked block RANK-NAMES; only that block is skipped
    if f == "Ranks.lua" then
      src = src:gsub("(%-%- >>> RANK%-NAMES.-%-%- <<< RANK%-NAMES)", function(b) return (b:gsub("[^\n]", "")) end)
    end
    for _, lit in ipairs(literals(src)) do
      local why = not (ERLAUBT_IN[f] and ERLAUBT_IN[f][lit.s]) and suspicious(lit.s)
      if why then found[#found + 1] = ("%s:%d  %s  %q"):format(f, lit.line, why, lit.s:sub(1, 60)) end
    end
  end
end
-- every key read in the code (L.KEY) is in enUS.lua; if it were missing, the game would show the key
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
