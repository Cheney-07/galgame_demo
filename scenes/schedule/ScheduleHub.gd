extends CanvasLayer

## ScheduleHub — 日程视觉化主界面
## 角色立绘排列 + 动作按钮 + 队员/编队子面板

# 动作定义
const ACTIONS := [
	{ "id": "train",    "label": "训练",   "ap": 3 },
		{ "id": "social",   "label": "交流",   "ap": 2 },
	{ "id": "cook",     "label": "做饭",   "ap": 2 },
	{ "id": "explore",  "label": "探索",   "ap": 3 },
	{ "id": "quest",    "label": "委托",   "ap": 3 },
	{ "id": "shop",     "label": "购物",   "ap": 0 },
	{ "id": "rest",     "label": "休息",   "ap": 0 },
]

const CHAPTER_NAMES := ["序章", "第一章", "第二章", "第三章", "第四章", "第五章", "终章"]
const STAT_LABELS := { "STR": "力量", "MAG": "魔力", "VIT": "耐力", "AGI": "敏捷", "TEC": "技术", "CHA": "魅力" }
const STATS := ["STR", "MAG", "VIT", "AGI", "TEC", "CHA"]

# 角色立绘在屏幕上的位置（6个锚点）
const CHAR_POSITIONS := [
	{ "ax": 0.05, "ay": 0.82, "id": "chenli" },
	{ "ax": 0.70, "ay": 0.62, "id": "hajiyou" },
	{ "ax": 0.32, "ay": 0.72, "id": "laocong" },
	{ "ax": 0.55, "ay": 0.62, "id": "laoma" },
	{ "ax": 0.45, "ay": 0.32, "id": "laoxiang" },
	{ "ax": 0.82, "ay": 0.82, "id": "hajilong" },
	{ "ax": 0.95, "ay": 0.92, "id": "protagonist" },
]

# --- Nodes ---
var chapter_label: Label
var ap_label: Label
var action_buttons: Array[Button] = []
var char_sprites: Dictionary = {}        # char_id → TextureRect
var selected_char_id: String = ""
var sub_panel: Control = null

# 训练状态
var training_target: String = ""

# 编队状态
var formation_purpose: String = ""       # "explore" / "quest" / "battle"
var formation_selected: Array[String] = []


#region --- Init ---
func _ready() -> void:
	setup_nodes()
	_connect_signals()
	_update_all()
	print("[ScheduleHub] Ready.")

func setup_nodes() -> void:
	_setup_background()
	_setup_header()
	_setup_character_sprites()
	_setup_action_panel()

func _connect_signals() -> void:
	GameState.ap_changed.connect(_on_ap_changed)
	GameState.day_advanced.connect(_on_day_advanced)
	GameState.daily_talks_changed.connect(_update_button_states)
	GameState.character_recruited.connect(_on_character_recruited)

func _setup_background() -> void:
	var bg: TextureRect = TextureRect.new()
	bg.name = "Background"
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tex: Texture2D = ImageUtils.load_texture("res://images/schedule_bg.png")
	if tex == null:
		tex = ImageUtils.load_texture("res://images/main_menu.png")
	if tex:
		bg.texture = tex
	add_child(bg)

#endregion

#region --- Header ---
func _setup_header() -> void:
	var panel: Panel = Panel.new()
	panel.name = "HeaderPanel"
	panel.anchor_left = 0.0; panel.anchor_top = 0.0
	panel.anchor_right = 1.0; panel.offset_bottom = 55.0
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var s: StyleBoxFlat = StyleBoxFlat.new()
	s.bg_color = Color(0, 0, 0, 0.55)
	panel.add_theme_stylebox_override("panel", s)
	add_child(panel)

	chapter_label = Label.new()
	chapter_label.position = Vector2(16, 10)
	chapter_label.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
	chapter_label.add_theme_font_size_override("font_size", 20)
	panel.add_child(chapter_label)

	ap_label = Label.new()
	ap_label.anchor_left = 1.0; ap_label.anchor_right = 1.0
	ap_label.position = Vector2(-210, 10)
	ap_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ap_label.add_theme_font_size_override("font_size", 20)
	panel.add_child(ap_label)

	# 菜单按钮（右上角）
	var menu_btn: Button = Button.new()
	menu_btn.text = "菜单"
	menu_btn.anchor_left = 1.0; menu_btn.anchor_right = 1.0
	menu_btn.position = Vector2(-100, 10)
	menu_btn.custom_minimum_size = Vector2(80, 32)
	menu_btn.add_theme_font_size_override("font_size", 14)
	menu_btn.add_theme_color_override("font_color", Color(1, 1, 1))
	var ms: StyleBoxFlat = StyleBoxFlat.new(); ms.bg_color = Color(0.2, 0.2, 0.35, 0.85)
	ms.set_corner_radius_all(4); menu_btn.add_theme_stylebox_override("normal", ms)
	var msh: StyleBoxFlat = StyleBoxFlat.new(); msh.bg_color = Color(0.35, 0.35, 0.5, 0.9)
	msh.set_corner_radius_all(4); menu_btn.add_theme_stylebox_override("hover", msh)
	menu_btn.pressed.connect(_show_system_menu)
	menu_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(menu_btn)

