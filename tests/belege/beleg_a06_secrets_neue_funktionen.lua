-- Gegenprobe Fund 20 (Secret-Regel): die seit der vorigen Jagd neuen oeffentlichen Funktionen.
-- Regel 5: erst issecretvalue pruefen, dann vergleichen oder rechnen. Kein heutiger Aufrufer reicht ein Secret
-- hinein (Werte aus der eigenen Datei bzw. nach Util.Str); die Regel ist in der Funktion selbst nicht erfuellt.
local H = dofile((arg[0]:match("^(.*)/") or ".") .. "/_kopf.lua")
local M = H.M
H.lauf("neue Funktionen mit Secret als Eingabe", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", "Die Testgilde", { friends = { "Berta" } })
  a.login(); W.run(40)
  local P, F, G = a.ns.Guild.Proto, a.ns.Friends, a.ns.Guild
  -- ein offener Konflikt, damit die Stumm-Liste nicht leer ist
  H.fluestern(a, H.J(P, "Falsch-Lamm", "Berta Fremd"), "Berta Fremd-Forever")
  H.fluestern(a, H.J(P, "Echt-Lamm", "Berta Senf"), "Berta Senf-Forever")
  local S = M.Secret("s", "string")
  local function probe(name, fn, ...)
    local ok, err = pcall(fn, ...)
    H.erwartet(name .. " wirft nicht bei einem Secret", ok, tostring(err):sub(1, 70))
  end
  probe("Friends.Muted", F.Muted, S)
  probe("Guild.Unmuted", G.Unmuted, { deeds = { { victim = S } } }, nil)
  probe("P.ValidGUID", P.ValidGUID, S)
  probe("P.EncodeHello (guid)", P.EncodeHello, 0, "1.2.0", S)
  probe("P.EncodeSnapshot", P.EncodeSnapshot, S, 1)
  -- Gegenproben (gruen)
  for name, fn in pairs({ Choose = function() return F.Choose("Berta", S) end, Loosen = function() return F.Loosen(S) end,
    Unbind = function() return F.Unbind(S) end, IsOwnChar = function() return G.IsOwnChar(S) end,
    Rank = function() return G.Rank(S, "all") end, HuntHidden = function() return G.HuntHidden(S) end,
    Release = function() return G.Release(S) end, CallOff = function() return G.CallOff(S) end,
    HelloText = function() a.env.UnitGUID = function() return S end; return F.HelloText(F.FriendOf("Berta")) end }) do
    probe("Gegenprobe " .. name, fn)
  end
  a.env.C_FriendList.GetFriendInfoByIndex = function() return { name = "Berta", connected = true, guid = S } end
  a.fire("FRIENDLIST_UPDATE"); W.run(5)
  H.erwartet("Gegenprobe: GUID der Freundesliste als Secret: kein Fehler, gilt als keine GUID", F.FriendOf("Berta") and F.FriendOf("Berta").guid == nil)
  H.erwartet("Gegenprobe: kein Secret in der Datei", not M.ContainsSecret(a.env.DeathNoteDB))
end)
H.fertig()
