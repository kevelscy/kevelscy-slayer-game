class_name SkillBar
extends RefCounted
## Six active skill slots with cooldowns, levels and auto-cast. Only bought skills
## fire. It only decides when a skill fires; listeners of `cast` resolve the effect.

signal cast(slot_index: int, definition: SkillDefinition)
signal leveled_up(slot_index: int, level: int)

const SLOT_COUNT: int = 6
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


func try_cast(slot_index: int, has_target: bool) -> bool:
	if slot_index < 0 or slot_index >= slots.size():
		return false
	var slot: SkillSlot = slots[slot_index]
	if not slot.is_ready() or (slot.definition.needs_target() and not has_target):
		return false
	slot.start_cooldown()
	cast.emit(slot_index, slot.definition)
	return true


## Pays the next level of a slot from the wallet. False when the slot does not
## exist, its first level needs a later stage or the gold is short.
func try_buy(slot_index: int, stage: int, wallet: CurrencyWallet, currency: StringName) -> bool:
	if slot_index < 0 or slot_index >= slots.size():
		return false
	var slot: SkillSlot = slots[slot_index]
	if not slot.can_buy(stage) or not wallet.try_spend(currency, slot.cost()):
		return false
	slot.level += 1
	leveled_up.emit(slot_index, slot.level)
	return true


## Skill id to level, 0 for skills not bought.
func levels() -> Dictionary[StringName, int]:
	var result: Dictionary[StringName, int] = {}
	for slot: SkillSlot in slots:
		result[slot.definition.id] = slot.level
	return result


## Level of the skill with this id, 0 when not bought or not on the bar.
func level_of(skill_id: StringName) -> int:
	for slot: SkillSlot in slots:
		if slot.definition.id == skill_id:
			return slot.level
	return 0


## Restores saved levels: missing ids mean not bought, unknown ids are ignored and
## negative levels clamp to 0.
func set_levels(saved: Dictionary[String, int]) -> void:
	for slot: SkillSlot in slots:
		slot.level = maxi(saved.get(String(slot.definition.id), 0), 0)


## Level 1 for every skill not bought yet whose unlock stage is reached; it carries
## saves from before skills were bought over to the new rules.
func grant_reached(stage: int) -> void:
	for slot: SkillSlot in slots:
		if not slot.is_owned() and stage >= slot.definition.unlock_stage:
			slot.level = 1


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
		if try_cast(index, has_target):
			fired += 1
	return fired