func _update_header() -> void:
	var ch_name: String = CHAPTER_NAMES[clamp(GameState.current_chapter, 0, CHAPTER_NAMES.size() - 1)]
	chapter_label.text = ch_name + " | 第 " + str(GameState.current_day) + " 天"
	ap_label.text = "AP: " + str(GameState.current_ap) + "/" + str(GameState.max_ap)
	match GameState.current_ap:
		0: ap_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
		1,2,3: ap_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
		_: ap_label.add_theme_color_override("font_color", Color(1, 1, 1))

#endregion

#region --- Character Sprites ---
func _setup_character_sprites() -> void:
	for pos in CHAR_POSITIONS:
		var c: PartyData.CharacterData = PartyData.get_character(pos["id"])
		if c == null or not GameState.is_character_recruited(pos["id"]):
			continue

		var sprite: TextureRect = TextureRect.new()
		sprite.name = "Char_" + pos["id"]
		sprite.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		sprite.mouse_filter = Control.MOUSE_FILTER_STOP
		sprite.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

		sprite.anchor_left = pos["ax"]; sprite.anchor_right = pos["ax"]
		sprite.anchor_top = pos["ay"]; sprite.anchor_bottom = pos["ay"]
		sprite.offset_left = -150.0; sprite.offset_right = 150.0
		sprite.offset_top = -160.0; sprite.offset_bottom = 40.0

		# 加载立绘
		var tex: Texture2D = ImageUtils.load_portrait(c.portrait_path, 300.0)
		if tex:
			sprite.texture = tex

		# 名字标签
		var name_lbl: Label = Label.new()
		name_lbl.name = "NameLabel"
		name_lbl.text = c.char_name + " Lv." + str(c.level)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_color_override("font_color", Color(1, 1, 1))
		name_lbl.add_theme_font_size_override("font_size", 16)
		name_lbl.anchor_left = 0.5; name_lbl.anchor_right = 0.5
		name_lbl.anchor_top = 1.0; name_lbl.anchor_bottom = 1.0
		name_lbl.offset_left = -120.0; name_lbl.offset_right = 120.0
		name_lbl.offset_top = -22.0; name_lbl.offset_bottom = 0.0
		sprite.add_child(name_lbl)

		sprite.gui_input.connect(_on_char_clicked.bind(pos["id"]))
		add_child(sprite)
		char_sprites[pos["id"]] = sprite

	# 放置在前景之后
	pass

func _on_char_clicked(event: InputEvent, char_id: String) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return

	if training_target != "":
		# 正在训练模式：选中角色即确认训练
		_confirm_training(char_id)
		return

	# 普通点击：选中/取消
	if selected_char_id == char_id:
		_deselect_all()
	else:
		_select_character(char_id)

func _select_character(char_id: String) -> void:
	_deselect_all()
	selected_char_id = char_id
	var sprite: TextureRect = char_sprites.get(char_id, null)
	if sprite:
		sprite.modulate = Color(1.3, 1.3, 1.0)  # 金色高亮

func _deselect_all() -> void:
	selected_char_id = ""
	for sp: TextureRect in char_sprites.values():
		sp.modulate = Color(1, 1, 1)

func _refresh_char_labels() -> void:
	for char_id in char_sprites:
		var c: PartyData.CharacterData = PartyData.get_character(char_id)
		if c == null: continue
		var sprite: TextureRect = char_sprites[char_id]
		var lbl: Label = sprite.get_node_or_null("NameLabel") as Label
		if lbl:
			lbl.text = c.char_name + " Lv." + str(c.level)

#endregion

#region --- Action Panel ---
func _setup_action_panel() -> void:
	var hbox: HBoxContainer = HBoxContainer.new() as HBoxContainer
	hbox.name = "ActionPanel"
	hbox.anchor_left = 0.5; hbox.anchor_right = 0.5
	hbox.anchor_top = 1.0; hbox.anchor_bottom = 1.0
	hbox.offset_left = -500.0; hbox.offset_right = 500.0
	hbox.offset_top = -52.0; hbox.offset_bottom = 0.0
	hbox.add_theme_constant_override("separation", 10)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(hbox)

	# 战斗日检测
	var is_battle_day: bool = GameState.is_special_battle_day()

	if is_battle_day:
		# 特殊战斗日：只能出战
		_show_toast("第 " + str(GameState.current_day) + " 天 - 特殊遭遇战！")
		var battle_btn: Button = _make_action_btn({"id": "battle_special", "label": "出战", "ap": 0})
		battle_btn.pressed.connect(func(): _show_formation("special"))
		hbox.add_child(battle_btn)
		action_buttons.append(battle_btn)
		var member_btn: Button = _make_icon_btn("队员")
		member_btn.pressed.connect(_show_character_panel)
		hbox.add_child(member_btn)
	else:
		for action in ACTIONS:
			var btn: Button = _make_action_btn(action)
			hbox.add_child(btn)
			action_buttons.append(btn)

		# 队员按钮
		var member_btn: Button = _make_icon_btn("队员")
		member_btn.pressed.connect(_show_character_panel)
		hbox.add_child(member_btn)

