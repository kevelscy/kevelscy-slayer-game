class_name FrameArt
extends RefCounted
## Draws the rounded, gold-framed art behind buttons and cards: a dark outline,
## a bevelled metal band, a thin inner line and a vertical gradient fill with a
## gloss on its upper half. Square and nine-sliced by GameTheme, so one image
## fits any control size.

const SIZE: int = 64
const RADIUS: float = 16.0
## Band widths in pixels, from the outside in.
const OUTLINE: int = 2
const BAND: int = 4
const INNER_LINE: int = 1
## Pixels kept unstretched at each side when nine-slicing.
const SLICE_MARGIN: int = 20

const OUTLINE_COLOR: Color = Color(0.11, 0.06, 0.03)
const INNER_LINE_COLOR: Color = Color(0.2, 0.11, 0.05)
const GOLD_LIGHT: Color = Color(1.0, 0.92, 0.6)
const GOLD_DARK: Color = Color(0.62, 0.36, 0.1)
const IRON_LIGHT: Color = Color(0.72, 0.7, 0.66)
const IRON_DARK: Color = Color(0.34, 0.32, 0.3)
## Palette Plata and Acero: the silver band of unselected tabs.
const SILVER_LIGHT: Color = Color("#c0ced1")
const SILVER_DARK: Color = Color("#929ea6")
const GLOSS_STRENGTH: float = 0.22


## frame_light/frame_dark tint the metal band from top to bottom; gloss scales
## the highlight (0 turns it off, as for pressed buttons).
static func frame(
	fill_top: Color, fill_bottom: Color, frame_light: Color, frame_dark: Color, gloss: float = 1.0
) -> Image:
	var image: Image = Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	for y: int in SIZE:
		var t: float = (float(y) + 0.5) / float(SIZE)
		var metal: Color = frame_light.lerp(frame_dark, t)
		var fill: Color = fill_top.lerp(fill_bottom, t)
		if t < 0.45:
			fill = fill.lerp(Color.WHITE, GLOSS_STRENGTH * gloss * (1.0 - t / 0.45))
		for x: int in SIZE:
			var depth: float = _depth(float(x) + 0.5, float(y) + 0.5)
			image.set_pixel(x, y, _layer(depth, metal, fill))
	return image


## Distance inside the rounded square's edge (negative outside).
static func _depth(x: float, y: float) -> float:
	var half: float = float(SIZE) * 0.5
	var q: Vector2 = Vector2(absf(x - half), absf(y - half)) - Vector2(half - RADIUS, half - RADIUS)
	var outside: float = Vector2(maxf(q.x, 0.0), maxf(q.y, 0.0)).length() + minf(maxf(q.x, q.y), 0.0)
	return -(outside - RADIUS)


## Each band blends into the next over one pixel so curves stay smooth.
static func _layer(depth: float, metal: Color, fill: Color) -> Color:
	var band_start: float = float(OUTLINE)
	var line_start: float = band_start + float(BAND)
	var fill_start: float = line_start + float(INNER_LINE)
	# The band is brightest on its outer edge, a simple bevel.
	var bevel: Color = metal.lerp(metal.darkened(0.25), clampf((depth - band_start) / float(BAND), 0.0, 1.0))
	var color: Color = OUTLINE_COLOR
	color = color.lerp(bevel, _step(depth, band_start))
	color = color.lerp(INNER_LINE_COLOR, _step(depth, line_start))
	color = color.lerp(fill, _step(depth, fill_start))
	color.a = clampf(depth + 0.5, 0.0, 1.0)
	return color


static func _step(depth: float, edge: float) -> float:
	return clampf(depth - edge + 0.5, 0.0, 1.0)
