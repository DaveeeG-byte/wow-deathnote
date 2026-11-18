-- Design fixer 1.6.0 (design hunt 5, 6): red means guilt, danger, the selection's underline; the rest is ink.
-- A word to click in a row (Declare feud, Take back, Take over) is ink with a line under it; the chronicle's section
-- heads (day heads, avengers, most wanted) and the own avenger row are ink; an older version of a guildmate is no error
-- (faint ink, one line under the list counts them), the list starts closer to its head. Names made up.
local WT = arg[1] or "."
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_ju160.lua")
local function red(fs) local c = fs and fs._tc; return c ~= nil and c[1] > 0.45 and c[2] < 0.25 end
for _, code in ipairs({ "deDE", "enUS" }) do
  local W = J.world(WT, code, { guild = "Die Rostigen Naegel" })
  local ns, L, F = W.ns, W.ns.L, W.ns.F
  local AM, P = W.AM, ns.Guild.Proto
  AM.Advance(30)
  local function send(text, from) AM.FireEvent("CHAT_MSG_ADDON", "DeathNote", assert(text), "GUILD", from .. "-Forever") end
  send(P.EncodeHello(time() - 200, "1.2.0"), "Bertram"); AM.Advance(0.2)
  send(P.EncodeHello(time() - 200, "1.2.0"), "Liora"); AM.Advance(0.2)
  send(P.EncodeKill({ key = ns.Util.KeyFor("Grimm", "Aschgrau"), display = "Grimm Aschgrau", class = "ROGUE", level = 60,
    zone = "Schlingendorntal", t = time() - 3600, victim = "Liora Testfeld" }, "R"), "Liora")
  W.tick(3)
  W.open(); W.tab("guild"); W.settle()
  -- every row's click word: ink, underlined
  local takes, redTakes, lines = 0, 0, 0
  for _, f in ipairs(W.BM.frames) do
    if f.take and f.take.text then
      takes = takes + 1
      if red(f.take.text) then redTakes = redTakes + 1 end
      if f.take.line then lines = lines + 1 end
    end
  end
  J.check(code .. ": Wort-Knoepfe in Tinte", takes > 0 and redTakes == 0, redTakes .. "/" .. takes)
  J.check(code .. ": Wort-Knoepfe unterstrichen", takes > 0 and lines == takes, lines .. "/" .. takes)
  local GLUI = ns.GuildLogUI
  GLUI.Open("holders"); W.settle()
  local olds, redOld = 0, 0
  for _, f in ipairs(W.BM.frames) do
    if f._kind == "FontString" and f:IsVisible() and type(f._text) == "string"
      and f._text == F(L.GLOG_VERSION_OLD, { version = "1.2.0" }) then
      olds = olds + 1
      if red(f) then redOld = redOld + 1 end
    end
  end
  J.check(code .. ": aeltere Fassung nicht rot", olds == 2 and redOld == 0, redOld .. "/" .. olds)
  J.check(code .. ": eine Zeile zaehlt die aelteren", W.visible(F(L.GLOG_OLD_N, { count = 2 })) ~= nil)
  local dayHead = W.visible(L.GLOG_TODAY)
  J.check(code .. ": Tageskopf in Tinte", dayHead and not red(dayHead))
  GLUI.Open("avengers"); W.settle()
  local JK = ns.UI.JK
  local h1, h2 = W.visible(JK.Spaced(L.GLOG_AV_HEAD)), W.visible(JK.Spaced(L.GLOG_WANTED_HEAD))
  J.check(code .. ": Abschnittskoepfe gesperrt in Tinte", h1 and h2 and not red(h1) and not red(h2))
  local own
  for _, f in ipairs(W.BM.frames) do
    if f._kind == "FontString" and f:IsVisible() and type(f._text) == "string" and f._text:find(F(L.GLOG_ME, { name = "" }):gsub("%s*$", ""), 1, true) then own = f end
  end
  J.check(code .. ": eigene Raecher-Zeile in Tinte", own == nil or not red(own), own and own._text)
  J.check(code .. ": keine Addon-Fehler", #W.AM.errors == 0, W.AM.errors[1])
end
J.done()