func _make_action_btn(action: Dictionary) -> Button:
	var btn: Button = Button.new()
	btn.text = action["label"] + "\n[" + str(action["ap"]) + "AP]" if action["ap"] > 0 else action["label"]
	btn.custom_minimum_size = Vector2(80, 48)
	btn.add_theme_font_size_override("font_size", 13)
	btn.add_theme_color_override("font_color", Color(1, 1, 1))
	btn.set_meta("action_id", action["id"])
	btn.set_meta("ap_cost", action["ap"])
	btn.set_meta("base_label", action["label"])
	btn.pressed.connect(_on_action_pressed.bind(btn))
	_style_button(btn)
	return btn

func _make_icon_btn(label: String) -> Button:
	var btn: Button = Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(60, 48)
	btn.add_theme_font_size_override("font_size", 13)
	btn.add_theme_color_override("font_color", Color(0.7, 0.8, 1.0))
	_style_button(btn)
	return btn

func _style_button(btn: Button) -> void:
	var normal: StyleBoxFlat = StyleBoxFlat.new()
	normal.bg_color = Color(0.1, 0.1, 0.15, 0.85)
	normal.set_corner_radius_all(6)
	normal.content_margin_left = 6; normal.content_margin_right = 6
	btn.add_theme_stylebox_override("normal", normal)
	var hover: StyleBoxFlat = StyleBoxFlat.new()
	hover.bg_color = Color(0.2, 0.2, 0.3, 0.9)
	hover.set_corner_radius_all(6)
	hover.content_margin_left = 6; hover.content_margin_right = 6
	btn.add_theme_stylebox_override("hover", hover)

func _update_button_states() -> void:
	var ap: int = GameState.current_ap
	for btn in action_buttons:
		var cost: int = btn.get_meta("ap_cost", 0)
		var aid: String = btn.get_meta("action_id", "")
		var ok: bool = (cost == 0 or ap >= cost)
		if aid == "social" and not GameState.can_anyone_talk():
			ok = false; btn.text = "交流\n[已达上限]"
		btn.disabled = not ok
		btn.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4) if not ok else Color(1, 1, 1))
		if ok and not (aid == "social" and not GameState.can_anyone_talk()):
			var base: String = btn.get_meta("base_label", "")
			var pcost: int = cost
			btn.text = base + "\n[" + str(pcost) + "AP]" if pcost > 0 else base

func _refresh_action_panel() -> void:
	# 移除旧的动作面板和所有游离按钮
	var old_panel = get_node_or_null("ActionPanel")
	if old_panel:
		old_panel.queue_free()
	for child in get_children():
		if child is HBoxContainer:
			child.queue_free()
	action_buttons.clear()
	_setup_action_panel()

func _update_all() -> void:
	_update_header()
	_update_button_states()

#endregion

#region --- Signal Callbacks ---
func _on_ap_changed(_c: int, _m: int) -> void: _update_all()
func _on_day_advanced(_d: int) -> void: _refresh_action_panel(); _update_all()

func _on_character_recruited(_char_id: String) -> void:
	_setup_character_sprites()
	_refresh_action_panel()

func _on_action_pressed(btn: Button) -> void:
	if btn.disabled: return
	var aid: String = btn.get_meta("action_id", "")
	match aid:
		"train":   _start_training()
		"social":  _start_social()
		"cook":    _show_placeholder("做饭")
		"explore": _show_formation("explore")
		"quest":   _show_formation("quest")
		"shop":    _show_placeholder("购物")
		"rest":    _show_rest_confirm()

#endregion

#region --- Overlay System ---
func _close_sub_panel() -> void:
	if sub_panel == null: return
	var sp: Control = sub_panel; sub_panel = null
	var t: Tween = create_tween()
	t.tween_property(sp, "modulate:a", 0.0, 0.2)
	t.tween_callback(sp.queue_free)

func _create_overlay(title: String) -> Control:
	_close_sub_panel()
	sub_panel = Control.new()
	sub_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	sub_panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var bg: ColorRect = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.65)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sub_panel.add_child(bg)

	# 内容区（放在标题下面，不遮挡返回按钮和标题）
	var content: Control = Control.new()
	content.name = "Content"
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.mouse_filter = Control.MOUSE_FILTER_PASS
	sub_panel.add_child(content)

	# 返回按钮和标题在 content 之后添加，确保在最上层
	var back: Button = Button.new(); back.text = "← 返回"
	back.position = Vector2(16, 16); back.custom_minimum_size = Vector2(90, 32)
	back.add_theme_font_size_override("font_size", 14)
	back.pressed.connect(_close_sub_panel)
	sub_panel.add_child(back)

	var tl: Label = Label.new(); tl.text = title
	tl.anchor_left = 0.5; tl.anchor_right = 0.5; tl.position = Vector2(0, 18)
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tl.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
	tl.add_theme_font_size_override("font_size", 26)
	tl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sub_panel.add_child(tl)

	sub_panel.modulate.a = 0.0
	add_child(sub_panel)
	var t: Tween = create_tween()
	t.tween_property(sub_panel, "modulate:a", 1.0, 0.25)
	return content

