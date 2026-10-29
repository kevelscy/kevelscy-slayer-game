extends GutTest


func test_level_zero_costs_base() -> void:
	var curve: CostCurve = CostCurve.new(BigNumber.from_float(10.0), 1.15)
	assert_almost_eq(curve.cost_at(0).to_float(), 10.0, 1e-9)


func test_each_level_multiplies_by_growth() -> void:
	var curve: CostCurve = CostCurve.new(BigNumber.from_float(10.0), 1.15)
	assert_almost_eq(curve.cost_at(1).to_float(), 11.5, 1e-9)
	assert_almost_eq(curve.cost_at(2).to_float(), 13.225, 1e-9)


func test_high_levels_exceed_float_range() -> void:
	var curve: CostCurve = CostCurve.new(BigNumber.from_float(10.0), 1.15)
	var expected_log10: float = 1.0 + 6000.0 * log(1.15) / log(10.0)
	assert_almost_eq(curve.cost_at(6000).log10(), expected_log10, 1e-6)


func test_bulk_cost_equals_sum_of_single_costs() -> void:
	var curve: CostCurve = CostCurve.new(BigNumber.from_float(10.0), 1.15)
	var expected: BigNumber = curve.cost_at(5).add(curve.cost_at(6)).add(curve.cost_at(7))
	assert_almost_eq(curve.bulk_cost(5, 3).to_float(), expected.to_float(), 1e-6)


func test_bulk_cost_with_flat_growth() -> void:
	var curve: CostCurve = CostCurve.new(BigNumber.from_float(10.0), 1.0)
	assert_almost_eq(curve.bulk_cost(3, 4).to_float(), 40.0, 1e-9)


func test_bulk_cost_of_nothing_is_zero() -> void:
	var curve: CostCurve = CostCurve.new(BigNumber.from_float(10.0), 1.15)
	assert_true(curve.bulk_cost(3, 0).is_zero())
