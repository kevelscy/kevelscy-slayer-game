extends GutTest
## Portrait: HUD, battle and skill bar stay visible above one scrollable page
## (upgrades or spirits) picked from the bottom tab bar. Landscape: skills and
## spirits in the left column, upgrades in the right one, no tab bar.

const MAIN: PackedScene = preload("res://main/main.tscn")

var main: Main


func before_each() -> void:
	main = MAIN.instantiate()
	add_child_autofree(main)


func _portrait() -> void:
	main._landscape = false
	main._reparent_panels()


func _landscape() -> void:
	main._landscape = true
	main._reparent_panels()


func test_portrait_keeps_the_skills_above_the_pages_and_the_tab_bar_at_the_bottom() -> void:
	_portrait()
	for node: Control in [main.hud, main.battle_view, main.ability_panel, main.pages, main.tab_bar]:
		assert_eq(node.get_parent(), main.portrait, node.name)
	assert_lt(main.battle_view.get_index(), main.ability_panel.get_index())
	assert_lt(main.ability_panel.get_index(), main.pages.get_index())
	assert_eq(main.tab_bar.get_index(), main.portrait.get_child_count() - 1, "tab bar at the bottom")
	assert_eq(main.upgrade_panel.get_parent(), main.page_stack)
	assert_eq(main.spirit_panel.get_parent(), main.page_stack)


func test_tab_bar_has_upgrades_spirits_and_ascension_with_upgrades_first() -> void:
	_portrait()
	var titles: Array[String] = []
	for button: Button in main.tab_bar.buttons:
		titles.append(button.text)
	assert_eq(titles, ["Mejoras", "Espíritus", "Ascensión"] as Array[String])
	assert_eq(Main.TAB_ICONS.size(), Main.TAB_TITLES.size(), "one icon per tab")
	for index: int in main.tab_bar.buttons.size():
		assert_not_null(main.tab_bar.buttons[index].icon, "%s tab has its icon" % titles[index])
		assert_true(ResourceLoader.exists(Main.TAB_ICONS[index]), Main.TAB_ICONS[index])
	assert_eq(main.tab_bar.selected, Main.TAB_UPGRADES)
	assert_true(main.upgrade_panel.visible)
	assert_false(main.spirit_panel.visible)


func test_spirits_tab_shows_the_spirits_page_only() -> void:
	_portrait()
	main.tab_bar.select(Main.TAB_SPIRITS)
	assert_true(main.spirit_panel.visible)
	assert_false(main.upgrade_panel.visible)
	main.tab_bar.select(Main.TAB_UPGRADES)
	assert_true(main.upgrade_panel.visible)
	assert_false(main.spirit_panel.visible)


func test_ascension_tab_opens_the_overlay_and_keeps_the_page() -> void:
	_portrait()
	main.tab_bar.select(Main.TAB_SPIRITS)
	main.tab_bar.select(Main.TAB_ASCENSION)
	assert_true(main.ascension_panel.visible)
	assert_eq(main.tab_bar.selected, Main.TAB_SPIRITS, "the page tab stays selected")
	assert_true(main.tab_bar.buttons[Main.TAB_SPIRITS].button_pressed)
	assert_true(main.spirit_panel.visible)


func test_pages_scroll_vertically_and_fill_the_free_height() -> void:
	_portrait()
	assert_eq(main.pages.vertical_scroll_mode, ScrollContainer.SCROLL_MODE_AUTO)
	assert_eq(main.pages.horizontal_scroll_mode, ScrollContainer.SCROLL_MODE_DISABLED)
	assert_eq(main.pages.size_flags_vertical, Control.SIZE_EXPAND_FILL)
	assert_eq(main.tab_bar.size_flags_vertical & Control.SIZE_EXPAND, 0, "the tab bar never stretches")


func test_hud_ascension_button_shows_only_in_landscape() -> void:
	_portrait()
	assert_false(main.hud.ascension_button.visible, "the Ascension tab replaces it")
	_landscape()
	assert_true(main.hud.ascension_button.visible)
	_portrait()
	assert_false(main.hud.ascension_button.visible)


func test_landscape_puts_skills_left_and_upgrades_right() -> void:
	_landscape()
	assert_eq(main.ability_panel.get_parent(), main.left_column)
	assert_eq(main.upgrade_panel.get_parent(), main.right_column)


