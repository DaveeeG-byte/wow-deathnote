#!/usr/bin/env bash
# Baut die eigenen Texturen von DeathNote neu (ImageMagick 7, `magick`).
# Ausgabe: <Addon-Ordner>/Media/*.tga (DeathNote/ oder noch Staatsfeind/), 32 Bit RGBA, unkomprimiert, Kantenlaengen Zweierpotenz.
# Deterministisch (feste Seeds). Aufruf: tests/ui/make_media.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
ADIR="$ROOT/DeathNote"; [ -d "$ADIR" ] || ADIR="$ROOT/Staatsfeind"
OUT="$ADIR/Media"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$OUT"

# Schriften nur zum Einbrennen in Bilder (SIL OFL), im Spiel werden nur Client-Schriften benutzt.
STAMPFONT="/usr/share/fonts/noto/NotoSans-Black.ttf"
SERIFFONT="/usr/share/fonts/noto/NotoSerif-Black.ttf"
SYMFONT="/usr/share/fonts/TTF/Symbola.ttf"
for f in "$STAMPFONT" "$SERIFFONT" "$SYMFONT"; do
  [ -f "$f" ] || { echo "Schrift fehlt: $f" >&2; exit 1; }
done

# 32 Bit RGBA, unkomprimiert, klassischer Ursprung unten links (Deskriptor 0x08).
# ImageMagick setzt bei -orient nur das Flag, darum vorher selbst spiegeln.
tga() { magick "$1" -alpha set -flip -orient BottomLeft -type TrueColorAlpha -depth 8 -compress None "$2"; }

# Hinweis: Graustufen-Zwischenbilder immer mit -colorspace sRGB zurueckwandeln, sonst faerbt
# ImageMagick das Ergebnis grau. Nach copy_opacity immer -compose over setzen.

# 1) Papier 512x512: knochenweiss statt Western-Orange (Mitte #ebe3cc, Rand #c2b493), wolkig, Koernung,
#    milde Vignette, zwei Stockflecken mit 15 % Deckkraft. Gesamtschau: heller als 1.1.0 (#ddd3b8/#a89a7c),
#    damit kleine Schrift auf dem Plakat 4,5:1 haelt (gemessen im Standbild aus dem Code)
magick -seed 11 -size 512x512 plasma:fractal -blur 0x6 -colorspace gray -auto-level +level 88%,100% \
  -seed 12 -attenuate 0.30 +noise Gaussian -colorspace gray -blur 0x0.4 -colorspace sRGB \
  \( -size 512x512 radial-gradient:'#ebe3cc'-'#c2b493' -fx 'p' \) -compose multiply -composite \
  \( -size 512x512 xc:none -fill 'rgba(120,88,40,0.15)' -draw 'ellipse 382,128 26,21 0,360' \
     -draw 'ellipse 112,408 17,15 0,360' -blur 0x5 \) -compose over -composite \
  \( -size 512x512 xc:white -fill none -stroke '#a08f6c' -strokewidth 10 -draw 'rectangle 0,0 511,511' -blur 0x7 \) \
  -compose multiply -composite -alpha off \
  "$TMP/paper.png"
tga "$TMP/paper.png" "$OUT/paper.tga"

# 2) Einband 256x256: schwarzes Leder (Koernung, leichte Praegung, Abrieb an den Raendern)
magick -seed 21 -size 256x256 xc:gray50 -attenuate 2.0 +noise Gaussian -colorspace gray -blur 0x1.1 \
  -shade 120x45 -auto-level -level 30%,75% -colorspace sRGB \
  \( -size 256x256 xc:'#1b1918' \) -compose multiply -composite \
  \( -size 256x256 radial-gradient:white-black -fx '0.85+0.3*u' -colorspace sRGB \) -compose multiply -composite \
  -level 0%,70% "$TMP/cover.png"
tga "$TMP/cover.png" "$OUT/cover.tga"

# 3) Notizbuch-Seite 256x512: knochenweiss, leicht vergilbt, zum Falz (rechts) hin dunkler.
#    Die Linien zeichnet das Addon selbst, damit sie genau unter den Zeilen liegen.
magick -seed 23 -size 256x512 plasma:fractal -blur 0x8 -colorspace gray -auto-level +level 88%,100% \
  -seed 24 -attenuate 0.25 +noise Gaussian -colorspace gray -blur 0x0.4 -colorspace sRGB \
  \( -size 256x512 xc:'#f3ecdc' \) -compose multiply -composite \
  \( -size 512x256 gradient:white-'#c9b896' -rotate 90 -fx 'pow(u,0.35)' -colorspace sRGB \) -compose multiply -composite \
  \( -size 256x512 xc:white -fill none -stroke '#8a7a5a' -strokewidth 8 -draw 'rectangle 0,0 255,511' -blur 0x6 \) \
  -compose multiply -composite \
  "$TMP/page.png"
