extends GutTest
## Pins the shipped catalog to the skill and spirit decisions (D5-D7).

const CATALOG: AbilityCatalog = preload("res://data/content/abilities/ability_catalog.tres")


func test_six_skills_in_slot_order_with_their_unlock_stages() -> void:
	var ids: Array[StringName] = []
	var stages: Array[int] = []
	for skill: SkillDefinition in CATALOG.skills:
		ids.append(skill.id)
		stages.append(skill.unlock_stage)
	assert_eq(ids, [
		&"thunder", &"meteor", &"blizzard", &"fury", &"shield", &"wind", &"speed_sword", &"ice_block", &"heal",
		&"burning_sword", &"flame_wave", &"thunder_slash",
	] as Array[StringName])
	assert_eq(stages, [1, 3, 5, 8, 12, 15, 18, 20, 22, 25, 28, 32] as Array[int])


func test_each_skill_matches_its_element() -> void:
	var effects: Array[SkillDefinition.Effect] = []
	for skill: SkillDefinition in CATALOG.skills:
		effects.append(skill.effect)
		assert_gt(skill.cooldown_seconds, 0.0, String(skill.id))
		assert_false(skill.display_name.is_empty(), String(skill.id))
	assert_eq(effects, [
		SkillDefinition.Effect.DAMAGE_ALL, SkillDefinition.Effect.DAMAGE_FRONT,
		SkillDefinition.Effect.FREEZE_ALL, SkillDefinition.Effect.BUFF, SkillDefinition.Effect.SHIELD,
		SkillDefinition.Effect.DASH, SkillDefinition.Effect.BUFF, SkillDefinition.Effect.THROW_FRONT,
		SkillDefinition.Effect.HEAL, SkillDefinition.Effect.BUFF, SkillDefinition.Effect.WAVE,
		SkillDefinition.Effect.BARRAGE,
	] as Array[SkillDefinition.Effect])


## skill-branches S3.
func test_each_skill_belongs_to_its_branch() -> void:
	assert_eq(SkillDefinition.BRANCH_NAMES, ["Fuego", "Eléctrico", "Hielo", "Incremento", "Defensivo", "Aire"])
	var branches: Dictionary[StringName, SkillDefinition.Branch] = {}
	for skill: SkillDefinition in CATALOG.skills:
		branches[skill.id] = skill.branch
	assert_eq(branches[&"thunder"], SkillDefinition.Branch.ELECTRIC)
	assert_eq(branches[&"meteor"], SkillDefinition.Branch.FIRE)
	assert_eq(branches[&"blizzard"], SkillDefinition.Branch.ICE)
	assert_eq(branches[&"fury"], SkillDefinition.Branch.BOOST)
	assert_eq(branches[&"shield"], SkillDefinition.Branch.DEFENSIVE)
	assert_eq(branches[&"wind"], SkillDefinition.Branch.AIR)
	assert_eq(branches[&"speed_sword"], SkillDefinition.Branch.BOOST)
	assert_eq(branches[&"burning_sword"], SkillDefinition.Branch.FIRE)
	assert_eq(branches[&"ice_block"], SkillDefinition.Branch.ICE)
	assert_eq(branches[&"heal"], SkillDefinition.Branch.DEFENSIVE)
	assert_eq(branches[&"flame_wave"], SkillDefinition.Branch.FIRE)
	assert_eq(branches[&"thunder_slash"], SkillDefinition.Branch.ELECTRIC)


func _catalog_skill(id: StringName) -> SkillDefinition:
	for skill: SkillDefinition in CATALOG.skills:
		if skill.id == id:
			return skill
	return null


## skill-branches S6.3.
func test_speed_sword_raises_attack_speed_forty_percent() -> void:
	var skill: SkillDefinition = _catalog_skill(&"speed_sword")
	assert_eq(skill.display_name, "Espada Veloz")
	assert_eq(skill.branch, SkillDefinition.Branch.BOOST)
	assert_eq(skill.unlock_stage, 18)
	assert_eq(skill.base_cost, 4800.0)
	assert_eq(skill.power, 0.4)
	assert_eq(skill.duration_seconds, 8.0)
	assert_eq(skill.cooldown_seconds, 22.0)
	assert_eq(skill.buff_stats, [StatBlock.ATTACK_SPEED] as Array[StringName])


