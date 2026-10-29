#!/usr/bin/env bash
# Imports the client project and runs the full GUT suite headless.
# Extra arguments are forwarded to GUT. Exits with GUT's exit code.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
godot="$repo_root/scripts/godot.sh"
client="$repo_root/client"

# The first import builds .godot/ so class_name scripts resolve in headless runs.
"$godot" --headless --path "$client" --import

log_file="$(mktemp -t gut-run.XXXXXX)"
trap 'rm -f "$log_file"' EXIT

set +e
"$godot" --headless --path "$client" -s addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json "$@" 2>&1 | tee "$log_file"
gut_status="${PIPESTATUS[0]}"
set -e

# GUT skips test scripts that fail to parse and still exits 0: treat any
# script load/parse error as a failed run so the suite never reports a false green.
if grep -qE 'SCRIPT ERROR|Parse Error|Failed to load script' "$log_file"; then
  echo "test.sh: script errors detected (see output above); failing the run." >&2
  exit 1
fi

exit "$gut_status"
