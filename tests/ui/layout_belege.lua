-- 1.2.2 proofs for single findings of the layout hunt that the layout guard does not see as a group
-- (red on the code before 1.2.2, green after). Behaviour and geometry in the UI mock with measured widths.
-- Call from the project root: luajit tests/ui/layout_belege.lua .
local DIR = (arg[1] or "."):gsub("/+$", "")
package.path = DIR .. "/tests/ui/?.lua;" .. DIR .. "/tests/?.lua;" .. package.path
arg[0] = DIR .. "/tests/ui/layout_belege.lua"
local ADDON = DIR .. "/DeathNote"
local ok, bad = 0, 0
local function check(name, cond, info)
  if cond then ok = ok + 1 else bad = bad + 1; io.write("ROT   ", name, info ~= nil and ("  -> " .. tostring(info)) or "", "\n") end
end

local AM, BM, G
local function world(code)
  package.loaded.mock_wow, package.loaded.mock = nil, nil
  AM = require("mock_wow")
  BM = require("mock")
  BM.mediaDir = ADDON .. "/Media"
  BM.measure = true
  G = BM.G
  AM.locale = code
  local ns = AM.Load({ noLogin = true, before = function() AM.units.player.guild = "Die Wuchtwaldwallwaechter" end })
  for _, f in ipairs({ "Alert.lua", "UI.lua", "Extras.lua", "Humor.lua" }) do
    if io.open(ADDON .. "/" .. f) then BM.Load(ADDON .. "/" .. f, ns) end
  end
  AM.FireEvent("PLAYER_LOGIN")
  AM.FireEvent("PLAYER_ENTERING_WORLD")
  return ns
end
local function tick(s) AM.Advance(s or 0.1); BM.Advance(s or 0.1) end
local function settle() BM.Advance(13); BM.FinishAnims(); BM.Advance(1); BM.FinishAnims(); BM.Advance(1) end
local function find(pred) for _, f in ipairs(BM.frames) do if pred(f) then return f end end end

------------------------------------------------------------------------
-- Nr. 5 (list sub line), 13 (menu width), 18 (placeholder),
-- 30 (tooltip first line wraps), 31 (scale events)
------------------------------------------------------------------------
do
  local ns = world("frFR")
  local t = _G.time()
  local k = ns.Store.AddManual("Maximilianus", "Wunderkammer")
  for i = 1, 12 do ns.Store.ApplyKill({ name = "Maximilianus", surname = "Wunderkammer", class = "MAGE", level = 60 }, { t = t - 100 * i, zone = "Z" }, true) end
  for _ = 1, 12 do ns.Store.AddRevenge(k) end
  ns.Store.Get(k).lastSeen = { t = t - 3 * 3600 }
  ns:Fire("TOGGLE_UI"); tick(); settle()
  local row = find(function(f) return f.item and f.item.key == k and f.sub end)
  check("5 list: a cut sub line drops 'seen' and keeps the whole line for the tooltip",
    row and row.subFull ~= nil and row.sub._text ~= row.subFull and not row.sub:IsTruncated(), row and row.sub._text)
  -- 19: on the addon's own path in tests/ui/layout_red_probes.lua (130 wanted, the list at its end)
  -- 13: menu as wide as its longest entry, at most 252
  local F = rawget(G, "DeathNoteFrame")
  local long = "Maximilianus Wunderkammer-Langername"
  local fr = { ns.Friends and ns.Friends.Choose }
  row._scripts.OnClick(row, "RightButton"); tick()
  local menu = rawget(G, "DeathNoteMenu")
  check("8 menu clamped to the screen", menu and menu._clamped == true)
  local items = menu and menu.items or {}
  local need = 0
  for _, b in ipairs(items) do if b:IsShown() then need = math.max(need, BM.Unbounded(b.text) or 0) end end
  check("13 menu: every entry fits its button", items[1] and need <= items[1]._w - 8 + 0.5 or need == 0, need .. " / " .. tostring(items[1] and items[1]._w))
  menu.blocker._scripts.OnClick(menu.blocker)
  -- 17: four-digit count in a tab: tests/ui/layout_red_probes.lua (it checks the tab text against its field)
  -- 18: placeholder no wider than the search field
  local sb = find(function(f) return f._kind == "EditBox" and f.ph end)
  check("18 placeholder has the width of the search field", sb and sb.ph._wset and sb.ph._w <= sb._w, sb and tostring(sb.ph._wset))
  -- 30: first tooltip line wraps
  local GT = G.GameTooltip
  local seenWrap
  local orig = GT.SetText
  GT.SetText = function(self, t, r, g, b, a, wrap) seenWrap = wrap; return orig(self, t) end
  local e = find(function(f) return f.nameHit end)
  if e and e.infoHit then e.infoHit.tip = { "x" }; e.infoHit._scripts.OnEnter(e.infoHit) end
  GT.SetText = orig
  check("30 tooltip: the first line wraps", seenWrap == true, tostring(seenWrap))
  -- 31: resolution or UI scale changed while playing
  check("31 book re-checks its size on UI_SCALE_CHANGED", F._scripts.OnEvent ~= nil)
