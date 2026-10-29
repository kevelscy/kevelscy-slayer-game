class_name DamageResult
extends RefCounted
## Outcome of one hit: how much damage and whether it was a critical strike.

var amount: BigNumber
var is_critical: bool


func _init(damage: BigNumber, critical: bool) -> void:
	amount = damage
	is_critical = critical
