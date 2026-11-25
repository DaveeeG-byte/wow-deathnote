-- 1.7.0 claim next to 1.6.4 (v1.6.4 from git; skipped without the repository): 1.6.4 as poster drops C and sends no
-- Q (the record stays "sent"), 1.6.4 as killer sends only V (the 1.7.0 poster makes the claim with the bounty's time),
-- 1.6.4 as third in the guild drops C and Q quietly. The book of 1.7.0 loaded in 1.6.4 and back: nothing lost, no
-- error. All names are made up.
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local K = require("_cl170")
local H, M, G = K.H, K.M, K.G
local GitBase = dofile(H.DIR .. "/tests/git_base.lua")
local KEY = K.KEY

local OLD, why = GitBase.Archive(H.DIR, "v1.6.4")
if not OLD then
  io.write("  uebersprungen (Mischbetrieb 1.6.4): " .. tostring(why) .. "\n")
  GitBase.Clean()
  H.fertig()
  return
end
local OLDFILES = {}
for _, f in ipairs(M.FILES) do
  local fh = io.open(OLD .. f, "r")
  if fh then fh:close(); OLDFILES[#OLDFILES + 1] = f end
end
local function alt(W, name, surname, guild, opts)
  opts = opts or {}
  opts.fullSender, opts.dir, opts.files, opts.version = true, OLD, OLDFILES, "1.6.4"
  return W.client(name, surname, guild, opts)
end
local function typDrops(c) return c.ns.Guild.Health and c.ns.Guild.Bridge and c.ns.Guild.Bridge.gctx.stats.dropped or 0 end

H.lauf("(1) 1.6.4 als Aussteller: Anspruch wie bisher, kein Q; C verworfen; Eintrag bleibt unbestaetigt", function()
  local W = K.welt()
  local a = W.client("Anton", "Wurst", G, { fullSender = true })
  local b = alt(W, "Berta", "Senf", G)
  a.login(); b.login(); W.run(90)
  H.erwartet("Vorbedingung: 1.6.4 setzt Kopfgeld", b.ns.Guild.SetBounty(KEY, 40) == true)
  W.run(10)
  K.toetet(a); W.run(10)
  H.erwartet("1.6.4: Anspruch wie in 1.6.0", #K.claims(b) == 1 and K.claims(b)[1].b == nil)
  H.erwartet("kein Q", #K.msgs(W, "Q") == 0)
  H.erwartet("Eintrag unbestaetigt", (K.earned(a)[1] or {}).state == "sent")
  local d0 = typDrops(b)
  M.Advance(400)
  b.ns.Guild.SyncNow(); W.run(30)
  -- exactly two: one after FRESH_WAIT (Berta heard in the session), one at her hello (the first counted against the
  -- throttle on the record); no storm at a 1.6.4 poster who never answers
  H.erwartet("C ging hinaus: genau zwei (nach FRESH_WAIT und beim Hallo)", #K.msgs(W, "C", a) == 2, #K.msgs(W, "C", a))
  H.erwartet("1.6.4 verwirft es still (Art unbekannt)", typDrops(b) > d0 and b.ns.Guild.Bridge.gctx.stats.lastReason == "type",
    b.ns.Guild.Bridge.gctx.stats.lastReason)
  H.erwartet("weiter ein Anspruch, kein Fehler", #K.claims(b) == 1 and #M.errors == 0, M.errors[1])
  H.erwartet("Eintrag weiter unbestaetigt", (K.earned(a)[1] or {}).state == "sent")
  -- an hour more with a hello every 5 minutes: at most every 10 minutes, at most DAY_MAX a day
  for _ = 1, 12 do M.Advance(300); b.ns.Guild.SyncNow(); W.run(10) end
  local n = #K.msgs(W, "C", a)
  H.erwartet("eine Stunde Hallos: hoechstens DAY_MAX C am Tag", n <= (a.ns.Claim.DAY_MAX or 6) and n >= 3, n)
end)

H.lauf("(2) 1.6.4 als Schuetze: nur V; 1.7.0 stellt den Anspruch mit dem Zeitpunkt des Kopfgelds", function()
  local W = K.welt()
  local a = alt(W, "Anton", "Wurst", G)
  local b = W.client("Berta", "Senf", G, { fullSender = true })
  local c = alt(W, "Carla", "Klee", G)
  a.login(); b.login(); c.login(); W.run(90)
  b.ns.Guild.SetBounty(KEY, 40); W.run(10)
  K.toetet(a); W.run(10)
  H.erwartet("V von 1.6.4", #K.msgs(W, "V", a) == 1)
  local cl = K.claims(b)[1] or {}
  H.erwartet("Anspruch mit b", cl.b == K.bountyT(b, KEY) and cl.state == "open", cl.b)
  H.erwartet("Q geht hinaus, 1.6.4 verwirft es", #K.msgs(W, "Q", b) == 1 and K.earned(a)[1] == nil)
  b.ns.Feud.SetClaim(cl, "paid"); W.run(10)
  H.erwartet("bezahlt: Kopfgeld auch bei 1.6.4 zurueckgenommen", a.ns.Guild.HasBounty(KEY) == false
    and c.ns.Guild.HasBounty(KEY) == false)
  H.erwartet("Dritter 1.6.4: nichts, kein Fehler", #K.claims(c) == 0 and c.env.DeathNoteDB.earned == nil and #M.errors == 0,
    M.errors[1])
end)

H.lauf("(3) Buch der 1.7.0 in 1.6.4 geladen und zurueck: Eintraege und b bleiben", function()
  local W = K.welt()
  local a = W.client("Anton", "Wurst", G, { fullSender = true })
  local b = W.client("Berta", "Senf", G, { fullSender = true })
  a.login(); b.login(); W.run(90)
  b.ns.Guild.SetBounty(KEY, 40); W.run(10)
  K.toetet(a); W.run(10)
  local e0 = H.tiefe_kopie(K.earned(a))
  local c0 = H.tiefe_kopie(K.claims(b))
  H.erwartet("Vorbedingung", #e0 == 1 and #c0 == 1 and c0[1].b ~= nil)
  -- both log out, come back with 1.6.4, log out again, back with 1.7.0
  for _, c in ipairs({ a, b }) do c.fire("PLAYER_LOGOUT") end
  local da, db = H.tiefe_kopie(a.env.DeathNoteDB), H.tiefe_kopie(b.env.DeathNoteDB)
  local W2 = K.welt()
  local a1 = alt(W2, "Anton", "Wurst", G, { db = da })
  local b1 = alt(W2, "Berta", "Senf", G, { db = db })
  a1.login(); b1.login(); W2.run(60)
  H.erwartet("1.6.4: Ansprueche lesbar", #K.claims(b1) == 1 and b1.ns.Feud.OpenClaims() == 1)
  b1.ns.Feud.SetClaim(K.claims(b1)[1], "declined")
  for _, c in ipairs({ a1, b1 }) do c.fire("PLAYER_LOGOUT") end
  da, db = H.tiefe_kopie(a1.env.DeathNoteDB), H.tiefe_kopie(b1.env.DeathNoteDB)
  local W3 = K.welt()
  local a2 = W3.client("Anton", "Wurst", G, { fullSender = true, db = da })
  local b2 = W3.client("Berta", "Senf", G, { fullSender = true, db = db })
  a2.login(); b2.login(); W3.run(60)
  local e2, c2 = K.earned(a2), K.claims(b2)
  H.erwartet("Eintrag ueberlebt 1.6.4", #e2 == 1 and e2[1].owner == e0[1].owner and e2[1].t == e0[1].t
    and e2[1].g == e0[1].g and e2[1].via == e0[1].via, #e2)
  -- the record was open: its C in the answer to Berta's hello brings the state set under 1.6.4
  H.erwartet("Zustand aus 1.6.4 kommt mit der Quittung an", e2[1] and e2[1].state == "declined", e2[1] and e2[1].state)
  H.erwartet("b ueberlebt 1.6.4, Zustand von 1.6.4 bleibt", #c2 == 1 and c2[1].b == c0[1].b and c2[1].state == "declined")
  H.erwartet("keine Fehler", #M.errors == 0, M.errors[1])
end)

GitBase.Clean()
H.fertig()
