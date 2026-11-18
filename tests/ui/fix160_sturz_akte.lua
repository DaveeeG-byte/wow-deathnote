-- Fixer 1.6.0 (jl04, jl05): a player hurt me, the world (a fall) or a totem dealt the killing blow. The death stays in
-- the feud book (journal row, the player as candidate), the world is only a note in the file, no row among the
-- causes; the totem never becomes a creature of the death log. deDE and enUS, names made up.
local WT = arg[1] or "."
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_ju160.lua")
local function ev(o)
  return { sourceGUID = o.guid, sourceName = o.name, amount = o.amount or 100, overkill = o.overkill or 0,
    timestamp = time() - 1, spellName = o.spell, hideCaster = false, event = o.event or "SPELL_DAMAGE",
    environmentalType = o.env }
end
for _, code in ipairs({ "deDE", "enUS" }) do
  local W = J.world(WT, code)
  local ns, L = W.ns, W.ns.L
  W.AM.recap = { id = 4711, events = {
    ev({ guid = "Player-93-0000BEEF", name = "Grimm Bart", amount = 900, spell = "Donnerknall" }),
    ev({ event = "ENVIRONMENTAL_DAMAGE", env = "Falling", amount = 150, overkill = 40 }),
  } }
  W.AM.FireEvent("PLAYER_DEAD")
  W.tick(6)
  local j = ns.Store.Journal()
  J.check(code .. ": Sturz nach Spielerschaden: eine Journalzeile, unklar", #j == 1 and j[1].kind == "unknown", #j)
  J.check(code .. ": Grimm Bart Kandidat", j[1] and #(j[1].candidates or {}) == 1)
  J.check(code .. ": keine Zeile unter Ursachen", #ns.Fates.Rows() == 0, #ns.Fates.Rows())
  W.open()
  ns.UI.ShowCase(j[1]); W.settle()
  local note = ns.F(L.FATE_NOTE_ENV, { name = L.FATE_ENV_FALL })
  J.check(code .. ": Akte nennt die Umwelt als Zusatz", W.visible(note) ~= nil, note)
  -- the totem: the shaman's fresh damage makes an open case with him as candidate (fixer 2, jb01: never wanted), no creature
  W.AM.Advance(120)
  W.AM.recap = { id = 4712, events = {
    ev({ guid = "Player-93-0000BEEF", name = "Grimm Bart", amount = 900, spell = "Blitzschlag" }),
    ev({ guid = "Creature-0-3110-0-49-2523-0000AB0001", name = "Totem der Verbrennung", amount = 60, overkill = 20,
      spell = "Verbrennen" }),
  } }
  W.AM.FireEvent("PLAYER_DEAD")
  W.tick(6)
  j = ns.Store.Journal()
  J.check(code .. ": Totem: offener Fall mit dem Schamanen als Kandidat, kein Taeter",
    #j == 2 and j[1].kind == "pvp" and j[1].sure == false and j[1].killerKey == nil and ns.Store.IsOpenCase(j[1])
    and (j[1].candidates or {})[1] == "Grimm-Bart", #j .. " " .. tostring(j[1] and j[1].kind))
  J.check(code .. ": Totem: der Schamane steht nicht im Buch", ns.Store.Get("Grimm-Bart") == nil)
  J.check(code .. ": Totem: keine Kreatur unter Ursachen", #ns.Fates.Rows() == 0, #ns.Fates.Rows())
end
J.done()
