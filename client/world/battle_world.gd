class_name BattleWorld
extends Node2D
## The battle lane rendered in the 360x192 SubViewport. Each frame it spawns enemies,
## picks the hero's target, scrolls the world while the hero runs and resolves contact.
## It also resolves skill casts and spirit attacks against the living enemies.

const GROUND_Y: float = 172.0
const SPAWN_X: float = 400.0
const RUN_SPEED: float = 60.0
const ENEMY_SPACING: float = 4.0
## Gap between wave enemies as they spawn: a tight wave packs them, a spread one
## scatters them at random gaps in the spread range.
const WAVE_TIGHT_GAP: float = 20.0
const WAVE_SPREAD_GAP_MIN: float = 36.0
const WAVE_SPREAD_GAP_MAX: float = 80.0
const LAYER_SPEED_FACTORS: Array[float] = [0.1, 0.3, 0.6, 1.0]
const BUFF_TINT: Color = Color(1.4, 0.75, 0.7)
## Gap between an enemy's head and the bottom of its damage number.
const DAMAGE_NUMBER_GAP: float = 2.0
## The hero picks up a chest once it is this close in front of it.
const CHEST_PICKUP_RANGE: float = 8.0
## Wind dash: the hero dashes forward and the camera follows it, so the whole world
## (background, enemies, chests) scrolls this fast extra until the front enemy
## reaches the hero. The hero keeps its lane spot and never comes back.
const DASH_SECONDS: float = 0.3

## Any damage an enemy takes: hero hits, skills and spirit shots.
signal enemy_hit(result: DamageResult)
## The hero ran over a dropped chest; Main spins the roulette for it.
signal chest_picked

@export var roster: EnemyRoster

var session: GameSession
var scheduler: SpawnScheduler = SpawnScheduler.new(
	GameSession.SPAWN_INTERVAL_SECONDS, 4, GameSession.WAVE_CHANCE
)
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var effects: AbilityEffects = AbilityEffects.new()

var _world_speed: float = -1.0
var _dash_left: float = 0.0
var _dash_speed: float = 0.0
var _spirit_orbs: Dictionary[int, SpiritOrb] = {}
## Dropped chests still lying in the lane, oldest first.
var chests: Array[ChestPickup] = []

@onready var hero: Hero = $Hero
@onready var enemy_pool: NodePool = $EnemyPool
@onready var damage_number_pool: NodePool = $DamageNumberPool
@onready var background: Node2D = $Background


func _ready() -> void:
	effects.z_index = 10
	effects.hero = hero
	add_child(effects)


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
	session.talents.leveled_up.connect(
		func(_talent_id: StringName, _level: int) -> void: hero.set_max_health(session.hero_max_health())
	)
	session.ascended.connect(func(_shards: int) -> void: _restart_run())
	session.save_applied.connect(_restart_run)
	session.skills.cast.connect(func(_slot: int, skill: SkillDefinition) -> void: resolve_skill(skill))
	session.spirits.attacked.connect(resolve_spirit_attack)
	session.spirits.unlocked.connect(
		func(_slot: int, _spirit: SpiritDefinition) -> void: _sync_spirit_orbs()
	)
	_sync_spirit_orbs()


func _process(delta: float) -> void:
	if session == null:
		return
	session.progression.tick(delta)
	var enemies: Array[Enemy] = _alive_enemies_by_distance()
	_spawn_if_due(delta, enemies)
	hero.target = null if enemies.is_empty() or hero.health.is_dead() else enemies[0]
	session.tick_combat(delta, hero.target != null)
	hero.sprite.self_modulate = Color.WHITE if session.buffs.is_empty() else BUFF_TINT
	_set_world_speed((RUN_SPEED if hero.is_running() else 0.0) + _dash_step_speed(delta))
	_move_enemies(delta, enemies)
	_move_chests(delta)
	_resolve_enemy_attacks(delta, enemies)


func resolve_skill(skill: SkillDefinition) -> void:
	var enemies: Array[Enemy] = _alive_enemies_by_distance()
	var targets: Array[Enemy] = []
	match skill.effect:
		SkillDefinition.Effect.DAMAGE_ALL, SkillDefinition.Effect.FREEZE_ALL:
			targets = enemies
		SkillDefinition.Effect.DAMAGE_FRONT:
			if not enemies.is_empty():
				targets = [enemies[0]]
		SkillDefinition.Effect.DASH:
			if not enemies.is_empty():
				targets = [enemies[0]]
				_start_dash(enemies[0])
		SkillDefinition.Effect.BUFF:
			session.activate_buff(skill)
		SkillDefinition.Effect.SHIELD:
			hero.health.set_shield(session.shield_amount(skill), skill.duration_seconds)
	var damage: BigNumber = session.skill_damage(skill)
	var positions: Array[Vector2] = []
	for enemy: Enemy in targets:
		# The dash slash lands where the world brings the enemy: at the hero.
		positions.append(enemy.position - Vector2(_dash_speed * _dash_left, 0.0))
		enemy.health.take_damage(DamageResult.new(damage, false))
		if skill.effect == SkillDefinition.Effect.FREEZE_ALL:
			enemy.freeze(skill.duration_seconds)
	effects.play_skill(skill, positions)


func resolve_spirit_attack(slot_index: int, spirit: SpiritDefinition) -> void:
	var enemies: Array[Enemy] = _alive_enemies_by_distance()
	if enemies.is_empty():
		return
	var front: Enemy = enemies[0]
	front.health.take_damage(DamageResult.new(session.spirit_damage(spirit), false))
	var from: Vector2 = _spirit_orbs[slot_index].position if _spirit_orbs.has(slot_index) else hero.position
	effects.play_spirit_shot(from, front.position + Vector2(0.0, -10.0), spirit.color)


