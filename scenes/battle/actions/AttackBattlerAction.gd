# scenes/battle/actions/AttackBattlerAction.gd
class_name AttackBattlerAction extends BattlerAction

@export var hit_count: int = 1
@export var use_magic: bool = false
@export var crit_chance_bonus: float = 0.0

func execute(source, targets: Array) -> Dictionary:
	var result := { "damage": 0, "heal": 0, "crit": false, "hit": true, "messages": [], "effects": [] }
	if targets.is_empty():
		result["hit"] = false
		result["messages"].append("没有目标!")
		return result

	# 动画：向目标移动
	await _move_to_target(source, targets[0])

	var actual_hits := hit_count
	if action_name == "弹幕连射":
		actual_hits = 3 + int(source.stats.speed / 5)
		if actual_hits > 1:
			result["messages"].append(str(actual_hits) + " Hits!")

	var total_dmg := 0
	var atk_stat = source.stats.magic_attack if use_magic else source.stats.attack
	var target_def = targets[0].stats.defense

	for h in actual_hits:
		var hit_roll := randf()
		var hit_chance_val = source.stats.hit_chance / 100.0
		if hit_roll > hit_chance_val:
			continue  # miss 该段

		var base_dmg = atk_stat * base_power
		var def_factor = 100.0 / (100.0 + target_def)
		var dmg = max(1, int(base_dmg * def_factor))

		var crit_roll := randf()
		var crit := crit_roll < (0.05 + crit_chance_bonus)
		if crit:
			dmg = int(dmg * 1.5)
			result["crit"] = true

		total_dmg += dmg

	# 防御减半
	if targets[0].stats.guard:
		total_dmg = int(total_dmg * 0.5)
		result["messages"].append("防御!")

	targets[0].stats.guard = false
	result["damage"] = total_dmg

	targets[0].take_damage(total_dmg)
	source.position = source.origin_position

	return result

func _move_to_target(source, target) -> void:
	if not is_instance_valid(source) or not is_instance_valid(target):
		return
	var origin = source.position
	source.origin_position = origin
	var dir := -1.0 if source.is_player else 1.0
	var dest = target.position + Vector2(dir * 200.0, 0)
	if not source.is_inside_tree():
		return
	var tween = source.create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(source, "position", dest, 0.2)
	await tween.finished
	if not is_instance_valid(source):
		return
	source.position = origin
