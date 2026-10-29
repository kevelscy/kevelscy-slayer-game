class_name GameSession
extends RefCounted
## The player's run state and the rules that connect combat to the economy:
## kills pay gold and advance the stage, upgrades turn gold into hero stats.

const GOLD: StringName = &"gold"
const BOSS_DAMAGE_MULTIPLIER: float = 2.0

var wallet: CurrencyWallet = CurrencyWallet.new()
var balance: StageBalance
var progression: StageProgression
var hero_stats: StatBlock = StatBlock.new()
var attack_track: UpgradeTrack = UpgradeTrack.new(
	BigNumber.from_float(10.0), 1.12, CostCurve.new(BigNumber.from_float(10.0), 1.18)
)
var health_track: UpgradeTrack = UpgradeTrack.new(
	BigNumber.from_float(100.0), 1.12, CostCurve.new(BigNumber.from_float(15.0), 1.2)
)


func _init(
	stage_balance: StageBalance = StageBalance.new(),
	kills_per_stage: int = 10,
	boss_seconds: float = 30.0
) -> void:
	balance = stage_balance
	progression = StageProgression.new(kills_per_stage, boss_seconds)
	hero_stats.set_base_rate(StatBlock.CRIT_CHANCE, 0.05)
	hero_stats.set_base_rate(StatBlock.CRIT_DAMAGE, 1.5)
	hero_stats.set_base_rate(StatBlock.ATTACK_SPEED, 1.5)
	_refresh_hero_stats()


func on_enemy_killed(was_boss: bool) -> void:
	var stage: int = progression.stage
	if was_boss:
		wallet.add(GOLD, balance.boss_gold_reward(stage))
		progression.defeat_boss()
	else:
		wallet.add(GOLD, balance.gold_reward(stage))
		progression.register_kill()


func on_hero_died() -> void:
	progression.fail_boss()


func try_upgrade(track: UpgradeTrack) -> bool:
	if not track.try_buy(wallet, GOLD):
		return false
	_refresh_hero_stats()
	return true


func enemy_health(is_boss: bool) -> BigNumber:
	var stage: int = progression.stage
	return balance.boss_health(stage) if is_boss else balance.enemy_health(stage)


func enemy_damage(is_boss: bool) -> BigNumber:
	var damage: BigNumber = balance.enemy_damage(progression.stage)
	return damage.mul_float(BOSS_DAMAGE_MULTIPLIER) if is_boss else damage


func hero_max_health() -> BigNumber:
	return hero_stats.get_big(StatBlock.HEALTH)


func _refresh_hero_stats() -> void:
	hero_stats.set_base(StatBlock.ATTACK, attack_track.value())
	hero_stats.set_base(StatBlock.HEALTH, health_track.value())
