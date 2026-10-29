extends GutTest

const URL: String = "http://cloud.test"
const KEY: String = "sb_publishable_test"
const T0: int = 1_700_000_000
const HOUR: int = 3600

var dir_path: String
var store: SaveStore
var transport: FakeHttpTransport
var session: GameSession
var controller: SaveController
var sync: CloudSync


func before_each() -> void:
	dir_path = "user://test_cloud_sync/%d" % randi()
	DirAccess.make_dir_recursive_absolute(dir_path)
	store = SaveStore.new(dir_path.path_join("save.json"))
	transport = FakeHttpTransport.new()
	session = GameSession.new()
	controller = SaveController.new(session, store, func() -> int: return T0)
	controller.device_clock_offline = false
	var config: CloudConfig = CloudConfig.new(URL, KEY)
	var auth: SupabaseAuth = SupabaseAuth.new(
		config, transport, dir_path.path_join("auth.json"), func() -> int: return T0
	)
	sync = CloudSync.new(session, controller, CloudSaveClient.new(config, transport, auth))
	transport.queue(200, {"access_token": "a1", "refresh_token": "r1", "expires_in": 3600, "user": {"id": "u1"}})
	await auth.ensure_session()


func after_each() -> void:
	for file_name: String in DirAccess.get_files_at(dir_path):
		DirAccess.remove_absolute(dir_path.path_join(file_name))
	DirAccess.remove_absolute(dir_path)


func _save(stage: int, ascensions: int = 0, attack_level: int = 0) -> SaveData:
	var data: SaveData = SaveData.new()
	data.stage = stage
	data.gold = BigNumber.from_float(100.0)
	data.attack_level = attack_level
	data.ascension_count = ascensions
	data.last_seen_unix = T0
	return data


func _boot_local(data: SaveData) -> void:
	store.write(data)
	controller.boot()


func _queue_pull(data: SaveData, last_seen: int, server_now: int) -> void:
	var save: Variant = null if data == null else JSON.parse_string(SaveCodec.encode(data))
	transport.queue(200, {"save": save, "last_seen_unix": last_seen if data != null else null, "server_now_unix": server_now})


func _rpc_requests(function_name: String) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for request: Dictionary in transport.requests:
		if (request["url"] as String).ends_with("/rpc/" + function_name):
			found.append(request)
	return found


func _pushed_stage() -> int:
	return int((transport.last_json() as Dictionary)["save"]["stage"])


func _gold() -> BigNumber:
	return session.wallet.get_amount(GameSession.GOLD)


func test_compare_progress_orders_by_ascensions_then_stage_then_levels() -> void:
	assert_eq(CloudSync.compare_progress(_save(5, 1), _save(40, 0)), 1)
	assert_eq(CloudSync.compare_progress(_save(10), _save(12)), -1)
	assert_eq(CloudSync.compare_progress(_save(10, 0, 3), _save(10, 0, 2)), 1)
	var rate_levels: SaveData = _save(10)
	rate_levels.crit_chance_level = 1
	rate_levels.attack_speed_level = 1
	assert_eq(CloudSync.compare_progress(rate_levels, _save(10, 0, 1)), 1)
	assert_eq(CloudSync.compare_progress(_save(10, 0, 2), _save(10, 0, 2)), 0)


func test_a_cloud_save_ahead_replaces_the_session_and_pays_server_time() -> void:
	_boot_local(_save(3))
	_queue_pull(_save(9, 0, 4), T0 - HOUR, T0)
	transport.queue(200, {"server_now_unix": T0})
	watch_signals(sync)
	var reward: OfflineReward = await sync.boot()
	assert_eq(session.progression.stage, 9)
	assert_eq(session.to_save(0).attack_level, 4)
	assert_eq(reward.elapsed_seconds, HOUR)
	assert_true(_gold().is_equal_approx(BigNumber.from_float(100.0).add(reward.amounts[GameSession.GOLD])))
	assert_signal_emitted_with_parameters(sync, "offline_reward_granted", [reward])
	assert_eq(_pushed_stage(), 9, "the applied session is pushed back")
	assert_eq(store.load_save().data.stage, 9, "the local save follows the cloud")


func test_a_tie_goes_to_the_cloud_and_pays_server_time() -> void:
	var local: SaveData = _save(9, 0, 4)
	local.gold = BigNumber.from_float(5.0)
	_boot_local(local)
	_queue_pull(_save(9, 0, 4), T0 - 120, T0)
	transport.queue(200, {"server_now_unix": T0})
	var reward: OfflineReward = await sync.boot()
	assert_eq(reward.elapsed_seconds, 120)
	assert_true(_gold().is_equal_approx(BigNumber.from_float(100.0).add(reward.amounts[GameSession.GOLD])))


