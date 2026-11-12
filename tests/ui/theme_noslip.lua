-- Test theme "noslip" (only in the tests): the harbor cover without its own tint of the notice slip, so the slip takes
-- the tint of the paper (Extras.lua). Loaded like an addon file after Themes/harbor.lua (tests/ui/theme_fallback.lua).
local _, ns = ...
local T = ns.Theme
local base = T.Get("harbor")
local d = {}
for k, v in pairs(base) do d[k] = v end
d.tint = {}
for k, v in pairs(base.tint or {}) do if k ~= "slip" then d.tint[k] = v end end
d.order = 90
T.Register("noslip", d)
