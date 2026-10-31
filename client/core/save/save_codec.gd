class_name SaveCodec
extends RefCounted
## Versioned JSON format of SaveData. Decoding validates every field and rejects
## the whole save on the first problem, so a damaged file never half-applies.
## Older saves still load: version 1 has no rate upgrade levels, versions 1-2 have
## no ascension progress and versions 1-3 have no skill levels; the missing values
## start at 0 / empty, and has_skill_levels tells the session to grant the skills
## the saved stage reached.

const VERSION: int = 4
const OLDEST_VERSION: int = 1
const RATE_LEVELS_VERSION: int = 2
const ASCENSION_VERSION: int = 3
const SKILLS_VERSION: int = 4
const INTEGER_FIELDS: Dictionary[String, int] = {
	"stage": 1,
	"attack_level": 0,
	"health_level": 0,
	"last_seen_unix": 0,
}
## Added in version 2; required from that version on, each >= 0.
const RATE_LEVEL_FIELDS: Array[String] = ["crit_chance_level", "crit_damage_level", "attack_speed_level"]
## Added in version 3 next to the `talents` object; each >= 0.
const ASCENSION_FIELDS: Array[String] = ["ascension_shards", "ascension_count"]
const NUMBER_PATTERN: String = "^-?\\d+(\\.\\d+)?(e-?\\d+)?$"


static func encode(data: SaveData) -> String:
	return JSON.stringify({
		"version": VERSION,
		"stage": data.stage,
		"gold": data.gold.serialize(),
		"attack_level": data.attack_level,
		"health_level": data.health_level,
		"crit_chance_level": data.crit_chance_level,
		"crit_damage_level": data.crit_damage_level,
		"attack_speed_level": data.attack_speed_level,
		"ascension_shards": data.ascension_shards,
		"ascension_count": data.ascension_count,
		"talents": data.talents,
		"skills": data.skills,
		"equipped": data.equipped,
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
	if not _is_integer(version) or int(version) < OLDEST_VERSION or int(version) > VERSION:
		return SaveDecodeResult.new(null, "unsupported save version %s" % _describe(version))

	var required: Dictionary[String, int] = INTEGER_FIELDS.duplicate()
	if int(version) >= RATE_LEVELS_VERSION:
		for field: String in RATE_LEVEL_FIELDS:
			required[field] = 0
	if int(version) >= ASCENSION_VERSION:
		for field: String in ASCENSION_FIELDS:
			required[field] = 0
	var integers: Dictionary[String, int] = {}
	for field: String in required:
		var value: Variant = fields.get(field)
		if not _is_integer(value):
			return SaveDecodeResult.new(null, "save field '%s' is missing or not an integer" % field)
		var minimum: int = required[field]
		if int(value) < minimum:
			return SaveDecodeResult.new(
				null, "save field '%s' must be >= %d, got %d" % [field, minimum, int(value)]
			)
		integers[field] = int(value)

	var talents: Dictionary[String, int] = {}
	if int(version) >= ASCENSION_VERSION:
		var error: String = _decode_levels(fields, "talents", talents)
		if not error.is_empty():
			return SaveDecodeResult.new(null, error)
	var skills: Dictionary[String, int] = {}
	if int(version) >= SKILLS_VERSION:
		var error: String = _decode_levels(fields, "skills", skills)
		if not error.is_empty():
			return SaveDecodeResult.new(null, error)

	# Optional in every version: saves from before the skill tree have no list.
	var equipped: Array[String] = []
	if fields.has("equipped"):
		var saved: Variant = fields["equipped"]
		if not saved is Array or (saved as Array).any(func(id: Variant) -> bool: return not id is String):
			return SaveDecodeResult.new(null, "save field 'equipped' is not a list of skill ids")
		equipped.assign(saved as Array)

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
	data.crit_chance_level = integers.get("crit_chance_level", 0)
	data.crit_damage_level = integers.get("crit_damage_level", 0)
	data.attack_speed_level = integers.get("attack_speed_level", 0)
	data.ascension_shards = integers.get("ascension_shards", 0)
	data.ascension_count = integers.get("ascension_count", 0)
	data.talents = talents
	data.skills = skills
	data.has_skill_levels = int(version) >= SKILLS_VERSION
	data.equipped = equipped
	data.has_equipped = fields.has("equipped")
	data.last_seen_unix = integers["last_seen_unix"]
	return SaveDecodeResult.new(data)


## Reads an object of id to level (>= 0) into `levels`. Returns the error, or "".
static func _decode_levels(fields: Dictionary, name: String, levels: Dictionary[String, int]) -> String:
	var saved: Variant = fields.get(name)
	if not saved is Dictionary:
		return "save field '%s' is not an object" % name
	for id: Variant in saved:
		var field: String = "%s.%s" % [name, id]
		var level: Variant = (saved as Dictionary)[id]
		if not _is_integer(level):
			return "save field '%s' is missing or not an integer" % field
		if int(level) < 0:
			return "save field '%s' must be >= 0, got %d" % [field, int(level)]
		levels[str(id)] = int(level)
	return ""


## JSON numbers arrive as floats; only whole values count as integers.
static func _is_integer(value: Variant) -> bool:
	if value is int:
		return true
	return value is float and is_finite(value as float) and (value as float) == floorf(value as float)


static func _describe(value: Variant) -> String:
	return str(int(value)) if _is_integer(value) else str(value)
