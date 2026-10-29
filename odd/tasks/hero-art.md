# Hero art (Slayer Legend style)

Replace the pack hero (64x64) with original 48x48 Pixelorama art that follows
`client/art/STYLE.md`, then wire it into the game.

## Specs

- S1 Art lives inside the Godot project: "1." (answer to "Mover `art/` a `client/art/`").
- S2 Every asset follows `client/art/STYLE.md` (palette `paleta_juego.gpl` only, chibi, 1px dark outline lightened top-left, 3-4 tones, light from top-left, oversized weapon; idle 2-4 frames, attack 4-6 frames with anticipation, hit and recovery; 10-12 fps).
- S3 "Antes de crear cada asset, dime qué vas a hacer y su tamaño." / "Revisa cada asset con get_image antes de exportarlo."
- S4 Save the `.pxo` in `client/art/source/`; export transparent PNG horizontal spritesheets in `client/art/sprites/`.
- S5 "Al terminar, dime qué archivos creaste y sus dimensiones."
- S6 Godot: textures imported with Nearest filter and no mipmaps.

## Tasks

- T1 S1 move `art/` to `client/art/`, update STYLE.md paths — inline — commit: pending
- T2 S2-S5 hero attack, 6 frames 48x48 → `hero_attack.png` 288x48 — inline — commit: pending
- T3 S2-S5 hero run, 6 frames 48x48 → `hero_run.png` 288x48 — inline — commit: pending
- T4 S2-S5 hero hurt (2 frames) and die (4 frames) 48x48 → `hero_hurt.png` 96x48, `hero_die.png` 192x48 — inline — commit: pending
- T5 S6 wire the hero AnimationSet to the new sheets (48px frames, 10-12 fps, sprite offset), tests, screenshot — inline — commit: pending

## Log

- L1 (user) "1. y sigue ocn tu ejecucion" — answering: move `art/` into `client/art/` (option 1), then continue with the hero attack (6 frames 48x48, 288x48 sheet).
- L2 Hero idle already done before this document: `e92fa05` (`hero_idle.png` 192x48).
