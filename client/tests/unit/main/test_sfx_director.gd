extends GutTest
## Main plays a sound effect on each game event through its SfxPlayer.

const MAIN: PackedScene = preload("res://main/main.tscn")
const ABILITIES: AbilityCatalog = preload("res://data/content/abilities/ability_catalog.tres")

var main: Main
var clock_msec: int = 0


func before_each() -> void:
	main = MAIN.instantiate()
	add_child_autofree(main)
	# Each event happens a second after the previous one, outside every minimum interval.
	main.sfx.clock = func() -> int:
		clock_msec += 1000
		return clock_msec
	watch_signals(main.sfx)


func _played() -> Array[StringName]:
	var ids: Array[StringName] = []
	for index: int in get_signal_emit_count(main.sfx, "played"):
		ids.append(get_signal_parameters(main.sfx, "played", index)[0] as StringName)
	return ids


func test_main_loads_every_catalog_sound() -> void:
	for id: StringName in SfxPlayer.SOUNDS:
		assert_not_null(main.sfx.stream_player(id), "%s is loaded" % id)


func test_enemy_hit_plays_hit_and_a_critical_hit_plays_crit() -> void:
	main.battle_world.enemy_hit.emit(DamageResult.new(BigNumber.one(), false))
	main.battle_world.enemy_hit.emit(DamageResult.new(BigNumber.one(), true))
	assert_eq(_played(), [&"hit", &"crit"] as Array[StringName])


func test_enemy_killed_plays_coin() -> void:
	EventBus.enemy_killed.emit(false)
	assert_eq(_played(), [&"coin"] as Array[StringName])


func test_spirit_attack_plays_spirit() -> void:
	GameState.session.spirits.attacked.emit(0, ABILITIES.spirits[0])
	assert_eq(_played(), [&"spirit"] as Array[StringName])


func test_battle_world_signals_every_damage_an_enemy_takes() -> void:
	var world: BattleWorld = main.battle_world
	world._spawn(world.roster.regular_enemies[0], false)
	var enemy: Enemy = world.enemy_pool.active_nodes().back() as Enemy
	watch_signals(world)
	enemy.health.take_damage(DamageResult.new(BigNumber.one(), true))
	assert_signal_emit_count(world, "enemy_hit", 1)
	assert_true((get_signal_parameters(world, "enemy_hit")[0] as DamageResult).is_critical)
