class_name SfxDirector
extends Node
## Maps game events to sound effects. Its connections are methods of this node, so they
## drop with it and never reach a freed SfxPlayer.

var sfx: SfxPlayer


func bind(player: SfxPlayer, session: GameSession, world: BattleWorld) -> void:
	sfx = player
	world.enemy_hit.connect(_on_enemy_hit)
	EventBus.enemy_killed.connect(_on_enemy_killed)
	session.spirits.attacked.connect(_on_spirit_attacked)
	session.skills.cast.connect(_on_skill_cast)


func _on_enemy_hit(result: DamageResult) -> void:
	sfx.play(&"crit" if result.is_critical else &"hit")


func _on_enemy_killed(_was_boss: bool) -> void:
	sfx.play(&"coin")


func _on_spirit_attacked(_slot_index: int, _spirit: SpiritDefinition) -> void:
	sfx.play(&"spirit")


## Every skill's sound is named after its id.
func _on_skill_cast(_slot_index: int, skill: SkillDefinition) -> void:
	sfx.play(skill.id)
