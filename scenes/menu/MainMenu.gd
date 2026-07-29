extends CanvasLayer

var _cn_font: Font = preload("res://fonts/NotoSansSC-Regular.otf")

## MainMenu — 主菜单界面
## 左侧: 按钮竖排 | 右侧: 角色立绘竖排

var bg: TextureRect
var char_sprites: Array = []
var buttons: Array = []
var sub_screen: Control = null
var sub_screen_tween: Tween = null

# ── CG 画廊状态 ──
var cg_list: Array = []

const BUTTON_DEFS = [
	{ "idle": "res://images/icon_start_idle.png", "hover": "res://images/kaishi_gaoliang.png", "action": "start" },
	{ "idle": "res://images/icon_cg_idle.png.png", "hover": "res://images/cg_gaoliang.png", "action": "cg" },
	{ "idle": "res://images/duqu.png", "hover": "res://images/duqu_gaoliang.png", "action": "load" },
	{ "idle": "res://images/shezhi.png", "hover": "res://images/shezhi_gaoliang.png", "action": "settings" },
	{ "idle": "res://images/guanyu.png", "hover": "res://images/guanyu_gaoliang.png", "action": "about" },
	{ "idle": "res://images/bangzhu.png", "hover": "res://images/bangzhu_gaoliang.png", "action": "help" },
	{ "idle": "res://images/tuichu.png", "hover": "res://images/tuichu_gaoliang.png", "action": "quit" },
]

const CHAR_DEFS = [
		{ "char_id": "chenli",   	"path": "res://images/chenli_attack.png",    "ax": 0.40, "ay": 0.35 },
		{ "char_id": "hajiyou",  	"path": "res://images/hajiyou_lihui.png",   "ax": 0.55, "ay": 0.35 },
		{ "char_id": "laoma",    	"path": "res://images/laoma.png",     "ax": 0.66, "ay": 0.30 },
		{ "char_id": "laocong",  	"path": "res://images/laocong.png",   "ax": 0.65, "ay": 0.50 },
		{ "char_id": "hajilong", 	"path": "res://images/hajilong.png",  "ax": 0.80, "ay": 0.54 },
		{ "char_id": "laoxiang", 	"path": "res://images/laoxiang.png",  "ax": 0.50, "ay": 0.60 },
]


