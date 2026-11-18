-- Fixer 1.6.0 (ju05): the sheet Guild has one switch for sightings, the old one is gone; its tooltip says what goes
-- out and to whom (deDE, enUS; with and without the friends' sheet layout). Names made up.
local WT = arg[1] or "."
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_ju160.lua")
for _, code in ipairs({ "deDE", "enUS" }) do
  local W = J.world(WT, code, { guild = "Die Rostigen Naegel" })
  local L = W.ns.L
  W.open(); W.ns.UI.OpenPanel("settings"); W.tick(1)
  W.click(W.find(function(f) return f.page == 3 and f._scripts and f._scripts.OnClick and f:IsVisible() end))
  J.check(code .. ": der eine Haken steht da", W.visible(L.OPT_G_LAYERSIGHT) ~= nil, L.OPT_G_LAYERSIGHT)
  J.check(code .. ": der alte Haken nicht", not W.visible(L.OPT_F_SIGHTINGS) and not W.visible(L.OPT_G_SIGHTINGS))
  local cb = W.find(function(f) return f.optTip == "OPT_G_LAYERSIGHT_TIP" and f:IsVisible() end)
  J.check(code .. ": Haken mit Tooltip", cb ~= nil)
  if cb then
    local tip = W.G.GameTooltip
    tip._lines = {}
    cb._scripts.OnEnter(cb)
    local lines = table.concat(tip._lines or {}, "\n")
    J.check(code .. ": Tooltip sagt was und an wen", lines:find(L.OPT_G_LAYERSIGHT_TIP, 1, true) ~= nil, lines)
    J.check(code .. ": Tooltip steht", tip:IsShown())
    cb._scripts.OnLeave(cb)
    J.check(code .. ": Tooltip geht", not tip:IsShown())
  end
  J.check(code .. ": Standard an", cb and cb:GetChecked() == true, cb and tostring(cb:GetChecked()))
end
J.done()
