# scenes/battle/ui/player_panel/UIPlayerBattlerList.gd
class_name UIPlayerBattlerList extends Control

func setup(battler_list: BattlerList) -> void:
	var entry_scene = load("res://scenes/battle/ui/player_panel/UIBattlerEntry.tscn")
	if entry_scene == null:
		print("[UIPlayerBattlerList] ERROR: Failed to load UIBattlerEntry.tscn")
		return

	var idx = 0
	for p in battler_list.players:
		var entry = entry_scene.instantiate()
		if entry == null:
			continue
		entry.position = Vector2(0, idx * 70)
		entry.setup(p)
		add_child(entry)
		idx += 1

func fade_out() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
