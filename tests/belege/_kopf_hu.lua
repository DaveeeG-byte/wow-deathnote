-- Gemeinsamer Kopf der Humor-Belege (Abschlussjagd). Aufruf je Datei:
--   nice -n 15 luajit <datei> <Projektkopie>
-- Nutzt tests/mock_wow.lua und tests/ui/mock.lua der angegebenen Kopie. Alle Namen sind erfunden.
-- Geprueft werden Daten, Merker und der Vergleich mit den Tabellen aus Humor.lua, keine Wortlaute.
local DIR = assert(arg and arg[1], "Aufruf: luajit <datei> <Projektkopie>"):gsub("/+$", "")
-- mock_wow.lua leitet den Addon-Ordner aus arg[0] ab ("<x>/tests/...")
arg[0] = DIR .. "/tests/ui/beleg.lua"
package.path = DIR .. "/tests/?.lua;" .. DIR .. "/tests/ui/?.lua;" .. package.path
local ADDON = DIR .. "/DeathNote"

local H = { DIR = DIR, ADDON = ADDON, rot = 0, gruen = 0 }

function H.check(name, cond, detail)
  if cond then H.gruen = H.gruen + 1
  else H.rot = H.rot + 1; print("rot   " .. name .. (detail ~= nil and ("  -> " .. tostring(detail)) or "")) end
end

-- beide Texttabellen aus dem markierten Block der Datei (zur Laufzeit bleibt nur die aktive Sprache)
H.SRC = (function()
  local h = assert(io.open(ADDON .. "/Humor.lua", "rb"))
  local s = h:read("*a"); h:close()
  return assert(loadstring("return " .. assert(s:match("local TEXTS = (%b{})"))))()
end)()

-- alle Texte des Blocks als Menge (Text -> Pfad), fuer "ist das ein Humor-Text?"
function H.alleTexte(code)
  local out = {}
  local function walk(t, path)
    for k, v in pairs(t) do
      if type(v) == "table" then walk(v, path .. "." .. tostring(k))
      elseif type(v) == "string" then out[v] = path .. "." .. tostring(k) end
    end
  end
  if code then walk(H.SRC[code], code) else for c, t in pairs(H.SRC) do walk(t, c) end end
  return out
end

-- frische Welt mit Oberflaeche. opts: db, guild (Text oder Funktion), date (Tabelle oder Funktion),
-- chance (Zahl fuer alle Anlaesse, Standard 1), quiet (Standard 0), before(G), keep (Sperre/Chancen lassen),
-- epoch (Kalenderzeit dieser Sitzung; jede Welt beginnt sonst wieder bei 1700000000), vorLogin(ns)
function H.welt(code, opts)
  opts = opts or {}
  package.loaded.mock_wow, package.loaded.mock = nil, nil
  local AM = require("mock_wow")
  local BM = require("mock")
  BM.mediaDir = ADDON .. "/Media"
  local G = BM.G
  AM.locale = code
  H.AM, H.BM, H.G = AM, BM, G
  if opts.guild ~= nil then
    local g = opts.guild
    rawset(G, "GetGuildInfo", type(g) == "function" and g or function(u) if u == "player" then return g end end)
  end
  if opts.date then
    local d = opts.date
    rawset(G, "date", type(d) == "function" and d or function(f, t) if f == "*t" then return d end return os.date(f, t) end)
  end
  -- eine Uhr fuer beide Mocks: time() = AM.epoch + AM.now (der UI-Mock liefert sonst eine feste Zahl)
  rawset(G, "time", function() return math.floor(AM.epoch + AM.now) end)
  local ns = AM.Load({ noLogin = true, db = opts.db, before = function()
    AM.units.player.guild = "Die Probegilde"
    if opts.epoch then AM.epoch = opts.epoch end
    if opts.before then opts.before(G, AM, BM) end
  end })
  for _, f in ipairs({ "Alert.lua", "UI.lua", "Extras.lua", "Humor.lua" }) do
    local fh = io.open(ADDON .. "/" .. f, "r")
    if fh then fh:close(); BM.Load(ADDON .. "/" .. f, ns) end
  end
  if opts.vorLogin then opts.vorLogin(ns) end
  AM.FireEvent("PLAYER_LOGIN")
  AM.FireEvent("PLAYER_ENTERING_WORLD")
  if ns.Humor and not opts.keep then
    for k in pairs(ns.Humor.CHANCE) do ns.Humor.CHANCE[k] = opts.chance or 1 end
    ns.Humor.QUIET = opts.quiet or 0
  end
  H.ns = ns
  return ns
