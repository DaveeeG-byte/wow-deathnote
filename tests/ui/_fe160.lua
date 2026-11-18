-- 1.6.0 feud: shared world of the UI tests fe160_*.lua (UI mock with every file of the worktree, FeudUI.lua included).
-- Usage per test: luajit tests/ui/fe160_x.lua [<worktree>]. Names made up.
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_ju.lua")
local X = { J = J }

function X.world(WT, code, db, before)
  package.path = WT .. "/tests/ui/?.lua;" .. WT .. "/tests/?.lua;" .. package.path
  package.loaded.mock_wow, package.loaded.mock = nil, nil
  local AM = require("mock_wow")
  local BM = require("mock")
  local ADDON = WT .. "/DeathNote"
  BM.mediaDir = ADDON .. "/Media"
  AM.locale = code or "deDE"
  local ns = AM.Load({ noLogin = true, db = db, before = before })
  for _, f in ipairs({ "Alert.lua", "UI.lua", "Extras.lua", "FeudUI.lua" }) do
    if io.open(ADDON .. "/" .. f) then BM.Load(ADDON .. "/" .. f, ns) end
  end
  AM.FireEvent("PLAYER_LOGIN")
  AM.FireEvent("PLAYER_ENTERING_WORLD")
  local W = { AM = AM, BM = BM, G = BM.G, ns = ns, L = ns.L }
  function W.tick(s) AM.Advance(s or 0.1); BM.Advance(s or 0.1) end
  function W.settle() BM.Advance(13); BM.FinishAnims(); BM.Advance(1); BM.FinishAnims(); BM.Advance(1) end
  function W.open() ns:Fire("TOGGLE_UI"); W.tick(); W.settle() end
  function W.kit() return ns.UI.Kit end
  function W.frames() return W.kit().Frames() end
  -- a visible frame with this text (a button or its text string)
  function W.find(text, kind)
    for _, f in ipairs(BM.frames) do
      if f.IsVisible and f:IsVisible() and (not kind or f._kind == kind) then
        if f._text == text then return f end
        if f.text and f.text._text == text and f.text:IsVisible() then return f end
      end
    end
  end
  function W.click(b, mouse)
    if b and b._scripts.OnClick then b._scripts.OnClick(b, mouse or "LeftButton") end
    W.tick()
  end
  function W.tab(id)
    for _, f in ipairs(BM.frames) do
      if f.id == id and f._scripts.OnClick then f._scripts.OnClick(f) end
    end
    W.tick()
  end
  function W.rows()
    local out = {}
    for _, f in ipairs(BM.frames) do
      if f._kind == "Button" and f.item ~= nil and f.rank and f.sub and f:IsVisible() then out[#out + 1] = f end
    end
    return out
  end
  function W.kill(name, surname, guild, t)
    return ns.Store.ApplyKill({ name = name, surname = surname, guid = "Player-93-" .. name, guild = guild, class = "ROGUE",
      level = 40 }, { t = t or time() - 600, zone = "Schlingendorntal", source = "recap" }, true)
  end
  function W.errors()
    return #AM.errors == 0 and #BM.violations == 0, AM.errors[1] or BM.violations[1]
  end
  return W
end

return X
