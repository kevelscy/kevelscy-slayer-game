# Feature: stat-upgrades — gold upgrades for crit chance, crit damage and attack speed
Worked directly on `main`. Phase 2 slice 3: completes the flat stat list of L1 before prestige (prestige resets and boosts these stats, so they must exist first).
Agent decisions D9–D11 are open to user override. Save format moves to version 2 with a lossless v1 migration (high risk: data format).

## Specs

- S1 Stats (L1 verbatim): "Recolección de oro, gemas y experiencia para subir estadísticas planas (Ataque, % Crítico, Daño Crítico, Velocidad, Vida)."
  → three new gold upgrade tracks next to Attack and Health (D9): Crit Chance (base 5%, +0.5% per level, max level 90 = 50%), Crit Damage (base 150%, +5% per level, no max), Attack Speed (base 1.50/s, +0.02/s per level, max level 75 = 3.00/s). A maxed track cannot be bought and costs nothing. Gems and experience stay out of this slice (D10).
- S2 Persistence (D11): the save format becomes version 2 with `crit_chance_level`, `crit_damage_level`, `attack_speed_level` (integers >= 0). A version 1 save still loads, with those three levels at 0, and is written back as version 2 on the next save. Versions other than 1 and 2 are rejected as today ("unsupported save version N"); a version 2 save missing one of the new fields is rejected ("save field '<name>' is missing or not an integer"). A saved level above a track's max loads clamped to the max.
- S3 Offline: offline gold keeps using hero expected DPS, which now includes the upgraded crit and attack speed (phase 1 S1 / skills-spirits S4 still hold).
- S4 UI: the upgrade panel lists Attack, Health, Crit Chance, Crit Damage and Attack Speed, each with level, current value ("5.0%", "150%", "1.50/s" for the rate stats) and an "Up <cost>" button; a maxed track shows "Max" and a disabled button. Portrait and landscape both fit the five rows.

## Tasks

- [x] T1 UpgradeTrack max level + RateUpgradeTrack (TDD) — S1 — inline — commit: 41a4120
- [x] T2 GameSession rate tracks + SaveCodec v2 with v1 migration (TDD, high risk: own commit) — S1,S2,S3 — inline — commit: 6a445b2
- [x] T3 UpgradePanel rows, Max state, README — S4 — inline — commit: 607aed0
- [x] T4 Verify: suite, real v1 save migration, screenshots, soak — S1–S4 — inline — commit: n/a (evidence L5–L8)

## Log

- L1 (original project request, relevant part verbatim): see S1; full text in odd/tasks/phase-1-mvp.md L1.
- L2 (user, verbatim): "sigo tu recomendacion, y seguimos en modo auto" — after the agent recommended stat upgrades first, then prestige/ascension, then the server (backend choice open).
- L3 Decisions by the agent (open to user override): D9 the S1 numbers; D10 gems and experience deferred (no sink exists yet; ascension is the natural place); D11 save v2 with v1 migration instead of a separate migration file.
- L4 Routing: gentle-ai-worker/verify subagents failed in this environment (save-offline L7), tasks run inline; independent verify for the high-risk save change is reported unavailable and replaced by inline migration tests plus a real v1 save load.
- L5 T1 evidence: RED (RateUpgradeTrack missing), GREEN 259/259. UpgradeTrack gained max_level (0 = unlimited) and is_maxed(); scaling tracks keep no cap (pinned by a test). Costs chosen (D9 addendum): Crit Chance 50 x 1.25^level, Crit Damage 40 x 1.2^level, Attack Speed 60 x 1.28^level.
- L6 T2 evidence: RED 15 failing (new SaveData fields and tracks missing), GREEN 267/267. Native review assess (base 41a4120): medium, reviewDue false; independent verifier not run (native tier wins; subagents unavailable per L4).
- L7 T3 evidence: RED (UpgradePanel.rows missing), GREEN 270/270. Screenshots .tmp/su-portrait.png and .tmp/su-landscape.png: five rows "5.0%", "150%", "1.50/s", buttons "Up 50/40/60"; fits both layouts.
- L8 T4 verdict: S1 pass (tracks, caps, Max), S2 pass (real v1 save at stage 12 booted with 0 ERROR/WARNING and was rewritten as version 2 with the three levels at 0 and every other field kept; codec tests cover v0/v3/v99 rejection, v2 missing field, negatives), S3 pass (offline rate test with crit damage and speed levels), S4 pass (screenshots). Soak 7200 frames from a v2 save with crit 90, crit damage 60, speed 75: stage 12 -> 20, 0 ERROR/WARNING, levels preserved on save. Suite 270/270.
