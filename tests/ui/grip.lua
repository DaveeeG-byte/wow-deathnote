-- 1.5.0 grip: the mark on the nameplate (Plate.lua) with the real logic, the grudge notice's probable rows and sizes
-- (GrudgeCard.lua), the House Rules rows (sheet Rap Sheet: size of the notice, section NAMEPLATE) in 21 languages.
-- The plates are stand-ins (C_NamePlate.GetNamePlateForUnit gives a frame of the mock). All names are made up.
-- Use: luajit tests/ui/grip.lua [project folder]
local DIR = ((arg and arg[1]) or "."):gsub("/+$", "")
package.path = DIR .. "/tests/ui/?.lua;" .. DIR .. "/tests/?.lua;" .. package.path
local ADDON = DIR .. "/DeathNote"
local ok, bad = 0, 0
local function check(name, cond, info)
  if cond then ok = ok + 1
  else bad = bad + 1; io.write("RED   ", name, info ~= nil and ("  -> " .. tostring(info)) or "", "\n") end
end

local function world(code)
  package.loaded.mock_wow, package.loaded.mock = nil, nil
  local AM = require("mock_wow")
  local BM = require("mock")
  BM.mediaDir = ADDON .. "/Media"
  BM.measure = true
  AM.locale = code or "deDE"
  local ns = AM.Load({ noLogin = true })
  for _, f in ipairs({ "Alert.lua", "UI.lua", "Extras.lua", "GrudgeCard.lua", "Plate.lua", "Humor.lua" }) do
    BM.Load(ADDON .. "/" .. f, ns)
  end
  -- the plates: one stand-in frame per token, as the client hands them out
  local frames = {}
  rawset(BM.G, "C_NamePlate", { GetNamePlateForUnit = function(unit)
    local f = frames[unit]
    if f == nil then
      f = BM.G.CreateFrame("Frame", nil, BM.G.UIParent)
      f:SetSize(110, 40)
      f:SetPoint("CENTER", BM.G.UIParent, "CENTER", 0, 0)
      frames[unit] = f
    end
    return f
  end })
  AM.FireEvent("PLAYER_LOGIN")
  AM.FireEvent("PLAYER_ENTERING_WORLD")
  _G.UnitAffectingCombat = function(u) local x = AM.units[u]; return x ~= nil and x.combat ~= false end
  _G.UnitInParty = function() return false end
  local W = { AM = AM, BM = BM, G = BM.G, ns = ns, plates = frames }
  function W.tick(s) AM.Advance(s or 0.1); BM.Advance(s or 0.1) end
  function W.card() return rawget(BM.G, "DeathNoteGrudge") end
  function W.plate(token, name, surname, o)
    o = o or {}
    o.name, o.surname, o.guid = name, surname, o.guid or ("Player-93-" .. name)
    AM.AddEnemy(token, o)
    AM.FireEvent("NAME_PLATE_UNIT_ADDED", token)
  end
  function W.gone(token)
    AM.FireEvent("NAME_PLATE_UNIT_REMOVED", token)
    AM.units[token] = nil
  end
  return W
end

local function texName(t) return tostring(t and (t._tex or t._texture or (t.GetTexture and t:GetTexture())) or "") end

