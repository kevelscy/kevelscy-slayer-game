# Cloud-hardening advisory findings

Fixes the 3 non-blocking findings of the cloud-hardening native review (odd/tasks/cloud-hardening.md L3).
The reviewer text was not kept; the specs restate each finding from its file:line and title. Client only.

## Specs

- S1 Mid-play tie (R4-tick-sync-widens-tiebreak-window, cloud_sync.gd:117-119): a sync that runs after the
  boot sync failed (the 60 s timer retry, or a resume before the first sync) applies the cloud save only when
  it has strictly more progress than the live session; a tie keeps the session and pushes it. The boot sync
  keeps "ties go to the cloud".
- S2 Concurrent sync (R3-002, cloud_sync.gd:69-72): a sync requested while another is in flight sends no
  second pull and returns the reward of the sync in flight instead of an empty reward.
- S3 Scratch save (R3-001, game_state.gd:47-50): only a tool run that falls back to the scratch save (no
  `--save-path`) clears it at boot; an explicit `--save-path` is never deleted. A scratch save that cannot be
  removed is reported with `push_error` instead of silently loading the previous run's save.
- S4 Docs: README and code comments describe S1-S3.

Deferred (not in this feature): R3-gold-tiebreak-race (the boot sync can still apply a tie after play
started while its pull is slow), R4-boot-latency-cancels-reward, R1-unbounded-save-payload (needs a
migration), the 7 ascension advisory findings.

## Tasks

- [x] T1 S1 mid-play tie keeps the session — inline — fix(cloud) commit
- [x] T2 S2 concurrent sync returns the reward in flight — inline — fix(cloud) commit
- [ ] T3 S3 scratch save clearing — inline
- [ ] T4 S4 docs, suite, review — inline

## Log

- L1 (user, verbatim selection): "(a) Hallazgos de cloud-hardening" — "Los 3 advisory: game_state.gd:47-50, cloud_sync.gd:69-72, cloud_sync.gd:117-119. Recomendado."
