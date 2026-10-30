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

## Sound effects

`client/audio/sfx/` holds the game's sound effects: original sounds synthesized with SoundCraft
(built-in Subtractive Synth and Drum Synth, no samples), WAV 44.1 kHz 16-bit stereo, peak-normalized
with a 10 ms fade-out. `client/audio/source/build_sfx.py` rebuilds them: each recipe writes its
SoundCraft command script (`<id>.txt`) and session (`<id>.scraft`) next to it, then bounces the WAV
(`soundcraft-cli` on PATH; `build_sfx.py [id ...]`).

`SfxPlayer.SOUNDS` keys every sound by its file name and sets its minimum replay interval,
polyphony, volume and random pitch. They play on the `SFX` bus (`client/default_bus_layout.tres`).

| file | event | length |
|---|---|---|
| `hit.wav` | hero hits an enemy | 0.12 s |
| `crit.wav` | critical hit | 0.30 s |
| `coin.wav` | enemy killed (gold) | 0.25 s |
| `spirit.wav` | spirit attack | 0.15 s |
| `thunder.wav`, `meteor.wav`, `blizzard.wav`, `fury.wav`, `shield.wav` | skill cast (named after the skill id) | 0.60, 0.80, 0.70, 0.50, 0.50 s |
| `upgrade.wav` | gold upgrade or talent bought | 0.35 s |
| `ui_tap.wav` | bottom tab changed | 0.06 s |
| `boss_start.wav` | boss appears | 1.00 s |
| `boss_defeat.wav` | boss defeated | 1.20 s |
| `hero_death.wav` | hero dies | 0.80 s |
| `ascension.wav` | ascension confirmed | 1.50 s |

## HUD icons

`client/art/icons/sound_on.png` and `sound_off.png`, 24x24, one frame, transparent (sources
`client/art/source/sound_on.pxo`, `sound_off.pxo`): a silver speaker with two sound waves or with a
red cross. The HUD sound button draws them at 2x with nearest sampling (`BottomTabBar.icon_texture`).
