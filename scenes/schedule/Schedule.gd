extends CanvasLayer

var _cn_font: Font = preload("res://fonts/NotoSansSC-Regular.otf")

## Schedule — 日程主界面
## 显示AP、日期、动作按钮，管理训练/交流/休息等子面板

const CHAPTER_NAMES := ["序章", "第一章", "第二章", "第三章", "第四章", "第五章", "终章"]

# 动作定义: id, label, ap_cost
const ACTIONS := [
	{ "id": "train",    "label": "训练", "ap": 3 },
	{ "id": "explore",  "label": "探索", "ap": 3 },
	{ "id": "quest",    "label": "委托", "ap": 3 },
	{ "id": "social",   "label": "交流", "ap": 1 },
	{ "id": "cook",     "label": "做饭", "ap": 2 },
	{ "id": "shop",     "label": "购物", "ap": 0 },
	{ "id": "rest",     "label": "休息", "ap": 0 },
]

# Nodes
var header_panel: Panel
var chapter_label: Label
var ap_label: Label
var action_buttons: Array[Button] = []
var sub_panel: Control = null

# 训练子面板状态
var training_char_id: String = ""
var training_stat: String = ""


#region --- Init ---

func _ready() -> void:
	setup_nodes()
	_connect_signals()
	_update_all()
	print("[Schedule] Ready.")


func setup_nodes() -> void:
	# Background
	var bg: TextureRect = TextureRect.new()
	bg.name = "Background"
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg_tex: Texture2D = _load_texture("res://images/main_menu.png")
	if bg_tex:
		bg.texture = bg_tex
	add_child(bg)

	# Dark overlay for readability
	var dark: ColorRect = ColorRect.new()
	dark.name = "DarkOverlay"
	dark.set_anchors_preset(Control.PRESET_FULL_RECT)
	dark.color = Color(0, 0, 0, 0.45)
	dark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dark)

	_setup_header()
	_setup_action_panel()


func _load_texture(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	var tex: Resource = load(path)
	if tex != null:
		return tex
	# 编辑器降级方案：从文件直接加载（导出包中无效但不影响）
	var img: Image = Image.load_from_file(path)
	if img == null or img.is_empty():
		return null
	return ImageTexture.create_from_image(img)


func _connect_signals() -> void:
	GameState.ap_changed.connect(_on_ap_changed)
	GameState.day_advanced.connect(_on_day_advanced)
	GameState.daily_talks_changed.connect(_update_button_states)


#endregion

#region --- Header ---

func _setup_header() -> void:
	header_panel = Panel.new()
	header_panel.name = "HeaderPanel"
	header_panel.anchor_left = 0.0
	header_panel.anchor_top = 0.0
	header_panel.anchor_right = 1.0
	header_panel.offset_bottom = 70.0
	header_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.5)
	header_panel.add_theme_stylebox_override("panel", style)
	add_child(header_panel)

	# Chapter + Day label (left)
	chapter_label = Label.new()
	chapter_label.add_theme_font_override("font", _cn_font)
	chapter_label.name = "ChapterLabel"
	chapter_label.position = Vector2(20, 12)
	chapter_label.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
	chapter_label.add_theme_font_size_override("font_size", 22)
	header_panel.add_child(chapter_label)

	# AP label (right)
	ap_label = Label.new()
	ap_label.add_theme_font_override("font", _cn_font)
	ap_label.name = "APLabel"
	ap_label.anchor_left = 1.0
	ap_label.anchor_right = 1.0
	ap_label.position = Vector2(-240, 12)
	ap_label.add_theme_color_override("font_color", Color(1, 1, 1))
	ap_label.add_theme_font_size_override("font_size", 22)
	ap_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header_panel.add_child(ap_label)


func _update_header() -> void:
	var ch_name: String = CHAPTER_NAMES[clamp(GameState.current_chapter, 0, CHAPTER_NAMES.size() - 1)]
	chapter_label.text = ch_name + "  |  第 " + str(GameState.current_day) + " 天"
	ap_label.text = "剩余行动力: " + str(GameState.current_ap) + " / " + str(GameState.max_ap)

	match GameState.current_ap:
		0:
			ap_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
		1, 2, 3:
			ap_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
		_:
			ap_label.add_theme_color_override("font_color", Color(1, 1, 1))


#endregion

#region --- Action Panel ---

