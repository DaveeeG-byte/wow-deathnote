-- 1.2.1: "Avenged for you" (V). Usage: luajit beleg_b03_geraecht.lua <project copy>
-- A player with DeathNote kills with his own killing blow (PARTY_KILL) a killer who stands in the guild or friends' book
-- against OTHERS. Checked: who gets the message, who gets the line with sound (only those whom the killer harmed in their
-- own book), counters, exactly one message for a hit list target, 1.2.0/1.1.0 count nothing twice,
-- protection rules as for E. All names are made up.
local H = dofile((arg[0]:match("^(.*)/") or ".") .. "/_kopf.lua")
local M = H.M
local G = "Die Testgilde"
local OLD = H.DIR .. "/tests/fixtures/addon-1.1.0/"
local OLDFILES = { "Core.lua", "Store.lua", "Tracker.lua", "Attribution.lua", "Probe.lua", "Sync.lua" }
local V120 = H.DIR .. "/tests/fixtures/addon-1.2.0/"
local FILES120 = { "Locale.lua", "Locales/enUS.lua", "Locales/deDE.lua", "Core.lua", "Store.lua", "Tracker.lua",
  "Attribution.lua", "Probe.lua", "Sync.lua", "Friends.lua" }
local GUID = "Player-1-7461657465"

local function welt(watch)
  local W = H.welt(watch or { "GUILD_KILL", "GUILD_UPDATED", "HUNT_BAGGED", "AVENGED" })
  -- the killer as a unit (GetPlayerInfoByGUID returns his name)
  M.AddEnemy("nameplate9", { name = "Taeter", surname = "Lamm", guid = GUID })
  return W
end
local function toetet(c)
  c.fire("PARTY_KILL", c.env.UnitGUID("player"), GUID)
end
local function vs(W, von)
  local n = 0
  for _, m in ipairs(W.sent) do if (not von or m.sender == von) and m.text:find("^1\tV\t") then n = n + 1 end end
  return n
end

