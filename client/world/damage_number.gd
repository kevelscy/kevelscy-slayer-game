class_name DamageNumber
extends Label
## One floating damage number in the battle world: pixel-font text that rises from the
## hit enemy on whole pixels, fades out and then asks its pool to release it.

signal finished(number: DamageNumber)

const FONT: FontFile = preload("res://art/fonts/damage_font.png")
const CRIT_FONT: FontFile = preload("res://art/fonts/damage_font_crit.png")
## The glyph cell height, so the font draws 1:1 in the battle viewport.
const FONT_SIZE: int = 11
## Critical hits draw at this whole-pixel scale, grown from the bottom center.
const CRIT_SCALE: float = 2.0
const LIFETIME: float = 0.8
const FADE_START: float = 0.4
const RISE_SPEED: float = 24.0
## Random horizontal offset the world adds so fast hits do not stack exactly.
const MAX_JITTER: float = 6.0

var _age: float = 0.0
var _y: float = 0.0


func _ready() -> void:
	z_index = 20
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_font_size_override("font_size", FONT_SIZE)


func _process(delta: float) -> void:
	advance(delta)


## Shows the hit centered on anchor.x with its bottom on anchor.y.
func show_hit(result: DamageResult, anchor: Vector2) -> void:
	add_theme_font_override("font", CRIT_FONT if result.is_critical else FONT)
	text = NumberFormat.format(result.amount)
	reset_size()
	pivot_offset = Vector2(roundf(size.x * 0.5), size.y)
	scale = Vector2.ONE * (CRIT_SCALE if result.is_critical else 1.0)
	_age = 0.0
	modulate.a = 1.0
	_y = anchor.y - size.y
	position = Vector2(roundf(anchor.x - size.x * 0.5), roundf(_y))


func advance(delta: float) -> void:
	_age += delta
	_y -= RISE_SPEED * delta
	position.y = roundf(_y)
	modulate.a = clampf(1.0 - (_age - FADE_START) / (LIFETIME - FADE_START), 0.0, 1.0)
	if _age >= LIFETIME:
		finished.emit(self)