var _last_toast: Label = null

func _show_toast(msg: String) -> void:
	if _last_toast and is_instance_valid(_last_toast):
		_last_toast.queue_free()
	var lbl: Label = Label.new(); lbl.text = msg; _last_toast = lbl
	lbl.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.anchor_left = 0.5; lbl.anchor_right = 0.5
	lbl.anchor_top = 1.0; lbl.anchor_bottom = 1.0
	lbl.offset_top = -80.0; lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(lbl)
	var t: Tween = create_tween(); t.tween_interval(2.0)
	t.tween_property(lbl, "modulate:a", 0.0, 0.5)
	t.tween_callback(lbl.queue_free)

func _show_rest_confirm() -> void:
	var c: Control = _create_overlay("休息")
	var m: Label = Label.new(); m.text = "剩余 " + str(GameState.current_ap) + " AP 将清零\n确认休息至第二天？"
	m.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	m.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	m.anchor_left = 0.5; m.anchor_right = 0.5
	m.anchor_top = 0.5; m.anchor_bottom = 0.5
	m.offset_left = -300; m.offset_right = 300
	m.offset_top = -120; m.offset_bottom = -80
	m.add_theme_color_override("font_color", Color(1, 1, 1))
	m.add_theme_font_size_override("font_size", 22)
	c.add_child(m)
	var cfm: Button = Button.new(); cfm.text = "确认休息"
	cfm.set_anchors_preset(Control.PRESET_CENTER)
	cfm.position = Vector2(-110, 40)
	cfm.custom_minimum_size = Vector2(220, 42); cfm.add_theme_font_size_override("font_size", 18)
	cfm.pressed.connect(func(): _close_sub_panel(); _do_day_transition())
	c.add_child(cfm)
	var cancel: Button = Button.new(); cancel.text = "取消"
	cancel.set_anchors_preset(Control.PRESET_CENTER)
	cancel.position = Vector2(-110, 95)
	cancel.custom_minimum_size = Vector2(220, 38); cancel.add_theme_font_size_override("font_size", 16)
	cancel.pressed.connect(_close_sub_panel)
	c.add_child(cancel)

func _do_day_transition() -> void:
	var black: ColorRect = ColorRect.new()
	black.set_anchors_preset(Control.PRESET_FULL_RECT)
	black.color = Color(0,0,0,0); black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(black)
	var t: Tween = create_tween()
	t.tween_property(black, "color", Color(0,0,0,1), 0.5)
	t.tween_callback(func():
		GameState.advance_day()
		_refresh_char_labels()
		var dt: Label = Label.new(); dt.text = "第 " + str(GameState.current_day) + " 天"
		dt.set_anchors_preset(Control.PRESET_FULL_RECT)
		dt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; dt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		dt.add_theme_color_override("font_color", Color(1,1,1)); dt.add_theme_font_size_override("font_size", 48)
		black.add_child(dt)
	)
	t.tween_interval(2.0)
	t.tween_property(black, "color:a", 0.0, 0.5)
	t.tween_callback(black.queue_free)

func _show_placeholder(title: String) -> void:
	var c: Control = _create_overlay(title)
	var m: Label = Label.new(); m.text = "开发中..."; m.set_anchors_preset(Control.PRESET_CENTER)
	m.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	m.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	m.add_theme_font_size_override("font_size", 24)
	c.add_child(m)

#endregion

#region --- Training ---
func _start_training() -> void:
	training_target = "active"
	_show_toast("请直接点击场景中的角色完成训练")

func _confirm_training(char_id: String) -> void:
	training_target = ""
	if not GameState.spend_ap(3): return

	# 训练：各属性+2（按成长率浮动）
	var ch: PartyData.CharacterData = PartyData.get_character(char_id)
	var bonuses: Array[String] = []
	for st in STATS:
		var gain: int = max(1, int(ch.growth_rates[st] * 2))
		PartyData.modify_stat(char_id, st, gain)
		bonuses.append(st + "+" + str(gain))

	_deselect_all()
	_close_sub_panel()
	_refresh_char_labels()
	_show_toast(ch.char_name + " 训练完成! " + ", ".join(bonuses))

#endregion

