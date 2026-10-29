class_name SpiritPanel
extends VBoxContainer
## The three spirit cards: icon (gold once unlocked, silver and dimmed while locked),
## name and the lock stage or passive bonus. Built in code because every card comes
## from the ability catalog.

const REFRESH_SECONDS: float = 0.1
const ICON_PATH: String = "res://art/icons/spirit_%s.png"
const STAT_NAMES: Dictionary[StringName, String] = {
	StatBlock.ATTACK: "Ataque",
	StatBlock.HEALTH: "Vida",
	StatBlock.CRIT_CHANCE: "Prob. crítico",
	StatBlock.CRIT_DAMAGE: "Daño crítico",
	StatBlock.ATTACK_SPEED: "Vel. ataque",
}

var spirit_cards: Array[PanelContainer] = []
var spirit_icon_rects: Array[TextureRect] = []
## Per spirit card: [silver, gold] icon textures.
var spirit_icons: Array[Array] = []
var spirit_labels: Array[Label] = []

var _session: GameSession
var _refresh_elapsed: float = 0.0


func bind(session: GameSession) -> void:
	_session = session
	add_child(AbilityPanel.section_title("Espíritus"))
	var spirit_row: HBoxContainer = HBoxContainer.new()
	add_child(spirit_row)
	for slot: SpiritTeam.SpiritSlot in session.spirits.slots:
		var card: PanelContainer = PanelContainer.new()
		card.theme_type_variation = GameTheme.CARD
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var column: VBoxContainer = VBoxContainer.new()
		card.add_child(column)
		spirit_icons.append(AbilityPanel.icon_frames(ICON_PATH % slot.definition.id))
		var icon: TextureRect = TextureRect.new()
		icon.expand_mode = TextureRect.EXPAND_KEEP_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		column.add_child(icon)
		var label: Label = Label.new()
		label.theme_type_variation = GameTheme.CARD_TEXT
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.custom_minimum_size = Vector2(0.0, 60.0)
		column.add_child(label)
		spirit_row.add_child(card)
		spirit_cards.append(card)
		spirit_icon_rects.append(icon)
		spirit_labels.append(label)
	refresh()


func _process(delta: float) -> void:
	if _session == null:
		return
	_refresh_elapsed += delta
	if _refresh_elapsed >= REFRESH_SECONDS:
		_refresh_elapsed = 0.0
		refresh()


func refresh() -> void:
	# Locked spirits dim like the icons of disabled skill buttons.
	var dimmed: Color = get_theme_color("icon_disabled_color", &"Button")
	for index: int in spirit_labels.size():
		var slot: SpiritTeam.SpiritSlot = _session.spirits.slots[index]
		spirit_labels[index].text = "%s\n%s" % [slot.definition.display_name, _spirit_status(slot)]
		var icon_rect: TextureRect = spirit_icon_rects[index]
		icon_rect.texture = spirit_icons[index][AbilityPanel.GOLD if slot.unlocked else AbilityPanel.SILVER]
		icon_rect.self_modulate = Color.WHITE if slot.unlocked else dimmed


static func _spirit_status(slot: SpiritTeam.SpiritSlot) -> String:
	var spirit: SpiritDefinition = slot.definition
	if not slot.unlocked:
		return "Etapa %d" % spirit.unlock_stage
	# PERCENT and FLAT rate passives are both fractions, shown as whole percents.
	return "+%d%% %s" % [roundi(spirit.passive_value * 100.0), STAT_NAMES.get(spirit.passive_stat, String(spirit.passive_stat))]
