extends GutTest
## Skill buttons and the auto-cast toggle shown by the ability panel.

const ABILITIES: AbilityCatalog = preload("res://data/content/abilities/ability_catalog.tres")

var session: GameSession
var panel: AbilityPanel


func before_each() -> void:
	session = GameSession.new(StageBalance.new(), 10, 30.0, ABILITIES)
	panel = AbilityPanel.new()
	add_child_autofree(panel)
	panel.bind(session)


func test_one_button_per_skill() -> void:
	assert_eq(panel.skill_buttons.size(), 5)


func _card(index: int) -> SkillCard:
	return panel.skill_buttons[index] as SkillCard


func test_locked_skill_shows_its_unlock_stage_greyed_and_is_disabled() -> void:
	assert_eq(_card(1).title_label.text, "Meteoro\nEtapa 3")
	assert_eq(_card(1).art.texture, _card(1).silver_grey)
	assert_true(_card(1).disabled)


func test_ready_skill_shows_its_name_in_full_color_and_is_enabled() -> void:
	assert_eq(_card(0).title_label.text, "Trueno")
	assert_eq(_card(0).art.texture, panel.skill_icons[0][AbilityPanel.GOLD])
	assert_eq(_card(0).cooldown_mask.value, 0.0)
	assert_false(_card(0).disabled)


func test_skill_on_cooldown_shows_a_clock_mask_instead_of_seconds() -> void:
	session.tick_combat(0.0, true)
	_card(0).pressed.emit()
	assert_almost_eq(_card(0).cooldown_mask.value, 1.0, 0.001, "all grey right after the cast")
	session.tick_combat(2.0, true)
	panel.refresh()
	# 8 s cooldown, 2 s gone: a quarter of the grey was swept away.
	assert_almost_eq(_card(0).cooldown_mask.value, 0.75, 0.001)
	assert_eq(_card(0).title_label.text, "Trueno", "no seconds")
	assert_eq(_card(0).text, "")
	assert_true(_card(0).disabled)
	session.tick_combat(6.0, true)
	panel.refresh()
	assert_eq(_card(0).cooldown_mask.value, 0.0)


func test_clock_mask_is_the_grey_icon_swept_away_clockwise() -> void:
	var mask: TextureProgressBar = _card(0).cooldown_mask
	assert_eq(mask.fill_mode, TextureProgressBar.FILL_COUNTER_CLOCKWISE,
		"the grey shrinks back counter-clockwise, so the cleared part grows like a clock hand")
	assert_eq(mask.texture_progress, _card(0).silver_grey)
	var grey: Image = _card(0).silver_grey.get_image()
	var color: Image = (panel.skill_icons[0][AbilityPanel.SILVER] as Texture2D).get_image()
	for point: Vector2i in [Vector2i(30, 30), Vector2i(48, 40), Vector2i(10, 70)]:
		var pixel: Color = grey.get_pixelv(point)
		assert_almost_eq(pixel.r, pixel.g, 0.01, "grey at %s" % point)
		assert_almost_eq(pixel.g, pixel.b, 0.01, "grey at %s" % point)
		assert_eq(pixel.a, color.get_pixelv(point).a)


func test_card_art_fills_the_card_with_the_title_over_its_bottom() -> void:
	var card: SkillCard = _card(0)
	assert_eq(card.custom_minimum_size, Vector2(96.0, 96.0))
	assert_eq(card.art.texture.get_size(), Vector2(96.0, 96.0))
	assert_eq(card.art.anchor_right, 1.0)
	assert_eq(card.art.anchor_bottom, 1.0)
	assert_eq(card.cooldown_mask.anchor_right, 1.0)
	assert_eq(card.cooldown_mask.anchor_bottom, 1.0)
	assert_eq(card.title_label.get_parent().anchor_top, 1.0, "title band hangs from the card bottom")
	assert_eq(card.icon, null)


func test_pressing_a_ready_skill_casts_it() -> void:
	watch_signals(session.skills)
	session.tick_combat(0.0, true)
	panel.skill_buttons[0].pressed.emit()
	assert_signal_emitted_with_parameters(session.skills, "cast", [0, ABILITIES.skills[0]])


func test_autocast_toggle_is_locked_until_stage_ten() -> void:
	assert_true(panel.autocast_toggle.disabled)
	assert_eq(panel.autocast_toggle.text, "Automático (Etapa 10)")
	session.progression.restore_stage(10)
	panel.refresh()
	assert_false(panel.autocast_toggle.disabled)
	assert_eq(panel.autocast_toggle.text, "Automático")
	assert_true(panel.autocast_toggle.button_pressed)


func test_autocast_toggle_switches_the_skill_bar() -> void:
	session.progression.restore_stage(10)
	panel.refresh()
	panel.autocast_toggle.toggled.emit(false)
	assert_false(session.skills.autocast_enabled)
	panel.autocast_toggle.toggled.emit(true)
	assert_true(session.skills.autocast_enabled)


func test_skill_cards_draw_no_button_frame_over_the_art() -> void:
	for button: Button in panel.skill_buttons:
		assert_true(button is SkillCard)
		for style: String in ["normal", "hover", "pressed", "disabled", "focus"]:
			assert_true(button.get_theme_stylebox(style) is StyleBoxEmpty, style)


func test_each_skill_card_shows_its_icon_scaled_three_times_with_square_pixels() -> void:
	for index: int in panel.skill_buttons.size():
		var sheet: Image = (load("res://art/icons/skill_%s.png" % ABILITIES.skills[index].id) as Texture2D).get_image()
		for frame: int in [AbilityPanel.SILVER, AbilityPanel.GOLD]:
			var icon: Image = (panel.skill_icons[index][frame] as Texture2D).get_image()
			assert_eq(icon.get_size(), Vector2i(96, 96))
			for point: Vector2i in [Vector2i(1, 1), Vector2i(16, 16), Vector2i(30, 29)]:
				var expected: Color = sheet.get_pixel(frame * 32 + point.x, point.y)
				assert_eq(icon.get_pixelv(point * 3), expected, "skill %d frame %d at %s" % [index, frame, point])
				assert_eq(icon.get_pixelv(point * 3 + Vector2i(2, 2)), expected, "nearest, not blended")


func test_skill_on_cooldown_goes_back_to_the_silver_frame_until_ready() -> void:
	session.tick_combat(0.0, true)
	_card(0).pressed.emit()
	assert_eq(_card(0).art.texture, panel.skill_icons[0][AbilityPanel.SILVER])
	session.tick_combat(8.0, true)
	panel.refresh()
	assert_eq(_card(0).art.texture, panel.skill_icons[0][AbilityPanel.GOLD])
