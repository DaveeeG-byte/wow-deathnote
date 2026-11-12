#!/usr/bin/env bash
# UI tests: syntax, smoke test against the contract stub, interplay with the logic files.
# Exit code != 0 as soon as anything is red. Optional: first argument = another source folder (red probe).
cd "$(dirname "$0")/../.." || exit 2
adir=DeathNote; [ -d "$adir" ] || adir=Staatsfeind
src="${1:-$adir}"
status=0

for f in "$src"/Alert.lua "$src"/UI.lua "$src"/Extras.lua "$adir"/Humor.lua tests/ui/mock.lua tests/ui/stub.lua \
         tests/ui/smoke.lua tests/ui/integration.lua tests/ui/gesamtschau.lua tests/ui/freunde.lua tests/ui/sprachen.lua \
         tests/ui/beleg_oberflaeche.lua tests/ui/beleg_alarm_eigenes_buch.lua tests/ui/fix_abschussliste.lua \
         tests/ui/humor.lua tests/ui/final_f05_kaputte_daten.lua tests/ui/final_f06_hoch_zurueck_hoch.lua \
         tests/ui/final_f10_oberflaeche_messen.lua tests/ui/final_f11_dialog_alarm_sprachwechsel.lua \
         tests/ui/final_f15_sprachdatei_fehlt_kaputt.lua tests/ui/final_f17_kampf_neue_stellen.lua tests/ui/fix2.lua tests/ui/fix3.lua \
         tests/ui/layout_guard.lua tests/ui/layout_belege.lua tests/ui/layout_kit.lua tests/ui/layout_fixes.lua \
         tests/ui/layout_red_probes.lua tests/ui/theme_probe.lua tests/ui/theme_guard.lua tests/ui/notice_first.lua \
         tests/belege/_kopf_ui.lua tests/belege/_kopf_hu.lua tests/belege/beleg_ui_*.lua tests/belege/beleg_hu_*.lua; do
  if ! luajit -bl "$f" > /dev/null; then echo "SYNTAX RED: $f"; status=1; fi
done
echo "Syntax checked"

luajit tests/ui/smoke.lua "$src" || status=1
luajit tests/ui/gesamtschau.lua "$src" || status=1

if [ -z "$1" ] && [ -f "$adir/Core.lua" ] && [ -f tests/mock_wow.lua ]; then
  luajit tests/ui/integration.lua || status=1
  # 1.2.0: friends' book and hit list with the real logic
  if [ -f "$adir/Friends.lua" ]; then luajit tests/ui/freunde.lua || status=1; fi
  # 1.2.0 (fix-1): proofs from the bug hunt (UI, alarm with own book) and the fixes after it
  if [ -f "$adir/Friends.lua" ]; then
    luajit tests/ui/beleg_oberflaeche.lua || status=1
    luajit tests/ui/beleg_alarm_eigenes_buch.lua || status=1
    luajit tests/ui/fix_abschussliste.lua || status=1
  fi
  # 1.2.0: first-start dialog, the book in all 21 languages, a full run in English
  if [ -f "$adir/Locale.lua" ]; then
    luajit tests/ui/sprachen.lua || status=1
  fi
  # 1.2.0 (build d): humor only in German and English, with UI
  if [ -f "$adir/Humor.lua" ]; then luajit tests/ui/humor.lua || status=1; fi
  # 1.2.0 (fix-2): proofs from the final hunt with UI (short, fixed seed) and the fixes after it
  if [ -f "$adir/Friends.lua" ]; then
    for t in final_f05_kaputte_daten final_f06_hoch_zurueck_hoch final_f10_oberflaeche_messen \
             final_f11_dialog_alarm_sprachwechsel final_f15_sprachdatei_fehlt_kaputt final_f17_kampf_neue_stellen fix2 fix3; do
      out=$(luajit tests/ui/$t.lua . 2>&1) || status=1
      printf '%s\n' "$out" | grep -v "^  Reiter \|^  Blatt \|^  Alarm \|^  UIParent\|^  Dialog \|^[a-z][a-z][A-Z][A-Z]: "
    done
    # 1.2.2: layout guard (nothing overlaps, nothing cut without tooltip, scroll pages) in all 21 languages
    out=$(luajit tests/ui/layout_guard.lua . 2>&1) || status=1
    printf '%s\n' "$out" | grep -v "^[a-z][a-z][A-Z][A-Z]: 0 findings"
    luajit tests/ui/layout_belege.lua . || status=1
    luajit tests/ui/layout_fixes.lua . || status=1
    luajit tests/ui/layout_red_probes.lua . || status=1
    # 1.3.0: the look comes from the theme only (test theme "probe" against the black book)
    luajit tests/ui/theme_guard.lua . || status=1
    # 1.3.0: the on-screen notice: first appearance equals the second, calm fade, both building styles
    luajit tests/ui/notice_first.lua . || status=1
  fi
