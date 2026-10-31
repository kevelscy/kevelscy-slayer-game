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
	for slot: SkillSlot in bar.slots:
		slot.level = 1
	bar.equip_owned()
	watch_signals(bar)


## A bar of `count` skills, all unlocked at stage 1.
func _wide_bar(count: int) -> SkillBar:
	var definitions: Array[SkillDefinition] = []
	for index: int in count:
		definitions.append(_skill(StringName("s%d" % index), SkillDefinition.Effect.DAMAGE_ALL, 1, 1.0))
	return SkillBar.new(definitions)


func test_the_bar_holds_every_catalog_skill_in_catalog_order() -> void:
	assert_eq(bar.slots.size(), 5)
	assert_eq(bar.slots[0].definition.id, &"thunder")
	assert_eq(bar.slots[4].definition.id, &"shield")
	var wide: SkillBar = _wide_bar(12)
	assert_eq(wide.slots.size(), 12, "no slot limit: every skill of the catalog is on the bar")


## skill-branches S4: up to 8 equipped skills; only they cast.
func test_equip_owned_equips_the_first_eight_owned_skills_in_catalog_order() -> void:
	assert_eq(SkillBar.EQUIP_LIMIT, 8)
	var wide: SkillBar = _wide_bar(12)
	for index: int in 12:
		if index != 1:
			wide.slots[index].level = 1
	wide.equip_owned()
	assert_eq(wide.equipped, [0, 2, 3, 4, 5, 6, 7, 8] as Array[int])
	assert_false(wide.is_equipped(1), "not bought")
	assert_false(wide.is_equipped(9), "no slot left")


func test_an_unequipped_skill_neither_casts_nor_autocasts() -> void:
	assert_true(bar.unequip(0))
	assert_false(bar.is_equipped(0))
	assert_false(bar.try_cast(0, true))
	assert_eq(bar.autocast(10, true), 4)
	assert_eq(bar.slots[0].cooldown_remaining, 0.0, "thunder stayed off the bar")


func test_equip_needs_a_bought_unequipped_skill_and_a_free_slot() -> void:
	var wide: SkillBar = _wide_bar(10)
	watch_signals(wide)
	assert_false(wide.equip(0), "not bought")
	for index: int in 10:
		wide.slots[index].level = 1
	for index: int in 8:
		assert_true(wide.equip(index))
	assert_false(wide.equip(3), "already equipped")
	assert_false(wide.equip(8), "all 8 slots taken")
	assert_false(wide.equip(42), "no such skill")
	assert_true(wide.unequip(3))
	assert_false(wide.unequip(3), "already unequipped")
	assert_true(wide.equip(9))
	assert_eq(wide.equipped, [0, 1, 2, 4, 5, 6, 7, 9] as Array[int], "equipping appends")
	assert_signal_emit_count(wide, "equipment_changed", 10)


func test_buying_the_first_level_equips_the_skill_when_a_slot_is_free() -> void:
	var wide: SkillBar = _wide_bar(10)
	var wallet: CurrencyWallet = CurrencyWallet.new()
	wallet.add(&"gold", BigNumber.from_float(1e9))
	for index: int in 9:
		assert_true(wide.try_buy(index, 1, wallet, &"gold"))
	assert_eq(wide.equipped, [0, 1, 2, 3, 4, 5, 6, 7] as Array[int])
	assert_false(wide.is_equipped(8), "bought while the bar was full")
	assert_true(wide.try_buy(0, 1, wallet, &"gold"))
	assert_eq(wide.equipped.size(), 8, "a later level changes nothing")
	wide.unequip(7)
	wide.grant_level(9)
	assert_true(wide.is_equipped(9), "a free first level from a chest equips too")


func test_equipped_ids_round_trip_keeping_only_bought_known_skills_once() -> void:
	bar.slots[2].level = 0
	bar.set_equipped(["meteor", "ghost", "blizzard", "meteor", "thunder"])
	assert_eq(bar.equipped, [1, 0] as Array[int])
	assert_eq(bar.equipped_ids(), [&"meteor", &"thunder"] as Array[StringName])
	var wide: SkillBar = _wide_bar(10)
	var ids: Array[String] = []
	for index: int in 10:
		wide.slots[index].level = 1
		ids.append("s%d" % index)
	wide.set_equipped(ids)
	assert_eq(wide.equipped.size(), 8, "never more than 8")


func test_cast_starts_cooldown_and_emits_cast() -> void:
	assert_true(bar.try_cast(0, true))
	assert_signal_emitted_with_parameters(bar, "cast", [0, bar.slots[0].definition])
	assert_almost_eq(bar.slots[0].cooldown_remaining, 8.0, 1e-9)
	assert_false(bar.slots[0].is_ready())


func test_cast_on_cooldown_does_nothing() -> void:
	bar.try_cast(0, true)
	bar.tick(7.9)
	assert_false(bar.try_cast(0, true))
	assert_signal_emit_count(bar, "cast", 1)
	assert_almost_eq(bar.slots[0].cooldown_remaining, 0.1, 1e-6)


