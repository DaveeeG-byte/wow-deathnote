#!/usr/bin/env bash
# Runs syntax checks and all logic tests with luajit. Exit code != 0 if anything is red.
cd "$(dirname "$0")/.." || exit 2
status=0
for f in DeathNote/*.lua tests/mock_wow.lua tests/test_*.lua tests/belege/*.lua; do
  [ -f "$f" ] || continue
  if ! luajit -bl "$f" > /dev/null; then echo "SYNTAX ROT: $f"; status=1; fi
done
for t in tests/test_*.lua; do
  luajit "$t" || status=1
done
# Belege der Logik (Namensform, Momentaufnahme Z, Spieltage, Secrets, Upgrade) und ein kurzer Zufallslauf
# 1.2.1: Kopfgeld, Rache abziehen, gerächt, Instanzen, Ausweis mit spaeter GUID, Upgrade-Kette (beleg_b0*)
# 1.2.1 nach der Jagd: Namensvetter, Ausweis ohne Verlust, Wege im Dungeon, Kopfgeld in der Antwort, Rache-Zeit (beleg_c0*)
# 1.2.1 nach der Abschluss-Jagd: lange Sperre, Zeitgeber, gewaehlte Bindung, Rache-Zeit, Kopfgeld-Pruefung (beleg_d0*)
for t in tests/belege/beleg_a0*.lua tests/belege/beleg_b0*.lua tests/belege/beleg_c0*.lua tests/belege/beleg_d0*.lua; do
  luajit "$t" . || status=1
done
luajit tests/belege/fuzz_abschluss.lua . 12 1000 120 || status=1
[ $status -eq 0 ] && echo "ALLES GRÜN" || echo "ES GIBT ROTE TESTS"
exit $status
