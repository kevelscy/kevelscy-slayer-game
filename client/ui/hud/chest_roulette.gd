class_name ChestRoulette
extends PanelContainer
## Megabonk-style chest roulette: for SPIN_SECONDS it flicks through every reward a
## chest can give, then lands on the rolled one, shows its rarity and only then pays
## it. Chests picked meanwhile wait their turn. The game keeps running underneath and
## the overlay never takes input.

signal revealed(reward: ChestReward)

const SPIN_SECONDS: float = 2.0
const SWAP_SECONDS: float = 0.08
const REVEAL_SECONDS: float = 1.5
## Icons are scaled by the biggest whole factor that fits this size, so pixels stay even.
const ICON_SIZE: int = 64
const SPIN_TITLE: String = "¡Cofre!"
## Rarity text colors in ChestTable.Rarity order.
const RARITY_COLORS: Array[Color] = [
	Color8(192, 206, 209), # Común: Plata
	Color8(50, 154, 234), # Raro: Azul 4
	Color(0.76, 0.5, 1.0), # Épico: the amethyst of the accent buttons
	Color8(240, 133, 13), # Legendario: Naranja 2
	Color8(253, 229, 4), # Super: Amarillo vivo
]
const ICON_PATHS: Dictionary[ChestReward.Kind, String] = {
	ChestReward.Kind.GOLD_MULTIPLIER: "res://art/icons/coin.png",
	ChestReward.Kind.GOLD_BAG: "res://art/icons/gold_bag.png",
	ChestReward.Kind.FREE_FURY: "res://art/icons/skill_fury.png",
	ChestReward.Kind.RECHARGE_SKILLS: "res://art/icons/hourglass.png",
	ChestReward.Kind.SKILL_LEVEL: "res://art/icons/tab_upgrades.png",
	ChestReward.Kind.DAMAGE_MULTIPLIER: "res://art/icons/sword.png",
}

enum Phase { IDLE, SPIN, REVEAL }

static var _icons: Dictionary[ChestReward.Kind, Texture2D] = {}

var title_label: Label = Label.new()
var icon: TextureRect = TextureRect.new()
var reward_label: Label = Label.new()

var _session: GameSession
var _queue: Array[ChestReward] = []
var _current: ChestReward
var _phase: Phase = Phase.IDLE
var _time: float = 0.0
var _swap_time: float = 0.0
## Every reward of every rarity, the order the reel flicks through them.
var _reel: Array[ChestReward] = []
var _reel_index: int = 0


func _init() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for rarity: int in ChestTable.WEIGHTS.size():
		_reel.append_array(ChestTable.rewards_for(rarity))
	var column: VBoxContainer = VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(column)
	for label: Label in [title_label, reward_label]:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.custom_minimum_size = Vector2(260.0, 0.0)
	icon.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	column.add_child(title_label)
	column.add_child(icon)
	column.add_child(reward_label)


func bind(session: GameSession) -> void:
	_session = session
	# A new run starts without the chests of the old one.
	session.ascended.connect(func(_shards: int) -> void: cancel())
	session.save_applied.connect(cancel)


## The reward's icon at ICON_SIZE or below, scaled by a whole factor, built once per kind.
static func icon_for(reward: ChestReward) -> Texture2D:
	if not _icons.has(reward.kind):
		var image: Image = (load(ICON_PATHS[reward.kind]) as Texture2D).get_image()
		# Skill icons hold a silver and a gold frame side by side: use the first.
		if image.get_width() > image.get_height():
			image = image.get_region(Rect2i(0, 0, image.get_height(), image.get_height()))
		var factor: int = maxi(ICON_SIZE / image.get_width(), 1)
		image.resize(image.get_width() * factor, image.get_height() * factor, Image.INTERPOLATE_NEAREST)
		_icons[reward.kind] = ImageTexture.create_from_image(image)
	return _icons[reward.kind]


func enqueue(reward: ChestReward) -> void:
	_queue.append(reward)
	if _phase == Phase.IDLE:
		_next()


## Drops the spinning chest and the queued ones without paying them.
func cancel() -> void:
	_queue.clear()
	_current = null
	_phase = Phase.IDLE
	visible = false


func _process(delta: float) -> void:
	step(delta)


func step(delta: float) -> void:
	match _phase:
		Phase.SPIN:
			_time += delta
			_swap_time += delta
			while _swap_time >= SWAP_SECONDS:
				_swap_time -= SWAP_SECONDS
				_reel_index = (_reel_index + 1) % _reel.size()
				_show(_reel[_reel_index])
			if _time >= SPIN_SECONDS:
				_reveal()
		Phase.REVEAL:
			_time += delta
			if _time >= REVEAL_SECONDS:
				_next()


func _next() -> void:
	if _queue.is_empty():
		cancel()
		return
	_current = _queue.pop_front()
	_phase = Phase.SPIN
	_time = 0.0
	_swap_time = 0.0
	title_label.text = SPIN_TITLE
	title_label.add_theme_color_override(&"font_color", GameTheme.TITLE_GOLD)
	_show(_reel[_reel_index])
	visible = true


func _reveal() -> void:
	_phase = Phase.REVEAL
	_time = 0.0
	title_label.text = ChestTable.RARITY_NAMES[_current.rarity]
	title_label.add_theme_color_override(&"font_color", RARITY_COLORS[_current.rarity])
	_show(_current)
	_session.grant_chest_reward(_current)
	revealed.emit(_current)


func _show(reward: ChestReward) -> void:
	icon.texture = icon_for(reward)
	reward_label.text = reward.label()
