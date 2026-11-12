-- DeathNote - Humor.lua (1.2.0)
-- Dry remarks, milestones, hidden commands and a few surprises.
--
-- German and English only (1.2.0): in every other language this file does nothing, no remark, no
-- stamp, no switch, no English fallback. That is why the texts are not in the language table (no duty
-- for the 19 translations) but here in the marked block HUMOR-TEXTE; the guard against hard-wired texts
-- (tests/test_locale_waechter.lua) skips exactly this block and checks the rest of the file like any other.
--
-- Rules: everything only on the own screen (notice, chat line), nothing goes over the wire, DeathNoteDB
-- holds only counters and markers (db.humor, language neutral). No OnUpdate, no ticker, nothing in the
-- hot path: work happens only on death, revenge, pardon, taken down, login, guild change, when the
-- empty book is built and on own clicks. Randomness only at the event (Humor.random).
-- Hook points in other files are marked with "-- Humor" (Core.lua, Extras.lua, UI.lua).

local _, ns = ...
local Humor = {}
ns.Humor = Humor
local Util = ns.Util
local Fmt = ns.F

-- >>> HUMOR-TEXTE (deDE and enUS only; exempt from the guard against hard-wired texts, see the head)
local GUILD_NAME = "Die Fachkräfte"
-- hidden commands: word -> kind (not in /dn help; the manual only says "The book has moods.")
local COMMANDS = {
  fachkraft = "guild", ["fachkräfte"] = "guild", fachkraefte = "guild",
  ["42"] = "answer",
  beichte = "confess", confess = "confess",
  danke = "thanks", thanks = "thanks",
}
local TEXTS = {
  deDE = {
    OPT = "Trockene Bemerkungen",
    MANUAL = "Erprobt von der Gilde Die Fachkräfte. Das Buch hat Launen.",   -- one line at the foot of the manual
    STAMP = { regular = "STAMMKUNDE", revenge1 = "ERSTE RACHE", nr1 = "STAATSFEIND ERLEDIGT", pro = "FACHGERECHT ERLEDIGT" },
    MILESTONE = {
      regular  = "Zehnmal derselbe Name. Dafür gibt es jetzt einen Stempel.",
      revenge1 = "Die erste vergisst man nie. Das Buch schon gar nicht.",
      nr1      = "Staatsfeind Nr. 1 liegt. Die Stelle ist ab sofort neu zu besetzen.",
      d100     = "Hundert Tode. Das Buch gratuliert nicht, aber es hat mitgezählt.",
      clean30  = "30 Tage ohne Tod. Das Buch macht sich langsam Sorgen.",
    },
    POOL = {
      regular = {
        "Das ist keine Begegnung mehr, das ist ein Termin.",
        "Ihr zwei solltet euch mal mit anderen treffen.",
        "Das Buch schlägt seine Seite inzwischen von allein auf.",
        "Bei ihm lohnt sich langsam eine Bonuskarte.",
        "Er kommt öfter als die Post.",
      },
      revenge = {
        "Quittung zugestellt.",
        "Ausgleich hergestellt. Vorläufig.",
        "Das Buch nickt anerkennend.",
        "Kurz war die Welt in Ordnung.",
      },
      lowbie = {
        "Das Buch schreibt seine Stufe extra klein.",
        "Wir reden nie wieder darüber.",
        "Stufen sind auch nur Zahlen. Offenbar.",
        "Das hat keiner gesehen. Das Buch auch nicht.",
      },
      night = {
        "Um diese Uhrzeit. Das Buch hätte geschlafen.",
        "Nachtschicht. Zuschläge gibt es keine.",
      },
      pve = {
        "Kein Fall für das Buch. Die Schwerkraft hat keine Seite.",
        "Kein Täter, kein Eintrag. Die Welt kommt wieder davon.",
        "Ein Monster. Das Buch führt keine Tierakten.",
        "Natürliche Ursachen. Im weitesten Sinn.",
      },
      bagged = {
        "Freigegeben, gejagt, erledigt. Bürokratie kann so schön sein.",
        "Abgehakt. Das Buch liebt Ordnung.",
        "Die Liste wird kürzer. Sie bleibt es nie lange.",
        "Irgendwo wird gerade ein Plakat abgehängt.",
      },
      pardon = {
        "Begnadigt. Das Buch vergibt, aber es radiert nicht.",
        "Großzügig. Das Buch hätte es nicht getan.",
        "Er wird nie erfahren, wie knapp es war.",
      },
      empty = {
        "Entweder sehr vorsichtig oder sehr neu.",
        "So sauber wird das Buch nie wieder.",
        "Die Seiten warten. Geduldig. Noch.",
        "Genieß es. Das bleibt nicht so.",
      },
    },
    -- only for members of the guild GUILD_NAME: extra variants
    MEMBER = {
      revenge = { "Gelernt ist gelernt.", "Saubere Arbeit. Fachkräfte-Standard." },
      bagged  = { "Fachkräfte am Werk. Bitte nicht stören.", "Ausgeführt von Fachkräften. Mangel herrscht keiner." },
    },
    CMD = {
      guild = {
        "Die Fachkräfte haben dieses Buch erprobt. Gründlich. Meistens am Boden liegend.",
        "Fachkräftemangel? Nicht bei den Fachkräften. Nur in der Reparaturkasse.",
      },
      guild_member = {
        "Ausweis geprüft: Fachkraft. Das Buch nimmt Haltung an.",
        "Willkommen zurück, Fachkraft. Die Stechuhr läuft.",
      },
      answer = "42. Richtig, nur die falsche Frage. Die richtige lautet: Wer war das?",
      confess = "Beichte: {deaths} {deaths|Tod|Tode}, {killers} Täter, {revenge}× Rache. Das Buch urteilt nicht. Es zählt nur.",
      thanks = "Gern geschehen. Das Buch nimmt kein Trinkgeld, nur Namen.",
    },
    PIN = "Die Reißzwecke hat gekündigt. Das Plakat hält sich aus Trotz.",
    APRIL_SUB = "Gesucht wegen wiederholten Sterbens.",
    APRIL_HINT = "Kopfgeld: die nächste Reparaturrechnung.",
  },
  enUS = {
    OPT = "Dry remarks",
    MANUAL = "Field-tested by the guild Die Fachkräfte. The book has moods.",
    STAMP = { regular = "LOYAL CUSTOMER", revenge1 = "FIRST PAYBACK", nr1 = "PUBLIC ENEMY DOWN", pro = "PROFESSIONALLY DONE" },
    MILESTONE = {
      regular  = "Ten times, one name. That earns a stamp.",
      revenge1 = "You never forget your first. The book certainly won't.",
      nr1      = "Public Enemy No. 1 is down. The position is now open, applications welcome.",
      d100     = "One hundred deaths. The book won't congratulate you, but it did keep count.",
      clean30  = "30 days without dying. The book is starting to worry.",
    },
    POOL = {
      regular = {
        "At this point it's not an encounter, it's an appointment.",
        "You two should really see other people.",
        "The book now falls open at their page by itself.",
        "Loyalty card: one more stamp and the next death is free.",
        "The ink for this name is running low.",
      },
      revenge = {
        "Paid in full. Interest pending.",
        "Balance restored. For now.",
        "For one brief moment, the world made sense.",
        "The book nods. Slowly.",
      },
      lowbie = {
        "The book will write their level very, very small.",
        "We never speak of this again.",
        "Levels are just numbers. Apparently.",
        "Nobody saw that. The book included.",
      },
      night = {
        "At this hour. Even the book was asleep.",
        "Night shift. No overtime pay.",
      },
      pve = {
        "Not a case for the book. Gravity doesn't get a page.",
        "No killer, no entry. The world gets away with it again.",
        "A monster. The book does not keep files on wildlife.",
        "Natural causes. Broadly speaking.",
      },
      bagged = {
        "Called, hunted, done. Paperwork has never been this satisfying.",
        "Checked off. The book loves a tidy list.",
        "The list gets shorter. It never stays that way.",
        "Somewhere, a poster is coming down.",
      },
      pardon = {
        "Pardoned. The book forgives, but it writes in ink.",
        "Generous. The book would not have done it.",
        "They will never know how close it was.",
      },
      empty = {
        "Either very careful or very new.",
        "The book will never be this clean again.",
        "The pages are waiting. Patiently. For now.",
        "Enjoy it. It won't last.",
      },
    },
    MEMBER = {
      revenge = { "Skilled labour, as advertised.", "Textbook. Die Fachkräfte would sign off on that." },
      bagged  = { "Die Fachkräfte at work. Do not disturb.", "Handled by professionals. No shortage here." },
    },
    CMD = {
      guild = {
        "Die Fachkräfte tested this book. Thoroughly. Mostly face down.",
        "Skilled labour shortage? Not in Die Fachkräfte. Only in the repair budget.",
      },
      guild_member = {
        "ID checked: certified Fachkraft. The book stands up straight.",
        "Welcome back, Fachkraft. You're clocked in.",
      },
      answer = "42. Correct, just the wrong question. The right one is: who did this?",
      confess = "Confession: {deaths} {deaths|death|deaths}, {killers} {killers|killer|killers}, payback {revenge}×. The book doesn't judge. It just counts.",
      thanks = "You're welcome. The book takes no tips. Only names.",
    },
    PIN = "The pin has quit. The poster stays up out of spite.",
    APRIL_SUB = "Wanted for repeated dying.",
    APRIL_HINT = "Bounty: your next repair bill.",
  },
}
-- <<< HUMOR-TEXTE
Humor.TEXTS = TEXTS
Humor.GUILD_NAME = GUILD_NAME
Humor.COMMANDS = COMMANDS

