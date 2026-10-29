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
