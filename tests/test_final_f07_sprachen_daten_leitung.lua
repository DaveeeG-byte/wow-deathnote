-- Sprache gegen Daten: zwei Clients in verschiedenen Sprachen (Deutsch, Chinesisch) in Gilde und als Freunde.
-- (1) Kommt irgendein uebersetzter Text ueber die Leitung? (alle gesendeten Nachrichten gegen beide Sprachtabellen)
-- (2) Steht irgendein uebersetzter Text in DeathNoteDB? (alle Texte der Datei gegen die Sprachtabelle)
-- (3) Sichern auf Deutsch, Einlesen auf Chinesisch, und zurueck.
-- (4) Befehle: deutsch und englisch gemischt; Spieler, die wie ein Unterbefehl heissen (Hunt, Lang, Test, Jagd, Help).
-- (fix-2) Belegtest der finalen Jagd, in die Suite uebernommen; Kopf: tests/beleg_helfer.lua
package.path = (arg[0]:match("^(.*)/") or ".") .. "/?.lua;" .. package.path
local H = require("beleg_helfer")
local M = H.M
local G = "Die Testgilde"

local function mitSprache(code)
  local files = {}
  for _, f in ipairs(M.FILES) do
    files[#files + 1] = f
    if f == "Locales/deDE.lua" and code ~= "deDE" and code ~= "enUS" then files[#files + 1] = "Locales/" .. code .. ".lua" end
  end
  return files
end
local function texte(ns)
  local out = {}
  for k, v in pairs(ns.L) do
    if type(v) == "string" then
      local plain = v:gsub("{[^{}]*}", "\0")
      for part in plain:gmatch("[^%z\n]+") do
        part = part:gsub("^%s+", ""):gsub("%s+$", "")
        if #part >= 9 and k ~= "SAMPLE_ZONE" and k ~= "CHANNEL_MASTER" then out[part] = k end   -- Beispielzone und Kanalname sind keine Saetze
      end
    end
  end
  return out
end
-- alle Texte einer Tabelle; ohneNotiz: das Feld "note" (freier Text des Spielers) bleibt aussen vor
local function strings(t, out, seen, ohneNotiz)
  out, seen = out or {}, seen or {}
  if seen[t] then return out end
  seen[t] = true
  for k, v in pairs(t) do
    if type(k) == "string" then out[#out + 1] = k end
    if type(v) == "string" then
      if not (ohneNotiz and k == "note") then out[#out + 1] = v end
    elseif type(v) == "table" then strings(v, out, seen, ohneNotiz) end
  end
  return out
end
local function treffer(list, dict, erlaubt)
  local hits = {}
  for _, s in ipairs(list) do
    for part, key in pairs(dict) do
      if s:find(part, 1, true) and not (erlaubt and erlaubt[key]) then hits[#hits + 1] = key; break end
    end
  end
  return hits
end

H.lauf("zwei Sprachen, Gilde und Freunde", function()
  local W = H.welt()
  local a = W.client("Anton", "Wurst", G, { lang = "deDE", friends = { "Carla" } })
  local b = W.client("Berta", "Senf", G, { lang = "zhCN", files = mitSprache("zhCN") })
  local c = W.client("Carla", "Fern", nil, { lang = "zhCN", files = mitSprache("zhCN"), friends = { "Anton" } })
  a.login(); b.login(); c.login(); W.run(60)
  H.erwartet("Vorbedingung: Sprachen aktiv", a.ns.Locale.code == "deDE" and b.ns.Locale.code == "zhCN" and c.ns.Locale.code == "zhCN",
    a.ns.Locale.code .. "/" .. b.ns.Locale.code)
  local k = H.tod(a, "Grimm", "Bart"); H.tod(b, "Grimm", "Bart", 5); H.tod(c, "Boese", "Wicht", 7)
  a.ns.Store.AddManual("Hand", "Eintrag"); b.ns.Store.AddManual("Zweite", "Hand")
  a.ns.Guild.Release(k, { to = "all", why = "Grund auf Deutsch" })
  b.ns.Guild.Release("Opfer-Lamm", { to = "guild", why = "他一直在路上偷袭" })
  c.ns.Guild.Release("Opfer-Lamm", { to = "friends", why = "理由" })
  W.run(30)
  a.ns.Guild.CallOff(k); b.ns.Store.Remove("Zweite-Hand")
  a.ns.Store.Setting("guild.sightings", true); b.ns.Store.Setting("guild.sightings", true)
  W.run(320)
  a.ns.Guild.SyncNow(); b.ns.Guild.SyncNow(); W.run(90)
  for _, x in ipairs({ a, b, c }) do x.ns.HandleSlash("probe"); x.ns.HandleSlash("gilde") end
  -- Uebernehmen aus dem Gildenbuch (schreibt laut Bau-Bericht einmal eine Notiz in der aktiven Sprache)
  local nb = H.tod(b, "Nur", "Bertas"); W.run(20)
  local adopted = a.ns.Guild.Adopt(nb)
  H.erwartet("Vorbedingung: Uebernehmen aus dem Gildenbuch klappt", adopted ~= nil)
  W.run(5)
  local da, dz = texte(a.ns), texte(b.ns)
  local wire = {}
  for _, m in ipairs(W.sent) do wire[#wire + 1] = m.text end
  local arten = {}
  for _, t in ipairs(wire) do arten[t:match("^%d+\t(%u)") or "?"] = true end
  local alle = true
  for _, kk in ipairs({ "H", "K", "R", "M", "X", "J", "A" }) do if not arten[kk] then alle = false end end
  local ak = {}
  for kk in pairs(arten) do ak[#ak + 1] = kk end
  table.sort(ak)
  H.erwartet("Vorbedingung: es wurde gesendet (H K R M X J A)", alle, table.concat(ak, " "))
  local h1, h2 = treffer(wire, da), treffer(wire, dz)
  H.erwartet("kein deutscher Sprachtext auf der Leitung", #h1 == 0, table.concat(h1, ","))
  H.erwartet("kein chinesischer Sprachtext auf der Leitung", #h2 == 0, table.concat(h2, ","))
  for _, x in ipairs({ a, b, c }) do x.fire("PLAYER_LOGOUT") end
  local ha = treffer(strings(a.env.DeathNoteDB), da)
  local hb = treffer(strings(b.env.DeathNoteDB), dz)
  local hc = treffer(strings(c.env.DeathNoteDB), dz)
  io.write("  in der Datei gefundene Sprachtexte: deDE-Client [" .. table.concat(ha, ",") .. "], zhCN-Clients [" .. table.concat(hb, ",") .. "] [" .. table.concat(hc, ",") .. "]\n")
  H.erwartet("in DeathNoteDB steht ausser im Feld Notiz kein Sprachtext",
    #treffer(strings(a.env.DeathNoteDB, nil, nil, true), da) == 0 and #treffer(strings(b.env.DeathNoteDB, nil, nil, true), dz) == 0
    and #treffer(strings(c.env.DeathNoteDB, nil, nil, true), dz) == 0)
  H.erwartet("die uebernommene Notiz ist sprachneutral (Regel 9: nichts Uebersetztes in DeathNoteDB)",
    #treffer(strings(b.env.DeathNoteDB), dz) == 0 and #ha == 0, "Schluessel NOTE_FROM_GUILD steht als Satz in der Datei und im Export")

  -- (3) Sichern auf Deutsch, Einlesen auf Chinesisch und umgekehrt
  local text = a.ns.Store.Export(false)
  H.erwartet("Export traegt keinen deutschen Sprachtext", #treffer({ text }, da) == 0, table.concat(treffer({ text }, da), ","))
  local ok, added = c.ns.Store.Import(text)
  H.erwartet("Deutsch gesichert, Chinesisch eingelesen", ok == true and (added or 0) > 0, tostring(added))
  local text2 = b.ns.Store.Export(false)
  local ok2, _, merged = a.ns.Store.Import(text2)
  H.erwartet("Chinesisch gesichert, Deutsch eingelesen", ok2 == true, tostring(merged))
  local okBad, msg = c.ns.Store.Import("E|kaputt")
  H.erwartet("Fehlermeldung beim Einlesen kommt in der aktiven Sprache (ein Text, kein Schluessel)", okBad == false and type(msg) == "string"
    and not msg:find("^IMPORT_"), tostring(msg))
end)

H.lauf("Befehle gemischt, Namen wie Unterbefehle", function()
  M.Reset()
  local ns = M.Load({ lang = "enUS" })
  local slash = _G.SlashCmdList.DEATHNOTE
  for _, n in ipairs({ "Hunt", "Lang", "Test", "Jagd", "Help", "Hilfe", "Sync", "Guild", "Add", "Del", "Probe", "Debug", "Friends", "Calloff" }) do
    slash("add " .. n .. " Nachname")
    H.erwartet("/dn add " .. n .. " Nachname traegt ein", ns.Store.Get(n .. "-Nachname") ~= nil)
    slash("ADD " .. n:lower() .. " zweitname")
    H.erwartet("/dn ADD " .. n:lower() .. " zweitname traegt ein (Gross/Klein)", ns.Store.Get(n .. "-Zweitname") ~= nil)
  end
  slash("del Hunt Nachname")
  H.erwartet("/dn del Hunt Nachname streicht", ns.Store.Get("Hunt-Nachname") == nil)
  -- deutsche und englische Befehle in der englischen Sitzung, ohne Fehler und ohne "unbekannt"
  local unknown = ns.L.CHAT_UNKNOWN_CMD
  for _, c in ipairs({ "hilfe", "help", "?", "ruhe", "still", "mute", "quiet", "gilde", "guild", "freunde", "friends", "sync",
      "jagd", "hunt", "abblasen Niemand", "calloff Niemand", "sprache", "lang", "language", "test", "debug", "debug" }) do
    M.chat = {}
    slash(c)
    local bad = false
    for _, l in ipairs(M.chat) do if l:find(unknown, 1, true) then bad = true end end
    H.erwartet("/dn " .. c .. " ist bekannt", not bad)
  end
  slash("jagd Test Nachname")
  H.erwartet("/dn jagd Test Nachname: kein Fehler", #M.errors == 0, M.errors[1])
  for _, v in ipairs({ "DE", "de-DE", "de_de", " deDE ", "zhcn", "zh", "xx", "", "deutsch", "|cffff0000de|r", ("x"):rep(300) }) do slash("lang " .. v) end
  H.erwartet("/dn lang mit Unsinn: kein Fehler, Wahl bleibt gueltig", #M.errors == 0 and ns.Locale.Normalize(ns.Store.Setting("lang")) ~= nil,
    tostring(M.errors[1] or ns.Store.Setting("lang")))
end)

H.fertig()
