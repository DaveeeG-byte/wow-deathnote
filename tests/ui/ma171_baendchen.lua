-- 1.7.1 fixer 2 (JN-1): the red ribbon of the guild chronicle does not stand while a sheet lies open on the right page
-- of the fourth tab (Put on hit list, Copy all, House Rules, Back up book, Import book, the manual), neither right
-- after opening it nor after the way back from the manual ("?" and "?" again, or "Back" in the contents). Before,
-- the ribbon came back over Put on hit list after the way back, and stood over Copy all right after opening it; a
-- click laid the chronicle over the open sheet. Closing the sheet brings the ribbon back. One place decides
-- (GuildLogUI.Ribbon, called by UI.lua GF.SetPanel); the source check below holds that.
-- Names made up. Usage: luajit tests/ui/ma171_baendchen.lua <project>
local J = dofile((arg[0]:match("^(.*)/") or ".") .. "/_mv164.lua")
local check = J.check
local ROOT = (arg[1] or "."):gsub("/+$", "")

local function db()
  return { version = 5, settings = { welcomed = true, firstRun = "done", news171 = true, news170 = true, news164 = true,
    news160 = true, news150 = true, news140 = true }, enemies = {}, deaths = {} }
end
local function pagesOf(W)
  for _, f in ipairs(W.BM.frames) do if f.help and f.settings then return f end end
end

for _, code in ipairs({ "deDE", "enUS" }) do
  local W = J.world(code, { db = db() })
  local ns = W.ns
  local UI, st = ns.UI, ns.UI.JK.state
  local GL = ns.GuildLogUI
  ns:Fire("TOGGLE_UI"); W.tick(); W.settle()
  local F = W.frame("DeathNoteFrame")
  W.click(F.help); W.click(F.help)
  local RP = pagesOf(W)
  local Hp = RP.help
  local R = GL.Frames()
  local function tab(fid) for _, t in ipairs(F.tabs) do if t.id == fid then W.click(t); return end end end
  local key = ns.Store.AddManual("Grimwald", "Ashbrand")
  tab("guild"); W.tick(1)
  check(code .. " Vorbedingung: im vierten Reiter ohne Blatt steht das Baendchen", R and R:IsShown())

  local SHEETS = {
    { "release", function() UI.OpenRelease(key) end, function() return RP.release end },
    { "take", function() UI.OV.OpenTake() end, function() return RP.take end },
    { "settings", function() UI.OpenPanel("settings") end, function() return RP.settings end },
    { "export", function() UI.OpenIO("export") end, function() return RP.io end },
    { "import", function() UI.OpenIO("import") end, function() return RP.io end },
  }
  for _, s in ipairs(SHEETS) do
    local name, open, sheet = s[1], s[2], s[3]
    -- direct
    open(); W.tick(1)
    check(code .. " " .. name .. ": direkt geoeffnet, das Baendchen steht nicht", st.panel == name and sheet():IsShown()
      and not R:IsShown(), tostring(st.panel))
    -- by "?" and "?" again
    W.click(F.help); W.tick(1)
    check(code .. " " .. name .. ": Anleitung offen, das Baendchen steht nicht", Hp:IsShown() and not R:IsShown())
    W.click(F.help); W.tick(1)
    check(code .. " " .. name .. ": ? zurueck ins Blatt, das Baendchen steht nicht", st.panel == name and sheet():IsShown()
      and not R:IsShown(), tostring(st.panel))
    -- by "?", the contents and "Back"
    W.click(F.help); W.click(Hp.toc); W.click(Hp.back); W.tick(1)
    check(code .. " " .. name .. ": Inhalt > Zurueck ins Blatt, das Baendchen steht nicht", st.panel == name
      and sheet():IsShown() and not R:IsShown(), tostring(st.panel))
    -- a refresh of the book keeps it so
    UI.Refresh(); W.tick(1); W.settle()
    check(code .. " " .. name .. ": nach dem Auffrischen steht das Baendchen nicht", not R:IsShown())
    UI.ClosePanel(); W.tick(1)
    check(code .. " " .. name .. ": Blatt zu, das Baendchen steht wieder", st.panel == nil and R:IsShown())
  end
  -- the manual alone, from the fourth tab
  W.click(F.help); W.tick(1)
  check(code .. " Anleitung aus dem vierten Reiter: das Baendchen steht nicht", Hp:IsShown() and not R:IsShown())
  W.click(F.help); W.tick(1)
  check(code .. " Anleitung zu: das Baendchen steht wieder", not Hp:IsShown() and R:IsShown())
  -- outside the fourth tab it never stands
  tab("wanted"); W.tick(1)
  check(code .. " Gesucht: kein Baendchen", not R:IsShown())
  UI.OpenRelease(key); W.tick(1); W.click(F.help); W.click(F.help); W.tick(1)
  check(code .. " Gesucht, Freigeben ueber ? und zurueck: kein Baendchen", st.panel == "release" and not R:IsShown())
  UI.ClosePanel(); W.tick(1)
  check(code .. " Gesucht, Blatt zu: kein Baendchen", not R:IsShown())
end

-- one place decides: the ribbon is shown or hidden only in GuildLogUI.Ribbon, and UI.lua sets its open sheet only
-- through GF.SetPanel
local function read(p) local h = assert(io.open(ROOT .. "/DeathNote/" .. p, "r")); local s = h:read("*a"); h:close(); return s end
local gl, ui = read("GuildLogUI.lua"), read("UI.lua")
local rib = select(2, gl:gsub("%f[%w_]R:SetShown%(", "")) + select(2, gl:gsub("%f[%w_]R:Show%(", ""))
  + select(2, gl:gsub("%f[%w_]R:Hide%(", ""))
check("eine Stelle: GuildLogUI zeigt oder versteckt das Baendchen genau einmal", rib == 1, rib)
check("eine Stelle: in GLUI.Ribbon", gl:find("function GLUI.Ribbon%(panel%)\n  if R then R:SetShown%(") ~= nil)
local direct = select(2, ui:gsub("state%.panel = ", ""))
check("UI.lua setzt state.panel nur in GF.SetPanel", direct == 1 and ui:find("function GF.SetPanel%(p%)\n  state.panel = p\n") ~= nil, direct)
J.done("ma171 baendchen")
