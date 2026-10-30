class_name SettingsStore
extends RefCounted
## Local player settings in a ConfigFile next to the save. They belong to the device,
## never to the cloud save. A missing or unreadable file keeps the defaults.

const SECTION_AUDIO: String = "audio"
const KEY_SFX_MUTED: String = "sfx_muted"

var path: String
var sfx_muted: bool = false


func _init(settings_path: String) -> void:
	path = settings_path


func load_settings() -> void:
	sfx_muted = false
	if not FileAccess.file_exists(path):
		return
	var config: ConfigFile = ConfigFile.new()
	if config.load(path) != OK:
		push_warning("SettingsStore: could not read '%s'; using the defaults" % path)
		return
	var muted: Variant = config.get_value(SECTION_AUDIO, KEY_SFX_MUTED, false)
	sfx_muted = muted is bool and muted


func save_settings() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value(SECTION_AUDIO, KEY_SFX_MUTED, sfx_muted)
	var error: Error = config.save(path)
	if error != OK:
		push_error("SettingsStore: could not write '%s' (%s)" % [path, error_string(error)])
