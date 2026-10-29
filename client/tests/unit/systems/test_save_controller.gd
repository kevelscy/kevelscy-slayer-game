extends GutTest

const T0: int = 1_700_000_000
const HOUR: int = 3600

var dir_path: String
var store: SaveStore
var now: int
var session: GameSession
var controller: SaveController


func before_each() -> void:
	dir_path = "user://test_controller/%d" % randi()
	DirAccess.make_dir_recursive_absolute(dir_path)
	store = SaveStore.new(dir_path.path_join("save.json"))
	now = T0
	session = GameSession.new()
	controller = SaveController.new(session, store, func() -> int: return now)


func after_each() -> void:
	for file_name: String in DirAccess.get_files_at(dir_path):
		DirAccess.remove_absolute(dir_path.path_join(file_name))
	DirAccess.remove_absolute(dir_path)


func _seed_save(stage: int, last_seen: int) -> void:
	var data: SaveData = SaveData.new()
	data.stage = stage
	data.gold = BigNumber.from_float(100.0)
	data.last_seen_unix = last_seen
	store.write(data)


func test_boot_without_save_starts_new_game_and_writes_one() -> void:
	var reward: OfflineReward = controller.boot()
	assert_true(reward.is_empty())
	assert_eq(session.progression.stage, 1)
	assert_eq(store.load_save().data.last_seen_unix, T0)


func test_boot_restores_save_and_pays_time_away() -> void:
	_seed_save(4, T0 - HOUR)
	var reward: OfflineReward = controller.boot()
	assert_eq(session.progression.stage, 4)
	assert_eq(reward.elapsed_seconds, HOUR)
	var expected: BigNumber = BigNumber.from_float(100.0).add(reward.amounts[GameSession.GOLD])
	assert_true(session.wallet.get_amount(GameSession.GOLD).is_equal_approx(expected))
	assert_eq(store.load_save().data.last_seen_unix, T0)


func test_without_device_clock_offline_boot_and_resume_pay_nothing() -> void:
	_seed_save(4, T0 - HOUR)
	controller.device_clock_offline = false
	watch_signals(controller)
	assert_true(controller.boot().is_empty())
	assert_eq(session.progression.stage, 4)
	assert_true(session.wallet.get_amount(GameSession.GOLD).is_equal_approx(BigNumber.from_float(100.0)))
	now = T0 + HOUR
	assert_true(controller.resume().is_empty())
	assert_signal_not_emitted(controller, "offline_reward_granted")
	assert_eq(store.load_save().data.last_seen_unix, T0 + HOUR, "saves still happen")


func test_boot_with_rejected_save_starts_new_game_and_keeps_the_bad_file() -> void:
	var file: FileAccess = FileAccess.open(store.path, FileAccess.WRITE)
	file.store_string("{broken")
	file.close()
	var reward: OfflineReward = controller.boot()
	assert_push_error("SaveController: save rejected")
	assert_true(reward.is_empty())
	assert_eq(session.progression.stage, 1)
	assert_eq(FileAccess.get_file_as_string(store.rejected_path()), "{broken")
	assert_eq(store.load_save().status, SaveLoadResult.Status.LOADED)


func test_resume_pays_only_the_time_since_suspend_and_emits() -> void:
	controller.boot()
	now = T0 + 100
	controller.suspend()
	now = T0 + 100 + HOUR
	watch_signals(controller)
	var reward: OfflineReward = controller.resume()
	assert_eq(reward.elapsed_seconds, HOUR)
	assert_signal_emitted_with_parameters(controller, "offline_reward_granted", [reward])
	assert_eq(store.load_save().data.last_seen_unix, T0 + 100 + HOUR)


func test_empty_reward_is_not_announced() -> void:
	controller.boot()
	watch_signals(controller)
	controller.resume()
	assert_signal_not_emitted(controller, "offline_reward_granted")


func test_autosaves_every_thirty_seconds() -> void:
	controller.boot()
	session.progression.restore_stage(6)
	controller.tick(29.0)
	assert_eq(store.load_save().data.stage, 1)
	controller.tick(1.0)
	assert_eq(store.load_save().data.stage, 6)
	session.progression.restore_stage(7)
	controller.tick(29.9)
	assert_eq(store.load_save().data.stage, 6)


func test_save_now_records_current_time() -> void:
	controller.boot()
	now = T0 + 42
	assert_eq(controller.save_now(), OK)
	assert_eq(store.load_save().data.last_seen_unix, T0 + 42)
