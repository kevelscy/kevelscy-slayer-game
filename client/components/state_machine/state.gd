class_name State
extends Node
## Base state. Override the hooks you need; `machine` is set by the owning StateMachine.

var machine: StateMachine


func enter() -> void:
	pass


func exit() -> void:
	pass


func update(_delta: float) -> void:
	pass


func physics_update(_delta: float) -> void:
	pass