-- How often (0..1). Fixed occasions (milestones, 5th/10th/20th/50th/100th death by the same one) always come.
-- 1.2.0: rarer (before: revenge 0.5, level 0.6, night 0.4, taken down 0.5, pardon 0.5, empty book 0.5) and
-- at most one random remark per QUIET seconds across all occasions; the 3rd death is no occasion any more
Humor.CHANCE = { revenge = 0.2, lowbie = 0.2, night = 0.15, pve = 0.25, bagged = 0.15, pardon = 0.2, empty = 0.2 }
Humor.QUIET = 600
local REGULAR_AT = { [5] = true, [10] = true, [20] = true, [50] = true, [100] = true }
local LOWBIE_GAP = 10              -- killer at least this many levels below you
local CLEAN_DAYS = 30
local EMPTY_HOLD = 30              -- seconds: the remark of the empty book stays while you look at it
local PENDING_MAX_AGE = 120        -- seconds: waiting notice (taken down, in the queue)
-- Stamp: empty frame (Media/stamp_<frame>_blank.tga), angle as in the image, ink
local STAMP_FRAME = {
  regular  = { "rache",   7,   { 0.69, 0.04, 0.04 } },   -- 1.2.0: red like the others (dark was invisible on black)
  revenge1 = { "rache",   9,   { 0.69, 0.04, 0.04 } },
  nr1      = { "nr1",     -11, { 0.69, 0.04, 0.04 } },
  pro      = { "hunt",    8,   { 0.69, 0.04, 0.04 } },
}
Humor.STAMP_FRAME = STAMP_FRAME