#region --- Social ---
func _start_social() -> void:
	var content: Control = _create_overlay("交流 — 选择角色")
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.anchor_left = 0.5; vbox.anchor_right = 0.5
	vbox.anchor_top = 0.5; vbox.anchor_bottom = 0.5
	vbox.offset_left = -220.0; vbox.offset_right = 220.0
	vbox.offset_top = -160.0; vbox.offset_bottom = 160.0
	vbox.add_theme_constant_override("separation", 10)
	content.add_child(vbox)

	for char_id in GameState.get_recruited_characters():
		var ch: PartyData.CharacterData = PartyData.get_character(char_id)
		var tcnt: int = GameState.get_talk_count(char_id)
		var ok: bool = GameState.can_talk(char_id) and GameState.current_ap >= 2
		var btn: Button = Button.new()
		btn.custom_minimum_size = Vector2(400, 42)
		btn.add_theme_font_size_override("font_size", 16)
		if not ok:
			btn.text = ch.char_name + " | 好感 " + str(ch.affection) + (" | (已达上限)" if not GameState.can_talk(char_id) else " | (AP不足)")
			btn.disabled = true
			btn.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		else:
			btn.text = ch.char_name + " | 好感 " + str(ch.affection) + " | 今日 " + str(tcnt) + "/3"
			btn.add_theme_color_override("font_color", Color(1, 1, 1))
		btn.add_theme_stylebox_override("normal", _make_flat_style(Color(0.12, 0.12, 0.22, 0.85)))
		btn.pressed.connect(_on_social_btn_pressed.bind(char_id))
		vbox.add_child(btn)


# ═══════ 读档 ═══════

func _on_social_btn_pressed(cid: String) -> void:
	if not GameState.can_talk(cid) or not GameState.spend_ap(2): return
	GameState.record_talk(cid)
	PartyData.add_affection(cid, GameState.social_affection_gain)
	_close_sub_panel()
	var scene_id: String = "social_" + cid + "_day" + str(GameState.current_day)
	GameState.pending_scene = "schedule"
	_play_dialogue_scene(scene_id)

func _play_dialogue_scene(scene_id: String) -> void:
	GameState.set_game_phase("vn")
	DialogicBridge.start_timeline("res://resources/dialogic/timelines/social.dtl", scene_id)

func _on_formation_btn_pressed(cid: String, content: Control) -> void:
	if cid in formation_selected:
		formation_selected.erase(cid)
	elif formation_selected.size() < 3:
		formation_selected.append(cid)
	_build_formation_grid(content)

func _show_save_slots() -> void:
	var SLOT_COUNT := 9
	var content: Control = _create_overlay("存档")
	var grid: GridContainer = GridContainer.new()
	grid.columns = 3
	grid.anchor_left = 0.5; grid.anchor_right = 0.5
	grid.anchor_top = 0.5; grid.anchor_bottom = 0.5
	grid.offset_left = -300.0; grid.offset_right = 300.0
	grid.offset_top = -120.0; grid.offset_bottom = 120.0
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	content.add_child(grid)
	for i in SLOT_COUNT:
		var slot_name := "slot_" + str(i)
		var btn: Button = Button.new()
		btn.custom_minimum_size = Vector2(160, 80)
		btn.add_theme_font_size_override("font_size", 13)
		btn.focus_mode = Control.FOCUS_NONE
		if SaveManager.has_slot(i):
			var info: Dictionary = SaveManager.get_slot_info(i)
			btn.text = "栏位 " + str(i + 1) + "\n" + info.get("timestamp", "") + "\n第" + str(info.get("chapter", 0) + 1) + "章 第" + str(info.get("day", 1)) + "天"
			btn.add_theme_color_override("font_color", Color(1, 1, 1))
			btn.add_theme_stylebox_override("normal", _make_flat_style(Color(0.15, 0.15, 0.25, 0.85)))
		else:
			btn.text = "空栏位 " + str(i + 1)
			btn.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			btn.add_theme_stylebox_override("normal", _make_flat_style(Color(0.1, 0.1, 0.15, 0.7)))
		btn.add_theme_stylebox_override("hover", _make_flat_style(Color(0.25, 0.25, 0.4, 0.9)))
		btn.pressed.connect(_do_schedule_save.bind(slot_name, i))
		grid.add_child(btn)

func _show_load_slots() -> void:
	var SLOT_COUNT := 9
	var content: Control = _create_overlay("读档")
	var grid: GridContainer = GridContainer.new()
	grid.columns = 3
	grid.anchor_left = 0.5; grid.anchor_right = 0.5
	grid.anchor_top = 0.5; grid.anchor_bottom = 0.5
	grid.offset_left = -300.0; grid.offset_right = 300.0
	grid.offset_top = -120.0; grid.offset_bottom = 120.0
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	content.add_child(grid)

	for i in SLOT_COUNT:
		var slot_name := "slot_" + str(i)
		var btn: Button = Button.new()
		btn.custom_minimum_size = Vector2(160, 80)
		btn.add_theme_font_size_override("font_size", 13)
		btn.focus_mode = Control.FOCUS_NONE

		if SaveManager.has_slot(i):
			var info: Dictionary = SaveManager.get_slot_info(i)
			btn.text = "栏位 " + str(i + 1) + "\n" + info.get("timestamp", "") + "\n第" + str(info.get("chapter", 0) + 1) + "章 第" + str(info.get("day", 1)) + "天"
			btn.add_theme_color_override("font_color", Color(1, 1, 1))
			btn.add_theme_stylebox_override("normal", _make_flat_style(Color(0.15, 0.15, 0.25, 0.85)))
			btn.pressed.connect(_do_schedule_load.bind(slot_name, i))
		else:
			btn.text = "空栏位 " + str(i + 1)
			btn.disabled = true
			btn.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			btn.add_theme_stylebox_override("normal", _make_flat_style(Color(0.1, 0.1, 0.15, 0.7)))
		btn.add_theme_stylebox_override("hover", _make_flat_style(Color(0.25, 0.25, 0.4, 0.9)))
		grid.add_child(btn)