tga "$TMP/page.png" "$OUT/page.tga"

# 4) Tintenstrich 256x16: leicht welliger Federstrich (Unterstreichen, Durchstreichen)
magick -size 256x16 xc:none -stroke black -strokewidth 2.6 -fill none \
  -draw "path 'M 3,9 C 50,6 90,11 140,8 S 220,6 252,9'" -strokewidth 1.2 \
  -draw "path 'M 10,10 C 60,8 120,12 180,9 S 230,8 248,10'" -blur 0x0.5 "$TMP/ink.png"
tga "$TMP/ink.png" "$OUT/ink.tga"

# Stempel-Helfer: Gummistempel in fetter Serifenschrift mit Doppelrahmen (aussen 10 px, innen 3 px, Abstand 8 px,
# Ecken 14 px), Abnutzung als Rauschmaske, schraeg gedreht. Gezeichnet auf 512x256, gespeichert auf 256x128
# (Anzeige hoechstens 150x75 bei Skala 1,5 = 225 px; spart 2 MB).
# $1 Ausgabe, $2 Winkel, $3 Farbe, $4 Seed, $5.. Zeilen (Text|Punktgroesse)
stamp() {
  local out="$1" ang="$2" col="$3" seed="$4"; shift 4
  local x0=46 y0=44 x1=465 y1=211
  local n=$# i=0 line txt size y
  local args=() total=0
  for line in "$@"; do size="${line##*|}"; total=$((total + size)); done
  # Zeilen vertikal nach Schriftgroesse verteilt um die Mitte
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
  # Abnutzung: Rauschen, leicht verwischt, alles ueber der Schwelle wird ausgestanzt
  magick -seed "$seed" -size 512x256 xc:gray50 +noise Random -colorspace gray -blur 0x0.7 -auto-level \
      -threshold 82% -alpha copy "$TMP/st_holes.png"
  magick "$TMP/st_mask.png" "$TMP/st_holes.png" -compose DstOut -composite -blur 0x0.4 "$TMP/st_worn.png"
  magick -size 512x256 xc:"$col" \( "$TMP/st_worn.png" -alpha extract \) -alpha off -compose copy_opacity -composite \
      -channel A -evaluate multiply 0.94 +channel -compose over -background none \
      -virtual-pixel transparent -distort SRT "$ang" -resize 256x128 "$TMP/st_out.png"
  tga "$TMP/st_out.png" "$out"
}

# Stempel: Blutrot ist die einzige Akzentfarbe, Begnadigt und Verdacht in Tintenschwarz
stamp "$OUT/stamp_nr1.tga"     -11 '#b00a0a' 31 "STAATSFEIND|46" "Nr. 1|64"
stamp "$OUT/stamp_guild.tga"    -9 '#b00a0a' 71 "GILDENFEIND|46" "Nr. 1|64"
stamp "$OUT/stamp_rache.tga"     9 '#b00a0a' 41 "RACHE|64" "GENOMMEN|46"
stamp "$OUT/stamp_pardon.tga"   -6 '#1e1b19' 51 "BEGNADIGT|56"
stamp "$OUT/stamp_suspect.tga"   7 '#2e2a27' 61 "VERDACHT|60"
# 1.2.0: Abschussliste
stamp "$OUT/stamp_hunt.tga"      8 '#b00a0a' 81 "ZUR JAGD|52" "FREIGEGEBEN|44"
# 1.2.0: dieselben Stempel ohne Text (gleicher Winkel, Farbe, Abnutzung); den Text setzt das Spiel aus der
# Sprachtabelle darueber (alle Sprachen ausser Deutsch, das die Bilder oben behaelt)
stamp "$OUT/stamp_nr1_blank.tga"     -11 '#b00a0a' 31
stamp "$OUT/stamp_guild_blank.tga"    -9 '#b00a0a' 71
stamp "$OUT/stamp_rache_blank.tga"     9 '#b00a0a' 41
stamp "$OUT/stamp_pardon_blank.tga"   -6 '#1e1b19' 51
stamp "$OUT/stamp_suspect_blank.tga"   7 '#2e2a27' 61
stamp "$OUT/stamp_hunt_blank.tga"      8 '#b00a0a' 81

# Haken fuer die Kaestchen 32x32: handgezeichnetes Kreuz (weiss, wird im Spiel tintenschwarz getoent)
magick -size 32x32 xc:none -fill none -stroke white -strokewidth 3.2 -draw "stroke-linecap round" \
  -draw "path 'M 6,7 C 12,12 19,19 26,26'" -strokewidth 2.6 \
  -draw "path 'M 25,6 C 20,12 13,19 7,27'" -blur 0x0.45 "$TMP/check.png"
tga "$TMP/check.png" "$OUT/check.tga"

