-- Fund 5: Reisszwecke. (a) An der Karteikarte (Akte, ungeklaerter Tod) ist die Zwecke ausgeblendet (PosterMode), der
-- unsichtbare Knopf darueber bleibt aber klickbar und meldet nach 5 Klicks, die Zwecke habe gekuendigt.
-- (b) Klicks waehrend des Falls zaehlen weiter: ein einzelner Klick danach laesst sie sofort wieder fallen.
-- (c) Der Knopf faengt die Maus an einer Stelle, an der vorher nur das Buch (zum Ziehen) lag.
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
-- (c) bleibt offen (niedrig): der Knopf nimmt 28 x 28 die Maus; hier nur vermerkt, nicht geprueft
print(("  offen (c): unter der Zwecke liegt ziehbar: %d"):format(#drunter))
-- (b)
for _ = 1, 5 do b._scripts.OnClick(b) end
H.check("Vorbedingung: 5 Klicks, sie faellt", b.fall:IsPlaying())
for _ = 1, 5 do b._scripts.OnClick(b) end       -- ungeduldig weitergeklickt, waehrend sie faellt
b.fall:Stop()                                    -- Fall und Wiederaufhaengen sind durch (unter 2 s)
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
