class_name DamageCalculator
extends RefCounted
## Pure damage formula: attack * skill_multiplier * (crit_damage if critical).
## The RNG is injected so tests and replays stay deterministic.


static func compute(
	attacker: StatBlock,
	rng: RandomNumberGenerator,
	skill_multiplier: float = 1.0
) -> DamageResult:
	var crit_chance: float = attacker.get_rate(StatBlock.CRIT_CHANCE)
	# randf() is inclusive of 1.0, so a guaranteed crit is checked explicitly.
	var is_critical: bool = crit_chance >= 1.0 or rng.randf() < crit_chance
	var multiplier: float = skill_multiplier
	if is_critical:
		multiplier *= attacker.get_rate(StatBlock.CRIT_DAMAGE)
	return DamageResult.new(attacker.get_big(StatBlock.ATTACK).mul_float(multiplier), is_critical)
