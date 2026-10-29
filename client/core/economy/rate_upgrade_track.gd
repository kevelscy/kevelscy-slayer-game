class_name RateUpgradeTrack
extends UpgradeTrack
## A rate stat upgrade (crit chance, crit damage, attack speed): the value grows
## by a fixed step per level instead of exponentially, usually up to a cap.

var base_rate: float
var rate_step: float


func _init(base: float, step_per_level: float, level_cap: int, cost_curve: CostCurve) -> void:
	super(BigNumber.zero(), 1.0, cost_curve)
	base_rate = base
	rate_step = step_per_level
	max_level = level_cap


func rate() -> float:
	return base_rate + rate_step * level
