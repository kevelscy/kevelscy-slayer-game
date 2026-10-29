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
	assert_eq(panel.shards_label.text, "Fragmentos 0")
	assert_eq(panel.count_label.text, "Ascensiones 0")


func test_ascend_button_is_disabled_before_stage_20() -> void:
	session.progression.restore_stage(19)
	panel.refresh()
	assert_eq(panel.ascend_button.text, "Ascender (Etapa 20)")
	assert_true(panel.ascend_button.disabled)


func test_ascend_asks_for_confirmation_before_resetting() -> void:
	session.progression.restore_stage(23)
	panel.refresh()
	assert_eq(panel.ascend_button.text, "Ascender +8 fragmentos")
	assert_false(panel.ascend_button.disabled)
	panel.ascend_button.pressed.emit()
	assert_true(panel.confirm_dialog.visible)
	assert_eq(session.progression.stage, 23, "nothing resets before confirming")
	panel.confirm_dialog.confirmed.emit()
	assert_eq(session.progression.stage, 1)
	assert_eq(panel.shards_label.text, "Fragmentos 8")
	assert_eq(panel.count_label.text, "Ascensiones 1")
	assert_eq(panel.ascend_button.text, "Ascender (Etapa 20)")


func test_one_row_per_talent_with_level_bonus_and_cost() -> void:
	assert_eq(panel.rows.size(), 6)
	assert_eq(_row(&"might").label.text, "Poder  Nv 0/10\n+0% ataque")
	assert_eq(_row(&"might").button.text, "Mejorar 1 fragmento")
	assert_true(_row(&"might").button.disabled, "no shards yet")
	assert_eq(_row(&"precision").label.text, "Precisión  Nv 0/10\n+0% prob. crítico")
	assert_eq(_row(&"precision").button.text, "Requiere Poder 5")
	assert_true(_row(&"precision").button.disabled)


func test_buying_a_talent_spends_shards_and_updates_the_row() -> void:
	session.talents.shards = 3
	panel.refresh()
	_row(&"greed").button.pressed.emit()
	assert_eq(session.talents.level(&"greed"), 1)
	assert_eq(_row(&"greed").label.text, "Codicia  Nv 1/10\n+10% oro")
	assert_eq(_row(&"greed").button.text, "Mejorar 2 fragmentos")
	assert_eq(panel.shards_label.text, "Fragmentos 2")


func test_tier_two_unlocks_and_maxed_talent_shows_max() -> void:
	var saved: SaveData = SaveData.new()
	saved.talents = {"might": 10, "ferocity": 2}
	session.apply_save(saved)
	session.talents.shards = 100
	panel.refresh()
	assert_eq(_row(&"might").button.text, "Máx")
	assert_true(_row(&"might").button.disabled)
	assert_eq(_row(&"ferocity").label.text, "Ferocidad  Nv 2/10\n+20% daño crítico")
	assert_eq(_row(&"ferocity").button.text, "Mejorar 3 fragmentos")
	assert_false(_row(&"ferocity").button.disabled)


func test_close_button_hides_the_overlay() -> void:
	panel.open()
	assert_true(panel.visible)
	panel.close_button.pressed.emit()
	assert_false(panel.visible)


func test_ascend_is_an_accent_button_and_talents_are_cards_with_buy_buttons() -> void:
	assert_eq(panel.ascend_button.theme_type_variation, GameTheme.ACCENT_BUTTON)
	for row: AscensionPanel.Row in panel.rows:
		assert_eq(row.button.theme_type_variation, GameTheme.BUY_BUTTON)
		assert_eq((row.button.get_parent().get_parent() as Control).theme_type_variation, GameTheme.CARD)


func test_close_button_and_confirmation_dialog_are_spanish() -> void:
	assert_eq(panel.close_button.text, "Cerrar")
	assert_eq(panel.confirm_dialog.title, "Ascender")
	assert_eq(panel.confirm_dialog.get_ok_button().text, "Ascender")
	assert_eq(panel.confirm_dialog.get_cancel_button().text, "Cancelar")
	session.progression.restore_stage(23)
	panel.refresh()
	panel.ascend_button.pressed.emit()
	assert_eq(panel.confirm_dialog.dialog_text,
		"¿Volver a la etapa 1 por +8 fragmentos?\n"
		+ "Se reinician el oro, las mejoras, las habilidades y los espíritus; los talentos se mantienen.")


func test_confirmation_dialog_wraps_its_text_and_fits_the_portrait_width() -> void:
	session.progression.restore_stage(23)
	panel.refresh()
	panel.ascend_button.pressed.emit()
	assert_true(panel.confirm_dialog.dialog_autowrap, "long Spanish text wraps")
	assert_lte(float(panel.confirm_dialog.size.x), AscensionPanel.CONTENT_WIDTH, "both buttons stay on screen")
	panel.confirm_dialog.hide()
