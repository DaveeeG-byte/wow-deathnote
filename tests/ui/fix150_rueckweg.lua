-- 1.5.0 fixer: the way back from the map (U12) and the switch's legend (U4). A place clicked in the book closes the
-- book; closing the map without a pin's click opens it again, a pin's click opens the book once (on the scene). The
-- switch's tooltip explains the pins: one line per kind, each with its own picture, and the bundle. Names made up.
local WT = arg[1] or "."
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_jukarte.lua")
local W = J.map(WT, { mapID = 1434 })
local ns, G = W.ns, W.G
local Map = ns.SceneMap
W.death("Grimm", 40, 40)
ns.UI.Open(); W.settle()
local book = rawget(G, "DeathNoteFrame")
J.check("Buch da", book ~= nil)

-- count how often the book is opened
local shows = 0
local origShow = book.Show
book.Show = function(self, ...) shows = shows + 1; return origShow(self, ...) end

-- 1) from the book to the map, the map closed (Esc): the book is back
book:Show(); W.settle(); shows = 0
local r = Map.Show({ mapID = 1434, x = 40, y = 40, zone = "Schlingendorntal" })
W.settle()
J.check("Klick im Buch: Karte offen", r == "shown" and W.wm:IsShown(), r)
J.check("Klick im Buch: Buch weicht der Karte", not book:IsShown())
G.HideUIPanel(W.wm); W.settle()
J.check("Karte zu ohne Nadelklick: Buch wieder offen", book:IsShown(), shows)
J.check("Buch genau einmal geoeffnet", shows == 1, shows)

-- 2) from the book to the map, back through a pin's click: the book opens once, on the scene
shows = 0
local opened = 0
local origCase = ns.UI.ShowCase
ns.UI.ShowCase = function(...) opened = opened + 1; book:Show() end
r = Map.Show({ mapID = 1434, x = 40, y = 40, zone = "Schlingendorntal" })
W.settle()
J.check("zweiter Weg: Karte offen", r == "shown" and not book:IsShown(), r)
local pins = W.pins()
J.check("eine Nadel", #pins == 1, #pins)
Map.Go(pins[1].data.items[1]); W.settle()
J.check("Nadelklick: Karte zu", not W.wm:IsShown())
J.check("Nadelklick: Buch auf dem Tatort", opened == 1 and book:IsShown(), opened)
J.check("Nadelklick: Buch nur einmal geoeffnet (nicht noch einmal beim Schliessen)", shows == 1, shows)
ns.UI.ShowCase = origCase

-- 3) the map opened by itself (not from the book): closing it opens no book
book:Hide(); shows = 0
G.ShowUIPanel(W.wm); W.settle()
G.HideUIPanel(W.wm); W.settle()
J.check("Karte von selbst: Schliessen oeffnet kein Buch", shows == 0 and not book:IsShown(), shows)

-- 4) the legend: four kinds of pin with their own pictures, then the bundle
local leg = Map.Legend and Map.Legend() or {}
-- 1.6.0 call: two more kinds (help call, sighting) before the bundle
J.check("Legende: 7 Zeilen", #leg == 7, #leg)
local want = { "scene_death", "scene_kill", "scene_guild", "scene_friend", "scene_guild", "scene_friend", "scene_badge" }
local seen = {}
for i, w in ipairs(want) do
  local l = leg[i] or ""
  J.check("Legende Zeile " .. i .. " zeigt " .. w, l:find(w, 1, true) ~= nil and l:find("|T", 1, true) == 1, l)
  local tex = l:match("|T([^:|]+)")
  J.check("Legende Zeile " .. i .. ": Bild gibt es", tex and io.open(WT .. "/DeathNote/Media/" .. (tex:match("([^\\/]+)$") or "x"), "rb") ~= nil, tex)
  local text = l:match("|t%s*(.+)$")
  J.check("Legende Zeile " .. i .. ": Text ohne Schluessel", text and #text > 2 and not text:find("^SCENE_"), text)
  if text then seen[text] = true end
end
local n = 0
for _ in pairs(seen) do n = n + 1 end
J.check("Legende: sieben verschiedene Texte", n == 7, n)
-- the switch's tooltip carries the legend
local btn = Map.Button()
local tipText = ""
if btn and btn._scripts and btn._scripts.OnEnter then
  btn._scripts.OnEnter(btn)
  local tip = G.GameTooltip
  tipText = tostring(tip and tip._text or "")
  if tip and tip._lines then for _, l in ipairs(tip._lines) do tipText = tipText .. "\n" .. tostring(l.text or l[1] or l) end end
end
J.check("Schalter-Tooltip traegt die Legende", tipText:find(ns.L.SCENE_LEG_BUNDLE or "\1", 1, true) ~= nil, tipText)
J.done()
