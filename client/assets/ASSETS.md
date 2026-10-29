# Asset technical sheet

Third-party art kept in the game. Every character sprite (hero, enemies, boss) is original art
in `client/art/` (see `client/art/STYLE.md`). Sizes measured with `sips`.

Sprite sheets are horizontal: frames are numbered left to right (then top to bottom when a sheet
has several rows), starting at 0.

## Backgrounds

`backgrounds/forest/` has 4 layers, each 272x160. Each layer tiles horizontally (the pack is
"seamlessly loopable"). Order from back to front:

1. `forest_back_trees.png` (opaque sky and far trees)
2. `forest_lights.png`
3. `forest_middle_trees.png`
4. `forest_front_trees.png`

The layers are 160 px tall and the battle viewport is 192 px. Anchor the layers to the top
and fill the bottom 32 px with a ground strip, which is the lane the characters stand on.
