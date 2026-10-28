#!/usr/bin/env bash
# Runs GUT headless. Usage: tools/test.sh [res://path/to/test_file.gd]
set -uo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
if [ ! -d .godot ]; then "$GODOT" --headless --path . --import >/dev/null 2>&1; fi
if [ $# -ge 1 ]; then SEL="-gtest=$1"; else SEL="-gdir=res://tests"; fi
"$GODOT" --headless --path . -s addons/gut/gut_cmdln.gd "$SEL" -ginclude_subdirs -gexit