-- Globals only through this door: normal in the client, nil in a strict environment without the name
local GLOBALS = {
  date = function() return date end, time = function() return time end, GetTime = function() return GetTime end,
  GetGuildInfo = function() return GetGuildInfo end, UnitName = function() return UnitName end,
  C_Timer = function() return C_Timer end,
}
local function global(name)
  local ok, v = pcall(GLOBALS[name])
  if ok then return v end
end

-- Randomness (tests set a fixed seed or replace the function)
Humor.random = math.random
-- Clock (tests replace it): table as from date("*t") or nil
function Humor.Clock()
  local d = global("date")
  if type(d) ~= "function" then return nil end
  local ok, t = pcall(d, "*t")
  if ok and type(t) == "table" then return t end
end

------------------------------------------------------------------------
-- State
------------------------------------------------------------------------
local member = false     -- guild name is exactly GUILD_NAME (checked once at login and on guild change)
local last = {}          -- pot -> index drawn last (never the same one twice in a row)
local cur                -- which notice is up right now: { kind, key, banner }
local pending = {}       -- kind .. key -> { d = decision, at = GetTime() }
local emptyPick          -- { text, at }

local function T()
  local code = ns.Locale and ns.Locale.code
  return code and TEXTS[code] or nil
end

-- German and English only
function Humor.Active() return T() ~= nil end
local Active = Humor.Active

