# scenes/battle/actions/ActionFactory.gd
class_name ActionFactory extends RefCounted

static func from_skill_data(skill_data) -> BattlerAction:
	if skill_data == null:
		return null

	match skill_data.skill_type:
		"damage":
			var action := AttackBattlerAction.new()
			action.action_name = skill_data.skill_name
			action.description = skill_data.description
			action.base_power = skill_data.power
			action.stat_scale = skill_data.stat_scale
			action.icon_path = skill_data.icon_path
			action.hit_count = skill_data.hit_count
			action.readiness_saved = 0.0
			action.target_scope = _map_target_type(skill_data.target_type)
			action.use_magic = (skill_data.stat_scale == "MAG")
			return action

		"heal":
			var action := HealBattlerAction.new()
			action.action_name = skill_data.skill_name
			action.description = skill_data.description
			action.base_power = skill_data.power
			action.stat_scale = skill_data.stat_scale
			action.icon_path = skill_data.icon_path
			action.readiness_saved = 0.0
			action.target_scope = _map_target_type(skill_data.target_type)
			return action

		"buff":
			var action := ModifyStatsBattlerAction.new()
			action.action_name = skill_data.skill_name
			action.description = skill_data.description
			action.base_power = skill_data.power
			action.stat_scale = skill_data.stat_scale
			action.icon_path = skill_data.icon_path
			action.readiness_saved = 0.0
			action.target_scope = _map_target_type(skill_data.target_type)
			if skill_data.effects.size() > 0:
				var ef = skill_data.effects[0]
				action.modify_stat = ef.get("stat", "attack")
				action.modify_value = ef.get("value", 5)
				action.duration_turns = ef.get("turns", 3)
			return action

		"special":
			var action := SpecialBattlerAction.new()
			action.action_name = skill_data.skill_name
			action.description = skill_data.description
			action.base_power = skill_data.power
			action.stat_scale = skill_data.stat_scale
			action.icon_path = skill_data.icon_path
			action.readiness_saved = 0.0
			action.target_scope = _map_target_type(skill_data.target_type)
			return action

	return null

static func create_basic_attack() -> AttackBattlerAction:
	var action := AttackBattlerAction.new()
	action.action_name = "攻击"
	action.description = "普通攻击"
	action.base_power = 1.5
	action.stat_scale = "STR"
	action.hit_count = 1
	action.readiness_saved = 30.0
	action.target_scope = BattlerAction.TargetScope.SINGLE_ENEMY
	return action

static func create_defend() -> BattlerAction:
	var action := BattlerAction.new()
	action.action_name = "防御"
	action.description = "本回合伤害减半"
	action.readiness_saved = 50.0
	action.target_scope = BattlerAction.TargetScope.SELF
	return action

static func _map_target_type(ttype: String) -> int:
	match ttype:
		"single_enemy": return BattlerAction.TargetScope.SINGLE_ENEMY
		"all_enemies": return BattlerAction.TargetScope.ALL_ENEMIES
		"single_ally": return BattlerAction.TargetScope.SINGLE_ALLY
		"all_allies": return BattlerAction.TargetScope.ALL_ALLIES
		"self": return BattlerAction.TargetScope.SELF
	return BattlerAction.TargetScope.SINGLE_ENEMY
