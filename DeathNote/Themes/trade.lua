-- DeathNote theme "trade": The Workshop. The customer file of a trade business: hardboard clipboard, yellow carbon
-- paper, index card, ballpoint blue, stamp-pad red box stamps, a clipboard clamp instead of the thumbtack.
-- Pure data. Every value left out comes from the base theme "notebook" (tape, height chart, tones).
-- Fields: see the schema in Theme.lua. Words: Locales\Themes\trade.lua.
local _, ns = ...
if not (ns.Theme and ns.Theme.Register) then return end

ns.Theme.Register("trade", {
  order = 3,
  nameKey = "THEME_TRADE",
  -- Palette: ballpoint blue ink, stamp-pad red, warm brown board, amber on the cover
  color = {
    ink           = "#0e1628",     -- ballpoint blue, dark enough for the class ink on the notice slip
    accent        = "#a81c1c",
    accentSmall   = "#8a1414",
    accentOnCover = "#ffcf70",
    onCover       = "#f3ead6",
    tabOff        = "#d8cbb4",
    hint          = "#bfae92",
    btnFill       = "#1c1610f0",
    btnEdge       = "#8a6a48",     -- also the edge of the menus
    btnEdgeHot    = "#ffcf70",
    menuFill      = "#17110cf7",
    rule          = "#3a5a9a",     -- blue form lines
    frameEdge     = "#0e0a06",
    fold          = "#0e0a06d9",
    quipFill      = "#1a130dd9",
    edgeIdle      = "#8a6a48",
    edgeHot       = "#ffcf70",
    edgeNr1       = "#d83a2a",
    skullTint     = "#2a3038",
    skullFaint    = "#0e1628b3",
    coinTint      = "#9a7a3ae6",
    stampInk      = "#a81c1c",
    stampDark     = "#390a0a",     -- pardoned (the frame is grey 34 % under the same tint)
    stampDarker   = "#4d0d0d",     -- suspect (grey 46 %)
    stampCount    = "#8a1414f2",
    tipLabel      = "#ffcf70",
    tipListed     = "#c86048",
  },
  tex = {
    cover = "g_cover.tga",         -- grey kit cover, tinted to hardboard brown
    pin   = "trade_clamp.tga",
  },
  tint = {
    cover = "#775b3f",             -- mean #443424
    page  = "#f6f0c0",             -- mean #d0c38d, yellow carbon paper
    paper = "#f8f3e6",             -- mean #c2b594, index card
    stamp = "#a81c1c",
    slip  = "#fffadc",             -- the notice slip: light carbon yellow (the page tint is too dark for class ink)
  },
  stamp = {
    -- frames without text in every language (also German): the text comes from the theme's words
    blank = { nr1 = "trade_stamp_nr1.tga", rache = "trade_stamp_rache.tga", pardon = "trade_stamp_pardon.tga",
              suspect = "trade_stamp_suspect.tga", guild = "trade_stamp_guild.tga", hunt = "trade_stamp_hunt.tga" },
  },
  fallback = {
    cover       = "#443424ff",
    coverDark   = "#443424ff",
    pin         = "#8d9499ff",
    stamp       = "#a81c1c80",
    stampNotice = "#a81c1c80",
  },
  -- headings in Nimrod (form print); names stay in the hand of the black book: Friz Quadrata for names (concept)
  -- also widens the hand-written input fields (release reason without a tooltip: a finding of the layout hunt)
  font = { head = "type" },
  sound = { alert = "glocke" },    -- shop door bell
  words = "trade",
})
