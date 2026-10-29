class_name AutoAttackComponent
extends Node
## Attack cadence. The cooldown recovers all the time; an attack fires when it is
## ready and a target is in range. At most one attack per tick.

signal attack_triggered

const MIN_ATTACKS_PER_SECOND: float = 0.1
const READY_EPSILON: float = 1e-6

@export var attacks_per_second: float = 1.0

var _cooldown: float = 0.0


## Advances the cooldown; returns true when an attack fires this tick.
func tick(delta: float, has_target: bool) -> bool:
	_cooldown = maxf(_cooldown - delta, 0.0)
	if not has_target or _cooldown > READY_EPSILON:
		return false
	_cooldown = 1.0 / maxf(attacks_per_second, MIN_ATTACKS_PER_SECOND)
	attack_triggered.emit()
	return true
