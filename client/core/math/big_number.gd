class_name BigNumber
extends RefCounted
## Immutable arbitrary-magnitude number for the idle economy: mantissa * 10^exponent.
##
## Normalized form keeps 1 <= |mantissa| < 10 (or mantissa == 0 with exponent == 0),
## so values far beyond float's ~1.8e308 limit stay representable. Every operation
## returns a new instance; operands are never mutated. Precision is that of a float
## mantissa (~15-16 significant digits), which is plenty for game values.

## Exponent gap beyond which the smaller operand cannot change a float mantissa.
const MAX_SIGNIFICANT_GAP: int = 17
const LN10: float = 2.302585092994046

var mantissa: float
var exponent: int


func _init(normalized_mantissa: float = 0.0, normalized_exponent: int = 0) -> void:
	mantissa = normalized_mantissa
	exponent = normalized_exponent


static func zero() -> BigNumber:
	return BigNumber.new(0.0, 0)


static func one() -> BigNumber:
	return BigNumber.new(1.0, 0)


## Builds a value from any mantissa/exponent pair, normalizing it.
static func of(raw_mantissa: float, raw_exponent: int) -> BigNumber:
	if raw_mantissa == 0.0 or is_nan(raw_mantissa):
		return zero()
	var shift: int = int(floor(log(absf(raw_mantissa)) / LN10))
	var m: float = raw_mantissa / pow(10.0, shift)
	var e: int = raw_exponent + shift
	# log() rounding can leave the mantissa one decade off; fix it up.
	while absf(m) >= 10.0:
		m /= 10.0
		e += 1
	while absf(m) < 1.0:
		m *= 10.0
		e -= 1
	return BigNumber.new(m, e)


static func from_float(value: float) -> BigNumber:
	return of(value, 0)


## Parses "1.5e1234" (the serialize() format) or any plain float literal.
static func parse(text: String) -> BigNumber:
	var parts: PackedStringArray = text.strip_edges().to_lower().split("e")
	if parts.size() == 2:
		return of(parts[0].to_float(), parts[1].to_int())
	return from_float(text.to_float())


func is_zero() -> bool:
	return mantissa == 0.0


func is_negative() -> bool:
	return mantissa < 0.0


func add(other: BigNumber) -> BigNumber:
	if other.is_zero():
		return self
	if is_zero():
		return other
	var gap: int = exponent - other.exponent
	if gap > MAX_SIGNIFICANT_GAP:
		return self
	if gap < -MAX_SIGNIFICANT_GAP:
		return other
	if gap >= 0:
		return of(mantissa + other.mantissa / pow(10.0, gap), exponent)
	return of(mantissa / pow(10.0, -gap) + other.mantissa, other.exponent)


func sub(other: BigNumber) -> BigNumber:
	return add(other.negated())


func negated() -> BigNumber:
	return BigNumber.new(-mantissa, exponent)


func mul(other: BigNumber) -> BigNumber:
	return of(mantissa * other.mantissa, exponent + other.exponent)


func mul_float(factor: float) -> BigNumber:
	return of(mantissa * factor, exponent)


## Division by zero is a programming error: it is reported and yields zero.
func div(other: BigNumber) -> BigNumber:
	if other.is_zero():
		push_error("BigNumber.div: division by zero")
		return zero()
	return of(mantissa / other.mantissa, exponent - other.exponent)


## Raises a non-negative value to a real power through log10, so growth curves
## like 1.15^level never overflow an intermediate float.
func pow_f(power: float) -> BigNumber:
	if power == 0.0:
		return one()
	if is_zero():
		return zero()
	if is_negative():
		push_error("BigNumber.pow_f: negative base is not supported")
		return zero()
	var result_log10: float = log10() * power
	var result_exponent: int = int(floor(result_log10))
	return of(pow(10.0, result_log10 - result_exponent), result_exponent)


## log10 of the absolute value; -INF for zero.
func log10() -> float:
	if is_zero():
		return -INF
	return float(exponent) + log(absf(mantissa)) / LN10


## Returns -1, 0 or 1.
func compare(other: BigNumber) -> int:
	var own_sign: int = signi(int(signf(mantissa)))
	var other_sign: int = signi(int(signf(other.mantissa)))
	if own_sign != other_sign:
		return 1 if own_sign > other_sign else -1
	if own_sign == 0:
		return 0
	var magnitude: int = 0
	if exponent != other.exponent:
		magnitude = 1 if exponent > other.exponent else -1
	elif absf(mantissa) != absf(other.mantissa):
		magnitude = 1 if absf(mantissa) > absf(other.mantissa) else -1
	return magnitude * own_sign


func gt(other: BigNumber) -> bool:
	return compare(other) > 0


func gte(other: BigNumber) -> bool:
	return compare(other) >= 0


func lt(other: BigNumber) -> bool:
	return compare(other) < 0


func lte(other: BigNumber) -> bool:
	return compare(other) <= 0


func is_equal_approx(other: BigNumber) -> bool:
	return exponent == other.exponent and is_equal_approx_float(mantissa, other.mantissa)


static func is_equal_approx_float(a: float, b: float) -> bool:
	return absf(a - b) <= 1e-12 * maxf(1.0, maxf(absf(a), absf(b)))


## Float value; +/-INF when the magnitude is beyond float range.
func to_float() -> float:
	if exponent > 308:
		return INF if mantissa > 0.0 else -INF
	if exponent < -308:
		return 0.0
	return mantissa * pow(10.0, exponent)


## Persistence format, e.g. "1.5e1234". Inverse of parse().
func serialize() -> String:
	return "%se%d" % [String.num(mantissa, 14), exponent]
