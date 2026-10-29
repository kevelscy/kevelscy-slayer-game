class_name GameSession
extends RefCounted
## The player's run state and the rules that connect combat to the economy:
## kills pay gold and advance the stage, upgrades turn gold into hero stats,
## skills and spirits add damage on top of the hero's auto-attack.

const GOLD: StringName = &"gold"
const BOSS_DAMAGE_MULTIPLIER: float = 2.0
## Seconds between regular enemy spawns; also caps the offline kill rate.
const SPAWN_INTERVAL_SECONDS: float = 1.2
const OFFLINE_CAP_SECONDS: int = 8 * 3600

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
var skills: SkillBar
var spirits: SpiritTeam
var buffs: BuffTracker = BuffTracker.new(hero_stats)


func _init(
	stage_balance: StageBalance = StageBalance.new(),
	kills_per_stage: int = 10,
	boss_seconds: float = 30.0,
	abilities: AbilityCatalog = AbilityCatalog.new()
) -> void:
	balance = stage_balance
	progression = StageProgression.new(kills_per_stage, boss_seconds)
	hero_stats.set_base_rate(StatBlock.CRIT_CHANCE, 0.05)
	hero_stats.set_base_rate(StatBlock.CRIT_DAMAGE, 1.5)
	hero_stats.set_base_rate(StatBlock.ATTACK_SPEED, 1.5)
	_refresh_hero_stats()
	skills = SkillBar.new(abilities.skills)
	spirits = SpiritTeam.new(abilities.spirits, hero_stats)
	# Unlocks follow the stage, so a loaded save restores them without extra save data.
	progression.stage_changed.connect(spirits.refresh_unlocks)
	spirits.refresh_unlocks(progression.stage)


## One combat frame of the ability systems; auto-cast runs after cooldowns tick.
func tick_combat(delta: float, has_target: bool) -> void:
	skills.tick(delta)
	buffs.tick(delta)
	spirits.tick(delta, has_target)
	skills.autocast(progression.stage, has_target)


func skill_damage(skill: SkillDefinition) -> BigNumber:
	return hero_stats.get_big(StatBlock.ATTACK).mul_float(skill.power)


func spirit_damage(spirit: SpiritDefinition) -> BigNumber:
	return hero_stats.get_big(StatBlock.ATTACK).mul_float(spirit.attack_power)


func shield_amount(skill: SkillDefinition) -> BigNumber:
	return hero_max_health().mul_float(skill.power)


## Fury-style buff: the skill power raises both attack and attack speed.
func activate_buff(skill: SkillDefinition) -> void:
	var modifiers: Array[StatModifier] = [
		StatModifier.percent(StatBlock.ATTACK, skill.power),
		StatModifier.percent(StatBlock.ATTACK_SPEED, skill.power),
	]
	buffs.apply(skill.id, modifiers, skill.duration_seconds)


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


func to_save(now_unix: int) -> SaveData:
	var data: SaveData = SaveData.new()
	data.stage = progression.stage
	data.gold = wallet.get_amount(GOLD)
	data.attack_level = attack_track.level
	data.health_level = health_track.level
	data.last_seen_unix = now_unix
	return data


## Restores a decoded save in place, so views bound to the wallet keep working.
func apply_save(data: SaveData) -> void:
	progression.restore_stage(data.stage)
	wallet.restore(GOLD, data.gold)
	attack_track.set_level(data.attack_level)
	health_track.set_level(data.health_level)
	_refresh_hero_stats()


## Gold per second while away: regular kills the hero and its spirits sustain on
## the current stage times their gold. Active skills never count offline, and
## offline time never advances the stage.
func offline_gold_rate() -> BigNumber:
	var dps: BigNumber = DamageCalculator.expected_dps(hero_stats).add(
		spirits.expected_dps(hero_stats.get_big(StatBlock.ATTACK))
	)
	var kills: float = OfflineCalculator.kills_per_second(dps, enemy_health(false), SPAWN_INTERVAL_SECONDS)
	return balance.gold_reward(progression.stage).mul_float(kills)


## Pays offline gold for the validated time between the two timestamps.
func grant_offline(last_seen_unix: int, now_unix: int) -> OfflineReward:
	# Buff time ran out while away, and a buff must not inflate the offline rate.
	buffs.clear()
	var rates: Dictionary[StringName, BigNumber] = {GOLD: offline_gold_rate()}
	var reward: OfflineReward = OfflineCalculator.compute(
		rates, last_seen_unix, now_unix, OFFLINE_CAP_SECONDS
	)
	if not reward.is_empty():
		wallet.add(GOLD, reward.amounts[GOLD])
	return reward


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
