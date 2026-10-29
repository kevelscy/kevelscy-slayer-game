# Background art (Slayer Legend style)

Replace the CC0 forest pack backgrounds (4 layers 272x160 + a flat ground ColorRect) with
original Pixelorama parallax layers that follow `client/art/STYLE.md`, then wire them.

## Specs

- S1 Every asset follows `client/art/STYLE.md`: "Usa SOLO la paleta \"paleta_juego.gpl\" (35 colores). No inventes colores fuera de ella."
- S2 "Fondos: tonos oscuros y apagados (marrones, púrpuras y grises oscuros)." / "Poco detalle, formas grandes y simples, 2–3 capas de parallax." / "Más oscuros y menos saturados que los personajes para no competir con ellos."
- S3 "Antes de crear cada asset, dime qué vas a hacer y su tamaño." / "Revisa cada asset con get_image antes de exportarlo."
- S4 Save the `.pxo` in `client/art/source/`; export transparent PNGs in `client/art/tiles/` (layers tile horizontally every 272 px).
- S5 "Al terminar, dime qué archivos creaste y sus dimensiones."
- S6 Godot: Nearest filter, no mipmaps; the battle world scrolls the new layers with the same parallax and the pack backgrounds are removed (ASSETS.md/CREDITS.md updated).

## Tasks

- [x] T1 S1-S5 far layer 272x160 (opaque night sky + distant hills) → `bg_far.png` — inline — commit: f02801c
- [x] T2 S1-S5 middle layer 272x160 (forest canopy silhouettes, transparent sky) → `bg_middle.png` — inline — commit: f02801c
- [x] T3 S1-S5 front layer 272x160 (sparse dark trunks and grass, transparent) → `bg_front.png` — inline — commit: f02801c
- [x] T4 S1-S5 ground strip 272x32 (dirt path, scrolls with the hero) → `bg_ground.png` — inline — commit: f02801c
- [x] T5 S6 wire layers in battle_world.tscn (3 parallax + ground), tests, screenshot, remove pack backgrounds, update ASSETS.md/CREDITS.md — inline — commit: 3b65da2

## Log

- L1 (user) "retoma la ultima sesion" — resumed in auto mode with the step recommended at the close of enemy-art: original parallax backgrounds replacing the CC0 forest pack (dark, muted layers; announce sizes before drawing).
- L2 Announced before drawing: bg_far 272x160 opaque (sky bands Sombra fria -> Sombra purpura -> Gris 1 glow, distant range Sombra purpura, near hills Rojo 1; no moon because the 272 px tile repeats inside the 360 px viewport and two moons would show), bg_middle 272x160 (canopy mass), bg_front 272x160 (2 trunks + hanging foliage + grass), bg_ground 272x32 (dirt strip replacing the flat ColorRect). Generator client/.tmp/bg.py writes a 360x192 composite preview; drafts fixed mushroom-like canopies (cut bumps -> one mass filled from the top envelope), diagonal-split shading (-> spherical normal, curved terminator) and hills hidden behind the canopy (sky glow and hills raised).
- L3 Exports verified: bg_far 272x160 43520 px, bg_middle 17564, bg_front 11196, bg_ground 272x32 8704 (match the generator), palette-only, no semi-transparent px; `.pxo` 1 frame each at the right size; imports Nearest (project default), no mipmaps. Reviewed with get_image before export.
- L4 T5 wired: Background children Far/Middle/Front/Ground (Parallax2D, repeat 272, factors 0.1/0.3/0.6/1.0 unchanged), ground sprite at y 160, Ground ColorRect removed. tests/unit/world/test_battle_world_background.gd RED (pack layers, no ground strip) then GREEN; suite 407/407. client/assets/backgrounds removed; ASSETS.md describes the new layers (and keeps the frame numbering note), CREDITS.md: no third-party art left. In game (slime roster, `--no-cloud`, scratch save): characters stand on the dirt strip, read clearly on the dark forest, parallax visible, no errors. Feature CLOSED.
