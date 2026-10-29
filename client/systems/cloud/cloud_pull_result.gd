class_name CloudPullResult
extends RefCounted
## Outcome of pull_save: the player's cloud save (null when there is none), when the
## server last stored it (-1 when there is none) and the server time of the call.

var ok: bool
var data: SaveData
var last_seen_unix: int
var server_now_unix: int
var error: String


func _init(
	succeeded: bool, save: SaveData = null, last_seen: int = -1, server_now: int = 0, reason: String = ""
) -> void:
	ok = succeeded
	data = save
	last_seen_unix = last_seen
	server_now_unix = server_now
	error = reason


static func failed(reason: String) -> CloudPullResult:
	return CloudPullResult.new(false, null, -1, 0, reason)
