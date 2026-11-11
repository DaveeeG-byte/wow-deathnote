-- Gegenprobe (soll gruen sein): Secret-Values an jeder neuen Eingangsstelle werfen keinen Fehler.
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local H = require("beleg_helfer")
local M = H.M

H.lauf("Secrets an den neuen Eingaengen", function()
  local sec = M.Secret
  local friendInfo, bnInfo, byId
  local ns = M.Load({ before = function()
    M.units.player.guild = "Die Testgilde"
    _G.C_FriendList = {
      GetNumFriends = function() return 4 end,
      GetFriendInfoByIndex = function(i) return friendInfo and friendInfo(i) or { name = "Fritz Frei", connected = true } end,
      ShowFriends = function() end,
    }
    _G.BNGetNumFriends = function() return 3 end
    _G.C_BattleNet = {
      GetFriendAccountInfo = function(i) return bnInfo and bnInfo(i) or nil end,
      GetGameAccountInfoByID = function(id) return byId and byId(id) or nil end,
    }
    _G.BNSendGameData = function() end
  end })
  M.Advance(40)
  friendInfo = function(i)
    return ({ { name = sec("name"), connected = true }, { name = "Fritz Frei", connected = sec("bool", "boolean") },
      M.SecretTable(), sec("x") })[i]
  end
  bnInfo = function(i)
    return ({ M.SecretTable(), { gameAccountInfo = M.SecretTable() },
      { gameAccountInfo = { isOnline = sec("b", "boolean"), clientProgram = sec("c"), wowProjectID = sec("n", "number"),
        characterName = sec("n"), gameAccountID = sec("id", "number") } } })[i]
  end
  M.FireEvent("FRIENDLIST_UPDATE"); M.FireEvent("BN_FRIEND_INFO_CHANGED"); M.Advance(5)
  local P = ns.Guild.Proto
  local text = P.EncodeHunt({ key = "Opfer-Lamm", t = time(), by = "Fritz Frei", why = "x" })
  for _, args in ipairs({
    { sec("prefix"), text, "WHISPER", "Fritz-Forever" }, { "DeathNote", sec("text"), "WHISPER", "Fritz-Forever" },
    { "DeathNote", text, sec("channel"), "Fritz-Forever" }, { "DeathNote", text, "WHISPER", sec("sender") },
    { "DeathNote", text, "GUILD", sec("sender") },
  }) do M.FireEvent("CHAT_MSG_ADDON", args[1], args[2], args[3], args[4]) end
  for _, args in ipairs({
    { sec("prefix"), text, "WHISPER", 7 }, { "DeathNote", sec("text"), "WHISPER", 7 }, { "DeathNote", text, "WHISPER", sec("id", "number") },
    { "DeathNote", text, sec("ch"), 7 },
  }) do M.FireEvent("BN_CHAT_MSG_ADDON", args[1], args[2], args[3], args[4]) end
  byId = function() return M.SecretTable() end
  M.FireEvent("BN_CHAT_MSG_ADDON", "DeathNote", text, "WHISPER", 7)
  byId = function() return { characterName = sec("n"), wowProjectID = sec("p", "number") } end
  M.FireEvent("BN_CHAT_MSG_ADDON", "DeathNote", text, "WHISPER", 7)
  ns.Guild.Release("Opfer-Lamm", { to = "all" })
  M.FireEvent("PARTY_KILL", sec("a"), sec("t"))
  M.FireEvent("PARTY_KILL", "Player-93-0000AAAA", sec("t"))
  M.FireEvent("PARTY_KILL", sec("a"), "Player-1-X")
  ns.Guild.FindTarget(sec("text"))
  -- Guild.Release/CallOff mit Secret als key oder why sind hier bewusst nicht dabei: die Aufrufer
  -- (UI.lua GF.DoRelease, Core.lua Slash) pruefen vorher; die Funktionen selbst pruefen es nicht.
  M.Advance(60)
  H.erwartet("keine Fehler mit Secret-Values", #M.errors == 0, M.errors[1])
  H.erwartet("kein Secret in den gespeicherten Daten", not M.ContainsSecret(_G.DeathNoteDB))
  M.errors = {}
end)
H.fertig()
