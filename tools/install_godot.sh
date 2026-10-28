#!/usr/bin/env bash
# Installs the pinned Godot editor binary and export templates (Linux x86_64).
set -euo pipefail
cd "$(dirname "$0")/.."
VER="$(tr -d '[:space:]' < tools/godot_version.txt)"
BASE="https://github.com/godotengine/godot/releases/download/${VER}-stable"
BIN_DIR="$HOME/.local/bin"
TPL_DIR="$HOME/.local/share/godot/export_templates/${VER}.stable"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$BIN_DIR"

if ! "$BIN_DIR/godot" --version 2>/dev/null | grep -q "^${VER}.stable"; then
  curl -fsSL -o "$TMP/godot.zip" "$BASE/Godot_v${VER}-stable_linux.x86_64.zip"
  unzip -q -o "$TMP/godot.zip" -d "$TMP"
  install -m 755 "$TMP/Godot_v${VER}-stable_linux.x86_64" "$BIN_DIR/godot"
fi

if [ ! -f "$TPL_DIR/windows_release_x86_64.exe" ]; then
  curl -fsSL -o "$TMP/templates.tpz" "$BASE/Godot_v${VER}-stable_export_templates.tpz"
  unzip -q -o "$TMP/templates.tpz" -d "$TMP/tpl"
  mkdir -p "$TPL_DIR"
  cp "$TMP/tpl/templates/version.txt" "$TMP"/tpl/templates/windows_*_x86_64*.exe "$TPL_DIR/"
fi

"$BIN_DIR/godot" --version
