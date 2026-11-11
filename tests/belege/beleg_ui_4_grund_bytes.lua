-- Beleg UI 4: Unterzeile der Abschussliste, Grund "ab 24 Bytes gekuerzt" (UI.lua, GF.WHY_ROW, GF.BindHuntRow).
-- Aufruf: nice -n 15 luajit beleg_ui_4_grund_bytes.lua <Projektkopie>
-- Die Grenze zaehlt Bytes, nicht Zeichen: ein Grund in kyrillischer Schrift (2 Bytes je Buchstabe) zeigt halb so
-- viele Buchstaben wie derselbe Grund in lateinischer Schrift, CJK ein Drittel. Dazu faellt ein vollstaendiges
-- Mehrbyte-Zeichen weg, das genau an der Grenze endet.
-- Gegenproben (gruen): der Schnitt zerreisst nie ein Zeichen (gueltiges UTF-8), Farbcodes und Pipes kommen nicht an,
-- kurzer Grund bleibt ganz.
-- Alle Namen sind erfunden; geprueft werden Zeichenzahlen, kein Wortlaut.
package.path = (arg[0]:match("^(.*)/[^/]+$") or ".") .. "/?.lua;" .. package.path
local K = require("_kopf_ui")

local function zeichen(s) local _, n = s:gsub("[^\128-\191]", ""); return n end
local function gueltig(s)
  local i, n = 1, #s
  while i <= n do
    local b = s:byte(i)
    local len = b < 0x80 and 1 or (b >= 0xC2 and b < 0xE0) and 2 or (b >= 0xE0 and b < 0xF0) and 3 or (b >= 0xF0 and b < 0xF5) and 4 or 0
    if len == 0 or i + len - 1 > n then return false end
    for k = 1, len - 1 do local c = s:byte(i + k); if c < 0x80 or c > 0xBF then return false end end
    i = i + len
  end
  return true
end
-- laengster Anfang des Grunds (ganze Zeichen), der in der Unterzeile steht
local function gezeigt(sub, why)
  local best, i = 0, 1
  while i <= #why do
    local b = why:byte(i)
    local len = b >= 0xF0 and 4 or b >= 0xE0 and 3 or b >= 0xC0 and 2 or 1
    local pre = why:sub(1, i + len - 1)
    if sub:find(pre, 1, true) then best = zeichen(pre) else break end
    i = i + len
  end
  return best
end

local W = K.world("deDE")
local ns, P, t = W.ns, W.P, _G.time()
local FAELLE = {
  { "lat24", ("abcdefghijklmnopqrstuvwx") },                         -- 24 Buchstaben, 24 Bytes
  { "kyr24", ("абвгдежзийклмнопрстуфхцч") },                         -- 24 Buchstaben, 48 Bytes
  { "cjk24", ("一二三四五六七八九十一二三四五六七八九十一二三四") },      -- 24 Zeichen, 72 Bytes
  { "grenze", ("abcdefghijklmnopqrstuv") .. "é" .. "xyz" },          -- é endet genau auf Byte 24
  { "mitte", ("abcdefghijklmnopqrstuvw") .. "é" .. "xyz" },          -- é liegt auf Byte 24 und 25
  { "kurz", "Umlaute äöü kurz" },
  { "farbe", "ein |cffff0000roter|r Grund |Hunit:1|h[klick]|h und mehr Text" },
}
for i, f in ipairs(FAELLE) do
  W.gmsg(P.EncodeHunt({ key = "Ziel" .. string.char(64 + i) .. "-Test", display = "Ziel" .. string.char(64 + i) .. " Test", class = "MAGE", level = 40,
    t = t - i, by = "Kollege Wurst", why = f[2] }))
end
W.tick(12)
ns:Fire("TOGGLE_UI"); W.tick(); W.settle()
W.tab("guild"); ns.UI.SetGuildView("hunt"); W.tick(); W.settle()
local subs = {}
for _, r in ipairs(W.rows()) do subs[r.item.key] = r.sub and r.sub._text or "" end
local shown = {}
for i, f in ipairs(FAELLE) do
  local key = "Ziel" .. string.char(64 + i) .. "-Test"
  local h = ns.Guild.Hunt(key, "all")
  local why = h and h.why or ""
  local sub = subs[key] or ""
  shown[f[1]] = gezeigt(sub, why)
  K.info(("%-7s Grund %2d Zeichen / %2d Bytes, in der Zeile %2d Zeichen"):format(f[1], zeichen(why), #why, shown[f[1]]))
  K.check(f[1] .. ": Zeile da und gueltiges UTF-8", sub ~= "" and gueltig(sub), sub)
  K.check(f[1] .. ": kein Pipe-Zeichen in der Zeile", not sub:find("|", 1, true), sub)
end
K.check("lat24: 24 lateinische Buchstaben stehen ganz da", shown.lat24 == 24, shown.lat24)
K.check("kurz: kurzer Grund mit Umlauten bleibt ganz", shown.kurz == zeichen("Umlaute äöü kurz"), shown.kurz)
K.check("kyr24: 24 kyrillische Buchstaben so viele wie lateinische (24)", shown.kyr24 == shown.lat24, shown.kyr24 .. " statt " .. shown.lat24)
K.check("cjk24: wenigstens 12 CJK-Zeichen (doppelt breit, halbe Zahl)", shown.cjk24 >= 12, shown.cjk24)
-- seit der Behebung zaehlt die Grenze Zeichen: ein Mehrbyte-Zeichen an Stelle 23 ist eines von 24
K.check("grenze: das Zeichen an der Grenze bleibt ganz (24 Zeichen)", shown.grenze == 24, shown.grenze)
K.check("mitte: kein zerrissenes Zeichen (24 Zeichen)", shown.mitte == 24, shown.mitte)
local n, e = W.errs()
K.check("keine Fehler", n == 0, e)
K.done("beleg_ui_4 Grund in Bytes")
