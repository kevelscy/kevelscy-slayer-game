class_name BuffTracker
extends RefCounted
## Timed stat modifiers on one StatBlock. Reapplying a buff by id refreshes its
## duration instead of stacking.

class ActiveBuff:
	var modifiers: Array[StatModifier]
	var remaining: float


var _stats: StatBlock
var _active: Dictionary[StringName, ActiveBuff] = {}


func _init(stats: StatBlock) -> void:
	_stats = stats


func apply(id: StringName, modifiers: Array[StatModifier], seconds: float) -> void:
	_remove(id)
	var buff: ActiveBuff = ActiveBuff.new()
	buff.modifiers = modifiers
	buff.remaining = seconds
	_active[id] = buff
	for modifier: StatModifier in modifiers:
		_stats.add_modifier(modifier)


func tick(delta: float) -> void:
	for id: StringName in _active.keys():
		var buff: ActiveBuff = _active[id]
		buff.remaining -= delta
		if buff.remaining <= 1e-6:
			_remove(id)


func is_active(id: StringName) -> bool:
	return _active.has(id)


func is_empty() -> bool:
	return _active.is_empty()


func remaining(id: StringName) -> float:
	return _active[id].remaining if _active.has(id) else 0.0


func clear() -> void:
	for id: StringName in _active.keys():
		_remove(id)


func _remove(id: StringName) -> void:
	if not _active.has(id):
		return
	for modifier: StatModifier in _active[id].modifiers:
		_stats.remove_modifier(modifier)
	_active.erase(id)
