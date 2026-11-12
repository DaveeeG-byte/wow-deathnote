-- Finding 11 (estimate of the UI mock, measure in game): Humor.Apply sets the stamp text fixed at 13 pt, without the
-- fitting that Extras.Banner (11 pt from 1.6 times the field width) and the poster (16/13/11 pt) have. The field is
-- 96 wide, two lines. A single word wider than the field is broken mid-word or
-- cut off. Measured with the mock's width estimate (characters x size x font factor).
local here = arg[0]:match("^(.*)/[^/]+$") or "."
package.path = here .. "/?.lua;" .. package.path
local H = require("_kopf_hu")
local FAKTOR = { ["Fonts\\MORPHEUS.TTF"] = 0.5, ["Fonts\\FRIZQT__.TTF"] = 0.52, ["Fonts\\NIM_____.ttf"] = 0.45, ["Fonts\\SKURRI_CYR.TTF"] = 0.6 }
for _, code in ipairs({ "deDE", "enUS" }) do
  for art in pairs(H.SRC[code].STAMP) do
    local ns = H.welt(code, { guild = "Die Fachkr\195\164fte" })
    H.BM.measure = true
    local key
    if art == "pro" then
      ns:Fire("HUNT_BAGGED", "Ziel-Eins", "Hans", _G.time(), "guild"); H.settle()
    elseif art == "regular" then
      for i = 1, 10 do key = H.kill(ns, "Grimm", "Bart"); if i < 10 then H.away() end end
    else
      H.kill(ns, "Ober", "Schurke"); H.kill(ns, "Ober", "Schurke"); key = H.kill(ns, "Grimm", "Bart"); H.away()
      if art == "nr1" then key = "Ober-Schurke" end
      ns.Store.AddRevenge(key); H.settle()
    end
    local fs = H.banner().stampText
    local text = H.stampText()
    H.check(code .. " " .. art .. ": Vorbedingung, Humor-Stempel steht", text == H.SRC[code].STAMP[art], text)
    if text == H.SRC[code].STAMP[art] then
      local laengstes = 0
      for w in text:gmatch("%S+") do laengstes = math.max(laengstes, #(w:gsub("[\128-\191]", ""))) end
      local px = laengstes * fs._fontSize * (FAKTOR[fs._font] or 0.5)
      H.check(code .. " " .. art .. ": laengstes Wort passt in das Feld", px <= fs:GetWidth(),
        string.format("%.0f in %d bei %d pt", px, fs:GetWidth(), fs._fontSize))
    end
  end
end
H.ende("beleg_hu_11_stempelbreite")
