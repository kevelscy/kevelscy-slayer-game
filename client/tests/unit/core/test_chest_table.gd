extends GutTest
## Chest drops, rarities and rewards (bonuses S1, S3).


func test_a_regular_enemy_drops_a_chest_four_percent_of_the_time() -> void:
	assert_true(ChestTable.drops(false, 0.0))
	assert_true(ChestTable.drops(false, 0.0399))
	assert_false(ChestTable.drops(false, 0.04))
	assert_false(ChestTable.drops(false, 0.99))


func test_a_boss_always_drops_a_chest() -> void:
	assert_true(ChestTable.drops(true, 0.0))
	assert_true(ChestTable.drops(true, 0.9999))


func test_rarity_odds_follow_the_table() -> void:
	assert_eq(ChestTable.WEIGHTS, [55, 27, 12, 5, 1] as Array[int])
	var cases: Array[Array] = [
		[0.0, ChestTable.Rarity.COMMON], [0.5499, ChestTable.Rarity.COMMON],
		[0.55, ChestTable.Rarity.RARE], [0.8199, ChestTable.Rarity.RARE],
		[0.82, ChestTable.Rarity.EPIC], [0.9399, ChestTable.Rarity.EPIC],
		[0.94, ChestTable.Rarity.LEGENDARY], [0.9899, ChestTable.Rarity.LEGENDARY],
		[0.99, ChestTable.Rarity.SUPER], [0.9999, ChestTable.Rarity.SUPER],
	]
	for entry: Array in cases:
		assert_eq(ChestTable.rarity_for(entry[0]), entry[1], str(entry[0]))


func test_rarity_names_are_spanish() -> void:
	assert_eq(ChestTable.RARITY_NAMES, ["Común", "Raro", "Épico", "Legendario", "Super"] as Array[String])


func test_each_rarity_offers_its_two_rewards() -> void:
	var expected: Array[Array] = [
		["Oro x2 60 s", "Bolsa de oro"],
		["Oro x4 60 s", "Furia gratis"],
		["Oro x6 90 s", "Recarga habilidades"],
		["Oro x8 120 s", "Bolsa grande"],
		["Oro x10 180 s", "+1 nivel habilidad"],
	]
	for rarity: int in ChestTable.Rarity.size():
		var labels: Array[String] = []
		for reward: ChestReward in ChestTable.rewards_for(rarity):
			assert_eq(reward.rarity, rarity)
			labels.append(reward.label())
		assert_eq(labels, expected[rarity] as Array[String], ChestTable.RARITY_NAMES[rarity])


func test_multiplier_rewards_carry_factor_and_seconds() -> void:
	var factors: Array[float] = []
	var seconds: Array[float] = []
	for rarity: int in ChestTable.Rarity.size():
		var boost: ChestReward = ChestTable.rewards_for(rarity)[0]
		assert_eq(boost.kind, ChestReward.Kind.GOLD_MULTIPLIER)
		factors.append(boost.factor)
		seconds.append(boost.seconds)
	assert_eq(factors, [2.0, 4.0, 6.0, 8.0, 10.0] as Array[float])
	assert_eq(seconds, [60.0, 60.0, 90.0, 120.0, 180.0] as Array[float])


func test_reward_roll_picks_either_reward_half_the_time() -> void:
	assert_eq(ChestTable.reward_for(ChestTable.Rarity.EPIC, 0.0).kind, ChestReward.Kind.GOLD_MULTIPLIER)
	assert_eq(ChestTable.reward_for(ChestTable.Rarity.EPIC, 0.4999).kind, ChestReward.Kind.GOLD_MULTIPLIER)
	assert_eq(ChestTable.reward_for(ChestTable.Rarity.EPIC, 0.5).kind, ChestReward.Kind.RECHARGE_SKILLS)
	assert_eq(ChestTable.reward_for(ChestTable.Rarity.EPIC, 0.9999).kind, ChestReward.Kind.RECHARGE_SKILLS)
