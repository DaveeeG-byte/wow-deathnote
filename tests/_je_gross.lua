-- Jagd 2 Effizienz: das grosse Buch der Messlaeufe und Belegtests (erfundene Namen).
-- 3.000 Eintraege (je 2 Taten mit Ort), 5 volle Gildenlisten (400 Feinde x 20 Taten), volles Freundesbuch, 50 Fehden,
-- 50 Ansprueche, 200 Abgelegte; dazu ueber die echten Wege: 200 Journal-Tode, 300 Todeszeilen ueber 150 Kreaturen,
-- 500 Buch-Besitzer (Hallo). X.build(J, DIR) gibt die Tabelle zurueck, wie sie nach dem Ausloggen in der Datei stuende.
local X = {}
local T0 = 1700000000 + 1000
X.GUILD = "Gilde Nr 1"

function X.raw(n)
  n = n or 3000
  local enemies = {}
  for i = 1, n do
    local kill = i % 3 == 0
    local g = "Feindgilde " .. (i % 50)
    local e = { kills = kill and 1 or 0, suspected = kill and 0 or 1, status = kill and "wanted" or "suspect", deaths = {},
      guild = g, class = "ROGUE", level = 40, day = 3, name = "Feind" .. i, surname = "Ling" }
    for d = 1, 2 do
      e.deaths[d] = { t = T0 - i * 60 - d, zone = "Schlingendorntal", role = kill and d == 1 and "kill" or "suspect",
        sure = kill and d == 1, source = "recap", guild = g, mapID = 1434, x = (i * 7 + d) % 100, y = (i * 13 + d) % 100 }
    end
    enemies[("Feind%d-Ling"):format(i)] = e
  end
  local function list(prefix)
    local en = {}
    for i = 1, 400 do
      local deeds = {}
      for d = 1, 20 do deeds[d] = { t = T0 - i * 100 - d, victim = "Kollege Nr" .. (d % 5), by = "Kollege Nr" .. (d % 5), zone = "Z" } end
      en[("%s%d-Ling"):format(prefix, i)] = { deeds = deeds }
    end
    return { enemies = en, members = {}, used = T0 }
  end
  local lists = {}
  for g = 1, 5 do lists["Gilde Nr " .. g] = list("G" .. g .. "x") end
  local fen = list("F").enemies
  for i = 1, 100 do fen[("G1x%d-Ling"):format(i)] = lists["Gilde Nr 1"].enemies[("G1x%d-Ling"):format(i)] end
  local feuds, claims, expired = {}, {}, {}
  for i = 0, 49 do feuds["Feindgilde " .. i] = { t = T0 - i * 3600, by = "Varorak Narenmar" } end
  for i = 1, 50 do
    claims[i] = { key = "Feind" .. (i * 3) .. "-Ling", name = "Feind" .. (i * 3) .. " Ling", by = "Kollege Nr" .. (i % 5), t = T0 - i * 600,
      g = 10 + i, char = "Varorak Narenmar", state = "open" }
  end
  for i = 1, 200 do
    expired[("Alt%d-Ling"):format(i)] = { kills = 0, suspected = 1, status = "suspect", class = "MAGE", level = 30, day = 0,
      expiredAt = T0 - i * 86400, deaths = { { t = T0 - 40 * 86400 - i, zone = "Brachland", role = "suspect", source = "recap" } } }
  end
  return { enemies = enemies, guild = { name = X.GUILD, lists = lists }, friends = { enemies = fen, days = 3, dayAt = 0 },
    days = 3, dayAt = T0, feuds = feuds, claims = claims, expired = expired }
end

-- fuellt ueber die echten Wege nach und gibt die Tabelle nach PLAYER_LOGOUT zurueck
function X.build(J, DIR, n)
  local W = J.world(DIR, { db = X.raw(n), guild = X.GUILD, noUI = true, countApi = false })
  local ns, AM = W.ns, W.AM
  for i = 1, 200 do
    local key = ("Feind%d-Ling"):format(i * 3)
    local j = { t = _G.time() - i * 5000, zone = "Schlingendorntal", subzone = "Grom'gol", mapID = 1434, x = (i * 3) % 100, y = (i * 5) % 100,
      me = "Varorak Narenmar", myLevel = 40, kind = "pvp", sure = true, counted = true, killerKey = key, source = "recap", candidates = {} }
    ns.Store.RecordDeath(j)
  end
  for i = 1, 300 do
    local c = i % 150
    local j = { t = _G.time() - i * 4000, kind = "pve", zone = "Wald von Elwynn", subzone = "Jaspismine", mapID = 1429, x = i % 100, y = (i * 3) % 100,
      me = "Varorak Narenmar", myLevel = 6, counted = true, candidates = {}, cause = { art = "creature", name = "Kobold Nr " .. c, npc = 1000 + c } }
    ns.Store.RecordDeath(j)
    ns:Fire("DEATH_RECORDED", j, nil)
  end
  local P = ns.Guild.Proto
  for i = 1, 500 do
    AM.FireEvent("CHAT_MSG_ADDON", "DeathNote", P.EncodeHello(_G.time() - 60, "1.6.0"), "GUILD", ("Halter%d Wurst-Forever"):format(i))
    if i % 20 == 0 then AM.Advance(1) end
  end
  AM.Advance(600)
  AM.FireEvent("PLAYER_LOGOUT")
  X.errors = #AM.errors
  return _G.DeathNoteDB
end

-- grobe Groesse der SavedVariables-Datei: so wie der Client schreibt (ein Feld je Zeile, Tabulator je Ebene)
function X.size(t)
  local n = 0
  local function w(v, depth)
    local tv = type(v)
    if tv == "table" then
      n = n + 2
      local i = 0
      for k, x in pairs(v) do
        i = i + 1
        n = n + depth + 1
        if type(k) == "string" then n = n + #k + 7 else n = n + 0 end      -- ["key"] = 
        w(x, depth + 1)
        if type(k) ~= "string" then n = n + #tostring(k) + 8 end            -- , -- [i]
        n = n + 2
      end
      n = n + depth + 1
    elseif tv == "string" then n = n + #v + 2
    else n = n + #tostring(v) end
  end
  w(t, 0)
  return n
end
return X
