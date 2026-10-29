extends GutTest

const GOLD: StringName = &"gold"
const HOUR: int = 3600
const CAP: int = 12 * HOUR
const NOW: int = 1_800_000_000


func _rates(gold_per_second: float) -> Dictionary[StringName, BigNumber]:
	var rates: Dictionary[StringName, BigNumber] = {GOLD: BigNumber.from_float(gold_per_second)}
	return rates


func test_reward_is_rate_times_elapsed() -> void:
	var reward: OfflineReward = OfflineCalculator.compute(_rates(5.0), NOW - 2 * HOUR, NOW, CAP)
	assert_eq(reward.elapsed_seconds, 2 * HOUR)
	assert_almost_eq(reward.amounts[GOLD].to_float(), 5.0 * 2 * HOUR, 1e-6)


func test_elapsed_is_capped() -> void:
	var reward: OfflineReward = OfflineCalculator.compute(_rates(1.0), NOW - 100 * HOUR, NOW, CAP)
	assert_eq(reward.elapsed_seconds, CAP)
	assert_almost_eq(reward.amounts[GOLD].to_float(), float(CAP), 1e-6)


func test_clock_moved_backwards_gives_nothing() -> void:
	var reward: OfflineReward = OfflineCalculator.compute(_rates(1.0), NOW + HOUR, NOW, CAP)
	assert_eq(reward.elapsed_seconds, 0)
	assert_true(reward.amounts[GOLD].is_zero())
	assert_true(reward.is_empty())


func test_huge_rates_beyond_float_range() -> void:
	var rates: Dictionary[StringName, BigNumber] = {GOLD: BigNumber.of(2.0, 400)}
	var reward: OfflineReward = OfflineCalculator.compute(rates, NOW - 1000, NOW, CAP)
	assert_almost_eq(reward.amounts[GOLD].mantissa, 2.0, 1e-9)
	assert_eq(reward.amounts[GOLD].exponent, 403)


func test_same_inputs_same_result() -> void:
	var a: OfflineReward = OfflineCalculator.compute(_rates(3.3), NOW - 777, NOW, CAP)
	var b: OfflineReward = OfflineCalculator.compute(_rates(3.3), NOW - 777, NOW, CAP)
	assert_true(a.amounts[GOLD].is_equal_approx(b.amounts[GOLD]))


func test_kills_per_second_from_dps() -> void:
	var rate: float = OfflineCalculator.kills_per_second(
		BigNumber.from_float(10.0), BigNumber.from_float(50.0), 1.0
	)
	assert_almost_eq(rate, 0.2, 1e-9)


func test_kills_per_second_is_limited_by_spawn_pace() -> void:
	var rate: float = OfflineCalculator.kills_per_second(
		BigNumber.from_float(1000.0), BigNumber.from_float(50.0), 1.0
	)
	assert_almost_eq(rate, 1.0, 1e-9)
