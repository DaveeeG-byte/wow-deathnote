-- 1.6.0 feud: "Which guilds kill you" in Wanted. The switch Players | Guilds at the bottom left, one head row per guild
-- (deaths, standing, members in the book, last seen), a click opens its members as the rows of the player list, the
-- word on the head row declares and ends a feud, the right page, the search; a crowd of sightings rebuilds the list at
-- most every 0.5 s. Names made up.
local WT = arg[1] or "."
local X = dofile((arg[0]:match("^(.*)/") or ".") .. "/_fe160.lua")
local J = X.J

for _, code in ipairs({ "deDE", "enUS" }) do
  local W = X.world(WT, code)
  local ns, L, F = W.ns, W.L, W.ns.F
  W.kill("Grimm", "Bart", "Die Schlaechter von Sturmwind", time() - 9000)
  W.kill("Grimm", "Bart", "Die Schlaechter von Sturmwind", time() - 8000)
  W.kill("Fies", "Ling", "Die Schlaechter von Sturmwind", time() - 7000)
  W.kill("Ohne", "Gilde", nil, time() - 6000)
  W.kill("Rot", "Hand", "Rote Hand", time() - 5000)
  W.open()
  local _, LP, RP, P = W.frames()
  J.check(code .. ": Umschalter sichtbar", LP.fdWanted and LP.fdWanted:IsVisible())
  W.click(W.find(L.VIEW_GUILDS))
  J.check(code .. ": Gildenseite an", ns.FeudUI.On())
  local rows = W.rows()
  J.check(code .. ": zwei Gildenzeilen", #rows == 2 and rows[1].item.fdHead and rows[2].item.fdHead, #rows)
  local r1 = rows[1]
  J.check(code .. ": erste Gilde die mit den meisten Toden", r1.name._text == "Die Schlaechter von Sturmwind", r1.name._text)
  J.check(code .. ": rechts im Buch", r1.right._text == F(L.FEUD_MEMBERS, { count = 2 }), r1.right._text)
  J.check(code .. ": Unterzeile Tode und Stand", (r1.sub._text or ""):find(F(L.FEUD_KILLED_YOU, { times = ns.Look.Times(3) }), 1, true)
    and (r1.sub._text or ""):find("0 : 3", 1, true), r1.sub._text)
  J.check(code .. ": Wort Fehde erklaeren", r1.take:IsVisible() and r1.take.text._text == L.FEUD_DECLARE)
  J.check(code .. ": Filter und Sortierung versteckt", not LP.filter:IsVisible() and not LP.sort:IsVisible())
  -- all closed: the guild's page on the right with the feud button
  J.check(code .. ": rechts die Gildenseite", RP.empty:IsVisible() and RP.empty.big._text == "Die Schlaechter von Sturmwind",
    RP.empty.big._text)
  -- open
  W.click(r1)
  rows = W.rows()
  J.check(code .. ": aufgeklappt: Kopf und zwei Mitglieder", #rows == 4 and rows[2].item.key == "Grimm-Bart"
    and rows[3].item.key == "Fies-Ling", #rows)
  J.check(code .. ": Mitglied wie in der Spielerliste (Rang)", rows[2].rank._text ~= nil and rows[2].rank._text ~= "")
  J.check(code .. ": rechts das Plakat des Mitglieds", P.enemy:IsVisible() and P.enemy.current and P.enemy.current.key == "Grimm-Bart")
  W.click(rows[3])
  J.check(code .. ": Klick auf Fies zeigt Fies", P.enemy.current and P.enemy.current.key == "Fies-Ling")
  -- declare feud by the word
  W.click(r1.take)
  J.check(code .. ": Fehde erklaert", ns.Feud.Is("Die Schlaechter von Sturmwind"))
  rows = W.rows()
  J.check(code .. ": Wort jetzt Fehde beenden", rows[1].take.text._text == L.FEUD_END, rows[1].take.text._text)
  W.click(rows[1].take)
  J.check(code .. ": Fehde beendet", not ns.Feud.Is("Die Schlaechter von Sturmwind"))
  -- search: a member's name opens his guild for the search only
  W.click(W.find(L.VIEW_GUILDS))
  ns.FeudUI.opened = {}
  LP.search:SetText("rot"); LP.search._scripts.OnTextChanged(LP.search, true); W.tick()
  rows = W.rows()
  J.check(code .. ": Suche nach Gilde oder Mitglied", #rows == 2 and rows[1].item.fdHead and rows[2].item.key == "Rot-Hand", #rows)
  -- Enter without a match adds nobody on the guild page
  LP.search:SetText("Niemandsgilde"); LP.search._scripts.OnTextChanged(LP.search, true); W.tick()
  LP.search._scripts.OnEnterPressed(LP.search); W.tick()
  J.check(code .. ": Enter auf der Gildenseite traegt niemanden ein", ns.Store.Find("Niemandsgilde") == nil)
  J.check(code .. ": Platzhalter nur Suchen", LP.search.ph._text ~= L.SEARCH_ADD, LP.search.ph._text)
  LP.search:SetText(""); LP.search._scripts.OnTextChanged(LP.search, true); W.tick()
  -- back to players
  W.click(W.find(L.VIEW_PLAYERS))
  J.check(code .. ": Spielerliste wie vorher", not ns.FeudUI.On() and #W.rows() >= 4 and LP.filter:IsVisible())
  local ok, err = W.errors()
  J.check(code .. ": keine Fehler", ok, err)
end

-- a crowd of sightings: at most one rebuild per 0.5 s (red before 1.6.0: one per sighting)
do
  local W = X.world(WT, "deDE")
  local ns = W.ns
  for i = 1, 20 do W.kill("Feind" .. i, "Ling", "Rote Hand", time() - 1000 - i) end
  W.open()
  local UX = W.kit().UX
  local before = UX.seenRefreshes + UX.autoRefreshes
  for i = 1, 20 do
    ns.Store.Seen("Feind" .. i .. "-Ling", {}, { t = time(), zone = "Z" }, true)
    W.tick(0.05)
  end
  W.tick(1)
  local n = UX.seenRefreshes + UX.autoRefreshes - before
  -- over 1 s of sightings: the first at once, then one per 0.5 s, the last one after the crowd: at most 4 (before: 20)
  J.check("20 Sichtungen in 1 s: hoechstens 4 Neuaufbauten", n <= 4 and n >= 2, n)
  -- a death still shows at once
  local b2 = UX.autoRefreshes
  W.kill("Neu", "Ling", nil, time())
  W.tick(0.01)
  J.check("ein neuer Tod: sofort", UX.autoRefreshes == b2 + 1, UX.autoRefreshes - b2)
end

J.done()
