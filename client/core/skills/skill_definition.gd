class_name SkillDefinition
extends Resource
## One active skill of the skill bar. `power` reads per effect: a multiple of hero
## attack for damage skills, a percent bonus (0.5 = +50%) for buffs and a fraction
## of max health for shields and heals (a heal spreads over `duration_seconds`). A dash (wind) carries the hero forward to stab the nearest enemy. Skills are bought with gold and leveled: each level
## above the first adds LEVEL_POWER_STEP of the base power.

## New effects go last: the catalog stores them as integers.
## THROW_FRONT hits the front enemy like DAMAGE_FRONT, thrown by the hero instead of falling.
enum Effect { DAMAGE_ALL, DAMAGE_FRONT, FREEZE_ALL, BUFF, SHIELD, DASH, HEAL, THROW_FRONT }
## Skill tree branch; BRANCH_NAMES holds the shown names in the same order.
enum Branch { FIRE, ELECTRIC, ICE, BOOST, DEFENSIVE, AIR }

const BRANCH_NAMES: Array[String] = ["Fuego", "Eléctrico", "Hielo", "Incremento", "Defensivo", "Aire"]

const LEVEL_POWER_STEP: float = 0.15

@export var id: StringName
@export var display_name: String
@export var effect: Effect = Effect.DAMAGE_ALL
@export var branch: Branch = Branch.FIRE
@export var unlock_stage: int = 1
@export_range(0.1, 600.0) var cooldown_seconds: float = 10.0
@export var power: float = 1.0
## Freeze, buff, shield and heal length; ignored by pure damage skills.
@export var duration_seconds: float = 0.0
@export var color: Color = Color.WHITE
## Hero stats a buff raises by `power` percent; Furia raises attack and attack speed.
@export var buff_stats: Array[StringName] = [StatBlock.ATTACK, StatBlock.ATTACK_SPEED]
## Sound played on cast; empty means the sound named after the id.
@export var sound: StringName = &""
## Gold price of level 1; each next level costs cost_growth times more.
@export var base_cost: float = 50.0
@export var cost_growth: float = 1.35


## Power at a skill level; a skill not bought yet reads as level 1.
func power_at(level: int) -> float:
	return power * (1.0 + LEVEL_POWER_STEP * (maxi(level, 1) - 1))


func sound_id() -> StringName:
	return id if sound.is_empty() else sound


## Damage and freeze skills are wasted without an enemy to hit.
func needs_target() -> bool:
	return effect in [Effect.DAMAGE_ALL, Effect.DAMAGE_FRONT, Effect.FREEZE_ALL, Effect.DASH, Effect.THROW_FRONT]
