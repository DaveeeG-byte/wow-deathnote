-- Fixer 1.6.0 (ju01, ju02): the first impression of a new player. After a death by a wolf the book opens the Death Log;
-- the empty Wanted says in one sentence that such deaths are in the Death Log; the view Players says "no death by a
-- player yet" and names the view All. A book with a wanted name stays on Wanted, a book without any death says nothing
-- about the Death Log. Names made up.
local WT = arg[1] or "."
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_ju160.lua")
for _, code in ipairs({ "deDE", "enUS", "ruRU", "zhTW" }) do
  local W = J.world(WT, code)
  local ns, L, F = W.ns, W.ns.L, W.ns.F
  local sentence = F(L.EMPTY_WANTED_FATES, { log = L.TAB_DEATHLOG })
  -- no death at all: Wanted, without the sentence
  W.open()
  J.check(code .. ": ohne Tod: Gesucht", ns.UI.JK.state.filter == "wanted")
  J.check(code .. ": ohne Tod: kein Satz zum Todesjournal", W.visible(sentence) == nil)
  W.ns:Fire("TOGGLE_UI"); W.tick(1)
  W.creature("Grauer Wolf", 299, "Biss")
  W.open()
  J.check(code .. ": nach dem Wolf: das Buch schlaegt das Todesjournal auf", ns.UI.JK.state.filter == "journal",
    ns.UI.JK.state.filter)
  ns.UI.SetFilter("wanted"); W.settle()
  J.check(code .. ": leeres Gesucht nennt das Todesjournal", W.visible(sentence) ~= nil, sentence)
  ns.UI.SetFilter("journal"); W.settle()
  ns.FatesUI.SetMode("players"); W.settle()
  J.check(code .. ": Ansicht Spieler: kein Tod durch Spieler", W.visible(L.EMPTY_JPLAYERS_HEAD) ~= nil
    and W.visible(L.EMPTY_JOURNAL_HEAD) == nil, L.EMPTY_JPLAYERS_HEAD)
  J.check(code .. ": und nennt die Ansicht Alles", W.visible(F(L.EMPTY_JPLAYERS_SUB, { all = L.FATE_VIEW_ALL })) ~= nil)
  ns.FatesUI.SetMode("all"); W.settle()
  -- a wanted name: the book stays where the player was / on Wanted
  ns.UI.SetFilter("wanted"); W.settle()
  W.ns:Fire("TOGGLE_UI"); W.tick(1)
  ns.Store.ApplyKill({ name = "Velka", surname = "Thornheart", class = "WARLOCK", level = 58 },
    { t = time() - 60, zone = "Schlingendorntal", source = "recap" }, true)
  W.open()
  J.check(code .. ": mit Gesuchtem bleibt Gesucht", ns.UI.JK.state.filter == "wanted", ns.UI.JK.state.filter)
end
J.done()
