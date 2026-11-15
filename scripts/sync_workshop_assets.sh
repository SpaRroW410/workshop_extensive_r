#!/usr/bin/env bash
# The quiz engine and its styles are identical in every workshop. regression-workshop/assets/ holds the master copy.
#   scripts/sync_workshop_assets.sh          copy the master files into every other *-workshop/assets/
#   scripts/sync_workshop_assets.sh --check  exit 1 if any copy differs (used by CI)
set -euo pipefail
cd "$(dirname "$0")/.."
files="quiz.js quiz.R quiz.css quiz-include.html"
status=0
for d in *-workshop; do
  [ "$d" = "regression-workshop" ] && continue
  for f in $files; do
    if [ "${1:-}" = "--check" ]; then
      cmp -s "regression-workshop/assets/$f" "$d/assets/$f" || { echo "DIFFERS: $d/assets/$f"; status=1; }
    else
      cp "regression-workshop/assets/$f" "$d/assets/$f"
    fi
  done
done
[ "${1:-}" = "--check" ] && [ $status -eq 0 ] && echo "All workshop quiz assets match the master copy"
exit $status
