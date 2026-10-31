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
	for slot: SkillSlot in session.skills.slots:
		slot.level = 1
	session.skills.equip_owned()
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


func test_wind_dash_hits_only_the_nearest_enemy() -> void:
	var skill: SkillDefinition = _skill(&"wind")
	world.resolve_skill(skill)
	assert_true(_lost(enemies[0]).is_equal_approx(session.skill_damage(skill)))
	assert_true(_lost(enemies[1]).is_zero())
	assert_true(_lost(enemies[2]).is_zero())


func _dash_setup() -> float:
	session.skills.autocast_enabled = false
	for index: int in enemies.size():
		enemies[index].position.x = 200.0 + 40.0 * index
	return world.hero.position.x + Hero.ATTACK_RANGE * 0.5 + enemies[0].body_half_width()


func _front_layer_speed() -> float:
	var layers: Array[Node] = world.background.get_children()
	return -(layers.back() as Parallax2D).autoscroll.x


## S4: the hero dashes forward and the camera follows, so the whole world scrolls
## toward it; the hero keeps its lane spot and never comes back.
func test_wind_dash_scrolls_the_world_until_the_front_enemy_reaches_the_hero() -> void:
	var contact_x: float = _dash_setup()
	var home: Vector2 = world.hero.position
	var sprite_home: Vector2 = world.hero.sprite.position
	var distance: float = 200.0 - contact_x
	world.resolve_skill(_skill(&"wind"))
	assert_true(world.is_dashing())
	assert_eq(world.hero.sprite.animation, &"attack", "sword stab")
	world._process(BattleWorld.DASH_SECONDS * 0.5)
	assert_lte(enemies[1].position.x, 240.0 - distance * 0.5 + 0.001, "half the dash done")
	assert_eq(world.hero.sprite.position, sprite_home, "the sprite does not lunge")
	world._process(BattleWorld.DASH_SECONDS * 0.5)
	assert_false(world.is_dashing())
	assert_almost_eq(enemies[0].position.x, contact_x, 0.001, "front enemy at the hero")
	assert_lte(enemies[1].position.x, 240.0 - distance + 0.001, "the rest of the world moved as far")
	assert_eq(world.hero.position, home, "the hero keeps its lane spot")
	assert_eq(world.hero.sprite.position, sprite_home)


func test_wind_dash_scrolls_the_background_with_it_then_back_to_the_normal_speed() -> void:
	var contact_x: float = _dash_setup()
	var base: float = BattleWorld.RUN_SPEED if world.hero.is_running() else 0.0
	world.resolve_skill(_skill(&"wind"))
	world._process(0.05)
	var dash_speed: float = (200.0 - contact_x) / BattleWorld.DASH_SECONDS
	assert_almost_eq(_front_layer_speed(), base + dash_speed, 0.01)
	world._process(BattleWorld.DASH_SECONDS)
	assert_false(world.is_dashing())
	world._process(0.05)
	assert_lte(_front_layer_speed(), BattleWorld.RUN_SPEED, "no dash speed left, never a return")
	assert_gte(_front_layer_speed(), 0.0, "never scrolls back")


func test_wind_dash_never_brings_the_world_back() -> void:
	_dash_setup()
	world.resolve_skill(_skill(&"wind"))
	world._process(BattleWorld.DASH_SECONDS)
	var after_dash: float = enemies[2].position.x
	world._process(0.2)
	assert_lte(enemies[2].position.x, after_dash, "no return")


func test_wind_dash_runs_over_a_chest_in_its_way() -> void:
	_dash_setup()
	watch_signals(world)
	world._drop_chest(world.hero.position.x + 40.0)
	world.resolve_skill(_skill(&"wind"))
	world._process(BattleWorld.DASH_SECONDS)
	assert_signal_emit_count(world, "chest_picked", 1)


func test_wind_without_enemies_does_not_dash() -> void:
	for enemy: Enemy in enemies:
		enemy.vanish()
	world.resolve_skill(_skill(&"wind"))
	assert_false(world.is_dashing())


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


## skill-branches S6.1: the burning sword adds 50% to the hero's own hits and burns.
func test_burning_sword_makes_sword_hits_half_stronger_while_it_burns() -> void:
	var front: Enemy = enemies[0]
	front.health.setup(BigNumber.from_float(1e30))
	world.hero.target = front
	world.hero.rng.seed = 7
	world.hero.perform_attack()
	var plain: BigNumber = _lost(front)
	assert_false(world.hero.sword_flame.emitting)
	world.resolve_skill(_skill(&"burning_sword"))
	world._process(0.0)
	assert_true(world.hero.sword_flame.emitting, "the sword burns while the buff lasts")
	front.health.setup(BigNumber.from_float(1e30))
	world.hero.rng.seed = 7
	world.hero.perform_attack()
	assert_true(_lost(front).is_equal_approx(plain.mul_float(1.5)))
	world._process(_skill(&"burning_sword").duration_seconds + 0.1)
	assert_false(world.hero.sword_flame.emitting, "the fire goes out with the buff")


