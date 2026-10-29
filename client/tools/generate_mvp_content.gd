extends SceneTree
## One-shot generator for the MVP content resources (.tres). Run it after changing the
## tables below, then tune the generated files in the editor:
##   scripts/godot.sh --headless --path client -s res://tools/generate_mvp_content.gd
## Enemy frame data comes from assets/ASSETS.md; the hero is original art from art/sprites/
## (art/STYLE.md): 48 px tall frames, the attack is 96 px wide so the swing fits.

const HERO_DIR: String = "res://art/sprites/"
const ENEMY_DIR: String = "res://assets/sprites/enemies/"
const CONTENT_DIR: String = "res://data/content/"


func _init() -> void:
	var hero_sheets: Array[AnimationSheet] = [
		_sheet(&"idle", HERO_DIR + "hero_idle.png", Vector2i(48, 48), 0, 4, 10.0, true),
		_sheet(&"run", HERO_DIR + "hero_run.png", Vector2i(48, 48), 0, 6, 12.0, true),
		_sheet(&"attack", HERO_DIR + "hero_attack.png", Vector2i(96, 48), 0, 6, 12.0, false),
		_sheet(&"hurt", HERO_DIR + "hero_hurt.png", Vector2i(48, 48), 0, 2, 10.0, false),
		_sheet(&"die", HERO_DIR + "hero_die.png", Vector2i(48, 48), 0, 4, 10.0, false),
	]
	var hero_set: AnimationSet = AnimationSet.new()
	hero_set.sheets = hero_sheets
	_save(hero_set, CONTENT_DIR + "hero/hero_animations.tres")

	var slime: EnemyDefinition = _enemy(
		&"slime", _sheet(&"move", ENEMY_DIR + "slime/slime.png", Vector2i(74, 86), 0, 4, 8.0, true),
		0.45, 0.0, 1.0, 0.8, 35.0
	)
	var bat: EnemyDefinition = _enemy(
		&"bat", _sheet(&"fly", ENEMY_DIR + "bat/bat.png", Vector2i(127, 138), 0, 3, 10.0, true),
		0.3, 18.0, 0.7, 1.0, 55.0
	)
	var skeleton: EnemyDefinition = _enemy(
		&"skeleton", _sheet(&"walk", ENEMY_DIR + "skeleton/skeleton.png", Vector2i(138, 138), 0, 4, 8.0, true),
		0.45, 0.0, 1.4, 1.2, 30.0
	)
	var boss: EnemyDefinition = _enemy(
		&"spider_boss", _sheet(&"walk", "res://assets/sprites/boss/spider.png", Vector2i(138, 138), 0, 6, 10.0, true),
		0.75, 0.0, 1.0, 1.0, 25.0
	)
	boss.tint = Color(1.0, 0.55, 0.55)
	for definition: EnemyDefinition in [slime, bat, skeleton, boss]:
		_save(definition, CONTENT_DIR + "enemies/%s.tres" % definition.id)

	var roster: EnemyRoster = EnemyRoster.new()
	var regulars: Array[EnemyDefinition] = [slime, bat, skeleton]
	roster.regular_enemies = regulars
	roster.boss = boss
	_save(roster, CONTENT_DIR + "enemies/forest_roster.tres")
	_save(StageBalance.new(), CONTENT_DIR + "balance/stage_balance.tres")
	quit()


func _sheet(
	anim_name: StringName, path: String, size: Vector2i, first: int, count: int, fps: float, loop: bool
) -> AnimationSheet:
	var sheet: AnimationSheet = AnimationSheet.new()
	sheet.animation_name = anim_name
	sheet.texture = load(path) as Texture2D
	sheet.frame_size = size
	sheet.first_frame = first
	sheet.frame_count = count
	sheet.fps = fps
	sheet.loop = loop
	return sheet


func _enemy(
	id: StringName, sheet: AnimationSheet, sprite_scale: float, hover: float,
	health_multiplier: float, damage_multiplier: float, speed: float
) -> EnemyDefinition:
	var definition: EnemyDefinition = EnemyDefinition.new()
	definition.id = id
	definition.animation = sheet
	definition.sprite_scale = sprite_scale
	definition.hover_height = hover
	definition.health_multiplier = health_multiplier
	definition.damage_multiplier = damage_multiplier
	definition.move_speed = speed
	return definition


func _save(resource: Resource, path: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var error: Error = ResourceSaver.save(resource, path, ResourceSaver.FLAG_CHANGE_PATH)
	if error != OK:
		push_error("generate_mvp_content: failed to save %s (%s)" % [path, error_string(error)])
		return
	# Later saves must reference this file instead of embedding a copy.
	resource.take_over_path(path)
	print("saved ", path)
