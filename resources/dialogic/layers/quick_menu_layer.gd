@tool
extends DialogicLayoutLayer

var _cn_font: Font = preload("res://fonts/NotoSansSC-Regular.otf")

## 快捷菜单层 — 存档/读档/自动/快进/设置
## 按钮居中放置，含多栏位存档读档界面

@export_group("Layout")
@export var menu_offset_x: float = -150
@export var menu_offset_y: float = -20

@export_group("Button Style")
@export var button_color: Color = Color(0.12, 0.12, 0.22, 0.85)
@export var button_hover_color: Color = Color(0.22, 0.22, 0.4, 0.9)
@export var font_size: int = 12
@export var button_width: float = 65
@export var button_height: float = 22
@export var button_padding_h: int = 6
@export var button_padding_v: int = 2
@export var panel_bg_color: Color = Color(0.08, 0.08, 0.15, 0.92)

const SAVE_SLOT_COUNT := 9
const BUS_MASTER := &"Master"

var auto_on := false
var skip_on := false
var overlay_panel: Control = null
var btn_auto: Button = null
var btn_skip: Button = null


func _ready() -> void:
	set(&"mouse_filter", Control.MOUSE_FILTER_IGNORE)
	_setup_buttons()


func _setup_buttons() -> void:
	var container := HBoxContainer.new()
	container.name = "QuickMenuContainer"
	container.anchors_preset = Control.PRESET_CENTER_BOTTOM
	container.anchor_top = 1.0
	container.anchor_bottom = 1.0
	container.offset_top = menu_offset_y
	container.offset_left = menu_offset_x
	container.offset_right = 0
	container.offset_bottom = 0
	container.add_theme_constant_override("separation", 6)
	add_child(container)

	var names := ["存档", "读档", "自动", "快进", "设置"]
	var callbacks := [_on_save, _on_load, _on_auto, _on_skip, _on_settings]
	for i in names.size():
		var btn := _make_button(names[i], callbacks[i])
		container.add_child(btn)
		match names[i]:
			"自动": btn_auto = btn
			"快进": btn_skip = btn

	if not Engine.is_editor_hint():
		Dialogic.Inputs.auto_advance.toggled.connect(_on_auto_toggled)
		Dialogic.Inputs.auto_skip.toggled.connect(_on_skip_toggled)


func _make_button(text: String, callback: Callable) -> Button:
	var btn := Button.new()
	btn.add_theme_font_override("font", _cn_font)
	btn.text = text
	btn.custom_minimum_size = Vector2(button_width, button_height)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn.add_theme_font_override("font", _cn_font)
	btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_color_override("font_color", Color(1, 1, 1))
	btn.add_theme_stylebox_override("normal", _make_stylebox(button_color))
	btn.add_theme_stylebox_override("hover", _make_stylebox(button_hover_color))
	btn.focus_mode = Control.FOCUS_NONE
	btn.pressed.connect(func():
		callback.call()
		# 释放焦点，避免按钮吞后续点击
		get_viewport().gui_release_focus()
		btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
		await get_tree().process_frame
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
	)
	return btn


func _make_stylebox(color: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.content_margin_left = button_padding_h
	sb.content_margin_right = button_padding_h
	sb.content_margin_top = button_padding_v
	sb.content_margin_bottom = button_padding_v
	sb.corner_radius_top_left = 4
	sb.corner_radius_top_right = 4
	sb.corner_radius_bottom_left = 4
	sb.corner_radius_bottom_right = 4
	return sb


func _make_panel_button(text: String, normal_c: Color, hover_c: Color) -> Button:
	var btn := Button.new()
	btn.add_theme_font_override("font", _cn_font)
	btn.text = text
	btn.custom_minimum_size = Vector2(280, 40)
	btn.add_theme_font_size_override("font_size", 17)
	btn.add_theme_color_override("font_color", Color(1, 1, 1))
	btn.add_theme_stylebox_override("normal", _make_stylebox(normal_c))
	btn.add_theme_stylebox_override("hover", _make_stylebox(hover_c))
	btn.focus_mode = Control.FOCUS_NONE
	return btn


#region 按钮回调

func _on_save() -> void:
	if Engine.is_editor_hint(): return
	_show_save_panel()

func _on_load() -> void:
	if Engine.is_editor_hint(): return
	_show_load_panel()

func _on_auto() -> void:
	if Engine.is_editor_hint(): return
	auto_on = !auto_on
	Dialogic.Inputs.auto_advance.enabled_until_user_input = auto_on
	_update_auto_button()

func _on_skip() -> void:
	if Engine.is_editor_hint(): return
	skip_on = !skip_on
	Dialogic.Inputs.auto_skip.enabled = skip_on
	if skip_on:
		Dialogic.Inputs.auto_skip.disable_on_unread_text = false
	_update_skip_button()

func _on_settings() -> void:
	if Engine.is_editor_hint(): return
	_show_settings_panel()

func _on_auto_toggled(enabled: bool) -> void:
	auto_on = enabled
	_update_auto_button()

func _on_skip_toggled(enabled: bool) -> void:
	skip_on = enabled
	_update_skip_button()

func _update_auto_button() -> void:
	if btn_auto:
		btn_auto.text = "自动" if not auto_on else "■ 自动"
		btn_auto.add_theme_color_override("font_color", Color(1, 1, 1) if not auto_on else Color(1, 0.9, 0.2))

func _update_skip_button() -> void:
	if btn_skip:
		btn_skip.text = "快进" if not skip_on else "■ 快进"
		btn_skip.add_theme_color_override("font_color", Color(1, 1, 1) if not skip_on else Color(1, 0.9, 0.2))

#endregion


#region 通用面板

func _close_overlay() -> void:
	if overlay_panel:
		var t := create_tween()
		t.tween_property(overlay_panel, "modulate:a", 0.0, 0.12)
		t.tween_callback(func():
			overlay_panel.queue_free()
			overlay_panel = null
		)


func _make_overlay(title_text: String) -> VBoxContainer:
	if overlay_panel:
		_close_overlay()

	overlay_panel = Control.new()
	overlay_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay_panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.7)
	overlay_panel.add_child(bg)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.offset_left = -200.0
	vbox.offset_top = -200.0
	vbox.offset_right = 200.0
	vbox.offset_bottom = 200.0
	vbox.add_theme_constant_override("separation", 10)
	overlay_panel.add_child(vbox)

	var title := Label.new()
	title.add_theme_font_override("font", _cn_font)
	title.text = title_text
	title.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
	title.add_theme_font_size_override("font_size", 26)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	add_child(overlay_panel)
	overlay_panel.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(overlay_panel, "modulate:a", 1.0, 0.15)

	return vbox


