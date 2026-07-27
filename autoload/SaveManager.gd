extends Node

## SaveManager — 存档管理
## 序列化/反序列化全部 GameState + PartyData + StoryFlags 到文件

const SAVE_DIR := "user://saves/"
const SAVE_EXTENSION := ".sav"
const MAX_SLOTS := 20

func _ready() -> void:
	ensure_save_dir()
	print("[SaveManager] Initialized. Save directory: ", SAVE_DIR)

func ensure_save_dir() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)

func save(slot: int) -> bool:
	if slot < 0 or slot >= MAX_SLOTS:
		print("[SaveManager] Invalid slot: ", slot)
		return false

	var data := {
		"timestamp": Time.get_datetime_string_from_system(),
		"game_state": GameState.serialize(),
		"party_data": PartyData.serialize(),
		"story_flags": StoryFlags.serialize(),
	}

	var file_path := get_slot_path(slot)
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		print("[SaveManager] Failed to open file for writing: ", file_path)
		return false

	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	print("[SaveManager] Saved to slot ", slot, " at ", data["timestamp"])
	return true

func load(slot: int) -> bool:
	var file_path := get_slot_path(slot)
	if not FileAccess.file_exists(file_path):
		print("[SaveManager] No save file in slot ", slot)
		return false

	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		print("[SaveManager] Failed to open file for reading: ", file_path)
		return false

	var json_string := file.get_as_text()
	file.close()

	var json := JSON.new()
	var error := json.parse(json_string)
	if error != OK:
		print("[SaveManager] JSON parse error: ", json.get_error_message())
		return false

	var data = json.data
	GameState.deserialize(data.get("game_state", {}))
	PartyData.deserialize(data.get("party_data", {}))
	StoryFlags.deserialize(data.get("story_flags", {}))
	print("[SaveManager] Loaded from slot ", slot)
	return true

func get_slot_info(slot: int) -> Dictionary:
	var file_path := get_slot_path(slot)
	if not FileAccess.file_exists(file_path):
		return {"empty": true}

	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return {"empty": true}

	var json_string := file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(json_string) != OK:
		return {"empty": true, "corrupt": true}

	var data = json.data
	return {
		"empty": false,
		"timestamp": data.get("timestamp", "Unknown"),
		"chapter": data.get("game_state", {}).get("current_chapter", 0),
		"day": data.get("game_state", {}).get("current_day", 1),
	}

func delete_slot(slot: int) -> void:
	var file_path := get_slot_path(slot)
	if FileAccess.file_exists(file_path):
		DirAccess.remove_absolute(file_path)
		print("[SaveManager] Deleted save slot ", slot)

func has_slot(slot: int) -> bool:
	return FileAccess.file_exists(get_slot_path(slot))

func get_slot_path(slot: int) -> String:
	return SAVE_DIR + "save_" + str(slot) + SAVE_EXTENSION
