class_name SkillSlot
extends RefCounted
## Cooldown and level of one skill bar slot. Level 0 means not bought yet; reaching
## the skill's unlock stage lets the player buy it, and once bought it casts at any
## stage.

var definition: SkillDefinition
var cooldown_remaining: float = 0.0
var level: int = 0


func _init(skill: SkillDefinition) -> void:
	definition = skill


func is_owned() -> bool:
	return level > 0


## The first level needs the unlock stage; later levels can be bought at any stage.
func can_buy(stage: int) -> bool:
	return is_owned() or stage >= definition.unlock_stage


## Gold price of the next level.
func cost() -> BigNumber:
	return CostCurve.new(BigNumber.from_float(definition.base_cost), definition.cost_growth).cost_at(level)


func is_ready() -> bool:
	return is_owned() and cooldown_remaining <= 0.0


func start_cooldown() -> void:
	cooldown_remaining = definition.cooldown_seconds


func tick(delta: float) -> void:
	cooldown_remaining = maxf(cooldown_remaining - delta, 0.0)


## 1 right after a cast, 0 when ready.
func cooldown_ratio() -> float:
	return clampf(cooldown_remaining / definition.cooldown_seconds, 0.0, 1.0)
