class_name Hero
extends Node2D
## The auto-battling hero. It stays at a fixed x; the world scrolls while it runs.

signal died
signal respawned

const ATTACK_RANGE: float = 30.0
## An enemy hit turns the hero a bit red and knocks the sprite back to the left; both
## ease back over HURT_SECONDS. The hero itself keeps its lane spot.
const HURT_SECONDS: float = 0.3
const HURT_KNOCKBACK: float = 6.0
const HURT_TINT: Color = Color(1.0, 0.45, 0.45)

@export var animation_set: AnimationSet

var stats: StatBlock
var target: Enemy
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
## The chest damage boost on the hero's own hits, set by BattleWorld each frame.
var damage_multiplier: float = 1.0

var _hurt_left: float = 0.0
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
	health.damaged.connect(_on_damaged)


func setup(hero_stats: StatBlock, max_health: BigNumber) -> void:
	stats = hero_stats
	health.setup(max_health)
	if not stats.changed.is_connected(_sync_attack_speed):
		stats.changed.connect(_sync_attack_speed)
	_sync_attack_speed()


func _process(delta: float) -> void:
	if _hurt_left <= 0.0:
		return
	_hurt_left = maxf(_hurt_left - delta, 0.0)
	_place_sprite()


func _place_sprite() -> void:
	var offset: float = 0.0
	var hurt_progress: float = 1.0 - _hurt_left / HURT_SECONDS
	if _hurt_left > 0.0:
		offset -= HURT_KNOCKBACK * sin(PI * hurt_progress)
	sprite.position = _sprite_home + Vector2(offset, 0.0)
	modulate = HURT_TINT.lerp(Color.WHITE, hurt_progress) if _hurt_left > 0.0 else Color.WHITE


## Wind dash sword stab; BattleWorld scrolls the world so the hero dashes forward
## while keeping its lane spot.
func stab() -> void:
	sprite.stop()
	sprite.play(&"attack")


func is_hurt() -> bool:
	return _hurt_left > 0.0


func is_running() -> bool:
	return state_machine.current_state != null and state_machine.current_state.name == &"Run"


func has_target_in_range() -> bool:
	if target == null or not target.is_alive:
		return false
	return target.position.x - position.x <= ATTACK_RANGE + target.body_half_width()


func perform_attack() -> void:
	var hit: DamageResult = DamageCalculator.compute(stats, rng)
	if damage_multiplier != 1.0:
		hit.amount = hit.amount.mul_float(damage_multiplier)
	target.health.take_damage(hit)
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
	_hurt_left = 0.0
	_place_sprite()
	state_machine.transition_to(&"Run")


func _sync_attack_speed() -> void:
	auto_attack.attacks_per_second = stats.get_rate(StatBlock.ATTACK_SPEED)


func _on_animation_finished() -> void:
	if sprite.animation == &"attack":
		sprite.play(&"idle")


func _on_damaged(_result: DamageResult) -> void:
	if health.is_dead():
		return
	_hurt_left = HURT_SECONDS
	_place_sprite()


func _on_died() -> void:
	_hurt_left = 0.0
	_place_sprite()
	target = null
	state_machine.transition_to(&"Dead")
	died.emit()
