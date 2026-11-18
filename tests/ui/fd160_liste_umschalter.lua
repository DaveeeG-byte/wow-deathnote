-- Design fixer 1.6.0 (design hunt 16): with the word switch Players | Guilds at the bottom left of Wanted, a full list
-- ends one row earlier, so the switch stands free below the last row; the mouse wheel still reaches the last entry.
-- Without the switch the list keeps all its rows. Names made up.
local WT = arg[1] or "."
local X = dofile((arg[0]:match("^(.*)/") or ".") .. "/_fe160.lua")
local J = X.J
local NAMES = { "Aldric", "Berengar", "Cyprian", "Doran", "Edric", "Falk", "Gerold", "Hartwig", "Ingram", "Jorund", "Kasimir" }
for _, code in ipairs({ "deDE", "enUS" }) do
  local W = X.world(WT, code)
  W.BM.measure = true   -- positions of rows and switch
  local ns, L = W.ns, W.L
  for i, n in ipairs(NAMES) do W.kill(n, "Testfeld", i == 1 and "Die Schlaechter von Sturmwind" or nil, time() - 9000 + i * 60) end
  W.open()
  local _, LP = W.frames()
  local sw = LP.fdWanted
  J.check(code .. ": Umschalter da", sw and sw:IsVisible())
  local rows = W.rows()
  local lowest
  for _, r in ipairs(rows) do if not lowest or r:GetBottom() < lowest:GetBottom() then lowest = r end end
  J.check(code .. ": volle Liste endet eine Zeile frueher", #rows == 8, #rows)
  local gap = lowest and sw and (lowest:GetBottom() - sw:GetTop())
  J.check(code .. ": Umschalter steht frei unter der letzten Zeile", gap and gap >= 8, gap)
  -- the wheel reaches the last entry
  local LR = rows[1] and rows[1]:GetParent()
  for _ = 1, 10 do LR._scripts.OnMouseWheel(LR, -1) end
  W.tick()
  local data = W.kit().Data()
  local lastShown = false
  for _, r in ipairs(W.rows()) do if r.item == data[#data] then lastShown = true end end
  J.check(code .. ": Mausrad erreicht den letzten Eintrag", lastShown, #data)
  local ok, err = W.errors()
  J.check(code .. ": keine Fehler", ok, err)
end
J.done()
