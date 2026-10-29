class_name CloudSync
extends RefCounted
## Keeps the local game and the player's cloud save together, and pays offline
## time from the server clock only (the device clock is never trusted).
##
## The local save loads first so the game never waits on the network. On boot the
## save with more progress wins (ties go to the cloud). Offline gold is paid only
## when the cloud save holds the same progress as the session, because only then
## does its server-stamped last_seen mark when this session stopped playing.
## Without the cloud nothing is paid and play continues on the local save.

signal offline_reward_granted(reward: OfflineReward)

const PUSH_SECONDS: float = 60.0

var _session: GameSession
var _controller: SaveController
var _client: CloudSaveClient
var _push_elapsed: float = 0.0
var _pushing: bool = false


func _init(session: GameSession, controller: SaveController, client: CloudSaveClient) -> void:
	_session = session
	_controller = controller
	_client = client


## Compares progress: ascensions first, then stage, then the sum of upgrade levels.
static func compare_progress(a: SaveData, b: SaveData) -> int:
	var keys_a: Array[int] = [a.ascension_count, a.stage, _upgrade_levels(a)]
	var keys_b: Array[int] = [b.ascension_count, b.stage, _upgrade_levels(b)]
	for index: int in keys_a.size():
		if keys_a[index] != keys_b[index]:
			return 1 if keys_a[index] > keys_b[index] else -1
	return 0


func boot() -> OfflineReward:
	var pulled: CloudPullResult = await _client.pull()
	if not pulled.ok:
		push_warning("CloudSync: boot sync skipped (%s)" % pulled.error)
		return _nothing()
	var reward: OfflineReward = _nothing()
	if pulled.data != null and compare_progress(pulled.data, _local()) >= 0:
		_session.apply_save(pulled.data)
		_controller.save_now()
		reward = _grant(pulled)
	await push()
	return reward


func resume() -> OfflineReward:
	var pulled: CloudPullResult = await _client.pull()
	if not pulled.ok:
		push_warning("CloudSync: resume sync skipped (%s)" % pulled.error)
		return _nothing()
	var reward: OfflineReward = _nothing()
	if pulled.data != null and compare_progress(pulled.data, _local()) == 0:
		reward = _grant(pulled)
	await push()
	return reward


func suspend() -> void:
	await push()


func tick(delta: float) -> void:
	_push_elapsed += delta
	if _push_elapsed >= PUSH_SECONDS:
		push()


## Sends the session to the cloud; a push already in flight makes this a no-op.
func push() -> CloudPushResult:
	_push_elapsed = 0.0
	if _pushing:
		return CloudPushResult.new(false, 0, "push already in flight")
	_pushing = true
	var result: CloudPushResult = await _client.push(_local())
	_pushing = false
	if not result.ok:
		push_warning("CloudSync: push failed (%s)" % result.error)
	return result


func _grant(pulled: CloudPullResult) -> OfflineReward:
	var reward: OfflineReward = _session.grant_offline(pulled.last_seen_unix, pulled.server_now_unix)
	if not reward.is_empty():
		_controller.save_now()
		offline_reward_granted.emit(reward)
	return reward


func _local() -> SaveData:
	return _session.to_save(0)


static func _upgrade_levels(data: SaveData) -> int:
	return (
		data.attack_level + data.health_level + data.crit_chance_level
		+ data.crit_damage_level + data.attack_speed_level
	)


static func _nothing() -> OfflineReward:
	return OfflineReward.new(0, {})