fi

# Proofs with UI: hit list views and alarm, poster, reason, humor
if [ -z "$1" ] && [ -f "$adir/Friends.lua" ]; then
  for t in tests/belege/beleg_ui_*.lua tests/belege/beleg_hu_*.lua; do
    out=$(luajit "$t" . 2>&1) || status=1
    printf '%s\n' "$out" | grep -v "^  ok\|^      \|^  Hinweis\|^  info" | tail -n 4
  done
fi

# 1.2.2: the minimap button with the real embedded libraries (DeathNote/Libs) instead of stand-ins
for f in tests/ui/real_libs.lua tests/ui/minimap_real_libs.lua; do
  if ! luajit -bl "$f" > /dev/null; then echo "SYNTAX RED: $f"; status=1; fi
done
if [ -z "$1" ] && [ -f "$adir/Libs/embeds.xml" ]; then
  luajit tests/ui/minimap_real_libs.lua . || status=1
fi

# "Staatsfeind" (the old addon name) may only appear in the UI files as the poster term
if grep -n "Staatsfeind" "$src"/Alert.lua "$src"/UI.lua "$src"/Extras.lua | grep -v "STAATSFEIND\|Staatsfeind Nr\. 1"; then
  echo "RED: old addon name in the UI files"; status=1
fi

# Textures: type 2, 32 bpp, origin bottom left, edges a power of two
for f in "$adir"/Media/*.tga; do
  set -- $(od -An -tu1 -j2 -N1 "$f") $(od -An -tu2 -j12 -N4 "$f") $(od -An -tu1 -j16 -N2 "$f")
  if [ "$1" != 2 ] || [ "$4" != 32 ] || [ "$5" != 8 ] || [ $(( $2 & ($2 - 1) )) -ne 0 ] || [ $(( $3 & ($3 - 1) )) -ne 0 ]; then
    echo "TEXTURE RED: $f"; status=1
  fi
done
echo "Textures checked ($(ls "$adir"/Media/*.tga | wc -l) files, $(du -ch "$adir"/Media/*.tga | tail -1 | cut -f1))"

# Alarm sounds: 5 sounds x 5 levels, names lower case without umlauts, Ogg Vorbis mono, at most 600 KB in total
snd="$adir/Media/Sounds"
n=$(ls "$snd"/*.ogg 2>/dev/null | wc -l)
bytes=$(cat "$snd"/*.ogg 2>/dev/null | wc -c)
[ "$n" -eq 25 ] || { echo "SOUND RED: $n files instead of 25"; status=1; }
[ "$bytes" -le 614400 ] || { echo "SOUND RED: $bytes bytes in total"; status=1; }
if ls "$snd" | grep -v '^[a-z]*_[1-5]\.ogg$'; then echo "SOUND RED: file name not lower case/without umlauts"; status=1; fi
for f in "$snd"/*.ogg; do
  [ "$(head -c 4 "$f")" = "OggS" ] || { echo "SOUND RED: not Ogg: $f"; status=1; }
done
if command -v ffprobe >/dev/null && command -v ffmpeg >/dev/null; then
  sndlog=$(mktemp)
  if bash tests/ui/make_sounds.sh --check > "$sndlog" 2>&1; then
    echo "Sounds checked ($n files, $((bytes / 1024)) KB, Vorbis mono, duration and level rising per step)"
  else
    cat "$sndlog"; echo "SOUND RED: measurement"; status=1
  fi
  rm -f "$sndlog"
else
  echo "Sounds checked ($n files, $((bytes / 1024)) KB; ffprobe missing, format/level not measured)"
fi

[ $status -eq 0 ] && echo "UI: ALL GREEN" || echo "UI: SOME TESTS ARE RED"
exit $status
