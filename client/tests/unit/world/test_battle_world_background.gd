extends GutTest
## The battle lane draws the original night forest: three parallax layers plus a
## ground strip that scrolls with the hero.

const BATTLE_WORLD: PackedScene = preload("res://world/battle_world.tscn")
const LAYERS: Array[Array] = [
	["Far", "res://art/tiles/bg_far.png", 0.1],
	["Middle", "res://art/tiles/bg_middle.png", 0.3],
	["Front", "res://art/tiles/bg_front.png", 0.6],
	["Ground", "res://art/tiles/bg_ground.png", 1.0],
]

var world: BattleWorld


func before_each() -> void:
	world = BATTLE_WORLD.instantiate()
	add_child_autofree(world)


func test_layers_use_the_original_art_in_back_to_front_order() -> void:
	var layers: Array[Node] = world.background.get_children()
	assert_eq(layers.size(), LAYERS.size())
	for index: int in mini(layers.size(), LAYERS.size()):
		var layer: Parallax2D = layers[index] as Parallax2D
		var sprite: Sprite2D = layer.get_node("Sprite") as Sprite2D
		assert_eq(String(layer.name), LAYERS[index][0])
		assert_eq(sprite.texture.resource_path, LAYERS[index][1])
		assert_eq(layer.repeat_size, Vector2(sprite.texture.get_width(), 0.0), "%s tiles every texture width" % layer.name)


func test_layers_scroll_at_their_parallax_speed_while_the_hero_runs() -> void:
	world._set_world_speed(BattleWorld.RUN_SPEED)
	var layers: Array[Node] = world.background.get_children()
	for index: int in mini(layers.size(), LAYERS.size()):
		var layer: Parallax2D = layers[index] as Parallax2D
		assert_almost_eq(layer.autoscroll.x, -BattleWorld.RUN_SPEED * float(LAYERS[index][2]), 0.001, String(layer.name))


func test_the_ground_strip_fills_the_bottom_of_the_lane() -> void:
	var sprite: Sprite2D = world.get_node("Background/Ground/Sprite") as Sprite2D
	assert_eq(sprite.position, Vector2(0.0, 160.0))
	assert_eq(sprite.texture.get_height(), 32)
	assert_lt(sprite.position.y, BattleWorld.GROUND_Y, "the hero stands on the strip")
	assert_null(world.get_node_or_null("GroundFill"), "no flat fill left over")
	assert_false(world.get_node_or_null("Ground") is ColorRect, "the flat ColorRect is gone")
