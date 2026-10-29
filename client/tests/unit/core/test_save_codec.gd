extends GutTest


func _sample() -> SaveData:
	var data: SaveData = SaveData.new()
	data.stage = 7
	data.gold = BigNumber.of(1.5, 400)
	data.attack_level = 12
	data.health_level = 3
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
	assert_eq(result.data.last_seen_unix, 1_800_000_000)


func test_encode_writes_current_version() -> void:
	assert_eq(int(_valid_dict()["version"]), SaveCodec.VERSION)


func test_rejects_text_that_is_not_json() -> void:
	var result: SaveDecodeResult = SaveCodec.decode("{not json")
	assert_false(result.is_ok())
	assert_null(result.data)
	assert_eq(result.error, "save is not a JSON object")


func test_rejects_json_that_is_not_an_object() -> void:
	assert_eq(SaveCodec.decode("[1, 2]").error, "save is not a JSON object")


func test_rejects_unsupported_version() -> void:
	var fields: Dictionary = _valid_dict()
	fields["version"] = 99
	var result: SaveDecodeResult = _decode_dict(fields)
	assert_null(result.data)
	assert_eq(result.error, "unsupported save version 99")


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
