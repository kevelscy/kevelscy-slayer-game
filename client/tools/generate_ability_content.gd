extends SceneTree
## One-shot generator for the skill and spirit catalog (.tres). Run it after
## changing the tables below, then tune the generated file in the editor:
##   scripts/godot.sh --headless --path client -s res://tools/generate_ability_content.gd

const CATALOG_PATH: String = "res://data/content/abilities/ability_catalog.tres"


func _init() -> void:
	var catalog: AbilityCatalog = AbilityCatalog.new()
	catalog.skills = [
		_skill(&"thunder", "Trueno", SkillDefinition.Effect.DAMAGE_ALL, SkillDefinition.Branch.ELECTRIC, 1, 8.0, 3.0, 0.0, Color(0.6, 0.8, 1.0), 30.0),
		_skill(&"meteor", "Meteoro", SkillDefinition.Effect.DAMAGE_FRONT, SkillDefinition.Branch.FIRE, 3, 12.0, 10.0, 0.0, Color(1.0, 0.5, 0.15), 150.0),
		_skill(&"blizzard", "Ventisca", SkillDefinition.Effect.FREEZE_ALL, SkillDefinition.Branch.ICE, 5, 15.0, 1.5, 3.0, Color(0.55, 0.95, 1.0), 300.0),
		_skill(&"fury", "Furia", SkillDefinition.Effect.BUFF, SkillDefinition.Branch.BOOST, 8, 20.0, 0.5, 6.0, Color(1.0, 0.3, 0.25), 600.0),
		_skill(&"shield", "Escudo", SkillDefinition.Effect.SHIELD, SkillDefinition.Branch.DEFENSIVE, 12, 25.0, 0.5, 8.0, Color(1.0, 0.85, 0.3), 1200.0),
		# Faster than thunder but a little weaker, and on one enemy only (L1 bonuses).
		_skill(&"wind", "Viento", SkillDefinition.Effect.DASH, SkillDefinition.Branch.AIR, 15, 5.0, 2.5, 0.0, Color("#13ccbd"), 2400.0),
		# skill-branches S6.3: +40% attack speed only.
		_buff(_skill(&"speed_sword", "Espada Veloz", SkillDefinition.Effect.BUFF, SkillDefinition.Branch.BOOST, 18, 22.0, 0.4, 8.0, Color8(232, 189, 75), 4800.0), [StatBlock.ATTACK_SPEED], &"fury"),
		# skill-branches S6.6: a thrown ice block on the front enemy.
		_sound(_skill(&"ice_block", "Bloque de Hielo", SkillDefinition.Effect.THROW_FRONT, SkillDefinition.Branch.ICE, 20, 10.0, 8.0, 0.0, Color8(106, 230, 241), 9600.0), &"blizzard"),
		# skill-branches S6.5: half the max health healed over 4 s.
		_sound(_skill(&"heal", "Curación", SkillDefinition.Effect.HEAL, SkillDefinition.Branch.DEFENSIVE, 22, 30.0, 0.5, 4.0, Color8(19, 204, 189), 19200.0), &"shield"),
		# skill-branches S6.1: +50% on the hero's own sword hits only.
		_buff(_skill(&"burning_sword", "Espada Ardiente", SkillDefinition.Effect.BUFF, SkillDefinition.Branch.FIRE, 25, 25.0, 0.5, 10.0, Color8(240, 133, 13), 38400.0), [StatBlock.SWORD_DAMAGE], &"meteor"),
	]
	catalog.spirits = [
		_spirit(&"wisp", "Fuego fatuo", 2, StatBlock.ATTACK, StatModifier.Kind.PERCENT, 0.1, 3.0, 1.0, Color("#13ccbd")),
		_spirit(&"ember_fox", "Zorro ígneo", 6, StatBlock.CRIT_CHANCE, StatModifier.Kind.FLAT, 0.05, 4.0, 2.0, Color(1.0, 0.55, 0.2)),
		_spirit(&"frost_owl", "Búho de escarcha", 10, StatBlock.HEALTH, StatModifier.Kind.PERCENT, 0.2, 5.0, 3.0, Color(0.7, 0.85, 1.0)),
	]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CATALOG_PATH.get_base_dir()))
	var error: Error = ResourceSaver.save(catalog, CATALOG_PATH)
	if error != OK:
		push_error("generate_ability_content: failed to save %s (%s)" % [CATALOG_PATH, error_string(error)])
	else:
		print("saved ", CATALOG_PATH)
	quit()


func _skill(
	id: StringName, display_name: String, effect: SkillDefinition.Effect, branch: SkillDefinition.Branch, unlock_stage: int,
	cooldown: float, power: float, duration: float, color: Color, base_cost: float
) -> SkillDefinition:
	var skill: SkillDefinition = SkillDefinition.new()
	skill.id = id
	skill.display_name = display_name
	skill.effect = effect
	skill.branch = branch
	skill.unlock_stage = unlock_stage
	skill.cooldown_seconds = cooldown
	skill.power = power
	skill.duration_seconds = duration
	skill.color = color
	skill.base_cost = base_cost
	return skill


func _buff(skill: SkillDefinition, stats: Array[StringName], sound: StringName) -> SkillDefinition:
	skill.buff_stats = stats
	return _sound(skill, sound)


## New skills borrow an existing cast sound until they get their own.
func _sound(skill: SkillDefinition, sound: StringName) -> SkillDefinition:
	skill.sound = sound
	return skill


func _spirit(
	id: StringName, display_name: String, unlock_stage: int, stat: StringName, kind: StatModifier.Kind,
	value: float, interval: float, power: float, color: Color
) -> SpiritDefinition:
	var spirit: SpiritDefinition = SpiritDefinition.new()
	spirit.id = id
	spirit.display_name = display_name
	spirit.unlock_stage = unlock_stage
	spirit.passive_stat = stat
	spirit.passive_kind = kind
	spirit.passive_value = value
	spirit.attack_interval_seconds = interval
	spirit.attack_power = power
	spirit.color = color
	return spirit
