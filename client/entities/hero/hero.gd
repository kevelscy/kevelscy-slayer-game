class_name Hero
extends Node2D
## The auto-battling hero. It stays at a fixed x; the world scrolls while it runs.

signal died
signal respawned

const ATTACK_RANGE: float = 30.0

@export var animation_set: AnimationSet

var stats: StatBlock
var target: Enemy
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var health: HealthComponent = $Health
@onready var auto_attack: AutoAttackComponent = $AutoAttack
@onready var state_machine: StateMachine = $StateMachine


func _ready() -> void:
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


func _sync_attack_speed() -> void:
	auto_attack.attacks_per_second = stats.get_rate(StatBlock.ATTACK_SPEED)


func _on_animation_finished() -> void:
	if sprite.animation == &"attack":
		sprite.play(&"idle")


func _on_died() -> void:
	target = null
	state_machine.transition_to(&"Dead")
	died.emit()
