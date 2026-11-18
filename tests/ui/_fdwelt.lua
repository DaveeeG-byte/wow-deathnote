-- Jagd 2 Gestaltung: kleine Gildenwelt fuer jd*.lua. Zwei Kollegen (Liora, Bertram, erfunden) melden Tode ueber die
-- echte Leitung (K). kills = { { victim, killerVorname, killerNachname, hoursAgo } }
return function(W, kills)
  local AM, P = W.AM, W.ns.Guild.Proto
  AM.Advance(30)
  local function send(text, from) AM.FireEvent("CHAT_MSG_ADDON", "DeathNote", assert(text), "GUILD", from .. "-Forever") end
  for _, n in ipairs({ "Liora", "Bertram" }) do send(P.EncodeHello(time() - 200, "1.6.0"), n); AM.Advance(0.2) end
  for _, k in ipairs(kills) do
    send(P.EncodeKill({ key = W.ns.Util.KeyFor(k[2], k[3]), display = k[2] .. " " .. k[3], class = "ROGUE", level = 60, zone = "Schlingendorntal",
      t = time() - k[4] * 3600, victim = k[1] .. " Testfeld" }, "R"), k[1])
    AM.Advance(0.2)
  end
  W.tick(3)
end
