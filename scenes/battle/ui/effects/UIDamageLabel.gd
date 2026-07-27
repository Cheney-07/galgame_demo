# scenes/battle/ui/effects/UIDamageLabel.gd
class_name UIDamageLabel extends Label

func show_damage(amount: int, is_crit: bool) -> void:
	text = "-" + str(amount)
	if is_crit:
		text += " 暴击!"
		add_theme_color_override("font_color", Color(1, 0.6, 0))
		add_theme_font_size_override("font_size", 20)
	else:
		add_theme_color_override("font_color", Color(1, 0.3, 0.3))
		add_theme_font_size_override("font_size", 16)
	_animate()

func show_heal(amount: int) -> void:
	text = "+" + str(amount)
	add_theme_color_override("font_color", Color(0.3, 1, 0.3))
	add_theme_font_size_override("font_size", 16)
	_animate()

func show_miss() -> void:
	text = "MISS!"
	add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	add_theme_font_size_override("font_size", 14)
	_animate()

func _animate() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position", position + Vector2(0, -40), 1.0)
	tween.tween_property(self, "modulate:a", 0.0, 1.0)
	await tween.finished
	queue_free()
