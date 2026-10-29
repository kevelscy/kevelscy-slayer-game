class_name EnemyRoster
extends Resource
## Enemies that can appear in a zone: random regular enemies plus one boss.

@export var regular_enemies: Array[EnemyDefinition] = []
@export var boss: EnemyDefinition


func pick_regular(rng: RandomNumberGenerator) -> EnemyDefinition:
	return regular_enemies[rng.randi_range(0, regular_enemies.size() - 1)]
