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
