extends GutTest

var stats: StatBlock
var team: SpiritTeam


static func spirit(
	id: StringName, unlock_stage: int, stat: StringName, value: float, interval: float, power: float,
	kind: StatModifier.Kind = StatModifier.Kind.PERCENT
) -> SpiritDefinition:
	var definition: SpiritDefinition = SpiritDefinition.new()
	definition.id = id
	definition.unlock_stage = unlock_stage
	definition.passive_stat = stat
	definition.passive_kind = kind
	definition.passive_value = value
	definition.attack_interval_seconds = interval
	definition.attack_power = power
	return definition


func before_each() -> void:
	stats = StatBlock.new()
	stats.set_base(StatBlock.ATTACK, BigNumber.from_float(100.0))
	var definitions: Array[SpiritDefinition] = [
		spirit(&"wisp", 2, StatBlock.ATTACK, 0.1, 3.0, 1.0),
		spirit(&"fox", 6, StatBlock.CRIT_CHANCE, 0.05, 4.0, 2.0, StatModifier.Kind.FLAT),
		spirit(&"owl", 10, StatBlock.HEALTH, 0.2, 5.0, 3.0),
	]
	team = SpiritTeam.new(definitions, stats)
	watch_signals(team)


func test_team_has_three_locked_slots() -> void:
	assert_eq(SpiritTeam.SLOT_COUNT, 3)
	assert_eq(team.slots.size(), 3)
	for slot: SpiritTeam.SpiritSlot in team.slots:
		assert_false(slot.unlocked)


func test_more_than_three_spirits_are_rejected_beyond_the_third() -> void:
	var definitions: Array[SpiritDefinition] = []
	for index: int in 4:
		definitions.append(spirit(StringName("s%d" % index), 1, StatBlock.ATTACK, 0.1, 1.0, 1.0))
	var oversized: SpiritTeam = SpiritTeam.new(definitions, StatBlock.new())
	assert_push_error("SpiritTeam")
	assert_eq(oversized.slots.size(), 3)


func test_reaching_the_unlock_stage_applies_the_permanent_passive() -> void:
	team.refresh_unlocks(1)
	assert_signal_not_emitted(team, "unlocked")
	assert_almost_eq(stats.get_big(StatBlock.ATTACK).to_float(), 100.0, 1e-6)
	team.refresh_unlocks(2)
	assert_true(team.slots[0].unlocked)
	assert_false(team.slots[1].unlocked)
	assert_signal_emitted_with_parameters(team, "unlocked", [0, team.slots[0].definition])
	assert_almost_eq(stats.get_big(StatBlock.ATTACK).to_float(), 110.0, 1e-6)


func test_refreshing_again_never_stacks_the_passive() -> void:
	team.refresh_unlocks(2)
	team.refresh_unlocks(3)
	assert_signal_emit_count(team, "unlocked", 1)
	assert_almost_eq(stats.get_big(StatBlock.ATTACK).to_float(), 110.0, 1e-6)


func test_jumping_stages_unlocks_every_reached_spirit() -> void:
	team.refresh_unlocks(10)
	assert_signal_emit_count(team, "unlocked", 3)
	assert_almost_eq(stats.get_rate(StatBlock.CRIT_CHANCE), 0.05, 1e-6)


func test_unlocked_spirit_attacks_every_interval_while_fighting() -> void:
	team.refresh_unlocks(2)
	assert_eq(team.tick(2.9, true), 0)
	assert_eq(team.tick(0.1, true), 1)
	assert_signal_emitted_with_parameters(team, "attacked", [0, team.slots[0].definition])
	assert_eq(team.tick(2.9, true), 0)
	assert_eq(team.tick(0.1, true), 1)


func test_spirit_holds_its_ready_attack_until_there_is_a_target() -> void:
	team.refresh_unlocks(2)
	assert_eq(team.tick(10.0, false), 0)
	assert_signal_not_emitted(team, "attacked")
	assert_eq(team.tick(0.01, true), 1)


func test_locked_spirits_never_attack() -> void:
	assert_eq(team.tick(60.0, true), 0)
	assert_signal_not_emitted(team, "attacked")


func test_expected_dps_sums_unlocked_spirits() -> void:
	var attack: BigNumber = BigNumber.from_float(100.0)
	assert_true(team.expected_dps(attack).is_zero())
	team.refresh_unlocks(6)
	# wisp 100 * 1 / 3 s + fox 100 * 2 / 4 s
	assert_almost_eq(team.expected_dps(attack).to_float(), 100.0 / 3.0 + 50.0, 1e-6)
