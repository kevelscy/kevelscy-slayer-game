extends GutTest

const EPSILON: float = 1e-9


func _assert_big(actual: BigNumber, mantissa: float, exponent: int) -> void:
	assert_almost_eq(actual.mantissa, mantissa, EPSILON, "mantissa of %s" % actual.serialize())
	assert_eq(actual.exponent, exponent, "exponent of %s" % actual.serialize())


# --- construction / normalization ---

func test_from_float_normalizes_to_scientific_form() -> void:
	_assert_big(BigNumber.from_float(1234.0), 1.234, 3)


func test_from_float_handles_exact_powers_of_ten() -> void:
	_assert_big(BigNumber.from_float(1000.0), 1.0, 3)
	_assert_big(BigNumber.from_float(1e15), 1.0, 15)


func test_from_float_handles_fractions() -> void:
	_assert_big(BigNumber.from_float(0.05), 5.0, -2)


func test_from_float_zero_is_canonical_zero() -> void:
	var zero: BigNumber = BigNumber.from_float(0.0)
	assert_true(zero.is_zero())
	_assert_big(zero, 0.0, 0)


func test_from_float_keeps_sign() -> void:
	_assert_big(BigNumber.from_float(-500.0), -5.0, 2)
	assert_true(BigNumber.from_float(-500.0).is_negative())


func test_of_normalizes_unnormalized_mantissa() -> void:
	_assert_big(BigNumber.of(123.0, 10), 1.23, 12)
	_assert_big(BigNumber.of(0.5, 10), 5.0, 9)


func test_operations_do_not_mutate_operands() -> void:
	var a: BigNumber = BigNumber.from_float(2.0)
	var b: BigNumber = BigNumber.from_float(3.0)
	a.add(b)
	a.mul(b)
	_assert_big(a, 2.0, 0)
	_assert_big(b, 3.0, 0)


# --- arithmetic ---

func test_add_same_exponent() -> void:
	_assert_big(BigNumber.from_float(5.0).add(BigNumber.from_float(7.0)), 1.2, 1)


func test_add_different_exponents() -> void:
	_assert_big(BigNumber.of(1.0, 5).add(BigNumber.of(5.0, 3)), 1.05, 5)


func test_add_beyond_float_range() -> void:
	_assert_big(BigNumber.of(5.0, 400).add(BigNumber.of(5.0, 400)), 1.0, 401)


func test_add_negligible_operand_returns_larger_value() -> void:
	_assert_big(BigNumber.of(1.0, 100).add(BigNumber.of(1.0, 50)), 1.0, 100)
	_assert_big(BigNumber.of(1.0, 50).add(BigNumber.of(1.0, 100)), 1.0, 100)


func test_add_zero_is_identity() -> void:
	_assert_big(BigNumber.of(3.0, 500).add(BigNumber.zero()), 3.0, 500)
	_assert_big(BigNumber.zero().add(BigNumber.of(3.0, 500)), 3.0, 500)


func test_sub_to_zero() -> void:
	assert_true(BigNumber.of(4.2, 300).sub(BigNumber.of(4.2, 300)).is_zero())


func test_sub_to_negative() -> void:
	var result: BigNumber = BigNumber.from_float(100.0).sub(BigNumber.from_float(250.0))
	_assert_big(result, -1.5, 2)


func test_mul_beyond_float_range() -> void:
	_assert_big(BigNumber.of(2.0, 200).mul(BigNumber.of(3.0, 200)), 6.0, 400)


func test_mul_renormalizes() -> void:
	_assert_big(BigNumber.from_float(5.0).mul(BigNumber.from_float(4.0)), 2.0, 1)


func test_mul_by_zero_is_zero() -> void:
	assert_true(BigNumber.of(9.0, 900).mul(BigNumber.zero()).is_zero())


func test_mul_float() -> void:
	_assert_big(BigNumber.of(2.0, 500).mul_float(1.5), 3.0, 500)
	_assert_big(BigNumber.of(8.0, 500).mul_float(2.5), 2.0, 501)


func test_div() -> void:
	_assert_big(BigNumber.of(6.0, 400).div(BigNumber.of(3.0, 200)), 2.0, 200)
	_assert_big(BigNumber.from_float(1.0).div(BigNumber.from_float(4.0)), 2.5, -1)


func test_pow_large_exponent() -> void:
	_assert_big(BigNumber.from_float(10.0).pow_f(500.0), 1.0, 500)


func test_pow_matches_log_identity_for_growth_curves() -> void:
	# 1.15^1000 = 10^(1000 * log10(1.15))
	var expected_log10: float = 1000.0 * log(1.15) / log(10.0)
	var result: BigNumber = BigNumber.from_float(1.15).pow_f(1000.0)
	assert_eq(result.exponent, int(floor(expected_log10)))
	assert_almost_eq(result.log10(), expected_log10, 1e-6)


func test_pow_zero_is_one() -> void:
	_assert_big(BigNumber.of(7.0, 77).pow_f(0.0), 1.0, 0)


# --- comparison ---

func test_compare_by_exponent_then_mantissa() -> void:
	assert_true(BigNumber.of(1.0, 400).gt(BigNumber.of(9.9, 399)))
	assert_true(BigNumber.of(2.0, 10).gt(BigNumber.of(1.5, 10)))
	assert_true(BigNumber.of(1.5, 10).lt(BigNumber.of(2.0, 10)))


func test_compare_handles_signs_and_zero() -> void:
	assert_true(BigNumber.from_float(-1e300).lt(BigNumber.zero()))
	assert_true(BigNumber.zero().lt(BigNumber.of(1.0, -50)))
	# A more negative exponent is closer to zero, so larger when negative.
	assert_true(BigNumber.of(-1.0, 2).lt(BigNumber.of(-1.0, 1)))


func test_gte_and_lte_include_equality() -> void:
	var a: BigNumber = BigNumber.of(3.0, 30)
	assert_true(a.gte(BigNumber.of(3.0, 30)))
	assert_true(a.lte(BigNumber.of(3.0, 30)))
	assert_eq(a.compare(BigNumber.of(3.0, 30)), 0)


# --- conversion / persistence ---

func test_to_float_within_range() -> void:
	assert_almost_eq(BigNumber.from_float(1234.5).to_float(), 1234.5, 1e-9)


func test_to_float_out_of_range_is_inf() -> void:
	assert_eq(BigNumber.of(1.0, 400).to_float(), INF)
	assert_eq(BigNumber.of(-1.0, 400).to_float(), -INF)


func test_serialize_roundtrip_beyond_float_range() -> void:
	var original: BigNumber = BigNumber.of(1.5, 1234)
	var text: String = original.serialize()
	assert_eq(text, "1.5e1234")
	_assert_big(BigNumber.parse(text), 1.5, 1234)


func test_parse_plain_number() -> void:
	_assert_big(BigNumber.parse("2500"), 2.5, 3)
