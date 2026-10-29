extends GutTest

const GOLD: StringName = &"gold"

var track: UpgradeTrack
var wallet: CurrencyWallet


func before_each() -> void:
	track = UpgradeTrack.new(BigNumber.from_float(10.0), 1.1, CostCurve.new(BigNumber.from_float(5.0), 1.5))
	wallet = CurrencyWallet.new()
	watch_signals(track)


func test_level_zero_value_and_cost() -> void:
	assert_eq(track.level, 0)
	assert_almost_eq(track.value().to_float(), 10.0, 1e-9)
	assert_almost_eq(track.next_cost().to_float(), 5.0, 1e-9)


func test_buying_spends_cost_and_levels_up() -> void:
	wallet.add(GOLD, BigNumber.from_float(100.0))
	assert_true(track.try_buy(wallet, GOLD))
	assert_eq(track.level, 1)
	assert_almost_eq(track.value().to_float(), 11.0, 1e-9)
	assert_almost_eq(track.next_cost().to_float(), 7.5, 1e-9)
	assert_almost_eq(wallet.get_amount(GOLD).to_float(), 95.0, 1e-9)
	assert_signal_emitted_with_parameters(track, "leveled_up", [1])


func test_unaffordable_purchase_changes_nothing() -> void:
	wallet.add(GOLD, BigNumber.from_float(4.0))
	assert_false(track.try_buy(wallet, GOLD))
	assert_eq(track.level, 0)
	assert_almost_eq(wallet.get_amount(GOLD).to_float(), 4.0, 1e-9)
	assert_signal_not_emitted(track, "leveled_up")


func test_set_level_restores_saved_progress() -> void:
	track.set_level(10)
	assert_eq(track.level, 10)
	assert_almost_eq(track.value().to_float(), 10.0 * pow(1.1, 10), 1e-6)
