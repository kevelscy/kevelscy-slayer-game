class_name GameSession
extends RefCounted
## The player's run state and the rules that connect combat to the economy:
## kills pay gold and advance the stage, upgrades turn gold into hero stats,
## skills and spirits add damage on top of the hero's auto-attack, and ascension
## trades the run for shards that buy permanent talents. Chests dropped by kills
## give timed gold multipliers and other prizes (ChestTable).

signal ascended(shards_gained: int)
## A loaded save (local or cloud) replaced the run state.
signal save_applied

const GOLD: StringName = &"gold"
## The skill a FREE_FURY chest reward casts.
const FURY_ID: StringName = &"fury"
const BOSS_DAMAGE_MULTIPLIER: float = 2.0
## Seconds between regular enemy spawns; also caps the offline kill rate.
const SPAWN_INTERVAL_SECONDS: float = 1.2
## Share of due regular spawns that come as a wave, and how much tougher and richer
## each wave enemy is.
const WAVE_CHANCE: float = 0.08
const WAVE_HEALTH_MULTIPLIER: float = 1.25
const WAVE_GOLD_MULTIPLIER: float = 1.25
const OFFLINE_CAP_SECONDS: int = 8 * 3600
const ASCEND_MIN_STAGE: int = 20
## Shards paid on ascending = stage - ASCEND_SHARD_OFFSET (5 at stage 20).
const ASCEND_SHARD_OFFSET: int = 15
## Characteristics (the five upgrade tracks) cost 30% less than their first prices.
const CHARACTERISTIC_COST_FACTOR: float = 0.7

var wallet: CurrencyWallet = CurrencyWallet.new()
var balance: StageBalance
var progression: StageProgression
var hero_stats: StatBlock = StatBlock.new()
var attack_track: UpgradeTrack = UpgradeTrack.new(
	BigNumber.from_float(10.0), 1.12, CostCurve.new(BigNumber.from_float(10.0 * CHARACTERISTIC_COST_FACTOR), 1.18)
)
var health_track: UpgradeTrack = UpgradeTrack.new(
	BigNumber.from_float(100.0), 1.12, CostCurve.new(BigNumber.from_float(15.0 * CHARACTERISTIC_COST_FACTOR), 1.2)
)
var crit_chance_track: RateUpgradeTrack = RateUpgradeTrack.new(
	0.05, 0.005, 90, CostCurve.new(BigNumber.from_float(50.0 * CHARACTERISTIC_COST_FACTOR), 1.25)
)
var crit_damage_track: RateUpgradeTrack = RateUpgradeTrack.new(
	1.5, 0.05, 0, CostCurve.new(BigNumber.from_float(40.0 * CHARACTERISTIC_COST_FACTOR), 1.2)
)
var attack_speed_track: RateUpgradeTrack = RateUpgradeTrack.new(
	1.5, 0.02, 75, CostCurve.new(BigNumber.from_float(60.0 * CHARACTERISTIC_COST_FACTOR), 1.28)
)
var skills: SkillBar
var spirits: SpiritTeam
var buffs: BuffTracker = BuffTracker.new(hero_stats)
## Chest gold multiplier on kill gold; online only, never saved.
var gold_boost: ChestBoost = ChestBoost.new()
## Chest damage multiplier on hero, skill and spirit damage; never counts offline.
var damage_boost: ChestBoost = ChestBoost.new()
var chest_rng: RandomNumberGenerator = RandomNumberGenerator.new()
## Views read the talents and the ascension count; only the session's rules
## (ascend, apply_save) and talent purchases through TalentTree.try_buy change them.
var talents: TalentTree
var ascension_count: int = 0
## Whether the last combat frame had a living target; manual casts read it.
var in_combat: bool = false


func _init(
	stage_balance: StageBalance = StageBalance.new(),
	kills_per_stage: int = 10,
	boss_seconds: float = 30.0,
	abilities: AbilityCatalog = AbilityCatalog.new(),
	talent_catalog: TalentCatalog = TalentCatalog.new()
) -> void:
	balance = stage_balance
	chest_rng.randomize()
	progression = StageProgression.new(kills_per_stage, boss_seconds)
	_refresh_hero_stats()
	skills = SkillBar.new(abilities.skills)
	spirits = SpiritTeam.new(abilities.spirits, hero_stats)
	talents = TalentTree.new(talent_catalog.talents, hero_stats)
	# Unlocks follow the stage, so a loaded save restores them without extra save data.
	progression.stage_changed.connect(spirits.refresh_unlocks)
	spirits.refresh_unlocks(progression.stage)


