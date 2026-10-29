class_name HttpTransport
extends RefCounted
## Sends one HTTP request and returns its answer. Callers always `await send()`,
## so implementations may answer immediately (tests) or after a network round trip.


func send(_method: HTTPClient.Method, _url: String, _headers: PackedStringArray, _body: String) -> HttpResponse:
	return HttpResponse.new(0, "")
