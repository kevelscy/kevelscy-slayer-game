extends GutTest
## Skill and spirit effects resolved by the real BattleWorld scene.

const BATTLE_WORLD: PackedScene = preload("res://world/battle_world.tscn")
const ABILITIES: AbilityCatalog = preload("res://data/content/abilities/ability_catalog.tres")
const STAGE: int = 20

var world: BattleWorld
var session: GameSession
var enemies: Array[Enemy] = []


func before_each() -> void:
	session = GameSession.new(StageBalance.new(), 10, 30.0, ABILITIES)
	session.progression.restore_stage(STAGE)
	world = BATTLE_WORLD.instantiate()
	add_child_autofree(world)
	world.start(session)
	enemies.clear()
	for x: float in [100.0, 140.0, 180.0]:
		world._spawn(world.roster.regular_enemies[0], false)
		var enemy: Enemy = world.enemy_pool.active_nodes().back() as Enemy
		enemy.position.x = x
		enemies.append(enemy)
	assert_true(enemies[0].health.max_health.gt(session.skill_damage(_skill(&"meteor"))), "precondition: no one-shots")


func _skill(id: StringName) -> SkillDefinition:
	for skill: SkillDefinition in ABILITIES.skills:
		if skill.id == id:
			return skill
	return null


func _lost(enemy: Enemy) -> BigNumber:
	return enemy.health.max_health.sub(enemy.health.current)


func test_thunder_damages_every_living_enemy() -> void:
	var skill: SkillDefinition = _skill(&"thunder")
	world.resolve_skill(skill)
	for enemy: Enemy in enemies:
		assert_true(_lost(enemy).is_equal_approx(session.skill_damage(skill)))


func test_meteor_hits_only_the_front_enemy() -> void:
	var skill: SkillDefinition = _skill(&"meteor")
	world.resolve_skill(skill)
	assert_true(_lost(enemies[0]).is_equal_approx(session.skill_damage(skill)))
	assert_true(_lost(enemies[1]).is_zero())
	assert_true(_lost(enemies[2]).is_zero())


func test_blizzard_damages_and_freezes_every_enemy() -> void:
	var skill: SkillDefinition = _skill(&"blizzard")
	world.resolve_skill(skill)
	for enemy: Enemy in enemies:
		assert_true(_lost(enemy).is_equal_approx(session.skill_damage(skill)))
		assert_true(enemy.is_frozen())


func test_frozen_enemy_neither_walks_nor_attacks_until_it_thaws() -> void:
	var enemy: Enemy = enemies[0]
	enemy.freeze(3.0)
	enemy.advance(1.0, 0.0, -INF)
	assert_eq(enemy.position.x, 100.0)
	assert_false(enemy.try_attack(10.0, true))
	enemy.tick_freeze(3.0)
	assert_false(enemy.is_frozen())
	enemy.advance(1.0, 0.0, -INF)
	assert_lt(enemy.position.x, 100.0)


func test_frozen_enemy_still_scrolls_with_the_world_but_stops_at_contact() -> void:
	var enemy: Enemy = enemies[0]
	enemy.freeze(3.0)
	enemy.advance(1.0, 60.0, 50.0)
	assert_almost_eq(enemy.position.x, 50.0, 1e-6)


func test_respawn_clears_the_freeze_and_plays_the_new_animation() -> void:
	var enemy: Enemy = enemies[0]
	enemy.freeze(3.0)
	var other: EnemyDefinition = world.roster.regular_enemies[1]
	enemy.spawn(other, BigNumber.from_float(10.0), BigNumber.one(), false, Vector2(300.0, 172.0))
	assert_false(enemy.is_frozen())
	assert_eq(enemy.sprite.self_modulate, Color.WHITE)
	assert_eq(enemy.sprite.animation, other.animation.animation_name)
	assert_true(enemy.sprite.is_playing())


func test_thawing_resumes_the_enemy_animation() -> void:
	var enemy: Enemy = enemies[0]
	enemy.freeze(1.0)
	assert_false(enemy.sprite.is_playing())
	enemy.tick_freeze(1.0)
	assert_true(enemy.sprite.is_playing())
	assert_eq(enemy.sprite.animation, enemy.definition.animation.animation_name)


func test_fury_buffs_the_hero() -> void:
	var attack_before: BigNumber = session.hero_stats.get_big(StatBlock.ATTACK)
	world.resolve_skill(_skill(&"fury"))
	assert_true(session.hero_stats.get_big(StatBlock.ATTACK).gt(attack_before))
	assert_false(session.buffs.is_empty())


func test_shield_protects_the_hero() -> void:
	var skill: SkillDefinition = _skill(&"shield")
	world.resolve_skill(skill)
	assert_true(world.hero.health.has_shield())
	assert_true(world.hero.health.shield.is_equal_approx(session.shield_amount(skill)))


func test_spirit_attack_hits_the_front_enemy() -> void:
	var spirit: SpiritDefinition = ABILITIES.spirits[0]
	world.resolve_spirit_attack(0, spirit)
	assert_true(_lost(enemies[0]).is_equal_approx(session.spirit_damage(spirit)))
	assert_true(_lost(enemies[1]).is_zero())


func test_casting_from_the_skill_bar_reaches_the_world() -> void:
	assert_true(session.skills.try_cast(0, STAGE, true))
	assert_true(_lost(enemies[2]).is_equal_approx(session.skill_damage(_skill(&"thunder"))))


func test_one_orb_per_unlocked_spirit() -> void:
	assert_eq(world.spirit_orb_count(), 3)
	var fresh: GameSession = GameSession.new(StageBalance.new(), 10, 30.0, ABILITIES)
	var other: BattleWorld = BATTLE_WORLD.instantiate()
	add_child_autofree(other)
	other.start(fresh)
	assert_eq(other.spirit_orb_count(), 0)
	fresh.progression.restore_stage(2)
	assert_eq(other.spirit_orb_count(), 1)
