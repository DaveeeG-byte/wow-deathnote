-- Test theme "probe" (1.3.0, only in the tests, never in the addon folder): sets EVERY value of the theme schema to a
-- value that differs from the base theme and can be recognised (colours 0.5xx / 0.25x / 0.75x with the role number
-- in the thousandths, textures swapped round among the existing files, font roles swapped, every show word "ZZ ...").
-- A frame tree built with it must not contain a single value of the black book: every one that still does is a
-- value the code does not take from the theme. Loaded like an addon file: chunk("DeathNote", ns), after Theme.lua
-- and notebook.lua, before the language is activated (the words register with Locale.RegisterWords).
local _, ns = ...
local T, Lc = ns.Theme, ns.Locale
local base = T.Get("notebook")

-- a colour per role: r 0.5xx, g 0.25x, b 0.75x (x = role number); alpha only where the base has one
local color = {}
for i, role in ipairs(T.COLORS) do
  local b = T.ParseColor(base.color[role])
  color[role] = { 0.5 + i / 1000, 0.25 + i / 1000, 0.75 + i / 1000, b[4] and (0.6 + i / 1000) or nil }
end
-- textures: each key gets the file of the next key (all files exist); client paths become other client paths
local own, client = {}, {}
for _, key in ipairs(T.TEXTURES) do
  local f = base.tex[key]
  if f:find("^Interface\\") then client[#client + 1] = key else own[#own + 1] = key end
end
local tex = {}
for i, key in ipairs(own) do tex[key] = base.tex[own[i % #own + 1]] end
for _, key in ipairs(client) do tex[key] = "Interface\\Probe\\" .. key end
local tint = {}
for i, key in ipairs(T.TINTS) do tint[key] = { 0.9, 0.8 + i / 1000, 0.7 } end
local fallback = {}
for i, key in ipairs(T.FALLBACKS) do fallback[key] = { 0.3 + i / 1000, 0.6, 0.9, 1 } end
-- stamps: the baked picture and the frame of the next stamp
local baked, blank = {}, {}
for i, key in ipairs(T.STAMPS) do
  local nxt = T.STAMPS[i % #T.STAMPS + 1]
  baked[key], blank[key] = base.stamp.baked[nxt], base.stamp.blank[nxt]
end
-- every role in another kind than in the base (head and hand differ, so both can be told apart)
local font = { title = "type", head = "body", hand = "title", body = "hand", type = "title" }
local tone = {}
for i, role in ipairs(T.TONES) do tone[role] = base.tone[role] - 0.01 * i end

T.Register("probe", {
  order = 99, nameKey = "THEME_NOTEBOOK", color = color, tex = tex, tint = tint, stamp = { baked = baked, blank = blank },
  fallback = fallback, font = font, tone = tone, sound = { alert = "glocke" }, words = "probe",
})

-- words: every show key in every language, placeholders kept ({count} stays)
local function words(W)
  for key in pairs(Lc.THEME_KEYS) do W[key] = "ZZ " .. key end
  W.BOUNTY_GOLD, W.BOUNTY_SILVER = "ZZ {count} BG", "ZZ {count} BS"
  W.BOOK_TITLE, W.POSTER_HEAD = "ZZTITLE", "ZZHEAD"
end
for _, code in ipairs(Lc.CODES) do Lc.RegisterWords("probe", code, words) end