------------------------------------------------------------------------
-- 1) The mark: wanted (pin and standing), attacks only (plain), hit list (crosshair), pardoned and strangers none
------------------------------------------------------------------------
do
  local W = world("deDE")
  local ns, P = W.ns, W.ns.Plate
  local t = _G.time()
  ns.Store.ApplyKill({ name = "Grimm", surname = "Bart", guid = "Player-93-Grimm" }, { t = t - 500, zone = "Z", source = "recap" }, true)
  ns.Store.ApplyKill({ name = "Grimm", surname = "Bart", guid = "Player-93-Grimm" }, { t = t - 400, zone = "Z", source = "recap" }, true)
  ns.Store.AddAttack({ name = "Nur", surname = "Angriff", guid = "Player-93-Nur" }, { t = t - 60, zone = "Z" })
  ns.Store.ApplyKill({ name = "Gnade", surname = "Los", guid = "Player-93-Gnade" }, { t = t - 300, zone = "Z", source = "recap" }, true)
  ns.Store.SetStatus("Gnade-Los", "pardoned")
  W.plate("nameplate1", "Grimm", "Bart")
  W.plate("nameplate2", "Nur", "Angriff")
  W.plate("nameplate3", "Gnade", "Los")
  W.plate("nameplate4", "Fremd", "Ling")
  W.AM.AddEnemy("nameplate5", { isPlayer = false, name = "Wolf", guid = "Creature-0-1" })
  W.AM.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate5")
  local m1, m2 = P.Active("nameplate1"), P.Active("nameplate2")
  check("wanted: a mark", m1 and m1:IsShown())
  check("wanted: child of its own plate, above it", m1 and m1._parent == W.plates.nameplate1 and m1._points[1][1] == "BOTTOM"
    and m1._points[1][2] == W.plates.nameplate1 and m1._points[1][3] == "TOP")
  check("wanted: the thumbtack", texName(m1 and m1.icon):find("pin", 1, true), texName(m1 and m1.icon))
  check("wanted: the standing 0 : 2 beside it", m1 and m1.score:IsShown() and m1.score._text == "0 : 2", m1 and m1.score._text)
  check("attacks only: plain mark (grey, smaller, no standing)", m2 and m2:IsShown() and m2.icon._desat == true
    and not m2.score:IsShown() and m2.icon:GetWidth() < m1.icon:GetWidth(), m2 and m2.icon:GetWidth())
  check("pardoned: no mark", P.Active("nameplate3") == nil)
  check("not in the book: no mark", P.Active("nameplate4") == nil)
  check("a creature: no mark", P.Active("nameplate5") == nil)
  -- the stranger is entered by hand: his mark comes at once
  ns.Store.AddManual("Fremd", "Ling")
  check("entered by hand: the mark comes at once", P.Active("nameplate4") ~= nil)
  -- pardoned: the mark goes
  ns.Store.SetStatus("Grimm-Bart", "pardoned")
  check("pardoned later: the mark goes", P.Active("nameplate1") == nil and not m1:IsShown())
  ns.Store.SetStatus("Grimm-Bart", "wanted")
  check("wanted again: the mark is back", P.Active("nameplate1") ~= nil)
  -- hit list: the crosshair
  local G = ns.Guild
  local realHunt = G.Hunt
  G.Hunt = function(key, src) if key == "Nur-Angriff" then return { key = key, display = "Nur Angriff" } end return realHunt(key, src) end
  ns:Fire("GUILD_UPDATED")
  local m2b = P.Active("nameplate2")
  check("hit list: the crosshair stamp", m2b and texName(m2b.icon):find("crosshair", 1, true) and m2b.icon._desat ~= true,
    texName(m2b and m2b.icon))
  G.Hunt = realHunt
  ns:Fire("GUILD_UPDATED")
  -- the pool: a plate that goes gives its mark back, the next one takes it
  local built = P.ProbeSnapshot().counts.built
  W.gone("nameplate1")
  check("plate gone: mark hidden", not m1:IsShown() and P.Active("nameplate1") == nil)
  W.plate("nameplate6", "Grimm", "Bart")
  check("pool: the next plate takes the same frame", P.Active("nameplate6") == m1 and P.ProbeSnapshot().counts.built == built)
  check("pool: on the new plate", m1._parent == W.plates.nameplate6)
  -- in combat: same, no protected action (the mock records violations)
  W.BM.combat = true; W.AM.inCombat = true
  W.gone("nameplate6")
  W.plate("nameplate7", "Grimm", "Bart")
  check("in combat: the mark comes", P.Active("nameplate7") ~= nil)
  W.BM.combat = false; W.AM.inCombat = false
  check("no violations (secure frames, globals)", #W.BM.violations == 0, W.BM.violations[1])
  -- settings: off, size
  ns.Store.Setting("plate.enabled", false)
  check("switched off: no mark", P.Active("nameplate7") == nil and P.Active("nameplate2") == nil)
  ns.Store.Setting("plate.enabled", true)
  check("switched on: marks again", P.Active("nameplate7") ~= nil)
  ns.Store.Setting("plate.size", "large")
  check("large: 24 px", P.Active("nameplate7").icon:GetWidth() == 24, P.Active("nameplate7").icon:GetWidth())
  ns.Store.Setting("plate.size", "small")
  check("small: 14 px", P.Active("nameplate7").icon:GetWidth() == 14, P.Active("nameplate7").icon:GetWidth())
  -- the enemy plates switched off (1.2.2 status): the marks go
  ns:Fire("PLATES_CHANGED", false)
  ns.Util.platesOn = false
  ns:Fire("PLATES_CHANGED", false)
  check("enemy plates off: no mark", P.Active("nameplate7") == nil)
  ns.Util.platesOn = true
  ns:Fire("PLATES_CHANGED", true)
  check("enemy plates on: the mark again", P.Active("nameplate7") ~= nil)
  -- an instance: nothing is touched
  W.AM.instance = { true, "party" }
  W.AM.FireEvent("ZONE_CHANGED_NEW_AREA")
  check("instance: the marks go", P.Active("nameplate7") == nil)
  W.plate("nameplate8", "Fremd", "Ling")
  check("instance: no new mark", P.Active("nameplate8") == nil)
  check("instance: counted", P.ProbeSnapshot().counts.instance >= 1)
  W.AM.instance = { false, "none" }
  W.AM.FireEvent("ZONE_CHANGED_NEW_AREA")
  check("open world again: marks back", P.Active("nameplate7") ~= nil and P.Active("nameplate8") ~= nil)
  check("no addon errors", #W.AM.errors == 0, W.AM.errors[1])
end

------------------------------------------------------------------------
-- 2) Forbidden, secret, missing, broken: nothing set, counted, no error
------------------------------------------------------------------------
do
  local W = world("deDE")
  local ns, P = W.ns, W.ns.Plate
  local t = _G.time()
  for _, n in ipairs({ "Aa", "Bb", "Cc", "Dd" }) do
    ns.Store.ApplyKill({ name = n, surname = "Test" }, { t = t - 100, zone = "Z", source = "recap" }, true)
  end
  local real = rawget(W.G, "C_NamePlate").GetNamePlateForUnit
  local forb = W.G.CreateFrame("Frame", nil, W.G.UIParent)
  forb.IsForbidden = function() return true end
  rawget(W.G, "C_NamePlate").GetNamePlateForUnit = function(u)
    if u == "nameplate1" then return forb end
    if u == "nameplate2" then return W.AM.Secret("plate", "table") end
    if u == "nameplate3" then return nil end
    if u == "nameplate4" then error("boom") end
    return real(u)
  end
  W.plate("nameplate1", "Aa", "Test"); W.plate("nameplate2", "Bb", "Test")
  W.plate("nameplate3", "Cc", "Test"); W.plate("nameplate4", "Dd", "Test")
  local c = P.ProbeSnapshot().counts
  check("forbidden: no mark, counted", P.Active("nameplate1") == nil and c.forbidden == 1, c.forbidden)
  check("secret: no mark, counted", P.Active("nameplate2") == nil and c.secret == 1, c.secret)
  check("no frame: counted", P.Active("nameplate3") == nil and c.noFrame == 1, c.noFrame)
  check("an error: counted, never raised", P.Active("nameplate4") == nil and c.errors == 1 and #W.AM.errors == 0, c.errors)
  -- the probe and the logout keep the counters, no secrets
  ns.Probe.Run(false)
  local g = _G.DeathNoteDB.probe.grip
  check("probe.grip: counters", g and g.counts and g.counts.seen == 4 and g.counts.players == 4, g and g.counts and g.counts.seen)
  _G.DeathNoteDB.probe = nil
  W.AM.FireEvent("PLAYER_LOGOUT")
  check("logout: probe.grip without /dn probe", _G.DeathNoteDB.probe and _G.DeathNoteDB.probe.grip
    and _G.DeathNoteDB.probe.grip.counts.forbidden == 1)
  check("no secret in the book", not W.AM.ContainsSecret(_G.DeathNoteDB))
end

------------------------------------------------------------------------
-- 3) The notice: a probable row carries "?" and paler ink, its tooltip says why; the sizes scale the notice
------------------------------------------------------------------------
do
  local W = world("deDE")
  local ns = W.ns
  ns.Grudge.Test(3)
  local card = W.card()
  check("test notice shown", card and card:IsShown())
  local rows = {}
  for _, fr in ipairs(card.rows) do if fr:IsShown() and fr.row then rows[#rows + 1] = fr end end
  local prob, sure
  for _, fr in ipairs(rows) do
    if fr.row.conf == "probable" then prob = fr elseif fr.row.conf == "sure" and not fr.row.kb then sure = fr end
  end
  check("probable row: \"?\"", prob and prob.maybe:IsShown() and prob.maybe._text == "?")
  check("probable row: paler name", prob and prob.name._tc and math.abs(prob.name._tc[4] - ns.GrudgeCard.PROBABLE_ALPHA) < 0.01,
    prob and prob.name._tc and prob.name._tc[4])
  check("sure row: no \"?\", full ink", sure and not sure.maybe:IsShown() and sure.name._tc[4] == 1)
  check("probable row last (the first row is right)", rows[#rows] == prob)
  local tip = W.G.GameTooltip
  tip._lines = nil
  prob._scripts.OnEnter(prob)
  local all = {}
  for _, l in ipairs(tip._lines or {}) do all[#all + 1] = type(l) == "table" and (l[1] or l.text) or tostring(l) end
  local joined = table.concat(all, " | ") .. " " .. tostring(tip._text)
  check("tooltip says why", joined:find(ns.L.GRUDGE_TIP_PROBABLE, 1, true) ~= nil, joined)
  tip._lines = nil
  sure._scripts.OnEnter(sure)
  all = {}
  for _, l in ipairs(tip._lines or {}) do all[#all + 1] = type(l) == "table" and (l[1] or l.text) or tostring(l) end
  joined = table.concat(all, " | ")
  check("tooltip of a sure row: the signal, no 'not sure'", joined:find(ns.L.GRUDGE_TIP_JOIN, 1, true) ~= nil
    and not joined:find(ns.L.GRUDGE_TIP_PROBABLE, 1, true), joined)
  check("default size: scale 1", card:GetScale() == 1)
  ns.Store.Setting("grudge.size", "large")
  check("large: scale 1.25", card:GetScale() == 1.25, card:GetScale())
  ns.Store.Setting("grudge.size", "small")
  check("small: scale 0.85", card:GetScale() == 0.85, card:GetScale())
  ns.Store.Setting("grudge.size", "huge")
  check("unknown value: medium", card:GetScale() == 1, card:GetScale())
end

------------------------------------------------------------------------
-- 4) House Rules, sheet Rap Sheet: size of the notice and the section NAMEPLATE; the sheet does not scroll; 21 languages
------------------------------------------------------------------------
local CODES = { "enUS", "deDE", "frFR", "esES", "itIT", "ptBR", "ruRU", "koKR", "zhCN", "zhTW", "svSE", "nbNO", "daDK",
  "fiFI", "nlNL", "plPL", "csCZ", "huHU", "hrHR", "ukUA", "trTR" }
local function overlap(a, b)
  return a[1] < b[3] - 0.5 and b[1] < a[3] - 0.5 and a[2] < b[4] - 0.5 and b[2] < a[4] - 0.5
end
for ci, code in ipairs(CODES) do
  local W = world(code)
  local ns = W.ns
  ns:Fire("TOGGLE_UI"); W.tick()
  ns.UI.OpenPanel("settings"); W.tick()
  local S
  for _, f in ipairs(W.BM.frames) do if f.settings and f.settings.tabs then S = f.settings end end
  S.tabs[4]._scripts.OnClick(S.tabs[4]); W.tick()
  check(code .. ": rows there", S.gsize and S.plate)
  if S.gsize and S.plate then
    check(code .. ": the sheet does not scroll", (S.page.range or 0) == 0, S.page.range)
    -- every row of the sheet: label, arrows, value, check boxes, buttons do not overlap and stay on the page
    local parts = {}
    local function add(x, what) if x and x:IsShown() then local l, b, r, t = W.BM.RectUI(x); if l then parts[#parts + 1] = { l, b, r, t, what } end end end
    for _, st in ipairs({ S.gsec, S.gsize, S.plate, S.settled }) do
      if st then add(st.label or st.l, "label"); add(st.minus, "minus"); add(st.plus, "plus"); add(st.hit or st, "value") end
    end
    for _, b in ipairs(S.grudgeButtons or {}) do add(b, "button") end
    for _, cb in ipairs(S.checks) do if cb.opt.path and cb.opt.path:find("^grudge") then add(cb, "check") end end
    local worst
    for i = 1, #parts do
      for j = i + 1, #parts do
        if overlap(parts[i], parts[j]) and parts[i][5] ~= parts[j][5] then
          worst = worst or (parts[i][5] .. "/" .. parts[j][5])
        end
      end
    end
    check(code .. ": nothing overlaps on the sheet", worst == nil, worst)
    if ci <= 2 then
      local P = ns.Plate
      check(code .. ": plate value medium", S.plate._text == ns.L.SIZE_MEDIUM, S.plate._text)
      S.plate.plus._scripts.OnClick(S.plate.plus); W.tick()
      check(code .. ": plate large", ns.Store.Setting("plate.size") == "large" and S.plate._text == ns.L.SIZE_LARGE, S.plate._text)
      for _ = 1, 4 do S.plate.minus._scripts.OnClick(S.plate.minus) end
      W.tick()
      check(code .. ": plate off", P.Enabled() == false and S.plate._text == ns.L.WORD_OFF, S.plate._text)
      S.plate.plus._scripts.OnClick(S.plate.plus); W.tick()
      check(code .. ": plate on again, small", P.Enabled() and P.Size() == "small", S.plate._text)
      check(code .. ": notice size medium", S.gsize._text == ns.L.SIZE_MEDIUM, S.gsize._text)
      S.gsize.minus._scripts.OnClick(S.gsize.minus); W.tick()
      check(code .. ": notice small", ns.Store.Setting("grudge.size") == "small" and S.gsize._text == ns.L.SIZE_SMALL)
    end
  end
  check(code .. ": no addon errors", #W.AM.errors == 0, W.AM.errors[1])
end

------------------------------------------------------------------------
-- 5) The notice in every size: 1, 8, 12 rows, nothing overlaps or sticks out, 21 languages
------------------------------------------------------------------------
for _, code in ipairs(CODES) do
  local W = world(code)
  local ns = W.ns
  local card = W.card()
  local worst
  for _, size in ipairs({ "small", "medium", "large" }) do
    ns.Store.Setting("grudge.size", size)
    for _, n in ipairs({ 1, 8, 12 }) do
      ns.Grudge.Test(n)
      local e = ns.Grudge.Current()
      for i, k in ipairs(e.order) do
        local r = e.rows[k]
        r.surname = "Wunderkammerlein" .. i
        if i == 2 then r.state = "yes" elseif i == 4 then r.state = "no" end
      end
      ns.GrudgeCard.Fill(e)
      local parts = {}
      for _, fr in ipairs(card.rows) do
        if fr:IsShown() then
          for _, x in ipairs({ fr.name, fr.level, fr.state, fr.yes, fr.no, fr.mark, fr.maybe }) do
            if x:IsShown() then
              local l, b, r, t = W.BM.RectUI(x)
              if l then parts[#parts + 1] = { l, b, r, t, x == fr.name and "name" or "part" } end
            end
          end
        end
      end
      local cl, cb, cr, ct = W.BM.RectUI(card)
      for i = 1, #parts do
        local a = parts[i]
        if a[1] < cl - 0.5 or a[3] > cr + 0.5 or a[2] < cb - 0.5 or a[4] > ct + 0.5 then worst = worst or (size .. " " .. n .. " rows: out") end
        for j = i + 1, #parts do
          if overlap(a, parts[j]) then worst = worst or (size .. " " .. n .. " rows: overlap " .. a[5] .. "/" .. parts[j][5]) end
        end
      end
      ns.Grudge.Close("test")
    end
  end
  check(code .. ": notice in three sizes, nothing overlaps (1, 8, 12 rows)", worst == nil, worst)
end

io.write(("grip UI: %d gruen, %d rot\n"):format(ok, bad))
os.exit(bad == 0 and 0 or 1)
