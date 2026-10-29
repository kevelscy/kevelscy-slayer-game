class_name NumberFormat
extends RefCounted
## Idle-game short notation: 999, 1,23K, 12,3M, 123B, 1,00T, then aa..zz, then scientific.
## Values are truncated, never rounded up, so the display never overstates a balance.
## Decimals use a comma, as the Spanish audience reads them.

const SHORT_SUFFIXES: PackedStringArray = ["", "K", "M", "B", "T"]
const ALPHABET: String = "abcdefghijklmnopqrstuvwxyz"
const LETTER_SUFFIX_COUNT: int = 26 * 26


static func format(value: BigNumber) -> String:
	if value.is_zero() or value.exponent < 0:
		return "0"
	var sign_prefix: String = "-" if value.is_negative() else ""
	var magnitude: float = absf(value.mantissa)
	if value.exponent < 3:
		return sign_prefix + str(int(floor(magnitude * pow(10.0, value.exponent) + 1e-9)))

	var group: int = value.exponent / 3
	var suffix: String = _suffix_for_group(group)
	if suffix.is_empty():
		return "%s%se%d" % [sign_prefix, _truncate(magnitude, 2), value.exponent]

	var scaled: float = magnitude * pow(10.0, value.exponent - group * 3)
	var decimals: int = 2 if scaled < 10.0 else (1 if scaled < 100.0 else 0)
	return sign_prefix + _truncate(scaled, decimals) + suffix


## Empty when the group is past the last letter suffix ("zz").
static func _suffix_for_group(group: int) -> String:
	if group < SHORT_SUFFIXES.size():
		return SHORT_SUFFIXES[group]
	var letter_index: int = group - SHORT_SUFFIXES.size()
	if letter_index >= LETTER_SUFFIX_COUNT:
		return ""
	return ALPHABET[letter_index / 26] + ALPHABET[letter_index % 26]


## A plain rate or percent with a fixed number of decimals and a decimal comma
## (rounded like "%.*f"), for labels such as "5,5%" or "1,50/s".
static func decimal(value: float, decimals: int) -> String:
	return ("%.*f" % [decimals, value]).replace(".", ",")


static func _truncate(value: float, decimals: int) -> String:
	var factor: float = pow(10.0, decimals)
	# Epsilon guards against values like 1.23 being stored as 1.2299999.
	var truncated: float = floor(value * factor + 1e-6) / factor
	return String.num(truncated, decimals).pad_decimals(decimals).replace(".", ",")
