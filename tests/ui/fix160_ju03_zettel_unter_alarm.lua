-- ju03: Abnahme im Kampf. Ein Gildie ruft um Hilfe (Zettel oben, TOP -150, Schicht HIGH), zugleich kommt ein Moerder
-- in Sicht (Alarm, TOP -190, Schicht HIGH). Der Alarm liegt ueber dem unteren Teil des Zettels und deckt dessen
-- Zeile "Klick: Karte dort oeffnen · Rechtsklick: schliessen" (Bild bilder/ju-zettel-alarm-deDE.png). Erwartet: beide
-- ganz lesbar (Zettel ueber oder unter dem Alarm, oder der Alarm rueckt). Namen erfunden.
local WT = arg[1] or "."
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_ju160.lua")
for _, code in ipairs({ "deDE", "enUS" }) do
  local W = J.world(WT, code, { guild = "Die Rostigen Naegel" })
  local ns = W.ns
  _G.C_Map.GetMapInfo = function() return { name = "Schlingendorntal", mapType = 3, parentMapID = 13 } end
  local key = ns.Store.ApplyKill({ name = "Velka", surname = "Thornheart", class = "WARLOCK", level = 58 },
    { t = time() - 3600, zone = "Schlingendorntal", source = "recap" }, true)
  local text = ns.Call.Encode({ mapID = 1434, x = 46, y = 38, t = time(), display = "Grimwald Ashbrand" })
  W.AM.FireEvent("CHAT_MSG_ADDON", "DeathNoteSOS", text, "GUILD", "Liora-Forever")
  W.tick(1)
  W.AM.AddEnemy("target", { name = "Velka", surname = "Thornheart", guid = "Player-1-VelkaThornheart", class = "WARLOCK",
    level = 58 })
  W.AM.FireEvent("PLAYER_TARGET_CHANGED")
  W.tick(1)
  local slip, alarm = rawget(W.G, "DeathNoteCall"), rawget(W.G, "DeathNoteAlert")
  local both = slip and alarm and slip:IsShown() and alarm:IsShown()
  J.check(code .. ": Zettel und Alarm stehen beide", both, tostring(slip and slip:IsShown()) .. "/" .. tostring(alarm and alarm:IsShown()))
  if both then
    local sb, at = slip:GetBottom(), alarm:GetTop()
    J.check(code .. ": Alarm deckt den Zettel nicht (Zettel unten " .. tostring(sb) .. ", Alarm oben " .. tostring(at) .. ")",
      sb and at and (sb >= at or slip:GetTop() <= alarm:GetBottom()), ("Ueberdeckung %.1f"):format((at or 0) - (sb or 0)))
  end
end
J.done()
