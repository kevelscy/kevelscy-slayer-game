class_name SkillTreePanel
extends VBoxContainer
## Mejoras > Habilidades: every catalog skill under its branch title, in branch
## then catalog order. Each card shows the icon (gold frame only while bought and
## equipped, grey otherwise), name, level and state, an equip toggle and the gold
## level button. Built in code because every card comes from the ability catalog.

const ICON_SCALE: int = 2
const EQUIP_BUTTON_SIZE: Vector2 = Vector2(150.0, 60.0)
const BUY_BUTTON_SIZE: Vector2 = Vector2(170.0, 60.0)


class Entry:
	var slot: SkillSlot
	var index: int
	var card: PanelContainer
	var icon: TextureRect
	var gold_icon: Texture2D
	var grey_icon: Texture2D
	var label: Label
	var equip_button: Button
	var buy_button: Button


## One box per SkillDefinition.Branch, in enum order; its first child is the title.
var branch_boxes: Array[VBoxContainer] = []
var entries: Array[Entry] = []

var _session: GameSession


func bind(session: GameSession) -> void:
	_session = session
	for branch: int in SkillDefinition.BRANCH_NAMES.size():
		var box: VBoxContainer = VBoxContainer.new()
		box.add_child(AbilityPanel.section_title(SkillDefinition.BRANCH_NAMES[branch]))
		add_child(box)
		branch_boxes.append(box)
	for index: int in session.skills.slots.size():
		_add_entry(index, session.skills.slots[index])
	session.wallet.changed.connect(func(_currency: StringName, _total: BigNumber) -> void: refresh())
	session.skills.equipment_changed.connect(refresh)
	session.skills.leveled_up.connect(func(_index: int, _level: int) -> void: refresh())
	session.progression.stage_changed.connect(func(_stage: int) -> void: refresh())
	refresh()


func _add_entry(index: int, slot: SkillSlot) -> void:
	var entry: Entry = Entry.new()
	entry.slot = slot
	entry.index = index
	var frames: Array[Texture2D] = AbilityPanel.icon_frames(AbilityPanel.ICON_PATH % slot.definition.id, ICON_SCALE)
	entry.gold_icon = frames[AbilityPanel.GOLD]
	entry.grey_icon = SkillCard.grey(frames[AbilityPanel.SILVER])
	entry.card = PanelContainer.new()
	entry.card.theme_type_variation = GameTheme.CARD
	var box: HBoxContainer = HBoxContainer.new()
	entry.icon = TextureRect.new()
	entry.icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	entry.icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	entry.label = Label.new()
	entry.label.theme_type_variation = GameTheme.CARD_TEXT
	entry.label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entry.equip_button = Button.new()
	entry.equip_button.theme_type_variation = GameTheme.SKILL_BUTTON
	entry.equip_button.custom_minimum_size = EQUIP_BUTTON_SIZE
	entry.equip_button.focus_mode = Control.FOCUS_NONE
	entry.equip_button.pressed.connect(func() -> void: _on_equip_pressed(index))
	entry.buy_button = Button.new()
	entry.buy_button.theme_type_variation = GameTheme.BUY_BUTTON
	entry.buy_button.custom_minimum_size = BUY_BUTTON_SIZE
	entry.buy_button.focus_mode = Control.FOCUS_NONE
	entry.buy_button.icon = GameTheme.coin_texture(AbilityPanel.BUY_COIN_SIZE)
	entry.buy_button.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	entry.buy_button.pressed.connect(func() -> void: _session.try_buy_skill(index))
	for child: Control in [entry.icon, entry.label, entry.equip_button, entry.buy_button]:
		box.add_child(child)
	entry.card.add_child(box)
	branch_boxes[slot.definition.branch].add_child(entry.card)
	entries.append(entry)


func refresh() -> void:
	var stage: int = _session.progression.stage
	var bar: SkillBar = _session.skills
	for entry: Entry in entries:
		var slot: SkillSlot = entry.slot
		var equipped: bool = bar.is_equipped(entry.index)
		var state: String
		if equipped:
			state = "Equipada"
		elif slot.is_owned():
			state = "Sin equipar"
		elif slot.can_buy(stage):
			state = "Sin comprar"
		else:
			state = "Etapa %d" % slot.definition.unlock_stage
		entry.label.text = "%s  Nv %d\n%s" % [slot.definition.display_name, slot.level, state]
		entry.icon.texture = entry.gold_icon if equipped else entry.grey_icon
		entry.equip_button.text = "Quitar" if equipped else "Equipar"
		entry.equip_button.disabled = not slot.is_owned() or (not equipped and bar.equipped.size() >= SkillBar.EQUIP_LIMIT)
		var cost: BigNumber = slot.cost()
		entry.buy_button.text = NumberFormat.format(cost)
		entry.buy_button.disabled = not slot.can_buy(stage) or not _session.wallet.can_afford(GameSession.GOLD, cost)


func _on_equip_pressed(index: int) -> void:
	if not _session.skills.unequip(index):
		_session.skills.equip(index)
