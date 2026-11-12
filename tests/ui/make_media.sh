#!/usr/bin/env bash
# Rebuilds DeathNote's own textures (ImageMagick 7, `magick`).
# Output: <addon folder>/Media/*.tga (DeathNote/, or the old Staatsfeind/), 32-bit RGBA, uncompressed, edges a power of two.
# Deterministic (fixed seeds). Usage: tests/ui/make_media.sh [all|base|kit|harbor|trade]
#   all (default) = everything; base = the black book's files; kit = the shared grey parts of the themes (g_*.tga);
#   harbor, trade = the kit plus the files of that theme only (<id>_*.tga). The header check runs over every file.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
ADIR="$ROOT/DeathNote"; [ -d "$ADIR" ] || ADIR="$ROOT/Staatsfeind"
OUT="$ADIR/Media"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$OUT"

# Fonts only for burning text into images (SIL OFL); in the game only the client's fonts are used.
STAMPFONT="/usr/share/fonts/noto/NotoSans-Black.ttf"
SERIFFONT="/usr/share/fonts/noto/NotoSerif-Black.ttf"
SYMFONT="/usr/share/fonts/TTF/Symbola.ttf"
for f in "$STAMPFONT" "$SERIFFONT" "$SYMFONT"; do
  [ -f "$f" ] || { echo "Font missing: $f" >&2; exit 1; }
done

# 32-bit RGBA, uncompressed, classic origin bottom left (descriptor 0x08).
# ImageMagick only sets the flag with -orient, so flip the image ourselves first.
tga() { magick "$1" -alpha set -flip -orient BottomLeft -type TrueColorAlpha -depth 8 -compress None "$2"; }

# Note: always convert grayscale intermediate images back with -colorspace sRGB, otherwise
# ImageMagick tints the result gray. Always set -compose over after copy_opacity.

WHAT="${1:-all}"

