# scenes/battle/actions/BattlerAction.gd
class_name BattlerAction extends Resource

enum TargetScope { SELF, SINGLE_ENEMY, ALL_ENEMIES, SINGLE_ALLY, ALL_ALLIES }

@export var action_name: String = "行动"
@export var description: String = ""
@export var target_scope: TargetScope = TargetScope.SINGLE_ENEMY
@export var readiness_saved: float = 0.0
@export var base_power: float = 1.0
@export var stat_scale: String = "STR"
@export var icon_path: String = ""

func can_execute(_source) -> bool:
	return true

func get_possible_targets(source, all_battlers: Array) -> Array:
	var targets: Array = []
	# 按阵法阵营分：同一阵营 vs 对方阵营
	var same_side := all_battlers.filter(func(b): return b.is_player == source.is_player and b.stats.health > 0)
	var other_side := all_battlers.filter(func(b): return b.is_player != source.is_player and b.stats.health > 0)

	match target_scope:
		TargetScope.SELF:
			targets = [source]
		TargetScope.SINGLE_ENEMY:
			targets = other_side
		TargetScope.ALL_ENEMIES:
			targets = other_side
		TargetScope.SINGLE_ALLY:
			targets = same_side
		TargetScope.ALL_ALLIES:
			targets = same_side

	return targets

func execute(source, targets: Array) -> Dictionary:
	return { "damage": 0, "heal": 0, "crit": false, "hit": true, "messages": [], "effects": [] }

func get_hit_chance(source) -> float:
	return source.stats.hit_chance / 100.0
