class_name StageProgression
extends RefCounted
## Stage flow: farm `kills_per_stage` regular enemies, then a timed boss.
## Defeating the boss advances the stage; running out of time (or the hero dying)
## fails it and the stage must be farmed again before the next attempt.

signal boss_started(seconds: float)
signal boss_defeated
signal boss_failed
signal stage_changed(stage: int)

var stage: int = 1
var kills: int = 0
var is_boss_active: bool = false
var boss_time_left: float = 0.0
var kills_per_stage: int
var boss_seconds: float


func _init(required_kills: int = 10, boss_time_limit: float = 30.0) -> void:
	kills_per_stage = maxi(required_kills, 1)
	boss_seconds = boss_time_limit


func register_kill() -> void:
	if is_boss_active:
		return
	kills += 1
	if kills >= kills_per_stage:
		_start_boss()


func defeat_boss() -> void:
	if not is_boss_active:
		return
	is_boss_active = false
	boss_time_left = 0.0
	kills = 0
	stage += 1
	boss_defeated.emit()
	stage_changed.emit(stage)


func fail_boss() -> void:
	if not is_boss_active:
		return
	is_boss_active = false
	boss_time_left = 0.0
	kills = 0
	boss_failed.emit()


func tick(delta: float) -> void:
	if not is_boss_active:
		return
	boss_time_left = maxf(boss_time_left - delta, 0.0)
	if boss_time_left <= 0.0:
		fail_boss()


func _start_boss() -> void:
	is_boss_active = true
	boss_time_left = boss_seconds
	boss_started.emit(boss_seconds)
