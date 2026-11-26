-- 1.7.1 manual (fixer after the hunt "truth and completeness"): the sentences the hunt found wrong stay right, and
-- what it found missing stays in a chapter. German and English, raw texts of the language files, each tied to the
-- code that makes it true where there is a number or a command: the numbers of the chapters against the values of the
-- loaded modules (JN-5), the commands and switches against a line of the code. Names made up, nothing measured in
-- the game.
-- Usage: luajit tests/ui/ma171_wahrheit.lua <project>
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_mv164.lua")
local check = J.check
local WT = J.WT
local function read(p) local h = assert(io.open(WT .. "/" .. p, "r")); local s = h:read("*a"); h:close(); return s end
local SRC = { deDE = read("DeathNote/Locales/deDE.lua"), enUS = read("DeathNote/Locales/enUS.lua") }
local function T(lang, key) return SRC[lang]:match("\nL%." .. key .. '%s*=%s*"(.-)"%s*[\n%-]') or "" end
local function has(s, w) return s:find(w, 1, true) ~= nil end
-- every paragraph text of the manual in one language (the keys the chapters really read)
local W = J.world("enUS", { db = { version = 5, settings = { welcomed = true, firstRun = "done", news171 = true }, enemies = {}, deaths = {} } })
local UI = W.ns.UI
local function paras(lang)
  local out = {}
  for _, c in ipairs(UI.MANUAL_DATA.chapters) do
    for _, p in ipairs(c.paras) do out[#out + 1] = { key = p[2], chapter = c.id, text = T(lang, p[2]) } end
  end
  return out
end
local function count(lang, w)
  local n, where = 0, {}
  for _, p in ipairs(paras(lang)) do if has(p.text, w) then n = n + 1; where[#where + 1] = p.key end end
  return n, table.concat(where, ",")
end
local function anywhere(lang, w) return (count(lang, w)) > 0 end
local core, store, feud, claim, tracker, bounty = read("DeathNote/Core.lua"), read("DeathNote/Store.lua"),
  read("DeathNote/Feud.lua"), read("DeathNote/Claim.lua"), read("DeathNote/Tracker.lua"), read("DeathNote/Bounty.lua")

-- A1: the text of "Back up book" is a machine format only "Import book" reads (Store.Export writes E|... lines)
check("A1 Code: Buch sichern schreibt E|-Zeilen", has(store, 'local fields = { "E", esc(k)'))
check("A1 deDE: nicht fuer Spieler ohne das Buch", not has(T("deDE", "MANUAL_POST_4"), "ohne das Buch")
  and has(T("deDE", "MANUAL_POST_4"), "mit dem Buch") and has(T("deDE", "MANUAL_POST_4"), "nur {import}"), T("deDE", "MANUAL_POST_4"))
check("A1 enUS: not for players without the book", not has(T("enUS", "MANUAL_POST_4"), "without the book")
  and has(T("enUS", "MANUAL_POST_4"), "with the book") and has(T("enUS", "MANUAL_POST_4"), "Only {import}"), T("enUS", "MANUAL_POST_4"))
-- A2: bounties expire with "Calls last" (Bounty.lua expire on guild.huntExpire)
check("A2 Code: Kopfgelder laufen mit huntExpire ab", has(bounty, 'path == "guild.huntExpire" then expire()'))
check("A2 deDE: Kopfgeld laeuft ab wie eine Freigabe", has(T("deDE", "MANUAL_HUNT_3"), "Freigaben und Kopfgelder gelten")
  and has(T("deDE", "MANUAL_BOUNTY_2"), "läuft ab") and has(T("deDE", "MANUAL_BOUNTY_2"), "{ch_hunt}"))
check("A2 enUS: bounties expire like calls", has(T("enUS", "MANUAL_HUNT_3"), "Calls and bounties last")
  and has(T("enUS", "MANUAL_BOUNTY_2"), "expires") and has(T("enUS", "MANUAL_BOUNTY_2"), "{ch_hunt}"))
-- A3: the rap sheet stays with you, but a killing blow on a target of others reaches them (V, E)
check("A3 Code: eigener Todesstoss geht als V hinaus", has(bounty, "Own killing blow (Sync.lua Guild.OnPartyKill): V to the guild"))
check("A3 deDE: nicht mehr 'Nichts davon wird geteilt'", not has(T("deDE", "MANUAL_RECORD_1"), "Nichts davon wird geteilt")
  and has(T("deDE", "MANUAL_RECORD_1"), "gerächt oder erlegt"))
check("A3 enUS: no longer 'Nothing of it is shared'", not has(T("enUS", "MANUAL_RECORD_1"), "Nothing of it is shared")
  and has(T("enUS", "MANUAL_RECORD_1"), "avenged or taken down"))
-- A11: /dn hunt Name calls without a choice and without a reason (G.Release(key))
check("A11 Code: /dn jagd ruft G.Release(key) ohne Angaben", has(core, "local g, f = G.Release(key)"))
check("A11 deDE: /dn jagd ohne Grund fuer beide", has(T("deDE", "MANUAL_HUNT_1"), "/dn jagd Name ohne Grund für beide"))
check("A11 enUS: /dn hunt for both without a reason", has(T("enUS", "MANUAL_HUNT_1"), "/dn hunt Name for both, without one"))
-- A12: the circle sees it, not everyone with the addon
check("A12 deDE/enUS: nicht 'alle mit dem Buch'", not has(T("deDE", "MANUAL_HUNT_1"), "Alle mit dem Buch")
  and not has(T("enUS", "MANUAL_HUNT_1"), "Everyone with the book"))
-- A13: what is never shared, and the spot with its switch
for _, x in ipairs({ { "deDE", { "Notizen", "Verdacht", "Beteiligungen", "Angriffe", "Übernommenes", "Eingelesenes", "samt Ort", "eigenem Schalter" } },
                     { "enUS", { "notes", "suspicions", "assists", "attacks", "copied", "imported", "their spot", "switch of their own" } } }) do
  local miss = {}
  for _, w in ipairs(x[2]) do if not has(T(x[1], "MANUAL_GUILD_1"), w) then miss[#miss + 1] = w end end
  check("A13 " .. x[1] .. ": Geteiltes und nie Geteiltes vollstaendig", #miss == 0, table.concat(miss, ", "))
end
-- A4 to A9: what was missing has a paragraph (the words of the surface as placeholders)
local NEED = {
  { "A4 geraecht fuer dich", "MANUAL_HUNT_4", {} },
  { "A5 Rache von selbst, Meldung, abziehen", "MANUAL_WANTED_6", { "{payback}", "{revenge_take}" } },
  { "A5 Knopf auf der Rache-Meldung", "MANUAL_RULES_3", { "{show}", "{payback}" } },
  { "A6 Knoepfe, die leeren", "MANUAL_RULES_5", { "{guild_clear}", "{friends_clear}", "{record_clear}" } },
  { "A6 Der Gilde empfehlen", "MANUAL_POST_5", { "{recommend}", "{holders}" } },
  { "A6 Chat-Links des Hilferufs", "MANUAL_GRUDGE_5", { "{gchat}", "{map_link}" } },
  { "A7 Quelle, Abgleichen, Uebernehmen, Nur was mir fehlt", "MANUAL_GUILD_4", { "{src_all}", "{src_guild}", "{src_friends}", "{sync}", "/dn sync", "{take}", "{take_all}", "{only_new}" } },
  { "A7 Freund ohne Nachnamen", "MANUAL_LIMITS_5", { "{by_mate}", "{tie_loose}" } },
  { "A8 Meldungen von selbst", "MANUAL_START_5", { "{banner_rank}", "{banner_award}", "{banner_claim}", "{sheet_guild}", "{more}", "{sheet_record}" } },
  { "A9 /dn start", "MANUAL_RULES_4", { "/dn start" } },
  { "A10 Marke an der Namensplakette", "MANUAL_ALARM_6", { "{sheet_record}" } },
  { "A21 Wieder offen, Aus der Liste nehmen", "MANUAL_BOUNTY_4", { "{reopen}", "{earned_remove}" } },
  { "A22 Wieder jagen", "MANUAL_WANTED_4", { "{hunt_again}" } },
}
local chapterOf = {}
for _, p in ipairs(paras("enUS")) do chapterOf[p.key] = p.chapter end
for _, n in ipairs(NEED) do
  for _, lang in ipairs({ "deDE", "enUS" }) do
    local t, miss = T(lang, n[2]), {}
    for _, w in ipairs(n[3]) do if not has(t, w) then miss[#miss + 1] = w end end
    check(n[1] .. " " .. lang .. ": " .. n[2] .. " ist ein Absatz und nennt es", chapterOf[n[2]] ~= nil and t ~= "" and #miss == 0,
      (chapterOf[n[2]] and "" or "kein Absatz; ") .. table.concat(miss, ", "))
  end
end
check("A4 deDE/enUS: Chatzeile und Zaehler", has(T("deDE", "MANUAL_HUNT_4"), "Chatzeile") and has(T("deDE", "MANUAL_HUNT_4"), "für andere")
  and has(T("enUS", "MANUAL_HUNT_4"), "chat line") and has(T("enUS", "MANUAL_HUNT_4"), "for others"))
check("A9 Code: /dn start oeffnet das Startfenster", has(core, 'cmd == "start"'))
check("A10 deDE/enUS: drei Marken genannt", has(T("deDE", "MANUAL_ALARM_6"), "Fadenkreuz") and has(T("deDE", "MANUAL_ALARM_6"), "graue")
  and has(T("enUS", "MANUAL_ALARM_6"), "crosshair") and has(T("enUS", "MANUAL_ALARM_6"), "grey"))
-- A9: the switch "Dry remarks" exists only in German and English: no chapter names it
check("A9 Trockene Bemerkungen in keinem Kapitel (nur deDE und enUS sichtbar)", not anywhere("deDE", "Trockene Bemerkungen")
  and not anywhere("enUS", "Dry remarks"))
-- A17: one title, the same in README and CHANGELOG
check("A17 enUS-Titel Post and back up", T("enUS", "MANUAL_POST_TITLE") == "Post and back up", T("enUS", "MANUAL_POST_TITLE"))
check("A17 README und CHANGELOG ohne 'Post and pass on'", not has(read("README.md"), "Post and pass on")
  and not has(read("CHANGELOG.md"), "Post and pass on"))
-- A18: said once only
for _, x in ipairs({ { "deDE", "bewegt kein Gold" }, { "enUS", "moves no gold" }, { "deDE", "Mittelklick" }, { "enUS", "middle-click" },
                     { "deDE", "Rechtsklick auf den Minimap-Knopf" }, { "enUS", "Right-click the minimap button" },
                     { "deDE", "Rechtsklick auf den Minimap" } }) do
  local n, where = count(x[1], x[2])
  check("A18 " .. x[1] .. " nur einmal: " .. x[2], n <= 1, where)
end
-- the minimap clicks in English, in any spelling ("Right-click the minimap button", "a right click on the minimap button")
do
  local n, where = 0, {}
  for _, p in ipairs(paras("enUS")) do
    if p.text:lower():find("right[%- ]click[^.;]-minimap") then n = n + 1; where[#where + 1] = p.key end
  end
  check("A18 enUS nur einmal: right click on the minimap button", n <= 1, table.concat(where, ","))
end
check("A18 Kapitel Grenzen nennt die stillen Zonen nicht noch einmal", not has(T("deDE", "MANUAL_LIMITS_1"), "Dungeons")
  and not has(T("enUS", "MANUAL_LIMITS_1"), "dungeons"))
-- A19: the alarm and the limits name the same units, focus too (Tracker.lua PLAYER_FOCUS_CHANGED)
check("A19 Code: Fokus wird gelesen", has(tracker, 'Tracker.OnUnit("focus", "other")'))
check("A19 deDE/enUS: Fokus in Alarm und Grenzen", has(T("deDE", "MANUAL_ALARM_1"), "Fokus") and has(T("deDE", "MANUAL_LIMITS_1"), "Fokus")
  and has(T("enUS", "MANUAL_ALARM_1"), "focus") and has(T("enUS", "MANUAL_LIMITS_1"), "focus"))
-- A20: /dn help does not list every command
check("A20 deDE/enUS: nicht 'alle Befehle'", not has(T("deDE", "MANUAL_LIMITS_3"), "alle Befehle")
  and not has(T("enUS", "MANUAL_LIMITS_3"), "every command"))
-- A21: claims for 30 days, the filed keep at most 200, the poster has a name in the sentence
check("A21 Code: 30 Tage Ansprueche, 200 Abgelegte", has(feud, "Feud.CLAIM_DAYS = 30") and has(claim, "Claim.DAYS = 30")
  and has(feud, "Feud.MAX_EXPIRED = 200"))
check("A21 deDE: Du und der Auslober, 30 Tage, 200", has(T("deDE", "MANUAL_BOUNTY_3"), "Du und der Auslober")
  and has(T("deDE", "MANUAL_BOUNTY_3"), "30 Tage") and has(T("deDE", "MANUAL_UNSOLVED_4"), "höchstens 200"))
check("A21 enUS: You and the poster, 30 days, 200", has(T("enUS", "MANUAL_BOUNTY_3"), "You and the poster")
  and has(T("enUS", "MANUAL_BOUNTY_3"), "30 days") and has(T("enUS", "MANUAL_UNSOLVED_4"), "at most 200"))
-- A22: the switch Players | Guilds comes once the book knows a guild (FeudUI.lua #Fe.Guilds() > 0)
check("A22 deDE/enUS: Bedingung des Umschalters", has(T("deDE", "MANUAL_WANTED_5"), "Sobald das Buch eine Gilde kennt")
  and has(T("enUS", "MANUAL_WANTED_5"), "Once a guild is known"))
-- A24: README and the old comments follow the code (drag without Shift since 1.5.0, the button Call, tab 5 from the start)
local readme = read("README.md")
check("A24 README ohne Shift-drag und ohne Help-Knopf", not has(readme, "Shift-drag") and not has(readme, '"Help" button'))
check("A24 Kommentare an UX.FILTERS und TAB_RECORD", not has(read("DeathNote/UI.lua"), "only from the first own kill on")
  and not has(SRC.enUS, "appears with your first own kill"))
-- 1.7.1 fixer 2 (JN-5): every number of a chapter is tied to the value the code uses. The value is read from the
-- loaded modules (not from a text in the source), and the sentence must name the number that value gives: a changed
-- constant turns this red. "Rank 1" (MANUAL_RECORD_2) is an ordinal, not a setting, and stays with its text.
do
  local ns = W.ns
  local GC = ns.Guild and ns.Guild.C or {}
  local ex = {}
  for _, d in ipairs(GC.EXPIRE_DAYS or {}) do if d ~= 0 then ex[#ex + 1] = tostring(d) end end
  local gap = ns.GuildLog and ns.GuildLog.RECOMMEND_GAP
  local NUMS = {
    { "MANUAL_POST_5", gap and gap % 60 == 0 and gap / 60, "alle %s Minuten", "every %s minutes" },
    { "MANUAL_UNSOLVED_4", ns.Feud and ns.Feud.EXPIRE_DAYS, "nach %s Spieltagen", "after %s play days" },
    { "MANUAL_UNSOLVED_4", ns.Feud and ns.Feud.MAX_EXPIRED, "höchstens %s,", "at most %s," },
    { "MANUAL_GRUDGE_3", ns.Call and ns.Call.C and ns.Call.C.COOLDOWN, "einmal je %s Sekunden", "once per %s seconds" },
    { "MANUAL_POST_1", ns.Share and ns.Share.COOLDOWN, "höchstens alle %s Sekunden", "at most every %s seconds" },
    { "MANUAL_BOUNTY_2", GC.BOUNTY_GOLD_MAX, "1 bis %s Gold", "1 to %s gold" },
    { "MANUAL_BOUNTY_3", ns.Claim and ns.Claim.DAYS, "%s Tage", "%s days" },
    { "MANUAL_BOUNTY_3", ns.Feud and ns.Feud.CLAIM_DAYS, "%s Tage", "%s days" },
    { "MANUAL_HUNT_3", GC.EXPIRE_DAYS and GC.EXPIRE_DAYS[1] == 0 and #ex > 0 and table.concat(ex, ", "),
      "immer oder %s Tage", "forever or %s days" },
  }
  for _, n in ipairs(NUMS) do
    local v = n[2]
    v = type(v) == "number" and (v == math.floor(v) and string.format("%d", v) or tostring(v)) or v
    for i, lang in ipairs({ "deDE", "enUS" }) do
      local want = type(v) == "string" and n[2 + i]:format(v) or nil
      check("JN-5 " .. lang .. " " .. n[1] .. ": Zahl aus dem Code (" .. tostring(v) .. ")",
        want ~= nil and has(T(lang, n[1]), want), tostring(want) .. " in: " .. T(lang, n[1]))
    end
  end
  -- 0 takes a bounty back: the command accepts 0 only for an own bounty (Core.lua), the bounty value 1 at least
  check("JN-5 Code: /dn kopfgeld Name 0 nimmt das eigene Kopfgeld zurueck", has(core, "gold == 0 and G.OwnBounty"))
  check("JN-5 deDE/enUS: 0 nimmt es zurueck", has(T("deDE", "MANUAL_BOUNTY_2"), "0 nimmt es zurück")
    and has(T("enUS", "MANUAL_BOUNTY_2"), "0 takes it back"))
end
-- 1.7.1 fixer 2 (JN-3): the source switch All | Guild | Friends stands only with a guild and a friend who has the book
-- (UI.lua UpdateTabs, GF.both); the sentence names that condition
check("JN-3 Code: der Umschalter Quelle haengt an GF.both", has(read("DeathNote/UI.lua"), "local srcs = guildTab and GF.HasFriends() and GF.both"))
check("JN-3 deDE/enUS: Bedingung des Umschalters", has(T("deDE", "MANUAL_GUILD_4"), "Hast du Gilde und Freunde mit dem Buch, wählt unten links")
  and has(T("enUS", "MANUAL_GUILD_4"), "If your guild and friends have the book, {src_all}"))
-- 1.7.1 fixer 2 (JN-8): the House Rules hold the mark's off and size (Plate.ORDER, GripUI.Plate in the sheet of the
-- rap sheet); the enemy nameplates are the game's setting (Util.NameplatesOn reads the CVar), not the book's
do
  local plate = read("DeathNote/Plate.lua")
  check("JN-8 Code: Marke aus und Groesse, Feind-Plaketten vom Spiel", has(plate, 'Plate.ORDER = { "off", "small", "medium", "large" }')
    and has(plate, "if Util.platesOn == false then return false end") and has(core, 'GetCVarBool, "nameplateShowEnemies"')
    and has(read("DeathNote/UI.lua"), "ns.GripUI.Plate(S, RR,"))
  check("JN-8 deDE: aus und Groesse in der Hausordnung, Plaketten vom Spiel", has(T("deDE", "MANUAL_ALARM_6"), "aus und Größe: {rules}, {sheet_record}")
    and has(T("deDE", "MANUAL_ALARM_6"), "wenn das Spiel Feind-Plaketten zeigt") and not has(T("deDE", "MANUAL_ALARM_6"), "Plaketten ({rules}"))
  check("JN-8 enUS: off and size in the rules, nameplates of the game", has(T("enUS", "MANUAL_ALARM_6"), "off and size: {rules}, {sheet_record}")
    and has(T("enUS", "MANUAL_ALARM_6"), "while the game shows enemy nameplates") and not has(T("enUS", "MANUAL_ALARM_6"), "nameplates on ({rules}"))
end
-- 1.7.1 fixer 2 (JN-7): the docs say what the guards and the page really do. ma171_stand whole (both conditions, the
-- format of the note, that it only reminds) in README, CHANGELOG and TRANSLATING; every chapter placeholder in
-- TRANSLATING; the visible things of the fix rounds in the CHANGELOG
do
  local docs = { README = read("README.md"), CHANGELOG = read("CHANGELOG.md"), TRANSLATING = read("TRANSLATING.md") }
  for name, d in pairs(docs) do
    check("JN-7 " .. name .. ": ma171_stand vollstaendig", has(d, "ma171_stand.lua") and has(d, "UI.MANUAL_CHECKED")
      and has(d, 'unchanged["<version>"] = "nothing the player sees changes, because') and has(d, "only reminds"))
  end
  local miss = {}
  for ph in pairs(UI.MANUAL_DATA.chapterWords) do if not has(docs.TRANSLATING, "{" .. ph .. "}") then miss[#miss + 1] = ph end end
  check("JN-7 TRANSLATING nennt jeden Kapitel-Platzhalter", #miss == 0, table.concat(miss, ", "))
  local cl = docs.CHANGELOG:match("## 1%.7%.1.-\n## 1%.7%.0") or ""
  check("JN-7 CHANGELOG 1.7.1: Farbe, Rueckweg ins Blatt, gemerkte Seite, Baendchen", has(cl, "stand in colour")
    and has(cl, "leads back into that sheet") and has(cl, "is not remembered") and has(cl, "red ribbon of the guild chronicle"))
end
J.done("ma171 wahrheit")
