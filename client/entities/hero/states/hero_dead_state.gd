extends State
## Plays the death animation, then revives the hero after a short delay.

const RESPAWN_SECONDS: float = 1.5

var _time_left: float = 0.0

@onready var hero: Hero = owner as Hero


func enter() -> void:
	_time_left = RESPAWN_SECONDS
	hero.sprite.play(&"die")


func update(delta: float) -> void:
	_time_left -= delta
	if _time_left <= 0.0:
		hero.revive()
		machine.transition_to(&"Run")
