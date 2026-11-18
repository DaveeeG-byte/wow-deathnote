local ADDON, ns = ...

-- 1.5.0 grip: the mark on the nameplate of somebody in the book. Builds on the nameplate status of 1.2.2 (Core.lua:
-- Util.CheckPlates / PLATES_CHANGED): with the enemy plates off there is nothing to mark, and the marks go.
--   wanted (in the book, not pardoned): the red thumbtack and the standing "me : him" beside it (Look.Score)
--   nothing but attacks (grudge): a plain grey thumbtack, no standing
--   on the hit list (guild or friends, not pardoned by me): the crosshair stamp, the standing when there is one
-- Rules: only the open world (in instances the plates are forbidden or their names secret: nothing is touched there);
-- an own frame per plate, a child of that plate (it follows the plate's scale and fading), nothing of the plate is
-- changed; the frames come from a pool; no OnUpdate, only events; every client value guarded (IsSecret first); every
-- step in pcall, an error is counted (probe.grip) and never reaches the book, the alarm or the death detection.
-- Unmeasured in the game: whether C_NamePlate.GetNamePlateForUnit answers on Forever in the open world (probe.grip).

local Util = ns.Util
local Call, IsSecret, Str, True = Util.Call, Util.IsSecret, Util.Str, Util.True

local Plate = {}
ns.Plate = Plate

Plate.SIZES = { small = { icon = 14, font = 9 }, medium = { icon = 18, font = 11 }, large = { icon = 24, font = 13 } }
Plate.ORDER = { "off", "small", "medium", "large" }   -- the stepper on the House Rules (off = plate.enabled false)
Plate.MEDIA = "Interface\\AddOns\\" .. (ADDON or "DeathNote") .. "\\Media\\"
Plate.TEX = { pin = Plate.MEDIA .. "pin.tga", cross = Plate.MEDIA .. "crosshair.tga" }
Plate.GAP = 2            -- px between the top of the plate and the mark
Plate.MAX_POOL = 40      -- marks kept for reuse

local active = {}        -- unit token -> mark (shown)
local unitKey = {}       -- unit token -> book key of the plate (players only)
local plates = {}        -- unit tokens of the visible plates
local pool = {}
local counts = { seen = 0, players = 0, marks = 0, secret = 0, forbidden = 0, noFrame = 0, instance = 0, errors = 0,
  hidden = 0, built = 0 }
local lastError

---------------------------------------------------------------------------
-- Settings and the kind of mark
---------------------------------------------------------------------------
local function setting(path, def)
  local S = ns.Store
  if not (S and S.DB and S.DB()) then return def end
  local v = S.Setting(path)
  if v == nil then return def end
  return v
end

function Plate.Enabled() return setting("plate.enabled", true) ~= false end
function Plate.Size()
  local v = setting("plate.size", "medium")
  return Plate.SIZES[v] and v or "medium"
end
-- the value of the House Rules' stepper: "off", "small", "medium", "large"
function Plate.Choice() return Plate.Enabled() and Plate.Size() or "off" end
function Plate.SetChoice(v)
  local S = ns.Store
  if not (S and S.Setting and S.DB and S.DB()) then return end
  if v == "off" then S.Setting("plate.enabled", false); return end
  if not Plate.SIZES[v] then return end
  if setting("plate.size", "medium") ~= v then S.Setting("plate.size", v) end
  if not Plate.Enabled() then S.Setting("plate.enabled", true) end
end

-- "wanted", "grudge", "hunt" or nil for a book key; the standing text ("2 : 5") or nil
function Plate.Kind(key)
  if type(key) ~= "string" then return nil end
  local S = ns.Store
  local e = S and S.Get and S.Get(key)
  if e and e.status == "pardoned" then return nil end
  local G = ns.Guild
  local hunt = false
  if G and G.Hunt then
    local ok, h = pcall(G.Hunt, key, "all")
    hunt = ok and type(h) == "table"
  end
  local Look = ns.Look
  local score = Look and Look.Score and Look.Score(key) or nil
  if hunt then return "hunt", score end
  if not e or e.status ~= "wanted" then return nil end
  if S.OnlyAttacks and S.OnlyAttacks(e) then return "grudge", nil end
  return "wanted", score
end

---------------------------------------------------------------------------
-- The marks (pool)
---------------------------------------------------------------------------
local function newMark()
  local f = CreateFrame("Frame")
  f:Hide()
  if f.EnableMouse then f:EnableMouse(false) end
  f.icon = f:CreateTexture(nil, "ARTWORK")
  f.icon:SetPoint("LEFT", 0, 0)
  f.score = f:CreateFontString(nil, "OVERLAY")
  f.score:SetPoint("LEFT", f.icon, "RIGHT", 2, 0)
  f.score:SetJustifyH("LEFT")
  if f.score.SetWordWrap then f.score:SetWordWrap(false) end
  counts.built = counts.built + 1
  return f
end

local function release(unit)
  local m = active[unit]
  if not m then return end
  active[unit] = nil
  m:Hide()
  m:ClearAllPoints()
  m.unit, m.key = nil, nil
  if #pool < Plate.MAX_POOL then pool[#pool + 1] = m end
end

local function fill(m, kind, score)
  local sz = Plate.SIZES[Plate.Size()]
  local Look = ns.Look
  local icon = kind == "grudge" and math.floor(sz.icon * 0.8 + 0.5) or sz.icon
  m.icon:SetSize(icon, icon)
  local tex = kind == "hunt" and Plate.TEX.cross or Plate.TEX.pin
  local okT = m.icon:SetTexture(tex)
  if okT == false then m.icon:SetColorTexture(0.7, 0.05, 0.05, 1) end
  if m.icon.SetDesaturated then m.icon:SetDesaturated(kind == "grudge") end
  if kind == "grudge" then m.icon:SetVertexColor(0.55, 0.52, 0.48, 0.9) else m.icon:SetVertexColor(1, 1, 1, 1) end
  local text = kind ~= "grudge" and type(score) == "string" and score or ""
  if Look and Look.Font then Look.Font(m.score, "body", sz.font, "OUTLINE") end
  local bone = Look and Look.BONE or { 0.93, 0.89, 0.8, 1 }
  m.score:SetTextColor(bone[1], bone[2], bone[3], 1)
  m.score:SetShadowOffset(0, 0)
  m.score:SetText(text)
  m.score:SetShown(text ~= "")
  local w = icon
  if text ~= "" then
    local okW, tw = pcall(m.score.GetStringWidth, m.score)
    w = w + 2 + ((okW and type(tw) == "number") and math.ceil(tw) or sz.font * 3)
  end
  m:SetSize(w, math.max(icon, sz.font + 2))
  m.kind, m.text = kind, text
end

-- the plate frame of a unit, or nil (counted why)
local function plateFrame(unit)
  local NP = rawget(_G, "C_NamePlate")
  local fn = NP and NP.GetNamePlateForUnit
  if type(fn) ~= "function" then counts.noFrame = counts.noFrame + 1; return nil end
  local ok, frame = pcall(fn, unit)
  if not ok then counts.errors = counts.errors + 1; lastError = "GetNamePlateForUnit"; return nil end
  if IsSecret(frame) then counts.secret = counts.secret + 1; return nil end
  if type(frame) ~= "table" then counts.noFrame = counts.noFrame + 1; return nil end
  if type(frame.IsForbidden) == "function" then
    local okF, forb = pcall(frame.IsForbidden, frame)
    if not okF or IsSecret(forb) or forb == true then counts.forbidden = counts.forbidden + 1; return nil end
  end
  return frame
end

-- may marks show at all right now (switch, open world, enemy plates)?
local function mayShow()
  if not Plate.Enabled() then return false end
  if not Util.IsOpenWorld() then return false end
  if Util.platesOn == false then return false end
  return true
end

-- looks at one plate: sets, refreshes or takes away its mark
local function update(unit)
  local key = unitKey[unit]
  local kind, score
  if key then kind, score = Plate.Kind(key) end
  if not kind then release(unit); return end
  if not mayShow() then release(unit); counts.hidden = counts.hidden + 1; return end
  local m = active[unit]
  if m and m.key == key then
    if m.kind ~= kind or m.text ~= ((kind ~= "grudge" and score) or "") or m.size ~= Plate.Size() then
      fill(m, kind, score); m.size = Plate.Size()
    end
    return
  end
  local frame = plateFrame(unit)
  if not frame then release(unit); return end
  m = m or table.remove(pool) or newMark()
  m:SetParent(frame)
  m:ClearAllPoints()
  m:SetPoint("BOTTOM", frame, "TOP", 0, Plate.GAP)
  m.unit, m.key = unit, key
  fill(m, kind, score)
  m.size = Plate.Size()
  m:Show()
  active[unit] = m
  counts.marks = counts.marks + 1
end

local function guarded(fn, ...)
  local ok, err = pcall(fn, ...)
  if not ok then
    counts.errors = counts.errors + 1
    lastError = type(err) == "string" and not IsSecret(err) and err:sub(1, 160) or "error"
  end
end

-- whose plate is it (players only; the identity of the Tracker, the GUID beats the first name), then its mark
local function identify(unit)
  unitKey[unit] = nil
  if not Plate.Enabled() then return end
  if not Util.IsOpenWorld() then counts.instance = counts.instance + 1; return end
  local T = ns.Tracker
  local key = T and T.Identity and T.Identity(unit)
  if not key then return end
  counts.players = counts.players + 1
  if T.IsUnitOf and not T.IsUnitOf(unit, key) then return end
  unitKey[unit] = key
  update(unit)
end

local function added(unit)
  plates[unit] = true
  counts.seen = counts.seen + 1
  identify(unit)
end

local function removed(unit)
  plates[unit] = nil
  unitKey[unit] = nil
  release(unit)
end

-- the plates again (a setting, the book, the hit list or the place changed): key = only that player's plate;
-- again = read every plate's identity anew (a key changed, the switch or the place allows marks again)
function Plate.Refresh(key, again)
  for unit in pairs(plates) do
    if again or (key == nil and not unitKey[unit]) then
      guarded(identify, unit)
    elseif key == nil or unitKey[unit] == key then
      guarded(update, unit)
    end
  end
end

function Plate.Clear()
  for unit in pairs(active) do release(unit) end
end

---------------------------------------------------------------------------
-- Probe (/dn probe: probe.grip) and tests
---------------------------------------------------------------------------
function Plate.ProbeSnapshot()
  local c = {}
  for k, v in pairs(counts) do c[k] = v end
  local n = 0
  for _ in pairs(active) do n = n + 1 end
  local NP = rawget(_G, "C_NamePlate")
  return { counts = c, shown = n, pool = #pool, enabled = Plate.Enabled(), size = Plate.Size(),
    api = type(NP and NP.GetNamePlateForUnit) == "function", plates = Util.platesOn, lastError = lastError }
end

function Plate.Active(unit) return active[unit] end

function Plate.Reset()
  Plate.Clear()
  active, unitKey, plates, pool = {}, {}, {}, {}
  for k in pairs(counts) do counts[k] = 0 end
  lastError = nil
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------
ns:RegisterEvent("NAME_PLATE_UNIT_ADDED", function(_, unit)
  if IsSecret(unit) or type(unit) ~= "string" then return end
  guarded(added, unit)
end)
ns:RegisterEvent("NAME_PLATE_UNIT_REMOVED", function(_, unit)
  if IsSecret(unit) or type(unit) ~= "string" then return end
  guarded(removed, unit)
end)
ns:RegisterEvent("PLAYER_ENTERING_WORLD", function()
  Plate.Clear()
  plates, unitKey = {}, {}
end)
ns:RegisterEvent("ZONE_CHANGED_NEW_AREA", function() Plate.Refresh(nil, true) end)
local function refreshKey(key) Plate.Refresh(type(key) == "string" and not IsSecret(key) and key or nil) end
ns:On("ENEMY_UPDATED", refreshKey)
ns:On("ENEMY_STATUS", refreshKey)
ns:On("ENEMY_REMOVED", refreshKey)
ns:On("ENEMY_REKEYED", function() Plate.Refresh(nil, true) end)
ns:On("GUILD_UPDATED", function() Plate.Refresh() end)
ns:On("STANDING_CHANGED", function() Plate.Refresh() end)
ns:On("PLATES_CHANGED", function() Plate.Refresh() end)
ns:On("SETTINGS_CHANGED", function(path)
  if type(path) == "string" and path:find("^plate%.") then Plate.Refresh(nil, true) end
end)
