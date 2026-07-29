extends Node

## DialogicBridge — Dialogic 与游戏状态桥接器
## 负责：
## 1. 同步游戏状态到 Dialogic 变量（用于选择支条件检定）
## 2. 补全角色别名（保留 .dch 文件的完整配置）
## 3. 提供存档/读档/自动推进/自动跳过快捷键

signal before_timeline_start(timeline_path: String, label: String)
signal after_timeline_ended(timeline_path: String)

# 角色变量名映射：char_id → Dialogic 文件夹名（中文）
const CHAR_VAR_NAMES := {
	"protagonist": "主角",
	"laocong": "牢聪",
	"chenli": "陈立",
	"hajilong": "哈基龙",
	"hajiyou": "哈基佑",
	"laoma": "老马",
	"laoxiang": "牢翔",
}


 # Dialogic character display_name → char_id（反向查找）
var _char_id_by_display_name := {}

func _ready() -> void:
	await get_tree().process_frame
	_register_characters()
	_setup_input_handling()
	# 等待 Dialogic 子系统完全就绪后再连接信号
	await get_tree().process_frame
	_connect_signals()
	print("[DialogicBridge] Initialized.")


#region 角色注册

# 只补别名，不覆盖 .dch 文件中的角色配置（color / portrait 等）
func _register_characters() -> void:
	if not Dialogic.has_subsystem("VAR"):
		return

	var existing: Dictionary = DialogicResourceUtil.get_directory("dch")
	var count := 0

	for cid in PartyData.get_all_character_ids():
		var data = PartyData.get_character(cid)
		if not data:
			continue

		# .dch 目录已有此 ID → 只补别名映射
		if existing.has(cid):
			if not existing.has(data.char_name):
				existing[data.char_name] = existing[cid]
			count += 1
			continue

		# 主角别名: protagonist → zhujue（.dch 文件用的是 zhujue）
		if cid == "protagonist" and existing.has("zhujue"):
			var zhujue_entry = existing["zhujue"]
			existing["protagonist"] = zhujue_entry
			if not existing.has(data.char_name):
				existing[data.char_name] = zhujue_entry
			count += 1
			continue

		# 真正没有 .dch 的角色才动态创建
		var dch: DialogicCharacter = DialogicCharacter.new()
		dch.resource_name = cid
		dch.display_name = data.char_name
		if data.portrait_path and not data.portrait_path.is_empty():
			dch.add_portrait("default", data.portrait_path)
			dch.default_portrait = "default"
		existing[cid] = dch
		existing[data.char_name] = dch
		count += 1

	DialogicResourceUtil.set_directory("dch", existing)
	print("[DialogicBridge] Registered ", count, " character aliases")

#endregion


#region 公共方法

func start_timeline(timeline_path: String, label: String = "") -> void:
	# 先停止已有时间线，防止快进时多个时间线重叠执行
	stop_timeline()
	before_timeline_start.emit(timeline_path, label)
	_sync_game_variables()
	print("[DialogicBridge] Starting timeline: ", timeline_path, " @ ", label)
	Dialogic.start(timeline_path, label)


func is_playing() -> bool:
	return Dialogic.current_timeline != null and Dialogic.current_state != Dialogic.States.IDLE


func stop_timeline() -> void:
	if Dialogic.current_timeline:
		Dialogic.end_timeline(true)


#endregion


#region 变量同步

# 连接游戏中信号 → 实时更新 Dialogic 变量
func _connect_signals() -> void:
	if not Dialogic.has_subsystem("VAR"):
		return

	# 主角属性变化
	PartyData.stat_changed.connect(_on_stat_changed)

	# 好感度变化
	PartyData.affection_changed.connect(_on_affection_changed)

	# 游戏状态变化
	GameState.ap_changed.connect(_on_ap_changed)
	GameState.day_advanced.connect(_on_day_advanced)
	GameState.time_period_changed.connect(_on_time_changed)
	GameState.game_phase_changed.connect(_on_phase_changed)
	GameState.daily_talks_changed.connect(_on_daily_talks_changed)

	# CG 解锁 — 监听背景变化
	if Dialogic.has_subsystem("Backgrounds"):
		Dialogic.Backgrounds.background_changed.connect(_on_background_changed)

	print("[DialogicBridge] Signals connected for reactive sync.")


func _on_stat_changed(char_id: String, stat: String, value: int) -> void:
	if not Dialogic.has_subsystem("VAR"):
		return
	if char_id == "protagonist":
		_set_var(Dialogic.VAR, "Player." + stat, value)


func _on_affection_changed(char_id: String, value: int) -> void:
	if not Dialogic.has_subsystem("VAR"):
		return
	var folder: String = CHAR_VAR_NAMES.get(char_id, "")
	if folder:
		_set_var(Dialogic.VAR, folder + ".affection", value)


func _on_ap_changed(current: int, _max: int) -> void:
	if not Dialogic.has_subsystem("VAR"):
		return
	_set_var(Dialogic.VAR, "Game.ap", current)


func _on_day_advanced(day: int) -> void:
	if not Dialogic.has_subsystem("VAR"):
		return
	_set_var(Dialogic.VAR, "Game.day", day)


