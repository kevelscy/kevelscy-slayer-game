class_name SpriteFramesBuilder
extends RefCounted
## Builds SpriteFrames from AnimationSheet descriptions so sheets stay data-driven
## instead of hand-authored frame lists.


static func build(sheets: Array[AnimationSheet]) -> SpriteFrames:
	var frames: SpriteFrames = SpriteFrames.new()
	frames.remove_animation(&"default")
	for sheet: AnimationSheet in sheets:
		_add_animation(frames, sheet)
	return frames


static func _add_animation(frames: SpriteFrames, sheet: AnimationSheet) -> void:
	frames.add_animation(sheet.animation_name)
	frames.set_animation_speed(sheet.animation_name, sheet.fps)
	frames.set_animation_loop(sheet.animation_name, sheet.loop)
	var columns: int = sheet.texture.get_width() / sheet.frame_size.x
	var rows: int = sheet.texture.get_height() / sheet.frame_size.y
	var cell_count: int = columns * rows
	for index: int in range(sheet.first_frame, sheet.first_frame + sheet.frame_count):
		if index >= cell_count:
			push_error(
				"SpriteFramesBuilder: frame %d of '%s' is outside its %dx%d sheet"
				% [index, sheet.animation_name, columns, rows]
			)
			return
		var atlas: AtlasTexture = AtlasTexture.new()
		atlas.atlas = sheet.texture
		atlas.region = Rect2(
			(index % columns) * sheet.frame_size.x,
			(index / columns) * sheet.frame_size.y,
			sheet.frame_size.x,
			sheet.frame_size.y
		)
		frames.add_frame(sheet.animation_name, atlas)
