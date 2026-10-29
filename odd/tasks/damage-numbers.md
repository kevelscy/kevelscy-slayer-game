# Damage numbers (Slayer Legend style)

Show every hit an enemy takes as a big pixel number that floats up and fades, drawn
with an original Pixelorama bitmap font that follows `client/art/STYLE.md`.

## Specs

- S1 "Números de daño grandes en rojo vivo (#f4170b) con contorno oscuro." (`client/art/STYLE.md`)
- S2 Every asset follows `client/art/STYLE.md` (palette `paleta_juego.gpl` only, 1px dark outline lightened top-left, 3-4 tones, light from top-left).
- S3 "Antes de crear cada asset, dime qué vas a hacer y su tamaño." / "Revisa cada asset con get_image antes de exportarlo."
- S4 Save the `.pxo` in `client/art/source/`; export transparent PNGs in `client/art/`.
- S5 "Al terminar, dime qué archivos creaste y sus dimensiones."
- S6 Godot: the font covers every character `NumberFormat.format` can print for damage (`0-9 . K M B T a-z`), Nearest filter, no mipmaps; every damage an enemy takes (hero hit, skill, spirit) shows its `NumberFormat` text above that enemy, floats up and fades; critical hits use the gold font.

## Tasks

- [x] T1 S1-S5 `damage_font.png` and `damage_font_crit.png` 369x11 (41 glyphs, 9x11 cells) — inline — commit: 1fa444a
- [x] T2 S6 image-font import, pooled DamageNumber in the battle world, wired to enemy damage; tests, screenshot — inline — commit: 54df1e0

## Log

- L1 (user) "retoma la ultima sesion" — resumed after skill-icons; the recommended next art was "Números de daño grandes en rojo vivo (#f4170b) con contorno oscuro." No damage numbers exist yet (HealthComponent.damaged emits DamageResult with is_critical, nothing shows it).
- L2 Decision (auto mode): bitmap font drawn in Pixelorama (not a Label outline on the UI font) so numbers stay pixel art inside the 360x192 battle viewport. Lowercase suffix letters are small caps 7x7. Crits use a gold copy of the font (STYLE keeps normal hits red). Reversible.
- L3 Landscape layout (1600x900) checked with the taller skill buttons: skills wrap in 3 columns, nothing clipped or overlapping (pending item from skill-icons L5).
- L4 T1: generator client/.tmp/font.py (7x9 bodies, 2 px strokes, small caps 7x7, three tones top to bottom, outline lighter on the top-left). Loaded in Pixelorama, reviewed with get_image; exports 369x11 match the generator pixel by pixel, palette-only, no semi-transparent px; `.pxo` 369x11, 1 frame. Commit 1fa444a.
- L5 Image font import: a quoted string in `character_ranges` mapped a single glyph; explicit hex ranges in sheet order (`0x30-0x39`, `0x2E`, `0x4B`, `0x4D`, `0x42`, `0x54`, `0x61-0x7A`) map all 41. Fixed size 11, so font size 11 draws 1:1.
- L6 Decision (auto mode): critical hits draw at 2x (whole pixels, pivot on a whole pixel at the bottom center) on top of the gold font, so crits read as "big". Reversible: one constant.
- L7 T2: DamageNumber (Label, pooled by a second NodePool in battle_world.tscn) rises 24 px/s on whole pixels, fades from 0.4 s, released at 0.8 s; BattleWorld connects every enemy's HealthComponent.damaged once at spawn, anchors 2 px above the head with +-6 px jitter. tests/unit/world/test_damage_numbers.gd RED (missing type, then crit size) then GREEN; suite 418/418. Screenshots 720x1280 (scratch save, --no-cloud): red "10" above the slime, crisp; with a forced 100% crit, gold "15" at 2x. Assess: medium, no verifier, no review due. Commit 54df1e0. Feature closed.
