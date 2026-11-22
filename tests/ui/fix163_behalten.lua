-- 1.6.3 (surface hunt 1.6.0, finding 11): "Keep" was only a word in the right-click menu. The switch "File away old
-- suspicions" now carries a tooltip that names where filed entries go and the menu word, in every language with the
-- words of that language's own file; the poster of an entry held back says so. Names made up.
-- Call from the project root: luajit tests/ui/fix163_behalten.lua .
local WT = arg[1] or "."
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_ju160.lua")
local LANGS = { "deDE", "enUS", "frFR", "esES", "itIT", "ptBR", "ruRU", "koKR", "zhCN", "zhTW", "svSE", "nbNO", "daDK",
  "fiFI", "nlNL", "plPL", "csCZ", "huHU", "hrHR", "ukUA", "trTR" }
for _, code in ipairs(LANGS) do
  local W = J.world(WT, code)
  local ns, L = W.ns, W.ns.L
  local tip = L.OPT_BOOK_EXPIRE_TIP
  J.check(code .. ": Hinweis nennt das Menuewort und die Ansicht", type(tip) == "string" and tip:find(L.ACT_KEEP, 1, true) ~= nil
    and tip:find(L.VIEW_FILED, 1, true) ~= nil, tip)
  if code == "deDE" or code == "enUS" then
    -- the switch shows the tip
    W.open()
    ns.UI.OpenPanel("settings"); W.tick(); W.settle()
    local cb
    for _, f in ipairs(W.BM.frames) do if f.optTip == "OPT_BOOK_EXPIRE_TIP" then cb = f end end
    J.check(code .. ": Schalter traegt den Hinweis", cb ~= nil and cb:IsVisible())
    ns.UI.ClosePanel(true)
    -- the poster of a kept suspect says so; without Keep it does not
    local key = ns.Store.ApplyKill({ name = "Kaelen", surname = "Dusk", class = "ROGUE", level = 40 },
      { t = time() - 3600, zone = "Brachland", source = "suspect" }, false)
    J.check(code .. ": Verdacht darf behalten werden", ns.Feud.MayKeep(ns.Store.Get(key)))
    ns.UI.ShowEnemy(key); W.tick(); W.settle()
    local P
    for _, f in ipairs(W.BM.frames) do if f.enemy and f.death then P = f end end
    local function marked()
      for _, fs in ipairs(P.enemy.info) do if fs:IsVisible() and fs:GetText() == L.ACT_KEEP then return true end end
      return false
    end
    J.check(code .. ": ohne Behalten keine Zeile am Plakat", not marked())
    ns.Feud.SetKeep(key, true); W.tick(); W.settle()
    ns.UI.ShowEnemy(key); W.tick(); W.settle()
    J.check(code .. ": mit Behalten steht es am Plakat", marked())
  end
end
J.done()
