-- Fixer 1.7.0, copy of hunt test ju04 adapted to the new E4 (several claims open on one bounty, one paid): Berta
-- declined Anton's claim and paid Carl's. Anton's claim has no "Open again" (it would do nothing); its sheet says to
-- whom the bounty is paid. Carl's paid claim keeps "Open again". All names are made up.
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_fx170.lua")
local check = J.check
local W = J.welt("deDE")
local a = J.client(W, "Anton", "Wurst", J.GILDE)
local b = J.client(W, "Berta", "Senf", J.GILDE, { ui = true })
local c = J.client(W, "Carl", "Kraut", J.GILDE)
a.login(); b.login(); c.login(); W.lauf(90)
local L, F = b.ns.L, b.ns.F
b.ns.Guild.SetBounty(J.KEY, 50); W.lauf(10)
J.toetet(a); W.lauf(5)
local first = J.claims(b)[1]
check("Vorbedingung: Antons Anspruch", first ~= nil and first.by == "Anton Wurst")
b.ns.Feud.SetClaim(first, "declined"); W.lauf(120)
J.toetet(c); W.lauf(5); W.ruhe()
local second = J.claims(b)[1]
check("Vorbedingung: Carls Anspruch offen", second ~= first and second.by == "Carl Kraut" and second.state == "open")
check("Vorbedingung: Carl bezahlt", b.ns.Feud.SetClaim(second, "paid") == true and b.ns.Feud.Rival(first) == second)
W.lauf(5); W.ruhe()
b.ns.FeudUI.ShowClaims(); W.lauf(0.3); W.ruhe()
local row
for _, r in ipairs(b.rows()) do if r.item.fdItem == "claim" and r.item.c == first then row = r end end
check("Zeile des abgelehnten Anspruchs", row ~= nil)
if row then row._scripts.OnClick(row, "LeftButton") end
W.lauf(0.2)
local S = b.sheet()
check("kein 'Wieder offen' auf dem abgelehnten", S and not (S.fdA:IsShown() and S.fdA.text._text == L.ACT_REOPEN))
check("Blatt sagt, an wen bezahlt", S and tostring(S.tiny._text):find(F(L.CLAIM_RIVAL_PAID, { name = "Carl" }), 1, true) ~= nil,
  S and S.tiny._text)
-- a refused change still says so in the chat (the stand-in refuses once)
local real = b.ns.Feud.SetClaim
b.ns.Feud.SetClaim = function() return false end
for _, r in ipairs(b.rows()) do if r.item.fdItem == "claim" and r.item.c == second then r._scripts.OnClick(r, "LeftButton") end end
W.lauf(1)
b.chat = {}
if S.fdA:IsShown() then b.click(S.fdA) end
W.lauf(1)
local said = false
for _, l in ipairs(b.chat) do if tostring(l):find(L.CHAT_CLAIM_UNCHANGED, 1, true) then said = true end end
check("abgelehnte Aenderung: Chatzeile", said, b.chat[1])
b.ns.Feud.SetClaim = real
J.done()
