class_name FakeHttpTransport
extends HttpTransport
## Replays queued responses in order and records every request it receives.
## An empty queue answers like an unreachable server (status 0). hold() keeps
## requests in flight until release().

signal _released

var requests: Array[Dictionary] = []
var _responses: Array[HttpResponse] = []
var _holding: bool = false


func queue(status_code: int, body: Variant = null) -> void:
	var text: String = "" if body == null else (body if body is String else JSON.stringify(body))
	_responses.append(HttpResponse.new(status_code, text))


func send(method: HTTPClient.Method, url: String, headers: PackedStringArray, body: String) -> HttpResponse:
	requests.append({"method": method, "url": url, "headers": headers, "body": body})
	if _holding:
		await _released
	if _responses.is_empty():
		return HttpResponse.new(0, "")
	return _responses.pop_front()


func hold() -> void:
	_holding = true


func release() -> void:
	_holding = false
	_released.emit()


func last_json() -> Variant:
	return JSON.parse_string(requests[-1]["body"])
