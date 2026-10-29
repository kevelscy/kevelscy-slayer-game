class_name CloudConfig
extends RefCounted
## Where the Supabase project lives. The API key is the public (publishable) key.

var url: String
var api_key: String


func _init(project_url: String, key: String) -> void:
	url = project_url.trim_suffix("/")
	api_key = key
