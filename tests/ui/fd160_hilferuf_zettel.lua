-- Design fixer 1.6.0 (design hunt 1, 17): the help call's slip is built like the bounty notice: the spaced red kicker
-- "HILFERUF", the caller big in the head font, place and attacker in ink below, the hint smaller and faded; as wide as
-- the bounty slip; below the band of the client's red error texts (UIErrorsFrame, TOP -122, 60 high), with and without
-- the alarm; the bounty notice keeps clear of it when all three stand. Names made up.
local WT = arg[1] or "."
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_ju160.lua")
local BAND_BOTTOM = 182          -- 122 + 60: the lower edge of the client's error band, from the top
local function apart(a, b) return a:GetBottom() >= b:GetTop() or a:GetTop() <= b:GetBottom() end
for _, code in ipairs({ "deDE", "enUS" }) do
  local W = J.world(WT, code, { guild = "Die Rostigen Naegel" })
  local ns, L = W.ns, W.ns.L
  _G.C_Map.GetMapInfo = function() return { name = "Schlingendorntal", mapType = 3, parentMapID = 13 } end
  local text = ns.Call.Encode({ mapID = 1434, x = 46, y = 38, t = time(), display = "Grimwald Ashbrand" })
  W.AM.FireEvent("CHAT_MSG_ADDON", "DeathNoteSOS", text, "GUILD", "Liora-Forever")
  W.tick(1)
  local slip = rawget(W.G, "DeathNoteCall")
  J.check(code .. ": Zettel steht", slip and slip:IsShown())
  if slip then
    local H = W.G.UIParent:GetHeight()
    J.check(code .. ": so breit wie der Kopfgeld-Zettel (352)", slip:GetWidth() == 352, slip:GetWidth())
    J.check(code .. ": Kopf ist das gesperrte Wort HILFERUF in Rot",
      slip.kicker and slip.kicker:GetText() == ns.Extras.Spaced(L.CALL_SLIP_HEAD)
        and slip.kicker._tc[1] > 0.4 and slip.kicker._tc[2] < 0.3, slip.kicker and slip.kicker:GetText())
    J.check(code .. ": Rufer gross in der Kopfschrift", slip.name and slip.name:GetText() == "Liora"
      and slip.name.fontKind == "head" and slip.name.fontSize >= 16, slip.name and slip.name.fontSize)
    J.check(code .. ": Ort und Angreifer darunter", slip.line and slip.line:GetText():find("Grimwald Ashbrand", 1, true)
      and slip.line:GetText():find("Schlingendorntal", 1, true), slip.line and slip.line:GetText())
    local ha = slip.hint._tc[4]
    J.check(code .. ": Bedienhinweis kleiner und blasser als die Nachricht",
      slip.hint.fontSize < slip.line.fontSize and ha < 0.8, ("%s/%s, Deckkraft %s"):format(slip.hint.fontSize,
        slip.line.fontSize, tostring(ha)))
    J.check(code .. ": ohne Alarm unter dem Fehlertext-Band", slip:GetTop() <= H - BAND_BOTTOM, H - slip:GetTop())
    -- the alarm comes: the slip moves, never into the band, never under the alarm
    ns.Store.ApplyKill({ name = "Velka", surname = "Thornheart", class = "WARLOCK", level = 58 },
      { t = time() - 3600, zone = "Schlingendorntal", source = "recap" }, true)
    W.AM.AddEnemy("target", { name = "Velka", surname = "Thornheart", guid = "Player-1-VelkaThornheart", class = "WARLOCK",
      level = 58 })
    W.AM.FireEvent("PLAYER_TARGET_CHANGED")
    W.tick(1)
    local alarm = rawget(W.G, "DeathNoteAlert")
    J.check(code .. ": Alarm steht", alarm and alarm:IsShown())
    if alarm and alarm:IsShown() then
      J.check(code .. ": mit Alarm unter dem Fehlertext-Band", slip:GetTop() <= H - BAND_BOTTOM, H - slip:GetTop())
      J.check(code .. ": mit Alarm kein Ueberdecken", apart(slip, alarm))
      -- a bounty notice of a claim on top: it keeps clear of both
      ns.Extras.Slip(L.BANNER_CLAIM, "Osric Bloodmoon", nil, "Liora", "Osric-Bloodmoon")
      W.tick(1)
      local banner = rawget(W.G, "DeathNoteBanner")
      J.check(code .. ": Kopfgeld-Zettel steht", banner and banner:IsShown())
      if banner and banner:IsShown() then
        J.check(code .. ": Kopfgeld-Zettel deckt den Hilferuf nicht", apart(banner, slip),
          ("Kopfgeld %s..%s, Ruf %s..%s"):format(banner:GetBottom(), banner:GetTop(), slip:GetBottom(), slip:GetTop()))
        J.check(code .. ": Kopfgeld-Zettel deckt den Alarm nicht", apart(banner, alarm))
      end
    end
  end
  J.check(code .. ": keine Addon-Fehler", #W.AM.errors == 0, W.AM.errors[1])
end
J.done()
