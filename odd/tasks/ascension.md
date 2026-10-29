# Feature: ascension — prestige reset for ascension shards and a permanent talent tree
Worked directly on `main`. Phase 2 slice 4: the last core mechanic of L1. Save format moves to version 3 (high risk: data format).
Agent decisions D12–D17 are open to user override.

## Specs

- S1 Ascension (L1 verbatim): "**Prestigio / Ascensión:** Reseteo de nivel a cambio de fragmentos de ascensión y árbol de talentos permanente."
  → ascending is possible from stage 20 (D12) and pays `stage - 15` ascension shards (5 at stage 20, D13). It resets the run: stage 1 with fresh progress, gold 0, all five upgrade levels 0, active buffs cleared, skills and spirits relocked because their unlocks follow the stage (D14). Shards, the ascension count and talent levels are kept. Ascending below stage 20 does nothing.
- S2 Talent tree (D15): six talents bought with shards; buying level n+1 costs n+1 shards; max level 10 each.
  Tier 1 (always available): Might +10% attack per level, Vitality +10% health per level, Greed +10% gold per level.
  Tier 2 (needs the named tier 1 talent at level 5): Precision (Might) +1% crit chance per level, Ferocity (Might) +10% crit damage per level, Haste (Vitality) +3% attack speed per level.
  Buying a talent that is maxed, locked or unaffordable does nothing and spends nothing. Talent bonuses apply immediately and survive ascension and restarts.
- S3 Economy: Greed multiplies every gold reward (kills, bosses) and offline gold (D16). Offline gold keeps using hero DPS, which includes talents.
- S4 Persistence (D17): save version 3 adds `ascension_shards` and `ascension_count` (integers >= 0) and `talents` (object of talent id to integer level >= 0). Versions 1 and 2 still load with no shards, no ascensions and no talents and are written back as version 3. A version 3 save missing one of these fields, or with a talent level that is not an integer >= 0, is rejected with the same messages as other fields ("save field '<name>' is missing or not an integer", "save field '<name>' must be >= 0, got N", "save field 'talents' is not an object"). Unknown talent ids are ignored and levels above the max load clamped.
- S5 UI: an "Ascension" button opens a panel with the shard balance, the ascension count, an "Ascend +N shards" button (disabled and labelled "Ascend (Stage 20)" before stage 20) that asks for confirmation, and one row per talent with level, bonus, cost and a buy button ("Max" when maxed, "Needs <talent> 5" while locked). After ascending the battle restarts at stage 1 with the hero at full health. Works in portrait and landscape.

## Tasks

- [ ] T1 Talent core: TalentDefinition, TalentTree (levels, prerequisites, shard costs, stat modifiers, gold multiplier) + generated catalog (TDD) — S2 — inline — commit:
- [ ] T2 GameSession ascension: shards, can_ascend, ascend reset, spirit relock, Greed on gold and offline (TDD) — S1,S3 — inline — commit:
- [ ] T3 SaveCodec v3 with v1/v2 migration + session save/restore (TDD, high risk: own commit) — S4 — inline — commit:
- [ ] T4 UI and world: AscensionPanel, confirm, BattleWorld reset after ascend, max health on Vitality, README — S5 — inline — commit:
- [ ] T5 Verify: suite, real v2 save migration, ascend in a real run, screenshots, soak — S1–S5 — inline — commit: n/a

## Log

- L1 (original project request, relevant part verbatim): see S1; full text in odd/tasks/phase-1-mvp.md L1.
- L2 (user, verbatim): "sigo tu recomendacion, y seguimos en modo auto" — the recommendation was stat upgrades, then ascension, then the server.
- L3 Decisions by the agent (open to user override): D12 ascension from stage 20; D13 shards = stage - 15; D14 skills, spirits and auto-cast relock because unlocks follow the current stage (keeps skills-spirits S5; the alternative is unlocks by best stage reached, which needs another save field); D15 the six-talent tree and costs; D16 Greed applies to all gold; D17 save v3 shape.
- L4 Routing: subagents failed in this environment (save-offline L7), tasks run inline; the independent verifier for the save change is reported unavailable and replaced by migration tests plus a real v2 save load.
