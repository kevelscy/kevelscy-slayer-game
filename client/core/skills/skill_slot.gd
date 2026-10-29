class_name SkillSlot
extends RefCounted
## Cooldown state of one skill bar slot.

var definition: SkillDefinition
var cooldown_remaining: float = 0.0


func _init(skill: SkillDefinition) -> void:
	definition = skill


func is_unlocked(stage: int) -> bool:
	return stage >= definition.unlock_stage


func is_ready(stage: int) -> bool:
	return is_unlocked(stage) and cooldown_remaining <= 0.0


func start_cooldown() -> void:
	cooldown_remaining = definition.cooldown_seconds


func tick(delta: float) -> void:
	cooldown_remaining = maxf(cooldown_remaining - delta, 0.0)


## 1 right after a cast, 0 when ready.
func cooldown_ratio() -> float:
	return clampf(cooldown_remaining / definition.cooldown_seconds, 0.0, 1.0)