# The black book (base theme "notebook") and the parts every theme shares (ink, check, edge, skull, icon, triangle)
base_media() {
# 1) Paper 512x512: bone white instead of western orange (centre #ebe3cc, edge #c2b493), cloudy, grain,
#    mild vignette, two foxing spots at 15 % opacity. Overview: lighter than 1.1.0 (#ddd3b8/#a89a7c),
#    so small text on the poster keeps 4.5:1 contrast (measured in a still rendered from the code)
magick -seed 11 -size 512x512 plasma:fractal -blur 0x6 -colorspace gray -auto-level +level 88%,100% \
  -seed 12 -attenuate 0.30 +noise Gaussian -colorspace gray -blur 0x0.4 -colorspace sRGB \
  \( -size 512x512 radial-gradient:'#ebe3cc'-'#c2b493' -fx 'p' \) -compose multiply -composite \
  \( -size 512x512 xc:none -fill 'rgba(120,88,40,0.15)' -draw 'ellipse 382,128 26,21 0,360' \
     -draw 'ellipse 112,408 17,15 0,360' -blur 0x5 \) -compose over -composite \
  \( -size 512x512 xc:white -fill none -stroke '#a08f6c' -strokewidth 10 -draw 'rectangle 0,0 511,511' -blur 0x7 \) \
  -compose multiply -composite -alpha off \
  "$TMP/paper.png"
tga "$TMP/paper.png" "$OUT/paper.tga"

# 2) Cover 256x256: black leather (grain, light embossing, wear at the edges)
magick -seed 21 -size 256x256 xc:gray50 -attenuate 2.0 +noise Gaussian -colorspace gray -blur 0x1.1 \
  -shade 120x45 -auto-level -level 30%,75% -colorspace sRGB \
  \( -size 256x256 xc:'#1b1918' \) -compose multiply -composite \
  \( -size 256x256 radial-gradient:white-black -fx '0.85+0.3*u' -colorspace sRGB \) -compose multiply -composite \
  -level 0%,70% "$TMP/cover.png"
tga "$TMP/cover.png" "$OUT/cover.tga"

# 3) Notebook page 256x512: bone white, slightly yellowed, darker towards the fold (right).
#    The addon draws the ruled lines itself so they sit exactly under the rows.
magick -seed 23 -size 256x512 plasma:fractal -blur 0x8 -colorspace gray -auto-level +level 88%,100% \
  -seed 24 -attenuate 0.25 +noise Gaussian -colorspace gray -blur 0x0.4 -colorspace sRGB \
  \( -size 256x512 xc:'#f3ecdc' \) -compose multiply -composite \
  \( -size 512x256 gradient:white-'#c9b896' -rotate 90 -fx 'pow(u,0.35)' -colorspace sRGB \) -compose multiply -composite \
  \( -size 256x512 xc:white -fill none -stroke '#8a7a5a' -strokewidth 8 -draw 'rectangle 0,0 255,511' -blur 0x6 \) \
  -compose multiply -composite \
  "$TMP/page.png"
tga "$TMP/page.png" "$OUT/page.tga"

# 4) Ink stroke 256x16: slightly wavy quill stroke (underline, strike-through)
magick -size 256x16 xc:none -stroke black -strokewidth 2.6 -fill none \
  -draw "path 'M 3,9 C 50,6 90,11 140,8 S 220,6 252,9'" -strokewidth 1.2 \
  -draw "path 'M 10,10 C 60,8 120,12 180,9 S 230,8 248,10'" -blur 0x0.5 "$TMP/ink.png"
tga "$TMP/ink.png" "$OUT/ink.tga"

# Stamp helper: rubber stamp in a bold serif font with a double frame (outer 10 px, inner 3 px, gap 8 px,
# corners 14 px), wear as a noise mask, rotated at an angle. Drawn at 512x256, saved at 256x128
# (shown at most 150x75 at scale 1.5 = 225 px; saves 2 MB).
# $1 output, $2 angle, $3 colour, $4 seed, $5.. lines (text|point size)
stamp() {
  local out="$1" ang="$2" col="$3" seed="$4"; shift 4
  local x0=46 y0=44 x1=465 y1=211
  local n=$# i=0 line txt size y
  local args=() total=0
  for line in "$@"; do size="${line##*|}"; total=$((total + size)); done
  # lines spread vertically around the centre by font size
  local acc=$(( -total / 2 ))
  for line in "$@"; do
    txt="${line%%|*}"; size="${line##*|}"
    y=$(( acc + size / 2 + 2 ))
    args+=( -pointsize "$size" -annotate +0+"$y" "$txt" )
    acc=$((acc + size))
    i=$((i+1))
  done
  magick -size 512x256 xc:none -fill none -stroke white -strokewidth 10 \
      -draw "roundrectangle $x0,$y0 $x1,$y1 14,14" -strokewidth 3 \
      -draw "roundrectangle $((x0+15)),$((y0+15)) $((x1-15)),$((y1-15)) 8,8" \
      -stroke none -fill white -font "$SERIFFONT" -gravity center "${args[@]}" \
      "$TMP/st_mask.png"
  # wear: noise, slightly blurred, everything above the threshold is punched out
  magick -seed "$seed" -size 512x256 xc:gray50 +noise Random -colorspace gray -blur 0x0.7 -auto-level \
      -threshold 82% -alpha copy "$TMP/st_holes.png"
  magick "$TMP/st_mask.png" "$TMP/st_holes.png" -compose DstOut -composite -blur 0x0.4 "$TMP/st_worn.png"
  magick -size 512x256 xc:"$col" \( "$TMP/st_worn.png" -alpha extract \) -alpha off -compose copy_opacity -composite \
      -channel A -evaluate multiply 0.94 +channel -compose over -background none \
      -virtual-pixel transparent -distort SRT "$ang" -resize 256x128 "$TMP/st_out.png"
  tga "$TMP/st_out.png" "$out"
}

# Stamps: blood red is the only accent colour, pardoned and suspect in ink black (German texts baked in)
stamp "$OUT/stamp_nr1.tga"     -11 '#b00a0a' 31 "STAATSFEIND|46" "Nr. 1|64"
stamp "$OUT/stamp_guild.tga"    -9 '#b00a0a' 71 "GILDENFEIND|46" "Nr. 1|64"
stamp "$OUT/stamp_rache.tga"     9 '#b00a0a' 41 "RACHE|64" "GENOMMEN|46"
stamp "$OUT/stamp_pardon.tga"   -6 '#1e1b19' 51 "BEGNADIGT|56"
stamp "$OUT/stamp_suspect.tga"   7 '#2e2a27' 61 "VERDACHT|60"
# 1.2.0: hit list
stamp "$OUT/stamp_hunt.tga"      8 '#b00a0a' 81 "ZUR JAGD|52" "FREIGEGEBEN|44"
# 1.2.0: the same stamps without text (same angle, colour, wear); the game puts the text from the language
# table on top (all languages except German, which keeps the images above)
stamp "$OUT/stamp_nr1_blank.tga"     -11 '#b00a0a' 31
stamp "$OUT/stamp_guild_blank.tga"    -9 '#b00a0a' 71
stamp "$OUT/stamp_rache_blank.tga"     9 '#b00a0a' 41
stamp "$OUT/stamp_pardon_blank.tga"   -6 '#1e1b19' 51
stamp "$OUT/stamp_suspect_blank.tga"   7 '#2e2a27' 61
stamp "$OUT/stamp_hunt_blank.tga"      8 '#b00a0a' 81

# Check mark for the boxes 32x32: hand-drawn cross (white, tinted ink black in the game)
magick -size 32x32 xc:none -fill none -stroke white -strokewidth 3.2 -draw "stroke-linecap round" \
  -draw "path 'M 6,7 C 12,12 19,19 26,26'" -strokewidth 2.6 \
  -draw "path 'M 25,6 C 20,12 13,19 7,27'" -blur 0x0.45 "$TMP/check.png"
tga "$TMP/check.png" "$OUT/check.tga"

# 7) Thumbtack 64x64: red head with highlight and shadow
magick -size 64x64 xc:none \
  -fill 'rgba(0,0,0,0.45)' -draw 'circle 36,38 36,55' -blur 0x3 \
  \( -size 64x64 xc:none -fill '#7a0d0d' -draw 'circle 31,30 31,47' \
     -fill '#c42222' -draw 'circle 30,29 30,44' \
     -fill '#e86a5a' -draw 'circle 25,23 25,29' \
     -fill 'rgba(255,255,255,0.8)' -draw 'circle 24,22 24,24' \) -compose over -composite \
  "$TMP/pin.png"
tga "$TMP/pin.png" "$OUT/pin.tga"

# 8) Red screen edge 256x256: transparent centre, red edges (stretched to full screen)
magick -size 256x256 xc:black -fill white -draw 'rectangle 22,22 233,233' -blur 0x20 -negate \
  -level 0%,85% "$TMP/edge_a.png"
magick -size 256x256 xc:'#ff1010' "$TMP/edge_a.png" -alpha off -compose copy_opacity -composite "$TMP/edge.png"
tga "$TMP/edge.png" "$OUT/edge.tga"

# 9) Mugshot background 128x128: police height chart (light wall, lines, numbers; light so stamps stay readable)
magick -size 128x128 xc:'#c4c0b6' \
  -stroke '#3d3a35' -strokewidth 1 \
  -draw 'line 0,16 127,16' -draw 'line 0,40 127,40' -draw 'line 0,64 127,64' \
  -draw 'line 0,88 127,88' -draw 'line 0,112 127,112' \
  -stroke '#5a5750' -draw 'line 0,28 10,28' -draw 'line 0,52 10,52' -draw 'line 0,76 10,76' -draw 'line 0,100 10,100' \
  -stroke none -fill '#2e2b27' -font "$STAMPFONT" -pointsize 8 \
  -annotate +114+14 '200' -annotate +114+38 '180' -annotate +114+62 '160' -annotate +114+86 '140' -annotate +114+110 '120' \
  \( -size 128x128 radial-gradient:white-'#9a958a' \) -compose multiply -composite \
  "$TMP/mug.png"
tga "$TMP/mug.png" "$OUT/mugshot.tga"

# 10) Skull 64x64 (glyph from Symbola), light with a dark outline, for the fallback photo and the journal
magick -size 64x64 xc:none -font "$SYMFONT" -pointsize 54 -gravity center \
  -fill '#1a1008' -stroke '#1a1008' -strokewidth 3 -annotate +0+2 $'☠' \
  -fill '#efe4c8' -stroke none -annotate +0+2 $'☠' "$TMP/skull.png"
tga "$TMP/skull.png" "$OUT/skull.tga"

# 11) Minimap icon 64x64: skull on a black circle with a blood red ring
magick -size 64x64 xc:none -fill '#8e0a0a' -draw 'circle 32,32 32,2' \
  -fill '#141212' -draw 'circle 32,32 32,6' \
  -font "$SYMFONT" -pointsize 40 -gravity center -fill '#f2e6c4' -annotate +0+1 $'☠' "$TMP/icon.png"
tga "$TMP/icon.png" "$OUT/icon.tga"

# 12) Tape 64x32: semi-transparent, frayed ends
magick -size 64x32 xc:white -fill black \
  -draw 'polygon 0,0 5,5 0,10 6,16 0,22 4,27 0,31' -draw 'polygon 63,0 58,6 63,12 57,18 63,24 59,28 63,31' \
  -evaluate multiply 0.7 "$TMP/tape_a.png"
magick -size 64x32 xc:'#f0e6c3' "$TMP/tape_a.png" -alpha off -compose copy_opacity -composite -compose over "$TMP/tape.png"
tga "$TMP/tape.png" "$OUT/tape.tga"

# 1.3.0) Notice slip 256x64: a strip torn out of the notebook page (bone white, grain, slightly darker rim),
#    ragged short ends that also fade out, top and bottom edge a little uneven. Shown stretched to 352x64 by
#    Extras.lua (on-screen notice, style "slip"); themes tint it like the paper.
magick -seed 91 -size 256x64 plasma:fractal -blur 0x4 -colorspace gray -auto-level +level 90%,100% \
  -seed 92 -attenuate 0.25 +noise Gaussian -colorspace gray -blur 0x0.4 -colorspace sRGB \
  \( -size 256x64 xc:'#f2ebdb' \) -compose multiply -composite \
  \( -size 256x64 xc:white -fill none -stroke '#b8ab92' -strokewidth 6 -draw 'rectangle 0,0 255,63' -blur 0x4 \) \
  -compose multiply -composite -alpha off "$TMP/slip_rgb.png"
magick -size 256x64 xc:black -fill white -draw "polygon \
  20,2 40,3 60,2 80,1 100,1 120,2 140,1 160,1 180,2 200,1 220,1 245,1 246,3 246,5 243,7 242,9 239,11 \
  237,13 239,15 245,17 243,19 244,21 245,23 242,25 241,27 240,29 239,31 243,33 243,35 242,37 243,39 \
  244,41 243,43 242,45 237,47 241,49 243,51 242,53 246,55 245,57 242,59 242,61 242,63 240,62 220,61 \
  200,61 180,62 160,60 140,62 120,60 100,62 80,61 60,61 40,60 20,62 13,63 14,61 18,59 16,57 13,55 \
  16,53 12,51 10,49 8,47 10,45 14,43 16,41 14,39 15,37 18,35 15,33 13,31 9,29 11,27 8,25 9,23 14,21 \
  13,19 18,17 14,15 13,13 13,11 10,9 13,7 10,5 10,3 12,1" -blur 0x0.8 \
  \( -size 64x256 gradient:black-white -rotate 90 -fx 'min(1,min(u*256/40,(1-u)*256/40))' \) \
  -compose multiply -composite -colorspace gray "$TMP/slip_a.png"
magick "$TMP/slip_rgb.png" "$TMP/slip_a.png" -alpha off -compose copy_opacity -composite -compose over "$TMP/slip.png"
tga "$TMP/slip.png" "$OUT/slip.tga"

for f in "$OUT"/*.tga; do magick identify -format '%f %wx%h %[channels] depth=%z compress=%C\n' "$f"; done
# 1.1.0) Triangle 32x32 for the sections of the "By guildmate" view: white (tinted in the game), points right;
#    when expanded the UI turns it 90 degrees to point down. Slightly irregular, as if drawn with a quill.
magick -size 32x32 xc:none -fill white -stroke white -strokewidth 1.6 -draw "stroke-linejoin round" \
  -draw "polygon 10,7 25,16.5 9.5,25" -blur 0x0.5 "$TMP/tri.png"
tga "$TMP/tri.png" "$OUT/tri.tga"
}

###########################################################################
# 1.3.0 themes. Shared kit files are g_*.tga, the files of one theme <id>_*.tga, all flat in Media\.
# Seed ranges: kit 100s, harbor 200s, trade 300s, so a new theme never changes an older picture.
# Paper and page are not repeated: a theme tints paper.tga and page.tga (SetVertexColor multiplies).
###########################################################################

# Stamp frame without text: white or grey (the theme tints it, Look.TINT.stamp), worn like the black book's stamps,
# already turned (the game turns only the text). Drawn at 512x256, saved at 256x128 with 16 alpha steps (a quarter
# of the size in the zip, not visible at 140x70); the inner frame keeps the text area of the black book (104 px).
# $1 output, $2 angle, $3 shape (box|cut), $4 seed, $5 grey in percent (100 = white; a darker grey gives the
# theme's dark stamps, pardoned and suspect, from the same tint)
frame() {
  local out="$1" ang="$2" shape="$3" seed="$4" grey="$5"
  local x0=46 y0=44 x1=465 y1=211 c=24 i=15
  if [ "$shape" = box ]; then
    # box stamp: one heavy square frame, one thin inner line
    magick -size 512x256 xc:none -fill none -stroke white -strokewidth 16 \
      -draw "rectangle $x0,$y0 $x1,$y1" -strokewidth 5 \
      -draw "rectangle $((x0+i)),$((y0+i)) $((x1-i)),$((y1-i))" "$TMP/fr_mask.png"
  else
    # cut corners: an octagon (ship's plate), double line
    magick -size 512x256 xc:none -fill none -stroke white -strokewidth 13 \
      -draw "polygon $((x0+c)),$y0 $((x1-c)),$y0 $x1,$((y0+c)) $x1,$((y1-c)) $((x1-c)),$y1 $((x0+c)),$y1 $x0,$((y1-c)) $x0,$((y0+c))" \
      -strokewidth 5 \
      -draw "polygon $((x0+c+6)),$((y0+i)) $((x1-c-6)),$((y0+i)) $((x1-i)),$((y0+c+6)) $((x1-i)),$((y1-c-6)) $((x1-c-6)),$((y1-i)) $((x0+c+6)),$((y1-i)) $((x0+i)),$((y1-c-6)) $((x0+i)),$((y0+c+6))" \
      "$TMP/fr_mask.png"
  fi
  magick -seed "$seed" -size 512x256 xc:gray50 +noise Random -colorspace gray -blur 0x0.7 -auto-level \
      -threshold 82% -alpha copy "$TMP/fr_holes.png"
  magick "$TMP/fr_mask.png" "$TMP/fr_holes.png" -compose DstOut -composite -blur 0x0.4 "$TMP/fr_worn.png"
  # turn and shrink the coverage only, then cut the faint fringe and keep 16 steps; the colour is one flat grey
  magick "$TMP/fr_worn.png" -alpha extract -background black -virtual-pixel black \
      -distort SRT "$ang" -resize 256x128 -level 6%,100% -posterize 16 -evaluate multiply 0.94 "$TMP/fr_alpha.png"
  magick -size 256x128 xc:"gray($grey%)" "$TMP/fr_alpha.png" -alpha off -compose copy_opacity -composite \
      -compose over "$TMP/fr_out.png"
  tga "$TMP/fr_out.png" "$out"
}

# Kit 1) Grey cover 256x256: woven cloth (fine warp and weft), grain, light embossing, darker edges. Mid grey
#    (centre about 60 %) so a theme tints it to any darker colour: canvas, hardboard, also the photo background.
#    Few grey levels on purpose: the file packs small in the zip.
kit_media() {
  magick -seed 101 -size 256x256 xc:gray50 -attenuate 1.4 +noise Gaussian -colorspace gray -blur 0x1.0 \
    -shade 120x45 -auto-level -level 18%,86% +level 62%,92% \
    \( -seed 102 -size 1x256 xc:gray50 +noise Random -colorspace gray -blur 0x0.6 -auto-level +level 86%,100% \
       -scale '256x256!' \) -compose multiply -composite \
    \( -seed 103 -size 256x1 xc:gray50 +noise Random -colorspace gray -blur 0x0.6 -auto-level +level 88%,100% \
       -scale '256x256!' \) -compose multiply -composite \
    \( -size 256x256 radial-gradient:white-gray62 \) -compose multiply -composite \
    -colorspace gray -posterize 40 -colorspace sRGB -alpha off "$TMP/g_cover.png"
  tga "$TMP/g_cover.png" "$OUT/g_cover.tga"
}

# Privateer's Ledger (harbor): stamps with cut corners in oxblood, a dagger instead of the thumbtack, brass nails
# instead of tape. Cover, photo background, paper, page: kit and the black book's files, tinted (Themes/harbor.lua).
theme_harbor() {
  # 1) Stamp frames (angles as the black book: nr1 -11, rache 9, pardon -6, suspect 7, guild -9, hunt 8)
  frame "$OUT/harbor_stamp_nr1.tga"     -11 cut 201 100
  frame "$OUT/harbor_stamp_rache.tga"     9 cut 202 100
  frame "$OUT/harbor_stamp_pardon.tga"   -6 cut 203 34
  frame "$OUT/harbor_stamp_suspect.tga"   7 cut 204 46
  frame "$OUT/harbor_stamp_guild.tga"    -9 cut 205 100
  frame "$OUT/harbor_stamp_hunt.tga"      8 cut 206 100
  # 2) Dagger 64x64 (shown at 28x28 in place of the thumbtack, the top 12 px above the poster): brass pommel and
  #    guard, leather grip, a short blade that ends in a slit in the paper. Own colours, slightly turned.
  magick -size 64x64 xc:none \
    -fill 'rgba(0,0,0,0.45)' -draw 'polygon 31,34 39,34 37,52 34,56' -blur 0x1.6 \
    \( -size 64x64 xc:none \
       -fill '#2a1a10' -draw 'polygon 27,53 37,53 36,56 28,56' \
       -fill '#8c969b' -draw 'polygon 27,31 37,31 36,52 32,55 28,52' \
       -fill '#dfe5e8' -draw 'polygon 31,31 33,31 33,53 32,55 31,53' \
       -fill '#5f696e' -draw 'polygon 27,31 29,31 29,52 28,52' \
       -fill '#8a6824' -draw 'roundrectangle 15,26 49,32 3,3' \
       -fill '#e0c070' -draw 'rectangle 18,27 46,28' \
       -fill '#3a2418' -draw 'roundrectangle 27,9 37,27 3,3' \
       -stroke '#6a4630' -strokewidth 1.6 -draw 'line 27,13 37,16' -draw 'line 27,18 37,21' -draw 'line 27,23 37,26' \
       -stroke none -fill '#8a6824' -draw 'circle 32,6 32,1' -fill '#e8cc80' -draw 'circle 30,4 30,3' \) \
    -compose over -composite -background none -virtual-pixel transparent -distort SRT '32,30 1 -12 32,32' \
    "$TMP/harbor_dagger.png"
  tga "$TMP/harbor_dagger.png" "$OUT/harbor_dagger.tga"
  # 3) Nail 64x32 (in place of the tape strip, shown at 52x20 and 34x14): a round head drawn narrow so it stays round
  #    on the wide strip; light grey, the theme tints it to brass (tint.tape). The rest of the strip stays clear.
  magick -size 64x32 xc:none \
    -fill 'rgba(0,0,0,0.55)' -draw 'ellipse 34,18 8,10 0,360' -blur 0x1.4 \
    \( -size 64x32 xc:none -fill '#6e6e6e' -draw 'ellipse 32,16 7.5,9.5 0,360' \
       -fill '#c4c4c4' -draw 'ellipse 31.5,15.5 6,7.8 0,360' \
       -fill '#f4f4f4' -draw 'ellipse 29.5,12.5 2.2,2.8 0,360' \) -compose over -composite "$TMP/harbor_nail.png"
  tga "$TMP/harbor_nail.png" "$OUT/harbor_nail.tga"
}

# The Workshop (trade): box stamps in stamp-pad red, a clipboard clamp instead of the thumbtack. Tape and the
# height chart of the photo are the black book's; cover from the kit, paper and page tinted (Themes/trade.lua).
theme_trade() {
  # 1) Stamp frames (same angles as the black book)
  frame "$OUT/trade_stamp_nr1.tga"     -11 box 301 100
  frame "$OUT/trade_stamp_rache.tga"     9 box 302 100
  frame "$OUT/trade_stamp_pardon.tga"   -6 box 303 34
  frame "$OUT/trade_stamp_suspect.tga"   7 box 304 46
  frame "$OUT/trade_stamp_guild.tga"    -9 box 305 100
  frame "$OUT/trade_stamp_hunt.tga"      8 box 306 100
  # 2) Clipboard clamp 64x64 (shown at 28x28 in place of the thumbtack, the top 12 px above the poster): steel plate
  #    with two rivets, a lever with a hanging hole on top. Own colours.
  magick -size 64x64 xc:none \
    -fill 'rgba(0,0,0,0.45)' -draw 'roundrectangle 8,32 60,58 4,4' -blur 0x1.6 \
    \( -size 64x64 xc:none \
       -fill '#80878c' -draw 'roundrectangle 22,8 42,32 7,7' \
       -fill '#b9c0c4' -draw 'roundrectangle 24,10 40,20 5,5' \
       -fill none -stroke '#30363a' -strokewidth 2.2 -draw 'circle 32,17 32,13' \
       -stroke none -fill '#8d9499' -draw 'roundrectangle 5,28 59,54 4,4' \
       -fill '#d2d8db' -draw 'rectangle 8,30 56,34' \
       -fill '#5f666b' -draw 'rectangle 8,48 56,52' \
       -fill '#454b50' -draw 'circle 14,41 14,38' -draw 'circle 50,41 50,38' \
       -fill '#c9d0d4' -draw 'circle 13,40 13,39' -draw 'circle 49,40 49,39' \) \
    -compose over -composite "$TMP/trade_clamp.png"
  tga "$TMP/trade_clamp.png" "$OUT/trade_clamp.tga"
}

case "$WHAT" in
  all) base_media; kit_media; theme_harbor; theme_trade ;;
  base) base_media ;;
  kit) kit_media ;;
  harbor) kit_media; theme_harbor ;;
  trade) kit_media; theme_trade ;;
  *) echo "unknown part: $WHAT (all, base, kit, harbor, trade)" >&2; exit 2 ;;
esac

# Check the headers: type 2 (uncompressed), 32 bpp, descriptor 0x08, edges a power of two
bad=0
for f in "$OUT"/*.tga; do
  set -- $(od -An -tu1 -j2 -N1 "$f") $(od -An -tu2 -j12 -N4 "$f") $(od -An -tu1 -j16 -N2 "$f")
  typ=$1 w=$2 h=$3 bpp=$4 desc=$5
  pot() { [ $(( $1 & ($1 - 1) )) -eq 0 ]; }
  if [ "$typ" != 2 ] || [ "$bpp" != 32 ] || [ "$desc" != 8 ] || ! pot "$w" || ! pot "$h"; then
    echo "ERROR $f type=$typ ${w}x${h} bpp=$bpp desc=$desc" >&2; bad=1
  fi
done
du -ch "$OUT"/*.tga | tail -1
[ "$bad" = 0 ] && echo "TGA headers ok"
exit "$bad"
