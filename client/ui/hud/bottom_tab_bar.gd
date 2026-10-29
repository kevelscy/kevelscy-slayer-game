class_name BottomTabBar
extends HBoxContainer
## Thumb-sized tab bar along the bottom of the portrait screen: one toggle button
## per tab sharing the width, exactly one selected (gold frame), the rest silver.

signal tab_selected(index: int)

## As tall as the skill buttons or more, so a thumb hits it without aiming.
const MIN_HEIGHT: float = 96.0

var buttons: Array[Button] = []
var selected: int = 0

var _group: ButtonGroup = ButtonGroup.new()


func setup(titles: PackedStringArray, first: int = 0) -> void:
	_group.allow_unpress = false
	for index: int in titles.size():
		var button: Button = Button.new()
		button.text = titles[index]
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


func _on_toggled(index: int, on: bool) -> void:
	if on and index != selected:
		selected = index
		tab_selected.emit(index)
