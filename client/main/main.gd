class_name Main
extends Control
## Root screen: moves the battle view, HUD, upgrade, ability and spirit panels between the
## portrait stack (mobile) and the three-column landscape layout (PC) as the window changes.
## The ascension panel is a full-screen overlay opened from the HUD in both layouts.

const DEV_REPORT_ARG: String = "--dev-report"
const SCREENSHOT_ARG_PREFIX: String = "--screenshot="
const ASCENSION_PANEL_ARG: String = "--ascension-panel"
const SCREENSHOT_DELAY_FRAMES: int = 120
const DEV_REPORT_SECONDS: float = 5.0
const TOAST_SECONDS: float = 4.0
const TAB_UPGRADES: int = 0
const TAB_SPIRITS: int = 1
const TAB_ASCENSION: int = 2
const TAB_TITLES: PackedStringArray = ["Upgrades", "Spirits", "Ascension"]

var _landscape: bool = false
var _layout_applied: bool = false
var _dev_report: bool = false
var _screenshot_path: String = ""
var _open_ascension: bool = false
var _frames: int = 0
var _report_elapsed: float = 0.0
var _toast_tween: Tween
## The page tab shown in portrait; Ascension is an overlay, never a page.
var _page: int = TAB_UPGRADES

@onready var safe_area: MarginContainer = $SafeArea
@onready var portrait: VBoxContainer = $SafeArea/Portrait
@onready var landscape_root: HBoxContainer = $SafeArea/Landscape
@onready var left_column: VBoxContainer = $SafeArea/Landscape/LeftColumn
@onready var center_column: VBoxContainer = $SafeArea/Landscape/CenterColumn
@onready var right_column: PanelContainer = $SafeArea/Landscape/RightColumn
@onready var battle_view: SubViewportContainer = $SafeArea/Portrait/BattleView
@onready var battle_world: BattleWorld = $SafeArea/Portrait/BattleView/SubViewport/BattleWorld
@onready var hud: Hud = $SafeArea/Portrait/Hud
@onready var ability_panel: AbilityPanel = $SafeArea/Portrait/AbilityPanel
@onready var pages: ScrollContainer = $SafeArea/Portrait/Pages
@onready var page_stack: VBoxContainer = $SafeArea/Portrait/Pages/PageStack
@onready var upgrade_panel: UpgradePanel = $SafeArea/Portrait/Pages/PageStack/UpgradePanel
@onready var spirit_panel: SpiritPanel = $SafeArea/Portrait/Pages/PageStack/SpiritPanel
@onready var tab_bar: BottomTabBar = $SafeArea/Portrait/TabBar
@onready var ascension_panel: AscensionPanel = $AscensionPanel
@onready var toast: PanelContainer = $Toast
@onready var toast_label: Label = $Toast/Label


func _ready() -> void:
	theme = GameTheme.build()
	_read_dev_args()
	var session: GameSession = GameState.session
	battle_world.start(session)
	hud.bind(session, battle_world.hero)
	upgrade_panel.bind(session)
	ability_panel.bind(session)
	spirit_panel.bind(session)
	ascension_panel.bind(session)
	hud.ascension_button.pressed.connect(ascension_panel.open)
	tab_bar.setup(TAB_TITLES, TAB_UPGRADES)
	tab_bar.tab_selected.connect(_on_tab_selected)
	if _open_ascension:
		ascension_panel.open()
	get_viewport().size_changed.connect(_apply_layout)
	_apply_layout()
	GameState.offline_reward_granted.connect(_show_offline_reward)
	if GameState.boot_reward != null and not GameState.boot_reward.is_empty():
		_show_offline_reward(GameState.boot_reward)


func _show_offline_reward(reward: OfflineReward) -> void:
	var gold: BigNumber = reward.amounts.get(GameSession.GOLD, BigNumber.zero())
	toast_label.text = "Welcome back!\n+%s gold (%s away)" % [
		NumberFormat.format(gold), _format_duration(reward.elapsed_seconds)
	]
	# A new reward restarts the toast; the previous fade must not hide it early.
	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()
	toast.visible = true
	toast.modulate.a = 1.0
	_toast_tween = create_tween()
	_toast_tween.tween_interval(TOAST_SECONDS)
	_toast_tween.tween_property(toast, "modulate:a", 0.0, 0.5)
	_toast_tween.tween_callback(toast.hide)
	if _dev_report:
		print("[dev] offline reward: %s" % toast_label.text.replace("\n", " "))


