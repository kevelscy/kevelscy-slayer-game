class_name Hero
extends Node2D
## The auto-battling hero. It stays at a fixed x; the world scrolls while it runs.

signal died
signal respawned

const ATTACK_RANGE: float = 30.0
## Wind dash: the sprite lunges to the enemy and back; the hero itself never leaves
## its lane spot, so targeting and enemy contact stay the same.
const DASH_SECONDS: float = 0.3
## Stops the stab this far short of the enemy center, sword tip on its body.
const DASH_STOP_SHORT: float = 14.0

@export var animation_set: AnimationSet

var stats: StatBlock
var target: Enemy
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var _dash_left: float = 0.0
var _dash_reach: float = 0.0
var _sprite_home: Vector2

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var health: HealthComponent = $Health
@onready var auto_attack: AutoAttackComponent = $AutoAttack
@onready var state_machine: StateMachine = $StateMachine


func _ready() -> void:
	_sprite_home = sprite.position
	rng.randomize()
	sprite.sprite_frames = SpriteFramesBuilder.build(animation_set.sheets)
	sprite.animation_finished.connect(_on_animation_finished)
	health.died.connect(_on_died)


func setup(hero_stats: StatBlock, max_health: BigNumber) -> void:
	stats = hero_stats
	health.setup(max_health)
	if not stats.changed.is_connected(_sync_attack_speed):
		stats.changed.connect(_sync_attack_speed)
	_sync_attack_speed()


func _process(delta: float) -> void:
	if _dash_left <= 0.0:
		return
	_dash_left = maxf(_dash_left - delta, 0.0)
	var progress: float = 1.0 - _dash_left / DASH_SECONDS
	var offset: float = _dash_reach * sin(PI * progress) if _dash_left > 0.0 else 0.0
	sprite.position = _sprite_home + Vector2(offset, 0.0)


## Lunges the sprite to `target_x` (world x) with a sword stab, then back.
func dash_to(target_x: float) -> void:
	_dash_reach = maxf(target_x - position.x - DASH_STOP_SHORT, 0.0)
	_dash_left = DASH_SECONDS
	sprite.stop()
	sprite.play(&"attack")


func is_dashing() -> bool:
	return _dash_left > 0.0


func is_running() -> bool:
	return state_machine.current_state != null and state_machine.current_state.name == &"Run"


func has_target_in_range() -> bool:
	if target == null or not target.is_alive:
		return false
	return target.position.x - position.x <= ATTACK_RANGE + target.body_half_width()


func perform_attack() -> void:
	target.health.take_damage(DamageCalculator.compute(stats, rng))
	sprite.stop()
	sprite.play(&"attack")


## Raises max health; a living hero gains the difference immediately.
func set_max_health(new_max_health: BigNumber) -> void:
	if not health.is_dead():
		health.current = health.current.add(new_max_health.sub(health.max_health))
	health.max_health = new_max_health


func revive() -> void:
	health.setup(health.max_health)
	respawned.emit()


## Starts a new run: full health at `new_max_health`, alive and running even if the
## hero was dead, so the Dead state never revives it a second time.
func restart(new_max_health: BigNumber) -> void:
	health.max_health = new_max_health
	revive()
	state_machine.transition_to(&"Run")


func _sync_attack_speed() -> void:
	auto_attack.attacks_per_second = stats.get_rate(StatBlock.ATTACK_SPEED)


func _on_animation_finished() -> void:
	if sprite.animation == &"attack":
		sprite.play(&"idle")


func _on_died() -> void:
	target = null
	state_machine.transition_to(&"Dead")
	died.emit()
