class_name SaveDecodeResult
extends RefCounted
## Either decoded save data or the reason the whole save was rejected.

var data: SaveData
var error: String


func _init(decoded: SaveData, reason: String = "") -> void:
	data = decoded
	error = reason


func is_ok() -> bool:
	return data != null
