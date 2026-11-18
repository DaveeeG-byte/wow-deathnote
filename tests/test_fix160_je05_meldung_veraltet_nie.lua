-- Fixer 2 1.6.0 (je05): a look at an attacker that changes nothing on the notice tells it nothing (GRUDGE_UPDATE only on
-- a change), the notice's OnUpdate does its work at most Card.TICKS times per second. Never stale: through a fight with
-- every kind of look (hits, casts, target, unit target, a new attacker, a level that changes, a pet, a creature on me)
-- the notice shows after every second what a fresh fill shows, and every change of a row came with GRUDGE_UPDATE.
-- The time still runs out at the end. All names are made up.
local DIR = ((arg and arg[1]) or "."):gsub("/+$", "")
local HERE = debug.getinfo(1, "S").source:match("^@(.*)/[^/]+$") or "."
package.path = HERE .. "/?.lua;" .. package.path
local J = require("_je")
local hp, level = 100000, 40
local W = J.world(DIR, { guild = "Die Testgilde", before = function()
  _G.UnitHealth = function() hp = hp - 7; return hp end
  _G.UnitAffectingCombat = function() return true end
end })
local ns, AM, BM = W.ns, W.AM, W.BM
W.tick(60)
local FOES = { { "Fremder", "Eins" }, { "Fremder", "Zwei" }, { "Fremder", "Drei" }, { "Fremder", "Vier" }, { "Fremder", "Fuenf" },
  { "Fremder", "Sechs" } }
local function hostile(token, i)
  AM.AddEnemy(token, { name = FOES[i][1], surname = FOES[i][2], guid = "Player-93-F00" .. i, target = "player",
    level = i == 2 and level or 40 })
end

-- what the rows hold (everything but the times), and what the notice shows
local function rowsNow()
  local e = ns.Grudge.Current()
  if not e then return "-" end
  local out = { tostring(e.id), tostring(e.running), tostring(e.closed), tostring(#e.order) }
  for _, key in ipairs(e.order) do
    local r, f = e.rows[key], {}
    for k, v in pairs(r) do
      if k ~= "at" and k ~= "cleanHit" and k ~= "floor" and k ~= "cast" and type(v) ~= "table" then f[#f + 1] = k .. "=" .. tostring(v) end
    end
    for p in pairs(r.proofs or {}) do f[#f + 1] = "p:" .. p end
    table.sort(f)
    out[#out + 1] = key .. "{" .. table.concat(f, ",") .. "}"
  end
  return table.concat(out, ";")
end
local card = rawget(BM.G, "DeathNoteGrudge")
local function under(f)
  local p = f
  for _ = 1, 10 do
    if not p then return false end
    if p == card then return true end
    p = p.GetParent and p:GetParent() or nil
  end
  return false
end
local function shownNow()
  card = card or rawget(BM.G, "DeathNoteGrudge")
  if not card then return "-" end
  local out = { tostring(card:IsShown()) }
  for i, f in ipairs(BM.frames) do
    if f ~= card and under(f) then out[#out + 1] = i .. ":" .. tostring(f:IsShown()) .. ":" .. tostring(f._text) end
  end
  return table.concat(out, "|")
end

local told, fires = rowsNow(), 0
ns:On("GRUDGE_UPDATE", function() fires = fires + 1; told = rowsNow() end)
local stale, silent = 0, 0
for i = 1, 5 do hostile("nameplate" .. i, i); AM.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate" .. i) end
AM.FireEvent("PLAYER_REGEN_DISABLED")
for s = 1, 29 do
  if s == 10 then level = 42 end                                  -- a level that changes
  if s == 15 then hostile("nameplate6", 6); AM.FireEvent("NAME_PLATE_UNIT_ADDED", "nameplate6") end   -- a new attacker
  local function look(fn)
    fn()
    -- a change of the rows that the notice was not told
    if rowsNow() ~= told then silent = silent + 1 end
  end
  for _ = 1, 4 do look(function() AM.FireEvent("UNIT_HEALTH", "player") end) end
  for _ = 1, 3 do look(function() AM.FireEvent("UNIT_COMBAT", "player", "WOUND", "", 120, 1) end) end
  for k = 1, 4 do look(function() AM.FireEvent("UNIT_SPELLCAST_SUCCEEDED", "nameplate" .. ((s + k) % 5 + 1), "Cast-1", 1752) end) end
  for k = 1, 3 do look(function() AM.FireEvent("UNIT_TARGET", "nameplate" .. ((s + k) % 5 + 1)) end) end
  look(function() hostile("target", s % 5 + 1); AM.FireEvent("PLAYER_TARGET_CHANGED") end)
  W.tick(1)
  local before = shownNow()
  local e = ns.Grudge.Current()
  if e and ns.GrudgeCard.Holds(e) then ns.GrudgeCard.Fill(e) end
  if shownNow() ~= before then stale = stale + 1 end
end
J.check("die Meldung hat 6 Zeilen", #(ns.Grudge.Current() or { order = {} }).order == 6)
J.check("jede Änderung einer Zeile kam mit GRUDGE_UPDATE", silent == 0, silent)
J.check("die Meldung zeigt nach jeder Sekunde den Stand einer frischen Füllung", stale == 0, stale)
J.check("Blicke ohne Änderung sagen nichts (höchstens 150 GRUDGE_UPDATE in 30 s)", fires <= 150, fires)
J.check("es gab stille Blicke", (ns.Grudge.quietLooks or 0) > 100, ns.Grudge.quietLooks)

-- the OnUpdate: at most TICKS works per second, the time still runs out
local ticks, tick = 0, ns.GrudgeCard.Tick
ns.GrudgeCard.Tick = function(dt) ticks = ticks + 1; return tick(dt) end
AM.FireEvent("PLAYER_REGEN_ENABLED")
local onUpdate = card and card._scripts and card._scripts.OnUpdate
J.check("die Meldung hat ein OnUpdate", onUpdate ~= nil)
local frames = 0
for _ = 1, 60 * 5 do
  if card:IsShown() and onUpdate then onUpdate(card, 1 / 60); frames = frames + 1 end
end
J.check("in 5 s mit 60 Bildern je Sekunde höchstens 4 Arbeiten je Sekunde", ticks <= 21, ticks .. " in " .. frames .. " Bildern")
for _ = 1, 60 * 200 do
  if not card:IsShown() then break end
  if onUpdate then onUpdate(card, 1 / 60) end
end
J.check("die Zeit läuft trotzdem ab (die Meldung geht)", not card:IsShown())
J.check("keine Fehler der Attrappe", #AM.errors == 0, AM.errors[1])
J.done()