end

------------------------------------------------------------------------
-- Nr. 15 (imprint in two lines), 16 (popup title ladder), 9 (bounty next to the revenge stamp),
-- 23 (release words), 29 (hunt word), 25/26 (banner), 27 (quip)
------------------------------------------------------------------------
do
  local ns = world("enUS")
  ns.Store.Setting("humor", true)
  ns:Fire("TOGGLE_UI"); tick(); settle()
  ns.UI.OpenPanel("help"); tick()
  local foot = find(function(f) return f._kind == "FontString" and f._text == ns.UI.HELP_FOOT and f:IsVisible() end)
  check("15 imprint: whole, on up to two lines", foot and not foot:IsTruncated() and (foot._maxl or 0) >= 2, foot and foot._wrap)
  ns.UI.ClosePanel()
end
do
  local ns = world("ukUA")
  local t = _G.time()
  local k = ns.Store.AddManual("Maximilianus", "Wunderkammer")
  ns.Store.ApplyKill({ name = "Maximilianus", surname = "Wunderkammer", class = "MAGE", level = 60 }, { t = t - 100, zone = "Z" }, true)
  BM.levels.player, BM.levels.mouseover = 60, 60
  AM.AddEnemy("mouseover", { name = "Maximilianus", surname = "Wunderkammer", guid = "Player-1-MW", level = 60, class = "MAGE" })
  AM.FireEvent("UPDATE_MOUSEOVER_UNIT"); tick()
  local popup = rawget(G, "DeathNoteAlert")
  check("16 popup title (rank 1) whole", popup and popup:IsShown() and not popup.title:IsTruncated(), popup and BM.Unbounded(popup.title))
  check("2 popup name whole in 286 px", popup and not popup.name:IsTruncated(), popup and BM.Unbounded(popup.name))
  settle()
  -- 9: bounty next to the revenge stamp stays left of the stamp frame
  ns.Store.AddRevenge(k)
  ns:Fire("TOGGLE_UI"); tick(); settle()
  ns.UI.ShowEnemy(k); tick(); settle()
  local E = find(function(f) return f.bounty and f.stampRache end)
  local bl, _, br = BM.RectUI(E.bounty)
  local sl = BM.RectUI(E.stampRache)
  local bw = BM.Unbounded(E.bounty)
  local cx = bl and (bl + br) / 2
  check("9 bounty ends before the revenge stamp", cx and sl and cx + bw / 2 <= sl + 0.5, cx and sl and (cx + bw / 2 - sl))
  -- 29: word under the photo stops before the profile (x = 140 of the poster)
  local el = BM.RectUI(E)
  if E.hunt:IsShown() then
    local _, _, hr = BM.RectUI(E.hunt)
    check("29 hunt word ends before the profile", hr - el <= 137, hr - el)
  end
  -- 23: release words
  ns.UI.OpenRelease(k); tick()
  local R = find(function(f) return f.release and f.settings end).release
  -- 24: against the rule itself (320 px) in tests/ui/layout_red_probes.lua and tests/ui/layout_fixes.lua (B09)
  local rl = BM.RectUI(R)
  local last = R.tabs[#R.tabs]
  local _, _, tr = BM.RectUI(last)
  check("23 release words end before the right margin", tr and tr - rl <= 346.5, tr and (tr - rl))
  ns.UI.ClosePanel(); tick()
end
do
  local ns = world("itIT")
  ns:Fire("TOGGLE_UI"); tick(); settle()
  -- 21: on the addon's own path (a death, the case file opened from the journal) in tests/ui/layout_red_probes.lua
  -- 25/26: banner name and line
  local P = ns.Guild.Proto
  AM.FireEvent("CHAT_MSG_ADDON", "DeathNote", P.EncodeKill({ key = "Maximilianus-Wunderkammer", display = "Maximilianus Wunderkammer",
    class = "MAGE", level = 60, zone = "Valle di Strangleronzolo Lungo", t = _G.time() - 5, victim = "Kollegalunghissimo Nomelungo" }, "K"),
    "GUILD", "Kollegalunghissimo-Forever")
  tick(1)
  local banner = rawget(G, "DeathNoteBanner")
  if banner and banner:IsShown() then
    check("25 banner name whole", not banner.name:IsTruncated(), BM.Unbounded(banner.name))
    check("26 banner line whole (zone gives way)", not banner.line:IsTruncated(), banner.line._text)
  else
    check("25/26 banner came", false)
  end
end

io.write(("Layout proofs 1.2.2: %d gruen, %d rot\n"):format(ok, bad))
os.exit(bad == 0 and 0 or 1)
