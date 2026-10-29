extends GutTest
## The main screen opens the ascension overlay from the HUD button; without the
## --ascension-panel dev flag the overlay starts hidden.

const MAIN: PackedScene = preload("res://main/main.tscn")

var main: Main


func before_each() -> void:
	main = MAIN.instantiate()
	add_child_autofree(main)


func test_ascension_panel_starts_hidden_without_the_dev_flag() -> void:
	assert_false(main.ascension_panel.visible)


func test_hud_ascension_button_opens_the_panel() -> void:
	main.hud.ascension_button.pressed.emit()
	assert_true(main.ascension_panel.visible)
