class_name FakeHttpTransport
extends HttpTransport
## Replays queued responses in order and records every request it receives.
## An empty queue answers like an unreachable server (status 0).

var requests: Array[Dictionary] = []
var _responses: Array[HttpResponse] = []


func queue(status_code: int, body: Variant = null) -> void:
	var text: String = "" if body == null else (body if body is String else JSON.stringify(body))
	_responses.append(HttpResponse.new(status_code, text))


func send(method: HTTPClient.Method, url: String, headers: PackedStringArray, body: String) -> HttpResponse:
	requests.append({"method": method, "url": url, "headers": headers, "body": body})
	if _responses.is_empty():
		return HttpResponse.new(0, "")
	return _responses.pop_front()


func last_json() -> Variant:
	return JSON.parse_string(requests[-1]["body"])
