extends GutTest


func test_values_below_one_thousand_show_whole_units() -> void:
	assert_eq(NumberFormat.format(BigNumber.zero()), "0")
	assert_eq(NumberFormat.format(BigNumber.from_float(7.0)), "7")
	assert_eq(NumberFormat.format(BigNumber.from_float(999.9)), "999")


func test_short_suffixes_keep_three_significant_digits() -> void:
	assert_eq(NumberFormat.format(BigNumber.from_float(1234.0)), "1.23K")
	assert_eq(NumberFormat.format(BigNumber.from_float(12345.0)), "12.3K")
	assert_eq(NumberFormat.format(BigNumber.from_float(123456.0)), "123K")
	assert_eq(NumberFormat.format(BigNumber.of(1.0, 6)), "1.00M")
	assert_eq(NumberFormat.format(BigNumber.of(1.0, 9)), "1.00B")
	assert_eq(NumberFormat.format(BigNumber.of(1.0, 12)), "1.00T")


func test_truncates_instead_of_rounding_up() -> void:
	assert_eq(NumberFormat.format(BigNumber.from_float(999999.0)), "999K")
	assert_eq(NumberFormat.format(BigNumber.from_float(1999.0)), "1.99K")


func test_letter_suffixes_after_trillions() -> void:
	assert_eq(NumberFormat.format(BigNumber.of(1.0, 15)), "1.00aa")
	assert_eq(NumberFormat.format(BigNumber.of(1.0, 18)), "1.00ab")
	# Letter index n = exponent / 3 - 5; suffix = alphabet[n / 26] + alphabet[n % 26].
	assert_eq(NumberFormat.format(BigNumber.of(1.0, 90)), "1.00az")
	assert_eq(NumberFormat.format(BigNumber.of(1.0, 93)), "1.00ba")
	assert_eq(NumberFormat.format(BigNumber.of(4.56, 94)), "45.6ba")


func test_last_letter_suffix_then_scientific() -> void:
	# "zz" is letter index 675 → exponent 3 * (5 + 675) = 2040.
	assert_eq(NumberFormat.format(BigNumber.of(1.0, 2040)), "1.00zz")
	assert_eq(NumberFormat.format(BigNumber.of(1.23, 2043)), "1.23e2043")


func test_negative_values_keep_sign() -> void:
	assert_eq(NumberFormat.format(BigNumber.from_float(-1234.0)), "-1.23K")
	assert_eq(NumberFormat.format(BigNumber.from_float(-5.0)), "-5")


func test_fractions_below_one_show_zero() -> void:
	assert_eq(NumberFormat.format(BigNumber.from_float(0.75)), "0")
