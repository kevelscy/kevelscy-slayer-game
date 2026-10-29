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



func test_tabs_show_their_icon_above_the_title() -> void:
	var icons: PackedStringArray = PackedStringArray([
		"res://art/icons/tab_upgrades.png", "res://art/icons/tab_spirits.png", "res://art/icons/tab_ascension.png",
	])
	var iconed: BottomTabBar = BottomTabBar.new()
	add_child_autofree(iconed)
	iconed.setup(PackedStringArray(["Upgrades", "Spirits", "Ascension"]), 0, icons)
	for index: int in iconed.buttons.size():
		var button: Button = iconed.buttons[index]
		assert_not_null(button.icon, "tab %d has an icon" % index)
		assert_eq(button.icon.get_size(), Vector2(48.0, 48.0), "24 px art at 2x")
		assert_eq(button.vertical_icon_alignment, VERTICAL_ALIGNMENT_TOP)
		assert_eq(button.icon_alignment, HORIZONTAL_ALIGNMENT_CENTER)
		assert_false(button.expand_icon, "integer scale, never stretched")
		assert_eq(button.text, ["Upgrades", "Spirits", "Ascension"][index], "the title stays")


func test_tab_icon_is_the_art_scaled_up_without_blending() -> void:
	var source: Image = (load("res://art/icons/tab_spirits.png") as Texture2D).get_image()
	var icon: Image = BottomTabBar.icon_texture("res://art/icons/tab_spirits.png").get_image()
	assert_eq(icon.get_size(), source.get_size() * BottomTabBar.ICON_SCALE)
	var mismatches: int = 0
	for y: int in icon.get_height():
		for x: int in icon.get_width():
			if icon.get_pixel(x, y) != source.get_pixel(x / BottomTabBar.ICON_SCALE, y / BottomTabBar.ICON_SCALE):
				mismatches += 1
	assert_eq(mismatches, 0, "every source pixel becomes a solid 2x2 block")


func test_tabs_without_icons_show_only_the_title() -> void:
	for button: Button in bar.buttons:
		assert_null(button.icon)
