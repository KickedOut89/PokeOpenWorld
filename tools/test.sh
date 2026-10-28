#!/usr/bin/env bash
# Runs GUT headless. Usage: tools/test.sh [res://path/to/test_file.gd]
# Last line of output is always "RESULT: <passing>/<total> passed" or "RESULT: FAILED ...".
set -uo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
# Re-import when any script/data is newer than the class cache, so new class_names register.
CACHE=.godot/global_script_class_cache.cfg
if [ ! -f "$CACHE" ] || [ -n "$(find src tests tools data scenes -newer "$CACHE" -print -quit 2>/dev/null)" ]; then
  "$GODOT" --headless --path . --import >/dev/null 2>&1
  touch "$CACHE"
fi
if [ $# -ge 1 ]; then SEL="-gtest=$1"; else SEL="-gdir=res://tests"; fi
LOG="$(mktemp)"
"$GODOT" --headless --path . -s addons/gut/gut_cmdln.gd "$SEL" -ginclude_subdirs -gdisable_colors -gexit 2>&1 \
  | grep -v "is now available" | tee "$LOG"
CODE=${PIPESTATUS[0]}
TOTAL=$(grep -E "^Tests +[0-9]+" "$LOG" | awk '{print $2}')
PASS=$(grep -E "^Passing Tests +[0-9]+" "$LOG" | awk '{print $3}')
rm -f "$LOG"
if [ "$CODE" -eq 0 ] && [ -n "${TOTAL:-}" ]; then
  echo "RESULT: ${PASS:-0}/${TOTAL} passed"
else
  echo "RESULT: FAILED (exit $CODE, ${PASS:-0}/${TOTAL:-?} passed)"
  [ "$CODE" -eq 0 ] && CODE=1
fi
exit "$CODE"
