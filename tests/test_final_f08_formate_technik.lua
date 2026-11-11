-- Sprache und Formate technisch.
-- (1) Datumsformat-Zeilen einer Uebersetzung gehen ungeprueft an date(): nur pcall schuetzt. Ein Formatzeichen, das die
--     C-Bibliothek des Clients nicht kennt, ist dort kein Lua-Fehler (unter Windows bricht strftime bei ungueltigen
--     Zeichen hart ab oder liefert Leeres). Erwartet: der Code reicht nur gepruefte Zeichen weiter.
-- (2) Gegenproben gruen: Mehrzahl mit 0, negativ, nil, Secret, sehr gross, NaN, unendlich in allen Regeln;
--     Platzhalter-Werte mit %, |, { }; fehlende Werte; Tausendertrenner aller 21 Sprachen.
-- (3) Die Datumsformate der 21 Sprachdateien des Stands benutzen nur %d %m %y %Y %H %M (Gegenprobe).
-- (fix-2) Belegtest der finalen Jagd, in die Suite uebernommen; Kopf: tests/beleg_helfer.lua
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local H = require("beleg_helfer")
local M = H.M

H.lauf("(1) Formatzeile mit unbekanntem Zeichen", function()
  M.Reset()
  local seen = {}
  local real = os.date
  _G.date = function(fmt, t) seen[#seen + 1] = fmt; return real(fmt, t) end
  local ns = M.Load({ lang = "enUS" })
  local L = ns.L
  local t = time() - 30 * 86400
  for _, bad in ipairs({ "%e. %B", "%-d/%-m", "%d.%m %", "%Q", "%5d", "%Ez %Oy" }) do
    rawset(L, "TIME_FMT_DAY", bad); rawset(L, "TIME_FMT_WHEN", bad); rawset(L, "TIME_FMT_DAY_YEAR", bad); rawset(L, "TIME_FMT_WHEN_YEAR", bad)
    seen = {}
    local a, w = ns.Util.Ago(t), ns.Util.When(t)
    local passed = false
    for _, f in ipairs(seen) do
      if f:gsub("%%[dmyYHM%%]", ""):find("%", 1, true) then passed = true end
    end
    H.erwartet("ungepruefte Formatzeile \"" .. bad .. "\" erreicht date() nicht", not passed, "an date() gereicht")
    H.erwartet("Ergebnis ist ein Text", type(a) == "string" and type(w) == "string")
  end
  _G.date = nil
end)

H.lauf("(2) Mehrzahl und Platzhalter an den Raendern", function()
  M.Reset()
  local ns = M.Load({ lang = "enUS" })
  local Lc, F = ns.Locale, ns.F
  local secret = M.Secret("zahl", "number")
  local ok = true
  for _, code in ipairs(Lc.CODES) do
    local forms = Lc.Forms(code)
    local text = "{count} {count|" .. table.concat({ "a", "b", "c" }, "|", 1, forms) .. "}"
    for _, v in ipairs({ 0, 1, 2, 5, 11, 21, 111, -1, -5, 1e15, 1e300, math.huge, -math.huge, 0 / 0, 2.5, "3", "x", true, secret }) do
      local good, s = pcall(F, text, { count = v }, code)
      if not good or type(s) ~= "string" or s:find("{", 1, true) then ok = false; io.write("    " .. code .. " " .. tostring(good and s or s) .. "\n") end
      local g2, idx = pcall(Lc.Plural, v, code)
      if not g2 or type(idx) ~= "number" or idx < 1 or idx > forms then ok = false; io.write("    Plural " .. code .. " " .. tostring(idx) .. "\n") end
    end
    local good, s = pcall(F, text, nil, code)
    if not good or type(s) ~= "string" then ok = false end
  end
  H.erwartet("Mehrzahl: 19 Randwerte in 21 Sprachen ohne Fehler, immer eine gueltige Form", ok)
  local s = F("{name} hat {count|ein|viele} %s %d |cffff0000x|r {unbekannt} {", { name = "A%sB|cff00ff00{count}", count = 2 })
  H.erwartet("Werte mit %, | und { werden nicht weiterverarbeitet", s == "A%sB|cff00ff00{count} hat viele %s %d |cffff0000x|r ? {", s)
  H.erwartet("fehlender Wert zeigt ?, kein Fehler", F("{a}{b}", { a = 1 }) == "1?")
  H.erwartet("kein Text: leer", F(nil, {}) == "" and F(5) == "")
end)

H.lauf("(3) Formatzeilen und Tausendertrenner der 21 Sprachdateien", function()
  M.Reset()
  local ns = {}
  assert(loadfile(H.DIR .. "/DeathNote/Locale.lua"))("DeathNote", ns)
  for _, c in ipairs(ns.Locale.CODES) do assert(loadfile(H.DIR .. "/DeathNote/Locales/" .. c .. ".lua"))("DeathNote", ns) end
  local bad, badSep = {}, {}
  for _, c in ipairs(ns.Locale.CODES) do
    local t = assert(ns.Locale.Raw(c))
    for _, k in ipairs({ "TIME_FMT_DAY", "TIME_FMT_DAY_YEAR", "TIME_FMT_WHEN", "TIME_FMT_WHEN_YEAR" }) do
      local f = t[k]
      if f and f:gsub("%%[dmyYHM]", ""):find("%", 1, true) then bad[#bad + 1] = c .. "." .. k end
    end
    local sep = t.THOUSANDS_SEP
    if sep then
      -- dieselbe Rechnung wie Thousands() in UI.lua
      local s = "1234567"
      local out = s:reverse():gsub("(%d%d%d)", "%1" .. sep:reverse():gsub("%%", "%%%%")):reverse()
      if out:sub(1, #sep) == sep then out = out:sub(#sep + 1) end
      if out ~= "1" .. sep .. "234" .. sep .. "567" then badSep[#badSep + 1] = c end
    end
  end
  H.erwartet("alle Formatzeilen nur mit %d %m %y %Y %H %M", #bad == 0, table.concat(bad, " "))
  H.erwartet("Tausendertrenner aller Sprachen ueberstehen die Rechnung (auch Mehrbyte)", #badSep == 0, table.concat(badSep, " "))
end)

H.fertig()
