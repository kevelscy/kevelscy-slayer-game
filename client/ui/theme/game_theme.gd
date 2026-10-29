class_name GameTheme
extends RefCounted
## The game's UI theme: every button and panel gets FrameArt's rounded gold
## frame, coloured by what it does. Controls pick a kind with
## theme_type_variation; plain Buttons and PanelContainers get the defaults.

const BUY_BUTTON: StringName = &"BuyButton"
const SKILL_BUTTON: StringName = &"SkillButton"
const ACCENT_BUTTON: StringName = &"AccentButton"
## Bottom tab bar: silver frame, gold frame and gold text on the selected tab.
const TAB_BUTTON: StringName = &"TabButton"
const CARD: StringName = &"Card"
const SECTION_TITLE: StringName = &"SectionTitle"
## Smaller text for the two-line labels inside cards.
const CARD_TEXT: StringName = &"CardText"
const HEALTH_BAR: StringName = &"HealthBar"

const FONT_SIZE: int = 26
const TITLE_FONT_SIZE: int = 28
const CARD_FONT_SIZE: int = 22
const TEXT: Color = Color(1.0, 0.97, 0.88)
const TEXT_DISABLED: Color = Color(0.78, 0.75, 0.7)
const TEXT_OUTLINE: Color = Color(0.1, 0.05, 0.02)
const TITLE_GOLD: Color = Color(1.0, 0.84, 0.4)

## Fill gradients (top, bottom) per kind.
const LEATHER: Array[Color] = [Color(0.66, 0.4, 0.22), Color(0.36, 0.19, 0.09)]
const AMBER: Array[Color] = [Color(1.0, 0.72, 0.24), Color(0.8, 0.38, 0.1)]
const AZURE: Array[Color] = [Color(0.38, 0.72, 1.0), Color(0.12, 0.34, 0.74)]
const AMETHYST: Array[Color] = [Color(0.76, 0.5, 1.0), Color(0.4, 0.18, 0.7)]
const STONE: Array[Color] = [Color(0.42, 0.42, 0.46), Color(0.24, 0.24, 0.28)]
const NIGHT: Array[Color] = [Color(0.2, 0.16, 0.28), Color(0.11, 0.09, 0.16)]

const BUTTON_PADDING: Vector2 = Vector2(14.0, 6.0)
const CARD_PADDING: Vector2 = Vector2(16.0, 8.0)


static func build() -> Theme:
	var theme: Theme = Theme.new()
	theme.default_font_size = FONT_SIZE
	_add_button(theme, &"Button", LEATHER)
	for kind: StringName in [BUY_BUTTON, SKILL_BUTTON, ACCENT_BUTTON]:
		theme.set_type_variation(kind, &"Button")
	_add_button(theme, BUY_BUTTON, AMBER)
	_add_button(theme, SKILL_BUTTON, AZURE)
	_add_button(theme, ACCENT_BUTTON, AMETHYST)
	_add_tab_button(theme)
	_add_text(theme, &"CheckButton")
	_add_text(theme, &"Label")

	var card: StyleBoxTexture = _box(FrameArt.frame(NIGHT[0], NIGHT[1], FrameArt.GOLD_LIGHT, FrameArt.GOLD_DARK, 0.3), CARD_PADDING)
	theme.set_stylebox("panel", &"PanelContainer", card)
	theme.set_type_variation(CARD, &"PanelContainer")
	theme.set_stylebox("panel", CARD, card)

	theme.set_type_variation(SECTION_TITLE, &"Label")
	theme.set_color("font_color", SECTION_TITLE, TITLE_GOLD)
	theme.set_font_size("font_size", SECTION_TITLE, TITLE_FONT_SIZE)
	theme.set_constant("outline_size", SECTION_TITLE, 8)
	theme.set_type_variation(CARD_TEXT, &"Label")
	theme.set_font_size("font_size", CARD_TEXT, CARD_FONT_SIZE)

	theme.set_stylebox("background", &"ProgressBar", _bar(Color(0.1, 0.07, 0.12)))
	theme.set_stylebox("fill", &"ProgressBar", _bar(Color(1.0, 0.72, 0.24)))
	theme.set_type_variation(HEALTH_BAR, &"ProgressBar")
	theme.set_stylebox("fill", HEALTH_BAR, _bar(Color(0.86, 0.22, 0.24)))
	return theme


