class_name SkillCard
extends Button
## One skill of the skill bar drawn as a card: the icon art fills it, the title sits
## over its bottom edge, and the cooldown is a clock mask. Casting turns the whole
## card grey and the grey is swept away clockwise until the skill is ready again.
## A bought skill shows its level in the top-left corner.
## Built in code; the button keeps the press handling and the disabled state.

const TITLE_FONT_SIZE: int = 18
const LEVEL_FONT_SIZE: int = 16
## Long titles shrink down to this size so they stay inside the title band.
const TITLE_MIN_FONT_SIZE: int = 11
const TITLE_OUTLINE: int = 6
## Space left at the sides of the title band so it stays inside the metal frame.
const TITLE_INSET: float = 6.0
const TITLE_BAND_HEIGHT: float = 26.0
const TITLE_BAND_COLOR: Color = Color(0.06, 0.03, 0.03, 0.65)
## Grey locked and unowned art keeps this much of the icon's luminance.
const GREY_BRIGHTNESS: float = 0.75
## The cooldown clock mask is darker, so the sweep reads clearly over the art.
const COOLDOWN_BRIGHTNESS: float = 0.4

var art: TextureRect
## Value 1 right after a cast and 0 when ready; draws the grey icon over that share.
var cooldown_mask: TextureProgressBar
var title_label: Label
var level_label: Label
var silver: Texture2D
var gold: Texture2D
var silver_grey: Texture2D
var cooldown_grey: Texture2D


func _init(silver_art: Texture2D, gold_art: Texture2D) -> void:
	silver = silver_art
	gold = gold_art
	silver_grey = grey(silver_art)
	cooldown_grey = grey(silver_art, COOLDOWN_BRIGHTNESS)
	custom_minimum_size = silver_art.get_size()
	focus_mode = Control.FOCUS_NONE
	for style: String in ["normal", "hover", "pressed", "disabled", "focus", "hover_pressed"]:
		add_theme_stylebox_override(style, StyleBoxEmpty.new())
	art = TextureRect.new()
	art.texture = silver_art
	add_child(_fill(art))
	cooldown_mask = TextureProgressBar.new()
	cooldown_mask.texture_progress = cooldown_grey
	cooldown_mask.fill_mode = TextureProgressBar.FILL_COUNTER_CLOCKWISE
	cooldown_mask.min_value = 0.0
	cooldown_mask.max_value = 1.0
	cooldown_mask.step = 0.0
	add_child(_fill(cooldown_mask))
	add_child(_title_band())
	level_label = Label.new()
	level_label.position = Vector2(TITLE_INSET, TITLE_INSET)
	level_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	level_label.add_theme_font_size_override("font_size", LEVEL_FONT_SIZE)
	level_label.add_theme_constant_override("outline_size", TITLE_OUTLINE)
	level_label.add_theme_color_override("font_outline_color", GameTheme.TEXT_OUTLINE)
	level_label.add_theme_color_override("font_color", GameTheme.TEXT)
	level_label.visible = false
	add_child(level_label)


## Locked: grey art and the unlock stage under the title.
func show_locked(title: String, unlock_stage: int) -> void:
	art.texture = silver_grey
	cooldown_mask.value = 0.0
	_set_title("%s\nEtapa %d" % [title, unlock_stage])
	level_label.visible = false


## Reached but not bought yet: grey art under the plain title.
func show_unowned(title: String) -> void:
	art.texture = silver_grey
	cooldown_mask.value = 0.0
	_set_title(title)
	level_label.visible = false


## Bought: gold frame when ready, silver frame under the clock mask while cooling,
## and the level in the corner.
func show_cooldown(title: String, cooldown_ratio: float, level: int = 1) -> void:
	art.texture = gold if cooldown_ratio <= 0.0 else silver
	cooldown_mask.value = cooldown_ratio
	_set_title(title)
	level_label.text = "Nv %d" % level
	level_label.visible = true


## Sets the title and the largest font size, down to TITLE_MIN_FONT_SIZE, whose widest
## line fits the band.
func _set_title(text: String) -> void:
	if text == title_label.text:
		return
	title_label.text = text
	var band_width: float = custom_minimum_size.x - 2.0 * TITLE_INSET
	var font: Font = title_label.get_theme_font(&"font")
	var font_size: int = TITLE_FONT_SIZE
	while font_size > TITLE_MIN_FONT_SIZE and _widest_line(font, text, font_size) > band_width:
		font_size -= 1
	title_label.add_theme_font_size_override("font_size", font_size)


static func _widest_line(font: Font, text: String, font_size: int) -> float:
	var widest: float = 0.0
	for line: String in text.split("\n"):
		widest = maxf(widest, font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x)
	return widest


## The texture in greyscale scaled by brightness, alpha untouched.
static func grey(texture: Texture2D, brightness: float = GREY_BRIGHTNESS) -> Texture2D:
	# A copy: an ImageTexture can hand out its own stored image.
	var image: Image = texture.get_image().duplicate() as Image
	image.convert(Image.FORMAT_RGBA8)
	for y: int in image.get_height():
		for x: int in image.get_width():
			var pixel: Color = image.get_pixel(x, y)
			var level: float = pixel.get_luminance() * brightness
			image.set_pixel(x, y, Color(level, level, level, pixel.a))
	return ImageTexture.create_from_image(image)


func _fill(control: Control) -> Control:
	control.set_anchors_preset(Control.PRESET_FULL_RECT)
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return control


func _title_band() -> Control:
	var band: PanelContainer = PanelContainer.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = TITLE_BAND_COLOR
	band.add_theme_stylebox_override("panel", style)
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.anchor_left = 0.0
	band.anchor_right = 1.0
	band.anchor_top = 1.0
	band.anchor_bottom = 1.0
	band.offset_left = TITLE_INSET
	band.offset_right = -TITLE_INSET
	band.offset_top = -TITLE_BAND_HEIGHT - TITLE_INSET
	band.offset_bottom = -TITLE_INSET
	band.grow_vertical = Control.GROW_DIRECTION_BEGIN
	title_label = Label.new()
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	title_label.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)
	title_label.add_theme_constant_override("outline_size", TITLE_OUTLINE)
	title_label.add_theme_color_override("font_outline_color", GameTheme.TEXT_OUTLINE)
	title_label.add_theme_color_override("font_color", GameTheme.TEXT)
	title_label.add_theme_constant_override("line_spacing", -4)
	band.add_child(title_label)
	return band
