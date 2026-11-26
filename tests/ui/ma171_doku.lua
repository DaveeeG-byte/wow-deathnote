-- 1.7.1 fixer 2 (JN-7): the docs of the manual say what its guards and its page really do. Kept apart from
-- ma171_wahrheit, which reads only the language files, the code, README and CHANGELOG. Usage:
-- luajit tests/ui/ma171_doku.lua <project>
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_mv164.lua")
local check = J.check
local function read(p) local h = assert(io.open(J.WT .. "/" .. p, "r")); local s = h:read("*a"); h:close(); return s end
local function has(s, w) return s:find(w, 1, true) ~= nil end
local W = J.world("enUS", { db = { version = 5, settings = { welcomed = true, firstRun = "done", news171 = true }, enemies = {}, deaths = {} } })
local UI = W.ns.UI
-- ma171_stand whole (both conditions, the format of the note, that it only reminds) in README, CHANGELOG and
-- TRANSLATING; every chapter placeholder in TRANSLATING; the visible things of the fix rounds in the CHANGELOG
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
J.done("ma171 doku")
