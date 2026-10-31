class_name ChestTable
extends RefCounted
## Megabonk-style chest odds: which kills drop a chest, its rarity and its two
## or three possible rewards. Rolls are passed in (0 <= roll < 1) so the table stays pure.

enum Rarity { COMMON, RARE, EPIC, LEGENDARY, SUPER }

const DROP_CHANCE: float = 0.04
## Percent chance per rarity, in Rarity order; they add up to 100.
const WEIGHTS: Array[int] = [55, 27, 12, 5, 1]
const RARITY_NAMES: Array[String] = ["Común", "Raro", "Épico", "Legendario", "Super"]
## Gold multiplier per rarity, in Rarity order, and how long each lasts.
const FACTORS: Array[float] = [2.0, 4.0, 6.0, 8.0, 10.0]
const FACTOR_SECONDS: Array[float] = [60.0, 60.0, 90.0, 120.0, 180.0]
## Regular kills of the current stage a gold bag (Common) and a big bag (Legendary) pay.
const BAG_KILLS: int = 50
const BIG_BAG_KILLS: int = 500
## Raro and Épico can also give a damage multiplier for DAMAGE_SECONDS.
const DAMAGE_FACTORS: Dictionary[Rarity, float] = {Rarity.RARE: 2.0, Rarity.EPIC: 4.0}
const DAMAGE_SECONDS: float = 45.0


## Bosses always drop a chest; regular enemies DROP_CHANCE of the time.
static func drops(was_boss: bool, roll: float) -> bool:
	return was_boss or roll < DROP_CHANCE


static func rarity_for(roll: float) -> Rarity:
	# Whole percents are summed first: adding the float shares drifts past the cut-offs.
	var percent: int = 0
	for rarity: int in WEIGHTS.size():
		percent += WEIGHTS[rarity]
		if roll < percent / 100.0:
			return rarity as Rarity
	return Rarity.SUPER


## The rewards of a rarity: its gold multiplier first, then its special prize, then
## its damage multiplier for the rarities that have one.
static func rewards_for(rarity: int) -> Array[ChestReward]:
	var boost: ChestReward = ChestReward.new(rarity, ChestReward.Kind.GOLD_MULTIPLIER)
	boost.factor = FACTORS[rarity]
	boost.seconds = FACTOR_SECONDS[rarity]
	var special: ChestReward
	match rarity:
		Rarity.COMMON:
			special = ChestReward.new(rarity, ChestReward.Kind.GOLD_BAG)
			special.bag_kills = BAG_KILLS
		Rarity.RARE:
			special = ChestReward.new(rarity, ChestReward.Kind.FREE_FURY)
		Rarity.EPIC:
			special = ChestReward.new(rarity, ChestReward.Kind.RECHARGE_SKILLS)
		Rarity.LEGENDARY:
			special = ChestReward.new(rarity, ChestReward.Kind.GOLD_BAG)
			special.bag_kills = BIG_BAG_KILLS
		_:
			special = ChestReward.new(rarity, ChestReward.Kind.SKILL_LEVEL)
	var rewards: Array[ChestReward] = [boost, special]
	if DAMAGE_FACTORS.has(rarity as Rarity):
		var damage: ChestReward = ChestReward.new(rarity, ChestReward.Kind.DAMAGE_MULTIPLIER)
		damage.factor = DAMAGE_FACTORS[rarity as Rarity]
		damage.seconds = DAMAGE_SECONDS
		rewards.append(damage)
	return rewards


## Any reward of the rarity, each with the same chance.
static func reward_for(rarity: int, roll: float) -> ChestReward:
	var rewards: Array[ChestReward] = rewards_for(rarity)
	return rewards[mini(floori(roll * rewards.size()), rewards.size() - 1)]