# ═══════ 设置 ═══════

func _make_spacer(h: int) -> Control:
	var sp: Control = Control.new(); sp.custom_minimum_size = Vector2(0, h); return sp

func _make_flat_style(c: Color) -> StyleBoxFlat:
	var s: StyleBoxFlat = StyleBoxFlat.new(); s.bg_color = c; s.set_corner_radius_all(6); return s

func _sys_button(text: String) -> Button:
	var btn: Button = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(280, 44)
	btn.add_theme_font_size_override("font_size", 17)
	btn.add_theme_color_override("font_color", Color(1, 1, 1))
	btn.add_theme_stylebox_override("normal", _make_flat_style(Color(0.12, 0.12, 0.22, 0.85)))
	btn.add_theme_stylebox_override("hover", _make_flat_style(Color(0.22, 0.22, 0.4, 0.9)))
	return btn

func _show_system_menu() -> void:
	var content: Control = _create_overlay("系统菜单")
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.anchor_left = 0.5; vbox.anchor_right = 0.5
	vbox.anchor_top = 0.5; vbox.anchor_bottom = 0.5
	vbox.offset_left = -200.0; vbox.offset_right = 200.0
	vbox.offset_top = -180.0; vbox.offset_bottom = 180.0
	vbox.add_theme_constant_override("separation", 14)
	content.add_child(vbox)

	var title: Label = Label.new(); title.text = "系统菜单"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
	title.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title)

	var save_btn: Button = _sys_button("存档")
	save_btn.pressed.connect(func(): _close_sub_panel(); _show_save_slots())
	vbox.add_child(save_btn)
	var load_btn: Button = _sys_button("读档")
	load_btn.pressed.connect(func(): _close_sub_panel(); _show_load_slots())
	vbox.add_child(load_btn)
	var set_btn: Button = _sys_button("设置")
	set_btn.pressed.connect(func(): _close_sub_panel(); _show_schedule_settings())
	vbox.add_child(set_btn)
	vbox.add_child(HSeparator.new())
	var quit_btn: Button = _sys_button("返回主菜单")
	quit_btn.pressed.connect(func(): _close_sub_panel(); get_tree().change_scene_to_file("res://scenes/menu/splash.tscn"))
	vbox.add_child(quit_btn)

func _show_schedule_settings() -> void:
	var content: Control = _create_overlay("设置")
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.anchor_left = 0.5; vbox.anchor_right = 0.5
	vbox.anchor_top = 0.5; vbox.anchor_bottom = 0.5
	vbox.offset_left = -200.0; vbox.offset_right = 200.0
	vbox.offset_top = -120.0; vbox.offset_bottom = 120.0
	vbox.add_theme_constant_override("separation", 12)
	content.add_child(vbox)

	# 音量滑块 — Master
	vbox.add_child(_make_volume_row("总音量", &"Master"))
	if AudioServer.get_bus_index(&"SFX") >= 0:
		vbox.add_child(_make_volume_row("音效", &"SFX"))
	if AudioServer.get_bus_index(&"Music") >= 0:
		vbox.add_child(_make_volume_row("音乐", &"Music"))

	vbox.add_child(HSeparator.new())

	var fs_btn: Button = Button.new()
	fs_btn.text = "窗口 / 全屏"
	fs_btn.add_theme_font_size_override("font_size", 16)
	fs_btn.add_theme_color_override("font_color", Color(1, 1, 1))
	fs_btn.custom_minimum_size = Vector2(280, 40)
	fs_btn.add_theme_stylebox_override("normal", _make_flat_style(Color(0.15, 0.15, 0.25, 0.85)))
	fs_btn.add_theme_stylebox_override("hover", _make_flat_style(Color(0.25, 0.25, 0.4, 0.9)))
	fs_btn.pressed.connect(func():
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	)
	vbox.add_child(fs_btn)



# 日程存档/读档回调（用 .bind() 传参避免闭包捕获 bug）
func _do_schedule_save(slot_name: String, idx: int) -> void:
	SaveManager.save(idx)
	var extra := { "date": Time.get_datetime_string_from_system(), "chapter": GameState.current_chapter, "day": GameState.current_day }
	Dialogic.Save.save(slot_name, false, Dialogic.Save.ThumbnailMode.NONE, extra)
	_close_sub_panel()
	_show_toast("已存档: 栏位 " + str(idx + 1))

