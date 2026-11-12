-- Findings in data and free text:
-- (a) P.SanitizeHunts only checks "is a table" for lastSeen: a mangled lastSeen.t throws a Lua error
--     on every rebuild of the hit list (and when a sighting arrives).
-- (b) P.CleanReason lets broken UTF-8 through (single lead or continuation bytes).
-- (c) Clock set back: the own call "from the future" silently disappears at login, the others
--     keep it and nobody can call it off any more.
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local H = require("beleg_helfer")
local M = H.M
local G = "Die Testgilde"

local function gueltig(s)
  local i, n = 1, #s
  while i <= n do
    local b = s:byte(i)
    local need = b < 0x80 and 0 or (b >= 0xC2 and b < 0xE0) and 1 or (b >= 0xE0 and b < 0xF0) and 2
      or (b >= 0xF0 and b < 0xF5) and 3 or -1
    if need < 0 or i + need > n then return false end
    for k = 1, need do local c = s:byte(i + k); if c < 0x80 or c > 0xBF then return false end end
    i = i + need + 1
  end
  return true
end

for _, garbage in ipairs({ "gestern", true, {} }) do
  H.lauf("lastSeen.t = " .. type(garbage), function()
    local W = H.welt()
    local a = W.client("Anton", "Wurst", G, { friends = { "Berta" } })
    a.login(); W.run(30)
    a.ns.Guild.Release("Opfer-Lamm", { to = "all" })
    a.ns.Guild.Release("Zwei-Lamm", { to = "all" })
    a.fire("PLAYER_LOGOUT")
    local db = H.tiefe_kopie(a.env.DeathNoteDB)
    db.friends.hunts["Opfer-Lamm"].lastSeen = { t = garbage, zone = "Z", by = "Anton" }
    db.guild.lists[G].hunts["Opfer-Lamm"].lastSeen = { t = garbage, zone = "Z", by = "Anton" }
    local W2 = H.welt()
    local a2 = W2.client("Anton", "Wurst", G, { friends = { "Berta" }, db = db })
    a2.login(); W2.run(30)
    local ok1, rows = pcall(a2.ns.Guild.Hunts, "all")
    H.erwartet("Abschussliste baut sich trotz kaputtem lastSeen.t (" .. type(garbage) .. ")", ok1 and #rows == 2, rows)
    a2.ns.Store.Setting("guild.sightings", true)
    local P = a2.ns.Guild.Proto
    H.gilde(a2, P.EncodeSight("Opfer-Lamm", "Zone", time()), "Dora-Forever")
    H.erwartet("Sichtung auf kaputtes lastSeen.t wirft nicht", #M.errors == 0, M.errors[1])
    M.errors = {}
  end)
end

H.lauf("Grund mit kaputtem UTF-8", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", G)
  a.login(); W.run(30)
  local P = a.ns.Guild.Proto
  for _, raw in ipairs({ "abc\195", "\195\164\195", "\128\129abc", "\255\254", "ok \240\159" }) do
    local r = P.CleanReason(raw)
    H.erwartet(("CleanReason liefert gueltiges UTF-8 fuer %q"):format(raw), gueltig(r), ("%q"):format(r))
  end
  -- over the wire: a guildmate sends the reason raw
  local msg = "1\tJ\tOpfer-Lamm\t\t\t0\t" .. time() .. "\tDora Dick\tjagt ihn \195"
  H.gilde(a, msg, "Dora-Forever")
  local h = a.ns.Guild.Hunt("Opfer-Lamm", "guild")
  H.erwartet("empfangener Grund ist gueltiges UTF-8", h and gueltig(h.why or ""), h and ("%q"):format(tostring(h.why)))
end)

H.lauf("Uhr zurueckgestellt", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", G)
  local b = W.client("Berta", "Senf", G)
  a.login(); b.login(); W.run(40)
  a.ns.Guild.Release("Opfer-Lamm", { to = "guild" }); W.run(5)
  H.erwartet("Vorbedingung: Berta hat die Freigabe", b.ns.Guild.Hunt("Opfer-Lamm", "guild") ~= nil)
  a.fire("PLAYER_LOGOUT")
  local db = H.tiefe_kopie(a.env.DeathNoteDB)
  M.epoch = M.epoch - 3600            -- Anton's computer sets the clock back one hour
  a.loggedIn = false
  local a2 = W.client("Anton", "Wurst", G, { db = db })
  a2.login(); W.run(40)
  local mine = a2.ns.Guild.Released("Opfer-Lamm")
  local called = a2.ns.Guild.CallOff("Opfer-Lamm")
  W.run(5)
  H.erwartet("eigene Freigabe bleibt nach dem Uhr-Sprung abblasbar (oder wird den anderen als abgeblasen gemeldet)",
    (mine and called) or b.ns.Guild.Hunt("Opfer-Lamm", "guild") == nil,
    "bei Anton weg (Released=" .. tostring(mine) .. "), bei Berta steht sie weiter")
end)

H.fertig()
