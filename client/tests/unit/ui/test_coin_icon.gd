extends GutTest
## The gold coin icon is shared by every gold amount: scaled with nearest filtering.


func test_coin_texture_scales_the_16px_art_without_smoothing() -> void:
	var texture: Texture2D = GameTheme.coin_texture(32)
	assert_eq(texture.get_size(), Vector2(32, 32))
	var image: Image = texture.get_image()
	var source: Image = load(GameTheme.COIN_PATH).get_image()
	# Each source pixel becomes a 2x2 block with the exact same color.
	assert_eq(image.get_pixel(10, 10), source.get_pixel(5, 5))
	assert_eq(image.get_pixel(11, 11), source.get_pixel(5, 5))
	assert_eq(image.get_pixel(0, 0).a, 0.0)


func test_coin_texture_is_cached_per_size() -> void:
	assert_same(GameTheme.coin_texture(32), GameTheme.coin_texture(32))
