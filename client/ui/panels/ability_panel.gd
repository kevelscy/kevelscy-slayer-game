class_name AbilityPanel
extends VBoxContainer
## Skill bar: one SkillCard per skill with its gold buy button under it, and the
## auto-cast toggle. Built in code because
## every card comes from the ability catalog. Also owns the icon sheet helpers the
## spirit panel shares.

const REFRESH_SECONDS: float = 0.1
## Each skill and spirit icon sheet has two 32x32 frames: the silver frame, then the
## gold one shown while the skill is ready or once the spirit is unlocked. Scaled with
## nearest filtering so the pixels stay square: 2x for spirits, 3x for skill cards.
const ICON_PATH: String = "res://art/icons/skill_%s.png"
const ICON_FRAME_SIZE: int = 32
const ICON_SCALE: int = 2
const CARD_SCALE: int = 3
const SILVER: int = 0
const GOLD: int = 1
const BUY_FONT_SIZE: int = 16
## Coin on the narrow buy buttons at its native 16 px, smaller than the stat upgrade one.
const BUY_COIN_SIZE: int = 16
var skill_buttons: Array[Button] = []
## Per skill: buys its first level, then the next ones, with gold.
var buy_buttons: Array[Button] = []
## Per skill button: [silver, gold] icon textures.
var skill_icons: Array[Array] = []
var autocast_toggle: CheckButton
var _session: GameSession
var _refresh_elapsed: float = 0.0


func bind(session: GameSession) -> void:
	_session = session
	add_child(section_title("Habilidades"))
	var skill_row: HFlowContainer = HFlowContainer.new()
	add_child(skill_row)
	for index: int in session.skills.slots.size():
		var frames: Array[Texture2D] = icon_frames(ICON_PATH % session.skills.slots[index].definition.id, CARD_SCALE)
		skill_icons.append(frames)
		var column: VBoxContainer = VBoxContainer.new()
		skill_row.add_child(column)
		var button: SkillCard = SkillCard.new(frames[SILVER], frames[GOLD])
		button.pressed.connect(func() -> void: _on_skill_pressed(index))
		column.add_child(button)
		skill_buttons.append(button)
		var buy: Button = Button.new()
		buy.theme_type_variation = GameTheme.BUY_BUTTON
		buy.focus_mode = Control.FOCUS_NONE
		buy.icon = GameTheme.coin_texture(BUY_COIN_SIZE)
		buy.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		buy.add_theme_font_size_override("font_size", BUY_FONT_SIZE)
		buy.pressed.connect(func() -> void: _on_buy_pressed(index))
		column.add_child(buy)
		buy_buttons.append(buy)
	autocast_toggle = CheckButton.new()
	autocast_toggle.button_pressed = session.skills.autocast_enabled
	autocast_toggle.toggled.connect(_on_autocast_toggled)
	add_child(autocast_toggle)
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
		var card: SkillCard = skill_buttons[index] as SkillCard
		var title: String = slot.definition.display_name
		if slot.is_owned():
			card.show_cooldown(title, slot.cooldown_ratio(), slot.level)
		elif slot.can_buy(stage):
			card.show_unowned(title)
		else:
			card.show_locked(title, slot.definition.unlock_stage)
		card.disabled = not slot.is_ready()
		var cost: BigNumber = slot.cost()
		buy_buttons[index].text = NumberFormat.format(cost)
		buy_buttons[index].disabled = not slot.can_buy(stage) or not _session.wallet.can_afford(GameSession.GOLD, cost)
	var autocast_unlocked: bool = _session.skills.is_autocast_unlocked(stage)
	autocast_toggle.disabled = not autocast_unlocked
	autocast_toggle.text = "Automático" if autocast_unlocked else (
		"Automático (Etapa %d)" % SkillBar.AUTOCAST_UNLOCK_STAGE
	)
	autocast_toggle.set_pressed_no_signal(_session.skills.autocast_enabled)


static func icon_frames(sheet_path: String, scale: int = ICON_SCALE) -> Array[Texture2D]:
	var sheet: Image = (load(sheet_path) as Texture2D).get_image()
	var frames: Array[Texture2D] = []
	for frame: int in [SILVER, GOLD]:
		var image: Image = sheet.get_region(Rect2i(frame * ICON_FRAME_SIZE, 0, ICON_FRAME_SIZE, ICON_FRAME_SIZE))
		image.resize(ICON_FRAME_SIZE * scale, ICON_FRAME_SIZE * scale, Image.INTERPOLATE_NEAREST)
		frames.append(ImageTexture.create_from_image(image))
	return frames


func _on_skill_pressed(index: int) -> void:
	if _session.cast_skill(index):
		refresh()


func _on_buy_pressed(index: int) -> void:
	if _session.try_buy_skill(index):
		refresh()


func _on_autocast_toggled(enabled: bool) -> void:
	_session.skills.autocast_enabled = enabled


static func section_title(text: String) -> Label:
	var label: Label = Label.new()
	label.theme_type_variation = GameTheme.SECTION_TITLE
	label.text = text
	return label
