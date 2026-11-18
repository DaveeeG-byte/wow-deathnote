-- Jagd Logik 160/06: Der Verfall (Feud.MayKeep) prueft nur e.manual, Taten, Rache, Kopfgeld, Listen, Fehde und keep.
-- Was der Spieler selbst an einen Verdacht geschrieben oder gesetzt hat, zaehlt nicht: eine Notiz (Store.SetNote) und
-- ein von Hand gesetzter Stand (Store.SetStatus "wanted" oder "pardoned") halten den Eintrag nicht. Nach 30
-- Spieltagen liegt er still im Archiv; wer ihn vergeben hatte, sieht ihn beim naechsten Angriff als frischen Verdacht.
-- Erwartet: eigene Notiz oder eigener Stand gelten wie "von Hand" (bleibt im Buch).
-- Lauf: cd ~/Projects/wow-deathnote-jagd && luajit <diese Datei> .   (Exit 1 = Fund belegt)
local DIR = ((arg and arg[1]) or "."):gsub("/+$", "")
arg[0] = DIR .. "/tests/jagd160_06.lua"
package.path = DIR .. "/tests/?.lua;" .. package.path
local M = require("mock_wow")
local test, ok = M.test, M.ok

local function suspect(S, name)
  return S.ApplyKill({ name = name, surname = "Ling", guid = "Player-93-" .. name }, { t = time() - 50, zone = "Z" }, false)
end

local cases = {
  { "Notiz", function(S) S.SetNote("Notiz-Ling", "hat mich am Steg ueberfallen, Druide") end },
  { "Gesucht", function(S) S.SetStatus("Gesucht-Ling", "wanted") end },
  { "Vergeben", function(S) S.SetStatus("Vergeben-Ling", "pardoned") end },
}
for _, c in ipairs(cases) do
  test("JL160-06: Verdacht, von Hand: " .. c[1] .. ", nach 31 Spieltagen noch im Buch", function()
    local ns = M.Load()
    local S = ns.Store
    suspect(S, c[1])
    c[2](S)
    for _ = 1, 31 do M.epoch = M.epoch + 86400; S.Init() end
    ok(S.Get(c[1] .. "-Ling"), c[1] .. ": im Buch (liegt im Archiv: " .. tostring(S.DB().expired and S.DB().expired[c[1] .. "-Ling"] ~= nil) .. ")")
  end)
end

M.done("jl160-06 verfall notiz status")
