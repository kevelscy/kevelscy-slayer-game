extends GutTest
## Skill buttons and the auto-cast toggle shown by the ability panel.

const ABILITIES: AbilityCatalog = preload("res://data/content/abilities/ability_catalog.tres")

var session: GameSession
var panel: AbilityPanel


func before_each() -> void:
	session = GameSession.new(StageBalance.new(), 10, 30.0, ABILITIES)
	session.skills.slots[0].level = 1
	panel = AbilityPanel.new()
	add_child_autofree(panel)
	panel.bind(session)


func test_one_button_per_skill() -> void:
	assert_eq(panel.skill_buttons.size(), 6)


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
	assert_eq(mask.texture_progress, _card(0).cooldown_grey)
	var grey: Image = _card(0).cooldown_grey.get_image()
	var color: Image = (panel.skill_icons[0][AbilityPanel.SILVER] as Texture2D).get_image()
	for point: Vector2i in [Vector2i(30, 30), Vector2i(48, 40), Vector2i(10, 70)]:
		var pixel: Color = grey.get_pixelv(point)
		assert_almost_eq(pixel.r, pixel.g, 0.01, "grey at %s" % point)
		assert_almost_eq(pixel.g, pixel.b, 0.01, "grey at %s" % point)
		assert_eq(pixel.a, color.get_pixelv(point).a)


func test_the_cooldown_grey_is_darker_than_the_locked_grey() -> void:
	assert_lte(SkillCard.COOLDOWN_BRIGHTNESS, 0.5, "dark enough to read over the art")
	assert_eq(SkillCard.GREY_BRIGHTNESS, 0.75, "locked and unowned cards keep their grey")
	var mask: Image = _card(0).cooldown_grey.get_image()
	var locked: Image = _card(0).silver_grey.get_image()
	var color: Image = (panel.skill_icons[0][AbilityPanel.SILVER] as Texture2D).get_image()
	for point: Vector2i in [Vector2i(30, 30), Vector2i(48, 40), Vector2i(10, 70)]:
		var luminance: float = color.get_pixelv(point).get_luminance()
		assert_almost_eq(mask.get_pixelv(point).r, luminance * SkillCard.COOLDOWN_BRIGHTNESS, 0.01)
		assert_almost_eq(locked.get_pixelv(point).r, luminance * SkillCard.GREY_BRIGHTNESS, 0.01)


func test_card_art_fills_the_card_with_the_title_over_its_bottom() -> void:
	var card: SkillCard = _card(0)
	assert_eq(card.custom_minimum_size, Vector2(128.0, 128.0))
	assert_eq(card.art.texture.get_size(), Vector2(128.0, 128.0))
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


func test_each_skill_card_shows_its_icon_scaled_four_times_with_square_pixels() -> void:
	for index: int in panel.skill_buttons.size():
		var sheet: Image = (load("res://art/icons/skill_%s.png" % ABILITIES.skills[index].id) as Texture2D).get_image()
		for frame: int in [AbilityPanel.SILVER, AbilityPanel.GOLD]:
			var icon: Image = (panel.skill_icons[index][frame] as Texture2D).get_image()
			assert_eq(icon.get_size(), Vector2i(128, 128))
			for point: Vector2i in [Vector2i(1, 1), Vector2i(16, 16), Vector2i(30, 29)]:
				var expected: Color = sheet.get_pixel(frame * 32 + point.x, point.y)
				assert_eq(icon.get_pixelv(point * 4), expected, "skill %d frame %d at %s" % [index, frame, point])
				assert_eq(icon.get_pixelv(point * 4 + Vector2i(3, 3)), expected, "nearest, not blended")


func test_skill_on_cooldown_goes_back_to_the_silver_frame_until_ready() -> void:
	session.tick_combat(0.0, true)
	_card(0).pressed.emit()
	assert_eq(_card(0).art.texture, panel.skill_icons[0][AbilityPanel.SILVER])
	session.tick_combat(8.0, true)
	panel.refresh()
	assert_eq(_card(0).art.texture, panel.skill_icons[0][AbilityPanel.GOLD])


func _gold(amount: float) -> void:
	session.wallet.restore(GameSession.GOLD, BigNumber.from_float(amount))
	panel.refresh()


func test_each_skill_has_a_buy_button_with_its_gold_cost_and_the_coin() -> void:
	assert_eq(panel.buy_buttons.size(), 6)
	for index: int in 5:
		var button: Button = panel.buy_buttons[index]
		assert_eq(button.text, NumberFormat.format(session.skills.slots[index].cost()))
		assert_not_null(button.icon, "coin next to the cost")
		assert_eq(button.icon_alignment, HORIZONTAL_ALIGNMENT_RIGHT)
		assert_eq(button.theme_type_variation, GameTheme.BUY_BUTTON)


func test_buy_button_needs_the_gold_and_the_unlock_stage() -> void:
	_gold(0.0)
	assert_true(panel.buy_buttons[0].disabled, "no gold")
	_gold(1e9)
	assert_false(panel.buy_buttons[0].disabled)
	assert_true(panel.buy_buttons[1].disabled, "the meteor needs stage 3")
	session.progression.restore_stage(3)
	panel.refresh()
	assert_false(panel.buy_buttons[1].disabled)


