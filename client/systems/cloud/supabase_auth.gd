class_name SupabaseAuth
extends RefCounted
## Anonymous Supabase session. The first boot signs up an anonymous player; the
## refresh token is kept in a file so later boots resume the same player. Only a
## refresh token the server refuses (4xx) leads to a new sign-up: a network or
## server failure, a timeout (408) or a rate limit (429) keeps the stored player
## for the next attempt.

## Refresh this many seconds before the access token expires.
const EXPIRY_MARGIN_SECONDS: int = 60
## 4xx answers that say "try later", not "this token is dead".
const TRANSIENT_CODES: Array[int] = [408, 429]

var access_token: String = ""
var user_id: String = ""
var _config: CloudConfig
var _transport: HttpTransport
var _token_path: String
var _clock: Callable
var _refresh_token: String = ""
var _expires_at: int = 0


func _init(config: CloudConfig, transport: HttpTransport, token_path: String, clock: Callable) -> void:
	_config = config
	_transport = transport
	_token_path = token_path
	_clock = clock
	_load_tokens()


## True when a usable access token is available, signing in when needed.
func ensure_session() -> bool:
	if access_token != "" and _now() < _expires_at - EXPIRY_MARGIN_SECONDS:
		return true
	if _refresh_token != "":
		var refreshed: HttpResponse = await _post(
			"/auth/v1/token?grant_type=refresh_token", {"refresh_token": _refresh_token}
		)
		if refreshed.is_success():
			return _accept(refreshed)
		if not refreshed.is_rejected() or TRANSIENT_CODES.has(refreshed.status_code):
			_drop_access_token()
			return false
	return _accept(await _post("/auth/v1/signup", {}))


## Forgets the access token so the next ensure_session() refreshes it.
func invalidate() -> void:
	_drop_access_token()


## Request headers for project APIs: the public key plus the player's bearer token.
func headers() -> PackedStringArray:
	var result: PackedStringArray = _base_headers()
	if access_token != "":
		result.append("Authorization: Bearer " + access_token)
	return result


func _post(path: String, payload: Dictionary) -> HttpResponse:
	return await _transport.send(
		HTTPClient.METHOD_POST, _config.url + path, _base_headers(), JSON.stringify(payload)
	)


func _base_headers() -> PackedStringArray:
	return PackedStringArray(["apikey: " + _config.api_key, "Content-Type: application/json"])


func _accept(response: HttpResponse) -> bool:
	var session: Variant = response.json() if response.is_success() else null
	if not session is Dictionary or not (session as Dictionary).get("access_token") is String:
		if response.is_success():
			push_error("SupabaseAuth: unexpected auth response")
		_drop_access_token()
		return false
	var fields: Dictionary = session
	access_token = fields["access_token"]
	_refresh_token = str(fields.get("refresh_token", ""))
	_expires_at = _now() + int(fields.get("expires_in", 0))
	var user: Variant = fields.get("user")
	if user is Dictionary:
		user_id = str((user as Dictionary).get("id", user_id))
	_save_tokens()
	return true


func _drop_access_token() -> void:
	access_token = ""
	_expires_at = 0


func _load_tokens() -> void:
	if not FileAccess.file_exists(_token_path):
		return
	# A JSON instance reports a damaged file without logging an engine error.
	var parser: JSON = JSON.new()
	var parsed: Variant = parser.data if parser.parse(FileAccess.get_file_as_string(_token_path)) == OK else null
	if parsed is Dictionary and (parsed as Dictionary).get("refresh_token") is String:
		_refresh_token = (parsed as Dictionary)["refresh_token"]
		user_id = str((parsed as Dictionary).get("user_id", ""))


func _save_tokens() -> void:
	var file: FileAccess = FileAccess.open(_token_path, FileAccess.WRITE)
	if file == null:
		push_error("SupabaseAuth: could not write %s" % _token_path)
		return
	file.store_string(JSON.stringify({"refresh_token": _refresh_token, "user_id": user_id}))
	file.close()


func _now() -> int:
	return _clock.call() as int
