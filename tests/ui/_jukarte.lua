-- Jagd UI 1.5.0: Welt mit Karten-Attrappe (tests/ui/scene_map.lua) fuer ju04 bis ju07
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_ju.lua")
function J.map(WT, opts)
  local W = J.world(WT, "deDE")
  package.loaded.scene_map = nil
  local SM = require("scene_map")
  W.wm = SM.Install(W.BM, opts or {})
  assert(W.ns.SceneMap.Attach(), "Karte nicht angebunden")
  function W.show() W.G.ShowUIPanel(W.wm); W.settle() end
  function W.pins() local o = {}; for _, f in ipairs(W.ns.SceneMap.Shown()) do if f:IsShown() then o[#o + 1] = f end end; return o end
  function W.death(name, x, y, ago)
    local t = time() - (ago or 600)
    local key = W.ns.Store.ApplyKill({ name = name, surname = "Bart", class = "ROGUE", level = 40 },
      { t = t, zone = "Schlingendorntal", mapID = 1434, x = x, y = y, source = "recap" }, true)
    W.ns.Store.RecordDeath({ t = t, zone = "Schlingendorntal", mapID = 1434, x = x, y = y, kind = "pvp", sure = true,
      counted = true, killerKey = key, killerName = name .. " Bart", candidates = {} })
    return key
  end
  return W
end
return J
