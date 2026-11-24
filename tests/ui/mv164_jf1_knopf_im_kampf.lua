-- Jagd 1.6.4, Jaeger A, Fund 1. Aufruf: luajit jf1_knopf_im_kampf.lua <projekt>   (rot = Exit 1)
-- Erwartet (Regeln, Entscheidung 1: "sagt eine Chatzeile das, und es passiert sonst nichts"; Kommentar im Bau-Test
-- mv164_modus "the button on the House Rules in combat: the chat line, the book stays"): Ein Klick auf den Knopf
-- "Alarm verschieben" im Kampf laesst das Buch offen und gibt genau eine Zeile MOVE_COMBAT.
-- Auf 4f30098 rot: der Knopf schliesst erst das Buch und fragt dann erst nach dem Kampf.
local WT = arg[1] or "."
local J = dofile(WT .. "/tests/ui/_mv164.lua")
for _, code in ipairs({ "deDE", "enUS" }) do
  local db = { version = 5, settings = { welcomed = true, firstRun = "done", news164 = true, news160 = true, news150 = true,
    news140 = true, lang = code }, enemies = {}, deaths = {} }
  local W = J.world(code, { db = db })
  W.ns:Fire("TOGGLE_UI"); W.tick(1); W.settle()
  W.ns.UI.OpenPanel("settings"); W.tick(1)
  local btn
  for _, f in ipairs(W.BM.frames) do
    if f.text and f.text._text == W.ns.L.SET_MOVE and f._scripts and f._scripts.OnClick then btn = f end
  end
  J.check(code .. " Knopf da", btn ~= nil)
  W.combat(true)
  J.check(code .. " Buch im Kampf offen (Voraussetzung)", W.shown("DeathNoteFrame"))
  local before = #W.chat()
  if btn then W.click(btn) end
  J.check(code .. " Knopf im Kampf: Modus bleibt aus", not W.ns.Place.Active() and #W.samples() == 0)
  J.check(code .. " Knopf im Kampf: genau eine Zeile MOVE_COMBAT", #W.chat() == before + 1 and W.said(W.ns.L.MOVE_COMBAT) == 1)
  J.check(code .. " Knopf im Kampf: das Buch bleibt offen", W.shown("DeathNoteFrame"))
end
J.done("jf1_knopf_im_kampf")
