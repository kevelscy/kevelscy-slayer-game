class_name AnimationSheet
extends Resource
## One animation cut from a grid sprite sheet: frames are numbered left to right,
## top to bottom, starting at 0 (see assets/ASSETS.md).

@export var animation_name: StringName = &"default"
@export var texture: Texture2D
@export var frame_size: Vector2i = Vector2i(64, 64)
@export var first_frame: int = 0
@export var frame_count: int = 1
@export var fps: float = 10.0
@export var loop: bool = true