func is_dashing() -> bool:
	return _dash_left > 0.0


func _start_dash(front: Enemy) -> void:
	var contact_x: float = hero.position.x + Hero.ATTACK_RANGE * 0.5 + front.body_half_width()
	_dash_speed = maxf(front.position.x - contact_x, 0.0) / DASH_SECONDS
	_dash_left = DASH_SECONDS
	hero.stab()


## Extra world speed the dash adds this frame; the last frame only gets the share of
## the dash left, so the world moves exactly the dash distance.
func _dash_step_speed(delta: float) -> float:
	if _dash_left <= 0.0 or delta <= 0.0:
		return 0.0
	var step: float = minf(delta, _dash_left)
	_dash_left -= step
	return _dash_speed * step / delta


func spirit_orb_count() -> int:
	return _spirit_orbs.size()


## One orb per unlocked spirit, floating behind the hero.
func _sync_spirit_orbs() -> void:
	for index: int in session.spirits.slots.size():
		if _spirit_orbs.has(index) or not session.spirits.slots[index].unlocked:
			continue
		var orb: SpiritOrb = SpiritOrb.new()
		var anchor: Vector2 = hero.position + Vector2(-22.0 - 14.0 * index, -46.0 + 8.0 * (index % 2))
		orb.setup(session.spirits.slots[index].definition, anchor, index * 1.3)
		add_child(orb)
		_spirit_orbs[index] = orb


## After an ascension or a loaded save the run starts on an empty lane with a
## fresh hero and orbs only for the spirits its stage unlocks.
func _restart_run() -> void:
	scheduler.reset()
	for node: Node in enemy_pool.active_nodes().duplicate():
		(node as Enemy).vanish()
	for orb: SpiritOrb in _spirit_orbs.values():
		orb.queue_free()
	_spirit_orbs.clear()
	for chest: ChestPickup in chests:
		chest.queue_free()
	chests.clear()
	_dash_left = 0.0
	hero.restart(session.hero_max_health())
	_sync_spirit_orbs()


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
	match scheduler.tick(delta, regular_alive, boss_alive, rng.randf()):
		SpawnScheduler.Order.REGULAR:
			_spawn(roster.pick_regular(rng), false)
		SpawnScheduler.Order.WAVE:
			_spawn_wave()
		SpawnScheduler.Order.BOSS:
			_spawn(roster.boss, true)


## WAVE_SIZE tougher, richer regular enemies lined up behind the spawn point.
func _spawn_wave() -> void:
	var tight: bool = rng.randf() < 0.5
	var x: float = SPAWN_X
	for index: int in SpawnScheduler.WAVE_SIZE:
		_spawn(roster.pick_regular(rng), false, x, GameSession.WAVE_HEALTH_MULTIPLIER, GameSession.WAVE_GOLD_MULTIPLIER)
		x += WAVE_TIGHT_GAP if tight else rng.randf_range(WAVE_SPREAD_GAP_MIN, WAVE_SPREAD_GAP_MAX)


func _spawn(
	definition: EnemyDefinition, is_boss: bool, x: float = SPAWN_X,
	health_scale: float = 1.0, gold_scale: float = 1.0
) -> void:
	var enemy: Enemy = enemy_pool.acquire() as Enemy
	if not enemy.defeated.is_connected(_on_enemy_defeated):
		enemy.defeated.connect(_on_enemy_defeated)
		enemy.despawn_requested.connect(enemy_pool.release)
		enemy.health.damaged.connect(_show_damage_number.bind(enemy))
	enemy.spawn(
		definition,
		session.enemy_health(is_boss).mul_float(definition.health_multiplier * health_scale),
		session.enemy_damage(is_boss).mul_float(definition.damage_multiplier),
		is_boss,
		Vector2(x, GROUND_Y),
		gold_scale
	)
	enemy.carry_chest(session.chest_drops(is_boss))


## Every hit an enemy takes floats up as a pixel number above its head.
func _show_damage_number(result: DamageResult, enemy: Enemy) -> void:
	enemy_hit.emit(result)
	var number: DamageNumber = damage_number_pool.acquire() as DamageNumber
	if not number.finished.is_connected(damage_number_pool.release):
		number.finished.connect(damage_number_pool.release)
	var head_y: float = enemy.position.y - enemy.definition.animation.frame_size.y * enemy.definition.sprite_scale
	var jitter: float = rng.randf_range(-DamageNumber.MAX_JITTER, DamageNumber.MAX_JITTER)
	number.show_hit(result, Vector2(enemy.position.x + jitter, head_y - DAMAGE_NUMBER_GAP))


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


## Chests scroll with the world; the ones that reach the hero are picked up.
func _move_chests(delta: float) -> void:
	for chest: ChestPickup in chests.duplicate():
		chest.advance(delta, maxf(_world_speed, 0.0))
		if chest.position.x - hero.position.x <= CHEST_PICKUP_RANGE:
			chests.erase(chest)
			chest.queue_free()
			chest_picked.emit()


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
	session.on_enemy_killed(enemy.is_boss, enemy.gold_multiplier)
	if enemy.carries_chest:
		_drop_chest(enemy.position.x)
	EventBus.enemy_killed.emit(enemy.is_boss)


func _drop_chest(x: float) -> void:
	var chest: ChestPickup = ChestPickup.new()
	chest.position = Vector2(x, GROUND_Y)
	add_child(chest)
	chests.append(chest)


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
