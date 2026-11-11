-- Gegenprobe Fund 17 und Dekoder (erwartet gruen): Zufallsbytes durch CleanReason, EncodeHunt, Decode.
-- Ergebnis immer gueltiges UTF-8 ohne Steuerzeichen und "|", hoechstens 60 Zeichen und 120 Bytes, Nachricht
-- hoechstens 255 Bytes; Decode wirft nie; CutUTF8 schneidet nie mitten im Zeichen (auch Kyrillisch, CJK, Emoji).
-- Aufruf: luajit beleg_f16_grund_und_dekoder_zufall.lua <Projektkopie> [Runden=60000] [Saat=7]
-- (fix-2) Belegtest der finalen Jagd, in die Suite uebernommen; Kopf: tests/beleg_helfer.lua
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local H = require("beleg_helfer")
local M = H.M
local N, SEED = tonumber(arg[2]) or 3000, tonumber(arg[3]) or 7

local function validUTF8(s)
  local i, n = 1, #s
  while i <= n do
    local b = s:byte(i)
    local need = b < 0x80 and 0 or (b >= 0xC2 and b <= 0xDF) and 1 or (b >= 0xE0 and b <= 0xEF) and 2 or (b >= 0xF0 and b <= 0xF4) and 3 or -1
    if need < 0 or i + need > n then return false end
    for k = 1, need do local c = s:byte(i + k); if c < 0x80 or c > 0xBF then return false end end
    i = i + need + 1
  end
  return true
end
local function chars(s) local _, c = s:gsub("[^\128-\191]", ""); return c end

H.lauf("Zufall", function()
  M.Reset()
  local ns = M.Load({ lang = "enUS" })
  local P = ns.Guild.Proto
  math.randomseed(SEED)
  local R = math.random
  local PIECES = { "Grund", " ", "|cffff0000", "|r", "|T", "|t", "|H", "|h", "||", "\n", "\t", "\0", "%", "%41", "Ж", "камень", "他在路上", "한국어", "😀",
    "\226\128\174", "\194\160", "\239\187\191", "\255", "\192\128", "\237\160\128", "\240\159", "\226\130", "é", "ß", "İ", "ı", "{count}", "\\" }
  local bad = {}
  local function note(k, s) bad[k] = bad[k] or s end
  for i = 1, N do
    local parts = {}
    for _ = 1, R(1, 40) do
      parts[#parts + 1] = R() < 0.25 and string.char(R(0, 255)) or PIECES[R(#PIECES)]
    end
    local raw = table.concat(parts)
    local ok, why = pcall(P.CleanReason, raw)
    if not ok then note("CleanReason wirft", why) else
      if not validUTF8(why) then note("CleanReason: kein gueltiges UTF-8", why) end
      if why:find("[%c|]") then note("CleanReason: Steuerzeichen oder |", why) end
      if chars(why) > 60 or #why > 120 then note("CleanReason: zu lang", #why) end
      if P.CleanReason(why) ~= why then note("CleanReason: nicht stabil bei zweiter Anwendung", why) end
      local msg = P.EncodeHunt({ key = "Opfer-Lamm", display = "Opfer Lamm", class = "MAGE", level = 40, t = time(), by = "Anton Wurst", why = raw })
      if not msg then note("EncodeHunt liefert nichts", raw) else
        if #msg > 255 then note("Nachricht ueber 255 Bytes", #msg) end
        local m, err = P.Decode(msg, time(), {})
        if not m then note("eigene Nachricht nicht lesbar", err)
        elseif m.why ~= P.CleanReason(m.why) or not validUTF8(m.why) then note("Grund nach dem Dekodieren nicht sauber", m.why) end
      end
    end
    -- Dekoder mit Muell und mit verstuemmelten echten Nachrichten
    local junk = "1\t" .. ({ "K", "R", "H", "S", "M", "X", "J", "A", "E", "Q" })[R(10)] .. "\t" .. raw:gsub("\t", R() < 0.5 and "\t" or "")
    local okd = pcall(P.Decode, junk, time(), {})
    if not okd then note("Decode wirft", junk) end
    local cut = P.CutUTF8(raw, R(0, #raw))
    if validUTF8(raw) and not validUTF8(cut) then note("CutUTF8 schneidet im Zeichen", cut) end
  end
  local list = {}
  for k, v in pairs(bad) do list[#list + 1] = k .. " (" .. tostring(v):sub(1, 40):gsub("%c", "?") .. ")" end
  H.erwartet(N .. " Zufallstexte ohne Verstoss", #list == 0, table.concat(list, "; "))
end)
H.fertig()
