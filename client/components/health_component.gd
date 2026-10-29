class_name HealthComponent
extends Node
## Health pool for any entity. Dies exactly once; damage and healing after death are ignored
## until setup() revives it.

signal damaged(result: DamageResult)
signal healed(amount: BigNumber)
signal died

var max_health: BigNumber = BigNumber.one()
var current: BigNumber = BigNumber.one()


func setup(new_max_health: BigNumber) -> void:
	max_health = new_max_health
	current = new_max_health


func take_damage(result: DamageResult) -> void:
	if is_dead():
		return
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


func is_dead() -> bool:
	return current.is_zero() or current.is_negative()


## Fraction of health left in [0, 1], safe for values beyond float range.
func get_ratio() -> float:
	if max_health.is_zero():
		return 0.0
	return clampf(current.div(max_health).to_float(), 0.0, 1.0)
