class_name BottomTabBar
extends HBoxContainer
## Thumb-sized tab bar along the bottom of the portrait screen: one toggle button
## per tab sharing the width, exactly one selected (gold frame), the rest silver.
## Each tab may show a pixel-art icon above its title.

signal tab_selected(index: int)

## As tall as the skill buttons or more, so a thumb hits it without aiming.
const MIN_HEIGHT: float = 96.0
## Tab icons are 24 px art drawn at this whole-number scale.
const ICON_SCALE: int = 2

var buttons: Array[Button] = []
var selected: int = 0

var _group: ButtonGroup = ButtonGroup.new()


## icon_paths is empty or holds one icon per title.
func setup(titles: PackedStringArray, first: int = 0, icon_paths: PackedStringArray = []) -> void:
	_group.allow_unpress = false
	for index: int in titles.size():
		var button: Button = Button.new()
		button.text = titles[index]
		if not icon_paths.is_empty():
			button.icon = icon_texture(icon_paths[index])
			button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
			button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		button.toggle_mode = true
		button.button_group = _group
		button.theme_type_variation = GameTheme.TAB_BUTTON
		button.custom_minimum_size = Vector2(0.0, MIN_HEIGHT)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		# Tabs are tapped, never reached by keyboard focus.
		button.focus_mode = Control.FOCUS_NONE
		button.toggled.connect(func(on: bool) -> void: _on_toggled(index, on))
		add_child(button)
		buttons.append(button)
	select(first, false)


## Selects a tab; notify = false changes it without emitting tab_selected.
func select(index: int, notify: bool = true) -> void:
	selected = index
	buttons[index].set_pressed_no_signal(true)
	# set_pressed_no_signal skips the group update, so clear the others by hand.
	for other: int in buttons.size():
		if other != index:
			buttons[other].set_pressed_no_signal(false)
	if notify:
		tab_selected.emit(index)


## The icon art scaled up by ICON_SCALE with nearest sampling, so it stays crisp.
static func icon_texture(path: String) -> Texture2D:
	var image: Image = (load(path) as Texture2D).get_image()
	image.resize(image.get_width() * ICON_SCALE, image.get_height() * ICON_SCALE, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(image)


func _on_toggled(index: int, on: bool) -> void:
	if on and index != selected:
		selected = index
		tab_selected.emit(index)
