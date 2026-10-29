extends GutTest
## Bottom tab bar: one big toggle button per tab, exactly one selected.

var bar: BottomTabBar


func before_each() -> void:
	bar = BottomTabBar.new()
	add_child_autofree(bar)
	bar.setup(PackedStringArray(["Upgrades", "Spirits", "Ascension"]))
	watch_signals(bar)


func test_one_tab_button_per_title_with_the_first_selected() -> void:
	assert_eq(bar.buttons.size(), 3)
	assert_eq(bar.buttons[1].text, "Spirits")
	assert_eq(bar.selected, 0)
	assert_true(bar.buttons[0].button_pressed)
	assert_false(bar.buttons[1].button_pressed)


func test_pressing_a_tab_selects_it_alone_and_reports_it() -> void:
	bar.buttons[1].button_pressed = true
	assert_eq(bar.selected, 1)
	assert_false(bar.buttons[0].button_pressed)
	assert_signal_emitted_with_parameters(bar, "tab_selected", [1])


func test_tapping_the_selected_tab_keeps_it_selected() -> void:
	# Godot ignores a tap that would unpress a toggle in a group without allow_unpress.
	var group: ButtonGroup = bar.buttons[0].button_group
	assert_not_null(group)
	assert_false(group.allow_unpress, "a tab never unselects itself")
	for button: Button in bar.buttons:
		assert_true(button.toggle_mode)
		assert_eq(button.button_group, group, "one group for every tab")


func test_select_without_notify_changes_the_tab_silently() -> void:
	bar.select(2, false)
	assert_eq(bar.selected, 2)
	assert_true(bar.buttons[2].button_pressed)
	assert_signal_not_emitted(bar, "tab_selected")
	bar.select(1)
	assert_signal_emitted_with_parameters(bar, "tab_selected", [1])


func test_tabs_are_thumb_sized_and_share_the_width() -> void:
	for button: Button in bar.buttons:
		assert_gte(button.custom_minimum_size.y, BottomTabBar.MIN_HEIGHT)
		assert_gte(BottomTabBar.MIN_HEIGHT, 88.0, "at least as tall as the skill buttons")
		assert_eq(button.size_flags_horizontal, Control.SIZE_EXPAND_FILL)
		assert_eq(button.theme_type_variation, GameTheme.TAB_BUTTON)
		assert_eq(button.focus_mode, Control.FOCUS_NONE)

