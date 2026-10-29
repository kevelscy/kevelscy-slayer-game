class_name StageBalance
extends Resource
## Designer-tunable per-stage scaling. Every value grows as base * growth^(stage - 1).

@export var base_enemy_health: float = 20.0
@export var enemy_health_growth: float = 1.25
@export var base_enemy_damage: float = 2.0
@export var enemy_damage_growth: float = 1.2
@export var base_gold: float = 5.0
@export var gold_growth: float = 1.2
@export var boss_health_multiplier: float = 8.0
@export var boss_gold_multiplier: float = 10.0


func enemy_health(stage: int) -> BigNumber:
	return _grow(base_enemy_health, enemy_health_growth, stage)


func enemy_damage(stage: int) -> BigNumber:
	return _grow(base_enemy_damage, enemy_damage_growth, stage)


func gold_reward(stage: int) -> BigNumber:
	return _grow(base_gold, gold_growth, stage)


func boss_health(stage: int) -> BigNumber:
	return enemy_health(stage).mul_float(boss_health_multiplier)


func boss_gold_reward(stage: int) -> BigNumber:
	return gold_reward(stage).mul_float(boss_gold_multiplier)


static func _grow(base: float, growth: float, stage: int) -> BigNumber:
	var steps: int = maxi(stage, 1) - 1
	return BigNumber.from_float(base).mul(BigNumber.from_float(growth).pow_f(steps))
