# Tab icons (Slayer Legend style)

Give each bottom tab (Upgrades, Spirits, Ascension) an original Pixelorama icon above its title,
following `client/art/STYLE.md`.

## Specs

- S1 "Usa SOLO la paleta \"paleta_juego.gpl\" (35 colores). No inventes colores fuera de ella." / "Contraste clave: cálidos (fuego/oro) contra fríos (cian/azul)."
- S2 "Barra de pestañas abajo; botones grandes, pensados para el pulgar." / "Ícono seleccionado o raro: borde dorado brillante (#fccf40, #fde504)." (the tab button already draws the silver/gold frame).
- S3 "Antes de crear cada asset, dime qué vas a hacer y su tamaño." / "Revisa cada asset con get_image antes de exportarlo."
- S4 Save the `.pxo` in `client/art/source/`; export transparent PNGs in `client/art/icons/`.
- S5 "Al terminar, dime qué archivos creaste y sus dimensiones."
- S6 Godot: Nearest filter, no mipmaps, integer scale; each tab shows its icon above its title.

## Tasks

- [x] T1 S1, S3-S5 three icons `tab_<id>.png` 24x24 (one frame, transparent, 1 px outline) for upgrades, spirits, ascension — inline — commit: f2f9ed5
- [x] T2 S2, S6 BottomTabBar shows the icons at 48 px above the titles; tests, screenshots — inline — commit: fb60e38

## Log

- L1 (user, verbatim): "retoma la anterior sesion, retoma tu ejecucio" — resumed after bottom-tab-bar (closed, pushed at 7887dd6); its optional next step was icons for the tabs. The "7 ascension review findings" pending item is stale: odd/tasks/ascension-advisories.md fixed them.
- L2 Decision (auto mode, reversible): icons have no own frame; the tab button's silver/gold frame marks the selection. Upgrades = silver sword with a gold up arrow, Spirits = cyan flame orb, Ascension = gold star with sparkles.
- L3 T1: generator client/.tmp/tab_icons.py (reuses outline/inside_poly from icons.py and lit/tone/ellipse from spirit_icons.py). First preview: the spirit's dark-teal eyes vanished on the cyan body, now 2x2 black eyes with a white top-left glint. Loaded in Pixelorama, reviewed with get_image; exports tab_<id>.png 24x24 match the generator pixel by pixel (235/227/231 painted px), palette-only, no semi-transparent px; `.pxo` 24x24 with 1 frame; import settings equal to the spirit icons (no mipmaps).
- L4 T2: BottomTabBar.setup(titles, first, icon_paths = []) sets each icon (BottomTabBar.icon_texture: 24 px art resized 2x with nearest, ICON_SCALE 2), centered above the title, expand_icon off; Main.TAB_ICONS. Tests RED (missing API) then GREEN; suite 442/442. Screenshots (scratch save, --no-cloud): 720x1280 Spirits tab, icons crisp above the titles, selected tab gold; the bar grew to about 128 px (icon + title), pages still scroll; 1600x900 landscape unchanged (no tab bar). README layout line updated. Assess (base 7887dd6, committedOnly): medium, no verifier, no review due (native unassessable: untracked .vscode/ and client/.mcp.json). S1-S6 covered. Feature closed.
