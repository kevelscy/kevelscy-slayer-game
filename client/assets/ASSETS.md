# Asset technical sheet

Every sprite and background in the game is original art in `client/art/` (see
`client/art/STYLE.md`). Sizes measured with `sips`.

Sprite sheets are horizontal: frames are numbered left to right (then top to bottom when a sheet
has several rows), starting at 0.

## Backgrounds

`client/art/tiles/` has the battle lane layers. Each layer tiles horizontally every 272 px.
Order from back to front (parallax speed relative to the hero's run in brackets):

1. `bg_far.png` 272x160, opaque night sky and two hill ranges (0.1)
2. `bg_middle.png` 272x160, forest canopy mass (0.3)
3. `bg_front.png` 272x160, dark trunks, hanging foliage and grass (0.6)
4. `bg_ground.png` 272x32, dirt strip the characters stand on (1.0)

The battle viewport is 192 px tall: the three 160 px layers are anchored to the top and the
ground strip fills the bottom 32 px (y 160 to 192).

## Damage number fonts

`client/art/fonts/` has two bitmap fonts imported as Godot image fonts (`font_data_image`, one row
of 41 cells 9x11, drawn 1:1 at font size 11). Glyph order, which the import's `character_ranges`
must match: `0-9 . K M B T a-z` (every character `NumberFormat.format` prints for damage;
lowercase letters are small caps).

- `damage_font.png` 369x11, red (Rojo vivo #f4170b) with a dark outline: normal hits
- `damage_font_crit.png` 369x11, gold: critical hits, drawn at 2x
