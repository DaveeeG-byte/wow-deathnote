-- ju06: Absender eines Hilferufs. Nach dem Ruf (Taste oder Knopf, also fast immer mitten im Kampf) haengt an der
-- Chatzeile der Link "Im Gildenchat rufen". Ein Klick darauf geht ueber Share.Send, das im Kampf nie sendet: der
-- Spieler bekommt "Nicht im Gildenchat gesendet: ...". Der Link wird genau dann angeboten, wenn er nicht geht.
-- Erwartet: Link im Kampf nicht zeigen (oder als "nach dem Kampf" anbieten), oder die Zeile sagt, dass er erst nach
-- dem Kampf geht. Namen erfunden.
local WT = arg[1] or "."
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_ju160.lua")
local W = J.world(WT, "deDE", { guild = "Die Rostigen Naegel" })
local ns = W.ns
local printed = {}
local Util = ns.Util
local oldPrint = Util.Print
Util.Print = function(s, ...) printed[#printed + 1] = tostring(s); return oldPrint(s, ...) end
_G.InCombatLockdown = function() return true end
rawset(W.G, "InCombatLockdown", _G.InCombatLockdown)
_G.UnitAffectingCombat = function() return true end
local ok, got = ns.Call.Trigger()
J.check("Hilferuf im Kampf geht hinaus (Voraussetzung)", ok, tostring(got))
local line = printed[#printed] or ""
local offered = line:find(ns.L.CALL_GCHAT_LINK, 1, true) ~= nil
local sent, why = ns.Call.GuildChat()
J.check("Link \"" .. ns.L.CALL_GCHAT_LINK .. "\" wird im Kampf nur angeboten, wenn er dann auch sendet",
  not offered or sent, "angeboten=" .. tostring(offered) .. ", Klick: " .. tostring(sent) .. " " .. tostring(why) .. " | " .. line)
J.done()
