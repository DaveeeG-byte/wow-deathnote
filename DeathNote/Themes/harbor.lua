-- DeathNote theme "harbor": the Privateer's Ledger. A privateer's log book: sailcloth cover in deep sea blue,
-- brass, sea chart paper, oxblood stamps with cut corners, a dagger in the poster, brass nails instead of tape.
-- Pure data. Every value left out comes from the base theme "notebook" (fonts, tones, the shared textures).
-- Fields: see the schema in Theme.lua. Words: Locales\Themes\harbor.lua.
local _, ns = ...
if not (ns.Theme and ns.Theme.Register) then return end

ns.Theme.Register("harbor", {
  order = 2,
  nameKey = "THEME_HARBOR",
  -- Palette: night blue ink, oxblood as the accent on paper, brass on the cover
  color = {
    ink           = "#101a24",
    accent        = "#8e1420",
    accentSmall   = "#7c0f1a",
    accentOnCover = "#e3bd62",     -- brass
    onCover       = "#efe6cf",
    tabOff        = "#aab4ba",
    hint          = "#9aa6ac",
    btnFill       = "#0e1a22f0",
    btnEdge       = "#8a6a2c",     -- also the edge of the menus
    btnEdgeHot    = "#e3bd62",
    menuFill      = "#0b151cf7",
    rule          = "#33566a",     -- lines of the left page: sea chart blue
    frameEdge     = "#05090c",
    fold          = "#05090cd9",
    quipFill      = "#0b141ad9",
    edgeIdle      = "#8a6a2c",
    edgeHot       = "#e3bd62",
    edgeNr1       = "#c0242c",
    mugTint       = "#d9d6c4",
    skullTint     = "#22303a",
    skullFaint    = "#1a2630b3",
    coinTint      = "#b08a3ce6",
    stampInk      = "#8a1818",
    stampDark     = "#2e0808",     -- pardoned (the frame is grey 34 % under the same tint)
    stampDarker   = "#3f0b0b",     -- suspect (grey 46 %)
    stampCount    = "#7c0f1af2",
    tipLabel      = "#e3bd62",
    tipListed     = "#c06050",
  },
  tex = {
    cover   = "g_cover.tga",       -- grey kit cover, tinted to sailcloth blue
    mugshot = "g_cover.tga",       -- the same cloth, sand coloured: a sail behind the photo
    pin     = "harbor_dagger.tga",
    tape    = "harbor_nail.tga",   -- brass nails (tinted) where the black book has tape
  },
  -- tints (SetVertexColor multiplies): kit cover centre about 57 % grey, paper and page as in the black book
  tint = {
    cover   = "#253d4a",           -- mean #15232a
    mugshot = "#f6eccf",
    page    = "#eef2e4",           -- mean #cac4a8
    paper   = "#eef0dc",           -- mean #bab28d
    tape    = "#e3bd62",           -- brass
    stamp   = "#8a1818",           -- oxblood
  },
  stamp = {
    -- frames without text in every language (also German): the text comes from the theme's words
    blank = { nr1 = "harbor_stamp_nr1.tga", rache = "harbor_stamp_rache.tga", pardon = "harbor_stamp_pardon.tga",
              suspect = "harbor_stamp_suspect.tga", guild = "harbor_stamp_guild.tga", hunt = "harbor_stamp_hunt.tga" },
  },
  fallback = {
    cover       = "#15232aff",
    coverDark   = "#15232aff",
    mugshot     = "#8a8475ff",
    mugshotDark = "#4a4a44ff",
    pin         = "#8a6824ff",
    tape        = "#b08a3cff",
    stamp       = "#8a181880",
    stampNotice = "#8a181880",
  },
  sound = { alert = "glocke" },    -- ship's bell
  words = "harbor",
})
