extends GutTest
## Ascension overlay: shard balance, the confirmed ascend button and the talent rows.

const ABILITIES: AbilityCatalog = preload("res://data/content/abilities/ability_catalog.tres")
const TALENTS: TalentCatalog = preload("res://data/content/talents/talent_catalog.tres")

var session: GameSession
var panel: AscensionPanel


func before_each() -> void:
	session = GameSession.new(StageBalance.new(), 10, 30.0, ABILITIES, TALENTS)
	panel = AscensionPanel.new()
	add_child_autofree(panel)
	panel.bind(session)


func _row(talent_id: StringName) -> AscensionPanel.Row:
	for row: AscensionPanel.Row in panel.rows:
		if row.talent.id == talent_id:
			return row
	return null


func test_header_shows_shards_and_ascension_count() -> void:
	assert_eq(panel.shards_label.text, "Shards 0")
	assert_eq(panel.count_label.text, "Ascensions 0")


func test_ascend_button_is_disabled_before_stage_20() -> void:
	session.progression.restore_stage(19)
	panel.refresh()
	assert_eq(panel.ascend_button.text, "Ascend (Stage 20)")
	assert_true(panel.ascend_button.disabled)


func test_ascend_asks_for_confirmation_before_resetting() -> void:
	session.progression.restore_stage(23)
	panel.refresh()
	assert_eq(panel.ascend_button.text, "Ascend +8 shards")
	assert_false(panel.ascend_button.disabled)
	panel.ascend_button.pressed.emit()
	assert_true(panel.confirm_dialog.visible)
	assert_eq(session.progression.stage, 23, "nothing resets before confirming")
	panel.confirm_dialog.confirmed.emit()
	assert_eq(session.progression.stage, 1)
	assert_eq(panel.shards_label.text, "Shards 8")
	assert_eq(panel.count_label.text, "Ascensions 1")
	assert_eq(panel.ascend_button.text, "Ascend (Stage 20)")


func test_one_row_per_talent_with_level_bonus_and_cost() -> void:
	assert_eq(panel.rows.size(), 6)
	assert_eq(_row(&"might").label.text, "Might  Lv 0/10\n+0% attack")
	assert_eq(_row(&"might").button.text, "Up  1 shard")
	assert_true(_row(&"might").button.disabled, "no shards yet")
	assert_eq(_row(&"precision").label.text, "Precision  Lv 0/10\n+0% crit chance")
	assert_eq(_row(&"precision").button.text, "Needs Might 5")
	assert_true(_row(&"precision").button.disabled)


func test_buying_a_talent_spends_shards_and_updates_the_row() -> void:
	session.talents.shards = 3
	panel.refresh()
	_row(&"greed").button.pressed.emit()
	assert_eq(session.talents.level(&"greed"), 1)
	assert_eq(_row(&"greed").label.text, "Greed  Lv 1/10\n+10% gold")
	assert_eq(_row(&"greed").button.text, "Up  2 shards")
	assert_eq(panel.shards_label.text, "Shards 2")


func test_tier_two_unlocks_and_maxed_talent_shows_max() -> void:
	var saved: SaveData = SaveData.new()
	saved.talents = {"might": 10, "ferocity": 2}
	session.apply_save(saved)
	session.talents.shards = 100
	panel.refresh()
	assert_eq(_row(&"might").button.text, "Max")
	assert_true(_row(&"might").button.disabled)
	assert_eq(_row(&"ferocity").label.text, "Ferocity  Lv 2/10\n+20% crit damage")
	assert_eq(_row(&"ferocity").button.text, "Up  3 shards")
	assert_false(_row(&"ferocity").button.disabled)


func test_close_button_hides_the_overlay() -> void:
	panel.open()
	assert_true(panel.visible)
	panel.close_button.pressed.emit()
	assert_false(panel.visible)
