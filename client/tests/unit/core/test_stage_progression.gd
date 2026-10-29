extends GutTest

const KILLS: int = 3
const BOSS_SECONDS: float = 10.0

var progression: StageProgression


func before_each() -> void:
	progression = StageProgression.new(KILLS, BOSS_SECONDS)
	watch_signals(progression)


func _kill(times: int) -> void:
	for i: int in times:
		progression.register_kill()


func test_starts_farming_stage_one() -> void:
	assert_eq(progression.stage, 1)
	assert_eq(progression.kills, 0)
	assert_false(progression.is_boss_active)


func test_kills_below_threshold_do_not_start_boss() -> void:
	_kill(KILLS - 1)
	assert_eq(progression.kills, KILLS - 1)
	assert_false(progression.is_boss_active)
	assert_signal_not_emitted(progression, "boss_started")


func test_reaching_threshold_starts_boss_once_with_timer() -> void:
	_kill(KILLS)
	assert_true(progression.is_boss_active)
	assert_eq(progression.boss_time_left, BOSS_SECONDS)
	assert_signal_emit_count(progression, "boss_started", 1)
	assert_signal_emitted_with_parameters(progression, "boss_started", [BOSS_SECONDS])


func test_regular_kills_during_boss_are_ignored() -> void:
	_kill(KILLS + 5)
	assert_signal_emit_count(progression, "boss_started", 1)
	assert_eq(progression.kills, KILLS)


func test_defeating_boss_advances_stage() -> void:
	_kill(KILLS)
	progression.defeat_boss()
	assert_eq(progression.stage, 2)
	assert_eq(progression.kills, 0)
	assert_false(progression.is_boss_active)
	assert_signal_emit_count(progression, "boss_defeated", 1)
	assert_signal_emitted_with_parameters(progression, "stage_changed", [2])


func test_defeat_boss_without_active_boss_is_ignored() -> void:
	progression.defeat_boss()
	assert_eq(progression.stage, 1)
	assert_signal_not_emitted(progression, "boss_defeated")


func test_timer_running_out_fails_boss() -> void:
	_kill(KILLS)
	progression.tick(BOSS_SECONDS - 1.0)
	assert_true(progression.is_boss_active)
	progression.tick(2.0)
	assert_false(progression.is_boss_active)
	assert_eq(progression.boss_time_left, 0.0)
	assert_eq(progression.stage, 1)
	assert_eq(progression.kills, 0)
	assert_signal_emit_count(progression, "boss_failed", 1)


func test_tick_without_boss_is_noop() -> void:
	progression.tick(100.0)
	assert_signal_not_emitted(progression, "boss_failed")


func test_hero_death_fails_active_boss() -> void:
	_kill(KILLS)
	progression.fail_boss()
	assert_false(progression.is_boss_active)
	assert_signal_emit_count(progression, "boss_failed", 1)


func test_fail_boss_without_active_boss_is_ignored() -> void:
	progression.fail_boss()
	assert_signal_not_emitted(progression, "boss_failed")


func test_boss_can_be_retried_after_failing() -> void:
	_kill(KILLS)
	progression.fail_boss()
	_kill(KILLS)
	assert_true(progression.is_boss_active)
	assert_signal_emit_count(progression, "boss_started", 2)
