extends GutTest
## GameState routes app lifecycle notifications to its SaveController.

const GameStateScript: GDScript = preload("res://autoload/game_state.gd")


class SpyController:
	extends SaveController

	var calls: Array[String] = []

	func _init() -> void:
		super(GameSession.new(), SaveStore.new("user://unused_spy_save.json"), func() -> int: return 0)

	func suspend() -> void:
		calls.append("suspend")

	func resume() -> OfflineReward:
		calls.append("resume")
		return OfflineReward.new(0, {})

	func save_now() -> Error:
		calls.append("save")
		return OK


class SpyCloud:
	extends CloudSync

	var calls: Array[String]

	func _init(log: Array[String]) -> void:
		super(null, null, null)
		calls = log

	func suspend() -> void:
		calls.append("cloud_suspend")

	func resume() -> OfflineReward:
		calls.append("cloud_resume")
		return OfflineReward.new(0, {})

	func push() -> CloudPushResult:
		calls.append("cloud_push")
		return CloudPushResult.new(true)

	func flush() -> CloudPushResult:
		calls.append("cloud_flush")
		return CloudPushResult.new(true)


var state: Node
var spy: SpyController


func before_each() -> void:
	state = GameStateScript.new()
	spy = SpyController.new()
	state.saves = spy


func after_each() -> void:
	state.free()


func test_app_pause_suspends_the_save_lifecycle() -> void:
	state._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	assert_eq(spy.calls, ["suspend"] as Array[String])


func test_app_resume_pays_the_suspended_time() -> void:
	state._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	assert_eq(spy.calls, ["resume"] as Array[String])


func test_focus_loss_only_saves() -> void:
	state._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert_eq(spy.calls, ["save"] as Array[String])


func test_other_notifications_do_not_touch_the_save() -> void:
	state._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	assert_eq(spy.calls, [] as Array[String])


func test_notifications_before_ready_are_ignored() -> void:
	state.saves = null
	state._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	assert_eq(spy.calls, [] as Array[String])


func test_cloud_is_on_by_default_and_off_for_no_cloud_test_and_import_runs() -> void:
	assert_true(GameStateScript.cloud_enabled(PackedStringArray(), PackedStringArray()))
	assert_false(GameStateScript.cloud_enabled(PackedStringArray(), PackedStringArray(["--no-cloud"])))
	assert_false(
		GameStateScript.cloud_enabled(PackedStringArray(["-s", "addons/gut/gut_cmdln.gd"]), PackedStringArray())
	)
	assert_false(GameStateScript.cloud_enabled(PackedStringArray(["--headless", "--import"]), PackedStringArray()))


func test_cloud_is_off_in_builds_exported_with_the_no_cloud_feature() -> void:
	assert_eq(GameStateScript.NO_CLOUD_FEATURE, "no_cloud")
	assert_false(GameStateScript.cloud_enabled(PackedStringArray(), PackedStringArray(), true))
	assert_true(GameStateScript.cloud_enabled(PackedStringArray(), PackedStringArray(), false))


func test_test_and_import_runs_use_a_scratch_save_unless_a_save_path_is_given() -> void:
	var none: PackedStringArray = PackedStringArray()
	var gut: PackedStringArray = PackedStringArray(["-s", "addons/gut/gut_cmdln.gd"])
	var scratch: PackedStringArray = PackedStringArray(["--save-path=/tmp/soak/save.json"])
	assert_eq(GameStateScript.save_path_for(none, none), "user://save.json")
	assert_eq(GameStateScript.save_path_for(gut, none), "user://tool_run/save.json")
	assert_eq(
		GameStateScript.save_path_for(PackedStringArray(["--headless", "--import"]), none),
		"user://tool_run/save.json"
	)
	assert_eq(GameStateScript.save_path_for(gut, scratch), "/tmp/soak/save.json")
	assert_eq(GameStateScript.save_path_for(none, scratch), "/tmp/soak/save.json")


func test_only_a_tool_run_without_a_save_path_clears_the_scratch_save() -> void:
	var none: PackedStringArray = PackedStringArray()
	var gut: PackedStringArray = PackedStringArray(["-s", "addons/gut/gut_cmdln.gd"])
	var explicit_scratch: PackedStringArray = PackedStringArray(["--save-path=user://tool_run/save.json"])
	assert_true(GameStateScript.clears_scratch_save(gut, none))
	assert_true(GameStateScript.clears_scratch_save(PackedStringArray(["--headless", "--import"]), none))
	assert_false(GameStateScript.clears_scratch_save(gut, explicit_scratch), "an explicit save path is never deleted")
	assert_false(GameStateScript.clears_scratch_save(none, none), "a play session keeps its save")


