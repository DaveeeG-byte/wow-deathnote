-- 1.2.1 nach der Abschluss-Jagd: eine Bindung, die die GUID der Liste nicht beweist (die Freundin listet den Spieler
-- nicht, ihr Hallo kommt nie), fragt nicht die ganze Sitzung lang alle 5 Minuten: hoechstens 3 Hallos je Sitzung.
-- Gegenprobe: eine bewiesene Bindung bekommt bei Listen-Ereignissen kein Hallo; wer online kommt, wird wie immer gefragt.
-- Aufruf: nice -n 15 luajit beleg_d03_hallo_unbewiesen.lua <Projektkopie>. Alle Namen erfunden.
local H = dofile((arg[0]:match("^(.*)/") or ".") .. "/_kopf_c.lua")

local function lage(bewiesen)
  local W = H.welt(); W.guids = true
  local b = W.client("Berta", "Senf", nil, { friends = {}, fullSender = true })
  local a = W.client("Anton", "Wurst", nil, { friends = { "Berta" }, fullSender = true })
  a.login(); b.login(); W.run(120)
  local db = a.env.DeathNoteDB.friends
  db.ties["Berta"] = db.ties["Berta"] or { chars = {} }
  local tie = db.ties["Berta"]
  tie.full, tie.hg = "Berta Senf", nil
  if bewiesen then tie.sure, tie.guid = true, W.guidOf(b) else tie.sure, tie.guid = nil, nil end
  local function hallos(ab)
    local n = 0
    for i = ab + 1, #W.sent do
      local m = W.sent[i]
      if m.sender == a and m.channel == "WHISPER" and m.text:match("^1\tH\t") then n = n + 1 end
    end
    return n
  end
  return W, a, b, hallos
end

H.lauf("(1) unbewiesen, jede Minute ein Listen-Ereignis, 2 h", function()
  local W, a, b, hallos = lage(false)
  local s0 = #W.sent
  for _ = 1, 120 do a.fire("FRIENDLIST_UPDATE"); W.run(60) end
  local n = hallos(s0)
  H.erwartet("mindestens ein Hallo (sie wird gefragt)", n >= 1, n)
  H.erwartet("hoechstens 3 Hallos in 2 h", n <= 3, n)
  -- sie geht offline und kommt wieder: wie immer ein Hallo
  W.setOnline(b, false); a.fire("FRIENDLIST_UPDATE"); W.run(60)
  local s1 = #W.sent
  W.setOnline(b, true); a.fire("FRIENDLIST_UPDATE"); W.run(120)
  H.erwartet("wieder online: gefragt wie immer", hallos(s1) >= 1, hallos(s1))
end)

H.lauf("(2) Gegenprobe bewiesen: kein Hallo durch Listen-Ereignisse", function()
  local W, a, _, hallos = lage(true)
  local s0 = #W.sent
  for _ = 1, 60 do a.fire("FRIENDLIST_UPDATE"); W.run(60) end
  H.erwartet("kein Hallo in 1 h", hallos(s0) == 0, hallos(s0))
end)

H.fertig()
