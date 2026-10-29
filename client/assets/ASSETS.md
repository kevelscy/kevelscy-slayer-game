# Asset technical sheet

Sizes measured with `sips`. Frame contents were checked by counting opaque pixels per cell.
Frames are numbered left to right, then top to bottom, starting at 0.

## Sprites

| Path | Sheet size | Frame | Grid (cols x rows) | Animations | Facing | FPS |
|---|---|---|---|---|---|---|
| `sprites/hero/hero_idle.png` | 64x128 | 64x64 | 1x2 | idle: 0-1 | right | 4 |
| `sprites/hero/hero_run.png` | 192x192 | 64x64 | 3x3 | run: 0-7 (cell 8 empty) | right | 12 |
| `sprites/hero/hero_attack.png` | 384x64 | 64x64 | 6x1 | attack: 0-5 | right | 14 |
| `sprites/hero/hero_hurt_die.png` | 192x256 | 64x64 | 3x4 | hurt: 0-2 (white flash), die: 3-11 (fades out) | right | 12 |
| `sprites/enemies/slime/slime.png` | 296x86 | 74x86 | 4x1 | move: 0-3 | left | 8 |
| `sprites/enemies/bat/bat.png` | 381x138 | 127x138 | 3x1 | fly: 0-2 | left | 10 |
| `sprites/enemies/skeleton/skeleton.png` | 552x138 | 138x138 | 4x1 | walk: 0-3 | left | 8 |
| `sprites/boss/spider.png` | 828x138 | 138x138 | 6x1 | walk: 0-5 | left | 10 |

Enemies come from the right, so their left-facing art needs no flipping.

**Scale.** The hero is drawn at 64 px and the enemies at roughly 2x that density. In the
360x192 battle viewport, scale regular enemies by 0.5. Scale the boss by 0.75–1.0 and tint it.

**Not in the packs.** There are no enemy hurt or death frames: use a white-flash shader or
`modulate` and a fade tween. There is also no boss-specific art: the boss is the spider,
scaled and tinted.

## Backgrounds

`backgrounds/forest/` has 4 layers, each 272x160. Each layer tiles horizontally (the pack is
"seamlessly loopable"). Order from back to front:

1. `forest_back_trees.png` (opaque sky and far trees)
2. `forest_lights.png`
3. `forest_middle_trees.png`
4. `forest_front_trees.png`

The layers are 160 px tall and the battle viewport is 192 px. Anchor the layers to the top
and fill the bottom 32 px with a ground strip, which is the lane the characters stand on.
