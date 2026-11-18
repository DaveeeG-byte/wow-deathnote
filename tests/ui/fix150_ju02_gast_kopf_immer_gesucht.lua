-- ju02: Das Gast-Plakat zeigt im Kopf immer POSTER_HEAD (WANTED bzw. das Themenwort), auch wenn die Zeile einen
-- Begnadigten (BEGNADIGT), eine Rache (VERGELTUNG), ein Gildenbuch oder die Wochenbilanz des Absenders (MEINE WOCHE)
-- zeigt. Bei der Woche stehen die Zahlen des Absenders (Rache genommen, offene Rechnungen) wie Angaben ueber den
-- Gezeigten da, und "Uebernehmen" traegt ihn als Gesuchten ein. Erwartet: Kopf aus dem ersten Teil der Zeile (oder
-- neutral), Woche ohne Gast-Plakat bzw. als Woche des Absenders beschriftet. Namen erfunden.
local WT = arg[1] or "."
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_ju.lua")
local W = J.world(WT, "deDE")
local ns, L, F = W.ns, W.ns.L, W.ns.F
local Sh, SU = ns.Share, ns.ShareUI
local function guestOf(line)
  local out = Sh.Linkify(line, "Bertram-Forever")
  local id = out and out:match("|Haddon:DeathNote:share:(%d+)|h")
  SU.OnLink("addon:DeathNote:share:" .. tostring(id)); W.settle()
  local GP = SU.GuestFrame()
  return GP and GP:IsShown() and GP.head:GetText() or nil, GP
end
local head = guestOf(Sh.Build("Odric Thornbush", { L.SHARE_KIND_PARDONED, F(L.STAND_LINE, { score = "3 : 2" }) }))
J.check("Begnadigter: Kopf sagt nicht " .. L.POSTER_HEAD, head ~= nil and head ~= L.POSTER_HEAD, head)
head = guestOf(Sh.Build("Odric Thornbush", { L.BANNER_REVENGE, F(L.SHARE_REVENGE_NOW, { score = "3 : 2" }) }))
J.check("Vergeltung: Kopf sagt nicht " .. L.POSTER_HEAD, head ~= nil and head ~= L.POSTER_HEAD, head)
local week = Sh.Build("Odric Thornbush", { L.SHARE_WEEK_HEAD, F(L.SHARE_WEEK_TOP, { times = "3×" }),
  F(L.SHARE_WEEK_REVENGE, { count = 1 }), F(L.SHARE_WEEK_DEBTS, { count = 4 }) })
head = guestOf(week)
J.check("Wochenzeile: kein Gast-Plakat WANTED mit den Wochenzahlen des Absenders", head ~= L.POSTER_HEAD, head)
J.done()
