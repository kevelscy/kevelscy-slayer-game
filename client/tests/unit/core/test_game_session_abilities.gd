extends GutTest
## GameSession wiring of the skill bar, timed buffs and spirits.

const SpiritTest: GDScript = preload("res://tests/unit/core/test_spirit_team.gd")

var session: GameSession


func _skill(id: StringName, effect: SkillDefinition.Effect, unlock_stage: int, power: float) -> SkillDefinition:
	var definition: SkillDefinition = SkillDefinition.new()
	definition.id = id
	definition.effect = effect
	definition.unlock_stage = unlock_stage
	definition.cooldown_seconds = 10.0
	definition.power = power
	definition.duration_seconds = 6.0
	return definition


func _catalog() -> AbilityCatalog:
	var catalog: AbilityCatalog = AbilityCatalog.new()
	catalog.skills = [
		_skill(&"thunder", SkillDefinition.Effect.DAMAGE_ALL, 1, 3.0),
		_skill(&"fury", SkillDefinition.Effect.BUFF, 1, 0.5),
		_skill(&"shield", SkillDefinition.Effect.SHIELD, 3, 0.5),
	]
	catalog.spirits = [
		SpiritTest.spirit(&"wisp", 2, StatBlock.ATTACK, 0.1, 3.0, 1.0),
		SpiritTest.spirit(&"owl", 10, StatBlock.HEALTH, 0.2, 5.0, 3.0),
	]
	return catalog


func before_each() -> void:
	session = GameSession.new(StageBalance.new(), 10, 30.0, _catalog())


func _own_all() -> void:
	for slot: SkillSlot in session.skills.slots:
		slot.level = 1
	session.skills.equip_owned()


func _restore(stage: int) -> void:
	var data: SaveData = session.to_save(0)
	data.stage = stage
	session.apply_save(data)


func test_default_session_has_no_abilities() -> void:
	var plain: GameSession = GameSession.new()
	assert_eq(plain.skills.slots.size(), 0)
	assert_eq(plain.spirits.slots.size(), 0)


func test_session_builds_the_bar_and_team_from_the_catalog() -> void:
	assert_eq(session.skills.slots.size(), 3)
	assert_eq(session.spirits.slots.size(), 2)
	assert_false(session.spirits.slots[0].unlocked, "stage 1 is below the wisp unlock")


func test_reaching_a_stage_unlocks_its_spirit() -> void:
	session.progression.restore_stage(2)
	assert_true(session.spirits.slots[0].unlocked)
	assert_almost_eq(session.hero_stats.get_big(StatBlock.ATTACK).to_float(), 11.0, 1e-6)


func test_loading_a_save_restores_unlocks_from_the_stage() -> void:
	_restore(12)
	assert_true(session.spirits.slots[0].unlocked)
	assert_true(session.spirits.slots[1].unlocked)


func test_skill_damage_scales_with_hero_attack() -> void:
	assert_almost_eq(session.skill_damage(session.skills.slots[0].definition).to_float(), 30.0, 1e-6)


func test_each_skill_level_above_one_adds_fifteen_percent_power() -> void:
	var thunder: SkillDefinition = session.skills.slots[0].definition
	session.skills.slots[0].level = 3
	assert_almost_eq(session.skill_damage(thunder).to_float(), 30.0 * 1.3, 1e-6)
	session.skills.slots[2].level = 2
	assert_almost_eq(session.shield_amount(session.skills.slots[2].definition).to_float(), 50.0 * 1.15, 1e-6)
	session.skills.slots[1].level = 5
	session.activate_buff(session.skills.slots[1].definition)
	assert_almost_eq(session.hero_stats.get_big(StatBlock.ATTACK).to_float(), 10.0 * (1.0 + 0.5 * 1.6), 1e-6)


func test_buying_a_skill_spends_its_cost_and_raises_its_level() -> void:
	var slot: SkillSlot = session.skills.slots[0]
	var cost: BigNumber = slot.cost()
	session.wallet.add(GameSession.GOLD, cost.mul_float(3.0))
	watch_signals(session.skills)
	assert_true(session.try_buy_skill(0))
	assert_eq(slot.level, 1)
	assert_true(session.wallet.get_amount(GameSession.GOLD).is_equal_approx(cost.mul_float(2.0)))
	assert_signal_emitted_with_parameters(session.skills, "leveled_up", [0, 1])
	assert_true(slot.cost().to_float() > cost.to_float(), "the next level costs more")


