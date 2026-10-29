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
var client: CloudSaveClient
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
	client = CloudSaveClient.new(config, transport, auth)
	sync = CloudSync.new(session, controller, client, dir_path.path_join("cloud_sync.json"))
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


## Boots on an empty cloud so the boot push is acknowledged at server_now.
func _boot_synced(data: SaveData, server_now: int = T0) -> void:
	_boot_local(data)
	_queue_pull(null, -1, server_now)
	transport.queue(200, {"server_now_unix": server_now})
	await sync.boot()


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


func test_compare_progress_orders_by_ascensions_stage_levels_talents_then_gold() -> void:
	assert_eq(CloudSync.compare_progress(_save(5, 1), _save(40, 0)), 1)
	assert_eq(CloudSync.compare_progress(_save(10), _save(12)), -1)
	assert_eq(CloudSync.compare_progress(_save(10, 0, 3), _save(10, 0, 2)), 1)
	var rate_levels: SaveData = _save(10)
	rate_levels.crit_chance_level = 1
	rate_levels.attack_speed_level = 1
	assert_eq(CloudSync.compare_progress(rate_levels, _save(10, 0, 1)), 1)
	var talented: SaveData = _save(10, 0, 2)
	talented.talents = {"might": 1}
	assert_eq(CloudSync.compare_progress(talented, _save(10, 0, 2)), 1, "talent levels after upgrade levels")
	var richer: SaveData = _save(10, 0, 2)
	richer.gold = BigNumber.from_float(101.0)
	assert_eq(CloudSync.compare_progress(richer, _save(10, 0, 2)), 1, "gold last")
	assert_eq(CloudSync.compare_progress(_save(10, 0, 2), richer), -1)
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
	await _boot_synced(_save(4))
	sync.tick(59.0)
	assert_eq(_rpc_requests("push_save").size(), 1)
	transport.queue(200, {"server_now_unix": T0})
	sync.tick(1.0)
	await wait_process_frames(1)
	assert_eq(_rpc_requests("push_save").size(), 2)
	sync.tick(59.0)
	assert_eq(_rpc_requests("push_save").size(), 2)


func test_nothing_is_pushed_before_a_successful_boot_sync() -> void:
	_boot_local(_save(4))
	var before_boot: CloudPushResult = await sync.push()
	await sync.boot()
	var after_failed_boot: CloudPushResult = await sync.push()
	for result: CloudPushResult in [before_boot, after_failed_boot]:
		assert_false(result.ok)
		assert_eq(result.error, "cloud not synced yet")
	assert_eq(_rpc_requests("push_save").size(), 0)
	assert_eq(_rpc_requests("pull_save").size(), 1, "only the boot pull was sent")


func test_tick_retries_the_boot_sync_instead_of_pushing() -> void:
	_boot_local(_save(4))
	await sync.boot()
	_queue_pull(_save(9), T0 - HOUR, T0)
	transport.queue(200, {"server_now_unix": T0})
	watch_signals(sync)
	sync.tick(60.0)
	await wait_process_frames(1)
	assert_eq(session.progression.stage, 9, "the cloud ahead is applied, not overwritten")
	assert_eq(_rpc_requests("pull_save").size(), 2)
	assert_eq(_rpc_requests("push_save").size(), 1)
	assert_eq(_pushed_stage(), 9)
	assert_signal_emitted(sync, "offline_reward_granted")
	sync.tick(60.0)
	await wait_process_frames(1)
	assert_eq(_rpc_requests("pull_save").size(), 2, "once synced, ticks push")
	assert_eq(_rpc_requests("push_save").size(), 2)


## The live session round-tripped through the codec: equal progress, gold included.
func _tied_cloud() -> SaveData:
	return SaveCodec.decode(SaveCodec.encode(session.to_save(T0))).data


func test_the_boot_sync_gives_an_exact_tie_to_the_cloud() -> void:
	_boot_local(_save(6))
	_queue_pull(_tied_cloud(), T0 - HOUR, T0)
	transport.queue(200, {"server_now_unix": T0})
	watch_signals(session)
	await sync.boot()
	assert_signal_emitted(session, "save_applied")


