class_name SkillDefinition
extends Resource
## One active skill of the skill bar. `power` reads per effect: a multiple of hero
## attack for damage skills, a percent bonus (0.5 = +50%) for buffs and a fraction
## of max health for shields. A dash (wind) carries the hero forward to stab the nearest enemy. Skills are bought with gold and leveled: each level
## above the first adds LEVEL_POWER_STEP of the base power.

## New effects go last: the catalog stores them as integers.
enum Effect { DAMAGE_ALL, DAMAGE_FRONT, FREEZE_ALL, BUFF, SHIELD, DASH }

const LEVEL_POWER_STEP: float = 0.15

@export var id: StringName
@export var display_name: String
@export var effect: Effect = Effect.DAMAGE_ALL
@export var unlock_stage: int = 1
@export_range(0.1, 600.0) var cooldown_seconds: float = 10.0
@export var power: float = 1.0
## Freeze, buff and shield length; ignored by pure damage skills.
@export var duration_seconds: float = 0.0
@export var color: Color = Color.WHITE
## Gold price of level 1; each next level costs cost_growth times more.
@export var base_cost: float = 50.0
@export var cost_growth: float = 1.35


## Power at a skill level; a skill not bought yet reads as level 1.
func power_at(level: int) -> float:
	return power * (1.0 + LEVEL_POWER_STEP * (maxi(level, 1) - 1))


## Damage and freeze skills are wasted without an enemy to hit.
func needs_target() -> bool:
	return effect in [Effect.DAMAGE_ALL, Effect.DAMAGE_FRONT, Effect.FREEZE_ALL, Effect.DASH]
