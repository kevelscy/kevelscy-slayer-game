extends GutTest
## The skill bar comes before the upgrades: right under the battle in portrait
## and in the left column in landscape.

const MAIN: PackedScene = preload("res://main/main.tscn")

var main: Main


func before_each() -> void:
	main = MAIN.instantiate()
	add_child_autofree(main)


func test_portrait_shows_skills_before_upgrades() -> void:
	main._landscape = false
	main._reparent_panels()
	assert_eq(main.ability_panel.get_parent(), main.portrait)
	assert_eq(main.upgrade_panel.get_parent(), main.portrait)
	assert_lt(main.ability_panel.get_index(), main.upgrade_panel.get_index())
	assert_lt(main.battle_view.get_index(), main.ability_panel.get_index())


func test_landscape_puts_skills_left_and_upgrades_right() -> void:
	main._landscape = true
	main._reparent_panels()
	assert_eq(main.ability_panel.get_parent(), main.left_column)
	assert_eq(main.upgrade_panel.get_parent(), main.right_column)
