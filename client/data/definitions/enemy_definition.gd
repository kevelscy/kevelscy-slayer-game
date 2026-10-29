class_name EnemyDefinition
extends Resource
## Data for one enemy type. Stage scaling comes from StageBalance; these multipliers
## make each type feel different within a stage.

@export var id: StringName
@export var animation: AnimationSheet
@export var sprite_scale: float = 0.5
@export var tint: Color = Color.WHITE
@export var hover_height: float = 0.0
@export var health_multiplier: float = 1.0
@export var damage_multiplier: float = 1.0
@export var move_speed: float = 40.0
@export var attacks_per_second: float = 0.8
