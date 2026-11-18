-- Fixer 1.6.0 (jl03): a help call received in a dungeon, raid or battleground gives only the quiet chat line: no
-- sound, no slip; the call still lands in the ring (the map's pin). In the open world it stays loud. Names made up.
local WT = arg[1] or "."
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_ju160.lua")
for _, kind in ipairs({ "party", "raid", "pvp", "none" }) do
  local W = J.world(WT, "deDE", { guild = "Die Rostigen Naegel" })
  local ns = W.ns
  _G.C_Map.GetMapInfo = function() return { name = "Schlingendorntal", mapType = 3, parentMapID = 13 } end
  W.AM.instance = { kind ~= "none", kind }
  local before = #W.BM.sounds
  local text = ns.Call.Encode({ mapID = 1434, x = 46, y = 38, t = time(), display = "Grimwald Ashbrand" })
  W.AM.FireEvent("CHAT_MSG_ADDON", "DeathNoteSOS", text, "GUILD", "Liora-Forever")
  W.tick(1)
  local slip = rawget(W.G, "DeathNoteCall")
  local shown = slip and slip:IsShown() or false
  local sounds = #W.BM.sounds - before
  local calls = ns.Call.Calls()
  J.check(kind .. ": der Ruf steht im Ring (Nadel)", #calls == 1, #calls)
  if kind == "none" then
    J.check("offene Welt: Zettel und Ton", shown and sounds > 0, tostring(shown) .. " / " .. sounds)
  else
    J.check(kind .. ": kein Zettel", not shown, tostring(shown))
    J.check(kind .. ": kein Ton", sounds == 0, sounds)
  end
  W.AM.instance = { false, "none" }
end
J.done()
