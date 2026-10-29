extends GutTest


func test_portrait_when_taller_than_wide() -> void:
	assert_false(LayoutRules.is_landscape(Vector2(720, 1280)))


func test_landscape_when_wider_than_tall() -> void:
	assert_true(LayoutRules.is_landscape(Vector2(1600, 900)))


func test_square_counts_as_portrait() -> void:
	assert_false(LayoutRules.is_landscape(Vector2(800, 800)))


func test_portrait_scale_fills_width_with_integer_factor() -> void:
	assert_eq(LayoutRules.battle_scale(Vector2(720, 1280), false), 2)
	assert_eq(LayoutRules.battle_scale(Vector2(1079, 1920), false), 2)
	assert_eq(LayoutRules.battle_scale(Vector2(1080, 1920), false), 3)


func test_landscape_scale_fits_center_column_and_height() -> void:
	# Center column = 1600 - 2 * 460 = 680 -> floor(680/360) = 1; height cap floor(900*0.75/192) = 3.
	assert_eq(LayoutRules.battle_scale(Vector2(1600, 900), true), 1)
	# Center 2560 - 920 = 1640 -> 4; height cap floor(1440*0.75/192) = 5.
	assert_eq(LayoutRules.battle_scale(Vector2(2560, 1440), true), 4)


func test_scale_never_drops_below_one() -> void:
	assert_eq(LayoutRules.battle_scale(Vector2(200, 400), false), 1)
	assert_eq(LayoutRules.battle_scale(Vector2(900, 300), true), 1)
