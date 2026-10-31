extends GutTest
## The audience is Spanish: the texts not covered by the panel tests (HUD, offline toast,
## section titles, catalog names) are Spanish with a decimal comma.

const MAIN: PackedScene = preload("res://main/main.tscn")
const CATALOG: AbilityCatalog = preload("res://data/content/abilities/ability_catalog.tres")

var main: Main


func before_each() -> void:
	main = MAIN.instantiate()
	add_child_autofree(main)


func _section_titles(panel: Node) -> Array[String]:
	var titles: Array[String] = []
	for label: Node in panel.find_children("*", "Label", true, false):
		if (label as Label).theme_type_variation == GameTheme.SECTION_TITLE:
			titles.append((label as Label).text)
	return titles


func test_hud_shows_stage_gold_and_the_ascension_button_in_spanish() -> void:
	main.hud._refresh()
	assert_eq(main.hud.stage_label.text, "Etapa %d" % GameState.session.progression.stage)
	# The coin icon names the currency, so the label is only the amount.
	assert_eq(main.hud.gold_label.text, NumberFormat.format(GameState.session.wallet.get_amount(GameSession.GOLD)))
	assert_same(main.hud.gold_icon.texture, GameTheme.coin_texture(GameTheme.COIN_SIZE))
	assert_eq(main.hud.ascension_button.text, "Ascensión")


func test_boss_timer_reads_jefe_with_a_decimal_comma() -> void:
	var progression: StageProgression = GameState.session.progression
	var was_boss: bool = progression.is_boss_active
	var time_left: float = progression.boss_time_left
	progression.is_boss_active = true
	progression.boss_time_left = 12.34
	main.hud._refresh()
	# The session is the shared autoload one: put the boss state back.
	progression.is_boss_active = was_boss
	progression.boss_time_left = time_left
	assert_eq(main.hud.progress_label.text, "JEFE 12,3s")


func test_offline_toast_welcomes_the_player_back_in_spanish() -> void:
	var gold: Dictionary[StringName, BigNumber] = {GameSession.GOLD: BigNumber.from_float(1234.0)}
	main._show_offline_reward(OfflineReward.new(3725, gold))
	assert_eq(main.toast_label.text, "¡Hola de nuevo!\n+1,23K de oro (1h 02m fuera)")


func test_section_titles_are_spanish() -> void:
	assert_eq(_section_titles(main.ability_panel), ["Habilidades"] as Array[String])
	assert_eq(_section_titles(main.spirit_panel), ["Espíritus"] as Array[String])
	assert_eq(_section_titles(main.upgrade_panel), [
		"Mejoras", "Fuego", "Eléctrico", "Hielo", "Incremento", "Defensivo", "Aire",
	] as Array[String], "skill branches sit in the Habilidades tab")


func test_skill_and_spirit_names_are_spanish() -> void:
	var names: Array[String] = []
	for skill: SkillDefinition in CATALOG.skills:
		names.append(skill.display_name)
	for spirit: SpiritDefinition in CATALOG.spirits:
		names.append(spirit.display_name)
	assert_eq(names, [
		"Trueno", "Meteoro", "Ventisca", "Furia", "Escudo", "Viento", "Fuego fatuo", "Zorro ígneo", "Búho de escarcha",
	] as Array[String])
