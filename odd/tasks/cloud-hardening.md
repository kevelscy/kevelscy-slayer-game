# Cloud-save hardening

Fixes the data-loss findings left by the cloud-save native review (odd/tasks/cloud-save.md L14) and the
old scripts/test.sh bug that overwrites the real save. Client only; no server migration.

## Specs

- S1 Auth refresh: a refresh answered 408 or 429 keeps the stored player like a network or server failure
  (no sign-up, `ensure_session()` returns false, the token file is unchanged). Only another 4xx (the server
  refused the refresh token) signs up a new anonymous player. Findings R1-any-4xx-refresh-replaces-player,
  R3-auth-identity-loss, R4-rate-limit-forks-identity.
- S2 Push gate: nothing is pushed to the cloud until a boot sync pulled the cloud successfully. Before that,
  `push()` sends no request and fails with "cloud not synced yet"; the 60 s tick retries the boot sync
  (pull, compare, apply or pay, push) instead of pushing; a resume before the first successful sync runs the
  boot sync. Findings R1-unsynced-push-overwrites-cloud, R3-unconditional-push-overwrite,
  R4-push-before-successful-sync.
- S3 Close: closing the window while a push is in flight waits for it, then pushes the current session,
  all within the 3 s close bound. Findings R3-close-inflight-push, R4-close-push-noop-when-in-flight.
- S4 Tool runs: GUT and `--import` runs (scripts/test.sh) never read or write the real `user://save.json`:
  without `--save-path` they use a scratch save cleared at boot. Old ascension pending item.
- S5 Docs: README and code comments describe S1-S4.

Deferred (not in this feature): R3-gold-tiebreak-race, R4-boot-latency-cancels-reward,
R1-unbounded-save-payload (needs a migration), the 7 ascension advisory findings.

## Tasks

- [x] T1 S1 auth transient 408/429 — inline — 9c16983
- [x] T2 S2, S3 push gate and close flush — inline — 2802a8d
- [x] T3 S4 tool runs use a scratch save — inline — f0d5165
- [x] T4 S5 docs, suite, real-stack check — inline — docs(cloud) commit

## Log

- L1 (user, verbatim selection): "Hardening de cloud-save (recomendado)" — "Nueva feature para corregir los hallazgos que pueden perder datos: un refresh de auth que recibe 4xx o 429 crea un jugador nuevo y se pierde el anterior; un push antes del primer sync puede pisar la nube; el push al cerrar no hace nada si ya hay otro en vuelo. Incluye el bug de scripts/test.sh, que pisa el save.json real."
- L2 Evidence. T1 9c16983: RED (408/429 sent a sign-up), GREEN. T2 2802a8d: RED for the push gate, tick retry, resume-before-sync and flush (FakeHttpTransport gained hold()/release() to keep a push in flight); the existing tests now boot through `_boot_synced` because a push without a sync sends nothing. T3 f0d5165: RED (`save_path_for` missing), GREEN; a full scripts/test.sh run left the real `user://save.json` and `auth.json` with the same mtime and SHA-1 (before the fix the save's mtime matched the last test run), and the run wrote `user://tool_run/save.json`. Suite 359/359. Real stack (T4): kong paused at boot on a scratch save -> "CloudSync: sync skipped (cloud sign-in unavailable)", no row; gateway unpaused after 12 s -> the 60 s timer retried the sync, signed up player e9ba78cf, pushed (cloud last_seen_at 14:06:09, stage 2) and `cloud_sync.json` acked that server time. S1-S5 verified (S1/S3 by unit tests; the close flush is not exercised against the real stack).
