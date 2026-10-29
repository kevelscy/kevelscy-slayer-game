extends Node
## Owns the running GameSession and its save lifecycle. Offline income is paid
## when the game boots and when a mobile app returns from the background; no
## work runs while the app is suspended.
##
## With the cloud on (the default) the local save still loads first, then
## CloudSync pulls the cloud save and pays offline time from the server clock;
## the device clock never pays offline time. `-- --no-cloud`, GUT runs and
## `--import` runs keep the local-only, device-clock behaviour. GUT and `--import`
## runs (scripts/test.sh) also never touch the player's save: without
## `--save-path` they start from an empty scratch save.

signal offline_reward_granted(reward: OfflineReward)

const STAGE_BALANCE: StageBalance = preload("res://data/content/balance/stage_balance.tres")
const ABILITIES: AbilityCatalog = preload("res://data/content/abilities/ability_catalog.tres")
const TALENTS: TalentCatalog = preload("res://data/content/talents/talent_catalog.tres")
const SAVE_PATH_ARG_PREFIX: String = "--save-path="
const NO_CLOUD_ARG: String = "--no-cloud"
const GUT_RUNNER: String = "gut_cmdln.gd"
const IMPORT_ARG: String = "--import"
const AUTH_FILE: String = "auth.json"
const TOOL_RUN_SAVE_PATH: String = "user://tool_run/save.json"
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
	var save_path: String = save_path_for(OS.get_cmdline_args(), OS.get_cmdline_user_args())
	var load_existing: bool = prepare_save(save_path, OS.get_cmdline_args(), OS.get_cmdline_user_args())
	saves = SaveController.new(session, SaveStore.new(save_path), _device_clock)
	saves.offline_reward_granted.connect(offline_reward_granted.emit)
	var cloud_on: bool = cloud_enabled(OS.get_cmdline_args(), OS.get_cmdline_user_args())
	saves.device_clock_offline = not cloud_on
	if load_existing:
		boot_reward = saves.boot()
	else:
		saves.start_new_game()
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


## Saves, gives the cloud a bounded chance to store the final state (after any
## push already in flight), then quits.
## A request cannot finish once the tree is gone, so this runs before quitting.
func close_game() -> void:
	saves.save_now()
	if cloud != null:
		var finished: Array[bool] = [false]
		var flush_then_flag: Callable = func() -> void:
			await cloud.flush()
			finished[0] = true
		flush_then_flag.call()
		var deadline: int = Time.get_ticks_msec() + int(CLOSE_PUSH_TIMEOUT_SECONDS * 1000.0)
		while not finished[0] and Time.get_ticks_msec() < deadline:
			await get_tree().process_frame
	quit_game.call()


static func cloud_enabled(args: PackedStringArray, user_args: PackedStringArray) -> bool:
	return not user_args.has(NO_CLOUD_ARG) and not _is_tool_run(args)


## GUT and `--import` runs are tools, not play sessions.
static func _is_tool_run(args: PackedStringArray) -> bool:
	if args.has(IMPORT_ARG):
		return true
	for arg: String in args:
		if arg.ends_with(GUT_RUNNER):
			return true
	return false


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


## Dev hook: `-- --save-path=<path>` points soak and playtest runs at a scratch
## save. Tool runs without it get their own scratch save.
static func save_path_for(args: PackedStringArray, user_args: PackedStringArray) -> String:
	var explicit_path: String = _explicit_save_path(user_args)
	if not explicit_path.is_empty():
		return explicit_path
	return TOOL_RUN_SAVE_PATH if _is_tool_run(args) else SaveStore.DEFAULT_PATH


## Only the scratch save a tool run falls back to is cleared at boot; a path
## given with `--save-path` belongs to the caller and is never deleted.
static func clears_scratch_save(args: PackedStringArray, user_args: PackedStringArray) -> bool:
	return _is_tool_run(args) and _explicit_save_path(user_args).is_empty()


## Clears a tool run's scratch save and tells whether the run may load the save
## at `save_path`. A scratch save that cannot be cleared is reported and not
## loaded, so the run starts a new game instead of the previous run's.
static func prepare_save(save_path: String, args: PackedStringArray, user_args: PackedStringArray) -> bool:
	if not clears_scratch_save(args, user_args):
		return true
	var cleared: Error = clear_save(save_path)
	if cleared == OK:
		return true
	push_error(
		"GameState: could not clear the scratch save '%s' (%s); starting a new game"
		% [save_path, error_string(cleared)]
	)
	return false


## Deletes the save at `path` (creating its folder), so the run starts a new
## game. A failure is returned rather than silently loading an earlier run.
static func clear_save(path: String) -> Error:
	var made: Error = DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if made != OK:
		return made
	if not FileAccess.file_exists(path):
		return OK
	return DirAccess.remove_absolute(path)


static func _explicit_save_path(user_args: PackedStringArray) -> String:
	for arg: String in user_args:
		if arg.begins_with(SAVE_PATH_ARG_PREFIX):
			return arg.trim_prefix(SAVE_PATH_ARG_PREFIX)
	return ""