## skill-branches S6.5: Curación heals half the max health over four seconds.
func test_heal_restores_half_the_max_health_over_four_seconds() -> void:
	var skill: SkillDefinition = _skill(&"heal")
	var health: HealthComponent = world.hero.health
	health.current = health.max_health.mul_float(0.1)
	assert_false(skill.needs_target(), "it heals with no enemy around")
	world.resolve_skill(skill)
	assert_true(session.heal_amount(skill).is_equal_approx(health.max_health.mul_float(0.5)))
	health.tick_regen(2.0)
	assert_true(health.current.is_equal_approx(health.max_health.mul_float(0.35)))
	health.tick_regen(2.0)
	assert_true(health.current.is_equal_approx(health.max_health.mul_float(0.6)))


## skill-branches S6.6: Bloque de Hielo hits the front enemy only, thrown by the hero.
func test_ice_block_hits_only_the_front_enemy() -> void:
	var skill: SkillDefinition = _skill(&"ice_block")
	assert_true(skill.needs_target())
	world.resolve_skill(skill)
	assert_true(_lost(enemies[0]).is_equal_approx(session.skill_damage(skill)))
	assert_true(_lost(enemies[1]).is_zero())
	assert_true(_lost(enemies[2]).is_zero())
	var shot: AbilityEffects.Flash = world.effects.last_flash()
	assert_eq(shot.kind, SkillDefinition.Effect.THROW_FRONT)
	assert_true(shot.from.distance_to(world.hero.position) < 40.0, "thrown from the hero, not the sky")


## skill-branches S6.2: Onda de Llamas crosses the scene and hits each enemy it reaches once.
func test_flame_wave_crosses_the_scene_hitting_each_enemy_once() -> void:
	var skill: SkillDefinition = _skill(&"flame_wave")
	assert_true(skill.needs_target())
	world.resolve_skill(skill)
	assert_eq(world.flame_waves.size(), 1)
	assert_true(_lost(enemies[0]).is_zero(), "the wave has to travel first")
	world.tick_skill_effects(0.1)
	assert_true(_lost(enemies[0]).is_equal_approx(session.skill_damage(skill)), "the front enemy is reached first")
	assert_true(_lost(enemies[2]).is_zero(), "the back enemy is still ahead of the wave")
	for step: int in 30:
		world.tick_skill_effects(0.1)
	for enemy: Enemy in enemies:
		assert_true(_lost(enemy).is_equal_approx(session.skill_damage(skill)), "one hit per enemy")
	assert_true(world.flame_waves.is_empty(), "gone once it leaves the scene")


func test_a_new_run_puts_out_the_flame_wave() -> void:
	world.resolve_skill(_skill(&"flame_wave"))
	world._restart_run()
	assert_true(world.flame_waves.is_empty())


## skill-branches S6.4: Tajo Relámpago strikes every enemy for 2x attack every 0.4 s for 4 s.
func test_thunder_slash_strikes_every_enemy_every_0_4_s_for_4_s() -> void:
	var skill: SkillDefinition = _skill(&"thunder_slash")
	assert_true(skill.needs_target())
	for enemy: Enemy in enemies:
		enemy.health.setup(session.skill_damage(skill).mul_float(100.0))
	world.resolve_skill(skill)
	for enemy: Enemy in enemies:
		assert_true(_lost(enemy).is_equal_approx(session.skill_damage(skill)), "the first strike lands on cast")
	world.tick_skill_effects(0.3)
	assert_true(_lost(enemies[0]).is_equal_approx(session.skill_damage(skill)), "no strike before 0.4 s")
	world.tick_skill_effects(0.1)
	for step: int in 8:
		world.tick_skill_effects(0.4)
	for enemy: Enemy in enemies:
		assert_true(_lost(enemy).is_equal_approx(session.skill_damage(skill).mul_float(10.0)), "ten strikes in 4 s")
	world.tick_skill_effects(2.0)
	assert_true(_lost(enemies[0]).is_equal_approx(session.skill_damage(skill).mul_float(10.0)), "it stops after 4 s")
	assert_true(world.barrages.is_empty())


func test_a_new_run_stops_the_thunder_slash() -> void:
	world.resolve_skill(_skill(&"thunder_slash"))
	world._restart_run()
	assert_true(world.barrages.is_empty())


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
	assert_true(session.skills.try_cast(0, true))
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
