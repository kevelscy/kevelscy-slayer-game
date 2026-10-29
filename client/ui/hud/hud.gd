class_name Hud
extends VBoxContainer
## Stage, gold, kill/boss progress and hero health. Refreshed at 10 Hz instead of
## every frame to keep string formatting cheap on mobile.

const REFRESH_SECONDS: float = 0.1

var _session: GameSession
var _hero: Hero
var _elapsed: float = 0.0

@onready var stage_label: Label = $TopRow/StageLabel
@onready var gold_label: Label = $TopRow/GoldLabel
@onready var progress_bar: ProgressBar = $ProgressRow/ProgressBar
@onready var progress_label: Label = $ProgressRow/ProgressLabel
@onready var hero_health_bar: ProgressBar = $HeroHealth


func bind(session: GameSession, hero: Hero) -> void:
	_session = session
	_hero = hero
	_refresh()


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
	stage_label.text = "Stage %d" % progression.stage
	gold_label.text = "Gold %s" % NumberFormat.format(_session.wallet.get_amount(GameSession.GOLD))
	if progression.is_boss_active:
		progress_bar.max_value = progression.boss_seconds
		progress_bar.value = progression.boss_time_left
		progress_label.text = "BOSS %.1fs" % progression.boss_time_left
	else:
		progress_bar.max_value = progression.kills_per_stage
		progress_bar.value = progression.kills
		progress_label.text = "%d / %d" % [progression.kills, progression.kills_per_stage]
	hero_health_bar.value = _hero.health.get_ratio() * 100.0