func _do_schedule_load(slot_name: String, idx: int) -> void:
	if not SaveManager.load(idx):
		_show_toast("读档失败")
		return
	_close_sub_panel()
	# Dialogic 存档恢复（含时间线位置）
	if Dialogic.Save.has_slot(slot_name):
		Dialogic.Save.load(slot_name)
	# 统一切到 MainScene，它会根据 game_phase 和 current_timeline 自动选择
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _make_volume_row(label_text: String, bus: StringName) -> HBoxContainer:
	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	var lbl: Label = Label.new(); lbl.text = label_text
	lbl.custom_minimum_size = Vector2(70, 0)
	lbl.add_theme_color_override("font_color", Color(1, 1, 1))
	lbl.add_theme_font_size_override("font_size", 16)
	hbox.add_child(lbl)

	var bus_idx: int = AudioServer.get_bus_index(bus)
	var cur: float = db_to_linear(AudioServer.get_bus_volume_db(bus_idx)) if bus_idx >= 0 else 1.0

	var slider: HSlider = HSlider.new()
	slider.custom_minimum_size = Vector2(180, 0)
	slider.min_value = 0.0; slider.max_value = 1.0; slider.step = 0.05
	slider.value = cur
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(slider)

	var val_lbl: Label = Label.new(); val_lbl.text = str(int(cur * 100)) + "%"
	val_lbl.custom_minimum_size = Vector2(40, 0); val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	val_lbl.add_theme_font_size_override("font_size", 14)
	hbox.add_child(val_lbl)

	slider.value_changed.connect(func(val: float):
		var b: int = AudioServer.get_bus_index(bus)
		if b >= 0:
			AudioServer.set_bus_volume_db(b, linear_to_db(val))
		val_lbl.text = str(int(val * 100)) + "%"
	)
	return hbox

#endregion

#region --- Formation Panel (编队) ---
func _show_character_panel() -> void:
	var content: Control = _create_overlay("队员详情")
	var char_ids: Array[String] = GameState.get_recruited_characters()
	if char_ids.is_empty(): return

	var state: Array[Dictionary] = [{ "idx": 0, "card": null }]
	var init_card: Control = _build_character_card(char_ids[0], content)
	init_card.name = "CharCard"
	init_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(init_card)
	state[0]["card"] = init_card

	var left_btn: Button = Button.new(); left_btn.text = "◀"
	left_btn.position = Vector2(40, 320); left_btn.custom_minimum_size = Vector2(50, 50)
	left_btn.add_theme_font_size_override("font_size", 28)
	left_btn.pressed.connect(func():
		state[0]["idx"] = (state[0]["idx"] - 1 + char_ids.size()) % char_ids.size()
		var new_card: Control = _build_character_card(char_ids[state[0]["idx"]], content)
		new_card.name = "CharCard"; new_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(new_card)
		var old = state[0]["card"]
		if old: old.queue_free()
		state[0]["card"] = new_card
	)
	content.add_child(left_btn)

	var right_btn: Button = Button.new(); right_btn.text = "▶"
	right_btn.anchor_left = 1.0; right_btn.anchor_right = 1.0
	right_btn.position = Vector2(-90, 320); right_btn.custom_minimum_size = Vector2(50, 50)
	right_btn.add_theme_font_size_override("font_size", 28)
	right_btn.pressed.connect(func():
		state[0]["idx"] = (state[0]["idx"] + 1) % char_ids.size()
		var new_card: Control = _build_character_card(char_ids[state[0]["idx"]], content)
		new_card.name = "CharCard"; new_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(new_card)
		var old = state[0]["card"]
		if old: old.queue_free()
		state[0]["card"] = new_card
	)
	content.add_child(right_btn)

