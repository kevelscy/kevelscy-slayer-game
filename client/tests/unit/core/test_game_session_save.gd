extends GutTest

var session: GameSession


func before_each() -> void:
	session = GameSession.new()


func _saved(stage: int, gold: BigNumber, attack_level: int, health_level: int) -> SaveData:
	var data: SaveData = SaveData.new()
	data.stage = stage
	data.gold = gold
	data.attack_level = attack_level
	data.health_level = health_level
	data.last_seen_unix = 1_700_000_000
	return data


func test_to_save_captures_run_state_and_timestamp() -> void:
	session.wallet.add(GameSession.GOLD, BigNumber.from_float(250.0))
	session.attack_track.set_level(4)
	session.health_track.set_level(2)
	session.progression.stage = 3
	var data: SaveData = session.to_save(1_700_000_123)
	assert_eq(data.stage, 3)
	assert_true(data.gold.is_equal_approx(BigNumber.from_float(250.0)))
	assert_eq(data.attack_level, 4)
	assert_eq(data.health_level, 2)
	assert_eq(data.last_seen_unix, 1_700_000_123)


func test_apply_save_restores_stage_with_fresh_progress() -> void:
	for i: int in 10:
		session.progression.register_kill()
	assert_true(session.progression.is_boss_active)
	session.apply_save(_saved(5, BigNumber.zero(), 0, 0))
	assert_eq(session.progression.stage, 5)
	assert_eq(session.progression.kills, 0)
	assert_false(session.progression.is_boss_active)


func test_apply_save_restores_gold_on_the_same_wallet_and_notifies() -> void:
	var wallet: CurrencyWallet = session.wallet
	watch_signals(wallet)
	session.apply_save(_saved(1, BigNumber.of(2.0, 500), 0, 0))
	assert_same(session.wallet, wallet)
	assert_true(wallet.get_amount(GameSession.GOLD).is_equal_approx(BigNumber.of(2.0, 500)))
	assert_signal_emitted(wallet, "changed")


func test_apply_save_restores_levels_and_hero_stats() -> void:
	session.apply_save(_saved(1, BigNumber.zero(), 6, 2))
	assert_eq(session.attack_track.level, 6)
	assert_eq(session.health_track.level, 2)
	assert_true(session.hero_stats.get_big(StatBlock.ATTACK).is_equal_approx(session.attack_track.value()))
	assert_true(session.hero_max_health().is_equal_approx(session.health_track.value()))


func test_wallet_restore_rejects_negative_and_keeps_balance() -> void:
	session.wallet.add(GameSession.GOLD, BigNumber.from_float(40.0))
	session.wallet.restore(GameSession.GOLD, BigNumber.from_float(-1.0))
	assert_push_error("CurrencyWallet.restore")
	assert_true(session.wallet.get_amount(GameSession.GOLD).is_equal_approx(BigNumber.from_float(40.0)))


func test_rate_stats_start_at_their_base_values() -> void:
	assert_almost_eq(session.hero_stats.get_rate(StatBlock.CRIT_CHANCE), 0.05, 1e-9)
	assert_almost_eq(session.hero_stats.get_rate(StatBlock.CRIT_DAMAGE), 1.5, 1e-9)
	assert_almost_eq(session.hero_stats.get_rate(StatBlock.ATTACK_SPEED), 1.5, 1e-9)


func test_buying_rate_upgrades_raises_the_hero_rates() -> void:
	session.wallet.add(GameSession.GOLD, BigNumber.from_float(1_000_000.0))
	assert_true(session.try_upgrade(session.crit_chance_track))
	assert_true(session.try_upgrade(session.crit_damage_track))
	assert_true(session.try_upgrade(session.attack_speed_track))
	assert_almost_eq(session.hero_stats.get_rate(StatBlock.CRIT_CHANCE), 0.055, 1e-9)
	assert_almost_eq(session.hero_stats.get_rate(StatBlock.CRIT_DAMAGE), 1.55, 1e-9)
	assert_almost_eq(session.hero_stats.get_rate(StatBlock.ATTACK_SPEED), 1.52, 1e-9)


func test_rate_track_caps() -> void:
	assert_eq(session.crit_chance_track.max_level, 90)
	assert_eq(session.crit_damage_track.max_level, 0)
	assert_eq(session.attack_speed_track.max_level, 75)


