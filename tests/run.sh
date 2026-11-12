#!/usr/bin/env bash
# Runs syntax checks and all logic tests with luajit. Exit code != 0 if anything is red.
cd "$(dirname "$0")/.." || exit 2
status=0
for f in DeathNote/*.lua tests/mock_wow.lua tests/test_*.lua tests/belege/*.lua; do
  [ -f "$f" ] || continue
  if ! luajit -bl "$f" > /dev/null; then echo "SYNTAX RED: $f"; status=1; fi
done
for t in tests/test_*.lua; do
  luajit "$t" || status=1
done
# Logic proofs (name form, snapshot Z, play days, secrets, upgrade) and a short random run
# 1.2.1: bounty, taking back revenge, avenged, instances, identity with a late GUID, upgrade chain (beleg_b0*)
# 1.2.1 after the bug hunt: namesake, identity without loss, routes in dungeons, bounty in the answer, revenge time (beleg_c0*)
# 1.2.1 after the final hunt: long lock, timer, chosen link, revenge time, bounty check (beleg_d0*)
for t in tests/belege/beleg_a0*.lua tests/belege/beleg_b0*.lua tests/belege/beleg_c0*.lua tests/belege/beleg_d0*.lua; do
  luajit "$t" . || status=1
done
luajit tests/belege/fuzz_abschluss.lua . 12 1000 120 || status=1
[ $status -eq 0 ] && echo "ALL GREEN" || echo "SOME TESTS ARE RED"
exit $status
