extends GutTest
## The chest roulette flicks through the rewards a chest can give for about two
## seconds, lands on the rolled one, shows its rarity and only then pays it (bonuses S1, S3).

const ABILITIES: AbilityCatalog = preload("res://data/content/abilities/ability_catalog.tres")
const STAGE: int = 20

var session: GameSession
var roulette: ChestRoulette


func before_each() -> void:
	session = GameSession.new(StageBalance.new(), 10, 30.0, ABILITIES)
	session.progression.restore_stage(STAGE)
	roulette = ChestRoulette.new()
	add_child_autofree(roulette)
	roulette.bind(session)
	watch_signals(roulette)


func _bag() -> ChestReward:
	return ChestTable.rewards_for(ChestTable.Rarity.COMMON)[1]


func _rare_boost() -> ChestReward:
	return ChestTable.rewards_for(ChestTable.Rarity.RARE)[0]


func _gold() -> BigNumber:
	return session.wallet.get_amount(GameSession.GOLD)


func test_it_starts_hidden() -> void:
	assert_false(roulette.visible)


func test_a_chest_spins_for_about_two_seconds_before_paying() -> void:
	assert_almost_eq(ChestRoulette.SPIN_SECONDS, 2.0, 0.25)
	roulette.enqueue(_bag())
	assert_true(roulette.visible)
	assert_eq(roulette.title_label.text, "¡Cofre!")
	roulette.step(ChestRoulette.SPIN_SECONDS - 0.05)
	assert_true(_gold().is_zero(), "nothing paid while spinning")
	assert_signal_not_emitted(roulette, "revealed")
	roulette.step(0.1)
	var bag_gold: BigNumber = session.balance.gold_reward(STAGE).mul_float(ChestTable.BAG_KILLS)
	assert_true(_gold().is_equal_approx(bag_gold), "paid on the reveal")
	assert_signal_emit_count(roulette, "revealed", 1)
	assert_eq(roulette.title_label.text, "Común")
	assert_eq(roulette.reward_label.text, "Bolsa de oro")
	assert_eq(roulette.icon.texture, ChestRoulette.icon_for(_bag()))
	assert_eq(roulette.title_label.get_theme_color(&"font_color"), ChestRoulette.RARITY_COLORS[0])


func test_the_reel_flicks_through_the_possible_rewards_while_spinning() -> void:
	roulette.enqueue(_bag())
	var labels: Dictionary[String, bool] = {}
	for index: int in 20:
		roulette.step(ChestRoulette.SWAP_SECONDS)
		labels[roulette.reward_label.text] = true
	assert_gt(labels.size(), 3)
	assert_signal_not_emitted(roulette, "revealed")


func test_it_hides_after_the_reveal() -> void:
	roulette.enqueue(_bag())
	roulette.step(ChestRoulette.SPIN_SECONDS + 0.01)
	roulette.step(ChestRoulette.REVEAL_SECONDS - 0.05)
	assert_true(roulette.visible)
	roulette.step(0.1)
	assert_false(roulette.visible)


func test_a_chest_picked_while_spinning_waits_its_turn() -> void:
	roulette.enqueue(_bag())
	roulette.enqueue(_rare_boost())
	roulette.step(ChestRoulette.SPIN_SECONDS + 0.01)
	assert_signal_emit_count(roulette, "revealed", 1)
	roulette.step(ChestRoulette.REVEAL_SECONDS + 0.01)
	assert_true(roulette.visible, "the second chest spins next")
	assert_eq(roulette.title_label.text, "¡Cofre!")
	assert_eq(session.gold_boost.multiplier(), 1.0)
	roulette.step(ChestRoulette.SPIN_SECONDS + 0.01)
	assert_signal_emit_count(roulette, "revealed", 2)
	assert_eq(session.gold_boost.multiplier(), 4.0)
	assert_eq(roulette.reward_label.text, "Oro x4 60 s")


func test_a_new_run_drops_the_unpaid_chests() -> void:
	roulette.enqueue(_bag())
	roulette.enqueue(_bag())
	session.ascended.emit(0)
	assert_false(roulette.visible)
	roulette.step(ChestRoulette.SPIN_SECONDS * 3.0)
	assert_true(_gold().is_zero())
	assert_signal_not_emitted(roulette, "revealed")
	roulette.enqueue(_bag())
	session.save_applied.emit()
	roulette.step(ChestRoulette.SPIN_SECONDS * 3.0)
	assert_true(_gold().is_zero())


func test_every_reward_has_an_icon_and_each_rarity_its_own_color() -> void:
	for rarity: int in ChestTable.WEIGHTS.size():
		for reward: ChestReward in ChestTable.rewards_for(rarity):
			assert_not_null(ChestRoulette.icon_for(reward), reward.label())
	assert_eq(ChestRoulette.RARITY_COLORS.size(), ChestTable.WEIGHTS.size())
	for index: int in ChestRoulette.RARITY_COLORS.size():
		assert_eq(ChestRoulette.RARITY_COLORS.count(ChestRoulette.RARITY_COLORS[index]), 1)