static func _format_duration(seconds: int) -> String:
	var hours: int = seconds / 3600
	var minutes: int = (seconds % 3600) / 60
	if hours > 0:
		return "%dh %02dm" % [hours, minutes]
	return "%dm %02ds" % [minutes, seconds % 60]


func _process(delta: float) -> void:
	_frames += 1
	if _dev_report:
		_report_elapsed += delta
		if _report_elapsed >= DEV_REPORT_SECONDS:
			_report_elapsed = 0.0
			_print_report()
	if not _screenshot_path.is_empty() and _frames == SCREENSHOT_DELAY_FRAMES:
		_save_screenshot()


func _apply_layout() -> void:
	var screen_size: Vector2 = get_viewport_rect().size
	_apply_safe_area(screen_size)
	var landscape: bool = LayoutRules.is_landscape(screen_size)
	if not _layout_applied or landscape != _landscape:
		_landscape = landscape
		_layout_applied = true
		_reparent_panels()
	var factor: int = LayoutRules.battle_scale(screen_size, _landscape)
	battle_view.stretch_shrink = factor
	battle_view.custom_minimum_size = Vector2(LayoutRules.BATTLE_SIZE * factor)


func _reparent_panels() -> void:
	portrait.visible = not _landscape
	landscape_root.visible = _landscape
	hud.ascension_button.visible = _landscape
	if _landscape:
		hud.reparent(center_column, false)
		battle_view.reparent(center_column, false)
		ability_panel.reparent(left_column, false)
		spirit_panel.reparent(left_column, false)
		upgrade_panel.reparent(right_column, false)
	else:
		hud.reparent(portrait, false)
		battle_view.reparent(portrait, false)
		ability_panel.reparent(portrait, false)
		upgrade_panel.reparent(page_stack, false)
		spirit_panel.reparent(page_stack, false)
		# Pages and the tab bar end the portrait stack, below the moved panels.
		portrait.move_child(pages, -1)
		portrait.move_child(tab_bar, -1)
	_show_page()


func _on_tab_selected(index: int) -> void:
	if index == TAB_ASCENSION:
		ascension_panel.open()
		tab_bar.select(_page, false)
		return
	_page = index
	_show_page()
	pages.scroll_vertical = 0


## Portrait shows only the picked page; landscape shows both panels in their columns.
func _show_page() -> void:
	upgrade_panel.visible = _landscape or _page == TAB_UPGRADES
	spirit_panel.visible = _landscape or _page == TAB_SPIRITS


## Mobile notches: convert the display safe area from window pixels to canvas units.
func _apply_safe_area(screen_size: Vector2) -> void:
	if not OS.has_feature("mobile"):
		return
	var window_size: Vector2 = Vector2(DisplayServer.window_get_size())
	if window_size.x <= 0.0 or window_size.y <= 0.0:
		return
	var to_canvas: Vector2 = screen_size / window_size
	var safe: Rect2 = Rect2(DisplayServer.get_display_safe_area())
	safe_area.add_theme_constant_override("margin_left", int(safe.position.x * to_canvas.x))
	safe_area.add_theme_constant_override("margin_top", int(safe.position.y * to_canvas.y))
	safe_area.add_theme_constant_override("margin_right", int((window_size.x - safe.end.x) * to_canvas.x))
	safe_area.add_theme_constant_override("margin_bottom", int((window_size.y - safe.end.y) * to_canvas.y))


## Dev hooks read only from user args after `--`, so a normal launch never enables them.
func _read_dev_args() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg == DEV_REPORT_ARG:
			_dev_report = true
		elif arg == ASCENSION_PANEL_ARG:
			_open_ascension = true
		elif arg.begins_with(SCREENSHOT_ARG_PREFIX):
			_screenshot_path = arg.trim_prefix(SCREENSHOT_ARG_PREFIX)


func _print_report() -> void:
	var session: GameSession = GameState.session
	print("[dev] stage=%d kills=%d gold=%s boss=%s" % [
		session.progression.stage,
		session.progression.kills,
		NumberFormat.format(session.wallet.get_amount(GameSession.GOLD)),
		session.progression.is_boss_active,
	])


func _save_screenshot() -> void:
	var image: Image = get_viewport().get_texture().get_image()
	var error: Error = image.save_png(_screenshot_path)
	if error != OK:
		push_error("Main: could not save screenshot to '%s' (%s)" % [_screenshot_path, error_string(error)])
	else:
		print("[dev] screenshot saved to %s" % _screenshot_path)
	get_tree().quit()
