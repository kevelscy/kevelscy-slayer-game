extends GutTest

var stats: StatBlock
var buffs: BuffTracker


func before_each() -> void:
	stats = StatBlock.new()
	stats.set_base(StatBlock.ATTACK, BigNumber.from_float(100.0))
	stats.set_base_rate(StatBlock.ATTACK_SPEED, 1.0)
	buffs = BuffTracker.new(stats)


func _fury() -> Array[StatModifier]:
	return [
		StatModifier.percent(StatBlock.ATTACK, 0.5),
		StatModifier.percent(StatBlock.ATTACK_SPEED, 0.5),
	]


func test_buff_applies_its_modifiers() -> void:
	buffs.apply(&"fury", _fury(), 6.0)
	assert_almost_eq(stats.get_big(StatBlock.ATTACK).to_float(), 150.0, 1e-6)
	assert_almost_eq(stats.get_rate(StatBlock.ATTACK_SPEED), 1.5, 1e-6)
	assert_true(buffs.is_active(&"fury"))


func test_buff_expires_after_its_duration() -> void:
	buffs.apply(&"fury", _fury(), 6.0)
	buffs.tick(5.9)
	assert_true(buffs.is_active(&"fury"))
	buffs.tick(0.1)
	assert_false(buffs.is_active(&"fury"))
	assert_almost_eq(stats.get_big(StatBlock.ATTACK).to_float(), 100.0, 1e-6)
	assert_almost_eq(stats.get_rate(StatBlock.ATTACK_SPEED), 1.0, 1e-6)


func test_reapplying_refreshes_duration_without_stacking() -> void:
	buffs.apply(&"fury", _fury(), 6.0)
	buffs.tick(4.0)
	buffs.apply(&"fury", _fury(), 6.0)
	assert_almost_eq(stats.get_big(StatBlock.ATTACK).to_float(), 150.0, 1e-6)
	buffs.tick(5.0)
	assert_true(buffs.is_active(&"fury"))
	assert_almost_eq(buffs.remaining(&"fury"), 1.0, 1e-6)


func test_clear_removes_every_buff() -> void:
	buffs.apply(&"fury", _fury(), 6.0)
	buffs.clear()
	assert_false(buffs.is_active(&"fury"))
	assert_almost_eq(stats.get_big(StatBlock.ATTACK).to_float(), 100.0, 1e-6)


func test_unknown_buff_is_inactive() -> void:
	assert_false(buffs.is_active(&"nothing"))
	assert_eq(buffs.remaining(&"nothing"), 0.0)


func test_is_empty_tracks_active_buffs() -> void:
	assert_true(buffs.is_empty())
	buffs.apply(&"fury", _fury(), 6.0)
	assert_false(buffs.is_empty())
	buffs.tick(6.0)
	assert_true(buffs.is_empty())
