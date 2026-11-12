-- Field 3: message Z (snapshot of the calls at the end of an answer).
-- (1) Second device or lost SavedVariables: the same character answers with "Z 0" and thereby deletes his
--     calls at everyone who is asking. Back on the first device they exist for him, not for the others.
-- (2) Namesakes in the guild, senders arrive by first name only (so in the mock, open in game): the Z of
--     one deletes the calls of the other (a Z deletes what the sender did not post himself).
-- (3) Friend becomes guildmate: a call "to all" stands in both of his books; it is called off only on
--     GUILD, neither A nor Z ever takes back the copy in the friends' book.
-- (5) Alt in another guild than the last played character, the client names the guild only after
--     a few seconds: the answer to a hello in that time comes from the list of the OTHER guild,
--     names no call and ends with "Z 0": the alt's calls are gone at everyone asking.
-- (4) Counter-checks (green): Z before the J, double Z, Z outside the own answer window, a stranger's Z
--     in someone else's name, Z with too small and too large count, own calls.
local H = dofile((arg[0]:match("^(.*)/") or ".") .. "/_kopf.lua")
local M = H.M
local G = "Die Testgilde"
local function hunts(c) return c.env.DeathNoteDB.guild.lists[G].hunts end

H.lauf("(1) zweites Geraet: Z 0 loescht die eigenen Freigaben bei allen", function()
  local W = H.welt({ "HUNT_NEW" })
  local a = W.client("Anton", "Wurst", G, { fullSender = true })
  local z = W.client("Zeuge", "Still", G, { fullSender = true })
  a.login(); z.login(); W.run(60)
  for i = 1, 3 do a.ns.Guild.Release("Ziel" .. i .. "-Lamm", { to = "guild", why = "Grund" }) end
  W.run(20)
  H.erwartet("Vorbedingung: Zeuge hat 3 Freigaben", H.freigaben(hunts(z)) == 3)
  local adb = H.raus(W, a); W.run(120)
  -- the same character on the second device (own, empty SavedVariables)
  local a2 = W.client("Anton", "Wurst", G, { fullSender = true })
  a2.login(); W.run(60)
  local z2 = H.relog(W, z); z2.login(); W.run(120)
  H.erwartet("ein Login desselben Chars an einem zweiten Geraet loescht seine Freigaben bei den anderen nicht",
    H.freigaben(hunts(z2)) == 3, "beim Zeugen noch " .. H.freigaben(hunts(z2)) .. " von 3")
  -- back on the first device
  H.raus(W, a2); W.run(120)
  local a3 = W.client("Anton", "Wurst", G, { db = adb, fullSender = true })
  a3.login(); W.run(120)
  H.erwartet("zurueck am ersten Geraet stimmen beide Seiten ueberein",
    H.freigaben(hunts(z2)) == H.freigaben(hunts(a3)),
    "Anton fuehrt " .. H.freigaben(hunts(a3)) .. ", der Zeuge " .. H.freigaben(hunts(z2)))
end)

H.lauf("(2) Namensvetter (Absender nur mit Vornamen): Z des einen loescht die Freigabe des anderen", function()
  local W = H.welt({ "HUNT_NEW" })
  local b1 = W.client("Berta", "Senf", G)
  local b2 = W.client("Berta", "Fremd", G)
  local z = W.client("Zeuge", "Still", G)
  b1.login(); b2.login(); z.login(); W.run(60)
  b1.ns.Guild.Release("Eins-Lamm", { to = "guild", why = "Grund" })
  b2.ns.Guild.Release("Zwei-Lamm", { to = "guild", why = "Grund" })
  W.run(20)
  H.erwartet("Vorbedingung: Zeuge hat beide", hunts(z)["Eins-Lamm"] ~= nil and hunts(z)["Zwei-Lamm"] ~= nil)
  H.raus(W, b2); W.run(400)
  local z2 = H.relog(W, z); z2.login(); W.run(120)
  H.erwartet("die Antwort der einen Berta laesst die Freigabe der anderen Berta stehen", hunts(z2)["Zwei-Lamm"] ~= nil,
    "geloescht durch die Z der Namensvetterin")
  H.erwartet("Gegenprobe: ihre eigene bleibt", hunts(z2)["Eins-Lamm"] ~= nil)
end)

