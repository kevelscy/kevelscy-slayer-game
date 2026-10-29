class_name GodotHttpTransport
extends HttpTransport
## HttpTransport over HTTPRequest nodes, one per request, parented to `host`.

const TIMEOUT_SECONDS: float = 10.0

var _host: Node


func _init(host: Node) -> void:
	_host = host


func send(method: HTTPClient.Method, url: String, headers: PackedStringArray, body: String) -> HttpResponse:
	var request: HTTPRequest = HTTPRequest.new()
	request.timeout = TIMEOUT_SECONDS
	_host.add_child(request)
	if request.request(url, headers, method, body) != OK:
		request.queue_free()
		return HttpResponse.new(0, "")
	var completed: Array = await request.request_completed
	request.queue_free()
	if completed[0] != HTTPRequest.RESULT_SUCCESS:
		return HttpResponse.new(0, "")
	return HttpResponse.new(completed[1] as int, (completed[3] as PackedByteArray).get_string_from_utf8())