end

-- Kalenderzeit vorstellen (Rechner war aus): nur die Uhr, nicht die Sitzungszeit
function H.tage(n) H.AM.epoch = H.AM.epoch + n * 86400 end
function H.settle() H.AM.Advance(0.1); H.BM.Advance(0.1) end
function H.vor(sec) H.AM.Advance(sec); H.BM.Advance(sec) end
function H.banner() return rawget(H.G, "DeathNoteBanner") end
function H.away() H.BM.Advance(6); H.BM.FinishAnims(); H.BM.Advance(1); H.AM.Advance(7); H.settle() end
function H.quip()
  local b = H.banner()
  return b and b.dnQuip and b.dnQuip:IsVisible() and b.dnQuip.text:GetText() or nil
end
function H.stampText() local b = H.banner(); return b and b.stampText:IsShown() and b.stampText:GetText() or nil end

-- ein Tod durch einen erfundenen Taeter (wie Attribution.finalize: Tat, Journal, Ereignis)
function H.kill(ns, name, surname, o)
  o = o or {}
  local S = ns.Store
  local key = S.ApplyKill({ name = name, surname = surname, guid = "Player-93-" .. name, class = "ROGUE", level = o.level or 40 },
    { t = _G.time(), zone = "Z", myLevel = 40, theirLevel = o.level or 40 }, true)
  local j = { t = _G.time(), kind = "pvp", sure = true, counted = true, killerKey = key, myLevel = 40, candidates = {} }
  S.RecordDeath(j)
  ns:Fire("DEATH_RECORDED", j, key)
  H.settle()
  return key
end

-- ein Tod ohne Taeter (Sturz, Monster) in der offenen Welt
function H.sturz(ns)
  local j = { t = _G.time(), kind = "pve", sure = false, counted = true, myLevel = 40, candidates = {} }
  ns.Store.RecordDeath(j)
  ns:Fire("DEATH_RECORDED", j, nil)
  H.settle()
end

function H.humorChat()
  local n = 0
  for _, l in ipairs(H.AM.chat) do if l:find("|cffa89878", 1, true) then n = n + 1 end end
  return n
end

function H.tiefe_kopie(t, seen)
  if type(t) ~= "table" then return t end
  seen = seen or {}
  if seen[t] then return seen[t] end
  local c = {}
  seen[t] = c
  for k, v in pairs(t) do c[H.tiefe_kopie(k, seen)] = H.tiefe_kopie(v, seen) end
  return c
end

function H.gleich(a, b, path, out)
  path, out = path or "db", out or {}
  if type(a) ~= type(b) then out[#out + 1] = path; return out end
  if type(a) ~= "table" then
    if a ~= b and not (a ~= a and b ~= b) then out[#out + 1] = path end
    return out
  end
  for k, v in pairs(a) do H.gleich(v, b[k], path .. "." .. tostring(k), out) end
  for k in pairs(b) do if a[k] == nil then out[#out + 1] = path .. "." .. tostring(k) end end
  return out
end

-- Rechteck eines Frames in UIParent-Einheiten: l, b, r, t
function H.rect(f) return H.BM.RectUI(f) end

function H.ende(name)
  print(string.format("%s: %d gruen, %d rot", name, H.gruen, H.rot))
  os.exit(H.rot == 0 and 0 or 1)
end

return H
