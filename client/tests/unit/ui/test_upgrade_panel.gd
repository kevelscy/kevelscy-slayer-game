extends GutTest
## Upgrade rows for the scaling stats and the rate stats, including the Max state.

const PANEL_SCENE: PackedScene = preload("res://ui/panels/upgrade_panel.tscn")

var session: GameSession
var panel: UpgradePanel


func before_each() -> void:
	session = GameSession.new()
	panel = PANEL_SCENE.instantiate()
	add_child_autofree(panel)
	panel.bind(session)


func _labels() -> Array[String]:
	var texts: Array[String] = []
	for row: UpgradePanel.Row in panel.rows:
		texts.append(row.label.text)
	return texts


## skill-branches S2: Mejoras splits into Características and Habilidades.
func test_mejoras_has_a_characteristics_tab_and_a_skills_tab() -> void:
	assert_eq(panel.tab_buttons.size(), 2)
	assert_eq(panel.tab_buttons[0].text, "Características")
	assert_eq(panel.tab_buttons[1].text, "Habilidades")
	for button: Button in panel.tab_buttons:
		assert_eq(button.theme_type_variation, GameTheme.TAB_BUTTON)
	assert_true(panel.tab_buttons[0].button_pressed, "Características opens first")
	assert_true(panel.characteristics_page.visible)
	assert_false(panel.skills_page.visible)
	for row: UpgradePanel.Row in panel.rows:
		assert_true(panel.characteristics_page.is_ancestor_of(row.button), "stat rows are characteristics")


func test_picking_a_tab_shows_only_its_page() -> void:
	panel.tab_buttons[1].pressed.emit()
	assert_false(panel.characteristics_page.visible)
	assert_true(panel.skills_page.visible)
	assert_true(panel.tab_buttons[1].button_pressed)
	assert_false(panel.tab_buttons[0].button_pressed)
	panel.tab_buttons[0].pressed.emit()
	assert_true(panel.characteristics_page.visible)
	assert_false(panel.skills_page.visible)


func test_lists_every_stat_with_level_and_value() -> void:
	assert_eq(_labels(), [
		"Ataque  Nv 0\n10",
		"Vida  Nv 0\n100",
		"Prob. crítico  Nv 0\n5,0%",
		"Daño crítico  Nv 0\n150%",
		"Vel. ataque  Nv 0\n1,50/s",
	])


func test_rate_button_shows_cost_and_buys() -> void:
	var row: UpgradePanel.Row = panel.rows[2]
	assert_eq(row.button.text, "Mejorar 35")
	assert_true(row.button.disabled)
	session.wallet.add(GameSession.GOLD, BigNumber.from_float(35.0))
	assert_false(row.button.disabled)
	row.button.pressed.emit()
	assert_eq(row.label.text, "Prob. crítico  Nv 1\n5,5%")
	assert_true(session.wallet.get_amount(GameSession.GOLD).is_zero())


func test_maxed_track_shows_max_and_stays_disabled() -> void:
	var saved: SaveData = SaveData.new()
	saved.attack_speed_level = 75
	session.apply_save(saved)
	session.wallet.add(GameSession.GOLD, BigNumber.of(1.0, 100))
	var row: UpgradePanel.Row = panel.rows[4]
	assert_eq(row.label.text, "Vel. ataque  Nv 75\n3,00/s")
	assert_eq(row.button.text, "Máx")
	assert_true(row.button.disabled)


func test_rows_are_framed_cards_with_buy_buttons() -> void:
	for row: UpgradePanel.Row in panel.rows:
		assert_eq(row.button.theme_type_variation, GameTheme.BUY_BUTTON)
		var card: Control = row.button.get_parent().get_parent()
		assert_true(card is PanelContainer)
		assert_eq(card.theme_type_variation, GameTheme.CARD)


func test_cost_buttons_show_the_gold_coin_after_the_amount() -> void:
	for row: UpgradePanel.Row in panel.rows:
		assert_same(row.button.icon, GameTheme.coin_texture(GameTheme.COIN_SIZE))
		assert_eq(row.button.icon_alignment, HORIZONTAL_ALIGNMENT_RIGHT)


func test_maxed_button_has_no_coin() -> void:
	var saved: SaveData = SaveData.new()
	saved.attack_speed_level = 75
	session.apply_save(saved)
	session.wallet.add(GameSession.GOLD, BigNumber.from_float(1.0))
	assert_null(panel.rows[4].button.icon)
	assert_not_null(panel.rows[0].button.icon)
