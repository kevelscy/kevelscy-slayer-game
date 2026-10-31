class_name SpawnScheduler
extends RefCounted
## Decides when to spawn: a queued boss first, regular enemies on an interval up to
## a cap, and no regular enemies while the boss is alive. A due regular spawn turns
## into a wave of WAVE_SIZE enemies when its roll lands under the wave chance.

enum Order { NONE, REGULAR, BOSS, WAVE }

const WAVE_SIZE: int = 6

var spawn_interval: float
var max_regular_alive: int
## Share of due regular spawns that become a wave, from 0 to 1.
var wave_chance: float

var _timer: float = 0.0
var _boss_queued: bool = false


func _init(interval_seconds: float = 1.2, max_alive: int = 4, wave_share: float = 0.0) -> void:
	spawn_interval = interval_seconds
	max_regular_alive = max_alive
	wave_chance = wave_share


func queue_boss() -> void:
	_boss_queued = true


func cancel_boss() -> void:
	_boss_queued = false


## Back to an empty lane: no queued boss and a full interval before the next spawn.
func reset() -> void:
	_boss_queued = false
	_timer = 0.0


## wave_roll is a random number in [0, 1); the default never makes a wave.
func tick(delta: float, regular_alive: int, boss_alive: bool, wave_roll: float = 1.0) -> Order:
	if _boss_queued:
		_boss_queued = false
		return Order.BOSS
	if boss_alive:
		return Order.NONE
	_timer = minf(_timer + delta, spawn_interval)
	if _timer < spawn_interval or regular_alive >= max_regular_alive:
		return Order.NONE
	_timer = 0.0
	return Order.WAVE if wave_roll < wave_chance else Order.REGULAR
