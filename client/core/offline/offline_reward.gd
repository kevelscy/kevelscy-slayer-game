class_name OfflineReward
extends RefCounted
## Rewards granted for time away, with the validated elapsed time they were based on.

var elapsed_seconds: int
var amounts: Dictionary[StringName, BigNumber]


func _init(seconds: int, reward_amounts: Dictionary[StringName, BigNumber]) -> void:
	elapsed_seconds = seconds
	amounts = reward_amounts


func is_empty() -> bool:
	if elapsed_seconds <= 0:
		return true
	for amount: BigNumber in amounts.values():
		if not amount.is_zero():
			return false
	return true
