extends GutTest

var attack: AutoAttackComponent


func before_each() -> void:
	attack = AutoAttackComponent.new()
	attack.attacks_per_second = 2.0
	add_child_autofree(attack)
	watch_signals(attack)


func test_fires_immediately_when_ready_with_target() -> void:
	assert_true(attack.tick(0.016, true))
	assert_signal_emit_count(attack, "attack_triggered", 1)


func test_respects_interval_between_attacks() -> void:
	attack.tick(0.0, true)
	assert_false(attack.tick(0.4, true))
	assert_true(attack.tick(0.1, true))
	assert_signal_emit_count(attack, "attack_triggered", 2)


func test_never_fires_without_target() -> void:
	assert_false(attack.tick(5.0, false))
	assert_signal_not_emitted(attack, "attack_triggered")


func test_cooldown_recovers_while_no_target() -> void:
	attack.tick(0.0, true)
	attack.tick(0.5, false)
	assert_true(attack.tick(0.0, true))


func test_one_attack_per_tick_even_with_large_delta() -> void:
	attack.tick(0.0, true)
	assert_true(attack.tick(10.0, true))
	assert_signal_emit_count(attack, "attack_triggered", 2)


func test_speed_floor_prevents_division_by_zero() -> void:
	attack.attacks_per_second = 0.0
	attack.tick(0.0, true)
	assert_false(attack.tick(9.0, true))
	assert_true(attack.tick(1.0, true))
