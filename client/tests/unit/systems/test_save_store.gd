extends GutTest

var dir_path: String
var store: SaveStore


func before_each() -> void:
	dir_path = "user://test_saves/%d" % randi()
	DirAccess.make_dir_recursive_absolute(dir_path)
	store = SaveStore.new(dir_path.path_join("save.json"))


func after_each() -> void:
	for file_name: String in DirAccess.get_files_at(dir_path):
		DirAccess.remove_absolute(dir_path.path_join(file_name))
	DirAccess.remove_absolute(dir_path)


func _sample(stage: int) -> SaveData:
	var data: SaveData = SaveData.new()
	data.stage = stage
	data.gold = BigNumber.of(3.0, 600)
	data.last_seen_unix = 1_750_000_000
	return data


func _write_raw(text: String) -> void:
	var file: FileAccess = FileAccess.open(store.path, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func test_missing_file_means_new_game() -> void:
	var result: SaveLoadResult = store.load_save()
	assert_eq(result.status, SaveLoadResult.Status.NEW_GAME)
	assert_null(result.data)


func test_write_then_load_round_trips() -> void:
	assert_eq(store.write(_sample(9)), OK)
	var result: SaveLoadResult = store.load_save()
	assert_eq(result.status, SaveLoadResult.Status.LOADED)
	assert_eq(result.data.stage, 9)
	assert_true(result.data.gold.is_equal_approx(BigNumber.of(3.0, 600)))


func test_write_replaces_previous_save_and_leaves_no_temp_file() -> void:
	store.write(_sample(2))
	store.write(_sample(3))
	assert_eq(store.load_save().data.stage, 3)
	assert_eq(Array(DirAccess.get_files_at(dir_path)), ["save.json"])


func test_rejected_save_is_moved_aside_and_reports_the_reason() -> void:
	_write_raw("{broken")
	var result: SaveLoadResult = store.load_save()
	assert_eq(result.status, SaveLoadResult.Status.REJECTED)
	assert_null(result.data)
	assert_eq(result.error, "save is not a JSON object")
	assert_false(FileAccess.file_exists(store.path))
	assert_eq(FileAccess.get_file_as_string(store.rejected_path()), "{broken")


func test_fresh_save_after_rejection_keeps_the_rejected_copy() -> void:
	_write_raw("{broken")
	store.load_save()
	store.write(_sample(1))
	assert_eq(store.load_save().status, SaveLoadResult.Status.LOADED)
	assert_eq(FileAccess.get_file_as_string(store.rejected_path()), "{broken")