static func _add_button(theme: Theme, kind: StringName, fill: Array[Color]) -> void:
	var light: Array[Color] = [fill[0].lightened(0.15), fill[1].lightened(0.15)]
	var dark: Array[Color] = [fill[0].darkened(0.2), fill[1].darkened(0.2)]
	var normal: StyleBoxTexture = _box(FrameArt.frame(fill[0], fill[1], FrameArt.GOLD_LIGHT, FrameArt.GOLD_DARK), BUTTON_PADDING)
	theme.set_stylebox("normal", kind, normal)
	theme.set_stylebox("hover", kind, _box(FrameArt.frame(light[0], light[1], FrameArt.GOLD_LIGHT, FrameArt.GOLD_DARK), BUTTON_PADDING))
	theme.set_stylebox("pressed", kind, _box(FrameArt.frame(dark[1], dark[0], FrameArt.GOLD_DARK, FrameArt.GOLD_LIGHT, 0.0), BUTTON_PADDING))
	theme.set_stylebox("disabled", kind, _box(FrameArt.frame(STONE[0], STONE[1], FrameArt.IRON_LIGHT, FrameArt.IRON_DARK, 0.4), BUTTON_PADDING))
	# Focus would draw over the art; the frame already marks the button.
	theme.set_stylebox("focus", kind, StyleBoxEmpty.new())
	_add_text(theme, kind)
	theme.set_color("font_disabled_color", kind, TEXT_DISABLED)
	for state: String in ["font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		theme.set_color(state, kind, TEXT)


static func _add_tab_button(theme: Theme) -> void:
	theme.set_type_variation(TAB_BUTTON, &"Button")
	var light: Array[Color] = [NIGHT[0].lightened(0.1), NIGHT[1].lightened(0.1)]
	var selected: StyleBoxTexture = _box(FrameArt.frame(light[0], light[1], FrameArt.GOLD_LIGHT, FrameArt.GOLD_DARK), BUTTON_PADDING)
	theme.set_stylebox("normal", TAB_BUTTON, _box(FrameArt.frame(NIGHT[0], NIGHT[1], FrameArt.SILVER_LIGHT, FrameArt.SILVER_DARK), BUTTON_PADDING))
	theme.set_stylebox("hover", TAB_BUTTON, _box(FrameArt.frame(light[0], light[1], FrameArt.SILVER_LIGHT, FrameArt.SILVER_DARK), BUTTON_PADDING))
	theme.set_stylebox("pressed", TAB_BUTTON, selected)
	theme.set_stylebox("hover_pressed", TAB_BUTTON, selected)
	theme.set_stylebox("disabled", TAB_BUTTON, _box(FrameArt.frame(STONE[0], STONE[1], FrameArt.IRON_LIGHT, FrameArt.IRON_DARK, 0.4), BUTTON_PADDING))
	theme.set_stylebox("focus", TAB_BUTTON, StyleBoxEmpty.new())
	_add_text(theme, TAB_BUTTON)
	theme.set_color("font_disabled_color", TAB_BUTTON, TEXT_DISABLED)
	for state: String in ["font_hover_color", "font_focus_color"]:
		theme.set_color(state, TAB_BUTTON, TEXT)
	for state: String in ["font_pressed_color", "font_hover_pressed_color"]:
		theme.set_color(state, TAB_BUTTON, TITLE_GOLD)


static func _add_text(theme: Theme, kind: StringName) -> void:
	theme.set_color("font_color", kind, TEXT)
	theme.set_color("font_outline_color", kind, TEXT_OUTLINE)
	theme.set_constant("outline_size", kind, 6)


static func _box(image: Image, padding: Vector2) -> StyleBoxTexture:
	var box: StyleBoxTexture = StyleBoxTexture.new()
	box.texture = ImageTexture.create_from_image(image)
	for side: Side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		box.set_texture_margin(side, FrameArt.SLICE_MARGIN)
	box.set_content_margin(SIDE_LEFT, padding.x)
	box.set_content_margin(SIDE_RIGHT, padding.x)
	box.set_content_margin(SIDE_TOP, padding.y)
	box.set_content_margin(SIDE_BOTTOM, padding.y)
	return box


static func _bar(color: Color) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(8)
	box.border_color = TEXT_OUTLINE
	box.set_border_width_all(2)
	return box