H.lauf("(3) Freund wird Kollege: abgeblasene Freigabe 'an alle' bleibt im Freundesbuch", function()
  local W = H.welt({ "HUNT_NEW" })
  local a = W.client("Anton", "Wurst", G, { friends = { "Berta Senf" }, fullSender = true })
  local b = W.client("Berta", "Senf", nil, { friends = { "Anton Wurst" }, fullSender = true })
  a.login(); b.login(); W.run(120)
  a.ns.Guild.Release("Beide-Lamm", { to = "all", why = "Grund" }); W.run(20)
  H.erwartet("Vorbedingung: die Freundin hat die Freigabe im Freundesbuch", b.ns.Guild.Hunt("Beide-Lamm", "friends") ~= nil)
  -- the friend joins the guild
  local b2 = H.relog(W, b, { guild = G }); b2.login(); a.fire("GUILD_ROSTER_UPDATE"); W.run(180)
  H.erwartet("Vorbedingung: jetzt Kollegin, Freigabe auch im Gildenbuch", a.ns.Guild.IsGuildmate("Berta Senf")
    and b2.ns.Guild.Hunt("Beide-Lamm", "guild") ~= nil)
  a.ns.Guild.CallOff("Beide-Lamm"); W.run(30)
  H.erwartet("Vorbedingung: im Gildenbuch der Kollegin ist sie weg", b2.ns.Guild.Hunt("Beide-Lamm", "guild") == nil)
  H.erwartet("nach dem Abblasen steht sie bei der Kollegin nirgends mehr", b2.ns.Guild.Hunt("Beide-Lamm", "all") == nil,
    "steht weiter im Freundesbuch")
  H.tage(40)
  local b3 = H.relog(W, b2, { guild = G }); b3.login(); W.run(180)
  local a2 = H.relog(W, a); a2.login(); W.run(180)
  H.erwartet("auch 40 Tage und zwei Abgleiche spaeter nicht", b3.ns.Guild.Hunt("Beide-Lamm", "all") == nil,
    "steht weiter (weder A noch Z erreichen das Freundesbuch der Kollegin)")
end)

H.lauf("(4) Gegenproben: Reihenfolge, Doppel, Fenster, Faelschung, Zahl", function()
  local W = H.welt({ "HUNT_NEW" })
  local z = W.client("Zeuge", "Still", G, { fullSender = true })
  z.login(); W.run(60)
  local P = z.ns.Guild.Proto
  local B, C = "Berta Senf", "Carl Otto"
  local function von(text, wer) H.gilde(z, text, wer .. "-Forever") end
  local function fenster() M.Advance(400); z.ns.Guild.SyncNow(); W.run(1) end
  local BB, CB = "bertabk1", "carlbk01"   -- book IDs of the two senders
  -- base: two calls each from Berta and Carl, plus one of our own
  fenster()
  von(H.J(P, "B1-Lamm", B, nil, BB), B); von(H.J(P, "B2-Lamm", B, nil, BB), B)
  von(H.J(P, "C1-Lamm", C, nil, CB), C); von(H.J(P, "C2-Lamm", C, nil, CB), C)
  z.ns.Guild.Release("Eigen-Lamm", { to = "guild", why = "Grund" })
  H.erwartet("Bestand 5", H.freigaben(hunts(z)) == 5, H.freigaben(hunts(z)))
  -- Z outside the own answer window: no effect
  M.Advance(200); W.run(1)
  von(P.EncodeSnapshot(B, 0, BB), B)
  H.erwartet("Z ausserhalb des Antwortfensters loescht nichts", H.freigaben(hunts(z)) == 5, H.freigaben(hunts(z)))
  -- Z before the J (order swapped): count does not match, nothing deleted
  fenster()
  von(P.EncodeSnapshot(B, 1, BB), B); von(H.J(P, "B1-Lamm", B, nil, BB), B)
  H.erwartet("Z vor den J loescht nichts", H.freigaben(hunts(z)) == 5, H.freigaben(hunts(z)))
  -- Z in someone else's name (Carl sends a Z for Berta; Berta one for the witness)
  fenster()
  von(P.EncodeSnapshot(B, 0, BB), C); von(P.EncodeSnapshot("Zeuge Still", 0, BB), B)
  H.erwartet("Z im Namen eines anderen loescht nichts", H.freigaben(hunts(z)) == 5, H.freigaben(hunts(z)))
  -- count too small and too large
  fenster()
  von(H.J(P, "B1-Lamm", B, nil, BB), B); von(P.EncodeSnapshot(B, 0, BB), B); von(P.EncodeSnapshot(B, 2, BB), B); von(P.EncodeSnapshot(B, 10, BB), B)
  H.erwartet("Z mit falscher Zahl loescht nichts", H.freigaben(hunts(z)) == 5, H.freigaben(hunts(z)))
  -- book ID: a Z without ID or with the ID of another book deletes nothing
  fenster()
  von(H.J(P, "B1-Lamm", B, nil, BB), B); von(P.EncodeSnapshot(B, 1), B)
  H.erwartet("Z ohne Buchkennung loescht nichts", H.freigaben(hunts(z)) == 5, H.freigaben(hunts(z)))
  fenster()
  von(H.J(P, "B1-Lamm", B, nil, BB), B); von(P.EncodeSnapshot(B, 1, "anderes1"), B)
  H.erwartet("Z aus einem anderen Buch loescht nichts", H.freigaben(hunts(z)) == 5, H.freigaben(hunts(z)))
  -- correct Z: exactly Berta's unnamed call goes, Carl's and our own stay
  fenster()
  von(H.J(P, "B1-Lamm", B, nil, BB), B); von(P.EncodeSnapshot(B, 1, BB), B)
  H.erwartet("richtige Z: B2 weg, alles andere bleibt", hunts(z)["B2-Lamm"] == nil and hunts(z)["B1-Lamm"] ~= nil
    and hunts(z)["C1-Lamm"] ~= nil and hunts(z)["C2-Lamm"] ~= nil and hunts(z)["Eigen-Lamm"] ~= nil)
  -- double Z afterwards: nothing more
  von(P.EncodeSnapshot(B, 1, BB), B)
  H.erwartet("doppelte Z loescht nichts weiter", H.freigaben(hunts(z)) == 4, H.freigaben(hunts(z)))
  -- Z 0 from Carl (has none left): only his go
  fenster()
  von(P.EncodeSnapshot(C, 0, CB), C)
  H.erwartet("Z 0: nur die des Absenders gehen", H.freigaben(hunts(z)) == 2 and hunts(z)["B1-Lamm"] ~= nil and hunts(z)["Eigen-Lamm"] ~= nil,
    H.freigaben(hunts(z)))
  -- broken Z
  for _, t in ipairs({ "1\tZ\t\t0", "1\tZ\tBerta Senf\t-1", "1\tZ\tBerta Senf\t11", "1\tZ\tBerta Senf\tx", "1\tZ\tBerta Senf", "1\tZ\tBerta Senf\t0\t0" }) do
    von(t, B)
  end
  H.erwartet("kaputte Z: kein Fehler, nichts geloescht", H.freigaben(hunts(z)) == 2)
end)