func _build_character_card(char_id: String, _parent: Control) -> Control:
	var c: PartyData.CharacterData = PartyData.get_character(char_id)
	var root: Control = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_PASS

	var portrait: TextureRect = TextureRect.new()
	portrait.name = "Portrait"
	portrait.anchor_left = 0.08; portrait.anchor_top = 0.1
	portrait.anchor_right = 0.08; portrait.anchor_bottom = 0.1
	portrait.offset_left = -80.0; portrait.offset_right = 120.0
	portrait.offset_top = -150.0; portrait.offset_bottom = 150.0
	portrait.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var tex: Texture2D = ImageUtils.load_portrait(c.portrait_path, 350.0)
	if tex: portrait.texture = tex
	root.add_child(portrait)

	var info: VBoxContainer = VBoxContainer.new()
	info.name = "Info"; info.anchor_left = 0.55; info.anchor_top = 0.12
	info.offset_right = -60.0; info.add_theme_constant_override("separation", 8)
	root.add_child(info)

	var name_lbl: Label = Label.new(); name_lbl.text = c.char_name + "  Lv." + str(c.level)
	name_lbl.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
	name_lbl.add_theme_font_size_override("font_size", 28)
	info.add_child(name_lbl)

	var role_desc: String = ""
	if c.template and c.template.has_method("get"):
		var desc_var: Variant = c.template.get("description")
		role_desc = str(desc_var) if desc_var != null else ""
	var role_lbl: Label = Label.new(); role_lbl.text = "定位: " + role_desc
	role_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	role_lbl.add_theme_font_size_override("font_size", 16)
	info.add_child(role_lbl)
	info.add_child(_make_spacer(10))

	for st in STATS:
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var icon: TextureRect = TextureRect.new()
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(28, 28)
		var itex: Texture2D = ImageUtils.load_icon("res://images/icons/stats/" + st + ".png", 28.0)
		if itex: icon.texture = itex
		row.add_child(icon)
		var st_lbl := Label.new(); st_lbl.text = STAT_LABELS[st] + ": " + str(c.get_base_stat(st))
		st_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
		st_lbl.add_theme_font_size_override("font_size", 18)
		st_lbl.custom_minimum_size = Vector2(160, 0)
		row.add_child(st_lbl)
		var bar_bg: ColorRect = ColorRect.new(); bar_bg.color = Color(0.2, 0.2, 0.2)
		bar_bg.custom_minimum_size = Vector2(120, 14)
		row.add_child(bar_bg)
		var bar_fg: ColorRect = ColorRect.new(); bar_fg.color = Color(0.4, 0.6, 0.9)
		var pct: float = clamp(float(c.get_base_stat(st)) / 50.0, 0.02, 1.0)
		bar_fg.custom_minimum_size = Vector2(120 * pct, 14)
		bar_bg.add_child(bar_fg)
		info.add_child(row)

	info.add_child(_make_spacer(10))
	var aff_lbl: Label = Label.new(); aff_lbl.text = "好感度: " + str(c.affection)
	aff_lbl.add_theme_color_override("font_color", Color(1, 0.8, 0.6))
	aff_lbl.add_theme_font_size_override("font_size", 18)
	info.add_child(aff_lbl)

	var skill_names: Array[String] = []
	for sid in c.skill_pool:
		var sk = PartyData.get_skill(sid)
		if sk and sk.has_method("get"):
			skill_names.append(str(sk.get("skill_name")))
		else:
			skill_names.append(sid)
	var skills_lbl: Label = Label.new()
	skills_lbl.text = "技能: " + ", ".join(skill_names)
	skills_lbl.add_theme_color_override("font_color", Color(0.7, 0.8, 1.0))
	skills_lbl.add_theme_font_size_override("font_size", 14)
	info.add_child(skills_lbl)

	return root

func _show_formation(purpose: String) -> void:
	formation_purpose = purpose
	formation_selected.clear()
	var content: Control = _create_overlay("编队 — 选择3名出战队员")
	_build_formation_grid(content)

func _build_formation_grid(content: Control) -> void:
	# clear old
	for child in content.get_children():
		child.queue_free()

	var grid: GridContainer = GridContainer.new()
	grid.name = "FormGrid"
	grid.columns = 3
	grid.anchor_left = 0.5; grid.anchor_right = 0.5
	grid.anchor_top = 0.5; grid.anchor_bottom = 0.5
	grid.offset_left = -360.0; grid.offset_right = 360.0
	grid.offset_top = -100.0; grid.offset_bottom = 100.0
	grid.add_theme_constant_override("h_separation", 15)
	grid.add_theme_constant_override("v_separation", 15)
	content.add_child(grid)

	for char_id in GameState.get_recruited_characters():
		var ch: PartyData.CharacterData = PartyData.get_character(char_id)
		var selected: bool = char_id in formation_selected
		var btn: Button = Button.new()
		btn.text = ch.char_name + "\nLv." + str(ch.level) + ("\n✓" if selected else "")
		btn.custom_minimum_size = Vector2(200, 70)
		btn.add_theme_font_size_override("font_size", 16)
		btn.add_theme_color_override("font_color", Color(1, 0.9, 0.4) if selected else Color(1, 1, 1))
		btn.add_theme_stylebox_override("normal", _make_flat_style(
			Color(0.3, 0.4, 0.2, 0.85) if selected else Color(0.12, 0.12, 0.22, 0.85)
		))
		btn.pressed.connect(_on_formation_btn_pressed.bind(char_id, content))
		grid.add_child(btn)

	# Confirm button (允许1-3人出战，未满时弹出确认)
	var cfm: Button = Button.new()
	var max_size = min(3, GameState.get_recruited_characters().size())
	var selected_count = formation_selected.size()
	cfm.text = "确认出战" if selected_count >= 1 else "请选择队员 (" + str(selected_count) + "/" + str(max_size) + ")"
	cfm.disabled = selected_count < 1
	if selected_count > 0 and selected_count < max_size:
		cfm.text = "确认出战(仅" + str(selected_count) + "人)"
	cfm.anchor_left = 0.5; cfm.anchor_right = 0.5; cfm.anchor_top = 0.5
	cfm.position = Vector2(-120, 130)
	cfm.custom_minimum_size = Vector2(240, 44)
	cfm.add_theme_font_size_override("font_size", 18)
	cfm.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
	cfm.pressed.connect(func():
		_close_sub_panel()
		if formation_purpose != "battle" and formation_purpose != "special":
			if not GameState.spend_ap(3):
				_show_toast("AP不足!")
				return
		GameState.formation_squad = formation_selected.duplicate()
		GameState.battle_type = formation_purpose
		_show_toast("出动!")
		GameState.set_game_phase("battle")
	)
	content.add_child(cfm)

#endregion
