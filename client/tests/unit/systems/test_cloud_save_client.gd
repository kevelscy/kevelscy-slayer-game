extends GutTest

const URL: String = "http://cloud.test"
const KEY: String = "sb_publishable_test"
const T0: int = 1_700_000_000

var dir_path: String
var transport: FakeHttpTransport
var auth: SupabaseAuth
var client: CloudSaveClient


func before_each() -> void:
	dir_path = "user://test_cloud_client/%d" % randi()
	DirAccess.make_dir_recursive_absolute(dir_path)
	transport = FakeHttpTransport.new()
	auth = SupabaseAuth.new(
		CloudConfig.new(URL, KEY), transport, dir_path.path_join("auth.json"), func() -> int: return T0
	)
	client = CloudSaveClient.new(CloudConfig.new(URL, KEY), transport, auth)


func after_each() -> void:
	for file_name: String in DirAccess.get_files_at(dir_path):
		DirAccess.remove_absolute(dir_path.path_join(file_name))
	DirAccess.remove_absolute(dir_path)


func _signed_in() -> void:
	transport.queue(200, {"access_token": "a1", "refresh_token": "r1", "expires_in": 3600, "user": {"id": "u1"}})
	await auth.ensure_session()


func _save(stage: int, last_seen: int) -> SaveData:
	var data: SaveData = SaveData.new()
	data.stage = stage
	data.gold = BigNumber.from_float(1500.0)
	data.attack_level = 7
	data.talents = {"might": 2}
	data.last_seen_unix = last_seen
	return data


func _save_json(stage: int, last_seen: int) -> Variant:
	return JSON.parse_string(SaveCodec.encode(_save(stage, last_seen)))


func test_pull_returns_the_cloud_save_with_server_times() -> void:
	await _signed_in()
	transport.queue(200, {"save": _save_json(12, T0 - 600), "last_seen_unix": T0 - 600, "server_now_unix": T0})
	var result: CloudPullResult = await client.pull()
	assert_true(result.ok, result.error)
	assert_eq(result.data.stage, 12)
	assert_eq(result.data.attack_level, 7)
	assert_eq(result.data.talents, {"might": 2})
	assert_eq(result.last_seen_unix, T0 - 600)
	assert_eq(result.server_now_unix, T0)
	var request: Dictionary = transport.requests[-1]
	assert_eq(request["method"], HTTPClient.METHOD_POST)
	assert_eq(request["url"], URL + "/rest/v1/rpc/pull_save")
	assert_eq(request["body"], "{}")
	assert_has(request["headers"], "Authorization: Bearer a1")


func test_pull_without_a_cloud_save_reports_none() -> void:
	await _signed_in()
	transport.queue(200, {"save": null, "last_seen_unix": null, "server_now_unix": T0})
	var result: CloudPullResult = await client.pull()
	assert_true(result.ok)
	assert_null(result.data)
	assert_eq(result.last_seen_unix, -1)
	assert_eq(result.server_now_unix, T0)


func test_pull_rejects_a_save_the_codec_rejects() -> void:
	await _signed_in()
	var bad: Dictionary = _save_json(12, T0)
	bad["stage"] = 0
	transport.queue(200, {"save": bad, "last_seen_unix": T0, "server_now_unix": T0})
	var result: CloudPullResult = await client.pull()
	assert_false(result.ok)
	assert_null(result.data)
	assert_eq(result.error, "save field 'stage' must be >= 1, got 0")


func test_pull_rejects_a_malformed_response() -> void:
	await _signed_in()
	transport.queue(200, "[]")
	var result: CloudPullResult = await client.pull()
	assert_false(result.ok)
	assert_eq(result.error, "cloud response is not a JSON object")


func test_push_sends_the_encoded_save_and_returns_the_server_time() -> void:
	await _signed_in()
	transport.queue(200, {"server_now_unix": T0 + 5})
	var result: CloudPushResult = await client.push(_save(9, 123))
	assert_true(result.ok, result.error)
	assert_eq(result.server_now_unix, T0 + 5)
	var request: Dictionary = transport.requests[-1]
	assert_eq(request["url"], URL + "/rest/v1/rpc/push_save")
	assert_eq(transport.last_json(), {"save": _save_json(9, 123)})


func test_push_reports_the_server_rejection_message() -> void:
	await _signed_in()
	transport.queue(400, {"code": "22023", "message": "unsupported save version 2"})
	var result: CloudPushResult = await client.push(_save(9, 123))
	assert_false(result.ok)
	assert_eq(result.error, "cloud rejected the request (400): unsupported save version 2")


func test_an_expired_token_is_refreshed_once_and_the_call_retried() -> void:
	await _signed_in()
	transport.queue(401, {"code": "PGRST303", "message": "JWT expired"})
	transport.queue(200, {"access_token": "a2", "refresh_token": "r2", "expires_in": 3600, "user": {"id": "u1"}})
	transport.queue(200, {"server_now_unix": T0})
	var result: CloudPushResult = await client.push(_save(9, 123))
	assert_true(result.ok, result.error)
	assert_eq(transport.requests.size(), 4)
	assert_eq(transport.requests[2]["url"], URL + "/auth/v1/token?grant_type=refresh_token")
	assert_has(transport.requests[3]["headers"], "Authorization: Bearer a2")


func test_a_second_unauthorized_answer_is_not_retried_again() -> void:
	await _signed_in()
	transport.queue(401, {"message": "JWT expired"})
	transport.queue(200, {"access_token": "a2", "refresh_token": "r2", "expires_in": 3600, "user": {"id": "u1"}})
	transport.queue(401, {"message": "JWT expired"})
	var result: CloudPullResult = await client.pull()
	assert_false(result.ok)
	assert_eq(transport.requests.size(), 4)
	assert_eq(result.error, "cloud rejected the request (401): JWT expired")


func test_no_rpc_is_sent_when_sign_in_fails() -> void:
	var result: CloudPullResult = await client.pull()
	assert_false(result.ok)
	assert_eq(result.error, "cloud sign-in unavailable")
	assert_eq(transport.requests.size(), 1, "only the failed sign-up")


func test_an_unreachable_server_is_reported() -> void:
	await _signed_in()
	var result: CloudPushResult = await client.push(_save(9, 123))
	assert_false(result.ok)
	assert_eq(result.error, "cloud unreachable")
