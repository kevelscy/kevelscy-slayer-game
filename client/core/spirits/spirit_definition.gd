class_name SpiritDefinition
extends Resource
## A companion spirit: a permanent bonus to one hero stat once unlocked, plus a
## periodic attack worth `attack_power` times hero attack.

@export var id: StringName
@export var display_name: String
@export var unlock_stage: int = 1
@export var passive_stat: StringName = StatBlock.ATTACK
## PERCENT scales the stat (0.1 = +10% attack); FLAT adds to it, which is how
## rate stats grow (0.05 = +5 points of crit chance).
@export var passive_kind: StatModifier.Kind = StatModifier.Kind.PERCENT
@export var passive_value: float = 0.1
@export_range(0.1, 60.0) var attack_interval_seconds: float = 3.0
@export var attack_power: float = 1.0
@export var color: Color = Color.WHITE
