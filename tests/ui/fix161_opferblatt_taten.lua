-- 1.6.1: the sheet of a victim (rap sheet) names his deeds too: whom he killed and when. Before, the sheet showed only
-- the own kills on him; why he is an enemy at all stood on his poster alone. Sources: the own book (every own char)
-- and what guild and friends sent; an own killing blow that also stands in the shared list shows once. A victim without
-- deeds keeps the sheet of 1.6.0. The row's tooltip names his newest killing blow. A victim known from the guild book
-- alone opens that poster by the click on the name. All names are invented.
-- Call from the project root: luajit tests/ui/fix161_opferblatt_taten.lua .
local DIR = (arg[1] or "."):gsub("/+$", "")
local K = dofile(DIR .. "/tests/ui/layout_kit.lua")(DIR, "fix161_opferblatt_taten")
local check = K.check
local ME = "Player-93-0000AAAA"

for _, code in ipairs({ "deDE", "enUS" }) do
  local ns = K.world(code)
  local AM, BM, L = K.AM, K.BM, ns.L
  AM.units.player.level = 40
  K.tick(30); K.settle()
  local plate = 0
  local now = time()
  local function iKill(name, surname, n)
    local guid = "Player-93-" .. name .. surname
    plate = plate + 1
    AM.AddEnemy("nameplate" .. plate, { name = name, surname = surname, level = 40, guid = guid, class = "MAGE" })
    AM.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate" .. plate)
    for _ = 1, n do AM.FireEvent("PARTY_KILL", ME, guid); K.tick(61) end
    return ns.Util.KeyFor(name, surname)
  end
  local function killsMe(name, surname, t, me, role)
    return ns.Store.ApplyKill({ name = name, surname = surname, class = "ROGUE", level = 40, guid = "Player-93-" .. name .. surname },
      { t = t, zone = "Schlingendorntal", spell = "Blutsauger", me = me, myLevel = 34, theirLevel = 34, role = role }, role == nil)
  end

  -- Grimm killed another char of mine once; I killed him twice
  local tOwn = now - 10 * 86400
  local grimm = killsMe("Grimm", "Bart", tOwn, "Moder Jock")
  iKill("Grimm", "Bart", 2)
  -- Olaf never did anything; I killed him once
  local olaf = iKill("Olaf", "Offen", 1)
  -- Velka killed a guildmate only (not in my book); I killed her once
  local velka = iKill("Velka", "Dorn", 1)
  -- Runa: seven deeds in my book
  local runa
  for i = 1, 7 do runa = killsMe("Runa", "Kalt", now - i * 86400, "Moder Jock") end
  iKill("Runa", "Kalt", 1)

  -- what guild and friends sent (stand-in for the shared lists; the real getter is asked for everything else)
  local shared = {
    [grimm] = { key = grimm, display = "Grimm Bart", class = "ROGUE", deeds = {
      { t = now - 3600, victim = "Liora Stormwell", zone = "Arathihochland", level = 40, by = "Liora" },
      { t = tOwn, victim = "Moder Jock", zone = "Schlingendorntal", by = "Moder" },   -- my own deed as the guild holds it
      { t = "kaputt", victim = "Niemand Da" }, "kaputt" } },
    [velka] = { key = velka, display = "Velka Dorn", class = "WARLOCK", deeds = {
      { t = now - 7200, victim = "Bertram Eisenfaust", zone = "Brachland", by = "Bertram" } } },
  }
  local boom = false
  local origGet = ns.Guild.Get
  ns.Guild.Get = function(key, src)
    if boom then error("shared list broken") end
    return shared[key] or origGet(key, src)
  end

  ns:Fire("TOGGLE_UI"); K.tick(); K.settle()
  local tabBtn
  for _, f in ipairs(BM.frames) do if f.id == "record" and f.mark and f._scripts and f._scripts.OnClick then tabBtn = f end end
  tabBtn._scripts.OnClick(tabBtn, "LeftButton"); K.tick()
  local P
  for _, f in ipairs(BM.frames) do if f.enemy and f.death then P = f end end
  local function row(key) for _, f in ipairs(BM.frames) do if f.item and f.under and f:IsVisible() and f.item.key == key then return f end end end
  local function sheet(key)
    local r = row(key)
    if P.record.vic:IsShown() and P.record.vic.strike.key == key then return P.record.vic end
    r._scripts.OnClick(r, "LeftButton"); K.tick()
    return P.record.vic
  end
  local function shownDeeds(V) local n = 0; for i = 1, #V.deeds do if V.deeds[i]:IsShown() then n = n + 1 end end return n end
  local function top(f) local _, _, _, t = BM.RectUI(f); return t end
  local function bottom(f) local _, b = BM.RectUI(f); return b end

  -- 1) own deed and a guildmate's, newest first, the own one once
  local V = sheet(grimm)
  check(code .. " label of his deeds shows", V.dlabel:IsShown() and V.drule:IsShown())
  check(code .. " label text", (V.dlabel._text or ""):gsub(" ", "") == (L.VICTIM_DEEDS_LABEL:gsub(" ", "")), V.dlabel._text)
  check(code .. " two deeds (the own one not twice, broken ones dropped)", shownDeeds(V) == 2, shownDeeds(V))
  local l1, l2 = V.deeds[1].text.full or V.deeds[1].text._text or "", V.deeds[2].text.full or V.deeds[2].text._text or ""
  check(code .. " newest first: the guildmate with first name and place", l1:find("Liora", 1, true) and l1:find("Arathihochland", 1, true)
    and not l1:find("Stormwell", 1, true), l1)
  check(code .. " my other char with date, spell and place", l2:find("Moder", 1, true) and l2:find("Blutsauger", 1, true)
    and l2:find(ns.Util.When(tOwn), 1, true), l2)
  local tip = K.hover(V.deeds[2])
  check(code .. " tooltip of the own deed names the victim", tip:find("Moder Jock", 1, true) and tip:find("Schlingendorntal", 1, true), tip)
  -- the own kills stay; the deeds stand below them, nothing on top of another
  check(code .. " own kills stay", V.lines[1]:IsShown() and V.lines[2]:IsShown() and V.label:IsShown())
  local lastKill = V.lines[2]
  check(code .. " label below the last own kill", top(V.dlabel) <= bottom(lastKill) + 0.5, tostring(top(V.dlabel)) .. " / " .. tostring(bottom(lastKill)))
  check(code .. " first deed below its label", top(V.deeds[1]) <= bottom(V.dlabel) + 0.5)
  check(code .. " second deed below the first", top(V.deeds[2]) <= bottom(V.deeds[1]) + 0.5)

  -- 2) the row's tooltip names his newest killing blow
  local rtip = K.hover(row(grimm))
  check(code .. " row tooltip: newest killing blow", rtip:find(ns.F(L.VICTIM_DEED_TIP, { name = "Liora", time = ns.Util.When(now - 3600) }), 1, true), rtip)
  check(code .. " row tooltip of one without deeds: no such line", not K.hover(row(olaf)):find(L.VICTIM_DEED_TIP:match("^[^{]+"), 1, true))

  -- 3) a victim without deeds: the sheet of 1.6.0
  V = sheet(olaf)
  check(code .. " no deeds: label and lines hidden", not V.dlabel:IsShown() and not V.drule:IsShown() and shownDeeds(V) == 0)
  check(code .. " no deeds: the name opens nothing", V.headHit.key == nil)

  -- 4) known from the guild book alone: deeds shown, the name opens the guild poster
  V = sheet(velka)
  check(code .. " guild only: one deed", V.dlabel:IsShown() and shownDeeds(V) == 1, shownDeeds(V))
  check(code .. " guild only: names the guildmate", (V.deeds[1].text.full or V.deeds[1].text._text or ""):find("Bertram", 1, true))
  check(code .. " guild only: the note about the poster shows", V.note:IsShown() and V.headHit.key == velka and V.headHit.shared == true)
  local opened
  local origShow = ns.UI.ShowGuildEnemy
  ns.UI.ShowGuildEnemy = function(key) opened = key end
  V.headHit._scripts.OnClick(V.headHit, "LeftButton")
  ns.UI.ShowGuildEnemy = origShow
  check(code .. " guild only: click on the name opens the guild poster", opened == velka, opened)

  -- 5) more deeds than lines: the last line names the rest
  V = sheet(runa)
  check(code .. " seven deeds: five lines", shownDeeds(V) == 5, shownDeeds(V))
  check(code .. " seven deeds: the last line names three more", (V.deeds[5].text._text or "") == ns.F(L.MORE_LINE, { count = 3 }), V.deeds[5].text._text)
  check(code .. " seven deeds: newest first", (V.deeds[1].text.full or V.deeds[1].text._text or ""):find(ns.Util.When(now - 86400), 1, true))

  -- 6) a broken shared list never breaks the sheet: the own deeds still show
  boom = true
  V = sheet(olaf); V = sheet(grimm)
  check(code .. " broken shared list: sheet shows, own deed stays", V:IsShown() and shownDeeds(V) == 1 and V.lines[1]:IsShown(), shownDeeds(V))
  boom = false

  check(code .. " no errors", #AM.errors == 0 and #BM.violations == 0, AM.errors[1] or BM.violations[1])
end

K.done("victim sheet: his deeds")