H.lauf("(5) Zweitchar in anderer Gilde, Gildenname in den ersten Sekunden unbekannt: Z 0 aus der falschen Liste", function()
  local GA, GB = "Gilde A", "Gilde B"
  local function lauf(verzug)
    local W = H.welt()
    local alt = W.client("Zweit", "Wurst", GB, { fullSender = true })
    local z = W.client("Zeuge", "Still", GB, { fullSender = true })
    alt.login(); z.login(); W.run(60)
    for i = 1, 3 do alt.ns.Guild.Release("Ziel" .. i .. "-Lamm", { to = "guild", why = "Grund" }) end
    W.run(20)
    local db = H.raus(W, alt); local zdb = H.raus(W, z); W.run(120)
    -- the main character in guild A plays one evening (the file remembers guild A as last used)
    local main = W.client("Haupt", "Wurst", GA, { db = db, fullSender = true })
    main.login(); W.run(60); db = H.raus(W, main); W.run(120)
    H.tage(1)
    local a2 = W.client("Zweit", "Wurst", GB, { db = db, fullSender = true })
    local t0 = M.now
    -- GetGuildInfo returns the name only after `verzug` seconds (IsInGuild is true at once)
    a2.env.GetGuildInfo = function(t) if t == "player" and M.now - t0 > verzug then return GB end end
    local z2 = W.client("Zeuge", "Still", GB, { db = zdb, fullSender = true })
    a2.login(); z2.login(); W.run(verzug + 2)
    a2.fire("PLAYER_GUILD_UPDATE"); W.run(120)
    return H.freigaben(z2.env.DeathNoteDB.guild.lists[GB].hunts), H.freigaben(a2.env.DeathNoteDB.guild.lists[GB].hunts)
  end
  local beimZeugen, selbst = lauf(0)
  H.erwartet("Gegenprobe: Gildenname sofort bekannt: Zeuge behaelt 3", beimZeugen == 3 and selbst == 3, beimZeugen)
  beimZeugen, selbst = lauf(30)
  H.erwartet("Gildenname 30 s spaeter bekannt: Zeuge behaelt die 3 Freigaben des Zweitchars", beimZeugen == 3,
    "Zeuge hat " .. beimZeugen .. ", der Zweitchar selbst " .. selbst .. " (Antwort mit Z 0 aus der Liste der anderen Gilde)")
end)

H.lauf("(6) Buchkennung: Freigaben ohne Kennung (aelterer Stand) bleiben bei jeder Z stehen", function()
  local W = H.welt({ "HUNT_NEW" })
  local z = W.client("Zeuge", "Still", G, { fullSender = true })
  z.login(); W.run(60)
  local P = z.ns.Guild.Proto
  local B = "Berta Senf"
  local function von(text) H.gilde(z, text, B .. "-Forever") end
  local function fenster() M.Advance(400); z.ns.Guild.SyncNow(); W.run(1) end
  fenster()
  von(H.J(P, "Alt-Lamm", B))                       -- without ID
  von(H.J(P, "Neu-Lamm", B, nil, "bertabk1"))
  H.erwartet("Vorbedingung: zwei Freigaben", H.freigaben(hunts(z)) == 2, H.freigaben(hunts(z)))
  fenster()
  von(P.EncodeSnapshot(B, 0))
  H.erwartet("Z ohne Kennung: die Freigabe ohne Kennung bleibt", hunts(z)["Alt-Lamm"] ~= nil)
  fenster()
  von(P.EncodeSnapshot(B, 0, "bertabk1"))
  H.erwartet("Z mit Kennung: nur die Freigabe dieses Buchs geht", hunts(z)["Neu-Lamm"] == nil and hunts(z)["Alt-Lamm"] ~= nil)
end)

H.fertig()
