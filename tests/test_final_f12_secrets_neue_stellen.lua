-- Secret values at the spots that are new since the fixer (counter-check, expected green):
-- guild roster (count, names), friend list, Battle.net, sender, level, inputs of the new functions
-- (HideHunt, Release, CallOff, FindTarget, WhoIs, IsGuildmate, HasAddon, language choice).
-- (fix-2) Proof test of the final hunt, taken into the suite; head: tests/beleg_helfer.lua
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local H = require("beleg_helfer")
local M = H.M
local G = "Die Testgilde"

H.lauf("Roster, Freundesliste und Battle.net liefern Secrets", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", G, { friends = { "Berta Senf" }, bn = { "Berta" } })
  local b = W.client("Berta", "Senf", G, { friends = { "Anton Wurst" } })
  local sStr, sNum, sTab, sBool = M.Secret("name", "string"), M.Secret("zahl", "number"), M.SecretTable(), M.Secret("b", "boolean")
  local mode = 0
  local env = a.env
  local gn, gi, fn, fi, bn, ba, bg = env.GetNumGuildMembers, env.GetGuildRosterInfo, env.C_FriendList.GetNumFriends,
    env.C_FriendList.GetFriendInfoByIndex, env.BNGetNumFriends, env.C_BattleNet.GetFriendAccountInfo, env.C_BattleNet.GetGameAccountInfoByID
  env.GetNumGuildMembers = function() if mode == 1 then return sNum end if mode == 3 then error("x") end return gn() end
  env.GetGuildRosterInfo = function(i) if mode == 1 then return sStr, sStr, sNum end if mode == 2 then return sTab end if mode == 3 then error("x") end return gi(i) end
  env.C_FriendList.GetNumFriends = function() if mode == 1 then return sNum end return fn() end
  env.C_FriendList.GetFriendInfoByIndex = function(i)
    if mode == 1 then return { name = sStr, connected = sBool } end
    if mode == 2 then return sTab end
    return fi(i)
  end
  env.BNGetNumFriends = function() if mode == 1 then return sNum end return bn() end
  env.C_BattleNet.GetFriendAccountInfo = function(i)
    if mode == 1 then return { gameAccountInfo = { isOnline = sBool, clientProgram = sStr, characterName = sStr, gameAccountID = sNum } } end
    if mode == 2 then return { gameAccountInfo = sTab } end
    if mode == 3 then return sTab end
    return ba(i)
  end
  env.C_BattleNet.GetGameAccountInfoByID = function(id) if mode == 1 then return { characterName = sStr, wowProjectID = sNum } end if mode == 2 then return sTab end return bg(id) end
  a.login(); b.login(); W.run(40)
  local P = a.ns.Guild.Proto
  for m = 1, 3 do
    mode = m
    a.fire("GUILD_ROSTER_UPDATE"); a.fire("FRIENDLIST_UPDATE"); a.fire("BN_FRIEND_INFO_CHANGED"); a.fire("PLAYER_GUILD_UPDATE")
    W.run(35)
    H.gilde(a, P.EncodeHunt({ key = "Ziel" .. m .. "x-Lamm", t = time(), by = "Berta Senf", why = "x" }), "Berta-Forever")
    H.gilde(a, P.EncodeHunt({ key = "Zieb" .. m .. "x-Lamm", t = time(), by = "Berta Senf", why = "x" }), sStr)
    H.fluestern(a, P.EncodeHello(0, "1.2.0"), sStr)
    H.fluestern(a, P.EncodeHello(0, "1.2.0"), "Berta Senf-Forever")
    a.fire("BN_CHAT_MSG_ADDON", "DeathNote", P.EncodeHello(0, "1.2.0"), "WHISPER", 101)
    a.fire("BN_CHAT_MSG_ADDON", "DeathNote", P.EncodeHello(0, "1.2.0"), "WHISPER", sNum)
    a.fire("BN_CHAT_MSG_ADDON", sStr, sStr, sStr, sNum)
    local Gd = a.ns.Guild
    Gd.IsGuildmate("Berta Senf"); Gd.HasAddon("Berta"); Gd.WhoIs("Berta", "Senf")
    a.ns.HandleSlash("gilde"); a.ns.HandleSlash("freunde"); a.ns.HandleSlash("sync"); a.ns.HandleSlash("probe")
    W.run(30)
    H.erwartet("Art " .. m .. ": keine Fehler", #M.errors == 0, M.errors[1])
    M.errors = {}
  end
  mode = 0
  local Gd = a.ns.Guild
  local CALLS = {
    { "Guild.HideHunt", function(v) Gd.HideHunt(v, true) end }, { "Guild.HuntHidden", function(v) Gd.HuntHidden(v) end },
    { "Guild.Release (Schluessel)", function(v) Gd.Release(v, { why = v, to = v }) end },
    { "Guild.Release (Grund)", function(v) Gd.Release("Opfer-Lamm", { why = v }) end },
    { "Guild.CallOff", function(v) Gd.CallOff(v) end }, { "Guild.FindTarget", function(v) Gd.FindTarget(v) end },
    { "Guild.Hunt", function(v) Gd.Hunt(v, "all") end }, { "Guild.Released", function(v) Gd.Released(v) end },
    { "Guild.IsGuildmate", function(v) Gd.IsGuildmate(v) end }, { "Guild.HasAddon", function(v) Gd.HasAddon(v) end },
    { "Guild.WhoIs", function(v) Gd.WhoIs(v, v) end }, { "Locale.SetChoice", function(v) a.ns.Locale.SetChoice(v) end },
    { "Friends.FriendOf", function(v) a.ns.Friends.FriendOf(v) end }, { "Friends.OnWhisper", function(v) a.ns.Friends.OnWhisper(v, v) end },
    { "Friends.OnMateHello", function(v) a.ns.Friends.OnMateHello(v) end },
  }
  local bad = {}
  for _, c in ipairs(CALLS) do
    for _, v in ipairs({ sStr, sNum, sTab, sBool }) do
      local ok = pcall(c[2], v)
      if not ok or #M.errors > 0 then bad[c[1]] = true end
      M.errors = {}
    end
  end
  local list = {}
  for k in pairs(bad) do list[#list + 1] = k end
  table.sort(list)
  H.erwartet("neue Funktionen pruefen Eingaben zuerst auf Secret (Regel 5)", #list == 0, "werfen bei Secret: " .. table.concat(list, ", "))
  a.fire("PLAYER_LOGOUT")
  H.erwartet("kein Secret in der Datei", not M.ContainsSecret(a.env.DeathNoteDB))
end)

H.fertig()
