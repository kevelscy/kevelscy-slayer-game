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


func test_lists_every_stat_with_level_and_value() -> void:
	assert_eq(_labels(), [
		"Attack  Lv 0\n10",
		"Health  Lv 0\n100",
		"Crit Chance  Lv 0\n5.0%",
		"Crit Damage  Lv 0\n150%",
		"Attack Speed  Lv 0\n1.50/s",
	])


func test_rate_button_shows_cost_and_buys() -> void:
	var row: UpgradePanel.Row = panel.rows[2]
	assert_eq(row.button.text, "Up  50")
	assert_true(row.button.disabled)
	session.wallet.add(GameSession.GOLD, BigNumber.from_float(50.0))
	assert_false(row.button.disabled)
	row.button.pressed.emit()
	assert_eq(row.label.text, "Crit Chance  Lv 1\n5.5%")
	assert_true(session.wallet.get_amount(GameSession.GOLD).is_zero())


func test_maxed_track_shows_max_and_stays_disabled() -> void:
	var saved: SaveData = SaveData.new()
	saved.attack_speed_level = 75
	session.apply_save(saved)
	session.wallet.add(GameSession.GOLD, BigNumber.of(1.0, 100))
	var row: UpgradePanel.Row = panel.rows[4]
	assert_eq(row.label.text, "Attack Speed  Lv 75\n3.00/s")
	assert_eq(row.button.text, "Max")
	assert_true(row.button.disabled)
