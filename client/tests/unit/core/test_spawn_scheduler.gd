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


func test_a_due_spawn_becomes_a_wave_when_the_roll_is_under_the_chance() -> void:
	scheduler = SpawnScheduler.new(1.0, 3, 0.1)
	assert_eq(scheduler.tick(0.5, 0, false, 0.0), SpawnScheduler.Order.NONE, "not before the interval")
	assert_eq(scheduler.tick(0.5, 2, false, 0.09), SpawnScheduler.Order.WAVE)
	assert_eq(scheduler.tick(0.1, 0, false, 0.0), SpawnScheduler.Order.NONE, "the wave restarts the interval")


func test_a_roll_at_or_over_the_chance_spawns_one_regular_enemy() -> void:
	scheduler = SpawnScheduler.new(1.0, 3, 0.1)
	assert_eq(scheduler.tick(1.0, 0, false, 0.1), SpawnScheduler.Order.REGULAR)


func test_no_wave_at_capacity_or_while_the_boss_is_alive() -> void:
	scheduler = SpawnScheduler.new(1.0, 3, 1.0)
	assert_eq(scheduler.tick(5.0, 3, false, 0.0), SpawnScheduler.Order.NONE)
	assert_eq(scheduler.tick(5.0, 0, true, 0.0), SpawnScheduler.Order.NONE)


func test_without_a_wave_chance_every_due_spawn_is_regular() -> void:
	assert_eq(scheduler.tick(1.0, 0, false, 0.0), SpawnScheduler.Order.REGULAR)


func test_cancelled_boss_does_not_spawn() -> void:
	scheduler.queue_boss()
	scheduler.cancel_boss()
	assert_eq(scheduler.tick(0.0, 3, false), SpawnScheduler.Order.NONE)
