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

- [ ] T1 S1 payload cap — inline — feat(server) migration commit
- [ ] T2 S2-S3 pull latency and boot tie — inline — fix(cloud) commit
- [ ] T3 S4 docs, suite, review, push — inline — docs commit

## Log

- L1 (user, verbatim): "vamos con todos los pendientes, dejas de ultimo las features neuvas"
