-- 1.7.0 claim: every input from the wire is hostile. A C naming another killer, a C for another poster, a Q from
-- somebody who is not the poster, a Q for an unknown record, times from the future, overlong fields, control
-- characters, floods: nothing changes data, nothing raises. Broken saved data breaks nothing. All names are made up.
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local K = require("_cl170")
local H, M, G = K.H, K.M, K.G
local KEY = K.KEY

local function snap(c)
  return H.tiefe_kopie({ e = K.earned(c), c = K.claims(c) })
end
local function same(a, b)
  if type(a) ~= type(b) then return false end
  if type(a) ~= "table" then return a == b end
  for k, v in pairs(a) do if not same(v, b[k]) then return false end end
  for k in pairs(b) do if a[k] == nil then return false end end
  return true
end

-- Anton (killer, open record), Berta (poster, open claim), Carla (third)
local function lage()
  local W = K.welt()
  local a = W.client("Anton", "Wurst", G, { fullSender = true })
  local b = W.client("Berta", "Senf", G, { fullSender = true })
  local c = W.client("Carla", "Klee", G, { fullSender = true })
  a.login(); b.login(); c.login(); W.run(90)
  b.ns.Guild.SetBounty(KEY, 50); W.run(10)
  K.toetet(a); W.run(10)
  return W, a, b, c
end

