extends GutTest


func _sample() -> SaveData:
	var data: SaveData = SaveData.new()
	data.stage = 7
	data.gold = BigNumber.of(1.5, 400)
	data.attack_level = 12
	data.health_level = 3
	data.crit_chance_level = 9
	data.crit_damage_level = 41
	data.attack_speed_level = 75
	data.ascension_shards = 12
	data.ascension_count = 2
	data.talents = {"might": 3, "greed": 1}
	data.last_seen_unix = 1_800_000_000
	return data


func _valid_dict() -> Dictionary:
	return JSON.parse_string(SaveCodec.encode(_sample())) as Dictionary


func _decode_dict(fields: Dictionary) -> SaveDecodeResult:
	return SaveCodec.decode(JSON.stringify(fields))


func test_round_trip_keeps_every_field_beyond_float_range() -> void:
	var result: SaveDecodeResult = SaveCodec.decode(SaveCodec.encode(_sample()))
	assert_true(result.is_ok(), result.error)
	assert_eq(result.data.stage, 7)
	assert_true(result.data.gold.is_equal_approx(BigNumber.of(1.5, 400)))
	assert_eq(result.data.attack_level, 12)
	assert_eq(result.data.health_level, 3)
	assert_eq(result.data.crit_chance_level, 9)
	assert_eq(result.data.crit_damage_level, 41)
	assert_eq(result.data.attack_speed_level, 75)
	assert_eq(result.data.ascension_shards, 12)
	assert_eq(result.data.ascension_count, 2)
	assert_eq(result.data.talents, {"might": 3, "greed": 1})
	assert_eq(result.data.last_seen_unix, 1_800_000_000)


func test_encode_writes_current_version() -> void:
	assert_eq(SaveCodec.VERSION, 3)
	assert_eq(int(_valid_dict()["version"]), 3)


func test_version_one_save_loads_with_rate_levels_at_zero() -> void:
	var result: SaveDecodeResult = SaveCodec.decode(JSON.stringify({
		"version": 1,
		"stage": 7,
		"gold": "1.5e400",
		"attack_level": 12,
		"health_level": 3,
		"last_seen_unix": 1_800_000_000,
	}))
	assert_true(result.is_ok(), result.error)
	assert_eq(result.data.stage, 7)
	assert_true(result.data.gold.is_equal_approx(BigNumber.of(1.5, 400)))
	assert_eq(result.data.attack_level, 12)
	assert_eq(result.data.health_level, 3)
	assert_eq(result.data.crit_chance_level, 0)
	assert_eq(result.data.crit_damage_level, 0)
	assert_eq(result.data.attack_speed_level, 0)
	assert_eq(result.data.ascension_shards, 0)
	assert_eq(result.data.ascension_count, 0)
	assert_eq(result.data.talents, {})
	assert_eq(result.data.last_seen_unix, 1_800_000_000)


func test_version_two_save_loads_without_ascension_progress() -> void:
	var fields: Dictionary = _valid_dict()
	fields["version"] = 2
	fields.erase("ascension_shards")
	fields.erase("ascension_count")
	fields.erase("talents")
	var result: SaveDecodeResult = _decode_dict(fields)
	assert_true(result.is_ok(), result.error)
	assert_eq(result.data.stage, 7)
	assert_eq(result.data.crit_damage_level, 41)
	assert_eq(result.data.attack_speed_level, 75)
	assert_eq(result.data.ascension_shards, 0)
	assert_eq(result.data.ascension_count, 0)
	assert_eq(result.data.talents, {})


func test_version_three_save_missing_ascension_fields_is_rejected() -> void:
	for field: String in ["ascension_shards", "ascension_count"]:
		var fields: Dictionary = _valid_dict()
		fields.erase(field)
		var result: SaveDecodeResult = _decode_dict(fields)
		assert_null(result.data, field)
		assert_eq(result.error, "save field '%s' is missing or not an integer" % field)


func test_rejects_talents_that_are_not_an_object() -> void:
	for bad: Variant in [null, [1, 2], "might", 3]:
		var fields: Dictionary = _valid_dict()
		if bad == null:
			fields.erase("talents")
		else:
			fields["talents"] = bad
		var result: SaveDecodeResult = _decode_dict(fields)
		assert_null(result.data, str(bad))
		assert_eq(result.error, "save field 'talents' is not an object")


