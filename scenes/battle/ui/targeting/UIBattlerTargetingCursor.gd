# scenes/battle/ui/targeting/UIBattlerTargetingCursor.gd
class_name UIBattlerTargetingCursor extends Control

signal target_selected(target)
signal cancelled()

func setup(possible_targets: Array, _all_battlers: Array, _turn_queue) -> void:
	for t in possible_targets:
		if t.stats.health <= 0:
			continue

		var btn := Button.new()
		btn.add_theme_font_override("font", _cn_font)
		btn.text = t.display_name
		btn.custom_minimum_size = Vector2(120, 40)
		if t.is_player:
			btn.position = t.position + Vector2(-60, -80)
		else:
			btn.position = t.position + Vector2(-60, 40)
		btn.add_theme_stylebox_override("normal", _make_highlight_style())
		btn.pressed.connect(func():
			target_selected.emit(t)
		)
		add_child(btn)

	var cancel := Button.new()
	cancel.add_theme_font_override("font", _cn_font)
	cancel.text = "取消"
	cancel.position = Vector2(800, 920)
	cancel.pressed.connect(func():
		cancelled.emit()
	)
	add_child(cancel)

func _make_highlight_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.2, 0.6, 1.0, 0.4)
	s.set_corner_radius_all(6)
	return s
