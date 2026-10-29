# Slayer Idle (working title)

2D pixel-art Incremental / Idle RPG inspired by *Slayer Legend*, built with Godot 4
(statically typed GDScript) for Windows, macOS, iOS and Android.

## Layout

| Path | Purpose |
|---|---|
| `client/` | Godot 4 project (one project for every platform, split by export presets and feature tags) |
| `client/core/` | Pure game logic (`RefCounted`, no Nodes) — unit tested headless with GUT |
| `client/tests/` | GUT test suite |
| `server/` | Supabase project: cloud save tables, RPCs and pgTAP tests (see `server/README.md`) |
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

Test and `--import` runs never touch your save: they start from an empty scratch save in
`user://tool_run/`. A save given with `--save-path` is never cleared, and a scratch save that
cannot be deleted is reported as an error (which fails a GUT run) and is not loaded: the run
starts a new game instead.

## Saves and offline income

- The run is saved to `user://save.json` (versioned JSON, written through a temp file and rename)
  every 30 s, when the app is paused or loses focus, and on every clean exit.
- Save format version 2 adds the crit chance, crit damage and attack speed levels; version 3 adds
  `ascension_shards`, `ascension_count` and `talents` (talent id to level). Version 1 and 2 saves
  still load with the missing values at 0 / no talents and are written back as version 3.
- A save that fails validation is never half-applied: the game starts fresh and keeps the bad
  file as `user://save.rejected.json`.
- Offline gold = sustainable kills per second × gold per kill × time away (capped at 8 h). It is
  paid on boot and when a mobile app returns from the background; nothing runs while suspended.
  With the cloud on, the time away comes from the server clock only (see Cloud save).

## Cloud save

The game signs in an anonymous Supabase player on first boot (refresh token in `auth.json`
next to the save) and keeps the save in the cloud. Start the local stack first (see
`server/README.md`); without it the game simply plays on the local save. A refresh that fails,
times out (408) or is rate limited (429) keeps the same player for the next attempt; only a
refresh token the server refuses signs up a new player.

- The local save loads first, so the game never waits on the network. Then the cloud save is
  pulled: if it has at least the local progress (ascensions, stage, upgrade levels, talent
  levels, then gold; ties go to the cloud) it replaces the run, and the battle restarts. A tie
  goes to the cloud only while that boot pull took less than 2 s of play; after a slower pull
  the tie keeps the run the player is already playing.
- Offline gold uses only server times: the server stamps `last_seen` on every push. While the
  cloud row is still this device's last confirmed push, the time away is the server's now minus
  that `last_seen` minus the game time played since (kept in `cloud_sync.json` next to the save,
  so it survives the OS killing a backgrounded app). Play while that pull is in flight comes
  after the server's now, so it does not shorten the absence. Another device's row, or an
  unreachable server, pays nothing.
- The game pushes after each sync, every 60 s, on focus loss, and when the window is closed
  (after any push already in flight, waiting at most 3 s in total). Requests cannot finish while
  a mobile app is suspended, so suspend pushes nothing.
- Nothing is pushed until a sync has pulled the cloud, so a device that booted offline never
  overwrites progress stored by another one; until then the 60 s timer retries the sync. That
  retry runs mid-play, so only a cloud save strictly ahead replaces the run; a tie keeps it.
- A hosted project is set with the project settings `cloud/url` and `cloud/api_key`
  (publishable key); the defaults point at the local stack.

## Stat upgrades

Gold buys five stats in the upgrade panel:

| Stat | Start | Per level | Max |
|---|---|---|---|
| Attack | 10 | ×1.12 | — |
| Health | 100 | ×1.12 | — |
| Crit Chance | 5.0% | +0.5% | level 90 (50%) |
| Crit Damage | 150% | +5% | — |
| Attack Speed | 1.50/s | +0.02/s | level 75 (3.00/s) |

A maxed stat shows `Max`. Offline gold uses the same hero DPS, so crit and speed upgrades count.

## Skills and spirits

- Skill bar (5 slots): Thunder (stage 1), Meteor (3), Blizzard (5), Fury (8), Shield (12). A
  button shows the skill name when ready, the seconds left while on cooldown, or `Stage N` while
  locked. Damage skills need an enemy in front of the hero; Fury and Shield cast any time.
- Auto-cast unlocks at stage 10. The `Auto-cast` toggle then fires every ready skill during
  combat; it is not saved and starts on after a restart.
- Spirits (3 slots): Wisp (stage 2, +10% attack), Ember Fox (stage 6, +5% crit chance), Frost Owl
  (stage 10, +20% health). Each unlocks from the current stage (again after an ascension) and
  attacks on its own timer while the hero fights.
- Offline gold counts spirit passives and spirit attacks, never active skills. Unlocks derive from
  the saved stage, so the save format is unchanged.
- The panel sits under the upgrades in portrait and in the right column in landscape.

## Ascension and talents

- The `Ascension` button in the HUD opens a full-screen panel (portrait and landscape).
- From stage 20, `Ascend +N shards` pays `stage - 15` ascension shards (5 at stage 20) after a
  confirmation. The run restarts at stage 1 with 0 gold, every upgrade at level 0, buffs cleared
  and skills, auto-cast and spirits locked again; the lane is cleared and the hero is at full
  health. Before stage 20 the button reads `Ascend (Stage 20)` and is disabled.
- Shards buy six permanent talents (max level 10; level n+1 costs n+1 shards). They survive
  ascensions and restarts:

| Talent | Per level | Needs |
|---|---|---|
| Might | +10% attack | — |
| Vitality | +10% health | — |
| Greed | +10% gold (kills, bosses, offline) | — |
| Precision | +1% crit chance | Might 5 |
| Ferocity | +10% crit damage | Might 5 |
| Haste | +3% attack speed | Vitality 5 |

  A row shows `Max` when maxed and `Needs <talent> 5` while locked.

## Dev run flags

Pass these after `--` (they are ignored otherwise):

```bash
scripts/godot.sh --headless --path client --fixed-fps 60 --quit-after 3600 -- --dev-report --save-path=/tmp/soak.json --no-cloud
scripts/godot.sh --path client --resolution 720x1280 -- --screenshot=$PWD/.tmp/portrait.png
```

| Flag | Effect |
|---|---|
| `--dev-report` | prints stage, kills, gold and boss state every 5 s, plus any offline reward |
| `--screenshot=<abs png>` | saves a screenshot after 120 frames and quits |
| `--ascension-panel` | opens the ascension panel on start (for screenshots) |
| `--save-path=<path>` | uses a scratch save file instead of `user://save.json` (and its own `auth.json` next to it) |
| `--no-cloud` | local save only, offline gold from the device clock (GUT and `--import` runs are always local) |

Soak runs with `--fixed-fps` need `--no-cloud`: the engine timer that bounds cloud requests then runs on game time, so requests time out before the server replies.

## Android build (sideload)

The `Android (no cloud)` preset in `client/export_presets.cfg` builds an arm64 APK with the
`no_cloud` feature tag: like `--no-cloud`, the game keeps a local save only and pays offline gold
from the device clock, because the default cloud (the local Supabase stack) is unreachable from a
phone. It needs the Godot 4.7.2 export templates, the Android SDK (`export/android/android_sdk_path`
in the editor settings), a JDK and the editor's debug keystore.

```bash
JAVA_HOME=$(/usr/libexec/java_home) scripts/godot.sh --headless --path client \
  --export-debug "Android (no cloud)" ../build/android/slayer-idle.apk
```

The APK lands in `build/android/` (git-ignored) and is signed with the debug key: install it with
`adb install` or by opening it on the phone with "install unknown apps" allowed.

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
