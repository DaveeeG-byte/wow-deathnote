-- Fixer 1.7.0 (JU-10, text side): a bounty of another own char is dropped by guild and friends only at that char's next
-- login (Claim.WouldTake's second answer "later", CLAIM_SETTLED's third). Sheet and chat say so instead of promising it
-- now. Without "later" the words of the build. Stand-in of the wire package. All names are made up.
local X = dofile((arg[0]:match("^(.*)/") or ".") .. "/_cu170.lua")
local check = X.check
for _, code in ipairs({ "deDE", "enUS" }) do
  for _, later in ipairs({ "Berta Senf", false }) do
    local W = X.world(code)
    X.fake(W, { later = later or nil })
    local ns, L, F = W.ns, W.L, W.F
    local G = ns.UI.Kit.GF.Gold
    W.open(); W.tab("open")
    local c = ns.Feud.AddClaim("Taeter-Lamm", "Taeter Lamm", "Anton Wurst", _G.time() - 100, 45, "Berta Senf")
    W.tick(); W.settle()
    W.click(W.find(L.VIEW_CLAIMS .. "  1"))
    local S = ns.FeudUI.Sheet()
    local tag = code .. (later and " spaeter" or " sofort")
    local want = later and F(L.CLAIM_PAID_TAKES_LATER, { button = L.ACT_PAID, char = "Berta" })
      or F(L.CLAIM_PAID_TAKES, { button = L.ACT_PAID })
    check(tag .. ": Blatt", tostring(S.tiny._text):find(want, 1, true) ~= nil, S.tiny._text)
    W.AM.chat = {}
    ns:Fire("CLAIM_SETTLED", c, true, later or nil)
    local line = later and F(L.CHAT_CLAIM_SETTLED_LATER, { target = "Taeter Lamm", gold = G(45), name = "Anton", char = "Berta" })
      or F(L.CHAT_CLAIM_SETTLED, { target = "Taeter Lamm", gold = G(45), name = "Anton" })
    check(tag .. ": Chat", W.chatHas(line), W.AM.chat[1])
    local n, e = W.errs()
    check(tag .. ": keine Fehler", n == 0, e)
  end
end
X.done("fx170 spaeter")
