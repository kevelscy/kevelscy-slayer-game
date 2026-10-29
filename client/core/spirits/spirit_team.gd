class_name SpiritTeam
extends RefCounted
## Three companion slots. A spirit unlocks once its stage is reached, adds its
## passive to the hero stats for good and attacks on its own timer while the hero
## fights. Listeners of `attacked` resolve the hit.

signal unlocked(slot_index: int, definition: SpiritDefinition)
signal attacked(slot_index: int, definition: SpiritDefinition)

const SLOT_COUNT: int = 3


class SpiritSlot:
	var definition: SpiritDefinition
	var unlocked: bool = false
	var attack_elapsed: float = 0.0
	var passive: StatModifier


var slots: Array[SpiritSlot] = []
var _stats: StatBlock


func _init(definitions: Array[SpiritDefinition], hero_stats: StatBlock) -> void:
	_stats = hero_stats
	if definitions.size() > SLOT_COUNT:
		push_error("SpiritTeam: %d spirits given, only the first %d fit" % [definitions.size(), SLOT_COUNT])
	for index: int in mini(definitions.size(), SLOT_COUNT):
		var slot: SpiritSlot = SpiritSlot.new()
		slot.definition = definitions[index]
		slots.append(slot)


## Unlocks are permanent: a lower stage never removes a passive.
func refresh_unlocks(stage: int) -> void:
	for index: int in slots.size():
		var slot: SpiritSlot = slots[index]
		if slot.unlocked or stage < slot.definition.unlock_stage:
			continue
		slot.unlocked = true
		var spirit: SpiritDefinition = slot.definition
		slot.passive = StatModifier.new(
			spirit.passive_stat, spirit.passive_kind, BigNumber.from_float(spirit.passive_value)
		)
		_stats.add_modifier(slot.passive)
		unlocked.emit(index, slot.definition)


## Ascension: every spirit locks again and its passive leaves the hero stats.
func relock() -> void:
	for slot: SpiritSlot in slots:
		if slot.passive != null:
			_stats.remove_modifier(slot.passive)
		slot.passive = null
		slot.unlocked = false
		slot.attack_elapsed = 0.0


## A ready attack waits for a target instead of being lost. Returns attacks fired.
func tick(delta: float, has_target: bool) -> int:
	var fired: int = 0
	for index: int in slots.size():
		var slot: SpiritSlot = slots[index]
		if not slot.unlocked:
			continue
		var interval: float = slot.definition.attack_interval_seconds
		slot.attack_elapsed = minf(slot.attack_elapsed + delta, interval)
		if has_target and slot.attack_elapsed >= interval - 1e-6:
			slot.attack_elapsed = 0.0
			attacked.emit(index, slot.definition)
			fired += 1
	return fired


func expected_dps(hero_attack: BigNumber) -> BigNumber:
	var total: BigNumber = BigNumber.zero()
	for slot: SpiritSlot in slots:
		if slot.unlocked:
			var per_second: float = slot.definition.attack_power / slot.definition.attack_interval_seconds
			total = total.add(hero_attack.mul_float(per_second))
	return total
