-- 1.7.0 claim: Unsolved > Claims both ways. Without anything owed to me the view stays as in 1.6.4 (no heads); with it
-- two heads, what I owe first, then what is owed to me; a row per entry with its state word; the sheet says how much
-- from whom, the target, my char, the state and what to do now; "Remove from list" in an end state or unconfirmed for
-- more than a day. The switch comes as soon as there is something either way; the red number on the tab and the
-- number on "Claims" count only what I have to settle. Broken entries and secret values never break the view. An open
-- claim on my bounty says before the click that "Paid" takes the bounty back. All names are made up.
local X = dofile((arg[0]:match("^(.*)/") or ".") .. "/_cu170.lua")
local check = X.check

local function items(W)
  local out = {}
  for _, r in ipairs(W.rows()) do out[#out + 1] = r end
  return out
end
local function kinds(W)
  local t = {}
  for _, r in ipairs(items(W)) do
    local it = r.item
    t[#t + 1] = it.fdSec and ("head:" .. it.fdSec) or (it.fdItem or "?")
  end
  return table.concat(t, ",")
end
local function select(W, pred)
  for _, r in ipairs(items(W)) do
    if pred(r.item) then r._scripts.OnClick(r, "LeftButton"); W.tick(); return r end
  end
end

for _, code in ipairs({ "deDE", "enUS" }) do
  local W = X.world(code)
  X.fake(W)
  local ns, L, F = W.ns, W.L, W.F
  local G = ns.UI.Kit.GF.Gold
  W.kill("Grimm", "Bart")
  W.open(); W.tab("open")
  local _, LP = W.frames()
  local red0 = ns.UI.Kit.UX.TabCount("open")
  check(code .. ": leer: kein Umschalter", not (LP.fdOpen and LP.fdOpen:IsVisible()))

  -- only owed to me
  local t = _G.time()
  local sent = W.earn({ key = "Kalt-Herz", name = "Kalt Herz", owner = "Anna Wurst", char = "Ich Selbst", t = t - 3600, g = 50,
    via = "guild", state = "sent" }, true)
  ns.UI.Refresh(); W.tick()
  check(code .. ": nur zustehen: Umschalter da", LP.fdOpen and LP.fdOpen:IsVisible())
  check(code .. ": Zahl am Wort Ansprueche zaehlt nur Geschuldetes", W.find(L.VIEW_CLAIMS) ~= nil and W.find(L.VIEW_CLAIMS .. "  1") == nil)
  check(code .. ": rote Zahl am Reiter unveraendert", ns.UI.Kit.UX.TabCount("open") == red0)
  W.click(W.find(L.VIEW_CLAIMS))
  check(code .. ": nur zustehen: Kopf und eine Zeile", kinds(W) == "head:earn,earned", kinds(W))
  local rows = items(W)
  check(code .. ": Kopf: Dir steht zu", rows[1] and rows[1].name._text == ns.UI.Kit.Spaced(L.SECTION_EARNED), rows[1] and rows[1].name._text)
  check(code .. ": Zeile: Ziel, unbestaetigt", rows[2] and rows[2].name._text == "Kalt Herz" and rows[2].mark._text == L.EARNED_SENT,
    rows[2] and rows[2].mark._text)
  local S = ns.FeudUI.Sheet()
  check(code .. ": Blatt: Gold von Anna", S and S:IsVisible() and S.big._text == F(L.EARNED_HEAD, { gold = G(50), name = "Anna" }),
    S and S.big._text)
  check(code .. ": Blatt: Ziel, Char, Zustand", tostring(S.small._text):find(F(L.CLAIM_FOR, { target = "Kalt Herz" }), 1, true)
    and tostring(S.small._text):find(F(L.EARNED_KILLED_BY, { name = "Ich" }), 1, true)
    and tostring(S.small._text):find(L.EARNED_SENT, 1, true), S.small._text)
  check(code .. ": Blatt: unbestaetigt erklaert", S.tiny._text == F(L.EARNED_NOTE_SENT, { name = "Anna", char = "Ich" }), S.tiny._text)
  check(code .. ": frisch unbestaetigt: kein Wegnehmen", W.find(L.ACT_EARNED_REMOVE) == nil)

  -- both ways
  local c = ns.Feud.AddClaim("Taeter-Lamm", "Taeter Lamm", "Dirk Wurst", t - 100, 40, "Ich Selbst")
  W.tick(); W.settle()
  W.click(W.find(L.VIEW_CLAIMS .. "  1"))
  check(code .. ": beides: erst Schulden, dann zustehen", kinds(W) == "head:owe,claim,head:earn,earned", kinds(W))
  select(W, function(it) return it.fdItem == "claim" end)
  check(code .. ": offener Anspruch: Blatt sagt, dass Bezahlt zuruecknimmt",
    tostring(S.tiny._text):find(F(L.CLAIM_PAID_TAKES, { button = L.ACT_PAID }), 1, true) ~= nil, S.tiny._text)
  check(code .. ": rote Zahl am Reiter unveraendert (beides)", ns.UI.Kit.UX.TabCount("open") == red0)

  -- every state of an entry owed to me
  local states = { open = "EARNED_NOTE_OPEN", paid = "EARNED_NOTE_PAID", declined = "EARNED_NOTE_DECLINED", gone = "EARNED_NOTE_GONE" }
  local words = { open = "CLAIM_OPEN", paid = "CLAIM_PAID", declined = "CLAIM_DECLINED", gone = "EARNED_GONE" }
  for _, st in ipairs({ "open", "paid", "declined", "gone" }) do
    W.change(sent, st)
    W.tick()
    local r = select(W, function(it) return it.fdItem == "earned" end)
    check(code .. ": Zustand " .. st .. ": Wort", r and r.mark._text == L[words[st]], r and r.mark._text)
    check(code .. ": Zustand " .. st .. ": Satz", S.tiny._text == F(L[states[st]], { name = "Anna" }), S.tiny._text)
    local can = W.find(L.ACT_EARNED_REMOVE) ~= nil
    check(code .. ": Zustand " .. st .. ": Wegnehmen " .. (st == "open" and "nein" or "ja"), can == (st ~= "open"))
  end
  -- unconfirmed for more than a day: may go
  W.change(sent, "sent")
  -- fixer 1.7.0 (JU-18): unconfirmed may go only after the 30 days the wire package keeps sending it
  sent.t = _G.time() - 2 * 86400
  ns.UI.Refresh(); W.tick()
  select(W, function(it) return it.fdItem == "earned" end)
  check(code .. ": unbestaetigt seit zwei Tagen: noch kein Wegnehmen", W.find(L.ACT_EARNED_REMOVE) == nil)
  sent.t = _G.time() - 31 * 86400
  ns.UI.Refresh(); W.tick()
  select(W, function(it) return it.fdItem == "earned" end)
  local rm = W.find(L.ACT_EARNED_REMOVE)
  check(code .. ": unbestaetigt seit 31 Tagen: Wegnehmen", rm ~= nil)
  W.tick(0.6)   -- fixer 1.7.0: the sheet's buttons are deaf for half a second after a change
  W.click(rm)
  check(code .. ": weggenommen", #W.earned == 0)
  check(code .. ": danach nur die Schulden, ohne Kopf", kinds(W) == "claim", kinds(W))
  -- fixer 1.7.0 (JU-02): after the last entry owed to me went, no sheet is picked (never the claim with "Paid")
  check(code .. ": danach kein Blatt mit Bezahlt", W.find(L.ACT_PAID) == nil)
  select(W, function(it) return it.fdItem == "claim" end)
  W.tick(0.6)
  W.click(W.find(L.ACT_PAID))
  check(code .. ": Bezahlt geht weiter ueber Feud.SetClaim", c.state == "paid")

  -- broken entries and secret values: the view stays
  W.earn({ key = 5, name = {}, owner = 7, char = true, t = "gestern", g = "viel", state = "weird" }, true)
  W.earn({}, true)
  table.insert(W.earned, "kein Eintrag")
  W.earn({ key = "SECRET_NAME", name = "SECRET_NAME", owner = "SECRET_NAME", char = "SECRET_NAME", t = "SECRET_NAME",
    g = "SECRET_NAME", state = "SECRET_NAME" }, true)
  ns.UI.Refresh(); W.tick()
  check(code .. ": kaputte Eintraege: Zeilen da", select(W, function(it) return it.fdItem == "earned" end) ~= nil, kinds(W))
  for _, r in ipairs(items(W)) do
    if r.item.fdItem == "earned" then r._scripts.OnClick(r, "LeftButton"); W.tick() end
  end
  local secretShown = false
  for _, f in ipairs(W.BM.frames) do if f._text == "SECRET_NAME" and f:IsVisible() then secretShown = true end end
  check(code .. ": Geheimwert nie angezeigt", not secretShown)
  local n, e = W.errs()
  check(code .. ": keine Fehler", n == 0, e)
end

-- without ns.Claim (an older wire package): Claims as in 1.6.4, no sentence about taking back
do
  local W = X.world("deDE")
  local ns, L, F = W.ns, W.L, W.F
  W.open(); W.tab("open")
  ns.Feud.AddClaim("Taeter-Lamm", "Taeter Lamm", "Dirk Wurst", _G.time() - 100, 40, "Ich Selbst")
  W.tick(); W.settle()
  W.click(W.find(L.VIEW_CLAIMS .. "  1"))
  check("ohne Claim: eine Zeile ohne Kopf", kinds(W) == "claim", kinds(W))
  local S = ns.FeudUI.Sheet()
  check("ohne Claim: Blatt wie 1.6.4", S.tiny._text == L.CLAIM_NOTE, S.tiny._text)
  local n, e = W.errs()
  check("ohne Claim: keine Fehler", n == 0, e)
end

X.done("cu170 ansprueche")
