# Feature: skills-spirits — skill bar (5 slots) and spirits (3 slots)
Worked directly on `main` (L2). Phase 2 slice 2: active elemental skills with cooldowns and unlockable auto-cast, plus companion spirits with permanent passives and periodic attacks.
Agent decisions D5–D8 are open to user override; placeholder visuals are procedural until real art exists.

## Specs

- S1 Skills (L1 verbatim): "**Barra de Habilidades (5 slots):** Habilidades elementales activas con cooldown (rayos en área, meteoros/fuego, ventiscas, buffs de furia y escudos), con soporte de auto-cast desbloqueable."
  → five slots, one skill each (D5): Thunder (area damage to every living enemy), Meteor (heavy hit on the front enemy), Blizzard (area damage + freezes enemies: no movement, no attacks), Fury (timed attack and attack-speed buff), Shield (timed damage absorb on the hero). Each has a cooldown; a skill is locked until its unlock stage is reached; casting a skill on cooldown or locked does nothing. Damage skills scale with hero attack and need a living target.
- S2 Auto-cast (S1 "auto-cast desbloqueable", D6): auto-cast unlocks at stage 10; once unlocked an "Auto" toggle casts every ready, unlocked skill as soon as it can take effect; before that the toggle is locked.
- S3 Spirits (L1 verbatim): "**Espíritus / Compañeros (3 slots):** Casillas secundarias para mascotas que otorgan bonificaciones pasivas permanentes y ataques automáticos periódicos."
  → three slots, one spirit each (D7), unlocked by stage reached; an unlocked spirit applies a permanent percent bonus to a hero stat and attacks the front enemy every N seconds for a multiple of hero attack.
- S4 Offline (D8): offline gold uses hero DPS including spirit passives plus spirit attack DPS; active skills never count offline. No background processes (phase 1 S1 still holds).
- S5 Persistence (D8): unlocks derive from the saved stage, so the save format stays unchanged (version 1); the auto-cast toggle resets to on after a restart.
- S6 UI: a skill bar with five buttons (name, cooldown countdown or "Lv stage" lock), the Auto toggle and three spirit slots, shown in the landscape right column and under the upgrade panel in portrait.

## Tasks

- [x] T1 Skill core: SkillDefinition, SkillSlot, SkillBar (cooldown, unlock, auto-cast), BuffTracker, HealthComponent shield (TDD) — S1,S2 — inline — commit: (this commit)
- [ ] T2 Spirit core + GameSession wiring (unlock on stage, passives, offline spirit DPS) + generated content (TDD) — S3,S4,S5 — inline — commit:
- [ ] T3 BattleWorld integration: cast effects, freeze, spirit attacks, placeholder VFX — S1,S2,S3 — inline — commit:
- [ ] T4 UI: SkillBarPanel + spirit slots, portrait/landscape layout, README — S6 — inline — commit:
- [ ] T5 Verify: suite, real runs, screenshots portrait/landscape — S1–S6 — inline — commit: n/a

## Log

- L1 (original project request, relevant part verbatim): see S1 and S3 quotes; full text in odd/tasks/phase-1-mvp.md L1.
- L2 (user, verbatim): "a partir de ahora trabajaremos en la rama de main, asi que todo lo que trabajaaste en la rama actual, muevelo a main y comienza a trabajar desde main" — and answered "Habilidades + espíritus (Recomendado)" to "¿Con qué seguimos en la fase 2?".
- L3 Decisions by the agent (open to user override): D5 skill catalog and stage unlocks (Thunder 1, Meteor 3, Blizzard 5, Fury 8, Shield 12); D6 auto-cast at stage 10, toggle not persisted; D7 spirits Wisp (stage 2, +10% attack), Ember Fox (stage 6, +5% crit chance), Frost Owl (stage 10, +20% health); D8 offline counts spirits but not skills, no save format change.
- L4 Routing: gentle-ai-worker/verify subagents fail in this environment (save-offline L7), so tasks run inline.
