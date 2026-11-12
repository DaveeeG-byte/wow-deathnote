-- Finding 5: thumbtack. (a) On the index card (case file, unsolved death) the tack is hidden (PosterMode), but the
-- invisible button over it stays clickable and reports after 5 clicks that the tack has quit.
-- (b) Clicks during the fall keep counting: a single click afterwards drops it again at once.
-- (c) The button catches the mouse at a spot where before only the book (for dragging) was.
local here = arg[0]:match("^(.*)/[^/]+$") or "."
package.path = here .. "/?.lua;" .. package.path
local H = require("_kopf_hu")
local ns = H.welt("deDE")
local T = H.SRC.deDE
local key = H.kill(ns, "Grimm", "Bart"); H.away()
ns:Fire("TOGGLE_UI"); H.settle()
ns.UI.ShowEnemy(key); H.settle()
local b
for _, f in ipairs(H.BM.frames) do if f.fall and f.wobble then b = f end end
assert(b, "Reisszwecken-Knopf nicht gefunden")
local P = b._parent
H.check("Vorbedingung: am Plakat ist die Zwecke zu sehen und klickbar", P.pin:IsShown() and b:IsVisible())
-- (c)
local l, bo, r, t = H.rect(b)
local cx, cy = (l + r) / 2, (bo + t) / 2
local drunter = {}
for _, f in ipairs(H.BM.frames) do
  if f ~= b and f._mouse and (f._kind == "Frame" or f._kind == "Button") and f:IsVisible() then
    local a, c, d, e = H.rect(f)
    if a and a <= cx and d >= cx and c <= cy and e >= cy and f._scripts.OnDragStart then drunter[#drunter + 1] = f._name or f._kind end
  end
end
-- (c) stays open (low): the button takes the mouse over 28 x 28; only noted here, not checked
print(("  offen (c): unter der Zwecke liegt ziehbar: %d"):format(#drunter))
-- (b)
for _ = 1, 5 do b._scripts.OnClick(b) end
H.check("Vorbedingung: 5 Klicks, sie faellt", b.fall:IsPlaying())
for _ = 1, 5 do b._scripts.OnClick(b) end       -- clicked on impatiently while it falls
b.fall:Stop()                                    -- fall and re-hanging are done (under 2 s)
H.AM.chat = {}
b._scripts.OnClick(b)
H.check("(b) ein Klick nach dem Wiederaufhaengen wackelt nur", not b.fall:IsPlaying() and H.humorChat() == 0,
  "faellt sofort wieder, Chatzeilen: " .. H.humorChat())
b.fall:Stop(); b.clicks = 0
-- (a)
local j = { t = _G.time(), kind = "pvp", sure = false, counted = true, myLevel = 40, candidates = { "Eins-A", "Zwei-B" } }
ns.Store.RecordDeath(j)
ns.UI.ShowCase(j); H.settle()
H.check("Vorbedingung: Akte offen, Zwecke ausgeblendet, Klebestreifen da", P:IsVisible() and not P.pin:IsShown() and P.card:IsShown())
H.check("(a) Akte: Knopf der Zwecke nicht klickbar", not b:IsVisible(), "sichtbar und Maus an: " .. tostring(b._mouse))
H.AM.chat = {}; ns.Humor.said = nil
H.vor(3)
for _ = 1, 5 do b._scripts.OnClick(b) end
H.check("(a) Akte: keine Zeile ueber eine Zwecke, die nicht da ist", ns.Humor.said ~= T.PIN, "Zeile PIN im Chat")
H.ende("beleg_hu_5_zwecke")
