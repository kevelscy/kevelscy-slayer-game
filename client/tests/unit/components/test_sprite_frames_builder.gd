extends GutTest


func _texture(width: int, height: int) -> Texture2D:
	return ImageTexture.create_from_image(Image.create(width, height, false, Image.FORMAT_RGBA8))


func _sheet(anim_name: StringName, texture: Texture2D, first: int, count: int) -> AnimationSheet:
	var sheet: AnimationSheet = AnimationSheet.new()
	sheet.animation_name = anim_name
	sheet.texture = texture
	sheet.frame_size = Vector2i(64, 64)
	sheet.first_frame = first
	sheet.frame_count = count
	sheet.fps = 12.0
	return sheet


func test_builds_one_frame_per_cell_in_reading_order() -> void:
	var sheets: Array[AnimationSheet] = [_sheet(&"run", _texture(192, 192), 0, 8)]
	var frames: SpriteFrames = SpriteFramesBuilder.build(sheets)
	assert_eq(frames.get_frame_count(&"run"), 8)
	var fifth: AtlasTexture = frames.get_frame_texture(&"run", 4)
	assert_eq(fifth.region, Rect2(64, 64, 64, 64))


func test_first_frame_offsets_the_range() -> void:
	var sheets: Array[AnimationSheet] = [_sheet(&"die", _texture(192, 256), 3, 9)]
	var frames: SpriteFrames = SpriteFramesBuilder.build(sheets)
	var first: AtlasTexture = frames.get_frame_texture(&"die", 0)
	assert_eq(first.region, Rect2(0, 64, 64, 64))
	assert_eq(frames.get_frame_count(&"die"), 9)


func test_applies_speed_and_loop() -> void:
	var sheet: AnimationSheet = _sheet(&"attack", _texture(384, 64), 0, 6)
	sheet.loop = false
	var sheets: Array[AnimationSheet] = [sheet]
	var frames: SpriteFrames = SpriteFramesBuilder.build(sheets)
	assert_eq(frames.get_animation_speed(&"attack"), 12.0)
	assert_false(frames.get_animation_loop(&"attack"))


func test_multiple_animations_and_no_default() -> void:
	var texture: Texture2D = _texture(192, 192)
	var sheets: Array[AnimationSheet] = [_sheet(&"run", texture, 0, 8), _sheet(&"idle", texture, 0, 2)]
	var frames: SpriteFrames = SpriteFramesBuilder.build(sheets)
	assert_true(frames.has_animation(&"run"))
	assert_true(frames.has_animation(&"idle"))
	assert_false(frames.has_animation(&"default"))


func test_frames_outside_the_sheet_are_rejected() -> void:
	var sheets: Array[AnimationSheet] = [_sheet(&"run", _texture(192, 192), 5, 10)]
	var frames: SpriteFrames = SpriteFramesBuilder.build(sheets)
	assert_eq(frames.get_frame_count(&"run"), 4)
	assert_push_error("SpriteFramesBuilder")
