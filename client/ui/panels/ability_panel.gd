class_name AbilityPanel
extends VBoxContainer
## Skill bar (five cast buttons and the auto-cast toggle) and the three spirit
## slots. Built in code because every row comes from the ability catalog.

const REFRESH_SECONDS: float = 0.1
const STAT_NAMES: Dictionary[StringName, String] = {
	StatBlock.ATTACK: "Attack",
	StatBlock.HEALTH: "Health",
	StatBlock.CRIT_CHANCE: "Crit Chance",
	StatBlock.CRIT_DAMAGE: "Crit Damage",
	StatBlock.ATTACK_SPEED: "Attack Speed",
}

var skill_buttons: Array[Button] = []
var autocast_toggle: CheckButton
var spirit_labels: Array[Label] = []

var _session: GameSession
var _refresh_elapsed: float = 0.0


func bind(session: GameSession) -> void:
	_session = session
	add_child(_title("Skills"))
	var skill_row: HFlowContainer = HFlowContainer.new()
	add_child(skill_row)
	for index: int in session.skills.slots.size():
		var button: Button = Button.new()
		button.theme_type_variation = GameTheme.SKILL_BUTTON
		button.custom_minimum_size = Vector2(140.0, 88.0)
		button.pressed.connect(func() -> void: _on_skill_pressed(index))
		skill_row.add_child(button)
		skill_buttons.append(button)
	autocast_toggle = CheckButton.new()
	autocast_toggle.button_pressed = session.skills.autocast_enabled
	autocast_toggle.toggled.connect(_on_autocast_toggled)
	add_child(autocast_toggle)
	add_child(_title("Spirits"))
	var spirit_row: HBoxContainer = HBoxContainer.new()
	add_child(spirit_row)
	for _slot: SpiritTeam.SpiritSlot in session.spirits.slots:
		var card: PanelContainer = PanelContainer.new()
		card.theme_type_variation = GameTheme.CARD
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var label: Label = Label.new()
		label.theme_type_variation = GameTheme.CARD_TEXT
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.custom_minimum_size = Vector2(0.0, 60.0)
		card.add_child(label)
		spirit_row.add_child(card)
		spirit_labels.append(label)
	refresh()


func _process(delta: float) -> void:
	if _session == null:
		return
	_refresh_elapsed += delta
	if _refresh_elapsed >= REFRESH_SECONDS:
		_refresh_elapsed = 0.0
		refresh()


func refresh() -> void:
	var stage: int = _session.progression.stage
	for index: int in skill_buttons.size():
		var slot: SkillSlot = _session.skills.slots[index]
		var button: Button = skill_buttons[index]
		var title: String = slot.definition.display_name
		if not slot.is_unlocked(stage):
			button.text = "%s\nStage %d" % [title, slot.definition.unlock_stage]
		elif slot.cooldown_remaining > 0.0:
			button.text = "%s\n%ds" % [title, ceili(slot.cooldown_remaining)]
		else:
			button.text = title
		button.disabled = not slot.is_ready(stage)
	var autocast_unlocked: bool = _session.skills.is_autocast_unlocked(stage)
	autocast_toggle.disabled = not autocast_unlocked
	autocast_toggle.text = "Auto-cast" if autocast_unlocked else (
		"Auto-cast (Stage %d)" % SkillBar.AUTOCAST_UNLOCK_STAGE
	)
	autocast_toggle.set_pressed_no_signal(_session.skills.autocast_enabled)
	for index: int in spirit_labels.size():
		var slot: SpiritTeam.SpiritSlot = _session.spirits.slots[index]
		spirit_labels[index].text = "%s\n%s" % [slot.definition.display_name, _spirit_status(slot)]


static func _spirit_status(slot: SpiritTeam.SpiritSlot) -> String:
	var spirit: SpiritDefinition = slot.definition
	if not slot.unlocked:
		return "Stage %d" % spirit.unlock_stage
	# PERCENT and FLAT rate passives are both fractions, shown as whole percents.
	return "+%d%% %s" % [roundi(spirit.passive_value * 100.0), STAT_NAMES.get(spirit.passive_stat, String(spirit.passive_stat))]


func _on_skill_pressed(index: int) -> void:
	if _session.cast_skill(index):
		refresh()


func _on_autocast_toggled(enabled: bool) -> void:
	_session.skills.autocast_enabled = enabled


static func _title(text: String) -> Label:
	var label: Label = Label.new()
	label.theme_type_variation = GameTheme.SECTION_TITLE
	label.text = text
	return label