func _add_close_button(vbox: VBoxContainer) -> void:
	var sep := HSeparator.new()
	sep.modulate.a = 0.2
	vbox.add_child(sep)
	var close_btn := _make_panel_button("关闭", button_color, button_hover_color)
	close_btn.pressed.connect(_close_overlay)
	vbox.add_child(close_btn)


func _make_grid(parent: VBoxContainer) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	parent.add_child(grid)
	return grid

#endregion


#region 存档/读档

func _show_save_panel() -> void:
	var vbox := _make_overlay("存档")
	var grid := _make_grid(vbox)
	for i in SAVE_SLOT_COUNT:
		var slot_name := "slot_" + str(i)
		var slot_btn := _make_slot_button(slot_name, false)
		slot_btn.pressed.connect(_do_save.bind(slot_name, slot_btn))
		grid.add_child(slot_btn)
	_add_close_button(vbox)


func _show_load_panel() -> void:
	var vbox := _make_overlay("读档")
	var grid := _make_grid(vbox)
	for i in SAVE_SLOT_COUNT:
		var slot_name := "slot_" + str(i)
		var slot_btn := _make_slot_button(slot_name, true)
		slot_btn.pressed.connect(_do_load.bind(slot_name, slot_btn))
		grid.add_child(slot_btn)
	_add_close_button(vbox)


func _make_slot_button(slot_name: String, is_load: bool) -> Button:
	var btn := Button.new()
	btn.add_theme_font_override("font", _cn_font)
	btn.custom_minimum_size = Vector2(120, 80)
	btn.add_theme_font_size_override("font_size", 13)
	btn.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	btn.focus_mode = Control.FOCUS_NONE

	var slot_num := _slot_name_to_num(slot_name)
	if slot_num >= 0 and SaveManager.has_slot(slot_num):
		var info: Dictionary = SaveManager.get_slot_info(slot_num)
		btn.text = "栏位 " + slot_name.right(1) + "\n" + str(info.get("timestamp", "")) + "\n第" + str(info.get("chapter", 0) + 1) + "章 第" + str(info.get("day", 1)) + "天"
		btn.add_theme_color_override("font_color", Color(1, 1, 1))
		btn.add_theme_stylebox_override("normal", _make_stylebox(Color(0.15, 0.15, 0.25, 0.85)))
	elif Dialogic.Save.has_slot(slot_name):
		var info: Dictionary = Dialogic.Save.get_slot_info(slot_name)
		var extra: Dictionary = info.get("extra", {})
		var timestamp: String = str(extra.get("date", info.get("timestamp", "")))
		var chapter: int = extra.get("chapter", 0)
		var day: int = extra.get("day", 1)
		btn.text = "栏位 " + slot_name.right(1) + "\n" + str(timestamp) + "\n第" + str(chapter + 1) + "章 第" + str(day) + "天"
		btn.add_theme_color_override("font_color", Color(1, 1, 1))
		btn.add_theme_stylebox_override("normal", _make_stylebox(Color(0.15, 0.15, 0.25, 0.85)))
	else:
		if is_load:
			btn.text = "空"
			btn.disabled = true
		else:
			btn.text = "空栏位 " + slot_name.right(1)
			btn.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			btn.add_theme_stylebox_override("normal", _make_stylebox(Color(0.1, 0.1, 0.15, 0.7)))

	btn.add_theme_stylebox_override("hover", _make_stylebox(Color(0.25, 0.25, 0.4, 0.9)))
	return btn


