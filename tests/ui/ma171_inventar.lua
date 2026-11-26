-- 1.7.1 manual: the inventory (tests/ui/manual_inventar.lua) against the chapters of the manual (UI.lua UX.MANUAL):
-- every line names a version, a chapter that exists and the key of the paragraph that says it; that key is a
-- paragraph of that very chapter (or MANUAL_INTRO, the way in) and has a text in English and German. Every chapter
-- explains at least one function.
-- Usage: luajit tests/ui/ma171_inventar.lua <project>
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_mv164.lua")
local check = J.check
local list = dofile(J.WT .. "/tests/ui/manual_inventar.lua")
local W = J.world("enUS", { db = { version = 5, settings = { welcomed = true, firstRun = "done", news171 = true }, enemies = {}, deaths = {} } })
local chapters = W.ns.UI.MANUAL_DATA.chapters
-- the raw text of a key in a language file (the fallback to English would hide a missing German text)
local function raw(lang, key)
  local h = assert(io.open(J.WT .. "/DeathNote/Locales/" .. lang .. ".lua", "r"))
  local s = h:read("*a"); h:close()
  return s:match("\nL%." .. key .. '%s*=%s*"(.-)"%s*[\n%-]')
end
local known, count, paraOf = {}, {}, {}
for _, c in ipairs(chapters) do
  known[c.id] = true; count[c.id] = 0
  for _, p in ipairs(c.paras) do paraOf[p[2]] = c.id end
end
local bad, badKey = {}, {}
for i, row in ipairs(list) do
  local what, ver, ch, key = row[1], row[2], row[3], row[4]
  if type(what) ~= "string" or what == "" then bad[#bad + 1] = "Zeile " .. i .. ": keine Funktion" end
  if type(ver) ~= "string" or not ver:match("^%d+%.%d+[%.%d]*$") then bad[#bad + 1] = "Zeile " .. i .. ": Version " .. tostring(ver) end
  if not known[ch] then bad[#bad + 1] = "Zeile " .. i .. ": Kapitel " .. tostring(ch) .. " gibt es nicht"
  else count[ch] = count[ch] + 1 end
  -- 1.7.1 fixer: the fourth field, the paragraph that explains it
  if type(key) ~= "string" or not (key == "MANUAL_INTRO" or paraOf[key] == ch) then
    badKey[#badKey + 1] = "Zeile " .. i .. ": " .. tostring(key) .. " ist kein Absatz von " .. tostring(ch)
  elseif not (raw("enUS", key) or ""):find("%S") or not (raw("deDE", key) or ""):find("%S") then
    badKey[#badKey + 1] = "Zeile " .. i .. ": " .. key .. " ohne Text in enUS oder deDE"
  end
end
check("Inventar: jede Zeile mit Funktion, Version und einem Kapitel, das es gibt (" .. #list .. " Zeilen)", #bad == 0, table.concat(bad, "; "))
check("Inventar: jede Zeile nennt den Absatz ihres Kapitels, und es gibt ihn in enUS und deDE", #badKey == 0, table.concat(badKey, "; "))
for _, c in ipairs(chapters) do
  check("Kapitel " .. c.id .. " erklaert mindestens eine Funktion des Inventars", count[c.id] > 0, count[c.id])
end
J.done("ma171 inventar")
