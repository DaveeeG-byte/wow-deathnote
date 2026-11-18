-- ju08: Ein Buendel zeigt das Bild der wichtigsten Art (mein Tod vor Gilde), der Klick oeffnet aber den neuesten
-- Eintrag (items[1]). Rote Todesnadel mit "2", Klick schlaegt Gilde & Freunde auf statt meines Todes; der Tooltip
-- sagt nur "Klick: das Buch dort aufschlagen". Erwartet: Klick folgt dem Bild (lead) oder der Tooltip nennt das Ziel.
-- Namen erfunden.
local WT = arg[1] or "."
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_ju.lua")
local W = J.world(WT, "deDE")
local ns = W.ns
local Sc = ns.Scene
local now = time()
local t = now - 3600
local key = ns.Store.ApplyKill({ name = "Grimm", surname = "Bart", class = "ROGUE", level = 40 },
  { t = t, zone = "Schlingendorntal", mapID = 1434, x = 40, y = 40, source = "recap" }, true)
ns.Store.RecordDeath({ t = t, zone = "Schlingendorntal", mapID = 1434, x = 40, y = 40, kind = "pvp", sure = true,
  counted = true, killerKey = key, killerName = "Grimm Bart", candidates = {} })
-- a guildmate's death next to it, newer (as the guild book holds it)
local Gd = ns.Guild
local orig = Gd.List
Gd.List = function(what, opts)
  if opts and opts.source == "guild" then
    return { { key = "Velka-Dorn", display = "Velka Dorn", class = "WARLOCK",
      deeds = { { t = now - 600, victim = "Liora Stormwell", zone = "Schlingendorntal", mapID = 1434, x = 40.5, y = 40.2 } } } }
  end
  return {}
end
local pins = Sc.Pins(1434, now)
Gd.List = orig
J.check("ein Buendel", #pins == 1 and pins[1].count == 2, #pins)
local p = pins[1]
local opened
ns.UI.ShowCase = function() opened = "death" end
ns.UI.ShowGuildEnemy = function() opened = "guild" end
ns.SceneMap.OpenBook(p.items[1])   -- what pinClick does
J.check("Bild der Nadel: " .. tostring(p.kind) .. ", Klick oeffnet dasselbe", opened == p.kind, "Klick oeffnet " .. tostring(opened))
J.done()
