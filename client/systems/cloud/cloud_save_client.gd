class_name CloudSaveClient
extends RefCounted
## Calls the server's pull_save / push_save RPCs for the signed-in player. An
## expired access token (401) is refreshed once and the call retried once.

var _config: CloudConfig
var _transport: HttpTransport
var _auth: SupabaseAuth


func _init(config: CloudConfig, transport: HttpTransport, auth: SupabaseAuth) -> void:
	_config = config
	_transport = transport
	_auth = auth


func pull() -> CloudPullResult:
	var outcome: Dictionary = await _rpc("pull_save", "{}")
	if outcome.has("error"):
		return CloudPullResult.failed(outcome["error"])
	var fields: Dictionary = outcome["fields"]
	var server_now: int = _as_int(fields.get("server_now_unix"), 0)
	var save: Variant = fields.get("save")
	if save == null:
		return CloudPullResult.new(true, null, -1, server_now)
	var decoded: SaveDecodeResult = SaveCodec.decode(JSON.stringify(save))
	if not decoded.is_ok():
		return CloudPullResult.failed(decoded.error)
	return CloudPullResult.new(true, decoded.data, _as_int(fields.get("last_seen_unix"), -1), server_now)


func push(data: SaveData) -> CloudPushResult:
	# The encoded save is embedded as is so integers stay integers in the JSON body.
	var outcome: Dictionary = await _rpc("push_save", "{\"save\": %s}" % SaveCodec.encode(data))
	if outcome.has("error"):
		return CloudPushResult.new(false, 0, outcome["error"])
	return CloudPushResult.new(true, _as_int((outcome["fields"] as Dictionary).get("server_now_unix"), 0))


## Returns {"fields": Dictionary} on success or {"error": String}.
func _rpc(function_name: String, body: String) -> Dictionary:
	var response: HttpResponse
	for attempt: int in 2:
		if not await _auth.ensure_session():
			return {"error": "cloud sign-in unavailable"}
		response = await _transport.send(
			HTTPClient.METHOD_POST,
			"%s/rest/v1/rpc/%s" % [_config.url, function_name],
			_auth.headers(),
			body
		)
		if response.status_code != 401:
			break
		_auth.invalidate()
	if response.is_unreachable():
		return {"error": "cloud unreachable"}
	if not response.is_success():
		return {"error": "cloud rejected the request (%d): %s" % [response.status_code, response.message()]}
	var parsed: Variant = response.json()
	if not parsed is Dictionary:
		return {"error": "cloud response is not a JSON object"}
	return {"fields": parsed}


static func _as_int(value: Variant, fallback: int) -> int:
	return int(value) if value is float or value is int else fallback