func _setup_action_panel() -> void:
	var container: VBoxContainer = VBoxContainer.new()
	container.name = "ActionPanel"
	container.anchor_left = 0.5
	container.anchor_top = 0.5
	container.anchor_right = 0.5
	container.anchor_bottom = 0.5
	container.add_theme_constant_override("separation", 16)
	add_child(container)

	for action in ACTIONS:
		var btn: Button = Button.new()
		btn.add_theme_font_override("font", _cn_font)
		btn.custom_minimum_size = Vector2(350, 52)
		btn.add_theme_font_size_override("font_size", 22)
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.set_meta("action_id", action["id"])
		btn.set_meta("ap_cost", action["ap"])
		btn.set_meta("base_label", action["label"])

		# Normal style
		var normal: StyleBoxFlat = StyleBoxFlat.new()
		normal.bg_color = Color(0.15, 0.15, 0.2, 0.85)
		normal.set_corner_radius_all(8)
		normal.content_margin_left = 20
		normal.content_margin_right = 20
		btn.add_theme_stylebox_override("normal", normal)

		# Hover style
		var hover: StyleBoxFlat = StyleBoxFlat.new()
		hover.bg_color = Color(0.25, 0.25, 0.35, 0.9)
		hover.set_corner_radius_all(8)
		hover.content_margin_left = 20
		hover.content_margin_right = 20
		btn.add_theme_stylebox_override("hover", hover)

		btn.add_theme_color_override("font_color", Color(1, 1, 1))
		btn.add_theme_color_override("font_hover_color", Color(1, 0.9, 0.4))
		btn.pressed.connect(_on_action_pressed.bind(btn))

		container.add_child(btn)
		action_buttons.append(btn)
		_refresh_button_label(btn)


func _refresh_button_label(btn: Button) -> void:
	var base: String = btn.get_meta("base_label", "")
	var cost: int = btn.get_meta("ap_cost", 0)
	if cost > 0:
		btn.text = base + "  [" + str(cost) + "AP]"
	else:
		btn.text = base + "  [免费]"


func _update_button_states() -> void:
	var ap: int = GameState.current_ap
	for btn in action_buttons:
		var cost: int = btn.get_meta("ap_cost", 0)
		var action_id: String = btn.get_meta("action_id", "")

		var can_use: bool = true

		# AP check
		if cost > 0 and ap < cost:
			can_use = false

		# Social daily limit check
		if action_id == "social" and not GameState.can_anyone_talk():
			can_use = false
			btn.text = "交流  [已达上限]"

		btn.disabled = not can_use

		if btn.disabled:
			btn.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		else:
			btn.add_theme_color_override("font_color", Color(1, 1, 1))
			if not (action_id == "social" and not GameState.can_anyone_talk()):
				_refresh_button_label(btn)


func _update_all() -> void:
	_update_header()
	_update_button_states()


#endregion

#region --- Signal Callbacks ---

func _on_ap_changed(_current: int, _max: int) -> void:
	_update_all()


func _on_day_advanced(_day: int) -> void:
	_update_all()


func _on_action_pressed(btn: Button) -> void:
	if btn.disabled:
		return
	var action_id: String = btn.get_meta("action_id", "")
	match action_id:
		"train":   _show_training_panel()
		"social":  _show_social_panel()
		"rest":    _show_rest_confirm()
		_:         _show_placeholder_panel(btn)


#endregion

#region --- Overlay Sub-Panel System ---

func _close_sub_panel() -> void:
	if sub_panel == null:
		return
	var sp: Control = sub_panel
	sub_panel = null
	var t: Tween = create_tween()
	t.tween_property(sp, "modulate:a", 0.0, 0.2)
	t.tween_callback(sp.queue_free)


func _create_overlay(title: String) -> Control:
	_close_sub_panel()

	sub_panel = Control.new()
	sub_panel.name = "SubPanel"
	sub_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	sub_panel.mouse_filter = Control.MOUSE_FILTER_STOP

	# Dark backdrop
	var backdrop: ColorRect = ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0, 0, 0, 0.65)
	sub_panel.add_child(backdrop)

	# Back button
	var back_btn: Button = Button.new()
	back_btn.add_theme_font_override("font", _cn_font)
	back_btn.text = "← 返回"
	back_btn.position = Vector2(20, 20)
	back_btn.custom_minimum_size = Vector2(100, 35)
	back_btn.add_theme_font_size_override("font_size", 16)
	back_btn.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	back_btn.pressed.connect(_close_sub_panel)
	sub_panel.add_child(back_btn)

	# Title
	var title_label: Label = Label.new()
	title_label.add_theme_font_override("font", _cn_font)
	title_label.text = title
	title_label.anchor_left = 0.5
	title_label.anchor_right = 0.5
	title_label.position = Vector2(0, 25)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
	title_label.add_theme_font_size_override("font_size", 30)
	sub_panel.add_child(title_label)

	# Content host — callers add their children to this node
	var content: Control = Control.new()
	content.name = "Content"
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.mouse_filter = Control.MOUSE_FILTER_PASS
	sub_panel.add_child(content)

	# Fade in
	sub_panel.modulate.a = 0.0
	add_child(sub_panel)
	var t: Tween = create_tween()
	t.tween_property(sub_panel, "modulate:a", 1.0, 0.25)

	return content


