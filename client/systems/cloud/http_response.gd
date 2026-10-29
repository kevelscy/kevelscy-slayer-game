class_name HttpResponse
extends RefCounted
## One HTTP answer. Status 0 means no answer at all (offline, DNS, timeout).

var status_code: int
var body: String


func _init(code: int, text: String) -> void:
	status_code = code
	body = text


func is_success() -> bool:
	return status_code >= 200 and status_code < 300


func is_unreachable() -> bool:
	return status_code == 0


## The client's request was refused (4xx), as opposed to a server or network failure.
func is_rejected() -> bool:
	return status_code >= 400 and status_code < 500


## Parsed JSON body, or null when the body is empty or not JSON.
func json() -> Variant:
	var parser: JSON = JSON.new()
	return parser.data if parser.parse(body) == OK else null


## Human-readable server message for error reports.
func message() -> String:
	var parsed: Variant = json()
	if parsed is Dictionary:
		for key: String in ["message", "msg", "error_description", "error"]:
			if (parsed as Dictionary).get(key) is String:
				return (parsed as Dictionary)[key]
	return body.strip_edges()