H.lauf("(1) gefaelschte C und Q aendern nichts", function()
  local W, a, b, c = lage()
  local P = b.ns.Guild.Proto
  local x = K.earned(a)[1]
  local cl = K.claims(b)[1]
  H.erwartet("Vorbedingung: Eintrag und Anspruch offen", x and x.state == "open" and cl and cl.state == "open")
  local sa, sb = snap(a), snap(b)
  local bt = K.bountyT(b, KEY)
  local t = time()
  -- Carla sends a C in Anton's name (fremder Schuetze)
  H.gilde(b, P.EncodeClaim(KEY, "Anton Wurst", t - 30, "Berta Senf", 50), "Carla Klee-Forever")
  -- Carla's own C for another poster (Dora)
  H.gilde(b, P.EncodeClaim(KEY, "Carla Klee", t - 30, "Dora Dorn", 50), "Carla Klee-Forever")
  -- Carla sends a Q in Berta's name (paid)
  H.gilde(a, P.EncodeReceipt(KEY, "Anton Wurst", x.t, "Berta Senf", 1, 50), "Carla Klee-Forever")
  -- Berta's Q for an unknown record (another time, another target, another killer)
  H.gilde(a, P.EncodeReceipt(KEY, "Anton Wurst", x.t - 500, "Berta Senf", 1, 50), "Berta Senf-Forever")
  H.gilde(a, P.EncodeReceipt(K.KEY2, "Anton Wurst", x.t, "Berta Senf", 1, 50), "Berta Senf-Forever")
  H.gilde(a, P.EncodeReceipt(KEY, "Emil Eck", x.t, "Berta Senf", 1, 50), "Berta Senf-Forever")
  -- a Q naming another poster than its sender (Berta names Carla)
  H.gilde(a, P.EncodeReceipt(KEY, "Anton Wurst", x.t, "Carla Klee", 1, 50), "Berta Senf-Forever")
  -- times from the future, overlong and broken fields, control characters, bad numbers
  local raw = {
    "1\tC\t" .. KEY .. "\tAnton Wurst\t" .. (t + 4000) .. "\tBerta Senf\t50",
    "1\tC\t" .. KEY .. "\tAnton Wurst\t" .. (t - 40 * 86400) .. "\tBerta Senf\t50",
    "1\tC\t" .. KEY .. "\t" .. ("A"):rep(70) .. "\t" .. (t - 30) .. "\tBerta Senf\t50",
    "1\tC\t" .. KEY .. "\tAnton Wurst\t" .. (t - 30) .. "\t" .. ("B"):rep(70) .. "\t50",
    "1\tC\t" .. KEY .. "\tAnton%01Wurst\t" .. (t - 30) .. "\tBerta Senf\t50",
    "1\tC\t" .. KEY .. "\tAnton Wurst\t" .. (t - 30) .. "\tBerta%7CSenf\t50",
    "1\tC\t" .. KEY .. "\tAnton Wurst\t" .. (t - 30) .. "\tBerta Senf\t0",
    "1\tC\t" .. KEY .. "\tAnton Wurst\t" .. (t - 30) .. "\tBerta Senf\t100000",
    "1\tC\t" .. KEY .. "\tAnton Wurst\t" .. (t - 30) .. "\tBerta Senf\t-5",
    "1\tC\t" .. KEY .. "\tAnton Wurst\t" .. (t - 30) .. "\tBerta Senf\t5.5",
    "1\tC\t" .. KEY .. "\tAnton Wurst\t" .. (t - 30) .. "\tBerta Senf",
    "1\tC\t" .. KEY .. "\tAnton Wurst\t" .. (t - 30) .. "\tBerta Senf\t50\textra",
    "1\tC\tkaputt\tAnton Wurst\t" .. (t - 30) .. "\tBerta Senf\t50",
    "1\tC\t" .. KEY .. "\t\t" .. (t - 30) .. "\tBerta Senf\t50",
    "1\tC\t" .. KEY .. "\tAnton Wurst\tabc\tBerta Senf\t50",
  }
  for _, s in ipairs(raw) do H.gilde(b, s, "Anton Wurst-Forever") end
  local rawQ = {
    "1\tQ\t" .. KEY .. "\tAnton Wurst\t" .. x.t .. "\tBerta Senf\t7\t50",
    "1\tQ\t" .. KEY .. "\tAnton Wurst\t" .. x.t .. "\tBerta Senf\t1\t-1",
    "1\tQ\t" .. KEY .. "\tAnton Wurst\t" .. x.t .. "\tBerta Senf\t1",
    "1\tQ\t" .. KEY .. "\tAnton Wurst\t" .. (t + 4000) .. "\tBerta Senf\t1\t50",
    "1\tQ\t" .. KEY .. "\tAnton%00Wurst\t" .. x.t .. "\tBerta Senf\t1\t50",
    "1\tQ\t" .. KEY .. "\tAnton Wurst\t" .. x.t .. "\t" .. ("B"):rep(70) .. "\t1\t50",
  }
  for _, s in ipairs(rawQ) do H.gilde(a, s, "Berta Senf-Forever") end
  W.run(10)
  H.erwartet("Anton: Eintrag unveraendert", same(snap(a), sa))
  H.erwartet("Berta: Ansprueche unveraendert", same(snap(b), sb))
  H.erwartet("Kopfgeld steht", K.bountyT(b, KEY) == bt)
  H.erwartet("keine Fehler", #M.errors == 0, M.errors[1])
  H.erwartet("Carla: nichts", #K.earned(c) == 0 and #K.claims(c) == 0)
end)

H.lauf("(2) Flut: Deckel je Absender, derselbe Kill ergibt keinen zweiten Anspruch, Quittungen gedrosselt", function()
  local W, a, b = lage()
  local P = b.ns.Guild.Proto
  local C = b.ns.Guild.C
  M.Advance(3000); W.run(1)
  local function n(c, k) return c.ns.Claim.Session()[k] or 0 end
  -- (a) 40 different kills (61 s apart, all while the bounty stood): new E4, each is a claim until the cap per sender
  local q0, f0 = #K.msgs(W, "Q", b), n(b, "drop.flood")
  local t = time()
  for i = 1, 40 do
    H.gilde(b, P.EncodeClaim(KEY, "Anton Wurst", t - 61 * i, "Berta Senf", 50), "Anton Wurst-Forever")
  end
  W.run(10)
  H.erwartet("(a) genau CLAIM_IN neue Ansprueche", #K.claims(b) == 1 + C.CLAIM_IN, #K.claims(b))
  H.erwartet("(a) der Rest als Flut", n(b, "drop.flood") - f0 == 40 - C.CLAIM_IN, n(b, "drop.flood") - f0)
  H.erwartet("(a) eine Quittung je neuem Anspruch", #K.msgs(W, "Q", b) - q0 == C.CLAIM_IN, #K.msgs(W, "Q", b) - q0)
  local paid = 0
  for _, y in ipairs(K.claims(b)) do if y.state == "paid" then paid = paid + 1 end end
  H.erwartet("(a) keiner bezahlt", paid == 0)
  -- (b) in a new window: the same kill 40 times: no further claim, one receipt
  M.Advance(C.CLAIM_IN_WINDOW + 1); W.run(1)
  local x = K.earned(a)[1]
  local q1, f1, c1 = #K.msgs(W, "Q", b), n(b, "drop.flood"), #K.claims(b)
  for _ = 1, 40 do H.gilde(b, P.EncodeClaim(KEY, "Anton Wurst", x.t, "Berta Senf", 50), "Anton Wurst-Forever") end
  W.run(10)
  H.erwartet("(b) derselbe Kill: kein weiterer Anspruch", #K.claims(b) == c1, #K.claims(b) - c1)
  H.erwartet("(b) eine Quittung (RECEIPT_GAP)", #K.msgs(W, "Q", b) - q1 == 1, #K.msgs(W, "Q", b) - q1)
  H.erwartet("(b) Deckel je Absender", n(b, "drop.flood") - f1 == 40 - C.CLAIM_IN, n(b, "drop.flood") - f1)
  -- (c) Q flood at the killer, in a window of its own
  M.Advance(C.CLAIM_IN_WINDOW + 1); W.run(1)
  local r0, g0 = n(a, "recv.Q"), n(a, "drop.flood")
  for _ = 1, 50 do H.gilde(a, P.EncodeReceipt(KEY, "Anton Wurst", x.t, "Berta Senf", 2, 50), "Berta Senf-Forever") end
  W.run(5)
  H.erwartet("(c) Q-Deckel je Absender", n(a, "recv.Q") - r0 == C.RECEIPT_IN and n(a, "drop.flood") - g0 == 50 - C.RECEIPT_IN,
    n(a, "recv.Q") - r0)
  H.erwartet("keine Fehler", #M.errors == 0, M.errors[1])
end)

H.lauf("(1b) ein C fuer einen anderen Aussteller nimmt Berta nicht an, auch wenn ihr Kopfgeld frei ist", function()
  local W, a, b, c = lage()
  local P = b.ns.Guild.Proto
  b.ns.Guild.SetBounty(K.KEY2, 40); W.run(10)
  local n0 = #K.claims(b)
  H.gilde(b, P.EncodeClaim(K.KEY2, "Carla Klee", time() - 30, "Dora Dorn", 40), "Carla Klee-Forever")
  W.run(5)
  H.erwartet("kein Anspruch, kein Q", #K.claims(b) == n0 and #K.msgs(W, "Q", b) == 1, #K.claims(b))
  H.erwartet("gezaehlt als fremd", (b.ns.Claim.Session()["other.C"] or 0) >= 1)
end)

H.lauf("(2b) wiederholtes C derselben Toetung: eine Quittung je RECEIPT_GAP", function()
  local W, a, b = lage()
  local P = b.ns.Guild.Proto
  local x = K.earned(a)[1]
  local q0 = #K.msgs(W, "Q", b)
  for _ = 1, 5 do H.gilde(b, P.EncodeClaim(KEY, "Anton Wurst", x.t, "Berta Senf", 50), "Anton Wurst-Forever") end
  W.run(5)
  H.erwartet("eine Quittung fuer fuenf C", #K.msgs(W, "Q", b) - q0 == 1, #K.msgs(W, "Q", b) - q0)
  M.Advance(b.ns.Guild.C.RECEIPT_GAP + 1)
  H.gilde(b, P.EncodeClaim(KEY, "Anton Wurst", x.t, "Berta Senf", 50), "Anton Wurst-Forever")
  W.run(5)
  H.erwartet("nach der Pause wieder eine", #K.msgs(W, "Q", b) - q0 == 2, #K.msgs(W, "Q", b) - q0)
end)

H.lauf("(3) Fluestern von Fremden und gefaelschte Freunde: nichts", function()
  local W = K.welt()
  local a = W.client("Anton", "Wurst", nil, { friends = { "Berta Senf" }, fullSender = true })
  local b = W.client("Berta", "Senf", nil, { friends = { "Anton Wurst" }, fullSender = true })
  a.login(); b.login(); W.run(120)
  b.ns.Guild.SetBounty(KEY, 75); W.run(20)
  K.toetet(a); W.run(10)
  local sb = snap(b)
  local sa = snap(a)
  local P = b.ns.Guild.Proto
  local t = time()
  H.fluestern(b, P.EncodeClaim(KEY, "Emil Eck", t - 30, "Berta Senf", 75), "Emil Eck-Forever")
  H.fluestern(b, P.EncodeClaim(KEY, "Anton Wurst", t - 30, "Berta Senf", 75), "Emil Eck-Forever")
  H.fluestern(a, P.EncodeReceipt(KEY, "Anton Wurst", K.earned(a)[1].t, "Berta Senf", 1, 75), "Emil Eck-Forever")
  -- Berta's whisper names another killer
  H.fluestern(b, P.EncodeClaim(KEY, "Emil Eck", t - 30, "Berta Senf", 75), "Anton Wurst-Forever")
  W.run(10)
  H.erwartet("nichts geaendert", same(snap(a), sa) and same(snap(b), sb))
  H.erwartet("keine Fehler", #M.errors == 0, M.errors[1])
end)

H.lauf("(4) Kaputte gespeicherte Daten, Secrets: nichts bricht", function()
  M.Reset()
  local t = time()
  local list = { "kaputt", { key = "Bad|Key", owner = "A B", char = "C D", t = t, g = 1, state = "sent" },
    { key = KEY, owner = "Berta Senf", char = "Anton Wurst", t = t - 31 * 86400, g = 5, state = "open" },
    { key = KEY, owner = "Berta Senf", char = "Anton Wurst", t = t - 5, g = 5, state = "weird" },
    { key = KEY, owner = M.Secret("o"), char = "Anton Wurst", t = t - 5, g = 5, state = "open" },
    { key = KEY, owner = "Berta Senf", char = "Anton Wurst", t = 0 / 0, g = 5, state = "open" },
    { key = KEY, owner = "Berta Senf", char = "Anton Wurst", t = t - 9, g = 5, state = "paid", via = "mond", at = "x",
      name = ("n"):rep(80) } }
  list[1000] = { key = KEY, owner = "Loch", char = "Anton Wurst", t = t - 3, g = 2, state = "sent" }
  list.x = 5
  for i = 1, 60 do
    list[#list + 1] = { key = "Ziel-Nr", owner = "Anna Alt", char = "Ich Selbst", t = t - 100 - i, g = i, state = "sent" }
  end
  local ns = M.Load({ db = { earned = list, claims = { { key = KEY, by = "Anton Wurst", t = t, g = 1, state = "open",
    b = "kaputt" } } } })
  local e = ns.Store.DB().earned
  H.erwartet("50 bleiben, newest first", #e == 50 and e[1].owner == "Loch", #e)
  local p
  for _, x in ipairs(e) do if x.state == "paid" then p = x end end
  H.erwartet("repariert statt verworfen", p and p.via == nil and p.at == nil and p.name == nil)
  H.erwartet("kaputtes b am Anspruch weg", ns.Store.DB().claims[1].b == nil)
  local C = ns.Claim
  H.erwartet("Dismiss mit Unsinn", C.Dismiss(nil) == false and C.Dismiss({}) == false and C.Dismiss(M.Secret("x")) == false)
  H.erwartet("OnKill mit Secret", C.OnKill(M.Secret("k"), true, t, "Ich Selbst") == 0)
  H.erwartet("Others mit Secret", ns.Bounty.Others(M.Secret("k")) == 0)
  local ns2 = M.Load({ db = { earned = "kaputt" } })
  H.erwartet("earned kein table: leer", type(ns2.Claim.Earned()) == "table" and #ns2.Claim.Earned() == 0
    and ns2.Claim.OpenEarned() == 0)
  local ns3 = M.Load({ db = {}, noLogin = true })
  H.erwartet("ohne Start: Earned nie nil", type(ns3.Claim.Earned()) == "table")
  H.erwartet("keine Fehler", #M.errors == 0, M.errors[1])
end)

H.fertig()
