-- 1.5.0 fixer: finds of the fixer's own overlap hunt. (1) The head of a guest card steps down far enough: huHU
-- "KEGYELMET KAPOTT" (pardoned) and the itIT week card "Settimana di Bertram" were cut without a tooltip. (2) The list
-- of a bundle on the map: rows wide enough for "date · sentence", and a cut row shows itself whole on hover.
-- Names made up.
local WT = arg[1] or "."
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_jukarte.lua")

local function guest(code, build)
  local W = J.world(WT, code)
  local ns, L = W.ns, W.ns.L
  local line = build(ns, L)
  local out = ns.Share.Linkify(line, "Bertram-Forever")
  local id = out and out:match("|Haddon:DeathNote:share:(%d+)|h")
  ns.ShareUI.OnLink("addon:DeathNote:share:" .. tostring(id)); W.settle()
  return ns.ShareUI.GuestFrame(), ns
end
local gp, ns = guest("huHU", function(ns, L)
  return ns.Share.Build("Odric Thornbush", { L.SHARE_KIND_PARDONED, ns.F(L.STAND_LINE, { score = "3 : 2" }) })
end)
J.check("huHU begnadigt: Kopf ganz", gp.head:GetText() == ns.L.SHARE_KIND_PARDONED and ns.Look.IsCut(gp.head) == false,
  tostring(ns.Look.IsCut(gp.head)))
gp, ns = guest("itIT", function(ns, L)
  return ns.Share.Build("Odric Thornbush", { L.SHARE_WEEK_HEAD, ns.F(L.SHARE_WEEK_TOP, { times = "3×" }),
    ns.F(L.SHARE_WEEK_REVENGE, { count = 1 }) })
end)
J.check("itIT Woche: Kopf ganz", gp.head:GetText() == ns.F(ns.L.SHARE_GUEST_WEEK, { name = "Bertram" })
  and ns.Look.IsCut(gp.head) == false, gp.head:GetText())

-- (2) the bundle's list
local W = J.map(WT, { mapID = 1434 })
W.death("Grimm", 40, 40, 600)
W.death("Fies", 40.3, 40.2, 900)
W.show()
local pin
for _, f in ipairs(W.pins()) do if f.data and f.data.count > 1 then pin = f end end
J.check("ein Buendel", pin ~= nil)
if pin then pin._scripts.OnMouseUp(pin, "LeftButton"); W.settle() end
local pick = W.ns.SceneMap.Pick()
J.check("Liste offen", pick and pick:IsShown())
local rows = pick and pick.rows or {}
J.check("Liste breit genug (mind. 380)", pick and pick:GetWidth() >= 380, pick and pick:GetWidth())
local r1 = rows[1]
J.check("Zeile zeigt sich beim Ueberfahren ganz", r1 and r1._scripts and r1._scripts.OnEnter ~= nil and r1.cutFs == r1.text)
J.done()
