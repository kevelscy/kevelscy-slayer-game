# Cloud-save deferred review findings

Fixes the 3 findings the cloud-save native review left for later (odd/tasks/cloud-save.md L14) that later
features did not already fix. The reviewer text was not kept; the specs restate each finding from its title.

## Specs

- S1 Payload cap (R1-unbounded-save-payload, migration lines 45-73): `push_save` rejects a save whose JSON text
  is larger than 16384 bytes with 22023 `save is larger than 16384 bytes` and leaves the stored save unchanged.
  A real save is about 400 bytes.
- S2 Boot latency (R4-boot-latency-cancels-reward, cloud_sync.gd:44-55): game time played while a pull is in
  flight is not subtracted from the offline time that pull pays; it still counts as play after the paid absence.
- S3 Boot tie race (R3-gold-tiebreak-race, cloud_sync.gd:44-55): the boot sync gives an exact tie to the cloud
  only while less than 2 s of game time ran during its pull; after that the tie keeps the running session, like
  the mid-play rule (odd/tasks/cloud-advisories.md S1).
- S4 Docs: README and code comments describe S1-S3.

## Tasks

- [x] T1 S1 payload cap — inline — 8253700
- [x] T2 S2-S3 pull latency and boot tie — inline — 2184be5
- [x] T3 S4 docs, suite, review, push — inline — docs commits

## Log

- L1 (user, verbatim): "vamos con todos los pendientes, dejas de ultimo las features neuvas"
- L2 Evidence. T1 8253700: pgTAP RED (an oversized save was stored), GREEN 36/36 after `supabase migration up`
  (no `db reset`, which would wipe the local player's row); a save of exactly 16384 bytes is stored. T2 2184be5:
  RED against the previous cloud_sync.gd (resume paid HOUR - 55 instead of HOUR - 40, the marker kept 3600 instead
  of 3615, a boot pull with 2 s of play applied the tie), GREEN 32/32; a 1.9 s boot pull still gives the tie to the
  cloud. Full scripts/test.sh 373/373, exit 0; real save.json/auth.json SHA-1 unchanged. Real run on the migrated
  stack (`--save-path=/tmp/cd-verify/save.json`, 600 frames): no warnings, the push was acknowledged.
- L3 Native review review-cdafddcbc63bc10e (base 3bcba3c, committed-only, untracked .vscode/ and client/.mcp.json
  excluded; assess unassessable with undeclared untracked files, so the review ran from the Task Size high-risk
  items: cloud overwrite rule and a server contract). Tier medium, 185 lines, lenses risk/resilience/reliability:
  approved on the first pass, acknowledged (authority burned). Non-blocking findings (reviewer text not kept):
  R3-001 WARNING cloud_sync.gd:190-192 (play-during-pull accounting in `_grant`), R3-002 WARNING cloud_sync.gd:110
  (grant after an applied cloud save). Left for the backlog after the ascension findings.
