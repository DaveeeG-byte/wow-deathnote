-- 1.6.0 feud: the page in the game's options (Settings.RegisterCanvasLayoutCategory, as OpenMap does it): title, one
-- line, "Open House Rules"; without that API nothing happens and nothing breaks. The switch "File away old suspicions"
-- on the sheet Book. Edit boxes take the fonts of the script being typed (OnTextChanged), not only on SetText.
-- Names made up.
local WT = arg[1] or "."
local X = dofile((arg[0]:match("^(.*)/") or ".") .. "/_fe160.lua")
local J = X.J
local CYR = "\208\147\209\128\208\184\208\188\208\188"

-- with the Settings API
do
  local reg = {}
  local W = X.world(WT, "deDE", nil, nil)
  -- the API is looked up at READY: set it, then start once more like a /reload
  rawset(W.G, "Settings", {
    RegisterCanvasLayoutCategory = function(panel, name) reg.panel, reg.name = panel, name; return { name = name } end,
    RegisterAddOnCategory = function(cat) reg.cat = cat end,
  })
  rawset(W.G, "SettingsPanel", W.BM.G.CreateFrame("Frame", nil, W.G.UIParent))
  rawset(W.G, "HideUIPanel", function(f) f:Hide(); reg.hidden = true end)
  W.ns.FeudUI.optionsPanel = nil
  W.ns:Fire("READY")
  local L = W.L
  J.check("Seite angemeldet", reg.cat ~= nil and reg.name == L.BOOK_TITLE, reg.name)
  local texts = {}
  for _, f in ipairs(W.BM.frames) do
    local o = f
    while o do if o == reg.panel then texts[#texts + 1] = f._text or (f.text and f.text._text) end; o = o._parent end
  end
  local all = table.concat(texts, "|")
  J.check("Titel, Zeile, Knopf", all:find(L.BOOK_TITLE, 1, true) and all:find(L.OPTIONS_LINE, 1, true)
    and W.ns.FeudUI.optionsButton.label._text == L.OPTIONS_OPEN, all)
  W.G.SettingsPanel:Show()
  W.ns.FeudUI.optionsButton._scripts.OnClick(W.ns.FeudUI.optionsButton)
  W.tick(); W.settle()
  local F, LP, RP = W.frames()
  J.check("Knopf: Optionen zu, Buch auf, Hausordnung offen", reg.hidden and F and F:IsShown() and RP.settings
    and RP.settings:IsVisible())
  -- the switch on the sheet Book
  local cb
  for _, f in ipairs(W.BM.frames) do
    if f.opt and f.opt.path == "book.expire" then cb = f end
  end
  J.check("Schalter auf dem Blatt Buch, an", cb ~= nil and cb:IsVisible() and cb.label._text == L.OPT_BOOK_EXPIRE)
  cb:SetChecked(false); cb._scripts.OnClick(cb)
  J.check("aus geschaltet", W.ns.Store.Setting("book.expire") == false and not W.ns.Feud.ExpireOn())
  local ok, err = W.errors()
  J.check("keine Fehler", ok, err)
end

-- without the Settings API (an older client): nothing registered, no error
do
  local W = X.world(WT, "deDE")
  J.check("ohne Settings-API: keine Seite, kein Fehler", W.ns.FeudUI.optionsPanel == nil and select(1, W.errors()))
end

-- typing in another script
do
  local W = X.world(WT, "deDE")
  W.open()
  local _, LP = W.frames()
  local sb = LP.search
  local latin = sb._font
  -- the player types (no SetText of the addon): the client changes the text and fires OnTextChanged
  sb._text = CYR
  sb._scripts.OnTextChanged(sb, true)
  local want = W.ns.Locale.FontList(W.ns.Look.FONT_KIND.hand or "hand", nil, "cyrillic")[1]
  J.check("Suche: getippter kyrillischer Name in kyrillischer Schrift", sb._font == want, tostring(sb._font))
  sb._text = "Grimm"
  sb._scripts.OnTextChanged(sb, true)
  J.check("Suche: zurueck zur eigenen Schrift", sb._font == latin, tostring(sb._font))
  -- the note on the poster
  W.kill("Grimm", "Bart", nil, time() - 50); W.tick(); W.settle()
  local _, _, _, P = W.frames()
  local note = P.enemy.note
  note._text = CYR
  note._scripts.OnTextChanged(note, true)
  J.check("Notiz: kyrillisch", note._font == want, tostring(note._font))
  local ok, err = W.errors()
  J.check("keine Fehler", ok, err)
end

J.done()