func test_cooldown_ends_after_its_duration() -> void:
	bar.try_cast(0, true)
	bar.tick(8.0)
	assert_true(bar.slots[0].is_ready())
	assert_eq(bar.slots[0].cooldown_remaining, 0.0)
	assert_true(bar.try_cast(0, true))


func test_cooldown_ratio_counts_down_from_one_to_zero() -> void:
	assert_eq(bar.slots[0].cooldown_ratio(), 0.0)
	bar.try_cast(0, true)
	assert_almost_eq(bar.slots[0].cooldown_ratio(), 1.0, 1e-9)
	bar.tick(2.0)
	assert_almost_eq(bar.slots[0].cooldown_ratio(), 0.75, 1e-9)


func test_a_skill_not_bought_cannot_cast() -> void:
	bar.slots[1].level = 0
	assert_false(bar.slots[1].is_owned())
	assert_false(bar.slots[1].is_ready())
	assert_false(bar.try_cast(1, true))
	assert_signal_not_emitted(bar, "cast")
	assert_eq(bar.slots[1].cooldown_remaining, 0.0)


func test_a_bought_skill_casts_at_any_stage() -> void:
	assert_true(bar.slots[4].is_owned())
	assert_true(bar.try_cast(4, true), "the shield unlocks at stage 12 but is owned")


func test_a_skill_can_be_bought_once_its_stage_is_reached() -> void:
	bar.slots[1].level = 0
	assert_false(bar.slots[1].can_buy(2))
	assert_true(bar.slots[1].can_buy(3))


func test_an_owned_skill_levels_up_at_any_stage() -> void:
	assert_true(bar.slots[4].can_buy(1))


func test_skill_cost_grows_with_each_level() -> void:
	var slot: SkillSlot = bar.slots[0]
	slot.definition.base_cost = 100.0
	slot.definition.cost_growth = 2.0
	slot.level = 0
	assert_almost_eq(slot.cost().to_float(), 100.0, 1e-9)
	slot.level = 3
	assert_almost_eq(slot.cost().to_float(), 800.0, 1e-9)


func test_levels_round_trip_by_skill_id() -> void:
	bar.slots[0].level = 4
	bar.slots[2].level = 0
	var levels: Dictionary[StringName, int] = bar.levels()
	assert_eq(levels[&"thunder"], 4)
	assert_eq(levels[&"blizzard"], 0)
	bar.set_levels({"meteor": 7, "ghost": 3, "fury": -2})
	assert_eq(bar.slots[0].level, 0, "a missing id means not bought")
	assert_eq(bar.slots[1].level, 7)
	assert_eq(bar.slots[3].level, 0, "negative levels clamp to 0")


func test_grant_reached_gives_level_one_to_skills_up_to_the_stage() -> void:
	bar.set_levels({"thunder": 3})
	bar.grant_reached(5)
	assert_eq(bar.slots[0].level, 3, "an owned skill keeps its level")
	assert_eq(bar.slots[1].level, 1)
	assert_eq(bar.slots[2].level, 1)
	assert_eq(bar.slots[3].level, 0)
	assert_eq(bar.slots[4].level, 0)


func test_damage_skills_need_a_target() -> void:
	for index: int in [0, 1, 2]:
		assert_false(bar.try_cast(index, false), "slot %d" % index)
	assert_signal_not_emitted(bar, "cast")


func test_buff_and_shield_cast_without_a_target() -> void:
	assert_true(bar.try_cast(3, false))
	assert_true(bar.try_cast(4, false))


func test_out_of_range_slot_does_nothing() -> void:
	assert_false(bar.try_cast(5, true))
	assert_false(bar.try_cast(-1, true))
	assert_signal_not_emitted(bar, "cast")


func test_autocast_is_locked_before_stage_ten() -> void:
	assert_false(bar.is_autocast_unlocked(9))
	assert_eq(bar.autocast(9, true), 0)
	assert_signal_not_emitted(bar, "cast")
	assert_true(bar.is_autocast_unlocked(10))


func test_autocast_casts_every_ready_owned_skill_in_combat() -> void:
	bar.slots[4].level = 0
	assert_eq(bar.autocast(10, true), 4)
	assert_signal_emit_count(bar, "cast", 4)
	assert_eq(bar.slots[4].cooldown_remaining, 0.0, "the shield is not bought")
	assert_eq(bar.autocast(10, true), 0, "everything is on cooldown")


func test_autocast_waits_for_combat() -> void:
	assert_eq(bar.autocast(20, false), 0)
	assert_signal_not_emitted(bar, "cast")


func test_autocast_toggle_off_stops_autocast() -> void:
	bar.autocast_enabled = false
	assert_eq(bar.autocast(20, true), 0)
	assert_true(bar.try_cast(0, true), "manual casts still work")


func test_autocast_starts_enabled() -> void:
	assert_true(bar.autocast_enabled)
