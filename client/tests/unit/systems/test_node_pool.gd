extends GutTest

var pool: NodePool


func before_each() -> void:
	var scene: PackedScene = PackedScene.new()
	var template: Node2D = Node2D.new()
	scene.pack(template)
	template.free()
	pool = NodePool.new()
	pool.scene = scene
	add_child_autofree(pool)


func test_acquire_instantiates_visible_child() -> void:
	var node: Node2D = pool.acquire() as Node2D
	assert_not_null(node)
	assert_eq(node.get_parent(), pool)
	assert_true(node.visible)
	assert_eq(pool.active_nodes().size(), 1)


func test_released_node_is_reused() -> void:
	var first: Node = pool.acquire()
	pool.release(first)
	assert_eq(pool.active_nodes().size(), 0)
	assert_false((first as Node2D).visible)
	assert_eq(pool.acquire(), first)
	assert_eq(pool.get_child_count(), 1)


func test_pool_grows_when_all_nodes_are_active() -> void:
	var first: Node = pool.acquire()
	var second: Node = pool.acquire()
	assert_ne(first, second)
	assert_eq(pool.active_nodes().size(), 2)


func test_release_all_deactivates_everything() -> void:
	pool.acquire()
	pool.acquire()
	pool.release_all()
	assert_eq(pool.active_nodes().size(), 0)