local function Store() return ns.Store end

-- Switch "Dry remarks" (house rules, sheet Book), on by default
function Humor.On()
  if not Active() then return false end
  local S = Store()
  if not (S and S.Setting) then return true end
  return S.Setting("humor") ~= false
end
local On = Humor.On

function Humor.IsMember() return member end

local function now() return Util.Num(Util.Call(global("time"))) or 0 end
local function clock() return Util.Num(Util.Call(global("GetTime"))) or 0 end

local function finite(v) return type(v) == "number" and v == v and v > -math.huge and v < math.huge end
local Mem
-- Lock: at most one random remark per QUIET seconds. Set only when a remark is really shown;
-- the time is in db.humor.quietAt (world time) and survives /reload.
local quietUntil = 0
local function Quiet()
  if clock() < quietUntil then return true end
  local db = Store() and Store().DB and Store().DB()
  local q = type(db) == "table" and type(db.humor) == "table" and db.humor.quietAt
  local t = now()
  return finite(q) and t >= q and t - q < (Humor.QUIET or 0)
end
local function Hush()
  quietUntil = clock() + (Humor.QUIET or 0)
  local h = Mem and Mem()
  if h then h.quietAt = now() end
end

local function Roll(kind)
  local p = Humor.CHANCE[kind] or 0
  if p <= 0 then return false end
  if Quiet() then return false end
  return p >= 1 or Humor.random() < p
end

