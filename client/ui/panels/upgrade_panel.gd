class_name UpgradePanel
extends VBoxContainer
## One row per stat upgrade: name, level, current value and a buy button priced in
## gold, or "Máx" once a capped track is complete.


class Row:
	var title: String
	var track: UpgradeTrack
	## Formats the track's current value for the label.
	var value_text: Callable
	var label: Label
	var button: Button


var rows: Array[Row] = []

var _session: GameSession


func bind(session: GameSession) -> void:
	_session = session
	_add_row("Ataque", session.attack_track, func() -> String: return NumberFormat.format(session.attack_track.value()))
	_add_row("Vida", session.health_track, func() -> String: return NumberFormat.format(session.health_track.value()))
	_add_row("Prob. crítico", session.crit_chance_track, func() -> String: return NumberFormat.decimal(session.crit_chance_track.rate() * 100.0, 1) + "%")
	_add_row("Daño crítico", session.crit_damage_track, func() -> String: return "%d%%" % roundi(session.crit_damage_track.rate() * 100.0))
	_add_row("Vel. ataque", session.attack_speed_track, func() -> String: return NumberFormat.decimal(session.attack_speed_track.rate(), 2) + "/s")
	session.wallet.changed.connect(func(_currency: StringName, _total: BigNumber) -> void: _refresh())
	_refresh()


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
	row.button.pressed.connect(func() -> void: _on_buy_pressed(track))
	box.add_child(row.label)
	box.add_child(row.button)
	card.add_child(box)
	add_child(card)
	rows.append(row)


func _on_buy_pressed(track: UpgradeTrack) -> void:
	if _session.try_upgrade(track):
		_refresh()


func _refresh() -> void:
	for row: Row in rows:
		row.label.text = "%s  Nv %d\n%s" % [row.title, row.track.level, row.value_text.call()]
		if row.track.is_maxed():
			row.button.text = "Máx"
			row.button.disabled = true
			continue
		var cost: BigNumber = row.track.next_cost()
		row.button.text = "Mejorar %s" % NumberFormat.format(cost)
		row.button.disabled = not _session.wallet.can_afford(GameSession.GOLD, cost)
