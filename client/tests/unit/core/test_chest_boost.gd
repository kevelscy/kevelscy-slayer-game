extends GutTest
## The chest gold multiplier rule (bonuses S2): a bigger one replaces the active one,
## an equal one adds its time, a smaller one is ignored.

var boost: ChestBoost


func before_each() -> void:
	boost = ChestBoost.new()


func test_no_boost_multiplies_by_one() -> void:
	assert_eq(boost.multiplier(), 1.0)
	assert_eq(boost.seconds_left, 0.0)


func test_a_boost_lasts_its_seconds_then_ends() -> void:
	boost.apply(2.0, 60.0)
	assert_eq(boost.multiplier(), 2.0)
	boost.tick(59.0)
	assert_eq(boost.multiplier(), 2.0)
	boost.tick(1.0)
	assert_eq(boost.multiplier(), 1.0)
	assert_eq(boost.seconds_left, 0.0)


func test_a_bigger_multiplier_replaces_the_active_one() -> void:
	boost.apply(4.0, 60.0)
	boost.tick(50.0)
	boost.apply(6.0, 90.0)
	assert_eq(boost.multiplier(), 6.0)
	assert_eq(boost.seconds_left, 90.0)


func test_an_equal_multiplier_adds_its_time() -> void:
	boost.apply(4.0, 60.0)
	boost.tick(20.0)
	boost.apply(4.0, 60.0)
	assert_eq(boost.multiplier(), 4.0)
	assert_eq(boost.seconds_left, 100.0)


func test_a_smaller_multiplier_changes_nothing() -> void:
	boost.apply(8.0, 120.0)
	boost.apply(2.0, 60.0)
	assert_eq(boost.multiplier(), 8.0)
	assert_eq(boost.seconds_left, 120.0)


func test_after_it_ends_any_multiplier_starts_fresh() -> void:
	boost.apply(10.0, 180.0)
	boost.tick(180.0)
	boost.apply(2.0, 60.0)
	assert_eq(boost.multiplier(), 2.0)
	assert_eq(boost.seconds_left, 60.0)


func test_clear_ends_the_boost() -> void:
	boost.apply(6.0, 90.0)
	boost.clear()
	assert_eq(boost.multiplier(), 1.0)
	assert_eq(boost.seconds_left, 0.0)
