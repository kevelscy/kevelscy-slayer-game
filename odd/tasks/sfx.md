# Sound effects (SoundCraft)

Original synthesized sound effects made with SoundCraft CLI 0.8.0 (no third-party samples),
exported as WAV into `client/audio/sfx/` and played by the game on combat, skills and progression events.

## Specs

- S1 Sounds are made with SoundCraft: "yo ya tengo soundcraft descargado, necesitas un mcp activo dentro del programa? dime como hacerlo para avisarte" / "dale play".
- S2 Before creating each sound, say which sound it is and how long it lasts (carried over from the art rule "Antes de crear cada asset, dime qué vas a hacer y su tamaño.").
- S3 Every sound is original (synthesized in SoundCraft); its recipe (`.txt` command script) and session (`.scraft`) live in `client/audio/source/`, its WAV (44.1 kHz, 16-bit) in `client/audio/sfx/`.
- S4 The game plays each sound on its event: hero hit, critical hit, enemy killed (coin), each skill cast (thunder, meteor, blizzard, fury, shield), spirit attack, upgrade or talent bought, boss appears, boss defeated, hero dies, ascension, tab change.
- S5 Frequent sounds never stack into noise: a sound replayed within its minimum interval is skipped, and each sound has a polyphony cap.
- S6 Sounds go through an `SFX` audio bus so a later settings toggle can mute them.

## Sound list

| id | event | length |
|---|---|---|
| hit | hero hits an enemy | 0.12 s |
| crit | critical hit | 0.30 s |
| coin | enemy killed (gold) | 0.25 s |
| spirit | spirit attack | 0.15 s |
| thunder | Trueno cast | 0.60 s |
| meteor | Meteoro cast | 0.80 s |
| blizzard | Ventisca cast | 0.70 s |
| fury | Furia cast | 0.50 s |
| shield | Escudo cast | 0.50 s |
| upgrade | upgrade or talent bought | 0.35 s |
| ui_tap | bottom tab changed | 0.06 s |
| boss_start | boss appears | 1.00 s |
| boss_defeat | boss defeated | 1.20 s |
| hero_death | hero dies | 0.80 s |
| ascension | ascension confirmed | 1.50 s |

## Tasks

- [x] T1 S3,S5,S6 `SfxPlayer` (systems/audio) + `SFX` bus + catalog, tests RED then GREEN — inline — commit: b2ca925
- [x] T2 S1-S4 combat sounds hit, crit, coin, spirit + wiring, tests — inline — commit: b2ca925
- [ ] T3 S1-S4 skill sounds thunder, meteor, blizzard, fury, shield + wiring, tests — inline
- [ ] T4 S1-S4 progression/UI sounds upgrade, ui_tap, boss_start, boss_defeat, hero_death, ascension + wiring, tests — inline
- [ ] T5 S4 in-game run without errors, ASSETS.md audio section — inline

## Log

- L1 (user, verbatim): "yo ya tengo soundcraft descargado, necesitas un mcp activo dentro del programa? dime como hacerlo para avisarte"
- L2 (user) approved installing `soundcraft-cli` to `~/.local/bin` and registering the MCP (read/write roots confined to `client/audio`). MCP tools load only after a session restart, so this session drives the CLI (`soundcraft-cli run`/`script ... --bounce`), the same command set.
- L3 (user, verbatim): "dale play"
- L4 Decisions (auto mode): enemy killed plays `coin` only (no separate death sound, less noise); sounds are owned by an `SfxPlayer` node wired from `Main` (main → systems), the battle world exposes a hit signal; no settings UI in this feature (bus ready for it).
- L5 T1+T2 (b2ca925): SfxPlayer + SFX bus + SfxDirector (Main) + BattleWorld.enemy_hit; hit 0.12 s, crit 0.30 s, coin 0.25 s, spirit 0.15 s built by client/audio/source/build_sfx.py (SoundCraft script → .scraft → convert 16-bit normalize → 10 ms fade-out). MIDI is 960 PPQ at 120 BPM (1.92 ticks per ms); with N tracks the clips take ids N+1..2N. Tests RED then GREEN; suite 465/465.
- L6 (user, verbatim): "para, se acaba la ventana de contexto, guarda todo en engram status actual y pendientes, retomamos en la siguiente sesion" — stopped at T3 (skill sounds announced: thunder 0.60 s, meteor 0.80 s, blizzard 0.70 s, fury 0.50 s, shield 0.50 s; recipes not written yet).
