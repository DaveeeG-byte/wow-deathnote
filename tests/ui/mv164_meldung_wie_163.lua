-- 1.6.4 move: a notice the player never moved stands exactly where 1.6.3 put it, in every case 1.6.3 showed: alone,
-- under the alarm at its default place, the alarm dragged elsewhere (top, middle, bottom, a corner), the alarm at
-- 150 %, with the help call slip, with a dry remark under it (Humor on), at UI scale 0.6. Compared against the real
-- 1.6.3 (git archive v1.6.3), not against numbers from memory. Without the repository: one line, skipped.
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_mv164.lua")
local GitBase = dofile(J.WT .. "/tests/git_base.lua")
local check = J.check

local old, why = GitBase.Archive(J.WT, "v1.6.3")
if not old then
  -- visible in the suite: the guard did not run (GitBase.Skip, as the other comparisons with older versions)
  GitBase.Skip("mv164_meldung_wie_163", "SKIPPED, the comparison with 1.6.3 did not run (" .. tostring(why) .. ")")
  os.exit(0)
end

local CASES = {
  { "allein", nil },
  { "Alarm Standard", {} },
  { "Alarm oben links", { point = { "TOPLEFT", "TOPLEFT", 20, -20 } } },
  { "Alarm Mitte", { point = { "CENTER", "CENTER", 0, 0 } } },
  { "Alarm auf der Meldung", { point = { "TOP", "TOP", 0, -300 } } },
  { "Alarm darunter", { point = { "TOP", "TOP", 0, -420 } } },
  { "Alarm unten", { point = { "BOTTOM", "BOTTOM", 0, 10 } } },
  { "Alarm ganz oben 150 %", { point = { "TOP", "TOP", 0, -5 }, scale = 1.5 } },
  { "Alarm 150 % Standard", { scale = 1.5 } },
  { "Alarm und Zettel", {}, true },
  { "Zettel allein", nil, true },
}

-- the notice's rectangle (and the slip's) in one world, case c, UI scale ui, Humor on/off
local function measure(dir, c, ui, humor)
  local alert = c[2] and { point = c[2].point, scale = c[2].scale } or nil
  local db = { version = 5, settings = { welcomed = true, firstRun = "done", news164 = true, news160 = true, news150 = true,
    news140 = true, lang = "deDE", alert = alert, humor = humor }, enemies = {}, deaths = {} }
  local W = J.world("deDE", { db = db, ui = ui, dir = dir })
  if c[2] then
    W.ns.Store.AddManual("Velka Thornheart")
    W.ns:Fire("TEST_ALERT"); W.tick(0.5)
  end
  if c[3] then
    W.ns.CallUI.Show({ by = "Liora", zone = "Ashenvale", same = true, display = "Grimwald Ashbrand", mapID = 1440, x = 1, y = 1 })
    W.tick(0.1)
  end
  W.ns.Extras.Notice("RANG", "Grimwald", "Zeile"); W.tick(0.1)
  local b = W.frame("DeathNoteBanner")
  local s = W.frame("DeathNoteCall")
  local n = W.errors()
  return { W.rect(b) }, (s and s:IsShown()) and { W.rect(s) } or {}, n, b:IsShown()
end

local function eq(r1, r2)
  if #r1 ~= #r2 then return false end
  for i = 1, #r1 do if math.abs(r1[i] - r2[i]) > 0.01 then return false end end
  return true
end
local function fmt(r) return #r > 0 and ("%.1f %.1f %.1f %.1f"):format(r[1], r[2], r[3], r[4]) or "-" end

for _, ui in ipairs({ 1, 0.6 }) do
  for _, humor in ipairs({ false, true }) do
    for _, c in ipairs(CASES) do
      local tag = ("UI %s%s %s"):format(ui, humor and " Humor" or "", c[1])
      local b0, s0, e0, v0 = measure(old, c, ui, humor)
      local b1, s1, e1, v1 = measure(nil, c, ui, humor)
      check(tag .. ": Meldung wie 1.6.3", v0 == v1 and eq(b0, b1), fmt(b1) .. " statt " .. fmt(b0))
      check(tag .. ": Zettel wie 1.6.3", eq(s0, s1), fmt(s1) .. " statt " .. fmt(s0))
      check(tag .. ": keine Fehler", e0 == 0 and e1 == 0)
    end
  end
end
GitBase.Clean()
J.done("mv164_meldung_wie_163")
