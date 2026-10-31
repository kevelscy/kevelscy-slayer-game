class_name SkillBar
extends RefCounted
## One slot per catalog skill with cooldowns, levels and auto-cast. Up to EQUIP_LIMIT
## bought skills are equipped and only they fire. It only decides when a skill fires;
## listeners of `cast` resolve the effect.

signal cast(slot_index: int, definition: SkillDefinition)
signal leveled_up(slot_index: int, level: int)
signal equipment_changed

const EQUIP_LIMIT: int = 8
const AUTOCAST_UNLOCK_STAGE: int = 10

var slots: Array[SkillSlot] = []
## Slot indices of the equipped skills, in the order they were equipped.
var equipped: Array[int] = []
## Player toggle; only takes effect once auto-cast is unlocked.
var autocast_enabled: bool = true


func _init(definitions: Array[SkillDefinition] = []) -> void:
	for definition: SkillDefinition in definitions:
		slots.append(SkillSlot.new(definition))


func tick(delta: float) -> void:
	for slot: SkillSlot in slots:
		slot.tick(delta)


func try_cast(slot_index: int, has_target: bool) -> bool:
	if slot_index < 0 or slot_index >= slots.size():
		return false
	var slot: SkillSlot = slots[slot_index]
	if not is_equipped(slot_index) or not slot.is_ready() or (slot.definition.needs_target() and not has_target):
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
	_equip_first_level(slot_index)
	leveled_up.emit(slot_index, slot.level)
	return true


## Gives a slot one more level for free (a chest prize), even its first one.
func grant_level(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= slots.size():
		return
	slots[slot_index].level += 1
	_equip_first_level(slot_index)
	leveled_up.emit(slot_index, slots[slot_index].level)


func is_equipped(slot_index: int) -> bool:
	return slot_index in equipped


## Equips a bought, unequipped skill when a slot is free. False otherwise.
func equip(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= slots.size() or not slots[slot_index].is_owned():
		return false
	if is_equipped(slot_index) or equipped.size() >= EQUIP_LIMIT:
		return false
	equipped.append(slot_index)
	equipment_changed.emit()
	return true


func unequip(slot_index: int) -> bool:
	if not is_equipped(slot_index):
		return false
	equipped.erase(slot_index)
	equipment_changed.emit()
	return true


## Equips the first EQUIP_LIMIT bought skills in catalog order (saves without an
## equipped list).
func equip_owned() -> void:
	equipped.clear()
	for index: int in slots.size():
		if slots[index].is_owned() and equipped.size() < EQUIP_LIMIT:
			equipped.append(index)
	equipment_changed.emit()


## Restores a saved equipped list: unknown, unbought and repeated ids are skipped,
## and only the first EQUIP_LIMIT are kept.
func set_equipped(saved: Array[String]) -> void:
	equipped.clear()
	for skill_id: String in saved:
		var index: int = _index_of(StringName(skill_id))
		if index >= 0 and slots[index].is_owned() and not is_equipped(index) and equipped.size() < EQUIP_LIMIT:
			equipped.append(index)
	equipment_changed.emit()


func equipped_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for index: int in equipped:
		result.append(slots[index].definition.id)
	return result


func _index_of(skill_id: StringName) -> int:
	for index: int in slots.size():
		if slots[index].definition.id == skill_id:
			return index
	return -1


func _equip_first_level(slot_index: int) -> void:
	if slots[slot_index].level == 1:
		equip(slot_index)


## The bought slot with the lowest level (the first one on a tie), or slot 0 when
## nothing is bought yet.
func lowest_owned_index() -> int:
	var best: int = -1
	for index: int in slots.size():
		if slots[index].is_owned() and (best < 0 or slots[index].level < slots[best].level):
			best = index
	return maxi(best, 0)


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
