-- 1.6.4 move, follow-up hunt N3: the bar could not be built (an error in its words): the mode runs with its samples,
-- one chat line names the ways out, and Esc ends it all the same. Names are made up.
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_mv164.lua")
local check = J.check
for _, code in ipairs({ "deDE", "enUS" }) do
  -- the four pieces are built first (real ones), so the error hits the bar on the first start of the mode
  local W = J.world(code)
  local Look = W.ns.Look
  local real, n = Look.Text, 0
  W.ns.Store.AddManual("Velka Thornheart")
  W.ns:Fire("TEST_ALERT"); W.ns.CallUI.Show({ by = "Liora", zone = "Ashenvale", same = true }); W.ns.Extras.Notice("RANG", "Grimwald", "Zeile")
  W.ns.Grudge.Test(); W.tick(0.6); W.settle(); if W.ns.Grudge.Current() then W.ns.Grudge.Close("click") end; W.tick(1)
  Look.Text = function(...) n = n + 1; if n == 1 then error("einmaliger Fehler im Aufbau") end return real(...) end
  local before = #W.chat()
  W.slash("move")
  Look.Text = real
  check(code .. ": Fehler traf die Leiste, Modus laeuft mit vier Mustern", n >= 1 and W.ns.Place.Active() and #W.samples() == 4)
  check(code .. ": keine halbe Leiste sichtbar", not W.shown("DeathNoteMove"))
  check(code .. ": eine Zeile nennt die Auswege", W.said(W.ns.L.MOVE_HOW) == 1, #W.chat() - before)
  W.esc()
  check(code .. ": Esc beendet den Modus ohne Leiste", not W.ns.Place.Active() and #W.samples() == 0)
  W.slash("move")
  check(code .. ": naechster Start mit ganzer Leiste", W.shown("DeathNoteMove") and W.frame("DeathNoteMove").done ~= nil)
  W.esc()
  check(code .. ": Esc beendet ihn wieder", not W.ns.Place.Active())
  local c = 0
  for _, nm in ipairs(W.G.UISpecialFrames) do if nm == "DeathNoteMove" or nm == "DeathNoteMoveEsc" then c = c + 1 end end
  check(code .. ": je Name ein Eintrag fuer Esc", c == 2, c)
end
J.done("mv164_n3_ohne_leiste")
