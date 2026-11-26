-- 1.7.1 manual: the guard "checked for this version". UI.MANUAL_CHECKED names the version of the addon the manual was
-- last checked against; it must equal the version in DeathNote.toc. This guard only reminds: it cannot see whether
-- anybody really read the chapters against the code. It turns red when
--  1. the TOC names another version than UI.MANUAL_CHECKED (the value the loaded addon carries, not a match in the
--     source, so a comment cannot stand in for it), or
--  2. tests/ui/manual_inventar.lua has no line for the TOC's version: neither a row whose second field is that version
--     nor an entry in its field `unchanged` (1.7.1 fixer, Seite B6), the explicit note for a version that changes
--     nothing a player sees. Its format, one entry per version, inside the returned table after the rows:
--        unchanged = { ["1.7.2"] = "nothing the player sees changes, because only the guild sync was made faster" },
--     The text must begin with "nothing the player sees changes, because " and give a reason (at least 10 more
--     characters). ipairs over the rows does not see this field.
-- Every line of the instruction begins with ROT, so tests/ui/run.sh (grep "^ROT") shows it whole.
-- Usage: luajit tests/ui/ma171_stand.lua <project>
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_mv164.lua")
local WT = J.WT:gsub("/+$", "")
local toc
for line in io.lines(WT .. "/DeathNote/DeathNote.toc") do
  local v = line:match("^## Version:%s*(%S+)")
  if v then toc = v end
end
local W = J.world("enUS", { db = { version = 5, settings = { welcomed = true, firstRun = "done", news171 = true }, enemies = {}, deaths = {} } })
local checked = W.ns.UI and W.ns.UI.MANUAL_CHECKED
local list = dofile(WT .. "/tests/ui/manual_inventar.lua")
local BECAUSE = "nothing the player sees changes, because "
local row, note = false, nil
for _, r in ipairs(list) do if r[2] == toc then row = true end end
local u = type(list.unchanged) == "table" and list.unchanged[toc]
if type(u) == "string" and u:sub(1, #BECAUSE) == BECAUSE and #u >= #BECAUSE + 10 then note = u end

local red = {}
if not (toc and checked and toc == checked) then
  red[#red + 1] = ("DeathNote.toc sagt Version %s, die Gebrauchsanweisung ist durchgesehen fuer %s (UI.MANUAL_CHECKED in UI.lua)")
    :format(tostring(toc), tostring(checked))
end
if not row and not note then
  red[#red + 1] = ("tests/ui/manual_inventar.lua hat keine Zeile fuer Version %s und keinen Eintrag unchanged[\"%s\"]")
    :format(tostring(toc), tostring(toc))
end
if #red == 0 then
  print(("ma171 stand: Gebrauchsanweisung durchgesehen fuer %s, TOC %s, Inventar %s: ok"):format(checked, toc,
    row and "mit Zeile dieser Version" or "Vermerk nichts Sichtbares"))
  os.exit(0)
end
for _, r in ipairs(red) do print("ROT   ma171 stand: " .. r .. ".") end
print("ROT   Zu tun: 1. tests/ui/manual_inventar.lua um jede sichtbare Neuerung dieser Version nachfuehren (Funktion, Version,")
print("ROT   Kapitel, Schluessel des Absatzes); aendert sie nichts Sichtbares, dort unchanged[\"<Version>\"] = \"" .. BECAUSE .. "...\".")
print("ROT   2. Die betroffenen Kapitel (MANUAL_* in Locales/*.lua) in allen 21 Sprachen aendern, jeder Satz am Code geprueft.")
print("ROT   3. Dann UI.MANUAL_CHECKED in UI.lua auf die neue Version setzen. Der Waechter erinnert nur, er prueft das Lesen nicht.")
print(("ma171 stand: %d rot"):format(#red))
os.exit(1)
