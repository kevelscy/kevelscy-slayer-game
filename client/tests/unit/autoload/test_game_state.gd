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


func test_window_close_saves_pushes_then_quits() -> void:
	state.cloud = SpyCloud.new(spy.calls)
	state.quit_game = func() -> void: spy.calls.append("quit")
	await state.close_game()
	assert_eq(spy.calls, ["save", "cloud_push", "quit"] as Array[String])


func test_window_close_without_cloud_saves_and_quits() -> void:
	state.quit_game = func() -> void: spy.calls.append("quit")
	await state.close_game()
	assert_eq(spy.calls, ["save", "quit"] as Array[String])
