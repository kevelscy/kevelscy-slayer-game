class_name SkillBar
extends RefCounted
## Five active skill slots with cooldowns, stage unlocks and auto-cast. It only
## decides when a skill fires; listeners of `cast` resolve the effect.

signal cast(slot_index: int, definition: SkillDefinition)

const SLOT_COUNT: int = 5
const AUTOCAST_UNLOCK_STAGE: int = 10

var slots: Array[SkillSlot] = []
## Player toggle; only takes effect once auto-cast is unlocked.
var autocast_enabled: bool = true


func _init(definitions: Array[SkillDefinition] = []) -> void:
	if definitions.size() > SLOT_COUNT:
		push_error("SkillBar: %d skills given, only the first %d fit" % [definitions.size(), SLOT_COUNT])
	for index: int in mini(definitions.size(), SLOT_COUNT):
		slots.append(SkillSlot.new(definitions[index]))


func tick(delta: float) -> void:
	for slot: SkillSlot in slots:
		slot.tick(delta)


func try_cast(slot_index: int, stage: int, has_target: bool) -> bool:
	if slot_index < 0 or slot_index >= slots.size():
		return false
	var slot: SkillSlot = slots[slot_index]
	if not slot.is_ready(stage) or (slot.definition.needs_target() and not has_target):
		return false
	slot.start_cooldown()
	cast.emit(slot_index, slot.definition)
	return true


func reset_cooldowns() -> void:
	for slot: SkillSlot in slots:
		slot.cooldown_remaining = 0.0


func is_autocast_unlocked(stage: int) -> bool:
	return stage >= AUTOCAST_UNLOCK_STAGE


## Casts every ready skill while the hero is fighting. Returns how many fired.
func autocast(stage: int, has_target: bool) -> int:
	if not has_target or not autocast_enabled or not is_autocast_unlocked(stage):
		return 0
	var fired: int = 0
	for index: int in slots.size():
		if try_cast(index, stage, has_target):
			fired += 1
	return fired
