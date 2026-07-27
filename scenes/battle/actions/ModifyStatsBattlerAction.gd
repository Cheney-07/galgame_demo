# scenes/battle/actions/ModifyStatsBattlerAction.gd
class_name ModifyStatsBattlerAction extends BattlerAction

@export var modify_stat: String = "attack"
@export var modify_value: int = 5
@export var duration_turns: int = 3

func execute(source, targets: Array) -> Dictionary:
	var result := { "damage": 0, "heal": 0, "crit": false, "hit": true, "messages": [], "effects": [] }
	result["effects"] = [{ "stat": modify_stat, "value": modify_value, "turns": duration_turns }]

	for t in targets:
		if t.stats.health > 0:
			var id = t.stats.add_modifier(modify_stat, modify_value)
			# 存储 buff id 以便后续移除
			if not t.has_meta("buff_ids"):
				t.set_meta("buff_ids", [])
			t.get_meta("buff_ids").append({ "id": id, "stat": modify_stat, "turns": duration_turns })

	result["messages"].append(action_name + "!")
	return result