func test_clear_save_removes_the_save_and_creates_its_folder() -> void:
	var dir_path: String = "user://test_game_state/%d" % randi()
	var save_path: String = dir_path.path_join("run/save.json")
	assert_eq(GameStateScript.clear_save(save_path), OK, "a missing save and folder are fine")
	assert_true(DirAccess.dir_exists_absolute(save_path.get_base_dir()))
	FileAccess.open(save_path, FileAccess.WRITE).store_string("{}")
	assert_eq(GameStateScript.clear_save(save_path), OK)
	assert_false(FileAccess.file_exists(save_path))
	DirAccess.remove_absolute(save_path.get_base_dir())
	DirAccess.remove_absolute(dir_path)


func test_clear_save_reports_a_save_it_cannot_remove() -> void:
	if not _can_lock_a_folder():
		return
	var save_path: String = _locked_save()
	var cleared: Error = GameStateScript.clear_save(save_path)
	_unlock_and_remove(save_path)
	assert_ne(cleared, OK)
	assert_eq(_unlocked_contents, "{}", "the save is left as it was")


func test_a_tool_run_loads_the_scratch_save_only_after_clearing_it() -> void:
	var gut: PackedStringArray = PackedStringArray(["-s", "addons/gut/gut_cmdln.gd"])
	var none: PackedStringArray = PackedStringArray()
	var dir_path: String = "user://test_game_state/%d" % randi()
	var save_path: String = dir_path.path_join("save.json")
	assert_true(GameStateScript.prepare_save(save_path, gut, none), "a cleared scratch save loads")
	DirAccess.remove_absolute(dir_path)
	assert_true(GameStateScript.prepare_save("user://unused/save.json", none, none), "a play session loads")
	assert_false(DirAccess.dir_exists_absolute("user://unused"), "a play session clears nothing")


func test_a_scratch_save_that_cannot_be_cleared_is_reported_and_not_loaded() -> void:
	if not _can_lock_a_folder():
		return
	var gut: PackedStringArray = PackedStringArray(["-s", "addons/gut/gut_cmdln.gd"])
	var save_path: String = _locked_save()
	var loads: bool = GameStateScript.prepare_save(save_path, gut, PackedStringArray())
	_unlock_and_remove(save_path)
	assert_false(loads, "the earlier run's save is not loaded")
	assert_push_error("could not clear the scratch save")


var _unlocked_contents: String


## Root ignores folder permissions and Windows has no chmod, so a locked folder
## cannot be simulated there.
func _can_lock_a_folder() -> bool:
	if OS.get_name() == "Windows":
		pending("needs chmod")
		return false
	var output: Array = []
	OS.execute("id", ["-u"], output)
	if output.size() > 0 and str(output[0]).strip_edges() == "0":
		pending("root ignores folder permissions")
		return false
	return true


## A save in a read-only folder, so it cannot be removed.
func _locked_save() -> String:
	var dir_path: String = "user://test_game_state/%d" % randi()
	DirAccess.make_dir_recursive_absolute(dir_path)
	var save_path: String = dir_path.path_join("save.json")
	FileAccess.open(save_path, FileAccess.WRITE).store_string("{}")
	OS.execute("chmod", ["555", ProjectSettings.globalize_path(dir_path)])
	return save_path


func _unlock_and_remove(save_path: String) -> void:
	OS.execute("chmod", ["755", ProjectSettings.globalize_path(save_path.get_base_dir())])
	_unlocked_contents = FileAccess.get_file_as_string(save_path)
	DirAccess.remove_absolute(save_path)
	DirAccess.remove_absolute(save_path.get_base_dir())


func test_cloud_config_defaults_to_the_local_stack() -> void:
	var config: CloudConfig = GameStateScript.cloud_config()
	assert_eq(config.url, "http://127.0.0.1:54321")
	assert_eq(config.api_key, "sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH")


func test_the_auth_file_sits_next_to_the_save() -> void:
	assert_eq(GameStateScript.auth_path("user://save.json"), "user://auth.json")
	assert_eq(GameStateScript.auth_path("/tmp/soak/save.json"), "/tmp/soak/auth.json")


func test_with_cloud_pause_resume_and_focus_loss_also_reach_the_cloud() -> void:
	state.cloud = SpyCloud.new(spy.calls)
	state._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	state._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	state._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert_eq(
		spy.calls,
		["suspend", "cloud_suspend", "resume", "cloud_resume", "save", "cloud_push"] as Array[String]
	)


func test_window_close_saves_flushes_the_cloud_then_quits() -> void:
	state.cloud = SpyCloud.new(spy.calls)
	state.quit_game = func() -> void: spy.calls.append("quit")
	await state.close_game()
	assert_eq(spy.calls, ["save", "cloud_flush", "quit"] as Array[String])


func test_window_close_without_cloud_saves_and_quits() -> void:
	state.quit_game = func() -> void: spy.calls.append("quit")
	await state.close_game()
	assert_eq(spy.calls, ["save", "quit"] as Array[String])