func test_rejects_talent_levels_that_are_not_whole_and_non_negative() -> void:
	var cases: Array = [
		[2.5, "save field 'talents.might' is missing or not an integer"],
		["3", "save field 'talents.might' is missing or not an integer"],
		[-1, "save field 'talents.might' must be >= 0, got -1"],
	]
	for case: Array in cases:
		var fields: Dictionary = _valid_dict()
		fields["talents"] = {"might": case[0]}
		var result: SaveDecodeResult = _decode_dict(fields)
		assert_null(result.data, str(case[0]))
		assert_eq(result.error, case[1])


func test_version_two_save_missing_a_rate_level_is_rejected() -> void:
	for field: String in ["crit_chance_level", "crit_damage_level", "attack_speed_level"]:
		var fields: Dictionary = _valid_dict()
		fields.erase(field)
		var result: SaveDecodeResult = _decode_dict(fields)
		assert_null(result.data, field)
		assert_eq(result.error, "save field '%s' is missing or not an integer" % field)


func test_rejects_text_that_is_not_json() -> void:
	var result: SaveDecodeResult = SaveCodec.decode("{not json")
	assert_false(result.is_ok())
	assert_null(result.data)
	assert_eq(result.error, "save is not a JSON object")


func test_rejects_json_that_is_not_an_object() -> void:
	assert_eq(SaveCodec.decode("[1, 2]").error, "save is not a JSON object")


func test_rejects_unsupported_version() -> void:
	var fields: Dictionary = _valid_dict()
	for version: int in [0, 4, 99]:
		fields["version"] = version
		var result: SaveDecodeResult = _decode_dict(fields)
		assert_null(result.data)
		assert_eq(result.error, "unsupported save version %d" % version)


func test_rejects_missing_field() -> void:
	var fields: Dictionary = _valid_dict()
	fields.erase("attack_level")
	assert_eq(_decode_dict(fields).error, "save field 'attack_level' is missing or not an integer")


func test_rejects_fractional_integer_field() -> void:
	var fields: Dictionary = _valid_dict()
	fields["stage"] = 2.5
	assert_eq(_decode_dict(fields).error, "save field 'stage' is missing or not an integer")


func test_rejects_out_of_range_values() -> void:
	var cases: Dictionary = {
		"stage": [0, "save field 'stage' must be >= 1, got 0"],
		"attack_level": [-1, "save field 'attack_level' must be >= 0, got -1"],
		"health_level": [-4, "save field 'health_level' must be >= 0, got -4"],
		"crit_chance_level": [-1, "save field 'crit_chance_level' must be >= 0, got -1"],
		"crit_damage_level": [-2, "save field 'crit_damage_level' must be >= 0, got -2"],
		"attack_speed_level": [-3, "save field 'attack_speed_level' must be >= 0, got -3"],
		"ascension_shards": [-5, "save field 'ascension_shards' must be >= 0, got -5"],
		"ascension_count": [-1, "save field 'ascension_count' must be >= 0, got -1"],
		"last_seen_unix": [-10, "save field 'last_seen_unix' must be >= 0, got -10"],
	}
	for field: String in cases:
		var fields: Dictionary = _valid_dict()
		var case: Array = cases[field]
		fields[field] = case[0]
		var result: SaveDecodeResult = _decode_dict(fields)
		assert_null(result.data, field)
		assert_eq(result.error, case[1])


func test_rejects_gold_that_is_not_a_number() -> void:
	for bad: Variant in ["abc", "", "1.5e", 12]:
		var fields: Dictionary = _valid_dict()
		fields["gold"] = bad
		var result: SaveDecodeResult = _decode_dict(fields)
		assert_null(result.data, str(bad))
		assert_eq(result.error, "save field 'gold' is not a serialized number")


func test_rejects_negative_gold() -> void:
	var fields: Dictionary = _valid_dict()
	fields["gold"] = "-5e0"
	assert_eq(_decode_dict(fields).error, "save field 'gold' must not be negative")
