class_name ChestPickup
extends Sprite2D
## A chest a kill dropped on the ground. It scrolls with the world like the dead
## enemies and the hero picks it up when it runs over it (BattleWorld._move_chests).

const TEXTURE_PATH: String = "res://art/icons/chest.png"


func _init() -> void:
	texture = load(TEXTURE_PATH)
	# Its bottom edge rests on the ground line.
	offset = Vector2(0.0, -texture.get_height() * 0.5)


func advance(delta: float, world_speed: float) -> void:
	position.x -= world_speed * delta
