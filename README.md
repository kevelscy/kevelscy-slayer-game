# Slayer Idle (working title)

2D pixel-art Incremental / Idle RPG inspired by *Slayer Legend*, built with Godot 4
(statically typed GDScript) for Windows, macOS, iOS and Android.

## Layout

| Path | Purpose |
|---|---|
| `client/` | Godot 4 project (one project for every platform, split by export presets and feature tags) |
| `client/core/` | Pure game logic (`RefCounted`, no Nodes) — unit tested headless with GUT |
| `client/tests/` | GUT test suite |
| `server/` | Backend (phase 2: Supabase) |
| `scripts/` | CLI helpers (`godot.sh`, `test.sh`) |
| `odd/tasks/` | Feature specs and task tracking |

## Requirements

- Godot 4.7.x. `scripts/godot.sh` resolves the binary from `$GODOT_BIN`, then `godot` on PATH,
  then `/Applications/Godot.app`, then `~/Downloads/Godot.app`.

## Tests

```bash
scripts/test.sh                      # import + full GUT suite, headless; exits non-zero on failure
scripts/test.sh -gselect=test_damage # extra args are forwarded to GUT
```

## Saves and offline income

- The run is saved to `user://save.json` (versioned JSON, written through a temp file and rename)
  every 30 s, when the app is paused or loses focus, and on every clean exit.
- A save that fails validation is never half-applied: the game starts fresh and keeps the bad
  file as `user://save.rejected.json`.
- Offline gold = sustainable kills per second × gold per kill × time away (capped at 8 h). It is
  paid on boot and when a mobile app returns from the background; nothing runs while suspended.
  The device clock is used until the server validates timestamps.

## Dev run flags

Pass these after `--` (they are ignored otherwise):

```bash
scripts/godot.sh --headless --path client --fixed-fps 60 --quit-after 3600 -- --dev-report --save-path=/tmp/soak.json
scripts/godot.sh --path client --resolution 720x1280 -- --screenshot=$PWD/.tmp/portrait.png
```

| Flag | Effect |
|---|---|
| `--dev-report` | prints stage, kills, gold and boss state every 5 s, plus any offline reward |
| `--screenshot=<abs png>` | saves a screenshot after 120 frames and quits |
| `--save-path=<path>` | uses a scratch save file instead of `user://save.json` |

## MCP (Godot MCP Toolkit)

1. Open `client/` in the Godot editor. The `Godot MCP Toolkit` plugin (`addons/godot_mcp_toolkit`)
   is enabled in `project.godot`; its dock shows the live port (127.0.0.1:6550–6560).
2. Register the bridge in your MCP client:
   `npx -y @npgamedev/godot-mcp-server@1.1.1` (requires Node.js 22+).
3. Keep the editor open while the agent uses MCP tools.

## Third-party

- [GUT](https://github.com/bitwes/Gut) 9.7.1 — MIT
- [godot-mcp-toolkit](https://github.com/NPGameDev/godot-mcp-toolkit) 1.1.1
- Art credits: `client/assets/CREDITS.md`
