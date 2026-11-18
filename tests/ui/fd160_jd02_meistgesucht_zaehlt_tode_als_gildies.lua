-- Copy of dev/berichte/160/jagd2-tests/design (helpers: _ju160.lua, _fdwelt.lua). -- jd02: Chronik, Ansicht Raecher, "Meistgesucht der Woche". Rechts steht "{n} Gildies" (enUS "guildmates"), n ist
-- aber die Zahl der Tode (GL.Week zaehlt je Tod). Ein Moerder, der dieselbe Kollegin dreimal toetet, steht mit
-- "3 Gildies" da. Erwartet: Zahl der verschiedenen Opfer, oder ein Wort, das Tode zaehlt ("3x"). Namen erfunden.
local WT = arg[1] or "."
local here = (arg[0]:match("^(.*)/") or ".")
local J = dofile(here .. "/_ju160.lua")
for _, code in ipairs({ "deDE", "enUS" }) do
  local W = J.world(WT, code, { guild = "Die Rostigen Naegel" })
  dofile(here .. "/_fdwelt.lua")(W, { { "Liora", "Grimm", "Aschgrau", 2 }, { "Liora", "Grimm", "Aschgrau", 5 },
    { "Liora", "Grimm", "Aschgrau", 9 } })
  W.open(); W.tab("guild"); W.settle()
  W.ns.GuildLogUI.Open("avengers"); W.settle()
  local bad = W.ns.F(W.ns.L.GLOG_WANTED_N, { count = 3 })
  local wk = W.ns.GuildLog.Week()
  J.check(code .. ": Woche kennt 3 Tode durch einen Moerder", wk and wk.wanted and wk.wanted[1] and wk.wanted[1].n == 3,
    wk and wk.wanted and wk.wanted[1] and wk.wanted[1].n)
  J.check(code .. ": ein Opfer, drei Tode heisst nicht \"" .. bad .. "\"", not W.visible(bad), bad)
end
J.done()
