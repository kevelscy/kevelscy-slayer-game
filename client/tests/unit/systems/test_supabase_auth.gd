extends GutTest

const URL: String = "http://cloud.test"
const KEY: String = "sb_publishable_test"
const T0: int = 1_700_000_000

var dir_path: String
var token_path: String
var transport: FakeHttpTransport
var now: int
var auth: SupabaseAuth


func before_each() -> void:
	dir_path = "user://test_auth/%d" % randi()
	DirAccess.make_dir_recursive_absolute(dir_path)
	token_path = dir_path.path_join("auth.json")
	transport = FakeHttpTransport.new()
	now = T0
	auth = _new_auth()


func after_each() -> void:
	for file_name: String in DirAccess.get_files_at(dir_path):
		DirAccess.remove_absolute(dir_path.path_join(file_name))
	DirAccess.remove_absolute(dir_path)


func _new_auth() -> SupabaseAuth:
	return SupabaseAuth.new(CloudConfig.new(URL, KEY), transport, token_path, func() -> int: return now)


func _session(access: String, refresh: String, user_id: String = "user-1") -> Dictionary:
	return {"access_token": access, "refresh_token": refresh, "expires_in": 3600, "user": {"id": user_id}}


func _saved_tokens() -> Variant:
	return JSON.parse_string(FileAccess.get_file_as_string(token_path))


func test_first_session_signs_up_anonymously_and_keeps_the_refresh_token() -> void:
	transport.queue(200, _session("a1", "r1"))
	assert_true(await auth.ensure_session())
	assert_eq(transport.requests.size(), 1)
	assert_eq(transport.requests[0]["method"], HTTPClient.METHOD_POST)
	assert_eq(transport.requests[0]["url"], URL + "/auth/v1/signup")
	assert_eq(transport.last_json(), {})
	assert_has(transport.requests[0]["headers"], "apikey: " + KEY)
	assert_eq(auth.access_token, "a1")
	assert_eq(auth.user_id, "user-1")
	assert_eq(_saved_tokens(), {"refresh_token": "r1", "user_id": "user-1"})


func test_a_live_access_token_is_reused_without_requests() -> void:
	transport.queue(200, _session("a1", "r1"))
	await auth.ensure_session()
	now = T0 + 3000
	assert_true(await auth.ensure_session())
	assert_eq(transport.requests.size(), 1)


func test_an_expiring_access_token_is_refreshed() -> void:
	transport.queue(200, _session("a1", "r1"))
	await auth.ensure_session()
	now = T0 + 3560
	transport.queue(200, _session("a2", "r2"))
	assert_true(await auth.ensure_session())
	assert_eq(transport.requests[1]["url"], URL + "/auth/v1/token?grant_type=refresh_token")
	assert_eq(transport.last_json(), {"refresh_token": "r1"})
	assert_eq(auth.access_token, "a2")


func test_a_later_boot_refreshes_the_stored_token_instead_of_signing_up() -> void:
	transport.queue(200, _session("a1", "r1"))
	await auth.ensure_session()
	var next_boot: SupabaseAuth = _new_auth()
	transport.queue(200, _session("a2", "r2"))
	assert_true(await next_boot.ensure_session())
	assert_eq(transport.requests[1]["url"], URL + "/auth/v1/token?grant_type=refresh_token")
	assert_eq(transport.last_json(), {"refresh_token": "r1"})
	assert_eq(next_boot.access_token, "a2")
	assert_eq(next_boot.user_id, "user-1")
	assert_eq(_saved_tokens(), {"refresh_token": "r2", "user_id": "user-1"})


func test_a_rejected_refresh_token_signs_up_a_new_anonymous_player() -> void:
	transport.queue(200, _session("a1", "r1"))
	await auth.ensure_session()
	var next_boot: SupabaseAuth = _new_auth()
	transport.queue(400, {"error": "invalid_grant"})
	transport.queue(200, _session("a3", "r3", "user-2"))
	assert_true(await next_boot.ensure_session())
	assert_eq(transport.requests[2]["url"], URL + "/auth/v1/signup")
	assert_eq(next_boot.user_id, "user-2")
	assert_eq(_saved_tokens(), {"refresh_token": "r3", "user_id": "user-2"})


func test_an_unreachable_server_keeps_the_stored_player() -> void:
	transport.queue(200, _session("a1", "r1"))
	await auth.ensure_session()
	var next_boot: SupabaseAuth = _new_auth()
	assert_false(await next_boot.ensure_session())
	assert_eq(transport.requests.size(), 2, "no sign-up after a network failure")
	assert_eq(next_boot.access_token, "")
	assert_eq(_saved_tokens(), {"refresh_token": "r1", "user_id": "user-1"})


func test_a_server_error_on_refresh_keeps_the_stored_player() -> void:
	transport.queue(200, _session("a1", "r1"))
	await auth.ensure_session()
	var next_boot: SupabaseAuth = _new_auth()
	transport.queue(503, "unavailable")
	assert_false(await next_boot.ensure_session())
	assert_eq(transport.requests.size(), 2)
	assert_eq(_saved_tokens(), {"refresh_token": "r1", "user_id": "user-1"})


func test_a_failed_sign_up_writes_no_token_file() -> void:
	transport.queue(422, {"msg": "Anonymous sign-ins are disabled"})
	assert_false(await auth.ensure_session())
	assert_false(FileAccess.file_exists(token_path))
	assert_eq(auth.access_token, "")


func test_a_damaged_token_file_signs_up_again() -> void:
	var file: FileAccess = FileAccess.open(token_path, FileAccess.WRITE)
	file.store_string("not json")
	file.close()
	transport.queue(200, _session("a1", "r1"))
	assert_true(await _new_auth().ensure_session())
	assert_eq(transport.requests[0]["url"], URL + "/auth/v1/signup")


func test_invalidate_forces_a_refresh_on_the_next_call() -> void:
	transport.queue(200, _session("a1", "r1"))
	await auth.ensure_session()
	auth.invalidate()
	transport.queue(200, _session("a2", "r2"))
	assert_true(await auth.ensure_session())
	assert_eq(transport.requests[1]["url"], URL + "/auth/v1/token?grant_type=refresh_token")
	assert_eq(auth.access_token, "a2")


func test_auth_headers_carry_the_key_and_bearer_token() -> void:
	transport.queue(200, _session("a1", "r1"))
	await auth.ensure_session()
	assert_eq(
		auth.headers(),
		PackedStringArray(["apikey: " + KEY, "Content-Type: application/json", "Authorization: Bearer a1"])
	)
