extends GutTest
## Pins the shipped catalog to the skill and spirit decisions (D5-D7).

const CATALOG: AbilityCatalog = preload("res://data/content/abilities/ability_catalog.tres")


func test_five_skills_in_slot_order_with_their_unlock_stages() -> void:
	var ids: Array[StringName] = []
	var stages: Array[int] = []
	for skill: SkillDefinition in CATALOG.skills:
		ids.append(skill.id)
		stages.append(skill.unlock_stage)
	assert_eq(ids, [&"thunder", &"meteor", &"blizzard", &"fury", &"shield"] as Array[StringName])
	assert_eq(stages, [1, 3, 5, 8, 12] as Array[int])


func test_each_skill_matches_its_element() -> void:
	var effects: Array[SkillDefinition.Effect] = []
	for skill: SkillDefinition in CATALOG.skills:
		effects.append(skill.effect)
		assert_gt(skill.cooldown_seconds, 0.0, String(skill.id))
		assert_false(skill.display_name.is_empty(), String(skill.id))
	assert_eq(effects, [
		SkillDefinition.Effect.DAMAGE_ALL, SkillDefinition.Effect.DAMAGE_FRONT,
		SkillDefinition.Effect.FREEZE_ALL, SkillDefinition.Effect.BUFF, SkillDefinition.Effect.SHIELD,
	] as Array[SkillDefinition.Effect])


func test_three_spirits_with_their_unlock_stages_and_passives() -> void:
	var stages: Array[int] = []
	var stats: Array[StringName] = []
	for spirit: SpiritDefinition in CATALOG.spirits:
		stages.append(spirit.unlock_stage)
		stats.append(spirit.passive_stat)
		assert_gt(spirit.attack_interval_seconds, 0.0, String(spirit.id))
	assert_eq(stages, [2, 6, 10] as Array[int])
	assert_eq(stats, [StatBlock.ATTACK, StatBlock.CRIT_CHANCE, StatBlock.HEALTH] as Array[StringName])
	assert_eq(CATALOG.spirits[1].passive_kind, StatModifier.Kind.FLAT, "crit chance grows by points")


func test_wisp_orb_uses_the_palette_turquoise_not_green() -> void:
	assert_eq(CATALOG.spirits[0].color.to_html(false), "13ccbd", "paleta_juego.gpl Turquesa")


func test_game_state_session_uses_the_catalog() -> void:
	assert_eq(GameState.session.skills.slots.size(), 5)
	assert_eq(GameState.session.spirits.slots.size(), 3)


func test_skill_prices_rise_with_their_unlock_stage() -> void:
	var prices: Dictionary[StringName, float] = {}
	for skill: SkillDefinition in CATALOG.skills:
		prices[skill.id] = skill.base_cost
		assert_eq(skill.cost_growth, 1.35, String(skill.id))
	assert_eq(prices, {&"thunder": 30.0, &"meteor": 150.0, &"blizzard": 300.0, &"fury": 600.0, &"shield": 1200.0})
