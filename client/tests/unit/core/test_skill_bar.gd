extends GutTest

var bar: SkillBar


func _skill(
	id: StringName, effect: SkillDefinition.Effect, unlock_stage: int, cooldown: float
) -> SkillDefinition:
	var definition: SkillDefinition = SkillDefinition.new()
	definition.id = id
	definition.effect = effect
	definition.unlock_stage = unlock_stage
	definition.cooldown_seconds = cooldown
	return definition


func before_each() -> void:
	var definitions: Array[SkillDefinition] = [
		_skill(&"thunder", SkillDefinition.Effect.DAMAGE_ALL, 1, 8.0),
		_skill(&"meteor", SkillDefinition.Effect.DAMAGE_FRONT, 3, 12.0),
		_skill(&"blizzard", SkillDefinition.Effect.FREEZE_ALL, 5, 15.0),
		_skill(&"fury", SkillDefinition.Effect.BUFF, 8, 20.0),
		_skill(&"shield", SkillDefinition.Effect.SHIELD, 12, 25.0),
	]
	bar = SkillBar.new(definitions)
	watch_signals(bar)


func test_bar_has_five_slots_in_catalog_order() -> void:
	assert_eq(SkillBar.SLOT_COUNT, 5)
	assert_eq(bar.slots.size(), 5)
	assert_eq(bar.slots[0].definition.id, &"thunder")
	assert_eq(bar.slots[4].definition.id, &"shield")


func test_more_than_five_definitions_are_rejected_beyond_the_fifth() -> void:
	var definitions: Array[SkillDefinition] = []
	for index: int in 6:
		definitions.append(_skill(StringName("s%d" % index), SkillDefinition.Effect.DAMAGE_ALL, 1, 1.0))
	var oversized: SkillBar = SkillBar.new(definitions)
	assert_push_error("SkillBar")
	assert_eq(oversized.slots.size(), 5)


func test_cast_starts_cooldown_and_emits_cast() -> void:
	assert_true(bar.try_cast(0, 1, true))
	assert_signal_emitted_with_parameters(bar, "cast", [0, bar.slots[0].definition])
	assert_almost_eq(bar.slots[0].cooldown_remaining, 8.0, 1e-9)
	assert_false(bar.slots[0].is_ready(1))


func test_cast_on_cooldown_does_nothing() -> void:
	bar.try_cast(0, 1, true)
	bar.tick(7.9)
	assert_false(bar.try_cast(0, 1, true))
	assert_signal_emit_count(bar, "cast", 1)
	assert_almost_eq(bar.slots[0].cooldown_remaining, 0.1, 1e-6)


func test_cooldown_ends_after_its_duration() -> void:
	bar.try_cast(0, 1, true)
	bar.tick(8.0)
	assert_true(bar.slots[0].is_ready(1))
	assert_eq(bar.slots[0].cooldown_remaining, 0.0)
	assert_true(bar.try_cast(0, 1, true))


func test_cooldown_ratio_counts_down_from_one_to_zero() -> void:
	assert_eq(bar.slots[0].cooldown_ratio(), 0.0)
	bar.try_cast(0, 1, true)
	assert_almost_eq(bar.slots[0].cooldown_ratio(), 1.0, 1e-9)
	bar.tick(2.0)
	assert_almost_eq(bar.slots[0].cooldown_ratio(), 0.75, 1e-9)


func test_locked_skill_cannot_cast_until_its_unlock_stage() -> void:
	assert_false(bar.slots[1].is_unlocked(2))
	assert_false(bar.try_cast(1, 2, true))
	assert_signal_not_emitted(bar, "cast")
	assert_eq(bar.slots[1].cooldown_remaining, 0.0)
	assert_true(bar.try_cast(1, 3, true))


func test_damage_skills_need_a_target() -> void:
	for index: int in [0, 1, 2]:
		assert_false(bar.try_cast(index, 99, false), "slot %d" % index)
	assert_signal_not_emitted(bar, "cast")


func test_buff_and_shield_cast_without_a_target() -> void:
	assert_true(bar.try_cast(3, 99, false))
	assert_true(bar.try_cast(4, 99, false))


func test_out_of_range_slot_does_nothing() -> void:
	assert_false(bar.try_cast(5, 99, true))
	assert_false(bar.try_cast(-1, 99, true))
	assert_signal_not_emitted(bar, "cast")


func test_autocast_is_locked_before_stage_ten() -> void:
	assert_false(bar.is_autocast_unlocked(9))
	assert_eq(bar.autocast(9, true), 0)
	assert_signal_not_emitted(bar, "cast")
	assert_true(bar.is_autocast_unlocked(10))


func test_autocast_casts_every_ready_unlocked_skill_in_combat() -> void:
	assert_eq(bar.autocast(10, true), 4)
	assert_signal_emit_count(bar, "cast", 4)
	assert_eq(bar.slots[4].cooldown_remaining, 0.0, "shield stays locked until stage 12")
	assert_eq(bar.autocast(10, true), 0, "everything is on cooldown")


func test_autocast_waits_for_combat() -> void:
	assert_eq(bar.autocast(20, false), 0)
	assert_signal_not_emitted(bar, "cast")


func test_autocast_toggle_off_stops_autocast() -> void:
	bar.autocast_enabled = false
	assert_eq(bar.autocast(20, true), 0)
	assert_true(bar.try_cast(0, 20, true), "manual casts still work")


func test_autocast_starts_enabled() -> void:
	assert_true(bar.autocast_enabled)
