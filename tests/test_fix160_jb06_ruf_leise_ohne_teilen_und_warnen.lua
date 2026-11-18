-- Fixer 2 1.6.0 (jb06, decision of the orchestrator): a call of the guild comes only as the quiet chat line when
-- "Share with the guild" (guild.share) and "Warn about killers in the shared books" (guild.alert) are both off. One of
-- them alone, or "Receive the guild book" off, keeps the call loud (the switch for the guild's calls is not one of
-- those). Calls of the group and of friends are not touched. Names made up.
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local M = require("mock_wow")
local test, eq = M.test, M.eq

local function loud(set, channel, sender)
  local ns = M.Load({ before = function() M.units.player.guild = "Gilde Eins" end })
  local n, q = 0, 0
  ns:On("HELP_CALL", function(rec) if type(rec) == "table" and rec.quiet then q = q + 1 else n = n + 1 end end)
  _G.C_Map.GetMapInfo = function() return { name = "Schlingendorntal", mapType = 3, parentMapID = 13 } end
  M.Advance(30)
  for k, v in pairs(set) do ns.Store.Setting("guild." .. k, v) end
  M.FireEvent("CHAT_MSG_ADDON", "DeathNoteSOS", ns.Call.Encode({ mapID = 1434, x = 46, y = 38, t = time() }),
    channel or "GUILD", sender or "Liora-Forever")
  M.Advance(1)
  return n, q
end

test("alles an: laut", function() local n, q = loud({}); eq(n, 1); eq(q, 0) end)
test("teilen und warnen aus: nur die leise Zeile", function()
  local n, q = loud({ share = false, alert = false }); eq(n, 0, "laut"); eq(q, 1, "leise")
end)
test("nur teilen aus: laut", function() eq((loud({ share = false })), 1) end)
test("nur warnen aus: laut", function() eq((loud({ alert = false })), 1) end)
test("empfangen aus allein: laut (nicht Teil der Entscheidung)", function() eq((loud({ receive = false })), 1) end)
test("teilen und warnen aus, Ruf der Gruppe: laut", function()
  _G.IsInGroup = function() return true end
  local n = loud({ share = false, alert = false }, "PARTY", "Liora-Forever")
  _G.IsInGroup = nil
  eq(n, 1)
end)
M.done("fix160 jb06 Ruf leise ohne Teilen und Warnen")
