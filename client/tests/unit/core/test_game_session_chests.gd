extends GutTest
## GameSession side of chests: the gold boost on kills and every reward kind (bonuses S1-S3).

const ABILITIES: AbilityCatalog = preload("res://data/content/abilities/ability_catalog.tres")
const STAGE: int = 20

var session: GameSession


func before_each() -> void:
	session = GameSession.new(StageBalance.new(), 10, 30.0, ABILITIES)
	session.progression.restore_stage(STAGE)


func _gold() -> BigNumber:
	return session.wallet.get_amount(GameSession.GOLD)


func _reward(rarity: ChestTable.Rarity, index: int) -> ChestReward:
	return ChestTable.rewards_for(rarity)[index]


func _slot(id: StringName) -> SkillSlot:
	for slot: SkillSlot in session.skills.slots:
		if slot.definition.id == id:
			return slot
	return null


func test_a_gold_boost_multiplies_regular_and_boss_kill_gold() -> void:
	session.grant_chest_reward(_reward(ChestTable.Rarity.RARE, 0))
	session.on_enemy_killed(false)
	assert_true(_gold().is_equal_approx(session.balance.gold_reward(STAGE).mul_float(4.0)))
	var before: BigNumber = _gold()
	session.progression.restore_stage(STAGE)
	session.on_enemy_killed(true)
	assert_true(_gold().sub(before).is_equal_approx(session.balance.boss_gold_reward(STAGE).mul_float(4.0)))


func test_the_boost_stacks_with_the_wave_gold_multiplier() -> void:
	session.grant_chest_reward(_reward(ChestTable.Rarity.COMMON, 0))
	session.on_enemy_killed(false, GameSession.WAVE_GOLD_MULTIPLIER)
	var expected: BigNumber = session.balance.gold_reward(STAGE).mul_float(2.0 * GameSession.WAVE_GOLD_MULTIPLIER)
	assert_true(_gold().is_equal_approx(expected))


func test_the_boost_runs_down_with_combat_frames() -> void:
	session.grant_chest_reward(_reward(ChestTable.Rarity.COMMON, 0))
	session.tick_combat(60.0, false)
	session.on_enemy_killed(false)
	assert_true(_gold().is_equal_approx(session.balance.gold_reward(STAGE)))


func test_offline_gold_ignores_the_boost_and_clears_it() -> void:
	var rate_before: BigNumber = session.offline_gold_rate()
	session.grant_chest_reward(_reward(ChestTable.Rarity.SUPER, 0))
	assert_true(session.offline_gold_rate().is_equal_approx(rate_before))
	session.grant_offline(1000, 1600)
	assert_eq(session.gold_boost.multiplier(), 1.0)


func test_ascending_and_loading_a_save_end_the_boost() -> void:
	session.grant_chest_reward(_reward(ChestTable.Rarity.EPIC, 0))
	assert_gt(session.ascend(), 0)
	assert_eq(session.gold_boost.multiplier(), 1.0)
	session.grant_chest_reward(_reward(ChestTable.Rarity.EPIC, 0))
	session.apply_save(session.to_save(0))
	assert_eq(session.gold_boost.multiplier(), 1.0)


func test_gold_bags_pay_kill_gold_of_the_stage() -> void:
	session.grant_chest_reward(_reward(ChestTable.Rarity.COMMON, 1))
	var kill: BigNumber = session.balance.gold_reward(STAGE)
	assert_true(_gold().is_equal_approx(kill.mul_float(ChestTable.BAG_KILLS)))
	session.grant_chest_reward(_reward(ChestTable.Rarity.LEGENDARY, 1))
	assert_true(_gold().is_equal_approx(kill.mul_float(ChestTable.BAG_KILLS + ChestTable.BIG_BAG_KILLS)))


func test_free_fury_buffs_the_hero_even_if_fury_is_not_bought() -> void:
	assert_false(_slot(&"fury").is_owned())
	var attack_before: BigNumber = session.hero_stats.get_big(StatBlock.ATTACK)
	session.grant_chest_reward(_reward(ChestTable.Rarity.RARE, 1))
	assert_false(session.buffs.is_empty())
	assert_true(session.hero_stats.get_big(StatBlock.ATTACK).gt(attack_before))
	assert_false(_slot(&"fury").is_owned(), "a free cast does not buy the skill")


func test_recharge_makes_every_cooling_skill_ready() -> void:
	for slot: SkillSlot in session.skills.slots:
		slot.level = 1
		slot.start_cooldown()
	session.grant_chest_reward(_reward(ChestTable.Rarity.EPIC, 1))
	for slot: SkillSlot in session.skills.slots:
		assert_true(slot.is_ready(), String(slot.definition.id))


func test_skill_level_goes_to_the_lowest_bought_skill() -> void:
	_slot(&"thunder").level = 3
	_slot(&"meteor").level = 1
	_slot(&"fury").level = 2
	watch_signals(session.skills)
	session.grant_chest_reward(_reward(ChestTable.Rarity.SUPER, 1))
	assert_eq(_slot(&"meteor").level, 2)
	assert_eq(_slot(&"thunder").level, 3)
	assert_eq(_slot(&"fury").level, 2)
	assert_signal_emitted_with_parameters(session.skills, "leveled_up", [1, 2])


func test_skill_level_without_bought_skills_gives_thunder_its_first_level() -> void:
	session.grant_chest_reward(_reward(ChestTable.Rarity.SUPER, 1))
	assert_eq(_slot(&"thunder").level, 1)


func test_open_chest_rolls_a_reward_and_grants_it() -> void:
	session.chest_rng.seed = 7
	var reward: ChestReward = session.open_chest()
	assert_not_null(reward)
	assert_true(_same_kind_in(reward), "one of its rarity's two rewards")


func _same_kind_in(reward: ChestReward) -> bool:
	for candidate: ChestReward in ChestTable.rewards_for(reward.rarity):
		if candidate.label() == reward.label():
			return true
	return false


func test_chest_drops_use_the_session_roll() -> void:
	assert_true(session.chest_drops(true))
	session.chest_rng.seed = 1
	var drops: int = 0
	for index: int in 10000:
		if session.chest_drops(false):
			drops += 1
	assert_between(drops, 300, 500, "about 4% of 10000")


func test_roll_chest_rolls_a_reward_without_paying_it() -> void:
	session.chest_rng.seed = 7
	var reward: ChestReward = session.roll_chest()
	assert_true(_same_kind_in(reward), "one of its rarity's two rewards")
	assert_true(_gold().is_zero(), "no gold paid yet")
	assert_eq(session.gold_boost.multiplier(), 1.0, "no boost yet")
	assert_true(session.buffs.is_empty(), "no free fury yet")
	for slot: SkillSlot in session.skills.slots:
		assert_eq(slot.level, 0, "no skill level yet")


func test_open_chest_pays_what_roll_chest_rolls_with_the_same_roll() -> void:
	session.chest_rng.seed = 7
	var rolled: ChestReward = session.roll_chest()
	session.chest_rng.seed = 7
	var opened: ChestReward = session.open_chest()
	assert_eq(opened.rarity, rolled.rarity)
	assert_eq(opened.label(), rolled.label())
