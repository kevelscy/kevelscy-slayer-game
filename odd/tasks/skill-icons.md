# Skill icons (Slayer Legend style)

Give each of the five skill buttons an original Pixelorama icon with a silver metal frame that
turns gold when the skill is ready, following `client/art/STYLE.md`.

## Specs

- S1 "Usa SOLO la paleta \"paleta_juego.gpl\" (35 colores). No inventes colores fuera de ella." / "Personajes, enemigos y efectos: colores saturados (rojo, naranja, amarillo, cian, azul)" / "Contraste clave: cálidos (fuego/oro) contra fríos (cian/azul)."
- S2 "Íconos de habilidad cuadrados con marco metálico plateado (#929ea6, #c0ced1)." / "Ícono seleccionado o raro: borde dorado brillante (#fccf40, #fde504)."
- S3 "Antes de crear cada asset, dime qué vas a hacer y su tamaño." / "Revisa cada asset con get_image antes de exportarlo."
- S4 Save the `.pxo` in `client/art/source/`; export transparent PNG sheets in `client/art/icons/`.
- S5 "Al terminar, dime qué archivos creaste y sus dimensiones."
- S6 Godot: Nearest filter, no mipmaps, integer scale; each skill button shows its icon (gold frame while the skill is ready, silver otherwise) and keeps its current text.

## Tasks

- [x] T1 S1-S5 five icon sheets `skill_<id>.png` 64x32 (frame 0 silver, frame 1 gold; 24x24 art inside a 2 px metal frame) for thunder, meteor, blizzard, fury, shield — inline — commit: cd13728
- [x] T2 S6 AbilityPanel shows the icon above the text at 64 px, gold frame while ready; tests, screenshot — inline — commit: 77cabc5

## Log

- L1 (user) "dale play" — answering the background-art report whose recommended next step was: "íconos de habilidad cuadrados con marco plateado (#929ea6, #c0ced1) y borde dorado cuando están seleccionados o son raros."
- L2 Decision (auto mode): the game has no selection or rarity for skills, so the gold border marks a skill that is ready to cast; locked or cooling down skills keep the silver frame. Reversible: only the frame index changes.
- L3 T1: generator client/.tmp/icons.py (frame + 24x24 art, outline lighter on the lit side). Exports skill_<id>.png 64x32 x5 match the generator pixel by pixel (all-opaque squares make pixel counts useless, so compare pixels), palette-only, no semi-transparent px; `.pxo` 32x32 with 2 frames; no mipmaps. Reviewed with get_image. Commit cd13728.
- L4 T2: first try used Button.expand_icon + icon_max_width 64: the icon shrank to fit beside the 2-line text (fractional scale, tiny on locked buttons). Now AbilityPanel cuts both frames from the sheet image and scales them 2x nearest into ImageTextures (skill_icons[index][SILVER|GOLD]); the button grows to fit. Tests RED (missing API) then GREEN; suite 412/412. Screenshot 720x1280 OK: crisp 64 px icons, Thunder gold, locked ones silver and dimmed. Commit 77cabc5.
- L5 (user) "para, se acaba la ventana de contexto, guarda todo en engram status actual y pendientes, retomamos en la siguiente sesion" — feature CLOSED at this point. Not done: native review assess for this feature; landscape layout not looked at with the taller skill buttons (suite incl. main layout tests passes).
