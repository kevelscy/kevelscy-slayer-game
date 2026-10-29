# Feature: cloud-save — Supabase anonymous auth, cloud save and server-validated offline time
Worked directly on `main`. Phase 2 slice 5: the `/server` zone of L1. Local Supabase stack (CLI + Docker), Postgres RPCs instead of Edge Functions (one runtime, pgTAP tests).
High risk: security (auth, RLS) and stored data (cloud overwrite). Agent decisions D18–D24 are open to user override.

## Specs

- S1 Server zone (L1 verbatim): "`/server`: Backend ligero (Node.js/Go o BaaS como Supabase) para autenticación, guardado en la nube (Cloud Save) y validación de marcas de tiempo del progreso offline para mitigar trampas de reloj."
  User choices (L2): Supabase, local with the CLI, anonymous auth, scope "Save + reloj".
  → `server/` is a Supabase CLI project (`supabase/config.toml`, migrations, pgTAP tests) with anonymous sign-ins enabled (D18).
- S2 Storage and access (D19): table `public.cloud_saves` (one row per auth user: `user_id`, `save` jsonb, `save_version`, `last_seen_at`, `updated_at`). RLS on; clients have no direct insert/update/delete and read only their own row. All writes go through `push_save(save jsonb)`; reads through `pull_save()`. Calls without a signed-in user fail.
- S3 Server validation (D20): `push_save` accepts only a save object with `version` 3 and the same field rules as the client SaveCodec (integers `stage` >= 1, `attack_level`, `health_level`, `crit_chance_level`, `crit_damage_level`, `attack_speed_level`, `ascension_shards`, `ascension_count` >= 0; `gold` a string number; `talents` an object of integer levels >= 0). A rejected save raises an error naming the field and leaves the stored row unchanged.
- S4 Server clock (server/README verbatim): "the server owns `last_seen_at`; the client clock is never trusted for offline rewards".
  → `push_save` ignores the client's `last_seen_unix`, stores `last_seen_at = now()` and writes that time back into the stored save; it returns `server_now_unix`. `pull_save()` returns `{save, last_seen_unix, server_now_unix}` (`save` and `last_seen_unix` null when there is no row).
- S5 Client auth (D21): the game signs in anonymously on first boot, keeps the refresh token in `user://auth.json`, and refreshes the session on later boots; a refresh token the server rejects triggers a new anonymous sign-up.
- S6 Boot sync (D22): local save loads first as today, so the game never waits on the network. Then the cloud is pulled:
  - cloud save present and with more progress than the local one (compare `ascension_count`, then `stage`, then the sum of the five upgrade levels; ties go to the cloud) → it replaces the session state;
  - offline gold uses server time only: `server_now_unix - last_seen_unix` of the cloud row, capped at 8 h as today, and only when the cloud save was applied or equals the local progress; when the local save has more progress (played without network) no offline gold is paid that boot;
  - after the pull the current session is pushed.
- S7 Unreachable or disabled cloud (D23): when the cloud cannot be reached, the game keeps playing on the local save and pays no offline gold (the device clock is never trusted). With the cloud disabled (tests and `-- --no-cloud`) the existing device-clock behaviour is kept.
- S8 Ongoing sync (D24, D25): the session is pushed every 60 s while playing, on suspend/focus loss and when the window is closed (the close waits up to 3 s for the push, L8); on mobile resume the suspended time is paid from a fresh `pull_save` (server time), never from the device clock.
- S9 Docs: README (root and `server/README.md`) explain how to start the local stack, run the server tests and point the client at it.

## Tasks

