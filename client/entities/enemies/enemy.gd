class_name Enemy
extends Node2D
## A pooled enemy configured from an EnemyDefinition. BattleWorld drives its movement
## and attacks; the enemy owns its health, visuals and death fade.

signal defeated(enemy: Enemy)
signal despawn_requested(enemy: Enemy)

const DEATH_FADE_SECONDS: float = 0.35
const HIT_FLASH_SECONDS: float = 0.08

static var _frames_cache: Dictionary[StringName, SpriteFrames] = {}

var definition: EnemyDefinition
var is_boss: bool = false
var is_alive: bool = false
var damage: BigNumber = BigNumber.zero()

var _fade_tween: Tween

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var health: HealthComponent = $Health
@onready var auto_attack: AutoAttackComponent = $AutoAttack


func _ready() -> void:
	health.died.connect(_on_died)
	health.damaged.connect(_on_damaged)


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
	auto_attack.attacks_per_second = definition.attacks_per_second
	health.setup(max_health)
	sprite.sprite_frames = _frames_for(definition)
	sprite.offset = Vector2(0.0, -definition.animation.frame_size.y * 0.5)
	sprite.play(definition.animation.animation_name)


func body_half_width() -> float:
	return definition.animation.frame_size.x * definition.sprite_scale * 0.3


## Moves left with the world, never past min_x. Dead (fading) enemies only scroll.
func advance(delta: float, world_speed: float, min_x: float) -> void:
	if not is_alive:
		position.x -= world_speed * delta
		return
	position.x = maxf(position.x - (definition.move_speed + world_speed) * delta, min_x)


func try_attack(delta: float, target_in_range: bool) -> bool:
	return is_alive and auto_attack.tick(delta, target_in_range)


## Removes the enemy without a kill (boss timeout, hero death).
func vanish() -> void:
	is_alive = false
	despawn_requested.emit(self)


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