func load_texture(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	var tex: Texture2D = load(path) as Texture2D
	if tex != null:
		return tex
	# 编辑器降级方案：从文件直接加载（导出包中无效但不影响）
	var img: Image = Image.load_from_file(path)
	if img == null or img.is_empty():
		return null
	return ImageTexture.create_from_image(img)


func _ready() -> void:
	setup_background()
	setup_character_sprites()
	setup_buttons()
	animate_characters()
	# 移除 splash 留下的黑底遮罩
	var black = get_tree().root.get_node_or_null("SplashToMenuBlack")
	if black:
		black.queue_free()


func setup_background() -> void:
	bg = TextureRect.new()
	bg.name = "Background"
	bg.anchor_left = 0.0; bg.anchor_top = 0.0
	bg.anchor_right = 1.0; bg.anchor_bottom = 1.0
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var path: String = "res://images/game_menu.png"
	if ResourceLoader.exists(path):
		var tex: Texture2D = load_texture(path)
		if tex:
			bg.texture = tex

	add_child(bg)


func setup_character_sprites() -> void:
	for data in CHAR_DEFS:
		var char_id: String = data.get("char_id", "")
		if not char_id.is_empty() and not StoryFlags.is_character_met(char_id):
			continue
		var sprite: TextureRect = TextureRect.new()
		sprite.name = "Char_" + data["path"].get_file().get_basename()
		sprite.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sprite.modulate.a = 0.0

		var path: String = data["path"]
		if ResourceLoader.exists(path):
			var tex: Texture2D = load_texture(path)
			if tex:
				sprite.texture = tex

		var ax: float = data["ax"]
		var ay: float = data["ay"]
		sprite.anchor_left = ax; sprite.anchor_right = ax
		sprite.anchor_top = ay; sprite.anchor_bottom = ay
		sprite.offset_left = -100.0; sprite.offset_right = 100.0
		sprite.offset_top = -160.0; sprite.offset_bottom = 160.0

		add_child(sprite)
		char_sprites.append(sprite)
		char_sprites.append(sprite)


func animate_characters() -> void:
	for i in range(char_sprites.size()):
		var sprite: TextureRect = char_sprites[i]
		sprite.modulate.a = 0.0
		var t: Tween = create_tween()
		t.tween_interval(i * 0.2)
		t.tween_property(sprite, "modulate:a", 1.0, 1.0)


func setup_buttons() -> void:
	var start_y: float = 0.2
	var spacing: float = 0.1

	for i in range(BUTTON_DEFS.size()):
		var bd: Dictionary = BUTTON_DEFS[i]
		var btn: TextureRect = TextureRect.new()
		btn.name = "Btn_" + bd["action"]
		btn.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		btn.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

		var btn_y: float = start_y + i * spacing
		btn.anchor_left = 0.02; btn.anchor_right = 0.02
		btn.anchor_top = btn_y; btn.anchor_bottom = btn_y
		btn.offset_left = -50; btn.offset_top = 0.0
		btn.offset_right = 300.0; btn.offset_bottom = 60.0

		_load_button_texture(btn, bd["idle"])

		btn.set_meta("idle_path", bd["idle"])
		btn.set_meta("hover_path", bd["hover"])
		btn.set_meta("action", bd["action"])
		btn.set_meta("orig_offset_top", 0.0)
		btn.set_meta("orig_offset_bottom", 110.0)

		btn.mouse_entered.connect(_on_btn_hover.bind(btn))
		btn.mouse_exited.connect(_on_btn_unhover.bind(btn))
		btn.gui_input.connect(_on_btn_clicked.bind(btn))

		add_child(btn)
		buttons.append(btn)


func _load_button_texture(btn: TextureRect, path: String) -> void:
	if ResourceLoader.exists(path):
		var tex: Texture2D = load_texture(path)
		if tex:
			btn.texture = tex


func _on_btn_hover(btn: TextureRect) -> void:
	var hover_path: String = btn.get_meta("hover_path")
	_load_button_texture(btn, hover_path)
	var base_top: float = btn.get_meta("orig_offset_top")
	var t: Tween = create_tween()
	t.set_parallel(true)
	t.tween_property(btn, "offset_top", base_top - 12.0, 0.1).set_ease(Tween.EASE_OUT)


func _on_btn_unhover(btn: TextureRect) -> void:
	var idle_path: String = btn.get_meta("idle_path")
	_load_button_texture(btn, idle_path)
	var base_top: float = btn.get_meta("orig_offset_top")
	var t: Tween = create_tween()
	t.set_parallel(true)
	t.tween_property(btn, "offset_top", base_top, 0.1).set_ease(Tween.EASE_OUT)


func _on_btn_clicked(event: InputEvent, btn: TextureRect) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return

	var action: String = btn.get_meta("action")
	match action:
		"start":
			GameState.reset()
			PartyData.reset()
			StoryFlags.clear_all()
			if Dialogic.has_subsystem("VAR"):
				Dialogic.VAR.reset()
			if Dialogic.current_timeline:
				Dialogic.end_timeline(true)
			get_tree().change_scene_to_file("res://scenes/main.tscn")
		"quit":
			get_tree().quit()
		_:
			_show_sub_screen(action)


#region --- Sub Screens ---

func _show_sub_screen(action: String) -> void:
	_close_sub_screen()

	sub_screen = Control.new()
	sub_screen.name = "SubScreen_" + action
	sub_screen.anchor_left = 0.0; sub_screen.anchor_top = 0.0
	sub_screen.anchor_right = 1.0; sub_screen.anchor_bottom = 1.0
	sub_screen.mouse_filter = Control.MOUSE_FILTER_STOP

	var overlay: ColorRect = ColorRect.new()
	overlay.anchor_left = 0.0; overlay.anchor_top = 0.0
	overlay.anchor_right = 1.0; overlay.anchor_bottom = 1.0
	overlay.color = Color(0, 0, 0, 0.6)
	sub_screen.add_child(overlay)

	var back_btn: Button = Button.new()
	back_btn.add_theme_font_override("font", _cn_font)
	back_btn.text = "← 返回"
	back_btn.add_theme_font_size_override("font_size", 20)
	back_btn.anchor_left = 0.02; back_btn.anchor_top = 0.02
	back_btn.offset_right = 120.0; back_btn.offset_bottom = 40.0
	back_btn.pressed.connect(_close_sub_screen)
	sub_screen.add_child(back_btn)

	match action:
		"load":
			_create_load_screen(sub_screen)
		"settings":
			_create_settings_screen(sub_screen)
		"cg":
			_create_cg_screen(sub_screen)
		"about":
			_create_info_screen(sub_screen, "关于", "《黎明之诗》\n\nGodot 4.7\n回合制 RPG + 视觉小说\n\n2026")
		"help":
			_create_help_screen(sub_screen)
		_:
			_create_info_screen(sub_screen, action, "开发中...")

	sub_screen.modulate.a = 0.0
	add_child(sub_screen)
	if sub_screen_tween:
		sub_screen_tween.kill()
	sub_screen_tween = create_tween()
	sub_screen_tween.tween_property(sub_screen, "modulate:a", 1.0, 0.3)


func _close_sub_screen() -> void:
	if sub_screen == null: return
	if sub_screen_tween: sub_screen_tween.kill()
	var ss: Control = sub_screen; sub_screen = null
	var t: Tween = create_tween()
	t.tween_property(ss, "modulate:a", 0.0, 0.2)
	t.tween_callback(ss.queue_free)


func _make_btn(text: String, color: Color, hover_color: Color, min_size: Vector2) -> Button:
	var btn := Button.new()
	btn.add_theme_font_override("font", _cn_font)
	btn.text = text
	btn.custom_minimum_size = min_size
	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_color_override("font_color", Color(1, 1, 1))
	btn.add_theme_stylebox_override("normal", _flat_stylebox(color))
	btn.add_theme_stylebox_override("hover", _flat_stylebox(hover_color))
	btn.focus_mode = Control.FOCUS_NONE
	return btn


func _flat_stylebox(color: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.corner_radius_top_left = 4
	sb.corner_radius_top_right = 4
	sb.corner_radius_bottom_left = 4
	sb.corner_radius_bottom_right = 4
	return sb


func _create_info_screen(parent: Control, title: String, body: String) -> void:
	var center: VBoxContainer = VBoxContainer.new()
	center.anchor_left = 0.5; center.anchor_top = 0.5
	center.anchor_right = 0.5; center.anchor_bottom = 0.5
	center.add_theme_constant_override("separation", 20)

	var title_label: Label = Label.new()
	title_label.add_theme_font_override("font", _cn_font)
	title_label.text = title
	title_label.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
	title_label.add_theme_font_size_override("font_size", 36)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(title_label)

	var body_label: Label = Label.new()
	body_label.add_theme_font_override("font", _cn_font)
	body_label.text = body
	body_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	body_label.add_theme_font_size_override("font_size", 20)
	body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(body_label)

	parent.add_child(center)


# ═══════════════════════════════════════════════
#  读档界面（与剧情快捷按钮一致）
# ═══════════════════════════════════════════════

func _create_load_screen(parent: Control) -> void:
	var container := VBoxContainer.new()
	container.anchor_left = 0.5; container.anchor_top = 0.5
	container.anchor_right = 0.5; container.anchor_bottom = 0.5
	container.offset_left = -300.0; container.offset_right = 300.0
	container.offset_top = -200.0; container.offset_bottom = 200.0
	container.add_theme_constant_override("separation", 10)

	var title := Label.new()
	title.add_theme_font_override("font", _cn_font)
	title.text = "读档"
	title.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
	title.add_theme_font_size_override("font_size", 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(title)

	# 使用 Dialogic.Save 的存档格式 — 与剧情快捷按钮一致
	var SLOT_COUNT := 9
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)

	for i in SLOT_COUNT:
		var slot_name := "slot_" + str(i)
		var btn := Button.new()
		btn.add_theme_font_override("font", _cn_font)
		btn.custom_minimum_size = Vector2(170, 80)
		btn.add_theme_font_size_override("font_size", 13)
		btn.focus_mode = Control.FOCUS_NONE

		if SaveManager.has_slot(i):
			var info: Dictionary = SaveManager.get_slot_info(i)
			btn.text = "栏位 " + str(i + 1) + "\n" + str(info.get("timestamp", "")) + "\n第" + str(info.get("chapter", 0) + 1) + "章 第" + str(info.get("day", 1)) + "天"
			btn.add_theme_color_override("font_color", Color(1, 1, 1))
			btn.add_theme_stylebox_override("normal", _flat_stylebox(Color(0.15, 0.15, 0.25, 0.85)))
			btn.pressed.connect(_do_load_from_menu.bind(slot_name))
		else:
			btn.text = "空栏位 " + str(i + 1)
			btn.disabled = true
			btn.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			btn.add_theme_stylebox_override("normal", _flat_stylebox(Color(0.1, 0.1, 0.15, 0.7)))

		btn.add_theme_stylebox_override("hover", _flat_stylebox(Color(0.25, 0.25, 0.4, 0.9)))
		grid.add_child(btn)

	container.add_child(grid)
	parent.add_child(container)


# 从主菜单读档：记下槽位 → 切场景
func _do_load_from_menu(slot_name: String) -> void:
	# 检查 SaveManager 或 Dialogic.Save 是否有存档
	var slot_num := -1
	if slot_name.begins_with("slot_"):
		var num_str := slot_name.trim_prefix("slot_")
		if num_str.is_valid_int():
			slot_num = num_str.to_int()
	if slot_num >= 0 and not SaveManager.has_slot(slot_num):
		if not Dialogic.Save.has_slot(slot_name):
			return
	GameState.pending_load_slot = slot_name
	get_tree().change_scene_to_file("res://scenes/main.tscn")


# ═══════════════════════════════════════════════
#  CG画廊
# ═══════════════════════════════════════════════

func _create_cg_screen(parent: Control) -> void:
	# 扫描 CG 文件
	_scan_cg_files()

	var container := VBoxContainer.new()
	container.anchor_left = 0.0; container.anchor_top = 0.0
	container.anchor_right = 1.0; container.anchor_bottom = 1.0
	container.offset_left = 40.0; container.offset_top = 60.0
	container.offset_right = -40.0; container.offset_bottom = -40.0
	container.add_theme_constant_override("separation", 8)

	var title := Label.new()
	title.add_theme_font_override("font", _cn_font)
	title.text = "CG 画廊"
	title.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
	title.add_theme_font_size_override("font_size", 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(title)

	# 进度条
	var progress_label := Label.new()
	progress_label.add_theme_font_override("font", _cn_font)
	progress_label.name = "CGProgress"
	var unlocked_count := 0
	for cg in cg_list:
		if StoryFlags.is_cg_unlocked(cg):
			unlocked_count += 1
	progress_label.text = str(unlocked_count) + " / " + str(cg_list.size()) + " 已解锁"
	progress_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	progress_label.add_theme_font_size_override("font_size", 16)
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(progress_label)

	# 网格容器
	var grid_scroll := ScrollContainer.new()
	grid_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	container.add_child(grid_scroll)

	var grid := GridContainer.new()
	grid.name = "CGGrid"
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 20)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid_scroll.add_child(grid)

	# 创建问号占位图（如果首次打开则生成）
	# 添加 CG 卡片
	for cg_id in cg_list:
		var card := _make_cg_card(cg_id)
		grid.add_child(card)

	parent.add_child(container)


# CG 文件列表（静态维护，DirAccess 在导出包中无法列目录）
const CG_FILES: Array[String] = [
	"bad_end1",
	"bad_end2",
	"goodend_1",
	"hajilong_cg1",
	"hajiyou_cg1",
	"hajiyou_cg2",
	"hajiyou_cg3",
	"laocong_cg1",
	"laoma_cg1",
	"laoma_cg2",
	"未命名",
]

func _scan_cg_files() -> void:
	cg_list.clear()
	cg_list.assign(CG_FILES)
	cg_list.sort()


func _make_cg_card(cg_id: String) -> Control:
	var card := Control.new()
	card.custom_minimum_size = Vector2(300, 260)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var unlocked := StoryFlags.is_cg_unlocked(cg_id)

	if unlocked:
		var tex_rect := TextureRect.new()
		tex_rect.anchor_left = 0.0; tex_rect.anchor_top = 0.0
		tex_rect.anchor_right = 1.0; tex_rect.anchor_bottom = 1.0
		tex_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var tex := load_texture("res://images/cg/" + cg_id + ".jpg")
		if tex == null:
			tex = load_texture("res://images/cg/" + cg_id + ".png")
		if tex:
			tex_rect.texture = tex
		card.add_child(tex_rect)

		# 名称标签（图片下方 30px 空间）
		var label := Label.new()
		label.add_theme_font_override("font", _cn_font)
		label.anchor_left = 0.0; label.anchor_top = 1.0
		label.anchor_right = 1.0; label.anchor_bottom = 1.0
		label.offset_top = -30.0; label.offset_bottom = 0.0
		label.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
		label.add_theme_font_size_override("font_size", 14)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.text = _cg_display_name(cg_id)
		card.add_child(label)

		# 点击查看大图
		card.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_show_cg_fullscreen(cg_id)
		)
	else:
		# 锁定状态：深色底 + 问号
		var bg := ColorRect.new()
		bg.anchor_left = 0.0; bg.anchor_top = 0.0
		bg.anchor_right = 1.0; bg.anchor_bottom = 1.0
		bg.color = Color(0.1, 0.1, 0.15, 0.8)
		card.add_child(bg)

		var question := Label.new()
		question.add_theme_font_override("font", _cn_font)
		question.anchor_left = 0.0; question.anchor_top = 0.0
		question.anchor_right = 1.0; question.anchor_bottom = 1.0
		question.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45))
		question.add_theme_font_size_override("font_size", 72)
		question.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		question.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		question.text = "?"
		card.add_child(question)

		var lock_label := Label.new()
		lock_label.add_theme_font_override("font", _cn_font)
		lock_label.anchor_left = 0.0; lock_label.anchor_top = 1.0
		lock_label.anchor_right = 1.0; lock_label.anchor_bottom = 1.0
		lock_label.offset_top = -30.0; lock_label.offset_bottom = 0.0
		lock_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		lock_label.add_theme_font_size_override("font_size", 14)
		lock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lock_label.text = "???"
		card.add_child(lock_label)

	return card


