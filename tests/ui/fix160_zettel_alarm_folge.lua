-- Fixer 1.6.0 (ju03): the help call's slip and the alarm never cover each other, whichever comes first; the slip goes
-- back when the alarm goes; an alarm dragged to the top edge gets the slip below it. Names made up.
local WT = arg[1] or "."
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_ju160.lua")
local function apart(s, a)
  return s:GetBottom() >= a:GetTop() or s:GetTop() <= a:GetBottom()
end
for _, code in ipairs({ "deDE", "enUS", "ruRU", "zhCN" }) do
  local W = J.world(WT, code, { guild = "Die Rostigen Naegel" })
  local ns = W.ns
  _G.C_Map.GetMapInfo = function() return { name = "Schlingendorntal", mapType = 3, parentMapID = 13 } end
  ns.Store.ApplyKill({ name = "Velka", surname = "Thornheart", class = "WARLOCK", level = 58 },
    { t = time() - 3600, zone = "Schlingendorntal", source = "recap" }, true)
  -- the alarm first, then the call
  W.AM.AddEnemy("target", { name = "Velka", surname = "Thornheart", guid = "Player-1-VelkaThornheart", class = "WARLOCK",
    level = 58 })
  W.AM.FireEvent("PLAYER_TARGET_CHANGED")
  W.tick(1)
  local text = ns.Call.Encode({ mapID = 1434, x = 46, y = 38, t = time(), display = "Grimwald Ashbrand" })
  W.AM.FireEvent("CHAT_MSG_ADDON", "DeathNoteSOS", text, "GUILD", "Liora-Forever")
  W.tick(1)
  local slip, alarm = rawget(W.G, "DeathNoteCall"), rawget(W.G, "DeathNoteAlert")
  local both = slip and alarm and slip:IsShown() and alarm:IsShown()
  J.check(code .. ": Alarm zuerst, dann Ruf: beide stehen", both)
  if both then
    J.check(code .. ": Alarm zuerst: kein Ueberdecken", apart(slip, alarm),
      ("Zettel %s..%s, Alarm %s..%s"):format(slip:GetBottom(), slip:GetTop(), alarm:GetBottom(), alarm:GetTop()))
    -- the alarm dragged near the top edge (over the slip's place, no room above): the slip goes below it
    alarm:ClearAllPoints()
    alarm:SetPoint("TOP", W.G.UIParent, "TOP", 0, -50)   -- overlaps the slip's place, no room above
    ns.CallUI.Place()
    J.check(code .. ": Alarm am oberen Rand: Zettel darunter", apart(slip, alarm) and slip:GetTop() <= alarm:GetBottom(),
      ("Zettel %s..%s, Alarm %s..%s"):format(slip:GetBottom(), slip:GetTop(), alarm:GetBottom(), alarm:GetTop()))
    -- the alarm goes: the slip goes back to its place
    alarm:Hide()
    W.tick(0.1)
    local H = W.G.UIParent:GetHeight()
    J.check(code .. ": Alarm weg: Zettel an seinem Platz", slip:GetTop() == H + ns.CallUI.POINT[4], slip:GetTop())
  end
end
J.done()