-- one line from the pot (members: plus their own variants), never the same one twice in a row
local function Pick(pool)
  local t = T()
  if not t then return nil end
  local list = t.POOL[pool] or t.CMD[pool]
  if type(list) == "string" then return list end
  if member and t.MEMBER[pool] then
    local both = {}
    for i = 1, #list do both[i] = list[i] end
    for _, v in ipairs(t.MEMBER[pool]) do both[#both + 1] = v end
    list = both
  end
  local n = #list
  if n == 0 then return nil end
  local i = Humor.random(n)
  if n > 1 and i == last[pool] then i = i % n + 1 end
  last[pool] = i
  return list[i]
end
Humor.Pick = Pick

local function Say(text)
  if type(text) ~= "string" or text == "" then return end
  if Util and Util.Print then Util.Print("|cffa89878" .. text .. "|r") end
  Humor.said = text      -- for tests: the last line
end

-- Markers in DeathNoteDB.humor: milestones (time), total deaths, last death. Matched with the book on every
-- call (counter db.tally and journal): after a time in another language, under 1.1.0 or after importing a
-- book they are right again; broken values are replaced. Filled in on the first run, so that a book from
-- 1.1.0 does not celebrate a "first revenge" that happened long ago.
Mem = function(ignoreNewest)
  local S = Store()
  local db = S and S.DB and S.DB()
  if type(db) ~= "table" then return nil end
  local h = db.humor
  local fresh = type(h) ~= "table"
  if fresh then h = {}; db.humor = h end
  if type(h.m) ~= "table" then h.m = {} end
  local deaths = type(db.deaths) == "table" and db.deaths or {}
  local tl = S.Tally and S.Tally()
  local n = tl and finite(tl.n) and tl.n or #deaths
  if ignoreNewest then n = n - 1 end      -- the death being counted right now
  if not finite(h.deaths) or h.deaths < n then h.deaths = n end
  h.deaths = math.floor(h.deaths)
  local newest = deaths[1]
  local last = tl and finite(tl.last) and tl.last or (type(newest) == "table" and Util.Num(newest.t)) or nil
  if not finite(h.lastDeath) then h.lastDeath = nil end
  if finite(last) and (not h.lastDeath or last > h.lastDeath) then h.lastDeath = last end
  if h.quietAt ~= nil and not finite(h.quietAt) then h.quietAt = nil end
  if fresh then
    if #deaths >= 100 then h.m.d100 = 0 end
    for _, e in pairs(S.All and S.All() or {}) do
      if type(e) == "table" and (tonumber(e.revenge) or 0) > 0 then h.m.revenge1 = 0; break end
    end
  end
  return h
end
Humor.Mem = Mem

------------------------------------------------------------------------
-- Notice (Extras.lua): remark under the strip, surprise stamp
------------------------------------------------------------------------
local FIT_QUIP = { sizes = { 11, 10 } }
local FIT_STAMP = { sizes = { 13, 11, 9 }, lines = 2, wrapFirst = true }   -- as Extras.FIT_STAMP (fallback)
local function QuipStrip(banner)
  if banner.dnQuip then return banner.dnQuip end
  local Look = ns.Look
  local q = CreateFrame("Frame", nil, banner)
  q:SetSize(440, 22)
  q:SetPoint("TOP", banner, "BOTTOM", 0, -4)
  local bg = q:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  bg:SetColorTexture(0.06, 0.05, 0.05, 0.85)
  q.text = Look.Text(q, "body", 11, Look.BONE)
  q.text:SetPoint("CENTER", 0, 0)
  q.text:SetWidth(430)
  q.text:SetWordWrap(false)
  q:Hide()
  banner.dnQuip = q
  return q
end

local function Apply(banner, d)
  local Look = ns.Look
  if not (banner and Look and d) then return false end
  if d.quip then
    local q = QuipStrip(banner)
    Look.FitText(q.text, d.quip, FIT_QUIP)   -- 1.2.2: 11 pt, else 10 pt (a quip was 1 to 2 px too wide)
    q:Show()
    if d.hush then Hush() end
  end
  local f = d.stamp and STAMP_FRAME[d.stamp]
  local t = T()
  if f and t and banner.stamp then
    Look.Tex(banner.stamp, Look.MEDIA .. "stamp_" .. f[1] .. "_blank.tga", 0.6, 0.1, 0.1, 0.5)
    banner.stamp:Show()
    if banner.stampAnim then banner.stampAnim:Stop(); banner.stampAnim:Play() end
    local fs = banner.stampText
    if fs then
      -- 1.2.2: the same ladder as the regular stamp of the notice (13, 11, 9 pt on up to two lines), through
      -- Look.FitText: the field was fitted for the regular stamp word just before, plain SetText kept that state
      Look.FitText(fs, t.STAMP[d.stamp], ns.Extras and ns.Extras.FIT_STAMP or FIT_STAMP)
      fs:SetTextColor(f[3][1], f[3][2], f[3][3], 0.95)
      if fs.SetRotation then pcall(fs.SetRotation, fs, math.rad(-f[2])) end
      fs:Show()
      if banner.stampTextAnim then banner.stampTextAnim:Stop(); banner.stampTextAnim:Play() end
    end
    if banner.name then banner.name:ClearAllPoints(); banner.name:SetPoint("TOP", -24, -26) end
  end
  Humor.applied = d       -- for tests
  return true
end

-- Hook point in Extras.lua (end of Banner): every new notice clears the old remark; if a decision is
-- already waiting for exactly this notice (taken down, from the queue), it comes now.
-- stamp: kind of notice ("rache", "hunt", "nr1" or nil), guild: notice about others
function Humor.OnBanner(banner, stamp, key, guild)
  if not banner then return end
  if banner.dnQuip then banner.dnQuip:Hide() end
  cur = nil
  if not Active() or type(key) ~= "string" then return end
  local kind = (stamp == "rache" and "revenge") or (stamp == "hunt" and "bagged") or (not guild and "death") or nil
  if not kind then return end
  cur = { kind = kind, key = key, banner = banner }
  local p = pending[kind .. key]
  if p then
    pending[kind .. key] = nil
    if clock() - p.at <= PENDING_MAX_AGE then Apply(banner, p.d) end
  end
end

-- Deliver a decision: if the matching notice is up, at once; taken down may be stuck in the queue
-- (waits); a milestone without a notice (notices off) comes as a chat line
local function Deliver(kind, key, d)
  local b = cur and cur.banner
  if cur and cur.kind == kind and cur.key == key and b and b:IsShown() then
    Apply(b, d)
  elseif kind == "bagged" and ns.Extras then
    pending[kind .. key] = { d = d, at = clock() }
  elseif d.milestone then
    Say(d.quip)
  end
end

------------------------------------------------------------------------
-- Occasions
------------------------------------------------------------------------
local function DeathQuip(e, death, h)
  local k = tonumber(e.kills) or 0
  local t = T()
  if k == 10 and not h.m.regular then
    h.m.regular = now()
    return { stamp = "regular", quip = t.MILESTONE.regular, milestone = true }
  end
  if REGULAR_AT[k] then return { quip = Pick("regular"), hush = true } end
  local my, their = Util.Num(death.myLevel), Util.Num(e.level)
  if my and their and their > 0 and my - their >= LOWBIE_GAP and Roll("lowbie") then
    return { quip = Pick("lowbie"), hush = true }
  end
  local c = Humor.Clock()
  local hour = c and Util.Num(c.hour)
  if hour and hour >= 2 and hour < 5 and Roll("night") then return { quip = Pick("night"), hush = true } end
end

function Humor.OnDeath(death, key)
  if not Active() or type(death) ~= "table" then return end
  local S0 = Store()
  -- the death is already in db.tally (Store.RecordDeath): match without it, then count
  local h = Mem(S0 and S0.Tally ~= nil)
  if not h then return end
  h.deaths = h.deaths + 1
  h.lastDeath = now()
  if not On() then return end
  local S = Store()
  if death.kind == "pvp" and type(key) == "string" then
    local e = S.Get(key)
    if e and death.sure ~= false and e.status ~= "suspect" then
      local d = DeathQuip(e, death, h)
      if d then Deliver("death", key, d) end
    end
  elseif death.kind ~= "pvp" and death.counted and not key and Roll("pve") then
    Say(Pick("pve"))
    Hush()
  end
  if h.deaths >= 100 and not h.m.d100 then
    h.m.d100 = now()
    Say(T().MILESTONE.d100)
  end
end

function Humor.OnRevenge(key)
  if not On() or type(key) ~= "string" then return end
  local h, S = Mem(), Store()
  local e = h and S.Get(key)
  if not e then return end
  local t, d = T(), nil
  -- revenge that was already in the book (other computer, other language, imported): no "first" any more
  if not h.m.revenge1 then
    local earlier = (tonumber(e.revenge) or 0) > 1
    if not earlier then
      for k2, o in pairs(S.All and S.All() or {}) do
        if k2 ~= key and type(o) == "table" and (tonumber(o.revenge) or 0) > 0 then earlier = true; break end
      end
    end
    if earlier then h.m.revenge1 = 0 end
  end
  if S.Rank(key) == 1 and not h.m.nr1 then
    h.m.nr1 = now()
    h.m.revenge1 = h.m.revenge1 or h.m.nr1     -- if it was the first revenge, no further "first" comes
    d = { stamp = "nr1", quip = t.MILESTONE.nr1, milestone = true }
  elseif not h.m.revenge1 then
    h.m.revenge1 = now()
    d = { stamp = "revenge1", quip = t.MILESTONE.revenge1, milestone = true }
  elseif Roll("revenge") then
    d = { quip = Pick("revenge"), hush = true }
  end
  if d then Deliver("revenge", key, d) end
end

function Humor.OnStatus(key, old, new)
  if new ~= "pardoned" or old == "pardoned" or not On() then return end
  if Roll("pardon") then Say(Pick("pardon")); Hush() end
end

function Humor.OnBagged(key, char, t, src)
  if not On() or type(key) ~= "string" or Util.IsSecret(key) then return end
  local Look, X = ns.Look, ns.Extras
  if Look and Look.GuildSetting and Look.GuildSetting("announceHunt") == false then return end
  -- own kill: if the REVENGE notice for the same player is up, it stays without an extra; the own
  -- taken-down notice gets stamp and remark like a guildmate's
  if src == "self" and X and X.BannerShows and X.BannerShows(key) and not (cur and cur.kind == "bagged" and cur.key == key) then
    return
  end
  local d = {}
  if member then d.stamp = "pro" end
  if Roll("bagged") then d.quip = Pick("bagged"); d.hush = true end
  if d.stamp or d.quip then Deliver("bagged", key, d) end
end

-- After importing a book (Store.Import): milestones that the imported book has reached already or would
-- reach with the next death count as reached and do not fire any more
function Humor.OnImport()
  if not Active() then return end
  local h, S = Mem(), Store()
  if not (h and S) then return end
  for _, e in pairs(S.All and S.All() or {}) do
    if type(e) == "table" then
      if (tonumber(e.revenge) or 0) > 0 then h.m.revenge1 = h.m.revenge1 or 0; h.m.nr1 = h.m.nr1 or 0 end
      if (tonumber(e.kills) or 0) >= 9 then h.m.regular = h.m.regular or 0 end
    end
  end
  if h.deaths >= 99 then h.m.d100 = h.m.d100 or 0 end
end

-- Guild: once at login and on every guild change; a secret or no guild = no member
function Humor.CheckGuild()
  if not Active() then member = false; return false end
  local g = Util.Str(Util.Call(global("GetGuildInfo"), "player"))   -- Str checks for a secret first
  member = g ~= nil and g == GUILD_NAME
  return member
end

function Humor.OnReady()
  Humor.CheckGuild()
  if not On() then return end
  local h = Mem()
  if not (h and h.lastDeath) or h.m.clean30 then return end
  if now() - h.lastDeath < CLEAN_DAYS * 86400 then return end
  local line = T().MILESTONE.clean30
  -- the marker comes only with the line (a /reload before it does not make the milestone vanish)
  local function show()
    local h2 = Mem()
    if not h2 or h2.m.clean30 then return end
    h2.m.clean30 = now()
    Say(line)
  end
  local timer = global("C_Timer")
  local After = type(timer) == "table" and timer.After
  if After then After(12, show) else show() end
end

------------------------------------------------------------------------
-- Hidden commands (hook point Core.lua, only for otherwise unknown commands; changes no data)
------------------------------------------------------------------------
function Humor.Slash(cmd)
  if not Active() or type(cmd) ~= "string" or Util.IsSecret(cmd) then return false end
  -- string.lower knows ASCII only: upper-case umlauts by hand
  local c = cmd:lower():gsub("\195\132", "\195\164"):gsub("\195\150", "\195\182"):gsub("\195\156", "\195\188")
  local what = COMMANDS[c]
  if not what then return false end
  local t = T()
  if what == "guild" then
    Humor.CheckGuild()
    Say(Pick(member and "guild_member" or "guild"))
  elseif what == "confess" then
    local S = Store()
    local h = Mem()
    local killers, revenge = 0, 0
    for _, e in pairs(S and S.All and S.All() or {}) do
      if type(e) == "table" then
        if e.status == "wanted" then killers = killers + 1 end
        revenge = revenge + (tonumber(e.revenge) or 0)
      end
    end
    Say(Fmt(t.CMD.confess, { deaths = h and h.deaths or 0, killers = killers, revenge = revenge }))
  else
    Say(t.CMD[what])
  end
  return true
end

------------------------------------------------------------------------
-- Book (UI.lua): switch, empty book, 1 April, thumbtack
------------------------------------------------------------------------
-- House rules, sheet Book: the switch is added in German and English only
function Humor.BookOptions(list)
  local t = T()
  if not t then return list end
  local out = {}
  for i = 1, #list do out[i] = list[i] end
  out[#out + 1] = { "humor", "HUMOR_OPT", true, text = t.OPT }
  return out
end

local function April1()
  local c = Humor.Clock()
  return c ~= nil and c.month == 4 and c.day == 1
end
Humor.April1 = April1

-- empty page "Wanted" (X = RP.empty with big, small, tiny): on 1 April the own poster, else sometimes
-- another sentence; it stays while you look at it (the page is rebuilt every few seconds)
function Humor.EmptyWanted(X)
  if not (X and On()) then return end
  local t = T()
  if April1() then
    local me = Util.Str(Util.Call(global("UnitName"), "player"))
    if me then
      X.big:SetText(me)
      X.small:SetText(t.APRIL_SUB)
      X.tiny:SetText(t.APRIL_HINT)
      return
    end
  end
  local at = clock()
  if not emptyPick or at - emptyPick.at > EMPTY_HOLD then
    emptyPick = { text = Roll("empty") and Pick("empty") or nil }
    if emptyPick.text then Hush() end
  end
  emptyPick.at = at
  if emptyPick.text then X.small:SetText(emptyPick.text) end
end

-- Poster: click the thumbtack five times, then it falls and pins itself back (animations as shown in
-- ForeverAuras/BlizzardAuraDisplay.lua:1825-1828; own clicks only, no OnUpdate)
local function Anim(group, kind, order, dur, set)
  local a = group:CreateAnimation(kind)
  if set then set(a) end
  a:SetOrder(order); a:SetDuration(dur)
  return a
end

function Humor.Pin(P, pin)
  if not (P and pin) or not Active() or P.dnPin then return end
  local b = CreateFrame("Button", nil, P)
  b:SetSize(28, 28)
  b:SetPoint("CENTER", pin, "CENTER", 0, 0)
  P.dnPin = b
  local function deg(d) return function(a)
    if a.SetDegrees then a:SetDegrees(d) end
    if a.SetOrigin then a:SetOrigin("TOP", 0, 0) end
  end end
  local wobble = pin:CreateAnimationGroup()
  Anim(wobble, "Rotation", 1, 0.07, deg(18))
  Anim(wobble, "Rotation", 2, 0.12, deg(-30))
  Anim(wobble, "Rotation", 3, 0.07, deg(12))
  local fall = pin:CreateAnimationGroup()
  Anim(fall, "Rotation", 1, 0.5, deg(150))
  Anim(fall, "Translation", 1, 0.5, function(a) if a.SetOffset then a:SetOffset(14, -70) end end)
  local fade = Anim(fall, "Alpha", 1, 0.5, function(a) a:SetFromAlpha(1); a:SetToAlpha(0) end)
  fade:SetStartDelay(0)
  -- hangs itself back up: after a pause, back with a thud
  local back = Anim(fall, "Alpha", 2, 0.08, function(a) a:SetFromAlpha(0); a:SetToAlpha(1) end)
  back:SetStartDelay(1.2)
  if ns.Look and ns.Look.ScaleAnim then ns.Look.ScaleAnim(fall, 1.8, 1, 0.12, 2) end
  b.wobble, b.fall, b.clicks, b.at = wobble, fall, 0, 0
  b:SetScript("OnClick", function(self)
    if self.fall:IsPlaying() or not pin:IsShown() then return end   -- clicks during the fall do not count
    local tnow = clock()
    if tnow - self.at > 2 then self.clicks = 0 end
    self.at = tnow
    self.clicks = self.clicks + 1
    if self.clicks >= 5 then
      self.clicks = 0
      self.wobble:Stop()
      self.fall:Play()
      Say(T().PIN)
    else
      self.wobble:Stop(); self.wobble:Play()
    end
  end)
end

------------------------------------------------------------------------
-- Manual: one line at the foot (GUILD_NAME, "The book has moods."), de/en only (1.2.0: a paragraph before)
------------------------------------------------------------------------
if ns.Locale and ns.Locale.OnActivate then
  ns.Locale.OnActivate(function()
    -- Memory: only the texts of the active language stay (none in the 19 other languages); the language
    -- changes only with /reload, then the file is loaded anew
    local code = ns.Locale.code
    for c in pairs(TEXTS) do if c ~= code then TEXTS[c] = nil end end
    local t = T()
    if t and ns.UI then ns.UI.HELP_FOOT = t.MANUAL end
  end)
end

ns:On("READY", Humor.OnReady)
ns:On("DEATH_RECORDED", Humor.OnDeath)
ns:On("REVENGE", Humor.OnRevenge)
ns:On("ENEMY_STATUS", Humor.OnStatus)
ns:On("HUNT_BAGGED", Humor.OnBagged)
ns:On("BOOK_IMPORTED", function() if Humor.OnImport then Humor.OnImport() end end)
ns:RegisterEvent("PLAYER_GUILD_UPDATE", function() Humor.CheckGuild() end)