func test_a_skill_is_not_bought_before_its_stage_or_without_gold() -> void:
	session.wallet.add(GameSession.GOLD, BigNumber.from_float(1e12))
	assert_false(session.try_buy_skill(2), "the shield needs stage 3")
	assert_eq(session.skills.slots[2].level, 0)
	assert_true(session.wallet.get_amount(GameSession.GOLD).is_equal_approx(BigNumber.from_float(1e12)))
	session.wallet.restore(GameSession.GOLD, BigNumber.zero())
	assert_false(session.try_buy_skill(0), "no gold")
	assert_eq(session.skills.slots[0].level, 0)
	assert_false(session.try_buy_skill(9), "no such slot")


func test_a_new_game_owns_no_skill_and_casts_nothing() -> void:
	for slot: SkillSlot in session.skills.slots:
		assert_eq(slot.level, 0)
	session.in_combat = true
	assert_false(session.cast_skill(0))


func test_save_round_trip_keeps_skill_levels() -> void:
	session.skills.slots[0].level = 4
	session.skills.slots[2].level = 1
	var data: SaveData = session.to_save(0)
	assert_eq(data.skills, {"thunder": 4, "fury": 0, "shield": 1})
	var loaded: GameSession = GameSession.new(StageBalance.new(), 10, 30.0, _catalog())
	loaded.apply_save(data)
	assert_eq(loaded.skills.slots[0].level, 4)
	assert_eq(loaded.skills.slots[1].level, 0)
	assert_eq(loaded.skills.slots[2].level, 1)


## skill-branches S6.3/S6.1: a buff raises only its own stats.
func test_a_buff_raises_only_its_buff_stats() -> void:
	var attack: BigNumber = session.hero_stats.get_big(StatBlock.ATTACK)
	var speed: float = session.hero_stats.get_rate(StatBlock.ATTACK_SPEED)
	var thunder_damage: BigNumber = session.skill_damage(session.skills.slots[0].definition)
	var haste: SkillDefinition = _skill(&"speed_sword", SkillDefinition.Effect.BUFF, 1, 0.4)
	haste.buff_stats = [StatBlock.ATTACK_SPEED]
	session.activate_buff(haste)
	assert_true(session.hero_stats.get_big(StatBlock.ATTACK).is_equal_approx(attack))
	assert_almost_eq(session.hero_stats.get_rate(StatBlock.ATTACK_SPEED), speed * 1.4, 1e-6)
	var blade: SkillDefinition = _skill(&"burning_sword", SkillDefinition.Effect.BUFF, 1, 0.5)
	blade.buff_stats = [StatBlock.SWORD_DAMAGE]
	assert_eq(session.hero_stats.get_rate(StatBlock.SWORD_DAMAGE), 1.0, "plain sword hits")
	session.activate_buff(blade)
	assert_almost_eq(session.hero_stats.get_rate(StatBlock.SWORD_DAMAGE), 1.5, 1e-6)
	assert_true(session.skill_damage(session.skills.slots[0].definition).is_equal_approx(thunder_damage),
		"skills do not hit harder with the burning sword")


## skill-branches S4: the equipped list is saved.
func test_save_round_trip_keeps_the_equipped_skills() -> void:
	_own_all()
	session.skills.unequip(0)
	session.skills.equip(0)
	var data: SaveData = session.to_save(0)
	assert_eq(data.equipped, ["fury", "shield", "thunder"] as Array[String])
	assert_true(data.has_equipped)
	var loaded: GameSession = GameSession.new(StageBalance.new(), 10, 30.0, _catalog())
	loaded.apply_save(data)
	assert_eq(loaded.skills.equipped_ids(), [&"fury", &"shield", &"thunder"] as Array[StringName])
	loaded.skills.unequip(2)
	loaded.apply_save(loaded.to_save(0))
	assert_eq(loaded.skills.equipped_ids(), [&"fury", &"thunder"] as Array[StringName], "an unequipped skill stays off")