func test_landscape_puts_spirits_under_the_skills() -> void:
	_landscape()
	assert_eq(main.spirit_panel.get_parent(), main.left_column)
	assert_lt(main.ability_panel.get_index(), main.spirit_panel.get_index())


func test_landscape_shows_both_panels_whatever_tab_was_picked() -> void:
	_portrait()
	main.tab_bar.select(Main.TAB_SPIRITS)
	_landscape()
	assert_true(main.upgrade_panel.visible)
	assert_true(main.spirit_panel.visible)
	_portrait()
	assert_eq(main.tab_bar.selected, Main.TAB_SPIRITS, "back to the page picked before")
	assert_false(main.upgrade_panel.visible)
	assert_true(main.spirit_panel.visible)


## Presses the left button at from and releases it at to through Main.handle_swipe
## (what Main._input runs); true when the release was consumed.
func _swipe(from: Vector2, to: Vector2) -> bool:
	var press: InputEventMouseButton = InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = from
	assert_false(main.handle_swipe(press), "the press is never consumed")
	var release: InputEventMouseButton = InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = to
	return main.handle_swipe(release)


func _pages_center() -> Vector2:
	await get_tree().process_frame
	var rect: Rect2 = main.pages.get_global_rect()
	assert_true(rect.has_area(), "the pages have a size to swipe on")
	return rect.get_center()


func _assert_page(index: int) -> void:
	assert_eq(main.tab_bar.selected, index, "selected tab")
	assert_true(main.tab_bar.buttons[index].button_pressed, "tab drawn selected")
	assert_eq(main.upgrade_panel.visible, index == Main.TAB_UPGRADES, "upgrades page")
	assert_eq(main.spirit_panel.visible, index == Main.TAB_SPIRITS, "spirits page")


func test_swipe_left_on_upgrades_shows_spirits_and_consumes_the_release() -> void:
	_portrait()
	var center: Vector2 = await _pages_center()
	assert_true(_swipe(center, center + Vector2(-200, 20)), "the release never presses a button")
	_assert_page(Main.TAB_SPIRITS)


func test_swipe_right_on_spirits_goes_back_to_upgrades() -> void:
	_portrait()
	main.tab_bar.select(Main.TAB_SPIRITS)
	var center: Vector2 = await _pages_center()
	assert_true(_swipe(center, center + Vector2(200, -20)))
	_assert_page(Main.TAB_UPGRADES)


func test_swipes_past_the_first_or_last_page_do_nothing() -> void:
	_portrait()
	var center: Vector2 = await _pages_center()
	assert_false(_swipe(center, center + Vector2(200, 0)), "no page before Upgrades")
	_assert_page(Main.TAB_UPGRADES)
	main.tab_bar.select(Main.TAB_SPIRITS)
	assert_false(_swipe(center, center + Vector2(-200, 0)), "never into Ascension")
	_assert_page(Main.TAB_SPIRITS)
	assert_false(main.ascension_panel.visible)


func test_short_or_vertical_drags_are_not_swipes() -> void:
	_portrait()
	var center: Vector2 = await _pages_center()
	assert_false(_swipe(center, center + Vector2(-Main.SWIPE_MIN_DISTANCE + 1.0, 0)), "too short")
	assert_false(_swipe(center, center + Vector2(-200, -101)), "mostly vertical scrolls the page")
	_assert_page(Main.TAB_UPGRADES)
	assert_true(_swipe(center, center + Vector2(-Main.SWIPE_MIN_DISTANCE, 0)), "exactly the threshold")
	_assert_page(Main.TAB_SPIRITS)


func test_swipes_starting_off_the_pages_are_ignored() -> void:
	_portrait()
	await _pages_center()
	var battle: Vector2 = main.battle_view.get_global_rect().get_center()
	assert_false(_swipe(battle, battle + Vector2(-200, 0)))
	_assert_page(Main.TAB_UPGRADES)


func test_swipes_are_ignored_in_landscape_and_under_the_ascension_overlay() -> void:
	_portrait()
	var center: Vector2 = await _pages_center()
	main.ascension_panel.open()
	assert_false(_swipe(center, center + Vector2(-200, 0)), "overlay open")
	_assert_page(Main.TAB_UPGRADES)
	main.ascension_panel.visible = false
	_landscape()
	assert_false(_swipe(center, center + Vector2(-200, 0)), "landscape")
	assert_eq(main.tab_bar.selected, Main.TAB_UPGRADES)
