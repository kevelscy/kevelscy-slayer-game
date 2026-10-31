class_name StatBlock
extends RefCounted
## Base stats plus modifiers. Resolution: (base + sum(FLAT)) * (1 + sum(PERCENT)).
##
## Scaling stats (attack, health) grow without bound and resolve to BigNumber.
## Rate stats (crit chance, crit damage, attack speed) resolve to clamped floats.

signal changed

const ATTACK: StringName = &"attack"
const HEALTH: StringName = &"health"
const CRIT_CHANCE: StringName = &"crit_chance"
const CRIT_DAMAGE: StringName = &"crit_damage"
const ATTACK_SPEED: StringName = &"attack_speed"
## Multiplier on the hero's own sword hits only (skills and spirits ignore it).
const SWORD_DAMAGE: StringName = &"sword_damage"

const DEFAULT_CRIT_DAMAGE: float = 1.5
const DEFAULT_ATTACK_SPEED: float = 1.0
const MIN_ATTACK_SPEED: float = 0.1
const MIN_CRIT_DAMAGE: float = 1.0

var _big_base: Dictionary[StringName, BigNumber] = {}
var _rate_base: Dictionary[StringName, float] = {
	CRIT_CHANCE: 0.0,
	CRIT_DAMAGE: DEFAULT_CRIT_DAMAGE,
	ATTACK_SPEED: DEFAULT_ATTACK_SPEED,
	SWORD_DAMAGE: 1.0,
}
var _modifiers: Array[StatModifier] = []


func set_base(stat: StringName, value: BigNumber) -> void:
	_big_base[stat] = value
	changed.emit()


func set_base_rate(stat: StringName, value: float) -> void:
	_rate_base[stat] = value
	changed.emit()


func add_modifier(modifier: StatModifier) -> void:
	_modifiers.append(modifier)
	changed.emit()


func remove_modifier(modifier: StatModifier) -> void:
	var index: int = _modifiers.find(modifier)
	if index == -1:
		return
	_modifiers.remove_at(index)
	changed.emit()


func get_big(stat: StringName) -> BigNumber:
	var total: BigNumber = _big_base.get(stat, BigNumber.zero())
	var percent: float = 0.0
	for modifier: StatModifier in _modifiers:
		if modifier.stat != stat:
			continue
		if modifier.kind == StatModifier.Kind.FLAT:
			total = total.add(modifier.value)
		else:
			percent += modifier.value.to_float()
	return total.mul_float(1.0 + percent)


func get_rate(stat: StringName) -> float:
	var total: float = _rate_base.get(stat, 0.0)
	var percent: float = 0.0
	for modifier: StatModifier in _modifiers:
		if modifier.stat != stat:
			continue
		if modifier.kind == StatModifier.Kind.FLAT:
			total += modifier.value.to_float()
		else:
			percent += modifier.value.to_float()
	return _clamp_rate(stat, total * (1.0 + percent))


static func _clamp_rate(stat: StringName, value: float) -> float:
	match stat:
		CRIT_CHANCE:
			return clampf(value, 0.0, 1.0)
		CRIT_DAMAGE:
			return maxf(value, MIN_CRIT_DAMAGE)
		ATTACK_SPEED:
			return maxf(value, MIN_ATTACK_SPEED)
	return value
