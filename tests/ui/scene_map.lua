-- 1.5.0 scene: a stand-in for the world map in the UI mock (tests and the picture tool have no client map).
-- The real map (WorldMapFrame) as SceneMap.lua uses it: a canvas to put pins on (1002 x 668 like a zone map at canvas
-- scale 1), GetMapID/SetMapID, the methods SceneMap hooks (OnMapChanged, OnCanvasScaleChanged), C_Map.OpenWorldMap,
-- hooksecurefunc, ShowUIPanel/HideUIPanel. The map art is a parchment field with a faint grid and a river, enough to
-- see and measure pins, bundles and tooltips on it.
-- Use: local SM = dofile(DIR .. "/tests/ui/scene_map.lua"); local wm = SM.Install(BM, { mapID = 1434 })
local SM = {}

function SM.Install(BM, opts)
  opts = opts or {}
  local G = BM.G
  SM.opened, SM.hooks = {}, 0
  local wm = G.CreateFrame("Frame", nil, G.UIParent)
  rawset(G, "WorldMapFrame", wm)
  wm:SetSize(1022, 720)
  wm:SetPoint("CENTER", G.UIParent, "CENTER", 0, 0)
  wm:SetFrameStrata("HIGH")
  local frame = wm:CreateTexture(nil, "BACKGROUND")
  frame:SetAllPoints()
  frame:SetColorTexture(0.12, 0.09, 0.06, 1)
  local title = wm:CreateFontString(nil, "OVERLAY")
  title:SetFont("Fonts\\FRIZQT__.TTF", 14)
  title:SetPoint("TOP", wm, "TOP", 0, -12)
  title:SetTextColor(1, 0.82, 0, 1)
  title:SetText(opts.title or "Stranglethorn Vale")
  wm.title = title
  local sc = G.CreateFrame("Frame", nil, wm)
  sc:SetSize(1002, 668)
  sc:SetPoint("BOTTOM", wm, "BOTTOM", 0, 10)
  wm.ScrollContainer = sc
  local canvas = G.CreateFrame("Frame", nil, sc)
  canvas:SetSize(1002, 668)
  canvas:SetPoint("TOPLEFT", sc, "TOPLEFT", 0, 0)
  local art = canvas:CreateTexture(nil, "BACKGROUND")
  art:SetAllPoints()
  art:SetColorTexture(0.80, 0.72, 0.53, 1)
  -- a faint grid every 100 px and a river across (the map is a stand-in: only the pins are real)
  for i = 1, 9 do
    local v = canvas:CreateTexture(nil, "BORDER")
    v:SetColorTexture(0.45, 0.38, 0.25, 0.18)
    v:SetSize(1, 668)
    v:SetPoint("TOPLEFT", canvas, "TOPLEFT", i * 100, 0)
  end
  for i = 1, 6 do
    local h = canvas:CreateTexture(nil, "BORDER")
    h:SetColorTexture(0.45, 0.38, 0.25, 0.18)
    h:SetSize(1002, 1)
    h:SetPoint("TOPLEFT", canvas, "TOPLEFT", 0, -i * 100)
  end
  for i = 0, 19 do
    local r = canvas:CreateTexture(nil, "BORDER")
    r:SetColorTexture(0.38, 0.52, 0.58, 0.55)
    r:SetSize(54, 14)
    r:SetPoint("TOPLEFT", canvas, "TOPLEFT", i * 50, -(420 + math.floor(40 * math.sin(i / 3))))
  end
  wm._mapID = opts.mapID or 1434
  wm._canvasScale = opts.canvasScale or 1
  wm.GetCanvas = function() return canvas end
  wm.GetMapID = function(self) return self._mapID end
  wm.GetCanvasScale = function(self) return self._canvasScale end
  wm.OnMapChanged = function() end
  wm.OnCanvasScaleChanged = function() end
  wm.SetMapID = function(self, id) self._mapID = id; self:OnMapChanged() end
  rawset(G, "hooksecurefunc", function(t, name, fn)
    local old = t[name]
    SM.hooks = SM.hooks + 1
    t[name] = function(...) local a, b, c = old(...); fn(...); return a, b, c end
  end)
  local function show() if not wm:IsShown() then wm:Show() end end
  rawset(G, "ShowUIPanel", function(f) if f == wm then show() end end)
  rawset(G, "HideUIPanel", function(f) if f == wm then wm:Hide() end end)
  rawset(G, "ToggleWorldMap", function() if wm:IsShown() then wm:Hide() else show() end end)
  local cm = rawget(G, "C_Map") or {}
  cm.OpenWorldMap = function(id)
    if BM.combat then error("C_Map.OpenWorldMap in combat (blocked)") end
    SM.opened[#SM.opened + 1] = id
    show()
    wm:SetMapID(id)
  end
  if opts.rect then cm.GetMapRectOnMap = opts.rect end
  rawset(G, "C_Map", cm)
  if opts.hidden ~= false then wm:Hide() end
  SM.wm, SM.canvas = wm, canvas
  return wm
end

return SM
