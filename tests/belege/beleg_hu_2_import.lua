-- Fund 2: Die Vorbelegung der Merker laeuft beim ersten Login (leeres Buch). Wer danach sein gesichertes Buch
-- einliest (neuer Rechner, neuer Account), bekommt "erste Rache" bei einem Taeter, an dem laengst Rache steht, und
-- den Stempel "zehnmal derselbe Name" beim ersten eigenen Tod durch einen Taeter, der mit 9 Toden eingelesen wurde.
local here = arg[0]:match("^(.*)/[^/]+$") or "."
package.path = here .. "/?.lua;" .. package.path
local H = require("_kopf_hu")
local src = H.welt("deDE")
local k = H.kill(src, "Fremd", "Feind"); H.away()
src.Store.AddRevenge(k); H.away()
src.Store.AddRevenge(k); H.away()
local k9
for _ = 1, 9 do k9 = H.kill(src, "Viel", "Toeter"); H.away() end
local text = src.Store.Export()

local db = {}
local ns = H.welt("deDE", { db = db })
local T = H.SRC.deDE
H.check("Vorbedingung: Merker schon beim Login angelegt (leer)", db.humor ~= nil and next(db.humor.m) == nil)
local ok = ns.Store.Import(text)
H.settle()
H.check("Vorbedingung: Einlesen klappt, Rache 2 und 9 Tode stehen im Buch", ok and ns.Store.Get(k).revenge == 2 and ns.Store.Get(k9).kills == 9)
H.check("Einlesen merkt vor: es gab schon Rache", db.humor.m.revenge1 ~= nil, "m.revenge1 = nil")
ns.Store.AddRevenge(k); H.settle()
local s = H.stampText()
H.check("dritte Rache am eingelesenen Taeter: kein Stempel 'erste Rache'", s ~= T.STAMP.revenge1 and s ~= T.STAMP.nr1,
  "revenge=" .. ns.Store.Get(k).revenge)
H.away()
H.kill(ns, "Viel", "Toeter")
H.check("erster eigener Tod durch den eingelesenen Taeter: kein Stempel 'zehnmal derselbe'", H.stampText() ~= T.STAMP.regular,
  "eigene Tode in diesem Buch: " .. #db.deaths .. ", kills=" .. ns.Store.Get(k9).kills)
H.ende("beleg_hu_2_import")
