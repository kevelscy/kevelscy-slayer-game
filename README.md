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
