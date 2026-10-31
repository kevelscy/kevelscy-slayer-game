class_name SaveData
extends RefCounted
## Everything a local save keeps. Progress inside a stage (kills, boss timer) is
## intentionally not saved: loading restarts the saved stage.

var stage: int = 1
var gold: BigNumber = BigNumber.zero()
var attack_level: int = 0
var health_level: int = 0
var crit_chance_level: int = 0
var crit_damage_level: int = 0
var attack_speed_level: int = 0
var ascension_shards: int = 0
var ascension_count: int = 0
## Talent id to level.
var talents: Dictionary[String, int] = {}
## Skill id to level; 0 or missing means not bought.
var skills: Dictionary[String, int] = {}
## False for saves older than version 4, which kept no skill levels: loading one
## gives level 1 to the skills its stage reached.
var has_skill_levels: bool = true
var last_seen_unix: int = 0
