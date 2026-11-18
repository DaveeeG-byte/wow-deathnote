-- 1.5.0 fixer: "Show" after the hunt (ju01, ju02, jl02). What goes into a chat or the Discord block uses the plain
-- words of the language, never the cover's; the guest card's head follows the kind of the line, a week line opens the
-- card "<sender>'s week" (even when the name is in my book), "Copy" only for somebody wanted. Names made up.
local WT = arg[1] or "."
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_ju.lua")

-- the trade cover: Discord block and hit list line without the cover's words
local W = J.world(WT, "deDE", { ui = { theme = "trade" } })
local ns, L = W.ns, W.ns.L
J.check("Einband trade aktiv, Plakatkopf KUNDE", L.POSTER_HEAD == "KUNDE", L.POSTER_HEAD)
local key = ns.Store.ApplyKill({ name = "Grimm", surname = "Bart", class = "ROGUE", level = 40 },
  { t = time() - 60, zone = "Schlingendorntal", source = "recap" }, true)
local dc = ns.Share.Discord(ns.Store.Get(key), "own") or ""
J.check("Discord: WANTED statt KUNDE", dc:find("WANTED", 1, true) ~= nil and not dc:find("KUNDE", 1, true), dc)
local hunt = ns.Share.HuntLine({ key = "Fies-Ling", name = "Fies", surname = "Ling", n = 2 }) or ""
J.check("Abschussliste: ABSCHUSSLISTE statt AUFTRAGSLAGE", hunt:find("] ABSCHUSSLISTE", 1, true) ~= nil, hunt)
J.check("Share.Word nimmt das Wort der Sprache", ns.Share.Word("POSTER_HEAD") == "WANTED", ns.Share.Word("POSTER_HEAD"))
-- the receiver in the trade cover knows a plain WANTED line (and shows his own cover's head)
local rec = ns.Share.Parse("[Revenge Book: Fremd Ling] WANTED · Stand 1 : 4")
J.check("Empfaenger im Einband erkennt WANTED", rec and rec.kind == "wanted", rec and rec.kind)
J.check("Kopf im Einband des Empfaengers", ns.ShareUI.GuestHead(rec) == "KUNDE", ns.ShareUI.GuestHead(rec))

-- the black book: guest cards by kind
W = J.world(WT, "deDE")
ns, L = W.ns, W.ns.L
local Sh, SU, F = ns.Share, ns.ShareUI, ns.F
local function open(line)
  local out = Sh.Linkify(line, "Bertram-Forever")
  local id = out and out:match("|Haddon:DeathNote:share:(%d+)|h")
  SU.OnLink("addon:DeathNote:share:" .. tostring(id)); W.settle()
  return SU.GuestFrame()
end
local gp = open(Sh.Build("Odric Thornbush", { L.SHARE_KIND_PARDONED, F(L.STAND_LINE, { score = "3 : 2" }) }))
J.check("Begnadigt: Kopf BEGNADIGT", gp.head:GetText() == L.SHARE_KIND_PARDONED, gp.head:GetText())
J.check("Begnadigt: kein Uebernehmen", not gp.add:IsShown())
J.check("Begnadigt: Kopfwort nicht noch einmal als Zeile", gp.lines[1]:GetText() ~= L.SHARE_KIND_PARDONED, gp.lines[1]:GetText())
J.check("Begnadigt: Uebernehmen geht auch nicht von Hand", SU.Adopt(gp.rec) == nil)
gp = open(Sh.Build("Odric Thornbush", { L.POSTER_HEAD, F(L.STAND_LINE, { score = "3 : 2" }) }))
J.check("Gesucht: Kopf WANTED, Uebernehmen da", gp.head:GetText() == L.POSTER_HEAD and gp.add:IsShown(), gp.head:GetText())
gp = open(Sh.Build("Odric Thornbush", { "GESUCHT", "Stand 3 : 2" }))
J.check("fremde Sprache: Kopf ist das Wort des Absenders, Uebernehmen da", gp.head:GetText() == "GESUCHT" and gp.add:IsShown(),
  gp.head:GetText())
-- a week line whose name is in my own book: still the week card, not my poster
local k2 = ns.Store.ApplyKill({ name = "Odric", surname = "Thornbush", class = "MAGE", level = 40 },
  { t = time() - 60, zone = "Ödland", source = "recap" }, true)
J.check("Odric steht in meinem Buch", ns.Store.Get(k2) ~= nil)
local week = Sh.Build("Odric Thornbush", { L.SHARE_WEEK_HEAD, F(L.SHARE_WEEK_TOP, { times = "3×" }),
  F(L.SHARE_WEEK_REVENGE, { count = 1 }) })
gp = open(week)
J.check("Woche: Karte 'Woche von Bertram'", gp:IsShown() and gp.head:GetText() == F(L.SHARE_GUEST_WEEK, { name = "Bertram" }),
  gp.head:GetText())
J.check("Woche: kein Uebernehmen", not gp.add:IsShown())
J.check("Woche: erste Zeile ist die Woche, nicht MEINE WOCHE", gp.lines[1]:GetText() == F(L.SHARE_WEEK_TOP, { times = "3×" }),
  gp.lines[1]:GetText())
J.done()
