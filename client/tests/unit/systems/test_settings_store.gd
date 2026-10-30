extends GutTest
## SettingsStore: local player settings (never synced) kept in a ConfigFile next to the save.

var dir_path: String
var store: SettingsStore


func before_each() -> void:
	dir_path = "user://test_settings/%d" % randi()
	DirAccess.make_dir_recursive_absolute(dir_path)
	store = SettingsStore.new(dir_path.path_join("settings.cfg"))


func after_each() -> void:
	for file_name: String in DirAccess.get_files_at(dir_path):
		DirAccess.remove_absolute(dir_path.path_join(file_name))
	DirAccess.remove_absolute(dir_path)


func _write_raw(text: String) -> void:
	var file: FileAccess = FileAccess.open(store.path, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func test_a_missing_file_means_sound_on() -> void:
	store.load_settings()
	assert_false(store.sfx_muted)
	assert_false(FileAccess.file_exists(store.path), "loading never creates the file")


func test_a_saved_mute_survives_a_new_store() -> void:
	store.sfx_muted = true
	store.save_settings()
	var reloaded: SettingsStore = SettingsStore.new(store.path)
	reloaded.load_settings()
	assert_true(reloaded.sfx_muted)
	var config: ConfigFile = ConfigFile.new()
	assert_eq(config.load(store.path), OK)
	assert_eq(config.get_value("audio", "sfx_muted"), true)


func test_unmuting_is_saved_too() -> void:
	store.sfx_muted = true
	store.save_settings()
	store.sfx_muted = false
	store.save_settings()
	var reloaded: SettingsStore = SettingsStore.new(store.path)
	reloaded.load_settings()
	assert_false(reloaded.sfx_muted)


func test_an_unreadable_file_means_sound_on() -> void:
	_write_raw("this is {not a config file")
	store.sfx_muted = true
	store.load_settings()
	assert_false(store.sfx_muted)


func test_a_non_boolean_value_means_sound_on() -> void:
	_write_raw("[audio]\nsfx_muted=\"yes\"\n")
	store.load_settings()
	assert_false(store.sfx_muted)
