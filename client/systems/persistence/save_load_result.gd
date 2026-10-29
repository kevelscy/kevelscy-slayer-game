class_name SaveLoadResult
extends RefCounted
## Outcome of reading the save file: a new game, a loaded save, or a rejected one.

enum Status { NEW_GAME, LOADED, REJECTED }

var status: Status
var data: SaveData
var error: String


func _init(load_status: Status, loaded: SaveData = null, reason: String = "") -> void:
	status = load_status
	data = loaded
	error = reason