func _show_toast(msg: String) -> void:
	var label: Label = Label.new()
	label.add_theme_font_override("font", _cn_font)
	label.text = msg
	label.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
	label.add_theme_font_size_override("font_size", 18)
	label.anchor_left = 0.5
	label.anchor_right = 0.5
	label.anchor_top = 1.0
	label.anchor_bottom = 1.0
	label.offset_top = -50.0
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(label)
	var t: Tween = create_tween()
	t.tween_interval(2.0)
	t.tween_property(label, "modulate:a", 0.0, 0.5)
	t.tween_callback(label.queue_free)


#endregion

#region --- Training Sub-Panel ---

func _show_training_panel() -> void:
	training_char_id = ""
	training_stat = ""
	var content: Control = _create_overlay("训练")
	_build_training_char_grid(content)


func _build_training_char_grid(content: Control) -> void:
	_clear_content_area(content)

	var hint: Label = Label.new()
	hint.add_theme_font_override("font", _cn_font)
	hint.text = "选择要训练的角色"
	hint.anchor_left = 0.5
	hint.anchor_right = 0.5
	hint.position = Vector2(0, 70)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	hint.add_theme_font_size_override("font_size", 20)
	content.add_child(hint)

	var grid: GridContainer = GridContainer.new()
	grid.name = "CharGrid"
	grid.columns = 3
	grid.anchor_left = 0.5
	grid.anchor_right = 0.5
	grid.anchor_top = 0.5
	grid.anchor_bottom = 0.5
	grid.offset_left = -375.0
	grid.offset_right = 375.0
	grid.offset_top = -60.0
	grid.offset_bottom = 60.0
	grid.add_theme_constant_override("h_separation", 15)
	grid.add_theme_constant_override("v_separation", 15)
	content.add_child(grid)

	for char_id in PartyData.characters:
		var c: PartyData.CharacterData = PartyData.characters[char_id]
		var btn: Button = _make_select_button(c.char_name + "\nLv." + str(c.level), 220, 65, 18)
		btn.set_meta("char_id", char_id)
		btn.pressed.connect(_on_train_char_selected.bind(btn, content))
		grid.add_child(btn)


func _on_train_char_selected(btn: Button, content: Control) -> void:
	training_char_id = btn.get_meta("char_id")

	# Highlight selected character button
	for child in (btn.get_parent().get_children() if btn.get_parent() else []):
		if child is Button:
			var style: StyleBoxFlat = _make_button_style(Color(0.3, 0.4, 0.2, 0.9) if child == btn else Color(0.15, 0.15, 0.25, 0.85))
			child.add_theme_stylebox_override("normal", style)

	_build_training_stat_grid(content)


func _build_training_stat_grid(content: Control) -> void:
	# Remove old stat grid
	var old: Node = content.get_node_or_null("StatGrid")
	if old:
		old.queue_free()

	var c: PartyData.CharacterData = PartyData.get_character(training_char_id)
	if c == null:
		return

	var stats: Array[String] = ["STR", "MAG", "VIT", "AGI", "TEC", "CHA"]
	var labels: Array[String] = ["STR 力量", "MAG 魔力", "VIT 耐力", "AGI 敏捷", "TEC 技术", "CHA 魅力"]

	var grid: GridContainer = GridContainer.new()
	grid.name = "StatGrid"
	grid.columns = 3
	grid.anchor_left = 0.5
	grid.anchor_right = 0.5
	grid.anchor_top = 0.5
	grid.anchor_bottom = 0.5
	grid.offset_left = -375.0
	grid.offset_right = 375.0
	grid.offset_top = 40.0
	grid.offset_bottom = 160.0
	grid.add_theme_constant_override("h_separation", 15)
	grid.add_theme_constant_override("v_separation", 15)
	content.add_child(grid)

	for i in stats.size():
		var stat: String = stats[i]
		var cur: int = c.get_stat(stat)
		var nxt: int = cur + GameState.training_per_session
		var btn: Button = _make_select_button(labels[i] + "\n" + str(cur) + " → " + str(nxt), 220, 65, 16)
		btn.set_meta("stat", stat)
		btn.pressed.connect(_on_train_stat_selected.bind(btn, content))
		grid.add_child(btn)


