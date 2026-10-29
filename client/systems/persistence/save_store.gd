class_name SaveStore
extends RefCounted
## Reads and writes the local save file. Writes go to a temp file first and are
## renamed over the save, so a crash mid-write never leaves a truncated save.

const DEFAULT_PATH: String = "user://save.json"
const TEMP_SUFFIX: String = ".tmp"
const REJECTED_SUFFIX: String = ".rejected.json"

var path: String


func _init(save_path: String = DEFAULT_PATH) -> void:
	path = save_path


func rejected_path() -> String:
	return path.get_basename() + REJECTED_SUFFIX


## A rejected save is moved to rejected_path() so the fresh game never overwrites it.
func load_save() -> SaveLoadResult:
	if not FileAccess.file_exists(path):
		return SaveLoadResult.new(SaveLoadResult.Status.NEW_GAME)
	var decoded: SaveDecodeResult = SaveCodec.decode(FileAccess.get_file_as_string(path))
	if decoded.is_ok():
		return SaveLoadResult.new(SaveLoadResult.Status.LOADED, decoded.data)
	var moved: Error = DirAccess.rename_absolute(path, rejected_path())
	if moved != OK:
		push_error("SaveStore: could not move rejected save to '%s' (%s)" % [rejected_path(), error_string(moved)])
	return SaveLoadResult.new(SaveLoadResult.Status.REJECTED, null, decoded.error)


func write(data: SaveData) -> Error:
	var temp_path: String = path + TEMP_SUFFIX
	var file: FileAccess = FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(SaveCodec.encode(data))
	file.close()
	var renamed: Error = DirAccess.rename_absolute(temp_path, path)
	if renamed != OK:
		DirAccess.remove_absolute(temp_path)
	return renamed
