class_name SaveCodec
extends RefCounted
## Versioned JSON format of SaveData. Decoding validates every field and rejects
## the whole save on the first problem, so a damaged file never half-applies.

const VERSION: int = 1
const INTEGER_FIELDS: Dictionary[String, int] = {
	"stage": 1,
	"attack_level": 0,
	"health_level": 0,
	"last_seen_unix": 0,
}
const NUMBER_PATTERN: String = "^-?\\d+(\\.\\d+)?(e-?\\d+)?$"


static func encode(data: SaveData) -> String:
	return JSON.stringify({
		"version": VERSION,
		"stage": data.stage,
		"gold": data.gold.serialize(),
		"attack_level": data.attack_level,
		"health_level": data.health_level,
		"last_seen_unix": data.last_seen_unix,
	}, "\t")


static func decode(text: String) -> SaveDecodeResult:
	# A JSON instance reports parse errors without logging them as engine errors.
	var json: JSON = JSON.new()
	var parsed: Variant = json.data if json.parse(text) == OK else null
	if not parsed is Dictionary:
		return SaveDecodeResult.new(null, "save is not a JSON object")
	var fields: Dictionary = parsed
	var version: Variant = fields.get("version")
	if not _is_integer(version) or int(version) != VERSION:
		return SaveDecodeResult.new(null, "unsupported save version %s" % _describe(version))

	var integers: Dictionary[String, int] = {}
	for field: String in INTEGER_FIELDS:
		var value: Variant = fields.get(field)
		if not _is_integer(value):
			return SaveDecodeResult.new(null, "save field '%s' is missing or not an integer" % field)
		var minimum: int = INTEGER_FIELDS[field]
		if int(value) < minimum:
			return SaveDecodeResult.new(
				null, "save field '%s' must be >= %d, got %d" % [field, minimum, int(value)]
			)
		integers[field] = int(value)

	var gold_text: Variant = fields.get("gold")
	var pattern: RegEx = RegEx.create_from_string(NUMBER_PATTERN)
	if not gold_text is String or pattern.search(gold_text as String) == null:
		return SaveDecodeResult.new(null, "save field 'gold' is not a serialized number")
	var gold: BigNumber = BigNumber.parse(gold_text as String)
	if gold.is_negative():
		return SaveDecodeResult.new(null, "save field 'gold' must not be negative")

	var data: SaveData = SaveData.new()
	data.stage = integers["stage"]
	data.gold = gold
	data.attack_level = integers["attack_level"]
	data.health_level = integers["health_level"]
	data.last_seen_unix = integers["last_seen_unix"]
	return SaveDecodeResult.new(data)


## JSON numbers arrive as floats; only whole values count as integers.
static func _is_integer(value: Variant) -> bool:
	if value is int:
		return true
	return value is float and is_finite(value as float) and (value as float) == floorf(value as float)


static func _describe(value: Variant) -> String:
	return str(int(value)) if _is_integer(value) else str(value)
