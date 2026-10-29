# Spirit icons (Slayer Legend style)

Give each of the three spirit cards an original Pixelorama icon with the same silver/gold metal
frame as the skill icons, following `client/art/STYLE.md`.

## Specs

- S1 "Usa SOLO la paleta \"paleta_juego.gpl\" (35 colores). No inventes colores fuera de ella." / "Personajes, enemigos y efectos: colores saturados (rojo, naranja, amarillo, cian, azul)" / "Contraste clave: cálidos (fuego/oro) contra fríos (cian/azul)."
- S2 "Íconos de habilidad cuadrados con marco metálico plateado (#929ea6, #c0ced1)." / "Ícono seleccionado o raro: borde dorado brillante (#fccf40, #fde504)."
- S3 "Antes de crear cada asset, dime qué vas a hacer y su tamaño." / "Revisa cada asset con get_image antes de exportarlo."
- S4 Save the `.pxo` in `client/art/source/`; export transparent PNG sheets in `client/art/icons/`.
- S5 "Al terminar, dime qué archivos creaste y sus dimensiones."
- S6 Godot: Nearest filter, no mipmaps, integer scale; each spirit card shows its icon (gold frame once unlocked, silver while locked) above its current text.

## Tasks

- [x] T1 S1-S5 three icon sheets `spirit_<id>.png` 64x32 (frame 0 silver, frame 1 gold; 24x24 art inside a 2 px metal frame) for wisp, ember_fox, frost_owl — inline — commit: 9c25d27
- [x] T2 S6 AbilityPanel spirit cards show the icon at 64 px, gold once unlocked; tests, screenshot — inline — commit: 2aa6675

## Log

- L1 (user) "retoma la ultima sesion" — resumed after damage-numbers (closed, pushed at 42f7ece); the recommended next art was spirit icons (Wisp, Ember Fox, Frost Owl) reusing the skill icon frame generator; spirit cards are text-only now.
- L2 Decision (auto mode): spirits have no cooldown or rarity, so the gold frame marks an unlocked spirit and the silver frame a locked one. Wisp is drawn cyan/teal (the palette has no greens; its world orb is green). Reversible.
- L3 T1: generator client/.tmp/spirit_icons.py (reuses the frame, outline and background helpers of icons.py; spherical-normal light from the top-left). Wisp eyes moved into the lit part of the body and the fox muzzle lightened after the first preview. Loaded in Pixelorama, reviewed with get_image; exports spirit_<id>.png 64x32 match the generator pixel by pixel, palette-only, no semi-transparent px; `.pxo` 32x32 with 2 frames; import settings equal to the skill icons (no mipmaps). Commit 9c25d27.
- L4 T2: each spirit card is PanelContainer > VBoxContainer > [TextureRect icon (EXPAND_KEEP_SIZE, STRETCH_KEEP_CENTERED), Label]; `_icon_frames` now takes the sheet path and serves skills and spirits; new `spirit_cards`, `spirit_icon_rects`, `spirit_icons`. The framed-card test now finds the card through `spirit_cards` (same rule, the label is no longer the card's direct child). Tests RED (missing API) then GREEN; suite 421/421. Screenshots (scratch save, --no-cloud): 720x1280 at stage 6, Wisp and Ember Fox gold, Frost Owl silver "Stage 10", crisp; 1600x900 cards in one row, nothing clipped. Commit 2aa6675. Assess (full baseRef, committedOnly): medium, no verifier, no review due. Feature closed.
- L5 Follow-ups (not requested): locked spirit icons are not dimmed like disabled skill buttons; the Wisp world orb is still green, off the palette.
