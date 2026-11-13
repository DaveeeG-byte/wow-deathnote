-- 1.2.2 red probes for Nr. 13, 16, 17, 20, 23, 24, 25, 27, 29 of the layout hunt (taken over from the second hunt
-- over the layout diff), plus Nr. 19 and 21 on the addon's own path. Each check is red on the code before 1.2.2 and
-- green after it. Width assumptions (the mock's wide end does not show every old cut; each block names its own):
--   16: capitals 0.81 em (Nimrod, calibrated on the screenshot of the round: 310 px at 14 pt)
--   17, 23: Friz 0.60 em (real font plus the pixel rounding of the client, factor 1.07 of the picture tool)
--   23, 24, 29: handwriting 0.68 em (Morpheus stand-in of the picture tool, up to 15 % wide)
--   25, 27: Morpheus 0.68 em
-- Call from the project root: luajit tests/ui/layout_red_probes.lua .
local DIR = (arg[1] or "."):gsub("/+$", "")
local K = dofile(DIR .. "/tests/ui/layout_kit.lua")(DIR, "layout_red_probes")
local whisper = K.whisper

-- Nr. 13 (menu "This is ...") and Nr. 20 (status sentence in the tooltip): a friend known by the first name only,
-- two players with that first name and 12 + 12 letters
do
  local ns = K.world("deDE", { before = function()
    local FR = { "Maximilianus" }
    _G.C_FriendList = {
      GetNumFriends = function() return #FR end,
      GetFriendInfoByIndex = function(i) local n = FR[i]; if n then return { name = n, connected = true } end end,
      ShowFriends = function() end,
    }
  end })
  local AM, BM, G, L = K.AM, K.BM, K.G, ns.L
  local P = ns.Guild.Proto
  K.tick(30); K.settle()
  local t = _G.time()
  local A, B = "Maximilianus Wunderkammer", "Maximilianus Wanderzirkus"
  whisper(P.EncodeKill({ key = "Grimm-Bart", display = "Grimm Bart", t = t - 30, zone = "Z", victim = A }, "K"), A .. "-Forever")
  whisper(P.EncodeHunt({ key = "Falsch-Lamm", t = t, by = A, why = "x" }), A .. "-Forever")
  whisper(P.EncodeHunt({ key = "Echt-Lamm", t = t, by = B, why = "y" }), B .. "-Forever")
  K.tick(2)
  K.check("13/20 precondition: conflict between two full names", ns.Friends.Health().reason == "conflict", ns.Friends.Health().reason)
  ns:Fire("TOGGLE_UI"); K.tick(); K.settle()
  local gt = K.find(function(f) return f.id == "guild" and f._scripts and f._scripts.OnClick end)
  gt._scripts.OnClick(gt, "LeftButton"); K.tick()
  ns.UI.SetGuildView("member"); K.settle()
  -- Nr. 20: the status line on the left has two lines at most; cut: the whole sentence in its tooltip
  local st = K.find(function(f) return f._kind == "FontString" and f:IsVisible() and f._maxl == 2 and type(f._text) == "string"
    and f._text:find("Wunderkammer", 1, true) and f._text:find("Wanderzirkus", 1, true) end)
  K.check("20 status sentence with both names is on the left page", st ~= nil)
  if st then
    -- the hit area over the status line (30 px high, at BOTTOMLEFT 44, 6 of the left page)
    local o = K.find(function(f) return f._kind == "Button" and f._parent == st._parent and f:IsVisible() and f._h == 30
      and f._points[1] and f._points[1][1] == "BOTTOMLEFT" and f._scripts.OnEnter end)
    local tip = o and K.hover(o) or "(no hit area)"
    K.check("20 status sentence whole, or whole in its tooltip", not st:IsTruncated() or tip:find(st._text, 1, true) ~= nil,
      ("%d lines, tooltip: %s"):format((BM.Lines(st)), (tip:gsub("\n", " / "))))
  end
  local head = K.find(function(f) return f._kind == "Button" and f.item and f.item.wrap and f.item.head and f._shown and f.item.m and f.item.m.name == A end)
  K.check("13 section of the friend is there", head ~= nil)
  if head then
    head._scripts.OnClick(head, "RightButton"); K.tick()
    local menu = rawget(G, "DeathNoteMenu")
    local n, cut = 0, nil
    for _, b in ipairs(menu and menu:IsShown() and menu.items or {}) do
      if b:IsShown() then
        n = n + 1
        if b.text:IsTruncated() then cut = ("'%s' %.0f px at %s pt in %s px"):format(b.text._text, BM.Unbounded(b.text), tostring(b.text._fontSize), tostring(b.text._w)) end
      end
    end
    K.check("13 menu 'This is ...': both entries show the whole name", n >= 2 and not cut, cut or n)
  end
end

-- Nr. 16: popup title of rank 1 in Hungarian
-- Width assumption of jagd-code.md (310 px at 14 pt, Nimrod calibrated on the screenshot): capitals 0.81 em in the
-- mock (its own wide end, 0.70 em, gives 267 px and would not show the old cut).
do
  local ns = K.world("huHU", { before = function(_, BM) BM.CAPS = 0.81 end })
  local AM, BM, G = K.AM, K.BM, K.G
  local t = _G.time()
  ns.Store.AddManual("Anna", "Beispiel")
  ns.Store.ApplyKill({ name = "Anna", surname = "Beispiel", class = "MAGE", level = 60 }, { t = t - 86400, zone = "Z" }, true)
  K.tick(30); for _ = 1, 4 do K.settle() end
  BM.levels.player, BM.levels.mouseover = 60, 60
  AM.AddEnemy("mouseover", { name = "Anna", surname = "Beispiel", guid = "Player-1-AB", level = 60, class = "MAGE" })
  AM.FireEvent("UPDATE_MOUSEOVER_UNIT"); K.tick()
  local popup = rawget(G, "DeathNoteAlert")
  K.check("16 popup title of rank 1 (huHU) is whole", popup and popup:IsShown() and not popup.title:IsTruncated()
    and BM.Unbounded(popup.title) <= 288.5, popup and ("%.0f px at %s pt"):format(BM.Unbounded(popup.title), tostring(popup.title._fontSize)))
end

-- Nr. 17 (tab with a four-digit count): Friz 11 pt is a real font in the tool; with the mock's wide factor (0.56 em)
-- "Procurados  1235" is 99 px in a 100 px text field. The proof takes the picture tool's margin for the pixel
-- rounding of the client (factor 1.07 on Friz: 0.60 em) so that the old overflow shows.
do
  local ns = K.world("ptBR", { before = function(_, BM) BM.WIDTH["Fonts\\FRIZQT__.TTF"] = 0.60 end })
  local AM, BM, G = K.AM, K.BM, K.G
  for i = 1, 1234 do ns.Store.AddManual("N" .. i, "Beispiel") end
  K.tick(30); K.settle()
  ns:Fire("TOGGLE_UI"); K.tick(); K.settle()
  local F = rawget(G, "DeathNoteFrame")
  local worst, what, four = -999, nil, false
  local tabs = F.tabs or {}
  for _, tb in ipairs(tabs) do
    if tb:IsVisible() then
      local over = (BM.Unbounded(tb.text) or 0) - (tb.text._wset and tb.text._w or tb._w or 0)
      -- 1.3.1: five tabs are always shown; a label that is cut there carries its whole text in the tab's tooltip
      if over > 0.5 and tb.text.tipOwner then over = 0 end
      if over > worst then worst, what = over, tb.text._text end
      if (tb.text._text or ""):find("%d%d%d%d") then four = true end
    end
  end
  K.check("17 precondition: a tab shows a four-digit count", four, what)
  K.check("17 every tab text fits its text field or shows it whole in a tooltip", worst <= 0.5, ("%.1f px over: %s"):format(worst, tostring(what)))
  local fl = BM.RectUI(F)
  local last
  for _, tb in ipairs(tabs) do if tb:IsVisible() then last = tb end end
  local _, _, r = BM.RectUI(last)
  K.check("17 control: tab row ends before x = 704", r and fl and r - fl <= 704.5, r and fl and (r - fl))
end

-- Nr. 23 (release words, esES) and Nr. 24 (sheet head, ukUA) and Nr. 29 (word under the photo, ukUA)
-- Width assumption for the handwriting (Morpheus stand-in of the picture tool, up to 15 % wide): 0.68 em
-- (jagd-code.md: REL_HEAD ukUA 333 px, release words esES end at x = 364).
for _, code in ipairs({ "esES", "ukUA" }) do
  local ns = K.world(code, { before = function(_, BM) BM.WIDTH["Fonts\\MORPHEUS.TTF"], BM.WIDTH["Fonts\\MORPHEUS_CYR.TTF"] = 0.68, 0.68
    BM.WIDTH["Fonts\\FRIZQT__.TTF"] = 0.60   -- release words are Friz 11 pt: real font plus the 1.07 pixel rounding of the client
  end })
  local AM, BM, G = K.AM, K.BM, K.G
  local P = ns.Guild.Proto
  K.tick(30); K.settle(); AM.Advance(120)
  local t = _G.time()
  local k1 = ns.Store.AddManual("Erster", "Rang")
  for i = 1, 3 do ns.Store.ApplyKill({ name = "Erster", surname = "Rang", class = "MAGE", level = 60 }, { t = t - 100 * i, zone = "Z" }, true) end
  local k2 = ns.Store.AddManual("Zweiter", "Rang")
  ns.Store.ApplyKill({ name = "Zweiter", surname = "Rang", class = "MAGE", level = 60 }, { t = t - 500, zone = "Z" }, true)
  K.gmsg(P.EncodeKill({ key = "Fremder-Langername", display = "Fremder Langername", class = "MAGE", level = 60, zone = "Z", t = t - 30, victim = "Kollege Lang" }, "K"))
  whisper(P.EncodeKill({ key = "Grimm-Bart", display = "Grimm Bart", t = t - 30, zone = "Z", victim = "Fritz Frei" }, "K"), "Fritz Frei-Forever")
  K.tick(10); for _ = 1, 6 do K.settle() end
  ns:Fire("TOGGLE_UI"); K.tick(); K.settle()
  ns.UI.ShowEnemy(k2); K.tick(); K.settle()
  local E = K.find(function(f) return f.bounty and f.stampRache end)
  if code == "ukUA" then
    local el = BM.RectUI(E)
    K.check("29 precondition: the word under the photo shows", E.hunt:IsVisible(), E.hunt.text._text)
    if E.hunt:IsVisible() then
      local l = BM.RectUI(E.hunt)
      local right = l + math.max(E.hunt._w or 0, 0)
      -- text centred in the word button: its ink must end before the profile column (x = 140 of the poster)
      local ink = (l + right) / 2 + math.min(BM.Unbounded(E.hunt.text), E.hunt.text._wset and E.hunt.text._w or 1e9) / 2
      K.check("29 word under the photo ends before the profile (x = 140)", right - el <= 137 and ink - el <= 137,
        ("frame ends %.0f, ink ends %.0f"):format(right - el, ink - el))
    end
  end
  ns.UI.OpenRelease(k2); K.tick()
  local RP = K.find(function(f) return f.release and f.settings end)
  local R = RP.release
  local rl = BM.RectUI(R)
  if code == "ukUA" then
    local head = K.find(function(f) return f._kind == "FontString" and f._text == ns.L.REL_HEAD and f:IsVisible() end)
    K.check("24 sheet head no wider than the rule under it (320 px)", head and BM.Unbounded(head) <= 320.5,
      head and ("%.0f px at %s pt"):format(BM.Unbounded(head), tostring(head._fontSize)))
  else
    local n, worst = 0, -999
    for _, b in ipairs(R.tabs) do
      if b:IsVisible() then
        n = n + 1
        local _, _, r = BM.RectUI(b)
        if r and r - rl > worst then worst = r - rl end
      end
    end
    K.check("23 precondition: three target words", n == 3, n)
    K.check("23 release words end before the right margin (x = 346)", worst <= 346.5, worst)
  end
end

-- Nr. 25 (banner name next to the stamp) and Nr. 27 (quip strip), enUS with humor
do
  local ns = K.world("enUS", { before = function(_, BM) BM.WIDTH["Fonts\\MORPHEUS.TTF"] = 0.68 end })
  local AM, BM, G = K.AM, K.BM, K.G
  ns.Store.Setting("humor", true)
  if ns.Humor then ns.Humor.QUIET = 0 end
  local t = _G.time()
  local k = ns.Store.AddManual("Maximilianus", "Wunderkammer")
  ns.Store.ApplyKill({ name = "Maximilianus", surname = "Wunderkammer", class = "MAGE", level = 60 }, { t = t - 100, zone = "Z" }, true)
  K.tick(30); for _ = 1, 4 do K.settle() end
  ns.Store.AddRevenge(k); K.tick()
  local banner = rawget(G, "DeathNoteBanner")
  K.check("25/27 revenge banner came", banner and banner:IsShown())
  if banner and banner:IsShown() then
    local nl, _, nr = BM.RectUI(banner.name)
    local ink = (nl + nr) / 2 + math.min(BM.Unbounded(banner.name), nr - nl) / 2
    local sl = BM.RectUI(banner.stamp)
    K.check("25 banner name (25 letters) is whole and ends before the stamp", not banner.name:IsTruncated() and ink <= sl + 12.5,
      ("ink ends %.0f px right of the stamp's left edge, %s pt"):format(ink - sl, tostring(banner.name._fontSize)))
    local q = banner.dnQuip
    K.check("27 precondition: quip strip shows the milestone line", q and q:IsShown() and q.text._text ~= "", q and q.text._text)
    if q then
      K.check("27 quip is whole in its strip", not q.text:IsTruncated(),
        ("%.0f px at %s pt in %s px"):format(BM.Unbounded(q.text), tostring(q.text._fontSize), tostring(q.text._w)))
    end
  end
end


-- Nr. 19 (rank of three digits in its 32 px) and Nr. 21 (killer name in the case file), both on the addon's path:
-- 130 wanted, the list wheeled to its end; a death by a killer with a long name, the case file opened from the journal
do
  local ns = K.world("frFR")
  local BM = K.BM
  local t = _G.time()
  for i = 1, 130 do
    ns.Store.ApplyKill({ name = "Nom" .. i, surname = "Exemple", class = "MAGE", level = 60 }, { t = t - 1000 - i, zone = "Z" }, true)
  end
  K.tick(30); for _ = 1, 3 do K.settle() end
  ns:Fire("TOGGLE_UI"); K.tick(); K.settle()
  local wheel = K.find(function(f) return f._scripts and f._scripts.OnMouseWheel and f._kind == "Frame" and K.find(function(r) return r._parent == f and r.rank end) end)
  if wheel then for _ = 1, 100 do wheel._scripts.OnMouseWheel(wheel, -1) end end
  K.tick(); K.settle()
  local row = K.find(function(f) return f.rank and f:IsVisible() and f.rank._text == "128." end)
  K.check("19 precondition: a row shows rank 128", row ~= nil)
  if row then
    local l, _, r = BM.RectUI(row.rank)
    local rl = BM.RectUI(row)
    local ink = BM.Unbounded(row.rank)
    -- right-justified in its field: the ink starts at r - ink
    K.check("19 rank 128. stays inside its row and its 32 px", not row.rank:IsTruncated() and r - ink >= rl - 0.5 and ink <= 32.5,
      ("%.1f px at %s pt, starts %.1f px left of the row"):format(ink, tostring(row.rank._fontSize), rl - (r - ink)))
  end
end
do
  local ns = K.world("itIT")
  local BM = K.BM
  local t = _G.time()
  local k = ns.Store.ApplyKill({ name = "Maximilianus", surname = "Wunderkammerdiener", class = "MAGE", level = 60 }, { t = t - 100, zone = "Z" }, true)
  ns.Store.RecordDeath({ t = t - 100, zone = "Z", kind = "pvp", sure = true, counted = true, killerKey = k,
    killerName = "Maximilianus Wunderkammerdiener", me = "Ich Selbst", candidates = {} })
  K.tick(30); for _ = 1, 3 do K.settle() end
  ns:Fire("TOGGLE_UI"); K.tick(); K.settle()
  for _, f in ipairs(BM.frames) do
    if f.id == "journal" and f._scripts and f._scripts.OnClick then f._scripts.OnClick(f, "LeftButton"); break end
  end
  K.tick(); K.settle()
  -- open the case file of the death (first row of the journal)
  local row = K.find(function(f) return f.item and f.sub and f:IsVisible() and f._scripts.OnClick end)
  if row then row._scripts.OnClick(row, "LeftButton"); K.tick(); K.settle() end
  local D = K.find(function(f) return f.killer and f.cands end)
  local fs = D and D.killer.text
  K.check("21 precondition: the case file names the killer", fs and fs:IsVisible() and (fs._text or ""):find("Wunderkammerdiener", 1, true) ~= nil,
    fs and fs._text)
  if fs then
    local tip = fs.tipOwner and K.hover(fs.tipOwner) or ""
    K.check("21 killer name whole, or whole in its tooltip", not fs:IsTruncated() or tip:find("Wunderkammerdiener", 1, true) ~= nil,
      ("%s px at %s pt in %s px, tooltip '%s'"):format(tostring(BM.Unbounded(fs)), tostring(fs._fontSize), tostring(fs._w), tip))
  end
end

K.done("Layout red probes 1.2.2")
