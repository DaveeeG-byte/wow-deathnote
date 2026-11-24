-- Schlussjagd 1.6.4, Jaeger B: gemeinsamer Kopf der Belegtests jb*.lua.
-- Aufruf je Test: luajit <test>.lua <projektpfad>   (aus beliebigem Ordner; Rueckgabe 1 = rot)
-- Nimmt die Testwelt des Bauers (tests/ui/_mv164.lua) aus dem Projektpfad; nichts wird dort geschrieben.
local WT = arg and arg[1] or "."
local J = dofile(WT .. "/tests/ui/_mv164.lua")
J.WT = WT
local world = J.world
-- mock_wow laedt ohne opt.dir aus "./DeathNote": darum immer den Ordner des Projektpfads nennen
function J.world(code, opt)
  opt = opt or {}
  if not opt.dir then opt.dir = WT .. "/DeathNote/" end
  return world(code, opt)
end
function J.db(extra)
  local s = { welcomed = true, firstRun = "done", news164 = true, news160 = true, news150 = true, news140 = true, lang = "deDE" }
  for k, v in pairs(extra or {}) do s[k] = v end
  return { version = 5, settings = s, enemies = {}, deaths = {} }
end
return J
