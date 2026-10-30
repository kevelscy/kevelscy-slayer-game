extends GutTest
## The HUD speaker button mutes and unmutes the sound effects and keeps the choice.

const MAIN: PackedScene = preload("res://main/main.tscn")

var main: Main


func _start_main() -> void:
	main = MAIN.instantiate()
	add_child_autofree(main)


func after_each() -> void:
	GameState.set_sfx_muted(false)


func _saved_mute() -> bool:
	var reloaded: SettingsStore = SettingsStore.new(GameState.settings.path)
	reloaded.load_settings()
	return reloaded.sfx_muted


func test_the_button_starts_showing_sound_on() -> void:
	_start_main()
	var button: Button = main.hud.sound_button
	assert_true(button.toggle_mode)
	assert_false(button.button_pressed)
	assert_eq(button.icon.get_size(), Vector2(48.0, 48.0), "24 px art drawn at 2x")
	assert_eq(button.tooltip_text, "Silenciar efectos")
	assert_eq(button.focus_mode, Control.FOCUS_NONE)


func test_a_tap_mutes_the_effects_and_keeps_the_choice() -> void:
	_start_main()
	var button: Button = main.hud.sound_button
	var on_icon: Texture2D = button.icon
	button.button_pressed = true
	assert_true(SfxPlayer.is_muted(), "the SFX bus is muted")
	assert_true(GameState.settings.sfx_muted)
	assert_true(_saved_mute(), "the mute is saved")
	assert_ne(button.icon, on_icon, "the icon shows sound off")
	assert_eq(button.tooltip_text, "Activar efectos")


func test_a_second_tap_unmutes_the_effects() -> void:
	_start_main()
	var button: Button = main.hud.sound_button
	button.button_pressed = true
	button.button_pressed = false
	assert_false(SfxPlayer.is_muted())
	assert_false(_saved_mute())
	assert_eq(button.tooltip_text, "Silenciar efectos")


func test_a_saved_mute_shows_on_the_button_at_start() -> void:
	GameState.set_sfx_muted(true)
	_start_main()
	var button: Button = main.hud.sound_button
	assert_true(button.button_pressed)
	assert_eq(button.tooltip_text, "Activar efectos")
	assert_true(SfxPlayer.is_muted(), "starting does not unmute")
