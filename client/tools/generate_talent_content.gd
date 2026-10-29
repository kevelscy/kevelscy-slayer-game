extends SceneTree
## One-shot generator for the ascension talent catalog (.tres). Run it after
## changing the table below:
##   scripts/godot.sh --headless --path client -s res://tools/generate_talent_content.gd

const CATALOG_PATH: String = "res://data/content/talents/talent_catalog.tres"


func _init() -> void:
	var catalog: TalentCatalog = TalentCatalog.new()
	catalog.talents = [
		_talent(&"might", "Poder", StatBlock.ATTACK, StatModifier.Kind.PERCENT, 0.1, &""),
		_talent(&"vitality", "Vitalidad", StatBlock.HEALTH, StatModifier.Kind.PERCENT, 0.1, &""),
		_talent(&"greed", "Codicia", TalentDefinition.GOLD_GAIN, StatModifier.Kind.PERCENT, 0.1, &""),
		_talent(&"precision", "Precisión", StatBlock.CRIT_CHANCE, StatModifier.Kind.FLAT, 0.01, &"might"),
		_talent(&"ferocity", "Ferocidad", StatBlock.CRIT_DAMAGE, StatModifier.Kind.FLAT, 0.1, &"might"),
		_talent(&"haste", "Celeridad", StatBlock.ATTACK_SPEED, StatModifier.Kind.PERCENT, 0.03, &"vitality"),
	]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CATALOG_PATH.get_base_dir()))
	var error: Error = ResourceSaver.save(catalog, CATALOG_PATH)
	if error != OK:
		push_error("generate_talent_content: failed to save %s (%s)" % [CATALOG_PATH, error_string(error)])
	else:
		print("saved ", CATALOG_PATH)
	quit()


func _talent(
	id: StringName, display_name: String, stat: StringName, kind: StatModifier.Kind,
	per_level: float, requires: StringName
) -> TalentDefinition:
	var talent: TalentDefinition = TalentDefinition.new()
	talent.id = id
	talent.display_name = display_name
	talent.stat = stat
	talent.kind = kind
	talent.per_level = per_level
	talent.max_level = 10
	talent.requires = requires
	talent.requires_level = 5
	return talent