## One combat frame of the ability systems; auto-cast runs after cooldowns tick.
func tick_combat(delta: float, has_target: bool) -> void:
	in_combat = has_target
	skills.tick(delta)
	buffs.tick(delta)
	gold_boost.tick(delta)
	damage_boost.tick(delta)
	spirits.tick(delta, has_target)
	skills.autocast(progression.stage, has_target)


## Player-pressed cast; the same stage and target rules as auto-cast apply.
func cast_skill(slot_index: int) -> bool:
	return skills.try_cast(slot_index, in_combat)


## Buys the next level of a skill with gold; the first level needs its unlock stage.
func try_buy_skill(slot_index: int) -> bool:
	return skills.try_buy(slot_index, progression.stage, wallet, GOLD)


func skill_damage(skill: SkillDefinition) -> BigNumber:
	return hero_stats.get_big(StatBlock.ATTACK).mul_float(_skill_power(skill) * damage_boost.multiplier())


func spirit_damage(spirit: SpiritDefinition) -> BigNumber:
	return hero_stats.get_big(StatBlock.ATTACK).mul_float(spirit.attack_power * damage_boost.multiplier())


func shield_amount(skill: SkillDefinition) -> BigNumber:
	return hero_max_health().mul_float(_skill_power(skill))


## Fury-style buff: the skill power raises both attack and attack speed.
func activate_buff(skill: SkillDefinition) -> void:
	var power: float = _skill_power(skill)
	var modifiers: Array[StatModifier] = [
		StatModifier.percent(StatBlock.ATTACK, power),
		StatModifier.percent(StatBlock.ATTACK_SPEED, power),
	]
	buffs.apply(skill.id, modifiers, skill.duration_seconds)


## gold_multiplier scales a regular kill's gold, for wave enemies; the chest gold
## boost scales every kill.
func on_enemy_killed(was_boss: bool, gold_multiplier: float = 1.0) -> void:
	var stage: int = progression.stage
	var boost: float = gold_boost.multiplier()
	if was_boss:
		wallet.add(GOLD, balance.boss_gold_reward(stage).mul_float(talents.gold_multiplier() * boost))
		progression.defeat_boss()
	else:
		wallet.add(GOLD, balance.gold_reward(stage).mul_float(talents.gold_multiplier() * gold_multiplier * boost))
		progression.register_kill()


## Whether an enemy drops a chest when killed, rolled as it spawns so it can show a
## chest icon over its head; the hero picks the chest up and the roulette rolls it.
func chest_drops(was_boss: bool) -> bool:
	return ChestTable.drops(was_boss, chest_rng.randf())


## Rolls a chest's rarity and reward without paying it: the roulette pays it with
## grant_chest_reward when it stops.
func roll_chest() -> ChestReward:
	var rarity: ChestTable.Rarity = ChestTable.rarity_for(chest_rng.randf())
	return ChestTable.reward_for(rarity, chest_rng.randf())


## Rolls the chest's rarity and reward, pays it and returns it.
func open_chest() -> ChestReward:
	var reward: ChestReward = roll_chest()
	grant_chest_reward(reward)
	return reward


func grant_chest_reward(reward: ChestReward) -> void:
	match reward.kind:
		ChestReward.Kind.GOLD_MULTIPLIER:
			gold_boost.apply(reward.factor, reward.seconds)
		ChestReward.Kind.DAMAGE_MULTIPLIER:
			damage_boost.apply(reward.factor, reward.seconds)
		ChestReward.Kind.GOLD_BAG:
			var kill_gold: BigNumber = balance.gold_reward(progression.stage).mul_float(talents.gold_multiplier())
			wallet.add(GOLD, kill_gold.mul_float(reward.bag_kills))
		ChestReward.Kind.FREE_FURY:
			for slot: SkillSlot in skills.slots:
				if slot.definition.id == FURY_ID:
					activate_buff(slot.definition)
					break
		ChestReward.Kind.RECHARGE_SKILLS:
			skills.reset_cooldowns()
		ChestReward.Kind.SKILL_LEVEL:
			skills.grant_level(skills.lowest_owned_index())


func on_hero_died() -> void:
	progression.fail_boss()


func can_ascend() -> bool:
	return progression.stage >= ASCEND_MIN_STAGE


