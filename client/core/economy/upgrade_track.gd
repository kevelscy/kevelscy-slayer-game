class_name UpgradeTrack
extends RefCounted
## A purchasable stat upgrade: value = value_base * value_growth^level, priced by a CostCurve.

signal leveled_up(level: int)

var level: int = 0
var value_base: BigNumber
var value_growth: float
var cost: CostCurve


func _init(base_value: BigNumber, growth_per_level: float, cost_curve: CostCurve) -> void:
	value_base = base_value
	value_growth = growth_per_level
	cost = cost_curve


func value() -> BigNumber:
	return value_base.mul(BigNumber.from_float(value_growth).pow_f(level))


func next_cost() -> BigNumber:
	return cost.cost_at(level)


func try_buy(wallet: CurrencyWallet, currency: StringName) -> bool:
	if not wallet.try_spend(currency, next_cost()):
		return false
	level += 1
	leveled_up.emit(level)
	return true


func set_level(saved_level: int) -> void:
	level = maxi(saved_level, 0)