func test_the_boot_sync_keeps_the_session_on_a_tie_once_play_ran_during_the_pull() -> void:
	_boot_local(_save(6))
	_queue_pull(_tied_cloud(), T0 - HOUR, T0)
	transport.queue(200, {"server_now_unix": T0})
	transport.hold()
	watch_signals(session)
	var booted: Array[bool] = [false]
	var boot_then_flag: Callable = func() -> void:
		await sync.boot()
		booted[0] = true
	boot_then_flag.call()
	sync.tick(2.0)
	transport.release()
	await wait_process_frames(2)
	assert_true(booted[0])
	assert_signal_not_emitted(session, "save_applied", "a slow pull never restarts the running game")
	assert_eq(_rpc_requests("push_save").size(), 1, "the kept session is pushed")
	assert_eq(_pushed_stage(), 6)


func test_the_boot_sync_still_gives_a_tie_to_the_cloud_after_a_short_pull() -> void:
	_boot_local(_save(6))
	_queue_pull(_tied_cloud(), T0 - HOUR, T0)
	transport.queue(200, {"server_now_unix": T0})
	transport.hold()
	watch_signals(session)
	sync.boot()
	sync.tick(1.9)
	transport.release()
	await wait_process_frames(2)
	assert_signal_emitted(session, "save_applied")


func test_a_timer_retry_keeps_the_running_session_on_a_tie() -> void:
	_boot_local(_save(6))
	await sync.boot()
	_queue_pull(_tied_cloud(), T0 - HOUR, T0)
	transport.queue(200, {"server_now_unix": T0})
	watch_signals(session)
	watch_signals(sync)
	sync.tick(60.0)
	await wait_process_frames(1)
	assert_signal_not_emitted(session, "save_applied", "a tie never restarts the running game")
	assert_signal_not_emitted(sync, "offline_reward_granted", "another device's row pays nothing")
	assert_eq(_rpc_requests("pull_save").size(), 2)
	assert_eq(_rpc_requests("push_save").size(), 1, "the kept session is pushed")
	assert_eq(_pushed_stage(), 6)


func test_a_resume_before_the_first_sync_keeps_the_running_session_on_a_tie() -> void:
	_boot_local(_save(6))
	await sync.boot()
	_queue_pull(_tied_cloud(), T0 - HOUR, T0)
	transport.queue(200, {"server_now_unix": T0})
	watch_signals(session)
	var reward: OfflineReward = await sync.resume()
	assert_signal_not_emitted(session, "save_applied", "a tie never restarts the running game")
	assert_true(reward.is_empty())
	assert_eq(_rpc_requests("push_save").size(), 1, "the kept session is pushed")


func test_a_sync_requested_while_one_is_in_flight_returns_its_reward() -> void:
	_boot_local(_save(4))
	await sync.boot()
	_queue_pull(_save(9), T0 - HOUR, T0)
	transport.queue(200, {"server_now_unix": T0})
	transport.hold()
	watch_signals(sync)
	sync.tick(60.0)
	var rewards: Array[OfflineReward] = []
	var resume_then_keep: Callable = func() -> void:
		rewards.append(await sync.resume())
	resume_then_keep.call()
	await wait_process_frames(1)
	assert_eq(rewards.size(), 0, "the resume waits for the sync in flight")
	transport.release()
	await wait_process_frames(2)
	assert_eq(rewards.size(), 1)
	assert_eq(rewards[0].elapsed_seconds, HOUR, "the reward of the sync in flight")
	assert_signal_emit_count(sync, "offline_reward_granted", 1, "paid once")
	assert_eq(_rpc_requests("pull_save").size(), 2, "no second pull")
	assert_eq(session.progression.stage, 9)


