extends GutTest
## Mejoras > Habilidades: every skill under its branch, grey unless bought and
## equipped, with a level button and an equip toggle (skill-branches S2-S5).

const ABILITIES: AbilityCatalog = preload("res://data/content/abilities/ability_catalog.tres")

var session: GameSession
var panel: SkillTreePanel


func before_each() -> void:
	session = GameSession.new(StageBalance.new(), 10, 30.0, ABILITIES)
	panel = SkillTreePanel.new()
	add_child_autofree(panel)
	panel.bind(session)


func _entry(id: StringName) -> SkillTreePanel.Entry:
	for entry: SkillTreePanel.Entry in panel.entries:
		if entry.slot.definition.id == id:
			return entry
	return null


func _rich() -> void:
	session.wallet.add(GameSession.GOLD, BigNumber.from_float(1e9))


func test_skills_sit_under_their_branch_titles_in_branch_order() -> void:
	var titles: Array[String] = []
	for box: VBoxContainer in panel.branch_boxes:
		titles.append((box.get_child(0) as Label).text)
	assert_eq(titles, ["Fuego", "Eléctrico", "Hielo", "Incremento", "Defensivo", "Aire"])
	assert_eq(_entry(&"meteor").card.get_parent(), panel.branch_boxes[SkillDefinition.Branch.FIRE])
	assert_eq(_entry(&"thunder").card.get_parent(), panel.branch_boxes[SkillDefinition.Branch.ELECTRIC])
	assert_eq(_entry(&"wind").card.get_parent(), panel.branch_boxes[SkillDefinition.Branch.AIR])
	assert_eq(panel.entries.size(), session.skills.slots.size(), "every skill of the catalog")


func test_a_skill_not_bought_is_grey_with_its_stage_or_its_price() -> void:
	var thunder: SkillTreePanel.Entry = _entry(&"thunder")
	assert_eq(thunder.label.text, "Trueno  Nv 0\nSin comprar")
	assert_eq(thunder.icon.texture, thunder.grey_icon)
	assert_true(thunder.equip_button.disabled)
	var meteor: SkillTreePanel.Entry = _entry(&"meteor")
	assert_eq(meteor.label.text, "Meteoro  Nv 0\nEtapa 3")
	assert_eq(meteor.icon.texture, meteor.grey_icon)


func test_the_level_button_shows_the_cost_and_needs_gold_and_the_stage() -> void:
	var thunder: SkillTreePanel.Entry = _entry(&"thunder")
	assert_eq(thunder.buy_button.text, NumberFormat.format(thunder.slot.cost()))
	assert_eq(thunder.buy_button.theme_type_variation, GameTheme.BUY_BUTTON)
	assert_not_null(thunder.buy_button.icon, "gold coin")
	assert_true(thunder.buy_button.disabled, "no gold yet")
	_rich()
	assert_false(thunder.buy_button.disabled)
	assert_true(_entry(&"meteor").buy_button.disabled, "meteor needs stage 3")


func test_buying_the_first_level_equips_the_skill_in_full_color() -> void:
	_rich()
	var thunder: SkillTreePanel.Entry = _entry(&"thunder")
	thunder.buy_button.pressed.emit()
	assert_eq(thunder.slot.level, 1)
	assert_true(session.skills.is_equipped(0))
	assert_eq(thunder.label.text, "Trueno  Nv 1\nEquipada")
	assert_eq(thunder.icon.texture, thunder.gold_icon)
	assert_eq(thunder.equip_button.text, "Quitar")
	assert_false(thunder.equip_button.disabled)


func test_the_equip_button_unequips_and_equips_a_bought_skill() -> void:
	_rich()
	var thunder: SkillTreePanel.Entry = _entry(&"thunder")
	thunder.buy_button.pressed.emit()
	thunder.equip_button.pressed.emit()
	assert_false(session.skills.is_equipped(0))
	assert_eq(thunder.label.text, "Trueno  Nv 1\nSin equipar")
	assert_eq(thunder.icon.texture, thunder.grey_icon, "unequipped skills are grey too")
	assert_eq(thunder.equip_button.text, "Equipar")
	thunder.equip_button.pressed.emit()
	assert_true(session.skills.is_equipped(0))
	assert_eq(thunder.icon.texture, thunder.gold_icon)


func test_entries_follow_changes_made_elsewhere() -> void:
	session.skills.slots[0].level = 1
	session.skills.equip(0)
	assert_eq(_entry(&"thunder").label.text, "Trueno  Nv 1\nEquipada")
	session.skills.unequip(0)
	assert_eq(_entry(&"thunder").label.text, "Trueno  Nv 1\nSin equipar")
	session.progression.restore_stage(3)
	assert_eq(_entry(&"meteor").label.text, "Meteoro  Nv 0\nSin comprar")