func test_save_round_trip_keeps_rate_levels() -> void:
	session.crit_chance_track.set_level(9)
	session.crit_damage_track.set_level(41)
	session.attack_speed_track.set_level(20)
	var data: SaveData = session.to_save(1_700_000_123)
	assert_eq(data.crit_chance_level, 9)
	assert_eq(data.crit_damage_level, 41)
	assert_eq(data.attack_speed_level, 20)
	var restored: GameSession = GameSession.new()
	restored.apply_save(data)
	assert_eq(restored.crit_chance_track.level, 9)
	assert_eq(restored.crit_damage_track.level, 41)
	assert_eq(restored.attack_speed_track.level, 20)
	assert_almost_eq(restored.hero_stats.get_rate(StatBlock.CRIT_CHANCE), 0.095, 1e-9)
	assert_almost_eq(restored.hero_stats.get_rate(StatBlock.CRIT_DAMAGE), 3.55, 1e-9)
	assert_almost_eq(restored.hero_stats.get_rate(StatBlock.ATTACK_SPEED), 1.9, 1e-9)


func test_apply_save_clamps_rate_levels_above_the_cap() -> void:
	var data: SaveData = _saved(1, BigNumber.zero(), 0, 0)
	data.crit_chance_level = 500
	data.attack_speed_level = 500
	session.apply_save(data)
	assert_eq(session.crit_chance_track.level, 90)
	assert_eq(session.attack_speed_track.level, 75)
	assert_almost_eq(session.hero_stats.get_rate(StatBlock.CRIT_CHANCE), 0.5, 1e-9)
	assert_almost_eq(session.hero_stats.get_rate(StatBlock.ATTACK_SPEED), 3.0, 1e-9)


func test_save_round_trip_keeps_ascension_progress() -> void:
	var talents: TalentCatalog = preload("res://data/content/talents/talent_catalog.tres")
	var source: GameSession = GameSession.new(StageBalance.new(), 10, 30.0, AbilityCatalog.new(), talents)
	source.talents.shards = 7
	source.ascension_count = 3
	source.talents.set_levels({&"might": 4, &"greed": 2})
	var data: SaveData = source.to_save(1_700_000_123)
	assert_eq(data.ascension_shards, 7)
	assert_eq(data.ascension_count, 3)
	assert_eq(data.talents, {"might": 4, "vitality": 0, "greed": 2, "precision": 0, "ferocity": 0, "haste": 0})
	var restored: GameSession = GameSession.new(StageBalance.new(), 10, 30.0, AbilityCatalog.new(), talents)
	restored.apply_save(data)
	assert_eq(restored.talents.shards, 7)
	assert_eq(restored.ascension_count, 3)
	assert_eq(restored.talents.level(&"might"), 4)
	assert_almost_eq(restored.talents.gold_multiplier(), 1.2, 1e-9)
	assert_true(restored.hero_stats.get_big(StatBlock.ATTACK).is_equal_approx(restored.attack_track.value().mul_float(1.4)))


func test_apply_save_ignores_unknown_talents_and_clamps_levels() -> void:
	var talents: TalentCatalog = preload("res://data/content/talents/talent_catalog.tres")
	var target: GameSession = GameSession.new(StageBalance.new(), 10, 30.0, AbilityCatalog.new(), talents)
	var data: SaveData = _saved(1, BigNumber.zero(), 0, 0)
	data.talents = {"might": 99, "removed_talent": 4}
	target.apply_save(data)
	assert_eq(target.talents.level(&"might"), 10)
	assert_false(target.talents.levels().has(&"removed_talent"))


func test_apply_save_restarts_the_run_and_announces_it() -> void:
	var full: GameSession = GameSession.new(
		StageBalance.new(), 10, 30.0,
		preload("res://data/content/abilities/ability_catalog.tres"),
		preload("res://data/content/talents/talent_catalog.tres")
	)
	full.progression.restore_stage(20)
	assert_eq(full.spirits.slots.filter(func(slot: Variant) -> bool: return slot.unlocked).size(), 3, "precondition")
	watch_signals(full)
	var data: SaveData = _saved(2, BigNumber.from_float(10.0), 0, 0)
	data.ascension_count = 1
	full.apply_save(data)
	assert_eq(full.spirits.slots.filter(func(slot: Variant) -> bool: return slot.unlocked).size(), 1)
	var fresh: GameSession = GameSession.new(
		StageBalance.new(), 10, 30.0,
		preload("res://data/content/abilities/ability_catalog.tres"),
		preload("res://data/content/talents/talent_catalog.tres")
	)
	fresh.progression.restore_stage(2)
	assert_true(full.hero_max_health().is_equal_approx(fresh.hero_max_health()), "no passives from relocked spirits")
	assert_true(
		full.hero_stats.get_big(StatBlock.ATTACK).is_equal_approx(fresh.hero_stats.get_big(StatBlock.ATTACK))
	)
	assert_signal_emitted(full, "save_applied")
