extends GutTest
## Linear rate upgrades (crit chance, crit damage, attack speed) with an optional max level.

const GOLD: StringName = &"gold"

var track: RateUpgradeTrack
var wallet: CurrencyWallet


func before_each() -> void:
	track = RateUpgradeTrack.new(0.05, 0.005, 2, CostCurve.new(BigNumber.from_float(10.0), 2.0))
	wallet = CurrencyWallet.new()
	wallet.add(GOLD, BigNumber.from_float(1000.0))
	watch_signals(track)


func test_rate_grows_linearly_with_level() -> void:
	assert_almost_eq(track.rate(), 0.05, 1e-9)
	assert_true(track.try_buy(wallet, GOLD))
	assert_almost_eq(track.rate(), 0.055, 1e-9)
	assert_almost_eq(track.next_cost().to_float(), 20.0, 1e-9)


func test_maxed_track_cannot_be_bought_and_keeps_the_gold() -> void:
	assert_true(track.try_buy(wallet, GOLD))
	assert_true(track.try_buy(wallet, GOLD))
	assert_true(track.is_maxed())
	assert_false(track.try_buy(wallet, GOLD))
	assert_eq(track.level, 2)
	assert_almost_eq(track.rate(), 0.06, 1e-9)
	assert_almost_eq(wallet.get_amount(GOLD).to_float(), 970.0, 1e-9)
	assert_signal_emit_count(track, "leveled_up", 2)


func test_set_level_clamps_to_the_max_level() -> void:
	track.set_level(50)
	assert_eq(track.level, 2)
	assert_true(track.is_maxed())


func test_zero_max_level_means_unlimited() -> void:
	var unlimited: RateUpgradeTrack = RateUpgradeTrack.new(1.5, 0.05, 0, CostCurve.new(BigNumber.from_float(1.0), 1.0))
	unlimited.set_level(500)
	assert_eq(unlimited.level, 500)
	assert_false(unlimited.is_maxed())
	assert_almost_eq(unlimited.rate(), 26.5, 1e-9)


func test_scaling_tracks_have_no_max_by_default() -> void:
	var scaling: UpgradeTrack = UpgradeTrack.new(BigNumber.from_float(10.0), 1.1, CostCurve.new(BigNumber.from_float(5.0), 1.5))
	scaling.set_level(1000)
	assert_eq(scaling.level, 1000)
	assert_false(scaling.is_maxed())
