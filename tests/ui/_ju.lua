-- Jagd UI 1.5.0: gemeinsame Welt der Belegtests ju*.lua (UI-Mock mit allen Dateien des Worktrees).
-- Aufruf je Test: cd <worktree> && luajit <pfad>/juNN_x.lua [<worktree>]   Exit 1 = Fund belegt.
local J = {}
function J.world(WT, code, settings)
  package.path = WT .. "/tests/ui/?.lua;" .. WT .. "/tests/?.lua;" .. package.path
  package.loaded.mock_wow, package.loaded.mock = nil, nil
  local AM = require("mock_wow")
  local BM = require("mock")
  local ADDON = WT .. "/DeathNote"
  BM.mediaDir = ADDON .. "/Media"
  BM.measure = true
  AM.locale = code or "deDE"
  local files = {}
  for _, f in ipairs(AM.Files()) do files[#files + 1] = f end
  for _, f in ipairs({ "Share.lua" }) do
    local have = false
    for _, g in ipairs(files) do if g == f then have = true end end
    if not have then files[#files + 1] = f end
  end
  local ns = AM.Load({ noLogin = true, files = files, db = settings and { settings = settings } or nil })
  for _, f in ipairs({ "Alert.lua", "UI.lua", "Extras.lua", "ShareUI.lua", "SceneMap.lua" }) do BM.Load(ADDON .. "/" .. f, ns) end
  AM.FireEvent("PLAYER_LOGIN")
  AM.FireEvent("PLAYER_ENTERING_WORLD")
  local W = { AM = AM, BM = BM, G = BM.G, ns = ns }
  function W.tick(s) AM.Advance(s or 0.1); BM.Advance(s or 0.1) end
  function W.settle() BM.Advance(13); BM.FinishAnims(); BM.Advance(1); BM.FinishAnims(); BM.Advance(1) end
  return W
end
J.pass, J.fail = 0, 0
function J.check(name, cond, detail)
  if cond then J.pass = J.pass + 1; print("ok    " .. name)
  else J.fail = J.fail + 1; print("ROT   " .. name .. (detail ~= nil and ("  -> " .. tostring(detail)) or "")) end
end
function J.done() print(("%d ok, %d rot"):format(J.pass, J.fail)); os.exit(J.fail > 0 and 1 or 0) end
return J