func ascension_shards_on_ascend() -> int:
	return progression.stage - ASCEND_SHARD_OFFSET if can_ascend() else 0


## Trades the run for shards: stage 1, no gold, no upgrade levels, no buffs, and
## spirits locked again (their unlocks follow the stage). Talents, bought skill
## levels, shards and the ascension count stay. Returns the shards paid, 0 if not allowed.
## Shards are paid first, so the reset's own signals already see the new balance.
func ascend() -> int:
	var gained: int = ascension_shards_on_ascend()
	if gained <= 0:
		return 0
	talents.shards += gained
	ascension_count += 1
	buffs.clear()
	gold_boost.clear()
	damage_boost.clear()
	spirits.relock()
	skills.reset_cooldowns()
	for track: UpgradeTrack in [attack_track, health_track, crit_chance_track, crit_damage_track, attack_speed_track]:
		track.set_level(0)
	wallet.restore(GOLD, BigNumber.zero())
	progression.restore_stage(1)
	_refresh_hero_stats()
	ascended.emit(gained)
	return gained


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
	data.crit_chance_level = crit_chance_track.level
	data.crit_damage_level = crit_damage_track.level
	data.attack_speed_level = attack_speed_track.level
	data.ascension_shards = talents.shards
	data.ascension_count = ascension_count
	var talent_levels: Dictionary[StringName, int] = talents.levels()
	for talent_id: StringName in talent_levels:
		data.talents[String(talent_id)] = talent_levels[talent_id]
	var skill_levels: Dictionary[StringName, int] = skills.levels()
	for skill_id: StringName in skill_levels:
		data.skills[String(skill_id)] = skill_levels[skill_id]
	for skill_id: StringName in skills.equipped_ids():
		data.equipped.append(String(skill_id))
	data.has_equipped = true
	data.last_seen_unix = now_unix
	return data


## Restores a decoded save in place, so views bound to the wallet keep working.
## It replaces the running game: buffs and cooldowns reset and spirits relock,
## then unlock again for the saved stage.
func apply_save(data: SaveData) -> void:
	buffs.clear()
	gold_boost.clear()
	damage_boost.clear()
	spirits.relock()
	skills.reset_cooldowns()
	progression.restore_stage(data.stage)
	wallet.restore(GOLD, data.gold)
	attack_track.set_level(data.attack_level)
	health_track.set_level(data.health_level)
	# Rate tracks clamp a level above their cap.
	crit_chance_track.set_level(data.crit_chance_level)
	crit_damage_track.set_level(data.crit_damage_level)
	attack_speed_track.set_level(data.attack_speed_level)
	talents.shards = data.ascension_shards
	ascension_count = data.ascension_count
	# Unknown talent ids are ignored and levels clamp to each talent's max.
	talents.set_levels(data.talents)
	skills.set_levels(data.skills)
	if not data.has_skill_levels:
		skills.grant_reached(data.stage)
	if data.has_equipped:
		skills.set_equipped(data.equipped)
	else:
		skills.equip_owned()
	_refresh_hero_stats()
	save_applied.emit()


## Gold per second while away: regular kills the hero and its spirits sustain on
## the current stage times their gold. Active skills never count offline, and
## offline time never advances the stage.
func offline_gold_rate() -> BigNumber:
	var dps: BigNumber = DamageCalculator.expected_dps(hero_stats).add(
		spirits.expected_dps(hero_stats.get_big(StatBlock.ATTACK))
	)
	var kills: float = OfflineCalculator.kills_per_second(dps, enemy_health(false), SPAWN_INTERVAL_SECONDS)
	return balance.gold_reward(progression.stage).mul_float(kills * talents.gold_multiplier())


## Pays offline gold for the validated time between the two timestamps.
func grant_offline(last_seen_unix: int, now_unix: int) -> OfflineReward:
	# Buff and chest boost time ran out while away, and neither may inflate the offline rate.
	buffs.clear()
	gold_boost.clear()
	damage_boost.clear()
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
	hero_stats.set_base_rate(StatBlock.CRIT_CHANCE, crit_chance_track.rate())
	hero_stats.set_base_rate(StatBlock.CRIT_DAMAGE, crit_damage_track.rate())
	hero_stats.set_base_rate(StatBlock.ATTACK_SPEED, attack_speed_track.rate())


## A skill's power at its bought level.
func _skill_power(skill: SkillDefinition) -> float:
	return skill.power_at(skills.level_of(skill.id))
