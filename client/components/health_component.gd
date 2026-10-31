class_name HealthComponent
extends Node
## Health pool for any entity. Dies exactly once; damage and healing after death are ignored
## until setup() revives it.

signal damaged(result: DamageResult)
signal healed(amount: BigNumber)
signal died

var max_health: BigNumber = BigNumber.one()
var current: BigNumber = BigNumber.one()
## Absorbs damage before health until it is used up or expires.
var shield: BigNumber = BigNumber.zero()
var shield_seconds: float = 0.0
## Heal over time: health per second and seconds left.
var regen_per_second: BigNumber = BigNumber.zero()
var regen_seconds: float = 0.0


func _process(delta: float) -> void:
	tick_shield(delta)
	tick_regen(delta)


func setup(new_max_health: BigNumber) -> void:
	max_health = new_max_health
	current = new_max_health
	clear_shield()
	regen_seconds = 0.0


## Replaces any active shield.
func set_shield(amount: BigNumber, seconds: float) -> void:
	shield = amount
	shield_seconds = seconds


func clear_shield() -> void:
	shield = BigNumber.zero()
	shield_seconds = 0.0


func has_shield() -> bool:
	return shield_seconds > 0.0 and not shield.is_zero()


func tick_shield(delta: float) -> void:
	if shield_seconds <= 0.0:
		return
	shield_seconds -= delta
	if shield_seconds <= 1e-6:
		clear_shield()


## Only the part of a hit that gets past the shield emits `damaged`.
func take_damage(result: DamageResult) -> void:
	if is_dead():
		return
	if has_shield():
		if shield.gte(result.amount):
			shield = shield.sub(result.amount)
			return
		result = DamageResult.new(result.amount.sub(shield), result.is_critical)
		clear_shield()
	current = current.sub(result.amount)
	if current.is_negative():
		current = BigNumber.zero()
	damaged.emit(result)
	if current.is_zero():
		died.emit()


func heal(amount: BigNumber) -> void:
	if is_dead():
		return
	current = current.add(amount)
	if current.gt(max_health):
		current = max_health
	healed.emit(amount)


## Heals `amount` spread evenly over `seconds`; replaces any heal still running.
func heal_over_time(amount: BigNumber, seconds: float) -> void:
	regen_per_second = amount.mul_float(1.0 / seconds)
	regen_seconds = seconds


func is_regenerating() -> bool:
	return regen_seconds > 1e-6


func tick_regen(delta: float) -> void:
	if not is_regenerating():
		return
	var step: float = minf(delta, regen_seconds)
	regen_seconds -= step
	heal(regen_per_second.mul_float(step))


func is_dead() -> bool:
	return current.is_zero() or current.is_negative()


## Fraction of health left in [0, 1], safe for values beyond float range.
func get_ratio() -> float:
	if max_health.is_zero():
		return 0.0
	return clampf(current.div(max_health).to_float(), 0.0, 1.0)
