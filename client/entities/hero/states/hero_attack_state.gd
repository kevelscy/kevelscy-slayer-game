extends State
## Stands and auto-attacks the front enemy; resumes running when nothing is in range.

@onready var hero: Hero = owner as Hero


func enter() -> void:
	hero.sprite.play(&"idle")


func update(delta: float) -> void:
	if not hero.has_target_in_range():
		machine.transition_to(&"Run")
		return
	if hero.auto_attack.tick(delta, true):
		hero.perform_attack()
