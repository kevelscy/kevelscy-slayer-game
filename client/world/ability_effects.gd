class_name AbilityEffects
extends Node2D
## Placeholder VFX drawn with primitives: lightning bolts, meteors, frost bursts,
## spirit shots and the hero's shield ring. Effects are short-lived and visual only.

const EFFECT_SECONDS: float = 0.35
const SKY_Y: float = -10.0


class Flash:
	var kind: SkillDefinition.Effect
	var from: Vector2
	var to: Vector2
	var color: Color
	var ttl: float = EFFECT_SECONDS
	var is_spirit_shot: bool = false


var hero: Hero
var _flashes: Array[Flash] = []


func play_skill(skill: SkillDefinition, targets: Array[Vector2]) -> void:
	for target: Vector2 in targets:
		var flash: Flash = Flash.new()
		flash.kind = skill.effect
		flash.from = Vector2(target.x, SKY_Y)
		flash.to = target
		flash.color = skill.color
		_flashes.append(flash)
	queue_redraw()


func play_spirit_shot(from: Vector2, to: Vector2, color: Color) -> void:
	var flash: Flash = Flash.new()
	flash.from = from
	flash.to = to
	flash.color = color
	flash.is_spirit_shot = true
	_flashes.append(flash)
	queue_redraw()


func _process(delta: float) -> void:
	for flash: Flash in _flashes:
		flash.ttl -= delta
	_flashes = _flashes.filter(func(flash: Flash) -> bool: return flash.ttl > 0.0)
	queue_redraw()


func _draw() -> void:
	if hero != null and hero.health.has_shield():
		draw_arc(hero.position + Vector2(0.0, -20.0), 22.0, 0.0, TAU, 32, Color(1.0, 0.85, 0.3, 0.8), 2.0)
	for flash: Flash in _flashes:
		var alpha: float = clampf(flash.ttl / EFFECT_SECONDS, 0.0, 1.0)
		var color: Color = Color(flash.color, alpha)
		if flash.is_spirit_shot:
			draw_line(flash.from, flash.to, color, 2.0)
			continue
		match flash.kind:
			SkillDefinition.Effect.DAMAGE_ALL:
				_draw_bolt(flash.from, flash.to, color)
			SkillDefinition.Effect.DAMAGE_FRONT:
				var progress: float = 1.0 - alpha
				draw_circle(flash.from.lerp(flash.to, minf(progress * 2.0, 1.0)), 8.0, color)
			SkillDefinition.Effect.FREEZE_ALL:
				draw_circle(flash.to, 16.0 * (1.5 - alpha), Color(color, alpha * 0.5))


func _draw_bolt(from: Vector2, to: Vector2, color: Color) -> void:
	var points: PackedVector2Array = [from]
	for step: int in range(1, 5):
		var point: Vector2 = from.lerp(to, step / 5.0)
		points.append(point + Vector2(6.0 if step % 2 == 0 else -6.0, 0.0))
	points.append(to)
	draw_polyline(points, color, 2.0)
