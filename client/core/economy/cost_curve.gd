class_name CostCurve
extends RefCounted
## Exponential upgrade cost: cost(level) = base_cost * growth^level.

var base_cost: BigNumber
var growth: float


func _init(base: BigNumber, growth_rate: float) -> void:
	base_cost = base
	growth = growth_rate


func cost_at(level: int) -> BigNumber:
	return base_cost.mul(BigNumber.from_float(growth).pow_f(level))


## Total cost of buying `count` levels starting at `from_level` (geometric series).
func bulk_cost(from_level: int, count: int) -> BigNumber:
	if count <= 0:
		return BigNumber.zero()
	if is_equal_approx(growth, 1.0):
		return base_cost.mul_float(count)
	# sum_{i=0}^{n-1} base * g^(L+i) = base * g^L * (g^n - 1) / (g - 1)
	var growth_power: BigNumber = BigNumber.from_float(growth).pow_f(count)
	return cost_at(from_level).mul(growth_power.sub(BigNumber.one())).div(
		BigNumber.from_float(growth - 1.0)
	)
