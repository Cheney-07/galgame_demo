extends Node

## GameState — 全局游戏状态
## 管理章节、天数、时间段、AP等顶层状态

# 当前状态
var current_chapter: int = 0          # 0=序章
var current_day: int = 1
var current_ap: int = 11              # 每日行动点数
var max_ap: int = 11
var time_period: String = "morning"   # morning / afternoon / evening / night
var game_phase: String = "vn"         # vn / schedule / battle

# 日程系统
var daily_talks: Dictionary = {}        # char_id → int，每角色每日交谈次数
var total_social_counts: Dictionary = {} # char_id → int，累计交流次数（跨天）
var training_per_session: int = 1       # 每次训练属性增长量
var social_affection_gain: int = 1      # 每次交流好感度增长量
var formation_squad: Array[String] = []  # 编队角色ID列表
var battle_type: String = "battle"       # 战斗类型: battle/explore/quest/special
var pending_scene: String = ""           # 战斗/交流结束后返回的场景ID（空=回日程）
var pending_load_slot: String = ""       # 主菜单读档时缓存槽位名

# 一周目/二周目
var is_new_game_plus: bool = false
var death_count: int = 0              # 死亡次数
var revival_count: int = 0            # 复活次数（每场战斗可复活，但累计次数影响结局）

# 角色解锁系统
var recruited_characters: Array[String] = ["protagonist", "hajiyou"]  # 初始只有主角和哈基佑
# 解锁条件：5天=陈立, 10天=老马, 15天=牢翔, 20天(打boss赢)=牢聪

# 特殊战斗跟踪
var special_battles_won: Array[int] = []  # 已完成特殊战斗的天数列表
var current_special_day: int = 0          # 当前特殊战斗天数（0=不是特殊战斗日）
var last_battle_won: bool = true          # 上一场战斗是否胜利
var special_prebattle_done: bool = false  # 特殊战斗的战前剧情是否已播放过

# 每5天特殊战斗标记
func is_special_battle_day() -> bool:
	return current_day % 5 == 0 and current_day >= 5

func get_special_battle_stage() -> int:
	# 返回特殊战斗阶段: 1=Day5, 2=Day10, 3=Day15, 4=Day20(boss), 5=Day25(final)
	if current_day < 5: return 0
	return current_day / 5

# 信号
signal chapter_changed(chapter: int)
signal day_advanced(day: int)
signal ap_changed(current: int, max: int)
signal time_period_changed(period: String)
signal game_phase_changed(phase: String)
signal daily_talks_changed()
signal character_recruited(char_id: String)  # 新角色加入

func _ready() -> void:
	_init_recruitment()
	print("[GameState] Initialized.")

func _init_recruitment() -> void:
	# 初始角色
	if not recruited_characters.has("protagonist"):
		recruited_characters.append("protagonist")
	if not recruited_characters.has("hajiyou"):
		recruited_characters.append("hajiyou")


func reset() -> void:
	current_chapter = 0
	current_day = 1
	current_ap = 11
	max_ap = 11
	time_period = "morning"
	game_phase = "vn"
	daily_talks.clear()
	total_social_counts.clear()
	training_per_session = 1
	social_affection_gain = 1
	formation_squad.clear()
	battle_type = "battle"
	pending_scene = ""
	pending_load_slot = ""
	is_new_game_plus = false
	death_count = 0
	revival_count = 0
	recruited_characters = ["protagonist", "hajiyou"]
	special_battles_won.clear()
	current_special_day = 0
	last_battle_won = true
	print("[GameState] Reset to defaults.")

func advance_day() -> void:
	current_day += 1
	current_ap = max_ap
	time_period = "morning"
	daily_talks.clear()
	day_advanced.emit(current_day)
	daily_talks_changed.emit()
	print("[GameState] Day advanced to ", current_day)

func set_chapter(chapter: int) -> void:
	current_chapter = chapter
	chapter_changed.emit(chapter)
	print("[GameState] Chapter set to ", chapter)

func spend_ap(amount: int) -> bool:
	if current_ap >= amount:
		current_ap -= amount
		ap_changed.emit(current_ap, max_ap)
		return true
	return false

