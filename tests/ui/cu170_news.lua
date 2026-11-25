-- 1.7.0 claim: the line after the update (news170) once for everybody who had the book before, after the older lines he
-- has not seen yet (1.5.0, 1.6.0, 1.6.4, as 1.6.4 did), never for a new installation, never in combat; every marker is
-- set with it. Names made up.
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
  local st = { welcomed = true, firstRun = "done", lang = "deDE" }
  for k, v in pairs(extra or {}) do st[k] = v end
  return { version = 5, settings = st, enemies = {}, deaths = {} }
end

for _, code in ipairs({ "deDE", "enUS" }) do
  do -- from 1.6.4: only the line of 1.7.0, once
    local d = db({ news164 = true, news160 = true, news150 = true, news140 = true, lang = code })
    local W = J.world(code, { db = d })
    W.tick(60)
    local S, L = W.ns.Start, W.ns.L
    local line = S.NewsLine170()
    check(code .. " news170: eine Zeile", count(W, line) == 1)
    check(code .. " news170: nicht die von 1.6.4", count(W, S.NewsLine164()) == 0)
    check(code .. " news170: Platzhalter gefuellt, nennt Zu klaeren > Ansprueche und den Buchwert", not line:find("{", 1, true)
      and line:find(L.TAB_UNSOLVED .. " > " .. L.VIEW_CLAIMS, 1, true) and line:find(L.POSTER_BOOK_VALUE, 1, true), line)
    check(code .. " news170: Merker", d.settings.news170 == true)
    local R = W.reload(code)
    R.tick(60)
    check(code .. " news170: nach dem Neuladen keine zweite", count(R, R.ns.Start.NewsLine170()) == 0)
  end
  do -- from 1.6.0: 1.6.4 first, then 1.7.0
    local d = db({ news160 = true, news150 = true, news140 = true, lang = code })
    local W = J.world(code, { db = d })
    W.tick(60)
    local i164, i170 = index(W, W.ns.Start.NewsLine164()), index(W, W.ns.Start.NewsLine170())
    check(code .. " aus 1.6.0: beide, 1.6.4 zuerst", i164 and i170 and i164 < i170, tostring(i164) .. " " .. tostring(i170))
    check(code .. " aus 1.6.0: nicht die von 1.6.0", count(W, W.ns.Start.NewsLine()) == 0)
    check(code .. " aus 1.6.0: alle Merker", d.settings.news170 and d.settings.news164 and d.settings.news160 and d.settings.news150)
  end
end
do -- from 1.4.x: 1.5.0, 1.6.0, 1.6.4, 1.7.0 in this order
  local d = db({ news140 = true })
  local W = J.world("deDE", { db = d })
  W.tick(60)
  local S = W.ns.Start
  local a, b, c, e = index(W, W.ns.L.CHAT_NEWS_150), index(W, S.NewsLine()), index(W, S.NewsLine164()), index(W, S.NewsLine170())
  check("aus 1.4: vier Zeilen in der Reihenfolge", a and b and c and e and a < b and b < c and c < e,
    tostring(a) .. " " .. tostring(b) .. " " .. tostring(c) .. " " .. tostring(e))
end
do -- in combat: waits for the end of the fight
  local d = db({ news164 = true, news160 = true, news150 = true, news140 = true })
  local W = J.world("deDE", { db = d })
  W.AM.inCombat, W.BM.combat = true, true
  W.tick(60)
  check("news170: nichts im Kampf", count(W, W.ns.Start.NewsLine170()) == 0 and d.settings.news170 == nil)
  W.combat(false)
  check("news170: nach dem Kampf", count(W, W.ns.Start.NewsLine170()) == 1)
end
do -- a new installation: no line, every marker at once
  local W = J.world("deDE", { db = nil, whole = true })
  W.tick(4)
  local st = _G.DeathNoteDB.settings
  check("neu: alle Merker sofort", st.news170 == true and st.news164 == true and st.news160 == true and st.news150 == true)
  local dlg = W.frame("DeathNoteStart")
  if dlg and dlg.go then dlg.go._scripts.OnClick(dlg.go, "LeftButton") end
  W.tick(60)
  check("neu: keine Zeile", count(W, W.ns.Start.NewsLine170()) == 0)
end

J.done("cu170 news")