- [x] T1 Server: supabase init in server/, anonymous sign-ins, migration (cloud_saves, RLS, push_save/pull_save with validation and server clock), pgTAP tests (high risk: own commit) — S1–S4 — inline — commit: 9f40901
- [x] T2 Client HTTP layer: CloudConfig, SupabaseAuth (anon sign-up, refresh, token file), CloudSaveClient (pull/push) over an injectable transport (TDD with a fake) — S5 — inline — commit: 97daf68
- [x] T3 Sync policy: CloudSync boot/resume/push schedule, progress comparison, server-time offline gold, unreachable fallback (TDD, high risk: own commit) — S6–S8 — inline — commit: d370caf
- [x] T4 Wire GameState + config + `--no-cloud`/scripts, README and server/README — S7, S8, S9 — inline — commit: (this commit)
- [ ] T5 Verify against the real local stack: anonymous sign-in from the game, push/pull, RLS from a second user, server-time offline reward with a shifted `last_seen_at`, unreachable fallback — S1–S9 — inline — commit: n/a

## Log

- L1 (original project request, relevant part verbatim): see S1; full text in odd/tasks/phase-1-mvp.md L1.
- L2 (user choices, 2026-10-29 session): backend "Supabase (Recomendado)"; environment "Local con CLI (Recomendado)"; auth "Anónimo (Recomendado)"; scope "Save + reloj (Recomendado)". The user approved installing the Supabase CLI with brew; Docker runs on OrbStack.
- L3 Decisions by the agent (open to user override): D18 server/ is the Supabase project root; D19 RPC-only writes with RLS; D20 server validation mirrors SaveCodec v3; D21 anonymous auth with a refresh token file; D22 progress-based conflict rule, ties to the cloud, no offline gold when the local save is ahead; D23 no offline gold when unreachable; D24 60 s cloud push.
- L4 Routing: subagents fail in this environment (save-offline L7), all tasks inline; the independent verifier is reported unavailable and replaced by pgTAP security tests plus T5 against the real stack.
- L5 T1 evidence: Supabase CLI 2.122.0 (brew), local stack with realtime, storage, analytics, edge runtime and local SMTP disabled; publishable key `sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH` (local default, public). pgTAP RED (cloud_saves missing), GREEN 33/33 after the migration. HTTP smoke on the real stack: anonymous sign-up token, push_save stamped server time over client last_seen_unix 1, version 2 rejected with 22023 "unsupported save version 2", anon pull_save and table read denied (42501). Native assess (base 6defe1b): risk medium, not due; native tier unassessable because of the pre-existing untracked .vscode/ and client/.mcp.json; native review deferred to the end of the feature (as ascension L12).
- L6 T2 evidence: RED (CloudConfig/SupabaseAuth/CloudSaveClient/CloudPullResult missing, parse errors), GREEN 324/324 (5057 asserts). One fix: a damaged token file logged an engine JSON error, now parsed with a JSON instance. Push embeds SaveCodec.encode as is so integers stay integers in the body. GodotHttpTransport (real HTTPRequest) has no unit test; T5 covers it against the real stack.
- L7 T3 evidence: RED (CloudSync missing; SaveController.device_clock_offline missing), GREEN 339/339 (5107 asserts) after one fix (typed Array[int] loop over an untyped literal in compare_progress). Rule refinement inside S6/S8: offline gold is paid only when, after the pull, the cloud save holds the same progress as the session (boot: cloud applied or tied; resume: the suspend push reached the cloud); resume never rolls the session back. Open for T4: applying a cloud save on boot changes the stage under a running BattleWorld, so the world must restart like after ascending.
- L8 T4 decisions: D25 a request cannot finish once the tree exits, so the exit push became a window-close push: with the cloud on GameState turns off auto-accepted quits and close_game() saves, pushes and waits at most 3 s before quitting (without it the next boot would see the local save ahead and pay no offline gold). D26 applying a save (local or cloud) now resets the running game like an ascension: buffs, cooldowns and spirits relock, then unlock for the saved stage; GameSession.save_applied makes BattleWorld restart the lane. GUT runs and `-- --no-cloud` stay local-only; `-- --save-path` keeps its own auth.json.
- L9 T4 evidence: RED (save_applied missing, spirits kept unlocked; GameState cloud API missing), GREEN 347/347. READMEs: root Cloud save section and `--no-cloud` flag; server/README with the local stack, RPCs and error codes.