func set_time_period(period: String) -> void:
	time_period = period
	time_period_changed.emit(period)

func set_game_phase(phase: String) -> void:
	game_phase = phase
	game_phase_changed.emit(phase)

func record_death() -> void:
	death_count += 1
	print("[GameState] Death recorded. Total deaths: ", death_count)

func record_revival() -> void:
	revival_count += 1
	print("[GameState] Revival counted. Total revivals: ", revival_count)

func has_ever_revived() -> bool:
	return revival_count > 0

func has_zero_deaths() -> bool:
	return death_count == 0

# 角色解锁
func recruit_character(char_id: String) -> void:
	if not recruited_characters.has(char_id):
		recruited_characters.append(char_id)
		character_recruited.emit(char_id)
		# 同步到主菜单角色立绘
		StoryFlags.mark_character_met(char_id)
		print("[GameState] Character recruited: ", char_id)

func is_character_recruited(char_id: String) -> bool:
	return recruited_characters.has(char_id)

func get_recruited_characters() -> Array[String]:
	# 确保至少返回已初始化的角色
	if recruited_characters.is_empty():
		_init_recruitment()
	var chars: Array[String] = []
	for c in recruited_characters:
		chars.append(c)
	if chars.is_empty():
		chars = ["protagonist", "hajiyou"]
	return chars

func get_available_formation_characters() -> Array[String]:
	# 返回可以编队的角色（已解锁的，不包括主角）
	var chars: Array[String] = []
	for c in recruited_characters:
		if c != "protagonist":
			chars.append(c)
	return chars

# 特殊战斗标记
func mark_special_battle_won() -> void:
	if not special_battles_won.has(current_day):
		special_battles_won.append(current_day)

func is_day_special_battle_won(day: int) -> bool:
	return special_battles_won.has(day)

# 每日交谈次数管理（每人每天最多1次，主角不可交流）

func can_talk(char_id: String) -> bool:
	if char_id == "protagonist":
		return false
	return daily_talks.get(char_id, 0) < 1

func record_talk(char_id: String) -> void:
	daily_talks[char_id] = daily_talks.get(char_id, 0) + 1
	total_social_counts[char_id] = total_social_counts.get(char_id, 0) + 1
	daily_talks_changed.emit()
	print("[GameState] Talk recorded for ", char_id, ": daily=", daily_talks[char_id], " total=", total_social_counts[char_id])

func get_talk_count(char_id: String) -> int:
	return daily_talks.get(char_id, 0)

func get_total_social_count(char_id: String) -> int:
	return total_social_counts.get(char_id, 0)



func return_to_main_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")

func can_anyone_talk() -> bool:
	for char_id in recruited_characters:
		if can_talk(char_id):
			return true
	return false

# 序列化
func serialize() -> Dictionary:
	return {
		"current_chapter": current_chapter,
		"current_day": current_day,
		"current_ap": current_ap,
		"max_ap": max_ap,
		"time_period": time_period,
		"game_phase": game_phase,
		"is_new_game_plus": is_new_game_plus,
		"death_count": death_count,
		"revival_count": revival_count,
		"daily_talks": daily_talks,
		"total_social_counts": total_social_counts,
		"recruited_characters": recruited_characters,
		"special_battles_won": special_battles_won,
	}

func deserialize(data: Dictionary) -> void:
	current_chapter = data.get("current_chapter", 0)
	current_day = data.get("current_day", 1)
	current_ap = data.get("current_ap", 11)
	max_ap = data.get("max_ap", 11)
	time_period = data.get("time_period", "morning")
	game_phase = data.get("game_phase", "vn")
	is_new_game_plus = data.get("is_new_game_plus", false)
	death_count = data.get("death_count", 0)
	revival_count = data.get("revival_count", 0)
	daily_talks = data.get("daily_talks", {})
	total_social_counts = data.get("total_social_counts", {})
	var raw_chars = data.get("recruited_characters", ["protagonist", "hajiyou"])
	recruited_characters.clear()
	for c in raw_chars:
		recruited_characters.append(str(c))
	var raw_battles = data.get("special_battles_won", [])
	special_battles_won.clear()
	for d in raw_battles:
		special_battles_won.append(int(d))
