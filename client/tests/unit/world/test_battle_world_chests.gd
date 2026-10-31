extends GutTest
## Chests dropped by kills lie in the lane, scroll with the world and the hero picks
## them up as it runs over them (bonuses S1).

const BATTLE_WORLD: PackedScene = preload("res://world/battle_world.tscn")

var world: BattleWorld
var session: GameSession


func before_each() -> void:
	session = GameSession.new(StageBalance.new(), 10, 30.0)
	world = BATTLE_WORLD.instantiate()
	add_child_autofree(world)
	world.start(session)
	watch_signals(world)


## Bosses always drop a chest.
func _kill_boss_at(x: float) -> void:
	world._spawn(world.roster.boss, true, x)
	var boss: Enemy = world.enemy_pool.active_nodes().back() as Enemy
	boss.health.take_damage(DamageResult.new(BigNumber.from_float(1e30), false))


func test_a_boss_kill_drops_a_chest_on_the_ground_where_it_died() -> void:
	_kill_boss_at(200.0)
	assert_eq(world.chests.size(), 1)
	var chest: ChestPickup = world.chests[0]
	assert_eq(chest.position, Vector2(200.0, BattleWorld.GROUND_Y))
	assert_eq(chest.texture, load(ChestPickup.TEXTURE_PATH))
	assert_eq(chest.get_parent(), world)
	assert_signal_not_emitted(world, "chest_picked")


func test_a_chest_scrolls_with_the_running_world_and_the_hero_picks_it_up_once() -> void:
	_kill_boss_at(200.0)
	var chest: ChestPickup = world.chests[0]
	world._set_world_speed(BattleWorld.RUN_SPEED)
	world._move_chests(1.0)
	assert_almost_eq(chest.position.x, 200.0 - BattleWorld.RUN_SPEED, 0.001)
	assert_signal_not_emitted(world, "chest_picked")
	world._move_chests(1.0)
	assert_signal_emit_count(world, "chest_picked", 1)
	assert_true(world.chests.is_empty())
	assert_true(chest.is_queued_for_deletion())
	world._move_chests(1.0)
	assert_signal_emit_count(world, "chest_picked", 1)


func test_a_standing_hero_leaves_the_chest_where_it_lies() -> void:
	_kill_boss_at(200.0)
	world._set_world_speed(0.0)
	world._move_chests(1.0)
	assert_eq(world.chests[0].position.x, 200.0)
	assert_signal_not_emitted(world, "chest_picked")


func test_a_new_run_clears_the_chests_without_picking_them() -> void:
	_kill_boss_at(200.0)
	var chest: ChestPickup = world.chests[0]
	world._restart_run()
	assert_true(world.chests.is_empty())
	assert_true(chest.is_queued_for_deletion())
	assert_signal_not_emitted(world, "chest_picked")


func _spawn_regular(carries_chest_roll_seed: int) -> Enemy:
	session.chest_rng.seed = carries_chest_roll_seed
	world._spawn(world.roster.pick_regular(world.rng), false, 200.0)
	return world.enemy_pool.active_nodes().back() as Enemy


func _seed_with_drop(wanted: bool) -> int:
	var probe: RandomNumberGenerator = RandomNumberGenerator.new()
	for seed_value: int in 10000:
		probe.seed = seed_value
		if ChestTable.drops(false, probe.randf()) == wanted:
			return seed_value
	return -1


## Bosses always carry one (S3).
func test_a_boss_shows_a_chest_icon_over_its_head_from_its_spawn() -> void:
	world._spawn(world.roster.boss, true, 200.0)
	var boss: Enemy = world.enemy_pool.active_nodes().back() as Enemy
	assert_true(boss.carries_chest)
	assert_true(boss.chest_marker.visible)
	assert_eq(boss.chest_marker.texture, load(ChestPickup.TEXTURE_PATH))
	var head_y: float = -boss.definition.animation.frame_size.y
	assert_lt(boss.chest_marker.position.y, head_y, "above the head")
	assert_eq(boss.chest_marker.global_scale, Vector2.ONE, "native 16 px, whatever the enemy scale")


func test_the_chest_drop_is_rolled_when_the_enemy_spawns() -> void:
	var with_chest: Enemy = _spawn_regular(_seed_with_drop(true))
	assert_true(with_chest.carries_chest)
	assert_true(with_chest.chest_marker.visible)
	var without_chest: Enemy = _spawn_regular(_seed_with_drop(false))
	assert_false(without_chest.carries_chest)
	assert_false(without_chest.chest_marker.visible)


func test_only_an_enemy_with_the_icon_drops_a_chest() -> void:
	var with_chest: Enemy = _spawn_regular(_seed_with_drop(true))
	var without_chest: Enemy = _spawn_regular(_seed_with_drop(false))
	for index: int in 200:
		session.chest_rng.seed = _seed_with_drop(true)
		without_chest.health.take_damage(DamageResult.new(BigNumber.from_float(1e30), false))
	assert_true(world.chests.is_empty(), "no icon, no chest, whatever the kill roll")
	with_chest.health.take_damage(DamageResult.new(BigNumber.from_float(1e30), false))
	assert_eq(world.chests.size(), 1)
	assert_eq(world.chests[0].position.x, with_chest.position.x)


func test_the_icon_goes_away_when_the_enemy_dies() -> void:
	var with_chest: Enemy = _spawn_regular(_seed_with_drop(true))
	with_chest.health.take_damage(DamageResult.new(BigNumber.from_float(1e30), false))
	assert_false(with_chest.chest_marker.visible, "the chest is on the ground now")