func _cg_display_name(cg_id: String) -> String:
	var cg_names := {
		"hajilong_cg1": "哈基龙 - 力之极限",
		"hajiyou_cg1": "哈基佑 - 古卷",
		"hajiyou_cg2": "哈基佑 - 星空",
		"hajiyou_cg3": "哈基佑 - 降临",
		"laoma_cg1": "老马 - 数据分析",
		"laoma_cg2": "老马 - 休憩",
	}
	return cg_names.get(cg_id, cg_id)


func _show_cg_fullscreen(cg_id: String) -> void:
	_close_sub_screen()

	var full := Control.new()
	full.name = "CG_Fullscreen"
	full.anchor_left = 0.0; full.anchor_top = 0.0
	full.anchor_right = 1.0; full.anchor_bottom = 1.0
	full.mouse_filter = Control.MOUSE_FILTER_STOP

	var bg_overlay := ColorRect.new()
	bg_overlay.anchor_left = 0.0; bg_overlay.anchor_top = 0.0
	bg_overlay.anchor_right = 1.0; bg_overlay.anchor_bottom = 1.0
	bg_overlay.color = Color(0, 0, 0, 0.95)
	full.add_child(bg_overlay)

	var tex_rect := TextureRect.new()
	tex_rect.anchor_left = 0.05; tex_rect.anchor_top = 0.05
	tex_rect.anchor_right = 0.95; tex_rect.anchor_bottom = 0.9
	tex_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	var tex: Texture2D = load_texture("res://images/cg/" + cg_id + ".jpg")
	if tex == null:
		tex = load_texture("res://images/cg/" + cg_id + ".png")
	if tex:
		tex_rect.texture = tex
	full.add_child(tex_rect)

	var name_label := Label.new()
	name_label.add_theme_font_override("font", _cn_font)
	name_label.text = _cg_display_name(cg_id)
	name_label.anchor_left = 0.0; name_label.anchor_bottom = 0.95
	name_label.anchor_right = 1.0
	name_label.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	full.add_child(name_label)

	var close_btn := Button.new()
	close_btn.add_theme_font_override("font", _cn_font)
	close_btn.text = "← 返回画廊"
	close_btn.anchor_left = 0.02; close_btn.anchor_top = 0.02
	close_btn.offset_right = 140.0; close_btn.offset_bottom = 40.0
	close_btn.add_theme_font_size_override("font_size", 18)
	close_btn.pressed.connect(func():
		_close_sub_screen()
		_show_sub_screen("cg")
	)
	full.add_child(close_btn)

	# 点击任意位置关闭
	full.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var mouse_pos := (event as InputEventMouseButton).position
			# 不要让点击关闭按钮时也触发
			if mouse_pos.x > 160 or mouse_pos.y > 50:
				_close_sub_screen()
				_show_sub_screen("cg")
	)

	sub_screen = full
	sub_screen.modulate.a = 0.0
	add_child(sub_screen)
	if sub_screen_tween:
		sub_screen_tween.kill()
	sub_screen_tween = create_tween()
	sub_screen_tween.tween_property(sub_screen, "modulate:a", 1.0, 0.3)


