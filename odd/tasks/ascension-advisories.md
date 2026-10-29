# Ascension advisories

Fixes the 7 non-blocking findings of the ascension native review (review-166b380dc3a5da41,
odd/tasks/ascension.md L12). The reviewer text was not kept; each spec states the reading
recorded at the reviewed commit cab903f.

## Specs

- S1 (R3-001, WARNING, game_session.gd ascend): ascending pays the shards and counts the
  ascension before it resets the run, so a listener of the reset signals (stage_changed,
  wallet changed) already reads the new shard balance and ascension count.
- S2 (R2-001, R3-002, battle_world.gd _restart_run): restarting the lane after an ascension
  or an applied save gives the hero the session's max health and a living hero at full health
  right away, also when the hero was dead; the Dead state does not revive it a second time.
- S3 (R2-002, R2-003, talent_tree.gd): set_levels reads the save's String-keyed talent levels
  only, and gold_multiplier sums the gold talents without looking each level up by id.
- S4 (R2-004, game_session.gd talents / ascension_count): the session documents that only
  its own rules (ascend, apply_save, talent purchases) change these fields; views read them.
- S5 (R3-003, main.gd): a test pins that the HUD ascension button opens the ascension panel
  and that the panel starts hidden without the --ascension-panel dev flag.

## Tasks

- T1 S1 inline, test-first — commit:
- T2 S2 inline, test-first — commit:
- T3 S3 inline, test-first — commit:
- T4 S4 inline, docs only — commit:
- T5 S5 inline, test — commit:
- T6 native review, push to main — commit:

## Log

- L1 User (verbatim): "vamos con todos los pendientes, dejas de ultimo las features neuvas"
- L2 User (verbatim, 2026-10-29 resume): "retomá la última sesión"
