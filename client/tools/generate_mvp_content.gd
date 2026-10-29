extends SceneTree
## One-shot generator for the MVP content resources (.tres). Run it after changing the
## tables below, then tune the generated files in the editor:
##   scripts/godot.sh --headless --path client -s res://tools/generate_mvp_content.gd
## Pack enemy frame data comes from assets/ASSETS.md; the hero, the slime, the bat and the skeleton
## are original art from art/sprites/ (art/STYLE.md): hero frames are 48 px tall (the attack is 96 px
## wide so the swing fits), slime frames are 32x32, bat frames are 40x32 (wide wings) and skeleton
## frames are 40x40 (room for its sword). The slime and the skeleton idle while they stand at the
## hero; the bat flies in place.

const ART_DIR: String = "res://art/sprites/"
const CONTENT_DIR: String = "res://data/content/"


func _init() -> void:
	var hero_sheets: Array[AnimationSheet] = [
		_sheet(&"idle", ART_DIR + "hero_idle.png", Vector2i(48, 48), 0, 4, 10.0, true),
		_sheet(&"run", ART_DIR + "hero_run.png", Vector2i(48, 48), 0, 6, 12.0, true),
		_sheet(&"attack", ART_DIR + "hero_attack.png", Vector2i(96, 48), 0, 6, 12.0, false),
		_sheet(&"hurt", ART_DIR + "hero_hurt.png", Vector2i(48, 48), 0, 2, 10.0, false),
		_sheet(&"die", ART_DIR + "hero_die.png", Vector2i(48, 48), 0, 4, 10.0, false),
	]
	var hero_set: AnimationSet = AnimationSet.new()
	hero_set.sheets = hero_sheets
	_save(hero_set, CONTENT_DIR + "hero/hero_animations.tres")

	var slime: EnemyDefinition = _enemy(
		&"slime", _sheet(&"move", ART_DIR + "slime_move.png", Vector2i(32, 32), 0, 6, 12.0, true),
		1.0, 0.0, 1.0, 0.8, 35.0
	)
	slime.idle_animation = _sheet(&"idle", ART_DIR + "slime_idle.png", Vector2i(32, 32), 0, 4, 10.0, true)
	var bat: EnemyDefinition = _enemy(
		&"bat", _sheet(&"fly", ART_DIR + "bat_fly.png", Vector2i(40, 32), 0, 4, 12.0, true),
		1.0, 18.0, 0.7, 1.0, 55.0
	)
	var skeleton: EnemyDefinition = _enemy(
		&"skeleton", _sheet(&"walk", ART_DIR + "skeleton_walk.png", Vector2i(40, 40), 0, 6, 10.0, true),
		1.0, 0.0, 1.4, 1.2, 30.0
	)
	skeleton.idle_animation = _sheet(&"idle", ART_DIR + "skeleton_idle.png", Vector2i(40, 40), 0, 4, 10.0, true)
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
