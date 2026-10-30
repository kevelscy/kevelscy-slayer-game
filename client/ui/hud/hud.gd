class_name Hud
extends VBoxContainer
## Stage, gold, kill/boss progress and hero health. Refreshed at 10 Hz instead of
## every frame to keep string formatting cheap on mobile.

signal sfx_muted_toggled(muted: bool)

const REFRESH_SECONDS: float = 0.1
const SOUND_ON_ICON: String = "res://art/icons/sound_on.png"
const SOUND_OFF_ICON: String = "res://art/icons/sound_off.png"

var _session: GameSession
var _hero: Hero
var _elapsed: float = 0.0

@onready var stage_label: Label = $TopRow/StageLabel
@onready var gold_label: Label = $TopRow/GoldLabel
@onready var ascension_button: Button = $TopRow/AscensionButton
@onready var sound_button: Button = $TopRow/SoundButton
@onready var progress_bar: ProgressBar = $ProgressRow/ProgressBar
@onready var progress_label: Label = $ProgressRow/ProgressLabel
@onready var hero_health_bar: ProgressBar = $HeroHealth


func _ready() -> void:
	sound_button.toggled.connect(_on_sound_toggled)
	_refresh_sound_button()


func bind(session: GameSession, hero: Hero) -> void:
	_session = session
	_hero = hero
	_refresh()


## Shows the sound effects state without emitting sfx_muted_toggled.
func show_sfx_muted(muted: bool) -> void:
	sound_button.set_pressed_no_signal(muted)
	_refresh_sound_button()


func _on_sound_toggled(muted: bool) -> void:
	_refresh_sound_button()
	sfx_muted_toggled.emit(muted)


## The pressed button means muted: speaker with a cross; else speaker with waves.
func _refresh_sound_button() -> void:
	var muted: bool = sound_button.button_pressed
	sound_button.icon = BottomTabBar.icon_texture(SOUND_OFF_ICON if muted else SOUND_ON_ICON)
	sound_button.tooltip_text = "Activar efectos" if muted else "Silenciar efectos"


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed < REFRESH_SECONDS:
		return
	_elapsed = 0.0
	_refresh()


func _refresh() -> void:
	if _session == null:
		return
	var progression: StageProgression = _session.progression
	stage_label.text = "Etapa %d" % progression.stage
	gold_label.text = "Oro %s" % NumberFormat.format(_session.wallet.get_amount(GameSession.GOLD))
	if progression.is_boss_active:
		progress_bar.max_value = progression.boss_seconds
		progress_bar.value = progression.boss_time_left
		progress_label.text = "JEFE %ss" % NumberFormat.decimal(progression.boss_time_left, 1)
	else:
		progress_bar.max_value = progression.kills_per_stage
		progress_bar.value = progression.kills
		progress_label.text = "%d / %d" % [progression.kills, progression.kills_per_stage]
	hero_health_bar.value = _hero.health.get_ratio() * 100.0
