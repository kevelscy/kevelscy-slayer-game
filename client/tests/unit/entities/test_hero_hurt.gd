extends GutTest
## An enemy hit turns the hero a bit red and knocks it back to the left, then it
## returns to its spot (playtest feedback S5).

const HERO_SCENE: PackedScene = preload("res://entities/hero/hero.tscn")

var hero: Hero
var home: Vector2


func before_each() -> void:
	var session: GameSession = GameSession.new(StageBalance.new(), 10, 30.0)
	hero = HERO_SCENE.instantiate()
	add_child_autofree(hero)
	hero.setup(session.hero_stats, BigNumber.from_float(100.0))
	home = hero.sprite.position


func _hit(amount: float) -> void:
	hero.health.take_damage(DamageResult.new(BigNumber.from_float(amount), false))


func test_a_hit_tints_the_hero_red_and_pushes_it_left_then_back() -> void:
	_hit(10.0)
	assert_true(hero.is_hurt())
	assert_eq(hero.modulate, Hero.HURT_TINT, "red right at the hit")
	assert_gt(Hero.HURT_TINT.r, Hero.HURT_TINT.g, "reddish")
	assert_eq(Hero.HURT_TINT.g, Hero.HURT_TINT.b)
	hero._process(Hero.HURT_SECONDS * 0.5)
	assert_almost_eq(hero.sprite.position.x, home.x - Hero.HURT_KNOCKBACK, 0.001, "furthest back halfway")
	assert_eq(hero.sprite.position.y, home.y)
	assert_gt(hero.modulate.g, Hero.HURT_TINT.g, "the red fades")
	hero._process(Hero.HURT_SECONDS * 0.5)
	assert_false(hero.is_hurt())
	assert_eq(hero.sprite.position, home, "back at its spot")
	assert_eq(hero.modulate, Color.WHITE)


func test_a_new_hit_restarts_the_reaction() -> void:
	_hit(10.0)
	hero._process(Hero.HURT_SECONDS * 0.9)
	_hit(10.0)
	assert_eq(hero.modulate, Hero.HURT_TINT)
	hero._process(Hero.HURT_SECONDS * 0.5)
	assert_almost_eq(hero.sprite.position.x, home.x - Hero.HURT_KNOCKBACK, 0.001)


func test_a_hit_the_shield_absorbs_does_not_hurt() -> void:
	hero.health.set_shield(BigNumber.from_float(50.0), 5.0)
	_hit(10.0)
	assert_false(hero.is_hurt())
	assert_eq(hero.modulate, Color.WHITE)


func test_the_killing_hit_leaves_the_sprite_in_place_for_the_death() -> void:
	_hit(1000.0)
	assert_false(hero.is_hurt())
	hero._process(Hero.HURT_SECONDS * 0.5)
	assert_eq(hero.sprite.position, home)


func test_a_restart_clears_the_reaction() -> void:
	_hit(10.0)
	hero._process(Hero.HURT_SECONDS * 0.5)
	hero.restart(BigNumber.from_float(100.0))
	assert_false(hero.is_hurt())
	assert_eq(hero.sprite.position, home)
	assert_eq(hero.modulate, Color.WHITE)
