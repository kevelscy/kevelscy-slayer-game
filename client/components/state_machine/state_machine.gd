class_name StateMachine
extends Node
## Finite state machine whose states are its State children, addressed by node name.

signal state_changed(state_name: StringName)

@export var initial_state: NodePath

var current_state: State


func _ready() -> void:
	# States usually read the owner's @onready nodes, which exist only after the owner is ready.
	if owner != null and not owner.is_node_ready():
		await owner.ready
	for child: Node in get_children():
		var state: State = child as State
		if state != null:
			state.machine = self
	current_state = get_node_or_null(initial_state) as State
	if current_state == null:
		push_error("StateMachine: initial_state '%s' is not a State child" % initial_state)
		return
	current_state.enter()


func transition_to(state_name: StringName) -> void:
	if current_state != null and current_state.name == state_name:
		return
	var next_state: State = get_node_or_null(NodePath(state_name)) as State
	if next_state == null:
		push_error("StateMachine: unknown state '%s'" % state_name)
		return
	if current_state != null:
		current_state.exit()
	current_state = next_state
	current_state.enter()
	state_changed.emit(state_name)


func _process(delta: float) -> void:
	if current_state != null:
		current_state.update(delta)


func _physics_process(delta: float) -> void:
	if current_state != null:
		current_state.physics_update(delta)