## skill-branches S6.1.
func test_burning_sword_raises_sword_damage_fifty_percent() -> void:
	var skill: SkillDefinition = _catalog_skill(&"burning_sword")
	assert_eq(skill.display_name, "Espada Ardiente")
	assert_eq(skill.branch, SkillDefinition.Branch.FIRE)
	assert_eq(skill.unlock_stage, 25)
	assert_eq(skill.base_cost, 38400.0)
	assert_eq(skill.power, 0.5)
	assert_eq(skill.duration_seconds, 10.0)
	assert_eq(skill.cooldown_seconds, 25.0)
	assert_eq(skill.buff_stats, [StatBlock.SWORD_DAMAGE] as Array[StringName])


## skill-branches S6.5.
func test_heal_restores_half_the_max_health_in_four_seconds() -> void:
	var skill: SkillDefinition = _catalog_skill(&"heal")
	assert_eq(skill.display_name, "Curación")
	assert_eq(skill.unlock_stage, 22)
	assert_eq(skill.base_cost, 19200.0)
	assert_eq(skill.power, 0.5)
	assert_eq(skill.duration_seconds, 4.0)
	assert_eq(skill.cooldown_seconds, 30.0)


## skill-branches S6.6.
func test_ice_block_hits_the_front_enemy_for_eight_times_attack() -> void:
	var skill: SkillDefinition = _catalog_skill(&"ice_block")
	assert_eq(skill.display_name, "Bloque de Hielo")
	assert_eq(skill.unlock_stage, 20)
	assert_eq(skill.base_cost, 9600.0)
	assert_eq(skill.power, 8.0)
	assert_eq(skill.cooldown_seconds, 10.0)


## skill-branches S6.2.
func test_flame_wave_hits_each_enemy_it_reaches_for_twelve_times_attack() -> void:
	var skill: SkillDefinition = _catalog_skill(&"flame_wave")
	assert_eq(skill.display_name, "Onda de Llamas")
	assert_eq(skill.unlock_stage, 28)
	assert_eq(skill.base_cost, 76800.0)
	assert_eq(skill.power, 12.0)
	assert_eq(skill.cooldown_seconds, 16.0)


## skill-branches S6.4.
func test_thunder_slash_strikes_twice_attack_every_0_4_s_for_4_s() -> void:
	var skill: SkillDefinition = _catalog_skill(&"thunder_slash")
	assert_eq(skill.display_name, "Tajo Relámpago")
	assert_eq(skill.unlock_stage, 32)
	assert_eq(skill.base_cost, 153600.0)
	assert_eq(skill.power, 2.0)
	assert_eq(skill.duration_seconds, 4.0)
	assert_eq(skill.hit_interval_seconds, 0.4)
	assert_eq(skill.cooldown_seconds, 24.0)


func test_fury_still_raises_attack_and_attack_speed() -> void:
	assert_eq(_catalog_skill(&"fury").buff_stats, [StatBlock.ATTACK, StatBlock.ATTACK_SPEED] as Array[StringName])


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
	assert_eq(GameState.session.skills.slots.size(), CATALOG.skills.size())
	assert_eq(GameState.session.spirits.slots.size(), 3)


func test_skill_prices_rise_with_their_unlock_stage() -> void:
	var prices: Dictionary[StringName, float] = {}
	for skill: SkillDefinition in CATALOG.skills:
		prices[skill.id] = skill.base_cost
		assert_eq(skill.cost_growth, 1.35, String(skill.id))
	assert_eq(prices, {&"thunder": 30.0, &"meteor": 150.0, &"blizzard": 300.0, &"fury": 600.0, &"shield": 1200.0, &"wind": 2400.0,
		&"speed_sword": 4800.0, &"ice_block": 9600.0, &"heal": 19200.0, &"burning_sword": 38400.0,
		&"flame_wave": 76800.0, &"thunder_slash": 153600.0,
	})


func test_wind_cools_faster_and_hits_a_little_less_than_thunder() -> void:
	var thunder: SkillDefinition = CATALOG.skills[0]
	var wind: SkillDefinition = CATALOG.skills[5]
	assert_eq(wind.display_name, "Viento")
	assert_lt(wind.cooldown_seconds, thunder.cooldown_seconds)
	assert_lt(wind.power, thunder.power)
	assert_gt(wind.power, thunder.power * 0.75, "only a little less")
	assert_true(wind.needs_target(), "the dash is wasted without an enemy")


func test_every_skill_has_a_cast_sound_and_an_icon() -> void:
	for skill: SkillDefinition in CATALOG.skills:
		assert_true(SfxPlayer.SOUNDS.has(skill.sound_id()), String(skill.id))
		assert_true(ResourceLoader.exists(AbilityPanel.ICON_PATH % skill.id), String(skill.id))
