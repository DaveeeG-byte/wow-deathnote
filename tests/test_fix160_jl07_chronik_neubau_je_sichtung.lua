-- Jagd Logik 160/07 (Last): GuildLog.lua erhoeht seine Version bei JEDEM GUILD_UPDATED. Das feuert Sync auch fuer
-- Aenderungen, die die Chronik nicht zeigt: eine Sichtung (Guild.OnUnit schreibt lastSeen, alle 5 s je Feind), eine
-- T/S von Gildies, Mitgliederliste. Bei offenem Buch fragt UX.UpdateTabs -> GuildLogUI.UpdateMarks -> GL.Unseen, und
-- GL.All baut die ganze Chronik neu (alle Taten aller Feinde aus Gilden- und Freundesbuch, sortiert).
-- Gemessen (Mock, volle Liste 400x20 Taten + Freundesbuch 400x20 = 16.000 Ereignisse): ein Neubau 27,8 ms (luajit),
-- 42,2 ms (luajit -joff); 20 Aenderungen 470 ms bzw. 816 ms. Sync drosselt auf 0,5 s, also bis 2 Neubauten je s in
-- einem belebten Gebiet nur fuer Sichtungen.
-- Erwartet: eine reine Sichtung macht die Chronik nicht ungueltig.
-- Lauf: cd ~/Projects/wow-deathnote-jagd && luajit <diese Datei> .   (Exit 1 = Fund belegt)
local DIR = ((arg and arg[1]) or "."):gsub("/+$", "")
package.path = DIR .. "/tests/?.lua;" .. package.path
local H = require("beleg_helfer")
local G = "Die Testgilde"

H.lauf("eine Sichtung eines Gilden-Feindes baut die Chronik nicht neu", function()
  local W = H.welt({ "GUILD_UPDATED" })
  local a = W.client("Anton", "Wurst", G)
  local b = W.client("Berta", "Senf", G)
  a.login(); b.login(); W.run(45)
  local key = H.tod(a, "Grimm", "Bart")
  W.run(5)
  local GL = b.ns.GuildLog
  local list = GL.All("all")
  H.erwartet("Vorbedingung: der Tod steht in Bertas Chronik", #list >= 1, #list)
  local v0 = GL.Version()
  b.ns.Guild.OnUnit(key, "nameplate1", "plate", nil)    -- Berta sieht Grimm (lastSeen, ein updated())
  W.run(1)
  H.erwartet("Vorbedingung: GUILD_UPDATED kam", H.zaehle(b, "GUILD_UPDATED") > 0)
  H.erwartet("Chronik bleibt im Cache (Version unveraendert)", GL.Version() == v0,
    ("Version %d -> %d, naechster Blick baut alles neu"):format(v0, GL.Version()))
end)

H.fertig()
