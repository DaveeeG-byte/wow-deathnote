-- Copy of dev/berichte/160/jagd2-tests/design (helpers: _ju160.lua, _fdwelt.lua). -- jd01: Gildenchronik. Die Unterzeile sagt "n Ereignisse", die Fusszeile "1 bis 13 von m": m zaehlt die
-- Tagesueberschriften (HEUTE, GESTERN, Datum) mit, also steht auf derselben Seite zweimal eine andere Zahl
-- (Bild j2-chronik-zahlen-deDE.png: "24 Ereignisse" und "von 28"). Erwartet: beide Zahlen gleich. Namen erfunden.
local WT = arg[1] or "."
local here = (arg[0]:match("^(.*)/") or ".")
local J = dofile(here .. "/_ju160.lua")
local W = J.world(WT, "deDE", { guild = "Die Rostigen Naegel" })
local kills = {}
for i = 1, 18 do kills[i] = { (i % 2 == 0) and "Liora" or "Bertram", "Feind" .. string.char(96 + i), "Grau", i * 7 } end
dofile(here .. "/_fdwelt.lua")(W, kills)
W.open(); W.tab("guild"); W.settle()
W.ns.GuildLogUI.Open("holders"); W.settle()
local sub, foot
for _, t in ipairs(W.texts()) do
  if t:find("Ereignis", 1, true) then sub = t end
  if t:find(" von ", 1, true) and t:find("Mausrad", 1, true) then foot = t end
end
local n = sub and tonumber(sub:match("(%d+) Ereignis"))
local m = foot and tonumber(foot:match("von (%d+)"))
J.check("Chronik hat Unterzeile und Fusszeile", n and m, tostring(sub) .. " / " .. tostring(foot))
J.check("Fusszeile zaehlt dasselbe wie die Unterzeile", n == m, tostring(sub) .. "  |  " .. tostring(foot))
J.done()
