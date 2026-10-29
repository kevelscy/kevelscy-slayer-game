class_name Enemy
extends Node2D
## A pooled enemy configured from an EnemyDefinition. BattleWorld drives its movement
## and attacks; the enemy owns its health, visuals and death fade.

signal defeated(enemy: Enemy)
signal despawn_requested(enemy: Enemy)

const DEATH_FADE_SECONDS: float = 0.35
const HIT_FLASH_SECONDS: float = 0.08
const FROZEN_TINT: Color = Color(0.55, 0.85, 1.6)

static var _frames_cache: Dictionary[StringName, SpriteFrames] = {}

var definition: EnemyDefinition
var is_boss: bool = false
var is_alive: bool = false
var damage: BigNumber = BigNumber.zero()
## While above zero the enemy neither walks nor attacks.
var frozen_seconds: float = 0.0

var _fade_tween: Tween

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var health: HealthComponent = $Health
@onready var auto_attack: AutoAttackComponent = $AutoAttack


func _ready() -> void:
	health.died.connect(_on_died)
	health.damaged.connect(_on_damaged)


func _process(delta: float) -> void:
	tick_freeze(delta)


func spawn(
	enemy_definition: EnemyDefinition, max_health: BigNumber, attack_damage: BigNumber,
	boss: bool, ground_position: Vector2
) -> void:
	definition = enemy_definition
	is_boss = boss
	is_alive = true
	damage = attack_damage
	position = ground_position - Vector2(0.0, definition.hover_height)
	scale = Vector2.ONE * definition.sprite_scale
	modulate = definition.tint
	if _fade_tween != null:
		_fade_tween.kill()
	frozen_seconds = 0.0
	sprite.self_modulate = Color.WHITE
	auto_attack.attacks_per_second = definition.attacks_per_second
	health.setup(max_health)
	sprite.sprite_frames = _frames_for(definition)
	sprite.offset = Vector2(0.0, -definition.animation.frame_size.y * 0.5)
	sprite.play(definition.animation.animation_name)


func body_half_width() -> float:
	return definition.animation.frame_size.x * definition.sprite_scale * 0.3


## Moves left with the world, never past min_x. Dead (fading) enemies only scroll;
## frozen ones scroll too but still stop at min_x.
func advance(delta: float, world_speed: float, min_x: float) -> void:
	if not is_alive:
		position.x -= world_speed * delta
		return
	var speed: float = world_speed if is_frozen() else definition.move_speed + world_speed
	position.x = maxf(position.x - speed * delta, min_x)


func try_attack(delta: float, target_in_range: bool) -> bool:
	return is_alive and not is_frozen() and auto_attack.tick(delta, target_in_range)


## A longer freeze extends a shorter one; it never shortens it.
func freeze(seconds: float) -> void:
	if not is_alive:
		return
	frozen_seconds = maxf(frozen_seconds, seconds)
	sprite.self_modulate = FROZEN_TINT
	sprite.pause()


func is_frozen() -> bool:
	return frozen_seconds > 0.0


func tick_freeze(delta: float) -> void:
	if not is_frozen():
		return
	frozen_seconds -= delta
	if frozen_seconds <= 1e-6:
		_thaw()


## Removes the enemy without a kill (boss timeout, hero death).
func vanish() -> void:
	is_alive = false
	despawn_requested.emit(self)


func _thaw() -> void:
	frozen_seconds = 0.0
	sprite.self_modulate = Color.WHITE
	sprite.play(definition.animation.animation_name)


func _on_damaged(_result: DamageResult) -> void:
	if not is_alive:
		return
	modulate = Color(2.0, 2.0, 2.0)
	create_tween().tween_property(self, "modulate", definition.tint, HIT_FLASH_SECONDS)


func _on_died() -> void:
	is_alive = false
	defeated.emit(self)
	_fade_tween = create_tween()
	_fade_tween.tween_property(self, "modulate:a", 0.0, DEATH_FADE_SECONDS)
	_fade_tween.tween_callback(func() -> void: despawn_requested.emit(self))


static func _frames_for(enemy_definition: EnemyDefinition) -> SpriteFrames:
	if not _frames_cache.has(enemy_definition.id):
		var sheets: Array[AnimationSheet] = [enemy_definition.animation]
		_frames_cache[enemy_definition.id] = SpriteFramesBuilder.build(sheets)
	return _frames_cache[enemy_definition.id]
