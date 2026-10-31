class_name AbilityEffects
extends Node2D
## Placeholder VFX drawn with primitives: lightning bolts, meteors, frost bursts,
## wind slashes, thrown ice blocks, flame waves, thick barrage bolts, spirit shots, the
## hero's shield ring and heal crosses. Effects are short-lived and visual only.

const EFFECT_SECONDS: float = 0.35
const SKY_Y: float = -10.0
## Thrown skills (ice block) leave from the hero's hand.
const HAND_OFFSET: Vector2 = Vector2(10.0, -18.0)
const ICE_BLOCK_SIZE: float = 9.0
## Heal crosses rising around the hero while Curación lasts (palette Turquesa).
const HEAL_COLOR: Color = Color8(19, 204, 189)
const HEAL_CROSS_OFFSETS: Array[Vector2] = [Vector2(-12.0, -10.0), Vector2(12.0, -18.0), Vector2(-4.0, -30.0)]
## Flame wave crescent, at hero chest height, in palette fire colors (Rojo vivo, Naranja 3, Amarillo vivo).
const WAVE_Y: float = 154.0
const WAVE_RADIUS: float = 18.0
const WAVE_COLORS: Array[Color] = [Color8(244, 23, 11), Color8(244, 144, 6), Color8(253, 229, 4)]


class Flash:
	var kind: SkillDefinition.Effect
	var from: Vector2
	var to: Vector2
	var color: Color
	var ttl: float = EFFECT_SECONDS
	var is_spirit_shot: bool = false


var hero: Hero
var _flashes: Array[Flash] = []
## Owned by BattleWorld; drawn here while they cross the lane.
var flame_waves: Array[FlameWave] = []


func play_skill(skill: SkillDefinition, targets: Array[Vector2]) -> void:
	for target: Vector2 in targets:
		var flash: Flash = Flash.new()
		flash.kind = skill.effect
		flash.from = Vector2(target.x, SKY_Y)
		if skill.effect == SkillDefinition.Effect.THROW_FRONT and hero != null:
			flash.from = hero.position + HAND_OFFSET
		flash.to = target
		flash.color = skill.color
		_flashes.append(flash)
	queue_redraw()


## The newest effect still playing, or null.
func last_flash() -> Flash:
	return null if _flashes.is_empty() else _flashes.back()


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
	if hero != null and hero.health.is_regenerating():
		_draw_heal_crosses(hero.health.regen_seconds)
	for wave: FlameWave in flame_waves:
		_draw_flame_wave(wave.x)
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
			SkillDefinition.Effect.DASH:
				_draw_wind_slash(flash.to, color, 1.0 - alpha)
			SkillDefinition.Effect.BARRAGE:
				_draw_bolt(flash.from, flash.to, color, 4.0)
				_draw_bolt(flash.from, flash.to, Color(Color.WHITE, alpha), 1.0)
			SkillDefinition.Effect.THROW_FRONT:
				_draw_ice_block(flash.from.lerp(flash.to + Vector2(0.0, -12.0), minf((1.0 - alpha) * 2.0, 1.0)), color)


func _draw_bolt(from: Vector2, to: Vector2, color: Color, width: float = 2.0) -> void:
	var points: PackedVector2Array = [from]
	for step: int in range(1, 5):
		var point: Vector2 = from.lerp(to, step / 5.0)
		points.append(point + Vector2(6.0 if step % 2 == 0 else -6.0, 0.0))
	points.append(to)
	draw_polyline(points, color, width)


## A Getsuga-like crescent bulging forward: red rim, orange body, yellow core.
func _draw_flame_wave(x: float) -> void:
	var center: Vector2 = Vector2(x - WAVE_RADIUS, WAVE_Y)
	var widths: Array[float] = [7.0, 4.0, 1.5]
	for index: int in WAVE_COLORS.size():
		var spread: float = PI * (0.4 - 0.05 * index)
		draw_arc(center, WAVE_RADIUS - index, -spread, spread, 16, WAVE_COLORS[index], widths[index])


## A square block with a white top-left light and a dark outline.
func _draw_ice_block(center: Vector2, color: Color) -> void:
	var half: float = ICE_BLOCK_SIZE / 2.0
	var block: Rect2 = Rect2(center - Vector2(half, half), Vector2(ICE_BLOCK_SIZE, ICE_BLOCK_SIZE))
	draw_rect(block, color)
	draw_rect(Rect2(block.position + Vector2(1.0, 1.0), Vector2(3.0, 2.0)), Color(Color.WHITE, color.a))
	draw_rect(block, Color(0.03, 0.28, 0.37, color.a), false, 1.0)


## Three plus signs drifting up around the hero, looping every second.
func _draw_heal_crosses(seconds_left: float) -> void:
	for index: int in HEAL_CROSS_OFFSETS.size():
		var phase: float = fposmod(seconds_left + index / 3.0, 1.0)
		var at: Vector2 = hero.position + HEAL_CROSS_OFFSETS[index] + Vector2(0.0, -10.0 * (1.0 - phase))
		var color: Color = Color(HEAL_COLOR, phase)
		draw_rect(Rect2(at - Vector2(1.0, 3.0), Vector2(2.0, 6.0)), color)
		draw_rect(Rect2(at - Vector2(3.0, 1.0), Vector2(6.0, 2.0)), color)


## Three speed lines trailing the stab plus a diagonal cut across the enemy.
func _draw_wind_slash(at: Vector2, color: Color, progress: float) -> void:
	var center: Vector2 = at + Vector2(0.0, -14.0)
	for row: int in 3:
		var y: float = center.y - 8.0 + 8.0 * row
		var length: float = 40.0 * (1.0 - progress)
		draw_line(Vector2(center.x - 14.0 - length, y), Vector2(center.x - 14.0, y), color, 2.0)
	var cut: Vector2 = Vector2(10.0, -10.0) * (0.5 + progress)
	draw_line(center - cut, center + cut, Color(Color.WHITE, color.a), 2.0)