# 7) Reisszwecke 64x64: roter Kopf mit Glanz und Schatten
magick -size 64x64 xc:none \
  -fill 'rgba(0,0,0,0.45)' -draw 'circle 36,38 36,55' -blur 0x3 \
  \( -size 64x64 xc:none -fill '#7a0d0d' -draw 'circle 31,30 31,47' \
     -fill '#c42222' -draw 'circle 30,29 30,44' \
     -fill '#e86a5a' -draw 'circle 25,23 25,29' \
     -fill 'rgba(255,255,255,0.8)' -draw 'circle 24,22 24,24' \) -compose over -composite \
  "$TMP/pin.png"
tga "$TMP/pin.png" "$OUT/pin.tga"

# 8) Roter Bildschirmrand 256x256: Mitte transparent, Raender rot (fuer Vollbild gestreckt)
magick -size 256x256 xc:black -fill white -draw 'rectangle 22,22 233,233' -blur 0x20 -negate \
  -level 0%,85% "$TMP/edge_a.png"
magick -size 256x256 xc:'#ff1010' "$TMP/edge_a.png" -alpha off -compose copy_opacity -composite "$TMP/edge.png"
tga "$TMP/edge.png" "$OUT/edge.tga"

# 9) Fahndungsfoto-Hintergrund 128x128: Polizei-Messlatte (helle Wand, Linien, Zahlen; hell, damit Stempel lesbar bleiben)
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

# 10) Totenkopf 64x64 (Glyphe aus Symbola), hell mit dunkler Kontur, fuer Rueckfall-Foto und Journal
magick -size 64x64 xc:none -font "$SYMFONT" -pointsize 54 -gravity center \
  -fill '#1a1008' -stroke '#1a1008' -strokewidth 3 -annotate +0+2 $'☠' \
  -fill '#efe4c8' -stroke none -annotate +0+2 $'☠' "$TMP/skull.png"
tga "$TMP/skull.png" "$OUT/skull.tga"

# 11) Minimap-Symbol 64x64: Totenkopf auf schwarzem Kreis mit blutrotem Ring
magick -size 64x64 xc:none -fill '#8e0a0a' -draw 'circle 32,32 32,2' \
  -fill '#141212' -draw 'circle 32,32 32,6' \
  -font "$SYMFONT" -pointsize 40 -gravity center -fill '#f2e6c4' -annotate +0+1 $'☠' "$TMP/icon.png"
tga "$TMP/icon.png" "$OUT/icon.tga"

# 12) Klebestreifen 64x32: halbtransparent, ausgefranste Enden
magick -size 64x32 xc:white -fill black \
  -draw 'polygon 0,0 5,5 0,10 6,16 0,22 4,27 0,31' -draw 'polygon 63,0 58,6 63,12 57,18 63,24 59,28 63,31' \
  -evaluate multiply 0.7 "$TMP/tape_a.png"
magick -size 64x32 xc:'#f0e6c3' "$TMP/tape_a.png" -alpha off -compose copy_opacity -composite -compose over "$TMP/tape.png"
tga "$TMP/tape.png" "$OUT/tape.tga"

for f in "$OUT"/*.tga; do magick identify -format '%f %wx%h %[channels] depth=%z compress=%C\n' "$f"; done
# Kopfzeile pruefen: Typ 2 (unkomprimiert), 32 bpp, Deskriptor 0x08, Kanten Zweierpotenz
# 1.1.0) Dreieck 32x32 fuer die Abschnitte "Nach Mitglied": weiss (im Spiel eingefaerbt), zeigt nach rechts,
#    aufgeklappt dreht die Oberflaeche es um 90 Grad nach unten. Leicht unregelmaessig wie mit der Feder gezogen.
magick -size 32x32 xc:none -fill white -stroke white -strokewidth 1.6 -draw "stroke-linejoin round" \
  -draw "polygon 10,7 25,16.5 9.5,25" -blur 0x0.5 "$TMP/tri.png"
tga "$TMP/tri.png" "$OUT/tri.tga"

bad=0
for f in "$OUT"/*.tga; do
  set -- $(od -An -tu1 -j2 -N1 "$f") $(od -An -tu2 -j12 -N4 "$f") $(od -An -tu1 -j16 -N2 "$f")
  typ=$1 w=$2 h=$3 bpp=$4 desc=$5
  pot() { [ $(( $1 & ($1 - 1) )) -eq 0 ]; }
  if [ "$typ" != 2 ] || [ "$bpp" != 32 ] || [ "$desc" != 8 ] || ! pot "$w" || ! pot "$h"; then
    echo "FEHLER $f typ=$typ ${w}x${h} bpp=$bpp desc=$desc" >&2; bad=1
  fi
done
du -ch "$OUT"/*.tga | tail -1
[ "$bad" = 0 ] && echo "TGA-Kopfzeilen ok"
exit "$bad"
