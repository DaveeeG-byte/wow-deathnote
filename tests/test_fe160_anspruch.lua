-- 1.6.0 feud: the claim on a bounty. V also goes out when a bounty of guild or friends lies on the killed player, with or
-- without a deed in their books; the poster of that bounty gets a claim (who, whom, when, gold, open / paid / declined;
-- at most 50, older than 30 days go). The addon pays nothing. Mixed use with 1.5.0 (a003532, from git) in both
-- directions: nothing breaks, nothing counts twice. All names are made up.
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local H = require("beleg_helfer")
local M = H.M
local GitBase = dofile(H.DIR .. "/tests/git_base.lua")
local G = "Die Testgilde"
local GUID = "Player-1-7461657465"

local function welt()
  local W = H.welt({ "GUILD_KILL", "GUILD_UPDATED", "AVENGED", "CLAIM_NEW" })
  M.AddEnemy("nameplate9", { name = "Taeter", surname = "Lamm", guid = GUID })
  return W
end
local function toetet(c) c.fire("PARTY_KILL", c.env.UnitGUID("player"), GUID) end
local function vs(W, von)
  local n = 0
  for _, m in ipairs(W.sent) do if (not von or m.sender == von) and m.text:find("^1\tV\t") then n = n + 1 end end
  return n
end
local function claims(c) return c.env.DeathNoteDB.claims or {} end

