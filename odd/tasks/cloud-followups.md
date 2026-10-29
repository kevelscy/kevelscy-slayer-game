# Cloud follow-ups

Fixes the 4 non-blocking findings of the advisory-followups review (review-b03e54d082585f8a)
and the cloud-save-deferred review (review-cdafddcbc63bc10e). The reviewer text was not kept;
each spec states the reading recorded for the reviewed lines.

## Specs

- S1 (advisory-followups R3-001, WARNING, cloud_sync.gd:79-80): a caller that waits on the sync
  in flight returns when that sync has finished, its push included, like the caller that started it.
- S2 (cloud-save-deferred R3-002, WARNING, cloud_sync.gd:110): when another device's cloud save
  wins, its offline time starts no earlier than when this device's own play stopped (its last
  acknowledged push plus the play since), so time played here is never paid as time away.
- S3 (cloud-save-deferred R3-001, WARNING, cloud_sync.gd:190-192): the _grant comment states what
  the accounting really does with play during the pull: it is all counted after the server's now,
  which can only lower the next absence's reward, by at most the time before the server answered.
- S4 (advisory-followups R3-002, SUGGESTION, game_state.gd:53): SaveController exposes boot() and
  start_new_game() instead of a boot(load_existing) flag.

## Tasks

- [x] T1 S1 inline, test-first — commit: 17190e7
- [x] T2 S2 inline, test-first — commit: 2da16ba
- [x] T3 S3 inline, docs only — commit: 63a0717
- [x] T4 S4 inline, refactor under existing tests — commit: 46fae37
- [x] T5 native assess, push to main — commit: this log entry (L4)

## Log

- L1 User (verbatim): "vamos con todos los pendientes, dejas de ultimo las features neuvas"
- L2 User (verbatim, 2026-10-29 resume): "retomá la última sesión"
- L3 Evidence: T1 RED pushes seen by the waiter `[0] != [1]`, then GREEN (the sync emits
  _sync_finished after its push). T2 RED `3590` expected `3575`, then GREEN (_grant starts at
  max(last_seen, acked + play before the pull)); a device that never pushed still pays from the
  row's last_seen. T4 has no meaningful RED: the boot test now calls start_new_game() and checks
  no reward is announced. Full suite 380/380.
- L4 Native assess (base ec137d5, committed-only): risk medium, no reviewDue and no independent
  verifier, so no native review was started. Pushed to origin/main.
