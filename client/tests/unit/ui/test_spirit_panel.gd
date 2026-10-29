extends GutTest
## Spirit cards shown by the spirit panel: icon, lock stage or passive.

const ABILITIES: AbilityCatalog = preload("res://data/content/abilities/ability_catalog.tres")

var session: GameSession
var panel: SpiritPanel


func before_each() -> void:
	session = GameSession.new(StageBalance.new(), 10, 30.0, ABILITIES)
	panel = SpiritPanel.new()
	add_child_autofree(panel)
	panel.bind(session)


func test_one_card_per_spirit() -> void:
	assert_eq(panel.spirit_labels.size(), 3)
	assert_eq(panel.spirit_cards.size(), 3)


func test_spirit_slots_show_lock_stage_or_passive() -> void:
	assert_eq(panel.spirit_labels[0].text, "Wisp\nStage 2")
	session.progression.restore_stage(6)
	panel.refresh()
	assert_eq(panel.spirit_labels[0].text, "Wisp\n+10% Attack")
	assert_eq(panel.spirit_labels[1].text, "Ember Fox\n+5% Crit Chance")
	assert_eq(panel.spirit_labels[2].text, "Frost Owl\nStage 10")


func test_spirits_sit_in_framed_cards() -> void:
	for index: int in panel.spirit_labels.size():
		var card: PanelContainer = panel.spirit_cards[index]
		assert_true(card.is_ancestor_of(panel.spirit_labels[index]))
		assert_eq(card.theme_type_variation, GameTheme.CARD)


func test_each_spirit_card_shows_its_icon_scaled_twice_with_square_pixels() -> void:
	for index: int in panel.spirit_icon_rects.size():
		var sheet: Image = (load("res://art/icons/spirit_%s.png" % ABILITIES.spirits[index].id) as Texture2D).get_image()
		for frame: int in [AbilityPanel.SILVER, AbilityPanel.GOLD]:
			var icon: Image = (panel.spirit_icons[index][frame] as Texture2D).get_image()
			assert_eq(icon.get_size(), Vector2i(64, 64))
			for point: Vector2i in [Vector2i(1, 1), Vector2i(16, 16), Vector2i(30, 29)]:
				var expected: Color = sheet.get_pixel(frame * 32 + point.x, point.y)
				assert_eq(icon.get_pixelv(point * 2), expected, "spirit %d frame %d at %s" % [index, frame, point])
				assert_eq(icon.get_pixelv(point * 2 + Vector2i.ONE), expected, "nearest, not blended")


func test_locked_spirits_show_the_silver_frame_and_unlocked_ones_the_gold_frame() -> void:
	for index: int in 3:
		assert_eq(panel.spirit_icon_rects[index].texture, panel.spirit_icons[index][AbilityPanel.SILVER])
	session.progression.restore_stage(6)
	panel.refresh()
	assert_eq(panel.spirit_icon_rects[0].texture, panel.spirit_icons[0][AbilityPanel.GOLD])
	assert_eq(panel.spirit_icon_rects[1].texture, panel.spirit_icons[1][AbilityPanel.GOLD])
	assert_eq(panel.spirit_icon_rects[2].texture, panel.spirit_icons[2][AbilityPanel.SILVER])


func test_locked_spirit_icons_are_dimmed_like_disabled_skill_icons() -> void:
	var skill_button: Button = Button.new()
	add_child_autofree(skill_button)
	var dimmed: Color = skill_button.get_theme_color("icon_disabled_color")
	assert_ne(dimmed, Color.WHITE, "disabled skill icons are dimmed")
	for index: int in 3:
		assert_eq(panel.spirit_icon_rects[index].self_modulate, dimmed)
	session.progression.restore_stage(6)
	panel.refresh()
	assert_eq(panel.spirit_icon_rects[0].self_modulate, Color.WHITE)
	assert_eq(panel.spirit_icon_rects[1].self_modulate, Color.WHITE)
	assert_eq(panel.spirit_icon_rects[2].self_modulate, dimmed)


func test_spirit_icons_sit_centered_above_the_text_at_their_own_size() -> void:
	for index: int in panel.spirit_icon_rects.size():
		var rect: TextureRect = panel.spirit_icon_rects[index]
		var label: Label = panel.spirit_labels[index]
		assert_true(panel.spirit_cards[index].is_ancestor_of(rect))
		assert_eq(rect.get_parent(), label.get_parent())
		assert_lt(rect.get_index(), label.get_index(), "icon above the text")
		assert_eq(rect.expand_mode, TextureRect.EXPAND_KEEP_SIZE, "never shrunk to a fractional scale")
		assert_eq(rect.stretch_mode, TextureRect.STRETCH_KEEP_CENTERED)


func test_spirits_refresh_on_their_own_as_the_stage_grows() -> void:
	session.progression.restore_stage(6)
	await wait_seconds(SpiritPanel.REFRESH_SECONDS * 3.0)
	assert_eq(panel.spirit_labels[0].text, "Wisp\n+10% Attack")
