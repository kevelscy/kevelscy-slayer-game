class_name AbilityPanel
extends VBoxContainer
## Skill bar: one SkillCard per equipped skill with its gold buy button under it, in a
## single row carousel between two gold arrows, and the auto-cast toggle. The row shows
## the equipped skills in equipped order, as many as fit the width; an arrow greys out
## when that side has no more skills.
## Built in code because every card comes from the ability catalog. Also owns the
## icon sheet helpers the spirit panel shares.

const REFRESH_SECONDS: float = 0.1
## Each skill and spirit icon sheet has two 32x32 frames: the silver frame, then the
## gold one shown while the skill is ready or once the spirit is unlocked. Scaled with
## nearest filtering so the pixels stay square: 2x for spirits, 4x for skill cards.
const ICON_PATH: String = "res://art/icons/skill_%s.png"
const ICON_FRAME_SIZE: int = 32
const ICON_SCALE: int = 2
const CARD_SCALE: int = 4
const CARD_SIZE: float = ICON_FRAME_SIZE * CARD_SCALE
const CARD_SEPARATION: int = 8
## Arrow buttons at both ends of the carousel row: a triangle tinted gold, grey when
## that side has no more skills.
const ARROW_WIDTH: float = 40.0
const ARROW_ICON_SIZE: Vector2i = Vector2i(20, 32)
const ARROW_GREY: Color = Color(0.45, 0.45, 0.48)
const SILVER: int = 0
const GOLD: int = 1
const BUY_FONT_SIZE: int = 16
## Coin on the narrow buy buttons at its native 16 px, smaller than the stat upgrade one.
const BUY_COIN_SIZE: int = 16
var skill_buttons: Array[Button] = []
## Per skill: the column holding its card and its buy button.
var skill_columns: Array[VBoxContainer] = []
var carousel_row: HBoxContainer
var cards_row: HBoxContainer
var left_arrow: Button
var right_arrow: Button
## Shown instead of cards while no skill is equipped.
var empty_hint: Label
## Carousel window: the first shown skill and how many fit.
var first_shown: int = 0
var shown_count: int = 1
## Per skill: buys its first level, then the next ones, with gold.
var buy_buttons: Array[Button] = []
## Per skill button: [silver, gold] icon textures.
var skill_icons: Array[Array] = []
var autocast_toggle: CheckButton
var _session: GameSession
var _refresh_elapsed: float = 0.0
## Width of the last fit, so equipping refits to the same room.
var _fit_width: float = 0.0


func bind(session: GameSession) -> void:
	_session = session
	add_child(section_title("Habilidades"))
	carousel_row = HBoxContainer.new()
	carousel_row.add_theme_constant_override("separation", CARD_SEPARATION)
	add_child(carousel_row)
	left_arrow = _arrow(true)
	left_arrow.pressed.connect(func() -> void: scroll(-1))
	carousel_row.add_child(left_arrow)
	cards_row = HBoxContainer.new()
	cards_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards_row.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_row.add_theme_constant_override("separation", CARD_SEPARATION)
	carousel_row.add_child(cards_row)
	empty_hint = Label.new()
	empty_hint.theme_type_variation = GameTheme.CARD_TEXT
	empty_hint.text = "Equipa habilidades en Mejoras > Habilidades"
	empty_hint.custom_minimum_size.y = CARD_SIZE
	empty_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cards_row.add_child(empty_hint)
	right_arrow = _arrow(false)
	right_arrow.pressed.connect(func() -> void: scroll(1))
	carousel_row.add_child(right_arrow)
	for index: int in session.skills.slots.size():
		var frames: Array[Texture2D] = icon_frames(ICON_PATH % session.skills.slots[index].definition.id, CARD_SCALE)
		skill_icons.append(frames)
		var column: VBoxContainer = VBoxContainer.new()
		cards_row.add_child(column)
		skill_columns.append(column)
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
	session.skills.equipment_changed.connect(_on_equipment_changed)
	resized.connect(func() -> void: fit_cards(size.x))
	fit_cards(size.x)
	_on_equipment_changed()
	refresh()


## Shows as many equipped skill cards as fit in width, always at least one, and keeps
## the window inside the equipped list.
func fit_cards(width: float) -> void:
	_fit_width = width
	var room: float = width - 2.0 * (ARROW_WIDTH + CARD_SEPARATION)
	var fitting: int = floori((room + CARD_SEPARATION) / (CARD_SIZE + CARD_SEPARATION))
	shown_count = clampi(fitting, 1, maxi(_session.skills.equipped.size(), 1))
	_show_window()


## Moves the carousel window by step skills, stopping at both ends.
func scroll(step: int) -> void:
	first_shown += step
	_show_window()


func _show_window() -> void:
	var equipped: Array[int] = _session.skills.equipped
	first_shown = clampi(first_shown, 0, maxi(equipped.size() - shown_count, 0))
	for column: VBoxContainer in skill_columns:
		column.visible = false
	for position: int in equipped.size():
		skill_columns[equipped[position]].visible = position >= first_shown and position < first_shown + shown_count
	empty_hint.visible = equipped.is_empty()
	left_arrow.disabled = first_shown == 0
	right_arrow.disabled = first_shown + shown_count >= equipped.size()


## Puts the equipped columns first, in equipped order, then refits the window.
func _on_equipment_changed() -> void:
	var equipped: Array[int] = _session.skills.equipped
	for position: int in equipped.size():
		cards_row.move_child(skill_columns[equipped[position]], position)
	fit_cards(_fit_width)


func _arrow(points_left: bool) -> Button:
	var arrow: Button = Button.new()
	arrow.focus_mode = Control.FOCUS_NONE
	arrow.custom_minimum_size = Vector2(ARROW_WIDTH, CARD_SIZE)
	arrow.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	arrow.icon = arrow_texture(points_left)
	arrow.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for style: String in ["normal", "hover", "pressed", "disabled", "focus", "hover_pressed"]:
		arrow.add_theme_stylebox_override(style, StyleBoxEmpty.new())
	for state: String in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_hover_pressed_color", "icon_focus_color"]:
		arrow.add_theme_color_override(state, GameTheme.TITLE_GOLD)
	arrow.add_theme_color_override("icon_disabled_color", ARROW_GREY)
	return arrow


## White triangle with a dark 1 px outline; the button tints the white part.
static func arrow_texture(points_left: bool) -> Texture2D:
	var image: Image = Image.create_empty(ARROW_ICON_SIZE.x, ARROW_ICON_SIZE.y, false, Image.FORMAT_RGBA8)
	var half: float = ARROW_ICON_SIZE.y / 2.0
	for y: int in ARROW_ICON_SIZE.y:
		var reach: float = ARROW_ICON_SIZE.x * (1.0 - absf(y + 0.5 - half) / half)
		for x: int in ARROW_ICON_SIZE.x:
			var column: int = ARROW_ICON_SIZE.x - 1 - x if points_left else x
			if column + 0.5 > reach:
				continue
			var edge: bool = column + 1.5 > reach or y == 0 or y == ARROW_ICON_SIZE.y - 1 or column == 0
			image.set_pixel(x, y, GameTheme.TEXT_OUTLINE if edge else Color.WHITE)
	return ImageTexture.create_from_image(image)


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
