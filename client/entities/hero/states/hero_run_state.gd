extends State
## Runs forward (the world scrolls) until an enemy is in range.

@onready var hero: Hero = owner as Hero


func enter() -> void:
	hero.sprite.play(&"run")


func update(_delta: float) -> void:
	if hero.has_target_in_range():
		machine.transition_to(&"Attack")
