class_name AbilityPanel
extends VBoxContainer
## Skill bar (five cast buttons and the auto-cast toggle) and the three spirit
## slots. Built in code because every row comes from the ability catalog.

const REFRESH_SECONDS: float = 0.1
## Each skill icon sheet has two 32x32 frames: the silver frame, then the gold one
## shown while the skill is ready. Scaled 2x with nearest filtering so the pixels
## stay square, and drawn above the button text.
const ICON_PATH: String = "res://art/icons/skill_%s.png"
const ICON_FRAME_SIZE: int = 32
const ICON_SCALE: int = 2
const SILVER: int = 0
const GOLD: int = 1
const STAT_NAMES: Dictionary[StringName, String] = {
	StatBlock.ATTACK: "Attack",
	StatBlock.HEALTH: "Health",
	StatBlock.CRIT_CHANCE: "Crit Chance",
	StatBlock.CRIT_DAMAGE: "Crit Damage",
	StatBlock.ATTACK_SPEED: "Attack Speed",
}

var skill_buttons: Array[Button] = []
## Per skill button: [silver, gold] icon textures.
var skill_icons: Array[Array] = []
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
		skill_icons.append(_icon_frames(session.skills.slots[index].definition))
		button.icon = skill_icons[index][SILVER]
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
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
		button.icon = skill_icons[index][GOLD if slot.is_ready(stage) else SILVER]
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


static func _icon_frames(skill: SkillDefinition) -> Array[Texture2D]:
	var sheet: Image = (load(ICON_PATH % skill.id) as Texture2D).get_image()
	var frames: Array[Texture2D] = []
	for frame: int in [SILVER, GOLD]:
		var image: Image = sheet.get_region(Rect2i(frame * ICON_FRAME_SIZE, 0, ICON_FRAME_SIZE, ICON_FRAME_SIZE))
		image.resize(ICON_FRAME_SIZE * ICON_SCALE, ICON_FRAME_SIZE * ICON_SCALE, Image.INTERPOLATE_NEAREST)
		frames.append(ImageTexture.create_from_image(image))
	return frames


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
