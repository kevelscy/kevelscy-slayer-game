extends GutTest


func _stats(attack: float = 10.0) -> StatBlock:
	var stats: StatBlock = StatBlock.new()
	stats.set_base(StatBlock.ATTACK, BigNumber.from_float(attack))
	return stats


func test_base_value_without_modifiers() -> void:
	assert_almost_eq(_stats(10.0).get_big(StatBlock.ATTACK).to_float(), 10.0, 1e-9)


func test_flat_modifiers_apply_before_percent() -> void:
	var stats: StatBlock = _stats(10.0)
	stats.add_modifier(StatModifier.flat(StatBlock.ATTACK, 5.0))
	stats.add_modifier(StatModifier.percent(StatBlock.ATTACK, 0.5))
	# (10 + 5) * (1 + 0.5)
	assert_almost_eq(stats.get_big(StatBlock.ATTACK).to_float(), 22.5, 1e-9)


func test_percent_modifiers_stack_additively() -> void:
	var stats: StatBlock = _stats(10.0)
	stats.add_modifier(StatModifier.percent(StatBlock.ATTACK, 0.5))
	stats.add_modifier(StatModifier.percent(StatBlock.ATTACK, 0.5))
	assert_almost_eq(stats.get_big(StatBlock.ATTACK).to_float(), 20.0, 1e-9)


func test_flat_big_modifier_beyond_float_range() -> void:
	var stats: StatBlock = _stats(1.0)
	stats.add_modifier(StatModifier.flat_big(StatBlock.ATTACK, BigNumber.of(1.0, 400)))
	assert_eq(stats.get_big(StatBlock.ATTACK).exponent, 400)


func test_removed_modifier_no_longer_applies() -> void:
	var stats: StatBlock = _stats(10.0)
	var bonus: StatModifier = StatModifier.flat(StatBlock.ATTACK, 5.0)
	stats.add_modifier(bonus)
	stats.remove_modifier(bonus)
	assert_almost_eq(stats.get_big(StatBlock.ATTACK).to_float(), 10.0, 1e-9)


func test_defaults_for_rate_stats() -> void:
	var stats: StatBlock = StatBlock.new()
	assert_eq(stats.get_rate(StatBlock.CRIT_CHANCE), 0.0)
	assert_eq(stats.get_rate(StatBlock.CRIT_DAMAGE), StatBlock.DEFAULT_CRIT_DAMAGE)
	assert_eq(stats.get_rate(StatBlock.ATTACK_SPEED), StatBlock.DEFAULT_ATTACK_SPEED)


func test_crit_chance_is_clamped_to_unit_interval() -> void:
	var stats: StatBlock = StatBlock.new()
	stats.set_base_rate(StatBlock.CRIT_CHANCE, 0.9)
	stats.add_modifier(StatModifier.flat(StatBlock.CRIT_CHANCE, 0.3))
	assert_eq(stats.get_rate(StatBlock.CRIT_CHANCE), 1.0)
	stats.set_base_rate(StatBlock.CRIT_CHANCE, -2.0)
	assert_eq(stats.get_rate(StatBlock.CRIT_CHANCE), 0.0)


func test_crit_damage_and_attack_speed_have_floors() -> void:
	var stats: StatBlock = StatBlock.new()
	stats.set_base_rate(StatBlock.CRIT_DAMAGE, 0.2)
	stats.set_base_rate(StatBlock.ATTACK_SPEED, 0.0)
	assert_eq(stats.get_rate(StatBlock.CRIT_DAMAGE), 1.0)
	assert_eq(stats.get_rate(StatBlock.ATTACK_SPEED), StatBlock.MIN_ATTACK_SPEED)


func test_changed_signal_on_modifier_and_base_updates() -> void:
	var stats: StatBlock = StatBlock.new()
	watch_signals(stats)
	stats.set_base(StatBlock.ATTACK, BigNumber.from_float(3.0))
	stats.add_modifier(StatModifier.flat(StatBlock.ATTACK, 1.0))
	assert_signal_emit_count(stats, "changed", 2)
