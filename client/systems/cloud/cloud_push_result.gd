class_name CloudPushResult
extends RefCounted
## Outcome of push_save: the server time the save was stamped with.

var ok: bool
var server_now_unix: int
var error: String


func _init(succeeded: bool, server_now: int = 0, reason: String = "") -> void:
	ok = succeeded
	server_now_unix = server_now
	error = reason
