class_name ChestBoost
extends RefCounted
## A timed chest multiplier: GameSession keeps one on kill gold and one on damage.
## A bigger multiplier replaces the active one, an equal one adds its time and a
## smaller one changes nothing.

var factor: float = 1.0
var seconds_left: float = 0.0


func apply(new_factor: float, seconds: float) -> void:
	if seconds_left <= 0.0 or new_factor > factor:
		factor = new_factor
		seconds_left = seconds
	elif is_equal_approx(new_factor, factor):
		seconds_left += seconds


func tick(delta: float) -> void:
	if seconds_left <= 0.0:
		return
	seconds_left = maxf(seconds_left - delta, 0.0)
	if seconds_left <= 0.0:
		factor = 1.0


func multiplier() -> float:
	return factor if seconds_left > 0.0 else 1.0


func clear() -> void:
	factor = 1.0
	seconds_left = 0.0