# ═══════════════════════════════════════════════
#  设置 / 帮助
# ═══════════════════════════════════════════════

func _create_settings_screen(parent: Control) -> void:
	var container: VBoxContainer = VBoxContainer.new()
	container.anchor_left = 0.5; container.anchor_top = 0.5
	container.anchor_right = 0.5; container.anchor_bottom = 0.5
	container.add_theme_constant_override("separation", 20)

	var title: Label = Label.new()
	title.add_theme_font_override("font", _cn_font)
	title.text = "设置"
	title.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
	title.add_theme_font_size_override("font_size", 32)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(title)

	var fs_btn: Button = Button.new()
	fs_btn.add_theme_font_override("font", _cn_font)
	fs_btn.text = "窗口 / 全屏"
	fs_btn.custom_minimum_size = Vector2(300, 45)
	fs_btn.add_theme_font_size_override("font_size", 18)
	fs_btn.pressed.connect(func():
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	)
	container.add_child(fs_btn)

	var hint: Label = Label.new()
	hint.add_theme_font_override("font", _cn_font)
	hint.text = "更多设置将在后续版本完善"
	hint.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	hint.add_theme_font_size_override("font_size", 14)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(hint)

	parent.add_child(container)


func _create_help_screen(parent: Control) -> void:
	var container: VBoxContainer = VBoxContainer.new()
	container.anchor_left = 0.5; container.anchor_top = 0.5
	container.anchor_right = 0.5; container.anchor_bottom = 0.5
	container.add_theme_constant_override("separation", 12)

	var title: Label = Label.new()
	title.add_theme_font_override("font", _cn_font)
	title.text = "操作帮助"
	title.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
	title.add_theme_font_size_override("font_size", 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(title)

	var entries: Array = [
		["左键点击 / 空格 / 回车", "推进对话"],
		["滚轮上 / H键", "查看对话历史"],
		["鼠标右键 / Esc", "返回"],
		["Ctrl 键", "快进"],
	]

	for entry in entries:
		var hbox: HBoxContainer = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 30)
		var key_label: Label = Label.new()
		key_label.add_theme_font_override("font", _cn_font)
		key_label.text = entry[0]
		key_label.add_theme_color_override("font_color", Color(1, 0.8, 0.4))
		key_label.add_theme_font_size_override("font_size", 18)
		key_label.custom_minimum_size = Vector2(250, 0)
		hbox.add_child(key_label)
		var desc_label: Label = Label.new()
		desc_label.add_theme_font_override("font", _cn_font)
		desc_label.text = entry[1]
		desc_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
		desc_label.add_theme_font_size_override("font_size", 18)
		hbox.add_child(desc_label)
		container.add_child(hbox)

	parent.add_child(container)

#endregion
