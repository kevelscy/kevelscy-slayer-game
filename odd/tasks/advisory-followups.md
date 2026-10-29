# Cloud-advisories review follow-ups

Fixes the 4 non-blocking findings of the cloud-advisories native review (odd/tasks/cloud-advisories.md L3).
The reviewer text was not kept; the specs restate each finding from its file:line and title. Client only.

## Specs

- S1 Scratch clear failure (R4-scratch-clear-failure-still-loads, game_state.gd:48-51): a tool run whose
  scratch save cannot be cleared reports it with `push_error` and starts a new game instead of loading the
  previous run's save.
- S2 Root chmod test (R3-chmod-test-fails-when-run-as-root, test_game_state.gd:146-149): the unremovable-save
  test is pending when the suite runs as root, which ignores folder permissions.
- S3 Shared reward (R3-waiter-receives-same-reward-as-inflight-caller, cloud_sync.gd:74-75): a sync waiting on
  the sync in flight gets its own copy of that reward; the reward is paid and announced once.
- S4 Unbounded wait (R4-sync-waiter-unbounded, cloud_sync.gd:74-75): the code documents that the wait ends
  with the sync in flight, whose requests each end within `GodotHttpTransport.TIMEOUT_SECONDS`.

## Tasks

- [x] T1 S1-S2 scratch save — inline — 9518200
- [x] T2 S3-S4 sync waiter — inline — 4e4facc
- [x] T3 suite, review, push — inline — this docs commit

## Log

- L1 (user, verbatim): "vamos con todos los pendientes, dejas de ultimo las features neuvas"
- L2 Evidence. T1 9518200: RED (`GameState.prepare_save` and `SaveController.boot(load_existing)` missing),
  GREEN; a scratch save in a read-only folder makes `prepare_save` return false with the `push_error`, and
  `boot(false)` starts stage 1 over a stage 4 save; the locked-folder tests are pending as root (S2, no
  meaningful RED without root). T2 4e4facc: RED (two concurrent resumes got the same reward object), GREEN
  (each gets its own equal copy, one `offline_reward_granted`). Full scripts/test.sh 370/370, exit 0; the
  real `save.json` and `auth.json` kept the same SHA-1.
- L3 Native review review-b03e54d082585f8a (base 0ad8c73, committed-only, untracked .vscode/ and
  client/.mcp.json excluded; assess was unassessable with undeclared untracked files, so the review ran from the
  Task Size high-risk item: concurrent sync). Tier medium, 172 lines, lenses resilience/reliability: approved on
  the first pass, acknowledged (authority burned). Non-blocking findings (reviewer text not kept):
  R3-001 WARNING cloud_sync.gd:79-80 (the waiter's early return), R3-002 SUGGESTION game_state.gd:53
  (`saves.boot(load_existing)`). Left for the backlog after the ascension findings.
