extends GutTest
## Each active chest modifier shows its icon, a small factor and the seconds it has
## left; it goes away when it runs out (playtest-feedback S7).

const ABILITIES: AbilityCatalog = preload("res://data/content/abilities/ability_catalog.tres")

var session: GameSession
var timers: ModifierTimers


func before_each() -> void:
	session = GameSession.new(StageBalance.new(), 10, 30.0, ABILITIES)
	timers = ModifierTimers.new()
	add_child_autofree(timers)
	timers.bind(session)


func test_no_active_modifier_shows_nothing() -> void:
	timers.refresh()
	assert_false(timers.visible)
	assert_false(timers.gold_row.visible)
	assert_false(timers.damage_row.visible)


func test_the_gold_boost_shows_the_coin_its_factor_and_its_seconds() -> void:
	session.gold_boost.apply(4.0, 60.0)
	session.gold_boost.tick(1.5)
	timers.refresh()
	assert_true(timers.visible)
	assert_true(timers.gold_row.visible)
	assert_false(timers.damage_row.visible)
	assert_eq(timers.gold_row.factor_label.text, "x4")
	assert_eq(timers.gold_row.seconds_label.text, "59s")
	assert_not_null(timers.gold_row.icon.texture)


func test_the_damage_boost_shows_the_sword_its_factor_and_its_seconds() -> void:
	session.damage_boost.apply(2.0, 45.0)
	timers.refresh()
	assert_true(timers.damage_row.visible)
	assert_false(timers.gold_row.visible)
	assert_eq(timers.damage_row.factor_label.text, "x2")
	assert_eq(timers.damage_row.seconds_label.text, "45s")
	assert_eq(timers.damage_row.icon.texture.get_width(), ModifierTimers.ICON_SIZE)


func test_both_modifiers_show_one_row_each_and_each_goes_away_when_it_ends() -> void:
	session.gold_boost.apply(6.0, 90.0)
	session.damage_boost.apply(4.0, 45.0)
	timers.refresh()
	assert_true(timers.gold_row.visible)
	assert_true(timers.damage_row.visible)
	session.damage_boost.tick(45.0)
	timers.refresh()
	assert_true(timers.gold_row.visible)
	assert_false(timers.damage_row.visible)
	session.gold_boost.tick(90.0)
	timers.refresh()
	assert_false(timers.visible)


func test_the_overlay_never_takes_input() -> void:
	assert_eq(timers.mouse_filter, Control.MOUSE_FILTER_IGNORE)
