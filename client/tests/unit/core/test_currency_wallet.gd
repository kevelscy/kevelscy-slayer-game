extends GutTest

const GOLD: StringName = &"gold"
const GEMS: StringName = &"gems"

var wallet: CurrencyWallet


func before_each() -> void:
	wallet = CurrencyWallet.new()
	watch_signals(wallet)


func test_unknown_currency_is_zero() -> void:
	assert_true(wallet.get_amount(GOLD).is_zero())


func test_add_accumulates_and_emits_total() -> void:
	wallet.add(GOLD, BigNumber.from_float(50.0))
	wallet.add(GOLD, BigNumber.from_float(25.0))
	assert_almost_eq(wallet.get_amount(GOLD).to_float(), 75.0, 1e-9)
	assert_signal_emit_count(wallet, "changed", 2)


func test_spend_succeeds_when_affordable() -> void:
	wallet.add(GOLD, BigNumber.from_float(100.0))
	assert_true(wallet.try_spend(GOLD, BigNumber.from_float(40.0)))
	assert_almost_eq(wallet.get_amount(GOLD).to_float(), 60.0, 1e-9)


func test_spend_fails_without_changing_balance() -> void:
	wallet.add(GOLD, BigNumber.from_float(10.0))
	assert_false(wallet.try_spend(GOLD, BigNumber.from_float(11.0)))
	assert_almost_eq(wallet.get_amount(GOLD).to_float(), 10.0, 1e-9)
	assert_signal_emit_count(wallet, "changed", 1)


func test_spend_exact_balance_leaves_zero() -> void:
	wallet.add(GEMS, BigNumber.of(3.0, 500))
	assert_true(wallet.try_spend(GEMS, BigNumber.of(3.0, 500)))
	assert_true(wallet.get_amount(GEMS).is_zero())


func test_negative_add_is_rejected() -> void:
	wallet.add(GOLD, BigNumber.from_float(10.0))
	wallet.add(GOLD, BigNumber.from_float(-5.0))
	assert_almost_eq(wallet.get_amount(GOLD).to_float(), 10.0, 1e-9)
	assert_push_error("CurrencyWallet.add")


func test_serialization_roundtrip() -> void:
	wallet.add(GOLD, BigNumber.of(1.5, 1234))
	wallet.add(GEMS, BigNumber.from_float(42.0))
	var restored: CurrencyWallet = CurrencyWallet.from_dict(wallet.to_dict())
	assert_eq(restored.get_amount(GOLD).exponent, 1234)
	assert_almost_eq(restored.get_amount(GEMS).to_float(), 42.0, 1e-9)
