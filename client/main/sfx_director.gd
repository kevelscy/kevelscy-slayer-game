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


func _on_enemy_hit(result: DamageResult) -> void:
	sfx.play(&"crit" if result.is_critical else &"hit")


func _on_enemy_killed(_was_boss: bool) -> void:
	sfx.play(&"coin")


func _on_spirit_attacked(_slot_index: int, _spirit: SpiritDefinition) -> void:
	sfx.play(&"spirit")