func test_a_waiting_sync_gets_its_own_copy_of_the_reward() -> void:
	_boot_local(_save(4))
	await sync.boot()
	_queue_pull(_save(9), T0 - HOUR, T0)
	transport.queue(200, {"server_now_unix": T0})
	transport.hold()
	watch_signals(sync)
	var rewards: Array[OfflineReward] = []
	var resume_then_keep: Callable = func() -> void:
		rewards.append(await sync.resume())
	resume_then_keep.call()
	resume_then_keep.call()
	await wait_process_frames(1)
	transport.release()
	await wait_process_frames(2)
	assert_eq(rewards.size(), 2)
	assert_false(is_same(rewards[0], rewards[1]), "each caller owns its reward")
	assert_false(is_same(rewards[0].amounts, rewards[1].amounts), "amounts are not shared")
	assert_eq(rewards[1].elapsed_seconds, HOUR)
	assert_eq(rewards[1].amounts.keys(), rewards[0].amounts.keys())
	for key: StringName in rewards[0].amounts:
		assert_eq(rewards[1].amounts[key].serialize(), rewards[0].amounts[key].serialize())
	assert_signal_emit_count(sync, "offline_reward_granted", 1, "paid and announced once")


func test_a_resume_before_the_first_sync_runs_the_boot_sync() -> void:
	_boot_local(_save(4))
	await sync.boot()
	_queue_pull(_save(9), T0 - HOUR, T0)
	transport.queue(200, {"server_now_unix": T0})
	var reward: OfflineReward = await sync.resume()
	assert_eq(session.progression.stage, 9)
	assert_eq(reward.elapsed_seconds, HOUR)
	assert_eq(_pushed_stage(), 9)


func test_flush_waits_for_the_push_in_flight_then_pushes_the_current_session() -> void:
	await _boot_synced(_save(6))
	transport.hold()
	transport.queue(200, {"server_now_unix": T0 + 10})
	transport.queue(200, {"server_now_unix": T0 + 20})
	sync.push()
	session.wallet.restore(GameSession.GOLD, BigNumber.from_float(900.0))
	var done: Array[bool] = [false]
	var flush_then_flag: Callable = func() -> void:
		var result: CloudPushResult = await sync.flush()
		done[0] = result.ok
	flush_then_flag.call()
	await wait_process_frames(2)
	assert_false(done[0], "flush waits for the push in flight")
	assert_eq(_rpc_requests("push_save").size(), 2)
	transport.release()
	await wait_process_frames(2)
	assert_true(done[0])
	assert_eq(_rpc_requests("push_save").size(), 3)
	assert_eq((transport.last_json() as Dictionary)["save"]["gold"], BigNumber.from_float(900.0).serialize())


func test_suspend_keeps_the_marker_without_pushing() -> void:
	await _boot_synced(_save(6))
	sync.tick(30.0)
	sync.suspend()
	assert_eq(_rpc_requests("push_save").size(), 1, "requests cannot finish while suspended")
	var marker: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(dir_path.path_join("cloud_sync.json")))
	assert_eq(int(marker["acked_unix"]), T0)
	assert_almost_eq(float(marker["played_since_ack"]), 30.0, 0.001)


func test_resume_pays_the_suspended_time_from_the_server() -> void:
	await _boot_synced(_save(6))
	_queue_pull(_save(6), T0, T0 + HOUR)
	transport.queue(200, {"server_now_unix": T0 + HOUR})
	watch_signals(sync)
	var reward: OfflineReward = await sync.resume()
	assert_eq(reward.elapsed_seconds, HOUR)
	assert_signal_emitted_with_parameters(sync, "offline_reward_granted", [reward])
	assert_eq(_pushed_stage(), 6)


func test_play_while_the_resume_pull_is_in_flight_is_not_subtracted_from_the_reward() -> void:
	await _boot_synced(_save(6))
	sync.tick(40.0)
	_queue_pull(_save(6), T0, T0 + HOUR)
	transport.queue(500, {})
	transport.hold()
	var rewards: Array[OfflineReward] = []
	var resume_then_keep: Callable = func() -> void:
		rewards.append(await sync.resume())
	resume_then_keep.call()
	sync.tick(15.0)
	transport.release()
	await wait_process_frames(2)
	assert_eq(rewards.size(), 1)
	assert_eq(rewards[0].elapsed_seconds, HOUR - 40, "only the play before the pull is subtracted")
	var marker: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(dir_path.path_join("cloud_sync.json")))
	assert_almost_eq(
		float(marker["played_since_ack"]), float(HOUR + 15), 0.001, "the play during the pull still counts after the paid absence"
	)


