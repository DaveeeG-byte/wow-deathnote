#!/usr/bin/env bash
# Oberflaechen-Tests (Bauer B): Syntax, Rauchtest gegen Vertrags-Stub, Zusammenspiel mit A's Dateien.
# Exit-Code != 0, sobald etwas rot ist. Optional: erster Parameter = anderer Quellordner (Rot-Probe).
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
         tests/belege/_kopf_ui.lua tests/belege/_kopf_hu.lua tests/belege/beleg_ui_*.lua tests/belege/beleg_hu_*.lua; do
  if ! luajit -bl "$f" > /dev/null; then echo "SYNTAX ROT: $f"; status=1; fi
done
echo "Syntax geprueft"

luajit tests/ui/smoke.lua "$src" || status=1
luajit tests/ui/gesamtschau.lua "$src" || status=1

if [ -z "$1" ] && [ -f "$adir/Core.lua" ] && [ -f tests/mock_wow.lua ]; then
  luajit tests/ui/integration.lua || status=1
  # 1.2.0: Freundesbuch und Abschussliste mit der echten Logik
  if [ -f "$adir/Friends.lua" ]; then luajit tests/ui/freunde.lua || status=1; fi
  # 1.2.0 (fix-1): Belege der Fehlerjagd (Oberflaeche, Alarm bei eigenem Buch) und die Fixe danach
  if [ -f "$adir/Friends.lua" ]; then
    luajit tests/ui/beleg_oberflaeche.lua || status=1
    luajit tests/ui/beleg_alarm_eigenes_buch.lua || status=1
    luajit tests/ui/fix_abschussliste.lua || status=1
  fi
  # 1.2.0: Erststart-Dialog, das Buch in allen 21 Sprachen, voller Lauf auf Englisch
  if [ -f "$adir/Locale.lua" ]; then
    luajit tests/ui/sprachen.lua || status=1
  fi
  # 1.2.0 (bau-d): Humor nur in Deutsch und Englisch, mit Oberflaeche
  if [ -f "$adir/Humor.lua" ]; then luajit tests/ui/humor.lua || status=1; fi
  # 1.2.0 (fix-2): Belege der finalen Jagd mit Oberflaeche (kurz, fester Startwert) und die Fixe danach
  if [ -f "$adir/Friends.lua" ]; then
    for t in final_f05_kaputte_daten final_f06_hoch_zurueck_hoch final_f10_oberflaeche_messen \
             final_f11_dialog_alarm_sprachwechsel final_f15_sprachdatei_fehlt_kaputt final_f17_kampf_neue_stellen fix2 fix3; do
      out=$(luajit tests/ui/$t.lua . 2>&1) || status=1
      printf '%s\n' "$out" | grep -v "^  Reiter \|^  Blatt \|^  Alarm \|^  UIParent\|^  Dialog \|^[a-z][a-z][A-Z][A-Z]: "
    done
  fi
fi

# Belege mit Oberflaeche: Ansichten und Alarm der Abschussliste, Plakat, Grund, Humor
if [ -z "$1" ] && [ -f "$adir/Friends.lua" ]; then
  for t in tests/belege/beleg_ui_*.lua tests/belege/beleg_hu_*.lua; do
    out=$(luajit "$t" . 2>&1) || status=1
    printf '%s\n' "$out" | grep -v "^  ok\|^      \|^  Hinweis\|^  info" | tail -n 4
  done
fi

# "Staatsfeind" darf in B's Code nur als Plakat-Begriff vorkommen
if grep -n "Staatsfeind" "$src"/Alert.lua "$src"/UI.lua "$src"/Extras.lua | grep -v "STAATSFEIND\|Staatsfeind Nr\. 1"; then
  echo "ROT: alter Addon-Name in B's Dateien"; status=1
fi

# Texturen: Typ 2, 32 bpp, Ursprung unten links, Kanten Zweierpotenz
for f in "$adir"/Media/*.tga; do
  set -- $(od -An -tu1 -j2 -N1 "$f") $(od -An -tu2 -j12 -N4 "$f") $(od -An -tu1 -j16 -N2 "$f")
  if [ "$1" != 2 ] || [ "$4" != 32 ] || [ "$5" != 8 ] || [ $(( $2 & ($2 - 1) )) -ne 0 ] || [ $(( $3 & ($3 - 1) )) -ne 0 ]; then
    echo "TEXTUR ROT: $f"; status=1
  fi
done
echo "Texturen geprueft ($(ls "$adir"/Media/*.tga | wc -l) Dateien, $(du -ch "$adir"/Media/*.tga | tail -1 | cut -f1))"

# Alarmtoene: 5 Toene x 5 Stufen, Namen klein ohne Umlaute, OGG Vorbis mono, zusammen hoechstens 600 KB
snd="$adir/Media/Sounds"
n=$(ls "$snd"/*.ogg 2>/dev/null | wc -l)
bytes=$(cat "$snd"/*.ogg 2>/dev/null | wc -c)
[ "$n" -eq 25 ] || { echo "TON ROT: $n statt 25 Dateien"; status=1; }
[ "$bytes" -le 614400 ] || { echo "TON ROT: zusammen $bytes Bytes"; status=1; }
if ls "$snd" | grep -v '^[a-z]*_[1-5]\.ogg$'; then echo "TON ROT: Dateiname nicht klein/ohne Umlaut"; status=1; fi
for f in "$snd"/*.ogg; do
  [ "$(head -c 4 "$f")" = "OggS" ] || { echo "TON ROT: kein Ogg: $f"; status=1; }
done
if command -v ffprobe >/dev/null && command -v ffmpeg >/dev/null; then
  sndlog=$(mktemp)
  if bash tests/ui/make_sounds.sh --check > "$sndlog" 2>&1; then
    echo "Toene geprueft ($n Dateien, $((bytes / 1024)) KB, Vorbis mono, Dauer und Pegel je Stufe steigend)"
  else
    cat "$sndlog"; echo "TON ROT: Messung"; status=1
  fi
  rm -f "$sndlog"
else
  echo "Toene geprueft ($n Dateien, $((bytes / 1024)) KB; ffprobe fehlt, Format/Pegel nicht gemessen)"
fi

[ $status -eq 0 ] && echo "UI: ALLES GRUEN" || echo "UI: ES GIBT ROTE TESTS"
exit $status
