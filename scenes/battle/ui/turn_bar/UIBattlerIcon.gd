# scenes/battle/ui/turn_bar/UIBattlerIcon.gd
class_name UIBattlerIcon extends TextureRect

var battler_ref
var position_range := Vector2.ZERO

var progress := 0.0:
	set(value):
		progress = clamp(value, 0.0, 1.0)
		position.x = lerp(position_range.x, position_range.y, progress)

func setup(battler, range_val: Vector2) -> void:
	battler_ref = battler
	position_range = range_val
	texture = battler.icon_texture
	modulate = Color(0.5, 0.5, 1.0) if battler.is_player else Color(1.0, 0.5, 0.5)

func fade_out() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)
