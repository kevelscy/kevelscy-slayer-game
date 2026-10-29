#!/usr/bin/env bash
# Resolves the Godot 4 binary and execs it with all arguments.
set -euo pipefail

if [[ -n "${GODOT_BIN:-}" ]]; then
  if [[ ! -x "$GODOT_BIN" ]]; then
    echo "godot.sh: GODOT_BIN is set but not executable: $GODOT_BIN" >&2
    exit 1
  fi
  exec "$GODOT_BIN" "$@"
fi

if command -v godot >/dev/null 2>&1; then
  exec godot "$@"
fi

for candidate in \
  "/Applications/Godot.app/Contents/MacOS/Godot" \
  "$HOME/Downloads/Godot.app/Contents/MacOS/Godot"; do
  if [[ -x "$candidate" ]]; then
    exec "$candidate" "$@"
  fi
done

echo "godot.sh: Godot binary not found. Set GODOT_BIN to the Godot 4 executable." >&2
exit 1
