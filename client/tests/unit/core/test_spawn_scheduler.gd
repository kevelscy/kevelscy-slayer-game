extends GutTest

var scheduler: SpawnScheduler


func before_each() -> void:
	scheduler = SpawnScheduler.new(1.0, 3)


func test_regular_spawn_waits_for_interval() -> void:
	assert_eq(scheduler.tick(0.5, 0, false), SpawnScheduler.Order.NONE)
	assert_eq(scheduler.tick(0.5, 0, false), SpawnScheduler.Order.REGULAR)
	assert_eq(scheduler.tick(0.1, 1, false), SpawnScheduler.Order.NONE)


func test_no_regular_spawn_at_capacity_until_a_slot_frees() -> void:
	assert_eq(scheduler.tick(5.0, 3, false), SpawnScheduler.Order.NONE)
	assert_eq(scheduler.tick(0.0, 2, false), SpawnScheduler.Order.REGULAR)


func test_queued_boss_spawns_on_next_tick_once() -> void:
	scheduler.queue_boss()
	assert_eq(scheduler.tick(0.0, 3, false), SpawnScheduler.Order.BOSS)
	assert_eq(scheduler.tick(0.0, 3, true), SpawnScheduler.Order.NONE)


func test_regular_spawns_pause_while_boss_is_alive() -> void:
	assert_eq(scheduler.tick(10.0, 0, true), SpawnScheduler.Order.NONE)


func test_cancelled_boss_does_not_spawn() -> void:
	scheduler.queue_boss()
	scheduler.cancel_boss()
	assert_eq(scheduler.tick(0.0, 3, false), SpawnScheduler.Order.NONE)
