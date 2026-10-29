class_name AscensionPanel
extends PanelContainer
## Full-screen overlay for the prestige loop: shard balance, ascension count, the
## ascend button (behind a confirmation) and one buy row per talent. Built in code
## because every row comes from the talent catalog.

const BACKGROUND: Color = Color(0.08, 0.09, 0.12, 1.0)
## Content width: the full portrait width, centered in landscape.
const CONTENT_WIDTH: float = 720.0
const STAT_NAMES: Dictionary[StringName, String] = {
	StatBlock.ATTACK: "attack",
	StatBlock.HEALTH: "health",
	StatBlock.CRIT_CHANCE: "crit chance",
	StatBlock.CRIT_DAMAGE: "crit damage",
	StatBlock.ATTACK_SPEED: "attack speed",
	TalentDefinition.GOLD_GAIN: "gold",
}


class Row:
	var talent: TalentDefinition
	var label: Label
	var button: Button


var rows: Array[Row] = []
var shards_label: Label
var count_label: Label
var ascend_button: Button
var close_button: Button
var confirm_dialog: ConfirmationDialog

var _session: GameSession


func bind(session: GameSession) -> void:
	_session = session
	# The overlay covers the battle, so it needs its own opaque background.
	var background: StyleBoxFlat = StyleBoxFlat.new()
	background.bg_color = BACKGROUND
	add_theme_stylebox_override("panel", background)
	var margin: MarginContainer = MarginContainer.new()
	for side: String in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	margin.custom_minimum_size = Vector2(CONTENT_WIDTH, 0.0)
	margin.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	add_child(margin)
	var column: VBoxContainer = VBoxContainer.new()
	margin.add_child(column)

	var header: HBoxContainer = HBoxContainer.new()
	column.add_child(header)
	var title: Label = Label.new()
	title.text = "Ascension"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	close_button = Button.new()
	close_button.text = "Close"
	close_button.custom_minimum_size = Vector2(160.0, 72.0)
	close_button.pressed.connect(hide)
	header.add_child(close_button)

	var balance_row: HBoxContainer = HBoxContainer.new()
	column.add_child(balance_row)
	shards_label = Label.new()
	shards_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	balance_row.add_child(shards_label)
	count_label = Label.new()
	balance_row.add_child(count_label)

	ascend_button = Button.new()
	ascend_button.custom_minimum_size = Vector2(0.0, 88.0)
	ascend_button.pressed.connect(_on_ascend_pressed)
	column.add_child(ascend_button)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var list: VBoxContainer = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	for talent: TalentDefinition in session.talents.definitions():
		list.add_child(_build_row(talent))

	confirm_dialog = ConfirmationDialog.new()
	confirm_dialog.title = "Ascend"
	confirm_dialog.confirmed.connect(_on_ascend_confirmed)
	add_child(confirm_dialog)

	# Stage changes enable the ascend button; ascending is refreshed by its handler.
	session.progression.stage_changed.connect(func(_stage: int) -> void: refresh())
	refresh()


func open() -> void:
	refresh()
	show()


func refresh() -> void:
	shards_label.text = "Shards %d" % _session.talents.shards
	count_label.text = "Ascensions %d" % _session.ascension_count
	if _session.can_ascend():
		ascend_button.text = "Ascend +%d shards" % _session.ascension_shards_on_ascend()
		ascend_button.disabled = false
	else:
		ascend_button.text = "Ascend (Stage %d)" % GameSession.ASCEND_MIN_STAGE
		ascend_button.disabled = true
	for row: Row in rows:
		_refresh_row(row)


func _build_row(talent: TalentDefinition) -> HBoxContainer:
	var row: Row = Row.new()
	row.talent = talent
	var box: HBoxContainer = HBoxContainer.new()
	row.label = Label.new()
	row.label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.button = Button.new()
	row.button.custom_minimum_size = Vector2(240.0, 72.0)
	row.button.pressed.connect(func() -> void: _on_buy_pressed(talent.id))
	box.add_child(row.label)
	box.add_child(row.button)
	rows.append(row)
	return box


func _refresh_row(row: Row) -> void:
	var talents: TalentTree = _session.talents
	var talent: TalentDefinition = row.talent
	var level: int = talents.level(talent.id)
	row.label.text = "%s  Lv %d/%d\n+%d%% %s" % [
		talent.display_name, level, talent.max_level,
		roundi(talent.per_level * level * 100.0), STAT_NAMES.get(talent.stat, String(talent.stat)),
	]
	if talents.is_maxed(talent.id):
		row.button.text = "Max"
		row.button.disabled = true
	elif not talents.is_unlocked(talent.id):
		row.button.text = "Needs %s %d" % [talents.definition(talent.requires).display_name, talent.requires_level]
		row.button.disabled = true
	else:
		var cost: int = talents.next_cost(talent.id)
		row.button.text = "Up  %d %s" % [cost, "shard" if cost == 1 else "shards"]
		row.button.disabled = talents.shards < cost


func _on_buy_pressed(talent_id: StringName) -> void:
	if _session.talents.try_buy(talent_id):
		refresh()


func _on_ascend_pressed() -> void:
	if not _session.can_ascend():
		return
	confirm_dialog.dialog_text = (
		"Restart from stage 1 for +%d shards?\nGold, upgrades, skills and spirits reset; talents stay."
		% _session.ascension_shards_on_ascend()
	)
	confirm_dialog.popup_centered()


func _on_ascend_confirmed() -> void:
	_session.ascend()
	refresh()
