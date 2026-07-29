extends CanvasLayer

var _cn_font: Font = preload("res://fonts/NotoSansSC-Regular.otf")

## MainScene — 场景管理器
## 根据 GameState.game_phase 管理 VN / Schedule / Battle 场景切换

var schedule_scene: CanvasLayer = null
var battle_scene: CanvasLayer = null
var transition_overlay: ColorRect = null
var _transition_lock := false

func _ready() -> void:
	print("[MainScene] Starting scene manager...")

	# 连接阶段切换信号
	GameState.game_phase_changed.connect(_on_game_phase_changed)

	# 创建过渡遮罩
	transition_overlay = ColorRect.new()
	transition_overlay.name = "TransitionOverlay"
	transition_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	transition_overlay.color = Color(0, 0, 0, 0)
	transition_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	transition_overlay.visible = false
	add_child(transition_overlay)

	# 检查是否有从主菜单发起的读档请求
	var load_slot: String = GameState.pending_load_slot
	if not load_slot.is_empty():
		GameState.pending_load_slot = ""
		_handle_load_from_menu(load_slot)
		# 不 return — 继续执行 _switch_to_phase

	# 根据当前 phase 进入对应场景
	_switch_to_phase(GameState.game_phase)

	# 如果 Dialogic 已有活动时间线（Dialogic.Save.load() 已恢复），不重复启动序章
	if Dialogic.current_timeline != null:
		print("[MainScene] Dialogic timeline already active, skipping prologue start.")
		return

	# 首次启动时，如果 phase 是 vn，启动序章
	if GameState.game_phase == "vn":
		DialogicBridge.start_timeline("res://resources/dialogic/timelines/prologue.dtl", "prologue_dream")


func _on_game_phase_changed(phase: String) -> void:
	_switch_to_phase(phase)


func _switch_to_phase(phase: String) -> void:
	if _transition_lock:
		print("[MainScene] Transition locked, skipping phase: ", phase)
		return
	_transition_lock = true
	print("[MainScene] Switching to phase: ", phase)
	match phase:
		"vn":
			_transition_to_vn()
		"schedule":
			_transition_to_schedule()
		"battle":
			_transition_to_battle()
		_:
			print("[MainScene] Unknown phase: ", phase)


#region --- Phase Transitions ---

func _fade_transition(action: Callable) -> void:
	transition_overlay.visible = true
	var t: Tween = create_tween()
	t.tween_property(transition_overlay, "color:a", 1.0, 0.3)
	t.tween_callback(action)
	t.tween_interval(0.1)
	t.tween_property(transition_overlay, "color:a", 0.0, 0.3)
	t.tween_callback(func(): transition_overlay.visible = false; _transition_lock = false)


func _transition_to_vn() -> void:
	# VN 模式：Dialogic 自行管理布局
	# 只需隐藏其他场景；时间线由外部或 _ready() 启动
	_fade_transition(func():
		if schedule_scene:
			schedule_scene.visible = false
		if battle_scene:
			battle_scene.queue_free()
			battle_scene = null
	)


func _transition_to_schedule() -> void:
	# 停止正在运行的 Dialogic 时间线，防止快进时越界执行
	DialogicBridge.stop_timeline()
	# 隐藏 Dialogic 布局
	_hide_dialogic_layout()

	_fade_transition(func():
		if battle_scene:
			battle_scene.queue_free()
			battle_scene = null
		if schedule_scene == null:
			_create_schedule_scene()
		schedule_scene.visible = true
	)


func _transition_to_battle() -> void:
	# 特殊战斗：先播放战前剧情
	if GameState.battle_type == "special" and not GameState.special_prebattle_done:
		GameState.special_prebattle_done = true
		_hide_dialogic_layout()
		var label := "special_pre_day" + str(GameState.current_day)
		_transition_lock = false
		GameState.set_game_phase("vn")
		DialogicBridge.start_timeline("res://resources/dialogic/timelines/special_battles.dtl", label)
		return
	_transition_lock = false

	# 停止正在运行的 Dialogic 时间线
	DialogicBridge.stop_timeline()
	_hide_dialogic_layout()
	_fade_transition(func():
		if schedule_scene:
			schedule_scene.visible = false
		if battle_scene:
			battle_scene.queue_free()
		_create_battle_scene()
		if battle_scene:
			battle_scene.visible = true
		if GameState.battle_type == "special":
			GameState.special_prebattle_done = false
	)


func _hide_dialogic_layout() -> void:
	if Dialogic.has_subsystem("Styles") and Dialogic.Styles.has_active_layout_node():
		var layout = Dialogic.Styles.get_layout_node()
		if layout and layout.is_inside_tree():
			layout.hide()
			print("[MainScene] Dialogic layout hidden")

#endregion

#region --- Scene Instantiation ---

func _create_schedule_scene() -> void:
	var sch_res: Resource = load("res://scenes/schedule/schedule.tscn")
	if sch_res:
		schedule_scene = sch_res.instantiate()
		schedule_scene.visible = false
		add_child(schedule_scene)
		print("[MainScene] Schedule scene instantiated.")
	else:
		_show_error("无法加载日程场景")


func _create_battle_scene() -> void:
	var btl_res: Resource = load("res://scenes/battle/battle_main.tscn")
	if btl_res:
		battle_scene = btl_res.instantiate()
		battle_scene.visible = false
		add_child(battle_scene)
		print("[MainScene] Battle scene instantiated.")

		var squad: Array[String] = GameState.formation_squad
		if squad.is_empty():
			var chars: Array[String] = PartyData.get_all_character_ids()
			for i in min(3, chars.size()):
				squad.append(chars[i])

		var encounter = _get_encounter(GameState.battle_type)

		var arena = battle_scene.get_node("Arena")
		if arena and arena.has_method("start"):
			arena.start(squad, encounter)
		else:
			_show_error("Arena node missing start method")
	else:
		_show_error("无法加载战斗场景")


func _get_encounter(battle_type: String):
	return PartyData.get_encounter(battle_type)


#endregion

func _show_error(msg: String) -> void:
	var label := Label.new()
	label.add_theme_font_override("font", _cn_font)
	label.text = msg
	label.add_theme_color_override("font_color", Color(1, 0, 0))
	label.add_theme_font_size_override("font_size", 24)
	label.set_anchors_preset(Control.PRESET_CENTER)
	add_child(label)
	print("[MainScene] ERROR: ", msg)


# 从主菜单读档
func _handle_load_from_menu(slot_name: String) -> void:
	print("[MainScene] Loading from menu: ", slot_name)

	# 恢复游戏状态
	var slot_num := _slot_name_to_num(slot_name)
	if slot_num >= 0 and SaveManager.has_slot(slot_num):
		SaveManager.load(slot_num)

	# 恢复 Dialogic 状态（时间线位置）
	var err := Dialogic.Save.load(slot_name)
	if err != OK:
		print("[MainScene] Failed to load save: ", slot_name)
		_show_error("读档失败")


func _slot_name_to_num(slot_name: String) -> int:
	if slot_name.begins_with("slot_"):
		var num_str := slot_name.trim_prefix("slot_")
		if num_str.is_valid_int():
			return num_str.to_int()
	return -1
