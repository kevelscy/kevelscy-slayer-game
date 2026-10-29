# Enemy art (Slayer Legend style)

Replace the pack enemies (slime, bat, skeleton, spider boss) with original Pixelorama art that
follows `client/art/STYLE.md`, then wire each one into the game. One enemy per task.

## Specs

- S1 Every asset follows `client/art/STYLE.md` (palette `paleta_juego.gpl` only, chibi, 1px dark outline lightened top-left, 3-4 tones, light from top-left; heroes/enemies 32-48px, bosses 128px+; idle 2-4 frames, attack 4-6 frames; 10-12 fps). Enemies face left (the hero faces right).
- S2 "Antes de crear cada asset, dime qué vas a hacer y su tamaño." / "Revisa cada asset con get_image antes de exportarlo."
- S3 Save the `.pxo` in `client/art/source/`; export transparent PNG horizontal spritesheets in `client/art/sprites/`.
- S4 "Al terminar, dime qué archivos creaste y sus dimensiones."
- S5 Godot: textures imported with Nearest filter and no mipmaps.
- S6 An enemy with an idle animation plays it while it stands at the hero, and its move animation while it advances (enemies without idle keep their single animation).

## Tasks

- [x] T1 S1-S6 slime: idle 4 frames + move 6 frames, 32x32 → `slime_idle.png` 128x32, `slime_move.png` 192x32; EnemyDefinition idle sheet + Enemy idle/move switch; wire, tests, screenshot — inline — commit: 3ef6371
- [ ] T2 S1-S5 bat (size announced before drawing) — inline — commit: -
- [ ] T3 S1-S5 skeleton (size announced before drawing) — inline — commit: -
- [ ] T4 S1-S5 boss 128px+ (size announced before drawing) — inline — commit: -

## Log

- L1 (user) "dale arranca!" — answering: "Si seguimos con los enemigos, arranco por el slime: idle de 4 frames y move de 6, en frames de 32x32 (sheets de 128x32 y 192x32), y te lo muestro antes de exportarlo. ¿Le doy?"
- L2 Enemies played a single animation (`move`) even while stopped at the hero, so the slime idle needs Enemy to switch animations (S6). The palette has no greens: the slime is turquoise (Azul 1, Azul 2, Turquesa, Cian, Blanco), a cold enemy against the warm hero.
- L3 Pixelorama MCP: after `new_project`, `save_project`/`export_png` kept the previous tab (slime_idle came out 192x32 with the move frames) until a `get_image` ran; sheet_load.sh now calls it. Exports verified: `slime_idle.png` 128x32 [442, 439, 432, 439] px per frame, `slime_move.png` 192x32 [420, 458, 458, 453, 460, 420], palette-only, no semi-transparent px; `.pxo` 4 and 6 frames.
- L4 T1 wired: EnemyDefinition.idle_animation (optional), Enemy plays idle at min_x and move otherwise (also after a thaw), slime 32x32 at scale 1.0 (move 6f 12 fps, idle 4f 10 fps). tests/unit/entities/test_enemy_art.gd RED then GREEN (the bat test pins enemies without idle); suite 399/399. In game (scratch slime-only roster, `--no-cloud`, scratch save): slimes hop in, the front one idles at the hero, feet on the ground line, no errors.
- L5 (user) "para, se acaba la ventana de contexto, guarda todo en engram status actual y pendientes, retomamos en la siguiente sesion" — stopped after T1 was pushed (7cfd4e9). Proposed next (not yet confirmed): T2 bat, fly 4 frames 40x32 → `bat_fly.png` 160x32, 12 fps, no separate idle, same hover height.
