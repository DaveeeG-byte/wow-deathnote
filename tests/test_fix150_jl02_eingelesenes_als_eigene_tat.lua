-- Jagd Logik 150/02: "Zeigen" behandelt eingelesene Daten (Store.Import, e.imported / d.imported, im Code "foreign
-- data: never shared in the guild") als eigene Taten. Share.Adopted nennt imported zwar als uebernommen, Share.Offer
-- fragt aber zuerst OwnDeeds (e.kills > 0) und laesst den Eintrag durch; LastOwnDeed nimmt die eingelesene Tat samt Ort,
-- die Woche zaehlt eingelesene Tode als "Meistgesuchter". Die Leitung (Sync ownKills) laesst d.imported bewusst weg.
-- Erwartet: ein nur eingelesener Eintrag bietet kein "Zeigen" (wie Uebernommenes), die Woche zaehlt nur eigene Tode.
local DIR = ((arg and arg[1]) or "."):gsub("/+$", "")
arg[0] = DIR .. "/tests/jagd150.lua"
package.path = DIR .. "/tests/?.lua;" .. package.path
local M = require("mock_wow")
local test, eq, ok, no = M.test, M.eq, M.ok, M.no

local FILES = {}
for _, f in ipairs(M.FILES) do FILES[#FILES + 1] = f end
FILES[#FILES + 1] = "Share.lua"

local function E(key, kills, surname)
  return table.concat({ "E", key, "wanted", "0", tostring(kills), "0", "0", "", "", "", "0", "ROGUE", "", "40", "", "",
    surname, "", "", "0", "0" }, "|")
end
local function D(key, t, zone)
  -- D|key|t|sure|source|zone|subzone|mapID|x|y|me|myLevel|spell|role
  return table.concat({ "D", key, tostring(t), "1", "recap", zone, "", "1434", "40", "30", "Fremder Spieler", "40", "", "kill" }, "|")
end

test("JL150-02a: ein nur eingelesener Eintrag wird nicht als eigener WANTED gezeigt", function()
  local ns = M.Load({ files = M.Files(FILES) })
  local S, Sh = ns.Store, ns.Share
  local t = time() - 3600
  local okI, a = S.Import("DEATHNOTE:1\n" .. E("Fremd-Ling", 3, "Ling") .. "\n" .. D("Fremd-Ling", t, "Fremdland"))
  ok(okI, tostring(a)); eq(a, 1)
  local e = S.Get("Fremd-Ling")
  ok(e and e.imported, "eingelesen")
  ok(Sh.Adopted(e), "Share selbst nennt ihn uebernommen")
  local line = Sh.LineFor(e)
  eq(line, nil, "Zeile fuer eingelesene Daten: " .. tostring(line))
end)

test("JL150-02b: die Woche zaehlt keinen eingelesenen Tod als Meistgesuchten", function()
  local ns = M.Load({ files = M.Files(FILES) })
  local S, Sh = ns.Store, ns.Share
  local t = time() - 3600
  S.Import("DEATHNOTE:1\n" .. E("Fremd-Ling", 3, "Ling") .. "\n" .. D("Fremd-Ling", t, "Fremdland"))
  local w = Sh.Week(time())
  eq(w.top, nil, "Meistgesuchter aus eingelesenen Daten: " .. tostring(w.top and w.top.key))
end)

M.done("jl150-02 eingelesen")
