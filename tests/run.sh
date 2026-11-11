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
for t in tests/belege/beleg_a0*.lua; do
  luajit "$t" . || status=1
done
luajit tests/belege/fuzz_abschluss.lua . 12 1000 120 || status=1
[ $status -eq 0 ] && echo "ALLES GRÜN" || echo "ES GIBT ROTE TESTS"
exit $status
