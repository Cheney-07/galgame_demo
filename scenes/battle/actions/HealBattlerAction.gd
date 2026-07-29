# scenes/battle/actions/HealBattlerAction.gd
class_name HealBattlerAction extends BattlerAction

func execute(source, targets: Array) -> Dictionary:
	var result := { "damage": 0, "heal": 0, "crit": false, "hit": true, "messages": [], "effects": [] }
	if targets.is_empty():
		return result

	# 根据 stat_scale 获取对应属性值
	var stat_val = source.stats.magic_attack
	if stat_scale == "CHA":
		stat_val = source.stats.cha

	var heal_amount := int(stat_val * base_power * 8.0)
	heal_amount = max(1, heal_amount)

	# 跳跃动画（成功入树时才播放）
	if source.is_inside_tree():
		var origin = source.position
		var jump = source.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		jump.tween_property(source, "position", origin + Vector2(0, -100), 0.15)
		await jump.finished
		if is_instance_valid(source):
			var fall = source.create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
			fall.tween_property(source, "position", origin, 0.15)
			await fall.finished

	if target_scope == TargetScope.ALL_ALLIES:
		var count := 0
		for t in targets:
			if is_instance_valid(t) and t.stats.health > 0:
				t.heal(heal_amount)
				count += 1
		result["heal"] = heal_amount
		if count > 1:
			result["messages"].append("全队回复 " + str(heal_amount))
	else:
		if targets.size() > 0:
			var t = targets[0]
			if is_instance_valid(t):
				t.heal(heal_amount)
				result["heal"] = heal_amount

	return result
