-- 1.3.0: rap sheet notices (new rank, awards) are never lost. One own kill can bring four awards (first entry, a red
-- one without a group, revenge on the same day, revenge after ten deaths by him) and a new rank. They wait in a queue
-- of their own without a cap (in combat, behind the revenge notice, while the first-start dialog of a new installation
-- is open) and come as at most two notices per kill: the rank, and one notice "4 awards" naming them in its line; a chat
-- line names them all. Played out of combat, in combat, and with the first-start dialog open (the real Start.lua).
-- Call from the project root: luajit tests/ui/notice_queue.lua .
local DIR = (arg[1] or "."):gsub("/+$", "")
package.path = DIR .. "/tests/ui/?.lua;" .. DIR .. "/tests/?.lua;" .. package.path
arg[0] = DIR .. "/tests/ui/notice_queue.lua"
local ADDON = DIR .. "/DeathNote"
local okN, badN = 0, 0
local current = ""
local function check(name, cond, info)
  if cond then okN = okN + 1 else badN = badN + 1; io.write("RED   ", current, ": ", name, info ~= nil and ("  -> " .. tostring(info)) or "", "\n") end
end

local function tocFiles()
  local out = {}
  for line in io.lines(ADDON .. "/DeathNote.toc") do
    line = line:gsub("\r", ""):gsub("%s+$", "")
    if line ~= "" and not line:find("^#") and line:find("%.lua$") then out[#out + 1] = (line:gsub("\\", "/")) end
  end
  return out
end

-- the whole addon in TOC order (logic in the logic mock, drawing files in the UI mock); db nil = a new installation
local AM, BM, G
local function world(code, db)
  package.loaded.mock_wow, package.loaded.mock = nil, nil
  AM = require("mock_wow")
  BM = require("mock")
  BM.mediaDir = ADDON .. "/Media"
  G = BM.G
  AM.Reset()
  AM.locale, AM.client = code, code
  _G.DeathNoteDB = db
  local LOGIC = {}
  for _, f in ipairs(AM.FILES) do LOGIC[f] = true end
  local ns, ui = {}, false
  for _, f in ipairs(tocFiles()) do
    if f == "Alert.lua" then ui = true end
    if LOGIC[f] or not ui then assert(loadfile(ADDON .. "/" .. f))("DeathNote", ns) else BM.Load(ADDON .. "/" .. f, ns) end
  end
  AM.ns = ns
  AM.units.player.level = 40
  AM.FireEvent("ADDON_LOADED", "DeathNote")
  AM.FireEvent("PLAYER_LOGIN")
  AM.FireEvent("PLAYER_ENTERING_WORLD")
  return ns
end
local function tick(s) AM.Advance(s or 0.1); BM.Advance(s or 0.1) end
local function combat(on)
  BM.combat = on; AM.inCombat = on
  rawset(G, "InCombatLockdown", function() return on end); _G.InCombatLockdown = G.InCombatLockdown
end

-- every notice that showed: "kicker|name|line" in order of appearance
local function watcher(list)
  local last
  return function()
    local b = rawget(G, "DeathNoteBanner")
    if b and b:IsShown() then
      local s = tostring(b.kicker._text) .. "|" .. tostring(b.name._text) .. "|" .. tostring(b.line._text)
      if s ~= last then list[#list + 1] = s; last = s end
    else
      last = nil
    end
  end
end

-- he killed me ten times today (invented player), then my first own kill on him: four awards and a new rank
local function play(ns, how)
  for i = 1, 10 do
    ns.Store.ApplyKill({ name = "Rolf", surname = "Rot", class = "ROGUE", level = 46, guid = "Player-93-RolfRot" },
      { t = time() - 600 * i, zone = "Testtal" }, true)
  end
  local awards, ranks, chat = {}, 0, {}
  ns:On("AWARD", function(id) local n = ns.Humor.Award(id); if n then awards[#awards + 1] = n end end)
  ns:On("REPUTE_RANK", function() ranks = ranks + 1 end)
  local print0 = ns.Util.Print
  ns.Util.Print = function(t) chat[#chat + 1] = tostring(t); return print0(t) end
  local seen = {}
  local watch = watcher(seen)
  -- nine points on the accounts: the kill lifts the rank
  local db = ns.Ledger.DB()
  db.acc.s, db.tier = 9, 1
  if how == "combat" then combat(true) end
  AM.AddEnemy("nameplate1", { name = "Rolf", surname = "Rot", level = 46, guid = "Player-93-RolfRot", class = "ROGUE" })
  AM.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate1")
  AM.FireEvent("PARTY_KILL", AM.units.player.guid or "Player-93-0000AAAA", "Player-93-RolfRot"); tick()
  watch()
  if how == "combat" then
    for _ = 1, 30 do tick(0.5); watch(); BM.FinishAnims(); watch() end
    combat(false); AM.FireEvent("PLAYER_REGEN_ENABLED")
  elseif how == "first" then
    for _ = 1, 30 do tick(0.5); watch(); BM.FinishAnims(); watch() end
    check("first-start dialog still open while the kill came", ns.Start.Holding() and rawget(G, "DeathNoteStart") and G.DeathNoteStart:IsShown())
    local early = 0
    for _, x in ipairs(seen) do if not x:find("Rolf Rot", 1, true) then early = early + 1 end end
    check("no rap sheet notice while the dialog is open (the revenge notice may come)", early == 0, table.concat(seen, " / "))
    ns.Start.Go(); tick(); watch()
  end
  for _ = 1, 80 do tick(0.5); watch(); BM.FinishAnims(); watch() end
  return awards, ranks, seen, chat
end

local function run(code, how)
  current = code .. " " .. how
  local ns = world(code, how ~= "first" and { settings = {} } or nil)
  tick(3.2)
  if how ~= "first" then
    check("no first-start dialog for an existing installation", not ns.Start.Holding())
  else
    check("first-start dialog open", rawget(G, "DeathNoteStart") ~= nil and G.DeathNoteStart:IsShown())
  end
  local awards, ranks, seen, chat = play(ns, how)
  local L = ns.L
  check("the kill brings four awards", #awards == 4, #awards)
  check("and a new rank", ranks == 1, ranks)
  local rank, sum, single = 0, nil, 0
  for _, s in ipairs(seen) do
    local k, n, l = s:match("^(.-)|(.-)|(.*)$")
    if n == ns.Ranks.Title(ns.Ledger.DB().tier, ns.Ledger.DB().path) then rank = rank + 1 end
    if n and n:find("^4 ") then sum = { k = k, n = n, l = l } end
    for _, a in ipairs(awards) do if n == a then single = single + 1 end end
  end
  local sheet = rank + (sum and 1 or 0) + single
  check("the rank notice came", rank == 1, table.concat(seen, " / "))
  check("one notice for all four awards", sum ~= nil and single == 0, table.concat(seen, " / "))
  check("at most two rap sheet notices for the kill", sheet == 2, sheet)
  if sum then
    check("its head says awards", sum.k ~= nil and sum.k ~= "", sum.k)
    local inLine = 0
    for _, a in ipairs(awards) do if sum.l:find(a, 1, true) then inLine = inLine + 1 end end
    check("its line names the awards (as far as it fits)", inLine >= 1, sum.l)
  end
  local line
  for _, c in ipairs(chat) do
    local all = true
    for _, a in ipairs(awards) do if not c:find(a, 1, true) then all = false end end
    if all and #awards > 0 then line = c end
  end
  check("a chat line names all four awards", line ~= nil, table.concat(chat, " / "))
  check("no addon errors", #AM.errors == 0 and #BM.violations == 0, AM.errors[1] or BM.violations[1])
end

for _, code in ipairs({ "deDE", "enUS" }) do
  for _, how in ipairs({ "calm", "combat", "first" }) do run(code, how) end
end

io.write(("Rap sheet notices of one kill: %d green, %d red\n"):format(okN, badN))
os.exit(badN == 0 and 0 or 1)
