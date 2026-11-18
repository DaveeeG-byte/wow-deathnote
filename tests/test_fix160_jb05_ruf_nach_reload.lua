-- Fixer 2 1.6.0 (jb05): who answered with the book (peers) and whose hello proved the list's GUID (proven) are kept
-- over a /reload of the same char within HELLO_PER_SENDER seconds, so the help call reaches bound friends and is taken
-- by them right after it (a friend answers a hello of the same char only every 5 minutes). Another char inherits
-- nothing, an old session is not taken, the kept table is capped and gone after the start, and the proof stays
-- strict: a hello with another GUID takes it back. Names made up.
local DIR = ((arg and arg[1]) or "."):gsub("/+$", "")
package.path = DIR .. "/tests/?.lua;" .. package.path
local H = require("beleg_helfer")

local function pair(guids)
  local W = H.welt({ "HELP_CALL" })
  _G.C_Map.GetMapInfo = function() return { name = "Zone", mapType = 3, parentMapID = 13 } end
  W.guids = guids
  local a = W.client("Anton", "Wurst", nil, { friends = { "Berta" } })
  local b = W.client("Berta", "Senf", nil, { friends = { "Anton" } })
  a.login(); b.login(); W.run(100)
  return W, a, b
end
local function call(W, from, to)
  local n0 = H.zaehle(to, "HELP_CALL")
  local ok, why = from.ns.Call.Send()
  W.run(2)
  return ok == true and H.zaehle(to, "HELP_CALL") - n0 == 1, tostring(ok) .. " " .. tostring(why)
end

H.lauf("/reload nach 100 s: der Ruf geht in beide Richtungen sofort", function()
  for _, guids in ipairs({ false, true }) do
    for _, who in ipairs({ "a", "b" }) do
      local W, a, b = pair(guids)
      if who == "a" then a = H.relog(W, a); a.login() else b = H.relog(W, b); b.login() end
      W.run(20)
      local tag = ("GUID %s, neu geladen %s"):format(tostring(guids), who)
      local ok1, d1 = call(W, b, a)
      H.erwartet("Bertas Ruf kommt an (" .. tag .. ")", ok1, d1)
      W.run(130)
      local ok2, d2 = call(W, a, b)
      H.erwartet("Antons Ruf kommt an (" .. tag .. ")", ok2, d2)
      H.erwartet("die gemerkte Sitzung ist nach dem Start weg (" .. tag .. ")",
        (who == "a" and a or b).ns.Store.DB().friends.session == nil)
    end
  end
end)

H.lauf("Eine alte Sitzung (älter als 5 Minuten) und ein anderer Char erben nichts", function()
  local W, a, b = pair(true)
  a.ns.Friends.SaveSession(time() - 400)
  a.ns.Friends.RestoreSession(time())
  H.erwartet("alte Sitzung: nichts übernommen", (a.ns.Friends.stats.restored or 0) == 0)
  local fdb = a.ns.Store.DB().friends
  a.ns.Friends.SaveSession(time())
  fdb.session.char = "Anderer Char"
  a.ns.Friends.RestoreSession(time())
  H.erwartet("anderer Char: nichts übernommen", (a.ns.Friends.stats.restored or 0) == 0)
  H.erwartet("und die Tabelle ist weg", fdb.session == nil)
end)

H.lauf("Deckel: höchstens PEERS_MAX Namen je Liste", function()
  local W, a, b = pair(false)
  local fdb = a.ns.Store.DB().friends
  local p = {}
  for i = 1, 50 do p["Freund" .. i] = true end
  fdb.session = { at = time(), char = "Anton Wurst", peers = p, proven = p }
  a.ns.Friends.RestoreSession(time())
  a.ns.Friends.SaveSession(time())
  local n, m = 0, 0
  for _ in pairs(fdb.session.peers) do n = n + 1 end
  for _ in pairs(fdb.session.proven) do m = m + 1 end
  H.erwartet("gemerkt höchstens 10 Freunde mit dem Buch", n <= 10, n)
  H.erwartet("gemerkt höchstens 10 Beweise", m <= 10, m)
end)

H.lauf("Die Prüfung bleibt streng: nach dem /reload nimmt ein Hallo mit fremder GUID den Beweis zurück", function()
  local W, a, b = pair(true)
  a = H.relog(W, a); a.login()
  W.run(5)
  H.erwartet("Berta gilt nach dem /reload", a.ns.Friends.Vouch("Berta") ~= nil)
  H.fluestern(a, a.ns.Guild.Proto.EncodeHello(time() - 60, "1.6.0", "Player-93-FREMD"), "Berta")
  W.run(1)
  H.erwartet("Hallo mit fremder GUID: Berta gilt nicht mehr", a.ns.Friends.Vouch("Berta") == nil)
end)

H.fertig()