H.lauf("(1) Gilde: Nachricht an die Gilde, Zeile und Ton nur fuer das Opfer, Zaehler bei allen", function()
  local W = welt()
  local a = W.client("Anton", "Wurst", G, { fullSender = true })
  local b = W.client("Berta", "Senf", G, { fullSender = true })
  local c = W.client("Carla", "Klee", G, { fullSender = true })
  a.login(); b.login(); c.login(); W.run(90)
  local key = H.tod(b, "Taeter", "Lamm"); W.run(10)          -- Berta: in the own book and in the others' guild book
  H.erwartet("Vorbedingung: Taeter im Gildenbuch von Anton", a.ns.Guild.Get(key, "guild") ~= nil)
  toetet(a); W.run(10)
  H.erwartet("ein V auf GUILD", vs(W, a) == 1, vs(W, a))
  H.erwartet("Berta: eine Meldung fuer sie (nach kurzer Wartezeit)", H.zaehle(b, "AVENGED") == 1, H.zaehle(b, "AVENGED"))
  H.erwartet("Carla: keine Meldung", H.zaehle(c, "AVENGED") == 0)
  local rb, nb = b.ns.Guild.Avenged(key)
  local rc, nc = c.ns.Guild.Avenged(key)
  local ra, na = a.ns.Guild.Avenged(key)
  H.erwartet("Zaehler: bei Berta, Carla und Anton je 1 von Anton", nb == 1 and nc == 1 and na == 1 and rb[1].char == "Anton Wurst")
  H.erwartet("der Stempel RACHE GENOMMEN bleibt der eigenen Rache vorbehalten", (b.ns.Store.Get(key).revenge or 0) == 0)
  -- the same kill reported again (echo, second channel): counts once
  local P = b.ns.Guild.Proto
  local t = time()
  for _ = 1, 3 do H.gilde(b, P.EncodeAvenged(key, "Anton Wurst", t - 9, false), "Anton Wurst-Forever") end
  local _, nb2 = b.ns.Guild.Avenged(key)
  H.erwartet("dieselbe Toetung zaehlt einmal", nb2 == 1, nb2)
  -- a second avenger: second message, two names (line and sound are shown by beleg_ui_7)
  H.gilde(b, P.EncodeAvenged(key, "Carla Klee", time(), false), "Carla Klee-Forever"); W.run(5)
  H.erwartet("zweite Meldung, zwei Raecher", H.zaehle(b, "AVENGED") == 2 and #b.ns.Guild.Avenged(key) == 2)
end)

H.lauf("(2) keine Nachricht fuer Gegner, die niemanden aus Gilde und Freunden getoetet haben; Instanz", function()
  local W = welt()
  local a = W.client("Anton", "Wurst", G, { fullSender = true })
  local b = W.client("Berta", "Senf", G, { fullSender = true })
  a.login(); b.login(); W.run(90)
  local key = H.tod(a, "Taeter", "Lamm"); W.run(10)          -- only Anton himself was killed
  toetet(a); W.run(10)
  H.erwartet("eigener Taeter, sonst niemand: kein V", vs(W) == 0)
  H.erwartet("... und kein Zaehler", select(2, a.ns.Guild.Avenged(key)) == 0)
  -- unknown player
  M.AddEnemy("nameplate8", { name = "Fremd", surname = "Ling", guid = "Player-1-46524D44" })
  a.fire("PARTY_KILL", a.env.UnitGUID("player"), "Player-1-46524D44"); W.run(5)
  H.erwartet("Unbekannter: kein V", vs(W) == 0)
  -- instance: no V (as for taken down)
  H.tod(b, "Taeter", "Lamm"); W.run(10)
  M.instance = { true, "party" }
  toetet(a); W.run(5)
  H.erwartet("in der Instanz: kein V", vs(W) == 0)
  M.instance = { false, "none" }
  -- a monster
  a.fire("PARTY_KILL", a.env.UnitGUID("player"), "Creature-0-1-2-3-4-5"); W.run(5)
  H.erwartet("ein Monster: kein V, kein Fehler", vs(W) == 0 and #M.errors == 0, M.errors[1])
end)

H.lauf("(3) Ziel auch auf der Abschussliste: genau eine Meldung (erlegt), beide Zaehler; 1.2.0 zaehlt nicht doppelt", function()
  local W = welt()
  local a = W.client("Anton", "Wurst", G, { fullSender = true })
  local b = W.client("Berta", "Senf", G, { fullSender = true })
  local n = W.client("Otto", "Neu", G, { dir = V120, files = FILES120, fullSender = true, version = "1.2.0" })
  local o = W.client("Olaf", "Alt", G, { dir = OLD, files = OLDFILES, lang = false, fullSender = true })
  for _, c in ipairs({ a, b, n, o }) do c.login() end
  W.run(90)
  local key = H.tod(b, "Taeter", "Lamm"); W.run(10)
  b.ns.Guild.Release(key, { to = "guild", why = "Grund" }); W.run(10)
  local vorO = H.tiefe_kopie(o.env.DeathNoteDB.guild.lists[G].enemies)
  toetet(a); W.run(10)
  H.erwartet("E und V gingen hinaus", vs(W, a) == 1)
  H.erwartet("Berta: genau eine Meldung, die Erlegt-Meldung", H.zaehle(b, "HUNT_BAGGED") == 1 and H.zaehle(b, "AVENGED") == 0,
    H.zaehle(b, "HUNT_BAGGED") .. "/" .. H.zaehle(b, "AVENGED"))
  local hb = b.ns.Guild.Hunt(key, "guild")
  H.erwartet("Berta: erlegt 1 und geraecht 1", hb and hb.bagged == 1 and select(2, b.ns.Guild.Avenged(key)) == 1)
  local hn = n.ns.Guild.Hunt(key, "guild")
  H.erwartet("1.2.0: erlegt genau 1 (nichts doppelt)", hn and hn.bagged == 1, hn and hn.bagged)
  local d = {}
  for k, v in pairs(o.env.DeathNoteDB.guild.lists[G].enemies) do if not vorO[k] then d[#d + 1] = k end end
  H.erwartet("1.1.0: nichts Neues, kein Fehler", #d == 0 and #M.errors == 0, M.errors[1])
end)

H.lauf("(4) Freunde: nur die betroffenen Freunde bekommen V, Ausweis wie gehabt", function()
  local W = welt()
  local a = W.client("Anton", "Wurst", nil, { friends = { "Berta Senf", "Fritz Frei" }, fullSender = true })
  local b = W.client("Berta", "Senf", nil, { friends = { "Anton Wurst" }, fullSender = true })
  local f = W.client("Fritz", "Frei", nil, { friends = { "Anton Wurst" }, fullSender = true })
  a.login(); b.login(); f.login(); W.run(120)
  local key = H.tod(b, "Taeter", "Lamm"); W.run(10)
  H.erwartet("Vorbedingung: Taeter im Freundesbuch", a.ns.Guild.Get(key, "friends") ~= nil)
  toetet(a); W.run(10)
  local an = {}
  for _, m in ipairs(W.sent) do if m.sender == a and m.text:find("^1\tV\t") then an[m.to or "?"] = true end end
  H.erwartet("V nur an Berta", an["Berta Senf"] and not an["Fritz Frei"])
  H.erwartet("Berta: Meldung", H.zaehle(b, "AVENGED") == 1)
  H.erwartet("Fritz: nichts", H.zaehle(f, "AVENGED") == 0 and select(2, f.ns.Guild.Avenged(key)) == 0)
  -- forged sender
  local P = b.ns.Guild.Proto
  H.fluestern(b, P.EncodeAvenged(key, "Anton Wurst", time(), false), "Fritz Frei-Forever")
  H.erwartet("fremder Absender: verworfen", select(2, b.ns.Guild.Avenged(key)) == 1)
end)

H.lauf("(5) Schutzregeln: nur live bis 10 Minuten, Deckel je Absender, Zaehler gedeckelt, Schalter", function()
  local W = welt()
  local b = W.client("Berta", "Senf", G, { fullSender = true })
  b.login(); W.run(90)
  local key = H.tod(b, "Taeter", "Lamm"); W.run(5)
  local P, C = b.ns.Guild.Proto, b.ns.Guild.C
  H.gilde(b, P.EncodeAvenged(key, "Anton Wurst", time() - C.BAG_FRESH - 5, false), "Anton Wurst-Forever")
  H.erwartet("aelter als 10 Minuten: verworfen", select(2, b.ns.Guild.Avenged(key)) == 0)
  for i = 1, 6 do H.gilde(b, P.EncodeAvenged(key, "Anton Wurst", time() - 200 * i, false), "Anton Wurst-Forever") end
  H.erwartet("hoechstens 3 je Absender in 10 Minuten", select(2, b.ns.Guild.Avenged(key)) == C.AVENGE_PER_SENDER)
  for r = 1, 50 do
    W.run(C.BAG_WINDOW + 1)
    for i = 1, 3 do H.gilde(b, P.EncodeAvenged(key, "Anton Wurst", time() - 130 * i, false), "Anton Wurst-Forever") end
  end
  local rows = b.ns.Guild.Avenged(key)
  H.erwartet("Zaehler je Raecher gedeckelt (99)", rows[1].n <= C.BAGGED_MAX, rows[1].n)
  -- unknown target: not remembered
  H.gilde(b, P.EncodeAvenged("Nie-Gesehen", "Carla Klee", time(), false), "Carla Klee-Forever")
  H.erwartet("Ziel, das niemand kennt: nicht gemerkt", select(2, b.ns.Guild.Avenged("Nie-Gesehen")) == 0)
  -- switch "report hit list": off = no line, counter keeps counting
  W.run(5)
  b.ns.Store.Setting("guild.announceHunt", false)
  local vor = H.zaehle(b, "AVENGED")
  H.gilde(b, P.EncodeAvenged(key, "Carla Klee", time(), false), "Carla Klee-Forever"); W.run(5)
  H.erwartet("Schalter aus: keine Meldung, Zaehler zaehlt", H.zaehle(b, "AVENGED") == vor and #b.ns.Guild.Avenged(key) == 2,
    H.zaehle(b, "AVENGED") - vor .. " Meldungen, " .. #b.ns.Guild.Avenged(key) .. " Raecher")
  H.erwartet("keine Fehler", #M.errors == 0, M.errors[1])
end)

H.fertig()