func _on_train_stat_selected(btn: Button, content: Control) -> void:
	training_stat = btn.get_meta("stat")

	# Highlight selected stat button
	for child in (btn.get_parent().get_children() if btn.get_parent() else []):
		if child is Button:
			var style: StyleBoxFlat = _make_button_style(Color(0.4, 0.3, 0.15, 0.9) if child == btn else Color(0.15, 0.15, 0.25, 0.85))
			child.add_theme_stylebox_override("normal", style)

	# Show confirm button
	var old_confirm: Node = content.get_node_or_null("ConfirmBtn")
	if old_confirm:
		old_confirm.queue_free()

	var confirm_btn: Button = Button.new()
	confirm_btn.add_theme_font_override("font", _cn_font)
	confirm_btn.name = "ConfirmBtn"
	confirm_btn.text = "确认训练 [3AP]"
	confirm_btn.anchor_left = 0.5
	confirm_btn.anchor_right = 0.5
	confirm_btn.position = Vector2(-150, 200)
	confirm_btn.custom_minimum_size = Vector2(300, 50)
	confirm_btn.add_theme_font_size_override("font_size", 20)
	confirm_btn.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
	confirm_btn.pressed.connect(_on_training_confirm)
	content.add_child(confirm_btn)


func _on_training_confirm() -> void:
	if training_char_id.is_empty() or training_stat.is_empty():
		return
	if not GameState.spend_ap(3):
		return

	PartyData.modify_stat(training_char_id, training_stat, GameState.training_per_session)

	var c: PartyData.CharacterData = PartyData.get_character(training_char_id)
	var new_val: int = c.get_stat(training_stat) if c else 0
	_show_toast(c.char_name + "  " + training_stat + " +" + str(GameState.training_per_session) + "  →  " + str(new_val))
	_close_sub_panel()


#endregion

#region --- Social Sub-Panel ---

func _show_social_panel() -> void:
	var content: Control = _create_overlay("交流")
	_build_social_list(content)


func _build_social_list(content: Control) -> void:
	_clear_content_area(content)

	var container: VBoxContainer = VBoxContainer.new()
	container.name = "SocialList"
	container.anchor_left = 0.5
	container.anchor_right = 0.5
	container.anchor_top = 0.5
	container.anchor_bottom = 0.5
	container.offset_left = -250.0
	container.offset_right = 250.0
	container.offset_top = -180.0
	container.offset_bottom = 180.0
	container.add_theme_constant_override("separation", 12)
	content.add_child(container)

	for char_id in PartyData.characters:
		var c: PartyData.CharacterData = PartyData.characters[char_id]
		var talk_count: int = GameState.get_talk_count(char_id)
		var can_talk: bool = GameState.can_talk(char_id)
		var has_ap: bool = GameState.current_ap >= 1

		var btn: Button = Button.new()
		btn.add_theme_font_override("font", _cn_font)
		btn.custom_minimum_size = Vector2(450, 48)
		btn.add_theme_font_size_override("font_size", 18)

		if not can_talk:
			btn.text = c.char_name + "  |  好感 " + str(c.affection) + "  |  (已达上限)"
			btn.disabled = true
		elif not has_ap:
			btn.text = c.char_name + "  |  好感 " + str(c.affection) + "  |  (AP不足)"
			btn.disabled = true
		else:
			btn.text = c.char_name + "  |  好感 " + str(c.affection) + "  |  今日 " + str(talk_count) + "/3"

		if btn.disabled:
			btn.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		else:
			btn.add_theme_color_override("font_color", Color(1, 1, 1))

		btn.add_theme_stylebox_override("normal", _make_button_style(Color(0.15, 0.15, 0.25, 0.85)))

		# Capture char_id per iteration
		var captured_id: String = char_id
		btn.pressed.connect(func():
			if not GameState.can_talk(captured_id):
				return
			if not GameState.spend_ap(1):
				return
			GameState.record_talk(captured_id)
			PartyData.add_affection(captured_id, GameState.social_affection_gain)
			var ch: PartyData.CharacterData = PartyData.get_character(captured_id)
			_show_toast("与 " + ch.char_name + " 交谈，好感度 +" + str(GameState.social_affection_gain) + "  (当前: " + str(ch.affection) + ")")
			_build_social_list(content)
		)

		container.add_child(btn)


