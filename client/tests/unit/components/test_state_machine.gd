extends GutTest


class RecordingState:
	extends State

	var entries: Array[String]

	func _init(state_name: String, shared_entries: Array[String]) -> void:
		name = state_name
		entries = shared_entries

	func enter() -> void:
		entries.append("enter:" + name)

	func exit() -> void:
		entries.append("exit:" + name)

	func update(_delta: float) -> void:
		entries.append("update:" + name)


var machine: StateMachine
var calls: Array[String] = []


func before_each() -> void:
	calls.clear()
	machine = StateMachine.new()
	machine.add_child(RecordingState.new("Run", calls))
	machine.add_child(RecordingState.new("Attack", calls))
	machine.initial_state = NodePath("Run")
	watch_signals(machine)
	add_child_autofree(machine)


func test_enters_initial_state_when_ready() -> void:
	assert_eq(machine.current_state.name, &"Run")
	assert_eq(calls, ["enter:Run"] as Array[String])


func test_transition_exits_then_enters() -> void:
	machine.transition_to(&"Attack")
	assert_eq(machine.current_state.name, &"Attack")
	assert_eq(calls, ["enter:Run", "exit:Run", "enter:Attack"] as Array[String])
	assert_signal_emitted_with_parameters(machine, "state_changed", [&"Attack"])


func test_transition_to_current_state_is_ignored() -> void:
	machine.transition_to(&"Run")
	assert_eq(calls, ["enter:Run"] as Array[String])


func test_unknown_state_keeps_current() -> void:
	machine.transition_to(&"Fly")
	assert_eq(machine.current_state.name, &"Run")
	assert_push_error("StateMachine")


func test_process_updates_only_current_state() -> void:
	machine._process(0.016)
	assert_eq(calls, ["enter:Run", "update:Run"] as Array[String])


func test_states_know_their_machine() -> void:
	var state: State = machine.get_node("Attack")
	assert_eq(state.machine, machine)
