class_name UpgradePanel
extends VBoxContainer
## One row per stat upgrade: name, level, current value and a buy button priced in gold.


class Row:
	var title: String
	var track: UpgradeTrack
	var label: Label
	var button: Button


var _session: GameSession
var _rows: Array[Row] = []


func bind(session: GameSession) -> void:
	_session = session
	_add_row("Attack", session.attack_track)
	_add_row("Health", session.health_track)
	session.wallet.changed.connect(func(_currency: StringName, _total: BigNumber) -> void: _refresh())
	_refresh()


func _add_row(title: String, track: UpgradeTrack) -> void:
	var row: Row = Row.new()
	row.title = title
	row.track = track
	var box: HBoxContainer = HBoxContainer.new()
	row.label = Label.new()
	row.label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.button = Button.new()
	row.button.custom_minimum_size = Vector2(220.0, 72.0)
	row.button.pressed.connect(func() -> void: _on_buy_pressed(track))
	box.add_child(row.label)
	box.add_child(row.button)
	add_child(box)
	_rows.append(row)


func _on_buy_pressed(track: UpgradeTrack) -> void:
	if _session.try_upgrade(track):
		_refresh()


func _refresh() -> void:
	for row: Row in _rows:
		var cost: BigNumber = row.track.next_cost()
		row.label.text = "%s  Lv %d\n%s" % [row.title, row.track.level, NumberFormat.format(row.track.value())]
		row.button.text = "Up  %s" % NumberFormat.format(cost)
		row.button.disabled = not _session.wallet.can_afford(GameSession.GOLD, cost)
