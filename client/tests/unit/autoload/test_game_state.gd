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