func test_a_reached_skill_not_bought_is_grey_with_its_name_and_no_level() -> void:
	session.progression.restore_stage(3)
	panel.refresh()
	assert_eq(_card(1).title_label.text, "Meteoro")
	assert_eq(_card(1).art.texture, _card(1).silver_grey)
	assert_true(_card(1).disabled)
	assert_false(_card(1).level_label.visible)


func test_buying_spends_the_gold_and_shows_the_new_level() -> void:
	session.progression.restore_stage(3)
	var cost: BigNumber = session.skills.slots[1].cost()
	_gold(cost.to_float() + 5.0)
	panel.buy_buttons[1].pressed.emit()
	assert_eq(session.skills.slots[1].level, 1)
	assert_almost_eq(session.wallet.get_amount(GameSession.GOLD).to_float(), 5.0, 1e-6)
	assert_true(_card(1).level_label.visible)
	assert_eq(_card(1).level_label.text, "Nv 1")
	assert_eq(_card(1).art.texture, panel.skill_icons[1][AbilityPanel.GOLD])
	assert_eq(panel.buy_buttons[1].text, NumberFormat.format(session.skills.slots[1].cost()))


func test_an_owned_skill_shows_its_level_in_the_corner() -> void:
	session.skills.slots[0].level = 7
	panel.refresh()
	assert_eq(_card(0).level_label.text, "Nv 7")
	assert_eq(_card(0).level_label.get_parent(), _card(0))
	assert_eq(_card(0).level_label.position, Vector2(SkillCard.TITLE_INSET, SkillCard.TITLE_INSET))


func _shown() -> Array[int]:
	var shown: Array[int] = []
	for index: int in panel.skill_columns.size():
		if panel.skill_columns[index].visible:
			shown.append(index)
	return shown


func test_skills_sit_in_one_row_between_the_two_arrows() -> void:
	var row: HBoxContainer = panel.carousel_row
	assert_eq(row.get_child(0), panel.left_arrow)
	assert_eq(row.get_child(row.get_child_count() - 1), panel.right_arrow)
	assert_eq(panel.skill_columns.size(), 6)
	for index: int in panel.skill_columns.size():
		assert_eq(panel.skill_columns[index].get_parent(), panel.cards_row, "one row, no wrapping")
		assert_eq(panel.skill_buttons[index].get_parent(), panel.skill_columns[index])
		assert_eq(panel.buy_buttons[index].get_parent(), panel.skill_columns[index], "buy button under its card")


func test_the_row_shows_as_many_cards_as_fit_the_width() -> void:
	panel.fit_cards(720.0)
	assert_eq(_shown(), [0, 1, 2, 3], "portrait width: four 128 px cards")
	panel.fit_cards(400.0)
	assert_eq(_shown(), [0, 1])
	panel.fit_cards(100.0)
	assert_eq(_shown(), [0], "always at least one card")
	panel.fit_cards(2000.0)
	assert_eq(_shown(), [0, 1, 2, 3, 4, 5])


func test_resizing_the_panel_refits_the_cards() -> void:
	panel.size = Vector2(720.0, 300.0)
	assert_eq(_shown(), [0, 1, 2, 3])


func test_arrows_are_gold_and_grey_out_when_that_side_has_no_more_skills() -> void:
	panel.fit_cards(720.0)
	assert_true(panel.left_arrow.disabled, "nothing to the left at the start")
	assert_false(panel.right_arrow.disabled)
	for arrow: Button in [panel.left_arrow, panel.right_arrow]:
		assert_eq(arrow.get_theme_color("icon_normal_color"), GameTheme.TITLE_GOLD)
		assert_eq(arrow.get_theme_color("icon_hover_color"), GameTheme.TITLE_GOLD)
		assert_eq(arrow.get_theme_color("icon_disabled_color"), AbilityPanel.ARROW_GREY)
		assert_not_null(arrow.icon)
	panel.right_arrow.pressed.emit()
	assert_eq(_shown(), [1, 2, 3, 4], "scrolls one skill to the right")
	assert_false(panel.left_arrow.disabled)
	panel.right_arrow.pressed.emit()
	assert_eq(_shown(), [2, 3, 4, 5])
	assert_true(panel.right_arrow.disabled, "last skill reached")
	panel.right_arrow.pressed.emit()
	assert_eq(_shown(), [2, 3, 4, 5], "no scroll past the end")
	panel.left_arrow.pressed.emit()
	assert_eq(_shown(), [1, 2, 3, 4])


func test_both_arrows_grey_when_every_skill_fits() -> void:
	panel.fit_cards(2000.0)
	assert_true(panel.left_arrow.disabled)
	assert_true(panel.right_arrow.disabled)


func test_widening_after_a_scroll_keeps_the_last_cards_in_view() -> void:
	panel.fit_cards(400.0)
	for step: int in 4:
		panel.right_arrow.pressed.emit()
	assert_eq(_shown(), [4, 5])
	panel.fit_cards(720.0)
	assert_eq(_shown(), [2, 3, 4, 5], "no empty space after the last skill")
