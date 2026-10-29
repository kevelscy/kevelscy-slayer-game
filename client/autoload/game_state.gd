extends Node
## Owns the running GameSession and its save lifecycle. Offline income is paid
## when the game boots and when a mobile app returns from the background; no
## work runs while the app is suspended.
##
## With the cloud on (the default) the local save still loads first, then
## CloudSync pulls the cloud save and pays offline time from the server clock;
## the device clock never pays offline time. `-- --no-cloud`, GUT runs and
## `--import` runs keep the local-only, device-clock behaviour.

signal offline_reward_granted(reward: OfflineReward)

const STAGE_BALANCE: StageBalance = preload("res://data/content/balance/stage_balance.tres")
const ABILITIES: AbilityCatalog = preload("res://data/content/abilities/ability_catalog.tres")
const TALENTS: TalentCatalog = preload("res://data/content/talents/talent_catalog.tres")
const SAVE_PATH_ARG_PREFIX: String = "--save-path="
const NO_CLOUD_ARG: String = "--no-cloud"
const GUT_RUNNER: String = "gut_cmdln.gd"
const IMPORT_ARG: String = "--import"
const AUTH_FILE: String = "auth.json"
const SYNC_MARKER_FILE: String = "cloud_sync.json"
## Project settings that point a build at a hosted project; the defaults are the
## local Supabase stack started from server/ (its publishable key is public).
const CLOUD_URL_SETTING: String = "cloud/url"
const CLOUD_KEY_SETTING: String = "cloud/api_key"
const LOCAL_CLOUD_URL: String = "http://127.0.0.1:54321"
const LOCAL_CLOUD_KEY: String = "sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH"
## How long closing the window waits for the last cloud push.
const CLOSE_PUSH_TIMEOUT_SECONDS: float = 3.0

var session: GameSession = GameSession.new(STAGE_BALANCE, 10, 30.0, ABILITIES, TALENTS)
var saves: SaveController
var cloud: CloudSync
## Reward paid on boot, kept until the main screen can show it.
var boot_reward: OfflineReward
var quit_game: Callable


func _init() -> void:
	quit_game = func() -> void: get_tree().quit()


func _ready() -> void:
	var save_path: String = _save_path()
	saves = SaveController.new(session, SaveStore.new(save_path), _device_clock)
	saves.offline_reward_granted.connect(offline_reward_granted.emit)
	var cloud_on: bool = cloud_enabled(OS.get_cmdline_args(), OS.get_cmdline_user_args())
	saves.device_clock_offline = not cloud_on
	boot_reward = saves.boot()
	if cloud_on:
		cloud = _make_cloud(save_path)
		cloud.offline_reward_granted.connect(offline_reward_granted.emit)
		get_tree().set_auto_accept_quit(false)
		cloud.boot()


## Every clean exit (window close, quit(), --quit-after) frees the tree, so this
## also covers quits that never send a close request.
func _exit_tree() -> void:
	if saves != null:
		saves.save_now()


func _process(delta: float) -> void:
	saves.tick(delta)
	if cloud != null:
		cloud.tick(delta)


func _notification(what: int) -> void:
	if saves == null:
		return
	match what:
		NOTIFICATION_APPLICATION_PAUSED:
			saves.suspend()
			if cloud != null:
				cloud.suspend()
		NOTIFICATION_APPLICATION_RESUMED:
			saves.resume()
			if cloud != null:
				cloud.resume()
		# Desktop keeps simulating without focus, so focus loss only saves.
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			saves.save_now()
			if cloud != null:
				cloud.push()
		# Only received with the cloud on, which turns off auto-accepted quits.
		NOTIFICATION_WM_CLOSE_REQUEST:
			close_game()


## Saves, gives the cloud a bounded chance to store the final state, then quits.
## A request cannot finish once the tree is gone, so this runs before quitting.
func close_game() -> void:
	saves.save_now()
	if cloud != null:
		var finished: Array[bool] = [false]
		var push_then_flag: Callable = func() -> void:
			await cloud.push()
			finished[0] = true
		push_then_flag.call()
		var deadline: int = Time.get_ticks_msec() + int(CLOSE_PUSH_TIMEOUT_SECONDS * 1000.0)
		while not finished[0] and Time.get_ticks_msec() < deadline:
			await get_tree().process_frame
	quit_game.call()


static func cloud_enabled(args: PackedStringArray, user_args: PackedStringArray) -> bool:
	if user_args.has(NO_CLOUD_ARG) or args.has(IMPORT_ARG):
		return false
	for arg: String in args:
		if arg.ends_with(GUT_RUNNER):
			return false
	return true


static func cloud_config() -> CloudConfig:
	return CloudConfig.new(
		str(ProjectSettings.get_setting(CLOUD_URL_SETTING, LOCAL_CLOUD_URL)),
		str(ProjectSettings.get_setting(CLOUD_KEY_SETTING, LOCAL_CLOUD_KEY))
	)


## The anonymous player belongs to the save next to it, so scratch saves get
## their own player.
static func auth_path(save_path: String) -> String:
	return save_path.get_base_dir().path_join(AUTH_FILE)


func _make_cloud(save_path: String) -> CloudSync:
	var config: CloudConfig = cloud_config()
	var transport: GodotHttpTransport = GodotHttpTransport.new(self)
	var auth: SupabaseAuth = SupabaseAuth.new(config, transport, auth_path(save_path), _device_clock)
	var marker_path: String = save_path.get_base_dir().path_join(SYNC_MARKER_FILE)
	return CloudSync.new(session, saves, CloudSaveClient.new(config, transport, auth), marker_path)


## Device clock: only for local saves and token expiry, never for cloud offline time.
static func _device_clock() -> int:
	return int(Time.get_unix_time_from_system())


## Dev hook: `-- --save-path=<path>` points soak and playtest runs at a scratch save.
static func _save_path() -> String:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with(SAVE_PATH_ARG_PREFIX):
			return arg.trim_prefix(SAVE_PATH_ARG_PREFIX)
	return SaveStore.DEFAULT_PATH
