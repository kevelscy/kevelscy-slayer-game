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
	assert_eq(titles, ["Upgrades", "Spirits", "Ascension"] as Array[String])
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
