extends GutTest

const HOUR: int = 3600
const LAST_SEEN: int = 1_700_000_000

var session: GameSession


func before_each() -> void:
	session = GameSession.new()


func _expected_rate() -> BigNumber:
	var kills: float = OfflineCalculator.kills_per_second(
		DamageCalculator.expected_dps(session.hero_stats),
		session.enemy_health(false),
		GameSession.SPAWN_INTERVAL_SECONDS
	)
	return session.balance.gold_reward(session.progression.stage).mul_float(kills)


func test_offline_rate_is_kill_rate_times_gold_per_kill() -> void:
	assert_true(session.offline_gold_rate().is_equal_approx(_expected_rate()))
	assert_false(session.offline_gold_rate().is_zero())


func test_offline_rate_grows_with_stage_rewards() -> void:
	var stage_one: BigNumber = session.offline_gold_rate()
	var saved: SaveData = SaveData.new()
	saved.stage = 3
	saved.attack_level = 200
	session.apply_save(saved)
	assert_true(session.offline_gold_rate().gt(stage_one))


func test_grant_adds_rate_times_elapsed_to_gold() -> void:
	var reward: OfflineReward = session.grant_offline(LAST_SEEN, LAST_SEEN + HOUR)
	var expected: BigNumber = _expected_rate().mul_float(HOUR)
	assert_eq(reward.elapsed_seconds, HOUR)
	assert_true(reward.amounts[GameSession.GOLD].is_equal_approx(expected))
	assert_true(session.wallet.get_amount(GameSession.GOLD).is_equal_approx(expected))


func test_grant_is_capped_at_eight_hours() -> void:
	var reward: OfflineReward = session.grant_offline(LAST_SEEN, LAST_SEEN + 30 * HOUR)
	assert_eq(GameSession.OFFLINE_CAP_SECONDS, 8 * HOUR)
	assert_eq(reward.elapsed_seconds, 8 * HOUR)


func test_clock_moved_backwards_grants_nothing() -> void:
	var reward: OfflineReward = session.grant_offline(LAST_SEEN, LAST_SEEN - HOUR)
	assert_true(reward.is_empty())
	assert_true(session.wallet.get_amount(GameSession.GOLD).is_zero())


func test_grant_does_not_advance_stage_or_kills() -> void:
	session.grant_offline(LAST_SEEN, LAST_SEEN + HOUR)
	assert_eq(session.progression.stage, 1)
	assert_eq(session.progression.kills, 0)


func test_offline_rate_counts_crit_and_attack_speed_upgrades() -> void:
	var before: BigNumber = session.offline_gold_rate()
	var saved: SaveData = SaveData.new()
	saved.crit_damage_level = 40
	saved.attack_speed_level = 50
	session.apply_save(saved)
	assert_true(session.offline_gold_rate().gt(before))
	assert_true(session.offline_gold_rate().is_equal_approx(_expected_rate()))
