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
		_skill(&"shield", SkillDefinition.Effect.SHIELD, 1, 0.5),
	]
	catalog.spirits = [
		SpiritTest.spirit(&"wisp", 2, StatBlock.ATTACK, 0.1, 3.0, 1.0),
		SpiritTest.spirit(&"owl", 10, StatBlock.HEALTH, 0.2, 5.0, 3.0),
	]
	return catalog


func before_each() -> void:
	session = GameSession.new(StageBalance.new(), 10, 30.0, _catalog())


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
