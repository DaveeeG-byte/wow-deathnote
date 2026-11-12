-- DeathNote theme "notebook": the black book (the look of 1.2.2, every value as it was). Pure data.
-- The base theme: every other theme falls back to these values. Fields: see the schema in Theme.lua.
local _, ns = ...
if not (ns.Theme and ns.Theme.Register) then return end

ns.Theme.Register("notebook", {
  order = 1,
  nameKey = "THEME_NOTEBOOK",
  -- Palette: black, bone white, ink black, blood red as the only accent
  color = {
    ink           = { 0.08, 0.07, 0.07 },
    accent        = { 0.72, 0.04, 0.04 },
    accentSmall   = { 0.55, 0.03, 0.03 },
    accentOnCover = { 1.0, 0.40, 0.33 },
    onCover       = { 0.93, 0.90, 0.82 },
    faded         = { 0.38, 0.35, 0.31 },
    black         = { 0.05, 0.045, 0.045 },
    tabOff        = { 0.62, 0.59, 0.54 },
    warn          = { 1.0, 0.62, 0.18 },
    hint          = { 0.62, 0.58, 0.52 },
    btnFill       = { 0.07, 0.06, 0.06, 0.94 },
    btnEdge       = { 0.45, 0.04, 0.04, 1 },
    btnEdgeHot    = { 0.95, 0.1, 0.08, 1 },
    menuFill      = { 0.05, 0.045, 0.045, 0.97 },
    boxFill       = { 0.93, 0.90, 0.82, 1 },
    editFill      = { 1, 0.98, 0.92, 0.5 },
    rule          = { 0.25, 0.27, 0.33 },
    frameEdge     = { 0.02, 0.02, 0.02, 1 },
    fold          = { 0, 0, 0, 0.85 },
    shadow        = { 0, 0, 0 },
    titleShadow   = { 0, 0, 0, 1 },
    tabFill       = { 1, 1, 1, 0.05 },
    tabHi         = { 1, 1, 1, 0.06 },
    quipFill      = { 0.06, 0.05, 0.05, 0.85 },
    edgeIdle      = { 0.55, 0.03, 0.03 },
    edgeHot       = { 0.95, 0.10, 0.08 },
    edgeNr1       = { 0.90, 0.12, 0.10 },
    mugTint       = { 0.85, 0.80, 0.70, 1 },
    skullTint     = { 0.25, 0.22, 0.2, 1 },
    skullFaint    = { 0.2, 0.18, 0.16, 0.7 },
    coinTint      = { 0.55, 0.45, 0.25, 0.9 },
    classUnknown  = { 0.85, 0.85, 0.85 },
    classOther    = { 0.75, 0.75, 0.75 },
    stampInk      = { 0.69, 0.04, 0.04 },      -- #b00a0a
    stampDark     = { 0.12, 0.106, 0.098 },    -- #1e1b19
    stampDarker   = { 0.18, 0.165, 0.153 },    -- #2e2a27
    stampCount    = { 0.56, 0.04, 0.04, 0.95 },
    tipLabel      = "#e03020",
    tipText       = "#d8c8a8",
    tipListed     = "#b05040",
    tipNote       = "#a89878",
  },
  -- files in Media\ or client paths
  tex = {
    paper   = "paper.tga",      -- wanted poster
    page    = "page.tga",       -- notebook page
    cover   = "cover.tga",      -- black leather cover
    ink     = "ink.tga",        -- quill stroke
    mugshot = "mugshot.tga",
    edge    = "edge.tga",
    check   = "check.tga",
    pin     = "pin.tga",
    skull   = "skull.tga",
    tape    = "tape.tga",
    tri     = "tri.tga",        -- triangle open/closed (guild by guildmate)
    border  = "Interface\\Tooltips\\UI-Tooltip-Border",
    coin    = "Interface\\MoneyFrame\\UI-GoldIcon",    -- coin on a killer with a bounty
    gear    = "Interface\\Buttons\\UI-OptionsButton",  -- house rules button
  },
  tint = {},                    -- the black book's textures carry their own colours
  stamp = {
    -- German: the pictures with burnt-in text (as 1.1.0); every other language the frame plus the text
    baked = { nr1 = "stamp_nr1.tga", rache = "stamp_rache.tga", pardon = "stamp_pardon.tga",
              suspect = "stamp_suspect.tga", guild = "stamp_guild.tga", hunt = "stamp_hunt.tga" },
    blank = { nr1 = "stamp_nr1_blank.tga", rache = "stamp_rache_blank.tga", pardon = "stamp_pardon_blank.tga",
              suspect = "stamp_suspect_blank.tga", guild = "stamp_guild_blank.tga", hunt = "stamp_hunt_blank.tga" },
  },
  fallback = {
    paper       = { 0.85, 0.80, 0.70, 1 },
    page        = { 0.85, 0.80, 0.70, 1 },
    cover       = { 0.85, 0.80, 0.70, 1 },
    coverDark   = { 0.06, 0.05, 0.05, 1 },     -- popup and notice
    ink         = { 0.1, 0.1, 0.1, 1 },
    inkRed      = { 0.6, 0.05, 0.05, 1 },      -- stroke under the name in the popup
    mugshot     = { 0.75, 0.73, 0.69, 1 },
    mugshotDark = { 0.45, 0.44, 0.42, 1 },     -- popup
    edge        = { 1, 0, 0, 0.25 },
    check       = { 0.1, 0.1, 0.1, 1 },
    pin         = { 0.7, 0.05, 0.05, 1 },
    skull       = { 0.2, 0.2, 0.2, 1 },
    tape        = { 0.9, 0.86, 0.7, 0.6 },
    tri         = { 0.1, 0.1, 0.1, 1 },
    gear        = { 0.8, 0.75, 0.65, 1 },
    stamp       = { 0.7, 0.05, 0.05, 0.5 },
    stampNotice = { 0.6, 0.1, 0.1, 0.5 },
    white       = { 0.93, 0.90, 0.82, 1 },     -- inside of a check box
    classes     = { 0.3, 0.3, 0.3, 1 },
    icon        = { 0.5, 0.05, 0.05, 1 },
  },
  -- role -> kind in Locale.FONTS: title Skurri, head and hand Morpheus, body Friz Quadrata, type Nimrod
  font = { title = "title", head = "hand", hand = "hand", body = "body", type = "type" },
  -- Ink on paper: opacity per role. Measured against page and poster (contrast guard in tests/ui):
  -- every role for small text keeps 4.5:1, "hand" and "off" are for text of 16 pt and up only.
  tone = { ink = 1, label = 0.85, sub = 0.8, hint = 0.8, hand = 0.7, off = 0.5 },
  sound = { alert = "warnung" },     -- suggested alarm sound (a key of Look.SOUNDS)
  -- no words: the black book is the base (Locales\xxXX.lua)
})
