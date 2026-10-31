extends GutTest
## Main wires chests: a picked chest spins the roulette, the battle view shows the
## active modifiers top-right and the reveal plays a sound (bonuses S1, S2;
## playtest-feedback S7).

const MAIN: PackedScene = preload("res://main/main.tscn")

var main: Main
var clock_msec: int = 0


func before_each() -> void:
	main = MAIN.instantiate()
	add_child_autofree(main)
	GameState.session.gold_boost.clear()
	GameState.session.damage_boost.clear()
	# Each sound plays a second after the previous one, outside every minimum interval.
	main.sfx.clock = func() -> int:
		clock_msec += 1000
		return clock_msec
	watch_signals(main.sfx)


func test_a_picked_chest_spins_the_roulette() -> void:
	assert_false(main.chest_roulette.visible)
	main.battle_world.chest_picked.emit()
	assert_true(main.chest_roulette.visible)
	assert_eq(main.chest_roulette.title_label.text, "¡Cofre!")
	var center: Vector2 = main.chest_roulette.get_global_rect().get_center()
	assert_almost_eq(center, main.battle_view.get_global_rect().get_center(), Vector2.ONE, "over the battle")


func test_the_modifier_timers_sit_in_the_top_right_corner_of_the_battle_view() -> void:
	GameState.session.gold_boost.apply(4.0, 60.0)
	GameState.session.damage_boost.apply(2.0, 45.0)
	main.modifier_timers.refresh()
	main.place_modifier_timers()
	assert_true(main.modifier_timers.visible)
	var view: Rect2 = main.battle_view.get_global_rect()
	var rect: Rect2 = main.modifier_timers.get_global_rect()
	assert_true(view.encloses(rect), "inside the battle view")
	assert_almost_eq(rect.end.x, view.end.x - Main.MODIFIER_MARGIN, 1.0, "right edge")
	assert_almost_eq(rect.position.y, view.position.y + Main.MODIFIER_MARGIN, 1.0, "top edge")


func test_the_hud_no_longer_shows_the_gold_boost() -> void:
	assert_null(main.hud.get_node_or_null("TopRow/BoostLabel"))
	assert_false(&"boost_label" in main.hud)


func test_a_reveal_plays_upgrade_and_a_legendary_or_super_one_a_fanfare() -> void:
	main.chest_roulette.revealed.emit(ChestTable.rewards_for(ChestTable.Rarity.EPIC)[0])
	main.chest_roulette.revealed.emit(ChestTable.rewards_for(ChestTable.Rarity.LEGENDARY)[0])
	main.chest_roulette.revealed.emit(ChestTable.rewards_for(ChestTable.Rarity.SUPER)[1])
	var ids: Array[StringName] = []
	for index: int in get_signal_emit_count(main.sfx, "played"):
		ids.append(get_signal_parameters(main.sfx, "played", index)[0] as StringName)
	assert_eq(ids, [&"upgrade", &"boss_defeat", &"boss_defeat"] as Array[StringName])
