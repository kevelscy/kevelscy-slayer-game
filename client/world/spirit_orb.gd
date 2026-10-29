class_name SpiritOrb
extends Node2D
## Placeholder companion visual: a glowing orb that bobs near the hero until real
## spirit art exists.

const RADIUS: float = 5.0
const BOB_PIXELS: float = 3.0
const BOB_SPEED: float = 3.0

var color: Color = Color.WHITE
var anchor: Vector2 = Vector2.ZERO
var _time: float = 0.0


func setup(spirit: SpiritDefinition, anchor_position: Vector2, phase: float) -> void:
	color = spirit.color
	anchor = anchor_position
	_time = phase
	position = anchor
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	position = anchor + Vector2(0.0, sin(_time * BOB_SPEED) * BOB_PIXELS)


func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS * 1.8, Color(color, 0.25))
	draw_circle(Vector2.ZERO, RADIUS, color)
	draw_circle(Vector2(-1.5, -1.5), RADIUS * 0.35, Color(1.0, 1.0, 1.0, 0.8))
