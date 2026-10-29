extends GutTest
## Skill buttons, auto-cast toggle and spirit slots shown by the ability panel.

const ABILITIES: AbilityCatalog = preload("res://data/content/abilities/ability_catalog.tres")

var session: GameSession
var panel: AbilityPanel


func before_each() -> void:
	session = GameSession.new(StageBalance.new(), 10, 30.0, ABILITIES)
	panel = AbilityPanel.new()
	add_child_autofree(panel)
	panel.bind(session)


func test_one_button_per_skill_and_one_slot_per_spirit() -> void:
	assert_eq(panel.skill_buttons.size(), 5)
	assert_eq(panel.spirit_labels.size(), 3)


func test_locked_skill_shows_its_unlock_stage_and_is_disabled() -> void:
	assert_eq(panel.skill_buttons[1].text, "Meteor\nStage 3")
	assert_true(panel.skill_buttons[1].disabled)


func test_ready_skill_shows_its_name_and_is_enabled() -> void:
	assert_eq(panel.skill_buttons[0].text, "Thunder")
	assert_false(panel.skill_buttons[0].disabled)


func test_skill_on_cooldown_shows_the_seconds_left() -> void:
	session.tick_combat(0.0, true)
	panel.skill_buttons[0].pressed.emit()
	session.tick_combat(2.5, true)
	panel.refresh()
	assert_eq(panel.skill_buttons[0].text, "Thunder\n6s")
	assert_true(panel.skill_buttons[0].disabled)


func test_pressing_a_ready_skill_casts_it() -> void:
	watch_signals(session.skills)
	session.tick_combat(0.0, true)
	panel.skill_buttons[0].pressed.emit()
	assert_signal_emitted_with_parameters(session.skills, "cast", [0, ABILITIES.skills[0]])


func test_autocast_toggle_is_locked_until_stage_ten() -> void:
	assert_true(panel.autocast_toggle.disabled)
	assert_eq(panel.autocast_toggle.text, "Auto-cast (Stage 10)")
	session.progression.restore_stage(10)
	panel.refresh()
	assert_false(panel.autocast_toggle.disabled)
	assert_eq(panel.autocast_toggle.text, "Auto-cast")
	assert_true(panel.autocast_toggle.button_pressed)


func test_autocast_toggle_switches_the_skill_bar() -> void:
	session.progression.restore_stage(10)
	panel.refresh()
	panel.autocast_toggle.toggled.emit(false)
	assert_false(session.skills.autocast_enabled)
	panel.autocast_toggle.toggled.emit(true)
	assert_true(session.skills.autocast_enabled)


func test_spirit_slots_show_lock_stage_or_passive() -> void:
	assert_eq(panel.spirit_labels[0].text, "Wisp\nStage 2")
	session.progression.restore_stage(6)
	panel.refresh()
	assert_eq(panel.spirit_labels[0].text, "Wisp\n+10% Attack")
	assert_eq(panel.spirit_labels[1].text, "Ember Fox\n+5% Crit Chance")
	assert_eq(panel.spirit_labels[2].text, "Frost Owl\nStage 10")
