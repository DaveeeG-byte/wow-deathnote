-- Design fixer 1.6.0 (design hunt 14): the button "Call" on the grudge notice is a target for a click in a fight: at
-- least 72 x 18 with the word at 11 pt (deDE, enUS), never cut in 21 languages, the head beside it not cut. Names made up.
local WT = arg[1] or "."
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_ju160.lua")
local LANGS = { "deDE", "enUS", "frFR", "esES", "itIT", "ptBR", "ruRU", "koKR", "zhCN", "zhTW", "svSE", "nbNO", "daDK",
  "fiFI", "nlNL", "plPL", "csCZ", "huHU", "hrHR", "ukUA", "trTR" }
local cut = {}
for _, code in ipairs(LANGS) do
  local W = J.world(WT, code, { guild = "Die Rostigen Naegel" })
  local ns = W.ns
  -- the notice's own file (the shared world loads the book's windows, not the grudge notice)
  W.BM.Load(WT .. "/DeathNote/GrudgeCard.lua", ns)
  ns:Fire("READY")
  ns.Grudge.Test(3); W.tick(1)
  local card = rawget(W.G, "DeathNoteGrudge")
  local b = card and card.dnCall
  if code == "deDE" or code == "enUS" then
    J.check(code .. ": Knopf da", b ~= nil and b:IsShown())
    if b then
      J.check(code .. ": Knopf mindestens 72 x 18", b:GetWidth() >= 72 and b:GetHeight() >= 18,
        ("%sx%s"):format(b:GetWidth(), b:GetHeight()))
      J.check(code .. ": Wort 11 pt", b.text.fontSize == 11, b.text.fontSize)
    end
  end
  if not b or ns.Look.IsCut(b.text) then cut[#cut + 1] = code .. " Knopf" end
  if card and ns.Look.IsCut(card.head) then cut[#cut + 1] = code .. " Kopf" end
end
J.check("21 Sprachen: Knopf und Kopf nicht abgeschnitten", #cut == 0, table.concat(cut, ", "))
J.done()
