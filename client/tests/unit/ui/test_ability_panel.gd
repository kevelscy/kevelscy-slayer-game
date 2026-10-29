extends GutTest
## Skill buttons, auto-cast toggle and spirit slots shown by the ability panel.

const ABILITIES: AbilityCatalog = preload("res://data/content/abilities/ability_catalog.tres")

var session: GameSession
var panel: AbilityPanel


func before_each() -> void:
	session = GameSession.new(StageBalance.new(), 10, 30.0, ABILITIES)
	panel = AbilityPanel.new()
	add_child_autofree(panel)
	panel.bind(session)


func test_one_button_per_skill_and_one_slot_per_spirit() -> void:
	assert_eq(panel.skill_buttons.size(), 5)
	assert_eq(panel.spirit_labels.size(), 3)


func test_locked_skill_shows_its_unlock_stage_and_is_disabled() -> void:
	assert_eq(panel.skill_buttons[1].text, "Meteor\nStage 3")
	assert_true(panel.skill_buttons[1].disabled)


func test_ready_skill_shows_its_name_and_is_enabled() -> void:
	assert_eq(panel.skill_buttons[0].text, "Thunder")
	assert_false(panel.skill_buttons[0].disabled)


func test_skill_on_cooldown_shows_the_seconds_left() -> void:
	session.tick_combat(0.0, true)
	panel.skill_buttons[0].pressed.emit()
	session.tick_combat(2.5, true)
	panel.refresh()
	assert_eq(panel.skill_buttons[0].text, "Thunder\n6s")
	assert_true(panel.skill_buttons[0].disabled)


func test_pressing_a_ready_skill_casts_it() -> void:
	watch_signals(session.skills)
	session.tick_combat(0.0, true)
	panel.skill_buttons[0].pressed.emit()
	assert_signal_emitted_with_parameters(session.skills, "cast", [0, ABILITIES.skills[0]])


func test_autocast_toggle_is_locked_until_stage_ten() -> void:
	assert_true(panel.autocast_toggle.disabled)
	assert_eq(panel.autocast_toggle.text, "Auto-cast (Stage 10)")
	session.progression.restore_stage(10)
	panel.refresh()
	assert_false(panel.autocast_toggle.disabled)
	assert_eq(panel.autocast_toggle.text, "Auto-cast")
	assert_true(panel.autocast_toggle.button_pressed)


func test_autocast_toggle_switches_the_skill_bar() -> void:
	session.progression.restore_stage(10)
	panel.refresh()
	panel.autocast_toggle.toggled.emit(false)
	assert_false(session.skills.autocast_enabled)
	panel.autocast_toggle.toggled.emit(true)
	assert_true(session.skills.autocast_enabled)


func test_spirit_slots_show_lock_stage_or_passive() -> void:
	assert_eq(panel.spirit_labels[0].text, "Wisp\nStage 2")
	session.progression.restore_stage(6)
	panel.refresh()
	assert_eq(panel.spirit_labels[0].text, "Wisp\n+10% Attack")
	assert_eq(panel.spirit_labels[1].text, "Ember Fox\n+5% Crit Chance")
	assert_eq(panel.spirit_labels[2].text, "Frost Owl\nStage 10")


func test_skills_use_skill_buttons_and_spirits_sit_in_framed_cards() -> void:
	for button: Button in panel.skill_buttons:
		assert_eq(button.theme_type_variation, GameTheme.SKILL_BUTTON)
	for label: Label in panel.spirit_labels:
		var card: Control = label.get_parent()
		assert_true(card is PanelContainer)
		assert_eq(card.theme_type_variation, GameTheme.CARD)



func test_each_skill_button_shows_its_icon_scaled_twice_with_square_pixels() -> void:
	for index: int in panel.skill_buttons.size():
		var sheet: Image = (load("res://art/icons/skill_%s.png" % ABILITIES.skills[index].id) as Texture2D).get_image()
		for frame: int in [AbilityPanel.SILVER, AbilityPanel.GOLD]:
			var icon: Image = (panel.skill_icons[index][frame] as Texture2D).get_image()
			assert_eq(icon.get_size(), Vector2i(64, 64))
			for point: Vector2i in [Vector2i(1, 1), Vector2i(16, 16), Vector2i(30, 29)]:
				var expected: Color = sheet.get_pixel(frame * 32 + point.x, point.y)
				assert_eq(icon.get_pixelv(point * 2), expected, "skill %d frame %d at %s" % [index, frame, point])
				assert_eq(icon.get_pixelv(point * 2 + Vector2i.ONE), expected, "nearest, not blended")


func test_ready_skill_shows_the_gold_frame() -> void:
	assert_eq(panel.skill_buttons[0].icon, panel.skill_icons[0][AbilityPanel.GOLD])


func test_locked_skill_shows_the_silver_frame() -> void:
	assert_eq(panel.skill_buttons[1].icon, panel.skill_icons[1][AbilityPanel.SILVER])


func test_skill_on_cooldown_goes_back_to_the_silver_frame_until_ready() -> void:
	session.tick_combat(0.0, true)
	panel.skill_buttons[0].pressed.emit()
	assert_eq(panel.skill_buttons[0].icon, panel.skill_icons[0][AbilityPanel.SILVER])
	session.tick_combat(8.0, true)
	panel.refresh()
	assert_eq(panel.skill_buttons[0].icon, panel.skill_icons[0][AbilityPanel.GOLD])


func test_icons_are_drawn_above_the_text_at_their_own_size() -> void:
	var button: Button = panel.skill_buttons[0]
	assert_false(button.expand_icon, "never shrunk to a fractional scale")
	assert_eq(button.vertical_icon_alignment, VERTICAL_ALIGNMENT_TOP)
	assert_eq(button.icon_alignment, HORIZONTAL_ALIGNMENT_CENTER)
