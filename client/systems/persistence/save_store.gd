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
## A temp file left behind means a write was interrupted before its rename; the
## save itself is still the last complete one, so the partial copy is discarded.
func load_save() -> SaveLoadResult:
	if FileAccess.file_exists(_temp_path()):
		DirAccess.remove_absolute(_temp_path())
	if not FileAccess.file_exists(path):
		return SaveLoadResult.new(SaveLoadResult.Status.NEW_GAME)
	var decoded: SaveDecodeResult = SaveCodec.decode(FileAccess.get_file_as_string(path))
	if decoded.is_ok():
		return SaveLoadResult.new(SaveLoadResult.Status.LOADED, decoded.data)
	var moved: Error = DirAccess.rename_absolute(path, rejected_path())
	if moved != OK:
		push_error("SaveStore: could not move rejected save to '%s' (%s)" % [rejected_path(), error_string(moved)])
	return SaveLoadResult.new(SaveLoadResult.Status.REJECTED, null, decoded.error)


## A failed write (full disk, I/O error) never replaces the existing save.
func write(data: SaveData) -> Error:
	var temp_path: String = _temp_path()
	var file: FileAccess = FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	var stored: bool = file.store_string(SaveCodec.encode(data))
	var write_error: Error = file.get_error()
	file.close()
	if not stored or write_error != OK:
		DirAccess.remove_absolute(temp_path)
		return write_error if write_error != OK else ERR_FILE_CANT_WRITE
	var renamed: Error = DirAccess.rename_absolute(temp_path, path)
	if renamed != OK:
		DirAccess.remove_absolute(temp_path)
	return renamed


func _temp_path() -> String:
	return path + TEMP_SUFFIX
