class_name FlameWave
extends RefCounted
## Onda de Llamas in flight: it moves right across the lane from the hero's hand and
## hits each enemy it reaches once, until it leaves the scene.

var skill: SkillDefinition
var x: float = 0.0
var hit: Array[Enemy] = []


func _init(wave_skill: SkillDefinition, start_x: float) -> void:
	skill = wave_skill
	x = start_x
