class_name TalentDefinition
extends Resource
## One permanent talent of the ascension tree, bought level by level with shards.

## Not a hero stat: multiplies every gold reward instead.
const GOLD_GAIN: StringName = &"gold_gain"

@export var id: StringName
@export var display_name: String
@export var stat: StringName = StatBlock.ATTACK
## PERCENT scales the stat (0.1 = +10% per level); FLAT adds to it, which is how
## rate stats grow (0.01 = +1 point of crit chance per level).
@export var kind: StatModifier.Kind = StatModifier.Kind.PERCENT
@export var per_level: float = 0.1
@export var max_level: int = 10
## Talent that must reach `requires_level` first; empty for tier 1 talents.
@export var requires: StringName
@export var requires_level: int = 5
