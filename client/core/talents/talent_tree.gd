class_name TalentTree
extends RefCounted
## Talent levels and the ascension shards that buy them. Buying level n + 1 costs
## n + 1 shards. Each talent keeps one modifier on the hero stats, replaced when
## its level changes; the gold talent feeds gold_multiplier() instead.

signal leveled_up(talent_id: StringName, level: int)

var shards: int = 0

var _definitions: Dictionary[StringName, TalentDefinition] = {}
var _levels: Dictionary[StringName, int] = {}
var _modifiers: Dictionary[StringName, StatModifier] = {}
var _stats: StatBlock


func _init(definitions: Array[TalentDefinition], hero_stats: StatBlock) -> void:
	_stats = hero_stats
	for definition: TalentDefinition in definitions:
		_definitions[definition.id] = definition
		_levels[definition.id] = 0


func definitions() -> Array[TalentDefinition]:
	var result: Array[TalentDefinition] = []
	result.assign(_definitions.values())
	return result


func definition(talent_id: StringName) -> TalentDefinition:
	return _definitions.get(talent_id)


func level(talent_id: StringName) -> int:
	return _levels.get(talent_id, 0)


func levels() -> Dictionary[StringName, int]:
	return _levels.duplicate()


func next_cost(talent_id: StringName) -> int:
	return level(talent_id) + 1


func is_maxed(talent_id: StringName) -> bool:
	return level(talent_id) >= _definitions[talent_id].max_level


func is_unlocked(talent_id: StringName) -> bool:
	var talent: TalentDefinition = _definitions[talent_id]
	return talent.requires.is_empty() or level(talent.requires) >= talent.requires_level


func try_buy(talent_id: StringName) -> bool:
	if not _definitions.has(talent_id) or is_maxed(talent_id) or not is_unlocked(talent_id):
		return false
	var cost: int = next_cost(talent_id)
	if shards < cost:
		return false
	shards -= cost
	_set_level(talent_id, level(talent_id) + 1)
	return true


## Restores saved levels keyed by talent id as in SaveData.talents: unknown ids
## are ignored, levels clamp to each max and talents missing from `saved` drop to
## 0. Prerequisites are not re-checked.
func set_levels(saved: Dictionary[String, int]) -> void:
	for talent: TalentDefinition in _definitions.values():
		_set_level(talent.id, clampi(saved.get(String(talent.id), 0), 0, talent.max_level))


func gold_multiplier() -> float:
	var bonus: float = 0.0
	for talent: TalentDefinition in _definitions.values():
		if talent.stat == TalentDefinition.GOLD_GAIN:
			bonus += talent.per_level * _levels[talent.id]
	return 1.0 + bonus


func _set_level(talent_id: StringName, new_level: int) -> void:
	var changed: bool = new_level != level(talent_id)
	_levels[talent_id] = new_level
	var talent: TalentDefinition = _definitions[talent_id]
	if talent.stat != TalentDefinition.GOLD_GAIN:
		if _modifiers.has(talent_id):
			_stats.remove_modifier(_modifiers[talent_id])
			_modifiers.erase(talent_id)
		if new_level > 0:
			var modifier: StatModifier = StatModifier.new(
				talent.stat, talent.kind, BigNumber.from_float(talent.per_level * new_level)
			)
			_modifiers[talent_id] = modifier
			_stats.add_modifier(modifier)
	if changed:
		leveled_up.emit(talent_id, new_level)
