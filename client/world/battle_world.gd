class_name BattleWorld
extends Node2D
## The battle lane rendered in the 360x192 SubViewport. Each frame it spawns enemies,
## picks the hero's target, scrolls the world while the hero runs and resolves contact.

const GROUND_Y: float = 172.0
const SPAWN_X: float = 400.0
const RUN_SPEED: float = 60.0
const ENEMY_SPACING: float = 4.0
const LAYER_SPEED_FACTORS: Array[float] = [0.1, 0.3, 0.6, 1.0]

@export var roster: EnemyRoster

var session: GameSession
var scheduler: SpawnScheduler = SpawnScheduler.new(1.2, 4)
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var _world_speed: float = -1.0

@onready var hero: Hero = $Hero
@onready var enemy_pool: NodePool = $EnemyPool
@onready var background: Node2D = $Background


func start(game_session: GameSession) -> void:
	session = game_session
	rng.randomize()
	hero.setup(session.hero_stats, session.hero_max_health())
	hero.died.connect(_on_hero_died)
	session.progression.boss_started.connect(func(_seconds: float) -> void: scheduler.queue_boss())
	session.progression.boss_failed.connect(_on_boss_failed)
	session.health_track.leveled_up.connect(
		func(_level: int) -> void: hero.set_max_health(session.hero_max_health())
	)


func _process(delta: float) -> void:
	if session == null:
		return
	session.progression.tick(delta)
	var enemies: Array[Enemy] = _alive_enemies_by_distance()
	_spawn_if_due(delta, enemies)
	hero.target = null if enemies.is_empty() or hero.health.is_dead() else enemies[0]
	_set_world_speed(RUN_SPEED if hero.is_running() else 0.0)
	_move_enemies(delta, enemies)
	_resolve_enemy_attacks(delta, enemies)


func _alive_enemies_by_distance() -> Array[Enemy]:
	var enemies: Array[Enemy] = []
	for node: Node in enemy_pool.active_nodes():
		var enemy: Enemy = node as Enemy
		if enemy.is_alive:
			enemies.append(enemy)
	enemies.sort_custom(func(a: Enemy, b: Enemy) -> bool: return a.position.x < b.position.x)
	return enemies


func _spawn_if_due(delta: float, enemies: Array[Enemy]) -> void:
	var boss_alive: bool = enemies.any(func(enemy: Enemy) -> bool: return enemy.is_boss)
	var regular_alive: int = enemies.size() - (1 if boss_alive else 0)
	match scheduler.tick(delta, regular_alive, boss_alive):
		SpawnScheduler.Order.REGULAR:
			_spawn(roster.pick_regular(rng), false)
		SpawnScheduler.Order.BOSS:
			_spawn(roster.boss, true)


func _spawn(definition: EnemyDefinition, is_boss: bool) -> void:
	var enemy: Enemy = enemy_pool.acquire() as Enemy
	if not enemy.defeated.is_connected(_on_enemy_defeated):
		enemy.defeated.connect(_on_enemy_defeated)
		enemy.despawn_requested.connect(enemy_pool.release)
	enemy.spawn(
		definition,
		session.enemy_health(is_boss).mul_float(definition.health_multiplier),
		session.enemy_damage(is_boss).mul_float(definition.damage_multiplier),
		is_boss,
		Vector2(SPAWN_X, GROUND_Y)
	)


## Enemies queue up in front of the hero: the first stops at contact range, the
## rest stop behind the one ahead.
func _move_enemies(delta: float, enemies: Array[Enemy]) -> void:
	var limit: float = hero.position.x + Hero.ATTACK_RANGE * 0.5
	for enemy: Enemy in enemies:
		var min_x: float = limit + enemy.body_half_width()
		enemy.advance(delta, _world_speed, min_x)
		limit = enemy.position.x + enemy.body_half_width() + ENEMY_SPACING
	for node: Node in enemy_pool.active_nodes():
		var fading: Enemy = node as Enemy
		if not fading.is_alive:
			fading.advance(delta, _world_speed, -INF)


func _resolve_enemy_attacks(delta: float, enemies: Array[Enemy]) -> void:
	if enemies.is_empty() or hero.health.is_dead():
		return
	var front: Enemy = enemies[0]
	var in_contact: bool = front.position.x - hero.position.x <= Hero.ATTACK_RANGE + front.body_half_width()
	if front.try_attack(delta, in_contact):
		hero.health.take_damage(DamageResult.new(front.damage, false))


func _set_world_speed(speed: float) -> void:
	if is_equal_approx(speed, _world_speed):
		return
	_world_speed = speed
	var layers: Array[Node] = background.get_children()
	for index: int in layers.size():
		var layer: Parallax2D = layers[index] as Parallax2D
		layer.autoscroll = Vector2(-speed * LAYER_SPEED_FACTORS[mini(index, LAYER_SPEED_FACTORS.size() - 1)], 0.0)


func _on_enemy_defeated(enemy: Enemy) -> void:
	session.on_enemy_killed(enemy.is_boss)
	EventBus.enemy_killed.emit(enemy.is_boss)


func _on_boss_failed() -> void:
	scheduler.cancel_boss()
	for node: Node in enemy_pool.active_nodes().duplicate():
		var enemy: Enemy = node as Enemy
		if enemy.is_boss and enemy.is_alive:
			enemy.vanish()


func _on_hero_died() -> void:
	session.on_hero_died()
	for node: Node in enemy_pool.active_nodes().duplicate():
		(node as Enemy).vanish()
	EventBus.hero_died.emit()
