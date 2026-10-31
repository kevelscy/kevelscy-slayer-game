class_name UpgradePanel
extends VBoxContainer
## Mejoras page with two tabs: Características, one row per stat upgrade (name, level,
## current value and a buy button priced in gold, or "Máx" once a capped track is
## complete), and Habilidades, the skill page.

const TAB_TITLES: PackedStringArray = ["Características", "Habilidades"]
const TAB_CHARACTERISTICS: int = 0
const TAB_SKILLS: int = 1


class Row:
	var title: String
	var track: UpgradeTrack
	## Formats the track's current value for the label.
	var value_text: Callable
	var label: Label
	var button: Button


var rows: Array[Row] = []
var tab_buttons: Array[Button] = []
var characteristics_page: VBoxContainer
var skills_page: VBoxContainer
var skill_tree: SkillTreePanel

var _session: GameSession
var _tab_group: ButtonGroup = ButtonGroup.new()


func bind(session: GameSession) -> void:
	_session = session
	var tab_row: HBoxContainer = HBoxContainer.new()
	add_child(tab_row)
	for index: int in TAB_TITLES.size():
		var tab: Button = Button.new()
		tab.text = TAB_TITLES[index]
		tab.toggle_mode = true
		tab.button_group = _tab_group
		tab.theme_type_variation = GameTheme.TAB_BUTTON
		tab.focus_mode = Control.FOCUS_NONE
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab.pressed.connect(func() -> void: select_tab(index))
		tab_row.add_child(tab)
		tab_buttons.append(tab)
	characteristics_page = _page()
	skills_page = _page()
	skill_tree = SkillTreePanel.new()
	skills_page.add_child(skill_tree)
	skill_tree.bind(session)
	_add_row("Ataque", session.attack_track, func() -> String: return NumberFormat.format(session.attack_track.value()))
	_add_row("Vida", session.health_track, func() -> String: return NumberFormat.format(session.health_track.value()))
	_add_row("Prob. crítico", session.crit_chance_track, func() -> String: return NumberFormat.decimal(session.crit_chance_track.rate() * 100.0, 1) + "%")
	_add_row("Daño crítico", session.crit_damage_track, func() -> String: return "%d%%" % roundi(session.crit_damage_track.rate() * 100.0))
	_add_row("Vel. ataque", session.attack_speed_track, func() -> String: return NumberFormat.decimal(session.attack_speed_track.rate(), 2) + "/s")
	session.wallet.changed.connect(func(_currency: StringName, _total: BigNumber) -> void: _refresh())
	select_tab(TAB_CHARACTERISTICS)
	_refresh()


func select_tab(index: int) -> void:
	for tab: int in tab_buttons.size():
		tab_buttons[tab].set_pressed_no_signal(tab == index)
	characteristics_page.visible = index == TAB_CHARACTERISTICS
	skills_page.visible = index == TAB_SKILLS


func _page() -> VBoxContainer:
	var page: VBoxContainer = VBoxContainer.new()
	page.add_theme_constant_override("separation", get_theme_constant("separation"))
	add_child(page)
	return page


func _add_row(title: String, track: UpgradeTrack, value_text: Callable) -> void:
	var row: Row = Row.new()
	row.title = title
	row.track = track
	row.value_text = value_text
	var card: PanelContainer = PanelContainer.new()
	card.theme_type_variation = GameTheme.CARD
	var box: HBoxContainer = HBoxContainer.new()
	row.label = Label.new()
	row.label.theme_type_variation = GameTheme.CARD_TEXT
	row.label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.button = Button.new()
	row.button.theme_type_variation = GameTheme.BUY_BUTTON
	row.button.custom_minimum_size = Vector2(220.0, 60.0)
	row.button.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.button.pressed.connect(func() -> void: _on_buy_pressed(track))
	box.add_child(row.label)
	box.add_child(row.button)
	card.add_child(box)
	characteristics_page.add_child(card)
	rows.append(row)


func _on_buy_pressed(track: UpgradeTrack) -> void:
	if _session.try_upgrade(track):
		_refresh()


func _refresh() -> void:
	for row: Row in rows:
		row.label.text = "%s  Nv %d\n%s" % [row.title, row.track.level, row.value_text.call()]
		if row.track.is_maxed():
			row.button.text = "Máx"
			row.button.icon = null
			row.button.disabled = true
			continue
		var cost: BigNumber = row.track.next_cost()
		row.button.text = "Mejorar %s" % NumberFormat.format(cost)
		row.button.icon = GameTheme.coin_texture(GameTheme.COIN_SIZE)
		row.button.disabled = not _session.wallet.can_afford(GameSession.GOLD, cost)
