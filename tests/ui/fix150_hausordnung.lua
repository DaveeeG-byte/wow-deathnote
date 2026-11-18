-- 1.5.0 fixer (U15): the foot of the House Rules sheet Guild no longer says that only guild and friends get anything
-- while the section POST above it sends into the open chat. The foot limits itself to sharing and alerts and says that
-- a post is for everyone, with the word of the button. In deDE and enUS on the built sheet.
local WT = arg[1] or "."
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_ju.lua")
local function hints(W, text)
  local n = 0
  for _, f in ipairs(W.BM.frames) do
    if f._kind == "FontString" and f._text == text then n = n + 1 end
  end
  return n
end
for _, code in ipairs({ "deDE", "enUS" }) do
  local W = J.world(WT, code)
  local ns, L = W.ns, W.ns.L
  ns.UI.Open(); W.settle()
  ns.UI.OpenPanel("settings"); W.tick()
  local foot = L.SET_HINT_FRIENDS_POST
  J.check(code .. ": Fusszeile des Blatts Gilde ist die neue", foot ~= nil and hints(W, foot) == 1, foot)
  J.check(code .. ": kein Satz 'nur Gilde und Freunde' ohne Einschraenkung",
    hints(W, code == "deDE" and "Geteilt wird nur mit Gilde und Freunden mit Revenge Book." or
      "Only guild and friends with Revenge Book get anything.") == 0)
  local word = code == "deDE" and "Aushang" or "post"
  J.check(code .. ": Fusszeile nennt den Aushang", foot and foot:find(word, 1, true) ~= nil, foot)
  J.check(code .. ": Fusszeile begrenzt sich auf Teilen und Warnen",
    foot and foot:find(code == "deDE" and "Teilen und Warnen" or "Sharing and alerts", 1, true) ~= nil, foot)
  J.check(code .. ": keine Fehler", #W.AM.errors == 0 and #W.BM.violations == 0, W.AM.errors[1] or W.BM.violations[1])
end
-- the rule in all 21 languages: tests/test_fix150_texte.lua
J.done()
