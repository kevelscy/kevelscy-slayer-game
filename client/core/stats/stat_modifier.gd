class_name StatModifier
extends RefCounted
## A single bonus applied to one stat. FLAT adds to the base value; PERCENT adds a
## fraction (0.1 = +10%) to the multiplier. Identity matters: remove the same instance.

enum Kind { FLAT, PERCENT }

var stat: StringName
var kind: Kind
var value: BigNumber


func _init(target_stat: StringName, modifier_kind: Kind, amount: BigNumber) -> void:
	stat = target_stat
	kind = modifier_kind
	value = amount


static func flat(target_stat: StringName, amount: float) -> StatModifier:
	return StatModifier.new(target_stat, Kind.FLAT, BigNumber.from_float(amount))


static func flat_big(target_stat: StringName, amount: BigNumber) -> StatModifier:
	return StatModifier.new(target_stat, Kind.FLAT, amount)


static func percent(target_stat: StringName, fraction: float) -> StatModifier:
	return StatModifier.new(target_stat, Kind.PERCENT, BigNumber.from_float(fraction))
