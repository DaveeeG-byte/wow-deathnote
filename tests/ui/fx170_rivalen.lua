-- Fixer 1.7.0 (JU-04, new E4): the sheet of an open claim names how many other claims are open on the same bounty
-- (Feud.Rivals) and that "Paid" declines them; with a paid one (Feud.Rival) "Paid" is gone. Stand-in of the interface
-- between the two fixers. Without both functions (an older logic) the sheet as before. All names are made up.
local X = dofile((arg[0]:match("^(.*)/") or ".") .. "/_cu170.lua")
local check = X.check
for _, code in ipairs({ "deDE", "enUS" }) do
  local W = X.world(code)
  X.fake(W)
  local ns, L, F = W.ns, W.L, W.F
  W.open(); W.tab("open")
  local t = _G.time()
  local c1 = ns.Feud.AddClaim("Taeter-Lamm", "Taeter Lamm", "Anna Wurst", t - 300, 40, "Ich Selbst")
  local c2 = ns.Feud.AddClaim("Taeter-Lamm", "Taeter Lamm", "Dirk Wurst", t - 200, 40, "Ich Selbst")
  W.tick(); W.settle()
  local realRival, realRivals = ns.Feud.Rival, ns.Feud.Rivals
  ns.Feud.Rival = function() return nil end
  ns.Feud.Rivals = function(c) return c == c1 and { c2 } or (c == c2 and { c1 } or {}) end
  ns.UI.Refresh(); W.tick()
  W.click(W.find(L.VIEW_CLAIMS .. "  2"))
  local S = ns.FeudUI.Sheet()
  local want = F(L.CLAIM_RIVALS, { count = 1, button = L.ACT_PAID })
  check(code .. ": offenes Blatt nennt die anderen offenen", tostring(S.tiny._text):find(want, 1, true) ~= nil, S.tiny._text)
  check(code .. ": Bezahlt bleibt", W.find(L.ACT_PAID) ~= nil)
  -- one of them paid: no "Paid" on the other, the sheet names him
  ns.Feud.Rival = function(c) return c == c1 and { by = "Dirk Wurst", state = "paid" } or nil end
  ns.Feud.Rivals = function() return {} end
  ns.FeudUI.oview = "claims"; ns.UI.Refresh(); W.tick(1)
  for _, f in ipairs(W.rows()) do if f.item.c == c1 then f._scripts.OnClick(f, "LeftButton"); W.tick() end end
  check(code .. ": bezahlter Rivale: kein Bezahlt", W.find(L.ACT_PAID) == nil and W.find(L.ACT_DECLINE) ~= nil)
  check(code .. ": Satz an wen", tostring(S.tiny._text):find(F(L.CLAIM_RIVAL_PAID, { name = "Dirk" }), 1, true) ~= nil, S.tiny._text)
  -- without the functions: as before
  ns.Feud.Rival, ns.Feud.Rivals = nil, nil
  ns.UI.Refresh(); W.tick(1)
  check(code .. ": ohne Rival/Rivals: Bezahlt da", W.find(L.ACT_PAID) ~= nil)
  ns.Feud.Rival, ns.Feud.Rivals = realRival, realRivals
  local n, e = W.errs()
  check(code .. ": keine Fehler", n == 0, e)
end
X.done("fx170 rivalen")
