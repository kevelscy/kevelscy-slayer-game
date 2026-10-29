class_name SkillDefinition
extends Resource
## One active skill of the skill bar. `power` reads per effect: a multiple of hero
## attack for damage skills, a percent bonus (0.5 = +50%) for buffs and a fraction
## of max health for shields.

enum Effect { DAMAGE_ALL, DAMAGE_FRONT, FREEZE_ALL, BUFF, SHIELD }

@export var id: StringName
@export var display_name: String
@export var effect: Effect = Effect.DAMAGE_ALL
@export var unlock_stage: int = 1
@export_range(0.1, 600.0) var cooldown_seconds: float = 10.0
@export var power: float = 1.0
## Freeze, buff and shield length; ignored by pure damage skills.
@export var duration_seconds: float = 0.0
@export var color: Color = Color.WHITE


## Damage and freeze skills are wasted without an enemy to hit.
func needs_target() -> bool:
	return effect in [Effect.DAMAGE_ALL, Effect.DAMAGE_FRONT, Effect.FREEZE_ALL]
