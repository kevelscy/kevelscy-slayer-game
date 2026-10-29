# Feature: save-offline — local save + in-game offline income
Branch `feat/save-offline` off `main`. Phase 2 slice 1: persist the run locally and grant offline gold on boot/resume.
Cloud save and server time validation stay for the `/server` slice; this slice keeps a trusted-clock seam for it.

## Specs

- S1 Offline (L1 verbatim): "**Cálculo Offline (Idle):** Fórmula determinista ($DPS \times \text{Tiempo validado}$) calculada al iniciar sesión, sin mantener procesos activos innecesarios en segundo plano en dispositivos móviles."
  → offline gold = kills_per_second(expected DPS, regular enemy health, spawn interval) × gold per kill × validated elapsed; computed on boot and on app resume, never by a background process; clock moving backwards → 0; elapsed capped at 8 h (decision D1).
- S2 Server (L1 verbatim, deferred): "`/server`: Backend ligero (Node.js/Go o BaaS como Supabase) para autenticación, guardado en la nube (Cloud Save) y validación de marcas de tiempo del progreso offline para mitigar trampas de reloj."
  → this slice reads "now" through one injectable clock so the server can replace it later; no network code.
- S3 Save content (decision D2): version, stage, gold wallet, attack level, health level, last_seen_unix. Loading restarts the saved stage with kills 0 and no active boss.
- S4 Save safety (decision D3): versioned JSON at `user://save.json`, written atomically (temp file + rename). A missing file starts a new game; a malformed, wrong-version or out-of-range save is rejected as a whole (nothing applied, error reported) and moved aside to `user://save.rejected.json` before the fresh game saves, so it is never silently lost. Values beyond 1e308 survive (BigNumber serialize/parse).
- S5 Save triggers (decision D4): autosave every 30 s, on app pause / focus loss and on window close.
- S6 Feedback: a "Welcome back" toast shows offline gold and time away when the reward is not empty.

## Tasks

- [x] T1 SaveCodec (encode/decode/validate) + GameSession.to_save/apply_save (TDD) — S3,S4 — inline — commit: 4e1f187
- [x] T2 SaveStore atomic read/write with injectable path (TDD) — S4 — inline — commit: 71ba887
- [x] T3 Offline income: GameSession.offline_gold_rate + grant via OfflineCalculator (TDD) — S1 — inline — commit: 9341473
- [x] T4 GameState wiring (load/offline on boot+resume, autosave, clock seam) + welcome-back toast + README — S1,S2,S5,S6 — inline — commit: 144579d
- [x] T5 Verify: suite, soak, restart persistence, faked last_seen offline grant, corrupt-save rejection — S1–S6 — inline (gentle-ai-verify unavailable) — commit: n/a
- [x] T6 Review follow-ups: abort write on store/IO error, discard leftover .tmp on load, GameState notification tests, toast tween restart — S4,S5,S6 — inline — commit: see L9

## Log

- L1 (original project request, relevant part verbatim): see S1 and S2 quotes; full text in odd/tasks/phase-1-mvp.md L1.
- L2 (user, verbatim): "arranca, sigue con tu ejecucion" — answer to "¿Arrancamos con la barra de habilidades y los espíritus, o primero con el guardado y el cálculo offline dentro del juego?"; no choice given, so the agent picked save + offline first (foundation for later systems and cloud save).
- L3 Decisions by the agent (open to user override): D1 8 h offline cap; D2 stage-only restore; D3 versioned JSON + atomic write + whole-save rejection; D4 autosave 30 s + pause/close.
- L4 Decision: S4 refined — a rejected save is moved to `save.rejected.json` instead of being overwritten by the fresh game.
- L5 Slice boundary: slice 1 = T1+T2 (4e1f187, 71ba887, ~430 lines, save foundation); slice 2 = T3+T4. Push/PR stays the user decision.
- L6 Evidence (inline, before independent verify): suite 176/176. Real runs with --save-path=/tmp/slayer-verify/save.json: run1 fresh 60 s → 0 ERROR/WARNING, save stage 2 gold 151 (found + fixed: --quit-after/quit() skipped the close-request save → GameState now saves in _exit_tree); run2 last_seen −2 h → "Welcome back! +26.5K gold (2h 00m away)", stage 2 kept; run3 corrupt save → "SaveController: save rejected (save is not a JSON object); starting a new game", save.rejected.json holds the bad bytes, fresh save written; run4 last_seen +1 day (clock moved back) → no reward, gold unchanged 50. Toast screenshot .tmp/toast_720x1280.png reviewed; upgrade buttons confirmed enabled (grey is the default theme).
- L7 Verify: gentle-ai-verify subagent failed ("assistant reported an error"), not retried. Native RDD assess (base origin/main, 844 lines): tier medium, reviewDue false, no independent verifier required → inline evidence in L6 stands. Known limitation (S2): moving the device clock forward still pays up to 8 h; fixed only by server-validated time.
- L8 (user, verbatim): "a partir de ahora trabajaremos en la rama de main, asi que todo lo que trabajaaste en la rama actual, muevelo a main y comienza a trabajar desde main" — feat/save-offline fast-forwarded into main (1a6bd16) and the merged branch deleted; work continues on main.
- L9 T6 evidence: RED 2 failing (.tmp left after load), GREEN suite 183/183; GameState notification tests cover existing behavior (pass from the start). Write-failure branch has no deterministic test (store_string failure needs a full disk). Real run /tmp/slayer-t6: fresh run 0 ERROR/WARNING; last_seen −2 h + junk save.json.tmp → "Welcome back! +27.6K gold (2h 00m away)", .tmp removed.
