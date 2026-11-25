-- 1.7.1 manual: the line after the update (news171) once for everybody who had the book before, after the chain of
-- 1.7.0 when he has not seen that one yet; never for a new installation, never in combat; every marker is set with it.
-- Names made up. Usage: luajit tests/ui/ma171_news.lua <project>
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_mv164.lua")
local check = J.check
local function plain(s) return (tostring(s or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")) end
local function index(W, text)
  for i, l in ipairs(W.chat()) do if plain(l):find(plain(text), 1, true) then return i end end
end
local function count(W, text)
  local n = 0
  for _, l in ipairs(W.chat()) do if plain(l):find(plain(text), 1, true) then n = n + 1 end end
  return n
end
local function db(extra)
  local st = { welcomed = true, firstRun = "done" }
  for k, v in pairs(extra or {}) do st[k] = v end
  return { version = 5, settings = st, enemies = {}, deaths = {} }
end
for _, code in ipairs({ "deDE", "enUS" }) do
  do -- from 1.7.0: only the line of 1.7.1, once
    local d = db({ news170 = true, news164 = true, news160 = true, news150 = true, news140 = true, lang = code })
    local W = J.world(code, { db = d })
    W.tick(60)
    local S, L = W.ns.Start, W.ns.L
    local line = S.NewsLine171()
    check(code .. " news171: eine Zeile", count(W, line) == 1)
    check(code .. " news171: nicht die von 1.7.0", count(W, S.NewsLine170()) == 0)
    check(code .. " news171: Platzhalter gefuellt, nennt den Kopf der Gebrauchsanweisung und ?", not line:find("{", 1, true)
      and line:find(L.HEAD_HELP, 1, true) and line:find("?", 1, true), line)
    check(code .. " news171: Merker", d.settings.news171 == true)
    local R = W.reload(code)
    R.tick(60)
    check(code .. " news171: nach dem Neuladen keine zweite", count(R, R.ns.Start.NewsLine171()) == 0)
  end
  do -- from 1.6.4: 1.7.0 first, then 1.7.1
    local d = db({ news164 = true, news160 = true, news150 = true, news140 = true, lang = code })
    local W = J.world(code, { db = d })
    W.tick(60)
    local a, b = index(W, W.ns.Start.NewsLine170()), index(W, W.ns.Start.NewsLine171())
    check(code .. " aus 1.6.4: beide, 1.7.0 zuerst", a and b and a < b, tostring(a) .. " " .. tostring(b))
    check(code .. " aus 1.6.4: alle Merker", d.settings.news171 and d.settings.news170 and d.settings.news164)
  end
end
do -- from 1.4.x: 1.5.0, 1.6.0, 1.6.4, 1.7.0, 1.7.1 in this order
  local W = J.world("deDE", { db = db({ news140 = true }) })
  W.tick(60)
  local S = W.ns.Start
  local a, b, c, e, f = index(W, W.ns.L.CHAT_NEWS_150), index(W, S.NewsLine()), index(W, S.NewsLine164()),
    index(W, S.NewsLine170()), index(W, S.NewsLine171())
  check("aus 1.4: fuenf Zeilen in der Reihenfolge", a and b and c and e and f and a < b and b < c and c < e and e < f,
    table.concat({ tostring(a), tostring(b), tostring(c), tostring(e), tostring(f) }, " "))
end
do -- in combat: waits for the end of the fight
  local d = db({ news170 = true, news164 = true, news160 = true, news150 = true, news140 = true })
  local W = J.world("deDE", { db = d })
  W.AM.inCombat, W.BM.combat = true, true
  W.tick(60)
  check("news171: nichts im Kampf", count(W, W.ns.Start.NewsLine171()) == 0 and d.settings.news171 == nil)
  W.combat(false)
  check("news171: nach dem Kampf", count(W, W.ns.Start.NewsLine171()) == 1)
end
do -- a new installation: no line, every marker at once
  local W = J.world("deDE", { db = nil, whole = true })
  W.tick(4)
  local st = _G.DeathNoteDB.settings
  check("neu: alle Merker sofort", st.news171 == true and st.news170 == true and st.news164 == true)
  local dlg = W.frame("DeathNoteStart")
  if dlg and dlg.go then dlg.go._scripts.OnClick(dlg.go, "LeftButton") end
  W.tick(60)
  check("neu: keine Zeile", count(W, W.ns.Start.NewsLine171()) == 0)
end
J.done("ma171 news")
