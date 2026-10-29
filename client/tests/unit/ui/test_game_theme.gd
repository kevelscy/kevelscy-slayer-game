extends GutTest
## Framed, rounded art for every button and card, and the theme that applies it.

const BUTTON_STATES: Array[String] = ["normal", "hover", "pressed", "disabled"]


func _fill_art() -> Image:
	return FrameArt.frame(Color(0.2, 0.4, 1.0), Color(0.1, 0.2, 0.6), FrameArt.GOLD_LIGHT, FrameArt.GOLD_DARK)


func test_frame_is_a_square_image_with_transparent_rounded_corners() -> void:
	var art: Image = _fill_art()
	assert_eq(art.get_size(), Vector2i(FrameArt.SIZE, FrameArt.SIZE))
	assert_eq(art.get_pixel(0, 0).a, 0.0)
	assert_eq(art.get_pixel(FrameArt.SIZE - 1, FrameArt.SIZE - 1).a, 0.0)


func test_frame_has_a_dark_outline_then_a_gold_band_then_the_fill() -> void:
	var art: Image = _fill_art()
	var middle: int = FrameArt.SIZE / 2
	var outline: Color = art.get_pixel(middle, 0)
	assert_eq(outline.a, 1.0)
	assert_lt(outline.v, 0.25, "outline is dark")
	var band: Color = art.get_pixel(middle, FrameArt.OUTLINE + 1)
	assert_gt(band.r, band.b, "frame band is gold")
	var fill: Color = art.get_pixel(middle, middle)
	assert_gt(fill.b, fill.r, "centre shows the blue fill")


func test_frame_fill_is_lighter_at_the_top() -> void:
	var art: Image = _fill_art()
	var inner: int = FrameArt.OUTLINE + FrameArt.BAND + FrameArt.INNER_LINE + 1
	var top: Color = art.get_pixel(FrameArt.SIZE / 2, inner)
	var bottom: Color = art.get_pixel(FrameArt.SIZE / 2, FrameArt.SIZE - 1 - inner)
	assert_gt(top.v, bottom.v)


func test_every_button_kind_has_framed_art_for_every_state() -> void:
	var theme: Theme = GameTheme.build()
	for kind: StringName in [&"Button", GameTheme.BUY_BUTTON, GameTheme.SKILL_BUTTON, GameTheme.ACCENT_BUTTON]:
		if kind != &"Button":
			assert_eq(theme.get_type_variation_base(kind), &"Button", String(kind))
		for state: String in BUTTON_STATES:
			var box: StyleBox = theme.get_stylebox(state, kind)
			assert_true(box is StyleBoxTexture, "%s %s" % [kind, state])
		assert_true(theme.get_stylebox("focus", kind) is StyleBoxEmpty, "%s focus" % kind)


func test_tab_buttons_have_a_silver_frame_and_a_gold_one_when_selected() -> void:
	var theme: Theme = GameTheme.build()
	assert_eq(theme.get_type_variation_base(GameTheme.TAB_BUTTON), &"Button")
	var middle: int = FrameArt.SIZE / 2
	var band_y: int = FrameArt.OUTLINE + 1
	for state: String in ["normal", "hover"]:
		var band: Color = (theme.get_stylebox(state, GameTheme.TAB_BUTTON) as StyleBoxTexture).texture.get_image().get_pixel(middle, band_y)
		assert_gt(band.b, band.r, "%s band is silver" % state)
	for state: String in ["pressed", "hover_pressed"]:
		var band: Color = (theme.get_stylebox(state, GameTheme.TAB_BUTTON) as StyleBoxTexture).texture.get_image().get_pixel(middle, band_y)
		assert_gt(band.r, band.b, "%s band is gold" % state)
	assert_eq(theme.get_color("font_pressed_color", GameTheme.TAB_BUTTON), GameTheme.TITLE_GOLD)
	assert_eq(theme.get_color("font_hover_pressed_color", GameTheme.TAB_BUTTON), GameTheme.TITLE_GOLD)


func test_button_kinds_use_different_art() -> void:
	var theme: Theme = GameTheme.build()
	var buy: StyleBoxTexture = theme.get_stylebox("normal", GameTheme.BUY_BUTTON)
	var skill: StyleBoxTexture = theme.get_stylebox("normal", GameTheme.SKILL_BUTTON)
	var disabled: StyleBoxTexture = theme.get_stylebox("disabled", GameTheme.BUY_BUTTON)
	assert_ne(buy.texture, skill.texture)
	assert_ne(buy.texture, disabled.texture)


func test_panels_and_cards_are_framed_and_titles_are_gold() -> void:
	var theme: Theme = GameTheme.build()
	assert_true(theme.get_stylebox("panel", &"PanelContainer") is StyleBoxTexture)
	assert_eq(theme.get_type_variation_base(GameTheme.CARD), &"PanelContainer")
	assert_true(theme.get_stylebox("panel", GameTheme.CARD) is StyleBoxTexture)
	assert_eq(theme.get_type_variation_base(GameTheme.SECTION_TITLE), &"Label")
	assert_eq(theme.get_color("font_color", GameTheme.SECTION_TITLE), GameTheme.TITLE_GOLD)
	assert_eq(theme.default_font_size, 26)