#endregion

#region --- Rest / Day Advance ---

func _show_rest_confirm() -> void:
	var content: Control = _create_overlay("休息")

	var msg: Label = Label.new()
	msg.add_theme_font_override("font", _cn_font)
	msg.text = "剩余 " + str(GameState.current_ap) + " AP 将清零\n确认休息至第二天？"
	msg.anchor_left = 0.5
	msg.anchor_right = 0.5
	msg.position = Vector2(0, -80)
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.add_theme_color_override("font_color", Color(1, 1, 1))
	msg.add_theme_font_size_override("font_size", 24)
	content.add_child(msg)

	var confirm_btn: Button = Button.new()
	confirm_btn.add_theme_font_override("font", _cn_font)
	confirm_btn.text = "确认休息"
	confirm_btn.anchor_left = 0.5
	confirm_btn.anchor_right = 0.5
	confirm_btn.position = Vector2(-120, 20)
	confirm_btn.custom_minimum_size = Vector2(240, 50)
	confirm_btn.add_theme_font_size_override("font_size", 22)
	confirm_btn.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
	confirm_btn.pressed.connect(func():
		_close_sub_panel()
		_do_day_transition()
	)
	content.add_child(confirm_btn)

	var cancel_btn: Button = Button.new()
	cancel_btn.add_theme_font_override("font", _cn_font)
	cancel_btn.text = "取消"
	cancel_btn.anchor_left = 0.5
	cancel_btn.anchor_right = 0.5
	cancel_btn.position = Vector2(-120, 85)
	cancel_btn.custom_minimum_size = Vector2(240, 45)
	cancel_btn.add_theme_font_size_override("font_size", 18)
	cancel_btn.pressed.connect(_close_sub_panel)
	content.add_child(cancel_btn)


func _do_day_transition() -> void:
	# Full-screen black overlay
	var black: ColorRect = ColorRect.new()
	black.name = "DayTransition"
	black.set_anchors_preset(Control.PRESET_FULL_RECT)
	black.color = Color(0, 0, 0, 0)
	black.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(black)

	var t: Tween = create_tween()
	t.tween_property(black, "color", Color(0, 0, 0, 1), 0.5)
	t.tween_callback(func():
		GameState.advance_day()

		var day_text: Label = Label.new()
		day_text.add_theme_font_override("font", _cn_font)
		day_text.text = "第 " + str(GameState.current_day) + " 天"
		day_text.set_anchors_preset(Control.PRESET_FULL_RECT)
		day_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		day_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		day_text.add_theme_color_override("font_color", Color(1, 1, 1))
		day_text.add_theme_font_size_override("font_size", 48)
		black.add_child(day_text)

		# TODO: Check StoryFlags for night event triggers
		# var flag = "night_event_day_" + str(GameState.current_day)
		# if StoryFlags.has_flag(flag): ...
		print("[Schedule] Night event check placeholder for day ", GameState.current_day)
	)
	t.tween_interval(2.0)
	t.tween_property(black, "color:a", 0.0, 0.5)
	t.tween_callback(black.queue_free)


#endregion

#region --- Placeholder Panels ---

func _show_placeholder_panel(btn: Button) -> void:
	var label: String = btn.get_meta("base_label", btn.text)
	var content: Control = _create_overlay(label)

	var msg: Label = Label.new()
	msg.add_theme_font_override("font", _cn_font)
	msg.text = "开发中..."
	msg.set_anchors_preset(Control.PRESET_CENTER)
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	msg.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	msg.add_theme_font_size_override("font_size", 28)
	content.add_child(msg)


#endregion

#region --- Helpers ---

func _clear_content_area(content: Control) -> void:
	for child in content.get_children():
		child.queue_free()


func _make_button_style(bg_color: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.set_corner_radius_all(8)
	return style


func _make_select_button(text: String, width: int, height: int, font_size: int) -> Button:
	var btn: Button = Button.new()
	btn.add_theme_font_override("font", _cn_font)
	btn.text = text
	btn.custom_minimum_size = Vector2(width, height)
	btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_color_override("font_color", Color(1, 1, 1))
	btn.add_theme_stylebox_override("normal", _make_button_style(Color(0.15, 0.15, 0.25, 0.85)))
	return btn


#endregion
