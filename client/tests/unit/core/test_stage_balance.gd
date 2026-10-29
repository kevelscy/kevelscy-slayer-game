extends GutTest

var balance: StageBalance


func before_each() -> void:
	balance = StageBalance.new()
	balance.base_enemy_health = 20.0
	balance.enemy_health_growth = 1.25
	balance.base_enemy_damage = 2.0
	balance.enemy_damage_growth = 1.2
	balance.base_gold = 5.0
	balance.gold_growth = 1.2
	balance.boss_health_multiplier = 8.0
	balance.boss_gold_multiplier = 10.0


func test_stage_one_uses_base_values() -> void:
	assert_almost_eq(balance.enemy_health(1).to_float(), 20.0, 1e-9)
	assert_almost_eq(balance.enemy_damage(1).to_float(), 2.0, 1e-9)
	assert_almost_eq(balance.gold_reward(1).to_float(), 5.0, 1e-9)


func test_values_grow_per_stage() -> void:
	assert_almost_eq(balance.enemy_health(3).to_float(), 20.0 * 1.25 * 1.25, 1e-9)
	assert_almost_eq(balance.gold_reward(2).to_float(), 6.0, 1e-9)


func test_boss_multipliers() -> void:
	assert_almost_eq(balance.boss_health(1).to_float(), 160.0, 1e-9)
	assert_almost_eq(balance.boss_gold_reward(1).to_float(), 50.0, 1e-9)


func test_late_stages_exceed_float_range() -> void:
	var expected_log10: float = log(20.0) / log(10.0) + 4000.0 * log(1.25) / log(10.0)
	assert_almost_eq(balance.enemy_health(4001).log10(), expected_log10, 1e-6)


func test_stage_below_one_is_treated_as_one() -> void:
	assert_almost_eq(balance.enemy_health(0).to_float(), 20.0, 1e-9)
