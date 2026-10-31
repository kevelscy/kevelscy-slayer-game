extends GutTest
## Ascension: shards for the stage reached, the run reset, and Greed on gold.

const ABILITIES: AbilityCatalog = preload("res://data/content/abilities/ability_catalog.tres")
const TALENTS: TalentCatalog = preload("res://data/content/talents/talent_catalog.tres")
const HOUR: int = 3600
const LAST_SEEN: int = 1_700_000_000

var session: GameSession


func before_each() -> void:
	session = GameSession.new(StageBalance.new(), 10, 30.0, ABILITIES, TALENTS)


func _reach(stage: int) -> void:
	var data: SaveData = session.to_save(0)
	data.stage = stage
	data.gold = BigNumber.from_float(5000.0)
	data.attack_level = 7
	data.health_level = 6
	data.crit_chance_level = 5
	data.crit_damage_level = 4
	data.attack_speed_level = 3
	session.apply_save(data)


func test_shards_for_ascending_follow_the_stage() -> void:
	_reach(19)
	assert_false(session.can_ascend())
	assert_eq(session.ascension_shards_on_ascend(), 0)
	_reach(20)
	assert_true(session.can_ascend())
	assert_eq(session.ascension_shards_on_ascend(), 5)
	_reach(31)
	assert_eq(session.ascension_shards_on_ascend(), 16)


func test_ascending_below_stage_twenty_changes_nothing() -> void:
	_reach(19)
	watch_signals(session)
	assert_eq(session.ascend(), 0)
	assert_eq(session.progression.stage, 19)
	assert_true(session.wallet.get_amount(GameSession.GOLD).is_equal_approx(BigNumber.from_float(5000.0)))
	assert_eq(session.attack_track.level, 7)
	assert_eq(session.talents.shards, 0)
	assert_eq(session.ascension_count, 0)
	assert_signal_not_emitted(session, "ascended")


func test_ascending_resets_the_run_and_pays_shards() -> void:
	_reach(24)
	session.activate_buff(ABILITIES.skills[3])
	watch_signals(session)
	assert_eq(session.ascend(), 9)
	assert_eq(session.progression.stage, 1)
	assert_eq(session.progression.kills, 0)
	assert_false(session.progression.is_boss_active)
	assert_true(session.wallet.get_amount(GameSession.GOLD).is_zero())
	for track: UpgradeTrack in [
		session.attack_track, session.health_track, session.crit_chance_track,
		session.crit_damage_track, session.attack_speed_track,
	]:
		assert_eq(track.level, 0)
	assert_true(session.buffs.is_empty())
	assert_eq(session.talents.shards, 9)
	assert_eq(session.ascension_count, 1)
	assert_signal_emitted_with_parameters(session, "ascended", [9])


func test_run_reset_signals_already_see_the_paid_shards() -> void:
	_reach(24)
	var seen: Array[int] = []
	var record: Callable = func() -> void: seen.append_array([session.talents.shards, session.ascension_count])
	session.progression.stage_changed.connect(func(_stage: int) -> void: record.call())
	session.wallet.changed.connect(func(_currency: StringName, _total: BigNumber) -> void: record.call())
	session.ascend()
	assert_eq(seen, [9, 1, 9, 1], "wallet then stage listeners read the new shards and count")


func test_ascending_relocks_spirits_and_their_passives() -> void:
	var fresh_attack: BigNumber = session.hero_stats.get_big(StatBlock.ATTACK)
	_reach(20)
	assert_true(session.spirits.slots[0].unlocked)
	session.ascend()
	for slot: SpiritTeam.SpiritSlot in session.spirits.slots:
		assert_false(slot.unlocked)
	assert_true(session.hero_stats.get_big(StatBlock.ATTACK).is_equal_approx(fresh_attack))
	assert_almost_eq(session.hero_stats.get_rate(StatBlock.CRIT_CHANCE), 0.05, 1e-9)
	assert_false(session.skills.is_autocast_unlocked(session.progression.stage))
	session.progression.restore_stage(2)
	assert_true(session.spirits.slots[0].unlocked, "spirits unlock again on the next run")


func test_skill_cooldowns_restart_ready_after_ascending() -> void:
	_reach(20)
	session.skills.autocast_enabled = false
	session.tick_combat(0.0, true)
	session.skills.slots[0].level = 1
	session.skills.equip(0)
	assert_true(session.cast_skill(0))
	assert_false(session.skills.slots[0].is_ready())
	session.ascend()
	assert_true(session.skills.slots[0].is_ready())


func test_skill_levels_survive_ascending() -> void:
	_reach(20)
	session.skills.slots[0].level = 6
	session.ascend()
	assert_eq(session.skills.slots[0].level, 6)


func test_talents_survive_ascending() -> void:
	_reach(20)
	session.talents.shards = 1
	assert_true(session.talents.try_buy(&"might"))
	session.ascend()
	var with_might: BigNumber = session.attack_track.value().mul_float(1.1)
	assert_eq(session.talents.level(&"might"), 1)
	assert_true(session.hero_stats.get_big(StatBlock.ATTACK).is_equal_approx(with_might))


func test_greed_multiplies_kill_and_boss_gold() -> void:
	session.talents.set_levels({"greed": 5})
	session.on_enemy_killed(false)
	var expected: BigNumber = session.balance.gold_reward(1).mul_float(1.5)
	assert_true(session.wallet.get_amount(GameSession.GOLD).is_equal_approx(expected))
	session.wallet.restore(GameSession.GOLD, BigNumber.zero())
	for i: int in 9:
		session.progression.register_kill()
	session.on_enemy_killed(true)
	expected = session.balance.boss_gold_reward(1).mul_float(1.5)
	assert_true(session.wallet.get_amount(GameSession.GOLD).is_equal_approx(expected))


func test_greed_multiplies_offline_gold() -> void:
	var base_rate: BigNumber = session.offline_gold_rate()
	session.talents.set_levels({"greed": 10})
	assert_true(session.offline_gold_rate().is_equal_approx(base_rate.mul_float(2.0)))
	var reward: OfflineReward = session.grant_offline(LAST_SEEN, LAST_SEEN + HOUR)
	assert_true(reward.amounts[GameSession.GOLD].is_equal_approx(base_rate.mul_float(2.0 * HOUR)))
