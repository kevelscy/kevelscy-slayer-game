extends GutTest
## Enemies play the original Pixelorama art from art/sprites/ (10-12 fps). The slime (32x32
## frames) moves while it advances and idles at the hero; the bat (40x32 frames) only flies.

const SLIME: EnemyDefinition = preload("res://data/content/enemies/slime.tres")
const BAT: EnemyDefinition = preload("res://data/content/enemies/bat.tres")
const ENEMY_SCENE: PackedScene = preload("res://entities/enemies/enemy.tscn")
const CONTACT_X: float = 50.0


func _spawn(definition: EnemyDefinition) -> Enemy:
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	add_child_autofree(enemy)
	enemy.spawn(definition, BigNumber.from_float(10.0), BigNumber.one(), false, Vector2(100.0, 0.0))
	return enemy


func _assert_sheet(
	sheet: AnimationSheet, anim_name: StringName, path: String, count: int, size: Vector2i = Vector2i(32, 32)
) -> void:
	assert_not_null(sheet, "%s sheet" % anim_name)
	if sheet == null:
		return
	assert_eq(sheet.animation_name, anim_name)
	assert_eq(sheet.texture.resource_path, path)
	assert_eq(sheet.frame_size, size)
	assert_eq(sheet.first_frame, 0)
	assert_eq(sheet.frame_count, count)
	assert_true(sheet.loop, "%s loops" % anim_name)
	assert_between(sheet.fps, 10.0, 12.0, "%s fps" % anim_name)
	assert_eq(sheet.texture.get_size(), Vector2(size.x * count, size.y))


func test_slime_uses_the_original_art() -> void:
	_assert_sheet(SLIME.animation, &"move", "res://art/sprites/slime_move.png", 6)
	_assert_sheet(SLIME.idle_animation, &"idle", "res://art/sprites/slime_idle.png", 4)
	# 32 px art is drawn at its native size, like the 48 px hero.
	assert_eq(SLIME.sprite_scale, 1.0)


func test_bat_uses_the_original_art() -> void:
	_assert_sheet(BAT.animation, &"fly", "res://art/sprites/bat_fly.png", 4, Vector2i(40, 32))
	assert_eq(BAT.animation.fps, 12.0)
	assert_null(BAT.idle_animation, "the bat flies in place at the hero")
	assert_eq(BAT.sprite_scale, 1.0)
	assert_eq(BAT.hover_height, 18.0)


func test_slime_moves_while_it_advances_and_idles_at_the_hero() -> void:
	var enemy: Enemy = _spawn(SLIME)
	assert_eq(enemy.sprite.animation, &"move")
	assert_true(enemy.sprite.is_playing())
	enemy.advance(0.1, 0.0, CONTACT_X)
	assert_eq(enemy.sprite.animation, &"move", "still has room to advance")
	enemy.advance(10.0, 0.0, CONTACT_X)
	assert_eq(enemy.position.x, CONTACT_X)
	assert_eq(enemy.sprite.animation, &"idle")
	assert_true(enemy.sprite.is_playing())
	enemy.advance(0.1, 0.0, -INF)
	assert_eq(enemy.sprite.animation, &"move", "the hero is gone, so it walks again")


func test_frozen_slime_thaws_into_its_idle_at_the_hero() -> void:
	var enemy: Enemy = _spawn(SLIME)
	enemy.advance(10.0, 0.0, CONTACT_X)
	enemy.freeze(1.0)
	assert_false(enemy.sprite.is_playing())
	enemy.tick_freeze(1.0)
	assert_eq(enemy.sprite.animation, &"idle")
	assert_true(enemy.sprite.is_playing())


func test_enemy_without_idle_keeps_its_single_animation_at_the_hero() -> void:
	var enemy: Enemy = _spawn(BAT)
	enemy.advance(10.0, 0.0, CONTACT_X)
	assert_eq(enemy.position.x, CONTACT_X)
	assert_eq(enemy.sprite.animation, BAT.animation.animation_name)
	assert_true(enemy.sprite.is_playing())
