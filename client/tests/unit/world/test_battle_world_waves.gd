extends GutTest
## A wave drops six tougher, richer enemies into the lane at once, tight or spread.

const BATTLE_WORLD: PackedScene = preload("res://world/battle_world.tscn")

var world: BattleWorld
var session: GameSession


func before_each() -> void:
	session = GameSession.new(StageBalance.new(), 10, 30.0)
	world = BATTLE_WORLD.instantiate()
	add_child_autofree(world)
	world.start(session)


func _alive() -> Array[Enemy]:
	var enemies: Array[Enemy] = []
	for node: Node in world.enemy_pool.active_nodes():
		if (node as Enemy).is_alive:
			enemies.append(node as Enemy)
	return enemies


func test_the_world_rolls_waves_with_the_session_chance() -> void:
	assert_eq(world.scheduler.wave_chance, GameSession.WAVE_CHANCE)
	assert_gt(GameSession.WAVE_CHANCE, 0.0)


func test_a_wave_spawns_six_enemies_behind_the_spawn_point() -> void:
	world._spawn_wave()
	var enemies: Array[Enemy] = _alive()
	assert_eq(enemies.size(), SpawnScheduler.WAVE_SIZE)
	assert_eq(SpawnScheduler.WAVE_SIZE, 6)
	var xs: Array[float] = []
	for enemy: Enemy in enemies:
		assert_gte(enemy.position.x, BattleWorld.SPAWN_X)
		assert_false(enemy.is_boss)
		xs.append(enemy.position.x)
	xs.sort()
	for index: int in range(1, xs.size()):
		assert_gte(xs[index] - xs[index - 1], BattleWorld.WAVE_TIGHT_GAP, "never stacked on one spot")


func test_wave_enemies_have_a_quarter_more_health_and_gold() -> void:
	world._spawn_wave()
	for enemy: Enemy in _alive():
		var expected: BigNumber = session.enemy_health(false).mul_float(
			enemy.definition.health_multiplier * 1.25
		)
		assert_true(enemy.health.max_health.is_equal_approx(expected))
		assert_eq(enemy.gold_multiplier, 1.25)


func test_killing_a_wave_enemy_pays_the_wave_gold() -> void:
	world._spawn_wave()
	var enemy: Enemy = _alive()[0]
	enemy.health.take_damage(DamageResult.new(BigNumber.from_float(1e30), false))
	var gold: float = session.wallet.get_amount(GameSession.GOLD).to_float()
	assert_almost_eq(gold, session.balance.gold_reward(1).to_float() * 1.25, 1e-6)


func test_a_regular_enemy_keeps_plain_health_and_gold() -> void:
	world._spawn(world.roster.regular_enemies[0], false)
	var enemy: Enemy = _alive()[0]
	assert_eq(enemy.gold_multiplier, 1.0)
	enemy.health.take_damage(DamageResult.new(BigNumber.from_float(1e30), false))
	var gold: float = session.wallet.get_amount(GameSession.GOLD).to_float()
	assert_almost_eq(gold, session.balance.gold_reward(1).to_float(), 1e-6)
