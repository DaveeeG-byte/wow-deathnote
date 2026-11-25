-- 1.7.1 manual: the inventory (tests/ui/manual_inventar.lua) against the chapters of the manual (UI.lua UX.MANUAL):
-- every line names a version and a chapter that exists, and every chapter explains at least one function.
-- Usage: luajit tests/ui/ma171_inventar.lua <project>
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_mv164.lua")
local check = J.check
local list = dofile(J.WT .. "/tests/ui/manual_inventar.lua")
local W = J.world("enUS", { db = { version = 5, settings = { welcomed = true, firstRun = "done", news171 = true }, enemies = {}, deaths = {} } })
local chapters = W.ns.UI.MANUAL_DATA.chapters
local known, count = {}, {}
for _, c in ipairs(chapters) do known[c.id] = true; count[c.id] = 0 end
local bad = {}
for i, row in ipairs(list) do
  local what, ver, ch = row[1], row[2], row[3]
  if type(what) ~= "string" or what == "" then bad[#bad + 1] = "Zeile " .. i .. ": keine Funktion" end
  if type(ver) ~= "string" or not ver:match("^%d+%.%d+[%.%d]*$") then bad[#bad + 1] = "Zeile " .. i .. ": Version " .. tostring(ver) end
  if not known[ch] then bad[#bad + 1] = "Zeile " .. i .. ": Kapitel " .. tostring(ch) .. " gibt es nicht"
  else count[ch] = count[ch] + 1 end
end
check("Inventar: jede Zeile mit Funktion, Version und einem Kapitel, das es gibt (" .. #list .. " Zeilen)", #bad == 0, table.concat(bad, "; "))
for _, c in ipairs(chapters) do
  check("Kapitel " .. c.id .. " erklaert mindestens eine Funktion des Inventars", count[c.id] > 0, count[c.id])
end
J.done("ma171 inventar")
