class_name ChestReward
extends RefCounted
## One prize a chest can give. GameSession.grant_chest_reward pays it.

enum Kind { GOLD_MULTIPLIER, GOLD_BAG, FREE_FURY, RECHARGE_SKILLS, SKILL_LEVEL, DAMAGE_MULTIPLIER }

var rarity: int
var kind: Kind
## GOLD_MULTIPLIER and DAMAGE_MULTIPLIER: the factor and how long it lasts.
var factor: float = 1.0
var seconds: float = 0.0
## GOLD_BAG: how many regular kills of the current stage the bag is worth.
var bag_kills: int = 0


func _init(reward_rarity: int, reward_kind: Kind) -> void:
	rarity = reward_rarity
	kind = reward_kind


## Spanish text shown on the roulette.
func label() -> String:
	match kind:
		Kind.GOLD_MULTIPLIER:
			return "Oro x%d %d s" % [roundi(factor), roundi(seconds)]
		Kind.GOLD_BAG:
			return "Bolsa grande" if bag_kills >= ChestTable.BIG_BAG_KILLS else "Bolsa de oro"
		Kind.FREE_FURY:
			return "Furia gratis"
		Kind.RECHARGE_SKILLS:
			return "Recarga habilidades"
		Kind.DAMAGE_MULTIPLIER:
			return "Daño x%d %d s" % [roundi(factor), roundi(seconds)]
		_:
			return "+1 nivel habilidad"
