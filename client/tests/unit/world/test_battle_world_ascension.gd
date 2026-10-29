extends GutTest
## The battle lane restarts cleanly after an ascension, and Vitality raises the
## hero's max health right away.

const BATTLE_WORLD: PackedScene = preload("res://world/battle_world.tscn")
const ABILITIES: AbilityCatalog = preload("res://data/content/abilities/ability_catalog.tres")
const TALENTS: TalentCatalog = preload("res://data/content/talents/talent_catalog.tres")

var world: BattleWorld
var session: GameSession


func before_each() -> void:
	session = GameSession.new(StageBalance.new(), 10, 30.0, ABILITIES, TALENTS)
	session.progression.restore_stage(20)
	world = BATTLE_WORLD.instantiate()
	add_child_autofree(world)
	world.start(session)
	for x: float in [100.0, 140.0]:
		world._spawn(world.roster.regular_enemies[0], false)
		(world.enemy_pool.active_nodes().back() as Enemy).position.x = x


func _alive_enemies() -> int:
	return world.enemy_pool.active_nodes().filter(func(node: Node) -> bool: return (node as Enemy).is_alive).size()


func test_ascending_clears_enemies_orbs_and_heals_the_hero() -> void:
	world.hero.health.take_damage(DamageResult.new(BigNumber.from_float(30.0), false))
	world.scheduler.queue_boss()
	assert_eq(world.spirit_orb_count(), 3, "precondition")
	session.ascend()
	assert_eq(_alive_enemies(), 0)
	assert_eq(world.spirit_orb_count(), 0)
	assert_true(world.hero.health.max_health.is_equal_approx(session.hero_max_health()))
	assert_true(world.hero.health.current.is_equal_approx(world.hero.health.max_health))
	assert_eq(world.scheduler.tick(0.0, 0, false), SpawnScheduler.Order.NONE, "the queued boss is dropped")


func test_spirit_orbs_come_back_as_the_new_run_reaches_their_stage() -> void:
	session.ascend()
	session.progression.restore_stage(2)
	assert_eq(world.spirit_orb_count(), 1)


func test_vitality_raises_the_hero_max_health() -> void:
	var before: BigNumber = world.hero.health.max_health
	session.talents.shards = 1
	assert_true(session.talents.try_buy(&"vitality"))
	assert_true(world.hero.health.max_health.gt(before))
	assert_true(world.hero.health.max_health.is_equal_approx(session.hero_max_health()))


func test_applying_a_save_restarts_the_lane_with_the_saved_stage_orbs() -> void:
	world.hero.health.take_damage(DamageResult.new(BigNumber.from_float(30.0), false))
	var data: SaveData = session.to_save(0)
	data.stage = 2
	data.ascension_count = 1
	session.apply_save(data)
	assert_eq(_alive_enemies(), 0)
	assert_eq(world.spirit_orb_count(), 1)
	assert_true(world.hero.health.current.is_equal_approx(world.hero.health.max_health))
