class_name CloudSync
extends RefCounted
## Keeps the local game and the player's cloud save together, and pays offline
## time from the server clock only (the device clock is never trusted).
##
## The local save loads first so the game never waits on the network. On boot the
## save with more progress wins (ties go to the cloud). Offline gold is paid while
## the cloud row is still this device's last confirmed push: its server-stamped
## last_seen plus the game time played since marks when play stopped. Requests
## cannot finish while the app is suspended, so the marker of that push survives
## a relaunch in a file. Without the cloud nothing is paid.
##
## Nothing is pushed until a sync has pulled the cloud: a device that booted
## offline could otherwise overwrite progress another device stored. Until then
## the push timer retries the sync instead.

signal offline_reward_granted(reward: OfflineReward)
signal _push_finished
signal _sync_finished(reward: OfflineReward)

const PUSH_SECONDS: float = 60.0
## Game time a boot pull may take and still give an exact tie to the cloud.
const BOOT_TIE_GRACE_SECONDS: float = 2.0

var _session: GameSession
var _controller: SaveController
var _client: CloudSaveClient
var _marker_path: String
var _push_elapsed: float = 0.0
var _pushing: bool = false
## True once a pull reached the cloud and the session was reconciled with it.
var _synced: bool = false
var _syncing: bool = false
## Server time of the last push the cloud confirmed; that row carries it as last_seen.
var _acked_unix: int = 0
## Game time played since that push's snapshot. Frames stop while suspended, so
## time away is never counted, and the device clock is never read.
var _played_since_ack: float = 0.0


func _init(
	session: GameSession, controller: SaveController, client: CloudSaveClient, marker_path: String = ""
) -> void:
	_session = session
	_controller = controller
	_client = client
	_marker_path = marker_path


## Compares progress: ascensions, stage, the sum of upgrade levels, the sum of
## talent levels, then gold, so gold or talents earned without network count.
static func compare_progress(a: SaveData, b: SaveData) -> int:
	var keys_a: Array[int] = [a.ascension_count, a.stage, _upgrade_levels(a), _talent_levels(a)]
	var keys_b: Array[int] = [b.ascension_count, b.stage, _upgrade_levels(b), _talent_levels(b)]
	for index: int in keys_a.size():
		if keys_a[index] != keys_b[index]:
			return 1 if keys_a[index] > keys_b[index] else -1
	# A pushed save carries gold rounded by serialize(); the same rounding on both
	# sides keeps a save equal to the session it came from.
	if a.gold.serialize() == b.gold.serialize():
		return 0
	return a.gold.compare(b.gold)


func boot() -> OfflineReward:
	_load_marker()
	return await _sync(true)


## Pulls the cloud, keeps the save with more progress, pays an owned row's
## offline time, then pushes the result. Only the boot sync gives a tie to the
## cloud: a retry runs mid-play, where applying an equal save would restart the
## running game (buffs, spirits and the battle) for no progress.
## The returned reward reports what the sync paid; it is paid and announced
## through offline_reward_granted once, whoever asked. Every caller returns once
## the sync has finished, its push included.
func _sync(cloud_wins_ties: bool) -> OfflineReward:
	if _syncing:
		# A resume during the timer retry shares that sync: one pull, one reward,
		# reported to this caller as its own copy. The wait ends with that sync,
		# whose requests each end within GodotHttpTransport.TIMEOUT_SECONDS.
		var shared: OfflineReward = await _sync_finished
		return OfflineReward.new(shared.elapsed_seconds, shared.amounts.duplicate())
	_syncing = true
	var reward: OfflineReward = await _pull_and_reconcile(cloud_wins_ties)
	if _synced:
		await push()
	_syncing = false
	_sync_finished.emit(reward)
	return reward


## The boot tie goes to the cloud only while less than BOOT_TIE_GRACE_SECONDS of
## game time ran during the pull; after that applying it would restart a game the
## player is already playing.
func _pull_and_reconcile(cloud_wins_ties: bool) -> OfflineReward:
	var played_at_pull: float = _played_since_ack
	var pulled: CloudPullResult = await _client.pull()
	if not pulled.ok:
		push_warning("CloudSync: sync skipped (%s)" % pulled.error)
		return _nothing()
	_synced = true
	var reward: OfflineReward = _nothing()
	var owned: bool = _owns(pulled)
	var played_during_pull: float = _played_since_ack - played_at_pull
	var ties_to_cloud: bool = cloud_wins_ties and played_during_pull < BOOT_TIE_GRACE_SECONDS
	var min_lead: int = 0 if ties_to_cloud else 1
	if pulled.data != null and compare_progress(pulled.data, _local()) >= min_lead:
		_session.apply_save(pulled.data)
		_controller.save_now()
		reward = _grant(pulled, owned, played_at_pull)
	elif owned:
		# The local save is ahead only by the play after this device's last push.
		reward = _grant(pulled, true, played_at_pull)
	return reward


