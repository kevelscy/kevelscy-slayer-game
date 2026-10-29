extends GutTest
## The hero plays the original Pixelorama art from art/sprites/ (48 px tall frames,
## 10-12 fps) and its feet rest on the node origin.

const HERO_ANIMATIONS: AnimationSet = preload("res://data/content/hero/hero_animations.tres")
const HERO_SCENE: PackedScene = preload("res://entities/hero/hero.tscn")
const EXPECTED: Dictionary[StringName, Array] = {
	&"idle": ["res://art/sprites/hero_idle.png", Vector2i(48, 48), 4, true],
	&"run": ["res://art/sprites/hero_run.png", Vector2i(48, 48), 6, true],
	&"attack": ["res://art/sprites/hero_attack.png", Vector2i(96, 48), 6, false],
	&"hurt": ["res://art/sprites/hero_hurt.png", Vector2i(48, 48), 2, false],
	&"die": ["res://art/sprites/hero_die.png", Vector2i(48, 48), 4, false],
}


func test_every_hero_animation_uses_the_original_art() -> void:
	var seen: Array[StringName] = []
	for sheet: AnimationSheet in HERO_ANIMATIONS.sheets:
		var expected: Array = EXPECTED[sheet.animation_name]
		seen.append(sheet.animation_name)
		assert_eq(sheet.texture.resource_path, expected[0], "%s texture" % sheet.animation_name)
		assert_eq(sheet.frame_size, expected[1], "%s frame size" % sheet.animation_name)
		assert_eq(sheet.first_frame, 0, "%s first frame" % sheet.animation_name)
		assert_eq(sheet.frame_count, expected[2], "%s frame count" % sheet.animation_name)
		assert_eq(sheet.loop, expected[3], "%s loop" % sheet.animation_name)
		assert_between(sheet.fps, 10.0, 12.0, "%s fps" % sheet.animation_name)
		assert_eq(sheet.texture.get_size(), Vector2(expected[1].x * expected[2], expected[1].y))
	assert_eq_deep(seen, EXPECTED.keys())


func test_hero_feet_rest_on_the_origin() -> void:
	var hero: Node2D = HERO_SCENE.instantiate()
	var sprite: AnimatedSprite2D = hero.get_node("Sprite")
	# Frames are 48 px tall and centered; the boot outline is the last opaque row (45).
	assert_eq(sprite.offset, Vector2(0, -22))
	hero.free()