func test_a_save_without_an_equipped_list_equips_its_bought_skills() -> void:
	var data: SaveData = session.to_save(0)
	data.skills = {"thunder": 2, "fury": 0, "shield": 1}
	data.equipped = []
	data.has_equipped = false
	session.apply_save(data)
	assert_eq(session.skills.equipped_ids(), [&"thunder", &"shield"] as Array[StringName])


func test_a_save_without_skill_levels_owns_the_skills_its_stage_reached() -> void:
	var data: SaveData = session.to_save(0)
	data.stage = 2
	data.skills = {}
	data.has_skill_levels = false
	data.has_equipped = false
	session.apply_save(data)
	assert_eq(session.skills.slots[0].level, 1)
	assert_eq(session.skills.slots[1].level, 1)
	assert_eq(session.skills.slots[2].level, 0, "the shield needs stage 3")
	assert_eq(session.skills.equipped_ids(), [&"thunder", &"fury"] as Array[StringName])


func test_spirit_damage_scales_with_hero_attack() -> void:
	_restore(2)
	var wisp: SpiritDefinition = session.spirits.slots[0].definition
	assert_almost_eq(session.spirit_damage(wisp).to_float(), 11.0, 1e-6)


func test_buff_skill_raises_attack_and_speed_until_it_expires() -> void:
	session.activate_buff(session.skills.slots[1].definition)
	assert_almost_eq(session.hero_stats.get_big(StatBlock.ATTACK).to_float(), 15.0, 1e-6)
	assert_almost_eq(session.hero_stats.get_rate(StatBlock.ATTACK_SPEED), 2.25, 1e-6)
	session.tick_combat(6.0, true)
	assert_almost_eq(session.hero_stats.get_big(StatBlock.ATTACK).to_float(), 10.0, 1e-6)


func test_shield_amount_is_a_fraction_of_max_health() -> void:
	assert_almost_eq(session.shield_amount(session.skills.slots[2].definition).to_float(), 50.0, 1e-6)


func test_offline_rate_adds_spirit_dps() -> void:
	_restore(2)
	var dps: BigNumber = DamageCalculator.expected_dps(session.hero_stats).add(
		session.spirits.expected_dps(session.hero_stats.get_big(StatBlock.ATTACK))
	)
	var kills: float = OfflineCalculator.kills_per_second(
		dps, session.enemy_health(false), GameSession.SPAWN_INTERVAL_SECONDS
	)
	var expected: BigNumber = session.balance.gold_reward(2).mul_float(kills)
	assert_true(session.offline_gold_rate().is_equal_approx(expected))


func test_offline_grant_ends_buffs_and_pays_without_them() -> void:
	var base_rate: BigNumber = session.offline_gold_rate()
	session.activate_buff(session.skills.slots[1].definition)
	var reward: OfflineReward = session.grant_offline(0, 3600)
	assert_false(session.buffs.is_active(&"fury"))
	assert_true(reward.amounts[GameSession.GOLD].is_equal_approx(base_rate.mul_float(3600.0)))


func test_tick_combat_runs_cooldowns_spirits_and_autocast() -> void:
	_restore(10)
	_own_all()
	watch_signals(session.skills)
	watch_signals(session.spirits)
	session.tick_combat(0.1, true)
	assert_signal_emit_count(session.skills, "cast", 3, "auto-cast fires every ready skill at stage 10")
	session.tick_combat(3.0, true)
	assert_signal_emit_count(session.spirits, "attacked", 1)
	assert_almost_eq(session.skills.slots[0].cooldown_remaining, 7.0, 1e-6)


func test_tick_combat_without_autocast_unlocked_never_casts() -> void:
	watch_signals(session.skills)
	session.tick_combat(1.0, true)
	assert_signal_not_emitted(session.skills, "cast")


func test_manual_cast_uses_the_combat_state() -> void:
	_own_all()
	watch_signals(session.skills)
	assert_false(session.cast_skill(0), "thunder needs a target and the hero is not fighting")
	session.tick_combat(0.0, true)
	assert_true(session.in_combat)
	assert_true(session.cast_skill(0))
	assert_true(session.cast_skill(1), "buffs cast in or out of combat")
	session.tick_combat(0.0, false)
	assert_false(session.in_combat)
	assert_signal_emit_count(session.skills, "cast", 2)