func test_resume_subtracts_the_play_since_the_last_push() -> void:
	await _boot_synced(_save(6))
	sync.tick(40.0)
	session.wallet.restore(GameSession.GOLD, BigNumber.from_float(900.0))
	_queue_pull(_save(6), T0, T0 + HOUR)
	transport.queue(200, {"server_now_unix": T0 + HOUR})
	var reward: OfflineReward = await sync.resume()
	assert_eq(reward.elapsed_seconds, HOUR - 40, "gold earned after the push does not block the reward")


func test_play_while_pushes_fail_is_not_paid_as_offline_time() -> void:
	await _boot_synced(_save(6))
	sync.tick(60.0)
	sync.tick(60.0)
	await wait_process_frames(1)
	_queue_pull(_save(6), T0, T0 + HOUR)
	transport.queue(200, {"server_now_unix": T0 + HOUR})
	var reward: OfflineReward = await sync.resume()
	assert_eq(reward.elapsed_seconds, HOUR - 120)


func test_a_second_resume_pays_only_the_second_absence() -> void:
	await _boot_synced(_save(6))
	_queue_pull(_save(6), T0, T0 + HOUR)
	var first: OfflineReward = await sync.resume()
	assert_eq(first.elapsed_seconds, HOUR, "its push failed, so the cloud keeps the T0 row")
	sync.tick(50.0)
	_queue_pull(_save(6), T0, T0 + 3 * HOUR)
	var second: OfflineReward = await sync.resume()
	assert_eq(second.elapsed_seconds, 2 * HOUR - 50)


func test_boot_after_the_app_was_killed_pays_from_the_saved_marker() -> void:
	await _boot_synced(_save(6))
	sync.tick(25.0)
	sync.suspend()
	session.wallet.restore(GameSession.GOLD, BigNumber.from_float(900.0))
	controller.save_now()
	var relaunched: CloudSync = CloudSync.new(session, controller, client, dir_path.path_join("cloud_sync.json"))
	_queue_pull(_save(6), T0, T0 + HOUR)
	transport.queue(200, {"server_now_unix": T0 + HOUR})
	var reward: OfflineReward = await relaunched.boot()
	assert_eq(reward.elapsed_seconds, HOUR - 25)
	assert_true(_gold().is_equal_approx(BigNumber.from_float(900.0).add(reward.amounts[GameSession.GOLD])))


func test_resume_pays_nothing_when_another_push_replaced_the_cloud_row() -> void:
	await _boot_synced(_save(6))
	_queue_pull(_save(5), T0 + 60, T0 + HOUR)
	transport.queue(200, {"server_now_unix": T0 + HOUR})
	var reward: OfflineReward = await sync.resume()
	assert_true(reward.is_empty())
	assert_eq(session.progression.stage, 6, "resume never rolls the session back")
	assert_eq(_pushed_stage(), 6)


func test_resume_while_unreachable_pays_nothing() -> void:
	_boot_local(_save(6))
	var reward: OfflineReward = await sync.resume()
	assert_true(reward.is_empty())


func test_gold_earned_without_network_at_the_same_stage_is_kept() -> void:
	var local: SaveData = _save(4)
	local.gold = BigNumber.from_float(900.0)
	_boot_local(local)
	_queue_pull(_save(4), T0 - HOUR, T0)
	transport.queue(200, {"server_now_unix": T0})
	var reward: OfflineReward = await sync.boot()
	assert_true(reward.is_empty(), "the cloud last_seen predates the local play")
	assert_true(_gold().is_equal_approx(BigNumber.from_float(900.0)))
	assert_eq((transport.last_json() as Dictionary)["save"]["gold"], BigNumber.from_float(900.0).serialize())


func test_gold_that_only_differs_by_serialization_ties() -> void:
	var local: SaveData = _save(6)
	local.gold = BigNumber.from_float(27675.123456789)
	_boot_local(local)
	session.wallet.restore(GameSession.GOLD, BigNumber.from_float(27675.123456789))
	var cloud: SaveData = SaveCodec.decode(SaveCodec.encode(session.to_save(T0))).data
	assert_eq(CloudSync.compare_progress(cloud, session.to_save(T0)), 0)
