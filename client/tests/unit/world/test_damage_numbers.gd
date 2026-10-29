extends GutTest
## Damage numbers: every hit an enemy takes floats up as pixel text above it.

const BATTLE_WORLD: PackedScene = preload("res://world/battle_world.tscn")
const ABILITIES: AbilityCatalog = preload("res://data/content/abilities/ability_catalog.tres")
const DAMAGE_CHARS: String = "0123456789.KMBTabcdefghijklmnopqrstuvwxyz"

var world: BattleWorld
var session: GameSession
var enemy: Enemy


func before_each() -> void:
	session = GameSession.new(StageBalance.new(), 10, 30.0, ABILITIES)
	session.progression.restore_stage(20)
	world = BATTLE_WORLD.instantiate()
	add_child_autofree(world)
	world.start(session)
	world._spawn(world.roster.regular_enemies[0], false)
	enemy = world.enemy_pool.active_nodes().back() as Enemy
	enemy.position.x = 120.0


func _numbers() -> Array[DamageNumber]:
	var numbers: Array[DamageNumber] = []
	for node: Node in world.damage_number_pool.active_nodes():
		numbers.append(node as DamageNumber)
	return numbers


func _hit(target: Enemy, amount: float, critical: bool) -> void:
	target.health.take_damage(DamageResult.new(BigNumber.from_float(amount), critical))


func test_fonts_cover_every_character_number_format_prints() -> void:
	for font: FontFile in [DamageNumber.FONT, DamageNumber.CRIT_FONT]:
		for index: int in DAMAGE_CHARS.length():
			assert_true(font.has_char(DAMAGE_CHARS.unicode_at(index)), "%s has '%s'" % [font.resource_path, DAMAGE_CHARS[index]])
		assert_false(font.generate_mipmaps, "%s has no mipmaps" % font.resource_path)


func test_a_hit_shows_its_formatted_amount_above_the_enemy() -> void:
	_hit(enemy, 1234.0, false)

	var numbers: Array[DamageNumber] = _numbers()
	assert_eq(numbers.size(), 1)
	var number: DamageNumber = numbers[0]
	assert_eq(number.text, NumberFormat.format(BigNumber.from_float(1234.0)))
	assert_eq(number.text, "1,23K")
	assert_eq(number.get_theme_font("font"), DamageNumber.FONT)
	var enemy_top: float = enemy.position.y - enemy.definition.animation.frame_size.y * enemy.definition.sprite_scale
	assert_lt(number.position.y + number.size.y, enemy_top + 1.0, "the number sits above the enemy")
	var center_x: float = number.position.x + number.size.x * 0.5
	assert_almost_eq(center_x, enemy.position.x, DamageNumber.MAX_JITTER + 1.0, "the number is centered on the enemy")


func test_a_critical_hit_uses_the_gold_font_at_double_size() -> void:
	_hit(enemy, 50.0, true)
	var number: DamageNumber = _numbers()[0]

	assert_eq(number.get_theme_font("font"), DamageNumber.CRIT_FONT)
	assert_eq(number.scale, Vector2(2.0, 2.0), "whole-pixel double size")
	assert_eq(number.pivot_offset, Vector2(roundf(number.size.x * 0.5), number.size.y), "it grows from its bottom center, on a whole pixel")

	number.advance(DamageNumber.LIFETIME)
	_hit(enemy, 50.0, false)
	assert_eq(number.scale, Vector2.ONE, "a reused number drops the crit size")


func test_skills_and_spirits_show_one_number_per_damaged_enemy() -> void:
	world._spawn(world.roster.regular_enemies[0], false)
	(world.enemy_pool.active_nodes().back() as Enemy).position.x = 160.0
	world.resolve_skill(ABILITIES.skills[0])
	assert_eq(_numbers().size(), 2, "thunder hits both enemies")

	world.resolve_spirit_attack(0, ABILITIES.spirits[0])
	assert_eq(_numbers().size(), 3, "the spirit hits the front enemy")


func test_damage_to_the_hero_shows_no_number() -> void:
	world.hero.health.take_damage(DamageResult.new(BigNumber.from_float(5.0), false))

	assert_eq(_numbers().size(), 0)


func test_a_number_rises_fades_and_returns_to_the_pool() -> void:
	_hit(enemy, 7.0, false)
	var number: DamageNumber = _numbers()[0]
	var start_y: float = number.position.y

	number.advance(DamageNumber.LIFETIME * 0.8)
	assert_lt(number.position.y, start_y, "it rises")
	assert_eq(number.position.y, roundf(number.position.y), "it stays on whole pixels")
	assert_lt(number.modulate.a, 1.0, "it fades")

	number.advance(DamageNumber.LIFETIME * 0.3)
	assert_eq(_numbers().size(), 0, "it is released after its lifetime")

	_hit(enemy, 8.0, false)
	assert_eq(_numbers()[0], number, "the pool reuses it")
	assert_eq(number.modulate.a, 1.0, "a reused number starts opaque")
	assert_eq(number.text, "8")
