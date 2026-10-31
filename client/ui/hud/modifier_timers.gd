class_name ModifierTimers
extends VBoxContainer
## The active chest modifiers over the battle view, one row each: its icon, a small
## factor and the seconds it has left ([coin]x4 58s). Hidden while none runs, and it
## never takes input. Refreshed at 10 Hz like the HUD.

const REFRESH_SECONDS: float = 0.1
## 16 px icons shown at 2x so their pixels stay even.
const ICON_SIZE: int = 32
const SWORD_PATH: String = "res://art/icons/sword.png"
const FACTOR_FONT_SIZE: int = 18
const SECONDS_FONT_SIZE: int = 24
const OUTLINE_SIZE: int = 6


## One modifier: [icon][x4][58s].
class ModifierRow extends HBoxContainer:
	var icon: TextureRect = TextureRect.new()
	var factor_label: Label = ModifierTimers._label(FACTOR_FONT_SIZE, GameTheme.TITLE_GOLD)
	var seconds_label: Label = ModifierTimers._label(SECONDS_FONT_SIZE, Color.WHITE)

	func _init(texture: Texture2D) -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_theme_constant_override("separation", 4)
		icon.texture = texture
		icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# The small factor sits low, next to the icon's base.
		factor_label.size_flags_vertical = Control.SIZE_SHRINK_END
		add_child(icon)
		add_child(factor_label)
		add_child(seconds_label)
		visible = false

	func show_boost(boost: ChestBoost) -> void:
		visible = boost.multiplier() > 1.0
		if visible:
			factor_label.text = "x%d" % roundi(boost.factor)
			seconds_label.text = "%ds" % ceili(boost.seconds_left)


var gold_row: ModifierRow = ModifierRow.new(GameTheme.coin_texture(ICON_SIZE))
var damage_row: ModifierRow = ModifierRow.new(_icon_texture(SWORD_PATH))

var _session: GameSession
var _elapsed: float = 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", 2)
	add_child(gold_row)
	add_child(damage_row)
	visible = false


func bind(session: GameSession) -> void:
	_session = session
	refresh()


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed < REFRESH_SECONDS:
		return
	_elapsed = 0.0
	refresh()


func refresh() -> void:
	if _session == null:
		return
	gold_row.show_boost(_session.gold_boost)
	damage_row.show_boost(_session.damage_boost)
	visible = gold_row.visible or damage_row.visible


static func _icon_texture(path: String) -> Texture2D:
	var image: Image = (load(path) as Texture2D).get_image()
	image.resize(ICON_SIZE, ICON_SIZE, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(image)


static func _label(font_size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", OUTLINE_SIZE)
	return label
