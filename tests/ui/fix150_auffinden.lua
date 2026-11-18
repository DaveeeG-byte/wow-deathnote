-- 1.5.0 fixer (U9): a new player finds the new things. (c) The nameplate stepper's label has a tooltip: the three
-- marks with their pictures, the standing "you : them", where the keys are set. (d) The chronicle's word on the poster
-- is a plain link: red ink, underlined, a tooltip says what the click does. (e) After a typed "/dn add <name>" one
-- line, once per account: a key does this for the target, and where to set it (or which key it is). Names made up.
-- (a) README and (b) the line after the update: tests/test_fix150_texte.lua.
local WT = arg[1] or "."
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_ju.lua")
-- the world of _ju.lua plus the files of the package grip (keys, nameplate stepper)
function J.world(WT, code)
  package.path = WT .. "/tests/ui/?.lua;" .. WT .. "/tests/?.lua;" .. package.path
  package.loaded.mock_wow, package.loaded.mock = nil, nil
  local AM = require("mock_wow")
  local BM = require("mock")
  local ADDON = WT .. "/DeathNote"
  BM.mediaDir = ADDON .. "/Media"
  BM.measure = true
  AM.locale = code or "deDE"
  local files = {}
  for _, f in ipairs(AM.Files()) do files[#files + 1] = f end
  files[#files + 1] = "Share.lua"
  files[#files + 1] = "Grip.lua"
  local ns = AM.Load({ noLogin = true, files = files })
  for _, f in ipairs({ "Alert.lua", "UI.lua", "Extras.lua", "GrudgeCard.lua", "Plate.lua", "ShareUI.lua", "SceneMap.lua" }) do
    BM.Load(ADDON .. "/" .. f, ns)
  end
  AM.FireEvent("PLAYER_LOGIN")
  AM.FireEvent("PLAYER_ENTERING_WORLD")
  local W = { AM = AM, BM = BM, G = BM.G, ns = ns }
  function W.tick(s) AM.Advance(s or 0.1); BM.Advance(s or 0.1) end
  function W.settle() BM.Advance(13); BM.FinishAnims(); BM.Advance(1); BM.FinishAnims(); BM.Advance(1) end
  return W
end

local function tipOf(W, f)
  local tip = W.G.GameTooltip
  tip._lines, tip._text = {}, nil
  f._scripts.OnEnter(f)
  local out = { tip._text }
  for _, l in ipairs(tip._lines or {}) do out[#out + 1] = l end
  return out
end
local function has(list, s)
  for _, l in ipairs(list) do if type(l) == "string" and l:find(s, 1, true) then return true end end
  return false
end

for _, code in ipairs({ "deDE", "enUS" }) do
  local W = J.world(WT, code)
  local ns, L = W.ns, W.ns.L
  ns.UI.Open(); W.settle()

  -- (c) the stepper's tooltip
  ns.UI.OpenPanel("settings"); W.tick()
  local hit, lines
  for _, f in ipairs(W.BM.frames) do
    if not hit and f._scripts and f._scripts.OnEnter and f._kind == "Frame" then
      local ok, got = pcall(tipOf, W, f)
      if ok and got[1] == L.SET_PLATE and #got > 1 then hit, lines = f, got end
    end
  end
  J.check(code .. " (c) Schrittwaehler der Plakette hat einen Tooltip", hit ~= nil)
  lines = lines or {}
  for _, k in ipairs({ "PLATE_TIP_WANTED", "PLATE_TIP_GRUDGE", "PLATE_TIP_HUNT" }) do
    J.check(code .. " (c) Tooltip: " .. k, type(L[k]) == "string" and has(lines, L[k]), L[k])
  end
  J.check(code .. " (c) Tooltip: Bilder der Marken", has(lines, "pin.tga") and has(lines, "crosshair.tga"))
  J.check(code .. " (c) Tooltip: Stand du : er", has(lines, code == "deDE" and "du : er" or "you : them"))
  -- the last step is the head of the addon's section in the game's key bindings (the TOC title; "DeathNote" in the mock)
  local head = rawget(_G, "BINDING_HEADER_DEATHNOTE") or "?"
  J.check(code .. " (c) Tooltip: wo die Tasten sind", has(lines, (code == "deDE" and "Tastaturbelegung > " or "Key Bindings > ") .. head),
    lines[#lines])

  -- (d) the chronicle's word
  local key = ns.Store.ApplyKill({ name = "Grimm", surname = "Bart", class = "ROGUE", level = 40 },
    { t = time() - 600, zone = "Schlingendorntal", source = "recap" }, true)
  ns.UI.ShowEnemy(key); W.settle()
  local E
  for _, f in ipairs(W.BM.frames) do if f.lines and f.chron then E = f end end
  local ch = E and E.chron
  J.check(code .. " (d) Wort Chronik sichtbar", ch and ch:IsShown() and ch.text._text == L.CHRON_OPEN)
  local Look = ns.Look
  local col = ch and ch.text._tc or {}
  J.check(code .. " (d) Chronik in roter Tinte (Link)", col[1] and math.abs(col[1] - Look.RED_INK[1]) < 0.01
    and math.abs(col[2] - Look.RED_INK[2]) < 0.01, col[1])
  J.check(code .. " (d) Chronik unterstrichen", ch and ch.ul and ch.ul:IsShown() and ch.ul:GetWidth() >= 8 and ch.ul:GetHeight() == 1)
  local t = ch and tipOf(W, ch) or {}
  J.check(code .. " (d) Tooltip sagt, was der Klick tut", has(t, L.CHRON_OPEN_TIP or "\1"), t[1])
  if ch then ch._scripts.OnLeave(ch) end
  J.check(code .. " (d) nach dem Verlassen wieder rote Tinte", col[1] and math.abs((ch.text._tc or col)[1] - Look.RED_INK[1]) < 0.01)

  -- (e) the hint after a typed /dn add, once
  local n0 = #W.AM.chat
  ns.HandleSlash("add Fies Ling")
  local said = table.concat(W.AM.chat, "\n", n0 + 1)
  local want = ns.F(L.GRIP_KEY_HINT or "\1", { title = rawget(_G, "BINDING_HEADER_DEATHNOTE") or "?" })
  J.check(code .. " (e) nach /dn add: Hinweis auf die Taste", said:find(want, 1, true) ~= nil, said)
  n0 = #W.AM.chat
  ns.HandleSlash("add Noch Einer")
  said = table.concat(W.AM.chat, "\n", n0 + 1)
  J.check(code .. " (e) nur einmal", not said:find(want, 1, true), said)
  J.check(code .. " keine Fehler", #W.AM.errors == 0 and #W.BM.violations == 0, W.AM.errors[1] or W.BM.violations[1])
end

-- (e) with a key set: the line names it
local W = J.world(WT, "deDE")
rawset(_G, "GetBindingKey", function(name) if name == "DEATHNOTE_ADD" then return "SHIFT-F5" end end)
rawset(_G, "GetBindingText", function(k) return (k:gsub("SHIFT%-", "Umschalt-")) end)
local n0 = #W.AM.chat
W.ns.HandleSlash("add Fies Ling")
local said = table.concat(W.AM.chat, "\n", n0 + 1)
J.check("(e) Taste belegt: der Hinweis nennt sie", said:find(W.ns.F(W.ns.L.GRIP_KEY_HAVE or "\1", { key = "Umschalt-F5" }), 1, true) ~= nil, said)
rawset(_G, "GetBindingKey", nil); rawset(_G, "GetBindingText", nil)
J.done()
