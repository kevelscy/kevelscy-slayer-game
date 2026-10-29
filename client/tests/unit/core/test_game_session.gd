extends GutTest

const KILLS: int = 2

var session: GameSession


func before_each() -> void:
	session = GameSession.new(StageBalance.new(), KILLS, 30.0)


func _gold() -> float:
	return session.wallet.get_amount(GameSession.GOLD).to_float()


func test_regular_kill_grants_stage_gold_and_counts() -> void:
	session.on_enemy_killed(false)
	assert_almost_eq(_gold(), session.balance.gold_reward(1).to_float(), 1e-9)
	assert_eq(session.progression.kills, 1)


func test_boss_kill_grants_boss_gold_of_its_stage_and_advances() -> void:
	session.on_enemy_killed(false)
	session.on_enemy_killed(false)
	var gold_before: float = _gold()
	session.on_enemy_killed(true)
	var boss_reward: float = session.balance.boss_gold_reward(1).to_float()
	assert_almost_eq(_gold() - gold_before, boss_reward, 1e-9)
	assert_eq(session.progression.stage, 2)


func test_hero_death_fails_active_boss() -> void:
	session.on_enemy_killed(false)
	session.on_enemy_killed(false)
	session.on_hero_died()
	assert_false(session.progression.is_boss_active)
	assert_eq(session.progression.stage, 1)


func test_upgrade_spends_gold_and_raises_attack() -> void:
	var attack_before: float = session.hero_stats.get_big(StatBlock.ATTACK).to_float()
	session.wallet.add(GameSession.GOLD, session.attack_track.next_cost())
	assert_true(session.try_upgrade(session.attack_track))
	assert_true(session.hero_stats.get_big(StatBlock.ATTACK).to_float() > attack_before)
	assert_true(session.wallet.get_amount(GameSession.GOLD).is_zero())


func test_upgrade_without_gold_changes_nothing() -> void:
	var attack_before: float = session.hero_stats.get_big(StatBlock.ATTACK).to_float()
	assert_false(session.try_upgrade(session.attack_track))
	assert_eq(session.hero_stats.get_big(StatBlock.ATTACK).to_float(), attack_before)
	assert_eq(session.attack_track.level, 0)


func test_health_upgrade_raises_hero_max_health() -> void:
	var before: float = session.hero_max_health().to_float()
	session.wallet.add(GameSession.GOLD, session.health_track.next_cost())
	assert_true(session.try_upgrade(session.health_track))
	assert_true(session.hero_max_health().to_float() > before)


func test_enemy_stats_follow_current_stage() -> void:
	assert_true(session.enemy_health(false).is_equal_approx(session.balance.enemy_health(1)))
	assert_true(session.enemy_health(true).is_equal_approx(session.balance.boss_health(1)))
	session.progression.stage = 5
	assert_true(session.enemy_health(false).is_equal_approx(session.balance.enemy_health(5)))
