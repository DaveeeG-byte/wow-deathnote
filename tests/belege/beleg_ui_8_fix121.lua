-- 1.2.1 after the hunt, UI: book draggable at the poster (M1), double-click guard for "Undo" (M2),
-- /dn kopfgeld (M3, N4, N5), short lines "Bounty"/"Avenged by" with tooltip in all 21 languages (M4),
-- "last seen" stays (N1), coin after expiry (N2), one rule for the pardoned (N6), click areas (N7),
-- tooltip with the rest (N8), no garbage without bounty (N9).
-- Usage: nice -n 15 luajit beleg_ui_8_fix121.lua <project copy>. All names made up.
package.path = (arg[0]:match("^(.*)/[^/]+$") or ".") .. "/?.lua;" .. package.path
local K = require("_kopf_ui")

local function welt(code, opts)
  local W = K.world(code or "deDE", opts)
  local ns, t = W.ns, _G.time()
  W.key = ns.Store.ApplyKill({ name = "Grimm", surname = "Bart", class = "MAGE", level = 40, race = "Orc", raceLoc = "Orc", guild = "Die Boesen" },
    { t = t - 100, zone = "Z", me = "Varorak Narenmar", source = "recap" }, true)
  W.key2 = ns.Store.ApplyKill({ name = "Ohne", surname = "Geld", class = "MAGE", level = 40 },
    { t = t - 300, zone = "Z", me = "Varorak Narenmar", source = "recap" }, true)
  W.tick(40); W.settle()
  ns:Fire("TOGGLE_UI"); W.tick(); W.settle()
  W.E = W.frameWith(function(f) return f.stampNr1 and f.hunt end)
  W.zeigen = function(key) ns.UI.ShowEnemy(key); W.tick() end
  W.info = function()
    local o = {}
    for i = 1, #W.E.info do local fs = W.E.info[i]; if fs:IsVisible() and (fs._text or "") ~= "" then o[#o + 1] = fs end end
    return o
  end
  W.chat = function() return W.AM.chat[#W.AM.chat] or "" end
  return W
end
local function vorn(s) return (s:match("^(.-){") or s) end
local function zeileMit(W, pre) for _, fs in ipairs(W.info()) do if fs._text:find(pre, 1, true) then return fs end end end
local function zeileVon(W, key)
  for _, r in ipairs(W.rows()) do local it = r.item; if it and (it.key == key or (it.wrap and it.r and it.r.key == key)) then return r end end
end
local function menue(W, row)
  row._scripts.OnClick(row, "RightButton"); W.tick()
  local menu, m = rawget(W.BM.G, "DeathNoteMenu"), {}
  if menu and menu:IsShown() then
    for _, it in ipairs(menu.items) do if it:IsShown() then m[W.keyOf[(it.text or it.label)._text] or "?"] = it end end
  end
  return m, menu
end
local function zu(menu) if menu and menu:IsShown() then menu.blocker._scripts.OnClick(menu.blocker) end end

------------------------------------------------------------------------ (1) M1 dragging the poster
do
  local W = welt("deDE")
  local E, F = W.E, rawget(W.BM.G, "DeathNoteFrame")
  W.zeigen(W.key)
  K.check("1 Plakat nimmt die Maus (Rechtsklick)", E:IsMouseEnabled())
  K.check("1 Ziehen am Plakat ist angemeldet", E._scripts.OnDragStart ~= nil and E._scripts.OnDragStop ~= nil)
  F._moving = nil
  if E._scripts.OnDragStart then E._scripts.OnDragStart(E) end
  K.check("1 Ziehen am Plakat bewegt das Buch", F._moving == true)
  if E._scripts.OnDragStop then E._scripts.OnDragStop(E) end
  local n, e = W.errs(); K.check("1 keine Fehler", n == 0, e)
end

------------------------------------------------------------------------ (2) M2 double click
do
  local W = welt("deDE")
  local ns, E, L = W.ns, W.E, W.L
  W.zeigen(W.key)
  local b1 = E.buttons[1]
  b1._scripts.OnClick(b1, "LeftButton"); b1._scripts.OnClick(b1, "LeftButton")
  local e = ns.Store.Get(W.key)
  K.check("2 zwei Klicks im selben Bild: eine Rache", e.revenge == 1 and e.revengeHand == 1, e.revenge)
  W.tick(0.15); W.click(b1)
  K.check("2 Doppelklick (0,15 s): die Rache bleibt", e.revenge == 1, e.revenge)
  K.check("2 der Knopf heisst weiter Rueckgaengig", b1.text._text == L.ACT_UNDO, b1.text._text)
  W.tick(0.5); W.click(b1)
  K.check("2 danach nimmt Rueckgaengig zurueck", e.revenge == 0, e.revenge)
end

------------------------------------------------------------------------ (3) M3, N4, N5 /dn kopfgeld
do
  local W = welt("deDE", { guild = false, friends = {} })
  local ns, L = W.ns, W.L
  local function own() local n = 0; for _, x in pairs(ns.Store.DB().bounty or {}) do for _ in pairs(x) do n = n + 1 end end; return n end
  ns.HandleSlash("kopfgeld")
  K.check("3 ohne alles, ohne Kopfgeld: sagt es", W.AM.chat[#W.AM.chat - 1] and W.AM.chat[#W.AM.chat - 1]:find(L.CHAT_BOUNTY_LIST_NONE, 1, true) ~= nil)
  ns.HandleSlash("kopfgeld Tippfeler Bart 90")
  K.check("3 Name aus keinem Buch: abgelehnt", own() == 0 and W.chat():find(vorn(L.CHAT_BOUNTY_UNKNOWN):sub(1, 1) == "{" and "steht in keinem" or vorn(L.CHAT_BOUNTY_UNKNOWN), 1, true) ~= nil
    or (own() == 0 and W.chat():find("Tippfeler Bart", 1, true) ~= nil and W.chat():find((L.CHAT_BOUNTY_UNKNOWN:match("}(.-)%.") or "x"), 1, true) ~= nil), W.chat())
  for _, cmd in ipairs({ "kopfgeld Grimm Bart 50g", "kopfgeld Grimm Bart 50 Gold", "kopfgeld Grimm Bart 1e3" }) do
    ns.HandleSlash(cmd)
    K.check("3 Betrag mit Einheit: Regelzeile (" .. cmd .. ")", own() == 0 and W.chat():find(L.CHAT_BOUNTY_BAD, 1, true) ~= nil, W.chat())
  end
  ns.HandleSlash("kopfgeld Grimm Bart 500")
  K.check("3 ohne Gilde und Freunde: kein 'sehen es'", own() == 1 and W.chat():find(ns.F(L.CHAT_BOUNTY_SET_ALONE, { name = "Grimm Bart", gold = 500 }), 1, true) ~= nil
    and W.chat() ~= ("|cffc41e3aDeathNote|r: " .. ns.F(L.CHAT_BOUNTY_SET, { name = "Grimm Bart", gold = 500 })), W.chat())
  ns.HandleSlash("kopfgeld Ohne Geld 70")
  ns.HandleSlash("kopfgeld")
  local line = W.chat()
  K.check("3 ohne alles: listet die eigenen", line:find("Grimm Bart", 1, true) and line:find("Ohne Geld", 1, true) and line:find("2", 1, true), line)
  -- struck: the own bounty goes too (no poster any more)
  ns.Store.Remove(W.key2); W.tick()
  K.check("3 gestrichener Taeter: eigenes Kopfgeld zurueckgenommen", ns.Guild.OwnBounty(W.key2) == nil and own() == 1)
  local n, e = W.errs(); K.check("3 keine Fehler", n == 0, e)
end

------------------------------------------------------------------------ (4) M4 short lines, in 192 px, with tooltip
local NAMES = { "Annabellchen", "Bertramchens", "Cordulachens", "Dietmarchens" }
for _, code in ipairs(K.CODES) do
  local W = welt(code)
  local ns, E, L, P, t = W.ns, W.E, W.L, W.P, _G.time()
  -- (a) four posters with long names and maximum amount, four avengers
  for i, n in ipairs(NAMES) do W.gmsg(P.EncodeBounty(W.key2, n .. " Wurst", 99999, t), n .. " Wurst-Forever") end
  for i, n in ipairs(NAMES) do W.gmsg(P.EncodeAvenged(W.key2, n .. " Wurst", t - 5 - i * 40, false), n .. " Wurst-Forever"); W.tick(20) end
  W.tick(5); W.zeigen(W.key2)
  local zu_breit = {}
  for _, fs in ipairs(W.info()) do local w = K.estimate(fs); if w > 192 then zu_breit[#zu_breit + 1] = math.floor(w) .. "px " .. fs._text end end
  local bz, az = zeileMit(W, vorn(L.POSTER_BOUNTY_MANY)), zeileMit(W, vorn(L.POSTER_AVENGED))
  K.check(code .. " 4a beide Zeilen da", bz ~= nil and az ~= nil)
  K.check(code .. " 4a alles in 192 px", #zu_breit == 0, table.concat(zu_breit, " / "))
  K.check(code .. " 4a Tooltip Kopfgeld mit allen vier", E.bountyLineHit:IsShown() and #(E.bountyLineHit.tip or {}) >= 5)
  K.check(code .. " 4a Tooltip gerächt mit allen vier", E.avengedHit:IsShown() and #(E.avengedHit.tip or {}) >= 5)
  -- (b) one foreign poster with a long name and maximum amount, one avenger with 99
  local W2 = welt(code)
  W2.gmsg(W2.P.EncodeBounty(W2.key2, "Annabellchen Wurst", 99999, t), "Annabellchen Wurst-Forever")
  local av = W2.ns.Store.DB(); av.avenged = { [W2.key2] = { by = { ["Bertramchens Wurst"] = 99 }, log = {}, t = t } }
  W2.tick(1); W2.zeigen(W2.key2)
  zu_breit = {}
  for _, fs in ipairs(W2.info()) do local w = K.estimate(fs); if w > 192 then zu_breit[#zu_breit + 1] = math.floor(w) .. "px " .. fs._text end end
  K.check(code .. " 4b ein Auslober, ein Raecher: in 192 px", #zu_breit == 0, table.concat(zu_breit, " / "))
  K.check(code .. " 4b Tooltip gerächt auch bei einem", W2.E.avengedHit:IsShown() and W2.E.avengedHit.tip ~= nil)
  -- (c) own bounty
  local W3 = welt(code)
  W3.ns.Guild.SetBounty(W3.key2, 99999); W3.tick(1); W3.zeigen(W3.key2)
  zu_breit = {}
  for _, fs in ipairs(W3.info()) do local w = K.estimate(fs); if w > 192 then zu_breit[#zu_breit + 1] = math.floor(w) .. "px " .. fs._text end end
  K.check(code .. " 4c eigenes: in 192 px", #zu_breit == 0, table.concat(zu_breit, " / "))
  local n, e = W.errs(); K.check(code .. " 4 keine Fehler", n == 0, e)
end

------------------------------------------------------------------------ (5) N1, N7: seen stays, areas in front
do
  local W = welt("deDE")
  local ns, E, L, P, t = W.ns, W.E, W.L, W.P, _G.time()
  local key = ns.Store.ApplyKill({ name = "Maximilianus", surname = "Vonundzuhohenstein", class = "MAGE", level = 40 },
    { t = t - 50, zone = "Z", me = "Varorak Narenmar", source = "recap" }, true)
  for i = 1, 3 do ns.Store.ApplyKill({ name = "Maximilianus", surname = "Vonundzuhohenstein", class = "MAGE", level = 40 }, { t = t - 40 + i, zone = "Z", me = "Varorak Narenmar", source = "recap" }, true) end
  ns.Store.Get(key).lastSeen = { t = t - 60, zone = "Z" }
  W.gmsg(P.EncodeHunt({ key = key, display = "Maximilianus Vonundzuhohenstein", class = "MAGE", level = 40, t = t - 50, by = "Kollege Wurst", why = "weil" }))
  W.tick(12); W.settle()
  ns.Guild.SetBounty(key, 500); W.tick(1); W.zeigen(key)
  local seen = false
  for _, fs in ipairs(W.info()) do if fs._text:find(vorn(L.POSTER_LAST_SEEN), 1, true) or fs._text:find(vorn(L.POSTER_LAST_SEEN_IN), 1, true) then seen = true end end
  K.check("5 N1: mit Kopfgeld bleibt 'zuletzt gesehen'", seen)
  K.check("5 N1: der Tooltip ueber dem Steckbrief zeigt die Kopfgeld-Zeile", E.infoHit:IsShown() and table.concat(E.infoHit.tip or {}, "|"):find(vorn(L.POSTER_BOUNTY_MINE) ~= "" and "500" or "500", 1, true) ~= nil)
  -- Grimm Bart with race, guild and bounty: bounty line before the profile tooltip
  W.gmsg(P.EncodeBounty(W.key, "Kollege Wurst", 300, t)); W.tick(1); W.zeigen(W.key)
  K.check("5 N7: Rasse faellt weg, Kopfgeld-Zeile und Steckbrief-Tooltip beide da", E.infoHit:IsShown() and E.bountyLineHit:IsShown())
  -- (on the same level the first named would not win in the mock: the higher level must decide)
  K.check("5 N7: Kopfgeld-Zeile liegt vor dem Steckbrief-Tooltip", W.BM.TopFrame(E.bountyLineHit, E.infoHit) == E.bountyLineHit)
  W.zeigen(W.key)
  W.click(E.bountyHit)
  K.check("5 N7: bei offener Eingabe ist die Kopfgeld-Flaeche weg", E.bountyEdit:IsShown() and not E.bountyHit:IsShown())
  W.ns.UI.Refresh(); W.tick()
  K.check("5 N7: auch nach einem Neuaufbau", E.bountyEdit:IsShown() and not E.bountyHit:IsShown())
  E.bountyEdit._scripts.OnEscapePressed(E.bountyEdit); W.tick()
  K.check("5 N7: nach Esc wieder da", E.bountyHit:IsShown())
end

------------------------------------------------------------------------ (6) N2 coin after expiry, N6 pardoned, N8, N9
do
  local W = welt("deDE")
  local ns, E, L, P, t = W.ns, W.E, W.L, W.P, _G.time()
  ns.Store.Setting("guild.huntExpire", 30)
  W.gmsg(P.EncodeBounty(W.key, "Kollege Wurst", 300, t - 29 * 86400)); W.tick(1)
  K.check("6 N2: frisch: Muenze", ns.Guild.HasBounty(W.key) == true)
  W.AM.epoch = W.AM.epoch + 2 * 86400; W.tick(1)
  K.check("6 N2: abgelaufen: keine Muenze (ohne /reload)", ns.Guild.HasBounty(W.key) == false)
  ns.Store.Setting("guild.huntExpire", 0)
  -- N6: pardoned: neither menu nor poster; with an own bounty both (to take it back)
  ns.Store.SetStatus(W.key2, "pardoned"); W.tick(); W.zeigen(W.key2)
  local m, menu = menue(W, zeileVon(W, W.key2)); zu(menu)
  K.check("6 N6: begnadigt: kein Menuepunkt, keine Klickflaeche", m.ACT_BOUNTY == nil and not E.bountyHit:IsShown())
  ns.Store.SetStatus(W.key2, "wanted"); ns.Guild.SetBounty(W.key2, 5); ns.Store.SetStatus(W.key2, "pardoned"); W.tick(); W.zeigen(W.key2)
  m, menu = menue(W, zeileVon(W, W.key2)); zu(menu)
  K.check("6 N6: begnadigt mit eigenem: beides da", m.ACT_BOUNTY ~= nil and E.bountyHit:IsShown())
  -- N8: 25 posters: tooltip ends with "and 5 more"
  for i = 1, 25 do W.gmsg(P.EncodeBounty(W.key, "Kollege" .. string.char(64 + i) .. " Wurst", 10, t), "Kollege" .. string.char(64 + i) .. " Wurst-Forever"); W.AM.Advance(130) end
  W.tick(1); W.zeigen(W.key)
  local tip = E.bountyHit.tip or {}
  local mehr = false
  for _, l in ipairs(tip) do if l == ns.F(L.MORE_LINE, { count = #select(1, ns.Guild.Bounties(W.key)) - 20 }) then mehr = true end end
  K.check("6 N8: Tooltip nennt den Rest", #select(1, ns.Guild.Bounties(W.key)) > 20 and mehr, #select(1, ns.Guild.Bounties(W.key)))
  -- N9: without bounty and without avenger no new tables
  local r1 = select(1, ns.Guild.Bounties("Niemand-Hier"))
  local r2 = select(1, ns.Guild.Bounties("Keiner-Da"))
  K.check("6 N9: ohne Kopfgeld dieselbe leere Tabelle", r1 == r2 and next(r1) == nil)
  K.check("6 N9: Gesamtzahl gerächt ohne Tabelle", ns.Guild.AvengedTotal ~= nil and ns.Guild.AvengedTotal("Niemand-Hier") == 0)
  local n, e = W.errs(); K.check("6 keine Fehler", n == 0, e)
end
K.done("beleg_ui_8 fix-121")
