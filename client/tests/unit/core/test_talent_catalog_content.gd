extends GutTest
## Pins the shipped talent catalog to the ascension decisions (D15).

const CATALOG: TalentCatalog = preload("res://data/content/talents/talent_catalog.tres")


func test_six_talents_with_their_bonuses_and_prerequisites() -> void:
	var rows: Array[String] = []
	for talent: TalentDefinition in CATALOG.talents:
		rows.append("%s|%s|%s|%s|%.2f|%d|%s|%d" % [
			talent.id, talent.display_name, talent.stat, StatModifier.Kind.keys()[talent.kind],
			talent.per_level, talent.max_level, talent.requires, talent.requires_level,
		])
	assert_eq(rows, [
		"might|Poder|attack|PERCENT|0.10|10||5",
		"vitality|Vitalidad|health|PERCENT|0.10|10||5",
		"greed|Codicia|gold_gain|PERCENT|0.10|10||5",
		"precision|Precisión|crit_chance|FLAT|0.01|10|might|5",
		"ferocity|Ferocidad|crit_damage|FLAT|0.10|10|might|5",
		"haste|Celeridad|attack_speed|PERCENT|0.03|10|vitality|5",
	] as Array[String])
