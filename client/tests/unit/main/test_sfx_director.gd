extends GutTest
## Main plays a sound effect on each game event through its SfxPlayer.

const MAIN: PackedScene = preload("res://main/main.tscn")
const ABILITIES: AbilityCatalog = preload("res://data/content/abilities/ability_catalog.tres")

var main: Main
var clock_msec: int = 0


func before_each() -> void:
	main = MAIN.instantiate()
	add_child_autofree(main)
	# Each event happens a second after the previous one, outside every minimum interval.
	main.sfx.clock = func() -> int:
		clock_msec += 1000
		return clock_msec
	watch_signals(main.sfx)


func _played() -> Array[StringName]:
	var ids: Array[StringName] = []
	for index: int in get_signal_emit_count(main.sfx, "played"):
		ids.append(get_signal_parameters(main.sfx, "played", index)[0] as StringName)
	return ids


func test_main_loads_every_catalog_sound() -> void:
	for id: StringName in SfxPlayer.SOUNDS:
		assert_not_null(main.sfx.stream_player(id), "%s is loaded" % id)


func test_enemy_hit_plays_hit_and_a_critical_hit_plays_crit() -> void:
	main.battle_world.enemy_hit.emit(DamageResult.new(BigNumber.one(), false))
	main.battle_world.enemy_hit.emit(DamageResult.new(BigNumber.one(), true))
	assert_eq(_played(), [&"hit", &"crit"] as Array[StringName])


func test_enemy_killed_plays_coin() -> void:
	EventBus.enemy_killed.emit(false)
	assert_eq(_played(), [&"coin"] as Array[StringName])


func test_spirit_attack_plays_spirit() -> void:
	GameState.session.spirits.attacked.emit(0, ABILITIES.spirits[0])
	assert_eq(_played(), [&"spirit"] as Array[StringName])


func test_every_catalog_skill_has_a_sound() -> void:
	for skill: SkillDefinition in ABILITIES.skills:
		assert_true(SfxPlayer.SOUNDS.has(skill.id), "%s has a sound" % skill.id)


func test_each_skill_cast_plays_its_own_sound() -> void:
	var expected: Array[StringName] = []
	for slot_index: int in ABILITIES.skills.size():
		var skill: SkillDefinition = ABILITIES.skills[slot_index]
		GameState.session.skills.cast.emit(slot_index, skill)
		expected.append(skill.id)
	assert_eq(_played(), expected)


func test_buying_each_gold_upgrade_plays_upgrade() -> void:
	var session: GameSession = GameState.session
	session.wallet.add(GameSession.GOLD, BigNumber.from_float(1e12))
	var tracks: Array[UpgradeTrack] = [
		session.attack_track, session.health_track, session.crit_chance_track,
		session.crit_damage_track, session.attack_speed_track,
	]
	for track: UpgradeTrack in tracks:
		assert_true(session.try_upgrade(track), "bought %s" % track)
	assert_eq(_played(), [&"upgrade", &"upgrade", &"upgrade", &"upgrade", &"upgrade"] as Array[StringName])


func test_buying_a_talent_plays_upgrade_but_restoring_talents_plays_nothing() -> void:
	var talents: TalentTree = GameState.session.talents
	var talent_id: StringName = talents.definitions()[0].id
	talents.set_levels({String(talent_id): 1} as Dictionary[String, int])
	assert_eq(_played(), [] as Array[StringName], "restoring is silent")
	talents.shards = 100
	assert_true(talents.try_buy(talent_id))
	assert_eq(_played(), [&"upgrade"] as Array[StringName])


func test_changing_the_bottom_tab_plays_ui_tap() -> void:
	main.tab_bar.select(1)
	assert_eq(_played(), [&"ui_tap"] as Array[StringName])


func test_boss_start_and_boss_defeat_play_their_sounds() -> void:
	var progression: StageProgression = GameState.session.progression
	progression.boss_started.emit(30.0)
	progression.boss_defeated.emit()
	assert_eq(_played(), [&"boss_start", &"boss_defeat"] as Array[StringName])


func test_hero_death_plays_hero_death() -> void:
	EventBus.hero_died.emit()
	assert_eq(_played(), [&"hero_death"] as Array[StringName])


func test_ascending_plays_ascension() -> void:
	GameState.session.ascended.emit(5)
	assert_eq(_played(), [&"ascension"] as Array[StringName])


func test_battle_world_signals_every_damage_an_enemy_takes() -> void:
	var world: BattleWorld = main.battle_world
	world._spawn(world.roster.regular_enemies[0], false)
	var enemy: Enemy = world.enemy_pool.active_nodes().back() as Enemy
	watch_signals(world)
	enemy.health.take_damage(DamageResult.new(BigNumber.one(), true))
	assert_signal_emit_count(world, "enemy_hit", 1)
	assert_true((get_signal_parameters(world, "enemy_hit")[0] as DamageResult).is_critical)
