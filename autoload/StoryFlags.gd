extends Node

## StoryFlags — 剧情标记管理
## 管理好感度、结局条件flag、选项历史、CG解锁等

# 布尔型标记（用于触发条件判断）
var flags: Dictionary = {}

# 好感度（PartyData 也有好感度，这里存剧情相关的额外好感记录）
var affection: Dictionary = {}     # char_id → int

# 选项历史（记录玩家关键选择）
var choice_history: Array = []

# 已解锁结局
var unlocked_endings: Array = []

# CG画廊
var unlocked_cgs: Array = []      # CG文件名列表，如 ["hajiyou_cg1", "laoma_cg2"]

# 主菜单角色立绘
var met_characters: Array[String] = []

# 战斗相关
var total_battles: int = 0
var total_victories: int = 0
var resurrection_used: bool = false    # 是否使用过复活

signal flag_set(flag_name: String)
signal flag_cleared(flag_name: String)
signal choice_made(choice_id: String)
signal cg_unlocked(cg_id: String)

func _ready() -> void:
	load_global_progress()
	cg_unlocked.connect(_on_cg_unlocked)
	print("[StoryFlags] Initialized.")

func clear_all() -> void:
	flags.clear()
	affection.clear()
	choice_history.clear()
	unlocked_endings.clear()
	unlocked_cgs.clear()
	total_battles = 0
	total_victories = 0
	resurrection_used = false
	print("[StoryFlags] Cleared all state.")

func set_flag(flag_name: String) -> void:
	flags[flag_name] = true
	flag_set.emit(flag_name)
	print("[StoryFlags] Flag set: ", flag_name)

func clear_flag(flag_name: String) -> void:
	flags.erase(flag_name)
	flag_cleared.emit(flag_name)

func has_flag(flag_name: String) -> bool:
	return flags.get(flag_name, false)

func record_choice(choice_id: String) -> void:
	choice_history.append(choice_id)
	choice_made.emit(choice_id)

func unlock_ending(ending_id: String) -> void:
	if ending_id not in unlocked_endings:
		unlocked_endings.append(ending_id)
		print("[StoryFlags] Ending unlocked: ", ending_id)

func has_ending(ending_id: String) -> bool:
	return ending_id in unlocked_endings

# CG画廊
func unlock_cg(cg_id: String) -> void:
	if cg_id not in unlocked_cgs:
		unlocked_cgs.append(cg_id)
		cg_unlocked.emit(cg_id)
		print("[StoryFlags] CG unlocked: ", cg_id)

func is_cg_unlocked(cg_id: String) -> bool:
	return cg_id in unlocked_cgs


func mark_character_met(char_id: String) -> void:
	if char_id not in met_characters:
		met_characters.append(char_id)
		save_global_progress()
		print("[StoryFlags] Character met: ", char_id)


func is_character_met(char_id: String) -> bool:
	return char_id in met_characters


# 全局进度持久化（CG/结局独立于存档槽，跨周目保留）
const GLOBAL_PROGRESS_PATH := "user://global_progress.cfg"

func save_global_progress() -> void:
	var data := {
		"unlocked_cgs": unlocked_cgs,
		"unlocked_endings": unlocked_endings,
		"met_characters": met_characters,
	}
	var file := FileAccess.open(GLOBAL_PROGRESS_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()

func load_global_progress() -> bool:
	if not FileAccess.file_exists(GLOBAL_PROGRESS_PATH):
		return false
	var file := FileAccess.open(GLOBAL_PROGRESS_PATH, FileAccess.READ)
	if file == null:
		return false
	var json_string := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(json_string) != OK:
		return false
	var data = json.data
	if data.has("unlocked_cgs"):
		for cg in data["unlocked_cgs"]:
			if cg not in unlocked_cgs:
				unlocked_cgs.append(cg)
	if data.has("unlocked_endings"):
		for e in data["unlocked_endings"]:
			if e not in unlocked_endings:
				unlocked_endings.append(e)
	if data.has("met_characters"):
		for ch in data["met_characters"]:
			if ch not in met_characters:
				met_characters.append(ch)
	return true

func _on_cg_unlocked(_cg_id: String) -> void:
	save_global_progress()


# 序列化
func serialize() -> Dictionary:
	return {
		"flags": flags,
		"affection": affection,
		"choice_history": choice_history,
		"unlocked_endings": unlocked_endings,
		"unlocked_cgs": unlocked_cgs,
		"total_battles": total_battles,
		"total_victories": total_victories,
		"resurrection_used": resurrection_used,
	}

func deserialize(data: Dictionary) -> void:
	flags = data.get("flags", {})
	affection = data.get("affection", {})
	choice_history = data.get("choice_history", [])
	unlocked_endings = data.get("unlocked_endings", [])
	unlocked_cgs = data.get("unlocked_cgs", [])
	total_battles = data.get("total_battles", 0)
	total_victories = data.get("total_victories", 0)
	resurrection_used = data.get("resurrection_used", false)
	print("[StoryFlags] State deserialized.")
