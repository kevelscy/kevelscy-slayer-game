class_name SaveController
extends RefCounted
## Save lifecycle of one GameSession: load and pay offline time on boot, save on
## suspend, pay the suspended time on resume, and autosave while playing.
##
## "Now" comes from an injected clock so a server-validated time can replace the
## device clock later without touching this flow.

signal offline_reward_granted(reward: OfflineReward)

const AUTOSAVE_SECONDS: float = 30.0

var session: GameSession
var store: SaveStore
## Pays offline time measured by the injected clock. CloudSync turns this off and
## pays offline time from the server clock instead.
var device_clock_offline: bool = true
var _clock: Callable
var _last_seen_unix: int = 0
var _autosave_elapsed: float = 0.0


func _init(game_session: GameSession, save_store: SaveStore, clock: Callable) -> void:
	session = game_session
	store = save_store
	_clock = clock


func boot() -> OfflineReward:
	var loaded: SaveLoadResult = store.load_save()
	var reward: OfflineReward = OfflineReward.new(0, {})
	match loaded.status:
		SaveLoadResult.Status.LOADED:
			session.apply_save(loaded.data)
			reward = _grant_since(loaded.data.last_seen_unix)
		SaveLoadResult.Status.REJECTED:
			push_error("SaveController: save rejected (%s); starting a new game" % loaded.error)
	save_now()
	return reward


func suspend() -> void:
	save_now()


func resume() -> OfflineReward:
	var reward: OfflineReward = _grant_since(_last_seen_unix)
	save_now()
	return reward


func tick(delta: float) -> void:
	_autosave_elapsed += delta
	if _autosave_elapsed >= AUTOSAVE_SECONDS:
		_autosave_elapsed = 0.0
		save_now()


func save_now() -> Error:
	_last_seen_unix = _now()
	_autosave_elapsed = 0.0
	var error: Error = store.write(session.to_save(_last_seen_unix))
	if error != OK:
		push_error("SaveController: could not write save (%s)" % error_string(error))
	return error


func _grant_since(last_seen_unix: int) -> OfflineReward:
	if not device_clock_offline:
		return OfflineReward.new(0, {})
	var reward: OfflineReward = session.grant_offline(last_seen_unix, _now())
	if not reward.is_empty():
		offline_reward_granted.emit(reward)
	return reward


func _now() -> int:
	return _clock.call() as int