func resume() -> OfflineReward:
	if not _synced:
		return await _sync(false)
	var played_at_pull: float = _played_since_ack
	var pulled: CloudPullResult = await _client.pull()
	if not pulled.ok:
		push_warning("CloudSync: resume sync skipped (%s)" % pulled.error)
		return _nothing()
	# Resume never rolls the session back; another device's row pays nothing.
	var reward: OfflineReward = _grant(pulled, true, played_at_pull) if _owns(pulled) else _nothing()
	await push()
	return reward


## Nothing reaches the server while suspended, so keep the marker for a relaunch.
func suspend() -> void:
	_save_marker()


func tick(delta: float) -> void:
	_played_since_ack += delta
	_push_elapsed += delta
	if _push_elapsed < PUSH_SECONDS:
		return
	if _synced:
		push()
	else:
		_push_elapsed = 0.0
		_sync(false)


## Sends the session to the cloud; a push already in flight makes this a no-op.
func push() -> CloudPushResult:
	_push_elapsed = 0.0
	if not _synced:
		return CloudPushResult.new(false, 0, "cloud not synced yet")
	if _pushing:
		return CloudPushResult.new(false, 0, "push already in flight")
	_pushing = true
	_save_marker()
	var played_at_send: float = _played_since_ack
	var result: CloudPushResult = await _client.push(_local())
	_pushing = false
	if result.ok:
		_acked_unix = result.server_now_unix
		_played_since_ack -= played_at_send
		_save_marker()
	else:
		push_warning("CloudSync: push failed (%s)" % result.error)
	_push_finished.emit()
	return result


## Waits for a push in flight, then pushes the current session, so the last
## state reaches the cloud even when a timer push was already sending.
func flush() -> CloudPushResult:
	while _pushing:
		await _push_finished
	return await push()


func _owns(pulled: CloudPullResult) -> bool:
	return pulled.data != null and _acked_unix > 0 and pulled.last_seen_unix == _acked_unix


## Pays from when play stopped: the row's last_seen, but never before this
## device's last acknowledged push plus the play before the pull was sent, so play
## here is never paid as time away (an owned row's last_seen is that push).
## An owned row then counts the time up to the server's now as accounted so a
## later resume pays only the next absence. Play while the pull was in flight
## happened after that now, so it is not subtracted here and still counts as play
## afterwards.
func _grant(pulled: CloudPullResult, owned: bool, played_at_pull: float) -> OfflineReward:
	var stopped_unix: int = pulled.last_seen_unix
	if _acked_unix > 0:
		stopped_unix = maxi(stopped_unix, _acked_unix + int(played_at_pull))
	var reward: OfflineReward = _session.grant_offline(stopped_unix, pulled.server_now_unix)
	if owned:
		var played_during_pull: float = _played_since_ack - played_at_pull
		var accounted: float = maxf(played_at_pull, float(pulled.server_now_unix - _acked_unix))
		_played_since_ack = accounted + played_during_pull
	if not reward.is_empty():
		_controller.save_now()
		offline_reward_granted.emit(reward)
	return reward


func _save_marker() -> void:
	if _marker_path.is_empty():
		return
	var file: FileAccess = FileAccess.open(_marker_path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"acked_unix": _acked_unix, "played_since_ack": _played_since_ack}))


func _load_marker() -> void:
	if _marker_path.is_empty() or not FileAccess.file_exists(_marker_path):
		return
	var json: JSON = JSON.new()
	if json.parse(FileAccess.get_file_as_string(_marker_path)) != OK or not json.data is Dictionary:
		return
	var marker: Dictionary = json.data
	if marker.get("acked_unix") is float and marker.get("played_since_ack") is float:
		_acked_unix = int(marker["acked_unix"])
		_played_since_ack = maxf(0.0, marker["played_since_ack"])


func _local() -> SaveData:
	return _session.to_save(0)


static func _upgrade_levels(data: SaveData) -> int:
	return (
		data.attack_level + data.health_level + data.crit_chance_level
		+ data.crit_damage_level + data.attack_speed_level
	)


static func _talent_levels(data: SaveData) -> int:
	var total: int = 0
	for level: int in data.talents.values():
		total += level
	return total


static func _nothing() -> OfflineReward:
	return OfflineReward.new(0, {})
