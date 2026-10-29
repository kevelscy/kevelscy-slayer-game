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

- [x] T1 S1 move `art/` to `client/art/`, update STYLE.md paths — inline — commit: 619082f
- [x] T2 S2-S5 hero attack, 6 frames 96x48 (hero centered as in idle) → `hero_attack.png` 576x48 — inline — commit: e0a821f
- [x] T3 S2-S5 hero run, 6 frames 48x48 → `hero_run.png` 288x48 — inline — commit: 623a8e0
- [x] T4 S2-S5 hero hurt (2 frames) and die (4 frames) 48x48 → `hero_hurt.png` 96x48, `hero_die.png` 192x48 — inline — commit: 80a0cad
- [ ] T5 S6 wire the hero AnimationSet to the new sheets (48px frames, 10-12 fps, sprite offset), tests, screenshot — inline — commit: see L5 (screenshot pending)

## Log

- L1 (user) "1. y sigue ocn tu ejecucion" — answering: move `art/` into `client/art/` (option 1), then continue with the hero attack (6 frames 48x48, 288x48 sheet).
- L2 Hero idle already done before this document: `e92fa05` (`hero_idle.png` 192x48).
- L3 Attack frames widened to 96x48: a 36 px sword swung forward does not fit 48 px. The hero keeps the idle position relative to the frame center so a centered AnimatedSprite2D does not jump between animations.
- L4 Pixelorama MCP: `add_frame` lands asynchronously; drawing in the same batch hit a shifted frame (frame 4 empty, frame 5 doubled). Fix: create frames in a separate call, check `frames`, and pass `frame`/`layer` to `draw_pixels`. Per-frame pixel counts of the export now match the generated frames.
- L5 T5 wired: generate_mvp_content.gd hero table -> res://art/sprites (idle 4f 10fps, run 6f 12fps, attack 96x48 6f 12fps, hurt 2f 10fps, die 4f 10fps), hero_animations.tres regenerated (enemy .tres unchanged), Sprite offset (0,-22). tests/unit/entities/test_hero_art.gd RED then GREEN; suite 395/395. Pending: in-game screenshot (run with `--save-path=` scratch + `--no-cloud` so the real save is untouched), push.
- L6 (user) "para, se acaba la ventana de contexto, guarda todo en engram status actual y pendientes, retomamos en la siguiente sesion"
