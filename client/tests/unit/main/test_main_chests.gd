extends GutTest
## Main wires chests: a picked chest spins the roulette, the HUD shows the active gold
## boost and the reveal plays a sound (bonuses S1, S2).

const MAIN: PackedScene = preload("res://main/main.tscn")

var main: Main
var clock_msec: int = 0


func before_each() -> void:
	main = MAIN.instantiate()
	add_child_autofree(main)
	GameState.session.gold_boost.clear()
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


func test_the_hud_shows_the_active_gold_boost_and_hides_it_when_it_ends() -> void:
	main.hud._refresh()
	assert_false(main.hud.boost_label.visible)
	GameState.session.gold_boost.apply(4.0, 60.0)
	main.hud._refresh()
	assert_true(main.hud.boost_label.visible)
	assert_eq(main.hud.boost_label.text, "x4 60 s")
	GameState.session.gold_boost.tick(60.0)
	main.hud._refresh()
	assert_false(main.hud.boost_label.visible)


func test_a_reveal_plays_upgrade_and_a_legendary_or_super_one_a_fanfare() -> void:
	main.chest_roulette.revealed.emit(ChestTable.rewards_for(ChestTable.Rarity.EPIC)[0])
	main.chest_roulette.revealed.emit(ChestTable.rewards_for(ChestTable.Rarity.LEGENDARY)[0])
	main.chest_roulette.revealed.emit(ChestTable.rewards_for(ChestTable.Rarity.SUPER)[1])
	var ids: Array[StringName] = []
	for index: int in get_signal_emit_count(main.sfx, "played"):
		ids.append(get_signal_parameters(main.sfx, "played", index)[0] as StringName)
	assert_eq(ids, [&"upgrade", &"boss_defeat", &"boss_defeat"] as Array[StringName])
