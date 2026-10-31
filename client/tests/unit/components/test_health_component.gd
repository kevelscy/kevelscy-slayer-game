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


func test_shield_absorbs_damage_before_health() -> void:
	health.set_shield(BigNumber.from_float(40.0), 8.0)
	_hit(30.0)
	assert_almost_eq(health.current.to_float(), 100.0, 1e-9)
	assert_almost_eq(health.shield.to_float(), 10.0, 1e-9)
	assert_signal_emit_count(health, "damaged", 0)


func test_damage_beyond_the_shield_reaches_health() -> void:
	health.set_shield(BigNumber.from_float(40.0), 8.0)
	_hit(55.0, true)
	assert_true(health.shield.is_zero())
	assert_almost_eq(health.current.to_float(), 85.0, 1e-9)
	var result: DamageResult = get_signal_parameters(health, "damaged")[0]
	assert_almost_eq(result.amount.to_float(), 15.0, 1e-9)
	assert_true(result.is_critical)


func test_shield_expires_after_its_duration() -> void:
	health.set_shield(BigNumber.from_float(40.0), 8.0)
	health.tick_shield(7.9)
	assert_true(health.has_shield())
	health.tick_shield(0.1)
	assert_false(health.has_shield())
	_hit(30.0)
	assert_almost_eq(health.current.to_float(), 70.0, 1e-9)


## skill-branches S6.5: Curación spreads its heal over a few seconds.
func test_heal_over_time_spreads_the_heal_over_its_seconds() -> void:
	_hit(80.0)
	health.heal_over_time(BigNumber.from_float(50.0), 4.0)
	assert_true(health.is_regenerating())
	health.tick_regen(2.0)
	assert_almost_eq(health.current.to_float(), 45.0, 1e-6, "half the heal after half the time")
	health.tick_regen(2.0)
	assert_almost_eq(health.current.to_float(), 70.0, 1e-6)
	assert_false(health.is_regenerating())
	health.tick_regen(1.0)
	assert_almost_eq(health.current.to_float(), 70.0, 1e-6, "nothing once it ends")


func test_a_tick_past_the_end_heals_only_what_is_left() -> void:
	_hit(80.0)
	health.heal_over_time(BigNumber.from_float(50.0), 4.0)
	health.tick_regen(10.0)
	assert_almost_eq(health.current.to_float(), 70.0, 1e-6)


func test_heal_over_time_never_goes_past_max_health() -> void:
	_hit(10.0)
	health.heal_over_time(BigNumber.from_float(50.0), 4.0)
	health.tick_regen(4.0)
	assert_almost_eq(health.current.to_float(), 100.0, 1e-9)


func test_a_new_heal_over_time_replaces_the_running_one() -> void:
	_hit(80.0)
	health.heal_over_time(BigNumber.from_float(40.0), 4.0)
	health.heal_over_time(BigNumber.from_float(8.0), 2.0)
	health.tick_regen(4.0)
	assert_almost_eq(health.current.to_float(), 28.0, 1e-6)


func test_setup_clears_the_heal_over_time() -> void:
	_hit(80.0)
	health.heal_over_time(BigNumber.from_float(50.0), 4.0)
	health.setup(BigNumber.from_float(100.0))
	assert_false(health.is_regenerating())


func test_setup_clears_the_shield() -> void:
	health.set_shield(BigNumber.from_float(40.0), 8.0)
	health.setup(BigNumber.from_float(100.0))
	assert_false(health.has_shield())
