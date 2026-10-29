class_name OfflineCalculator
extends RefCounted
## Deterministic idle income: rate_per_second * validated elapsed time.
##
## Timestamps are Unix seconds. Callers pass a trusted "now" (server time when
## available); a clock that moved backwards yields nothing and elapsed time is capped.


static func compute(
	rates_per_second: Dictionary[StringName, BigNumber],
	last_seen_unix: int,
	now_unix: int,
	cap_seconds: int
) -> OfflineReward:
	var elapsed: int = clampi(now_unix - last_seen_unix, 0, maxi(cap_seconds, 0))
	var amounts: Dictionary[StringName, BigNumber] = {}
	for currency: StringName in rates_per_second:
		amounts[currency] = rates_per_second[currency].mul_float(elapsed)
	return OfflineReward.new(elapsed, amounts)


## Kills per second the hero sustains on a stage: DPS / enemy health, but never
## faster than enemies can arrive (one per `min_seconds_per_kill`).
static func kills_per_second(
	dps: BigNumber,
	enemy_health: BigNumber,
	min_seconds_per_kill: float
) -> float:
	var spawn_limit: float = 1.0 / maxf(min_seconds_per_kill, 0.001)
	if enemy_health.is_zero():
		return spawn_limit
	return minf(dps.div(enemy_health).to_float(), spawn_limit)
