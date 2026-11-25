-- 1.7.1 manual: the guard "checked for this version". UI.MANUAL_CHECKED names the version of the addon the manual was
-- last checked against; it must equal the version in DeathNote.toc. A new version turns this test red until the
-- manual is brought along. Usage: luajit tests/ui/ma171_stand.lua <project>
local WT = (arg and arg[1] or "."):gsub("/+$", "")
local toc
for line in io.lines(WT .. "/DeathNote/DeathNote.toc") do
  local v = line:match("^## Version:%s*(%S+)")
  if v then toc = v end
end
local src = assert(io.open(WT .. "/DeathNote/UI.lua", "r")):read("*a")
local checked = src:match('UI%.MANUAL_CHECKED%s*=%s*"([^"]+)"')
if toc and checked and toc == checked then
  print(("ma171 stand: Gebrauchsanweisung durchgesehen fuer %s, TOC %s: ok"):format(checked, toc))
  os.exit(0)
end
print(("ROT   ma171 stand: DeathNote.toc sagt Version %s, die Gebrauchsanweisung ist durchgesehen fuer %s (UI.MANUAL_CHECKED in UI.lua)."):format(tostring(toc), tostring(checked)))
print("      Zu tun: 1. tests/ui/manual_inventar.lua um jede sichtbare Neuerung dieser Version nachfuehren (Funktion, Version,")
print("      Kapitel). 2. Die betroffenen Kapitel (MANUAL_* in Locales/*.lua) in allen 21 Sprachen aendern, jeder Satz am Code")
print("      geprueft. 3. Dann UI.MANUAL_CHECKED auf die neue Version setzen.")
os.exit(1)
