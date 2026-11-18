-- 1.6.0 feud: claims and filed entries in Unsolved. The switch Open | Claims | Filed comes only while there is one; a
-- claim shows Paid and Decline, settled Open again; a filed entry comes back with Take back; "Keep" in the poster menu
-- for an entry that would expire; a new claim comes as a notice on the slip and a chat line. Names made up.
local WT = arg[1] or "."
local X = dofile((arg[0]:match("^(.*)/") or ".") .. "/_fe160.lua")
local J = X.J

for _, code in ipairs({ "deDE", "enUS" }) do
  local t0 = 1700000000 + 1000
  local db = { days = 50, dayAt = math.floor(t0 / 86400) - 1,
    enemies = { ["Alt-Ling"] = { suspected = 1, status = "suspect", day = 1, deaths = { { t = t0 - 99999, role = "suspect" } } } } }
  local W = X.world(WT, code, db)
  local ns, L, F = W.ns, W.L, W.ns.F
  J.check(code .. ": Alt-Ling beim Start abgelegt", ns.Store.Get("Alt-Ling") == nil and ns.Feud.ExpiredCount() == 1)
  W.kill("Grimm", "Bart", nil, time() - 500)
  ns.Store.ApplyKill({ name = "Verd", surname = "Acht", class = "MAGE" }, { t = time() - 400, zone = "Z" }, false)
  W.open()
  W.tab("open")
  local _, LP, RP = W.frames()
  J.check(code .. ": Umschalter da (ein abgelegter Eintrag)", LP.fdOpen and LP.fdOpen:IsVisible())
  -- a claim comes in while the book is open
  W.AM.chat = {}
  local c = ns.Feud.AddClaim("Taeter-Lamm", "Taeter Lamm", "Anna Alt", time(), 50, "Ich Selbst")
  W.tick(); W.settle()
  local line = F(L.CLAIM_LINE, { name = "Anna", target = "Taeter Lamm", gold = 50 })
  local inChat = false
  for _, l in ipairs(W.AM.chat) do if tostring(l):find(line, 1, true) then inChat = true end end
  J.check(code .. ": Zeile im Chat", inChat, W.AM.chat[1])
  J.check(code .. ": Zettel gezeigt", W.BM.texts[line] == true)
  W.click(W.find(L.VIEW_CLAIMS .. "  1"))
  local rows = W.rows()
  J.check(code .. ": eine Anspruchszeile", #rows == 1 and rows[1].item.fdItem == "claim", #rows)
  J.check(code .. ": Zeile: Ziel, von Anna, offen", rows[1].name._text == "Taeter Lamm" and rows[1].mark._text == L.CLAIM_OPEN,
    rows[1].mark._text)
  J.check(code .. ": rechts der Satz", RP.empty:IsVisible() and RP.empty.small._text == line, RP.empty.small._text)
  local paid = W.find(L.ACT_PAID)
  J.check(code .. ": Knoepfe Bezahlt und Ablehnen", paid ~= nil and W.find(L.ACT_DECLINE) ~= nil)
  W.click(paid)
  J.check(code .. ": bezahlt", c.state == "paid")
  J.check(code .. ": danach Wieder offen", W.find(L.ACT_REOPEN) ~= nil and W.find(L.ACT_PAID) == nil)
  W.click(W.find(L.ACT_REOPEN))
  J.check(code .. ": wieder offen", c.state == "open")
  W.click(W.find(L.ACT_DECLINE))
  J.check(code .. ": abgelehnt", c.state == "declined")
  -- filed
  W.click(W.find(L.VIEW_FILED .. "  1"))
  rows = W.rows()
  J.check(code .. ": eine abgelegte Zeile mit Zurueckholen", #rows == 1 and rows[1].take:IsVisible()
    and rows[1].take.text._text == L.ACT_RESTORE, #rows)
  W.click(rows[1].take)
  J.check(code .. ": zurueckgeholt", ns.Store.Get("Alt-Ling") ~= nil and ns.Store.Get("Alt-Ling").keep == true)
  J.check(code .. ": Archiv leer", ns.Feud.ExpiredCount() == 0)
  -- back to Open: the old list
  W.click(W.find(L.VIEW_OPEN))
  rows = W.rows()
  local has = false
  for _, r in ipairs(rows) do if r.item.key == "Verd-Acht" then has = true end end
  J.check(code .. ": Offen zeigt den Verdacht wie vorher", has)
  -- "Keep" in the row menu of a suspect
  for _, r in ipairs(rows) do if r.item.key == "Verd-Acht" then W.click(r, "RightButton") end end
  local keep = W.find(L.ACT_KEEP)
  J.check(code .. ": Menue: Behalten", keep ~= nil)
  W.click(keep)
  J.check(code .. ": behalten gesetzt", ns.Store.Get("Verd-Acht").keep == true)
  local ok, err = W.errors()
  J.check(code .. ": keine Fehler", ok, err)
end

-- without claims and filed entries the switch stays away (Unsolved as before)
do
  local W = X.world(WT, "deDE")
  W.kill("Grimm", "Bart", nil, time() - 500)
  W.open(); W.tab("open")
  local _, LP = W.frames()
  J.check("ohne Ansprueche und Abgelegtes: kein Umschalter", not (LP.fdOpen and LP.fdOpen:IsVisible()))
end

J.done()
