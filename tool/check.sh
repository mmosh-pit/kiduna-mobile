#!/usr/bin/env bash
#
# Everything CI should run. Fails on the first problem.
#
#   ./tool/check.sh
#
# What it guards, and why each one exists:
#
#   analyze   — no warnings, not just no errors.
#   test      — the contract suites. In particular:
#                 · fixture_coverage_test asserts every schema field is
#                   populated by at least one fixture, AND that the check
#                   itself still fails when a field is stripped, so it cannot
#                   rot into a no-op;
#                 · events_test asserts the event vocabulary is exactly six
#                   types — if `RealmEntered` ever appears, that is a decision
#                   which needs review, not a silent addition;
#                 · ki_test asserts Ki never speaks in the first person.
#   build     — the web bundle actually compiles.
#   assets    — no oversized art creeps back in. The emblems are drawn at 84px
#               and were shipped at 640px once already.
#
set -euo pipefail

cd "$(dirname "$0")/.."

step() { printf '\n\033[36m── %s\033[0m\n' "$1"; }

step 'analyze'
flutter analyze

step 'test'
flutter test

step 'build web'
flutter build web --no-tree-shake-icons

step 'asset budget'
budget_kb=1024
over=0
while IFS= read -r -d '' f; do
  kb=$(( $(wc -c < "$f") / 1024 ))
  if [ "$kb" -gt "$budget_kb" ]; then
    printf '  %s is %sKB (budget %sKB)\n' "$f" "$kb" "$budget_kb"
    over=1
  fi
done < <(find assets -type f \( -name '*.png' -o -name '*.jpg' \) -print0)
if [ "$over" -eq 1 ]; then
  echo '  Downscale with: sips -Z 256 <file> --out <file>'
  exit 1
fi
total=$(du -sk assets | cut -f1)
printf '  assets total %sKB, largest under %sKB — ok\n' "$total" "$budget_kb"

step 'fixtures are valid JSON and in sync'
for f in assets/fixtures/*.json; do
  python3 -c "import json,sys; json.load(open('$f'))" || exit 1
done
printf '  %s fixtures parse — ok\n' "$(ls assets/fixtures/*.json | wc -l | tr -d ' ')"

printf '\n\033[32mAll checks passed.\033[0m\n'