H.lauf("(1) Gilde: Kopfgeld auf ein Ziel ohne Tat, ein anderer erwischt es: V und Anspruch beim Aussteller", function()
  local W = welt()
  local a = W.client("Anton", "Wurst", G, { fullSender = true })
  local b = W.client("Berta", "Senf", G, { fullSender = true })
  a.login(); b.login(); W.run(90)
  H.erwartet("Vorbedingung: Kopfgeld gesetzt", b.ns.Guild.SetBounty("Taeter-Lamm", 50) == true)
  W.run(10)
  H.erwartet("Vorbedingung: Anton kennt das Kopfgeld", a.ns.Guild.HasBounty("Taeter-Lamm") == true)
  H.erwartet("Vorbedingung: kein Eintrag im Gildenbuch", a.ns.Guild.Get("Taeter-Lamm", "guild") == nil)
  toetet(a); W.run(10)
  H.erwartet("ein V auf GUILD", vs(W, a) == 1, vs(W, a))
  local c = claims(b)
  H.erwartet("Berta: ein Anspruch", #c == 1, #c)
  local x = c[1] or {}
  H.erwartet("Anspruch: wer, wen, Gold, offen", x.by == "Anton Wurst" and x.key == "Taeter-Lamm" and x.g == 50
    and x.state == "open" and x.char == "Berta Senf", tostring(x.by) .. "/" .. tostring(x.g) .. "/" .. tostring(x.state))
  H.erwartet("Berta: Meldung CLAIM_NEW", H.zaehle(b, "CLAIM_NEW") == 1)
  H.erwartet("Anton: kein Anspruch bei sich", #claims(a) == 0)
  -- the same kill again (echo, a second channel): one claim
  local P = b.ns.Guild.Proto
  H.gilde(b, P.EncodeAvenged("Taeter-Lamm", "Anton Wurst", x.t, false), "Anton Wurst-Forever")
  H.erwartet("dieselbe Toetung: ein Anspruch", #claims(b) == 1, #claims(b))
  -- paid, declined, open again
  local F = b.ns.Feud
  H.erwartet("bezahlt", F.SetClaim(x, "paid") and x.state == "paid" and F.OpenClaims() == 0)
  H.erwartet("wieder offen", F.SetClaim(x, "open") and F.OpenClaims() == 1)
  H.erwartet("abgelehnt", F.SetClaim(x, "declined") and x.state == "declined")
  H.erwartet("unbekannter Zustand: nein", not F.SetClaim(x, "stolen"))
  H.erwartet("keine Fehler", #M.errors == 0, M.errors[1])
end)

H.lauf("(2) Eigener Kill auf das eigene Kopfgeld: kein Anspruch, kein V", function()
  local W = welt()
  local b = W.client("Berta", "Senf", G, { fullSender = true })
  local a = W.client("Anton", "Wurst", G, { fullSender = true })
  a.login(); b.login(); W.run(90)
  b.ns.Guild.SetBounty("Taeter-Lamm", 30); W.run(10)
  toetet(b); W.run(10)
  H.erwartet("kein V fuer das eigene Kopfgeld", vs(W, b) == 0, vs(W, b))
  H.erwartet("kein Anspruch", #claims(b) == 0)
end)

H.lauf("(3) Freunde: nur der Freund mit dem Kopfgeld bekommt V und den Anspruch", function()
  local W = welt()
  local a = W.client("Anton", "Wurst", nil, { friends = { "Berta Senf", "Fritz Frei" }, fullSender = true })
  local b = W.client("Berta", "Senf", nil, { friends = { "Anton Wurst" }, fullSender = true })
  local f = W.client("Fritz", "Frei", nil, { friends = { "Anton Wurst" }, fullSender = true })
  a.login(); b.login(); f.login(); W.run(120)
  H.erwartet("Vorbedingung: Kopfgeld gesetzt", b.ns.Guild.SetBounty("Taeter-Lamm", 75) == true)
  W.run(20)
  H.erwartet("Vorbedingung: Anton kennt das Kopfgeld", a.ns.Guild.HasBounty("Taeter-Lamm") == true)
  toetet(a); W.run(10)
  local an = {}
  for _, m in ipairs(W.sent) do if m.sender == a and m.text:find("^1\tV\t") then an[m.to or "?"] = true end end
  H.erwartet("V nur an Berta", an["Berta Senf"] and not an["Fritz Frei"])
  H.erwartet("Berta: Anspruch ueber 75", #claims(b) == 1 and claims(b)[1].g == 75)
  H.erwartet("Fritz: nichts", #claims(f) == 0)
end)

-- 1.5.0 next to 1.6.0 (a003532 from git: skipped without the repository)
local OLD, why = GitBase.Archive(H.DIR, "a003532")
if not OLD then
  io.write("  uebersprungen (Mischbetrieb): " .. tostring(why) .. "\n")
else
  local OLDFILES = {}
  for _, f in ipairs(M.FILES) do if f ~= "Feud.lua" then OLDFILES[#OLDFILES + 1] = f end end

  H.lauf("(4) Mischbetrieb: 1.5.0 als Aussteller nimmt das neue V still hin", function()
    local W = welt()
    local a = W.client("Anton", "Wurst", G, { fullSender = true })
    local b = W.client("Berta", "Senf", G, { fullSender = true, dir = OLD, files = OLDFILES, version = "1.5.0" })
    a.login(); b.login(); W.run(90)
    H.erwartet("Vorbedingung: 1.5.0 setzt Kopfgeld", b.ns.Guild.SetBounty("Taeter-Lamm", 40) == true)
    W.run(10)
    toetet(a); W.run(10)
    H.erwartet("1.6.0 sendet V", vs(W, a) == 1)
    H.erwartet("1.5.0: kein Fehler, keine Meldung, nichts gezaehlt", #M.errors == 0 and H.zaehle(b, "AVENGED") == 0
      and select(2, b.ns.Guild.Avenged("Taeter-Lamm")) == 0, M.errors[1])
    H.erwartet("1.5.0 kennt keine Ansprueche", b.env.DeathNoteDB.claims == nil)
  end)

  H.lauf("(5) Mischbetrieb: 1.5.0 als Schuetze sendet fuer ein Ziel ohne Tat kein V, 1.6.0 bleibt ruhig", function()
    local W = welt()
    local a = W.client("Anton", "Wurst", G, { fullSender = true, dir = OLD, files = OLDFILES, version = "1.5.0" })
    local b = W.client("Berta", "Senf", G, { fullSender = true })
    a.login(); b.login(); W.run(90)
    b.ns.Guild.SetBounty("Taeter-Lamm", 40); W.run(10)
    toetet(a); W.run(10)
    H.erwartet("1.5.0 sendet kein V", vs(W, a) == 0)
    H.erwartet("kein Anspruch, kein Fehler", #claims(b) == 0 and #M.errors == 0, M.errors[1])
  end)

  H.lauf("(6) Mischbetrieb: Ziel mit Tat im Gildenbuch, 1.5.0 schiesst, 1.6.0 stellt Anspruch und meldet wie bisher", function()
    local W = welt()
    local a = W.client("Anton", "Wurst", G, { fullSender = true, dir = OLD, files = OLDFILES, version = "1.5.0" })
    local b = W.client("Berta", "Senf", G, { fullSender = true })
    local c = W.client("Carla", "Klee", G, { fullSender = true })
    a.login(); b.login(); c.login(); W.run(90)
    local key = H.tod(c, "Taeter", "Lamm"); W.run(10)
    b.ns.Guild.SetBounty(key, 20); W.run(10)
    toetet(a); W.run(10)
    H.erwartet("1.5.0 sendet V (Tat an Carla)", vs(W, a) == 1)
    H.erwartet("Berta: Anspruch", #claims(b) == 1)
    H.erwartet("Carla: Meldung wie bisher, kein Anspruch", H.zaehle(c, "AVENGED") == 1 and #claims(c) == 0)
  end)
end
GitBase.Clean()

H.lauf("(7) Deckel 50, aelter als 30 Tage weg, kaputte Ansprueche repariert", function()
  M.Reset()
  local t = time()
  local list = { { key = "Bad|Key", by = "X", t = t, g = 1, state = "open" }, "kaputt",
    { key = "Alt-Ling", by = "Anna Alt", t = t - 31 * 86400, g = 5, state = "open" },
    { key = "Gut-Ling", by = "Anna Alt", t = t - 5, g = 5, state = "weird" } }
  for i = 1, 60 do list[#list + 1] = { key = "Ziel-" .. i, by = "Anna Alt", t = t - i, g = i, state = "open" } end
  local ns = M.Load({ db = { claims = list } })
  local c = ns.Store.DB().claims
  H.erwartet("50 bleiben, die neuesten", #c == 50 and c[1].key == "Ziel-1" and c[50].key == "Ziel-50", #c)
  local F = ns.Feud
  for i = 1, 10 do F.AddClaim("Neu-" .. i, nil, "Bert Bunt", time(), 10, "Ich Selbst") end
  H.erwartet("neue vorne, Deckel bleibt", #c == 50 and c[1].key == "Neu-10", #c)
  H.erwartet("kein Anspruch ohne Absender", F.AddClaim("X-Y", nil, M.Secret("by"), time(), 1) == nil)
end)

H.fertig()
