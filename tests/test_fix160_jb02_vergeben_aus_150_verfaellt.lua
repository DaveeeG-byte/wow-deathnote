-- Copy of the bug hunter's test (fixer 2 1.6.0), red on b55addb.
-- Jagd 2 Fehler 02: Der Fix zu jl06 (e.statusHand haelt einen von Hand gesetzten Stand) greift nur fuer Staende, die
-- ab 1.6.0 gesetzt werden. Ein Buch aus 1.5.0 (und aelter) kennt die Marke nicht: ein Verdacht, den der Spieler dort
-- vergeben ("pardoned") oder von Hand auf "gesucht" gesetzt hat, traegt keinen statusHand und wird nach 30 Spieltagen
-- mit 1.6.0 still abgelegt. Kommt derselbe Spieler danach wieder (neuer Verdacht), ist er ein frischer Eintrag
-- "suspect": die Vergebung ist weg. "pardoned" kann nur von Hand entstehen, die Marke waere also ableitbar.
-- Das Buch unten ist gebaut, wie 1.5.0 es schreibt: Store.ApplyKill + Store.SetStatus, ohne statusHand, ohne day.
-- Lauf: cd ~/Projects/wow-deathnote-jagd && luajit <diese Datei> .   (Exit 1 = Fund belegt)
local DIR = ((arg and arg[1]) or "."):gsub("/+$", "")
arg[0] = DIR .. "/tests/jagd2_bug_02.lua"
package.path = DIR .. "/tests/?.lua;" .. package.path
local M = require("mock_wow")
local test, ok, eq = M.test, M.ok, M.eq

local function copy(t) if type(t) ~= "table" then return t end local c = {} for k, v in pairs(t) do c[k] = copy(v) end return c end

-- ein Buch im Zustand von 1.5.0: Verdacht, dann von Hand vergeben bzw. auf gesucht gesetzt
local function book150(status)
  local ns = M.Load()
  local S = ns.Store
  S.ApplyKill({ name = "Alt", surname = "Ling", guid = "Player-93-Alt" }, { t = time() - 50, zone = "Z" }, false)
  S.SetStatus("Alt-Ling", status)
  local db = copy(S.DB())
  local e = db.enemies["Alt-Ling"]
  e.statusHand, e.day = nil, nil            -- 1.5.0 schreibt beides nicht
  db.days, db.dayAt, db.expired, db.feuds, db.claims = nil, nil, nil, nil, nil
  return db
end

for _, status in ipairs({ "pardoned", "wanted" }) do
  test("JB02: Verdacht in 1.5.0 von Hand auf '" .. status .. "', 31 Spieltage mit 1.6.0", function()
    local db = book150(status)
    local ns = M.Load({ db = db })
    local S = ns.Store
    ok(S.Get("Alt-Ling") and S.Get("Alt-Ling").status == status, "erster Login: da, Stand " .. status)
    for _ = 1, 31 do M.epoch = M.epoch + 86400; S.Init() end
    local filed = S.DB().expired and S.DB().expired["Alt-Ling"] ~= nil
    ok(S.Get("Alt-Ling"), "nach 31 Spieltagen noch im Buch (abgelegt: " .. tostring(filed) .. ")")
  end)
end

test("JB02 Folge: der Vergebene kommt als frischer Verdacht wieder", function()
  local ns = M.Load({ db = book150("pardoned") })
  local S = ns.Store
  for _ = 1, 31 do M.epoch = M.epoch + 86400; S.Init() end
  S.ApplyKill({ name = "Alt", surname = "Ling", guid = "Player-93-Alt" }, { t = time(), zone = "Z" }, false)
  local e = S.Get("Alt-Ling")
  eq(e and e.status, "pardoned", "Stand nach dem naechsten Verdacht")
end)

M.done("jb02 vergeben aus 1.5.0")
