class_name LayoutRules
extends RefCounted
## Pure sizing rules for the main screen: orientation and integer battle-view scale.

const BATTLE_SIZE: Vector2i = Vector2i(360, 192)
const SIDE_PANEL_WIDTH: float = 460.0
const LANDSCAPE_HEIGHT_SHARE: float = 0.75


## Landscape only when strictly wider than tall; square screens use the portrait layout.
static func is_landscape(screen_size: Vector2) -> bool:
	return screen_size.x > screen_size.y


## Largest integer factor that fits the battle view in its column, never below 1.
static func battle_scale(screen_size: Vector2, landscape: bool) -> int:
	var factor: int
	if landscape:
		var center_width: float = screen_size.x - 2.0 * SIDE_PANEL_WIDTH
		var by_width: int = floori(center_width / BATTLE_SIZE.x)
		var by_height: int = floori(screen_size.y * LANDSCAPE_HEIGHT_SHARE / BATTLE_SIZE.y)
		factor = mini(by_width, by_height)
	else:
		factor = floori(screen_size.x / BATTLE_SIZE.x)
	return maxi(factor, 1)
