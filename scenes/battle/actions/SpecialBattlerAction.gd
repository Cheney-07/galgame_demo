# scenes/battle/actions/SpecialBattlerAction.gd
class_name SpecialBattlerAction extends BattlerAction

func execute(source, targets: Array) -> Dictionary:
	var result := { "damage": 0, "heal": 0, "crit": false, "hit": true, "messages": [], "effects": [] }
	result["messages"].append("召唤助战!")

	if targets.is_empty():
		return result

	# 额外 MAG 伤害
	var mag = source.stats.magic_attack
	var def_val = targets[0].stats.defense
	var dmg := int(mag * base_power * 100.0 / (100.0 + def_val))
	dmg = max(1, dmg)
	result["damage"] = dmg
	targets[0].take_damage(dmg)

	return result
