-- Fixer 1.7.0 round 2: copy of the hunt test jn06.
-- jn06 (Nachjagd 1.7.0, Fixer-Diff Extras.lua JU-13): der verdraengte Zettel geht mit table.insert VORN in die
-- Warteschlange der Gildenmeldungen, ohne deren Deckel (GUILD_QUEUE_MAX = 3) zu achten, belegt dort aber einen der
-- drei Plaetze. Kommen danach, solange die verdraengende Meldung steht, drei Gildenmeldungen (drei Kollegen fallen im
-- selben Gefecht), wartet in 1.6.4 jede; jetzt faellt die dritte weg (Later: #guildQueue < GUILD_QUEUE_MAX).
-- "Das Verhalten der anderen Meldungen bleibt wie in 1.6.4" haelt hier nicht.
-- Erwartet: alle drei Gildenmeldungen kommen (wie ohne den Zettel). Alle Namen sind erfunden.
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_fx170.lua")
local check = J.check
local X = J.cu()

local function lauf(mitZettel)
  local W = X.world("deDE")
  X.fake(W)
  local ns = W.ns
  local function banner() return W.frameWith(function(f) return f.kicker and f.stamp and f.line and f.name and f.inAnim end) end
  local key = W.kill("Grimm", "Bart")
  W.tick(1); W.settle()
  if mitZettel then
    W.earn({ key = "Kalt-Herz", name = "Kalt Herz", owner = "Anna Wurst", char = "Ich Selbst", t = _G.time(), g = 50,
      via = "guild", state = "sent" })
    W.tick(1.2)
  end
  W.tick(0.5)
  ns.Store.AddRevenge(key)          -- verdraengt den Zettel (stand unter 2 s)
  W.tick(0.2)
  for i, v in ipairs({ "Egon Wurst", "Carla Wurst", "Dirk Wurst" }) do
    ns:Fire("GUILD_KILL", { victim = v, zone = "Z", t = _G.time() }, "Feind-Nummer" .. i, "guild")
  end
  local seen = {}
  for i = 1, 900 do
    W.tick(0.1)
    if i % 20 == 0 then W.BM.FinishAnims() end
    local B = banner()
    if B and B:IsShown() then seen[tostring(B.name._text)] = true end
  end
  local n = 0
  for _, v in ipairs({ "Egon", "Carla", "Dirk" }) do if seen[v] then n = n + 1 end end
  return n, seen
end

local ohne = lauf(false)
local mit = lauf(true)
check("Vorbedingung: ohne Zettel kommen alle drei Gildenmeldungen (wie 1.6.4)", ohne == 3, ohne)
check("mit verdraengtem Zettel kommen ebenfalls alle drei", mit == 3, mit .. " von 3")
J.done()
