extends GutTest

var health: HealthComponent


func before_each() -> void:
	health = HealthComponent.new()
	add_child_autofree(health)
	health.setup(BigNumber.from_float(100.0))
	watch_signals(health)


func _hit(amount: float, critical: bool = false) -> void:
	health.take_damage(DamageResult.new(BigNumber.from_float(amount), critical))


func test_setup_fills_health() -> void:
	assert_almost_eq(health.current.to_float(), 100.0, 1e-9)
	assert_almost_eq(health.get_ratio(), 1.0, 1e-9)
	assert_false(health.is_dead())


func test_damage_reduces_health_and_emits_damaged() -> void:
	_hit(30.0, true)
	assert_almost_eq(health.current.to_float(), 70.0, 1e-9)
	assert_almost_eq(health.get_ratio(), 0.7, 1e-9)
	assert_signal_emit_count(health, "damaged", 1)
	var params: Array = get_signal_parameters(health, "damaged")
	var result: DamageResult = params[0]
	assert_true(result.is_critical)


func test_overkill_clamps_to_zero_and_dies_once() -> void:
	_hit(250.0)
	assert_true(health.current.is_zero())
	assert_true(health.is_dead())
	assert_signal_emit_count(health, "died", 1)


func test_damage_after_death_is_ignored() -> void:
	_hit(100.0)
	_hit(10.0)
	assert_true(health.current.is_zero())
	assert_signal_emit_count(health, "damaged", 1)
	assert_signal_emit_count(health, "died", 1)


func test_heal_is_capped_at_max() -> void:
	_hit(50.0)
	health.heal(BigNumber.from_float(80.0))
	assert_almost_eq(health.current.to_float(), 100.0, 1e-9)
	assert_signal_emit_count(health, "healed", 1)


func test_heal_after_death_is_ignored() -> void:
	_hit(100.0)
	health.heal(BigNumber.from_float(50.0))
	assert_true(health.is_dead())
	assert_signal_emit_count(health, "healed", 0)


func test_setup_revives_with_new_max() -> void:
	_hit(100.0)
	health.setup(BigNumber.of(5.0, 400))
	assert_false(health.is_dead())
	assert_eq(health.current.exponent, 400)
	assert_almost_eq(health.get_ratio(), 1.0, 1e-9)


func test_ratio_with_huge_values() -> void:
	health.setup(BigNumber.of(1.0, 500))
	health.take_damage(DamageResult.new(BigNumber.of(2.5, 499), false))
	assert_almost_eq(health.get_ratio(), 0.75, 1e-9)