func _on_time_changed(period: String) -> void:
	if not Dialogic.has_subsystem("VAR"):
		return
	_set_var(Dialogic.VAR, "Game.time", period)


func _on_phase_changed(phase: String) -> void:
	if not Dialogic.has_subsystem("VAR"):
		return
	_set_var(Dialogic.VAR, "Game.phase", phase)


func _on_daily_talks_changed() -> void:
	if not Dialogic.has_subsystem("VAR"):
		return
	var V: Node = Dialogic.VAR
	for cid in PartyData.get_all_character_ids():
		var folder: String = CHAR_VAR_NAMES.get(cid, "")
		if folder.is_empty():
			continue
		_set_var(V, folder + ".talk_today", GameState.get_talk_count(cid))
		_set_var(V, folder + ".talk_slots", 3 - GameState.get_talk_count(cid))


# 当 Dialogic 切换背景图时，自动解锁 cg/ 目录下的 CG
func _on_background_changed(info: Dictionary) -> void:
	var arg: String = info.get("argument", "")
	if arg.begins_with("res://images/cg/"):
		var cg_id := arg.get_file().get_basename()
		StoryFlags.unlock_cg(cg_id)


# 每次时间线开始时将游戏状态同步到 Dialogic 变量
# 这些变量定义在 Dialogic 编辑器 > Variables 标签中
func _sync_game_variables() -> void:
	if not Dialogic.has_subsystem("VAR"):
		return

	var V: Node= Dialogic.VAR

	# ── Game ──
	_set_var(V, "Game.day", GameState.current_day)
	_set_var(V, "Game.chapter", GameState.current_chapter)
	_set_var(V, "Game.ap", GameState.current_ap)
	_set_var(V, "Game.max_ap", GameState.max_ap)
	_set_var(V, "Game.time", GameState.time_period)
	_set_var(V, "Game.phase", GameState.game_phase)
	_set_var(V, "Game.deaths", GameState.death_count)
	_set_var(V, "Game.battles", StoryFlags.total_battles)
	_set_var(V, "Game.victories", StoryFlags.total_victories)
	_set_var(V, "Game.resurrected", StoryFlags.resurrection_used)
	_set_var(V, "Game.talk_slots", 3)

	# ── Player 属性 ──
	var p := PartyData.get_character("protagonist")
	if p:
		_set_var(V, "Player.STR", p.get_stat("STR"))
		_set_var(V, "Player.MAG", p.get_stat("MAG"))
		_set_var(V, "Player.VIT", p.get_stat("VIT"))
		_set_var(V, "Player.AGI", p.get_stat("AGI"))
		_set_var(V, "Player.TEC", p.get_stat("TEC"))
		_set_var(V, "Player.CHA", p.get_stat("CHA"))

	# ── 各角色好感度 & 交谈次数 ──
	for cid in PartyData.get_all_character_ids():
		var folder: String = CHAR_VAR_NAMES.get(cid, "")
		if folder.is_empty():
			continue
		var data = PartyData.get_character(cid)
		if data:
			_set_var(V, folder + ".affection", int(data.affection))
		_set_var(V, folder + ".talk_today", GameState.get_talk_count(cid))
		_set_var(V, folder + ".talk_slots", 3 - GameState.get_talk_count(cid))


## 安全设置变量：只在变量已定义时写入
func _set_var(V: Node, path: String, value: Variant) -> void:
	if V.has(path):
		V.set(path, value)


#endregion


#region 输入处理（存档/读档/自动推进/自动跳过）

func _setup_input_handling() -> void:
	set_process(true)
	set_process_input(true)


func _input(event: InputEvent) -> void:
	if Dialogic.current_timeline == null:
		return

	if event.is_action_pressed("dialogic_save", false, true):
		_save_game()
		get_viewport().set_input_as_handled()

	elif event.is_action_pressed("dialogic_load", false, true):
		_load_game()
		get_viewport().set_input_as_handled()

	elif event.is_action_pressed("dialogic_auto", false, true):
		_toggle_auto_advance()
		get_viewport().set_input_as_handled()

	elif event.is_action_pressed("dialogic_skip", false, true):
		_toggle_auto_skip()
		get_viewport().set_input_as_handled()


func _toggle_auto_advance() -> void:
	if not Dialogic.has_subsystem("Inputs"):
		return
	var aa = Dialogic.Inputs.auto_advance
	aa.enabled_until_user_input = !aa.enabled_until_user_input


func _toggle_auto_skip() -> void:
	if not Dialogic.has_subsystem("Inputs"):
		return
	var as_ = Dialogic.Inputs.auto_skip
	as_.enabled = !as_.enabled
	if as_.enabled:
		as_.disable_on_unread_text = false



func _save_game() -> void:
	if not Dialogic.has_subsystem("Save"):
		return
	Dialogic.Save.save("quick_save", false, Dialogic.Save.ThumbnailMode.NONE)


func _load_game() -> void:
	if not Dialogic.has_subsystem("Save"):
		return
	if not Dialogic.Save.has_slot("quick_save"):
		return
	Dialogic.Save.load("quick_save")

#endregion
