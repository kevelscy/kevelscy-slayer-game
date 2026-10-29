extends Node
## Owns the running GameSession and its save lifecycle. Offline income is paid
## when the game boots and when a mobile app returns from the background; no
## work runs while the app is suspended.

signal offline_reward_granted(reward: OfflineReward)

const STAGE_BALANCE: StageBalance = preload("res://data/content/balance/stage_balance.tres")
const ABILITIES: AbilityCatalog = preload("res://data/content/abilities/ability_catalog.tres")
const TALENTS: TalentCatalog = preload("res://data/content/talents/talent_catalog.tres")
const SAVE_PATH_ARG_PREFIX: String = "--save-path="

var session: GameSession = GameSession.new(STAGE_BALANCE, 10, 30.0, ABILITIES, TALENTS)
var saves: SaveController
## Reward paid on boot, kept until the main screen can show it.
var boot_reward: OfflineReward


func _ready() -> void:
	saves = SaveController.new(session, SaveStore.new(_save_path()), _device_clock)
	saves.offline_reward_granted.connect(offline_reward_granted.emit)
	boot_reward = saves.boot()


## Every clean exit (window close, quit(), --quit-after) frees the tree, so this
## also covers quits that never send a close request.
func _exit_tree() -> void:
	if saves != null:
		saves.save_now()


func _process(delta: float) -> void:
	saves.tick(delta)


func _notification(what: int) -> void:
	if saves == null:
		return
	match what:
		NOTIFICATION_APPLICATION_PAUSED:
			saves.suspend()
		NOTIFICATION_APPLICATION_RESUMED:
			saves.resume()
		# Desktop keeps simulating without focus, so focus loss only saves.
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			saves.save_now()


## Device clock for now; the server slice swaps this for validated time.
static func _device_clock() -> int:
	return int(Time.get_unix_time_from_system())


## Dev hook: `-- --save-path=<path>` points soak and playtest runs at a scratch save.
static func _save_path() -> String:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with(SAVE_PATH_ARG_PREFIX):
			return arg.trim_prefix(SAVE_PATH_ARG_PREFIX)
	return SaveStore.DEFAULT_PATH