func _do_save(slot_name: String, _btn: Button) -> void:
	if Engine.is_editor_hint(): return
	var extra := {
		"date": Time.get_datetime_string_from_system(),
		"chapter": GameState.current_chapter,
		"day": GameState.current_day
	}
	Dialogic.Save.save(slot_name, false, Dialogic.Save.ThumbnailMode.NONE, extra)
	# 同时保存游戏状态（属性、好感度等）
	var slot_num := _slot_name_to_num(slot_name)
	if slot_num >= 0:
		SaveManager.save(slot_num)
	_show_toast("已存档: " + slot_name)
	_close_overlay()


func _do_load(slot_name: String, _btn: Button) -> void:
	if Engine.is_editor_hint(): return
	if Dialogic.Save.has_slot(slot_name):
		# 恢复游戏状态
		var slot_num := _slot_name_to_num(slot_name)
		if slot_num >= 0 and SaveManager.has_slot(slot_num):
			SaveManager.load(slot_num)
		# 恢复 Dialogic 状态
		Dialogic.Save.load(slot_name)
		# 关闭面板并重载场景，避免与当前时间线冲突
		_close_overlay()
		get_tree().change_scene_to_file("res://scenes/main.tscn")
	else:
		_show_toast("该栏位没有存档")


func _slot_name_to_num(slot_name: String) -> int:
	if slot_name.begins_with("slot_"):
		var num_str := slot_name.trim_prefix("slot_")
		if num_str.is_valid_int():
			return num_str.to_int()
	return -1

#endregion


#region 设置

func _show_settings_panel() -> void:
	if overlay_panel:
		return

	var panel := Control.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.75)
	panel.add_child(bg)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.offset_left = -180.0
	vbox.offset_top = -120.0
	vbox.offset_right = 180.0
	vbox.offset_bottom = 120.0
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	var title := Label.new()
	title.add_theme_font_override("font", _cn_font)
	title.text = "设置"
	title.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
	title.add_theme_font_size_override("font_size", 26)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	vbox.add_child(_make_volume_row("音量", BUS_MASTER))
	if AudioServer.get_bus_index(&"SFX") >= 0:
		vbox.add_child(_make_volume_row("音效", &"SFX"))
	if AudioServer.get_bus_index(&"Music") >= 0:
		vbox.add_child(_make_volume_row("音乐", &"Music"))

	var sep := HSeparator.new()
	sep.modulate.a = 0.2
	vbox.add_child(sep)

	var menu_btn := _make_panel_button("返回主菜单", Color(0.5, 0.1, 0.1, 0.85), Color(0.7, 0.15, 0.15, 0.9))
	menu_btn.pressed.connect(_on_return_to_menu)
	vbox.add_child(menu_btn)

	var close_btn := _make_panel_button("关闭", button_color, button_hover_color)
	close_btn.pressed.connect(func(): panel.queue_free())
	vbox.add_child(close_btn)

	add_child(panel)
	overlay_panel = panel
	panel.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(panel, "modulate:a", 1.0, 0.15)


func _make_volume_row(label_text: String, bus_name: StringName) -> Control:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)

	var lbl := Label.new()
	lbl.add_theme_font_override("font", _cn_font)
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(80, 0)
	lbl.add_theme_color_override("font_color", Color(1, 1, 1))
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(lbl)

	var bus_idx := AudioServer.get_bus_index(bus_name)
	var current_vol := db_to_linear(AudioServer.get_bus_volume_db(bus_idx)) if bus_idx >= 0 else 1.0

	var slider := HSlider.new()
	slider.custom_minimum_size = Vector2(200, 0)
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = current_vol
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(slider)

	var val_label := Label.new()
	val_label.add_theme_font_override("font", _cn_font)
	val_label.text = str(int(current_vol * 100)) + "%"
	val_label.custom_minimum_size = Vector2(40, 0)
	val_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	val_label.add_theme_font_size_override("font_size", 14)
	val_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(val_label)

	slider.value_changed.connect(func(val: float):
		var b := AudioServer.get_bus_index(bus_name)
		if b >= 0:
			AudioServer.set_bus_volume_db(b, linear_to_db(val))
		val_label.text = str(int(val * 100)) + "%"
	)
	return hbox


func _on_return_to_menu() -> void:
	if Engine.is_editor_hint(): return
	_close_overlay()
	Dialogic.end_timeline(true)
	get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")

#endregion


func _show_toast(msg: String) -> void:
	var label := Label.new()
	label.add_theme_font_override("font", _cn_font)
	label.text = msg
	label.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	label.add_theme_font_size_override("font_size", 16)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_CENTER)
	label.offset_top = -60.0
	label.modulate.a = 1.0
	add_child(label)
	var t: Tween = create_tween()
	t.tween_interval(1.2)
	t.tween_property(label, "modulate:a", 0.0, 0.5)
	t.tween_callback(label.queue_free)