func test_offline_time_from_the_server_is_capped_at_eight_hours() -> void:
	_boot_local(_save(3))
	_queue_pull(_save(3), T0 - 20 * HOUR, T0)
	transport.queue(200, {"server_now_unix": T0})
	var reward: OfflineReward = await sync.boot()
	assert_eq(reward.elapsed_seconds, GameSession.OFFLINE_CAP_SECONDS)


func test_the_device_clock_never_sets_the_offline_time() -> void:
	var local: SaveData = _save(3)
	local.last_seen_unix = T0 - 8 * HOUR
	_boot_local(local)
	_queue_pull(_save(3), T0 - 60, T0 + 60)
	transport.queue(200, {"server_now_unix": T0 + 60})
	var reward: OfflineReward = await sync.boot()
	assert_eq(reward.elapsed_seconds, 120)


func test_a_local_save_ahead_is_kept_pushed_and_pays_nothing() -> void:
	_boot_local(_save(12))
	_queue_pull(_save(9), T0 - HOUR, T0)
	transport.queue(200, {"server_now_unix": T0})
	watch_signals(sync)
	var reward: OfflineReward = await sync.boot()
	assert_true(reward.is_empty())
	assert_signal_not_emitted(sync, "offline_reward_granted")
	assert_eq(session.progression.stage, 12)
	assert_true(_gold().is_equal_approx(BigNumber.from_float(100.0)))
	assert_eq(_pushed_stage(), 12)


func test_no_cloud_save_pushes_the_local_one_and_pays_nothing() -> void:
	_boot_local(_save(4))
	_queue_pull(null, -1, T0)
	transport.queue(200, {"server_now_unix": T0})
	var reward: OfflineReward = await sync.boot()
	assert_true(reward.is_empty())
	assert_eq(session.progression.stage, 4)
	assert_eq(_pushed_stage(), 4)


func test_an_unreachable_cloud_keeps_the_local_game_and_pays_nothing() -> void:
	_boot_local(_save(4))
	var reward: OfflineReward = await sync.boot()
	assert_true(reward.is_empty())
	assert_eq(session.progression.stage, 4)
	assert_true(_gold().is_equal_approx(BigNumber.from_float(100.0)))
	assert_eq(_rpc_requests("push_save").size(), 0)
	assert_eq(store.load_save().data.stage, 4)


func test_a_rejected_cloud_save_is_not_applied_nor_overwritten() -> void:
	_boot_local(_save(4))
	transport.queue(200, {"save": {"version": 99}, "last_seen_unix": T0, "server_now_unix": T0})
	var reward: OfflineReward = await sync.boot()
	assert_true(reward.is_empty())
	assert_eq(session.progression.stage, 4)
	assert_eq(_rpc_requests("push_save").size(), 0)


func test_tick_pushes_every_sixty_seconds() -> void:
	_boot_local(_save(4))
	sync.tick(59.0)
	assert_eq(_rpc_requests("push_save").size(), 0)
	transport.queue(200, {"server_now_unix": T0})
	sync.tick(1.0)
	await wait_process_frames(1)
	assert_eq(_rpc_requests("push_save").size(), 1)
	sync.tick(59.0)
	assert_eq(_rpc_requests("push_save").size(), 1)


func test_suspend_pushes_the_session() -> void:
	_boot_local(_save(6))
	transport.queue(200, {"server_now_unix": T0})
	await sync.suspend()
	assert_eq(_rpc_requests("push_save").size(), 1)
	assert_eq(_pushed_stage(), 6)


func test_resume_pays_the_suspended_time_from_the_server() -> void:
	_boot_local(_save(6))
	_queue_pull(_save(6), T0, T0 + HOUR)
	transport.queue(200, {"server_now_unix": T0 + HOUR})
	watch_signals(sync)
	var reward: OfflineReward = await sync.resume()
	assert_eq(reward.elapsed_seconds, HOUR)
	assert_signal_emitted_with_parameters(sync, "offline_reward_granted", [reward])
	assert_eq(_pushed_stage(), 6)


func test_resume_pays_nothing_when_the_cloud_missed_the_suspend_push() -> void:
	_boot_local(_save(6))
	_queue_pull(_save(5), T0 - 5 * HOUR, T0 + HOUR)
	transport.queue(200, {"server_now_unix": T0 + HOUR})
	var reward: OfflineReward = await sync.resume()
	assert_true(reward.is_empty())
	assert_eq(session.progression.stage, 6, "resume never rolls the session back")
	assert_eq(_pushed_stage(), 6)


func test_resume_while_unreachable_pays_nothing() -> void:
	_boot_local(_save(6))
	var reward: OfflineReward = await sync.resume()
	assert_true(reward.is_empty())
