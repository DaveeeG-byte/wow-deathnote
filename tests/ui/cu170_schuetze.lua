-- 1.7.0 claim: the shooter. EARNED_NEW: a chat line at once, a notice "Bounty earned" (gold, target, poster) a moment
-- later; a click on it opens Unsolved > Claims. One window per event: a notice of the same kill (payback) stays, the
-- bounty follows it and is never lost; several posters of one kill give one notice. EARNED_CHANGED: chat lines for
-- paid, declined, no bounty; unconfirmed to open is silent. The poster: CLAIM_SETTLED gives one chat line.
-- All names are made up.
local X = dofile((arg[0]:match("^(.*)/") or ".") .. "/_cu170.lua")
local check = X.check

local function banner(W)
  return W.frameWith(function(f) return f.kicker and f.stamp and f.line and f.name and f.inAnim end)
end

for _, code in ipairs({ "deDE", "enUS" }) do
  local W = X.world(code)
  X.fake(W)
  local ns, L, F = W.ns, W.L, W.F
  local G = ns.UI.Kit.GF.Gold
  local where = L.TAB_UNSOLVED .. " > " .. L.VIEW_CLAIMS
  -- (1) a bounty earned, nothing else on the screen
  W.AM.chat = {}
  local t = _G.time()
  local x = W.earn({ key = "Kalt-Herz", name = "Kalt Herz", owner = "Anna Wurst", char = "Ich Selbst", t = t, g = 50,
    via = "guild", state = "sent" })
  local chat = F(L.CHAT_EARNED, { gold = G(50), name = "Anna", target = "Kalt Herz", where = where })
  check(code .. ": Chatzeile sofort", W.chatHas(chat), W.AM.chat[1])
  local B = banner(W)
  check(code .. ": Zettel noch nicht im selben Augenblick", not (B and B:IsShown() and tostring(B.kicker._text):gsub("%s", "") == L.BANNER_EARNED:gsub("%s", "")))
  W.tick(1.2)
  B = banner(W)
  local function kick(b) return b and tostring(b.kicker._text):gsub("%s", "") end
  local earnedKick = (L.BANNER_EARNED:gsub("%s", ""))
  check(code .. ": Zettel Kopfgeld verdient", B and B:IsShown() and kick(B) == earnedKick,
    B and B.kicker._text)
  check(code .. ": Zettel: Ziel gross", B and B.name._text == "Kalt Herz", B and B.name._text)
  check(code .. ": Zettel: Gold und Auslober", B and tostring(B.line._text):find(F(L.EARNED_SLIP_LINE, { gold = G(50), name = "Anna" }), 1, true) ~= nil,
    B and B.line._text)
  -- the click opens Unsolved > Claims
  check(code .. ": Zettel klickbar", B and B.open ~= nil)
  if B and B.open then B.open(); W.tick(); W.settle() end
  local k = W.kit()
  check(code .. ": Klick oeffnet Zu klaeren > Ansprueche", k.state.filter == "open" and ns.FeudUI.oview == "claims",
    tostring(k.state.filter) .. " " .. tostring(ns.FeudUI.oview))
  ns:Fire("TOGGLE_UI"); W.tick(); W.settle()

  -- (2) state changes: unconfirmed to open silent; paid, declined, no bounty each one line
  W.AM.chat = {}
  W.change(x, "open")
  check(code .. ": unbestaetigt -> offen still", #W.AM.chat == 0, W.AM.chat[1])
  W.change(x, "paid")
  check(code .. ": bezahlt: Zeile", W.chatHas(F(L.CHAT_EARNED_PAID, { name = "Anna", target = "Kalt Herz", gold = G(50) })), W.AM.chat[1])
  W.change(x, "declined")
  check(code .. ": abgelehnt: Zeile", W.chatHas(F(L.CHAT_EARNED_DECLINED, { name = "Anna", target = "Kalt Herz", gold = G(50) })))
  W.change(x, "gone")
  check(code .. ": kein Kopfgeld: Zeile", W.chatHas(F(L.CHAT_EARNED_GONE, { name = "Anna", target = "Kalt Herz", gold = G(50) })))
  check(code .. ": drei Zeilen, nicht mehr", #W.AM.chat == 3, #W.AM.chat)
  W.settle()

  -- (3) one window per event: the payback notice of the same kill comes first and stays; the bounty follows it
  local key = W.kill("Grimm", "Bart")
  W.tick(1); W.settle()
  ns.Store.AddRevenge(key, true)
  W.tick()
  B = banner(W)
  local revKicker = B and B.kicker._text
  check(code .. ": Rache-Meldung steht", B and B:IsShown() and B.key == key, revKicker)
  -- every notice that comes up from here on (kicker without spaces, line)
  local seen = {}
  local slip = ns.Extras.Slip
  local realBanner = B
  local function note()
    local b = banner(W)
    if b and b:IsShown() then
      local sig = kick(b) .. "|" .. tostring(b.line._text)
      if seen[#seen] ~= sig then seen[#seen + 1] = sig end
    end
  end
  -- the mock plays no animation by itself: every few steps the running ones end (the notice's hold and fade)
  local function poll(sec)
    for i = 1, math.floor(sec / 0.5) do
      W.tick(0.5); note()
      if i % 4 == 0 then W.BM.FinishAnims(); note() end
    end
  end
  W.earn({ key = key, name = "Grimm Bart", owner = "Bert Wurst", char = "Ich Selbst", t = _G.time(), g = 30, via = "guild", state = "sent" })
  W.earn({ key = key, name = "Grimm Bart", owner = "Cora Wurst", char = "Ich Selbst", t = _G.time(), g = 70, via = "friends", state = "sent" })
  W.tick(1.2)
  B = banner(W)
  check(code .. ": Rache-Meldung bleibt stehen", B and B:IsShown() and B.kicker._text == revKicker, B and B.kicker._text)
  poll(40)
  local two = F(L.EARNED_SLIP_LINE, { gold = G(100), name = F(L.NAMES_PLUS, { name = "Cora", count = 1 }) })
  local earnedSeen = {}
  for _, sig in ipairs(seen) do if sig:find(earnedKick .. "|", 1, true) == 1 then earnedSeen[#earnedSeen + 1] = sig end end
  check(code .. ": erst Rache, dann EIN Zettel fuer beide Auslober", #seen >= 2 and seen[1]:find(earnedKick, 1, true) ~= 1
    and #earnedSeen == 1 and earnedSeen[1]:find(two, 1, true) ~= nil, table.concat(seen, " / "))
  B = banner(W)
  check(code .. ": danach nichts mehr", not (B and B:IsShown()), B and B.kicker._text)

  -- (3b) the other order in the same moment: the bounty's event first, the payback right after it. The slip waits
  -- (FD.EARNED_DELAY), so the payback notice is not pushed away and the bounty is not lost under it
  W.settle(); W.BM.FinishAnims(); W.tick(1)
  local key2 = W.kill("Hart", "Holz")
  W.tick(1); W.settle(); W.BM.FinishAnims(); W.tick(1)
  seen = {}
  W.earn({ key = key2, name = "Hart Holz", owner = "Dora Wurst", char = "Ich Selbst", t = _G.time(), g = 20, via = "guild", state = "sent" })
  W.tick(0.1)
  ns.Store.AddRevenge(key2, true)
  W.tick(0.1); note()
  poll(40)
  local one = F(L.EARNED_SLIP_LINE, { gold = G(20), name = "Dora" })
  local firstRev = seen[1] and seen[1]:find(earnedKick, 1, true) ~= 1
  local got = 0
  for _, sig in ipairs(seen) do if sig:find(earnedKick .. "|", 1, true) == 1 and sig:find(one, 1, true) then got = got + 1 end end
  check(code .. ": Kopfgeld zuerst gefeuert: Rache steht zuerst, Zettel danach", firstRev and got == 1, table.concat(seen, " / "))

  -- (4) the poster after "Paid": one line; with the bounty taken back, and without
  W.AM.chat = {}
  local c = { key = "Taeter-Lamm", name = "Taeter Lamm", by = "Dora Wurst", t = _G.time(), g = 40, char = "Ich Selbst", state = "paid" }
  ns:Fire("CLAIM_SETTLED", c, true)
  check(code .. ": Bezahlt: eingeloest und zurueckgenommen",
    W.chatHas(F(L.CHAT_CLAIM_SETTLED, { target = "Taeter Lamm", gold = G(40), name = "Dora" })), W.AM.chat[1])
  ns:Fire("CLAIM_SETTLED", c, false)
  check(code .. ": Bezahlt ohne Kopfgeld: abgehakt",
    W.chatHas(F(L.CHAT_CLAIM_SETTLED_KEPT, { target = "Taeter Lamm", gold = G(40), name = "Dora" })), W.AM.chat[2])

  -- (5) hostile events: broken entries never break anything
  for _, bad in ipairs({ 5, "x", { key = 7, g = "viel", owner = {}, state = "weird", t = "gestern" }, {} }) do
    ns:Fire("EARNED_NEW", bad)
    ns:Fire("EARNED_CHANGED", bad, "sent")
    ns:Fire("CLAIM_SETTLED", bad, true)
  end
  W.tick(2); W.settle()
  local sv = "SECRET_NAME"   -- a hidden value of the UI mock (issecretvalue answers true)
  ns:Fire("EARNED_NEW", { key = sv, name = sv, owner = sv, g = sv, t = sv, state = sv })
  W.tick(2); W.settle()
  local n, e = W.errs()
  check(code .. ": keine Fehler", n == 0, e)
end

-- (6) without the wire package nothing of it fires: the claim notice of 1.6.0 as before
do
  local W = X.world("deDE")
  local ns, L = W.ns, W.L
  W.AM.chat = {}
  ns.Feud.AddClaim("Taeter-Lamm", "Taeter Lamm", "Anna Alt", _G.time(), 50, "Ich Selbst")
  W.tick(); W.settle()
  check("ohne Leitung: Zeile Kopfgeld faellig wie 1.6.0", W.chatHas(W.F(L.CLAIM_LINE, { name = "Anna", target = "Taeter Lamm", gold = 50 })))
  local n, e = W.errs()
  check("ohne Leitung: keine Fehler", n == 0, e)
end

X.done("cu170 schuetze")
