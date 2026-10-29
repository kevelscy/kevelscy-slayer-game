extends GutTest
## Permanent talents bought with ascension shards: costs, caps, prerequisites and bonuses.

var stats: StatBlock
var tree: TalentTree


static func talent(
	id: StringName, stat: StringName, kind: StatModifier.Kind, per_level: float,
	requires: StringName = &"", requires_level: int = 5
) -> TalentDefinition:
	var definition: TalentDefinition = TalentDefinition.new()
	definition.id = id
	definition.display_name = String(id).capitalize()
	definition.stat = stat
	definition.kind = kind
	definition.per_level = per_level
	definition.max_level = 10
	definition.requires = requires
	definition.requires_level = requires_level
	return definition


func before_each() -> void:
	stats = StatBlock.new()
	stats.set_base(StatBlock.ATTACK, BigNumber.from_float(100.0))
	stats.set_base_rate(StatBlock.CRIT_CHANCE, 0.05)
	var definitions: Array[TalentDefinition] = [
		talent(&"might", StatBlock.ATTACK, StatModifier.Kind.PERCENT, 0.1),
		talent(&"greed", TalentDefinition.GOLD_GAIN, StatModifier.Kind.PERCENT, 0.1),
		talent(&"precision", StatBlock.CRIT_CHANCE, StatModifier.Kind.FLAT, 0.01, &"might"),
	]
	tree = TalentTree.new(definitions, stats)
	watch_signals(tree)


func test_buying_level_n_plus_one_costs_n_plus_one_shards() -> void:
	tree.shards = 3
	assert_eq(tree.next_cost(&"might"), 1)
	assert_true(tree.try_buy(&"might"))
	assert_eq(tree.next_cost(&"might"), 2)
	assert_true(tree.try_buy(&"might"))
	assert_eq(tree.level(&"might"), 2)
	assert_eq(tree.shards, 0)
	assert_signal_emitted_with_parameters(tree, "leveled_up", [&"might", 2])


func test_talent_bonus_applies_immediately_and_grows_with_level() -> void:
	tree.shards = 10
	tree.try_buy(&"might")
	assert_almost_eq(stats.get_big(StatBlock.ATTACK).to_float(), 110.0, 1e-6)
	tree.try_buy(&"might")
	assert_almost_eq(stats.get_big(StatBlock.ATTACK).to_float(), 120.0, 1e-6)


func test_unaffordable_purchase_spends_nothing() -> void:
	tree.shards = 1
	tree.try_buy(&"might")
	assert_false(tree.try_buy(&"might"))
	assert_eq(tree.level(&"might"), 1)
	assert_eq(tree.shards, 0)


func test_maxed_talent_cannot_be_bought() -> void:
	tree.set_levels({&"might": 10})
	tree.shards = 100
	assert_true(tree.is_maxed(&"might"))
	assert_false(tree.try_buy(&"might"))
	assert_eq(tree.shards, 100)


func test_tier_two_talent_needs_its_prerequisite_level() -> void:
	tree.shards = 100
	assert_false(tree.is_unlocked(&"precision"))
	assert_false(tree.try_buy(&"precision"))
	assert_eq(tree.shards, 100)
	tree.set_levels({&"might": 5})
	assert_true(tree.is_unlocked(&"precision"))
	assert_true(tree.try_buy(&"precision"))
	assert_almost_eq(stats.get_rate(StatBlock.CRIT_CHANCE), 0.06, 1e-9)


func test_gold_gain_talent_multiplies_gold_and_not_stats() -> void:
	assert_almost_eq(tree.gold_multiplier(), 1.0, 1e-9)
	tree.set_levels({&"greed": 3})
	assert_almost_eq(tree.gold_multiplier(), 1.3, 1e-9)
	assert_almost_eq(stats.get_big(StatBlock.ATTACK).to_float(), 100.0, 1e-6)


func test_set_levels_clamps_ignores_unknown_ids_and_replaces_bonuses() -> void:
	tree.set_levels({&"might": 50, &"unknown": 3})
	assert_eq(tree.level(&"might"), 10)
	assert_almost_eq(stats.get_big(StatBlock.ATTACK).to_float(), 200.0, 1e-6)
	tree.set_levels({})
	assert_eq(tree.level(&"might"), 0)
	assert_almost_eq(stats.get_big(StatBlock.ATTACK).to_float(), 100.0, 1e-6)


func test_levels_snapshot_lists_every_talent() -> void:
	tree.set_levels({&"might": 2})
	assert_eq(tree.levels(), {&"might": 2, &"greed": 0, &"precision": 0})
