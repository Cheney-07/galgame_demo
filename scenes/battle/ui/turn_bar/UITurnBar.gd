# scenes/battle/ui/turn_bar/UITurnBar.gd
class_name UITurnBar extends Control

const ICON_SCENE_PATH := "res://scenes/battle/ui/turn_bar/UIBattlerIcon.tscn"

@onready var background := $Background as TextureRect
@onready var icons_container := $Background/Icons as Control

var _icons := []

func setup(battler_list: BattlerList) -> void:
	var icon_scene = load(ICON_SCENE_PATH)
	for b in battler_list.get_all_battlers():
		var icon = icon_scene.instantiate()
		icon.custom_minimum_size = Vector2(48, 48)
		icon.size = Vector2(48, 48)

		var range_x := Vector2(icon.size.x / 2.0, background.size.x - icon.size.x / 2.0)
		icon.setup(b, range_x)
		icon.progress = 0.0

		b.readiness_changed.connect(func(val: float):
			if is_instance_valid(icon):
				icon.progress = val / 100.0
		)
		b.stats.health_depleted.connect(icon.fade_out)

		icons_container.add_child(icon)
		_icons.append(icon)

func fade_in() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
	modulate.a = 0.0

func fade_out() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
