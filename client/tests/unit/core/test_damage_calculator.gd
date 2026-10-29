extends GutTest


func _stats(attack: float, crit_chance: float, crit_damage: float) -> StatBlock:
	var stats: StatBlock = StatBlock.new()
	stats.set_base(StatBlock.ATTACK, BigNumber.from_float(attack))
	stats.set_base_rate(StatBlock.CRIT_CHANCE, crit_chance)
	stats.set_base_rate(StatBlock.CRIT_DAMAGE, crit_damage)
	return stats


func _rng(seed_value: int = 42) -> RandomNumberGenerator:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func test_no_crit_deals_attack() -> void:
	var result: DamageResult = DamageCalculator.compute(_stats(100.0, 0.0, 2.0), _rng())
	assert_false(result.is_critical)
	assert_almost_eq(result.amount.to_float(), 100.0, 1e-9)


func test_crit_applies_crit_damage_multiplier() -> void:
	var result: DamageResult = DamageCalculator.compute(_stats(100.0, 1.0, 2.5), _rng())
	assert_true(result.is_critical)
	assert_almost_eq(result.amount.to_float(), 250.0, 1e-9)


func test_zero_crit_chance_never_crits() -> void:
	var stats: StatBlock = _stats(1.0, 0.0, 2.0)
	var rng: RandomNumberGenerator = _rng()
	for i: int in 2000:
		assert_false(DamageCalculator.compute(stats, rng).is_critical)
		if is_failing():
			return


func test_full_crit_chance_always_crits() -> void:
	var stats: StatBlock = _stats(1.0, 1.0, 2.0)
	var rng: RandomNumberGenerator = _rng()
	for i: int in 2000:
		assert_true(DamageCalculator.compute(stats, rng).is_critical)
		if is_failing():
			return


func test_crit_rate_converges_to_crit_chance() -> void:
	var stats: StatBlock = _stats(1.0, 0.25, 2.0)
	var rng: RandomNumberGenerator = _rng(7)
	var crits: int = 0
	for i: int in 10000:
		if DamageCalculator.compute(stats, rng).is_critical:
			crits += 1
	assert_between(crits, 2300, 2700)


func test_same_seed_produces_same_sequence() -> void:
	var stats: StatBlock = _stats(1.0, 0.5, 2.0)
	var rng_a: RandomNumberGenerator = _rng(99)
	var rng_b: RandomNumberGenerator = _rng(99)
	for i: int in 100:
		assert_eq(
			DamageCalculator.compute(stats, rng_a).is_critical,
			DamageCalculator.compute(stats, rng_b).is_critical
		)


func test_skill_multiplier_scales_damage() -> void:
	var result: DamageResult = DamageCalculator.compute(_stats(100.0, 0.0, 2.0), _rng(), 3.0)
	assert_almost_eq(result.amount.to_float(), 300.0, 1e-9)


func test_damage_beyond_float_range() -> void:
	var stats: StatBlock = StatBlock.new()
	stats.set_base(StatBlock.ATTACK, BigNumber.of(4.0, 500))
	stats.set_base_rate(StatBlock.CRIT_CHANCE, 1.0)
	stats.set_base_rate(StatBlock.CRIT_DAMAGE, 3.0)
	var result: DamageResult = DamageCalculator.compute(stats, _rng())
	assert_almost_eq(result.amount.mantissa, 1.2, 1e-9)
	assert_eq(result.amount.exponent, 501)
