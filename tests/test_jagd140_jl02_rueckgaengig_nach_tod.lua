-- Jagd Logik 02: "Rueckgaengig" nach "Buch einlesen" (Store.UndoImport) wirft Tode weg, die NACH dem Einlesen gebucht
-- wurden. Erwartet: Rueckgaengig nimmt nur zurueck, was das Einlesen tat. Ein Kill, der danach an einem eingelesenen
-- (neuen) oder zusammengefuehrten Eintrag gebucht wurde, bleibt (Eintrag bleibt, kills zaehlt ihn, die Tat bleibt).
-- Heute: UndoImport streicht neue Eintraege ohne Pruefung (nur e.imported) und setzt zusammengefuehrte auf den
-- Schnappschuss von vorher zurueck, kills und Tat des neuen Todes sind weg, die Todeszeile im Journal zeigt ins Leere.
-- Der Knopf "Rueckgaengig" bleibt im Blatt "Buch einlesen" stehen, lastImport lebt bis zum naechsten Einlesen/Reload.
package.path = "./tests/?.lua;" .. package.path
local M = require("mock_wow")
local test, eq, ok = M.test, M.eq, M.ok

local function E(key, kills, surname, guid)
  -- E|key|status|manual|kills|suspected|revenge|firstKill|lastKill|lastRevenge|sightings|class|race|level|guild|faction|surname|guid|note|assists|attacks
  return table.concat({ "E", key, "wanted", "0", tostring(kills), "0", "0", "", "", "", "0", "ROGUE", "", "40", "", "",
    surname, guid, "", "0", "0" }, "|")
end

test("JL02a: Kill an einem zusammengefuehrten Eintrag nach dem Einlesen ueberlebt Rueckgaengig", function()
  local ns = M.Load()
  local S = ns.Store
  local t0 = time() - 5000
  S.ApplyKill({ name = "Grimm", surname = "Bart", guid = "Player-93-Grimm" }, { t = t0, zone = "Z", source = "recap" }, true)
  eq(S.Get("Grimm-Bart").kills, 1)
  local okI, a, m = S.Import("DEATHNOTE:1\n" .. E("Grimm-Bart", 3, "Bart", "Player-93-Grimm"))
  ok(okI); eq(m, 1)
  eq(S.Get("Grimm-Bart").kills, 3)
  -- danach toetet er mich wirklich
  M.Advance(60)
  S.ApplyKill({ name = "Grimm", surname = "Bart", guid = "Player-93-Grimm" }, { t = time(), zone = "Z", source = "recap" }, true)
  local after = S.Get("Grimm-Bart").kills
  local deeds = #S.Get("Grimm-Bart").deaths
  S.UndoImport()
  local e = S.Get("Grimm-Bart")
  ok(e, "Eintrag bleibt")
  -- vorher 1 eigener Kill + 1 neuer = 2 eigene; mindestens der neue darf nicht verschwinden
  ok(e.kills >= 2, "der Kill nach dem Einlesen bleibt (kills=" .. tostring(e.kills) .. ", vor Rueckgaengig " .. after .. ")")
  eq(#e.deaths, deeds, "die Tat des neuen Todes bleibt")
end)

test("JL02b: ein eingelesener NEUER Eintrag, der mich danach toetet, wird von Rueckgaengig nicht gestrichen", function()
  local ns = M.Load()
  local S = ns.Store
  local okI, a = S.Import("DEATHNOTE:1\n" .. E("Fies-Ling", 2, "Ling", "Player-93-Fies"))
  ok(okI); eq(a, 1)
  M.Advance(60)
  S.ApplyKill({ name = "Fies", surname = "Ling", guid = "Player-93-Fies" }, { t = time(), zone = "Z", source = "recap" }, true)
  ok(S.Get("Fies-Ling").kills >= 1)
  S.UndoImport()
  ok(S.Get("Fies-Ling"), "Eintrag mit eigenem Kill bleibt")
end)

M.done("jl02 undo nach tod")
