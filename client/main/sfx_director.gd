class_name SfxDirector
extends Node
## Maps game events to sound effects. Its connections are methods of this node, so they
## drop with it and never reach a freed SfxPlayer.

var sfx: SfxPlayer


func bind(
	player: SfxPlayer, session: GameSession, world: BattleWorld, tab_bar: BottomTabBar,
	roulette: ChestRoulette = null
) -> void:
	sfx = player
	if roulette != null:
		roulette.revealed.connect(_on_chest_revealed)
	world.enemy_hit.connect(_on_enemy_hit)
	EventBus.enemy_killed.connect(_on_enemy_killed)
	session.spirits.attacked.connect(_on_spirit_attacked)
	session.skills.cast.connect(_on_skill_cast)
	# Upgrade tracks emit leveled_up only when bought; loading a save sets levels silently.
	for track: UpgradeTrack in [
		session.attack_track, session.health_track, session.crit_chance_track,
		session.crit_damage_track, session.attack_speed_track,
	]:
		track.leveled_up.connect(_on_upgrade_leveled_up)
	session.talents.bought.connect(_on_talent_bought)
	tab_bar.tab_selected.connect(_on_tab_selected)
	session.progression.boss_started.connect(_on_boss_started)
	session.progression.boss_defeated.connect(_on_boss_defeated)
	EventBus.hero_died.connect(_on_hero_died)
	session.ascended.connect(_on_ascended)


func _on_enemy_hit(result: DamageResult) -> void:
	sfx.play(&"crit" if result.is_critical else &"hit")


func _on_enemy_killed(_was_boss: bool) -> void:
	sfx.play(&"coin")


func _on_spirit_attacked(_slot_index: int, _spirit: SpiritDefinition) -> void:
	sfx.play(&"spirit")


## Every skill's sound is named after its id.
func _on_skill_cast(_slot_index: int, skill: SkillDefinition) -> void:
	sfx.play(skill.id)


func _on_upgrade_leveled_up(_level: int) -> void:
	sfx.play(&"upgrade")


func _on_talent_bought(_talent_id: StringName) -> void:
	sfx.play(&"upgrade")


func _on_tab_selected(_index: int) -> void:
	sfx.play(&"ui_tap")


func _on_boss_started(_seconds: float) -> void:
	sfx.play(&"boss_start")


func _on_boss_defeated() -> void:
	sfx.play(&"boss_defeat")


func _on_hero_died() -> void:
	sfx.play(&"hero_death")


## Legendary and Super chests get the boss fanfare; the rest the upgrade chime.
func _on_chest_revealed(reward: ChestReward) -> void:
	sfx.play(&"boss_defeat" if reward.rarity >= ChestTable.Rarity.LEGENDARY else &"upgrade")


func _on_ascended(_shards_gained: int) -> void:
	sfx.play(&"ascension")
