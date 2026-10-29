class_name NodePool
extends Node
## Reuses instances of `scene` instead of freeing them, to avoid allocation spikes
## on mobile. Inactive nodes stay as hidden children with processing disabled.

@export var scene: PackedScene

var _inactive: Array[Node] = []
var _active: Array[Node] = []


func acquire() -> Node:
	var node: Node
	if _inactive.is_empty():
		node = scene.instantiate()
		add_child(node)
	else:
		node = _inactive.pop_back()
	_set_active(node, true)
	_active.append(node)
	return node


func release(node: Node) -> void:
	var index: int = _active.find(node)
	if index == -1:
		return
	_active.remove_at(index)
	_set_active(node, false)
	_inactive.append(node)


func release_all() -> void:
	for node: Node in _active.duplicate():
		release(node)


func active_nodes() -> Array[Node]:
	return _active


static func _set_active(node: Node, active: bool) -> void:
	node.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
	var canvas_item: CanvasItem = node as CanvasItem
	if canvas_item != null:
		canvas_item.visible = active
